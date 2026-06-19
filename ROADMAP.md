---
title: Combined Roadmap — Cost-Observed Marathon Loops + Adversarial Hardening
status: Active
created: 2026-06-16
updated: 2026-06-18
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
| **Part A Phase 3.6 — worktree isolation** ✅ shipped 2026-06-18 (opt-in `RELAY_WORKTREE_ISOLATION=1`; `test/worktree-isolation.sh` 12/12) — the airtight async/side-effect close, which **unblocks Phase 6**. (Phase 4 M5 + Phase 6 plan done earlier.) `validate.sh` **33/33**. | **Part A Phase 6 — WPCC real-monolith dogfood** 🟢 now unblocked: run the experiment (`PROJECT/2-WORKING/MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md`) with isolation on. |
| **Part B Phase 1 — Epoch fencing & stale-writer prevention** ✅ shipped 2026-06-18 (R1 + G3) + **Phase 2 partials**: G1 mid-turn-kill **detection** + R5 **wall-clock** cap. `validate.sh` **32/32**. | **Part B Phase 2 remainder** — R2 auto-reap authority, G2 dup-token determinism, G4 concurrent-pollers (+ R5 disk/codex-gemini-spend ceilings). |

> **⚠️ Operational note — Gemini CLI temporarily swapped for Antigravity CLI (`agy`) (2026-06-18).**
> The Gemini CLI (0.46.0) is throwing **false-positive "out of credits" errors** on this account — a
> Google-side account/system bug, not a real quota exhaustion. Until Google fixes the account and/or
> their system, the **Antigravity CLI (`agy`) is the stand-in for the Gemini lane.** A parallel shim
> `relay-automation/agy-turn.sh` (mirrors `gemini-turn.sh` on the shared `relay-turn-lib.sh` core) is
> routed via `AGY_AGENT` in `marathon-agent.sh`; `test/agy-turn.sh` 19/19, `validate.sh` 32/32.
> `agy` is authed off the signed-in Antigravity desktop app and is itself a multi-model gateway
> (Gemini / Claude / GPT-OSS via `--model`). **Two known limitations vs. the Gemini shim** (memory:
> `agy-antigravity-cli`): (1) `agy -p` exits 0 with **empty output** when its backend is blocked (e.g.
> under a sandbox) — the shim treats empty-output-on-success as a hard failure (exit 5) so a blocked
> turn can't read as a phantom success; **run agy turns sandbox-OFF.** (2) `agy` has **no JSON/token
> output**, so an agy lane is **cost-blind** (a floor, same Phase-1 partial as the Codex lane).
> **Revert trigger:** Google restores correct credit accounting on the Gemini CLI → switch the lane's
> agent id back from `AGY_AGENT` to `GEMINI_AGENT`. The Gemini shim is unchanged and ready.

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
- [Part A · Phase 3.6 — Autonomous-builder hardening (dogfood findings)](#part-a--phase-36--autonomous-builder-hardening-dogfood-findings)
- [Part A · Phase 4 — Multi-Phase Chaining & State (Full Marathon)](#part-a--phase-4--multi-phase-chaining--state-full-marathon)
- [Part A · Phase 5 — Cross-System Comparison (The Payoff)](#part-a--phase-5--cross-system-comparison-the-payoff) ✅
- [Part A · Phase 6 — Real-Monolith Dogfood (WPCC): the graduation test](#part-a--phase-6--real-monolith-dogfood-wpcc-the-graduation-test) 🔜

**Part B — Adversarial Hardening**
- [Part B · Phase 1 — Epoch Fencing & Stale-Writer Prevention](#part-b--phase-1--epoch-fencing--stale-writer-prevention-r1--g3)
- [Part B · Phase 2 — Chaos Suite & Auto-Recovery](#part-b--phase-2--chaos-suite--auto-recovery-g1-g2-g4-r2-r5)
- [Part B · Phase 3 — Cross-Repo E2E & Multi-Device Sync](#part-b--phase-3--cross-repo-e2e--multi-device-sync-g5-r3)
- [Part B · Phase 4 — Observability & Reference Deploy](#part-b--phase-4--observability--reference-deploy-r4)

**Part C — Autonomous Self-Improvement**
- [Part C — Autonomous Self-Improvement Loop (the LOOPS.md endgame)](#part-c--autonomous-self-improvement-loop-the-loopsmd-endgame) 🔮

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

## Part A · Phase 3.6 — Autonomous-builder hardening (dogfood findings)

**Status: ✅ Done (4 of 4) — airtight close shipped 2026-06-18 (opt-in).** Surfaced by the G4 dogfood
(real autonomous build of `test/chaos-concurrent-pollers.sh`; see CHANGELOG). The build *succeeded*
but the builder went off-task — pulled in by stray untracked briefs, it ran `consult` (real
Codex+Gemini API calls) and edited an off-lane skill file. Containment caught the tracked edit (✅).
**Done surgically:** tool-surface shadow, clean-workspace precondition, exit-6 escalation. **Airtight
close (NEW 2026-06-18):** **worktree isolation** — `RELAY_WORKTREE_ISOLATION=1` runs the builder turn
in a *throwaway git worktree*, so async/background writes land in a tree we delete, never ROOT;
`.tick` stays shared via `TICK_REPO_ROOT`; only the allowlist is copied back; an off-lane change in the
worktree → **exit 6 (contained AND escalated)**. Opt-in (default off → prior behaviour byte-identical).
`test/worktree-isolation.sh` 12/12 (incl. the adversarial background-spawn case); `validate.sh` 33/33.
Process-group reap is now redundant for ROOT-safety (isolation makes ROOT unreachable regardless).
This **unblocks the [Part A · Phase 6 WPCC dogfood](#part-a--phase-6--real-monolith-dogfood-wpcc-the-graduation-test)**.

**Intent:** make the headless builder safe to run unattended in a real repo — bound *side effects*,
not just tracked-file edits.

### Checklist

- [ ] **Bound the builder's tool surface (root cause).** `Bash,Read,Edit,Write` lets the builder
      spawn anything (it ran `consult` → external model calls). ✅ **Done 2026-06-17:** `claude-turn.sh`
      PATH-shadows `codex gemini consult consult.sh marathon-drive.sh relay-drive.sh` for the builder's
      `claude -p` subprocess ONLY (reviewer turn unaffected); even a path-invoked `consult.sh` is
      neutered because its internal bare `codex`/`gemini` calls hit the stubs. Override via
      `CLAUDE_BLOCK_CMDS`. Test: `test/claude-turn.sh` case 7b (builder can't spawn gemini/codex; shadow
      is subprocess-scoped). *Not airtight* — an absolute-path call to the real binary bypasses it;
      worktree isolation (below) is the airtight version.
- [x] **Close the async-side-effect gap.** ✅ **Done 2026-06-18 (opt-in):** the builder turn runs in an
      **isolated git worktree** (`RELAY_WORKTREE_ISOLATION=1`) — any async side effect lands in the
      throwaway tree, not the real repo; only the allowlist is copied back; off-lane in the worktree →
      exit 6. Process-group reap proved unnecessary (ROOT is unreachable regardless). Helpers
      `rtl_worktree_begin`/`rtl_worktree_end` in `relay-turn-lib.sh`; wired into `claude-turn.sh`
      (builder; reviewers are read-only). Test: `test/worktree-isolation.sh` case 1.
      *Observable (now proven):* no repo mutation survives a turn that spawned a background process. ✅
- [x] **Clean-workspace precondition.** ✅ **Done 2026-06-17:** `marathon-drive` warns (lists pre-existing
      dirty/untracked files outside `phases/`+`.tick/`) before seeding, and `--require-clean` hard-stops
      (exit 2) for unattended runs. Test: `test/marathon-drive.sh` case 13.
- [x] **`marathon-drive` handles turn exit 6 cleanly.** ✅ **Done 2026-06-17:** exit 6 (turn-taker
      reverted an off-lane edit) now writes `ESCALATION.md` (reason: containment-violation) and exits 6,
      like the other escalation paths — no more "unexpected code 6" die. Test: `test/marathon-drive.sh` case 8b.

### QA checklist

- [x] Containment now bounds side effects — tool-shadow stops external-model spawns; **worktree isolation (opt-in) closes the rest** (async writes land in the throwaway tree). ✅ 2026-06-18
- [x] A deliberately rogue builder (scripted to spawn a subprocess + edit off-lane) is fully contained + escalated. ✅ `test/worktree-isolation.sh`: case 1 (background async-spawn → ROOT byte-clean), case 2 (sync off-lane → exit 6, nothing copied back).
- [x] `validate.sh` green with no regressions from the hardening — **33/33** (worktree isolation is opt-in; the default in-ROOT path is byte-identical, so existing shim tests are unchanged).

---

## Part A · Phase 4 — Multi-Phase Chaining & State (Full Marathon)

**Status: 🟡 M5 shipped + E2E-validated 2026-06-17; M6 + M7 deferred.** A `MARATHON.yaml` plan runs
end-to-end: parse → resolve `depends_on` order → run each phase via `marathon-drive` → halt on the
first failure → `marathon.complete` on full success. `validate.sh` 28/28. **Real 2-phase E2E run
(Claude builder + Codex reviewer, un-stubbed, `depends_on` chain):** both phases reached Approved,
`marathon.complete` emitted, state cleanliness verified (p2 built from a clean tree), and the
AI-built cross-phase code worked (p2's test passed against p1's helper). All 3 QA invariants met.

**Intent:** Scale the single loop into an ordered DAG of loops, fulfilling the full MARATHON.md vision.

### Checklist

- [x] **Parse `MARATHON.yaml`:** ✅ **M5 2026-06-17** — zero-dep Node reader (`src/marathon-yaml.js` +
      `bin/marathon-yaml`): constrained-subset parse, validation (bad reviewer / unknown dep / cycle /
      dup id), topological `depends_on` order → TSV/JSON. Test `test/marathon-yaml.sh` 11/11.
- [x] **Phase chaining & escalation:** ✅ **M5 2026-06-17** — `relay-automation/marathon.sh`: per-phase
      `round-cap = 2*max_review_rounds+1`, routes reviewer/brief/artifact to `marathon-drive --phase-id`,
      advances on exit 0, HALTS on the first non-zero (later phases never start; the phase's
      `ESCALATION.md` is already written), emits `marathon.complete` only on full success. `marathon-drive`
      generalized with `--phase-id` (phases/<id>/, `MARATHON-<ID>-TURN`; 38/38 backward-compat). Test
      `test/marathon.sh` 11/11 (order, cap math, halt-after-middle-phase, depends_on reorder, error paths).
- [ ] **State projection (M7):** `MARATHON-STATE.md` projected from `.tick/events/` *(deferred — boundary
      events already land in `.tick/events/`: phase.start/approved/escalated + marathon.complete)*.
      *Observable:* State file reflects current phase, per-phase round counts, and statuses.
- [ ] **Cross-phase context injection (M6):** Approved prior-phase artifact prepended into next builder
      prompt *(deferred — spec says "start without this; add only once a phase genuinely needs it")*.
      *Observable:* Phase 2 builder turn visibly references a decision from Phase 1.

### QA checklist

- [x] **State cleanliness:** Next phase's `rtl_before` snapshot is clean before it starts. ✅ **Verified by
      a real 2-phase E2E run 2026-06-17** (Claude builder + Codex reviewer, `depends_on` chain): the p2
      builder commit touched ONLY `phases/p2/RELAY.md` + its own artifact — not p1's files — proving p2
      started from a clean tree with no p1 residue. Both phases reached Approved, `marathon.complete` emitted.
- [x] **Peer threading:** `RELAY_PEER` passed on every turn handoff — no bare "the other agent" strings.
      ✅ `marathon-drive` exports `MARATHON_BUILDER`/`REVIEWER` per phase; `marathon-agent:35` threads `RELAY_PEER`.
      Confirmed independently by the Gemini QA review (2026-06-17, `relay-system/.../phase4-qa-220946/`).
- [x] **Emit tick events at phase boundaries:** ✅ `marathon.phase.start` (mdrive:229) / `approved` (288) /
      `escalated` (262) + `marathon.complete` (marathon.sh:95) — all emitted; seen live in the G4/CI dogfood tick chains.

> **Automated QA review (Gemini, 2026-06-17):** verdict *"ship-ready for dogfood; all 3 invariants met."*
> No real blockers — its one **[Blocker]** (round-cap "one turn short") was **refuted against `relay-drive:88`**
> (the cap is a maximum; the relay exits early on approval, so `2N+1` correctly provisions N reviews; the
> suggested `2N+2` would over-grant a review). It independently confirmed the `tr→\037` tab fix, peer
> threading, and topo-sort determinism, and flagged the stub-coverage gap (→ the real multi-phase E2E run).
> *(Single-advisor: Codex died on a resource kill, so each Gemini claim was verified against source.)*

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

## Part A · Phase 6 — Real-Monolith Dogfood (WPCC): the graduation test

**Status: 🟢 Unblocked 2026-06-18 — the Phase 3.6 worktree-isolation gate shipped (opt-in).** Ready to
run with `RELAY_WORKTREE_ISOLATION=1`. Standalone plan (Codex-reviewed, Approved r2):
`PROJECT/2-WORKING/MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md`.

**Why it's in the bigger picture:** Phases 1–5 prove Marathon on *synthetic* code (`greet.js`). This
is the **graduation test** — the first run of the whole harness against a **real 6,988-line / 275 KB
production monolith** (WPCC `dist/bin/check-performance.sh`), with **Codex + `agy`** as the workers.
It harvests the data the toy phases cannot, as pre-registered questions Q1–Q6:
- **Q1** — feasibility of a headless `claude -p` edit to a 275 KB file at fixed caps,
- **Q2** — an objective fixture-gate pass/fail on AI-built detector code,
- **Q3** — containment on a real repo (the live re-test of Phase 3.6),
- **Q4/Q5** — a *falsifiable* Codex-vs-`agy` reviewer comparison (first live agy relay turn),
- **Q6** — chain cleanliness across a real dependency edge (conditional).

Output feeds `REAL-AGENT-OBSERVATIONS.md` and a **graduate / iterate / abandon** verdict on the
harness — closing the Part A "does this work on real code?" question and feeding the Part B
"adversarially proven → commercially viable" ladder. (An external consumer already rated the
containment core *"production-quality"* in a real cross-repo run — see `PROJECT/1-INBOX/FEEDBACK/FEEDBACK-KWFS-02.md`.)

**Scope discipline:** it is a HARNESS experiment with WPCC as the substrate — NOT an autonomous
scanner rebuild. One bounded slice (WPCC Phase 2 `php-direct-access-entrypoint`), one new variable per
run. A run that fails honestly is a passing experiment.

**Sequencing:** the gate — **Phase 3.6 worktree isolation** — **shipped 2026-06-18** (opt-in
`RELAY_WORKTREE_ISOLATION=1`), so the clean unattended run is available now. Still **independent of
Part B Phase 2** (chaos suite). Run on a dedicated branch in `wp-code-check` (the plan's blast-radius
backstop), with isolation on.

> Pointer, not a duplicate. The pre-registered Q1–Q6, the one-variable-per-run design, the reviewer
> scoring rubric, and per-phase QA all live in the plan doc above.

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

**Status: ✅ Shipped 2026-06-18 — mechanism in place.** Monotonic per-task `epoch` added to the
event schema (0.1.0 → 0.2.0); the projection kernel (`src/project.js` `fold`) now fences any mutation
below the current owner's epoch — **including a same-id zombie**, the keystone the threat names.
`test/chaos-stale-writer.sh` 13/13 (keystone same-id reclaim + cross-agent takeover); fenced events
land in a deterministic `.tick/rejected.jsonl` (surfaced by `tick fences`). `validate.sh` **29/29**, no
regressions. Decision record: `decisions/2026-06-18-epoch-fencing.md`. *(Kernel diff written on Opus
per the model-assignment table; remaining Part B work reverts to Sonnet High.)* **Carried forward:**
epoch is assigned under the per-clone `withClaimLock` — cross-machine concurrent claims (R3) are out of
scope and flagged as this record's revisit trigger.

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

- [x] **R1: Implement monotonic epoch fencing tokens.** ✅ 2026-06-18
  - [x] Add `epoch` field to claim events in the event schema. ✅ (`src/events.js`, schema 0.2.0; absent ⇒ epoch 0)
  - [x] Modify `tick` projection kernel to track the current owner's epoch. ✅ (`fold`: owner = highest live epoch)
  - [x] Reject mutating events (`done`/`release`/scope) whose epoch is older than the current owner's. ✅
        Plus two sub-invariants: a `released` retires a claim only at `epoch >= claim.epoch` (same-id keystone);
        a handoff is honoured only from the latest epoch (no zombie redirect).
- [x] **G3: Build `test/chaos-stale-writer.sh`.** ✅ 2026-06-18 (13/13)
  - [x] Script: claim as agent X → force reap+reclaim (new epoch) → replay X's `done`/`release`/scope events. ✅
        Keystone scenario uses a **same-id** reclaim so ownership passes and only the epoch fences.
  - [x] Assert: every stale event rejected; relay state byte-identical; owner still completes. ✅

### QA checklist

- [x] `test/chaos-stale-writer.sh` emits a rejected-event log showing the fence firing. ✅ (`.tick/rejected.jsonl`, `tick fences`; deterministic across re-projections)
- [x] `validate.sh` green with no regressions from epoch addition. ✅ **29/29** (28 prior + the new chaos test; baseline is no longer 22).
- [x] Schema change documented in a decision record. ✅ `decisions/2026-06-18-epoch-fencing.md`

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
> **Status:** ⚠️ *Partial — detection PROVEN 2026-06-18* (`test/chaos-midturn-kill.sh`, 8 assertions:
> orphaned claim flagged in `parked_suspects[]` past threshold + false-positive guard; `watchdog.sh`
> exits 0 with exactly one valid-JSON escalation record — never hangs). The recovery half (auto-reap)
> remains a stub behind `--allow-reap`, gated on **R2**.

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
- [~] **G1: Build `test/chaos-midturn-kill.sh`** (mid-turn termination). *(detection half ✅ 2026-06-18; recovery gated on R2)*
  - [x] Claim as agent X → simulate death (zero heartbeats, time advanced via `TICK_TS`) → assert `parked_suspects[X]` flagged (+ false-positive guard). ✅
  - [~] Assert: structured JSON escalation emitted ✅; **auto-reap re-offers token exactly once** ⬅ deferred (R2 `--allow-reap` stub).
- [ ] **G2: Build `test/chaos-dup-token.sh`** (duplicate/ambiguous token).
  - [ ] Inject concurrent/duplicate claims → assert projection resolves to exactly one stable winner across N replays.
  - [ ] Inject malformed/duplicate event files → assert safely quarantined without crash.
- [ ] **G4: Build `test/chaos-concurrent-pollers.sh`** (concurrent pollers).
  - [ ] Launch two concurrent `poll.sh` instances against the same relay state.
  - [ ] Assert exactly one poller acts; the other idles — across N trials.
- [~] **R5: Resource / quota limits** (per-turn runaway containment; Gemini 2026-06-15). *(wall-clock ✅ 2026-06-18; disk + codex/gemini spend deferred)*
  - [x] Cap per-turn **wall-clock** in the turn-taker shim. ✅ `rtl_run_bounded` (coreutils-free) in `relay-turn-lib.sh`; all 3 shims via `RELAY_TURN_TIMEOUT_S` (default 300); timeout → exit 7. Test `test/relay-turn-timeout.sh` 9/9.
  - [~] **disk** + **per-turn API spend (codex/gemini)** ceilings — deferred (claude already has `--max-budget-usd`; disk belongs in a TMPDIR watchdog). In-code `# NOTE:`s mark the gap.
  - [x] Pairs with `relay-drive.sh` round-cap (turn COUNT); wall-clock adds the per-turn TIME ceiling. ✅

### QA checklist

- [~] `test/chaos-midturn-kill.sh` passes with watchdog JSON escalation (detection ✅ 8/8); "correct recovery state" deferred to R2.
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

## Part C — Autonomous Self-Improvement Loop (the LOOPS.md endgame)

**Status: 🔮 Vision / Not started — gated on the prerequisites below.** Everything to date builds the
*cage*; this is the experiment the cage exists for. The Phase 6 dogfood is its controlled, bounded,
human-gated precursor — a single iteration with a binary gate. Part C removes "single" and
"human-gated": an **unattended loop that measurably improves an artifact against a scalar, behind an
un-gameable oracle, until a stop condition fires.** Do NOT start it before the prerequisites land —
an autonomous optimizer without all three pillars is a budget bonfire or a silently-gamed metric.

**Intent:** turn the build↔review *convergence* loop (Part A) into a metric-driven *optimization*
loop — the LOOPS.md endgame — without sacrificing the trust properties Parts A/B established.

### The three pillars (a loop is illegitimate without all three)

- **Metric — the scalar it optimizes.** A deterministic, machine-readable number emitted after each
  iteration (test-pass count, benchmark score, perf/throughput, finding count, binary size, coverage).
  New surface: a pluggable **`--measure-cmd`** (sibling to `--pre-advance-cmd`) that prints ONE number;
  same input → same number, or the loop chases noise instead of climbing.
- **Oracle — the un-gameable correctness gate.** Stops the loop "winning" by cheating (deleting tests,
  hardcoding outputs, editing the benchmark). Two layers we already have: the **mechanical** oracle
  (`--pre-advance-cmd` test/fixture suite) + the **semantic** oracle (the reviewer turn). The
  load-bearing rule: **the oracle must live OUTSIDE the builder's write surface** — enforce
  `ALLOW_PATHS ∩ oracle-paths = ∅`, or the loop optimizes the oracle instead of the artifact.
- **Stop condition — why it terminates.** Autonomy demands a guaranteed halt. Compose: a **cumulative
  budget** ceiling ($ / tokens / wall-clock across ALL iterations — new; today's caps are per-turn) +
  **plateau detection** (K consecutive no-improvement iterations) + a **target** (metric hits goal) +
  a hard **iteration cap**. Plus a **regression guard**: never accept an iteration whose oracle fails
  or whose metric regressed — keep the champion.

### The loop (champion/challenger hill-climb with a correctness gate)

1. **Baseline:** measure metric₀ on the starting artifact under the oracle (which must already pass).
2. **Each iteration, in an isolated worktree:** builder proposes a change → oracle gate (tests +
   reviewer) → measure metric. **Accept** iff oracle passes AND metric improved; else **reject**
   (discard the worktree, keep the champion). *Reuses worktree isolation (3.6) + per-turn caps (R5) +
   epoch fencing (B·P1) — the safety cage is already built.*
3. **Halt** on: cumulative budget exhausted ∨ plateau(K) ∨ target reached ∨ iteration cap. Emit the
   **champion** + a provenance log (every accepted/rejected step, the metric trace, the spend).

### Prerequisites (this is why it's gated, not "next")

- [ ] **Cumulative budget ceiling** across iterations (`--max-total-budget`), not just per-turn.
- [ ] **`--measure-cmd` metric harness** — deterministic scalar capture; floor-vs-exact honesty.
- [ ] **Oracle-immutability guard** — assert `ALLOW_PATHS` excludes the oracle/test paths; fail loudly otherwise.
- [ ] **Champion/challenger state** — keep best-so-far; accept-on-improve; rollback-on-regress.
- [ ] **Anti-gaming / held-out validation** — a second metric the builder cannot see, to catch overfit/gaming.
- [ ] **Full cost observability** — close the Codex/agy/Claude capture gaps (Phase 1 deferral) so the
      loop's OWN efficiency (improvement-per-dollar) is measurable, not a floor.
- [x] **Autonomy safety cage** — worktree isolation (3.6 ✅), per-turn caps (R5 ✅), epoch fencing (B·P1 ✅).

### QA checklist

- [ ] **Termination proof:** the loop provably halts on every stop path (budget/plateau/target/cap) — no infinite run.
- [ ] **Un-gameable:** an adversarial builder that edits the oracle or hardcodes the benchmark is *contained* (oracle outside write surface) AND *caught* (held-out metric).
- [ ] **No-regress:** the emitted champion's metric ≥ baseline and oracle-passing — always; a losing run ships *nothing*, never a worse artifact.
- [ ] **Provenance:** every accept/reject + metric + spend logged deterministically (feeds R4 observability).
- [ ] **Determinism litmus:** same seed/target → same champion, or the metric noise is explicitly bounded and disclosed.

> **Why this is the capstone, not a side-quest:** Part A proved the loop *runs*; Part B proves it
> *survives failure*; Part C is the only track where the system changes its own artifacts toward a goal
> with no human in the inner loop. That is exactly why it is sequenced last — it is safe to attempt
> *only* once containment (3.6), per-turn limits (R5), and the fencing kernel (B·P1) are trustworthy,
> and once cost is fully observable (the loop must be able to see — and cap — what it spends on itself).

---

*Part B gaps map to the backlog in `4X4.md`; any mechanism that changes the event schema (e.g. R1
epoch fencing) gets a decision record before it lands. Part B was merged 2026-06-15 from the flat
gap-analysis + the phased/QA structure, then folded into this roadmap — now the canonical `ROADMAP.md`
(the earlier standalone gap-analysis roadmap is superseded).*
