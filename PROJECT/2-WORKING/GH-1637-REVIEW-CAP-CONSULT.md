---
gh_issue: 1637
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1637
title: "Factory review loop: 4-round default and consult tie-break at the cap instead of stalling"
status: "Planned 2026-11-26 (start-task; plan QA pending)"
created: 2026-11-26
updated: 2026-11-26
owner: start-task implementation child (Flywheel Day 2, ledger #1610)
doc_type: feature
ratings_provisional: true
non_goals:
  - Changing the push gate, red-then-green, or operator merge (all kept)
  - The legacy Bash relay-drive.sh path (`XYZ_PYTHON=0`); it keeps its stall-at-cap behavior
  - `utils/py/jog_run.py` `_jog_task_local_failure` area (owned by the #1633 child)
  - Counting TESTS-RESULTS-only repairs as progress (`relay_drive.py` RECEIPT_DIRS); the consult tie-break supersedes it
  - A new test suite or runner (GH-831)
goal: >
  A factory phase whose reviewer still has open findings at the round cap no longer stalls with no PR:
  one Codex+agy consult adjudicates the findings, and the phase either continues to the real gate and a
  ready PR recorded as `Consult-Adjudicated` (distinct from `Approved`), takes one repair, or holds for safety.
---

# GH-1637 · Factory review loop: 4-round default and consult tie-break

## Status

| What was just completed | What's next |
|---|---|
| Recon of the cap, attestation and consult seams on `origin/development` 961cac652. | Plan QA, then implement in `relay_drive.py`, `marathon_drive.py`, `relay_attest.py`, `marathon.sh`. |

## Problem

Factory loops (Jog -> Preflight -> Marathon -> relay-drive) stall with no PR when the reviewer still has open
findings at the round cap (#1610: GH-1315 stalled after one review; a contract `round_cap: 2` is **turns**, not rounds).
A stall yields no forward progress while the real safety net (exact-head gate, red-then-green, operator merge) never runs.
Operator decision (2026-11-26, on the issue): the goal is net forward progress.

## Acceptance

- [ ] Default factory review budget is 4 rounds: `max_review_rounds` default 4 (cap 9) in `relay-automation/marathon.sh`, and the `marathon_drive.py` default `round_cap` 9; the docs that state the old default are updated.
- [ ] At the cap, with the lane non-terminal and not escalated, `relay_drive.py` runs one consult (`consult.sh`, Codex + agy) over the pinned diff, the relay file (open findings plus the builder rebuttal) and asks each advisor for one `ADJUDICATION:` token.
- [ ] All advisors `NON-BLOCKING` -> the driver records `STATUS: Consult-Adjudicated` with both answers linked, attests it through the existing `judge_terminal` path (driver-run gate included) and exits 0; marathon then runs its real gate as for an approval.
- [ ] Any advisor `REAL` (and none `SAFETY`) -> exactly one repair: the driver appends the findings, grants two more turns once, and the normal reviewer path then decides. A second cap escalates as today.
- [ ] Any `SAFETY`, or a missing/unparseable answer -> escalate (hold) with a named reason; never silently approve.
- [ ] `Consult-Adjudicated` is not `Approved`: `express.py` and jog auto-merge refuse it, so merge stays an operator action.
- [ ] Default-off in `relay_drive.py` (flag `--consult-at-cap`), so every existing direct caller and suite keeps today's behavior; `marathon_drive.py` passes the flag.
- [ ] `hard_cap` becomes `round_cap + 2` (decision on the issue's note); the TESTS-RESULTS-only progress note is decided as rejected (consult supersedes).
- [ ] Verified by existing suites (`gh115-round-cap`, attestation and marathon suites) plus a recorded manual check under `TESTS-RESULTS/2026-11-26+GH-1637/`: one run per verdict class (adjudicated, real-then-repair, safety hold) with stub advisors, and the default-off run.

## Recon note

- **Baseline:** `origin/development` `961cac652`.
- **Cap loop:** `utils/py/relay_drive.py` `main()`; `hard_cap = args.round_cap * 2` at `:1017`; progress extension and final `cap-stalled` / `cap-progressing-extended` escalation at `:1415-1436`. Progress is `commits_touch_non_receipt` or a resolved `[x]` item (`:764`; `TESTS-RESULTS/` is a receipt dir, GH-976).
- **Attestation:** `judge_terminal` (`:~810-1000`) is the one writer of the trailer and record; it needs a reviewer-role turn, runs `MARATHON_REVIEWER_GATE_CMD` itself on an approval, checks the token is `done`, and writes `record["status"]`. `relay_attest.TERMINAL = ("Approved","Closed")` (`relay_attest.py:28`) gates `load()`.
- **Terminal readers:** `marathon_drive.py:2553` (`terminal_status`), `relay_drive.py:556`. Others (`poll.py`, `check_marathon_qa.py`, legacy Bash) are the hands-free poll loop, a PDDA lint and the Bash fallback; left alone.
- **Existing consult path:** `--consult-verify` in `relay_drive.py` (`:1238`) already shells to `consult.sh` and parses `->` output lines; the new path reuses `consult_sh` and the same parse, with its own prompt.
- **Cap writers:** `marathon.sh:587` (`rounds="${rounds:-2}"`, cap `2N+1`), `marathon_drive.py:3072` (`args.round_cap = 5`). Preflight contracts carry an explicit hand-written `round_cap` (`swarm_preflight.py:155`); that is an operator value and stays, but a short cap now ends in a consult rather than a stall.
- **Why a new STATUS word and not `Closed`:** `Closed` is already written by reviewers and accepted everywhere as done; reusing it would make an adjudicated phase indistinguishable from a reviewer close. The marathon result receipt already records `relay_status`, so the new word is visible in the receipt for free.
- **Preflight Bet Check:** outcome = no zero-progress stall; smallest bet = one opt-in tie-break in the existing driver; rejected = a new adjudication subsystem, a second attestation writer, and changing `Approved` semantics; rollback = drop the flag from `marathon_drive.py` (default-off elsewhere), revert the default.

## Plan (ordered, verification inline)

1. `relay_attest.py`: add `Consult-Adjudicated` to `TERMINAL`. Verify: `load()` accepts a record with that status; existing attest suites stay green.
2. `relay_drive.py`: add `--consult-at-cap`; `hard_cap = original_round_cap + 2`; at the cap (when no progress extension is available) call a new `consult_adjudicate()` that builds the prompt (pinned diff against the merge-base with the integration branch, the relay file, the verdict token rules), runs `consult_sh`, and returns `adjudicated` / `real` / `hold`. `adjudicated`: append the consult block, set STATUS, close the token, call `judge_terminal(..., role="reviewer")` with `actor = args.reviewer`, then exit 0 as the approval path does. `real`: append findings once, `round_cap += 2`, `hard_cap += 2`, continue. `hold`: `exit_escalate("consult-hold")`. Verify: the three stub-advisor runs and the default-off run.
3. `marathon_drive.py`: `terminal_status` reads `relay_attest.TERMINAL`; default `round_cap` 9; pass `--consult-at-cap`. `marathon.sh`: default 4 rounds. Docs: the `MARATHON.example.yaml` and `marathon.sh` header comments, relay-automation README.
4. `jog_run.py`: auto-merge refuses a record whose status is not `Approved` (a small hunk away from `_jog_task_local_failure`).
5. Run `gh115-round-cap` plus the attestation, marathon and jog suites that cover the touched seams; write the manual-check receipt under `TESTS-RESULTS/2026-11-26+GH-1637/`.

## Risks / rollback

- Consult fails open to an approval-like terminal: mitigated by requiring every advisor to answer `NON-BLOCKING`, treating anything else as hold, and by the unchanged driver-run gate, push gate and operator merge.
- Reverting: remove `--consult-at-cap` from `marathon_drive.py` and restore the two defaults; the new word is inert without the flag.

## Rating rationale

Rated through `roadmap pickup` on 2026-11-26 (see the ledger row). Severity 55: a stalled phase wastes a day of factory work but loses no data. Priority 70: operator-prioritized and it blocks the Flywheel arc; recurrence 1 distinct incident (GH-1315, #1610) in the last 14 days, trend otherwise unknown. Appeal 50 (neutral). Effort 70.
