---
name: relay-xyz
description: >-
  Drive an automated /relay review loop on THIS repo with the shipped
  relay-automation harness (relay-drive.sh + codex-turn.sh / agy-turn.sh /
  poll.sh) rather than improvising the handoff by hand. Use when the operator
  wants to "run an automated relay", "have Codex (or agy) review this
  end-to-end", "drive a relay to completion headless", "run the relay harness",
  or set up the all-Claude hands-free poll loop — and the working tree is a
  clone of the xyz-3-agents-swarm repo (it ships relay-automation/). /relay
  scaffolds the thread and owns the turn protocol; relay-xyz is the repo-specific
  layer that runs the real scripts. NOT for scaffolding a thread from scratch
  (that is /relay), NOT for repos without relay-automation/.
---

# relay-xyz — automated relays on the shipped harness

This repo **already ships** the relay automation. Don't reinvent the CLI handoff turn by turn — call
the scripts under [`relay-automation/`](../../relay-automation/). `/relay` defines the thread format
and turn protocol and scaffolds the dated file; **`relay-xyz` is the thin repo-specific layer that
drives that thread to completion with the shipped supervisor + turn-takers.**

Use `/relay` to *create* the thread (or reuse one under `relay-system/<date>/`), then `relay-xyz` to
*run* it headless or hands-free.

## When to use

- "Run an automated relay" / "drive this relay to completion" / "run the relay harness."
- "Have Codex review `<file>` end-to-end" / "let agy take the reviewer turns."
- Setting up the all-Claude hands-free `/loop` poll so two Claude windows self-serialize.
- You have a relay thread (or are about to scaffold one with `/relay`) **and** the working tree is a
  clone of this repo.

**Not** for: scaffolding a brand-new thread from scratch (that's `/relay`), repos that don't ship
`relay-automation/`, or work that needs a human checkpoint between every turn (use plain `/relay`
manual mode).

## First-time setup on a new clone or machine (make the skill discoverable)

This repo keeps its skills in top-level `skills/`, which Claude Code does **not** scan. A session
finds `relay-xyz` only if it's symlinked into `~/.claude/skills/`. A fresh clone or second machine has
no such symlink, so the skill is invisible in **every** session there — the "other VS Code sessions
can't find the relay-xyz files" failure. Fix it **once per clone** (idempotent, self-locating, no
hardcoded path):

```bash
bash skills/relay-xyz/install.sh   # symlinks this clone's skills/relay-xyz into ~/.claude/skills/
```

It also replaces a stale/dangling symlink and verifies `find-harness.sh` resolves the harness. The
locator below handles *where the harness scripts live*; this step handles *whether Claude Code can
load the skill at all* — a layer the locator can't reach, since it runs only after the skill loads.

## Preconditions — locate the harness (bundled locator, never hardcode a path)

`relay-xyz` ships its own device-agnostic locator, [`find-harness.sh`](find-harness.sh), beside this
skill. It resolves the harness repo (the clone that ships `relay-automation/`) **relative to its own
installed location**, following symlinks — so it works from *any* working directory, including a clone
that has only `relay-system/` thread storage (from `/relay`) but **not** the harness scripts. `$HOME`
and the skill's own symlink are the only anchors; **no machine path is ever hardcoded.** That's what
keeps relay-xyz from "complaining the harness isn't in this repo" when you launch it from a clone
without `relay-automation/` + `bin/tick`.

Run this first. It finds the locator, exports the harness env, `cd`s into the clone that ships the
harness, and prints a one-glance readiness line:

```bash
# Find the bundled locator. The skill installs at one of these — all anchored on $HOME or
# the CWD, never an absolute machine path:
for L in "${XYZ_HARNESS:+$XYZ_HARNESS/skills/relay-xyz/find-harness.sh}" \
         "$HOME/.claude/skills/relay-xyz/find-harness.sh" \
         "./.claude/skills/relay-xyz/find-harness.sh" \
         "$(git rev-parse --show-toplevel 2>/dev/null)/skills/relay-xyz/find-harness.sh"; do
  [ -n "$L" ] && [ -x "$L" ] && break
done
[ -x "$L" ] || { echo "relay-xyz: locator not found — set XYZ_HARNESS to your xyz-3-agents-swarm clone"; exit 1; }

eval "$("$L" --env)"   # exports HARNESS, TICK, TICK_REPO_ROOT, RELAY_HAS_{TICK,CODEX,AGY}
cd "$HARNESS"
"$L" --check           # prints: harness path + which reviewers (codex/agy/tick) are on PATH
```

After this, `$HARNESS` is the harness repo root, `$TICK` is the absolute `bin/tick`, and
`TICK_REPO_ROOT` points `tick` at that clone's event log. The relay/turn scripts self-resolve their
own location (`$(dirname "$BASH_SOURCE")/..`), so invoke them with **repo-relative** paths exactly as
the [headless Codex bring-up section](../../relay-automation/README.md#headless-codex-bring-up) shows.
The relay always operates on **the
harness clone** (its `.tick/` log and guarded git root live there), whatever repo you launched from —
so a clone with only `relay-system/` thread files still drives the real harness next door.

## The two automated paths

| Path | One session? | Models | Driver |
|---|---|---|---|
| **A. Headless single-session** | yes — Claude drives both roles | Codex / agy as the reviewer subprocess | `relay-drive.sh` + a turn-taker shim |
| **B. Hands-free poll** | no — two live Claude windows | all-Claude | `poll.sh` under `/loop` in each window |

Path A is the marquee flow — what "have Codex review this for me" means. Path B is the all-Claude
self-serializing loop: no human nudge, no second model.

### Path A — headless single-session (relay-drive.sh + a shim)

`relay-drive.sh` is the **supervisor** (round cap, no-progress escalation, reads the file's `STATUS:`
as the terminal signal). The **turn-taker** is `--agent-cmd` — a shipped shim (`codex-turn.sh` or
`agy-turn.sh`) that owns the safety boundary: path-allowlist, commit-bypass guard, **no push**.
Whose-turn is a `tick` relay task, handed off with `tick release --to`.

End-to-end Codex review of an artifact (run after Preconditions — `$TICK` and `$HARNESS` set, CWD is
the harness clone). Confirm `$RELAY_HAS_CODEX` is `1`:

```bash
# 0. The reviewer you want must be on PATH (set by the locator).
[ "$RELAY_HAS_CODEX" = 1 ] || { echo "codex not on PATH — use agy or Path B"; exit 1; }

# 1. Have a relay thread with an embedded "▶ TAKE YOUR TURN" block.
#    Reuse one under relay-system/<date>/, or scaffold a fresh thread with /relay first.
RELAY=relay-system/<date>/<slug>.md
ARTIFACT=<repo-relative-path-the-turn-reviews>     # e.g. skills/relay-xyz/SKILL.md
TASK="RELAY-$(basename "$RELAY" .md)"              # use a per-relay id, not literal RELAY-TURN

# 2. Seed the relay task and hand the first turn to the Codex agent.
"$TICK" log     task.created "$TASK" --agent claude-a
"$TICK" claim   "$TASK" --agent claude-a --paths "$ARTIFACT"
"$TICK" release "$TASK" --agent claude-a --to codex

# 3. Drive it. The shim dispatches ONLY when the token's actor == CODEX_AGENT.
CODEX_AGENT=codex ALLOW_PATHS="$ARTIFACT" CODEX_LOG="${TMPDIR:-/tmp}/codex-turn.log" \
relay-automation/relay-drive.sh \
  --relay-file "$RELAY" \
  --relay-task "$TASK" \
  --agent-cmd  relay-automation/codex-turn.sh \
  --round-cap  4
```

Swap `agy-turn.sh` + `AGY_AGENT=...` to use agy (a multi-model gateway) as the reviewer instead
(guard on `$RELAY_HAS_AGY` the same way). `$TICK` is absolute, so these work even if CWD drifts.

**Important — run the shim OUTSIDE the Bash sandbox.** When *you* (Claude Code) drive this, the
`codex` / `agy` subprocess needs the OS keychain + outbound network to authenticate. Claude Code's
Bash sandbox blocks both: `codex` errors (looks like a keychain/login fault, but it's the sandbox),
and `agy -p` **fails silently — exit 0, empty output** (the shim catches this and exits 5, but only
un-sandboxed). Run these Bash calls with `dangerouslyDisableSandbox: true`. (Memory:
`codex-cli-needs-sandbox-disabled`, `agy-antigravity-cli`.)

### Path B — hands-free poll (all-Claude, two windows)

In each Claude window, run a guarded `/loop` that uses `poll.sh` as the gate, then take the turn from
the relay file's embedded instructions. The token *is* the lock — a window acts only when the token is
claimable by its agent **and** the artifact scope is clean.

Each window is its own shell, so run Preconditions in each one (or `cd` into the `find-harness.sh
--root` output) before the loop — the `relay-automation/` paths below are relative to `$HARNESS`.

```
# In each window (set --agent to that window's id). --claude-agents lists EVERY Claude id in
# the relay so the poller knows whose turns can self-poll vs. which need a cross-model nudge:
/loop 60s run relay-automation/poll.sh --mode relay --agent <claude-a|claude-b> \
  --claude-agents "claude-a,claude-b" \
  --relay-file relay-system/<date>/<slug>.md --artifact <path> \
  --deadline "$(date -v+30M +%s)" --dry-run ;\
  if it prints "DECISION: run-runner", take your turn on that relay file per its embedded \
  instructions (review/produce, append your block, `tick release RELAY-TURN --to <other>` or \
  `tick done` on approve, commit); on "DECISION: stop" CronList+CronDelete this job; else do nothing.
```

`--claude-agents` is load-bearing: a turn belonging to an agent **not** in this list yields
`DECISION: nudge-cross-model` (a one-line "take your turn" for the human to relay to a non-Claude
window), not `idle`. List both Claude ids and Path B stays fully hands-free; omit one and that
window's turns surface as a manual nudge. `60s` keeps the prompt cache warm; the lock/heartbeat is the
real correctness guard, not the timer. Always set a `--deadline` so the loop self-closes — cron jobs
are per-session, and you can't stop another window's loop from yours. `poll.sh` exits `10` on a closed
relay (`STATUS: Approved|Closed`); see `/relay` → "Self-closing loops". Optionally run **one** extra
window with `--watchdog-authority` (longer interval, e.g. `120s`) so a stalled turn escalates exactly
once.

## Turn-taker shims & their env

Both shims are thin dispatchers over `relay-turn-lib.sh` (the model-agnostic containment core), so
they share the same env shape:

| Env | `codex-turn.sh` | `agy-turn.sh` | Meaning |
|---|---|---|---|
| dispatch gate | `CODEX_AGENT` | `AGY_AGENT` | NO-OPS unless `RELAY_AGENT == this` |
| extra writable paths | `ALLOW_PATHS` | `ALLOW_PATHS` | comma-sep git paths the turn may change (the relay file is always allowed) |
| peer id | `RELAY_PEER` | `RELAY_PEER` | so the turn hands off `--to <peer>` (else "the other agent") |
| binary | `CODEX_BIN` | `AGY_BIN` | override the CLI path |
| autonomy | `CODEX_FLAGS` (default `-s workspace-write`) | `AGY_MODEL` / `AGY_FLAGS` | the codex sandbox/approval flags or the agy model |
| transcript | `CODEX_LOG` | `AGY_LOG` | where the CLI transcript lands (default a `$TMPDIR` file) |
| turn ceiling | `RELAY_TURN_TIMEOUT_S` | `RELAY_TURN_TIMEOUT_S` | per-turn wall-clock cap (default 300s; hung CLI → exit 7) |

If a fresh device's `codex` still blocks writes, escalate autonomy:
`CODEX_FLAGS='--dangerously-bypass-approvals-and-sandbox'` (or `-c approval_policy=never`).

## Exit codes

- **`relay-drive.sh`**: `0` closed Approved/Closed · `3` no-progress (token actor didn't move) ·
  `4` round-cap / closed-not-approved · `2` usage.
- **shims** (`codex-turn.sh` / `agy-turn.sh`): `0` acted or deferred · `5` CLI failed (or agy empty
  output) · `6` off-allowlist edit reverted (or committed mid-turn → reset) · `7` timeout-killed · `2` usage.
- **`poll.sh`**: `10` relay closed (stop the loop); on stdout one of
  `DECISION: run-runner | run-watchdog | nudge-cross-model | stop | idle`
  (`nudge-cross-model` = turn belongs to an agent not in `--claude-agents`; relay it as a manual nudge).

## Safety boundary (what the shim guarantees)

The shim is the containment contract, so an unattended turn can't run away: **path-allowlist**
(anything off `RELAY_FILE` + `ALLOW_PATHS` is reverted, exit 6), **commit-bypass guard** (if the CLI
commits mid-turn, the shim resets and re-commits file-scoped), and **no push** (turns commit locally
only — `git push` yourself when ready). `.tick/` is gitignored and per-device, so this is single-clone
coordination, not cross-machine.

**Worktree isolation is ON by default for driven runs.** `relay-drive.sh` exports
`RELAY_WORKTREE_ISOLATION=1`, so each turn-taker runs in a throwaway `git worktree` of `ROOT@HEAD` —
an off-task model's stray *creations/renames* (not just tracked edits) can't reach the real tree,
closing the gap where the allowlist only reverted named tracked files. Opt out per run with
`RELAY_WORKTREE_ISOLATION=0`; direct/attended shim use keeps the leaf default OFF. Also: `--agent-cmd`
runs a bare executable path directly, so an **absolute path with spaces** (a clone under
`…/GH Repos/…`) is safe — no quoting needed.

## Verify the harness is green before a real run

These are anchored on `$HARNESS` (set by Preconditions) so they resolve whatever your CWD is — don't
drop the `$HARNESS/` prefix or they'll 404 from a foreign session:

```bash
bash "$HARNESS/validate.sh"            # the tick/automation suite
bash "$HARNESS/test/codex-turn.sh"     # the Codex shim's tests   (before a Codex run)
bash "$HARNESS/test/agy-turn.sh"       # the agy shim's tests      (before an agy run)
```

Run the shim test matching the reviewer you'll drive (both are first-class). Run these un-sandboxed —
`mktemp`/network under the Bash sandbox can fail them for reasons unrelated to the code.

## Relationship to the other skills

- **`/relay`** — portable, dependency-free. Owns the thread template, turn block formats, evidence
  contract, and guardrails. **Use it to scaffold the thread**; relay-xyz never redefines the protocol,
  only runs it.
- **`/xyz`** — concurrent, non-overlapping path-scoped lanes (parallel *builds*), also `tick`-backed.
  A relay is sequential review (one writer, turn-based); `xyz` is parallel construction. Different
  shapes.
- **`consult.sh`** — `relay-automation/consult.sh` asks one question of Codex *and* agy in parallel,
  captures both transcripts, leaves synthesis to you. Advisory-only, read-only, **not** a relay turn —
  reach for it when you want a second opinion without a review loop.

## Framing

Open with a human sentence ("Driving a headless Codex review of `<artifact>` — round cap 4…") and
close with the result + exit code. The structured thread lives in the relay file; the operator gets a
sentence and a verdict, not a wall of transcript.
