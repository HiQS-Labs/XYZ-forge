# Real-agent hand-test observations

> **Tip:** run `./bin/tick analyze --write REAL-AGENT-OBSERVATIONS.md` after a session to auto-fill the per-agent compliance numbers. Write the subjective sections and synthesis by hand.

---

## Run 1 — 2026-05-06

### Run metadata

- **Date:** 2026-05-06
- **Duration:** ~3 minutes (Gemini crashed almost immediately)
- **Fixture codebase:** coordination-layer test harness (3 tasks: TASK-A, TASK-B, TASK-C)
- **Seeded tasks:** 3
- **Worktree topology:** shared repo, one branch

### Outcome: FAILED — no parallelism, no code output

Gemini claimed all 3 tasks in 33 seconds, starving Codex. Codex behaved correctly — lost 2 tie-breakers, auto-released both times, then stood down on `(no available task)`. Gemini then crashed with zero work commits, leaving all 3 tasks stuck in `claimed` with no recovery path.

**Root causes:**
1. No per-agent claim cap — fast claimer monopolized the backlog.
2. No liveness lever — crashed claimer left tasks unrecoverable.
3. Git transport made claim events too slow to arrive for Codex before Gemini swept all 3.

### Auto-analyzed (tick analyze)

- **Run window:** `2026-05-06T16:17:18.481Z` → `2026-05-06T16:20:27.912Z`
- **Total events:** 10 (created: 3, claimed: 5, released: 2)

#### codex — 0 won / 2 lost / 0 done
- Claimed before editing: yes
- Used `tick done`: no (never got a task)
- 2 releases (both auto-release after tie-breaker loss)

#### gemini — 3 won / 0 lost / 0 done
- Claimed before editing: **no — 3 unclaimed work commits**
- Used `tick done`: no (crashed)
- Unclaimed commits: edits to BACKLOG.md, CLAUDE.md, CODEX.md, GEMINI.md, README.md

### Cross-cutting
- File collisions: none
- Wasted work: none (Gemini never produced output)

---

## Run 2 — 2026-05-14–15

### Run metadata

- **Date:** 2026-05-14 (started) → 2026-05-15 (Gemini finished TASK-A1)
- **Duration:** ~21h elapsed wall time, but most of that was session interruptions; actual agent-active time was ~1h
- **Fixture codebase:** Todo REST API skeleton (`sandbox-app/`) — stdlib-only Node.js, 6 tasks
- **Seeded tasks:** 6 (TASK-A1–A3 HTTP layer, TASK-B1–B3 store layer)
- **Worktree topology:** shared local repo, local-transport `.tick/events/` (no git push per event)

### Outcome: ALL TASKS COMPLETE — parallelism partially achieved

All 6 tasks done, 0 circuit breaks. The cap held — no agent exceeded 2 active claims. No file collisions. The two halves were successfully kept separate by path-routing.

**Concurrent-claim-time: 2m 9s / 21h run window (0%)** — this number is misleading. The 21h elapsed window is dominated by session interruptions; the agents were not both active for most of it. A same-session run would show genuine parallel overlap.

### Auto-analyzed (tick analyze)

- **Run window:** `2026-05-14T20:13:47Z` → `2026-05-15T17:21:31Z`
- **Total events:** 18 (created: 6, claimed: 6, released: 0, done: 6)

#### codex — 2 claimed / 2 done

- Claimed before editing: yes (after resolving git identity issues)
- Used `tick done`: yes — both tasks
- Used `tick scope` / `tick break`: no
- Compliance: clean

#### gemini — 4 claimed / 4 done

- Claimed before editing: yes
- Used `tick done`: yes — all 4 tasks
- Did both halves (claimed A tasks after B tasks were done)
- Compliance: clean

### Cross-cutting

- File collisions: none
- Wasted work on broken tasks: none
- Cap held: no agent held > 2 claims at any point

### Subjective observations

**Friction — both agents:**
- The `tick next` → `tick claim` two-step has a real race window. Both agents hit it (Codex lost TASK-B3; Gemini lost TASK-B1 momentarily). Significant enough that both agents independently flagged it in post-run feedback.
- Git identity (`git config user.name`) flipped between agents in the shared repo, producing noisy and misleading `tick: warning` messages. Both agents flagged this independently.

**Friction — Codex specifically:**
- Writing `.git/tick-claim.lock` was blocked in Codex's sandbox environment. Forced an escalation just to claim work. Directly blocked progress.
- `tick next` rewrote `STATE.md` on every invocation, making `git status` dirty on read-only operations.

**Friction — Gemini specifically:**
- Path globs copied verbatim from the prompt — Gemini flagged that `tick info <TASK-ID>` would remove the need to copy-paste scope strings.

### Post-run improvements shipped (2026-05-15)

All implemented and committed before documentation:

| Item | Change |
|---|---|
| P0: Lock location | `.git/tick-claim.lock` → `.tick/locks/claim.lock` |
| P0: Ownership enforcement | `done/release/break/scope` now reject calls from non-owning agents |
| P1: Atomic claim | New `tick take --agent <id>` — next+claim under one lock |
| P1: Identity check | Removed `checkAgentIdentity()` — `--agent` is authoritative |
| P2: Read-only `next` | `tick next` no longer writes STATE.md |
| P2: Task query | New `tick info <TASK-ID>` — prints status/priority/paths/claimer |

### Recommendation

**Iterate — run again (Run 3) with same-session agents.**

The protocol worked: both agents engaged, all tasks completed, no collisions, cap held. The primary failure was operational (session fragmentation over 21h), not protocol-level. The concurrent-claim-time metric (the load-bearing success criterion) is not answerable from Run 2's data because the 21h window dominated by idle time makes 0% meaningless.

Run 3 should: (a) use the same-session start prompt (`START-HERE.md`), (b) use `tick take` instead of `tick next` + `tick claim`, (c) complete within a single session so the concurrent-claim-time metric is meaningful. All known friction points are fixed. If Run 3 shows ≥50% concurrent-claim time with both agents active, graduate to Phase 2.

---

## Run 3 — 2026-06-14

### Run metadata

- **Date:** 2026-06-14 (single session)
- **Duration:** work-bounded window **3m 37s** (first `task.claimed` → last `task.done`). Note: ~8h elapsed between coordinator seeding and agent start — excluded from the metric by the redefined work-bounded window.
- **Fixture codebase:** same Todo REST API skeleton (`sandbox-app/`), cleared to scaffolding and re-seeded
- **Seeded tasks:** 6 (TASK-A1–A3 HTTP, TASK-B1–B3 store)
- **Worktree topology:** shared local repo, shared `.tick/events/`, single session, branch `development`
- **Protocol:** `tick take` (atomic claim) + `tick ping` (liveness heartbeat); parked-claim detection via `tick analyze`

### Outcome: ALL TASKS COMPLETE, mechanically clean — but metric MISSED (40% < 50%)

All 6 tasks done; **26/26 sandbox-app acceptance tests pass** (real, working, integrated code on both halves). 0 circuit breaks, 0 file collisions, 0 parked-claim suspects, cap held throughout. The agent-facing fixes all worked: no claim-race reported (`tick take`), heartbeats honored (`tick ping`), lane separation clean.

**Redefined success criterion — FAIL:**

| Check | Result | Bar | Pass? |
|---|---|---|---|
| Work-bounded concurrent-claim time | **40%** (1m 27s / 3m 37s) | ≥ 50% | ❌ |
| Both agents ≥ 2 done | gemini 3, codex 3 | ≥ 2 each | ✅ |
| Disqualifier — parked claims | 0 suspects | none | ✅ |
| Disqualifier — serial double-claim | none | none | ✅ |
| Cross-check — overlap = real edits | 26/26 tests pass, both halves real | — | ✅ |

**Why the metric missed:** Gemini completed all 3 HTTP tasks quickly, then sat **idle for the final ~1m 33s** while Codex finished B2 and B3 alone. Genuine simultaneous overlap occurred early (~1m 27s with both holding claims), but static per-half partitioning gives the faster agent nothing to do once its lane is clear — there is no work-stealing across halves. Sustained overlap therefore capped at 40%.

### Auto-analyzed (tick analyze)

- **Run window (tool default, old metric):** `2026-06-14T07:25:58Z` → `2026-06-14T15:24:04Z` — shows 0%/7h56m, **misleading** (dominated by the ~8h seed→start gap). Use the work-bounded number above.
- **Total events:** 27 (created: 6, claimed: 6, released: 0, scope_changed: 0, heartbeat: 9, done: 6, circuit_break: 0)

#### codex — 3 claimed / 3 done / 6 heartbeats
- Store half (B1, B2, B3). Claimed before editing: yes. Used `tick done`: all 3. Heartbeats: 6 (contract honored). Compliance: clean.

#### gemini — 3 claimed / 3 done / 3 heartbeats
- HTTP half (A1, A2, A3). Claimed before editing: yes. Used `tick done`: all 3. Heartbeats: 3 (contract honored). Compliance: clean. Went idle after its half completed (~1m 33s before run end).

### Cross-cutting

- File collisions: none
- Parked-claim suspects: none (heartbeats present throughout each claim window)
- Wasted work on broken tasks: none
- Cap held: no agent held > 2 claims at any point
- Claim mechanics: `tick take` produced no observed race; lane separation kept agents on their own halves

### Subjective observations

> _To be filled from agent post-run feedback (ask Codex and Gemini directly) and Noel's own observation. Objective sections above are coordinator-verified._

### Recommendation

**Iterate — Run 4.**

The coordination protocol is mechanically proven: atomic claims, clean lane separation, zero collisions, honored heartbeats, all tasks completed with passing tests. The failure is **not** a coordination failure — it is **load imbalance**: a static per-half split lets the faster agent idle once its lane is clear, capping sustained overlap below the 50% bar (40% achieved).

Run 4 should target balance rather than mechanics:
- **Work-stealing across halves** (let an idle agent claim from the other half once its own is drained), or
- **Finer-grained / interleaved task split** so neither agent runs dry early, or
- **A balanced fixture** where the two halves take comparable effort.

Then retest the ≥50% bar. Do **not** graduate to Phase 2 until sustained parallelism clears the bar — but note the result is a near-miss on a flawless run, not a structural dead end (so not "abandon").

---

## Run 4 — 2026-06-14 (meta-exercise: balanced fixture)

### Run metadata

- **Date:** 2026-06-14 (single session)
- **Duration:** work-bounded window **3m 02.9s** (first `task.claimed` 21:48:16.699Z → last `task.done` 21:51:19.580Z). ~2m 30s elapsed between coordinator seeding (21:45:46Z) and agent start — excluded from the metric.
- **Fixture codebase:** **this repo (`xyz-3-agents-swarm`) itself** — the meta-exercise. The 4 tasks build the relay-automation Phase-1 slice (Project 2), and the act of building it *is* Run 4 (Project 1).
- **Seeded tasks:** 4 — Enforcement half (TASK-A1 `tick` handoff-exclusive rule, TASK-A2 its test) ∥ Automation half (TASK-B1 `runner.sh` skeleton, TASK-B2 `watchdog.sh` skeleton). Deliberately balanced: a fiddly code change + test ≈ two real skeletons.
- **Worktree topology:** shared local repo, shared `.tick/events/`, single session, branch `main`
- **Protocol:** `tick take` + `tick ping`; balanced disjoint lanes; **launch-sync guard (#6)** to force the split

### Outcome: ALL TASKS COMPLETE, mechanically clean — metric PASSED (72% ≥ 50%)

All 4 tasks done; both acceptances met (see below). 0 circuit breaks, 0 file collisions, 0 parked suspects, cap held. The balanced fixture resolved Run-3's load-imbalance by construction: neither agent ran dry — gemini's A1→A2 and codex's B1→B2 stayed near-simultaneous for the whole window.

**Redefined success criterion — PASS:**

| Check | Result | Bar | Pass? |
|---|---|---|---|
| Work-bounded concurrent-claim time | **72.2%** (132s / 182.9s) | ≥ 50% | ✅ |
| Both agents ≥ 2 done | gemini 2, codex 2 | ≥ 2 each | ✅ |
| Disqualifier — parked claims | 0 suspects | none | ✅ |
| Disqualifier — serial double-claim | none (lanes never crossed) | none | ✅ |
| Cross-check — overlap = real edits | validate 13/13 + both skeletons `bash -n` clean | — | ✅ |

**Why the metric passed (vs Run-3's 40%):** the balanced fixture eliminated the idle tail. The launch-sync guard held by construction — A1 claimed 21:48:16.699Z, B1 claimed 21:48:18.949Z (**2.25s apart, before any `done`**), so the in-half overlap exclusion locked each agent into its lane for task 2. No work-stealing needed; the two halves were comparable enough in effort that neither agent drained early.

### Dual acceptance — both met

- **Project 2 (relay automation):**
  - A1+A2 → `validate.sh` **13/13** incl. the new `handoff-exclusive.sh` (was 12). The rule **provably rejects a wrong-`handoff_to` claim with zero events** — `test/handoff-exclusive.sh` asserts both the refusal and `INITIAL_EVENTS == FINAL_EVENTS`.
  - B1+B2 → `relay-automation/runner.sh` (4.1K) + `watchdog.sh` (2.6K) exist, both pass `bash -n`, documented stubs.
- **Project 1 (Run 4 concurrency):** work-bounded concurrent-claim = **72.2%** ≥ 50%. Beats Run-3's 40%.

### Auto-analyzed (tick analyze)

- **Run window (tool default, old metric):** `2026-06-14T21:45:46Z` → `2026-06-14T21:51:19Z` — shows **40%** / 5m 33s, **misleading** (denominator includes the ~2m 30s seed→start gap). The tool's *numerator* (concurrent time 2m 12s ≈ 132s) matches the hand calc; only its window differs. Use the work-bounded **72.2%** above.
- **Total events:** 17 (created: 4, claimed: 4, heartbeat: 5, done: 4, circuit_break: 0)

#### gemini — 2 claimed / 2 done / 2 heartbeats
- Enforcement half (A1, A2). Claimed before editing: yes. Used `tick done`: both. Heartbeats: 2 (contract honored). Compliance: clean.

#### codex — 2 claimed / 2 done / 3 heartbeats
- Automation half (B1, B2). Claimed before editing: yes. Used `tick done`: both. Heartbeats: 3 (contract honored). Compliance: clean.

### Cross-cutting

- File collisions: none (disjoint lanes — `src`/`test`/`validate.sh` vs `relay-automation/`)
- Parked-claim suspects: none
- Wasted work on broken tasks: none
- Cap held: no agent held > 2 claims at any point
- Claim mechanics: `tick take` produced no observed race; launch-sync forced the balanced split exactly as designed

### Caveats (honest)

- **Small absolute window (~3 min).** The 72.2% is valid and clears the bar, but the run was short — a longer/larger balanced fixture would be a stronger datapoint. The metric is sound; the sample is small.
- **Single trial.** One balanced run cleared the bar; this is the first ≥50% result, not a distribution.

### Subjective observations

_From the build agents' own feedback, gathered via relay `relay-system/2026-06-14/run4-feedback.md` (Codex `4414059`, Gemini `9d44555`)._

**Codex (Automation half — `runner.sh` + `watchdog.sh` skeletons):**
- *Prompt clarity:* mostly clear; the one guess was **how much initiative to take inside the lane** — the prompt named files + acceptance shape but not how opinionated the skeleton behavior should be beyond "parse clean" / Phase-1-sized.
- *Friction:* the file-scoped commit + lane scoping worked but added bookkeeping — caught itself re-checking "am I allowed to touch this" more than thinking about the code.
- *Protocol:* atomic claim + staying in-lane helped; the **launch-sync wait felt a bit ceremonial** once both agents were clearly active (front-loaded coordination overhead into a short run).
- *One fix:* add an explicit **initiative bound** to the build prompt, e.g. *"implement the thinnest passing skeleton; no behavior beyond tests/acceptance unless specified."*

**Gemini (Enforcement half — handoff-exclusive rule + `test/handoff-exclusive.sh`):**
- *Prompt clarity:* clear and precise; paths explicitly bounded, acceptance concrete. Slight ambiguity: inferring that `tick take` yields "(no available task)" when remaining tasks are handoff-reserved for someone else — resolved by reading the CLI code.
- *Friction:* low; `tick` verbs (`take`/`info`/`ping`/`done`) ergonomic. Minor testing friction: **`TICK_REPO_ROOT` was unbound** when adapting existing tests — had to realize local-transport tests use `$A`.
- *Protocol:* worked seamlessly; atomic claim removed race cognitive overhead; strict lane = confident isolated work; heartbeats easy to interleave.
- *One fix:* **standardize the test-harness env vars** (unify `TICK_REPO_ROOT` or document `$A` for test writing) so agents don't stumble on unbound vars when scaffolding new tests.

**Actionable follow-ups (out of session):**
1. **Build-prompt template** — add an "initiative bound" line (Codex). Cheap, removes a real guess point.
2. **Test harness** — document/standardize `TICK_REPO_ROOT` vs `$A` for new tests (Gemini).
3. **Launch-sync UX** — consider downgrading to a quick "both claimed?" confirmation rather than a wait once both agents are active (Codex). *Keep it for now* — it's what guaranteed the balanced split; treat as a polish item, not a protocol change.

Both reports independently confirm the coordination mechanics (atomic claim, lane isolation, heartbeats) were low-friction; the remaining friction was at the **edges** — prompt initiative scope and test-env ergonomics — not the protocol itself. This strengthens, not weakens, the graduate recommendation.

### Recommendation

**Graduate to Phase 2.**

Run 4 cleared the load-balance bar that Run 3 missed — **72.2% work-bounded concurrency** on a flawless run: both agents ≥2 done, zero collisions, zero parked claims, real passing deliverables (validate 13/13, both skeletons parse clean). It did so via the exact fix Run 3 prescribed (a balanced fixture), and the launch-sync guard forced the split by construction. The coordination protocol is now proven on *both* axes — mechanics (Runs 2–3) and sustained parallelism (Run 4). The honest caveats are sample size, not structure: one short single-trial run. Recommend graduating to Phase 2 while treating the 72% as a first datapoint to be confirmed by a longer balanced run if a stronger number is wanted. **Final graduate/iterate call is Noel's, out of session, per the brief.**

> **Decided: graduate to Phase 2** — see [decisions/2026-06-14-graduate-relay-automation-phase-2.md](decisions/2026-06-14-graduate-relay-automation-phase-2.md).

---

## Run 5 — 2026-06-14 (Phase-2 build: watchdog ‖ runner)

### Run metadata
- **Date:** 2026-06-14 (single session); work-bounded window **3m 45s** (first `claimed` 03:54:30.508Z → last `done` 03:58:15.560Z UTC). ~18m elapsed between seeding and first claim — excluded.
- **Builders:** `codex` (Runner lane, proposal Phase 3) ‖ `copilot-codex` (Watchdog lane, proposal Phase 2) — two Codex variants, distinct agent ids.
- **Lanes (claim-by-name, pre-assigned — no global `take`):** Runner = `relay-automation/runner.sh` + `test/runner-loop.sh`; Watchdog = `relay-automation/watchdog.sh` + `test/watchdog-liveness.sh`. Disjoint.

### Outcome: ALL TASKS COMPLETE, deliverables real & tested — metric MISSED (39% < 50%)
All 4 tasks done; `validate.sh` **15/15** (added `watchdog-liveness.sh` 6/6 + `runner-loop.sh` 6/6). 0 collisions, 0 parked, 0 drift, commits correctly tagged by distinct agent ids. Real work: watchdog now emits structured JSON escalation records (`--channel stdout|file`); runner drives a real verdict-gated turn loop with an injectable `--agent-cmd`.

| Check | Result | Bar | Pass? |
|---|---|---|---|
| Work-bounded concurrent-claim time | **39.2%** (88s / 225s) | ≥ 50% | ❌ |
| Both agents ≥ 2 done | codex 2, copilot-codex 2 | ≥ 2 each | ✅ |
| Parked / serial double-claim | 0 / none | none | ✅ |
| Deliverables real | 15/15 incl. 2 new tests | — | ✅ |

**Why the metric missed — start-skew, NOT load imbalance.** `codex` claimed TASK-R1 at 03:54:30 and finished it (solo) at 03:56:17; `copilot-codex` didn't claim TASK-W1 until 03:56:26 — a **116s late start**. So one agent ran solo for the first ~half of the window. The lanes themselves stayed perfectly balanced (2 tasks each, no drift). Contrast Run 4: **2s** start-skew → **72%**. Same balanced-lane design; the delta is almost entirely *simultaneity of start*.

### Key finding
The work-bounded concurrency metric is **dominated by how close together the two windows start**, not by the lane design. A balanced fixture is necessary but **not sufficient** for ≥50% — without a start-together discipline (or automated simultaneous launch), one agent drains its lane before the other begins. Run-4's 72% rode on a near-simultaneous start that this round didn't reproduce.

### Subjective observations
> _To be filled from `codex` / `copilot-codex` feedback if gathered._

### Recommendation
**Iterate on launch discipline, not lane design.** This is a sub-50% datapoint (valid, per the brief — not a retry trigger in-session). It does **not** indict the Phase-2 deliverables (real, tested, clean) or the lane model. It re-opens the graduate bet: balance alone doesn't guarantee ≥50% — **simultaneous start does.** See the decision-record update below. Next balanced run should enforce start-together (the manual launch-sync, or automated launch) before reading the metric.

---

## Phase-5 dogfood — first hands-free automated relay (2026-06-15)

First real end-to-end run of the relay-automation tooling (tick `RELAY-TURN` token + `poll.sh` under `/loop`), all-Claude, reviewing the Phase-5 plan. **Outcome: relay closed `Approved` with zero turn-advancement nudges** — the hands-free claim held.

### Metrics
- **Rounds to approve:** 2 (Producer r1 → Reviewer r1 *Request Changes* → Producer r2 *adopt E3* → Reviewer r2 *Approved*).
- **Turn-advancement human interventions: 0** — no "your turn" nudges; both windows self-fired (Claude-B via its `/loop`, Claude-A via cron `e2918ffd`). This is the real hands-free proof.
- **Other human interventions: 1** — a permission gate stalled Claude-B mid-run (now eliminated by the `.claude/settings.local.json` allowlist). Plus the one-time `/loop` launch.
- **Steady-state turn latency:** Claude-B's turns ~1.5 min and ~47 s; fast. Total wall-time ~40 min was dominated by operator-side detours (the poll bug + claim-ordering debug below), not the loop.
- **Auto-recovered stalls:** 0 — no window held `--watchdog-authority` this run, so nothing recovered (and nothing needed to).

### Findings (the value of the dogfood)
1. **[fixed] `poll.sh` crashed on empty `--claude-agents`** (`set -u` empty-array, bash 3.2) — only reachable in a real cross-model-branch poll; tests never hit it. Fixed + regression added.
2. **[fixed] permission gate** stalled the hands-free loop → added a relay-automation allowlist to `.claude/settings.local.json` (tick, the 4 scripts, git, test runners, relay-path edits).
3. **[Phase-2 follow-up] parked-detector flags *closed* windows** — it flagged Claude-A's 15-min r1 claim window (already released) as a "parked suspect." For the watchdog/self-healing use case, parked detection should consider only *currently-claimed* windows, else it would escalate already-completed turns.
4. **[process] claim-before-release ordering** — `release` requires the agent to `claim` the token first; editing the artifact then releasing without claiming hits the ownership guard. The embedded turn-instructions say claim-first; the operator's manual shortcut tripped it.
5. **[setup] designate one `--watchdog-authority` poller** for real runs, or a genuine stall won't auto-recover.

### Verdict
The transport works end-to-end hands-free (token/poll/handoff/close). This closes the **transport-E2E** sense of QA item 196 (shared-model caveat noted); cross-model coordination remains separate (now feasible — Codex CLI installed). The Phase-5 plan itself was **Approved** through this run.
