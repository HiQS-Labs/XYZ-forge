# RELAY · GH-1498 pr-minder final QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-16.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1498-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/pr-minder-body.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-XYZ-forge/80ba96e0-33b8-4de1-bab4-44615f129982/scratchpad/pr-minder-body.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-11-16
- Definition of Done: the implementation on this branch delivers the approved plan (`PROJECT/1-INBOX/GH-1498-PR-MINDER.md`; plan QA approved in `relay-system/2026-11-16/gh1498-plan-qa.md`) and every acceptance checkbox in the issue (`.relay-artifacts/pr-minder-body.md`). The evidence in `TESTS-RESULTS/2026-11-16+GH-1498/` substantiates each claim. No duplicate subsystem or writer, and no new test file or registry entry.

## Context and questions

**Operational envelope.** A manually invoked local CLI skill, run by one operator in one repo with about 12–50 open PRs. Grade against the stated requirements and proportionate complexity. Don't ask for daemons, locks, journals or new test suites. The repo forbids new tests (AGENTS.md, GH-831). `manual_check.py.txt` is a recorded manual-check driver stored as `.txt`, following the `TESTS-RESULTS/2026-11-14+GH-1486/fixture-checks.sh.txt` pattern; it is not registered in `validate.sh`.

**Changed code** (diff `f346d8908..HEAD`):
- `skills/3-weekly/weekly-planner/scripts/planner_core.py`: `fetch_pr_activity`, `is_maintenance_commit`, `author_activity`, `AUTHOR_AGE_DISCLOSURE`, `_age_disclosure`, the `collect_stalled_stale(..., activity=None)` path, and the `run_stalled_scan` wiring.
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`: `body` added to `refresh_pr`.
- `skills/2-daily/pr-minder/scripts/pr_minder.py` and `skills/2-daily/pr-minder/SKILL.md` (new).
- `CHANGELOG.md`.

**Evidence:**
- `TESTS-RESULTS/2026-11-16+GH-1498/manual-check.log`: A1–A12 plus A8b, 13/13 PASS, every bad candidate rejected.
- `smoke-plan-mode.log`: real repo, plan mode run twice, identical output.
- `gate.log`: publisher suites 4/4. The first `ci-local` run went red only because `mypy` was missing on this machine; the second run, in a venv with `mypy==1.14.1`, was green at `c8ca1ccd6`. `README.md` and `provenance.jsonl` record both.

Commits after `c8ca1ccd6` are evidence and relay files only.

Answer, citing `file:line`:
1. Does the code implement each plan item? Check the activity predicate and completeness rule, the hold union plus pre-write refresh, the ladder table, precedence, the cap, owned label/comment idempotency, intent/result receipts, the kill switch and stack inheritance. Name any divergence from the plan or issue.
2. For each issue checkbox, does the cited evidence show the **observed rejection** of an unfixed candidate, not just a passing run? Name any assertion whose bad candidate doesn't actually exercise the code path it claims.
3. Did a duplicate subsystem or a second write path slip in? Does pr-minder ever merge, close, rebase, force-push or retarget?
4. Are there correctness bugs in `pr_minder.py`'s write path? Look at the label add/remove logic, the comment PATCH/POST, the update-branch outcome classification, and the early `break`.
5. Is `planner_core`'s fail-open contract preserved for `/daily-planner` (an activity-fetch failure becomes a coverage gap, not an exception)?
6. Is the rated 55/40/50/45 consistent with the evidence?
7. Is anything over-built or under-built for the envelope?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
