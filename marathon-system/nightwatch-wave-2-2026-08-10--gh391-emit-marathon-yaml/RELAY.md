# Marathon Phase gh391-emit-marathon-yaml
STATUS: Approved
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-GH391-EMIT-MARATHON-YAML-TURN builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

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


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/marathon_yaml_emit.py,test/gh391-emit-marathon-yaml.sh,validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): ~/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - ~/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH391-EMIT-MARATHON-YAML-TURN --agent codex --paths "marathon-system/nightwatch-wave-2-2026-08-10--gh391-emit-marathon-yaml/RELAY.md,utils/py/marathon_yaml_emit.py,test/gh391-emit-marathon-yaml.sh,validate.sh"
   - ~/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH391-EMIT-MARATHON-YAML-TURN --agent codex
   - ~/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH391-EMIT-MARATHON-YAML-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/nightwatch-wave-2-2026-08-10--gh391-emit-marathon-yaml/RELAY.md and utils/py/marathon_yaml_emit.py,test/gh391-emit-marathon-yaml.sh,validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/marathon_yaml_emit.py,test/gh391-emit-marathon-yaml.sh,validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: ~/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH391-EMIT-MARATHON-YAML-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: ~/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH391-EMIT-MARATHON-YAML-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: ~/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY marathon-system/nightwatch-wave-2-2026-08-10--gh391-emit-marathon-yaml/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

### Round 1 · Builder · codex

- Touched: `utils/py/marathon_yaml_emit.py`, `test/gh391-emit-marathon-yaml.sh`, `validate.sh`, and this relay record only.
- Added the standalone documented `--plan` + `--packets` + explicit `--reviewer` + `--output` command. It reads the generated plan's canonical score-ascending `Per-item scoring` table, derives stable `gh<issue>` ids and order there, and joins each lane to exactly one ready packet for its `brief` and exact `Artifacts:` value.
- Preserved causal fidelity: only a single dependency explicitly recorded in the plan becomes scalar `depends_on`; multiple or out-of-plan dependencies fail before output instead of being guessed.
- Made the join fail loud before writing for missing, malformed, duplicate, and unmatched packets, with the lane or packet path in the error. The output path is rejected if it aliases an input, and no parent directory is created implicitly.
- Registered the focused test in `validate.sh`. Verification: `bash test/gh391-emit-marathon-yaml.sh` passed **13/13**, including both unchanged oracles (`bin/marathon-yaml` and `marathon.sh --dry-run`), the observed absent-packet negative control, the other three packet refusal classes, explicit reviewer/dependency checks, and byte-identical inputs/output-only writes.
- Per the phase containment instruction, the full `validate.sh` gate was not run; the harness owns that gate after handoff.

### Round 1 · Reviewer · agy

swept file: yes
I have reviewed `utils/py/marathon_yaml_emit.py`, `test/gh391-emit-marathon-yaml.sh`, and `validate.sh`.
- The emitter script meets all the acceptance criteria. It validates the packets, requires them to correspond to the lanes, correctly extracts the exact fields, handles scalar dependencies, fails loud with clear error messages mentioning the lanes and offending files, and safely outputs the YAML.
- The negative control tests correctly demonstrate the refusal for absent, malformed, duplicate, and unmatched packets, ensuring no yaml is outputted for invalid states.
- The `validate.sh` was swept, and no pre-existing defects were found in the file; the test was cleanly appended to the `TESTS` array.

**Verdict:** Approved
