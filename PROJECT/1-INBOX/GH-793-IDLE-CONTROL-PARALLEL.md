---
title: "GH-793: idle-kill control fails under parallel load"
status: queued
created: 2026-09-24
updated: 2026-09-24
owner: unassigned
goal: Diagnose the idle-control parallel failure without weakening its negative control.
gh_issue: https://github.com/HiQS-Labs/XYZ-forge/issues/793
---

## Status

| What was just completed | What's next |
|---|---|
| Captured a parallel failure and passing isolated control during GH-791 review. | Held for separate operator-authorized work. |

## Finding

The idle suite returned 14 pass / 2 fail under four-worker macOS load: the progressing
turn reported 6.81 seconds idle, and the blocked turn classified as timeout-unclassified.
It passed alone. The suite and `utils/py/turn_diagnostics.py` are unchanged across the
GH-791 batch. This is distinct from GH-502's security-dialog detection failure.

## Evidence and verification

See `TESTS-RESULTS/2026-09-24+GH-791/idle-parallel.log`, `idle-alone.log`, and provenance.
Reproduce in a disposable full clone with `bash validate.sh`; compare with
`bash test/gh492-idle-kill.sh` alone. Root cause remains unverified. No runtime fix is in GH-791.

## Merge evidence

- PR #794 merged 2026-09-25 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
