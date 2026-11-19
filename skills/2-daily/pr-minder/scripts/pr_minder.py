#!/usr/bin/env python3
"""pr_minder.py (GH-1498) — one manually invoked remediation pass over the current repo's open PRs.

Plan mode (default) prints what each PR needs and writes nothing to GitHub. --apply performs the
eligible bundle per PR: at most one `gh pr update-branch`, plus pr-minder's own label and its one
owned comment. It never merges, closes, rebases, force-pushes, retargets or touches the ledger.

Reuses, rather than re-implements: planner_core (open-PR fetch, engine holds, hold labels/regex, the
GH-1498 author-activity clock) and merge_cleanup (hold_label veto, refresh_pr_with_retry).
"""
from __future__ import annotations

import argparse
import json
import os
import shlex
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent


def _bundle(env: str, rel_repo: str, rel_flat: str) -> Path:
    """Locate another skill's scripts dir: env override (a file path) -> repo layout -> flat install."""
    if os.environ.get(env):
        return Path(os.environ[env]).resolve().parent
    # HERE is <skill>/scripts: parents[1] is the skills root in a flat install, parents[2] in the repo layout
    for cand in (HERE.parents[2] / rel_repo, HERE.parents[1] / rel_flat):
        if cand.is_dir():
            return cand
    sys.exit(f"pr-minder: cannot find {rel_flat}; set {env} to its script path")


sys.path.insert(0, str(_bundle("PLANNER_ENGINE", "3-weekly/weekly-planner/scripts", "weekly-planner/scripts")))
sys.path.insert(0, str(_bundle("MERGE_CLEANUP_DRIVER", "2-daily/merge-cleanup/scripts", "merge-cleanup/scripts")))
import planner_core as pc  # noqa: E402
import merge_cleanup as mc  # noqa: E402

MARKER = "<!-- pr-minder:v1 -->"
LABELS = {2: "pr-minder:stale", 3: "pr-minder:decide"}
RUNG_NAMES = ["fresh", "nudge", "repair", "decide", "retire"]
UPDATE_CAP = 2
FAILING = {"FAILURE", "ERROR", "TIMED_OUT", "CANCELLED", "ACTION_REQUIRED", "STARTUP_FAILURE"}
EXTRA_FIELDS = "number,mergeStateStatus,isCrossRepository,maintainerCanModify,headRefOid,createdAt"
SYNC_POLL = (5, 2.0)   # update-branch is async (202): re-read the head up to 5 times, 2s apart


def md_safe(text) -> str:
    """Text safe INSIDE a code span: no backtick breakout, no newlines. Callers render it via lit()."""
    return str(text or "").replace("`", "'").replace("\r", " ").replace("\n", " ").strip()


def lit(text) -> str:
    """PR- or CLI-controlled text as an inert inline code span: GitHub renders no links, autolinks,
    @-mentions or emphasis inside code, so this is the one rendering path for untrusted text."""
    t = md_safe(text)
    return f"`{t}`" if t else "`unknown`"


def safe_url(url) -> str:
    u = str(url or "")
    return u if u.startswith("https://") and not any(ch in u for ch in " \n\r`<>()[]") else ""


def gh(args: list[str], root: Path, stdin: str | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(["gh", *args], cwd=str(root), input=stdin, capture_output=True, text=True)


def gh_json(args: list[str], root: Path):
    r = gh(args, root)
    if r.returncode != 0:
        raise RuntimeError(f"gh {' '.join(args[:3])} failed: {r.stderr.strip()[-200:]}")
    return json.loads(r.stdout or "null")


# ---------- receipts (audit log; also feeds the update-branch cap and known-sync OIDs) ----------

class Receipts:
    def __init__(self, slug: str):
        base = os.environ.get("PR_MINDER_STATE") or str(Path.home() / ".local/state/pr-minder")
        self.dir = Path(base) / slug
        self.path = self.dir / "actions.jsonl"
        self.rows = []
        if self.path.is_file():
            for line in self.path.read_text().splitlines():
                try:
                    self.rows.append(json.loads(line))
                except ValueError:
                    pass

    def paused(self) -> bool:
        return (self.dir / "paused").exists()

    def write(self, **row) -> None:
        row = {"ts": datetime.now(timezone.utc).isoformat(timespec="seconds"), **row}
        self.dir.mkdir(parents=True, exist_ok=True)
        with self.path.open("a") as fh:
            fh.write(json.dumps(row, sort_keys=True) + "\n")
        self.rows.append(row)

    def owned_labels(self, pr: int) -> set:
        """pr-minder labels a receipt proves this tool added (and has not since removed) on this PR."""
        owned: set = set()
        for r in self.rows:
            if r.get("pr") == pr and r.get("phase") == "result" and r.get("outcome") == "ok":
                if r.get("action") == "add-label":
                    owned.add(r.get("arg"))
                elif r.get("action") == "remove-label":
                    owned.discard(r.get("arg"))
        return owned

    def updates_since(self, pr: int, since: datetime | None) -> int:
        n = 0
        for r in self.rows:
            if (r.get("pr") == pr and r.get("phase") == "result" and r.get("action") == "update-branch"
                    and r.get("outcome") in ("ok", "failed", "uncertain")):   # every attempt counts toward the cap
                ts = pc._parse_gh_time(r.get("ts"))
                if since is None or (ts and ts >= since):
                    n += 1
        return n


# ---------- classification ----------

def hold_reason(pr: dict, engine_held: dict) -> str | None:
    n = pr.get("number")
    if n in engine_held:
        return engine_held[n]
    labels = {str(l.get("name", "")).lower() for l in pr.get("labels") or [] if isinstance(l, dict)}
    if labels & pc.HOLD_LABELS:
        return f"label {sorted(labels & pc.HOLD_LABELS)[0]}"
    if pc.OWNER_HOLD_RE.search(pr.get("body") or ""):
        return "owner decision: hold (body)"
    veto = mc.hold_label(pr)
    return f"merge veto ({veto})" if veto else None


def engine_holds(prs: list[dict]) -> dict:
    seq = pc.detect_merge_sequence(prs)
    return {p.get("number"): p.get("hold_reason") or "held (engine)"
            for p in seq.get("evidence_carriers_or_held", [])}


def base_rung(age: float, draft: bool, stale: int, draft_stale: int) -> int:
    shift = (draft_stale - stale) if draft else 0
    floors = [stale + shift, 7 + shift, 14 + shift, 30 + shift]
    return sum(1 for f in floors if age >= f)


def failing_checks(pr: dict) -> list[dict]:
    out = []
    for c in pr.get("statusCheckRollup") or []:
        state = str(c.get("conclusion") or c.get("state") or "").upper()
        if state in FAILING:
            out.append({"name": c.get("name") or c.get("context") or "check",
                        "url": c.get("detailsUrl") or c.get("targetUrl") or ""})
    return out


def conflict_files(root: Path, pr: dict) -> list[str] | None:
    base, head = pr.get("baseRefName"), pr.get("headRefOid")
    if not base or not head:
        return None
    for args in (["fetch", "-q", "origin", base], ["fetch", "-q", "origin", f"pull/{pr['number']}/head"]):
        if subprocess.run(["git", *args], cwd=str(root), capture_output=True).returncode != 0:
            return None
    r = subprocess.run(["git", "merge-tree", "--write-tree", "--name-only", f"origin/{base}", head],
                       cwd=str(root), capture_output=True, text=True)
    if r.returncode not in (0, 1):
        return None
    lines = r.stdout.splitlines()[1:]
    return lines[:lines.index("")] if "" in lines else lines


def drift(root: Path, slug: str, pr: dict) -> int | None:
    try:
        d = gh_json(["api", f"repos/{slug}/compare/{pr['baseRefName']}...{pr['headRefOid']}"], root)
        return int(d.get("behind_by"))
    except Exception:
        return None


def assess(root: Path, slug: str, prs: list[dict], activity: dict | None, receipts: Receipts, args) -> list[dict]:
    now = datetime.now(timezone.utc)
    held_by_engine = engine_holds(prs)
    by_head = {p.get("headRefName"): p for p in prs if not p.get("isCrossRepository")}
    # Maintenance syncs are recognised by commit structure only (planner_core.is_maintenance_commit).
    # A receipt's head_after is NOT trusted as a sync OID: an author push between update-branch and the
    # head re-read would be misrecorded and then hidden from the clock (CodeRabbit #1510).
    sync_oids: frozenset = frozenset()
    rows: dict[int, dict] = {}

    for pr in prs:
        n = pr["number"]
        row = {"pr": n, "title": pr.get("title", ""), "draft": bool(pr.get("isDraft")),
               "held": hold_reason(pr, held_by_engine), "pr_data": pr}
        node = (activity or {}).get(n) or {}
        ts, complete = pc.author_activity(node or None, sync_oids)
        cm = node.get("comments") or {}
        row["has_owned_comment"] = any(pc.PR_MINDER_MARKER in (c.get("body") or "") and c.get("viewerDidAuthor", True)
                                       for c in cm.get("nodes") or [])
        # the history window shows only the newest 20 comments: an older owned comment may exist beyond it
        row["owned_comment_maybe"] = row["has_owned_comment"] or bool((cm.get("pageInfo") or {}).get("hasPreviousPage"))
        commits = (node.get("commits") or {})
        row["own_commits"] = [((c.get("commit") or {}).get("oid") or "")[:9] + " " +
                              ((c.get("commit") or {}).get("messageHeadline") or "")[:60]
                              for c in commits.get("nodes") or []
                              if not pc.is_maintenance_commit(c.get("commit") or {}, sync_oids)]
        row["own_commits_truncated"] = bool((commits.get("pageInfo") or {}).get("hasPreviousPage"))
        files = pr.get("files") or []
        row["diff_size"] = (f"{len(files)} files, +{sum(f.get('additions') or 0 for f in files)}"
                            f"/-{sum(f.get('deletions') or 0 for f in files)}") if files else None
        row["unknown"] = not (complete and ts)
        row["since"] = ts
        row["age"] = None if row["unknown"] else pc._age_days(ts, now)
        state = str(pr.get("mergeStateStatus") or "").upper()
        row["conflicting"] = state == "DIRTY" or pr.get("mergeable") == "CONFLICTING"
        row["failing"] = failing_checks(pr)
        row["drift"] = drift(root, slug, pr) if not (row["held"] or row["unknown"]) else None
        # GitHub reports CLEAN for a behind branch when no up-to-date rule applies: trust measured drift too
        row["behind"] = state == "BEHIND" or (not row["conflicting"] and (row["drift"] or 0) > 0)
        rung = 0 if row["age"] is None else base_rung(row["age"], row["draft"], args.stale_days, args.draft_stale_days)
        if 1 <= rung <= 2 and row["drift"] is not None and row["drift"] > args.drift_bump:
            rung += 1   # never from 0, never into 4
        row["own_rung"] = rung
        rows[n] = row

    def parent(n):
        base = rows[n]["pr_data"].get("baseRefName")
        p = by_head.get(base)
        return p["number"] if p and p["number"] != n else None

    def resolve(n, seen=()):
        row = rows[n]
        if "rung" in row:
            return row
        p = parent(n)
        row["rung"], row["inherited_hold"] = row["own_rung"], None
        if p is not None and p not in seen:
            pr_ = resolve(p, seen + (n,))
            if pr_["held"] or pr_["inherited_hold"]:
                row["inherited_hold"] = f"stacked on held #{p}"
            elif not pr_["unknown"]:
                row["rung"] = max(row["rung"], pr_["rung"])
        return row

    out = [resolve(n) for n in sorted(rows)]
    for row in out:
        row["plan"] = plan_bundle(row, receipts)
    return out


def plan_bundle(row: dict, receipts: Receipts) -> dict:
    """The bundle plus the owned-label removals apply_row will make, so plan output shows every write."""
    b = _plan_bundle(row, receipts)
    b["remove_labels"] = []
    if b.get("write"):
        on_pr = {str(lb.get("name", "")) for lb in row["pr_data"].get("labels") or [] if isinstance(lb, dict)}
        owned = receipts.owned_labels(row["pr"])
        b["remove_labels"] = [lab for lab in LABELS.values() if lab != b["label"] and lab in on_pr and lab in owned]
    return b


def _plan_bundle(row: dict, receipts: Receipts) -> dict:
    """Precedence: held > unknown > conflicting > failing > behind > none. One branch mutation max.
    `write` False means report only: apply_row makes no call of any kind for the row."""
    pr = row["pr_data"]
    b = {"write": True, "update_branch": False, "label": None, "comment": None, "fallback": None, "why": ""}
    if row["held"] or row["inherited_hold"]:
        b.update(write=False, why=f"held: {row['held'] or row['inherited_hold']} (report only)")
        return b
    if row["unknown"]:
        b.update(write=False, why="author history incomplete or unavailable (no writes)")
        return b
    rung = row["rung"]
    if rung == 4:
        b.update(write=False, why="retire candidate (report only; closing is a deferred decision)")
        return b
    b["label"] = LABELS.get(rung)
    since = row["since"].date().isoformat()
    head = [MARKER, f"**pr-minder:** rung {rung} ({RUNG_NAMES[rung]}); no author activity since {since}."]
    tail = ["_Web-editor conflict fixes that kept GitHub's default merge message are not counted as activity._"]
    if rung == 0:
        b["why"] = "fresh"
        if row.get("owned_comment_maybe"):   # a (possibly) managed PR whose author came back: reset the diagnosis
            b["comment"] = "\n\n".join([MARKER, f"**pr-minder:** rung 0 (fresh); author activity on {since}. "
                                          "No action needed."])
            b["reset_only"] = True           # PATCH an existing owned comment; never create one
        return b
    lines = list(head)
    drift_txt = (f"Base has moved {row['drift']} commits since this branch's merge base."
                 if row.get("drift") is not None else "Base drift unknown.")
    if row["conflicting"]:
        files = row.get("conflict_files")
        lines.append("Conflicts with base in: " + (", ".join(lit(f) for f in files) if files else "files unknown")
                     + f". {drift_txt}")
        if rung == 2:
            head, base = str(pr.get("headRefName") or ""), str(pr.get("baseRefName") or "")
            if any(ch in head + base for ch in "`\n\r"):
                lines.append("Repair: merge the base branch into this branch in a disposable clone "
                             "(branch name not rendered: it contains characters unsafe in a comment).")
            else:
                lines.append(f"Repair in a disposable clone: `git fetch origin && git checkout {shlex.quote(head)} "
                             f"&& git merge {shlex.quote('origin/' + base)}` then resolve, commit and push.")
        if rung == 3:
            own = row.get("own_commits") or []
            size = row.get("diff_size")
            lines.append("Option: re-cut — a fresh branch off base with this PR's own commits cherry-picked"
                         + (f" ({size})" if size else "") + ", instead of resolving this drift. Commits: "
                         + (", ".join(lit(c) for c in own) if own else "unknown")
                         + (" (newest 10 shown)" if row.get("own_commits_truncated") else "") + ".")
        b["why"] = "conflicting"
    elif row["failing"]:
        lines += [f"Failing check: {lit(c['name'])} — {safe_url(c['url']) or 'link unavailable'}"
                  for c in row["failing"]]
        b["why"] = "checks failing"
    elif row["behind"]:
        b["why"] = "behind base"
        skip = None
        if row["draft"]:
            skip = "draft"
        elif pr.get("isCrossRepository") and not pr.get("maintainerCanModify"):
            skip = "fork without maintainer edits"
        elif receipts.updates_since(row["pr"], row["since"]) >= UPDATE_CAP:
            skip = f"update-branch cap ({UPDATE_CAP}) reached this stale episode"
        if rung == 3:
            lines.append(f"Branch is behind base; not updating a branch idle this long. {drift_txt} "
                         "Keep, hold, or retire?")
        elif skip:
            lines.append(f"Branch is behind base; update-branch skipped: {skip}. {drift_txt}")
        else:
            b["update_branch"] = True
            # used only if update-branch fails: the diagnosis still gets posted (no retry)
            b["fallback"] = "\n\n".join(head + [f"Branch is behind base; update-branch failed: {{error}}. {drift_txt}"]
                                          + tail)
            lines = None
    else:
        b["why"] = "idle, nothing to repair"
        lines = None if rung < 3 else lines + ["Keep, hold, or retire?"]
    if lines:
        b["comment"] = "\n\n".join(lines + tail)
    return b


# ---------- apply ----------

_VIEWER: dict = {}


def viewer_login(root: Path) -> str:
    if "login" not in _VIEWER:
        r = gh(["api", "user", "-q", ".login"], root)
        if r.returncode != 0 or not r.stdout.strip():
            raise RuntimeError(f"cannot resolve the operator's GitHub login: {r.stderr.strip()[-160:]}")
        _VIEWER["login"] = r.stdout.strip()
    return _VIEWER["login"]


def owned_comment(root: Path, slug: str, n: int):
    """The marker comment written by THIS operator. The marker is public, so text alone is not ownership."""
    me = viewer_login(root).lower()
    data = gh_json(["api", "--paginate", "--slurp", f"repos/{slug}/issues/{n}/comments"], root)
    flat = [c for page in (data or []) for c in (page if isinstance(page, list) else [page])]
    return next((c for c in flat if MARKER in (c.get("body") or "")
                 and str((c.get("user") or {}).get("login") or "").lower() == me), None)


def apply_row(root: Path, slug: str, row: dict, receipts: Receipts, held_by_engine_fn) -> list[str]:
    n, plan, pr = row["pr"], row["plan"], row["pr_data"]
    if not plan.get("write"):
        return []                      # report only: held, stacked on held, unknown history, rung 4
    labels_now = {str(lb.get("name", "")) for lb in pr.get("labels") or [] if isinstance(lb, dict)}
    want = plan["label"]
    ops = []
    if want and want not in labels_now:
        ops.append(("add-label", want))
    ops += [("remove-label", lab) for lab in plan.get("remove_labels", [])]   # receipt-proven ownership only
    existing = owned_comment(root, slug, n) if (plan["comment"] or plan["fallback"]) else None

    def comment_op(body):
        if existing and (existing.get("body") or "").strip() == body.strip():
            return None
        if plan.get("reset_only") and not existing:
            return None                  # never-managed fresh PR: stay silent
        return ("comment", existing.get("id") if existing else None, body)

    if plan["comment"] and comment_op(plan["comment"]):
        ops.append(comment_op(plan["comment"]))
    if plan["update_branch"]:
        ops.insert(0, ("update-branch", None))
    if not ops:
        return []

    fresh = mc.refresh_pr_with_retry(n, root)
    reason = None
    if fresh.get("error"):
        reason = fresh["error"]
    elif fresh.get("state") != "OPEN":
        reason = f"state {fresh.get('state')}"
    elif fresh.get("headRefOid") != pr.get("headRefOid"):
        reason = "head SHA changed"
    elif fresh.get("baseRefName") != pr.get("baseRefName"):
        reason = "base changed"
    elif bool(fresh.get("isDraft")) != bool(pr.get("isDraft")):
        reason = "draft status changed"
    else:
        fresh_full = {**pr, **fresh}
        h = hold_reason(fresh_full, held_by_engine_fn([fresh_full]))
        if h:
            reason = f"now held: {h}"
    if reason:
        receipts.write(pr=n, phase="result", action="bundle", outcome="aborted", reason=reason,
                       head_before=pr.get("headRefOid"), base=pr.get("baseRefName"), rung=row["rung"])
        return [f"aborted ({reason})"]
    fresh_labels = {str(lb.get("name", "")) for lb in fresh.get("labels") or [] if isinstance(lb, dict)}
    ops = [op for op in ops if op[0] != "add-label" or op[1] not in fresh_labels]   # someone else added it
    done = []

    def run(op, arg, call, **extra_intent):
        receipts.write(pr=n, phase="intent", action=op, arg=arg, rung=row["rung"],
                       head_before=pr.get("headRefOid"), base=pr.get("baseRefName"), **extra_intent)
        outcome, extra = call()
        receipts.write(pr=n, phase="result", action=op, arg=arg, outcome=outcome, rung=row["rung"],
                       head_before=pr.get("headRefOid"), base=pr.get("baseRefName"), **extra)
        done.append(f"{op}{'=' + str(arg) if arg and op != 'comment' else ''}:{outcome}")
        return outcome, extra

    i = 0
    while i < len(ops):
        op = ops[i]
        if op[0] == "update-branch":
            def sync():
                r = gh(["pr", "update-branch", str(n)], root)
                after = ""
                for attempt in range(SYNC_POLL[0] if r.returncode == 0 else 1):
                    v = gh(["pr", "view", str(n), "--json", "headRefOid", "-q", ".headRefOid"], root)
                    after = v.stdout.strip() if v.returncode == 0 else ""
                    if r.returncode != 0 or (after and after != pr.get("headRefOid")):
                        break
                    time.sleep(SYNC_POLL[1])
                if r.returncode != 0:
                    return "failed", {"head_after": after, "error": (r.stderr.strip() or "no diagnostic")[-200:]}
                if not after:
                    return "uncertain", {"head_after": "", "error": "head re-read failed"}
                return ("ok" if after != pr.get("headRefOid") else "uncertain"), {"head_after": after}
            outcome, extra = run("update-branch", None, sync)
            if outcome != "ok" and plan["fallback"]:   # post the diagnosis instead; never retry the mutation
                c = comment_op(plan["fallback"].replace("{error}", lit(extra.get("error") or outcome)))
                if c:
                    ops.append(c)
        elif op[0] == "add-label":
            lab = op[1]
            created, _ = run("label-create", lab, lambda: (
                "ok" if gh(["label", "create", lab, "--force", "--color", "BFD4F2",
                            "--description", "owned by pr-minder (GH-1498)"], root).returncode == 0 else "failed", {}))
            if created == "ok":
                run("add-label", lab, lambda: (
                    "ok" if gh(["pr", "edit", str(n), "--add-label", lab], root).returncode == 0 else "failed", {}))
        elif op[0] == "remove-label":
            lab = op[1]
            run("remove-label", lab, lambda: (
                "ok" if gh(["pr", "edit", str(n), "--remove-label", lab], root).returncode == 0 else "failed", {}))
        else:
            _, cid, body = op
            args = (["api", "-X", "PATCH", f"repos/{slug}/issues/comments/{cid}", "-f", f"body={body}"] if cid
                    else ["api", f"repos/{slug}/issues/{n}/comments", "-f", f"body={body}"])
            run("comment", cid, lambda: ("ok" if gh(args, root).returncode == 0 else "failed", {}))
        i += 1
    return done


# ---------- main ----------

def describe(row: dict) -> str:
    p = row["plan"]
    acts = [a for a, on in (("update-branch", p["update_branch"]), (f"label {p['label']}", p["write"] and p["label"] is not None),
                            ("comment", bool(p["comment"]))) if on] + [f"remove label {lab}" for lab in p.get("remove_labels", [])]
    age = "?" if row["age"] is None else f"{row['age']:.0f}d"
    return (f"#{row['pr']:<5} rung {row.get('rung', 0)} {RUNG_NAMES[row.get('rung', 0)]:<7} age {age:<5} "
            f"drift {row['drift'] if row['drift'] is not None else '-':<4} {p['why']}"
            + (f"  -> {', '.join(acts)}" if acts else ""))


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--apply", action="store_true", help="perform the eligible writes (default: plan only)")
    ap.add_argument("--pr", type=int, help="one PR (its stack is still walked for inheritance)")
    ap.add_argument("--explain", type=int, metavar="PR", help="print one PR's inputs, rung and chosen action")
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--stale-days", type=int, default=3)
    ap.add_argument("--draft-stale-days", type=int, default=7)
    ap.add_argument("--drift-bump", type=int, default=30)
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args(argv)
    if not (1 <= args.stale_days < 7 and args.draft_stale_days >= args.stale_days and args.drift_bump >= 0):
        ap.error("need 1 <= --stale-days < 7 (the repair rung starts at 7d), --draft-stale-days >= --stale-days, "
                 "and --drift-bump >= 0")
    root = Path(args.repo_root).resolve()

    slug = pc.resolve_gh_slug(root, None)
    if not slug:
        print("pr-minder: cannot resolve this checkout's GitHub repo", file=sys.stderr)
        return 2
    try:
        prs = pc.get_open_prs(root)
        extra = {e["number"]: e for e in gh_json(["pr", "list", "--state", "open", "--limit", "300",
                                                   "--json", EXTRA_FIELDS], root) or []}
    except Exception as exc:   # e.g. GitHub rate limit: report it plainly, write nothing
        print(f"pr-minder: open-PR read failed, nothing done: {str(exc).splitlines()[-1][:200]}", file=sys.stderr)
        return 2
    prs = [{**p, **extra.get(p["number"], {})} for p in prs]
    try:
        activity = pc.fetch_pr_activity(root, slug)
    except Exception as exc:
        print(f"pr-minder: author history unavailable ({str(exc).splitlines()[-1][:160]}); every PR is unknown",
              file=sys.stderr)
        activity = None
    receipts = Receipts(slug)
    rows = assess(root, slug, prs, activity, receipts, args)   # all PRs: stack inheritance needs them
    focus = args.explain or args.pr
    if focus:   # narrow BEFORE the conflict lookup, which fetches into this checkout
        rows = [r for r in rows if r["pr"] == focus]
        if not rows:
            print(f"pr-minder: #{focus} is not an open PR here", file=sys.stderr)
            return 2
    for row in rows:
        if row["conflicting"] and row["plan"]["comment"] is not None:
            row["conflict_files"] = conflict_files(root, row["pr_data"])
            row["plan"] = plan_bundle(row, receipts)

    if args.explain:
        r = rows[0]
        print(json.dumps({k: (v.isoformat() if isinstance(v, datetime) else v) for k, v in r.items()
                          if k != "pr_data"}, indent=2, default=str))
        return 0
    if args.json:
        print(json.dumps([{k: (v.isoformat() if isinstance(v, datetime) else v) for k, v in r.items()
                           if k != "pr_data"} for r in rows], indent=2, default=str))
    else:
        print(f"pr-minder · {slug} · {'APPLY' if args.apply else 'plan only (no writes)'}")
        for r in rows:
            print(describe(r))
    if not args.apply:
        return 0
    if receipts.paused():
        print(f"pr-minder: paused ({receipts.dir / 'paused'} exists); no writes", file=sys.stderr)
        return 0
    problems = 0
    for r in rows:
        try:
            done = apply_row(root, slug, r, receipts, engine_holds)
        except Exception as exc:   # one PR's failure must not end the pass
            import traceback
            traceback.print_exc(file=sys.stderr)
            receipts.write(pr=r["pr"], phase="result", action="bundle", outcome="failed",
                           reason=f"{type(exc).__name__}: {str(exc)[:200]}", rung=r.get("rung"))
            done = [f"failed ({type(exc).__name__})"]
        if done:
            print(f"#{r['pr']}: {'; '.join(done)}")
            problems += sum(1 for d in done if any(k in d for k in ("failed", "uncertain", "aborted")))
    if problems:
        print(f"pr-minder: {problems} write(s) failed, uncertain or aborted; see receipts", file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
