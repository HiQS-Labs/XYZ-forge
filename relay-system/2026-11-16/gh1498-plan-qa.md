# RELAY · GH-1498 pr-minder plan QA
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
6. **Commit only the relay file** (`relay(gh1498-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
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
- Definition of Done: the plan in `PROJECT/1-INBOX/GH-1498-PR-MINDER.md` is safe to implement. It is grounded in the cited code, covers every acceptance checkbox in the issue body (`.relay-artifacts/pr-minder-body.md`), extends the existing writers rather than adding parallel ones, and its verification plan can actually reject an unfixed candidate.

## Context and questions

**Operational envelope.** A manually invoked local CLI skill, run by one operator in one repo with about 12–50 open PRs. Machinery and verification must stay proportionate. Don't ask for daemons, distributed locks, journaled recovery or new test suites. This repo forbids new tests (AGENTS.md *No new tests*, GH-831): verification uses existing suites plus a manual check recorded under `TESTS-RESULTS/`.

**Step A — paraphrase first (GH-1414).** Before opening the issue artifact or any source file, read ONLY `PROJECT/1-INBOX/GH-1498-PR-MINDER.md` and write:
- **What this proposes** (2–5 sentences)
- **How the existing system works, per this document** (2–5 sentences)
- **What it's not** (short; separate excluded, deferred, and later-authorization items; label any inference)

State the input boundary you used for this step (plan doc only).

**Step B — source-backed validation.** Now read the issue (`.relay-artifacts/pr-minder-body.md`) and the cited code:
- `skills/3-weekly/weekly-planner/scripts/planner_core.py` (`get_open_prs` :326, `detect_merge_sequence` :346, `HOLD_LABELS` :1203, `AGE_DISCLOSURE` :1214, `_age_days` :1229, `collect_stalled_stale` :1500, the stalled wiring :1726 and :1869)
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` (imports :27–54, `refresh_pr` :501, `refresh_pr_with_retry` :516, `_protect_stacked_dependents` :553, `hold_label` :574)
- `skills/2-daily/daily-planner/SKILL.md:14`

Answer:
1. Are the plan's five recon findings true against the source? Pay particular attention to #2: identifying update-branch commits by the headline `Merge branch '<base>' into <head>` instead of by receipts. Is that sound, and what would it misclassify?
2. Does each issue acceptance checkbox map to a plan step with a check that would **reject an unchanged or unfixed candidate**? Name any checkbox with no observable rejection.
3. Does the plan extend the existing writers (planner_core's fetch and stalled path, merge_cleanup's hold and read helpers) without a duplicate subsystem or a second write path?
4. Is the "first error line → failing check name plus URL" ponytail disposition acceptable against the issue?
5. Is the planner adoption safe for `/daily-planner`'s existing fail-open contract (:1871–1876)? Is there any risk to the existing suites that cover planner_core?
6. Is anything over-built or under-built for the envelope above?

Cite `file:line` for every claim.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
