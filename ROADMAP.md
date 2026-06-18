---
title: Combined Roadmap — Cost-Observed Marathon Loops + Adversarial Hardening
status: Active
created: 2026-06-16
updated: 2026-06-17
branch: main
supersedes: PROJECT/2-WORKING/ROADMAP-COMBINED.md (promoted to canonical 2026-06-17); folds in the former standalone ROADMAP.md (adversarial-hardening track, now Part B)
synthesizes:
  - PROJECT/1-INBOX/LOOPS.md
  - PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md
  - PROJECT/1-INBOX/MARATHON.md
goal: >
  Unify the theoretical loop architecture (LOOPS.md), the prerequisite cost
  measurement layer (COST-OBSERVABILITY-PLAN.md), the headless multi-phase
  chaining strategy (MARATHON.md), and the commercial-hardening track (now Part B)
  into a single, linear, execution-ready plan. This IS the canonical roadmap.
---

# Combined Roadmap: Cost-Observed Marathon Loops + Adversarial Hardening

Two parallel tracks, sequenced independently:

- **Part A — Marathon:** cost observability (done) → headless multi-phase chaining
- **Part B — Adversarial Hardening:** epoch fencing → chaos suite → cross-repo E2E → reference deploy

---

## Status

| Most recently completed | What's next |
|---|---|
| **Part A Phase 3 — Single-phase headless loop** ✅ shipped 2026-06-17: `marathon-drive.sh` + `test/marathon-drive.sh` (26/26); `marathon.phase.*` events added to tick schema; `validate.sh` 25/25. | **Part A Phase 4 — Multi-phase chaining & state** (`MARATHON.yaml` parse, phase DAG, cross-phase injection) |
| **Part B: Mechanically proven** ✅ (`validate.sh` 22/22; live Codex + Gemini headless turns; relay containment 3-model validated) | **Part B Phase 1 — Epoch fencing & stale-writer prevention** (R1 + G3) |

## Model assignment (build-track guidance)

The dividing line is **mechanical/pattern-following work** (Sonnet High is excellent) vs.
**trust-critical kernel-correctness reasoning** (reserve Opus). The mechanical bulk is most of the
line-count; the Opus-worthy core is small and self-contained, so this split is also the cheapest one.

| Work item | Model | Why |
|---|---|---|
| `claude -p` headless spike (A·P2) | **Sonnet High** | Empirical — run a turn, read the JSON, log the token/wall-clock number. Almost no reasoning depth. |
| `marathon-agent.sh` + `claude-turn.sh` (A·P2) | **Sonnet High** | `case` router + a shim mirroring the existing `codex-turn.sh`/`gemini-turn.sh` against shared `relay-turn-lib.sh`. Pattern-following with a concrete on-disk reference. |
| `marathon-drive.sh` single-phase loop (A·P3) | **Sonnet High** | Integration against an untouched `relay-drive.sh` + a clear checklist. Scaffolding acts as template. |
| Chaos **test scripts** (B·P2: midturn-kill, concurrent-pollers) | **Sonnet High** | `kill -9` + watchdog-assertion harnesses are mechanical once the mechanism exists. |
| E2E fresh-repo script, observability JSON logs, reference-deploy docs (B·P3/P4) | **Sonnet High** | Scripting + docs, low ambiguity. |
| Multi-phase DAG: `MARATHON.yaml` parse, state projection, cross-phase injection (A·P4) | **Sonnet High** *(spec)* → **Opus** *(review)* | Design is fully specified in the roadmap; Sonnet implements against the spec, Opus reviews escalation/ordering edges. |
| **R1 epoch fencing — projection kernel change (B·P1)** | **Opus** | Monotonic-epoch semantics + replay determinism + "stale writer *cannot* advance" is an adversarial-correctness invariant. A subtle bug isn't a failing test — it's a silently-corruptible coordinator. *(The chaos test around it is Sonnet-fine; the kernel mutation is not.)* |
| **G2 dup-token determinism + quarantine (B·P2)** | **Opus** | "Identical projection across N replays regardless of arrival order" is a correctness proof, not a script. |
| Graduate / iterate / abandon synthesis | **Opus** | Judgment, not mechanics. |

**Practical pattern:** let Sonnet High do the spike, all the shell shims, and the test harnesses;
reserve Opus for the **epoch-fencing kernel diff and the G2 determinism logic** — the two places where
a subtle bug is silent corruption, not a red test.

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

> **Deferred (honest blind spots — carried from `COST-OBSERVABILITY-PLAN.md`):** token capture is
> fully wired only for **Gemini** headless turns. **Codex** token parsing (usage format un-probed) and
> **Claude-orchestrator** tokens (no shell-visible per-turn count) are NOT yet captured — so a multi-model
> run's `tokens_total` is a floor, not a complete sum. "Cost observability" is complete for Gemini lanes only.

---

## Part A · Phase 2 — The Dispatcher & Headless Builder (Marathon prep)

**Status: ✅ Shipped 2026-06-17** — real authenticated turn measured: 7 turns, $0.172, 26s (Sonnet 4.6). Ceilings set: `--max-turns 12`, `--max-budget-usd 0.50`.

**Intent:** Build the execution wrappers required by MARATHON.md, creating the "Action" and
"Cross-Model Verification" mechanisms described in LOOPS.md.

### Checklist

- [x] **Confirm Gemini shim:** `gemini-turn.sh` exists, sources `relay-turn-lib.sh`, and passes all tests.
      *Observable:* 17/17 `gemini-turn.sh` tests pass; live real turn validated 2026-06-16. ✅
- [x] **Create `marathon-agent.sh` dispatcher:** `case "$RELAY_AGENT"` router — execs `claude-turn.sh`,
      `codex-turn.sh`, or `gemini-turn.sh`; passes `RELAY_PEER` through; exits 2 on unknown agent.
      *Observable:* Each known agent routes correctly; unknown → exit 2. ✅ Shipped 2026-06-17.
- [x] **Headless `claude -p` spike (gating unknown):** Confirmed JSON output schema and ran a real
      authenticated turn. Token schema: `usage.{input_tokens,cache_read_input_tokens,output_tokens}`,
      `total_cost_usd`, `duration_ms`, `num_turns`. Auth: subscription credentials from `~/.claude/`
      — no API key needed. **Real turn results (Sonnet 4.6, 2026-06-17):** 7 turns, $0.172,
      26s wall-clock, 207k cache-read + 1.4k output tokens. Ceilings set:
      `--max-turns 12`, `--max-budget-usd 0.50`.
      *Observable:* Real turn exit 0, committed, tick cost captured. ✅ 2026-06-17.
- [x] **Build `claude-turn.sh` shim:** Mirrors `codex-turn.sh` — `rtl_init` → `rtl_before` →
      `claude -p "$prompt" --allowedTools "Bash,Read,Edit,Write" --permission-mode acceptEdits
      --output-format json --max-turns <N> --max-budget-usd <$>` → `rtl_enforce`.
      Builder gets `Edit,Write`; reviewers (Gemini, Codex) keep `"Bash,Read"`. Cost capture parses
      JSON transcript via `tick cost --tokens-in/--tokens-out`. 27/27 tests pass.
      *Observable:* Stub `claude` drives one turn through relay; off-allowlist edit → exit 6. ✅ 2026-06-17.

### QA checklist

- [ ] **Containment:** All three shims (`claude`, `codex`, `gemini`) source the SAME `relay-turn-lib.sh` — never reimplement.
- [ ] **Tool allowlist split:** builder (`claude-turn.sh`) = `"Bash,Read,Edit,Write"`; reviewers (`codex-turn.sh`, `gemini-turn.sh`) = `"Bash,Read"`. Verified before Phase 3.
- [ ] **Both cost ceilings set:** `claude-turn.sh` passes both `--max-turns` AND `--max-budget-usd` — neither alone is sufficient. Values sized from M2 spike output.
- [ ] **Round-cap arithmetic:** `--round-cap = 2 × max_review_rounds + 1` (turns ≠ rounds; off-by-one kills phases early). Validated before M3.
- [ ] **RELAY_PEER threading:** Every turn passes the peer explicitly — unnamed peer caused a live Gemini "release to literal role-string" failure on 2026-06-15.

---

## Part A · Phase 3 — Single-Phase Headless Loop (The Proof)

**Status: ✅ Shipped 2026-06-17** — `marathon-drive.sh` + `test/marathon-drive.sh` (27/27); `marathon.phase.*` events registered in tick schema; `validate.sh` 25/25. **Real multi-model E2E validated 2026-06-17 — BOTH reviewers** (Claude builder + Gemini reviewer; Claude builder + Codex reviewer), un-stubbed → `STATUS: Approved` in 2 turns, EXIT 0. The un-stubbed runs found + fixed three integration bugs stubs hid: **(1)** spaced agent-cmd path broke `relay-drive`'s `eval` → `marathon-drive` now `printf %q`-quotes `--agent-cmd`; **(2)** headless `claude -p` inherited the operator's ambient model (an Opus session blew the Sonnet-sized budget cap) → `claude-turn.sh` now pins `--model` (default `claude-sonnet-4-6`); **(3)** relative `./bin/tick` in the relay template made the builder skip the token handoff → template now bakes the **absolute** tick path. Bugs 1–2 have regression tests. Earlier test-only fix: `.tick/` state must be wiped between test cases. *(Codex reviewer requires sandbox-off — keychain/`chatgpt.com` blocked inside Claude Code's Bash sandbox.)*

> **"Real code out" — RESOLVED (Phase 3.5, 2026-06-17):** `marathon-drive --artifact PATHS` now gives the builder a bounded real write surface (exports `ALLOW_PATHS`, renders the template with the artifact in `claim --paths` + edit-scope). Without it the phase stays relay-only. `test/marathon-drive.sh` 31/31 (incl. a containment guard that relay-only leaves `ALLOW_PATHS` unset). First real-code dogfood target: `test/chaos-concurrent-pollers.sh` (Part B G4), run on a dedicated branch gated on `validate.sh`.

**Intent:** Prove the core five-step execution cycle (LOOPS.md) works entirely hands-free by
running one Marathon phase end-to-end. Gated on Phase 2 `claude -p` spike passing.

### Checklist

- [x] **Hardcoded single phase:** `marathon-drive.sh` renders `phases/p1/RELAY.md` from a template,
      seeds `MARATHON-P1-TURN` tick token with handoff → `claude`, calls
      `relay-drive.sh --agent-cmd marathon-agent.sh --round-cap 5` unmodified.
      *Observable:* build turn → review turn → `STATUS: Approved` → relay-drive exit 0. ✅
- [x] **Round-cap enforcement:** A deliberately failing relay-drive (exit 4) halts the driver.
      *Observable:* Loop stops; `ESCALATION.md` written; driver exits 4. ✅
- [x] **Transcript capture:** Relay file saved under `relay-system/<date>/marathon-p1-<time>.md` and committed.
      *Observable:* Transcript file exists and is committed after the run (scripted step, not a prompt). ✅
- [x] **`--pre-advance-cmd` hook:** `marathon-drive.sh` runs a configurable command before emitting
      `phase.approved` and advancing to the next phase. Default: `bash validate.sh`. Non-zero exit
      halts with `ESCALATION.md` — same failure path as a relay timeout.
      *Observable:* `ESCALATION.md` written on gate failure; driver exits 5; approved event NOT emitted. ✅

### QA checklist

- [x] **Agreement check:** `relay-drive.sh` exits 0 ONLY when `STATUS: Approved` AND token is done (both required). ✅ (delegated to relay-drive.sh, which is unmodified)
- [x] **Unmodified core:** Chaining works with `relay-drive.sh` completely untouched. ✅
- [x] **Only `phases/p1/RELAY.md` changed:** No other tracked file mutated by the headless run. ✅
- [x] **Pre-advance gate fires:** `validate.sh` (or the operator-supplied `--pre-advance-cmd`) runs
      automatically after relay-drive exits 0, before `phase.approved` is emitted. Operator can
      override to a lighter check for fast inner loops; default must be non-empty. ✅

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

**Intent:** Dogfood the completed **cost-observability** layer to generate the final cross-system
artifact requested in the feedback doc. *Scope note:* this is a **relay cost comparison** (xyz fixture
vs. one real Gemini relay turn), **not** a Marathon dogfood — the Marathon dispatcher/builder
(Part A Phase 2–4) is not built yet, so no Marathon build was measured here.

### Checklist

- [x] **Run xyz build with cost on:** Synthetic 2-lane fixture (`$TMPDIR/p3-xyz`); 4 tasks, 2 agents.
      *Observable:* `tick analyze` shows `tokens_total=58920`, coverage `4/4`, `run_type=symmetric`. ✅
- [x] **Run relay build with cost on:** Real Gemini headless turn under `-o json` on
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

The `tick` + relay-automation stack is **mechanically proven** (happy-path coordination, 22/22
`validate.sh`, live Codex + Gemini headless turns behind one safety boundary). Commercial viability
needs a different bar: **adversarial proof under failure**, with reproducible logs a buyer (or an
auditor) can replay. This track closes that gap.

Maturity ladder: **1. Mechanically proven** ✅ → **2. Adversarially proven** ⬅ *this track* →
**3. Commercially viable** (adversarial proof + packaging + SLA/observability + reference deploy).

Each item carries a **Threat**, what a log must **Prove**, the **Test/artifact** it emits, the
mechanism it **Leans on**, and an honest **Status** (✅ proven · ⚠️ partial/unproven · ❌ missing
mechanism).

---

## Part B · Phase 1 — Epoch Fencing & Stale-Writer Prevention (R1 + G3)

**Status: 🔲 Not started — ❌ missing mechanism (highest priority in this track)**

> **G3 — Stale-writer fencing (the keystone).**
> **Threat:** agent X is presumed dead and the token is taken over (reap → reclaim by Y); then X
> *revives* and issues `done`/`release`/edit — a zombie advances or corrupts the relay after losing it.
> **Prove:** once ownership moves on, the stale epoch **cannot write/commit/advance** — its events are
> *fenced (rejected)* by the kernel, not merely ignored by convention.
> **Test/artifact:** `test/chaos-stale-writer.sh` → a rejected-event log showing the fence firing.
> **Leans on:** ownership enforcement (only the claimer can mutate) — **but that is not epoch fencing.**
> Today's `tick` has no monotonic fencing token, so a revived X with the same agent id still passes
> ownership checks after takeover.
> **Status:** ❌ **Missing mechanism** — the difference between "soft coordination" and "a kernel you
> can trust unattended." This is why R1 is sequenced first.

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

Package the deliberate failure scenarios and operationalize the watchdog's auto-recovery.

> **G1 — Mid-turn termination.**
> **Threat:** an agent dies *after* `claim` but *before* `release`/`done` — the token is held by a
> corpse and the relay stalls forever.
> **Prove:** the watchdog **detects** the stall within a bounded time and either **recovers** (reap →
> re-offer to a live agent, exactly once) or **safely halts** with a structured escalation — never
> silently hangs, never double-assigns.
> **Test/artifact:** `test/chaos-midturn-kill.sh` → watchdog JSON escalation + before/after token state.
> **Leans on:** `watchdog.sh` (`tick analyze --format json` → `parked_suspects[]`), `relay-drive.sh`
> no-progress escalation, `tick ping` heartbeats.
> **Status:** ⚠️ *Partial* — detection is unit-tested; the recovery half (auto-reap) is a stub behind
> `--allow-reap` (see R2). No deliberate kill-mid-turn chaos log yet.

> **G2 — Duplicate / ambiguous turn token.**
> **Threat:** two claims/ownership events for one token (race, replay, or a duplicated event file) →
> ambiguous "whose turn," double-execution.
> **Prove:** the projection kernel **deterministically resolves to exactly one owner** (or quarantines
> the token) — identical result on every replay, regardless of arrival order.
> **Test/artifact:** `test/chaos-dup-token.sh` → projection output across N replays (must be identical).
> **Leans on:** disjoint-files-per-event log, single-pass projection + deterministic tie-breaker
> (earliest ts, then lex agent id), the handoff-exclusive rule.
> **Status:** ⚠️ *Partial* — tie-breaker + handoff-exclusivity are tested; adversarial
> duplicate-injection + quarantine is not a standalone proof yet.

> **G4 — Concurrent pollers.**
> **Threat:** two eligible poller loops (two windows, or window + cron) both see "my turn / parked"
> and both act → double turn, double escalation, double commit.
> **Prove:** under a genuine race, **exactly one poller acts**; the others observe the state change
> and stand down.
> **Test/artifact:** `test/chaos-concurrent-pollers.sh` → per-poller decision log over N trials
> (must be 1-acts every time).
> **Leans on:** the lock/heartbeat as the real guard (not the timer), `--watchdog-authority` (exactly
> one authority), the token as the mutex.
> **Status:** ⚠️ *Partial / by-design but unproven* — no race-hammer test drives two pollers
> concurrently and counts winners yet.

> **R2 — Auto-reap authority.** Unblocks G1's recovery half: decide who may reap and on what evidence,
> record it, and flip `watchdog.sh --allow-reap` from stub to real.
> **R5 — Resource / quota limits** *(Gemini review 2026-06-15).* Cap per-turn wall-clock, disk, and
> API spend in the turn-taker shim so a headless agent can't run away; pairs with the `relay-drive.sh`
> round-cap. **Status:** ❌ not started (per-turn ceilings missing).

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

Prove the protocol generalizes beyond the home repository and supports true multi-device coordination.

> **G5 — Cross-repo / cross-model diversity.**
> **Threat:** the protocol is secretly coupled to *this* repo or to all-Claude/manual flows — it won't
> generalize, so it has no product surface.
> **Prove:** the same protocol runs in a **different repository** (zero-setup from the packaged skill)
> **and** with **heterogeneous agents** taking real turns (not just Claude, not just manual nudge).
> **Test/artifact:** `test/e2e-fresh-repo.sh` → transcript + commit graph from a foreign repo.
> **Leans on:** the packaged sibling skill (`relay-pkg.tar.gz`, `QUICKSTART.md`), `codex-turn.sh` +
> `gemini-turn.sh` over the shared core.
> **Status:** ⚠️ *Partial* — cross-**model** is live-proven (Codex + Gemini headless turns) and the
> MBP16 field report drove a real cross-**repo** run; but there's no zero-setup fresh-clone E2E
> proving no home-repo coupling, and `.tick/` is still per-device-local.
> **R3 — Cross-machine `.tick/` sync:** an out-of-band ref or daemon so machines share coordination state.

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

The final mile to commercial viability: the system is auditable and deployable with SLA-backing.

> **R4 — Observability surface** (commercial table-stakes). Structured, timestamped logs for every
> claim / handoff / reject / escalation that a buyer can ship to their SIEM.
> **Threat:** logs today are human-readable, not structured for ingestion — a buyer cannot ship them
> to a SIEM. This is the final mile to commercial viability.
> **Prove:** every coordination event emits a parseable, timestamped record with agent id + epoch.
> **Status:** ❌ not started (logs today are human-readable, not structured for ingestion).

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

---

*Part B gaps map to the backlog in `4X4.md`; any mechanism that changes the event schema (e.g. R1
epoch fencing) gets a decision record before it lands. Part B was merged 2026-06-15 from the flat
gap-analysis + the phased/QA structure, then folded into this roadmap — now the canonical `ROADMAP.md`
(the earlier standalone gap-analysis roadmap is superseded).*
