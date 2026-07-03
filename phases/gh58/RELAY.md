# Marathon Phase gh58
STATUS: Open
NEXT: agy

<!-- marathon-drive: task=MARATHON-GH58-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Phase brief — GH-58: claude-turn.sh CLAUDE_BIN discovery + fail-fast

## Goal
Fix `relay-automation/claude-turn.sh` so `marathon --builder claude` no longer dies with a raw
`exec: claude: not found` when `claude` is not on `PATH`. Add PATH discovery + a clear fail-fast.

## Current bug
`claude-turn.sh` sets `CLAUDE_BIN="${CLAUDE_BIN:-claude}"` then `exec`s it with **no PATH discovery
and no fail-fast** — headless, an unresolved `claude` dies with a raw `exec: not found` (mislabeled
downstream as a generic builder failure). codex/agy resolve their binaries; claude does not.

## Fix (both halves — GP #7 least-code + #8 honest)
1. **Discovery:** resolve `CLAUDE_BIN` robustly — check `PATH` first (`command -v claude`), then the
   known install location `~/.claude/local/claude`. Keep it a small ordered probe.
2. **Fail-fast:** when unresolvable, exit with a **distinct non-zero code** and a clear message —
   `claude CLI not found on PATH; set CLAUDE_BIN or use a codex/agy builder` — instead of a raw
   `exec: not found`.
3. **Unchanged when resolvable:** if `claude` (or an explicit `CLAUDE_BIN`) resolves, behavior is
   exactly as today.
Add a `# GH-58` marker comment.

## New test (the gate)
Create `test/claude-turn.sh` (mirror the structure of `test/codex-turn.sh`):
- With a stubbed/empty PATH and no `~/.claude/local/claude`, assert the shim fails fast with the clear
  message + the distinct exit code (NOT a raw `exec: not found`).
- With a stub `CLAUDE_BIN` that resolves, assert the shim dispatches normally (no false failure).
Wire `test/claude-turn.sh` into `validate.sh`'s `TESTS=( … )` array.

## Scope lock (ALLOW_PATHS)
Edit/create ONLY: `relay-automation/claude-turn.sh`, `test/claude-turn.sh`, `validate.sh` (the one
TESTS[] line). Do NOT touch the kernel (`relay-turn-lib.sh` / `bin/tick` / `relay-drive.sh`),
`codex-turn.sh`, or `agy-turn.sh`.

## Definition of done (gate)
- `bash test/claude-turn.sh` passes (fail-fast path + resolvable path).
- `claude-turn.sh` unchanged behavior when `claude`/`CLAUDE_BIN` resolves.
- No raw `exec: claude: not found` — a clear message + distinct exit code instead.

Contract of record: `PROJECT/1-INBOX/GH-58-CLAUDE-TURN-PATH-DISCOVERY.md`.
Note: this lane is built by agy (NOT `--builder claude` — the very path it fixes).

---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/claude-turn.sh,test/claude-turn.sh,validate.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH58-TURN --agent agy --paths "phases/gh58/RELAY.md,relay-automation/claude-turn.sh,test/claude-turn.sh,validate.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH58-TURN --agent agy
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH58-TURN --agent agy --to codex
4. Edit ONLY these paths: phases/gh58/RELAY.md and relay-automation/claude-turn.sh,test/claude-turn.sh,validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/claude-turn.sh,test/claude-turn.sh,validate.sh.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH58-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH58-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh58/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · agy

- **Files touched:**
  - [claude-turn.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/relay-automation/claude-turn.sh)
  - [claude-turn.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/test/claude-turn.sh) (test suite)
  - [validate.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/validate.sh)
  - [RELAY.md](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/phases/gh58/RELAY.md)
- **Key decisions & implementation:**
  - Implemented dynamic discovery of the `claude` CLI: check `PATH` via `command -v`, then probe `$HOME/.claude/local/claude`.
  - Implemented a clear fail-fast exit if `claude` is unresolvable: exit with distinct non-zero code `3` and print a clear error message `claude CLI not found on PATH; set CLAUDE_BIN or use a codex/agy builder` to stderr.
  - Added new test cases (10, 11, 12) to `test/claude-turn.sh` covering missing binary (exit 3 + message validation), local `~/.claude/local/claude` resolution, and explicit `CLAUDE_BIN` override.
  - Sourced `test/_setup.sh` and cleaned environment variables to protect the test run from ambient runner environment leakage.
  - Touched `validate.sh` with a tracking issue comment.
- **Verification:** Ran `bash test/claude-turn.sh` which succeeded with 30 passes (0 failures).
