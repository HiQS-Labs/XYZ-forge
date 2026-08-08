---
title: "Phase brief: GH-390 gh390-gate-guard-coverage (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-08-08
updated: 2026-08-08
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh390-gate-guard-coverage
  phase of MARATHON-2026-08-08-LITMUS-WAVE-2 — not itself an active-doc capture; the canonical
  capture doc is GH-390-GATE-GUARD-COVERAGE.md two levels up.
roadmap_exempt: true
---

# Brief — GH-390 remainder: the guard's other half has never been seen to fire

## Status

| What was just completed | What's next |
|---|---|
| **Phase 1 of #390 shipped in PR #393** — process-group kill, kernel CPU cap, RSS watchdog, `gate-killed` attribution with `GATE_GUARD_KILL_EXIT = 108`, and the soft/hard split (`GATE_CPU_HARD_MARGIN_S = 5`). Verified live 5x during the Litmus wave-1 marathon. Contract authored 2026-08-08 and verified READY; the acceptance list is reconciled against the issue with 15 declared deviations. | Fire as phase 3 of 3, **last**, because it changes the gate path every earlier phase depends on. |

**Parent doc:** `PROJECT/2-WORKING/GH-390-GATE-GUARD-COVERAGE.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/390

## Acceptance

**Read the acceptance criteria from the parent capture doc's `## Acceptance` block.** They are **not**
a verbatim copy of the issue's, and that is deliberate: eight of the issue's nine criteria shipped in
PR #393. The doc's `## Acceptance — deviations from the issue` section reconciles the two lists
item-by-item — read it, then work from the doc's seven criteria.

**Do not re-implement the guard.** It works. It fired correctly against a real runaway and runs on
every gate invocation. This lane is **criterion 8 only**, plus the coverage that makes criterion 8
checkable.

## The defect

`test/gh390-gate-guard.sh` can only observe the signal **its own host kernel** produces. The guard
maps two distinct kernel behaviours onto one verdict:

| platform | mechanism | signal seen | shape bash reports |
|---|---|---|---|
| macOS (BSD) | soft `RLIMIT_CPU` | `SIGXCPU` | `128+24` forked, `-24` exec-optimised |
| Linux | `posix_cpu_timers` checks the **hard** limit first | `SIGKILL` | `128+9` / `-9` |

So on macOS the Linux branch is dead code to the test, and vice versa. **One half of the attribution
logic has never been observed firing on the machine that runs the suite.** Per #419 that is not
evidence; and #407 is precisely about this verdict being wrong — a resource kill reported as the gate
having found a defect in the change.

**That exact branch already cost a day.** On 2026-08-07, PR #393's CI failed only on Linux. The first
fix mapped a second SIGXCPU exit shape and CI failed identically, because `ulimit -t N` sets soft
**and** hard together, so Linux never delivers SIGXCPU at all. What produced the answer was a
diagnostic commit printing the actual exit code (`gate exit -9`) — observing the branch, not
reasoning about it.

## Two structural blockers, both measured — these are the real work

1. **The gate's runnability pre-check rejects a literal `exec`** in `--pre-advance-cmd`, so the
   exec-optimised shape (`-24` / `-9`) cannot be forced from a test.
2. **The guard helpers are nested inside `main()`** — `_gate_guard_config`, `_gate_kill_group` and
   `run_pre_advance_gate` are all local (see `utils/py/marathon_drive.py`, the four-space-indented
   `def _gate_guard_config`), so there is no unit hook to drive a branch with a synthesised return
   code.

Together these mean the only way to reach a branch today is to be running on the kernel that produces
it. The current mitigation is a `COVERAGE CAVEAT` comment in the suite plus the failure printing its
exit status — which is what made the CI diagnosis possible, and is a mitigation, not coverage. Both
`fix_probes` for this lane target exactly these two facts.

## What to build

- **Phase 1 — the seam.** Lift the guard helpers out of `main()` (or expose an equivalent hook) so
  the signal→verdict mapping can be driven directly with a synthesised return code, and cover **both**
  branches plus both bash shapes on one machine.
- **Phase 2 — criterion 8, recorded.** Drive the guard against the **GH-382 runaway shape itself**
  (`MagicMock` in a `while True` loop), not a synthetic substitute, and commit the observed kill as a
  durable baseline: reproducer, revision, pre-fix and post-fix results.
- Add the `# gate-evidence:` declaration to `test/gh390-gate-guard.sh` so GH-419's inventory reports
  a declared, observed control instead of `none`.

## Litmus tests for this lane

- **The point is the branch nobody has seen.** A suite that adds assertions only for the local
  kernel's branch raises the pass count and changes nothing about the risk. That is a failed turn.
- **Do not "fix" this by widening what counts as `gate-killed`.** Mapping more signals to
  `gate-killed` would make both branches pass and would reintroduce #407 from the other direction —
  a real gate failure reported as a resource kill.
- **A passing gate must stay unaffected.** The real-gate runs are 704-806s and must stay green. A
  change that makes the guard trigger-happy would satisfy every coverage criterion and must fail this
  one.
- **Do not touch the caps.** They are load-bearing at ~704-806s against a 900s wall cap (~20%
  headroom, shrinking as each lane adds a suite). A coverage change that also nudges a cap confounds
  two things at once.
- **`relay-automation/marathon-drive.sh` is a GH-308 frozen twin.** The Python lane is the default
  (GH-264) and is what runs. Do not modify the Bash twin; this lane has no
  `Frozen-twin-exception:` trailer and does not need one.

## Scope

`utils/py/marathon_drive.py`, `test/gh390-gate-guard.sh`, `validate.sh`.

**Sequencing note you are entitled to know:** this is the last phase of the marathon precisely because
you are changing the code that runs each phase's pre-advance gate. If the seam refactor breaks the
gate path, the failure lands on this phase's own gate and nothing downstream — which is the containment
this ordering buys. Do not take that as licence to be careless with it: a broken gate here reports as
`pre-advance-failed`, which is the exact mislabel #407 is about, so if your gate fails, check whether
you broke the guard before you conclude you broke the change.
