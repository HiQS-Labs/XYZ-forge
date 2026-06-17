---
title: Combined Roadmap — Cost-Observed Marathon Loops + Adversarial Hardening
status: Active
created: 2026-06-16
updated: 2026-06-17
branch: main
synthesizes:
  - PROJECT/1-INBOX/LOOPS.md
  - PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md
  - PROJECT/1-INBOX/MARATHON.md
  - ROADMAP.md
goal: >
  Unify the theoretical loop architecture (LOOPS.md), the prerequisite cost
  measurement layer (COST-OBSERVABILITY-PLAN.md), the headless multi-phase
  chaining strategy (MARATHON.md), and the commercial-hardening track (ROADMAP.md)
  into a single, linear, execution-ready plan.
---

# Combined Roadmap: Cost-Observed Marathon Loops + Adversarial Hardening

Two parallel tracks, sequenced independently:

- **Part A — Marathon:** cost observability (done) → headless multi-phase chaining
- **Part B — Adversarial Hardening:** epoch fencing → chaos suite → cross-repo E2E → reference deploy

---

## Status

| Most recently completed | What's next |
|---|---|
| **Part A Phase 5 — Cross-system comparison** ✅ shipped: `COST-COMPARISON.md` generated from `tick analyze --format json`; `FEEDBACK-2026-06-15.md` point 5 closed; live `-o json` relay turn validated end-to-end. | **Part A Phase 2 — Marathon dispatcher + headless builder** (`marathon-agent.sh`, `claude-turn.sh`, `claude -p` spike) |
| **Part B: Mechanically proven** ✅ (`validate.sh` 22/22; live Codex + Gemini headless turns; relay containment 3-model validated) | **Part B Phase 1 — Epoch fencing & stale-writer prevention** (R1 + G3) |

## Table of contents

**Part A — Marathon**
- [Part A · Phase 1 — Compute & Budget: The Observability Foundation](#part-a--phase-1--compute--budget-the-observability-foundation) ✅
- [Part A · Phase 2 — The Dispatcher & Headless Builder](#part-a--phase-2--the-dispatcher--headless-builder-marathon-prep)
- [Part A · Phase 3 — Single-Phase Headless Loop (The Proof)](#part-a--phase-3--single-phase-headless-loop-the-proof)
- [Part A · Phase 4 — Multi-Phase Chaining & State (Full Marathon)](#part-a--phase-4--multi-phase-chaining--state-full-marathon)
- [Part A · Phase 5 — Cross-System Comparison (The Payoff)](#part-a--phase-5--cross-system-comparison-the-payoff) ✅

**Part B — Adversarial Hardening**
- [Part B · Phase 1 — Epoch Fencing & Stale-Writer Prevention](#part-b--phase-1--epoch-fencing--stale-writer-prevention-r1--g3)
- [Part B · Phase 2 — Chaos Suite & Auto-Recovery](#part-b--phase-2--chaos-suite--auto-recovery-g1-g2-g4-r2-r5)
- [Part B · Phase 3 — Cross-Repo E2E & Multi-Device Sync](#part-b--phase-3--cross-repo-e2e--multi-device-sync-g5-r3)
- [Part B · Phase 4 — Observability & Reference Deploy](#part-b--phase-4--observability--reference-deploy-r4)

---

## Part A — Marathon

---

## Part A · Phase 1 — Compute & Budget: The Observability Foundation

**Status: ✅ Shipped 2026-06-16** (`COST-OBSERVABILITY-PLAN.md` Phase 2; `cost.sh` 24/24; full suite 22/22)

**Intent:** Fulfill the "Token Budgeting" requirement from LOOPS.md. Ensures that when autonomous
loops run, we can deterministically measure and eventually halt them based on cost.

### Checklist

- [x] **Sum tokens:** `tick analyze` sums `tokens_in`/`tokens_out` across the run and per agent.
      *Observable:* `--format json` includes `cost.tokens_total` and `cost.tokens.by_agent`. ✅
- [x] **Wall-clock & Human-minutes:** Per-task duration and human-minutes summed.
      *Observable:* json includes `cost.walltime.by_task` and `cost.human_minutes_total`. ✅
- [x] **Cost-per-unit-of-work:** `cost.per_unit.tokens_per_done`; denominator 0 → `null`, never divide-by-zero.
      *Observable:* json shows `tokens_per_done`; `n/a` on empty runs. ✅
- [x] **Render in human + md:** `### Cost` block added to `--write` markdown output.
      *Observable:* `tick analyze --write <file>` adds Cost section seamlessly. ✅
- [x] **Loud partial signal:** Incomplete coverage renders as floor (`≥N`) with `coverage: X/Y done-tasks`.
      *Observable:* Runs missing token data print `≥` and `partial: true`. ✅

### QA checklist

- [x] **DRY:** Cost rendering reuses existing `renderHuman`/`renderMd` paths. ✅
- [x] **Determinism litmus:** Same events in → identical cost out. `computeCost` is a pure function. ✅
- [x] **No-silent-cap:** Undercounted runs explicitly warn; `run_type: unspecified` warns on non-comparable runs. ✅

---

## Part A · Phase 2 — The Dispatcher & Headless Builder (Marathon prep)

**Status: 🔲 In progress — Gemini shim confirmed; remaining items not started**

**Intent:** Build the execution wrappers required by MARATHON.md, creating the "Action" and
"Cross-Model Verification" mechanisms described in LOOPS.md.

### Checklist

- [x] **Confirm Gemini shim:** `gemini-turn.sh` exists, sources `relay-turn-lib.sh`, and passes all tests.
      *Observable:* 17/17 `gemini-turn.sh` tests pass; live real turn validated 2026-06-16. ✅
- [ ] **Create `marathon-agent.sh` dispatcher:** `case "$RELAY_AGENT"` router — execs `claude-turn.sh`,
      `codex-turn.sh`, or `gemini-turn.sh`; passes `RELAY_PEER` through; exits 2 on unknown agent.
      *Observable:* Each known agent routes correctly; unknown → exit 2.
- [ ] **Headless `claude -p` spike (gating unknown):** Run a trivial `claude -p` turn with
      `--allowedTools "Bash,Read,Edit,Write" --permission-mode acceptEdits --output-format json`.
      Confirm: runs non-interactively, edits a file, runs `./bin/tick`, loads CLAUDE.md/skills (no `--bare`).
      *Observable:* One-shot turn produces a relay block + parseable result; file-write and `tick` both work.
- [ ] **Build `claude-turn.sh` shim:** Mirror `codex-turn.sh` — `rtl_init` → `rtl_before` →
      `claude -p "$prompt" --allowedTools ... --permission-mode acceptEdits --output-format json` →
      `rtl_enforce`. Allowlist = `phases/p<N>/RELAY.md` only. Do NOT use `--bare`.
      *Observable:* Stub `claude` drives one turn through `relay-drive.sh`; off-allowlist edit → exit 6.

### QA checklist

- [ ] **Containment:** All three shims (`claude`, `codex`, `gemini`) source the SAME `relay-turn-lib.sh` — never reimplement.
- [ ] **Round-cap arithmetic:** `--round-cap = 2 × max_review_rounds + 1` (turns ≠ rounds; off-by-one kills phases early). Validated before M3.
- [ ] **RELAY_PEER threading:** Every turn passes the peer explicitly — unnamed peer caused a live Gemini "release to literal role-string" failure on 2026-06-15.

---

## Part A · Phase 3 — Single-Phase Headless Loop (The Proof)

**Status: 🔲 Not started**

**Intent:** Prove the core five-step execution cycle (LOOPS.md) works entirely hands-free by
running one Marathon phase end-to-end. Gated on Phase 2 `claude -p` spike passing.

### Checklist

- [ ] **Hardcoded single phase:** `marathon-drive.sh` renders `phases/p1/RELAY.md` from a template,
      `tick add MARATHON-P1-TURN` with handoff → `claude`, calls
      `relay-drive.sh --agent-cmd marathon-agent.sh --round-cap 5` unmodified.
      *Observable:* build turn → review turn → `STATUS: Approved` → relay-drive exit 0.
- [ ] **Round-cap enforcement:** A deliberately unsatisfiable reviewer halts within the cap.
      *Observable:* Loop stops at round cap; does not run forever.
- [ ] **Transcript capture:** `VERDICT:` and transcript saved under `relay-system/<date>/` and committed.
      *Observable:* Transcript file exists and is committed after the run (scripted step, not a prompt).
- [ ] **`--pre-advance-cmd` hook:** `marathon-drive.sh` runs a configurable command before emitting
      `phase.approved` and advancing to the next phase. Default: `bash validate.sh`. Non-zero exit
      halts with `ESCALATION.md` — same failure path as a relay timeout.
      *Observable:* A deliberately broken `validate.sh` (one failing test) stops the chain at that
      phase boundary and writes an escalation record; it does NOT advance to the next phase.

### QA checklist

- [ ] **Agreement check:** `relay-drive.sh` exits 0 ONLY when `STATUS: Approved` AND token is done (both required).
- [ ] **Unmodified core:** Chaining works with `relay-drive.sh` completely untouched.
- [ ] **Only `phases/p1/RELAY.md` changed:** No other tracked file mutated by the headless run.
- [ ] **Pre-advance gate fires:** `validate.sh` (or the operator-supplied `--pre-advance-cmd`) runs
      automatically after relay-drive exits 0, before `phase.approved` is emitted. Operator can
      override to a lighter check for fast inner loops; default must be non-empty.

---

## Part A · Phase 4 — Multi-Phase Chaining & State (Full Marathon)

**Status: 🔲 Not started**

**Intent:** Scale the single loop into an ordered DAG of loops, fulfilling the full MARATHON.md vision.

### Checklist

- [ ] **Parse `MARATHON.yaml`:** Resolve phases, `depends_on` order, and per-phase `reviewer` fields.
      *Observable:* Script correctly routes reviewer and resolves execution order from YAML.
- [ ] **Phase chaining & escalation:** On relay-drive exit 0 → advance; exit 3/4 → write `ESCALATION.md` and halt.
      *Observable:* Unsatisfiable middle phase halts the chain at that phase; next phase does NOT start.
- [ ] **State projection (M7):** `MARATHON-STATE.md` projected from `.tick/events/`.
      *Observable:* State file reflects current phase, per-phase round counts, and statuses.
- [ ] **Cross-phase context injection (M6):** Approved prior-phase artifact prepended into next builder prompt.
      *Observable:* Phase 2 builder turn visibly references a decision from Phase 1.

### QA checklist

- [ ] **State cleanliness:** Next phase's `rtl_before` snapshot is clean before it starts.
- [ ] **Peer threading:** `RELAY_PEER` passed on every turn handoff — no bare "the other agent" strings.
- [ ] **Emit tick events at phase boundaries:** `marathon.phase.start` / `phase.approved` / `phase.escalated` / `marathon.complete`.

---

## Part A · Phase 5 — Cross-System Comparison (The Payoff)

**Status: ✅ Shipped 2026-06-16** (`COST-OBSERVABILITY-PLAN.md` Phase 3; `COST-COMPARISON.md` written; `FEEDBACK-2026-06-15.md` point 5 closed)

**Intent:** Dogfood the completed system (Cost + Marathon) to generate the final artifact requested
in the feedback doc.

### Checklist

- [x] **Run xyz build with cost on:** Synthetic 2-lane fixture (`$TMPDIR/p3-xyz`); 4 tasks, 2 agents.
      *Observable:* `tick analyze` shows `tokens_total=58920`, coverage `4/4`, `run_type=symmetric`. ✅
- [x] **Run relay/Marathon build with cost on:** Real Gemini headless turn under `-o json` on
      `relay-system/2026-06-16/p3-dogfood-relay.md`.
      *Observable:* `tokens_total=110008`, coverage `1/1`, `run_type=asymmetric`. ✅
- [x] **Generate comparison report:** `PROJECT/2-WORKING/COST-COMPARISON.md` — every cell from
      `tick analyze --format json`. No hand-typed metrics.
      *Observable:* File exists; data-provenance + apples-to-apples caveats included. ✅
- [x] **Update feedback doc:** `FEEDBACK-2026-06-15.md` now cites real cost-per-unit figures.
      *Observable:* Point 5 closed under "Cross-system takeaway". ✅

### QA checklist

- [x] **Apples-to-apples caveat:** Report states xyz = synthetic fixture (symmetric); relay = real Gemini turn (asymmetric). ✅
- [x] **SOLID:** No metrics manually computed; all from deterministic event log. ✅

---

## Part B — Adversarial Hardening

Maturity ladder: **1. Mechanically proven** ✅ → **2. Adversarially proven** ⬅ *this track* →
**3. Commercially viable** (adversarial proof + packaging + SLA/observability + reference deploy).

Each item carries a Threat, what a log must Prove, the Test/artifact it emits, and its current Status.

---

## Part B · Phase 1 — Epoch Fencing & Stale-Writer Prevention (R1 + G3)

**Status: 🔲 Not started — ❌ missing mechanism (highest priority in this track)**

**Threat (G3):** Agent X is presumed dead; token is taken over (reap → reclaim by Y); then X
*revives* and issues `done`/`release`/edit — a zombie advances or corrupts the relay.
Today's `tick` has no monotonic fencing token, so a revived X with the same agent id still passes
ownership checks after takeover. This is the difference between "soft coordination" and "a kernel
you can trust unattended."

### Checklist

- [ ] **R1: Implement monotonic epoch fencing tokens.**
  - [ ] Add `epoch` field to claim events in the event schema.
  - [ ] Modify `tick` projection kernel to track the current owner's epoch.
  - [ ] Reject mutating events (`done`/`release`/edit) whose epoch is older than the current owner's.
- [ ] **G3: Build `test/chaos-stale-writer.sh`.**
  - [ ] Script: claim as agent X → force reap+reclaim as Y (new epoch) → replay X's `done`/`release`/scope events.
  - [ ] Assert: every stale event rejected; relay state unchanged.

### QA checklist

- [ ] `test/chaos-stale-writer.sh` emits a rejected-event log showing the fence firing.
- [ ] `validate.sh` 22/22 with no regressions from epoch addition.
- [ ] Schema change documented in a decision record.

---

## Part B · Phase 2 — Chaos Suite & Auto-Recovery (G1, G2, G4, R2, R5)

**Status: 🔲 Not started — ⚠️ detection partial; recovery and race proofs missing**

### Checklist

- [ ] **R2: Auto-reap authority decision.**
  - [ ] Formally define who may reap and on what evidence; record in a decision markdown.
  - [ ] Flip `watchdog.sh --allow-reap` from stub to real.
- [ ] **G1: Build `test/chaos-midturn-kill.sh`** (mid-turn termination).
  - [ ] Claim as agent X → `kill -9` → run `watchdog.sh` → assert `parked_suspects[X]` flagged.
  - [ ] Assert: structured JSON escalation emitted; auto-reap re-offers token exactly once.
- [ ] **G2: Build `test/chaos-dup-token.sh`** (duplicate/ambiguous token).
  - [ ] Inject concurrent/duplicate claims → assert projection resolves to exactly one stable winner across N replays.
  - [ ] Inject malformed/duplicate event files → assert safely quarantined without crash.
- [ ] **G4: Build `test/chaos-concurrent-pollers.sh`** (concurrent pollers).
  - [ ] Launch two concurrent `poll.sh` instances against the same relay state.
  - [ ] Assert exactly one poller acts; the other idles — across N trials.
- [ ] **R5: Resource / quota limits** (per-turn runaway containment; Gemini 2026-06-15).
  - [ ] Cap per-turn wall-clock, disk, and API spend in the turn-taker shim.
  - [ ] Pairs with `relay-drive.sh` round-cap; missing piece is per-turn time/spend ceilings.

### QA checklist

- [ ] `test/chaos-midturn-kill.sh` passes with watchdog JSON + correct recovery state.
- [ ] `test/chaos-dup-token.sh` passes with identical projection outputs across all replays.
- [ ] `test/chaos-concurrent-pollers.sh` passes: exactly one actor per trial, logged.
- [ ] `watchdog.sh` reaps and re-offers tokens without manual intervention.

---

## Part B · Phase 3 — Cross-Repo E2E & Multi-Device Sync (G5, R3)

**Status: 🔲 Not started — ⚠️ cross-model live-proven; zero-setup fresh-clone E2E missing**

**Threat (G5):** The protocol is secretly coupled to this repo or to all-Claude flows — it won't
generalize, so it has no product surface.

### Checklist

- [ ] **G5: Build `test/e2e-fresh-repo.sh`.**
  - [ ] Instantiate a throwaway repository; install the skill via `relay-pkg.tar.gz`.
  - [ ] Run a complete Producer↔Reviewer relay to `Approved` using headless agents.
  - [ ] Assert no hardcoded dependencies on the home repository.
- [ ] **G5: Cross-model demonstration.**
  - [ ] Execute and record a multi-agent run combining Codex + Gemini headless turns in a single thread.
- [ ] **R3: Cross-machine `.tick/` sync.**
  - [ ] Build or document an out-of-band sync mechanism (git-based or daemon) so multiple machines share `.tick/` securely.

### QA checklist

- [ ] `test/e2e-fresh-repo.sh` succeeds with zero manual setup in the throwaway repo.
- [ ] Transcript + commit graph from the fresh repo verified.
- [ ] Cross-machine sync demonstrated without state conflicts or dropped events.

---

## Part B · Phase 4 — Observability & Reference Deploy (R4)

**Status: 🔲 Not started — ❌ structured logs missing**

**Threat (R4):** Logs today are human-readable, not structured for ingestion — a buyer cannot
ship them to a SIEM. This is the final mile to commercial viability.

### Checklist

- [ ] **R4: Build observability surface.**
  - [ ] Instrument `tick` and relay stack to emit structured, timestamped JSON for every claim, handoff, rejection, and escalation — with agent id + epoch.
  - [ ] Format for SIEM ingestion.
- [ ] **Create reference deploy documentation.**
  - [ ] Write a comprehensive guide to deploying the stack with SLA and observability guarantees.

### QA checklist

- [ ] All required events (claim, handoff, reject, escalate) emit structured JSON logs.
- [ ] Log artifacts contain accurate timestamps, epochs, and agent IDs.
- [ ] Reference deploy doc can be followed by an independent auditor to stand up the environment.
