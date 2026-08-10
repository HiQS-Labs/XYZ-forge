#!/usr/bin/env bash
# marathon-ls.sh — cross-repo marathon monitor engine (read-only).
#
# Enumerates every repo known to the xyz registry (hub + col-5 coordinated_repo),
# resolves its relay-driver lock path, derives LIVE/STALE/IDLE/GONE state, finds
# the newest *marathon*.jsonl tick event, and prints one TSV row per repo.
#
# Output columns (tab-separated, header row first):
#   REPO  STATE  PHASE  LAST-TICK  PID  RELAY-FILE
#
# STATE derivation:
#   LIVE  — lock dir present + pid file alive (kill -0 succeeds)
#   STALE — lock dir present + pid dead or missing
#   IDLE  — no lock + newest marathon tick event is phase.approved or marathon.complete
#   GONE  — repo path does not exist on disk
#
# Registry: $XYZ_REGISTRY (default: ${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv)
# Registry format: install_dir<TAB>last_install_utc<TAB>tick_version<TAB>source_commit<TAB>coordinated_repo
#
# This script writes NO state to any monitored repo.
set -euo pipefail

XYZ_REGISTRY="${XYZ_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv}"

# Resolve this script's real directory (bash 3.2 / macOS safe — no readlink -f).
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
HUB_REPO="$(cd "$SELF_DIR/.." && pwd)"

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

trim_cr() { printf '%s' "${1%$'\r'}"; }

# Resolve the relay-driver lock directory for a given repo root.
# Clone: <repo>/.git/relay-driver.lock
# Vendored (.xyz/ with no .git/): <repo>/.relay-driver.lock
lock_path_for_repo() {
  local repo="$1"
  if [ -d "$repo/.git" ]; then
    printf '%s/.git/relay-driver.lock' "$repo"
  else
    printf '%s/.relay-driver.lock' "$repo"
  fi
}

# Find the newest *marathon*.jsonl file under <repo>/.tick/events/.
newest_marathon_jsonl() {
  local repo="$1"
  local events_dir="$repo/.tick/events"
  [ -d "$events_dir" ] || return 0
  # Use ls -t (newest first) rather than `find -newer` for bash 3.2 compat.
  # Glob for files matching *marathon*.jsonl; pick the first (newest by mtime).
  local f
  # shellcheck disable=SC2012
  f="$(ls -t "$events_dir"/*marathon*.jsonl 2>/dev/null | head -1 || true)"
  printf '%s' "$f"
}

# Extract the last event line from a jsonl file and return phase type + timestamp.
# Outputs: TYPE<TAB>TIMESTAMP  (or empty strings when not parseable).
last_event_fields() {
  local jsonl="$1"
  [ -f "$jsonl" ] || { printf '\t'; return 0; }
  local last_line type ts
  last_line="$(tail -1 "$jsonl" 2>/dev/null || true)"
  [ -n "$last_line" ] || { printf '\t'; return 0; }
  # Parse with sed: no jq dependency requirement.
  type="$(printf '%s' "$last_line" | sed 's/.*"type"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null || true)"
  ts="$(printf '%s' "$last_line" | sed 's/.*"ts"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' 2>/dev/null || true)"
  # If sed didn't actually find a match it returns the whole string unchanged; detect that.
  [ "$type" = "$last_line" ] && type=""
  [ "$ts" = "$last_line" ] && ts=""
  printf '%s\t%s' "${type:-}" "${ts:-}"
}

# Determine the STATE for a repo given its lock dir path.
# Sets globals: _STATE _PID
resolve_state() {
  local lock="$1"
  _STATE="IDLE"
  _PID="-"

  if [ -d "$lock" ]; then
    local pid_file="$lock/pid"
    local pid=""
    [ -f "$pid_file" ] && pid="$(cat "$pid_file" 2>/dev/null || true)"
    pid="$(trim_cr "${pid:-}")"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      _STATE="LIVE"
      _PID="$pid"
    else
      _STATE="STALE"
      _PID="${pid:--}"
    fi
    return 0
  fi

  # No lock — state is IDLE (no lock present).
  _STATE="IDLE"
  _PID="-"
}

# Find the newest <phase-dir>/*/RELAY.md path for a repo (used in RELAY-FILE column).
#
# GH-484: reads BOTH the current default (marathon-system/) and the historical one (phases/), and
# picks whichever holds the newer file — not a straight swap. Two populations need to stay visible
# at once: this repo's ~72 committed pre-flip runs (deliberately not migrated), and fleet repos
# whose vendored .xyz/ has not re-synced yet and so is still writing to phases/. Checking only the
# new name would make the monitor silently report nothing for either.
newest_relay_file() {
  local repo="$1" d f newest=""
  for d in "$repo/marathon-system" "$repo/phases"; do
    [ -d "$d" ] || continue
    # shellcheck disable=SC2012
    f="$(ls -t "$d"/*/RELAY.md 2>/dev/null | head -1 || true)"
    [ -n "$f" ] || continue
    if [ -z "$newest" ] || [ "$f" -nt "$newest" ]; then newest="$f"; fi
  done
  printf '%s' "${newest:--}"
}

# ---------------------------------------------------------------------------
# print one row per repo
# ---------------------------------------------------------------------------

print_row() {
  local repo="$1"
  local repo_abs

  # Canonicalize path (no readlink -f on macOS bash 3.2).
  if [ -d "$repo" ]; then
    repo_abs="$(cd "$repo" && pwd)"
  else
    repo_abs="$repo"
  fi

  # GONE: repo does not exist on disk.
  if [ ! -d "$repo_abs" ]; then
    printf '%s\tGONE\t-\t-\t-\t-\n' "$repo_abs"
    return 0
  fi

  local lock
  lock="$(lock_path_for_repo "$repo_abs")"

  resolve_state "$lock"
  local state="$_STATE" pid="$_PID"

  local marathon_jsonl phase ts relay_file
  marathon_jsonl="$(newest_marathon_jsonl "$repo_abs")"
  if [ -n "$marathon_jsonl" ]; then
    local fields
    fields="$(last_event_fields "$marathon_jsonl")"
    phase="$(printf '%s' "$fields" | cut -f1)"
    ts="$(printf '%s' "$fields" | cut -f2)"
  else
    phase="-"
    ts="-"
  fi
  [ -n "$phase" ] || phase="-"
  [ -n "$ts" ]    || ts="-"

  relay_file="$(newest_relay_file "$repo_abs")"

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$repo_abs" "$state" "$phase" "$ts" "$pid" "$relay_file"
}

# ---------------------------------------------------------------------------
# collect repos: hub + registry col-5
# ---------------------------------------------------------------------------

printf 'REPO\tSTATE\tPHASE\tLAST-TICK\tPID\tRELAY-FILE\n'

# Hub repo always first.
print_row "$HUB_REPO"

# Registry — col 5 (coordinated_repo), skip header + comment lines.
if [ -f "$XYZ_REGISTRY" ]; then
  while IFS=$'\t' read -r install_dir _last_utc _tick_ver _source_commit coordinated_repo _extra; do
    install_dir="$(trim_cr "${install_dir:-}")"
    coordinated_repo="$(trim_cr "${coordinated_repo:-}")"
    [ -n "$install_dir" ] || continue
    case "$install_dir" in \#*) continue ;; esac
    [ "$install_dir" = "install_dir" ] && continue   # skip the TSV header row
    [ -n "$coordinated_repo" ] || continue
    # Skip duplicates (if coordinated_repo == hub repo).
    local_abs=""
    if [ -d "$coordinated_repo" ]; then
      local_abs="$(cd "$coordinated_repo" && pwd)"
    fi
    [ "$local_abs" = "$HUB_REPO" ] && continue
    print_row "$coordinated_repo"
  done < "$XYZ_REGISTRY"
fi
