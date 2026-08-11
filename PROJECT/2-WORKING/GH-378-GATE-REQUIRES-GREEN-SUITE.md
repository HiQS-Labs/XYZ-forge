---
gh_issue: 378
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/378
title: "GH-378 — a marathon's global gate cannot distinguish a repo's pre-existing failures from a new regression"
status: "2-WORKING — captured 2026-08-10 for release 0.3.0 Nightwatch. Acceptance criteria authored onto the issue (it had none). The issue's own leading fix ('a baseline allowance') requires extracting a failing-set from an arbitrary shell command's output, which is verified below to be an unsolved design question, not an implementation detail — this doc enumerates options and stops short of picking one. Blocked on an operator decision before Phase 2 (implementation) can be scoped or preflighted."
created: 2026-08-10
updated: 2026-08-10
owner: noel
doc_type: project
release: "0.3.0 Nightwatch"
complexity: 4
risk: 4
effort: 3
phases: 2
ratings_provisional: true
roadmap_exempt: false
related:
  - "#390 — GH-390's layered gate guard wraps the same `pre_advance_cmd` with ulimit/RSS-poll code (`utils/py/marathon_drive.py:1321-1406`). Whatever this issue lands must compose with that wrapping, not bypass it."
  - "#441 — `gate_env.py`'s scrub-or-pass contract (`utils/py/marathon_drive.py:1283-1290`) is the precedent for 'every variable the gate sees is classified with a reason.' A baseline mechanism that threads new state into the gate's environment or command needs the same discipline, not a silent addition."
  - "#308 — Frozen Bash twin governance. `utils/py/marathon_drive.py` is the authoritative Tier-A implementation; `relay-automation/marathon-drive.sh` is its frozen twin. A behavior change here lands in the Python file; touching the Bash twin needs a `Frozen-twin-exception:` trailer."
  - "This repo's own GH-170 (PROJECT/3-COMPLETED/GH-170-VALIDATE-FAILING-TESTS.md, SHIPPED 2026-07-21) is UNRELATED to the '#170' the issue's circular case names — that is `Hypercart-Dev-Tools/rebalance-OS`'s own issue #170, a different repo's issue tracker. Same number, different issue, verified by reading both. Flagged here because conflating them would corrupt this doc's own provenance the way GH-343 got burned."
non_goals:
  - "Choosing among the enumerated options (baseline allowance / fail-fast precondition / per-phase gate override / documentation-only). That is an explicit operator decision (Step 4 of this doc's own authoring brief), recorded under `decisions/`, not something a capture doc or a builder may pick."
  - "Fixing `Hypercart-Dev-Tools/rebalance-OS`'s own #170 (worktree tests importing the main checkout). That is the target repo's test-infrastructure defect, out of this repo's tree entirely."
  - "Any change to what `GATE_SCRUBBED_ENV` scrubs today (`utils/py/marathon_drive.py:1283-1290`, 17 names). Phase-blindness is a property the issue itself endorses keeping — a baseline mechanism must not leak phase identity into the gate to satisfy itself."
  - "Sizing or scoping Phase 2 (implementation). Its artifacts, diff shape, and even which files change depend entirely on which option Phase 1 selects — a plan that pre-commits Phase 2 before the decision exists would be grading the builder against an assumption this doc explicitly refuses to make."
goal: >
  `marathon.sh --plan` accepts one `--pre-advance-cmd` for an entire run (verified:
  `relay-automation/marathon.sh:118,126,214` threads a single `PRE_ADVANCE_CMD` value to every
  phase). Verified in `utils/py/marathon_drive.py`'s `run_pre_advance_gate()` (`:1321-1406`): the
  gate's result is an EXIT CODE ONLY — `subprocess.Popen` at `:1352-1353` never sets
  `stdout=`/`stderr=PIPE`, so the gate's own output streams straight through and is never captured or
  parsed. `gate_exit != 0` at `:1558` unconditionally escalates and halts (`sys.exit(5)` at `:1570`) —
  a phase whose own change is correct still halts if the repo had ANY pre-existing failure before
  phase 1 ran. That makes a marathon usable only against a repo whose suite already started green,
  which excludes most of the work a marathon exists to do — including, circularly, the class of fix
  (test-infrastructure lanes) that would repair the repo's own suite health. The issue's leading
  proposal is a "baseline allowance": record the target's known-failing set once, then pass a phase
  when its gate result is no worse than that baseline. This doc's job is to state plainly that
  extracting a *failing-set* from an *arbitrary shell command* is not solved by that sentence — a
  command yields an exit code, not a structured result — and to record the real options without
  picking one.
---

# GH-378 · a marathon's global gate cannot tell a pre-existing failure from a new one

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10. **Acceptance criteria authored onto the issue** — it had none. Every factual claim about the gate's mechanics was verified against `utils/py/marathon_drive.py` and `relay-automation/marathon.sh` directly (not repeated from the issue's prose), including that the issue's own quoted `GATE_SCRUBBED_ENV` snippet (3 names) is now stale against the live 17-name tuple. The "extract a baseline failing-set from an arbitrary command" step is confirmed unsolved rather than assumed solvable, and left an open decision. | **Operator decision required first**: pick one of the four options below (or name a different one) and record it under `decisions/`. Only then can Phase 2 (implementation) be scoped, artifacted, and preflighted. Neither phase may be dispatched as a marathon/relay lane — see Reversibility & blast radius. |

**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/378

## The defect

**One gate command covers an entire plan, not one phase.** `utils/py/marathon_drive.py:409` declares
`--pre-advance-cmd` as a single `argparse` flag; `relay-automation/marathon.sh:118` initializes one
`PRE_ADVANCE_CMD` variable for the whole `--plan` run, and `:214` forwards that same value to every
phase's `marathon-drive.sh`/`marathon_drive.py` invocation via `--pre-advance-cmd`. There is no
per-phase gate today — confirmed by reading the flag's full lifecycle, not inferred from the issue.

**The gate's result is an exit code, and nothing else.** `run_pre_advance_gate()`
(`utils/py/marathon_drive.py:1321-1406`) launches the command with
`subprocess.Popen(cmd, shell=True, executable="/bin/bash", cwd=cwd, env=env, start_new_session=True)`
at `:1352-1353` — no `stdout=` or `stderr=PIPE`, so the gate's own output is inherited straight
through to the driver's terminal/log and is **never captured, stored, or parsed** by the function.
The only thing the driver retains is `rc`, mapped to `run_gate_result[0] = "green"/"red"` at `:1406`
(and identically at `:1332` on the guard-disabled path). At the call site, `:1557-1570`:
`gate_exit = run_pre_advance_gate()`; any nonzero value calls `escalate("pre-advance-failed", 0)` and
`sys.exit(5)` — one binary halt, no partial credit, no distinction between "this phase's change broke
something" and "the repo was already red before phase 1 started."

**This is true of the harness's own canonical gate, not just a hypothetical target repo's.**
`validate.sh` (repo root) is itself an aggregate `bash` loop over ~30 shell test scripts, reduced to a
single 0/1 exit code with `set -u` (deliberately without `-e`, per `GUIDING-PRINCIPLES.md`'s
strict-mode convention) — no JUnit/TAP/JSON output anywhere in this repo (checked:
`/usr/bin/grep -rl "junit\|TAP output\|junitxml"` across `.sh`/`.py`/`.md` returns nothing). So "parse
the gate's failing set" is not a problem only for target repos with unusual test runners; it is a
problem for this harness's own default gate.

**`swarm-preflight` already sees a per-packet `gate` value — and actively rejects disagreement.**
`utils/py/swarm_preflight.py`'s `merge_contracts()` reads `c["gate"]` per contract (`:116`) and, when
bundling several packets into one plan, requires every packet's gate to be byte-identical: `if
c["gate"] != out["gate"]:` exits 7 with `"bundle disagreement: gate commands differ"` (`:129-131`).
That is the concrete cost of the issue's own Option 3 (a per-phase `gate:` field): it is not merely
adding a field, it is loosening a consistency check the bundler currently depends on for a different
reason — making sure every packet in a plan agrees what "the gate" means before the plan is trusted.

**The env-scrubbing the issue cites is real but has grown since the issue was filed.** The issue
quotes `GATE_SCRUBBED_ENV = ("XYZ_HARNESS_CONTEXT", "XYZ_SESSION_ID", "MARATHON_LANE_NS")` — three
names. The live tuple at `utils/py/marathon_drive.py:1283-1290` (post GH-441 Phase 2) has **17**
names (`AGY_AGENT`, `AIDER_AGENT`, `ALLOW_PATHS`, `CLAUDE_AGENT`, `CODEX_AGENT`, `MARATHON_BUILDER`,
`MARATHON_LANE_NS`, `MARATHON_REVIEWER`, `RELAY_AGENT`, `PI_AGENT`, `RELAY_ARTIFACT_FILE`,
`RELAY_FILE`, `RELAY_PEER`, `RELAY_TARGET_ROOT`, `RELAY_TASK`, `RELAY_WORKTREE_ISOLATION`,
`XYZ_HARNESS_CONTEXT`, `XYZ_SESSION_ID`), governed by `test/gh441-gate-env-contract.sh`'s
scrub-or-pass classification contract. The issue's underlying claim — the gate cannot see which phase
it is gating — is still true; its code sample is not current. Noted so this doc does not repeat a
stale quotation as if it were verified.

**"No worse than baseline" already exists in this repo — as a human-read prose idiom, never a
mechanism.** `/usr/bin/grep -rn "no worse than baseline"` across `PROJECT/` and `relay-system/`
returns 20+ acceptance criteria (e.g. `PROJECT/3-COMPLETED/GH-189-...md:109`,
`GH-239-...md:92`) that all read `bash validate.sh` no worse than baseline, with the baseline named
in prose ("the two known environmental reds — acorn-extract.sh and pytest") and checked by a human
comparing a fresh run's output to that sentence. Nothing in `marathon_drive.py`, `marathon.sh`, or
`swarm_preflight.py` automates this comparison. GH-378 is asking for exactly the judgment call
operators already make by eye, made machine-checkable inside a live gate — which is why it is a real
design gap, not a missing flag.

## Acceptance

*The issue has no `## Acceptance` block — none was copied. Every criterion below was authored for
this capture, grounded in the verified mechanics above, and deliberately does not resolve which
option (Step 4) is chosen.*

- [ ] A decision record exists under `decisions/` (dated, per the directory's existing convention —
      e.g. `decisions/2026-08-10-marathon-gate-baseline-strategy.md`) naming which approach was
      chosen from the options enumerated below, or a different one the operator specifies, with the
      reason. A PR that implements a baseline mechanism without a decision record predating it does
      not satisfy this criterion, regardless of how the mechanism behaves.
- [ ] The mechanism is invoked through the same single `--pre-advance-cmd` contract already threaded
      from `marathon.sh` (`:118,126,214`) to `marathon_drive.py` (`:409`) UNLESS the decision record
      explicitly chooses a per-phase gate (Option 3 below), in which case the record states that it
      is also relaxing `swarm_preflight.py`'s current cross-packet gate-identity check (`:129-131`) —
      a reviewer must be able to see that tradeoff named, not discover it as a side effect.
- [ ] Whatever baseline representation is chosen is captured **once**, before phase 1 dispatches any
      builder turn — not synthesized retroactively from a later phase's gate run. This is the shape
      the issue itself already describes ("the marathon already runs a gate before phase 1").
- [ ] **Negative control, observed, not asserted.** Against a fixture repo whose gate is already red
      before phase 1 (a real, reproducible pre-existing failure), a captured run demonstrates BOTH: (a)
      a phase whose own change adds no new failure ADVANCES, and (b) a phase whose change adds one
      new, different failure on top of the same baseline HALTS. Both outcomes must be shown from an
      actual run's captured log/output — a written description of expected behavior does not satisfy
      this criterion. A mechanism that only ever demonstrates (a) has not been shown to gate anything.
- [ ] If the chosen option cannot distinguish "the same failures, still failing" from "a different set
      of failures that happens to be the same size" (true of any exit-code-only or count-only
      baseline), the decision record and the shipped documentation say so explicitly, in the words a
      later reader would need: what a passing gate now proves, and what it does not.
- [ ] `GATE_SCRUBBED_ENV` (`utils/py/marathon_drive.py:1283-1290`, 17 names) is not weakened to let
      the mechanism smuggle phase identity into the gate's environment. If the chosen option needs the
      gate to see *something* new (e.g. a baseline file path), that addition is classified through the
      same `gate_env.py` scrub-or-pass contract GH-441 established, not bolted on unclassified.
- [ ] Frozen-twin governance (GH-308) is honored: the behavior change lands in `utils/py/marathon_drive.py`
      (and `utils/py/swarm_preflight.py` if the chosen option touches per-packet gates). Any
      accompanying edit to a frozen Bash twin (`relay-automation/marathon-drive.sh`,
      `utils/swarm-preflight.sh`) carries a `Frozen-twin-exception:` trailer naming the file and
      reason; absent that, the twins are left untouched.
- [ ] `bash validate.sh` no worse than baseline for the PR itself — and because this PR changes what
      "no worse than baseline" even means mechanically, the PR states which baseline it was compared
      against and how, rather than repeating the prose idiom this repo already uses elsewhere without
      explanation.
- [ ] Ships as a direct PR against `development`. Never dispatched as a marathon or relay lane — see
      Reversibility & blast radius for why.

**Out of scope, explicitly:**
- Picking the option (this doc's whole point, per Step 4 of its own authoring brief).
- `Hypercart-Dev-Tools/rebalance-OS`'s own #170 (worktree-import defect) — a different repo's issue.
- Raising or lowering any existing test bound, count, or exclusion in this repo's own suite.
- Option 2 (fail-fast precondition) and Option 4 (documentation) are cheap and largely orthogonal to
  Options 1/3 — nothing here blocks landing either of them independently of the baseline decision, but
  neither satisfies this issue's acceptance on its own: the issue's title problem is that a marathon
  **cannot run** against a non-green repo, and fail-fast/documentation both leave that true.

## Acceptance — deviations from the issue

Not applicable in the GH-358/GH-392 sense (there is no verbatim issue block to deviate from — the
issue has no `## Acceptance` section at all). Two authoring choices are worth naming instead of
silently baking in:

1. **The negative-control criterion is new**, not implied by the issue's prose. The issue describes
   the *desired* behavior ("a phase passes when no worse than baseline") but never states how a
   reviewer would verify a fixed mechanism still catches a real regression rather than always passing
   once baseline exists. `GUIDING-PRINCIPLES.md` §13 — "a green gate without a witnessed red control
   is not evidence" — applies directly here, more than almost anywhere else in the repo: the
   surface being changed IS the mechanism every other lane's gate depends on.
2. **The issue's own code citation (`GATE_SCRUBBED_ENV`, 3 names) was verified and found stale**
   against the live 17-name tuple. The underlying claim survives; the literal snippet does not. Carried
   forward as a verified correction in "The defect," not silently fixed in a paraphrase.

## Litmus tests

- **A green run after this ships proves nothing about the chosen mechanism** unless the negative
  control (acceptance criterion 4) is demonstrated from a real captured run. This is the one gate in
  the entire harness where "it passed" and "it works" are least likely to coincide by accident,
  because the change's whole purpose is to make MORE things pass.
- **The self-referential trap is real and load-bearing.** `run_pre_advance_gate()` in
  `utils/py/marathon_drive.py` is the function that decides whether the marathon that is currently
  running may advance — including a hypothetical marathon whose own lane is this very fix. Editing it
  from inside a marathon means the running process is being asked to gate a change to its own gating
  logic mid-run. That is why this issue ships as a direct PR only, independent of which option is
  chosen.
- **Even the "cheap" options are not free.** Option 2 (fail-fast) still needs to run the SAME arbitrary
  gate command before phase 1 to know the repo is red — it just moves the halt earlier and makes the
  message clearer. It does not, by itself, let any phase after that point advance on a red repo. Do
  not accept a PR that implements Option 2 as if it satisfied the issue's title problem.

## Reversibility & blast radius

**Costly, not Easy — this changes the one mechanism every marathon phase, in every consuming repo,
currently trusts to mean "halt if something broke."** A subtly wrong implementation does not fail
loudly: it produces a phase that advances when it should have halted, and the harness has no other
check between "the gate passed" and "the change shipped." That failure mode is silent by
construction, which is exactly the shape `GUIDING-PRINCIPLES.md` warns is the hardest to catch (§13).

Concretely:
- **Whatever ships must be additive/opt-in in effect if it changes default behavior at all** — a
  baseline-off run today must remain byte-identical to today's `gate_exit != 0` → halt behavior, so
  the population of already-completed marathon runs is not silently reinterpreted after the fact.
- **Never a marathon/relay lane.** `utils/py/marathon_drive.py` is the live Tier-A driver
  (`AGENTS.md`'s Frozen Bash Twin list) that executes every phase of every marathon, including
  whichever phase would carry this fix. A headless build turn editing the file the driver that
  dispatched it is currently running would be self-modifying mid-flight — the containment hazard
  `GUIDING-PRINCIPLES.md` item 3 exists to rule out categorically, not case-by-case. This applies to
  the whole issue, including a documentation-only sub-step, to keep the rule simple rather than
  carving a narrow exception that the next reader has to re-derive.
- **Rollback is a straightforward revert** as long as the change stays additive (previous section) —
  the risk is not "hard to undo," it is "wrong in a way nobody notices until a real regression rides
  through on a false 'no worse than baseline.'"

## Swarm Preflight Contract

This contract intentionally scopes **Phase 1 only** — authoring the decision record. Phase 2
(implementation) cannot be preflighted yet: `swarm_preflight.py` requires at least one `fix_probes`
entry and one `artifacts` path (`:88-93`), and neither can be stated honestly before the operator
decision fixes which files change. The proposed decision-record path below is a naming convention,
not a technical choice — it does not resolve which option Phase 1 selects.

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "path_absent", "path": "decisions/2026-08-10-marathon-gate-baseline-strategy.md" }
  ],
  "artifacts":     ["decisions/2026-08-10-marathon-gate-baseline-strategy.md"],
  "artifacts_new": ["decisions/2026-08-10-marathon-gate-baseline-strategy.md"],
  "remediation":   { "source": "issue #378", "criteria": "record which baseline-allowance option (or alternative) the operator chose for the marathon global gate's inability to distinguish pre-existing failures from new ones — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above). Scope is Phase 1 (the decision) ONLY; Phase 2 (implementation in utils/py/marathon_drive.py) is unscoped pending that decision and, per this doc's Reversibility section, ships as a direct PR — never a marathon lane." },
  "lanes": { "agy_safe": [], "orchestrator_only": ["decisions/2026-08-10-marathon-gate-baseline-strategy.md"] }
}
```

**Probe polarity** (probes detect the **bug**, not the fix): `path_absent` reports `landed` once the
decision file *exists* at that path — today it is absent, so the probe currently reports the decision
as still required. Even once Phase 1 lands, this contract does not become marathon-fireable for
Phase 2: `lanes.agy_safe` is deliberately empty and `orchestrator_only` covers only the decision
artifact. **Neither phase of this issue is to be dispatched via `marathon.sh --plan` or driven by
`swarm-preflight.sh`'s automated path** — this JSON block exists for structural completeness and
future reference, not as an instruction to fire it. Phase 2 will need its own contract, authored after
the decision record exists, and will still require a direct PR per the Reversibility section above.

## Options, roughly in order of cost

*Carried from the issue and extended with what verification against live code adds. Not ranked as a
recommendation — recorded so the operator decision has the real shape of each option, including what
each one costs to build in THIS codebase specifically.*

1. **A baseline allowance.** Record the target's known-failing set at plan time (the marathon already
   runs a gate before phase 1); pass a phase when its gate result is no worse than that baseline. The
   issue calls this highest-value-for-effort — true only if "known-failing set" is cheap to extract,
   which the verification above shows it is not, in general, for an arbitrary shell command. Needs one
   of the sub-options below to actually produce a set rather than a bare exit code.
   - **1a. A gate-output contract.** Require the gate command to emit a structured result (e.g. a JSON
     summary on a fixed path, or a documented exit-code convention beyond 0/nonzero) that the driver
     reads after the run. Puts a new obligation on every repo's `validate.sh`/gate script, including
     this repo's own (`validate.sh` currently emits neither).
   - **1b. Per-runner parsers.** The driver recognizes common test-runner output (pytest, jest, a raw
     shell-script loop like this repo's `validate.sh`) and extracts a failing-test identifier list by
     pattern. No new obligation on the target repo, but an open-ended maintenance surface — a new
     runner shape is a parser gap discovered at run time, not compile time.
   - **1c. A coarser exit-code-only baseline.** Compare only the gate's exit code (or, at most, a
     count if the gate happens to print one) against baseline, with no attempt to identify WHICH
     failures recur. Cheapest to build; the weakest guarantee — cannot tell "the same failures,
     still failing" from "a different, equally-sized failure set," which the acceptance criteria above
     require the shipped docs to say plainly if this is what's chosen.
2. **An explicit precondition, failing fast.** Run the gate once before phase 1 and refuse the whole
   plan with the failing tests named, rather than discovering it at the first phase advance. Cheap and
   orthogonal to 1/3 — but on its own does not let any phase advance on a red repo, so it does not
   resolve the issue's title problem by itself (see Litmus tests).
3. **Per-phase gate override, opt-in (`gate:` field).** Matches what `swarm_preflight.py` already
   reads per packet (`:116`) — but merging currently REQUIRES every packet's gate to match exactly
   (`:129-131`, exit 7 on disagreement). Enabling this means deliberately loosening that existing
   check, not just adding a field; the decision record must name that tradeoff if this option is
   chosen. Weaker than Option 1 for the reason the issue itself gives: a phase-scoped gate proves only
   that phase's own tests pass, not that phases 1..N together haven't broken anything — the property a
   chained run actually needs.
4. **Document the precondition.** State plainly, in `README.md` and `MARATHON.example.yaml`, that the
   target's suite must already be green or the run halts at phase 1. Costs nothing to build and fixes
   nothing — it converts a confusing mid-run halt into an expected one. Worth doing regardless of which
   other option is chosen, and does not by itself satisfy this issue's acceptance criteria.

**This list is not exhaustive and no entry is a recommendation.** The operator may choose a hybrid
(e.g. 1c now, with the acceptance criteria's disclosure requirement, and 1a/1b as a later, separately
issued upgrade) or reject all four. Recording that choice in `decisions/` is acceptance criterion 1;
picking among them is explicitly this doc's non-goal.

## Provenance

Filed from a live marathon-preparation session against `Hypercart-Dev-Tools/rebalance-OS`
(`source_commit dcc8507`): a validated 10-lane plan (`marathon.sh --dry-run` reported "10 phase(s)
would run in order") blocked entirely on the gate, with every lane's own scoped gate green and the
target repo's full suite red (5 failed / 1587 passed, unrelated to any of the ten lanes). That
measurement is the target repo's own and was not re-run here; it is carried from the issue, attributed,
per the same rule this repo applies to any figure it cannot independently re-measure (see
`GH-392-HARDWARE-SIZING-GUIDANCE.md`'s Litmus tests for the precedent). Every claim about THIS
repo's code (`marathon_drive.py`, `marathon.sh`, `swarm_preflight.py`, `validate.sh`,
`GATE_SCRUBBED_ENV`, the `decisions/` convention, frozen-twin status of each file touched) was read
directly from `development` @ `40a75da` on 2026-08-10, not repeated from the issue's prose. No open
PR or branch touches this issue — checked before authoring (`git log --all --oneline | grep 378`,
`git branch -a | grep 378`, both empty of a matching lane).
