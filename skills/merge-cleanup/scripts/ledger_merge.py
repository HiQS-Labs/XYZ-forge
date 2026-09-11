#!/usr/bin/env python3
"""ledger_merge.py — GH-534 Phase B: pre-merge ledger gate (E.6) and disjoint-only ledger
conflict resolution (B1) for /merge-cleanup.

Everything here runs inside a DISPOSABLE full clone that already has `git merge
origin/<integration-branch>` in progress (or just completed) on top of the PR head. Nothing here
touches the operator's primary checkout, and nothing here writes a ledger row except through the
supported writer path — `utils/py/releases_app.py` verbs — never by editing the dump.

What the resolver (`utils/releases-merge-resolve.sh`) does NOT decide is which rows survive. B1's
job is exactly that decision, and it decides it only when the answer is mechanical:

  * three-way classify `releases.sql` against the merge base, per table, per key — adds, updates,
    deletes, natural-key duplicates, references to a row the other side deleted;
  * auto-resolve only when the two sides' change sets are DISJOINT and every change on the side
    being replayed is expressible by a roadmap verb (`add`, `update`, `rate`, `repoint`);
  * the side with the HIGHER generation is kept as-is and the other side's changes are replayed
    onto it, so the generation floor the resolver enforces is met by construction;
  * everything else — same-key change on both sides, a delete against a reference, a change in a
    table the writer cannot express, `harnesses.*`, a code file, an extraction error — is a
    HANDOFF with the key list, never a guess.
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

from scan_clones import run_git

LEDGER_DUMP = "releases.sql"
LEDGER_DB = "releases.db"
LEDGER_VIEWS = ("LEADERBOARD.md", "RELEASES-PREVIEW.html", "LEADERBOARD.html")
B1_SET = {LEDGER_DUMP, LEDGER_DB, *LEDGER_VIEWS}
# Excluded until they have their own resolver: a conflict here is a handoff (plan B1).
B1_EXCLUDED = {"harnesses.db", "harnesses.sql"}

# Tables whose rows are derived by the writer itself and must not be compared: receipts are
# rewritten by every replayed verb, and `settings.generation` is the floor the resolver enforces.
#
# GH-549: `work_events` belongs here for the same reason. Every roadmap verb this resolver replays
# goes through perform_write, which emits that verb's work-state event as part of the write — so
# the replayed side's events are REPRODUCED by the replay (with fresh ids and txn_ids, as receipts
# are), and comparing them beforehand would hand off every PR whose ledger carries one, which after
# #549 is every PR that touched the roadmap. The kept side's events survive untouched in the kept
# dump. `connector_cursors` never appears in the dump at all (it is device-local runtime state).
DERIVED_TABLES = {"op_receipts", "work_events"}
# roadmap_items columns a replay can express through a verb. Anything else that differs → handoff.
REPLAYABLE_COLUMNS = {"section", "status_marker", "raw_text", "issue_url", "doc_path",
                      "rating_pri", "rating_sev", "rating_appeal", "rating_effort", "rating_ovr",
                      "updated_at", "position"}

_INSERT_RE = re.compile(r"^INSERT INTO (\w+)\((.*?)\) VALUES\((.*)\);$")


def _split_values(s: str) -> List[Optional[str]]:
    """Split a SQL VALUES(...) body into python values: quoted strings (with '' unescaped), NULL,
    or bare literals. The dump is machine-written, so the grammar is exactly this."""
    out: List[Optional[str]] = []
    i, n = 0, len(s)
    while i < n:
        c = s[i]
        if c == "'":
            j = i + 1
            buf = []
            while j < n:
                if s[j] == "'":
                    if j + 1 < n and s[j + 1] == "'":
                        buf.append("'")
                        j += 2
                        continue
                    break
                buf.append(s[j])
                j += 1
            out.append("".join(buf))
            i = j + 1
        elif c in ", ":
            i += 1
        else:
            j = i
            while j < n and s[j] != ",":
                j += 1
            tok = s[i:j].strip()
            out.append(None if tok.upper() == "NULL" else tok)
            i = j
    return out


def parse_dump(text: str) -> Dict[str, Any]:
    """{"generation": int|None, "tables": {table: {key: {col: val}}}}.

    Key: `settings` by its `key` column; append-only event tables by their whole row; positional
    tables by (first column, position); everything else by its first column (the global id)."""
    gen = None
    m = re.search(r"^-- generation: (\d+)$", text, re.M)
    if m:
        gen = int(m.group(1))
    tables: Dict[str, Dict[Any, Dict[str, Optional[str]]]] = {}
    # Everything that is not a row and not the generation stamp — DDL, pragmas, unknown
    # statements, structural comments. The dump carries none today, so any difference here is
    # a shape this classifier was never taught and must hand off (plan: "schema changes →
    # handoff"). Compared verbatim, never interpreted.
    other: List[str] = []
    for line in text.splitlines():
        mm = _INSERT_RE.match(line)
        if not mm:
            if line.strip() and not line.startswith("-- generation:"):
                other.append(line.rstrip())
            continue
        table, cols_s, vals_s = mm.groups()
        cols = [c.strip() for c in cols_s.split(",")]
        vals = _split_values(vals_s)
        if len(cols) != len(vals):
            raise ValueError(f"{table}: {len(cols)} columns but {len(vals)} values in {line[:80]!r}")
        row = dict(zip(cols, vals))
        if table == "settings":
            key: Any = row.get("key")
        elif table in ("op_receipts", "manifest_state_events", "grandfather_entries", "schema_migrations"):
            key = line
        elif table in ("doc_lines", "legacy_lines"):
            key = (row.get(cols[0]), row.get("position"))
        else:
            key = row.get(cols[0])
        tables.setdefault(table, {})[key] = row
    return {"generation": gen, "tables": tables, "other": other}


def _changes(base: Dict[Any, Dict], side: Dict[Any, Dict]) -> Dict[Any, str]:
    """key -> 'added' | 'updated' | 'deleted' for one side against the base."""
    out: Dict[Any, str] = {}
    for k, row in side.items():
        if k not in base:
            out[k] = "added"
        elif base[k] != row:
            out[k] = "updated"
    for k in base:
        if k not in side:
            out[k] = "deleted"
    return out


def classify(base_text: str, ours_text: str, theirs_text: str) -> Dict[str, Any]:
    """Three-way classification of the ledger dump.

    Returns {"disjoint": bool, "reasons": [str], "ours": {table: {key: kind}},
             "theirs": {...}, "keep": "ours"|"theirs", "replay": [op...], "gen": (ours, theirs)}.
    `keep` is the side with the higher generation; `replay` is the OTHER side's roadmap changes
    expressed as verbs. `disjoint` False → handoff; `reasons` names every key."""
    try:
        base, ours, theirs = parse_dump(base_text), parse_dump(ours_text), parse_dump(theirs_text)
    except ValueError as exc:
        return {"disjoint": False, "reasons": [f"dump unparseable: {exc}"], "ours": {}, "theirs": {},
                "keep": "theirs", "replay": [], "gen": (None, None)}
    reasons: List[str] = []
    for side_name, side in (("ours", ours), ("theirs", theirs)):
        if side.get("other") != base.get("other"):
            changed = sorted(set(side.get("other", [])) ^ set(base.get("other", [])))
            reasons.append(f"non-row dump content changed on {side_name} (schema/DDL or unknown statements): "
                           + "; ".join(c[:60] for c in changed[:3]))
    ours_ch: Dict[str, Dict[Any, str]] = {}
    theirs_ch: Dict[str, Dict[Any, str]] = {}
    all_tables = set(base["tables"]) | set(ours["tables"]) | set(theirs["tables"])
    for t in sorted(all_tables):
        if t in DERIVED_TABLES:
            continue
        b = base["tables"].get(t, {})
        o = ours["tables"].get(t, {})
        h = theirs["tables"].get(t, {})
        oc = _changes(b, o)
        hc = _changes(b, h)
        if t == "settings":
            oc.pop("generation", None)
            hc.pop("generation", None)
        if oc:
            ours_ch[t] = oc
        if hc:
            theirs_ch[t] = hc
        # Same key changed on both sides (unless both made the identical change).
        for k in sorted(set(oc) & set(hc), key=str):
            if o.get(k) == h.get(k):
                continue
            reasons.append(f"{t}[{k}]: {oc[k]} on the PR side and {hc[k]} on {'the integration side'} — same-key change on both sides")
        # Natural-key duplicates for roadmap items: two different gids, one gh_number.
        if t == "roadmap_items":
            by_gh: Dict[str, Set[Any]] = {}
            for src, rows in (("ours", o), ("theirs", h)):
                for k, row in rows.items():
                    gh = row.get("gh_number")
                    if gh:
                        by_gh.setdefault(gh, set()).add(k)
            for gh, keys in sorted(by_gh.items()):
                if len(keys) > 1 and (any(k in oc for k in keys) or any(k in hc for k in keys)):
                    reasons.append(f"roadmap_items gh_number {gh}: {len(keys)} different rows ({', '.join(sorted(map(str, keys)))}) — a clean textual merge would still be a semantic conflict")

    # A delete on one side against an add/update on the other — in ANY table — that still
    # references the deleted key (repo_gid, release_gid, tracking_ref_gid, ...).
    for deleter, other, other_tables, label in ((theirs_ch, ours_ch, ours["tables"], "integration side deleted"),
                                                (ours_ch, theirs_ch, theirs["tables"], "PR side deleted")):
        deleted = {(t, k) for t, ch in deleter.items() for k, kind in ch.items() if kind == "deleted" and isinstance(k, str)}
        for (dt, dk) in sorted(deleted):
            for ot, och in other.items():
                for ok, okind in och.items():
                    if okind == "deleted":
                        continue
                    row = other_tables.get(ot, {}).get(ok, {})
                    if any(v == dk for v in row.values()):
                        reasons.append(f"{dt}[{dk}]: {label} a row that the other side's {okind} {ot} row {ok} still references")

    og, hg = ours["generation"], theirs["generation"]
    keep = "ours" if (og or 0) > (hg or 0) else "theirs"
    replay_side = theirs_ch if keep == "ours" else ours_ch
    replay_rows = theirs["tables"] if keep == "ours" else ours["tables"]
    kept_rows = ours["tables"] if keep == "ours" else theirs["tables"]
    replay: List[Dict[str, Any]] = []
    for t, ch in replay_side.items():
        if t == "settings":
            reasons.append(f"settings: {', '.join(map(str, ch))} changed on the replayed side — no writer verb sets it")
            continue
        if t != "roadmap_items":
            reasons.append(f"{t}: {len(ch)} change(s) on the replayed side — the writer path cannot express this table (keys: {', '.join(map(str, list(ch)[:5]))})")
            continue
        for k, kind in ch.items():
            row = replay_rows.get(t, {}).get(k, {})
            if kind == "deleted":
                reasons.append(f"roadmap_items[{k}]: deleted on the replayed side — no writer verb deletes a row")
                continue
            if kind == "added":
                replay.append({"op": "add", "row": row})
                continue
            base_row = base["tables"].get(t, {}).get(k, {})
            diff_cols = {c for c in row if row.get(c) != base_row.get(c)}
            bad = diff_cols - REPLAYABLE_COLUMNS
            if bad:
                reasons.append(f"roadmap_items[{k}]: column(s) {', '.join(sorted(bad))} changed — not expressible through a verb")
                continue
            kept = kept_rows.get(t, {}).get(k)
            if kept is None:
                reasons.append(f"roadmap_items[{k}]: updated on one side, absent on the other")
                continue
            replay.append({"op": "update", "row": row, "base": base_row, "cols": sorted(diff_cols - {"updated_at", "position"})})
    return {"disjoint": not reasons, "reasons": reasons, "ours": ours_ch, "theirs": theirs_ch,
            "keep": keep, "replay": replay, "gen": (og, hg)}


# --- replay through the writer path ---------------------------------------------------------

def _app(root: Path) -> List[str]:
    return [sys.executable, str(root / "utils" / "py" / "releases_app.py"), "--root", str(root)]


def _run(cmd: List[str], cwd: Path, timeout: int = 300) -> subprocess.CompletedProcess:
    try:
        return subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True, check=False, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return subprocess.CompletedProcess(args=cmd, returncode=127, stdout="", stderr=str(exc))


def _rated(row: Dict[str, Optional[str]]) -> Optional[str]:
    axes = [row.get(c) for c in ("rating_pri", "rating_sev", "rating_appeal", "rating_effort")]
    if all(a not in (None, "") for a in axes):
        return "/".join(str(a) for a in axes)
    return None


def replay_ops(root: Path, ops: List[Dict[str, Any]]) -> Tuple[bool, List[str]]:
    """Apply roadmap changes through `releases_app.py roadmap ...`. Stops at the first refusal."""
    log: List[str] = []
    for op in ops:
        row = op["row"]
        gh = row.get("gh_number")
        if not gh:
            return False, log + [f"replay: row {row.get('global_id')} has no gh_number — no verb can address it"]
        if op["op"] == "add":
            cmd = _app(root) + ["roadmap", "add", "--issue-num", str(gh), "--issue-url", row.get("issue_url") or "",
                                "--title", row.get("title") or "", "--created", (row.get("first_seen") or "")[:10],
                                "--doc-path", row.get("doc_path") or ""]
            if row.get("raw_text"):
                cmd += ["--raw-text", row["raw_text"]]
            r = _run(cmd, root)
            log.append(f"roadmap add GH-{gh}: rc={r.returncode} {r.stderr.strip()[:200]}")
            if r.returncode != 0:
                return False, log
            rated = _rated(row)
            if rated:
                cmd = _app(root) + ["roadmap", "rate", "--issue-num", str(gh), "--rated", rated, "--force"]
                if row.get("rating_ovr"):
                    cmd += ["--ovr", str(row["rating_ovr"])]
                r = _run(cmd, root)
                log.append(f"roadmap rate GH-{gh} {rated}: rc={r.returncode} {r.stderr.strip()[:200]}")
                if r.returncode != 0:
                    return False, log
            section, marker = row.get("section"), row.get("status_marker")
            if (section and section != "Queue / parked intake") or marker:
                cmd = _app(root) + ["roadmap", "update", "--issue-num", str(gh)]
                if section and section != "Queue / parked intake":
                    cmd += ["--section", section]
                if marker:
                    cmd += ["--status-marker", marker]
                r = _run(cmd, root)
                log.append(f"roadmap update GH-{gh} (section/marker): rc={r.returncode} {r.stderr.strip()[:200]}")
                if r.returncode != 0:
                    return False, log
        else:
            cols = set(op["cols"])
            if "doc_path" in cols:
                r = _run(_app(root) + ["roadmap", "repoint", "--issue-num", str(gh), "--doc-path", row.get("doc_path") or ""], root)
                log.append(f"roadmap repoint GH-{gh}: rc={r.returncode} {r.stderr.strip()[:200]}")
                if r.returncode != 0:
                    return False, log
            upd = [c for c in ("section", "status_marker", "raw_text", "issue_url") if c in cols]
            if upd:
                cmd = _app(root) + ["roadmap", "update", "--issue-num", str(gh)]
                for c in upd:
                    cmd += ["--" + c.replace("_", "-"), row.get(c) or ""]
                r = _run(cmd, root)
                log.append(f"roadmap update GH-{gh} ({', '.join(upd)}): rc={r.returncode} {r.stderr.strip()[:200]}")
                if r.returncode != 0:
                    return False, log
            if cols & {"rating_pri", "rating_sev", "rating_appeal", "rating_effort", "rating_ovr"}:
                rated = _rated(row)
                if not rated:
                    return False, log + [f"roadmap_items GH-{gh}: rating partially cleared — no verb expresses that"]
                cmd = _app(root) + ["roadmap", "rate", "--issue-num", str(gh), "--rated", rated, "--force"]
                if row.get("rating_ovr"):
                    cmd += ["--ovr", str(row["rating_ovr"])]
                r = _run(cmd, root)
                log.append(f"roadmap rate GH-{gh} {rated}: rc={r.returncode} {r.stderr.strip()[:200]}")
                if r.returncode != 0:
                    return False, log
    return True, log


# --- the clone-side operations -----------------------------------------------------------------

def extract_conflict_set(clone: Path) -> Tuple[bool, Set[str], str]:
    """(ok, unmerged paths, error). An extraction error is NOT an empty set."""
    d = run_git(clone, ["diff", "--name-only", "--diff-filter=U"])
    u = run_git(clone, ["ls-files", "-u"])
    if d.returncode != 0 or u.returncode != 0:
        return False, set(), f"conflict-set extraction failed: {(d.stderr or u.stderr).strip() or 'git failed'}"
    paths = {l.strip() for l in d.stdout.splitlines() if l.strip()}
    for line in u.stdout.splitlines():
        parts = line.split("\t", 1)
        if len(parts) == 2:
            paths.add(parts[1].strip())
    return True, paths, ""


def _show(clone: Path, ref: str, path: str) -> Optional[str]:
    r = run_git(clone, ["show", f"{ref}:{path}"])
    return r.stdout if r.returncode == 0 else None


def three_way_texts(clone: Path, integration_branch: str = "development") -> Tuple[Optional[str], Optional[str], Optional[str], str]:
    """(base, ours=HEAD, theirs=MERGE_HEAD) dump texts; the merge base is required.

    No MERGE_HEAD is acceptable only when there was nothing to merge (HEAD already contains the
    integration tip); then all three texts are HEAD's and the caller sees "no change on either side"."""
    mh = run_git(clone, ["rev-parse", "--verify", "-q", "MERGE_HEAD"])
    if mh.returncode != 0:
        anc = run_git(clone, ["merge-base", "--is-ancestor", f"origin/{integration_branch}", "HEAD"])
        if anc.returncode == 0:
            head = _show(clone, "HEAD", LEDGER_DUMP)
            if head is None:
                return None, None, None, "releases.sql is missing at HEAD"
            return head, head, head, ""
        return None, None, None, "no MERGE_HEAD — not inside a merge"
    mb = run_git(clone, ["merge-base", "HEAD", "MERGE_HEAD"])
    if mb.returncode != 0 or not mb.stdout.strip():
        return None, None, None, "cannot compute the merge base"
    base = _show(clone, mb.stdout.strip(), LEDGER_DUMP)
    ours = _show(clone, "HEAD", LEDGER_DUMP)
    theirs = _show(clone, "MERGE_HEAD", LEDGER_DUMP)
    if base is None or ours is None or theirs is None:
        return None, None, None, "releases.sql is missing on one of base/HEAD/MERGE_HEAD"
    return base, ours, theirs, ""


def ledger_semantic_check(clone: Path, integration_branch: str = "development") -> Dict[str, Any]:
    """E.6 step: after a merge (clean or not), classify the ledger three-way. Used both to detect
    a clean textual merge that is still a semantic conflict and to decide B1 eligibility."""
    base, ours, theirs, err = three_way_texts(clone, integration_branch)
    if err:
        return {"ok": False, "error": err}
    if ours == theirs or ours == base or theirs == base:
        return {"ok": True, "changed_both": False, "classification": None}
    return {"ok": True, "changed_both": True, "classification": classify(base, ours, theirs)}


def resolve_ledger_conflict(clone: Path, execute: bool) -> Dict[str, Any]:
    """B1 inside a clone with a conflicted merge in progress.

    Returns {"resolved": bool, "handoff": bool, "reason": str, "log": [...], "commit": sha|None,
             "conflict_set": [...]}. In dry-run (`execute` False) it classifies and reports and
    mutates nothing."""
    res: Dict[str, Any] = {"resolved": False, "handoff": False, "reason": "", "log": [], "commit": None, "conflict_set": []}
    ok, paths, err = extract_conflict_set(clone)
    if not ok:
        res.update(handoff=True, reason=err)
        return res
    res["conflict_set"] = sorted(paths)
    if not paths:
        res.update(handoff=True, reason="merge reported a conflict but the unmerged set is empty — refusing to guess")
        return res
    excluded = paths & B1_EXCLUDED
    if excluded:
        res.update(handoff=True, reason=f"conflict in {', '.join(sorted(excluded))} — no resolver for harness telemetry yet")
        return res
    non_ledger = paths - B1_SET
    if non_ledger:
        res.update(handoff=True, reason=f"code/doc conflict outside the ledger set: {', '.join(sorted(non_ledger))}")
        return res
    sem = ledger_semantic_check(clone)
    if not sem["ok"]:
        res.update(handoff=True, reason=sem["error"])
        return res
    cls = sem["classification"]
    if cls is None:
        # Only views conflicted; the dump itself is identical on one side. The resolver alone is
        # sufficient — but views regenerate from the dump, so still run the resolver.
        cls = {"disjoint": True, "reasons": [], "keep": "theirs", "replay": [], "gen": (None, None)}
    if not cls["disjoint"]:
        res.update(handoff=True, reason="ledger changes are not disjoint:\n  - " + "\n  - ".join(cls["reasons"]))
        return res
    res["log"].append(f"classification: keep={cls['keep']} generation ours/theirs={cls['gen']} replay={len(cls['replay'])} op(s)")
    if not execute:
        res.update(reason=f"[DRY RUN] B1 would keep the {cls['keep']} side and replay {len(cls['replay'])} roadmap change(s) through the writer, then run the resolver")
        return res

    keep_ref = "--ours" if cls["keep"] == "ours" else "--theirs"
    for f in (LEDGER_DUMP, LEDGER_DB):
        if f in paths:
            r = run_git(clone, ["checkout", keep_ref, "--", f])
            if r.returncode != 0:
                res.update(reason=f"git checkout {keep_ref} {f}: {r.stderr.strip()}")
                return res
    # The dump must be resolved in the index before the writer runs (it reads and rewrites it),
    # and the resolver refuses an unresolved dump anyway.
    r = run_git(clone, ["add", "--", LEDGER_DUMP])
    if r.returncode != 0:
        res.update(reason=f"git add {LEDGER_DUMP}: {r.stderr.strip()}")
        return res
    # Make the kept side's DB match its dump before replaying onto it.
    r = _run(_app(clone) + ["check", "--rebuild"], clone)
    res["log"].append(f"check --rebuild on the kept side: rc={r.returncode}")
    if r.returncode != 0:
        res.update(reason=f"kept side does not rebuild clean: {r.stderr.strip()[:300] or r.stdout.strip()[:300]}")
        return res
    ok, log = replay_ops(clone, cls["replay"])
    res["log"].extend(log)
    if not ok:
        res.update(handoff=True, reason="writer refused during replay: " + (log[-1] if log else "unknown"))
        return res
    r = run_git(clone, ["add", "--", LEDGER_DUMP])
    if r.returncode != 0:
        res.update(reason=f"git add after replay: {r.stderr.strip()}")
        return res
    r = _run(["bash", str(clone / "utils" / "releases-merge-resolve.sh"), "--root", str(clone)], clone)
    res["log"].append(f"releases-merge-resolve.sh: rc={r.returncode}")
    if r.returncode != 0:
        res.update(reason="resolver refused: " + (r.stderr.strip() or r.stdout.strip())[:600])
        return res
    r = _run(_app(clone) + ["check"], clone)
    if r.returncode != 0:
        res.update(reason="releases check red after resolution: " + (r.stderr.strip() or r.stdout.strip())[:400])
        return res
    u = run_git(clone, ["ls-files", "-u"])
    if u.returncode != 0 or u.stdout.strip():
        res.update(reason="unmerged entries remain after the resolver: " + u.stdout.strip()[:300])
        return res
    r = run_git(clone, ["commit", "--no-edit", "-q"])
    if r.returncode != 0:
        res.update(reason=f"merge commit failed: {r.stderr.strip()[:300]}")
        return res
    head = run_git(clone, ["rev-parse", "HEAD"]).stdout.strip()
    res.update(resolved=True, commit=head, reason=f"resolved through the writer path; merge commit {head[:10]}")
    return res


def pre_merge_ledger_gate(clone: Path, gh_bin: str = "gh", integration_branch: str = "development") -> Dict[str, Any]:
    """E.6: in a clone where the landing merge completed cleanly, run `check` and
    `roadmap reconcile-state --dry-run`; red on non-zero exit or any `FAIL:` line. `warn:` lines,
    per-row identity skips and `would move` lines are diagnostics, not red."""
    verdict: Dict[str, Any] = {"green": False, "failures": [], "diagnostics": []}
    sem = ledger_semantic_check(clone, integration_branch)
    if not sem["ok"]:
        verdict["failures"].append(f"ledger three-way read failed: {sem['error']}")
    elif sem["changed_both"] and not sem["classification"]["disjoint"]:
        verdict["failures"].append("ledger merged textually but is a semantic conflict:\n  - " + "\n  - ".join(sem["classification"]["reasons"]))
    for label, cmd in (("releases check", _app(clone) + ["check"]),
                       ("roadmap reconcile-state --dry-run", _app(clone) + ["roadmap", "reconcile-state", "--dry-run"])):
        env = dict(os.environ)
        if gh_bin != "gh":
            env["RELEASES_GH_BIN"] = gh_bin
        try:
            r = subprocess.run(cmd, cwd=str(clone), capture_output=True, text=True, check=False, timeout=600, env=env)
        except (OSError, subprocess.TimeoutExpired) as exc:
            verdict["failures"].append(f"{label}: did not run ({exc})")
            continue
        out = (r.stdout + "\n" + r.stderr)
        fails = [l.strip() for l in out.splitlines() if l.strip().startswith("FAIL:")]
        warns = [l.strip() for l in out.splitlines() if l.strip().startswith("warn:") or "would move" in l]
        verdict["diagnostics"].extend(f"{label}: {w}" for w in warns)
        if r.returncode != 0:
            verdict["failures"].append(f"{label}: exit {r.returncode}" + (": " + fails[0] if fails else ": " + (r.stderr.strip() or r.stdout.strip())[-300:]))
        elif fails:
            verdict["failures"].append(f"{label}: {fails[0]}")
    verdict["green"] = not verdict["failures"]
    return verdict
