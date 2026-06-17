# QUICKSTART — fresh-device bring-up for headless Codex relay turns

Status: **Current bring-up guide.** This gets a fresh device or fresh clone to the
point where it can run a **headless Codex relay turn** (`codex-turn.sh` via
`relay-drive.sh`). [README.md](README.md) is the canonical operator contract for
relay-automation; this doc is only the device/bootstrap path for the current
headless Codex flow. See [CROSSMODEL-OPTIONA-PLAN.md](CROSSMODEL-OPTIONA-PLAN.md)
for design.

> **Read this first — what a single-device test does and doesn't prove.**
> `.tick/` (the coordination event log) is **gitignored = per-device local**. Two clones do
> **not** share token state over git, so this is *not* a cross-machine coordination test. What
> it proves on the second device is: **"a headless Codex turn-taker runs cleanly in a fresh
> clone behind the safety shim."** Real cross-device coordination needs the out-of-band `.tick/`
> sync that's still on the backlog.

---

## 1. Prerequisites (check each — all three are assumed by the scripts)

```bash
node --version                                   # bin/tick is Node
codex exec -s workspace-write "create a file ok.txt with the text ok" < /dev/null  # must actually WRITE
git --version
```
**Autonomy check matters (MBP16 [3]):** a bare `codex exec "say ok"` returns fine but writes nothing,
so it does *not* prove the turn-taker can edit the relay file. `codex-turn.sh` defaults to
`-s workspace-write`; if a fresh device's `~/.codex/config.toml` still blocks writes, set
`CODEX_FLAGS='--dangerously-bypass-approvals-and-sandbox'` (or add `-c approval_policy=never`).
If `codex` isn't on PATH or isn't authed, fix that first — the shim shells out to it
(override the binary with `CODEX_BIN=/path/to/codex`).

## 2. Clone / pull

```bash
git clone https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm.git
cd xyz-3-agents-swarm
# (or, in an existing clone)  git pull origin main
export TICK_REPO_ROOT="$PWD"        # point tick at this clone root
```

## 3. Smoke test — prove the suite is green here

```bash
bash validate.sh                    # expect: green; currently passed: 23 / 23
bash test/codex-turn.sh             # expect: green; currently 24 pass, 0 fail
```
If `validate.sh` can't make tempdirs, it's usually a sandbox blocking `mktemp` — run it in a
normal shell. Green here = the shim + guards behave on this machine.

## 4. End-to-end — one headless Codex turn behind the shim

The supervisor (`relay-drive.sh`) drives the turn; the shim (`codex-turn.sh`) **is** the
turn-taker and owns the safety boundary (path-allowlist, commit-bypass guard, **no push**).

```bash
# a) a relay thread with embedded ▶ TAKE YOUR TURN instructions + a RELAY-TURN token.
#    Reuse an existing one under relay-system/<date>/, or scaffold a fresh /relay thread.
RELAY=relay-system/2026-06-15/<your-slug>.md
ARTIFACT=relay-automation/codex-turn.sh        # whatever the turn reviews/edits

# b) seed the RELAY-TURN token and hand it to the Codex agent
./bin/tick log task.created RELAY-TURN --agent claude-a
./bin/tick claim   RELAY-TURN --agent claude-a --paths "$ARTIFACT"
./bin/tick release RELAY-TURN --agent claude-a --to codex

# c) run the supervisor; the shim dispatches ONLY because the actor is the Codex agent
CODEX_AGENT=codex ALLOW_PATHS="$ARTIFACT" CODEX_LOG=/tmp/codex-turn.log \
relay-automation/relay-drive.sh \
  --relay-file "$RELAY" \
  --agent-cmd  relay-automation/codex-turn.sh \
  --round-cap  4
```

What to expect: Codex takes the turn (claims/pings the token, appends its block to `$RELAY`,
releases or `done`s the token), then the shim **reverts anything off the allowlist**, commits
**only** the allowlisted paths **file-scoped**, and **does not push**. Transcript lands in
`/tmp/codex-turn.log`.

**Exit codes** — `relay-drive`: `0` closed Approved/Closed · `3` no-progress · `4` round-cap /
closed-not-approved · `2` usage.  `codex-turn` (shim): `0` acted/deferred · `5` codex failed ·
`6` off-allowlist edit reverted (or Codex committed mid-turn → reset) · `2` usage.

## 5. WIP caveats for this device

- **No push by design.** Turns the shim takes commit locally only — `git push origin main`
  yourself when you want them upstream.
- **`.tick/` is local.** Token state on this device is independent of the other machine.
- **Each Codex turn is real API spend** (tens of k tokens for a substantive review) — keep
  `--round-cap` small.
- **Single window for headless.** Don't also run a live `/loop` as the same agent id on the
  same relay — the token is the lock, but two takers of the *same* id will thrash.

---
*Updated 2026-06-17. Tracks `codex-turn.sh` + `relay-drive.sh` as shipped; update if their
flags or expected suite counts change.*
