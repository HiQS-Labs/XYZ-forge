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
5. **Tests:**
   - `poll-driver.sh` relay cases — seed a `RELAY-TURN` in the test tick repo + set `handoff_to`/`claimer`/`status`; assert decisions from tick state. (parked+authority case already uses an analysis file; dirty-tree still uses git.) — *moderate rework*
   - `poll-relay.sh` fake turn-taker — do real `tick claim/ping/release/done` instead of `sed NEXT`. — *moderate rework*
   - **NEW `test/watchdog-relay.sh`** — a stalled `RELAY-TURN` (claim + stale heartbeat) is detected as a parked suspect and escalated. **This is the payoff test** ((a)'s reason for being). Builds on `watchdog-liveness.sh`. — *new*
6. **Proposal + docs** — re-check items 191 + 201 `[x]`; update README + PHASE-4-PLAN to the tick-native model. `validate.sh` 17 → ~18.

## Effort estimate (claim under review)
- **Pass 1 — plan/scope** (this doc + apply): ~½ pass.
- **Pass 2 — build + tests**: ~1–1.5 passes (conversion reuses xyz guard; the time leak is the test fakes doing tick ops + the new watchdog-relay test).
- **Pass 3 — Codex code review + dispose, re-check boxes, validate**: ~1 pass.
- **Total claim: ~2.5 passes / 2–3 working sessions.** Not greenfield — a conversion + test rework.

## Where I think it could blow up to 4–5h (reviewer: confirm / add / refute)
1. **Token/verdict split** — termination reads the file's `STATUS` while the token is tick; getting handoff-vs-terminate clean (release on continue, done on approve) without the two fighting.
2. **`release`/`done` semantics on `RELAY-TURN`** — does the existing `tick release --to` + handoff-exclusive rule behave correctly for a *repeatedly* re-handed single task across many turns? (Phase-1 tests covered a single handoff, not a long alternation.)
3. **Test-harness tick ops** — rewriting both fake turn-takers to claim/ping/release against the test repo is fiddlier than the current `sed`; this is the most likely time sink.
4. **Watchdog-relay test** — new territory; threshold/heartbeat timing in a test.

## Review ask
Is this scope **complete** (what's missing?), and is **~2.5 passes realistic** against the actual code — or does one of the risks (or something I missed) make this a 4–5h job? Grade the estimate, don't just approve it.
