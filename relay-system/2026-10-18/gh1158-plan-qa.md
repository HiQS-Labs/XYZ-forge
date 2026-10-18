# RELAY · GH-1158 plan QA — landing decision checkpoint for queues of 3+ PRs
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-18.
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1158-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1158-LANDING-PLAN-CHECKPOINT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1158-LANDING-PLAN-CHECKPOINT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-18
- Definition of Done:
  1. Grounded in live codebase paths (`merge_cleanup.py`, `batch_record.py`, `skills/2-daily/merge-cleanup/SKILL.md`).
  2. Clean CLI checkpoint (`--landing-plan direct|group`, `--landing-reason "<text>"`), with Exit 5 refusal on 3+ PR queues without plan/reason before any mutation.
  3. Zero-mutation fail-closed invariant on Exit 5 (no git commits/merges/removals, no GitHub issues opened).
  4. Decision and reason recorded in `batch_record` schema and mirrored into the `merge-batch` GitHub issue under the script-owned block.
  5. `--landing-plan group` records decision, prints GH-1066 execution checklist, and exits 0 cleanly without merging.
  6. `--resume` reuses recorded decision on unchanged PR sets; enforces a fresh decision if the PR set changed or was unrecorded.
  7. Queues < 3 PRs remain completely unaffected.
  8. Repo rail: No new tests (GH-831) adhered to — verification through existing suites (`test/gh436-merge-cleanup.py`, `test/gh534_phase_a_tests.py`), manual check under `TESTS-RESULTS/2026-10-18+GH-1158/`, and red controls.
  9. Ratings honest per RELEASES 4-axis vocabulary: rated 75/55/50/80 (sum 260).

## Context and questions for Reviewer

Operational envelope: `/merge-cleanup` developer workflow skill. Commensurate complexity applies: lightweight CLI checkpoint, no enterprise state machines or daemon schedulers. The repo strictly forbids new test suites (AGENTS.md GH-831) — do not request any.

1. Grounding: Does the plan accurately target `merge_cleanup.py` Phase 4/Phase 5 boundary and `batch_record.py` without conflicting with existing batch or resume mechanisms?
2. Clean separation: Does the design maintain the operator's requirement that the AI/operator makes the call while the tool guarantees the question is asked and recorded?
3. Zero-mutation: Is the refusal logic before Phase 5 guaranteed to perform zero git mutations and open zero GitHub issues when exiting 5?
4. Resume: Does the `--resume` contract correctly handle cases where the PR set has expanded vs. remained unchanged?
5. Verification: Is the verification plan commensurate and compliant with GH-831?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
