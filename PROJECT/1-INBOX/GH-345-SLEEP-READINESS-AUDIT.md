---
issue: 345
source: https://github.com/HiQS-Labs/XYZ-forge/issues/345
title: "Sleep-vs-readiness audit: one confirmed race in the agent-chorus doorbell assertion, and the case against the paid Test Reliability tier"
created: 2026-08-31
type: bugfix
status: 1-INBOX
complexity: 2
risk: 1
effort: 1
phases: 1
---

# GH-345 · Sleep-vs-readiness audit

## Why

#344 concluded that of StarSling's six paid optimizations only **Test Reliability** (replace
hardcoded `sleep` with readiness checks) touches a real defect class here, and that the audit was
worth doing by hand before paying for a tier to do it. This is that audit, done, with the answer:
**one real site.**

`test/agent-chorus.sh:611` uses a bare `sleep 0.3` to wait for a backgrounded `python3` to stamp
`runtime/agent2.watch`, then asserts the marker exists. Measured on an **idle** 10-core
Apple-silicon box the assertion is red at 0.2 s and green at 0.3 s — **under 1.5x headroom**. On a
shared 8-core Linux runner working through 190 suites, that margin is a coin flip. It is exactly
the failure shape #123 exists to close.

The fix is four lines, and the correct idiom already appears **twice in the same file**
(`:235-238`, with the explicit comment "no fixed sleep", and `:497`).

## Key Concepts

- **Proof standard is mutation, not inspection or load.** Set the sleep to `0`; if the suite stays
  green the sleep synchronizes nothing and cannot flake. 19 candidate sites tested across 11 suites.
- **The load test was wrong and is reported anyway.** 40 spinners on 10 cores, 3 repeats of the
  three densest suites: **9/9 green** at ~2.2x wall-clock. Contention at that level never reaches
  these margins — a team running only the load test concludes there is no problem.
- **Three classes came out of it:** one defect (`agent-chorus.sh:611`); five load-bearing sleeps
  that are correct as written (three are filesystem-mtime granularity, which no readiness check can
  fix — the remedy there is `touch -t`, and it is tidying, not reliability); eight that order
  nothing at all.
- **Closes the open question in #344.** `.github/workflows/ci.yml` contains **zero** `sleep` calls,
  so there is nothing at the workflow level for a `ci.yml` optimizer to act on. Paired with
  GH-528's spike, which falsified the same hypothesis for wall-clock, the paid tier's yield here is
  one line of one test file. **Recommendation: do not buy it.**

## Non-goals

- Production pacing and watchdog sleeps in `relay-automation/` (`consult.sh:164`,
  `relay-turn-lib.sh:541`, `runner.sh:123`, `marathon-drive.sh:277`, `relay-loop.sh:237`). Mutating
  these tests the watchdog, not the flake.
- `test/agent-chorus.sh:635` — its `sleep 2.5` is a genuine measurement window (the marker must be
  observed *while* refreshing). Mutation confirms it is not fragile. It needs a comment saying so,
  not a fix.
- Windows portability.

## Related

- #344 (StarSling optimizations — this answers its open question)
- #123 (Linux canary remainder) · #224 (Linux MVP RC umbrella)
- GH-528 (the wall-clock counterpart; same hypothesis, same verdict)
- Evidence: `relay-system/2026-08-31/gh123-sleep-readiness-audit.md`
