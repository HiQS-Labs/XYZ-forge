#!/usr/bin/env bash
#
# find-xyz.sh — device-agnostic locator for the xyz-3-agents-swarm INTAKE repo.
#
# Prints the absolute path to the clone that owns PROJECT/1-INBOX/ — the repo a bug
# report must land in. It resolves WITHOUT any hardcoded machine path, so /file-xyz-bug
# works from ANY working directory (that is the whole point of the skill: you are
# standing in some *other* repo when the bug bites).
#
# Usage:
#   find-xyz.sh            # print the intake repo root, or error to stderr (exit 1)
#   find-xyz.sh --root     # same as default
#   find-xyz.sh --env      # print shell `export …` lines, safe to eval
#   find-xyz.sh --check    # human-readable readiness checklist (advisory, always exit 0)
#
# Resolution order (first hit wins):
#   1. $XYZ_REPO / $XYZ_HARNESS / $XYZ_REPO_ROOT   — explicit override
#   2. this script's own real location             — …/<repo>/skills/file-xyz-bug → <repo>
#   3. relay-xyz's find-harness.sh, if installed   — reuse the sibling locator
#   4. the current git repo root                   — you're already standing in the clone
#
# NOTE the deliberate omission: a vendored `.xyz/` copy is NEVER accepted. It ships the
# harness scripts but has no PROJECT/1-INBOX and is not the upstream clone — filing a bug
# into one would write the report where nobody reads it. (This is the one place
# find-xyz.sh intentionally diverges from find-harness.sh's order.)
#
# bash 3.2-safe (macOS default): no `readlink -f`, no associative arrays.
set -u

# An intake repo is a git clone that owns the PDDA inbox. Both tests matter: the git test
# alone would accept any parent dir, the inbox test alone would accept a stray tarball.
_is_intake() {
  [ -n "${1:-}" ] && [ -d "$1/PROJECT/1-INBOX" ] && [ -e "$1/.git" ]
}
_canon_dir() { [ -n "${1:-}" ] && (cd "$1" >/dev/null 2>&1 && pwd); }

# --- resolve this script's real directory (symlink-safe) ---
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"

XYZ=""
RESOLVED_VIA=""

# 1. explicit override
for _o in "${XYZ_REPO:-}" "${XYZ_HARNESS:-}" "${XYZ_REPO_ROOT:-}"; do
  if _is_intake "$_o"; then XYZ="$(_canon_dir "$_o")"; RESOLVED_VIA="env override"; break; fi
done

# 2. relative to this script (…/<repo>/skills/file-xyz-bug → <repo>). This is the primary
#    path in normal use: the skill is symlinked into ~/.claude/skills from the clone.
if [ -z "$XYZ" ]; then
  _cand="$(_canon_dir "$SELF_DIR/../.." || true)"
  if _is_intake "$_cand"; then XYZ="$_cand"; RESOLVED_VIA="skill location"; fi
fi

# 3. borrow relay-xyz's locator if it happens to be installed
if [ -z "$XYZ" ]; then
  for _l in "$HOME/.claude/skills/relay-xyz/find-harness.sh" "$SELF_DIR/../relay-xyz/find-harness.sh"; do
    [ -x "$_l" ] || continue
    _cand="$("$_l" --root 2>/dev/null || true)"
    if _is_intake "$_cand"; then XYZ="$(_canon_dir "$_cand")"; RESOLVED_VIA="relay-xyz locator"; break; fi
  done
fi

# 4. the repo I'm standing in
if [ -z "$XYZ" ]; then
  _g="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if _is_intake "$_g"; then XYZ="$(_canon_dir "$_g")"; RESOLVED_VIA="current repo"; fi
fi

if [ -z "$XYZ" ]; then
  echo "find-xyz: could not locate an xyz-3-agents-swarm clone with PROJECT/1-INBOX/." >&2
  echo "  Set XYZ_REPO=/path/to/your/xyz-3-agents-swarm clone and retry." >&2
  exit 1
fi

# --- read-only state probes (safe under any sandbox) ---
XYZ_BRANCH="$(git -C "$XYZ" branch --show-current 2>/dev/null || true)"
XYZ_DIRTY=0
[ -n "$(git -C "$XYZ" status --porcelain 2>/dev/null || true)" ] && XYZ_DIRTY=1
XYZ_SLUG="$(git -C "$XYZ" remote get-url origin 2>/dev/null | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##' || true)"
GH_PATH="$(command -v gh 2>/dev/null || true)"
# Where the bug was observed — the repo the caller is standing in, which is the single
# most useful field in the report and the one an operator always forgets to include.
CALLER_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$CALLER_ROOT" ] || CALLER_ROOT="${PWD:-$(pwd)}"

case "${1:-}" in
  ""|--root)
    printf '%s\n' "$XYZ"
    ;;
  --env)
    printf 'export XYZ_REPO=%q\n'      "$XYZ"
    printf 'export XYZ_INBOX=%q\n'     "$XYZ/PROJECT/1-INBOX"
    printf 'export XYZ_BRANCH=%q\n'    "$XYZ_BRANCH"
    printf 'export XYZ_DIRTY=%s\n'     "$XYZ_DIRTY"
    printf 'export XYZ_SLUG=%q\n'      "$XYZ_SLUG"
    printf 'export XYZ_CALLER=%q\n'    "$CALLER_ROOT"
    printf 'export XYZ_HAS_GH=%s\n'    "$([ -n "$GH_PATH" ] && echo 1 || echo 0)"
    ;;
  --check)
    echo "file-xyz-bug readiness:"
    echo "  ok  intake repo   ($XYZ)  [via $RESOLVED_VIA]"
    echo "  ok  inbox         ($XYZ/PROJECT/1-INBOX)"
    echo "  ok  reporting from ($CALLER_ROOT)"
    [ "$(_canon_dir "$CALLER_ROOT")" = "$XYZ" ] && echo "  !   you are standing IN the intake repo — this is a local report, not cross-repo"
    if [ -n "$GH_PATH" ]; then
      echo "  ok  gh CLI        ($GH_PATH)  → issue filing available"
    else
      echo "  --  gh CLI        (not found) → doc-only capture; no issue will be filed"
    fi
    echo "  ok  origin        (${XYZ_SLUG:-unknown})"
    # Branch + dirty state are advisory, but they decide whether it is safe to COMMIT the
    # capture. A marathon can leave this clone parked on a marathon/* branch (memory:
    # check-branch-before-commit-marathon-left-it) — writing is fine, committing is not.
    echo "  ok  branch        (${XYZ_BRANCH:-detached HEAD})"
    if [ "$XYZ_DIRTY" = 1 ]; then
      echo "  !   the intake repo has uncommitted changes — write the capture, but do NOT"
      echo "      commit or push it without asking; another session may be mid-work there."
    fi
    case "$XYZ_BRANCH" in
      marathon/*|relay/*)
        echo "  !   intake repo is on '$XYZ_BRANCH' — a driver probably parked it there."
        echo "      Do not commit onto this branch; report the path and let the operator decide."
        ;;
    esac
    true   # advisory only: --check never blocks a report
    ;;
  *)
    echo "usage: find-xyz.sh [--root|--env|--check]" >&2
    exit 2
    ;;
esac
