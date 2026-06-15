# Trinity spike — recap

**Status:** Days 1-4 mechanical work compressed into a single Claude Code session on 2026-05-04. All 7 mechanical acceptance criteria pass. Day 5 real-agent hand-test deferred to a separate session.

## What worked

- **Disjoint-files-per-event** as the merge-conflict strategy. Two agents pushing claim events for different tasks in the same second produce zero conflicts because each writes a uniquely-named file.
- **Deterministic tie-breaker (earliest ts, then lex agent ID)** in projection. The `concurrent-claim.sh` test simulates the worst case — agent A pushes first but with a *later* timestamp than agent B's earlier-but-arrived-second claim — and projection consistently picks B as the winner across runs.
- **Auto-push contract on critical events** is a clean abstraction. The `auto-sync.sh` test verifies each of `claim/scope/release/break/done` produces exactly one remote commit, and `task.commented` produces zero.
- **Path-overlap routing via literal-prefix overlap** (no `micromatch` dependency) was sufficient for every test scenario — over-reports overlap (safer) but never misses one. If real-agent runs don't show starvation, leave it as-is.
- **Single-pass projection that resolves the winning claim first, then replays scope/handoff/terminal events** ([src/project.js](src/project.js)). The first cut had a sequencing bug — `scope_changed` ran before claims were resolved, so scope expansions were dropped on the floor. Fixed in the same session by computing the winner up front, then walking the timeline.

## What didn't work the first time

- **Initial projection sequencing.** Two-pass (events first, claims second) silently dropped `scope_changed` events because the claim wasn't yet bound when `scope_changed` was processed. Fix: bucket events per task, resolve the winning claim, then walk the bucket. Caught immediately by `scope-change.sh`.

## What we learned

- The **projection-after-push race** flagged in P1-TRINITY.md is real and observable. When agent A pushes a claim with ts=T1, then agent B pushes a claim with earlier ts=T0, A's `tick claim` returned `won=true` because A only saw its own event when it re-projected. A only learns it lost on the *next* `tick claim` or `tick project` after B's event arrives. The protocol is honest about this — the test exercises it explicitly — but it means agents must re-check before doing irreversible work, or a second `tick claim --confirm` verb (Phase 2) needs to gate the actual edits. **Concrete observation: a one-shot `tick claim` is not a reliable mutex; it is a best-effort soft claim that resolves correctly given enough time and re-projections.**
- **Worktree friction is worse than expected.** `git worktree add` refuses to check out the same branch twice. The README documents the workaround (per-agent child branches that push to the coordination ref), but this is enough friction that it could kill adoption. Phase 2 should consider either a separate ref for `.tick/` or an out-of-band sync daemon so agents can stay on their own branches.
- **The CLI is small (~600 lines of JS) but the tests are larger (~400 lines of bash) and were the slow part of the session.** Test-first would have caught the projection sequencing bug a step earlier. Worth the time investment — the protocol's correctness lives in the projection logic, and projections are easy to get wrong silently.

## What's next

Three live decisions, in order:

1. **Run the Day 5 real-agent hand-test** (the load-bearing deliverable). Fill in [REAL-AGENT-OBSERVATIONS.md](REAL-AGENT-OBSERVATIONS.md). Without this, the spike is incomplete — mechanical correctness ≠ adoption.
2. **If real-agent compliance is high → Phase 2.** Decide enforcement strategy (pre-commit hook? file watcher?) and pick which Phase 2 integration earns its keep first (WPCC adapter, Git Pulse, ask-self ingest, MCP wrapping).
3. **If real-agent compliance is low → revise.** The likely culprit is prompt friction or missing enforcement. Iterate on the integration snippet in README.md before declaring the protocol broken.

## Open questions surfaced (not solved)

All forwarded from P1-TRINITY.md plus:

- Is one-shot `tick claim` enough, or do we need `tick claim --confirm` as a second-phase mutex after re-projection settles?
- The path-overlap conservatism may starve agents whose tasks overlap in the literal prefix but not in actual files. Worth measuring in real-agent runs.
- Worktree friction — how badly does the per-child-branch workaround degrade the experience?

## Validate

```bash
cd experiments/coordination-layer
./validate.sh
# expected: passed: 7 / 7
```

---

## Run 2 — 2026-05-14–15

### What happened

Run 2 used a 6-task Todo REST API split into two halves (HTTP layer / store layer), with Gemini and Codex as peer agents on a shared local repo using the new local-transport model (no git push per event). All 6 tasks were completed with zero circuit breaks and zero file collisions. The claim cap held throughout — no agent exceeded 2 active claims.

The run spanned two calendar days due to session interruptions, which made the primary metric (concurrent-claim-time) uninterpretable: the 21h wall-clock window dominated by idle time produced 0% overlap even though agents were genuinely doing work when active.

### Compliance

- **Gemini:** 4 claimed / 4 done — both halves, clean protocol compliance
- **Codex:** 2 claimed / 2 done — store half, clean protocol compliance after initial git identity resolution

### Agent feedback (post-run)

Both agents independently surfaced the same two issues:

1. **`tick next` → `tick claim` race** — Codex lost TASK-B3, Gemini lost TASK-B1 momentarily to this gap.
2. **Git identity interference** — `git config user.name` flipped between agents in the shared repo, making `tick`'s identity warning noisy and unreliable.

Codex additionally flagged: lock in `.git/` (sandbox-blocked), `tick next` dirtying the working tree, ownership not enforced on `done/release/break`.

Gemini additionally flagged: no way to query task paths without copying from the prompt.

### Post-run improvements shipped

All 6 items from the agent feedback were implemented before closing the session:

- Lock moved to `.tick/locks/` (unblocks sandboxed environments)
- Ownership enforcement on `done/release/break/scope`
- `tick take` — atomic next+claim under one lock
- Git identity cross-check removed; `--agent` is authoritative
- `tick next` made read-only (no STATE.md write)
- `tick info <TASK-ID>` added

`validate.sh`: **10/10** green.

### Recommendation

**Iterate — Run 3 with same-session agents.** The protocol is sound; the measurement gap is operational. All known friction points are resolved. Run 3 success criterion: ≥50% concurrent-claim-time in a single session using `tick take`.

## Run 3 — 2026-06-14

### What happened

Run 3 re-ran the same 6-task split (HTTP / store) in a single session with the redefined success criterion (work-bounded window + parked-claim and serial-double-claim disqualifiers + heartbeats). All 6 tasks completed, **26/26 sandbox-app acceptance tests pass**, 0 collisions, 0 circuit breaks, 0 parked-claim suspects. The agent-facing changes worked: `tick take` (atomic claim, no observed race) and `tick ping` (heartbeats honored throughout).

The headline: the run was **mechanically flawless but missed the metric**. Work-bounded concurrent-claim time was **40%, below the ≥50% bar**.

### Compliance

- **Gemini:** 3 claimed / 3 done (HTTP half) / 3 heartbeats — clean
- **Codex:** 3 claimed / 3 done (store half) / 6 heartbeats — clean

### Why the metric missed

Gemini finished its HTTP half fast and went idle for the final ~1m 33s while Codex finished the store half alone. Genuine overlap happened early (~1m 27s of a 3m 37s work-bounded window), but a static per-half split gives the faster agent nothing to do once its lane is drained — no work-stealing across halves. So sustained overlap capped at 40%.

### Recommendation

**Iterate — Run 4 targets load balance, not mechanics.** The coordination layer is proven (atomic claims, lane separation, heartbeats, clean completion); the gap is that static partitioning lets the faster agent idle. Run 4 options: work-stealing across halves, finer/interleaved task split, or a balance-matched fixture — then retest the ≥50% bar. Not "graduate" (bar not cleared) and not "abandon" (flawless run, near-miss). `validate.sh`: **12/12** green (`tick take` + `tick ping` now tested).

## Run 4 — 2026-06-14 (meta-exercise: balanced fixture)

### What happened

Run 4 took Run 3's prescribed fix — a **balance-matched fixture** — and ran it as a meta-exercise: two agents (Codex + Gemini) built the relay-automation Phase-1 slice in two comparable-effort halves (Enforcement: `tick` handoff-exclusive rule + test ∥ Automation: `runner.sh` + `watchdog.sh` skeletons), and that build *was* Run 4. A launch-sync guard forced the balanced split. All 4 tasks completed in a ~3-min work-bounded window. **Metric cleared: 72.2% concurrent-claim time (≥50%).**

### Compliance

- **Gemini:** 2 claimed / 2 done (Enforcement half) / 2 heartbeats — clean
- **Codex:** 2 claimed / 2 done (Automation half) / 3 heartbeats — clean

### Result

- **Project 1 (concurrency):** work-bounded **72.2%** (132s / 182.9s) ≥ 50% — beats Run-3's 40%. Both agents ≥2 done, 0 parked, 0 collisions, no serial double-claim.
- **Project 2 (relay automation):** `validate.sh` **13/13** incl. new `handoff-exclusive.sh`; the rule provably rejects a wrong-`handoff_to` claim with zero events; both skeletons exist and pass `bash -n`.
- **Note:** `tick analyze` reports 40% because its window starts at task *creation* (includes the seed→start gap); the work-bounded number is 72.2%.

### Recommendation

**Graduate to Phase 2.** The balanced fixture cleared the load-balance bar Run 3 missed, on a flawless run (real passing deliverables on both halves). Coordination is now proven on both axes — mechanics (Runs 2–3) and sustained parallelism (Run 4). Caveats are sample size, not structure: one short single-trial run, so treat 72% as a first datapoint. Final graduate/iterate call is the operator's, out of session.

> **Decided: graduate to Phase 2.** Recorded in [decisions/2026-06-14-graduate-relay-automation-phase-2.md](decisions/2026-06-14-graduate-relay-automation-phase-2.md) — revisit if a real balanced run drops below the 50% bar.

## Run 5 — 2026-06-14 (Phase-2 build: watchdog ‖ runner)

### What happened
Two Codex variants built proposal Phase 2 (watchdog liveness/escalation, `copilot-codex`) ‖ Phase 3 (runner verdict-loop, `codex`) as a balanced 2-lane swarm. All 4 tasks done; `validate.sh` **15/15** (added `watchdog-liveness.sh` + `runner-loop.sh`, 6/6 each). Real deliverables: watchdog emits structured JSON escalation records; runner drives a verdict-gated turn loop with an injectable `--agent-cmd` (real headless wiring deferred). 0 collisions, 0 drift, 0 parked.

### Result
- **Concurrency: 39.2%** (88s / 225s work-bounded) — **below the 50% bar.** Cause = **start-skew** (`copilot-codex` claimed 116s after `codex`; one agent ran solo for the first half), **not** load imbalance (both did 2 tasks cleanly). Run 4 at 2s skew hit 72% on the same design.
- **Deliverables: pass** — real, tested, clean.

### Recommendation
**Iterate on launch discipline, not lane design.** Sub-50% is a valid datapoint, not an in-session retry trigger. The Phase-2 build stands; the ≥50% claim is **pending a start-synchronized re-run**. This fired the graduate decision's revisit trigger → status **Revisited** (start-skew refinement; bet not structurally broken). See the decision record's Updates.

## 2026-06-15 — relay-automation Phase 4 complete (hands-free poll)

Execution contract decided **Option B (baton + poll)** after a headless-CLI spike found no agent CLI present (Option A documented as a future upgrade). Phase-4 plan was Codex relay-reviewed (2 Blockers + 1 Should applied), then built solo across 4a/4b/4c:
- **4a** `poll.sh` — per-tick poll driver (two modes, split runner/watchdog guard, artifact-scoped clean check, cross-model nudge). `poll-driver.sh` 12/12.
- **4b** `relay-drive.sh` — relay-turn supervisor (loops to Approved, round-cap + no-progress escalation). `poll-relay.sh` 8/8.
- **4c** `relay-automation/README.md` — `/loop` invocations + designated-watchdog poller + cross-model one-line nudge + all-Claude boundary.

`validate.sh` **17/17**. **Proposal Phases 1–4 shipped; Phase 5 (package as sibling skill) remains.** Full per-change log now in `CHANGELOG.md`.

## 2026-06-15 — relay-automation COMPLETE (Phases 1–5) + cross-model/Option-A

Phase 4 finished (tick-native relay turns (a), self-expiring loops), Phase 5 packaged the whole thing as a sibling skill (`skill/relay-automation/`), and a cross-model **Claude↔Codex** relay with **Option-A headless Codex turns** (`codex exec` behind the `codex-turn.sh` path-allowlist shim) was built + live-proven. `validate.sh` **20/20** (12 test files). First hands-free dogfood: an all-Claude relay closed in 2 rounds with **0 turn-advancement nudges**.

### Honest limits (Run 1–3 caveat style)
- **Hands-free poll is all-Claude `/loop`-only.** Non-Claude agents take turns via manual nudge **or** the `codex-turn.sh` headless shim (Codex). No generic "any agent self-wakes."
- **Not a durable scheduler.** Loops are per-session crons (give them `--deadline`); truly unattended/no-window runs need a real runner/service (Option-A direction), not the agent session.
- **Verdict = LLM judgment**, not tooling — the relay advances the token + parses the verdict; it does not judge correctness.
- **≤ 2 roles** (Producer/Reviewer); no N-way relays.
- **Concurrency is start-skew-sensitive** (Run 4 72% vs Run 5 39%, same design) — a metric about launch discipline, not the protocol.
- **Open polish (not blocking):** Phase-4 race hammer-test, real auto-reap (needs an authority decision), a tighter Codex sandbox for unattended turns, a true zero-setup fresh-clone E2E. The Phase-5 skill packaging deliberately uses a **tarball sidecar**, not the xyz heredoc pattern (markdown linters corrupt embedded base64).

### Post-completion hardening — 3-model review of `codex-turn.sh` (2026-06-15)
A manual `/relay` with **Gemini** as a *third* Reviewer over the safety shim (`relay-system/2026-06-15/codex-turn-review-gemini.md`) found **two real bypasses** that neither I nor Codex's earlier headless review caught, then Approved the fixes (r3):
- **git-commit bypass** — Codex committing mid-turn hid edits from `git status`; fixed with a `before_head`/`reset --hard`/exit-6 guard.
- **quoted-path bypass** — porcelain quotes spaced paths so the revert no-op'd; fixed with `git status --porcelain -z` raw-path parsing (+ `R`/`C` rename handling).
- `test/codex-turn.sh` **10 → 16**, `validate.sh` still **20/20**. The shim's containment is now **3-model validated** (Claude authored → Codex added allowlist/no-push → Gemini cleared 2 bypasses). Also proves the **portable `/relay` generalizes to a third model** via embedded instructions + manual nudge. Plus `relay-automation/QUICKSTART.md` for a fresh-device test.

**Recommendation: project complete; ship-as-is.** Remaining items are polish/hardening, tracked in `4X4.md` and the proposal's open boxes.
