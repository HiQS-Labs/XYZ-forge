# Bug report — agy 1.0.10 `-p` hangs indefinitely; relay-xyz harness unavailable outside its home repo

**For:** maintainer of the `xyz` / `relay-xyz` skill suite (and `agy` CLI)
**Filed:** 2026-06-20
**Reporter:** Noel Saw (via Claude Code, Opus 4.8)
**Severity:** High for automated relays — the agy reviewer turn never completes and there is no self-recovery; a hard kill + tool fallback was required by hand.

> Note: this file is a standalone deliverable parked next to the evidence. It is **not** a rebalance-OS doc and should not be committed to that repo — move/send it as needed.

---

## Components & versions

| Component | Version |
|---|---|
| `agy` | 1.0.10 (`/Users/noelsaw/.local/bin/agy`) |
| `codex` (fallback that worked) | codex-cli 0.139.0 |
| Host | macOS (Darwin 24.6.0), zsh |
| Driver | Claude Code, model Opus 4.8, via the portable `/relay` skill's **CLI-driven (agy)** mode |
| Target repo | `rebalance-OS` (`/Users/noelsaw/Documents/rebalance-OS`) |

## Environment / how this was reached

The operator asked for an **automated `relay-xyz` with the agy CLI** to review a planning doc. Two things combined:

1. **`relay-xyz` was not usable here.** The `relay-xyz` skill drives the shipped `relay-automation/` harness (`relay-drive.sh`, `agy-turn.sh`, `codex-turn.sh`, `poll.sh`), which ships **only in the `xyz-3-agents-swarm` repo**. In `rebalance-OS` that directory is **absent**:
   ```
   $ ls relay-automation/        # in rebalance-OS
   ABSENT in this repo
   ```
   So none of the harness scripts ran. The request degraded to a **hand-improvised** CLI-driven relay using the portable `/relay` skill's documented agy path.

2. **agy itself then hung** during the improvised reviewer turn (the primary bug below).

---

## Bug A (primary): `agy -p` hangs well past `--print-timeout`, with no output and no error

### Repro

The reviewer turn was invoked exactly as the `/relay` skill's "CLI-driven handoff (agy)" section prescribes — sandbox disabled (Claude Code Bash sandbox off, as the skill requires for agy network/keychain), a **Go-duration** timeout, stderr captured, output asserted non-empty:

```bash
RESULT=$(agy -p "$(cat /tmp/claude/agy_full_prompt.md)" --print-timeout 4m 2>/tmp/claude/agy_err.log)
echo "$RESULT" > /tmp/claude/agy_reviewer_block.md
if [ -z "$RESULT" ]; then echo "ERROR: agy empty — sandbox or auth issue"; fi
```

- The prompt (`agy_full_prompt.md`) was ~42 KB: reviewer instructions + the relay thread + the full plan doc.
- Run as a Claude Code **background task** (id `bfgincbp2`).

### Expected
agy returns a reviewer block within `--print-timeout 4m`, **or self-terminates at 4m** and exits (empty result → the `-z "$RESULT"` guard fires).

### Actual
- agy ran **~10 minutes** — more than 2× its own `--print-timeout 4m` — and **never self-terminated**. The process (`agy -p …`, PID 93640) stayed alive doing nothing.
- **0 bytes of output**: `agy_reviewer_block.md` was never written; the background task's output file stayed 0 bytes.
- **0 bytes of stderr**: `agy_err.log` was empty — no error, no progress, no diagnostic.
- It only stopped when **manually killed** (`SIGTERM` → exit code 144). The background task then reported `failed (exit 144)`.

So `--print-timeout` did **not** bound wall-clock runtime, and the hang produced no signal at all (silent).

### Not a prompt/size or auth problem
The **same ~42 KB prompt** was immediately handed to `codex exec -s read-only` and returned a complete, correct review in **~2 minutes**. So the input, size, and task were fine — the failure is agy-specific.

### Relation to the already-documented agy gotcha
The `/relay` skill already warns of a *different* agy failure: "`agy -p` exits 0 with **empty** output when its backend network is blocked … a sandboxed call reads as a successful empty turn." That one is handled by the `-z "$RESULT"` assertion. **This report is a distinct, worse mode:** agy neither exited nor produced output — it hung past its own timeout. The `-z` guard can't catch a process that never returns.

---

## Bug B (harness gap): `relay-xyz` silently has no effect outside `xyz-3-agents-swarm`

When `relay-xyz` is requested in a repo that lacks `relay-automation/`, there is no harness to run and no graceful, operator-visible fallback — the driver must hand-roll the entire loop (prompt assembly, subprocess invocation, output capture, block append, header flip, commit). The skill description says it's "NOT for repos without relay-automation/," but in practice the operator's "do a relay-xyz with agy" request just quietly becomes a manual improvisation. A detect-and-redirect ("no relay-automation/ here → use portable /relay") would make the degradation explicit.

---

## Improvised artifacts (paths)

Because the `relay-xyz` harness was absent, I did **not** run `agy-turn.sh` / `relay-drive.sh` / `poll.sh`. There were **no standalone shell scripts** — the "scripts" were **inline Bash invocations plus prompt/IO text files**. For the maintainer's reference, everything I generated:

**agy attempt (the hang):**
- Inline invocation: the `agy -p … --print-timeout 4m` background command shown above (Claude Code task `bfgincbp2`).
- `/tmp/claude/agy_reviewer_prompt.md` — reviewer instruction header I wrote (2.4 KB).
- `/tmp/claude/agy_full_prompt.md` — assembled header + relay thread + plan doc, fed to agy (42 KB).
- `/tmp/claude/agy_reviewer_block.md` — intended output target; **never written** (agy produced nothing).
- `/tmp/claude/agy_err.log` — stderr capture; **0 bytes**.
- `/private/tmp/claude-501/-Users-noelsaw-Documents-rebalance-OS/a5df2164-091d-44cd-b7a8-58e6305bcd1c/tasks/bfgincbp2.output` — background-task stdout; **0 bytes**.

**Codex fallback (worked, same task):**
- `/tmp/claude/codex_rescope_header.md` — reviewer header (Codex variant).
- `/tmp/claude/codex_rescope_prompt.md` — assembled prompt (42 KB).
- `/tmp/claude/codex_rescope_block.md` — the review Codex produced (3.7 KB).
- `/tmp/claude/codex_rescope_run.log` — Codex run log.

**Relay thread (in-repo, durable):**
- `relay-system/2026-06-20/auth-storage-rescope.md` — the shared relay file; its `Setup` block records "agy CLI (agy 1.0.10) — hung past its `--print-timeout 4m`, killed; fell back to Codex CLI 0.139.0", and the Round-1 Reviewer block is Codex's.

> `/tmp/claude/...` is the Claude Code sandbox temp dir and is ephemeral — these may be GC'd. The relay thread under `relay-system/` is the durable record.

---

## Suggested fixes

**agy CLI:**
1. Make `--print-timeout` a **hard wall-clock bound** that actually kills the process and exits non-zero (or empty) on expiry. Today it did not terminate at 4m.
2. On hang/timeout, emit **something to stderr** (even one line) so a hung run is distinguishable from a slow one and from the empty-sandbox case.

**relay-automation / `agy-turn.sh` (if/when run for real):**
3. Wrap the agy call in an **external** hard kill independent of agy's own flag, e.g. `timeout --kill-after=10s 4m agy -p …` (GNU coreutils `timeout`), and treat a kill as a failed turn.
4. Keep the existing non-empty-output assertion **and** add a "did the process exit?" check — the `-z "$RESULT"` guard alone cannot catch a never-returning process.
5. Surface a clear, distinct message for each agy failure mode: `hung (killed at <t>)` vs `empty (sandbox/auth)`.

**relay-xyz skill:**
6. When invoked in a repo without `relay-automation/`, detect it and either (a) tell the operator to use the portable `/relay` CLI-driven mode, or (b) ship `relay-automation/` as an installable so the harness works cross-repo.

## Workaround that worked
Kill the hung agy process, then run the identical prompt through `codex exec -s read-only -C <repo> -o <out> -` (with the Bash sandbox disabled for keychain/network). Codex returned a complete reviewer block in ~2 minutes. Defaulting the reviewer turn to Codex is the current reliable path here.
