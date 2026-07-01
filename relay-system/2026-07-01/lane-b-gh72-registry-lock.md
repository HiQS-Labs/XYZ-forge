# RELAY · Lane B — GH-72 registry/projection write-lock (BUILD turn, codex)

NEXT: codex
STATUS: Open
ROUND: 1 / 1

## ▶ TAKE YOUR TURN — you are the BUILDER (codex). This is a BUILD turn, not a review.
1. **Read this whole file.**
2. **Implement the change below** by editing ONLY the allowed files. Do NOT edit any other file.
3. **Append ONE short block** at the bottom (above the marker) noting what you changed, per file.
4. Do NOT run git yourself; the harness commits your allowed files. Do NOT run the full `validate.sh`.

## BUILD BRIEF (GH-72 — issue #72)

**Problem:** `~/.config/xyz/registry.tsv` and the git-pulse projection are updated with an UNLOCKED
read-modify-write (read into `"$reg.tmp.$$"`, then `mv` back). Two concurrent `xyz-vendor.sh` /
`install.sh` operations on the same machine can interleave and lose a writer's row (last `mv` wins).

**Task:** Add a small **per-user advisory lock** around each registry/projection read-modify-write so
concurrent writers serialize instead of clobbering. Requirements:
- Use a portable `mkdir`-based lock (atomic) beside the registry, e.g. `~/.config/xyz/registry.lock`
  (resolve the same dir the registry uses — do NOT hardcode `$HOME` if the code already computes a
  config dir). Acquire before the read, release (rmdir) after the `mv`, and on EXIT (trap) so a crash
  can't deadlock.
- **Fail-open:** if the lock can't be acquired within a short bounded wait (e.g. ~5s / a few retries),
  reclaim a stale lock or proceed anyway with a warning — NEVER hard-fail the vendor/install on lock
  contention. Match the fail-open spirit of the existing relay driver lock.
- Keep the TSV schema and row format byte-identical. No behavior change when there is no contention.
- Apply to BOTH registry writers and the projection writer.

**Allowed files (edit ONLY these):**
- `relay-automation/xyz-vendor.sh` (registry write ~L98-131)
- `install.sh` (registry ~L144-183; git-pulse projection ~L112-140)

**Acceptance (the harness/orchestrator will verify after):** concurrent writers never lose a row;
lock is fail-open + stale-reclaiming; existing tests stay green. If a helper function is cleaner than
inlining the lock in three places, define it once and call it (DRY).

## Log

<!-- ↓↓↓ NEXT TURN goes here ↓↓↓ -->
