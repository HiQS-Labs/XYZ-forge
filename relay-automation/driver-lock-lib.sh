#!/usr/bin/env bash
# driver-lock-lib.sh — GH-448: the ONE shared resolver for the relay-driver lock path.
#
# Mirrors the DRIVER's own write-side resolution (marathon_drive.py / marathon-drive.sh,
# relay_drive.py / relay-drive.sh) byte-for-byte (utils/py/rtl.py's driver_lock_path is the Python
# twin — the two MUST agree, asserted by test/gh448-driver-lock-resolver.sh). SOURCED by every
# read-only consumer of the lock (marathon-ls.sh, utils/hq/marathon-live.sh,
# skills/relay-xyz/find-harness.sh) — a consumer that constructs this path inline instead of calling
# this function is the bug this file exists to kill (5 of 7 construction sites had drifted to a
# 2-branch guess that misses the linked-worktree case, silently reporting a LIVE marathon as IDLE).
#
#   .git is a directory  -> <repo>/.git/relay-driver.lock              (normal clone)
#   .git is a file       -> <git-common-dir>/relay-driver.lock         (linked worktree)
#   no .git (vendored)   -> <repo>/.relay-driver.lock                  (vendored .xyz/ copy)
#
# API:
#   driver_lock_path_for_repo <repo-root>   — prints the resolved lock path (no trailing newline)
set -u

driver_lock_path_for_repo() {
  local repo="$1"
  if [ -d "$repo/.git" ]; then
    printf '%s/.git/relay-driver.lock' "$repo"
    return 0
  fi
  if [ -f "$repo/.git" ]; then
    local common
    common="$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
    if [ -n "$common" ]; then
      printf '%s/relay-driver.lock' "$common"
      return 0
    fi
  fi
  printf '%s/.relay-driver.lock' "$repo"
}
