#!/usr/bin/env bash
# clone-identity.sh — the GH-1 suite-wide invariant gate.
#
# A suite run must not be able to change WHO the caller's clone is. GH-564 demonstrated the
# failure: a fixture escape rewrote core.bare, remote.origin.url, the local user identity and
# branch refs of the clone validate.sh was invoked from — and defeated the push gate while
# corrupting it. Per-suite require_fixture adoption is incremental; this bracket covers every
# suite run detectably in ONE place, because it compares the clone's identity before and after.
#
# Read-only by construction: every probe is a query (rev-parse / config --get / remote -v).
#
# Usage:
#   test/lib/clone-identity.sh capture <snapshot-file> [repo]   — write the identity blob
#   test/lib/clone-identity.sh assert  <snapshot-file> [repo]   — exit 0 iff unchanged
#
# The repo argument defaults to the script's own checkout root, never an inherited empty string
# (GH-567: `git -C ""` silently uses the CWD — harmless for a query, but the guard should not
# have a no-op path at all).

set -u

_ci_self() { echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; }

_ci_repo() {  # <repo-arg> -> resolved, non-empty repo path
  local r="${1:-}"
  [ -n "$r" ] || r="$(_ci_self)"
  [ -d "$r" ] || { echo "clone-identity: REFUSING — repo '$r' is not a directory" >&2; exit 2; }
  cd "$r" && pwd -P
}

_ci_snapshot() {  # <repo> -> identity blob on stdout
  local r="$1"
  echo "head:   $(git -C "$r" rev-parse --verify HEAD 2>/dev/null || echo '<none>')"
  echo "bare:   $(git -C "$r" config --get core.bare 2>/dev/null || echo '<unset>')"
  echo "remote: $(git -C "$r" remote -v 2>/dev/null | sort | tr '\n' ';')"
  echo "email:  $(git -C "$r" config --local --get user.email 2>/dev/null || echo '<unset>')"
  echo "name:   $(git -C "$r" config --local --get user.name 2>/dev/null || echo '<unset>')"
  echo "branch: $(git -C "$r" symbolic-ref -q HEAD 2>/dev/null || echo '<detached>')"
}

case "${1:-}" in
  capture)
    [ $# -ge 2 ] || { echo "usage: clone-identity.sh capture <snapshot-file> [repo]" >&2; exit 2; }
    _ci_snapshot "$(_ci_repo "${3:-}")" > "$2"
    ;;
  assert)
    [ $# -ge 2 ] || { echo "usage: clone-identity.sh assert <snapshot-file> [repo]" >&2; exit 2; }
    [ -f "$2" ] || { echo "clone-identity: REFUSING — snapshot '$2' missing; capture ran?" >&2; exit 2; }
    _diff="$(mktemp "${TMPDIR:-/tmp}/clone-identity.diff.XXXXXX")"
    [ -n "$_diff" ] && [ -f "$_diff" ] || { echo "clone-identity: mktemp failed" >&2; exit 2; }
    if diff -u "$2" <(_ci_snapshot "$(_ci_repo "${3:-}")") >"$_diff" 2>&1; then
      rm -f "$_diff"
    else
      echo "clone-identity: IDENTITY DRIFT — the clone this suite ran in changed under the run:" >&2
      cat "$_diff" >&2
      rm -f "$_diff"
      echo "Every result from this clone is invalidated (GH-567): re-clone, then run candidate and base at the same width." >&2
      exit 1
    fi
    ;;
  *)
    echo "usage: clone-identity.sh capture|assert <snapshot-file> [repo]" >&2
    exit 2
    ;;
esac
