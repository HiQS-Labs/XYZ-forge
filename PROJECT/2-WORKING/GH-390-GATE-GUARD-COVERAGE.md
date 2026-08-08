---
gh_issue: 390
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/390
title: "GH-390 remainder — the gate guard's CPU-cap branch can only ever be observed on the kernel that produced it, so one half has never been seen to fire"
status: "Intake (2-WORKING) — captured 2026-08-08 for release 0.2.0 Litmus. Phase 1 (the guard itself) SHIPPED via PR #393. This doc is the REMAINDER: acceptance criteria 8's demonstration, which is currently impossible to run on either platform alone. Not yet preflighted, not yet fired."
created: 2026-08-08
updated: 2026-08-08
owner: noel
doc_type: project
release: "0.2.0 Litmus"
complexity: 3
risk: 2
effort: 3
phases: 2
ratings_provisional: true
related:
  - "#419 — this is that thesis applied to the guard itself: one of its two kill branches has never been observed firing anywhere."
  - "#407 — a resource kill must not read as the gate finding a defect. The branch that cannot be tested is the branch that decides which of those two it was."
  - "#383 — owns the wall-clock bound; out of scope here."
non_goals:
  - "Re-implementing the guard. It shipped in PR #393 and works: it fired correctly against a real runaway and is exercised on every gate run (observed 5x on 2026-08-07/08, exit 0 in 704-806s)."
  - "Adding a container. The issue puts gate-in-container explicitly out of scope for this lane."
  - "Changing the caps' values. The defect is coverage of the attribution branches, not the numbers."
goal: >
  The guard maps two different kernel behaviours onto one verdict: macOS delivers SIGXCPU on the soft
  RLIMIT_CPU, Linux checks the hard limit first and delivers SIGKILL. Both must be reported as
  gate-killed rather than as the gate finding a defect. But a test can only ever observe the signal its
  own kernel produces, so on any single machine one of the two branches is unreachable — and the Linux
  branch is the one that cost a day to find, because ulimit -t sets soft AND hard together.
---

# GH-390 remainder · a guard whose other half has never been seen to fire

## Status

| What was just completed | What's next |
|---|---|
| Phase 1 shipped in PR #393: process-group kill, kernel CPU cap, RSS watchdog, `gate-killed` attribution with a distinct exit code (`GATE_GUARD_KILL_EXIT = 108`), and the soft/hard split (`GATE_CPU_HARD_MARGIN_S = 5`) that made the Linux branch reachable at all. Verified live 5x during the Litmus marathon. | The coverage this lane exists for: make BOTH attribution branches observable, and satisfy criterion 8's "demonstrated against the loop that caused the observed panics, and the observed kill recorded per #419". Needs operator go and a preflight contract. |

## The defect

`test/gh390-gate-guard.sh` can only observe the signal **its host kernel** produces. The guard maps
two distinct shapes onto one verdict:

| platform | mechanism | signal seen | shape bash reports |
|---|---|---|---|
| macOS (BSD) | soft `RLIMIT_CPU` | `SIGXCPU` | `128+24` forked, `-24` exec-optimised |
| Linux | `posix_cpu_timers` checks the **hard** limit first | `SIGKILL` | `128+9` / `-9` |

So on macOS the Linux branch is dead code to the test, and vice versa. **One half of the attribution
logic has never been observed firing on the machine that runs the suite.** Per #419 that is not
evidence, and #407 is precisely about this verdict being wrong: a resource kill reported as the gate
having found a defect in the change.

**This is not hypothetical — that exact branch already cost a day.** On 2026-08-07, PR #393's CI failed
only on Linux. The first fix mapped a second SIGXCPU exit shape and CI failed identically, because
`ulimit -t N` sets soft **and** hard together, so Linux never delivers SIGXCPU at all. What produced
the answer was a diagnostic commit printing the actual exit code (`gate exit -9`) — i.e. observing the
branch, not reasoning about it. The fix is the `GATE_CPU_HARD_MARGIN_S` split now in the tree.

## Two structural blockers, both measured

1. **The gate's runnability pre-check rejects a literal `exec`** in `--pre-advance-cmd`, so the
   exec-optimised shape (`-24` / `-9`, where bash replaces itself and the shell reports the negative
   form) cannot be forced from a test.
2. **The guard helpers are nested inside `main()`** — `_gate_guard_config`, `_gate_kill_group`,
   `run_pre_advance_gate` are all local, so there is no unit hook to drive a branch directly with a
   synthesised return code.

Together these mean the only way to reach a branch today is to be running on the kernel that produces
it. Currently mitigated by a coverage caveat in the suite plus the failure printing the exit status —
which is what made the CI diagnosis possible, and is a mitigation, not coverage.

## Acceptance

Derived. Criteria 1-7 and 9 of issue #390 shipped in PR #393; this lane is **criterion 8** plus the
coverage that makes it checkable. If #390 gains a phase-scoped acceptance block upstream, replace this.

1. Both attribution branches are exercised on **one** machine — the signal-to-verdict mapping is
   reachable without needing the matching kernel, via a unit hook, an injected return code, or a
   documented equivalent. Reasoning about the unreachable branch does not satisfy this.
2. The guard's decision function is callable from a test without running a real marathon phase (the
   `main()`-nested helpers get a seam).
3. The exec-optimised shape is reachable from a test, or the pre-check's refusal of a literal `exec`
   is documented as deliberate and the shape is covered another way.
4. Criterion 8 of #390: the guard is demonstrated against **the loop that caused the observed panics**
   — the `MagicMock`-in-`while True` shape from GH-382 — not a synthetic substitute, and the observed
   kill is recorded per #419 with reproducer, revision and result.
5. A passing gate is still unaffected: the 704-806s real-gate runs stay green. A change that makes the
   guard trigger-happy would satisfy every criterion above and must fail this one.
6. Each branch is observed FAILING (i.e. mis-attributing) against a revision with the attribution
   deliberately inverted, so the assertions are shown capable of catching a wrong verdict.

## Phases

| Phase | Deliverable | Artifacts | cx/risk/eff |
|---|---|---|---|
| 1 | **The seam.** Lift the guard helpers out of `main()` (or expose an equivalent hook) so the signal→verdict mapping can be driven directly with a synthesised return code, and cover BOTH branches plus both bash shapes on one machine. | `utils/py/marathon_drive.py`, `test/gh390-gate-guard.sh` | 3/2/3 |
| 2 | **Criterion 8, recorded.** Drive the guard against the GH-382 runaway shape itself and commit the observed kill as a durable baseline: reproducer, revision, pre-fix and post-fix results. | `test/gh390-gate-guard.sh`, a baseline artifact, `validate.sh` | 2/2/2 |

## Litmus tests

- **The point is the branch nobody has seen.** A suite that adds assertions only for the local
  kernel's branch would raise the pass count and change nothing about the risk.
- **`marathon-drive.sh` is a GH-308 frozen twin.** The Python lane is the default (GH-264) and is what
  runs; a Bash-side change needs a declared `Frozen-twin-exception:` trailer or it must not happen.
- **Do not "fix" this by widening what counts as gate-killed.** Mapping more signals to `gate-killed`
  would make both branches pass and would reintroduce #407 from the other direction — a real gate
  failure reported as a resource kill.
- **Guard the guard's quietness.** The caps are load-bearing at ~704-806s against a 900s wall cap
  (~20% headroom, shrinking as each lane adds a suite). A coverage change that also nudges the caps
  would confound two things at once.

## Provenance

Found 2026-08-06 while reviewing PR #393's own test, and sharpened 2026-08-07 when the Linux-only CI
failure proved the unreachable branch was the one carrying the bug. Recorded then as a parked finding
rather than an issue, and promoted here on operator instruction 2026-08-08. #390 is already on the
Litmus milestone; this doc is the part of it that PR #393 did not close.
