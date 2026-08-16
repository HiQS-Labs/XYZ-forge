#!/usr/bin/env bash
# fixture-guard.sh — shared, sourceable require_fixture (GH-1, hardening the GH-564 guard).
#
# Sourcing file: call `fixture_guard_init "$WORK"` once after creating the sandbox root, then call
# `require_fixture <path> [label]` before every dangerous use of a derived fixture path — at the
# USE boundary, in every function that receives the path, not only where it was created (GH-567).
#
# Deliberately stronger than the private copy it replaces in gh544-pre-push-gate.sh:
#   1. non-empty (the original GH-564 kill: `git -C ""` / `cd ""` are silent no-ops)
#   2. lexically under the sandbox root
#   3. PHYSICALLY RESOLVED under the sandbox root — the lexical test alone accepts
#      `$WORK/../../<real repo>`, because `"$WORK"/*` matches any string starting `$WORK/`,
#      including one full of `..` segments. Resolving with python3 `os.path.realpath` follows
#      symlinks and collapses traversal, so only a real descendant passes.
#   4. not the sandbox root itself (a bare `$WORK` would satisfy `"$WORK"/*` nowhere, but the
#      resolved check makes an explicit refusal clearer than a pattern accident)
#   5. of the expected type (directory for require_fixture, file for require_fixture_file)
#
# On refusal it writes the reason to stderr and exits 2 — refusing loudly is the whole point; a
# guard that could be talked into a warning does not guard anything.

FIXTURE_GUARD_ROOT=""
FIXTURE_GUARD_RESOLVED=""

fixture_guard_init() {  # <sandbox-root> — resolve and pin the root every fixture must live under
  local w="${1:-}"
  [ -n "$w" ] || { echo "fixture-guard: REFUSING — sandbox root is EMPTY" >&2; exit 2; }
  [ -d "$w" ] || { echo "fixture-guard: REFUSING — sandbox root '$w' is not a directory" >&2; exit 2; }
  FIXTURE_GUARD_ROOT="$w"
  FIXTURE_GUARD_RESOLVED="$(cd "$w" && pwd -P)" || {
    echo "fixture-guard: REFUSING — cannot resolve sandbox root '$w'" >&2; exit 2;
  }
}

_fixture_check() {  # <path> <label> <type-flag> — shared body of require_fixture / require_fixture_file
  local p="${1:-}" what="${2:-fixture}" type_flag="${3:--d}" type_name="directory" resolved
  [ -n "$FIXTURE_GUARD_RESOLVED" ] || { echo "fixture-guard: REFUSING — fixture_guard_init was not called" >&2; exit 2; }
  [ "$type_flag" = "-f" ] && type_name="file"
  case "$p" in
    "") echo "fixture-guard: REFUSING — $what path is EMPTY; git -C \"\" and cd \"\" would silently target the caller's clone ($PWD)" >&2; exit 2 ;;
  esac
  case "$p" in
    "$FIXTURE_GUARD_ROOT"/*) ;;
    *) echo "fixture-guard: REFUSING — $what path '$p' is outside the fixture root $FIXTURE_GUARD_ROOT; this suite must never touch a real repo" >&2; exit 2 ;;
  esac
  # Resolution is os.path.realpath, NOT `cd + pwd -P`: bash's cd fails outright on a path
  # containing `..` under a symlinked TMPDIR (macOS /tmp -> /private/var), and cd cannot
  # resolve a file path at all. python3 is already a suite dependency (validate.sh runs
  # pytest). realpath handles `..`, symlinks, files and directories uniformly.
  resolved="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$p" 2>/dev/null)" || {
    echo "fixture-guard: REFUSING — cannot resolve $what path '$p' (python3 missing or path unresolvable)" >&2; exit 2;
  }
  case "$resolved" in
    "$FIXTURE_GUARD_RESOLVED"/*) ;;
    *) echo "fixture-guard: REFUSING — $what path '$p' resolves to '$resolved', OUTSIDE the resolved fixture root $FIXTURE_GUARD_RESOLVED (traversal or symlink escape — the lexical check alone would have accepted it)" >&2; exit 2 ;;
  esac
  [ "$type_flag" "$resolved" ] || {
    echo "fixture-guard: REFUSING — $what path '$p' is not a $type_name" >&2; exit 2;
  }
}

require_fixture()      { _fixture_check "${1:-}" "${2:-fixture}" -d; }
require_fixture_file() { _fixture_check "${1:-}" "${2:-fixture}" -f; }
