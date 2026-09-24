---
gh_issue: 797
source: https://github.com/HiQS-Labs/XYZ-forge/issues/797
title: Flightdeck explains unknown progress and source states
status: In progress
created: 2026-09-24
updated: 2026-09-24
owner: Claude
goal: Unknown and unconfigured states read as "not measured / not set up" with a how-to-enable hint; red stays reserved for read failures.
doc_type: project
branch: fix/gh797-flightdeck-unknown-help
effort: 1
complexity: 1
risk: 1
phases: 1
---

# Flightdeck explains unknown progress and source states

## Status

| What was just completed | What's next |
|---|---|
| Implemented plan steps 1-4. Focused checks green: node check (the mutation red control fails it), pytest `test/flightdeck` 39/39, real-Chrome browser check. Headless screenshot shows "Progress not measured" with a grey dot | Final Codex relay QA, then full gate once, then PR |

## Problem (observed)

Running `python3 -m src.flightdeck.server` with default config shows every card as
**"Progress coverage unknown"**, with nothing that says why or what to do about it.

- `web/flightdeck/presentation.mjs:6` `progressTone()` always returns `'unknown'` on purpose
  (no producer supplies a repo-scoped progress window). `web/flightdeck/app.js:41` maps it
  to that label on every card.
- `app.js:162-172` `renderSources()` renders `<id> · <availability>`. `app.css:43` paints
  every `unavailable` pill **red**, including topology/continuity, which have no configured
  path and no producer (`connectors.py:394-397` returns an empty `unavailable` batch with
  `error: null`). Their tooltip reads `Coverage: unknown; observed unknown`.
- `xyz_work` shows `disabled` because it is enabled only when `FLIGHTDECK_XYZ_ROOTS` /
  `xyz_roots` is set (`contract.py:99-113`). That variable is missing from the README table.

The snapshot already carries everything needed to tell these cases apart:
`availability` (`ok`/`disabled`/`unavailable`), `error` (exception class name or null),
and `roots[].error` for xyz_work.

## Plan

Extend the existing read-side presentation module. No server, snapshot-contract, or
new-subsystem change.

1. In `presentation.mjs`, add `sourceStatus(source, fresh)`, which returns `{tone, label, help}`:
   - `ok` keeps its current look. `stale` keeps amber.
   - `disabled` → tone `off` (grey), label `off`, plus a per-source enable hint
     (xyz_work → `FLIGHTDECK_XYZ_ROOTS`; others → add the ID to `FLIGHTDECK_CONNECTORS`).
   - `unavailable` with no `error` and no root error → tone `off`, label `not set up`,
     plus a per-source hint naming its env var. Topology and continuity also say that no
     producer writes the feed yet.
   - `unavailable` with `error` or a root error → tone `failed` (red), label `read failed`,
     with the error name and the env var to check.
   - Verify: node assertions in `test/flightdeck/work-status-checks.mjs` for each branch.
2. In `presentation.mjs`, add `PROGRESS_HELP`. In `app.js` `health()`, change the unknown
   label to **"Progress not measured"** and put the help text in the health element's
   `title`. Keep the existing detail line. Verify: a node assertion that `PROGRESS_HELP`
   exists and says this isn't an error. Visual check against the live server.
3. `app.js` `renderSources()` uses `sourceStatus`, setting the pill class, visible label,
   and `title`. Keep the existing excluded-rows suffix. In `app.css`, change the red rule
   from `.unavailable` to `.failed`; `off` falls through to the grey default dot. Verify:
   the token audit test still passes.
4. README: add `FLIGHTDECK_XYZ_ROOTS` to the env table and one line on what the pill states
   mean. CHANGELOG entry.

**Non-goals:** no new progress producer, no server-side hint field, no health model
change (`progressTone` stays `'unknown'`), no new test framework or runner.

**Test scope:** extend the existing node check and run the existing pytest module
`test/flightdeck/`. Red control: the new assertions fail against the old `presentation.mjs`,
where `sourceStatus` doesn't exist.

**Rollback:** revert the single commit. Presentation-only; producers are untouched.

## Rating (2026-09-24)

`rated 40/25/50/85`. Severity 25: misleading UI, no data loss, and nothing blocked beyond
operator confusion. Priority 40: the operator raised it directly while piloting Flightdeck.
Appeal 50: neutral, since the operator gave no score. Effort 85: a presentation-only change
in one module. Recurrence: first report. No same-class Flightdeck issue was found in the
last 28 days (`gh issue list --search "flightdeck unknown"` → only #646 and #789, both
unrelated).

## Plan QA disposition

Simple change under the start-task definition: local, reversible, presentation-only, with
no uncertain behavior. Pre-implementation relay plan QA is skipped for that reason; the
final relay QA on the committed diff still applies.
