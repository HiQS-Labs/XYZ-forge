---
gh_issue: 137
source: https://github.com/HiQS-Suite/XYZ-forge/issues/137
title: "test: Wave-1 synthetic suites (gh129/gh130/gh131) are unregistered — nothing runs them"
status: Active (2-WORKING — built 2026-08-22)
created: 2026-08-22
updated: 2026-08-22
owner: noelsaw1
doc_type: bugfix
effort: 1
complexity: 1
risk: 2
goal: >
  Register the three Wave-1 suites (plus this wave's guard) in validate.sh's TESTS array via the
  GH-124 wrapper pattern, so the push gate and CI actually execute them.
---

# GH-137: Wave-1 suites registered

## Status

| What was just completed | What's next |
|---|---|
| **BUILT 2026-08-22 on `fix/gh135-140-followups-2026-08-22`** — thin wrappers `test/gh129-relay-tick-root.sh`, `test/gh130-agy-auth-whoami.sh`, `test/gh131-marathon-target-root.sh` (GH-124 pattern) plus TESTS entries for those and `gh139-pipe-grep-guard.sh`. Pool-safety confirmed: gh131's marathon lock is fixture-rooted and `marathon_drive.py` exports `RELAY_DRIVER_LOCKED=1` to the relay-drive child (line 850), so no suite touches the clone's real driver lock. | Land with the GH-135..140 PR; the suites ride every future gate run. |

## The defect

PR #134's wave plan scoped the commit to `test/synthetic/` only, so the three suites (33
assertions, all with recorded pre-fix negative controls) never ran again after the lane — the
exit-4-never-0 pin exists precisely because the #129 incident's snapshot passed its own era's
tests.

## Verification

`./validate.sh` full-gate green with the suites registered (their PASS lines present in the run
log); each also runnable standalone via its wrapper.
