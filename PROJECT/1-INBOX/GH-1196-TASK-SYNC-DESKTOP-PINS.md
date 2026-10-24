---
title: "task-sync: pin active Claude Desktop sessions (native set_pinned)"
status: Inbox
created: 2026-10-24
updated: 2026-10-24
owner: claude
gh_issue: 1196
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1196
doc_type: feature
complexity: 1
risk: 1
effort: 1
phases: 1
non_goals:
  - Unpinning anything (manual pins and aged-out sessions stay as they are)
  - The scheduler (#1191 step 4), other IDEs, or changes to title-stamping behaviour
  - Add test/ suites (AGENTS.md, GH-831)
related:
  - GH-1191
  - GH-896
goal: >
  Have the claude-desktop planner also propose pins for recently active Desktop
  sessions, applied with the app's native set_pinned tool and never unpinning.
---

# GH-1196 - task-sync: pin active Claude Desktop sessions (native set_pinned)

## Status

| What was just completed | What's next |
|---|---|
| Captured; plan written (base `a6fd65af`) | Codex plan QA |

## Key concepts

- Pins come from the same `list_sessions` snapshot as titles; `set_pinned` is the only writer.
- Never unpin: a pin is only ever added, and undo checks the session is still pinned.
- A running session can be pinned (a pin does not revert like a title does).

## Scope

Operator, 2026-10-24: "Are you able to also move active tasks to the pinned area?", then approval of the follow-up plan.

| # | Requirement | Acceptance check |
|---|---|---|
| R1 | Planner proposes pins for recently active, unpinned, non-archived, non-self sessions; `--no-pin` disables | Probes |
| R2 | Native pin procedure in `SKILL.md` (recheck, `set_pinned`, decline = skip, receipt, guarded undo) | Followed verbatim in the live smoke |
| R3 | Title behaviour unchanged | `TESTS-RESULTS/2026-10-24+GH-1191/probes.py` 17/17 on the new code |

## Recon (base `a6fd65af`)

| Seam | Location | Finding |
|---|---|---|
| Desktop sweep | `skills/3-weekly/task-sync/scripts/adapters/claude.py:406–439` | One loop: archived/running/self rows are skipped before activity is validated; proposals go to `report["renamed"]`. `pin`/`pin_hours` are already in the signature, unused. `--unpin-days`/`--group` are refused with "no pins or groups". |
| CLI | `task_sync.py` | `--pin-hours` (default 24) and `--no-pin` already exist and reach every adapter via `_sweep_kwargs`; `PLAN_ONLY` already refuses `--unpin-days`/`--group`. No CLI change needed. |
| Report shape | `core.new_ide_report()` | Already has `pinned` and `unpinned` lists. |
| Pattern to mirror | `adapters/zcode.py:194–266` | ZCode pins tasks active within `pin_hours` and lists `{task_id, title}` in `pinned`. |
| Native tools | `list_sessions` rows carry `pinned` (omitted when never recorded, which means not pinned); `set_pinned(session_id, pinned)` | `set_pinned` on another session asks the operator first in default permission mode. |

## Plan

1. **`ClaudeDesktopAdapter.sweep`** (`adapters/claude.py`). Restructure the loop:
   - Skip archived and self rows.
   - Validate activity for every remaining row. This is the one ordering change: running rows are now validated as well.
   - If `pin` and the row's `pinned` is not `True` and activity is within `pin_hours`, append `{task_id, title, activity_at}` to `pinned`.
   - Running or out-of-window rows are then skipped for titles exactly as before.
   - Update the refusal message to "no groups or unpinning" and the docstring.

   -> expect the new probes plus the #1191 probes green.
2. **`SKILL.md` "Claude Desktop (GH-1191)":** add the pin rule to the candidate paragraph and a pin step to the native procedure:
   - Recheck: not archived, still unpinned, not self, activity still within `--pin-hours`.
   - `set_pinned(<id>, true)`; a decline is a skip.
   - Append `{"at", "session_id", "op": "pin"}` to the same receipt.
   - Undo `set_pinned(<id>, false)` only while the session is still pinned.
   - Never unpin otherwise.
3. **Probes** `TESTS-RESULTS/2026-10-24+GH-1196/probes.py`:
   - an unpinned active row → pin proposal;
   - already pinned, or `pinned: false` vs key missing → only the unpinned get proposals;
   - a running row → pin but no rename;
   - archived or self → neither;
   - outside `--pin-hours` → no pin;
   - `--no-pin` → no pins.

   Plus the #1191 battery re-run. Red control: drop the `pinned is not True` check and watch the already-pinned probe fail.
4. **Live smoke:** pin one idle session through the procedure, confirm `pinned: true` via `list_sessions`, rerun (no proposal), undo via the receipt rule.
5. **Gate:** `utils/ci-route.sh pull_request` → run what it selects once; CHANGELOG entry.

## Bet check

- **Outcome:** sessions active today sit under Pinned in the sidebar.
- **Smallest bet:** a few lines in the existing loop plus a SKILL paragraph. No CLI or report-shape change.
- **Alternatives rejected:**
  - Unpinning stale sessions: risks removing the operator's manual pins, which the native list can't distinguish.
  - A separate pin adapter: a second planner over the same snapshot.
- **Rollback:** revert. Pins are listed in the receipt and undone with `set_pinned(false)`.

## Risks

- **Pins accumulate:** with no unpinning, yesterday's pins stay. This is by design (matches "never unpin manual pins"); the operator unpins by hand. A later opt-in unpin would need a way to tell task-sync pins from manual ones, which the receipt could provide.
- **Unattended decline:** pinning another session in default mode asks first, so an unattended run may decline every pin. This is witnessed at #1191 step 4, the same as for titles.

## Verification (no new test/ suites)

Manual probes and live smoke under `TESTS-RESULTS/2026-10-24+GH-1196/` with `provenance.jsonl`.

## Plan QA

Pending.

## Rating rationale (2026-10-24)

`rated 55/20/50/85`.
- `sev` 20: convenience; nothing breaks without it.
- `pri` 55: the operator asked for it while working the Desktop rollout.
- `appeal` 50: neutral.
- `effort` 85: a few lines in an existing loop.
- Recurrence: not applicable (feature).
