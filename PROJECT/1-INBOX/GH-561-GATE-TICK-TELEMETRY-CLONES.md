---
issue: 561
source: https://github.com/HiQS-Labs/XYZ-forge/issues/561
title: "merge-cleanup: a clone with only .tick/telemetry is judged an unverifiable coordination root, so every gate-run disposable clone is preserved forever"
created: 2026-09-08
type: bugfix
status: 1-INBOX
complexity: 2
risk: 2
effort: 3
phases: 1
---

# GH-561 · gate-run `.tick/` artifacts make disposable clones un-teardownable

## The defect

`merge_cleanup.py --teardown-only` reports fully-pushed, fully-merged disposable clones as
`PRESERVE_UNVERIFIED_SESSION` because `tick claims` exits 3 (`events-dir-missing`) on any clone
whose `.tick/` contains only gate-run artifacts (`.tick/telemetry/`, `.tick/orphan-backups/`)
and no coordination kernel state (`.tick/events/`, `locks/`, `STATE.md`).

## Fix shape

`inspect_tick_claims` (utils/py/merge_cleanup.py) must classify a `.tick/` that carries NO
coordination state as "no claims by construction" (the kernel never ran in this clone), not as
"unverifiable" — teardown verification then proceeds on the repo-state checks alone. A `.tick/`
WITH `events/` that cannot be read keeps today's PRESERVE verdict (A.4 unchanged).

## Acceptance

- [ ] A clean, fully-pushed clone with telemetry-only `.tick/` tears down via `--teardown-only` (red first).
- [ ] A clone with a real `.tick/events/` holding an unreleased claim still PRESERVEs (A.4 pin).
