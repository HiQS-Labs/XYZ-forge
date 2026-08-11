---
gh_issue: 391
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/391
title: "GH-391 — nothing generates MARATHON.yaml, so every multi-phase run starts with an undocumented hand-authoring step"
status: "2-WORKING — captured 2026-08-10 for release 0.3.0 Nightwatch, wave 2. Acceptance criteria authored onto the issue (it had none). Awaiting preflight."
created: 2026-08-10
updated: 2026-08-10
owner: noel
doc_type: project
release: "0.3.0 Nightwatch"
complexity: 3
risk: 2
effort: 3
phases: 1
ratings_provisional: true
roadmap_exempt: false
related:
  - "#340 — the marathon-plan renderer rework that produced `utils/py/_marathon_plan.py`, the native stdlib engine this lane extends. The natural home for an emitter."
  - "#359 — the plan omits the write-sets that determine wave grouping: the same information a `depends_on` emitter needs."
  - "#362 — made `utils/marathon-plan.sh` the 12th FROZEN twin. This lane must not touch it."
non_goals:
  - "Editing `bin/marathon-yaml`. It is this lane's acceptance ORACLE — a lane that changes both the producer and the validator that judges it can satisfy itself."
  - "Editing the planner at all — `utils/marathon-plan.sh`, `utils/py/marathon_plan.py` or `utils/py/_marathon_plan.py`. `test/marathon-plan.sh` Scenario T enforces CROSS-LANE BYTE PARITY between the Bash and Python engines (`:677-712`, with a mutation control), so a Python-only edit goes red inside this lane's own pre-advance gate, and a both-sides edit needs a `Frozen-twin-exception:` trailer on a file the repo is retiring. The emitter is therefore a NEW standalone script. This reversed the first draft's scope."
  - "Hosting the emitter on `marathon-plan`. It runs BEFORE `swarm-preflight` produces the packets, so `--emit-yaml` there would read a directory that does not exist yet — an ordering problem, not a preference."
  - "The generated plan document's 'How to fire a lane' section. It names only the single-lane route (`utils/py/_marathon_plan.py:1317`) and should be fixed, but not here — it is inside the parity-locked renderer."
  - "The `/10days` skill note from the issue body. A separate documentation question about which runner that skill targets."
  - "Changing how a marathon RUNS. This lane produces an input file; it does not touch marathon.sh, marathon-drive, or any turn shim."
goal: >
  XYZ has two runners. Every generated artifact feeds the single-lane one (`marathon-drive`), and the
  multi-phase one (`marathon.sh`) consumes a `MARATHON.yaml` that nothing in the harness generates —
  grepping the tree for it returns only readers. So a per-lane run is scripted end to end and a
  multi-phase run begins with hand-authoring, a step that appears in no skill, no generated document
  and no packet. Every field the YAML needs already exists in a generated artifact; this is a missing
  join, not a judgement call.
---

# GH-391 · the multi-phase runner consumes a file nothing produces

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10 as a lane of release 0.3.0 Nightwatch wave 2. **Acceptance criteria authored onto the issue** — it had none. **The claim was re-verified against the tree rather than taken from the issue:** the plan document's "How to fire a lane" section is emitted at `utils/py/_marathon_plan.py:1317` and names only the single-lane route. | Preflight, then fire as phase 2 of 2 — **after** GH-392, because this is the lane with actual code in it. |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/391

## The defect, and the evidence for it

Two runners, one scripted path:

```
marathon-drive  --phase-brief <packet>/packet.md ...     # ONE lane.   No YAML.
marathon.sh     --plan MARATHON.yaml ...                 # N phases.   YAML required.
```

The generated pipeline points exclusively at the first. `utils/py/_marathon_plan.py:1317-1329`
renders **"## How to fire a lane"** with a two-line pipeline — `swarm-preflight` then
`marathon-drive` — and never mentions `marathon.sh`. So an operator who reads the generated plan
document end to end never learns the multi-phase runner exists.

**This lane's own author hand-wrote two `MARATHON.yaml` files on 2026-08-10** (Nightwatch wave 1 and
this wave) — which is the issue reproducing itself during the release that contains it.

### The join is mechanical, except for one field

| YAML field | Source | Derivable? |
|---|---|---|
| phase order / `id` | the plan's score-ascending lane ranking, which is also its wave order | yes |
| `brief` | the packet path, `relay-system/preflight/<date>/<slug>/packet.md` | yes |
| `artifact` | the packet's declared artifact paths | yes |
| `depends_on` | an actual recorded dependency; absent when there is none | yes |
| `reviewer` | operator choice | **no** |

**One correction to the issue's framing, found by review:** `depends_on` is *not* about parallelism.
Phases run one at a time regardless — README's "Do phases run in parallel?" says so outright, and
wave 1's own plan repeats it. The harm from emitting it wrongly is that a fabricated dependency is
indistinguishable from a real one in the emitted file, silently misreporting the plan's causal
structure. The first draft of criterion 5 got this backwards.

**The two-source join is why no naive converter was ever written.** The plan document supplies
*ordering*; the packets supply *everything needed to execute*. A converter reading only the plan
`.md` has no brief paths and cannot produce a valid file — so the obvious implementation is the one
that cannot work, and an operator is unlikely to reconstruct the step unaided.

## Acceptance

*Copied verbatim from [issue #391](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/391) (`## Acceptance`), fetched 2026-08-10 after the revision below. Deviations, if any, are recorded in the same block.*

*Revised 2026-08-10 after an adversarial codex + agy consult on the first draft. Both advisors
independently returned the same two Blockers, and both were verified against the source before
rewriting — see "Draft defects found by review" below. The scope also changed as a result.*

**Scope: a NEW standalone emitter. No existing renderer or validator is edited.**

- `bin/marathon-yaml` is the acceptance ORACLE and must not be modified — a lane that changes both
  the producer and the validator that judges it can satisfy itself.
- `utils/marathon-plan.sh` and `utils/py/marathon_plan.py` / `utils/py/_marathon_plan.py` must not be
  modified. `test/marathon-plan.sh` Scenario T enforces **cross-lane byte parity** between the Bash
  and Python planner engines (`test/marathon-plan.sh:677-712`, with a mutation control proving the
  comparison is genuinely cross-lane). Editing the Python renderer alone breaks that test; editing
  both requires a `Frozen-twin-exception:` trailer on a Bash file the repo is retiring. Neither is
  worth it for this lane, so the emitter is a separate script.
- The planner is also the wrong host on ordering grounds: `marathon-plan` runs **before**
  `swarm-preflight` produces the packets, so `--emit-yaml` there would read a directory that does not
  exist yet.
- Deferred to their own work, explicitly not satisfied here: the generated plan document's "How to
  fire a lane" section (it names only the single-lane route today, at
  `utils/py/_marathon_plan.py:1317`), and the `/10days` skill's runner note.

- [ ] One documented command produces a `MARATHON.yaml` from an existing plan document plus a preflight packet directory, with no hand-authoring step between them. Producing a file an operator must then edit does not satisfy this.
- [ ] The emitted YAML is accepted by the existing `bin/marathon-yaml` validator, unmodified, **and** by `marathon.sh --dry-run`. The validator alone is not a sufficient oracle: it enforces only `id` and `reviewer` (`bin/marathon-yaml:91-94`), so a YAML with no `brief` and no `artifact` passes it and still cannot run. Both checks must be against unchanged runtime code.
- [ ] The emitter populates `brief` and `artifact` from the packet material — they are the fields the validator does **not** check, which is exactly why the emitter is responsible for them. `id` and phase order come from the plan's lane ranking. This is an emitter contract, not a restatement of what the validator enforces.
- [ ] `reviewer` is supplied by an explicit operator flag, and the emitted value is the supplied value, in a form the validator accepts (it must start with `codex`, `gemini`, or `agy`). Silently defaulting it would put an unreviewed choice into an unattended multi-hour run.
- [ ] `depends_on` is emitted only where the plan records an actual dependency, and is absent where none exists. **Phases run one at a time regardless** (README "Do phases run in parallel?"; `depends_on` constrains order, it does not create it), so this is not about preserving parallelism — it is that a fabricated dependency is indistinguishable from a real one in the emitted file and silently misreports the plan's causal structure. It must also be emitted in the scalar single-id form the reader accepts; the list form `[p1]` is rejected.
- [ ] A packet that is missing, malformed, duplicated, or does not correspond to a lane in the plan is a loud failure at emit time that names the offending packet. `marathon.sh` checks each `brief` inside its phase loop, so a bad path in phase 5 is discovered only after phases 1-4 have already run and committed.
- [ ] The lane ships a test that emits from a fixture plan + packet pair and asserts both oracles accept the result, **plus a negative control observed failing**: a fixture whose packets are absent must be rejected by the emitter, and that rejection must be demonstrated, not merely asserted. A generator whose only test is "it produced a file" is not evidence.
- [ ] The emitter writes only the path it is given and leaves the plan document, the packets, and every existing script byte-identical. A test asserts this, because an emitter that helpfully "fixes" its inputs is a mutation nobody asked for.

### Draft defects found by review

Recorded because the first draft would have been graded against them:

1. **Criterion 3 asserted the validator requires `brief` and `artifact`. It does not** — `bin/marathon-yaml:91-94` throws only on a missing `id` or `reviewer`. Rewritten as an emitter contract, and criterion 2 now adds `marathon.sh --dry-run` as the second oracle.
2. **Criterion 5 claimed a `depends_on` on every phase would "remove all parallelism". There is no parallelism to remove** — phases are strictly serial. Rewritten around misreported causal structure, which is the real harm.
3. **The original "Python-only" scope was impossible**, not merely awkward: Scenario T's cross-lane parity check would have gone red inside the lane's own pre-advance gate.

## Litmus tests

- **"It emitted a file" is not evidence.** Neither is "the file validated" — see criterion 5.
- **The emitter must fail before a run starts, not during one.** A YAML with a `brief` path that does
  not exist passes shape validation and dies after the driver has already seeded a token and begun
  dispatching. That is criterion 6, and it is the difference between a bad input and a wedged run.
- **If the emitter turns out to need `bin/marathon-yaml` changes**, stop and re-file rather than
  editing the oracle. That is a signal the join is not as mechanical as the issue claims, which is a
  finding worth more than the lane.

## Reversibility & blast radius

**Low, but NOT "inert" — the first draft's claim was wrong and the correction is worth stating.**

The draft said nothing a running marathon executes touches this lane. An adversarial codex + agy
consult produced the counterexample, independently and identically, and it holds: every phase's
pre-advance gate is `bash validate.sh`, `validate.sh:161` runs `test/marathon-plan.sh`, and that test
invokes the planner. So planner code **is** executed inside a live run — which is precisely why this
lane no longer touches the planner.

What remains is contained rather than inert. The new emitter's own test runs in the gate like any
other, so a defect turns that phase's gate red and escalates it. That is a *contained* failure, not a
wedge: unlike a turn-kernel change, it cannot break the reviewer turn inside its own phase, and
because this lane runs last, nothing downstream is affected either.

Additive otherwise: one new script, one new test, one `validate.sh` registration.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "path_absent", "path": "test/gh391-emit-marathon-yaml.sh" },
    { "type": "path_absent", "path": "utils/py/marathon_yaml_emit.py" }
  ],
  "artifacts":     ["utils/py/marathon_yaml_emit.py", "test/gh391-emit-marathon-yaml.sh", "validate.sh"],
  "artifacts_new": ["utils/py/marathon_yaml_emit.py", "test/gh391-emit-marathon-yaml.sh"],
  "remediation":   { "source": "issue #391", "criteria": "a NEW standalone emitter joins the plan's ordering with the preflight packets to produce a MARATHON.yaml that both bin/marathon-yaml and marathon.sh --dry-run accept — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
  "lanes": { "agy_safe": ["utils/py/marathon_yaml_emit.py", "test/gh391-emit-marathon-yaml.sh", "validate.sh"], "orchestrator_only": [] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): both `path_absent` probes report the fix
as still required while the emitter and its test do not exist, and stop reporting once the lane lands.

**Four paths are deliberately absent from `artifacts`, and the omissions are the design:**
`bin/marathon-yaml` is the oracle; `utils/marathon-plan.sh` is a frozen twin; and
`utils/py/marathon_plan.py` / `_marathon_plan.py` are parity-locked to it by Scenario T. A builder
that finds itself needing any of them should escalate rather than widen its own allowlist — that need
would mean the join is not as mechanical as the issue claims, which is a finding worth more than the
lane.

## Provenance

Filed from the plan-build report in #363. Promoted to `2-WORKING` 2026-08-10 as part of Nightwatch
wave 2 ([MARATHON-2026-08-10-NIGHTWATCH-WAVE-2](MARATHON-2026-08-10-NIGHTWATCH-WAVE-2/MARATHON.yaml)).
Wave 1 (GH-358 Phase 1) shipped in PR #489.
