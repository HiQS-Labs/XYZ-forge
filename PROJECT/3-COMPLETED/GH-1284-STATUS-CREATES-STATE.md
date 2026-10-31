---
gh_issue: 1284
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1284
title: "factory-primitive: status on an uninitialized run root creates state.db, then init refuses"
status: Complete
created: 2026-10-31
updated: 2026-10-31
owner: agent-b
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: false
non_goals:
  - Changing init, schema, or the run-root guard
  - New tests or suites (GH-831)
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1248
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1280
goal: >
  Read-style factory-primitive commands must not create instance state on a root that
  nobody initialized, so a later init still works.
---

## Key concepts

- `connect()` creates the database file and schema on open (`utils/py/harness.py:92`).
- `status()`, `make_packet()` and `run_tick()` call it on `instances/<X>/state.db` without
  checking that `init` ever ran; `init_instance()`/`init_from_prs()` refuse once the file exists.

## Plan (simple change: local, reversible, no design decision)

1. Add one guard, `_require_instance(instance)`, that raises `ValueError("instance not
   initialized; run init first")` when `state.db` is absent. `factory_main` already maps
   `ValueError` to rc 2 with a `factory-primitive:` message.
2. Call it at the top of `status()`, `make_packet()` and `run_tick()` (before `run_tick`
   creates the instance dir or lock). Init paths are untouched.
3. Verify (manual check, no new tests): fresh root → `status` rc 2, no `state.db`; then
   `init` rc 0, `status` rc 0, `tick --slot 1` rc 0. Adjacent: `packet` and `tick` on a fresh
   root both refuse rc 2 and leave no `state.db`. Re-run the GH-1280 D1 sequence. Evidence
   under `TESTS-RESULTS/2026-10-31+GH-1284/`.

Rating rationale: pri 55 (blocks clean campaign sequences), sev 35 (experimental tool, new
root recovers), appeal 50 (neutral), effort 90 (one guard, three call sites).
