---
issue: 341
source: https://github.com/HiQS-Labs/XYZ-forge/issues/341
title: "CI: attest Linux as an unprivileged user — the canary's 14 failures are almost all EUID=0 artifacts"
created: 2026-09-02
type: project
status: 1-INBOX
complexity: 3
risk: 2
effort: 3
phases: 1
---

# GH-341 · Attest Linux as an unprivileged user

## Why

Parked here on 2026-09-02 because the operator dropped **a green Linux full test suite to priority
2**, to be revisited once XYZ is bug-free on macOS. #341 was cut from the cancelled `0.7.4 Linux-RC`
manifest along with the rest of that release, and unlike the five non-Linux items it was deliberately
**not** re-homed into `0.9.0 Cargo`.

That left it dialed into no release, with no target date, in no plan — invisible. This capture and its
roadmap row are the fix for that: **deprioritized is not the same as forgotten.**

The work itself is unchanged and still worth doing. The canary's own numbers say why:

- **5,326 passing / 14 failing** on the hosted Ubuntu runner
- ~9 failures are `EUID=0` artifacts — root writes a `0444` file and reads a `0000` file regardless
  of mode bits, so every mode-based negative assertion collapses (`test/gh50-sandboxed-git-guard.sh`
  ×8, `test/security-scan.sh` ×2)
- 1 is `builder binary 'agy' not found on PATH`
- 1 is a negative control that could not fire ("worktree setup unexpectedly succeeded") — same
  root-privilege class
- 2 are lock/concurrency timing, which is the [[gh-123]] shape and is genuinely unresolved
- 1 tier-classifier assertion, unknown

**Zero of the 14 have been shown to be genuine Linux portability defects.** That is the finding, and
it is what makes this a measurement problem before it is a portability problem.

## Key Concepts

- #249 establishes *that* root defeats the mode-based assertions. #341 is the piece #249 does not
  cover: **where** a non-root run actually happens.
- The canary is no longer permanently red — recent runs alternate pass/fail. The mode-bit failures
  are deterministic, so the alternation means something else is flapping, and a non-root host is the
  instrument that would separate the two.
- The two lock/timing failures cannot be attributed without a differently-sized, non-root host. They
  are the only failures in the set that might be real.

## Non-goals

- Making the canary a merge gate. It is `continue-on-error: true` by design and #347 moved it off
  the pull-request path onto `push`-to-`development`.
- Fixing the mode-based assertions by weakening them. Running as a non-root user is the fix; rewriting
  `0444`/`0000` assertions to pass as root would delete the property they exist to prove.
- The `gh358` lock defect itself — that is #123, closed as deferred on the same decision.

## Related

- #249 (root defeats mode-based negative assertions — the *what*)
- #123 (closed 2026-09-02 as deferred; the two lock/timing failures are its shape)
- #347 (canary relocated to `push`-to-`development`, so hosted runs now happen unattended)
- #224 (Linux MVP RC umbrella — its Phase 3 "qualifying hosted run" hunt is satisfied and red)
- `0.7.4 Linux-RC` — cancelled 2026-09-02; this issue was cut from its manifest and intentionally
  not re-homed
