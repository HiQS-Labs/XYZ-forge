---
title: Marathon harness — build record (dispatcher · headless loop · containment · chaining)
slug: marathon-harness
status: Completed
created: 2026-06-17
updated: 2026-06-21
owner: Noel (operator) · Claude (producer)
branch: main
related:
  - PROJECT/1-INBOX/MARATHON.md                                   # the design/implementation plan this realizes
  - PROJECT/2-WORKING/MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md  # active graduation test that exercises this harness
  - PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md                  # Part A Phase 1 cost foundation (prerequisite)
  - relay-automation/marathon.sh
  - relay-automation/marathon-drive.sh
  - relay-automation/marathon-agent.sh
goal: >
  Build record for the Marathon headless-relay harness (ROADMAP Part A Phases 2, 3, 3.6, 4): the
  dispatcher + cross-model turn-takers, the single-phase headless loop, the autonomous-builder
  containment hardening, and multi-phase MARATHON.yaml chaining. Shipped + E2E-validated; M6/M7
  deferred until a phase needs them. This is the canonical detail ROADMAP.md points at.
---

# Marathon harness — build record

ROADMAP Part A "Marathon" execution detail for the harness build: **Phase 2** (dispatcher & headless
builder), **Phase 3** (single-phase headless loop), **Phase 3.6** (autonomous-builder hardening), and
**Phase 4** (multi-phase chaining & state). Part A Phase 1 (cost foundation) and Phase 5 (cross-system
comparison) live in [COST-OBSERVABILITY-PLAN.md](../2-WORKING/COST-OBSERVABILITY-PLAN.md) +
[COST-COMPARISON.md](../2-WORKING/COST-COMPARISON.md); Phase 6 (WPCC dogfood) is the active graduation
test in [MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md](../2-WORKING/MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md).

## Status

| What was just completed | What's next |
|---|---|
| **Phases 2, 3, 3.6 shipped + Phase 4 M5 E2E-validated** — full headless build→review→chain harness proven on synthetic code (claude/codex/agy turn-takers on shared `relay-turn-lib.sh`; airtight worktree-isolation close 2026-06-18; `validate.sh` 33/33). | **Harness build complete.** M6 (cross-phase context injection) + M7 (state projection) are **deferred** until a phase needs them (see [Deferred](#deferred--m6--m7) → `BACKLOG.md`/`4X4.md`); the live exercise is the [WPCC dogfood](../2-WORKING/MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md). |

## Operational note — cross-model lane

**Gemini CLI retired 2026-06-19; agy (Antigravity CLI) is the permanent cross-model lane.**
`relay-automation/agy-turn.sh` (on the shared `relay-turn-lib.sh` core) is routed via `AGY_AGENT`
in `marathon-agent.sh`; `test/agy-turn.sh` 19/19. `agy` is authed off the signed-in Antigravity
desktop app and is itself a multi-model gateway (Gemini / Claude / GPT-OSS via `--model`).
**Two known limitations** (memory: `agy-antigravity-cli`): (1) `agy -p` exits 0 with **empty output**
when its backend is blocked (e.g. under a sandbox) — the shim treats this as a hard failure (exit 5);
**run agy turns sandbox-OFF.** (2) `agy` has **no JSON/token output**, so an agy lane is
**cost-blind** (a floor, same Phase-1 partial as the Codex lane).

## Model assignment (build-track guidance)

The dividing line is **mechanical/pattern-following work** (Sonnet High is excellent) vs.
**trust-critical kernel-correctness reasoning** (reserve Opus). The mechanical bulk is most of the
line-count; the Opus-worthy core is small and self-contained, so this split is also the cheapest one.

| Work item | Model | Why |
|---|---|---|
| `claude -p` headless spike (A·P2) | **Sonnet High** | Empirical — run a turn, read the JSON, log the token/wall-clock number. Almost no reasoning depth. |
| `marathon-agent.sh` + `claude-turn.sh` (A·P2) | **Sonnet High** | `case` router + a shim mirroring the existing `codex-turn.sh`/`agy-turn.sh` against shared `relay-turn-lib.sh`. Pattern-following with a concrete on-disk reference. |
| `marathon-drive.sh` single-phase loop (A·P3) | **Sonnet High** | Integration against an untouched `relay-drive.sh` + a clear checklist. Scaffolding acts as template. |
| Chaos **test scripts** (B·P2: midturn-kill, concurrent-pollers) | **Sonnet High** | `kill -9` + watchdog-assertion harnesses are mechanical once the mechanism exists. |
| E2E fresh-repo script, observability JSON logs, reference-deploy docs (B·P3/P4) | **Sonnet High** | Scripting + docs, low ambiguity. |
| Multi-phase DAG: `MARATHON.yaml` parse, state projection, cross-phase injection (A·P4) | **Sonnet High** *(spec)* → **Opus** *(review)* | Design is fully specified in the plan; Sonnet implements against the spec, Opus reviews escalation/ordering edges. |
| **R1 epoch fencing — projection kernel change (B·P1)** | **Opus** | Monotonic-epoch semantics + replay determinism + "stale writer *cannot* advance" is an adversarial-correctness invariant. A subtle bug isn't a failing test — it's a silently-corruptible coordinator. *(The chaos test around it is Sonnet-fine; the kernel mutation is not.)* |
| **G2 dup-token determinism + quarantine (B·P2)** | **Opus** | "Identical projection across N replays regardless of arrival order" is a correctness proof, not a script. |
| Graduate / iterate / abandon synthesis | **Opus** | Judgment, not mechanics. |

**Practical pattern:** let Sonnet High do the spike, all the shell shims, and the test harnesses;
reserve Opus for the **epoch-fencing kernel diff and the G2 determinism logic** — the two places where
a subtle bug is silent corruption, not a red test.

---

## Phase 2 — The Dispatcher & Headless Builder (Marathon prep)

**Status: ✅ Shipped 2026-06-17** — real authenticated turn measured: 7 turns, $0.172, 26s (Sonnet 4.6). Ceilings set: `--max-turns 12`, `--max-budget-usd 0.50`.

**Intent:** Build the execution wrappers required by MARATHON.md, creating the "Action" and
"Cross-Model Verification" mechanisms described in LOOPS.md.

### Checklist

- [x] **Confirm cross-model shim:** `gemini-turn.sh` (now deprecated) was validated; replaced by `agy-turn.sh`
      (Antigravity CLI, 19/19 tests); live Gemini turn validated 2026-06-16 before CLI retirement. ✅
- [x] **Create `marathon-agent.sh` dispatcher:** `case "$RELAY_AGENT"` router — execs `claude-turn.sh`,
      `codex-turn.sh`, or `agy-turn.sh`; passes `RELAY_PEER` through; exits 2 on unknown agent.
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
      Builder gets `Edit,Write`; reviewers (agy, Codex) keep `"Bash,Read"`. Cost capture parses
      JSON transcript via `tick cost --tokens-in/--tokens-out`. 27/27 tests pass.
      *Observable:* Stub `claude` drives one turn through relay; off-allowlist edit → exit 6. ✅ 2026-06-17.

### QA checklist

- [ ] **Containment:** All three shims (`claude`, `codex`, `agy`) source the SAME `relay-turn-lib.sh` — never reimplement.
- [ ] **Tool allowlist split:** builder (`claude-turn.sh`) = `"Bash,Read,Edit,Write"`; reviewers (`codex-turn.sh`, `agy-turn.sh`) = `"Bash,Read"`. Verified before Phase 3.
- [ ] **Both cost ceilings set:** `claude-turn.sh` passes both `--max-turns` AND `--max-budget-usd` — neither alone is sufficient. Values sized from M2 spike output.
- [ ] **Round-cap arithmetic:** `--round-cap = 2 × max_review_rounds + 1` (turns ≠ rounds; off-by-one kills phases early). Validated before M3.
- [ ] **RELAY_PEER threading:** Every turn passes the peer explicitly — unnamed peer caused a live Gemini "release to literal role-string" failure on 2026-06-15.

---

## Phase 3 — Single-Phase Headless Loop (The Proof)

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

## Phase 3.6 — Autonomous-builder hardening (dogfood findings)

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
This **unblocks the Part A Phase 6 WPCC dogfood** ([MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md](../2-WORKING/MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md)).
(An external consumer already rated this containment core *"production-quality"* in a real cross-repo
run — see [FEEDBACK-KWFS-02.md](../1-INBOX/FEEDBACK/FEEDBACK-KWFS-02.md).)

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

## Phase 4 — Multi-Phase Chaining & State (Full Marathon)

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

## Deferred — M6 & M7

Consciously not built (per the MARATHON.md spec: "start without these; add only once a phase genuinely
needs it"). Tracked in the repo-wide backlog (`BACKLOG.md`, `4X4.md`); not lost.

- **M7 — State projection (`MARATHON-STATE.md`):** boundary events already land in `.tick/events/`
  (phase.start/approved/escalated + marathon.complete), so the data exists; only the projection view is
  deferred. *Unblocks when:* an operator needs a single-file run dashboard across phases.
- **M6 — Cross-phase context injection:** prepend an approved prior-phase artifact into the next
  builder prompt. *Unblocks when:* a real chained phase visibly needs a Phase-1 decision in Phase 2
  (the WPCC dogfood Phase 4 is the candidate trigger).
