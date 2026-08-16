#!/usr/bin/env bash
set -euo pipefail

# Manage vendored .xyz copies recorded in the local XYZ registry: list, update, delete, and check.
#
# `check` (GH-96) drift-detection contract: registry.tsv stamps `tick_version` and `source_commit`
# ONCE, at install/vendor time (register_vendor(), xyz-vendor.sh). `check` recomputes the CURRENT
# values the exact same way register_vendor() does -- tick_version() re-reads SCHEMA_VERSION from
# THIS harness's src/events.js; source_commit is `git -C "$HARNESS_ROOT" rev-parse HEAD` of the
# harness root -- and compares them against what's recorded per row. The comparison key is the
# PAIR (tick_version, source_commit): a mismatch in EITHER field counts as drift (a tick_version
# bump without a fresh source_commit, or vice versa a source_commit change that didn't bump
# SCHEMA_VERSION, both mean the installed copy no longer matches what's canonically shipped).
# This is report-only: a mismatch prints a warning naming the drifted field(s) and both values
# (recorded vs current) -- it is NEVER a hard error and NEVER auto-pulls. Updates land only via an
# explicit `xyz-sync update` / `xyz-vendor.sh` re-run (pinned + manual, by design).
#
# GH-293: source_commit is provenance, not a safety capability version. A safety fix can land
# without changing src/events.js's schema version, and old registry rows sometimes have
# source_commit=unknown. Keep a small manifest of behaviorally meaningful, static guard patterns
# and inspect the installed copy itself. This keeps `check` report-only while making a missing
# guard distinguishable from ordinary provenance drift.
#
# GH-312 -- what `update` does to the target's RUNTIME STATE: it updates harness CODE only and
# preserves state the target owns. `xyz-vendor.sh` rebuilds the tree by staging a fresh mirror of
# the harness and swapping it in over `rm -rf`, so anything the target accumulated that is not
# harness source would be destroyed unread -- and `.xyz/` is gitignored, so that loss has no git
# recovery path. materialize_vendor() therefore carries these across the swap:
#   relay-system/  .tick/  .relay-driver.lock  XYZ.json  XYZ.json.lock/  XYZ.heartbeat.json
# Adding a new runtime artifact under `.xyz/` means adding it to that preserve list, or `update`
# will silently delete it. Regression coverage: test/gh312-vendor-preserves-state.sh.

usage() {
  cat <<'USAGE'
Usage:
  xyz-sync.sh list
  xyz-sync.sh update <dir> | --all
  xyz-sync.sh delete <dir> | --all [--yes]
  xyz-sync.sh check <dir> | --all
  xyz-sync.sh --list
  xyz-sync.sh --update <dir> | --all
  xyz-sync.sh --delete <dir> | --all [--yes]
  xyz-sync.sh --check <dir> | --all
  xyz-sync.sh -h | --help

Manage vendored .xyz copies recorded in the local XYZ registry.

`check` compares each selected row's recorded (tick_version, source_commit) against the values
this harness currently ships. Exact match on both -> "ok" line. Mismatch on either field -> a
"DRIFT" warning naming the drifted field(s) and both recorded/current values. Report-only: never
a hard error, never an auto-pull.

`update` refuses to fan out from a dirty harness source or a non-canonical branch. The canonical
branches default to `main,development` and may be set with XYZ_SYNC_CANONICAL_BRANCHES. Set
XYZ_SYNC_ALLOW_UNSAFE_SOURCE=1 only for an intentional, reviewed override.
USAGE
}

note() { printf '%s\n' "$*"; }
die() { printf 'xyz-sync.sh: %s\n' "$*" >&2; exit 1; }

# Resolve this script's real path without readlink -f (bash 3.2 / macOS safe).
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
VENDOR_SCRIPT="$SELF_DIR/xyz-vendor.sh"
# GH-96: same HARNESS_ROOT resolution as xyz-vendor.sh -- this repo's own root, one level up from
# relay-automation/ -- so `check` compares against what THIS harness currently ships.
HARNESS_ROOT="$(cd "$SELF_DIR/.." >/dev/null 2>&1 && pwd)"
XYZ_REGISTRY="${XYZ_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv}"

SELECTED_INSTALL_DIRS=()
SELECTED_SOURCE_COMMITS=()
SELECTED_TICK_VERSIONS=()
SELECTED_TARGET_REPOS=()

# name|path inside a vendored .xyz/|literal behavior marker. These are deliberately behavior
# markers rather than source commits: a guard remains observable even when registry provenance is
# unknown, and the output names the exact safety property a vendored copy lacks.
SAFETY_GUARD_NAMES=(
  "relay-target-root-containment"
)
SAFETY_GUARD_PATHS=(
  "relay-automation/relay-drive.sh"
)
SAFETY_GUARD_PATTERNS=(
  # Match the guard's user-facing DIAGNOSTIC, not its shell conditional (agy review of PR #318,
  # [Should]). The original marker was the `[[ ... ]]` test itself, which any reformat — or the
  # variable rename GH-289 made two lanes earlier in this same marathon — silently stops matching,
  # and a silently-unmatched marker reports "SAFETY GUARD MISSING" on a copy that has the guard.
  # A diagnostic string is load-bearing text an operator reads; it does not get reflowed.
  'turn cannot report: relay file'
)

# GH-96: mirrors tick_version() in xyz-vendor.sh byte-for-byte -- both must read SCHEMA_VERSION
# the same way, or `check` would report false drift against a correctly-vendored install.
tick_version() {
  local v
  v="$(sed -n "s/.*SCHEMA_VERSION[[:space:]]*=[[:space:]]*['\"]\([^'\"]*\)['\"].*/\1/p" "$HARNESS_ROOT/src/events.js" 2>/dev/null | head -1)"
  printf '%s' "${v:-unknown}"
}

trim_cr() {
  printf '%s' "${1%$'\r'}"
}

normalize_path() {
  local input abs
  input="$1"

  if [ -d "$input" ]; then
    (cd -P "$input" >/dev/null 2>&1 && pwd)
    return
  fi

  if [ -e "$input" ]; then
    (
      cd -P "$(dirname "$input")" >/dev/null 2>&1 &&
      printf '%s/%s\n' "$(pwd)" "$(basename "$input")"
    )
    return
  fi

  case "$input" in
    /*) abs="$input" ;;
    *) abs="$PWD/$input" ;;
  esac

  while [ "$abs" != "/" ] && [ "${abs%/}" != "$abs" ]; do
    abs="${abs%/}"
  done

  printf '%s\n' "$abs"
}

is_vendored_install_dir() {
  [ "${1##*/}" = ".xyz" ]
}

target_repo_for_row() {
  local install_dir coordinated_repo
  install_dir="$1"
  coordinated_repo="$2"
  if [ -n "$coordinated_repo" ]; then
    printf '%s\n' "$coordinated_repo"
  else
    dirname "$install_dir"
  fi
}

safe_registered_xyz_dir() {
  case "$1" in
    */.xyz) [ "$1" != "/.xyz" ] ;;
    *) return 1 ;;
  esac
}

select_vendored_rows() {
  local wanted normalized_wanted install_dir last_install_utc tick_version source_commit coordinated_repo extra target_repo normalized_install normalized_repo
  wanted="${1:-}"
  normalized_wanted=""

  SELECTED_INSTALL_DIRS=()
  SELECTED_SOURCE_COMMITS=()
  SELECTED_TICK_VERSIONS=()
  SELECTED_TARGET_REPOS=()

  [ -f "$XYZ_REGISTRY" ] || return 0

  if [ -n "$wanted" ]; then
    normalized_wanted="$(normalize_path "$wanted")"
  fi

  while IFS=$'\t' read -r install_dir last_install_utc tick_version source_commit coordinated_repo extra; do
    install_dir="$(trim_cr "${install_dir:-}")"
    coordinated_repo="$(trim_cr "${coordinated_repo:-}")"
    source_commit="$(trim_cr "${source_commit:-}")"
    tick_version="$(trim_cr "${tick_version:-}")"

    [ -n "$install_dir" ] || continue
    case "$install_dir" in
      \#*) continue ;;
    esac

    is_vendored_install_dir "$install_dir" || continue
    target_repo="$(target_repo_for_row "$install_dir" "$coordinated_repo")"

    if [ -n "$normalized_wanted" ]; then
      normalized_install="$(normalize_path "$install_dir")"
      normalized_repo="$(normalize_path "$target_repo")"
      if [ "$normalized_wanted" != "$normalized_install" ] && [ "$normalized_wanted" != "$normalized_repo" ]; then
        continue
      fi
    fi

    SELECTED_INSTALL_DIRS[${#SELECTED_INSTALL_DIRS[@]}]="$install_dir"
    SELECTED_SOURCE_COMMITS[${#SELECTED_SOURCE_COMMITS[@]}]="${source_commit:-unknown}"
    SELECTED_TICK_VERSIONS[${#SELECTED_TICK_VERSIONS[@]}]="${tick_version:-unknown}"
    SELECTED_TARGET_REPOS[${#SELECTED_TARGET_REPOS[@]}]="$target_repo"
  done < "$XYZ_REGISTRY"
}

prune_registry_rows() {
  local keys_file tmp row i

  [ -f "$XYZ_REGISTRY" ] || return 0

  keys_file="${TMPDIR:-/tmp}/xyz-sync-keys.$$"
  tmp="$XYZ_REGISTRY.tmp.$$"
  : > "$keys_file"

  for row in "$@"; do
    printf '%s\n' "$row" >> "$keys_file"
  done

  if awk -F '\t' '
    BEGIN {
      while ((getline key < ARGV[1]) > 0) {
        drop[key] = 1
      }
      close(ARGV[1])
      ARGV[1] = ""
    }
    /^#/ { print; next }
    NF == 0 { next }
    !($1 in drop) { print }
  ' "$keys_file" "$XYZ_REGISTRY" > "$tmp"; then
    mv "$tmp" "$XYZ_REGISTRY"
  else
    rm -f "$tmp" "$keys_file"
    die "failed to rewrite registry: $XYZ_REGISTRY"
  fi

  rm -f "$keys_file"
}

require_selection() {
  local label
  label="$1"
  if [ "${#SELECTED_INSTALL_DIRS[@]}" -eq 0 ]; then
    note "No vendored registry rows matched: $label"
    return 1
  fi
  return 0
}

list_rows() {
  local i status

  select_vendored_rows
  if [ "${#SELECTED_INSTALL_DIRS[@]}" -eq 0 ]; then
    note "No vendored registry rows found."
    return 0
  fi

  printf '%-8s %-40s %s\n' 'STATUS' 'SOURCE_COMMIT' 'XYZ_DIR'
  for ((i = 0; i < ${#SELECTED_INSTALL_DIRS[@]}; i++)); do
    status="present"
    [ -d "${SELECTED_INSTALL_DIRS[$i]}" ] || status="MISSING"
    printf '%-8s %-40s %s\n' "$status" "${SELECTED_SOURCE_COMMITS[$i]}" "${SELECTED_INSTALL_DIRS[$i]}"
  done
}

update_rows() {
  local target i
  target="${1:-}"

  if [ -z "$target" ]; then
    die "update requires <dir> or --all"
  fi

  if [ "$target" = "--all" ]; then
    select_vendored_rows
  else
    select_vendored_rows "$target"
  fi

  require_selection "${target}" || return 0
  [ -f "$VENDOR_SCRIPT" ] || die "missing xyz-vendor.sh alongside xyz-sync.sh"
  # GH-293: source safety is a fleet fan-out guard. A deliberately selected
  # single target keeps the established GH-312 update behavior, while --all
  # cannot distribute unmerged or dirty harness code without an explicit opt-in.
  if [ "$target" = "--all" ]; then
    require_safe_update_source
  fi

  for ((i = 0; i < ${#SELECTED_TARGET_REPOS[@]}; i++)); do
    if [ ! -d "${SELECTED_TARGET_REPOS[$i]}" ]; then
      note "update: skip stale row (repo missing): ${SELECTED_INSTALL_DIRS[$i]}"
      continue
    fi
    "$VENDOR_SCRIPT" "${SELECTED_TARGET_REPOS[$i]}"
  done
}

is_canonical_update_branch() {
  local branch allowed
  branch="$1"
  allowed="${XYZ_SYNC_CANONICAL_BRANCHES:-main,development}"

  local IFS=','
  for candidate in $allowed; do
    [ "$branch" = "$candidate" ] && return 0
  done
  return 1
}

require_safe_update_source() {
  local branch dirty

  if [ "${XYZ_SYNC_ALLOW_UNSAFE_SOURCE:-0}" = "1" ]; then
    note "update: allowing unsafe harness source because XYZ_SYNC_ALLOW_UNSAFE_SOURCE=1"
    return 0
  fi

  branch="$(git -C "$HARNESS_ROOT" branch --show-current 2>/dev/null || true)"
  if [ -z "$branch" ] || ! is_canonical_update_branch "$branch"; then
    die "refusing update: harness source branch '${branch:-detached}' is not canonical (${XYZ_SYNC_CANONICAL_BRANCHES:-main,development}); set XYZ_SYNC_ALLOW_UNSAFE_SOURCE=1 for an intentional override"
  fi

  dirty="$(git -C "$HARNESS_ROOT" status --porcelain --untracked-files=normal 2>/dev/null || true)"
  if [ -n "$dirty" ]; then
    die "refusing update: harness source is dirty; set XYZ_SYNC_ALLOW_UNSAFE_SOURCE=1 for an intentional override"
  fi
}

delete_rows() {
  local target confirmed i
  target="${1:-}"
  confirmed="${2:-0}"

  if [ -z "$target" ]; then
    die "delete requires <dir> or --all"
  fi

  if [ "$target" = "--all" ]; then
    select_vendored_rows
  else
    select_vendored_rows "$target"
  fi

  require_selection "${target}" || return 0

  if [ "$confirmed" -ne 1 ]; then
    for ((i = 0; i < ${#SELECTED_INSTALL_DIRS[@]}; i++)); do
      printf 'WOULD REMOVE %s\n' "${SELECTED_INSTALL_DIRS[$i]}"
      printf 'WOULD PRUNE %s\n' "${SELECTED_INSTALL_DIRS[$i]}"
    done
    return 0
  fi

  for ((i = 0; i < ${#SELECTED_INSTALL_DIRS[@]}; i++)); do
    safe_registered_xyz_dir "${SELECTED_INSTALL_DIRS[$i]}" || die "refusing to delete non-.xyz path: ${SELECTED_INSTALL_DIRS[$i]}"
    if [ -e "${SELECTED_INSTALL_DIRS[$i]}" ]; then
      rm -rf "${SELECTED_INSTALL_DIRS[$i]}"
      note "removed ${SELECTED_INSTALL_DIRS[$i]}"
    else
      note "delete: missing on disk, pruning row: ${SELECTED_INSTALL_DIRS[$i]}"
    fi
  done

  prune_registry_rows "${SELECTED_INSTALL_DIRS[@]}"
  note "registry: pruned ${#SELECTED_INSTALL_DIRS[@]} row(s)"
}

# GH-96: report-only drift check. Compares each selected row's recorded (tick_version,
# source_commit) against the CURRENT values this harness computes the same way register_vendor()
# does. Mismatch on either field is drift; a match is silent/"ok". Never mutates the registry or
# the install, never exits non-zero for drift -- this is a warning, not a gate.
check_rows() {
  local target i j cur_ver cur_commit rec_ver rec_commit drifted missing_guards guard_path guard_pattern

  target="${1:-}"

  if [ -z "$target" ]; then
    die "check requires <dir> or --all"
  fi

  if [ "$target" = "--all" ]; then
    select_vendored_rows
  else
    select_vendored_rows "$target"
  fi

  require_selection "${target}" || return 0

  cur_ver="$(tick_version)"
  cur_commit="$(git -C "$HARNESS_ROOT" rev-parse HEAD 2>/dev/null || printf 'unknown')"

  for ((i = 0; i < ${#SELECTED_INSTALL_DIRS[@]}; i++)); do
    rec_ver="${SELECTED_TICK_VERSIONS[$i]}"
    rec_commit="${SELECTED_SOURCE_COMMITS[$i]}"
    drifted=""
    [ "$rec_ver" = "$cur_ver" ] || drifted="${drifted}${drifted:+,}tick_version"
    [ "$rec_commit" = "$cur_commit" ] || drifted="${drifted}${drifted:+,}source_commit"
    missing_guards=""

    for ((j = 0; j < ${#SAFETY_GUARD_NAMES[@]}; j++)); do
      guard_path="${SELECTED_INSTALL_DIRS[$i]}/${SAFETY_GUARD_PATHS[$j]}"
      guard_pattern="${SAFETY_GUARD_PATTERNS[$j]}"
      if [ ! -f "$guard_path" ] || ! grep -Fq -- "$guard_pattern" "$guard_path" 2>/dev/null; then
        missing_guards="${missing_guards}${missing_guards:+,}${SAFETY_GUARD_NAMES[$j]}"
      fi
    done

    if [ -z "$drifted" ]; then
      printf 'ok    %s\n' "${SELECTED_INSTALL_DIRS[$i]}"
    else
      printf 'DRIFT %s (%s drifted)\n' "${SELECTED_INSTALL_DIRS[$i]}" "$drifted"
      printf '  recorded: tick_version=%s source_commit=%s\n' "$rec_ver" "$rec_commit"
      printf '  current:  tick_version=%s source_commit=%s\n' "$cur_ver" "$cur_commit"
    fi
    if [ -n "$missing_guards" ]; then
      printf 'SAFETY GUARD MISSING %s (%s)\n' "${SELECTED_INSTALL_DIRS[$i]}" "$missing_guards"
      printf '  inspected installed copy directly; source_commit=%s does not establish guard coverage\n' "$rec_commit"
    fi
  done
}

COMMAND="${1:-}"
[ "$#" -gt 0 ] || { usage >&2; exit 2; }
shift || true

case "$COMMAND" in
  list|--list)
    [ "$#" -eq 0 ] || { usage >&2; exit 2; }
    list_rows
    ;;
  update|--update)
    case "${1:-}" in
      --all)
        [ "$#" -eq 1 ] || { usage >&2; exit 2; }
        update_rows --all
        ;;
      "")
        usage >&2
        exit 2
        ;;
      *)
        [ "$#" -eq 1 ] || { usage >&2; exit 2; }
        update_rows "$1"
        ;;
    esac
    ;;
  check|--check)
    case "${1:-}" in
      --all)
        [ "$#" -eq 1 ] || { usage >&2; exit 2; }
        check_rows --all
        ;;
      "")
        usage >&2
        exit 2
        ;;
      *)
        [ "$#" -eq 1 ] || { usage >&2; exit 2; }
        check_rows "$1"
        ;;
    esac
    ;;
  delete|--delete)
    DELETE_TARGET=""
    DELETE_YES=0
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --yes)
          DELETE_YES=1
          ;;
        --all)
          [ -z "$DELETE_TARGET" ] || { usage >&2; exit 2; }
          DELETE_TARGET="--all"
          ;;
        -h|--help)
          usage
          exit 0
          ;;
        -*)
          usage >&2
          exit 2
          ;;
        *)
          [ -z "$DELETE_TARGET" ] || { usage >&2; exit 2; }
          DELETE_TARGET="$1"
          ;;
      esac
      shift
    done
    [ -n "$DELETE_TARGET" ] || { usage >&2; exit 2; }
    delete_rows "$DELETE_TARGET" "$DELETE_YES"
    ;;
  -h|--help)
    usage
    ;;
  *)
    printf 'xyz-sync.sh: unknown subcommand %q\n\n' "$COMMAND" >&2
    usage >&2
    exit 2
    ;;
esac
