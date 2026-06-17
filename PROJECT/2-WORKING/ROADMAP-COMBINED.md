---
title: Combined Roadmap — Cost-Observed Marathon Loops
status: Draft
created: 2026-06-16
branch: main
synthesizes:
  - PROJECT/1-INBOX/LOOPS.md
  - PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md
  - PROJECT/1-INBOX/MARATHON.md
goal: >
  Unify the theoretical loop architecture (LOOPS.md), the prerequisite cost 
  measurement layer (COST-OBSERVABILITY-PLAN.md), and the headless multi-phase 
  chaining strategy (MARATHON.md) into a single, linear, execution-ready plan.
---

# Combined Roadmap: Cost-Observed Marathon Loops

## Status

| Most recently completed phase | What's next |
|---|---|
| **Phase 0 — Capture raw cost signals (Cost Phase 1)** ✅ shipped: `cost.tokens`/`cost.human` events, headless token capture wired into `gemini-turn.sh`. | **Phase 1 — Extend deterministic analyzer to compute cost (Cost Phase 2)** |

## Table of contents

- [Phase 1 — Compute & Budget: The Observability Foundation](#phase-1--compute--budget-the-observability-foundation)
- [Phase 2 — The Dispatcher & Headless Builder (Marathon prep)](#phase-2--the-dispatcher--headless-builder-marathon-prep)
- [Phase 3 — Single-Phase Headless Loop (The Proof)](#phase-3--single-phase-headless-loop-the-proof)
- [Phase 4 — Multi-Phase Chaining & State (Full Marathon)](#phase-4--multi-phase-chaining--state-full-marathon)
- [Phase 5 — Cross-System Comparison (The Payoff)](#phase-5--cross-system-comparison-the-payoff)

---

## Phase 1 — Compute & Budget: The Observability Foundation

**Intent:** Fulfill the "Token Budgeting" requirement from LOOPS.md by completing Phase 2 of the Cost Observability plan. This ensures that when autonomous loops run, we can deterministically measure and eventually halt them based on cost.

### Checklist (each item is observable)

- [ ] **Sum tokens:** Extend `src/analyze.js` to sum total `tokens_in`/`tokens_out` across the run and per agent.
      *Observable:* `tick analyze --format json` includes `cost.tokens_total` and `cost.tokens_by_agent`.
- [ ] **Wall-clock & Human-minutes:** Add per-task duration and human-minutes summation.
      *Observable:* json output includes `cost.walltime_by_task` and `cost.human_minutes_total`.
- [ ] **Cost-per-unit-of-work:** Divide cost by the run's output denominator (e.g., tasks done).
      *Observable:* json shows `cost.tokens_per_task`, never dividing by zero.
- [ ] **Render in human + md:** Add a `## Cost` block to the `--write` markdown section.
      *Observable:* `tick analyze --write <file>` adds a Cost section seamlessly.
- [ ] **Loud partial signal:** Ensure incomplete token coverage renders as a FLOOR (`≥N`).
      *Observable:* Runs missing token data print `≥` and `partial`, not a bare number.

### QA checklist — Phase 1

- [ ] **DRY:** Cost rendering reuses the existing format dispatch (human/md/json).
- [ ] **Determinism litmus:** Same events in → identical cost out, across two runs.
- [ ] **No-silent-cap:** Undercounted runs explicitly warn the user.

---

## Phase 2 — The Dispatcher & Headless Builder (Marathon prep)

**Intent:** Build the execution wrappers required by MARATHON.md, effectively creating the "Action" and "Cross-Model Verification" mechanisms described in LOOPS.md.

### Checklist (each item is observable)

- [ ] **Confirm/Build Gemini Shim:** Ensure `gemini-turn.sh` exists and adheres to the `relay-turn-lib.sh` contract.
      *Observable:* A stub-Gemini turn drives one relay turn and fails negative allowlist tests.
- [ ] **Create `marathon-agent.sh` Dispatcher:** Write the router that reads `RELAY_AGENT` and execs the right shim (`claude-turn.sh`, `codex-turn.sh`, or `gemini-turn.sh`).
      *Observable:* Dispatcher correctly routes known agents and exits `2` on unknowns.
- [ ] **Headless `claude -p` Spike:** Run a trivial headless Claude turn to confirm Context/Tool loading.
      *Observable:* Claude runs non-interactively, edits a file, and runs `./bin/tick`.
- [ ] **Build `claude-turn.sh` Shim:** Wrap `claude -p` using `relay-turn-lib.sh` for containment.
      *Observable:* Stub Claude correctly drives a turn through `relay-drive.sh` and is blocked from off-allowlist edits.

### QA checklist — Phase 2

- [ ] **Containment:** All three turn-takers (`claude`, `codex`, `gemini`) MUST source the exact same `relay-turn-lib.sh` containment core.
- [ ] **Tooling Check:** Ensure `claude -p` is NOT using `--bare` so it inherits project skills.

---

## Phase 3 — Single-Phase Headless Loop (The Proof)

**Intent:** Prove the core "Five-Step Execution Cycle" (LOOPS.md) works entirely hands-free by running a single phase of the Marathon architecture.

### Checklist (each item is observable)

- [ ] **Hardcoded Single Phase:** Create `marathon-drive.sh` to run exactly one phase. Render a `RELAY.md` template, hand off the `MARATHON-P1-TURN` to `claude`, and call `relay-drive.sh`.
      *Observable:* `marathon-drive.sh` executes the build/review cycle hands-free.
- [ ] **Round-Cap Enforcement:** Implement the `2 * max_review_rounds + 1` logic to enforce explicit termination (LOOPS.md).
      *Observable:* A loop halts correctly if the Reviewer model refuses to approve within the cap.
- [ ] **Feedback/Transcript Capture:** Ensure the `VERDICT:` and transcript are captured deterministically during the turn.
      *Observable:* Transcript files are saved under `relay-system/<date>/` and committed.

### QA checklist — Phase 3

- [ ] **Agreement Check:** Ensure `relay-drive.sh` only exits `0` when `STATUS: Approved` AND the token is done.
- [ ] **Unmodified Core:** Prove chaining works with `relay-drive.sh` completely unmodified.

---

## Phase 4 — Multi-Phase Chaining & State (Full Marathon)

**Intent:** Scale the single loop into an ordered DAG of loops, fulfilling the full vision of MARATHON.md.

### Checklist (each item is observable)

- [ ] **Parse `MARATHON.yaml`:** Implement logic to read phases, dependencies, and assigned reviewers.
      *Observable:* The script correctly resolves execution order and reviewer routing based on the YAML.
- [ ] **Phase Chaining & Escalation:** Loop through phases. On `0`, advance. On `3` or `4` (halt), write `ESCALATION.md` and stop.
      *Observable:* A deliberately unsatisfiable phase halts the chain and produces an escalation record.
- [ ] **State Projection (M7):** Project a `MARATHON-STATE.md` from `.tick/events/`.
      *Observable:* State file updates correctly as phases start, revise, and approve.
- [ ] **Cross-Phase Context Injection (M6):** Prepend approved prior-phase artifacts into the next phase's builder prompt.
      *Observable:* Phase 2 visibly references a decision made in Phase 1.

### QA checklist — Phase 4

- [ ] **State Cleanliness:** Verify the next phase's `.tick/*` snapshot is clean before starting.
- [ ] **Peer Threading:** Ensure `RELAY_PEER` is explicitly passed on every turn handoff to avoid "Unnamed peer" bugs.

---

## Phase 5 — Cross-System Comparison (The Payoff)

**Intent:** Dogfood the completed system (Cost + Marathon) to generate the final artifact requested in the feedback doc.

### Checklist (each item is observable)

- [ ] **Run xyz Build with Cost On:** Execute an xyz build on a fixture.
      *Observable:* Analyzer shows tokens and walltime.
- [ ] **Run Relay/Marathon Build with Cost On:** Execute a Marathon chain on the same or comparable fixture.
      *Observable:* Analyzer shows tokens and walltime for the headless turns.
- [ ] **Generate Comparison Report:** Write `COST-COMPARISON.md` generated from the analyzer JSON.
      *Observable:* File exists, filled entirely from deterministic json (no hand-typed metrics).
- [ ] **Update Feedback Doc:** Close the loop on point 5 from the June 15th feedback.
      *Observable:* `FEEDBACK-2026-06-15.md` is updated with real cost-per-unit figures.

### QA checklist — Phase 5

- [ ] **Apples-to-Apples Caveat:** The report explicitly states if the compared tasks represent different difficulty levels (independent vs. coupled).
- [ ] **SOLID:** No metrics are manually computed; everything originates from the deterministically parsed event log.
