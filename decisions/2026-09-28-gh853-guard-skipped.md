---
status: Decided
date: 2026-09-28
reversibility: Cheap
revisit: "the 2026-10-08 suite audit (#862), or any new suite-isolation member that leaks writes into ignored `.tick/` or `__pycache__/` paths"
related: []
decider: "@noelsaw1"
---

# #853 Guard task skipped: no `--ignored` in the runner envelope

**Decision:** Skip #853's *Guard* task. That task would add `--ignored` to `_re_tree` in `test/lib/runner-envelope.sh`,
filtered to `.tick/` and `__pycache__/`, so that `runner_envelope_assert` names suites writing into ignored paths.

**Why:** it is new gate machinery. #831's non-goals exclude that, and #853 said to skip the task unless the operator gave explicit OK.
The one observed leak of this kind (#745's `RollbackJournal` `.tick` writes) was fixed at the source in `fb1364fa`.

**Consequence:** #853's *Verify* check of "a clean `runner_envelope_assert`" uses the envelope as it is today.

**Recorded:** #853 comment 5861631341; lands with the #854 window.
