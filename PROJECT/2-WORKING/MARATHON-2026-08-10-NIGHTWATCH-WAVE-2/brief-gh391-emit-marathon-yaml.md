---
title: "Phase brief: GH-391 gh391-emit-marathon-yaml (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-08-10
updated: 2026-08-10
owner: noel
goal: >
  Phase-brief input consumed by the marathon driver for the gh391-emit-marathon-yaml phase of
  MARATHON-2026-08-10-NIGHTWATCH-WAVE-2 — not itself an active-doc capture; the canonical capture doc
  is GH-391-EMIT-MARATHON-YAML.md two levels up.
roadmap_exempt: true
---

# Brief — GH-391: build the emitter for the file the multi-phase runner needs and nothing produces

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10. Acceptance criteria **authored onto the issue** (it had none), then **rewritten after an adversarial codex + agy consult** returned three Blockers — two false premises and an impossible scope. All three were verified against the source before the rewrite. Preflight: **ready (exit 0)**, acceptance **8/8 verbatim**, issue **OPEN**. | Fire as phase 2 of 2, last, because it is the only lane in this wave with executable code. |

**Parent capture doc:** `PROJECT/2-WORKING/GH-391-EMIT-MARATHON-YAML.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/391

## Acceptance

**Read the acceptance criteria from the parent capture doc's `## Acceptance` block** — all eight,
carried verbatim, including the scope preamble. The preamble is not decoration; three of its bullets
are the output of a review that caught the first draft being unbuildable.

## The defect

XYZ has two runners. Every generated artifact feeds the single-lane one:

```
marathon-drive  --phase-brief <packet>/packet.md ...     # ONE lane.   No YAML.
marathon.sh     --plan MARATHON.yaml ...                 # N phases.   YAML required.
```

Grepping the tree for `MARATHON.yaml` returns **only readers**. So a per-lane run is scripted end to
end, and a multi-phase run begins with an undocumented hand-authoring step. The author of this very
wave hand-wrote two `MARATHON.yaml` files on 2026-08-10 — the issue reproducing itself inside the
release that contains it.

## Build a NEW standalone script. Do not touch the planner.

`utils/py/marathon_yaml_emit.py`, new. This is not a style preference — the obvious homes are all
closed, and the reasons are checkable:

- **`utils/py/marathon_plan.py` / `_marathon_plan.py` are parity-locked.** `test/marathon-plan.sh`
  Scenario T (`:677-712`) enforces **cross-lane byte parity** with the Bash engine and carries a
  mutation control proving the comparison is genuinely cross-lane. A Python-only edit turns that test
  red — **inside this lane's own pre-advance gate**.
- **`utils/marathon-plan.sh` is the 12th frozen twin** (GH-362). Editing it needs a
  `Frozen-twin-exception:` trailer on a file the repo is retiring.
- **`marathon-plan` is the wrong host on ordering grounds anyway**: it runs *before*
  `swarm-preflight` produces the packets, so `--emit-yaml` there would read a directory that does not
  exist yet.

## Two oracles, and one of them is not enough

**`bin/marathon-yaml` alone will not tell you the file works.** It enforces only `id` and `reviewer`
(`bin/marathon-yaml:91-94`) — a YAML with no `brief` and no `artifact` passes it and still cannot
run. So the emitter is responsible for exactly the fields the validator does *not* check.

Validate against **both**, unmodified:

```
bin/marathon-yaml <emitted>          # shape
marathon.sh --plan <emitted> --dry-run   # the runtime's own reading of it
```

**Do not modify either.** A lane that changes both the producer and the validator that judges it can
satisfy itself.

## The framing correction that matters most

`depends_on` **is not about parallelism.** Phases run one at a time regardless — README's
"Do phases run in parallel?" says so outright, and this wave's own plan repeats it. The first draft
of criterion 5 claimed that emitting `depends_on` everywhere would "remove all parallelism"; there is
no parallelism to remove.

The real harm is that a fabricated dependency is **indistinguishable from a real one** in the emitted
file, so the YAML silently misreports the plan's causal structure. Emit it only where the plan
records an actual dependency, and in the scalar single-id form (`depends_on: p3`) — the list form
`[p3]` is rejected by the hand-rolled reader.

## The negative control is the deliverable

A generator's happy path is trivially green. "It emitted a file" is not evidence, and neither is
"the file validated" — see the `depends_on` point above.

`test/gh391-emit-marathon-yaml.sh` must emit from a fixture plan + packet pair, assert **both**
oracles accept it, and then **observe the emitter refusing** a fixture whose packets are absent. That
refusal must be demonstrated, not asserted.

## Fail before the run, not during it

`marathon.sh` checks each `brief` **inside its phase loop** (`:186`), so a bad path in phase 5 is
discovered only after phases 1-4 have already run and committed. A packet that is missing, malformed,
duplicated, or does not correspond to a lane in the plan must be a loud failure **at emit time**,
naming the offending packet.

## Write-set

| File | Note |
|---|---|
| `utils/py/marathon_yaml_emit.py` | **new** — the emitter |
| `test/gh391-emit-marathon-yaml.sh` | **new** — happy path against both oracles + the observed refusal |
| `validate.sh` | register the new test in `TESTS=()`; it does **not** glob `test/` |

**Absent on purpose:** `bin/marathon-yaml` (oracle), `utils/marathon-plan.sh` (frozen twin),
`utils/py/marathon_plan.py` and `_marathon_plan.py` (parity-locked). If you find yourself needing any
of them, **escalate instead of widening your allowlist** — that need would mean the join is not as
mechanical as the issue claims, which is a finding worth more than the lane.
