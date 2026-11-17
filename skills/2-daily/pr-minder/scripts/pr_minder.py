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
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent


def _bundle(env: str, rel_repo: str, rel_flat: str) -> Path:
    """Locate another skill's scripts dir: env override (a file path) -> repo layout -> flat install."""
    if os.environ.get(env):
        return Path(os.environ[env]).resolve().parent
    for cand in (HERE.parents[2] / rel_repo, HERE.parents[1].parent / rel_flat):
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

    def sync_oids(self) -> frozenset:
        return frozenset(r.get("head_after") for r in self.rows
                         if r.get("phase") == "result" and r.get("action") == "update-branch"
                         and r.get("outcome") == "ok" and r.get("head_after"))

    def updates_since(self, pr: int, since: datetime | None) -> int:
        n = 0
        for r in self.rows:
            if (r.get("pr") == pr and r.get("phase") == "result" and r.get("action") == "update-branch"
                    and r.get("outcome") == "ok"):
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
    sync_oids = receipts.sync_oids()
    rows: dict[int, dict] = {}

    for pr in prs:
        n = pr["number"]
        row = {"pr": n, "title": pr.get("title", ""), "draft": bool(pr.get("isDraft")),
               "held": hold_reason(pr, held_by_engine), "pr_data": pr}
        ts, complete = pc.author_activity((activity or {}).get(n), sync_oids)
        row["unknown"] = not (complete and ts)
        row["since"] = ts
        row["age"] = None if row["unknown"] else pc._age_days(ts, now)
        state = str(pr.get("mergeStateStatus") or "").upper()
        row["conflicting"] = state == "DIRTY" or pr.get("mergeable") == "CONFLICTING"
        row["behind"] = state == "BEHIND"
        row["failing"] = failing_checks(pr)
        row["drift"] = drift(root, slug, pr) if not (row["held"] or row["unknown"]) else None
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
    """Precedence: held > unknown > conflicting > failing > behind > none. One branch mutation max."""
    pr = row["pr_data"]
    b = {"update_branch": False, "label": None, "comment": None, "why": ""}
    if row["held"] or row["inherited_hold"]:
        b["why"] = f"held: {row['held'] or row['inherited_hold']} (report only)"
        return b
    if row["unknown"]:
        b["why"] = "author history incomplete or unavailable (no writes)"
        return b
    rung = row["rung"]
    b["label"] = LABELS.get(rung) if rung in LABELS else None
    if rung == 4:
        b["why"], b["label"] = "retire candidate (report only; closing is a deferred decision)", "keep"
        return b
    if rung == 0:
        b["why"] = "fresh"
        return b
    since = row["since"].date().isoformat()
    lines = [MARKER, f"**pr-minder:** rung {rung} ({RUNG_NAMES[rung]}); no author activity since {since}."]
    if row["conflicting"]:
        files = row.get("conflict_files")
        lines.append("Conflicts with base in: " + (", ".join(f"`{f}`" for f in files) if files else "files unknown"))
        if rung == 2:
            lines.append(f"Repair in a disposable clone: `git fetch origin && git checkout {pr.get('headRefName')} "
                         f"&& git merge origin/{pr.get('baseRefName')}` then resolve, commit and push.")
        if rung == 3:
            lines.append("Option: re-cut — a fresh branch off base, cherry-picking this PR's own commits, "
                         "may be cheaper than resolving this much drift.")
        b["why"] = "conflicting"
    elif row["failing"]:
        lines += [f"Failing check: {c['name']} — {c['url'] or 'link unavailable'}" for c in row["failing"]]
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
        if rung <= 2 and not skip:
            b["update_branch"] = True
        if rung == 3:
            lines.append("Branch is behind base; not updating a branch idle this long. Keep, hold, or retire?")
        elif skip:
            lines.append(f"Branch is behind base; update-branch skipped: {skip}.")
        else:
            lines = None   # update-branch alone; no comment
    else:
        b["why"] = "idle, nothing to repair"
        lines = None if rung < 3 else lines + ["Keep, hold, or retire?"]
    if lines:
        lines.append("_Web-editor conflict fixes that kept GitHub's default merge message are not counted as activity._")
        b["comment"] = "\n\n".join(lines)
    return b


# ---------- apply ----------

def owned_comment(root: Path, slug: str, n: int):
    data = gh_json(["api", "--paginate", "--slurp", f"repos/{slug}/issues/{n}/comments"], root)
    flat = [c for page in (data or []) for c in (page if isinstance(page, list) else [page])]
    return next((c for c in flat if MARKER in (c.get("body") or "")), None)


def apply_row(root: Path, slug: str, row: dict, receipts: Receipts, held_by_engine_fn) -> list[str]:
    n, plan, pr = row["pr"], row["plan"], row["pr_data"]
    labels_now = {str(l.get("name", "")) for l in pr.get("labels") or [] if isinstance(l, dict)}
    want = plan["label"]
    ops = []
    if want != "keep":
        for lab in LABELS.values():
            if lab == want and lab not in labels_now:
                ops.append(("add-label", lab))
            elif lab != want and lab in labels_now:
                ops.append(("remove-label", lab))
    existing = None
    if plan["comment"]:
        existing = owned_comment(root, slug, n)
        if not existing or (existing.get("body") or "").strip() != plan["comment"].strip():
            ops.append(("comment", existing.get("id") if existing else None))
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
    else:
        fresh_full = {**pr, **fresh}
        h = hold_reason(fresh_full, held_by_engine_fn([fresh_full]))
        if h:
            reason = f"now held: {h}"
    if reason:
        receipts.write(pr=n, phase="result", action="bundle", outcome="aborted", reason=reason,
                       head_before=pr.get("headRefOid"), base=pr.get("baseRefName"), rung=row["rung"])
        return [f"aborted ({reason})"]

    done = []
    for op, arg in ops:
        receipts.write(pr=n, phase="intent", action=op, arg=arg, rung=row["rung"],
                       head_before=pr.get("headRefOid"), base=pr.get("baseRefName"))
        extra = {}
        if op == "update-branch":
            r = gh(["pr", "update-branch", str(n)], root)
            after = gh(["pr", "view", str(n), "--json", "headRefOid", "-q", ".headRefOid"], root).stdout.strip()
            ok = r.returncode == 0 and after and after != pr.get("headRefOid")
            extra["head_after"] = after
            outcome = "ok" if ok else ("uncertain" if r.returncode == 0 else "failed")
        elif op in ("add-label", "remove-label"):
            if op == "add-label":
                gh(["label", "create", arg, "--force", "--color", "BFD4F2",
                    "--description", "owned by pr-minder (GH-1498)"], root)
            r = gh(["pr", "edit", str(n), f"--{op}", arg], root)
            outcome = "ok" if r.returncode == 0 else "failed"
        else:
            body = ["-f", f"body={plan['comment']}"]
            r = (gh(["api", "-X", "PATCH", f"repos/{slug}/issues/comments/{arg}", *body], root) if arg
                 else gh(["api", f"repos/{slug}/issues/{n}/comments", *body], root))
            outcome = "ok" if r.returncode == 0 else "failed"
        receipts.write(pr=n, phase="result", action=op, arg=arg, outcome=outcome, rung=row["rung"],
                       head_before=pr.get("headRefOid"), base=pr.get("baseRefName"), **extra)
        done.append(f"{op}{'=' + str(arg) if arg and op != 'comment' else ''}:{outcome}")
        if op == "update-branch" and outcome != "ok" and plan["comment"] is None:
            break
    return done


# ---------- main ----------

def describe(row: dict) -> str:
    p = row["plan"]
    acts = [a for a, on in (("update-branch", p["update_branch"]), (f"label {p['label']}", p["label"] not in (None, "keep")),
                            ("comment", bool(p["comment"]))) if on]
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
    root = Path(args.repo_root).resolve()

    slug = pc.resolve_gh_slug(root, None)
    if not slug:
        print("pr-minder: cannot resolve this checkout's GitHub repo", file=sys.stderr)
        return 2
    prs = pc.get_open_prs(root)
    extra = {e["number"]: e for e in gh_json(["pr", "list", "--state", "open", "--limit", "300",
                                               "--json", EXTRA_FIELDS], root) or []}
    prs = [{**p, **extra.get(p["number"], {})} for p in prs]
    try:
        activity = pc.fetch_pr_activity(root, slug)
    except Exception as exc:
        print(f"pr-minder: author history unavailable ({str(exc).splitlines()[-1][:160]}); every PR is unknown",
              file=sys.stderr)
        activity = None
    receipts = Receipts(slug)
    rows = assess(root, slug, prs, activity, receipts, args)
    for row in rows:
        if row["conflicting"] and row["plan"]["comment"] is not None:
            row["conflict_files"] = conflict_files(root, row["pr_data"])
            row["plan"] = plan_bundle(row, receipts)
    focus = args.explain or args.pr
    if focus:
        rows = [r for r in rows if r["pr"] == focus]
        if not rows:
            print(f"pr-minder: #{focus} is not an open PR here", file=sys.stderr)
            return 2

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
    for r in rows:
        done = apply_row(root, slug, r, receipts, engine_holds)
        if done:
            print(f"#{r['pr']}: {'; '.join(done)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
