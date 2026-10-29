---
Goal: Plan QA — marathon #1250 (GH-1175 Phase 0 follow-ups), four lane plans
Date: 2026-10-29
NEXT: codex
STATUS: Open
---

# Context

Independent plan QA for marathon umbrella https://github.com/HiQS-Labs/XYZ-forge/issues/1250 before any build. Base `93f41cb8` (development). Each lane has its own issue with an `## Acceptance` checklist, copied verbatim into its doc. Direct `swarm-preflight --dry-run` currently reports READY (exit 0) for all four.

| Lane | Issue | Plan doc | Write-set |
|---|---|---|---|
| L1 | #1233 | `PROJECT/2-WORKING/GH-1233-JOG-RECOVERY-AFTER-DRIVER.md` | `skills/2-daily/jog/SKILL.md` (docs) |
| L2 | #1235 | `PROJECT/2-WORKING/GH-1235-MERGE-CLEANUP-JOG-LAND.md` | `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` |
| L3 | #1236 | `PROJECT/2-WORKING/GH-1236-JOG-MARATHON-LANE-RUNS.md` | `githooks/pre-push`, `utils/py/gate_receipt.py`, `utils/py/marathon_drive.py` |
| L4 | #1251 (slice 1 of #522) | `PROJECT/2-WORKING/GH-1251-GH-522-SLICE-1.md` | `utils/py/_marathon_plan.py` (+ existing planner tests only where they pin old behaviour) |

Operational envelope: four small, independent fixes. Grade each against its own issue's acceptance and commensurate complexity. Do not ask for new tests (AGENTS.md *No new tests*, GH-831), new suites, schemas, daemons or machinery. #522's larger program (model spike, monitor, automatic membership) is explicitly out of scope; #1251 is only its deterministic rung-2 slice.

Read each plan doc in full, plus the code each cites:
- L2: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:797-990`, its callers `:1615-1640` and `:1930-1945`, and the suites that mock `run_post_merge_reconcile` (`test/gh534_phase_a_tests.py:584`, `test/gh534_phase_b_tests.py:560,574`, `test/gh436-merge-cleanup.py:360,457`, `test/gh549-work-events.sh:620-640`).
- L3: `githooks/pre-push:58-80` and `:255-318`; `utils/py/gate_receipt.py`; `validate.sh:1575-1595`; `utils/py/marathon_drive.py:2810-2835`; `relay-automation/marathon-closeout.sh:149-190`.
- L4: `utils/py/_marathon_plan.py:1015-1205`, `test/marathon-plan.sh` (scenarios G and T).
- L1: `skills/2-daily/jog/SKILL.md:178-189`.

Questions:
1. Per lane: is the recon right, is the change the smallest that meets every acceptance item, and is anything missing or over-scoped? Cite file:line.
2. L2: does committing inside `run_post_merge_reconcile` on a Jog refusal (via the existing `commit_and_push_phase5_writes`) keep every current failure path stopping before the commit? Is any caller or suite broken by it?
3. L3: is reuse limited to the exact pushed SHA, a `validate.sh` full-gate receipt, and the full-gate arm only? Can any path weaken today's gate, for example through a stale receipt, a receipt from another tree, a docs/tier-2 route, or a marathon receipt? Is "marathon writes only when no receipt exists" sound?
4. L4: are the three fail-closed changes correct, and is the cycle case really what reaches the no-progress fallback? Is the Phase 0 grep plus the GH-698 parity precedent the right handling for existing fixtures?
5. Waves: are the four write-sets disjoint (including generated files and shared ledgers)? Can all four lanes run in one wave? L3 touches `utils/py/marathon_drive.py` and L4 touches `utils/py/_marathon_plan.py`; check that no lane edits a file another lane's gate or runtime depends on mid-wave in a way that matters.
6. Ratings (#1233 45/40/50/92, #1235 60/60/50/75, #1236 50/35/50/70, #1251 55/50/50/75): are they grounded?

Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]` per lane, citing file:line. End your final block with exactly `VERDICT: PASS` (or `FAIL`) on its own line, followed by a non-empty `Basis:` line (GH-533). Set STATUS to Approved on PASS.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log
