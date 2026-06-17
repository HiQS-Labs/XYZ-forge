# relay-automation

A tick-backed automation layer for the manual `/relay` review loop and `xyz`
build swarms. Built in phases on top of `tick` (see
[PROPOSAL-AUTOMATION.md](../PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md)).

**Execution contract: default live-window flow** — the default operator path is
still the poll-driven, live-window flow: a Claude window under `/loop`, or a
human one-line nudge when the turn belongs to a non-Claude window. Headless
turn-takers now exist for Codex and Gemini (`codex-turn.sh`, `gemini-turn.sh`),
but the cross-model poll loop still degrades to a manual nudge rather than
auto-firing those shims. For the current headless path, see
[QUICKSTART.md](QUICKSTART.md) and
[CROSSMODEL-OPTIONA-PLAN.md](CROSSMODEL-OPTIONA-PLAN.md).

## Components
| Script | Role |
|---|---|
| `poll.sh` | **Phase 4** per-tick poll driver. Reads state, applies the guard, dispatches `runner.sh`/`watchdog.sh` or idles. Run under `/loop`. |
| `runner.sh` | **Phase 3** single agent/turn: claim → run (`--agent-cmd`) → verdict gate (`VERDICT: PASS\|FAIL\|PARKED`) → done/retry; artifact-scoped clean-tree gate. |
| `watchdog.sh` | **Phase 2** liveness: `tick analyze --format json` → parked `parked_suspects[]` → structured escalation record; reap gated behind `--allow-reap` (stub, pending an authority decision). |
| `relay-drive.sh` | **Phase 4b** relay supervisor: loops a `/relay` Producer↔Reviewer thread to termination via a turn-taker; round cap + no-progress escalation. |
| `relay-turn-lib.sh` | **Shared safety core** (sourced, not run): the model-agnostic containment contract — path-allowlist + commit-bypass guard + no-push. Both headless turn-takers source this so the boundary lives in ONE place. See [decisions/2026-06-15-unattended-agent-containment.md](../decisions/2026-06-15-unattended-agent-containment.md). |
| `codex-turn.sh` | **Option-A** headless turn-taker for the **Codex** agent (`codex exec`); thin dispatch wrapper over `relay-turn-lib.sh`. |
| `gemini-turn.sh` | **Option-A** headless turn-taker for the **Gemini** agent (`gemini --yolo --skip-trust -p`, GCA auth); thin dispatch wrapper over the same `relay-turn-lib.sh`. First drafted standalone by Gemini, reconciled onto the shared core + corrected invocation; live-validated 2026-06-15. |
| `consult.sh` | Parallel read-only consult: asks the same question to Codex and Gemini, captures both transcripts, and leaves synthesis to the caller. Advisory-only; not part of the relay loop. |

## Operator usage (default live-window flow)

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
clean. `poll.sh` exits `10` on a closed relay (file `STATUS: Approved|Closed`) so the loop can stop.
*(Default `--relay-task RELAY-TURN`; seed it at relay setup, handed to the first actor.)*

**Poll interval — cache-warmth tradeoff.** `60s` keeps Claude Code's prompt cache warm
(≈5-min TTL); the **lock/heartbeat is the real correctness guard, not the timer**, so a longer
interval only adds latency, never a race. Use ~`60s` for active relays, longer (e.g. `120s`)
for the lower-frequency watchdog poller.

**Self-closing loops (no stray cron housekeeping).** Launch each loop with a deadline so it
ends on the first of: relay `Approved`/`Closed`, **or** the deadline:
`--deadline "$(date -v+30M +%s)"` (macOS) / `--deadline "$(date -d '+30 min' +%s)"` (GNU).
Past the deadline `poll.sh` prints `DECISION: stop`; the loop prompt then `CronList`s and
`CronDelete`s its own job. Cron jobs are per-session — you can't stop another window's loop
from yours, so always set a deadline. See the `/relay` skill → "Self-closing loops".

### Designated watchdog (exactly ONE window)
Only one poller holds watchdog authority, so a stalled turn is escalated once
without double-escalation:
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
`--agent-cmd` is the turn-taker seam. In the live-window flow it can remain a
window-driven/manual handoff; in the current headless path it can be a shipped
shim such as `relay-automation/codex-turn.sh` or `relay-automation/gemini-turn.sh`.
Exits: `0` closed Approved/Closed, `3` no-progress, `4` round cap / closed-not-approved.

### Cross-model windows (Codex / Gemini) — manual nudge
In the poll-based multi-window flow, non-Claude windows can't self-wake. The
operator's whole job is **one line**:
```
take your turn on relay-system/<date>/<slug>.md
```
The relay file embeds the `▶ TAKE YOUR TURN` instructions, so any agent acts from
the file alone. `poll.sh` detects a cross-model turn and emits this nudge text
rather than silently idling. If you want a current headless cross-model path
instead, use `relay-drive.sh` with a headless shim (`codex-turn.sh` or
`gemini-turn.sh`) rather than the `/loop` poll flow.

## Boundary (load-bearing)
- **Hands-free poll is all-Claude only** — it relies on Claude Code's in-session `/loop`. Cross-model stays on the manual nudge.
- **Not a durable scheduler / not unattended-without-a-window.** A Claude window must be open and looping for the default poll flow. Current headless turns exist, but durable unattended orchestration is still a separate problem.
- The portable `/relay` skill stays dependency-free; this tick-driven automation lives here.
