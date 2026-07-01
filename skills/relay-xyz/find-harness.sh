#!/usr/bin/env bash
#
# find-harness.sh — device-agnostic locator for the xyz-3-agents-swarm relay harness.
#
# Prints the absolute path to the repo root that ships relay-automation/ (the relay
# harness: relay-drive.sh, the turn shims, poll.sh, bin/tick). It resolves WITHOUT any
# hardcoded machine path, so /relay-xyz works from any working directory — including a
# clone of a *different* repo — because this script ships INSIDE the harness repo
# (skills/relay-xyz/find-harness.sh) and resolves relative to its own real location,
# following symlinks (the skill is usually symlinked into ~/.claude/skills/relay-xyz).
#
# Usage:
#   find-harness.sh            # print the harness root, or error to stderr (exit 1)
#   find-harness.sh --root     # same as default
#   find-harness.sh --env      # print shell `export …` lines, safe to eval
#   find-harness.sh --check    # human-readable readiness checklist
#
# Resolution order (first hit wins):
#   1. $XYZ_HARNESS / $XYZ_REPO_ROOT          — explicit override
#   2. <caller-root>/.xyz                     — vendored local copy in the repo you're standing in
#   3. the current git repo root              — you're already standing in a harness clone
#   4. this script's own real location        — …/<repo>/skills/relay-xyz → <repo>
#
# bash 3.2-safe (macOS default): no `readlink -f`, no associative arrays.
set -u

_has_harness() { [ -n "${1:-}" ] && [ -x "$1/relay-automation/relay-drive.sh" ]; }
_has_vendored_harness() { _has_harness "${1:-}" && [ -f "$1/bin/tick" ]; }
_canon_dir() { [ -n "${1:-}" ] && (cd "$1" >/dev/null 2>&1 && pwd); }
_short_sha() { printf '%.12s' "${1:-unknown}"; }
_read_source_commit() {
  [ -f "${1:-}/VERSION" ] || return 1
  while IFS='=' read -r _k _v; do
    [ "$_k" = "source_commit" ] || continue
    [ -n "$_v" ] || return 1
    printf '%s\n' "$_v"
    return 0
  done < "${1}/VERSION"
  return 1
}

# --- resolve this script's real directory (symlink-safe) ---
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"

HARNESS=""
VENDORED=0
CALLER_ROOT=""
VENDORED_COMMIT=""
LIVE_HARNESS=""
LIVE_HARNESS_HEAD=""
VENDORED_STATUS=""
# 1. explicit override
for _o in "${XYZ_HARNESS:-}" "${XYZ_REPO_ROOT:-}"; do
  if _has_harness "$_o"; then HARNESS="$(cd "$_o" && pwd)"; break; fi
done
# 2. vendored .xyz/ copy in the repo/PWD I'm standing in
if [ -z "$HARNESS" ]; then
  _g="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  CALLER_ROOT="$_g"
  [ -n "$CALLER_ROOT" ] || CALLER_ROOT="${PWD:-$(pwd)}"
  _vendored="$CALLER_ROOT/.xyz"
  if _has_vendored_harness "$_vendored"; then
    HARNESS="$(cd "$_vendored" && pwd)"
    VENDORED=1
  fi
fi
# 3. current git repo (preserves "operate on the clone I'm standing in")
if [ -z "$HARNESS" ]; then
  if _has_harness "$_g"; then HARNESS="$_g"; fi
fi
# 4. relative to this script (…/<repo>/skills/relay-xyz → <repo>) — fixes the
#    cross-repo case: the skill is global but the harness ships beside it.
if [ -z "$HARNESS" ]; then
  _cand="$(cd "$SELF_DIR/../.." >/dev/null 2>&1 && pwd || true)"
  if _has_harness "$_cand"; then HARNESS="$_cand"; fi
fi

if [ -z "$HARNESS" ]; then
  echo "find-harness: relay-automation/ harness not found." >&2
  echo "  Set XYZ_HARNESS=/path/to/your/xyz-3-agents-swarm clone and retry." >&2
  exit 1
fi

# Vendored copies are opt-in fallbacks: warn on reachable drift, never block.
if [ "$VENDORED" = 1 ]; then
  for _o in "${XYZ_HARNESS:-}" "${XYZ_REPO_ROOT:-}"; do
    if _has_harness "$_o"; then
      _live="$(_canon_dir "$_o" || true)"
      if [ -n "$_live" ] && [ "$_live" != "$HARNESS" ]; then
        LIVE_HARNESS="$_live"
        break
      fi
    fi
  done
  if [ -z "$LIVE_HARNESS" ]; then
    _cand="$(_canon_dir "$SELF_DIR/../.." || true)"
    if _has_harness "$_cand" && [ "$_cand" != "$HARNESS" ]; then
      LIVE_HARNESS="$_cand"
    fi
  fi

  if [ -n "$LIVE_HARNESS" ]; then
    VENDORED_COMMIT="$(_read_source_commit "$HARNESS" || true)"
    LIVE_HARNESS_HEAD="$(git -C "$LIVE_HARNESS" rev-parse HEAD 2>/dev/null || true)"
    if [ -n "$VENDORED_COMMIT" ] && [ -n "$LIVE_HARNESS_HEAD" ]; then
      if [ "$VENDORED_COMMIT" = "$LIVE_HARNESS_HEAD" ]; then
        VENDORED_STATUS="current"
      elif git -C "$LIVE_HARNESS" merge-base --is-ancestor "$VENDORED_COMMIT" HEAD >/dev/null 2>&1; then
        VENDORED_STATUS="behind"
        {
          echo "find-harness: WARNING — vendored .xyz harness is behind the live harness."
          echo "  vendored: $(_short_sha "$VENDORED_COMMIT")"
          echo "  live:     $(_short_sha "$LIVE_HARNESS_HEAD")"
          echo "  remedy:   xyz-sync --update $CALLER_ROOT"
        } >&2
      else
        VENDORED_STATUS="different"
      fi
    else
      VENDORED_STATUS="different"
    fi

    if [ "$VENDORED_STATUS" = "different" ]; then
      echo "find-harness: vendored copy differs from or can't be compared to the live harness." >&2
    fi
  else
    VENDORED_STATUS="standalone"
  fi
fi

# --- capability probes (read-only; safe under any sandbox) ---
TICK="$HARNESS/bin/tick"; [ -x "$TICK" ] || TICK=""
_bin() { command -v "${1:-}" 2>/dev/null || true; }
CODEX_PATH="$(_bin "${CODEX_BIN:-codex}")"
AGY_PATH="$(_bin "${AGY_BIN:-agy}")"
# Antigravity installs agy at ~/.local/bin/agy on macOS by default (not on system PATH).
# Fall back to that well-known location when neither AGY_BIN nor PATH resolves it.
if [ -z "$AGY_PATH" ] && [ -z "${AGY_BIN:-}" ] && [ -x "$HOME/.local/bin/agy" ]; then
  AGY_PATH="$HOME/.local/bin/agy"
fi
_flag() { [ -n "${1:-}" ] && echo 1 || echo 0; }

case "${1:-}" in
  ""|--root)
    printf '%s\n' "$HARNESS"
    ;;
  --env)
    printf 'export HARNESS=%q\n'         "$HARNESS"
    printf 'export TICK_REPO_ROOT=%q\n'  "$HARNESS"
    [ -n "$TICK" ]       && printf 'export TICK=%q\n'       "$TICK"
    [ -n "$CODEX_PATH" ] && printf 'export CODEX_BIN=%q\n'  "$CODEX_PATH"
    [ -n "$AGY_PATH" ]   && printf 'export AGY_BIN=%q\n'    "$AGY_PATH"
    printf 'export RELAY_HAS_TICK=%s\n'  "$(_flag "$TICK")"
    printf 'export RELAY_HAS_CODEX=%s\n' "$(_flag "$CODEX_PATH")"
    printf 'export RELAY_HAS_AGY=%s\n'   "$(_flag "$AGY_PATH")"
    ;;
  --check)
    mark() { if [ -n "${1:-}" ]; then echo "  ok  $2  ($1)"; else echo "  --  $2  (not found)"; fi; }
    echo "relay harness readiness:"
    echo "  ok  harness  ($HARNESS)"
    if [ "$VENDORED" = 1 ]; then
      echo "  ok  vendored resolution  ($HARNESS)"
      case "$VENDORED_STATUS" in
        current)
          echo "  ok  vendored copy is current with the live harness ($(_short_sha "$VENDORED_COMMIT") = $(_short_sha "$LIVE_HARNESS_HEAD"))"
          ;;
        behind)
          echo "  !   vendored copy is behind the live harness ($(_short_sha "$VENDORED_COMMIT") < $(_short_sha "$LIVE_HARNESS_HEAD")); run: xyz-sync --update $CALLER_ROOT"
          ;;
        different)
          echo "  !   vendored copy differs from or can't be compared to the live harness"
          ;;
        standalone)
          echo "  ok  no reachable live harness to compare; using vendored copy"
          ;;
      esac
    fi
    mark "$TICK"       "tick CLI"
    mark "$CODEX_PATH" "codex CLI (Path A worker)"
    mark "$AGY_PATH"   "agy CLI   (Path A worker)"
    if [ -z "$CODEX_PATH" ] && [ -z "$AGY_PATH" ]; then
      echo "  !   no cross-model headless worker on PATH — only Path B (all-Claude poll) is available"
    fi
    # GH-70: concurrency-readiness. When a FOREIGN repo (not the harness clone) has no local .xyz/, it
    # resolves to the CENTRALIZED harness, whose single global driver lock serializes ALL relays run
    # through it — so it cannot run a relay concurrently with another repo pointed at the same harness.
    # Advise vendoring for per-repo lock isolation. Fail-open: this only prints; --check still exits 0.
    if [ "$VENDORED" = 0 ]; then
      _caller="$(git rev-parse --show-toplevel 2>/dev/null || true)"
      if [ -n "$_caller" ] && [ "$(_canon_dir "$_caller")" != "$HARNESS" ]; then
        echo "  !   concurrency: no local .xyz/ in this repo — relays here use the CENTRALIZED harness and"
        echo "      share ONE global driver lock (can't run concurrently with another repo's relay). For"
        echo "      per-repo isolation / concurrent relays, vendor this repo:"
        echo "        relay-automation/xyz-vendor.sh vendor $_caller"
        for _lk in "$HARNESS/.git/relay-driver.lock" "$HARNESS/.relay-driver.lock"; do
          [ -d "$_lk" ] && { echo "  !   a driver lock is currently HELD ($_lk) — a relay started here will BLOCK until it frees"; break; }
        done
      fi
    fi
    true   # --check is advisory: always exit 0 (fail-open), never block a relay on a warning
    ;;
  *)
    echo "usage: find-harness.sh [--root|--env|--check]" >&2
    exit 2
    ;;
esac
