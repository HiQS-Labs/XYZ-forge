# RELAY · Lane A — GH-73 fixed-/tmp-log docs (BUILD turn, agy)

NEXT: claude-a
STATUS: Open
ROUND: 1 / 1

## ▶ TAKE YOUR TURN — you are the BUILDER (agy). This is a BUILD turn (doc edit), not a review.
1. **Read this whole file.**
2. **Make the doc change below** by editing ONLY the allowed files. Do NOT edit any other file.
3. **Append ONE short block** at the bottom (above the marker) noting what you changed, per file.
4. Do NOT run git yourself; the harness commits your allowed files. Do NOT run the full `validate.sh`.

## BUILD BRIEF (GH-73 — issue #73)

**Problem:** The turn shims already default their transcript logs to per-PID paths (`...-$$.log`,
concurrency-safe). But the operator-facing DOCS pin FIXED log paths, which makes two concurrent
same-machine runs write the same file and clobber each other's transcript.

**Task:** In the docs below, make every transcript-log example concurrency-safe. For each occurrence of
a fixed `CODEX_LOG`/`AGY_LOG` value like `"${TMPDIR:-/tmp}/codex-turn.log"` or `/tmp/agy-turn.log`:
- EITHER change it to the per-PID form `"${TMPDIR:-/tmp}/codex-turn-$$.log"` /
  `"${TMPDIR:-/tmp}/agy-turn-$$.log"`,
- OR drop the explicit `CODEX_LOG=`/`AGY_LOG=` from the example entirely (the shims already default to
  a unique per-PID path).
Pick ONE approach and apply it consistently. Add a single short note near the first changed example
that fixed log paths break concurrent same-machine runs (prefer the shims' per-PID default).
Do NOT change any code or the shims — docs only. Keep all other prose intact.

**Allowed files (edit ONLY these):**
- `skills/relay-xyz/SKILL.md` (examples around the CODEX_LOG/AGY_LOG env, ~L113-116 and ~L136-157)
- `relay-automation/README.md` (the `/tmp/codex-turn.log` / `/tmp/agy-turn.log` mentions, ~L212-300)

**Acceptance:** no example in either file pins a fixed (non-`$$`) transcript path; prose otherwise
unchanged; `skill-extract` / `path-integrity` gates stay green.

## Log

### Builder — agy — 2026-07-01
- Edited `skills/relay-xyz/SKILL.md` to update all `CODEX_LOG` and `AGY_LOG` example values to use concurrency-safe per-PID paths (`...-$$.log`), and added a note warning that fixed log paths break concurrent same-machine runs.
- Edited `relay-automation/README.md` to update all `/tmp/codex-turn.log` and `/tmp/agy-turn.log` example occurrences to their per-PID forms, and added a corresponding note warning that fixed log paths break concurrent same-machine runs.

<!-- ↓↓↓ NEXT TURN goes here ↓↓↓ -->
