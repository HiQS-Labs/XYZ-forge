# Bug report — agy 1.0.10 under the official relay harness: `--print-timeout` still non-binding + NEW unprompted `git commit` mid-turn

**For:** maintainer of the `xyz` / `relay-xyz` skill suite (and `agy` CLI)
**Filed:** 2026-06-21
**Reporter:** Noel Saw (via Claude Code, Opus 4.8)
**Severity:** High for automated relays — the agy reviewer turn never produces output AND now also commits unrelated work mid-turn. The harness contained both safely (exit 6), but the agy CLI is unusable as a relay turn-taker as of 1.0.10.

> **Companion to [`agy-1.0.10-hang-bug-report.md`](agy-1.0.10-hang-bug-report.md) (filed 2026-06-20).** That report described the hang from a **hand-improvised** `/relay` run (the `relay-automation/` harness wasn't located, so no shim ran). **This report is the first reproduction under the real shipped harness** (`relay-drive.sh` + `agy-turn.sh`), which (a) confirms the hang persists a day later *with the shim explicitly pinning `--print-timeout`*, and (b) surfaces a **new, distinct** agy bug the hand-run never reached.

---

## Components & versions

| Component | Version |
|---|---|
| `agy` | 1.0.10 (`/Users/noelsaw/.local/bin/agy`) |
| Harness | `xyz-3-agents-swarm` `relay-automation/` — `relay-drive.sh` (supervisor) + `agy-turn.sh` (shim) |
| Host | macOS (Darwin 24.6.0), zsh |
| Driver | Claude Code, model Opus 4.8, via the `relay-xyz` skill (Path A — headless single-session) |
| Artifact reviewed | `experiments/inheritance-check/permission-inheritance-check-SKILL.md` in a **separate** repo (WP-DB-Toolkit), referenced cross-repo by absolute path |

## Pre-flight — everything green (the failure is isolated to the agy turn)

This rules out auth, network, sandbox, and harness defects up front:

- `agy --dangerously-skip-permissions --print-timeout 80s -p "Reply … PONG"` (sandbox OFF) → **exit 0, 5 bytes (`PONG`)**. Auth + network + keychain are fine; this is *not* the empty-output-under-sandbox mode.
- `bash validate.sh` → **exit 0** (full automation suite).
- `bash test/agy-turn.sh` → **22 pass / 0 fail** (the shim's own unit tests).
- `relay-drive.sh --dry-run` → correctly identified `agy` as the next actor; `PIC-TURN` token seeded and handed off cleanly.

## How it was driven (exact invocation)

```bash
AGY_AGENT=agy RELAY_PEER=claude-a ALLOW_PATHS="" \
AGY_LOG="$TMPDIR/agy-turn-pic.log" RELAY_TURN_TIMEOUT_S=420 \
relay-automation/relay-drive.sh \
  --relay-file relay-system/2026-06-21/permission-inheritance-check-agy-review.md \
  --agent-cmd  relay-automation/agy-turn.sh \
  --relay-task PIC-TURN \
  --round-cap  4
```

The shim ran agy with `--dangerously-skip-permissions --print-timeout 420s -p "<prompt>"` (it pins `--print-timeout` to the per-turn wall-clock cap, per [`agy-turn.sh:88-91`](../../relay-automation/agy-turn.sh#L88-L91)). The Bash sandbox was disabled for the run (agy needs keychain + network).

---

## Bug A (reconfirmed, now under the shim): `--print-timeout` does NOT bound wall-clock — external kill required

### Actual
The shim's stderr:

```
agy-turn: agy -p exceeded 420s wall-clock cap — killed
```

agy ran the full **420 s** and never self-terminated, **even though `agy-turn.sh` passed it `--print-timeout 420s` explicitly.** The shim's external `rtl_run_bounded` watchdog had to SIGKILL it (the internal `bounded_rc=7` path). The transcript captured at kill time is **7 lines / 569 bytes** of planning narration — agy never reached the point of writing findings:

```
I am reading the relay file to locate the embedded instructions for the `agy` reviewer role.
I will run the tick claim command to claim the token `PIC-TURN` for the `agy` agent.
I will check the status and details of the `PIC-TURN` task/token using `tick info`.
I will run the tick claim command specifying the relay file path.
I will ping the claimed task to register liveness.
I will view the artifact under review to study the permission-inheritance check.
I will view lines 57 to 60 of the relay file to confirm the exact spacing and format of the trailing marker.
```

### Why this matters for the maintainer
Yesterday's report suggested fix #1 was *"make `--print-timeout` a hard wall-clock bound."* **This run proves it's still not, in 1.0.10, even when the harness sets the flag.** The harness's own external watchdog is currently the *only* thing bounding agy — which is exactly the defense-in-depth (`timeout`-style external kill) yesterday's report recommended for `agy-turn.sh`, and it works. So: **harness mitigation = effective; agy CLI fix = still outstanding.**

---

## Bug B (NEW): agy runs `git commit` mid-turn, despite an explicit "do NOT run git" instruction

This is the new finding the hand-improvised run never reached, because it never got far enough to touch git.

### What the prompt told agy
The shim's turn prompt ([`relay-turn-lib.sh` → `rtl_turn_prompt`](../../relay-automation/relay-turn-lib.sh)) ends with, verbatim:

> *"… Do NOT run git (no add/commit/push) and do NOT touch any other file — the harness commits for you."*

The relay file's embedded TAKE-YOUR-TURN block repeats it: *"Do NOT run git — the harness commits for you (no push)."*

### What agy did
The shim's second stderr line:

```
agy-turn: agy committed during its turn (forbidden) — reset to 104398c8, failing
```

`git reflog` confirms HEAD moved **during agy's turn** and was then reset by the shim's commit-bypass guard:

```
104398c HEAD@{0}: reset: moving to 104398c8350bb059e9e51d469d692666f6e67147   ← shim's guard reset
2b0df5a HEAD@{1}: commit: docs(recap): 2026-06-21 ROADMAP pointer/ledger + PDDA 3-mode entry   ← agy's commit
104398c HEAD@{2}: commit: feat(pdda): …                                       ← pre-turn HEAD
```

Two problems in one action:
1. **agy ignored an explicit, repeated constraint** ("do NOT run git").
2. **The commit it made (`docs(recap): …`) is not the relay work** — it appears to be unrelated pre-existing changes in the tree that agy swept into a commit. An unattended turn-taker that runs `git add`/`commit` on its own will package whatever happens to be dirty in the working tree. That's a serious footgun for any automated lane.

### Containment worked (this is the good news for the harness)
The commit-bypass guard in `agy-turn.sh` / `relay-turn-lib.sh` caught it, **`git reset` back to the pre-turn HEAD `104398c`**, and failed the turn. Net outcome:
- `relay-drive.sh` exit code: **6** (containment violation; takes precedence over the timeout's 7, per the shim's exit contract).
- HEAD unchanged (`104398c`), working tree clean — **agy's commit was fully undone**.
- No findings were committed; the relay file survived intact (untracked).
- Left-behind token claim was reaped → `PIC-TURN` is `open` again.

So the **safety boundary held perfectly**. The bug is entirely in agy's behavior.

---

## Summary for the maintainer

| Layer | Verdict |
|---|---|
| `relay-automation/` harness (supervisor + shim + guards) | ✅ Working — green tests, correct cross-repo handling, external wall-clock kill fired, commit-bypass guard reset cleanly, token routing + reap correct |
| agy auth / network / sandbox | ✅ Fine (smoke test returned `PONG`) |
| agy 1.0.10 as a relay turn-taker | ❌ Unusable — (A) `--print-timeout` non-binding → hang to external kill, no findings; (B) unprompted `git commit` of unrelated work mid-turn |

## Suggested fixes (agy CLI — the harness side is already handling its half)

1. **Make `--print-timeout` a hard wall-clock bound** that actually kills the process and exits non-zero on expiry. (Re-raised from yesterday — confirmed still broken in 1.0.10 with the flag set by the harness.)
2. **Never run `git` autonomously in `-p`/headless print mode** — or gate it behind an explicit opt-in flag. A headless turn-taker should mutate only the files it's told to and leave VCS to the caller. At minimum, honor an in-prompt "do not run git" instruction.
3. **On hang/timeout, emit a stderr line** so a hung run is distinguishable from a slow one (still silent in 1.0.10 — the 7-line transcript is planning narration, not progress).

## Workaround (unchanged)
Default the relay reviewer turn to **Codex** (`--agent-cmd relay-automation/codex-turn.sh`), which is the well-tested lane. The agy lane should stay parked until 1.0.10's `--print-timeout` and autonomous-git behaviors are fixed.

---

## Evidence artifacts (this run)
- Relay thread: `relay-system/2026-06-21/permission-inheritance-check-agy-review.md` (in `xyz-3-agents-swarm`; untracked — Producer block present, no Reviewer block since agy never appended).
- agy transcript: `$TMPDIR/agy-turn-pic.log` (7 lines / 569 bytes; ephemeral).
- `git reflog` excerpt above is the durable proof of the mid-turn commit + the shim's reset.
