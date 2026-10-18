"""batch_record.py — GH-1064: the durable record of one multi-PR landing batch.

One JSON file per batch under the primary's coordinator directory (beside the per-PR attempt
records), mirrored into one `merge-batch` GitHub issue. The script owns only the marked block of
that issue; every other section is the caller's and is never rewritten after creation.

The record answers two separate questions:
  qa_pending  — has anything landed that no recorded sweep verdict covers?  (drives exit 4)
  continuable — is any planned PR still not landed-and-reconciled?          (drives --resume)

GitHub calls go through the `gh(args, cwd)` callable the driver passes in (merge_cleanup._gh), so
this module has no wrapper of its own and never imports the driver.
"""

import importlib.util
import json
import os
import shlex
import sys
import tempfile
import time
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Tuple

import attempt_record

LABEL = "merge-batch"
START = "<!-- merge-batch:script:start -->"
END = "<!-- merge-batch:script:end -->"
VERDICTS = ("clean", "findings", "deferred")
FULL_GATE = "validate.sh --parallel 4"
CALLER_SECTIONS = (
    "## Strategy and sequence review\n<!-- groups/order, PR/head/base/candidate SHAs, CI checkpoints, rollback; "
    "for 3+ PRs: author/reviewer model identities, relay receipt and finding dispositions (GH-1066) -->\n\n",
    "## Problems\n\n",
    "## Ad-hoc fixes & pivots\n\n",
    "## Findings\n\n",
    "## Regression sweep (debug-mantra)\n- [ ] <!-- analysis with evidence; a clean sweep records what ran -->\n\n",
    "## Post-deployment carry-overs\n- [ ] <!-- verbatim items, attributed to #PR / #issue -->\n",
)


def _now() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def _strip_marks(obj: Any) -> Any:
    """Drop the one-shot intent markers before persisting (`_touched`, `_verdict_touched`,
    `_sweep_touched`, `_refreshed`) — they describe THIS save's intentional writes only."""
    if isinstance(obj, dict):
        return {k: _strip_marks(v) for k, v in obj.items()
                if k not in ("_touched", "_verdict_touched", "_sweep_touched", "_refreshed")}
    if isinstance(obj, list):
        return [_strip_marks(v) for v in obj]
    return obj


def _dir(primary: Path, origin: str) -> Path:
    return attempt_record.record_path(primary, origin, 0).parent


def _files(pr: Dict[str, Any]) -> List[str]:
    out = set()
    for f in pr.get("files") or []:
        if isinstance(f, dict) and f.get("path"):
            out.add(f["path"])
        elif isinstance(f, str):
            out.add(f)
    return sorted(out)


def _row(pos: int, pr: Dict[str, Any]) -> Dict[str, Any]:
    return {"pos": pos, "pr": pr["number"], "title": pr.get("title") or "", "files": _files(pr),
            "hard": list(pr.get("_hard_deps") or []),
            "soft": {str(k): v for k, v in (pr.get("_soft_reasons") or {}).items()}}


def new(primary: Path, origin: str, integration: str, ordered: List[Dict[str, Any]]) -> Dict[str, Any]:
    key = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime()) + f"-{ordered[0]['number']}"
    rec = {"schema": 1, "repo": origin, "integration": integration, "created": _now(),
           "issue": None, "issue_url": "", "issue_error": "",
           "planned": [_row(i + 1, pr) for i, pr in enumerate(ordered)],
           "outcomes": {str(pr["number"]): {"status": "unattempted"} for pr in ordered},
           "landed_order": [], "sweep_inputs": {}, "verdict": None,
           "path": str(_dir(primary, origin) / f"batch-{key}.json")}
    save(rec)
    return rec


def extend(rec: Dict[str, Any], ordered: List[Dict[str, Any]]) -> None:
    """A resumed queue may include a PR opened since the batch began: append it as a new row.
    GH-1140/#1075/#1073: a known PR whose branch changed between runs (a repair, a rebase, extra
    commits) must not keep its stale captured metadata — refresh title/files/hard/soft from the
    discovery data this call already receives. Order and outcomes are untouched. `_refreshed`
    marks the row as an intentional fresh write for save()'s merge rule. Empty discovery data
    never blanks a known row."""
    known = {row["pr"]: row for row in rec["planned"]}
    for pr in ordered:
        row = known.get(pr["number"])
        if row is None:
            rec["planned"].append(_row(len(rec["planned"]) + 1, pr))
            rec["outcomes"].setdefault(str(pr["number"]), {"status": "unattempted"})
            continue
        fresh_files = _files(pr)
        if not fresh_files:
            continue
        row["title"] = pr.get("title") or row.get("title") or ""
        row["files"] = fresh_files
        # valid discovery carries an authoritative dependency answer, empty included — stale
        # annotations must not survive a refresh the way a failed (empty) file list must
        row["hard"] = list(pr.get("_hard_deps") or [])
        row["soft"] = {str(k): v for k, v in (pr.get("_soft_reasons") or {}).items()}
        row["_refreshed"] = True
    save(rec)


_PLACEHOLDER = "unattempted"


def _merge_outcome(disk: Dict[str, Any], mine: Dict[str, Any]) -> Dict[str, Any]:
    """Per-PR field merge. Only fields the saving writer intentionally set this turn (`_touched`,
    recorded by set_outcome) are applied; every other field keeps the durable on-disk value, so a
    stale snapshot's carried `reconcile="failed: ..."` cannot overwrite a newer `reconcile="ok"`.
    Within touched fields, `merged` status is still never downgraded (GH-1074) and a concrete
    value beats the placeholder."""
    merged = {k: v for k, v in disk.items() if not k.startswith("_")}
    touched = set(mine.get("_touched") or [])
    for k in touched:
        v = mine.get(k)
        if k == "status":
            if disk.get("status") == "merged":
                continue
            if v and v != _PLACEHOLDER:
                merged[k] = v
            continue
        if v or v == 0:
            merged[k] = v
    merged.setdefault("status", _PLACEHOLDER)
    return merged


def _merge_records(disk: Dict[str, Any], mine: Dict[str, Any]) -> Dict[str, Any]:
    """GH-1140/#1072: merge the saving writer's record with the on-disk record so a stale snapshot
    cannot erase another writer's durable updates, while intentional fresh writes survive:
    - outcomes merge per PR at field level (concrete beats placeholder; merged never downgraded);
    - planned rows merge per PR — a row the current writer refreshed this turn (`_refreshed`,
      stripped before persisting) wins, otherwise the on-disk row wins; another writer's new rows
      are kept;
    - landed_order unions; verdict/sweep_inputs are intentional replacements, newest write time
      wins; issue identity fills from disk when the writer never saw it."""
    out = dict(mine)
    out["outcomes"] = dict(mine.get("outcomes") or {})
    for n, o in (disk.get("outcomes") or {}).items():
        if n not in out["outcomes"]:
            out["outcomes"][n] = o
    for n, o in list(out["outcomes"].items()):
        d = (disk.get("outcomes") or {}).get(n)
        if isinstance(d, dict):
            out["outcomes"][n] = _merge_outcome(d, o)

    disk_rows = {r.get("pr"): r for r in (disk.get("planned") or []) if isinstance(r, dict)}
    planned, seen = [], set()
    for r in (mine.get("planned") or []):
        d = disk_rows.get(r.get("pr"))
        if isinstance(d, dict) and not r.get("_refreshed"):
            planned.append(_strip_marks(d))
        else:
            planned.append(_strip_marks(r))
        seen.add(r.get("pr"))
    for pr, d in disk_rows.items():
        if pr not in seen:
            planned.append(_strip_marks(d))
    out["planned"] = planned

    # durable landing sequence is the base; only genuinely-new entries append — a stale subset
    # must not move retained landings ahead of it (the sweep range reads first/last, B order)
    order = [n for n in (disk.get("landed_order") or [])]
    for n in (mine.get("landed_order") or []):
        if n not in order:
            order.append(n)
    out["landed_order"] = order

    # verdict/sweep_inputs are intentional replacements by their owning mutators — an intent
    # marker decides, so a same-second stale snapshot cannot resurrect the replaced value
    if isinstance(disk.get("verdict"), dict) and not mine.get("_verdict_touched"):
        out["verdict"] = disk["verdict"]      # a carried (unmarked) verdict never beats durable
    if isinstance(disk.get("sweep_inputs"), dict) and not mine.get("_sweep_touched"):
        out["sweep_inputs"] = disk["sweep_inputs"]

    for k in ("issue", "issue_url"):
        if not out.get(k) and disk.get(k):
            out[k] = disk[k]
    return _strip_marks(out)


def save(rec: Dict[str, Any]) -> None:
    path = Path(rec["path"])
    with attempt_record.RecordLock(path):
        disk = None
        if path.exists():
            try:
                disk = json.loads(path.read_text())
            except (OSError, ValueError):
                disk = None
        if isinstance(disk, dict) and disk.get("repo") == rec.get("repo"):
            merged = _merge_records(disk, rec)
            rec.clear()
            rec.update(merged)  # long-lived holders (the driver's batch) see the merged state
        attempt_record.save(path, rec)


def refresh_row(rec: Dict[str, Any], pr: int, files: List[str]) -> None:
    """GH-1140/#1073 (in-run shape): a repair changed this PR's file set — refresh the captured
    row (marked as an intentional write for save()'s merge rule). Order/outcomes untouched."""
    if not files:
        return
    for row in rec["planned"]:
        if row["pr"] == pr:
            row["files"] = sorted(files)
            row["_refreshed"] = True
    save(rec)


def landed(rec: Dict[str, Any]) -> List[int]:
    """Landing order, plus any outcome that records a merge but is missing from it (GH-1074: a record
    saved without `landed_order` must never read as "nothing landed" and skip QA)."""
    order = list(rec.get("landed_order") or [])
    for n, o in (rec.get("outcomes") or {}).items():
        if (o.get("status") == "merged" or o.get("merge_oid")) and int(n) not in order:
            order.append(int(n))
    return order


def qa_pending(rec: Dict[str, Any]) -> bool:
    got = set(landed(rec))
    return bool(got) and got != set((rec.get("verdict") or {}).get("covers") or [])


def continuable(rec: Dict[str, Any]) -> bool:
    for row in rec["planned"]:
        o = rec["outcomes"].get(str(row["pr"]), {})
        status = o.get("status") or ""
        if status == "closed" or status.startswith("closed:") or (status == "merged" and o.get("reconcile") == "ok"):
            continue
        return True
    return False


def find_unfinished(primary: Path, origin: str, integration: str, prs: List[int],
                    need_qa: bool = False) -> Optional[Dict[str, Any]]:
    """Newest unfinished batch for this repo + integration branch. A non-empty `prs` must overlap
    its planned PRs; an empty one (OPEN-only discovery after everything landed) matches on repo +
    integration alone. `need_qa` restricts the match to batches whose QA is pending."""
    for rec in unfinished_batches(primary, origin, integration):
        if prs and not set(prs) & {row.get("pr") for row in rec.get("planned", [])}:
            continue
        if qa_pending(rec) if need_qa else (qa_pending(rec) or continuable(rec)):
            return rec
    return None


def unfinished_batches(primary: Path, origin: str, integration: str) -> List[Dict[str, Any]]:
    """All unfinished batches (QA pending or continuable) for this repo + integration, newest
    first. (GH-1154 follow-up: a resume-time recovery pass for unrecorded merges would iterate these.)"""
    d = _dir(primary, origin)
    out = []
    for path in sorted(d.glob("batch-*.json"), reverse=True):
        try:
            rec = json.loads(path.read_text())
        except (OSError, ValueError):
            continue
        if not isinstance(rec, dict) or rec.get("integration") != integration or rec.get("repo") != origin:
            continue
        rec["path"] = str(path)
        if qa_pending(rec) or continuable(rec):
            out.append(rec)
    return out


def set_outcome(rec: Dict[str, Any], pr: int, status: Optional[str] = None,
                merge_oid: Optional[str] = None, reconcile: Optional[str] = None) -> None:
    o = rec["outcomes"].setdefault(str(pr), {"status": "unattempted"})
    touched = set(o.get("_touched") or [])
    if status is not None and o.get("status") != "merged":  # GH-1074: a merge is never downgraded
        o["status"] = status
        touched.add("status")
    if merge_oid is not None:
        o["merge_oid"] = merge_oid
        touched.add("merge_oid")
    if reconcile is not None:
        o["reconcile"] = reconcile
        touched.add("reconcile")
    o["_touched"] = sorted(touched)  # GH-1140: these fields are intentional THIS turn — the
    if status == "merged" and pr not in rec.setdefault("landed_order", []):  # save merge applies
        rec["landed_order"].append(pr)                                       # them, carried values do not
    save(rec)


# --- the issue -----------------------------------------------------------------------------------

def _cell(text: str) -> str:
    return (text or "").replace("|", "\\|").replace("\n", " ")


def script_block(rec: Dict[str, Any]) -> str:
    lines = [START, "## Merge sequence",
             "_Planned order from Phase 4. This block is maintained by merge-cleanup; edits inside it are replaced._", "",
             "| # | PR | depends on | file overlap with | status | merge commit | reconcile |",
             "|---|----|------------|-------------------|--------|--------------|-----------|"]
    for row in rec["planned"]:
        o = rec["outcomes"].get(str(row["pr"]), {})
        hard = ", ".join(f"#{d}" for d in row["hard"]) or "—"
        soft = "; ".join(f"#{k}: {', '.join(v)}" for k, v in row["soft"].items()) or "—"
        oid = (o.get("merge_oid") or "")[:10] or "—"
        lines.append(f"| {row['pos']} | #{row['pr']} {_cell(row['title'])} | {hard} | {_cell(soft)} | "
                     f"{_cell(o.get('status', 'unattempted'))} | {oid} | {_cell(o.get('reconcile') or '—')} |")
    s = rec.get("sweep_inputs") or {}
    lines += ["", "## Sweep inputs"]
    if not s:
        lines.append("- No landings yet.")
    else:
        lines.append(f"- Merged range: `{s['range']}`")
        shared = s.get("shared_files") or {}
        lines.append("- Files touched by 2+ landed PRs: " + (
            "; ".join(f"`{f}` ({', '.join('#%d' % n for n in prs)})" for f, prs in shared.items()) or "none"))
        conflicts = s.get("conflict_sites") or {}
        lines.append("- Repaired conflict sites: " + (
            "; ".join(f"#{n}: {', '.join(fs)}" for n, fs in conflicts.items()) or "none"))
        lines.append(f"- Gate: `bash {s['gate']}` ({s['gate_reason']})")
        lines.append(f"- Run it in a throwaway clone: `{s['command']}`")
    v = rec.get("verdict")
    lines += ["", "## Sweep verdict"]
    if not landed(rec):
        lines.append("- Nothing landed; no verdict needed.")
    elif v and not qa_pending(rec):
        lines.append(f"- **{v['value']}** covering {', '.join('#%d' % n for n in v['covers'])} ({v['at']})")
        lines += ["", v["body"]]
    else:
        if v:
            lines.append(f"- Earlier verdict **{v['value']}** covered {', '.join('#%d' % n for n in v['covers'])}; "
                         "later landings need a new one.")
        lines.append("- **QA pending** — record one with `merge_cleanup.py --primary <path> --record-sweep <file>`.")
    lines.append(END)
    return "\n".join(lines) + "\n"


def _body_file(text: str) -> str:
    fd, path = tempfile.mkstemp(prefix="merge-batch-", suffix=".md")
    with os.fdopen(fd, "w") as fh:
        fh.write(text)
    return path


def create(rec: Dict[str, Any], gh: Callable, cwd: Path, slug: str) -> None:
    """Open the batch issue. Never raises: a failure is recorded in `issue_error`."""
    gh(["label", "create", LABEL, "--force", "--description", "merge-cleanup landing batch record"], cwd)
    prs = ", ".join(f"#{row['pr']}" for row in rec["planned"])
    title = f"Merge batch {time.strftime('%Y-%m-%d')} — {slug} — {prs}"
    body = f"Integration branch: `{rec['integration']}`\n\n{script_block(rec)}\n" + "".join(CALLER_SECTIONS)
    path = _body_file(body)
    try:
        r = gh(["issue", "create", "--title", title, "--label", LABEL, "--body-file", path], cwd)
    finally:
        os.unlink(path)
    url = (r.stdout or "").strip().splitlines()[-1:] if r.returncode == 0 else []
    num = url[0].rstrip("/").rsplit("/", 1)[-1] if url else ""
    if num.isdigit():
        rec["issue"], rec["issue_url"], rec["issue_error"] = int(num), url[0], ""
    else:
        rec["issue_error"] = f"issue create failed: {(r.stderr or r.stdout or 'no URL returned').strip()[:300]}"
    save(rec)


def update(rec: Dict[str, Any], gh: Callable, cwd: Path) -> None:
    """Replace only the script-owned block. A body that cannot be read, or has lost its markers,
    is left untouched and the reason recorded: caller-written text is never overwritten."""
    save(rec)
    if not rec.get("issue"):
        return
    n = str(rec["issue"])
    view = gh(["issue", "view", n, "--json", "body"], cwd)
    try:
        body = json.loads(view.stdout)["body"] if view.returncode == 0 else None
    except (ValueError, KeyError, TypeError):
        body = None
    if body is None:
        rec["issue_error"] = f"issue #{n} not updated: body unreadable ({(view.stderr or '').strip()[:200]})"
        return save(rec)
    i, j = body.find(START), body.find(END)
    if i < 0 or j < i:
        rec["issue_error"] = f"issue #{n} not updated: script markers missing"
        return save(rec)
    new_body = body[:i] + script_block(rec).rstrip("\n") + body[j + len(END):]
    if new_body == body:
        return
    path = _body_file(new_body)
    try:
        r = gh(["issue", "edit", n, "--body-file", path], cwd)
    finally:
        os.unlink(path)
    rec["issue_error"] = "" if r.returncode == 0 else f"issue #{n} edit failed: {(r.stderr or '').strip()[:200]}"
    save(rec)


# --- sweep inputs and verdict --------------------------------------------------------------------

def _gate(primary: Path, landings: List[Tuple[int, str]]) -> Tuple[str, str]:
    """The existing classifier (wave_reconcile.select_qualification_gate); any doubt → full gate."""
    try:
        from ledger_merge import tool_path
        src = tool_path(primary, "wave_reconcile.py")
        sys.path.insert(0, str(src.parent))
        try:
            spec = importlib.util.spec_from_file_location("wave_reconcile_gh1064", src)
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
        finally:
            sys.path.remove(str(src.parent))
        metas = [{"number": n, "mergeCommit": {"oid": oid}} for n, oid in landings]
        gate, _, reason = mod.select_qualification_gate(primary, metas, dict(os.environ))
        return gate, reason
    except Exception as exc:  # the classifier is advisory here: fall back to the full gate
        return FULL_GATE, f"classifier unavailable: {str(exc)[:160]}"


def finalize_sweep_inputs(rec: Dict[str, Any], primary: Path, origin: str) -> None:
    order = landed(rec)
    if not order:
        rec["sweep_inputs"] = {}
        return save(rec)
    oids = [(n, rec["outcomes"][str(n)].get("merge_oid") or "") for n in order]
    missing = [n for n, oid in oids if not oid]
    rng = f"unknown — merge commit missing for {', '.join('#%d' % n for n in missing)}" if missing \
        else f"{oids[0][1]}^1..{oids[-1][1]}"
    owners: Dict[str, List[int]] = {}
    for row in rec["planned"]:
        if row["pr"] in order:
            for f in row["files"]:
                owners.setdefault(f, []).append(row["pr"])
    conflicts = {}
    for n in order:
        p = attempt_record.record_path(primary, origin, n)
        files = []
        if p.exists():
            try:
                files = json.loads(p.read_text()).get("conflict_files") or []
            except (OSError, ValueError, AttributeError):
                files = []
        if files:
            conflicts[str(n)] = files
    gate, reason = _gate(primary, [x for x in oids if x[1]]) if not missing else (FULL_GATE, "merge commit missing")
    rec["_sweep_touched"] = True  # GH-1140: an intentional replacement, not a carried value
    rec["sweep_inputs"] = {
        "range": rng,
        "shared_files": {f: sorted(prs) for f, prs in sorted(owners.items()) if len(prs) > 1},
        "conflict_sites": conflicts, "gate": gate, "gate_reason": reason, "computed_at": _now(),
        "command": (f'T=$(mktemp -d) && git clone --no-local {shlex.quote(str(primary))} "$T" '
                    f'&& cd "$T" && bash {gate}'),
    }
    save(rec)


def record_verdict(rec: Dict[str, Any], text: str) -> Tuple[bool, str]:
    lines = (text or "").strip().splitlines()
    head = lines[0].strip().lower() if lines else ""
    value = head.split(":", 1)[1].strip() if head.startswith("verdict:") else ""
    body = "\n".join(lines[1:]).strip()
    if value not in VERDICTS:
        return False, "first line must be `verdict: clean|findings|deferred`"
    if not landed(rec):
        return False, "this batch has no landings to cover"
    if value == "clean" and not body:
        return False, "a clean verdict must name what ran"
    if value == "findings" and "- [ ]" not in body:
        return False, "a findings verdict needs at least one `- [ ]` item with its evidence"
    if value == "deferred" and not body:
        return False, "a deferred verdict needs a reason"
    rec["_verdict_touched"] = True  # GH-1140: an intentional replacement, not a carried value
    rec["verdict"] = {"value": value, "covers": sorted(landed(rec)), "body": body, "at": _now()}
    save(rec)
    return True, f"verdict {value} recorded for {', '.join('#%d' % n for n in rec['verdict']['covers'])}"
