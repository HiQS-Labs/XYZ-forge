#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  xyz-vendor.sh <target-repo> [--no-register]
  xyz-vendor.sh -h | --help

Materialize a vendored xyz harness snapshot into <target-repo>/.xyz/.
USAGE
}

note() { printf '%s\n' "$*"; }
die() { printf 'xyz-vendor.sh: %s\n' "$*" >&2; exit 1; }

HELD_LOCKS=""

# Resolve this script's real path without readlink -f (bash 3.2 / macOS safe).
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
HARNESS_ROOT="$(cd "$SELF_DIR/.." >/dev/null 2>&1 && pwd)"

REGISTER=1
TARGET_REPO=""
XYZ_REGISTRY="${XYZ_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-register) REGISTER=0; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'xyz-vendor.sh: unknown option %q\n\n' "$1" >&2; usage >&2; exit 2 ;;
    *)
      if [ -z "$TARGET_REPO" ]; then
        TARGET_REPO="$1"
        shift
      else
        printf 'xyz-vendor.sh: unexpected argument %q\n' "$1" >&2
        exit 2
      fi
      ;;
  esac
done

[ -n "$TARGET_REPO" ] || { usage >&2; exit 2; }
[ -d "$TARGET_REPO" ] || die "target repo not found: $TARGET_REPO"
[ -f "$HARNESS_ROOT/bin/tick" ] || die "missing bin/tick under $HARNESS_ROOT"
[ -d "$HARNESS_ROOT/src" ] || die "missing src/ under $HARNESS_ROOT"

TARGET_REPO="$(cd "$TARGET_REPO" >/dev/null 2>&1 && pwd)"
VENDOR_DIR="$TARGET_REPO/.xyz"
STAGE_DIR="$TARGET_REPO/.xyz.tmp.$$"

cleanup() {
  local entry
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    rm -rf "$entry" 2>/dev/null || true
  done <<EOF
$HELD_LOCKS
EOF
  if [ -n "${STAGE_DIR:-}" ] && [ -e "${STAGE_DIR:-}" ]; then
    rm -rf "$STAGE_DIR"
  fi
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
  case "$stem" in
    *.*) stem="${stem%.*}" ;;
  esac
  printf '%s/%s.lock' "$dir" "$stem"
}

acquire_advisory_lock() {
  local target="$1" label="$2" lockdir holder attempt
  lockdir="$(advisory_lock_path "$target")"
  attempt=0
  while :; do
    if mkdir "$lockdir" 2>/dev/null; then
      printf '%s\n' "$$" > "$lockdir/pid" 2>/dev/null || true
      remember_lock "$lockdir"
      ADVISORY_LOCK_DIR="$lockdir"
      return 0
    fi
    attempt=$((attempt + 1))
    holder="$(cat "$lockdir/pid" 2>/dev/null || true)"
    if [ -n "$holder" ] && kill -0 "$holder" 2>/dev/null; then
      if [ "$attempt" -ge 5 ]; then
        note "$label: lock busy ($lockdir, pid $holder); proceeding without lock"
        ADVISORY_LOCK_DIR=""
        return 1
      fi
      sleep 1
      continue
    fi
    if [ "$attempt" -ge 5 ]; then
      note "$label: could not acquire $lockdir after stale-lock retries; proceeding without lock"
      ADVISORY_LOCK_DIR=""
      return 1
    fi
    note "$label: reclaiming stale lock ($lockdir, pid ${holder:-none})"
    rm -rf "$lockdir" 2>/dev/null || true
  done
}

release_advisory_lock() {
  local lockdir="${1:-}"
  [ -n "$lockdir" ] || return 0
  rm -rf "$lockdir" 2>/dev/null || true
  forget_lock "$lockdir"
}

run_with_advisory_lock() {
  local target="$1" label="$2" lockdir="" rc
  shift 2
  if acquire_advisory_lock "$target" "$label"; then
    lockdir="$ADVISORY_LOCK_DIR"
  fi
  "$@"
  rc=$?
  release_advisory_lock "$lockdir"
  return "$rc"
}

tick_version() {
  local v
  v="$(sed -n "s/.*SCHEMA_VERSION[[:space:]]*=[[:space:]]*['\"]\([^'\"]*\)['\"].*/\1/p" "$HARNESS_ROOT/src/events.js" 2>/dev/null | head -1)"
  printf '%s' "${v:-unknown}"
}

manifest_from_make_pkg() {
  awk '
    $1 == "tar" && $2 == "czf" && $3 ~ /relay-pkg\.tar\.gz$/ { in_block = 1; next }
    in_block {
      line = $0
      sub(/[[:space:]]*#.*/, "", line)
      gsub(/[[:space:]]*\\[[:space:]]*$/, "", line)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (line == "") next
      if (line ~ /^(relay-automation|test)\//) {
        print line
        next
      }
      exit
    }
  ' "$HARNESS_ROOT/skills/relay-automation/make-pkg.sh"
}

write_registry_row() {
  local reg="$1" target="$2" row="$3" tmp
  tmp="$reg.tmp.$$"
  if awk -F '\t' -v t="$target" 'BEGIN{OFS="\t"} /^#/{print; next} NF==0{next} $1 != t {print}' "$reg" > "$tmp" 2>/dev/null; then
    if printf '%s\n' "$row" >> "$tmp" && mv "$tmp" "$reg"; then
      note "registry: updated $reg"
    else
      rm -f "$tmp" 2>/dev/null
      note "registry: write failed; skipped"
    fi
  else
    rm -f "$tmp" 2>/dev/null
    note "registry: write failed; skipped"
  fi
  return 0
}

ensure_gitignore() {
  local gitignore="$TARGET_REPO/.gitignore"
  if [ ! -f "$gitignore" ]; then
    : > "$gitignore"
  fi
  if ! grep -Fqx '.xyz/' "$gitignore" 2>/dev/null; then
    printf '%s\n' '.xyz/' >> "$gitignore"
  fi
}

register_vendor() {
  [ "$REGISTER" -eq 1 ] || return 0

  local reg dir ts ver src_commit row
  reg="$XYZ_REGISTRY"
  dir="$(dirname "$reg")"
  mkdir -p "$dir" 2>/dev/null || { note "registry: $dir not writable; skipped"; return 0; }

  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  ver="$(tick_version)"
  src_commit="$(git -C "$HARNESS_ROOT" rev-parse HEAD 2>/dev/null || printf 'unknown')"

  if [ ! -f "$reg" ]; then
    {
      printf '# XYZ install registry — per-user, per-device. Machine-local; do NOT commit.\n'
      printf '# install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n'
    } > "$reg" 2>/dev/null || { note "registry: $reg not writable; skipped"; return 0; }
  fi

  # Schema stays aligned with install.sh; vendored copies are identified by install_dir=.xyz and
  # coordinated_repo=<target repo>.
  row="$(printf '%s\t%s\t%s\t%s\t%s' "$VENDOR_DIR" "$ts" "$ver" "$src_commit" "$TARGET_REPO")"
  run_with_advisory_lock "$reg" "registry" write_registry_row "$reg" "$VENDOR_DIR" "$row"
  return 0
}

materialize_vendor() {
  local rel src_file copied

  rm -rf "$STAGE_DIR"
  mkdir -p "$STAGE_DIR"
  copied=0

  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    src_file="$HARNESS_ROOT/$rel"
    [ -f "$src_file" ] || die "manifest entry missing from harness: $rel"
    mkdir -p "$STAGE_DIR/$(dirname "$rel")"
    cp -p "$src_file" "$STAGE_DIR/$rel"
    copied=$((copied + 1))
  done <<EOF
$(manifest_from_make_pkg)
EOF

  [ "$copied" -gt 0 ] || die "failed to derive relay manifest from skills/relay-automation/make-pkg.sh"

  # GH-49b: the marathon runtime is NOT in the relay-pkg manifest — vendor it explicitly so the copy
  # can run marathons (marathon-drive), not just relays. marathon-agent dispatches to the turn shims
  # (claude/codex/agy), so claude-turn.sh comes along too even though it's absent from the relay set.
  for mrel in relay-automation/marathon-drive.sh relay-automation/marathon.sh \
              relay-automation/marathon-agent.sh relay-automation/claude-turn.sh; do
    [ -f "$HARNESS_ROOT/$mrel" ] || die "marathon runtime missing from harness: $mrel"
    mkdir -p "$STAGE_DIR/$(dirname "$mrel")"
    cp -p "$HARNESS_ROOT/$mrel" "$STAGE_DIR/$mrel"
  done

  mkdir -p "$STAGE_DIR/bin" "$STAGE_DIR/src"
  cp -p "$HARNESS_ROOT/bin/tick" "$STAGE_DIR/bin/tick"
  cp -p "$HARNESS_ROOT/bin/validate-relay-block" "$STAGE_DIR/bin/validate-relay-block"

  for src_file in "$HARNESS_ROOT"/src/*.js; do
    [ -e "$src_file" ] || die "no src/*.js found under $HARNESS_ROOT/src"
    cp -p "$src_file" "$STAGE_DIR/src/$(basename "$src_file")"
  done

  {
    printf 'source_commit=%s\n' "$(git -C "$HARNESS_ROOT" rev-parse HEAD 2>/dev/null || printf 'unknown')"
    printf 'tick_version=%s\n' "$(tick_version)"
    printf 'vendored_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } > "$STAGE_DIR/VERSION"

  rm -rf "$VENDOR_DIR"
  mv "$STAGE_DIR" "$VENDOR_DIR"
}

materialize_vendor
ensure_gitignore
register_vendor

note "vendored harness -> $VENDOR_DIR"
