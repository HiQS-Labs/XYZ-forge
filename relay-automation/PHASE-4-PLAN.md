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
A thin entrypoint a Claude window runs under `/loop` (e.g. `/loop 60s ...`). It has
**two modes — one dispatch shell, two "is-runnable?" adapters** (don't conflate the
state sources):
- **xyz mode** — runnable state is `tick`-native (an in-lane task claimable/resumable by me).
- **relay mode** — runnable state is the baton / relay-thread `NEXT`/`STATUS`.

Each tick:
1. **Read state** — `tick analyze --format json` (parked suspects?) + the mode's runnable check (xyz: `tick` task state; relay: baton `NEXT`/`STATUS`) + the **artifact-scoped** tree check (step 3).
2. **Two distinct guard→dispatch paths** — *a parked turn is held by the **other** window, so it cannot use the my-turn guard; that's why recovery is a separate path:*
   - **Runner path** → dispatch `runner.sh` only if **(my-turn) AND (artifact scope clean)**. My-turn = `NEXT`/`handoff_to` names me and I'm the bound agent.
   - **Watchdog path** → dispatch `watchdog.sh` only if **(a parked suspect exists) AND (I hold the designated watchdog authority)**. **Exactly one** designated poller (the coordinator window) runs the watchdog path — so a stalled *other* window's turn gets recovered, and no two windows escalate the same suspect (no double-escalate / double-reap).
   - else → idle to next tick.
3. **Artifact-scoped clean-tree check (matches Phase 3's contract — NOT repo-global):**
   - xyz turn → scope = the claimed task's paths from `tick info <task>`: `git status --porcelain -- <task-paths>`.
   - relay turn → scope = the artifact under review + the relay log: `git status --porcelain -- <artifact> <relay-log>`.
   - Repo-global `git status` is **wrong here** — unrelated dirt elsewhere in the shared checkout must not block a turn (the Phase-0 artifact-scoped decision).
4. **Stop conditions:** relay `STATUS: Approved`/`Closed`, or N idle ticks → stand down and tell the human (never spin forever).

The guard *is* the lock (condition-driven, not a timer) — mirrors the relay skill's
hands-free poll rules. Order is always: do work → commit → flip `NEXT`, so a poller
never sees `NEXT` flip before the commit lands.

## Two surfaces the driver serves
- **(4a) xyz build turn** — poll claims the next in-lane task and runs `runner.sh`; the existing Phase-1/3 mechanics handle claim exclusivity + verdict. Removes the "your turn" nudge between build turns.
- **(4b) /relay review turn** — poll drives a Producer/Reviewer turn: read the relay thread, run the turn, parse the Reviewer `VERDICT:`, advance the thread (append block, flip `NEXT`, commit), loop until `Approved` or escalate. The `--agent-cmd` seam wires to the **baton** (the turn is taken by the live polling window), **not** a CLI.

## Boundary (load-bearing)
- **All-Claude only.** Hands-free poll relies on Claude Code's in-session `/loop`. **Non-Claude windows (Codex/Gemini) stay on the manual one-line nudge** — they can't self-wake. When the driver detects a cross-model turn it must **emit the explicit nudge text** (e.g. `Codex/Gemini turn detected — manual nudge required: "take your turn on <file>"`), **never silently no-op** (silent idle is ambiguous; the explicit message preserves the boundary without pretending to automate it).
- **Not a durable scheduler, not unattended-without-a-window.** A Claude window must be open and looping. Truly unattended runs are a future Option-A upgrade (install + auth a CLI), explicitly out of Phase 4.
- The portable `/relay` skill stays dependency-free; this tick-driven poll lives in `relay-automation/`.

## Sub-phases & acceptance
- **4a — poll driver core (`poll.sh`). ✅ SHIPPED 2026-06-14** (solo build) — `relay-automation/poll.sh` (two modes, split guard, artifact-scoped clean check, cross-model nudge, dry-run + live dispatch) + `test/poll-driver.sh` (12/12, both dry-run sequence and fake live integration); `validate.sh` **16/16**. Reads state, applies the **two** guard→dispatch paths (runner vs watchdog-authority), dispatches or idles. Built as a **solo lane** (it's one file and the guard/dispatch is the risky part — splitting too early just adds coordination overhead). *Accept (two tests):* (i) `test/poll-driver.sh` drives a seeded scenario in **dry-run mode** and asserts the decision sequence (my-turn→run, not-my-turn→idle, dirty-tree→idle, parked+authority→watchdog, parked-without-authority→idle, approved→stop); (ii) one **fake live integration** proving the dispatched command actually runs under the guard, and that the parked path triggers **exactly one** watchdog action under the designated-authority rule (no double-escalate).
- **4b — relay-turn driving. ✅ SHIPPED 2026-06-15** — `relay-automation/relay-drive.sh` supervises a `/relay` thread to termination: the turn-taker (`--agent-cmd`; baton/live-window in Option B, fake in tests) takes each turn (appends block, flips `NEXT`, sets `STATUS`, commits); the supervisor loops on `NEXT`/`STATUS`, enforces a round cap, and **escalates on no-progress** (exit 3) or cap-without-Approved (exit 4). `test/poll-relay.sh` (8/8): 2-round Changes-requested→Approved closes (3 turns), no-progress + round-cap escalations, dry-run mutates nothing. `validate.sh` **17/17**.
- **4c — `/loop` packaging + docs. ✅ SHIPPED 2026-06-15** — `relay-automation/README.md`: components table, the exact `/loop` invocations (hands-free relay turn, designated single-watchdog poller, single-process `relay-drive.sh`), the cross-model one-line baton nudge, and the all-Claude boundary. All scripts `bash -n` clean; `validate.sh` 17/17. **Phase 4 complete.**

## Non-goals (guards)
- No real auto-reap (still gated on an authority decision record).
- No headless CLI / Option A wiring.
- No multi-relay supervision (later phase).
- Keep each new test self-running; coordinator wires into `validate.sh`.

## Resolved by relay review (Codex, 2026-06-14 — `relay-system/2026-06-14/phase4-plan-review.md`)
1. **`poll.sh` is the right seam** (not a `--watch` flag) — keeps orchestration separate from the single-turn executors and keeps the xyz/relay split honest. ✅ kept.
2. **Dry-run-first is necessary but not sufficient** — added a fake live integration to 4a acceptance (dispatched command runs under the guard; parked path → exactly one watchdog action). ✅ applied.
3. **Cross-model → detect + emit explicit nudge text**, never silent no-op. ✅ applied to the Boundary.
4. **Start as a solo lane** — `poll.sh` is the blast radius and the guard/dispatch is the risky part; revisit a split only after the core guard + mode boundary are nailed. ✅ 4a is a solo build.
- Plus 2 Blockers fixed: split guard (runner: my-turn+clean; watchdog: parked+designated-authority, single poller → no double-escalate) and artifact-scoped (not repo-global) clean-tree check named per mode.
