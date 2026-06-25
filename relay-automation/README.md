# relay-automation

A tick-backed automation layer for the manual `/relay` review loop and `xyz`
build swarms. Built in phases on top of `tick` (see
[PROPOSAL-AUTOMATION.md](../PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md)).

**Execution contract: default live-window flow** — the default operator path is
still the poll-driven, live-window flow: a Claude window under `/loop`, or a
human one-line nudge when the turn belongs to a non-Claude window. Headless
turn-takers now exist for Codex and agy (`codex-turn.sh`, `agy-turn.sh`),
but the cross-model poll loop still degrades to a manual nudge rather than
auto-firing those shims. For the current headless path, see
[the headless bring-up below](#headless-bring-up-codex--agy), plus
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
| `gemini-turn.sh` | **DEPRECATED 2026-06-19** — Gemini CLI retired; use `agy-turn.sh` instead. Kept as historical reference. |
| `agy-turn.sh` | **Option-A** headless turn-taker for the **agy** (Antigravity CLI) agent (`agy -p`); thin dispatch wrapper over `relay-turn-lib.sh`. Permanent replacement for `gemini-turn.sh`; live-validated 2026-06-18. |
| `consult.sh` | Parallel read-only consult: asks the same question to Codex and agy, captures both transcripts, and leaves synthesis to the caller. Advisory-only; not part of the relay loop. |

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
shim such as `relay-automation/codex-turn.sh` or `relay-automation/agy-turn.sh`.
Exits: `0` closed Approved/Closed, `3` no-progress, `4` round cap / closed-not-approved.

### Cross-model windows (Codex / agy) — manual nudge
In the poll-based multi-window flow, non-Claude windows can't self-wake. The
operator's whole job is **one line**:
```
take your turn on relay-system/<date>/<slug>.md
```
The relay file embeds the `▶ TAKE YOUR TURN` instructions, so any agent acts from
the file alone. `poll.sh` detects a cross-model turn and emits this nudge text
rather than silently idling. If you want a current headless cross-model path
instead, use `relay-drive.sh` with a headless shim (`codex-turn.sh` or
`agy-turn.sh`) rather than the `/loop` poll flow.

## Boundary (load-bearing)
- **Hands-free poll is all-Claude only** — it relies on Claude Code's in-session `/loop`. Cross-model stays on the manual nudge.
- **Not a durable scheduler / not unattended-without-a-window.** A Claude window must be open and looping for the default poll flow. Current headless turns exist, but durable unattended orchestration is still a separate problem.
- The portable `/relay` skill stays dependency-free; this tick-driven automation lives here.

## Headless bring-up (Codex + agy)

This section is the canonical fresh-device bootstrap path for the two shipped
headless Path-A workers: Codex and agy.

> **What a single-device test proves.** `.tick/` is gitignored and device-local,
> so two clones do not share token state over git. A fresh-device run proves
> that the selected headless turn-taker works cleanly in a fresh clone behind
> the safety shim; it does not prove cross-machine coordination.

### 1. Prerequisites

The shipped scripts assume Node, git, and whichever headless worker you plan to
drive:

```bash
node --version
codex exec -s workspace-write "create a file ok.txt with the text ok" < /dev/null   # Codex lane
agy -p "Reply with exactly: PONG" < /dev/null                                        # agy lane; run sandbox-OFF
git --version
```

Run the worker check for the lane you actually plan to drive; run both if you
want both workers available on that machine.

The Codex autonomy check matters: a bare `codex exec "say ok"` can succeed without
proving Codex can write the relay file. `codex-turn.sh` defaults to
`-s workspace-write`; if your device config still blocks writes, set
`CODEX_FLAGS='--dangerously-bypass-approvals-and-sandbox'` or add
`-c approval_policy=never`. If `codex` is not on `PATH` or is not authenticated,
fix that before running the shim; override the binary with
`CODEX_BIN=/path/to/codex` if needed.

The agy check must also run unsandboxed. `agy-turn.sh` uses `agy -p`; when agy's
backend is blocked by a sandbox it can exit `0` with empty output, which the
shim correctly treats as a failed turn. If `agy` is not on `PATH` or is not
authenticated through the Antigravity desktop app, fix that before driving the
lane; override the binary with `AGY_BIN=/path/to/agy` if needed.

If you are running under a sandboxed AI shell, run both workers outside that
sandbox. Codex often fails there because it cannot reach the OS keychain or
`chatgpt.com`; agy can fail "cleanly" with empty output when its backend network
is blocked.

### 2. Clone or refresh the harness

```bash
git clone https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm.git
cd xyz-3-agents-swarm
# or, in an existing clone: git pull origin main
export TICK_REPO_ROOT="$PWD"
```

### 3. Smoke test the local machine

Run the repo gate, then the shim test for the worker you plan to drive:

```bash
bash validate.sh
bash test/codex-turn.sh   # before Codex runs
bash test/agy-turn.sh     # before agy runs
```

If `validate.sh` cannot make tempdirs, that is usually a sandbox blocking
`mktemp`; rerun it in a normal shell.

### 4. Drive one headless turn in this repo

The supervisor (`relay-drive.sh`) drives the turn; the selected shim
(`codex-turn.sh` or `agy-turn.sh`) is the turn-taker and owns the safety
boundary: path allowlist, commit-bypass guard, file-scoped commit, and no push.

#### Codex worker

```bash
# Reuse an existing relay thread or scaffold a fresh one with embedded
# TAKE YOUR TURN instructions.
RELAY=relay-system/2026-06-15/<your-slug>.md
ARTIFACT=relay-automation/codex-turn.sh

# Use a per-relay token id, not the literal RELAY-TURN.
TASK="RELAY-$(basename "$RELAY" .md)"

./bin/tick log task.created "$TASK" --agent claude-a
./bin/tick claim   "$TASK" --agent claude-a --paths "$ARTIFACT"
./bin/tick release "$TASK" --agent claude-a --to codex

CODEX_AGENT=codex ALLOW_PATHS="$ARTIFACT" CODEX_LOG=/tmp/codex-turn.log \
relay-automation/relay-drive.sh \
  --relay-file "$RELAY" \
  --relay-task "$TASK" \
  --agent-cmd relay-automation/codex-turn.sh \
  --round-cap 4
```

Expect Codex to claim and ping the token, append its block to the relay file,
release or `done` the token, revert any off-allowlist edits, commit only the
allowlisted paths, and skip push. The transcript lands in
`/tmp/codex-turn.log`.

#### agy worker

```bash
# Reuse an existing relay thread or scaffold a fresh one with embedded
# TAKE YOUR TURN instructions.
RELAY=relay-system/2026-06-15/<your-slug>.md
ARTIFACT=relay-automation/agy-turn.sh

# Use a per-relay token id, not the literal RELAY-TURN.
TASK="RELAY-$(basename "$RELAY" .md)"

./bin/tick log task.created "$TASK" --agent claude-a
./bin/tick claim   "$TASK" --agent claude-a --paths "$ARTIFACT"
./bin/tick release "$TASK" --agent claude-a --to agy

AGY_AGENT=agy AGY_LOG=/tmp/agy-turn.log \
relay-automation/relay-drive.sh \
  --relay-file "$RELAY" \
  --relay-task "$TASK" \
  --agent-cmd relay-automation/agy-turn.sh \
  --round-cap 4
```

Expect agy to claim and ping the token, append its block to the relay file,
release or `done` the token, revert any off-allowlist edits, commit only the
allowlisted paths, and skip push. The transcript lands in `/tmp/agy-turn.log`.

Exit codes:

- `relay-drive.sh`: `0` closed Approved or Closed, `3` no progress, `4` round cap or closed-not-approved, `2` usage.
- `codex-turn.sh`: `0` acted or deferred, `5` Codex failed, `6` off-allowlist edit reverted or Codex committed mid-turn, `7` timeout-killed, `2` usage.
- `agy-turn.sh`: `0` acted or deferred, `5` agy failed or produced empty output, `6` off-allowlist edit reverted or agy committed mid-turn, `7` timeout-killed, `2` usage.

### 5. Review a file in another repo

The common case is reviewing a target repo while using this clone only as the
harness. The thread and artifact live in the target repo; `.tick` and `bin/tick`
stay anchored to the harness.

```bash
HARNESS=/path/to/xyz-3-agents-swarm
TARGET=/path/to/your-repo

export TICK_REPO_ROOT="$HARNESS"

# Run from the target root to keep relay and artifact paths repo-relative.
cd "$TARGET"
RELAY=relay-system/$(date +%F)/<your-slug>.md
ARTIFACT=path/to/file/under/target.ext
TASK="RELAY-$(basename "$RELAY" .md)"

"$HARNESS/bin/tick" log task.created "$TASK" --agent claude-a
"$HARNESS/bin/tick" claim   "$TASK" --agent claude-a --paths "$ARTIFACT"
"$HARNESS/bin/tick" release "$TASK" --agent claude-a --to codex

CODEX_AGENT=codex \
ALLOW_PATHS="$ARTIFACT" \
CODEX_FLAGS='--dangerously-bypass-approvals-and-sandbox' \
CODEX_LOG=/tmp/codex-turn.log \
"$HARNESS/relay-automation/relay-drive.sh" \
  --target-root "$TARGET" \
  --relay-file "$RELAY" \
  --relay-task "$TASK" \
  --agent-cmd "$HARNESS/relay-automation/codex-turn.sh" \
  --round-cap 4
```

Swap the worker-specific lines to drive agy instead:

```bash
"$HARNESS/bin/tick" release "$TASK" --agent claude-a --to agy

AGY_AGENT=agy \
AGY_LOG=/tmp/agy-turn.log \
"$HARNESS/relay-automation/relay-drive.sh" \
  --target-root "$TARGET" \
  --relay-file "$RELAY" \
  --relay-task "$TASK" \
  --agent-cmd "$HARNESS/relay-automation/agy-turn.sh" \
  --round-cap 4
```

The boundary is unchanged: path allowlist, file-scoped commit, no push, and
worktree isolation of `target@HEAD`. Only the artifact side moves to
`--target-root`.

### 6. Device caveats

- No push by design. Shim-taken turns commit locally only.
- `.tick/` is local. Token state on this device is independent of other machines.
- Each headless turn is real API spend, so keep `--round-cap` small. Codex and agy differ in cost visibility; the agy lane is currently cost-blind in harness logs.
- Headless runs should not share an agent id with a live `/loop` on the same relay.
