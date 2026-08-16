#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
vndr - A generic vendoring and registry tool

Usage:
  vndr install <target-repo-path>   # Vendor the utility to a target repo and register it
  vndr list                         # Show all vendored copies
  vndr sync                         # Sync/upgrade all vendored copies to the latest version
  vndr delete <target-repo-path>    # Remove a vendored copy and unregister it
  vndr -h | --help                  # Show this help

Configuration:
  Place a `.vendor.json` file in the source repository.
USAGE
}

note() { printf '%s\n' "$*"; }
die() { printf 'vndr: %s\n' "$*" >&2; exit 1; }

# Parse JSON config safely using python
read_config() {
  local key="$1"
  python3 -c "
import sys, json
try:
  d = json.load(open('.vendor.json'))
  val = d.get(sys.argv[1])
  if isinstance(val, list):
    print('\n'.join(val))
  elif val is not None:
    print(val)
except Exception:
  pass
" "$key"
}

[ -f ".vendor.json" ] || die "missing .vendor.json in current directory (must run from the source repo)"

TOOL_NAME="$(read_config "name")"
REGISTRY_KEY="$(read_config "registry_key")"
TARGET_DIR_NAME="$(read_config "target_dir_name")"

[ -n "$TOOL_NAME" ] || die ".vendor.json missing 'name'"
[ -n "$REGISTRY_KEY" ] || REGISTRY_KEY="$TOOL_NAME"
[ -n "$TARGET_DIR_NAME" ] || TARGET_DIR_NAME=".$TOOL_NAME"

VNDR_REGISTRY="${XDG_CONFIG_HOME:-$HOME/.config}/vndr/$REGISTRY_KEY.tsv"

HELD_LOCKS=""
cleanup() {
  local entry owner
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    owner="$(cat "$entry/pid" 2>/dev/null || true)"
    if [ -z "$owner" ] || [ "$owner" = "$$" ]; then
      rm -rf "$entry" 2>/dev/null || true
    fi
  done <<EOF
$HELD_LOCKS
EOF
}
trap cleanup EXIT INT TERM HUP

remember_lock() {
  HELD_LOCKS="${HELD_LOCKS}${HELD_LOCKS:+
}$1"
}

forget_lock() {
  local needle="$1" kept="" entry
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    [ "$entry" = "$needle" ] && continue
    kept="${kept}${kept:+
}$entry"
  done <<EOF
$HELD_LOCKS
EOF
  HELD_LOCKS="$kept"
}

advisory_lock_path() {
  local target="$1" dir stem
  dir="$(dirname "$target")"
  stem="$(basename "$target")"
  case "$stem" in *.*) stem="${stem%.*}" ;; esac
  printf '%s/%s.lock' "$dir" "$stem"
}

acquire_advisory_lock() {
  local target="$1" label="$2" lockdir holder deadline empty_streak
  lockdir="$(advisory_lock_path "$target")"
  deadline=$(( $(date +%s) + 30 ))
  empty_streak=0
  while :; do
    if mkdir -p "$(dirname "$lockdir")" 2>/dev/null && mkdir "$lockdir" 2>/dev/null; then
      printf '%s\n' "$$" > "$lockdir/pid" 2>/dev/null || true
      remember_lock "$lockdir"
      ADVISORY_LOCK_DIR="$lockdir"
      return 0
    fi
    if [ "$(date +%s)" -ge "$deadline" ]; then
      note "$label: lock $lockdir held too long; proceeding without lock"
      ADVISORY_LOCK_DIR=""
      return 1
    fi
    holder="$(cat "$lockdir/pid" 2>/dev/null || true)"
    if [ -z "$holder" ]; then
      empty_streak=$((empty_streak + 1))
      if [ "$empty_streak" -ge 20 ]; then
        rm -rf "$lockdir" 2>/dev/null || true
        empty_streak=0
      fi
      sleep 0.1 2>/dev/null || sleep 1
      continue
    fi
    empty_streak=0
    if kill -0 "$holder" 2>/dev/null; then
      sleep 0.1 2>/dev/null || sleep 1
      continue
    fi
    rm -rf "$lockdir" 2>/dev/null || true
  done
}

release_advisory_lock() {
  local lockdir="${1:-}" owner
  [ -n "$lockdir" ] || return 0
  owner="$(cat "$lockdir/pid" 2>/dev/null || true)"
  if [ -z "$owner" ] || [ "$owner" = "$$" ]; then
    rm -rf "$lockdir" 2>/dev/null || true
  fi
  forget_lock "$lockdir"
}

run_with_advisory_lock() {
  local target="$1" label="$2"
  shift 2
  if ! acquire_advisory_lock "$target" "$label"; then
    return 0
  fi
  local lockdir="$ADVISORY_LOCK_DIR" rc
  "$@"
  rc=$?
  release_advisory_lock "$lockdir"
  return "$rc"
}

write_registry_row() {
  local reg="$1" target="$2" row="$3" tmp
  tmp="$reg.tmp.$$"
  if {
       if [ -f "$reg" ]; then
         awk -F '\t' -v t="$target" 'BEGIN{OFS="\t"} /^#/{print; next} NF==0{next} $1 != t {print}' "$reg"
       else
         printf '# vndr install registry — per-user, per-device. Machine-local; do NOT commit.\n'
         printf '# install_dir\tlast_install_utc\tversion\tsource_commit\tcoordinated_repo\n'
       fi
       [ -n "$row" ] && printf '%s\n' "$row"
     } > "$tmp" 2>/dev/null && mv "$tmp" "$reg"; then
    note "registry: updated $reg"
  else
    rm -f "$tmp" 2>/dev/null
    note "registry: write failed; skipped"
  fi
  return 0
}

get_version() {
  local cmd
  cmd="$(read_config "version_command")"
  if [ -n "$cmd" ]; then
    eval "$cmd" 2>/dev/null || printf 'unknown'
  else
    printf 'unknown'
  fi
}

cmd_install() {
  local target_repo="${1:-}"
  [ -n "$target_repo" ] || die "usage: vndr install <target-repo-path>"
  [ -d "$target_repo" ] || die "target repo not found: $target_repo"
  target_repo="$(cd "$target_repo" >/dev/null 2>&1 && pwd)"
  
  local vendor_dir="$target_repo/$TARGET_DIR_NAME"
  local stage_dir="$target_repo/.vndr.tmp.$$"
  
  mkdir -p "$stage_dir"
  
  local paths
  paths="$(read_config "vendor_paths")"
  [ -n "$paths" ] || die ".vendor.json missing 'vendor_paths'"
  
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    if [ -d "$p" ]; then
      mkdir -p "$stage_dir/$p"
      cp -Rp "$p/." "$stage_dir/$p/"
    elif [ -f "$p" ]; then
      mkdir -p "$(dirname "$stage_dir/$p")"
      cp -p "$p" "$stage_dir/$p"
    else
      die "vendor path not found: $p"
    fi
  done <<< "$paths"
  
  find "$stage_dir" -name '.DS_Store' -delete 2>/dev/null || true
  
  local src_commit ver ts
  src_commit="$(git rev-parse HEAD 2>/dev/null || printf 'unknown')"
  ver="$(get_version)"
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  
  {
    printf 'source_commit=%s\n' "$src_commit"
    printf 'version=%s\n' "$ver"
    printf 'vendored_utc=%s\n' "$ts"
  } > "$stage_dir/VERSION"
  
  rm -rf "$vendor_dir"
  mv "$stage_dir" "$vendor_dir"
  
  local row
  row="$(printf '%s\t%s\t%s\t%s\t%s' "$vendor_dir" "$ts" "$ver" "$src_commit" "$target_repo")"
  
  mkdir -p "$(dirname "$VNDR_REGISTRY")"
  run_with_advisory_lock "$VNDR_REGISTRY" "registry" write_registry_row "$VNDR_REGISTRY" "$vendor_dir" "$row"
  
  # Ensure gitignore is updated
  local gitignore="$target_repo/.gitignore"
  if [ ! -f "$gitignore" ]; then
    : > "$gitignore"
  fi
  if ! grep -Fqx "$TARGET_DIR_NAME/" "$gitignore" 2>/dev/null; then
    printf '%s/\n' "$TARGET_DIR_NAME" >> "$gitignore"
  fi
  
  note "vendored $TOOL_NAME -> $vendor_dir"
}

cmd_list() {
  [ -f "$VNDR_REGISTRY" ] || { note "No installations found."; return 0; }
  awk -F'\t' 'BEGIN{OFS="\t"} /^#/{next} NF==0{next} {print $1 " (@ " $3 " / " substr($4,1,7) ")"}' "$VNDR_REGISTRY"
}

cmd_sync() {
  [ -f "$VNDR_REGISTRY" ] || { note "No installations to sync."; return 0; }
  local dirs
  dirs="$(awk -F'\t' '/^#/{next} NF==0{next} {print $5}' "$VNDR_REGISTRY")"
  local count=0
  while IFS= read -r repo; do
    [ -n "$repo" ] || continue
    if [ -d "$repo" ]; then
      note "Syncing $repo..."
      cmd_install "$repo"
      count=$((count+1))
    else
      note "Skipping $repo (not found)"
    fi
  done <<< "$dirs"
  note "Synced $count installations."
}

cmd_delete() {
  local target_repo="${1:-}"
  [ -n "$target_repo" ] || die "usage: vndr delete <target-repo-path>"
  target_repo="$(cd "$target_repo" 2>/dev/null && pwd || printf '%s' "$target_repo")"
  local vendor_dir="$target_repo/$TARGET_DIR_NAME"
  
  if [ -d "$vendor_dir" ]; then
    rm -rf "$vendor_dir"
    note "Removed directory $vendor_dir"
  fi
  
  if [ -f "$VNDR_REGISTRY" ]; then
    run_with_advisory_lock "$VNDR_REGISTRY" "registry" write_registry_row "$VNDR_REGISTRY" "$vendor_dir" ""
  fi
}

if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

cmd="$1"
shift

case "$cmd" in
  install) cmd_install "$@" ;;
  list)    cmd_list ;;
  sync)    cmd_sync ;;
  delete)  cmd_delete "$@" ;;
  -h|--help) usage ;;
  *) die "unknown command: $cmd" ;;
esac
