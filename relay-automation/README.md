# relay-automation

A tick-backed automation layer for the manual `/relay` review loop and `xyz`
build swarms. Built in phases on top of `tick` (see
[PROPOSAL-AUTOMATION.md](../PROJECT/1-INBOX/EXP-AUTOMATION/PROPOSAL-AUTOMATION.md)).

**Execution contract: default live-window flow** — the default operator path is
still the poll-driven, live-window flow: a Claude window under `/loop`, or a
human one-line nudge when the turn belongs to a non-Claude window. Headless
turn-takers now exist for Codex, agy, and Pi (`codex-turn.sh`, `agy-turn.sh`,
`pi-turn.sh`).
`relay-loop.sh --background --cross-model-cmd <shim>` can now auto-fire one of
those shims on `DECISION: nudge-cross-model`; without that wrapper-only flag,
the loop still degrades to the existing manual nudge. For the current headless path, see
[Set up Codex, agy, and Pi below](#set-up-codex-agy-and-pi-headless-bring-up), plus
[CROSSMODEL-OPTIONA-PLAN.md](CROSSMODEL-OPTIONA-PLAN.md).

## Components
| Script | Role |
|---|---|
| `poll.sh` | **Phase 4** per-tick poll driver. Reads state, applies the guard, dispatches `runner.sh`/`watchdog.sh` or idles. Run under `/loop`. |
| `relay-loop.sh` | **GH-33 Phase 2/3 + GH-46 Phase 4** adaptive-cadence wrapper over `poll.sh` (which stays a pure oracle). Default = one tick that prints `NEXT-POLL: <s>` for a `/loop` dynamic tick / cron / any scheduler; `--sleep-loop` self-paces in pure bash (no Claude dep). **`--background`** dispatches the turn DETACHED on `run-runner`, and on `nudge-cross-model` it dispatches `--cross-model-cmd` only when that command is configured and reachable; otherwise it prints the same manual nudge `poll.sh` would have emitted. A pidfile (`<relay-file>.bgpid` or `--bg-pidfile`) is still the single-turn lock (`BG-RUNNING`, no double-dispatch; stale pidfile cleared before the fresh decision acts). Containment is **inherited** — the backgrounded process is the same runner/shim boundary, so the `relay-turn-lib.sh` boundary is byte-identical (`&` changes only when the parent returns). |
| `runner.sh` | **Phase 3** single agent/turn: claim → run (`--agent-cmd`) → verdict gate (`VERDICT: PASS\|FAIL\|PARKED`) → done/retry; artifact-scoped clean-tree gate. |
| `watchdog.sh` | **Phase 2** liveness: `tick analyze --format json` → parked `parked_suspects[]` → structured escalation record; reap gated behind `--allow-reap` (stub, pending an authority decision). |
| `relay-drive.sh` | **Phase 4b** relay supervisor: loops a `/relay` Producer↔Reviewer thread to termination via a turn-taker; round cap + no-progress escalation. |
| `relay-turn-lib.sh` | **Shared safety core** (sourced, not run): the model-agnostic containment contract — path-allowlist + commit-bypass guard + no-push. Both headless turn-takers source this so the boundary lives in ONE place. See [decisions/2026-06-15-unattended-agent-containment.md](../decisions/2026-06-15-unattended-agent-containment.md). |
| `codex-turn.sh` | **Option-A** headless turn-taker for the **Codex** agent (`codex exec`); thin dispatch wrapper over `relay-turn-lib.sh`. |
| `agy-turn.sh` | **Option-A** headless turn-taker for the **agy** (Antigravity CLI) agent (`agy -p`); thin dispatch wrapper over `relay-turn-lib.sh`. Permanent replacement for `gemini-turn.sh`; live-validated 2026-06-18. |
| `pi-turn.sh` | **GH-295** headless turn-taker for **Pi** (`pi.dev`, package `@earendil-works/pi-coding-agent`; `pi --provider … --model … --mode json -p`); thin dispatch wrapper over `relay-turn-lib.sh`. Same posture as agy (no built-in sandbox — containment is worktree isolation + `rtl_enforce`), but genuinely better on cost visibility: `--mode json`'s JSONL stream carries real per-call `usage`/`cost` fields, so this is the first non-Claude lane with actual `tick cost --tool pi` capture. `PI_MODEL` has **no default** by design (GH-280/aider#5486 class of bug); the operator must set it explicitly. |
| `aider-turn.sh` | Headless turn-taker for **Aider ↔ OpenRouter** (`aider --model openrouter/… --message`) — an OpenAI-standard lane discrete from Codex. Same `relay-turn-lib.sh` containment; because Aider is a file-editor (no mid-turn shell), the SHIM performs the tick token ops itself and runs Aider with `--no-auto-commits` (the harness owns the commit). Set `OPENROUTER_API_KEY` + `AIDER_MODEL` (e.g. `openrouter/anthropic/claude-3.5-sonnet`, `openrouter/openai/gpt-4o`, `openrouter/deepseek/deepseek-chat`). Works in **both** a marathon `--builder aider` lane AND a plain `/relay` — it routes through the shared `marathon-agent.sh` dispatcher (`relay-drive.sh`'s `--agent-cmd`), so a driven relay with `RELAY_AGENT=aider` fires it just like Codex/agy. |
| `deep-research.mjs` | **Provider-agnostic grounded web search** (GH-87/GH-129): one normalized `{answer, citations, query, provider, model, raw}` contract over two backends — **Agy Gemini Search** (default; `agy` CLI in a throwaway tmpdir, side-effect free) and **Perplexity Sonar via OpenRouter** (`--provider openrouter`; same `OPENROUTER_API_KEY` gateway convention as the Aider lane, model `perplexity/sonar` overridable via `DEEP_RESEARCH_OPENROUTER_MODEL`, `--search-context-size` → Perplexity's native `web_search_options.search_context_size`). Fail-closed typed errors (`binary_missing`/`missing_api_key`/`timeout`/`backend_error`/`empty_output`) — never a silent cross-provider fallback. Run sandbox-OFF; prefer `--search-context-size medium` with focused single-intent queries (`high` risks runaway grounding near the 120s `DEEP_RESEARCH_TIMEOUT_MS` cap — see #124). Wall-clock cap is `DEEP_RESEARCH_TIMEOUT_MS`, default `120000` (120s); override upward (e.g. `DEEP_RESEARCH_TIMEOUT_MS=180000`) when a thorough `high`-context, multi-claim query genuinely needs more headroom — the default itself is unchanged. |
| `consult.sh` | Parallel read-only consult: asks the same question to **Codex, agy, and (opt-in) Aider↔OpenRouter** (`--models codex,agy,aider`), captures each transcript, and leaves synthesis to the caller. Advisory-only; also the engine behind `relay-drive.sh --consult-verify`. |
| `xyz-vendor.sh` / `xyz-sync.sh` | Vendoring pair for `.xyz/` copies materialized into another repo. `xyz-vendor.sh <target-repo>` mirrors this harness into `<target-repo>/.xyz/` and stamps a row in the local `registry.tsv` (`install_dir`, `last_install_utc`, `tick_version`, `source_commit`, `coordinated_repo`) at that moment. `xyz-sync.sh list \| update \| delete \| check` manages those registered rows: `list` shows them, `update <dir>\|--all` re-vendors, `delete <dir>\|--all [--yes]` removes a copy and prunes its row. **`check <dir>\|--all`** (GH-96) is report-only drift detection: it recomputes the CURRENT `tick_version`/`source_commit` this harness ships and compares against each row's recorded pair — a mismatch in **either** field counts as drift. Exact match on both → a silent `ok` line; drift → a warning naming the drifted field(s) and both recorded/current values. Never a hard error, never an auto-pull — updates land only via an explicit `update`/`xyz-vendor.sh` re-run (pinned + manual by design). This is the harness-side "is this install stale?" signal a downstream consumer (e.g. rebalance-OS) can poll instead of guessing. |

## Adding a new consult advisor (GH-178 A1)

`consult.sh`'s `--models` dispatch is a data table (`ADV_NAMES`/`ADV_RUNFNS`, parallel arrays —
bash 3.2/macOS has no `declare -A`), so adding a 5th advisor is a data addition, not a new case arm:
add its name to `ADV_NAMES`, write a `run_<vendor>() { local out="$1"; ...; }` alongside the existing
`run_codex`/`run_agy`/`run_gemini`/`run_aider`, and add its function name to `ADV_RUNFNS` at the same
index. What a new `run_<vendor>()` must do itself (genuinely vendor-specific): the CLI invocation
syntax/flags, any auth pre-flight probe (see `agy_auth_preflight`), and transcript-format quirks (e.g.
`run_codex`'s attestation-header prepend). What it gets for free by calling `_guarded "$out" ...`
(shared via this file, not `relay-turn-lib.sh` — that lib backs the separate `*-turn.sh` relay shims):
the wall-clock timeout watchdog and output capture into `$out`. If the new advisor is also wired as a
relay turn-taker (a `<vendor>-turn.sh` alongside `codex-turn.sh`/`agy-turn.sh`/`aider-turn.sh`), it
should source `relay-turn-lib.sh` for the containment contract (`rtl_init`/`rtl_before`/
`rtl_run_bounded`/`rtl_enforce`) exactly like the existing shims — that boundary is already
model-agnostic; do not reimplement it.

## XYZ completion telemetry

`XYZ.json` is the harness repo root's gitignored, newest-first completion log. It is always written in
the harness clone that owns `relay-automation/`; it is never redirected into a `--target-root`
foreign repo.

Each array element has this schema:

```json
{
	"harness": "relay",
	"sessionId": "gh96seam1",
	"health": "green",
	"title": "Marathon Phase gh96seam1",
	"description": "Relay session ended: STATUS Approved (health green).",
	"updatedAt": "2026-07-05T00:00:00Z"
}
```

Field contract:

| Field | Type | Meaning |
|---|---|---|
| `harness` | string | `relay`, `marathon`, or `swarm` |
| `sessionId` | string | Relay thread slug, marathon run id, or caller-supplied `XYZ_SESSION_ID` |
| `health` | string | `green`, `orange`, or `red` |
| `title` | string | Short human-readable label for the run |
| `description` | string | One-line outcome summary |
| `updatedAt` | string | UTC timestamp in ISO-8601 `YYYY-MM-DDTHH:MM:SSZ` form |

Emit cadence:

| Flow | `XYZ.json` emit contract |
|---|---|
| Standalone `relay-drive.sh` | Exactly one record when the relay terminates: `Approved`/`Closed` => `green`; explicit `Escalated` / review handback => `orange`; no-progress / review-once stall / round-cap => `red` |
| Bare `marathon-drive.sh` | Exactly one `marathon` record per invocation |
| Swarm-originated `marathon-drive.sh` (`XYZ_HARNESS_CONTEXT=swarm`) | Exactly one `swarm` record per invocation |
| `marathon.sh` orchestrated multi-phase run | Exactly one `marathon` record for the whole run; nested phase-level `marathon-drive.sh` completion hooks stay silent |

`XYZ.heartbeat.json` is the companion in-flight marker. It is a single mutable object, not an array:

```json
{
	"harness": "marathon",
	"sessionId": "gh96-seam1",
	"updatedAt": "2026-07-05T00:00:00Z"
}
```

Heartbeat cadence:

| Flow | `XYZ.heartbeat.json` behavior |
|---|---|
| Standalone `relay-drive.sh` | Overwritten once per round before the turn-taker runs |
| Any `marathon-drive.sh` phase | Overwritten once right after `marathon.phase.start` |
| Nested `relay-drive.sh` inside `marathon-drive.sh` | Silent; the phase-level marathon heartbeat owns freshness so a nested relay round does not double-write |
| Terminal completion for the same harness + `sessionId` | The heartbeat file is cleared before the completion record is appended, so finished runs leave no stale in-progress marker |
| Crash / kill / hang | No completion record is appended, so the last heartbeat remains in place and goes stale naturally for freshness-aware consumers |

## Recipes & docs (not scripts)
| Doc | What it gives you |
|---|---|
| [DUELING-CLAUDES.md](DUELING-CLAUDES.md) | **"Dueling Claudes"** — copy-paste recipe for two live Claude windows running a Reporter↔Maintainer bug-fix relay on one machine, zero new code, with the single human go-gate before commit. The worked form of the hands-free Path B in the `relay-xyz` skill. |
| [CONSUMING.md](CONSUMING.md) | How another repo consumes this harness (`--target-root`, cross-machine `.tick/` limits). |
| [CROSSMODEL-OPTIONA-PLAN.md](CROSSMODEL-OPTIONA-PLAN.md) | The Option-A cross-model headless turn-taker plan (Codex / agy shims). |
| [MARATHON.example.yaml](MARATHON.example.yaml) | Example multi-build marathon manifest for `marathon.sh`. |

## `marathon.sh` roots

`marathon.sh` resolves two different roots on purpose:

- `MARATHON_HOME`: the harness install that owns `bin/tick`, `bin/marathon-yaml`, and telemetry helpers. Default: the script's own parent dir (`relay-automation/..`).
- `MARATHON_ROOT`: the target repo that owns the plan's `brief:` files, `marathon-system/`, `.tick/`, and commit target. Default: `git -C "$PWD" rev-parse --show-toplevel`; outside a git repo it falls back to `MARATHON_HOME`.

That split preserves dev-checkout behavior (`MARATHON_HOME == MARATHON_ROOT`) and makes vendored installs work with no bin overrides:

```bash
cd /path/to/target-repo
./.xyz/relay-automation/marathon.sh --plan marathon-plans/my-wave/MARATHON.yaml
```

Override them independently only when you genuinely need a non-default harness or repo root. The lower-level binary overrides (`TICK_BIN`, `MARATHON_YAML_BIN`, `XYZ_APPEND_BIN`) still win if set.

## `marathon-plan.sh` zone config

`utils/marathon-plan.sh` can now load a repo-specific zone model instead of hardcoding xyz's own
`kernel` / `shim` filenames:

- Resolution order: `--zones-config <file>` → `QUEUE_PLAN_ZONES_FILE` → `QUEUE_PLAN_ROOT/.marathon-plan-zones.json` → built-in `utils/marathon-plan-zones.default.json`.
- Explicit files fail loud on read/JSON/schema errors; only an absent root-local file falls through.
- Schema:
  - `zones[]`: ordered first-match rules.
  - `name`: emitted zone label.
  - `pathPrefixes` / `pathRegex` / `pathRegexCaseInsensitive`: proven write-set matching.
  - `inferKeywordRegex`: fallback keyword inference when no contract write-set exists.
  - `maxPerWave`: per-zone cap.
  - `penalty`: planner score penalty.
  - `conservativeWhenInferred`: do not co-wave multiple inferred lanes in that zone.
  - `escalateOrchestratorOnly`: if true, an artifact under `contract.lanes.orchestrator_only` is promoted into that zone before normal path matching.
  - `defaultZone`: fallback `{name, penalty}` object (may also carry `maxPerWave` / `conservativeWhenInferred`).

The built-in default file reproduces xyz's prior behavior byte-for-byte; foreign repos can override
only the classifier rules without changing the rest of the planner.

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
Exits: `0` closed Approved/Closed, `3` no-progress, `4` round cap / closed-not-approved, `5`
(with `--review-once`) reviewer completed a single non-approval review. Inspect whose-turn mid-drive
with `tick info <task>` (the verb is `info`, not `status`).

### Cross-model windows (Codex / agy)
In the poll-based multi-window flow, non-Claude windows still need a wake-up path.
Without `relay-loop.sh --background --cross-model-cmd <shim>`, the operator's
whole job is **one line**:
```
take your turn on relay-system/<date>/<slug>.md
```
The relay file embeds the `▶ TAKE YOUR TURN` instructions, so any agent acts from
the file alone. `poll.sh` detects a cross-model turn and emits this nudge text
rather than silently idling. If you want the current headless cross-model path
inside the `/loop` poll flow, wrap `poll.sh` with `relay-loop.sh --background`
and pass `--cross-model-cmd relay-automation/codex-turn.sh` (or `agy-turn.sh`);
the same pidfile lock prevents a second dispatch while that shim is still
running. `relay-drive.sh` remains the deterministic single-window alternative.

## Boundary (load-bearing)
- **Hands-free poll is all-Claude only** — it relies on Claude Code's in-session `/loop`. Cross-model stays on the manual nudge.
- **Not a durable scheduler / not unattended-without-a-window.** A Claude window must be open and looping for the default poll flow. Current headless turns exist, but durable unattended orchestration is still a separate problem.
- The portable `/relay` skill stays dependency-free; this tick-driven automation lives here.

## Set up Codex, agy, and Pi (headless bring-up)

This section is the canonical fresh-device bootstrap path for the three shipped
headless Path-A workers: Codex, agy, and Pi — install them, authenticate them,
then prove each one can actually drive a turn.

> **What a single-device test proves.** `.tick/` is gitignored and device-local,
> so two clones do not share token state over git. A fresh-device run proves
> that the selected headless turn-taker works cleanly in a fresh clone behind
> the safety shim; it does not prove cross-machine coordination.

### 1. Install and authenticate the CLIs

The shipped scripts assume Node and git are already present, plus whichever
headless worker you plan to drive. **Install and sign in to the worker CLIs
first** — every shim shells out to them, so an unauthenticated CLI fails the turn
mid-run rather than at startup:

| Worker | Install | Authenticate |
|---|---|---|
| **Codex** (OpenAI) | <https://openai.com/index/introducing-the-codex-app/> | Sign in with your ChatGPT account — `codex` prompts on first run. Billing follows the ChatGPT subscription, not API credits. |
| **agy** (Google Antigravity — install the **CLI**, not just the desktop app) | <https://antigravity.google/product/antigravity-cli> | Sign in through the Antigravity desktop app. On macOS the CLI lands at `~/.local/bin/agy`, which is **not** on the default `PATH`. |
| **Pi** (optional third lane, GH-295) | Ships outside this repo — put `pi` on `PATH`, or point `PI_BIN` at it | Provider credential via `PI_PROVIDER` (defaults to `openrouter`, reusing `OPENROUTER_API_KEY`) |

You can also hand the Antigravity URL to Claude Code and ask it to do the install
for you. Codex and agy are the two the beta onboarding path assumes; Pi is
additive.

Once installed, verify Node, git, and the lane you actually plan to drive:

```bash
node --version
codex exec -s workspace-write "create a file ok.txt with the text ok" < /dev/null   # Codex lane
agy -p "Reply with exactly: PONG" < /dev/null                                        # agy lane; run sandbox-OFF
pi --provider openrouter --model <your-model-id> --no-session -p "Reply with exactly: PONG" < /dev/null  # Pi lane
git --version
```

Run the worker check for the lane you actually plan to drive; run all three if
you want every worker available on that machine.

The Codex autonomy check matters: a bare `codex exec "say ok"` can succeed without
proving Codex can write the relay file. `codex-turn.sh` defaults to
`-s workspace-write`, `-c approval_policy=never`, and a 900-second
`RELAY_TURN_TIMEOUT_S`; if your device config still blocks writes, set
`CODEX_FLAGS='--dangerously-bypass-approvals-and-sandbox'` or add
`-c approval_policy=never`. If `codex` is not on `PATH` or is not authenticated,
fix that before running the shim; override the binary with
`CODEX_BIN=/path/to/codex` if needed.

The agy check must also run unsandboxed. `agy-turn.sh` uses `agy -p`; when agy's backend is blocked by a sandbox it can exit `0` with empty output, which the shim correctly treats as a failed turn. The agy shim uses the same 900-second default `RELAY_TURN_TIMEOUT_S`, and passes that value through to `--print-timeout`. Note: Claude Code may misdiagnose the `-p` requirement as "requires interactive TTY" if it fails — this is a misdiagnosis; the flag just requires a clean non-sandboxed environment. Additionally, running `agy` headlessly for the first time on macOS may trigger a Documents-folder permission prompt mid-run, so keep an eye out for system dialogue boxes. If `agy` is not on `PATH` or is not authenticated through the Antigravity desktop app, fix that before driving the lane; override the binary with `AGY_BIN=/path/to/agy` if needed. Antigravity installs `agy` at `~/.local/bin/agy` on macOS by default (not on the system PATH); running `AGY_BIN=~/.local/bin/agy bash test/agy-turn.sh` confirms it works before adding it to your PATH or passing `AGY_BIN` to every drive command.

The Pi check needs `PI_MODEL` set explicitly — `pi-turn.sh`/`pi-turn.py` **never
default `PI_MODEL`**. This is a deliberate GH-295 safety choice: GH-280
(aider#5486) documented the exact failure class a silently-defaulted/unlisted
model id causes (billed against an unintended model), so this shim fails loud
(exit `5`) instead of guessing. Set it to any model id your `PI_PROVIDER`
exposes, e.g. `PI_MODEL=openai/gpt-mini-latest`; run `pi --list-models` to see
your account's catalog. `PI_PROVIDER` defaults to `openrouter`, reusing this
harness's existing `OPENROUTER_API_KEY` — no extra credential wiring needed for
that default seam. `pi`'s built-in tools (`read`/`bash`/`edit`/`write`) run with
no separate approval flag needed in headless `-p` mode (unlike Codex, there is
no interactive approval gate to disable). If `pi` is not on `PATH`, fix that
before running the shim, or override the binary with `PI_BIN=/path/to/pi`.

If you are running under a sandboxed AI shell, run all three workers outside
that sandbox. Codex often fails there because it cannot reach the OS keychain
or `chatgpt.com`; agy can fail "cleanly" with empty output when its backend
network is blocked; Pi's containment posture is the same as agy's (no
built-in sandbox of its own — see the Pi worker subsection below).

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
bash test/pi-turn.sh      # before Pi runs (GH-295)
```

If `validate.sh` cannot make tempdirs, that is usually a sandbox blocking
`mktemp`; rerun it in a normal shell.

#### Stale `.git/index.lock` preflight warning

`utils/swarm-preflight.sh` now emits an advisory warning when
`$TARGET_ROOT/.git/index.lock` exists and `lsof` shows no live holder on that
exact path. That stays fail-open on purpose: a stale lock is operator-visible,
but it does not change preflight readiness by itself.

If you see the warning, verify no live git process is still active with
`pgrep -fl git`, then remove the orphaned lock from the target repo root with
`rm .git/index.lock`.

### 4. Drive one headless turn in this repo

The supervisor (`relay-drive.sh`) drives the turn; the selected shim
(`codex-turn.sh` or `agy-turn.sh`) is the turn-taker and owns the safety
boundary: path allowlist, commit-bypass guard, file-scoped commit, and no push.
*(Note: Fixed log paths break concurrent same-machine runs. Prefer using the shims' default per-PID paths or specifying a per-PID log file path with `$$`.)*

**Worktree isolation is ON by default for driven runs.** `relay-drive.sh`
exports `RELAY_WORKTREE_ISOLATION=1`, so each shim runs inside a throwaway
`git worktree` of `ROOT@HEAD`. Off-allowlist writes in the worktree are
discarded and the turn fails with **exit 6**. One important side-effect: agents
that write to the relay file via **absolute paths** bypass the worktree (those
writes land in ROOT, not the throwaway tree) — so untracked relay files with
absolute paths in the `▶ TAKE YOUR TURN` block remain accessible to the agent.
Opt out per run with `RELAY_WORKTREE_ISOLATION=0` if you need to disable
isolation (e.g. during testing).

#### Codex worker

```bash
# Reuse an existing relay thread or scaffold a fresh one with embedded
# TAKE YOUR TURN instructions.
RELAY=relay-system/$(date +%F)/<your-slug>.md
ARTIFACT=relay-automation/codex-turn.sh

# Use a per-relay token id, not the literal RELAY-TURN.
TASK="RELAY-$(basename "$RELAY" .md)"

./bin/tick log task.created "$TASK" --agent claude-a
./bin/tick claim   "$TASK" --agent claude-a --paths "$ARTIFACT"
./bin/tick release "$TASK" --agent claude-a --to codex

CODEX_AGENT=codex ALLOW_PATHS="$ARTIFACT" CODEX_LOG="${TMPDIR:-/tmp}/codex-turn-$$.log" \
relay-automation/relay-drive.sh \
  --relay-file "$RELAY" \
  --relay-task "$TASK" \
  --agent-cmd relay-automation/codex-turn.sh \
  --round-cap 4
```

Expect Codex to claim and ping the token, append its block to the relay file,
release or `done` the token, revert any off-allowlist edits, commit only the
allowlisted paths, and skip push. The transcript lands in
`"${TMPDIR:-/tmp}/codex-turn-$$.log"`.

#### agy worker

```bash
# Reuse an existing relay thread or scaffold a fresh one with embedded
# TAKE YOUR TURN instructions.
RELAY=relay-system/$(date +%F)/<your-slug>.md
ARTIFACT=relay-automation/agy-turn.sh

# Use a per-relay token id, not the literal RELAY-TURN.
TASK="RELAY-$(basename "$RELAY" .md)"

./bin/tick log task.created "$TASK" --agent claude-a
./bin/tick claim   "$TASK" --agent claude-a --paths "$ARTIFACT"
./bin/tick release "$TASK" --agent claude-a --to agy

AGY_AGENT=agy ALLOW_PATHS="$ARTIFACT" AGY_LOG="${TMPDIR:-/tmp}/agy-turn-$$.log" \
relay-automation/relay-drive.sh \
  --relay-file "$RELAY" \
  --relay-task "$TASK" \
  --agent-cmd relay-automation/agy-turn.sh \
  --round-cap 4
```

Expect agy to claim and ping the token, append its block to the relay file,
release or `done` the token, revert any off-allowlist edits, commit only the
allowlisted paths, and skip push. The transcript lands in `"${TMPDIR:-/tmp}/agy-turn-$$.log"`.

#### Pi worker (GH-295)

```bash
# Reuse an existing relay thread or scaffold a fresh one with embedded
# TAKE YOUR TURN instructions.
RELAY=relay-system/$(date +%F)/<your-slug>.md
ARTIFACT=relay-automation/pi-turn.sh

# Use a per-relay token id, not the literal RELAY-TURN.
TASK="RELAY-$(basename "$RELAY" .md)"

./bin/tick log task.created "$TASK" --agent claude-a
./bin/tick claim   "$TASK" --agent claude-a --paths "$ARTIFACT"
./bin/tick release "$TASK" --agent claude-a --to pi

PI_AGENT=pi ALLOW_PATHS="$ARTIFACT" PI_MODEL=openai/gpt-mini-latest PI_LOG="${TMPDIR:-/tmp}/pi-turn-$$.log" \
relay-automation/relay-drive.sh \
  --relay-file "$RELAY" \
  --relay-task "$TASK" \
  --agent-cmd relay-automation/pi-turn.sh \
  --round-cap 4
```

Expect Pi to claim and ping the token, append its block to the relay file,
release or `done` the token, revert any off-allowlist edits, commit only the
allowlisted paths, and skip push. The transcript lands in
`"${TMPDIR:-/tmp}/pi-turn-$$.log"` as a JSONL stream (`--mode json`: one JSON
object per line, not a single blob or array); the shim's best-effort cost
capture scans it for the last `message.usage` block and — unlike the agy
lane, which is fully cost-blind — emits a real `tick cost --tool pi` event
when usage stats are present. **`PI_MODEL` has no default** and must be set
explicitly (see the prerequisites note above); an unset `PI_MODEL` fails the
turn before Pi is even invoked (exit `5`), never silently.

Containment note: Pi, like agy, has no sandbox of its own — the shim relies
entirely on `RELAY_WORKTREE_ISOLATION=1` + `rtl_enforce` (the shared
allowlist/commit-bypass guard), not a Pi-native `--sandbox`-style flag (there
isn't one to pass).

`RELAY_TURN_TIMEOUT_S` is the per-turn wall-clock ceiling for `codex-turn.sh`, `agy-turn.sh`, and
`pi-turn.sh`. Default: `900`. Override per run, for example:

```bash
RELAY_TURN_TIMEOUT_S=1200 relay-automation/relay-drive.sh ...
```

For multi-phase plans, prefer the per-lane `turn_timeout_s:` field in `MARATHON.yaml`; `marathon.sh`
exports it into that phase's drive env as `RELAY_TURN_TIMEOUT_S`.

Exit codes:

- `relay-drive.sh`: `0` closed Approved or Closed, `3` no progress, `4` round cap or closed-not-approved, `5` (with `--review-once`) reviewer completed a single non-approval review ("changes requested" — not a stall), `2` usage.
- `codex-turn.sh`: `0` acted or deferred, `5` Codex failed, `6` off-allowlist edit reverted or Codex committed mid-turn, `7` timeout-killed (`RELAY_TURN_TIMEOUT_S`, default `900`), `2` usage.
- `agy-turn.sh`: `0` acted or deferred, `5` agy failed or produced empty output, `6` off-allowlist edit reverted or agy committed mid-turn, `7` timeout-killed (`RELAY_TURN_TIMEOUT_S`, default `900`), `2` usage.
- `pi-turn.sh` (GH-295): `0` acted or deferred, `5` Pi failed / produced empty output / `PI_MODEL` unset / auth pre-flight failed, `6` off-allowlist edit reverted or Pi committed mid-turn, `7` timeout-killed (`RELAY_TURN_TIMEOUT_S`, default `900`), `2` usage.
- `bin/tick`: exits `8` when structural quality validation fail occurs (`bin/validate-relay-block` exits non-zero when `--relay-file` flag is provided to `release` or `done`).

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
CODEX_LOG="${TMPDIR:-/tmp}/codex-turn-$$.log" \
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
ALLOW_PATHS="$ARTIFACT" \
AGY_LOG="${TMPDIR:-/tmp}/agy-turn-$$.log" \
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

#### Optional: collect transcripts in one archive (`XYZ_ARCHIVE_ROOT`, GH-30)

By default a cross-repo turn writes its transcript into the target repo's
`relay-system/` tree and commits it into that repo's history. Set
`XYZ_ARCHIVE_ROOT` to an **absolute path of an existing git repo** to redirect
every transcript out of the product repos into one namespaced archive instead:

```bash
export XYZ_ARCHIVE_ROOT=/abs/path/to/transcript-archive   # absolute + exists + is a git repo
```

- **Unset (default):** byte-for-byte today's behavior.
- **Set:** all transcript writers (`consult.sh`, `marathon-drive.sh`,
  `relay-drive.sh`, `swarm-preflight.sh`, `new-relay.sh`) emit under
  `$XYZ_ARCHIVE_ROOT/relay-system/<repo-slug>/…`, namespaced per source repo.
  A headless **turn** then commits the transcript **into the archive repo**
  (Model A) while the code artifact and the `.tick` token stay anchored to the
  target — so the target tree stays free of `relay-system/` and its history
  carries no transcript commit. The archive commit is isolated from the target's
  HEAD, so it never orphans a concurrent peer commit there. Configure a git
  identity in the archive repo (a failed archive commit warns; it never fails the
  turn). Set-but-invalid (relative / missing / non-git) is a **hard error**; an
  explicit `--out` / `RELAY_FILE` always wins. `extract-relay-telemetry.sh`
  aggregates across all `<repo-slug>/` dirs when the var is set. Full contract:
  [CONSUMING.md](CONSUMING.md#optional-keep-transcripts-out-of-repo-b-xyz_archive_root-gh-30).

### 6. Device caveats

- No push by design. Shim-taken turns commit locally only.
- `.tick/` is local. Token state on this device is independent of other machines.
- Each headless turn is real API spend, so keep `--round-cap` small. Codex, agy, and Pi differ in cost visibility; the agy lane is currently cost-blind in harness logs, and Codex's token-stats parsing is still a Phase-1 partial. Pi's `--mode json` stream carries real per-call usage/cost fields, so the Pi lane is the first non-Claude lane with genuine `tick cost --tool pi` capture — a real gap-closer versus the other two, not just parity (GH-295).
- Headless runs should not share an agent id with a live `/loop` on the same relay.

## OpenRouter model-alias lookup (GH-120)

`openrouter-model-aliases.yml` + `resolve-model-alias.sh` resolve a colloquial
OpenRouter model name (e.g. "GLM 5.2", "Nemotron Ultra 3") to its canonical
`provider/slug[:variant]` id locally, without a live query against
`https://openrouter.ai/api/v1/models` on every lookup.

```bash
relay-automation/resolve-model-alias.sh "Nemotron 3 Ultra"
# -> nvidia/nemotron-3-ultra-550b-a55b
```

Matching is fuzzy: case, punctuation, hyphens, and whitespace are normalized,
and both reordered tokens ("Nemotron 3 Ultra") and squashed/concatenated
variants ("nemotron-ultra3") resolve to the same entry. Exit codes: `0` +
canonical slug on stdout for a match, `1` (no stdout) if nothing matches, `2`
on a usage error.

**Adding a new model alias when testing a new model:** append one line to
`openrouter-model-aliases.yml` in `alias: canonical-slug` format (get the
canonical slug from the OpenRouter models list), then add a matching
assertion in `test/model-alias.sh` and run `bash test/model-alias.sh` to
confirm it resolves. `test/model-alias.sh` is wired into `validate.sh`
alongside the other shim tests.

## Known OpenRouter edit-format quirks (GH-118)

Aider auto-detects an edit format per model, but many models proxied through
OpenRouter aren't in Aider's model-settings database, so Aider falls back to
the `whole` edit format — which some models don't reliably produce, causing
`aider-turn.sh` to report "aider turn produced no tracked changes" even
though the model's response was otherwise a valid review/fix.

Live-confirmed 2026-07-03 against two models with no entry in Aider's
`model-settings.yml`:

| Model | Symptom on default (`whole`) format | Fix |
|---|---|---|
| `openrouter/z-ai/glm-5.2` | Model chats instead of emitting an edit | `AIDER_FLAGS=--edit-format diff` |
| `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free` | Model emits a raw unified-diff hunk, unparseable by Aider | `AIDER_FLAGS=--edit-format diff` |

There is no dedicated `AIDER_EDIT_FORMAT` variable — `aider-turn.sh` already
exposes `AIDER_FLAGS` as a generic passthrough, so set
`AIDER_FLAGS=--edit-format diff` (or `--edit-format udiff`, per model) rather
than adding a new env var that would just shadow it. If you bring a new
OpenRouter model into a driven lane and see the "no tracked changes" failure,
try `--edit-format diff` first and add a row to the table above once
confirmed.
