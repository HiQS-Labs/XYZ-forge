---
title: Phase 4(a) — tick-native relay turns — concrete scope + effort estimate (for adversarial review)
status: Draft — estimate under relay review
created: 2026-06-15
decided_in: decisions/2026-06-15-relay-turns-tick-native.md
---

# Phase 4(a): convert relay turns to a tick-native `RELAY-TURN` task

**Goal of THIS doc:** let a reviewer judge whether (a) is *truly* ~2–3 passes or
secretly a 4–5 hour job. Every claim below is checkable against the current code:
`relay-automation/{poll.sh,relay-drive.sh,watchdog.sh}`, `test/{poll-driver.sh,poll-relay.sh,_setup.sh}`.

## Model
- **tick owns whose-turn + liveness:** a `RELAY-TURN` task; current actor = its `claimer`/`handoff_to`. Hand off with `tick release RELAY-TURN --to <other-agent>`; final turn does `tick done RELAY-TURN`.
- **markdown owns content + verdict:** the relay thread still holds the turn blocks and `STATUS:` (Approved closes). Termination signal stays the file's `STATUS`; *whose-turn* moves to tick.

## Concrete changes
1. **poll.sh relay mode** — replace the `NEXT == my-role` check (`poll.sh:140-157`) with `tick info RELAY-TURN` claimability — **which already exists in xyz mode** (`open + handoff-to=me` / `claimed + claimer=me`). Net: relay+xyz guards converge (likely *less* code). Keep reading the file's `STATUS` for the stop decision. Clean-tree scope unchanged.
2. **relay-drive.sh** (`relay-drive.sh:~60-110`) — loop selects the actor from `RELAY-TURN` state (not file `NEXT`); the no-progress guard checks that the token moved (claimer/handoff changed) rather than `NEXT`.
3. **Turn-taker contract** — must now `tick ping RELAY-TURN` during the turn (so the watchdog can see liveness) and `tick release RELAY-TURN --to <other>` (or `done` on approve) instead of `sed`-flipping `NEXT`.
4. **Relay setup** — seed a `RELAY-TURN` task at relay creation, handed to the first actor. (Role↔agent mapping lives in Setup; the token's `handoff_to` is the agent.)
5. **Role↔agent plumbing** *(added — Codex Blocker)* — once whose-turn moves from file `NEXT` to the token's `handoff_to`/`claimer`, the manual-nudge + cross-model path must rederive from the **token's agent**, not `--my-role`/`--roles`/`--claude-agents` (`poll.sh:41-46,117-130,140-157,180-206`), and the supervisor→taker env contract changes from `RELAY_ROLE` to an **agent id** (`relay-drive.sh:20-22,78-88`). Not trivial wiring.
6. **Tests — a FULL SLICE, not an add-on** *(re-priced — Codex Blocker)*. Today they are baton-file fakes: `poll-driver.sh` only seeds `NEXT`/`STATUS` + analysis fixtures; `poll-relay.sh` mutates the file with `sed` and the fake taker **never** claims/pings/releases/completes a task. Converting both to drive real `RELAY-TURN` tick state is its own slice of work:
   - `poll-driver.sh` relay cases → seed a real `RELAY-TURN` (`handoff_to`/`claimer`/`status`) and assert decisions from tick state.
   - `poll-relay.sh` fake taker → real `tick claim/ping/release/done`.
   - **NEW `test/watchdog-relay.sh`** — stalled `RELAY-TURN` (claim + stale heartbeat) → parked suspect → escalated. **The payoff test** ((a)'s reason for being).
   - **NEW multi-turn integration** — one `RELAY-TURN` re-handed across many turns stays exclusive + correctly re-targeted (the long-alternation proof Phase-1 tests never covered).
7. **Proposal + docs** — re-check items 191 + 201 `[x]`; update README + PHASE-4-PLAN to the tick-native model. `validate.sh` 17 → ~19 (two new tests).

## Effort estimate — REVISED after Codex scope-check (2026-06-15)
**Original claim ~2.5 passes was rosy.** Codex's independent number, accepted:
- **Pass 1 — plan/scope** (this doc + apply): ~½ pass.
- **Pass 2 — build (poll.sh + relay-drive.sh) + role↔agent plumbing**: ~1 pass.
- **Pass 3 — test-harness conversion (its own slice) + 2 new tests**: ~1–1.5 passes (the real time sink — fakes move off `sed`/`NEXT` onto real tick ops).
- **Pass 4 — Codex code review + dispose, re-check boxes, validate**: ~1 pass.
- **Revised: ~3.5 passes / ~4–5 hours.** Conversion work, no new core (the `tick` primitive + handoff-exclusive rule are verified sufficient), but the relay poll/supervisor/**test** contract all move off `NEXT`/`sed` together — that's the cost. Biggest risk = exactly that rewrite, not the `tick release --to` primitive.

## Where I think it could blow up to 4–5h (reviewer: confirm / add / refute)
1. **Token/verdict split** — termination reads the file's `STATUS` while the token is tick; getting handoff-vs-terminate clean (release on continue, done on approve) without the two fighting.
2. ~~**`release`/`done` semantics on `RELAY-TURN`**~~ **RESOLVED (Codex):** `release`/`done`/`ping` are ownership-guarded append-only events and projection already re-opens/re-targets a repeatedly handed-off task correctly (`src/scope.js:34-37,46-61`, `src/project.js:45-54,90-100`). Not a runtime risk — just needs the **multi-turn integration test** (now scope item 6).
3. **Test-harness tick ops (THE time sink, confirmed)** — both fake turn-takers + poll-driver fixtures move off `sed`/`NEXT` onto real `tick claim/ping/release/done`. Codex priced this as a full slice, not an add-on.
4. **Watchdog-relay test** — new territory; threshold/heartbeat timing in a test.

## Review ask
Is this scope **complete** (what's missing?), and is **~2.5 passes realistic** against the actual code — or does one of the risks (or something I missed) make this a 4–5h job? Grade the estimate, don't just approve it.
