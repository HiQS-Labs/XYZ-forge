---
title: relay-automation — Phase 4 plan (hands-free poll, Option B: baton + poll)
status: Draft (for relay review)
created: 2026-06-14
builds-on: PHASE-2-PLAN.md (Phases 1–3 shipped) + decisions/2026-06-14-graduate-relay-automation-phase-2.md
execution-contract: Option B (baton + poll) — chosen by the 2026-06-14 headless-auth spike (no agent CLI present)
---

# relay-automation — Phase 4 plan: hands-free poll (Option B)

## Goal
Remove the **human nudge** from the loop for all-Claude work. A poll driver watches
coordination state and, when it's this window's turn and the tree is clean, takes the
turn automatically — driving either an **xyz build turn** (via `runner.sh`) or a
**/relay review turn** (via the baton), and invoking `watchdog.sh` when a turn parks.
This is proposal **Phase 4 (Hands-free poll integration)**, built on **Option B
(baton + poll)** since no headless agent CLI exists here (spike, 2026-06-14).

## What's already in place (don't rebuild)
- **Phase 1:** handoff-exclusive `tick` rule (turn exclusivity).
- **Phase 2:** `watchdog.sh` — JSON-driven parked detection + structured escalation.
- **Phase 3:** `runner.sh` — verdict-gated turn loop with injectable `--agent-cmd`.
- **Baton pattern:** `relay-system/baton-pattern.md` — one stable file the operator/poller reads; the relay doc also embeds a `▶ TAKE YOUR TURN` block.

## Core: the poll driver (`relay-automation/poll.sh`, `/loop`-able)
A thin entrypoint a Claude window runs under `/loop` (e.g. `/loop 60s ...`). Each tick:
1. **Read state** — `tick analyze --format json` (parked?) + the target relay/turn pointer (`NEXT`) + `git status --porcelain` (clean?).
2. **Guard (all must hold, else do nothing this tick):**
   - it is **this agent's** turn (`NEXT`/`handoff_to` names me, and I'm the bound agent), **and**
   - the working tree is **clean** for the artifact scope (the other window already committed).
3. **Act (one of):**
   - turn runnable → invoke `runner.sh` for the turn;
   - turn **parked** (watchdog threshold) → invoke `watchdog.sh` (escalate; reap stays gated);
   - nothing to do → sleep to next tick.
4. **Stop conditions:** relay `STATUS: Approved`/`Closed`, or N idle ticks → stand down and tell the human (never spin forever).

The guard *is* the lock (condition-driven, not a timer) — mirrors the relay skill's
hands-free poll rules. Order is always: do work → commit → flip `NEXT`, so a poller
never sees `NEXT` flip before the commit lands.

## Two surfaces the driver serves
- **(4a) xyz build turn** — poll claims the next in-lane task and runs `runner.sh`; the existing Phase-1/3 mechanics handle claim exclusivity + verdict. Removes the "your turn" nudge between build turns.
- **(4b) /relay review turn** — poll drives a Producer/Reviewer turn: read the relay thread, run the turn, parse the Reviewer `VERDICT:`, advance the thread (append block, flip `NEXT`, commit), loop until `Approved` or escalate. The `--agent-cmd` seam wires to the **baton** (the turn is taken by the live polling window), **not** a CLI.

## Boundary (load-bearing)
- **All-Claude only.** Hands-free poll relies on Claude Code's in-session `/loop`. **Non-Claude windows (Codex/Gemini) stay on the manual one-line nudge** — they can't self-wake. The driver must detect a cross-model turn and degrade to the manual nudge.
- **Not a durable scheduler, not unattended-without-a-window.** A Claude window must be open and looping. Truly unattended runs are a future Option-A upgrade (install + auth a CLI), explicitly out of Phase 4.
- The portable `/relay` skill stays dependency-free; this tick-driven poll lives in `relay-automation/`.

## Sub-phases & acceptance
- **4a — poll driver core (`poll.sh`).** Reads state, applies the guard, dispatches to runner/watchdog or idles. *Accept:* `test/poll-driver.sh` drives a seeded scenario in **dry-run mode** (logs the decision it *would* take each tick) and asserts the decision sequence (my-turn→run, not-my-turn→idle, dirty-tree→idle, parked→watchdog, approved→stop).
- **4b — relay-turn driving.** Wire the driver to advance a `/relay` thread via the baton. *Accept:* `test/poll-relay.sh` runs a 2-round Producer/Reviewer relay with a fake turn-taker emitting `Changes requested` then `Approved`; asserts the thread advanced + closed on `Approved`.
- **4c — `/loop` packaging + docs.** The exact `/loop` invocation + a README section; bake the baton one-liner into operator docs. *Accept:* documented; `bash -n` clean; `validate.sh` green (target 16–17 with the two new tests).

## Non-goals (guards)
- No real auto-reap (still gated on an authority decision record).
- No headless CLI / Option A wiring.
- No multi-relay supervision (later phase).
- Keep each new test self-running; coordinator wires into `validate.sh`.

## Open questions for the reviewer
1. Is `poll.sh` the right seam, or should the poll logic live **inside** `runner.sh`/`watchdog.sh` with a `--watch` flag (one fewer file)?
2. Dry-run-first acceptance (4a) — sufficient to prove the guard, or do we need a live end-to-end poll test despite the no-CLI constraint?
3. Cross-model degrade: should the driver **detect** a non-Claude turn and emit the nudge text, or just document "all-Claude only" and no-op on cross-model turns?
4. Is splitting 4a/4b/4c right, or should this be one lane (it's mostly one file, `poll.sh`) — i.e. not a 2-lane swarm but a solo build?
