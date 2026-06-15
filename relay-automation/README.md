# relay-automation

A tick-backed, self-healing automation layer for the manual `/relay` review loop
and `xyz` build swarms. Built in phases on top of `tick` (see
[PROPOSAL-AUTOMATION.md](../PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md)).

**Execution contract: Option B (baton + poll)** — the turn itself is taken by a
live Claude window (driven by `/loop`) or by a human one-line nudge for non-Claude
windows. There is **no headless agent CLI** in this environment (spike, 2026-06-14);
fully-unattended Option A is a documented future upgrade (see
[PHASE-2-PLAN.md](PHASE-2-PLAN.md) → "Future upgrade — Option A").

## Components
| Script | Role |
|---|---|
| `poll.sh` | **Phase 4** per-tick poll driver. Reads state, applies the guard, dispatches `runner.sh`/`watchdog.sh` or idles. Run under `/loop`. |
| `runner.sh` | **Phase 3** single agent/turn: claim → run (`--agent-cmd`) → verdict gate (`VERDICT: PASS\|FAIL\|PARKED`) → done/retry; artifact-scoped clean-tree gate. |
| `watchdog.sh` | **Phase 2** liveness: `tick analyze --format json` → parked `parked_suspects[]` → structured escalation record; reap gated behind `--allow-reap` (stub, pending an authority decision). |
| `relay-drive.sh` | **Phase 4b** relay supervisor: loops a `/relay` Producer↔Reviewer thread to termination via a turn-taker; round cap + no-progress escalation. |

## Operator usage (Option B)

### Hands-free relay turn (all-Claude only)
In each Claude window, run a guarded `/loop` that uses `poll.sh` as the gate, then
takes the turn from the relay file's embedded `▶ TAKE YOUR TURN` instructions:
```
# Producer window (agent id = the agent the RELAY-TURN token is handed to)
/loop 60s run relay-automation/poll.sh --mode relay --agent claude-a \
  --relay-file relay-system/<date>/<slug>.md --artifact <path-under-review> --dry-run ;\
  if it prints "DECISION: run-runner", take your turn on that relay file per its embedded \
  instructions (review/produce, append your block, `tick release RELAY-TURN --to <other>` or
  `done` on approve, commit, push); otherwise do nothing.
# Reviewer window: same, with that window's --agent id
```
**Whose-turn is the `RELAY-TURN` tick task** (handed off via `tick release --to`), so the
Phase-1 handoff-exclusive rule + the Phase-2 watchdog both apply. The guard *is* the lock:
a window acts only when the token is claimable by **its** agent **and** the artifact scope is
clean. `poll.sh` exits `10` on a closed relay (file `STATUS: Approved`) so the loop can stop.
*(Default `--relay-task RELAY-TURN`; seed it at relay setup, handed to the first actor.)*

**Poll interval — cache-warmth tradeoff.** `60s` keeps Claude Code's prompt cache warm
(≈5-min TTL); the **lock/heartbeat is the real correctness guard, not the timer**, so a longer
interval only adds latency, never a race. Use ~`60s` for active relays, longer (e.g. `120s`)
for the lower-frequency watchdog poller.

### Designated watchdog (exactly ONE window)
Only one poller holds watchdog authority, so a stalled turn is recovered without
double-escalation:
```
/loop 120s run relay-automation/poll.sh --mode relay --agent coordinator \
  --relay-file relay-system/<date>/<slug>.md --watchdog-authority ;\
  if it prints "DECISION: run-watchdog", it has escalated the parked turn — surface it to me.
```

### Single-process relay supervision (one window drives the whole thread)
```
relay-automation/relay-drive.sh --relay-file relay-system/<date>/<slug>.md \
  --agent-cmd "<turn-taker>" --round-cap 6
```
`--agent-cmd` is the turn-taker seam (a CLI in a future Option A; in Option B the
turn is taken by the live window / baton). Exits: `0` closed Approved/Closed,
`3` no-progress, `4` round cap without Approved.

### Cross-model windows (Codex / Gemini) — manual nudge
Non-Claude windows can't self-wake. The operator's whole job is **one line**:
```
take your turn on relay-system/<date>/<slug>.md
```
The relay file embeds the `▶ TAKE YOUR TURN` instructions, so any agent acts from
the file alone. `poll.sh` detects a cross-model turn and emits this nudge text
rather than silently idling.

## Boundary (load-bearing)
- **Hands-free poll is all-Claude only** — it relies on Claude Code's in-session `/loop`. Cross-model stays on the manual nudge.
- **Not a durable scheduler / not unattended-without-a-window.** A Claude window must be open and looping. Truly unattended runs need Option A (future).
- The portable `/relay` skill stays dependency-free; this tick-driven automation lives here.
