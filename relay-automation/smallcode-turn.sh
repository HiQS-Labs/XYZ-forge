#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/relay-turn-lib.sh"

ROOT="${SMALLCODE_TURN_ROOT:-"$(git rev-parse --show-toplevel 2>/dev/null || (cd "$HERE/.." && pwd))"}"
die() { printf 'smallcode-turn: %s\n' "$*" >&2; exit 2; }

me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
smallcode_agent="${SMALLCODE_AGENT:-}"
[[ -n "$me" ]] || die "RELAY_AGENT required"
[[ -n "$f" ]] || die "RELAY_FILE required"
[[ -n "$smallcode_agent" ]] || die "SMALLCODE_AGENT required"

if [[ "$me" != "$smallcode_agent" ]]; then
  printf 'smallcode-turn: actor %s is not the smallcode agent (%s) — deferring\n' "$me" "$smallcode_agent" >&2
  exit 0
fi

: "${TICK_REPO_ROOT:=$ROOT}"
export TICK_REPO_ROOT

SMALLCODE_LOG="${SMALLCODE_LOG:-$(rtl_default_log "$ROOT" smallcode-turn "$t")}"
export RTL_LOG="$SMALLCODE_LOG"
rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"

prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"

claim_paths="${f#"$RTL_ROOT"/}"
if [[ -n "${ALLOW_PATHS:-}" ]]; then
  IFS=',' read -ra _claim_allow <<<"${ALLOW_PATHS}"
  for _ap in "${_claim_allow[@]}"; do
    _ap="${_ap#"${_ap%%[![:space:]]*}"}"
    _ap="${_ap%"${_ap##*[![:space:]]}"}"
    [[ -n "$_ap" ]] && claim_paths="$claim_paths,$_ap"
  done
fi
_tickroot="${TICK_REPO_ROOT:-$ROOT}"; _tickbin="$(rtl_tick_bin "$_tickroot")"
if [[ -x "$_tickbin" ]]; then
  TICK_REPO_ROOT="$_tickroot" "$_tickbin" claim "$t" --agent "$me" --paths "$claim_paths" >/dev/null 2>&1 || true
  _claimer="$(TICK_REPO_ROOT="$_tickroot" "$_tickbin" info "$t" 2>/dev/null | sed -n 's/^claimer:[[:space:]]*//p' | head -n1)"
  if [[ "$_claimer" != "$me" ]]; then
    printf 'smallcode-turn: could not establish token ownership\n' >&2
    exit 5
  fi
  TICK_REPO_ROOT="$_tickroot" "$_tickbin" ping "$t" --agent "$me" >/dev/null 2>&1 || true
fi

turn_timeout="${RELAY_TURN_TIMEOUT_S:-900}"

rtl_before
bounded_rc=0

# Worktree isolation is disabled for SmallCode because it's running in a disposable clone
# and may create untracked state files that we don't want to fail the isolation check.
wt=""; cwd_wrap=()
if [[ "0" == "1" ]]; then
  if wt="$(rtl_worktree_begin)"; then
    cwd_wrap=(bash -c 'cd "$1" || exit 127; shift; exec "$@"' bash "$wt")
    printf 'smallcode-turn: worktree isolation ON (%s)\n' "$wt" >&2
  else
    printf 'smallcode-turn: worktree isolation failed\n' >&2
    exit 5
  fi
fi

# Every other shim resolves its worker from PATH (`codex`, `agy`, `aider`). SmallCode has no
# installed entrypoint, so it is resolved from an env var instead — but NOT from a baked-in absolute
# path. A machine-specific path here runs on exactly one machine and fails on every other with
# node's own "Cannot find module", which names a directory the reader has no context for. (GH-548)
#
# The default is deliberately $HOME-relative rather than absolute: it is a convenience for the one
# layout this was developed against, not a claim that the file is there. The check below is what
# makes the difference legible.
SMALLCODE_BIN="${SMALLCODE_BIN:-$HOME/Documents/GH Repos/smallcode/bin/smallcode.js}"
if [[ ! -f "$SMALLCODE_BIN" ]]; then
  printf 'smallcode-turn: SmallCode entrypoint not found: %s\n' "$SMALLCODE_BIN" >&2
  printf 'smallcode-turn:   Point SMALLCODE_BIN at your smallcode/bin/smallcode.js and re-run.\n' >&2
  printf 'smallcode-turn:   Refusing rather than letting node fail later with a path you did not set.\n' >&2
  exit 5
fi

export SMALLCODE_PROVIDER="${SMALLCODE_PROVIDER:-openai}"
export SMALLCODE_MODEL="${SMALLCODE_MODEL:-qwen/qwen2.5-coder-32b}"
export SMALLCODE_BASE_URL="${SMALLCODE_BASE_URL:-http://localhost:1234/v1}"
export SMALLCODE_API_KEY="${SMALLCODE_API_KEY:-not-needed}"

rtl_run_bounded "$turn_timeout" ${cwd_wrap[@]+"${cwd_wrap[@]}"} node "$SMALLCODE_BIN" --non-interactive -P "$prompt" < /dev/null >> "$SMALLCODE_LOG" 2>&1 \
  || bounded_rc=$?

if [[ -n "$wt" ]]; then
  rtl_worktree_end "$wt"
  if [[ "${RTL_WT_OFFLANE:-0}" == "1" ]]; then
    printf 'smallcode-turn: off-lane edits in isolated worktree\n' >&2
    exit 6
  fi
fi

if [[ "$bounded_rc" -eq 7 ]]; then
  printf 'smallcode-turn: timeout\n' >&2
elif [[ "$bounded_rc" -ne 0 ]]; then
  printf 'smallcode-turn: failed (exit %s)\n' "$bounded_rc" >&2; exit 5
fi

rtl_enforce "$t" "$me" "$SMALLCODE_LOG" "smallcode"
if [[ "$bounded_rc" -eq 7 ]]; then exit 7; fi
