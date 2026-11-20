#!/usr/bin/env python3
"""build_queue.py (GH-1527) — print a kickstart run record's Authority, Queue and Needs-operator
sections from live state, so a long run starts from one command instead of a hand-built list.

Inputs (reused, never re-classified):
  * `pr_minder.py --json --no-conflict-files` owns PR state: draft, held, conflicting, behind,
    failing. The flag skips pr_minder's conflicting-file lookup, which fetches into the checkout.
  * one `gh pr list` call adds what pr_minder's JSON omits: author, title/body links, raw mergeable.
  * `gh issue list` supplies open issues created inside the window.

Ordering is a CLOSED list, first match wins (mirrored in skills/1-hourly/kickstart/SKILL.md):

  PRs:    1 --other-session -> Needs-operator   2 --needs-operator -> Needs-operator
          3 its closing keywords name a parked issue (issue rules 1-2) -> Needs-operator
          4 held / inherited hold -> Needs-operator   5 not --owner's -> Needs-operator
          6 draft -> D (a draft stays D even when it also conflicts)   7 conflicting or failing,
          or raw mergeable CONFLICTING -> B   8 behind, or raw mergeable not MERGEABLE -> C
          9 otherwise (confirmed MERGEABLE) -> A
  Issues: 1 --other-session -> Needs-operator   2 latest --owner "Operator decision: hold" comment
          -> Needs-operator   3 --needs-operator or "decide/decision" title unless released by a
          latest --owner comment whose first non-empty line starts with "Operator decision"
          (proceed) or "Operator decision: close" (close) -> Needs-operator
          4 label status:held, body HELD: marker, Blocked by #N, or open/active-gating after #N
          across all issue types (fail-closed; not overridden by an operator decision comment)
          -> Needs-operator   5 closed by an open own queued PR -> folded into that PR's line
          6 released "Operator decision: close" -> CLOSE (verify on development, then close)
          7 merge-batch label or "Merge batch / merge inventory / <skill> sweep <date>" title -> G
          8 "refactor" title -> H (gated on the first "after #N")   9 documentation label or a
          *.md in the title -> F   10 bug label or a code/config file in the title -> E
          11 released "Operator decision" (proceed) not matched by 7-10 -> DECIDED (never falls
          into unclassified)   12 Arc/Plan/Research/Spike/Umbrella/Radar/Daily goals title ->
          Not queued   13 anything else -> Needs-operator (unclassified; the operator picks scope)

  Queue order: A -> B -> C -> D -> E -> DECIDED -> F -> G -> CLOSE -> H -> final QA; ascending number inside each.

Replay: --prs-json/--pr-meta-json/--issues-json read saved inputs; with the same files, --as-of,
--owner, --other-session, --needs-operator and --since-days, the output is byte-identical.
Read-only: writes nothing but --out.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import subprocess
import sys
from pathlib import Path

AUTHORITY = """## Authority granted (one grant, covers the whole run)
- Merge PRs authored by {owner} when ALL hold: development is merged in where needed; the classified
  gate is green on that exact SHA; independent cross-model QA has approved the final head; hosted
  checks are green; and EITHER CodeRabbit has reviewed the current head with no open Major OR 30 min
  have passed since a "@coderabbitai review" request on the current head with no review. Re-read
  reviews immediately before the merge. Record the timeout path as "advisory not received;
  predeclared waiver used", never as reviewed or approved. Any Major that CodeRabbit posted blocks
  until it is fixed or answered.
- Close issues whose acceptance criteria are verified on development, with a comment that cites
  the commit.
- Post status comments on PRs and issues.
- Decision defaults (KS-11, fail-closed):
  - Round cap (KS-11a): land only with an independent reviewer's explicit approval covering the final
    head. Minor/nit findings may be deferred only when the reviewer explicitly tagged them Minor/nit
    and accepted the deferral; otherwise park and continue independent work. Never auto-accept on
    gate, hook, containment, schema, kernel, or Costly surfaces (utils/ci-route.sh full_required). A
    PR landed with accepted Minor/nit deferrals states so explicitly and never claims Approved beyond
    what the reviewer stated.
  - Conflict hubs (KS-11b): conflict hubs reported by the merge-cleanup forecast route to a separate
    recorded batch.
  - Operator decisions (KS-11c / KS-02): release holds only when authored by {owner}, applicable,
    and not superseded.
- Provider quota fallback: when the reviewer seat's stop reason verbatim states quota, switch that
  turn's reviewer to agy and record the actual model name; if both providers are capped, park. Never
  infer quota from a round cap or generic failure.
- Flywheel per-PR approval: once granted below, this launch grant satisfies Flywheel's per-PR merge
  approval step (skills/2-daily/flywheel/SKILL.md:109-120) for {owner} PRs within these bounds;
  exact full-SHA --prs N@<approved-full-sha> pin verification before --execute still applies.
- Out of scope, so the run stops and asks: merging anyone else's PR, deploys, installed-skill updates,
  ledger rewrites outside the reconcile, anything owned by another session{other}.
- Status: NOT YET GRANTED. The parent records the operator's grant here before dispatch."""

DECISION = re.compile(r"\bdecid(?:e|ing)\b|\bdecision\b", re.I)
BATCH = re.compile(r"^merge batch|merge inventory|^\S+ sweep \d{4}-\d{2}-\d{2}", re.I)
REFACTOR = re.compile(r"^refactor\b", re.I)
AFTER = re.compile(r"\bafter\s+(?:PR\s+)?#(\d+)", re.I)
MD_FILE = re.compile(r"[\w./-]+\.md\b")
CODE_FILE = re.compile(r"[\w./-]+\.(?:py|sh|txt|json|ya?ml)\b")
OUT_OF_SCOPE = re.compile(r"^(?:arc:|plan:|architectural plan|research:|spike:|umbrella:|radar|daily goals)", re.I)
CLOSES = re.compile(r"\b(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)\s+(?:([\w.-]+/[\w.-]+))?#(\d+)", re.I)
TITLE_GH = re.compile(r"\bGH-(\d+)\b")
FENCED_CODE = re.compile(r"```.*?```", re.S)
REF_BACKTICK = re.compile(r"`((?:PR\s+)?#\d+)`", re.I)
CHECKED_LINE = re.compile(r"^\s*(?:[-*]|\d+\.)\s*\[[xX]\]")
ATOMIC_REF = re.compile(r"(?<![\w/-])(?:([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+))?#(\d+)\b")
INLINE_BACKTICK = re.compile(r"`[^`\n]*`")
HELD_LINE = re.compile(r"^\s*(?:[-*]\s*)?(?:\*\*)?HELD:(?:\*\*)?", re.I | re.M)
BLOCKED_BY = re.compile(r"\bblocked\s+by\s+(?:PR\s+)?#(\d+)\b", re.I)
AFTER_ACTIVE = re.compile(
    r"(?:^\s*(?:[-*]\s*)?(?:\*\*)?(?:gated\s+on|depends\s+on|wait\s+for|after)\s+(?:PR\s+)?#(\d+)\b"
    r"(?!\s*(?:'s|\u2019s|passed\b|merged\b|landed\b|completed\b|closed\b)))"
    r"|\bafter\s+(?:PR\s+)?#(\d+)\s+(?:lands?|merges?|is\s+merged|completes?|closes?)\b",
    re.I | re.M,
)
OP_DECISION_CLOSE = re.compile(r"^operator\s+decision\s*:\s*close\b", re.I)
OP_DECISION_HOLD = re.compile(r"^operator\s+decision\s*:\s*hold\b", re.I)
OP_DECISION_PROCEED = re.compile(r"^operator\s+decision\b", re.I)


def run_json(argv: list[str], cwd: Path):
    out = subprocess.run(argv, cwd=cwd, capture_output=True, text=True)
    if out.returncode:
        sys.exit(f"build_queue: {' '.join(argv[:3])} failed: {out.stderr.strip()[-300:]}")
    return json.loads(out.stdout or "null")


def origin_slug(root: Path) -> str:
    url = subprocess.run(["git", "-C", str(root), "remote", "get-url", "origin"],
                         capture_output=True, text=True).stdout.strip()
    m = re.search(r"[:/]([\w.-]+/[\w.-]+?)(?:\.git)?$", url)
    if not m:
        sys.exit(f"build_queue: cannot read OWNER/NAME from origin {url!r}; pass --repo-slug")
    return m.group(1)


def load(path: str | None, live):
    return json.loads(Path(path).read_text()) if path else live()


def numbers(csv: str) -> set[int]:
    return {int(x.lstrip("#")) for x in csv.replace(" ", "").split(",") if x}


def fmt(nums) -> str:
    return ", ".join(f"#{n}" for n in sorted(nums))


def closing_refs(body: str, slug: str) -> set[int]:
    """Issues GitHub will close on merge: closing keywords, bare or naming this repository only."""
    return {int(num) for repo, num in CLOSES.findall(body or "") if not repo or repo.lower() == slug.lower()}


def _sanitize_body(body: str) -> str:
    """Strip fenced blocks and wholly quoted inline spans while unwrapping backticked #N refs."""
    cleaned = FENCED_CODE.sub("", body or "")
    cleaned = REF_BACKTICK.sub(r"\1", cleaned)
    return INLINE_BACKTICK.sub("", cleaned)


def operator_decision(issue: dict, owner: str) -> str | None:
    """Return latest --owner first-line Operator decision ('proceed'|'close'|'hold') or None."""
    comments = issue.get("comments") or []
    ordered = sorted(
        enumerate(comments),
        key=lambda pair: ((pair[1].get("createdAt") or ""), pair[0]),
    )
    decision: str | None = None
    for _, comment in ordered:
        author = (comment.get("author") or {}).get("login")
        if author != owner:
            continue
        first_line = ""
        for raw_line in (comment.get("body") or "").splitlines():
            stripped = raw_line.strip()
            if stripped:
                first_line = stripped
                break
        if not first_line:
            continue
        if OP_DECISION_CLOSE.match(first_line):
            decision = "close"
        elif OP_DECISION_HOLD.match(first_line):
            decision = "hold"
        elif OP_DECISION_PROCEED.match(first_line):
            decision = "proceed"
    return decision


def issue_hold_reason(issue: dict, open_refs: set[int]) -> str | None:
    """U15 fail-closed label/body hold detection across all issue types."""
    labels = {(lab.get("name") or "").lower() for lab in issue.get("labels") or []}
    if "status:held" in labels:
        return "label status:held"
    cleaned = _sanitize_body(issue.get("body") or "")
    if HELD_LINE.search(cleaned):
        return "body HELD: marker"
    blocked = BLOCKED_BY.search(cleaned)
    if blocked:
        return f"blocked by #{blocked.group(1)}"
    active_after = AFTER_ACTIVE.search(cleaned)
    if active_after:
        ref = active_after.group(1) or active_after.group(2)
        return f"after #{ref}"
    for m in AFTER.finditer(cleaned):
        ref_num = int(m.group(1))
        if ref_num in open_refs:
            return f"after #{ref_num}"
    return None


def parked_issues(issues, other, decide, owner: str = "", open_refs: set[int] | None = None) -> set[int]:
    """Issues parked by issue rules 1-4 (any creation date): a queued PR must not close them."""
    refs = open_refs or set()
    by_num = {i["number"]: i for i in issues}
    parked: set[int] = set(other)
    for num in decide:
        it = by_num.get(num)
        dec = operator_decision(it, owner) if (it and owner) else None
        if dec not in ("proceed", "close"):
            parked.add(num)
    for it in issues:
        num = it["number"]
        dec = operator_decision(it, owner) if owner else None
        if dec == "hold":
            parked.add(num)
        elif DECISION.search(it["title"]) and dec not in ("proceed", "close"):
            parked.add(num)
        elif issue_hold_reason(it, refs) is not None:
            parked.add(num)
    return parked


def classify_prs(rows, meta, owner, other, decide, parked, slug):
    """PR rules 1-9. Returns (buckets {A..D: [(n, title, folds)]}, needs [(n, reason)])."""
    buckets: dict[str, list] = {k: [] for k in "ABCD"}
    needs = []
    for row in sorted(rows, key=lambda r: r["pr"]):
        n = row["pr"]
        m = meta.get(n)
        if m is None:
            sys.exit(f"build_queue: PR #{n} is in pr_minder output but not in the PR metadata")
        title = row["title"]
        closing = closing_refs(m.get("body") or "", slug)
        closes = sorted(closing | {int(x) for x in TITLE_GH.findall(m.get("title") or title)})
        if n in other:
            needs.append((n, f"PR #{n} {title}: owned by another session; remind only"))
        elif n in decide:
            needs.append((n, f"PR #{n} {title}: operator decision"))
        elif closing & parked:
            needs.append((n, f"PR #{n} {title}: merging it would close parked {fmt(closing & parked)}"))
        elif row["held"] or row.get("inherited_hold"):
            needs.append((n, f"PR #{n} {title}: held ({row['held'] or row['inherited_hold']})"))
        elif ((m.get("author") or {}).get("login")) != owner:
            needs.append((n, f"PR #{n} {title}: authored by {(m.get('author') or {}).get('login')}, not {owner}"))
        elif row["draft"]:
            buckets["D"].append((n, title, closes))
        elif row["conflicting"] or row["failing"] or m.get("mergeable") == "CONFLICTING":
            buckets["B"].append((n, title, closes))
        elif row["behind"] or m.get("mergeable") != "MERGEABLE":
            buckets["C"].append((n, title, closes))   # UNKNOWN, or anything not confirmed MERGEABLE
        else:
            buckets["A"].append((n, title, closes))
    return buckets, needs


def parse_daily_goals_refs(body: str, slug: str, self_num: int) -> list[int]:
    """Parse unchecked local #N and same-repo slug#N references atomically.
    Foreign-repo references (other/repo#123) are consumed atomically and never fall back to #123.
    """
    clean = _sanitize_body(body or "")
    seen: set[int] = set()
    ordered: list[int] = []
    slug_l = slug.lower()
    for line in clean.splitlines():
        if CHECKED_LINE.match(line):
            continue
        for m in ATOMIC_REF.finditer(line):
            repo_qual, num_s = m.group(1), m.group(2)
            if repo_qual and repo_qual.lower() != slug_l:
                continue
            n = int(num_s)
            if n == self_num or n in seen:
                continue
            seen.add(n)
            ordered.append(n)
    return ordered


def _gh_view_issue(num: int, root: Path):
    p = subprocess.run(
        ["gh", "issue", "view", str(num), "--json", "number,title,labels,body,createdAt,comments,state"],
        cwd=root, capture_output=True, text=True,
    )
    if p.returncode != 0:
        return None
    return json.loads(p.stdout or "null")


def classify_issues(issues, cutoff, other, decide, folded, owner: str = "", open_refs: set[int] | None = None, include_ids: set[int] | None = None):
    """Issue rules 1-13. Returns (buckets {E,F,G,H,CLOSE,DECIDED}, needs, not_queued)."""
    refs = open_refs or set()
    buckets: dict[str, list] = {k: [] for k in ("E", "DECIDED", "F", "G", "CLOSE", "H")}
    needs, skipped = [], []
    for it in sorted(issues, key=lambda i: i["number"]):
        n, title = it["number"], it["title"]
        if it["createdAt"][:10] < cutoff and (include_ids is None or n not in include_ids):
            continue
        labels = {lab["name"] for lab in it.get("labels") or []}
        dec = operator_decision(it, owner) if owner else None
        hold = issue_hold_reason(it, refs)
        if n in other:
            needs.append((n, f"#{n} {title}: owned by another session; remind only"))
        elif dec == "hold":
            needs.append((n, f"#{n} {title}: operator decision: hold"))
        elif (n in decide or DECISION.search(title)) and dec not in ("proceed", "close"):
            needs.append((n, f"#{n} {title}: operator decision"))
        elif hold is not None:
            needs.append((n, f"#{n} {title}: held ({hold})"))
        elif n in folded:
            continue
        elif dec == "close":
            buckets["CLOSE"].append((n, title, None))
        elif "merge-batch" in labels or BATCH.search(title):
            buckets["G"].append((n, title, None))
        elif REFACTOR.search(title):
            after = AFTER.search(title) or AFTER.search(it.get("body") or "")
            buckets["H"].append((n, title, int(after.group(1)) if after else None))
        elif "documentation" in labels or MD_FILE.search(title):
            buckets["F"].append((n, title, None))
        elif "bug" in labels or CODE_FILE.search(title):
            buckets["E"].append((n, title, None))
        elif dec == "proceed":
            buckets["DECIDED"].append((n, title, None))
        elif OUT_OF_SCOPE.search(title):
            skipped.append(n)
        else:
            needs.append((n, f"#{n} {title}: unclassified; operator picks scope"))
    return buckets, needs, skipped


def render(args, prb, issb, needs, skipped, folded_map) -> str:
    dg_note = f"; daily-goals #{args.daily_goals}" if getattr(args, "daily_goals", None) else ""
    out = [f"<!-- build_queue.py (GH-1527) as of {args.as_of}; window {args.since_days} days{dg_note}; "
           f"inputs: pr_minder.py --json, gh pr list, gh issue list -->", ""]
    other = f" ({fmt(args.other)})" if args.other else ""
    out += [AUTHORITY.format(owner=args.owner, other=other), "", "## Queue (execution order)"]
    lines = []

    def with_issues(n, closes):
        hit = sorted(set(closes) & folded_map.get(n, set()))
        return f" (closes {fmt(hit)})" if hit else ""

    for n, title, closes in prb["A"]:
        lines.append(f"#{n} {title}{with_issues(n, closes)}: CLEAN. Wait for review, then merge.")
    for n, title, closes in prb["B"]:
        lines.append(f"#{n} {title}{with_issues(n, closes)}: CONFLICTING or failing. Merge development in, gate, merge.")
    if prb["C"]:
        items = "; ".join(f"#{n} {t}{with_issues(n, c)}" for n, t, c in prb["C"])
        lines.append(f"Mergeability UNKNOWN or behind: {items}. Refresh their state, then land them as one "
                     "merge-cleanup batch (the fold/aggregate policy applies to 3+ PRs). Reconcile once at the end.")
    for n, title, closes in prb["D"]:
        lines.append(f"Draft #{n} {title}{with_issues(n, closes)}: finish or close, with evidence.")
    for n, title, _ in issb["E"]:
        lines.append(f"#{n} {title}: small bug fix through start-task or jog.")
    for n, title, _ in issb["DECIDED"]:
        lines.append(f"#{n} {title}: operator decision recorded — execute via start-task or jog.")
    for n, title, _ in issb["F"]:
        lines.append(f"#{n} {title}: docs fix through express.")
    if issb["G"]:
        lines.append(f"Stale merge-batch and inventory issues {fmt(n for n, _, _ in issb['G'])}: "
                     "close each once it is verified complete.")
    for n, title, _ in issb["CLOSE"]:
        lines.append(f"#{n} {title}: operator decision: close — verify acceptance on development, then close with a comment citing the commit.")
    for n, title, after in issb["H"]:
        gate = f"only after #{after} has landed" if after else "no predecessor named; confirm before starting"
        lines.append(f"#{n} {title}: refactor, {gate}.")
    lines.append("Final QA pass on development: tier 1, plus the full gate in a disposable clone.")
    out += [f"{i}. {line}" for i, line in enumerate(lines, 1)]
    out += ["", "## Needs the operator (the run parks these and keeps going)"]
    out += [f"- {reason}" for _, reason in sorted(needs)] or ["- (none)"]
    out += ["", "## Not queued (arcs, plans, research, spikes, umbrellas, radar, daily goals)",
            f"- {fmt(skipped)}" if skipped else "- (none)", ""]
    return "\n".join(out)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--repo-root", default=".")
    ap.add_argument("--out", help="write here instead of stdout")
    ap.add_argument("--owner", help="GitHub login whose PRs the run may merge (default: gh's current user)")
    ap.add_argument("--other-session", default="", help="PR/issue numbers owned by another session (comma list)")
    ap.add_argument("--needs-operator", default="", help="PR/issue numbers that need an operator decision")
    ap.add_argument("--repo-slug", help="OWNER/NAME for qualified closing references (default: from origin URL)")
    ap.add_argument("--since-days", type=int, default=14, help="issue window, counted back from --as-of")
    ap.add_argument("--as-of", default=dt.datetime.now(dt.timezone.utc).date().isoformat(), help="YYYY-MM-DD")
    ap.add_argument("--prs-json", help="saved pr_minder.py --json output")
    ap.add_argument("--pr-meta-json", help="saved gh pr list --json number,author,title,body,mergeable output")
    ap.add_argument("--issues-json", help="saved gh issue list --json number,title,labels,body,createdAt,comments output")
    ap.add_argument("--daily-goals", type=int, help="scope queue to items referenced by this daily-goals issue (ignores --since-days for referenced items)")
    ap.add_argument("--daily-goals-json", help="saved gh issue view <N> --json number,title,body,labels,state,comments output (offline replay)")
    args = ap.parse_args()
    root = Path(args.repo_root).resolve()
    args.other, args.decide = numbers(args.other_session), numbers(args.needs_operator)
    cutoff = (dt.date.fromisoformat(args.as_of) - dt.timedelta(days=args.since_days)).isoformat()
    offline_replay = bool(args.prs_json or args.pr_meta_json or args.issues_json or args.daily_goals_json)
    if offline_replay:
        missing_replay = [
            flag for flag, val in [
                ("--prs-json", args.prs_json),
                ("--pr-meta-json", args.pr_meta_json),
                ("--issues-json", args.issues_json),
                ("--owner", args.owner),
                ("--repo-slug", args.repo_slug),
            ]
            if not val
        ]
        if missing_replay:
            sys.exit(
                "build_queue: offline replay requires complete saved inputs (zero network/git calls); "
                f"missing: {', '.join(missing_replay)}"
            )
    elif not args.owner:
        args.owner = run_json(["gh", "api", "user"], root)["login"]

    minder = root / "skills/2-daily/pr-minder/scripts/pr_minder.py"
    rows = load(args.prs_json, lambda: run_json([sys.executable, str(minder), "--json", "--no-conflict-files", "--repo-root", str(root)], root))
    meta_rows = load(args.pr_meta_json, lambda: run_json(
        ["gh", "pr", "list", "--state", "open", "--limit", "300", "--json", "number,author,title,body,mergeable"], root))
    issues = load(args.issues_json, lambda: run_json(
        ["gh", "issue", "list", "--state", "open", "--limit", "1000", "--search", f"created:>={cutoff}",
         "--json", "number,title,labels,body,createdAt,comments"], root))
    meta = {m["number"]: m for m in meta_rows}
    slug = args.repo_slug or origin_slug(root)
    issues_by_num = {i["number"]: i for i in issues}
    rows_by_pr = {r["pr"]: r for r in rows}
    selected_issue_ids: set[int] | None = None
    scoped_rows = rows
    scoped_issues = issues
    safety_issues = list(issues)
    uninspectable_targets: set[int] = set()

    if args.daily_goals is not None:
        dg_num = args.daily_goals
        dg_obj = None
        if args.daily_goals_json:
            dg_obj = json.loads(Path(args.daily_goals_json).read_text())
            if isinstance(dg_obj, list):
                dg_obj = next((x for x in dg_obj if x.get("number") == dg_num), None)
            elif dg_obj and dg_obj.get("number") is not None and dg_obj.get("number") != dg_num:
                sys.exit(f"build_queue: --daily-goals-json contains issue #{dg_obj.get('number')}, expected #{dg_num}")
        elif dg_num in issues_by_num:
            dg_obj = issues_by_num[dg_num]
        elif offline_replay:
            sys.exit(f"build_queue: daily-goals issue #{dg_num} not found in offline replay inputs (supply --daily-goals-json or include it in --issues-json)")
        else:
            dg_obj = _gh_view_issue(dg_num, root)
        if not dg_obj:
            sys.exit(f"build_queue: daily-goals issue #{dg_num} not found")
        if str(dg_obj.get("state", "OPEN")).upper() != "OPEN":
            sys.exit(f"build_queue: daily-goals issue #{dg_num} is {dg_obj.get('state')} (expected OPEN)")

        refs = parse_daily_goals_refs(dg_obj.get("body") or "", slug, dg_num)
        selected_prs: set[int] = set()
        sel_issues: set[int] = set()
        for num in refs:
            in_meta = num in meta
            in_rows = num in rows_by_pr
            if in_meta and in_rows:
                selected_prs.add(num)
            elif in_meta or in_rows:
                sys.exit(f"build_queue: incomplete PR input for selected PR #{num} (present in {'pr-meta' if in_meta else 'pr-minder'} only)")
            elif num in issues_by_num:
                if str(issues_by_num[num].get("state", "OPEN")).upper() == "OPEN":
                    sel_issues.add(num)
            elif offline_replay:
                sys.exit(f"build_queue: referenced #{num} in daily-goals #{dg_num} is missing from offline replay inputs")
            else:
                fetched = _gh_view_issue(num, root)
                if not fetched:
                    sys.exit(f"build_queue: failed to resolve referenced #{num} from daily-goals #{dg_num}")
                if str(fetched.get("state", "OPEN")).upper() != "OPEN":
                    continue
                if num in meta or num in rows_by_pr:
                    sys.exit(f"build_queue: incomplete PR input for selected PR #{num}")
                issues_by_num[num] = fetched
                safety_issues.append(fetched)
                sel_issues.add(num)

        if not selected_prs and not sel_issues:
            sys.exit(f"build_queue: daily-goals #{dg_num} selected zero open issues or PRs after resolution")

        admitted_prs: set[int] = set(selected_prs)
        for r in rows:
            pr_n = r["pr"]
            m = meta.get(pr_n, {})
            if set(closing_refs(m.get("body") or "", slug)) & sel_issues:
                admitted_prs.add(pr_n)

        safety_by_num = {i["number"]: i for i in safety_issues}
        for pr_n in sorted(admitted_prs):
            m = meta.get(pr_n, {})
            for target in closing_refs(m.get("body") or "", slug):
                if target in safety_by_num:
                    continue
                if offline_replay:
                    uninspectable_targets.add(target)
                else:
                    fetched = _gh_view_issue(target, root)
                    if fetched:
                        safety_by_num[target] = fetched
                        safety_issues.append(fetched)
                    else:
                        uninspectable_targets.add(target)

        selected_issue_ids = sel_issues
        scoped_rows = [r for r in rows if r["pr"] in admitted_prs]
        scoped_issues = [issues_by_num[n] for n in sorted(sel_issues)]

    open_refs = (
        set(meta.keys())
        | {r["pr"] for r in rows}
        | {i["number"] for i in safety_issues if str(i.get("state", "OPEN")).upper() == "OPEN"}
    )
    parked = parked_issues(safety_issues, args.other, args.decide, args.owner, open_refs)
    parked |= uninspectable_targets

    prb, pr_needs = classify_prs(scoped_rows, meta, args.owner, args.other, args.decide, parked, slug)
    folded_map = {n: set(closes) for k in "ABCD" for n, _, closes in prb[k]}
    folded = set().union(*folded_map.values()) if folded_map else set()
    issb, issue_needs, skipped = classify_issues(
        scoped_issues, cutoff, args.other, args.decide, folded, args.owner, open_refs,
        include_ids=selected_issue_ids,
    )
    open_issues = {
        i["number"]
        for i in scoped_issues
        if i["createdAt"][:10] >= cutoff or (selected_issue_ids is not None and i["number"] in selected_issue_ids)
    }
    # a folded mention is shown only for issues that did not route to Needs-operator (rules 1-2 win)
    folded_map = {n: (c & open_issues) - {i for i, _ in issue_needs} for n, c in folded_map.items()}

    text = render(args, prb, issb, pr_needs + issue_needs, skipped, folded_map)
    if args.out:
        Path(args.out).write_text(text)
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
