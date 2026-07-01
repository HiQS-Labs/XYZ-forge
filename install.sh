#!/usr/bin/env bash
set -euo pipefail

# XYZ / tick installer — materialize the `tick` runtime (bin/tick + src/*.js) into a target DIR, then
# "call home": record WHERE this copy was installed and on which source version/commit in a per-user,
# machine-local registry. Run it from a clone of this repo:
#
#   ./install.sh [options] [target-dir]     # target-dir default: ./xyz-tick
#
# The registry is what lets a future `tick` version be pushed to the copies that are behind. It lives
# in $HOME (never in the repo, so it can't leak into the eventually-public tree) and is never committed.
#
# This mirrors PDDA's install->call-home pattern (pdda/install.sh). The registry-writing block is kept
# in lockstep with the compact inline version embedded in the /xyz SKILL self-extract block (§4);
# change both together.

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REGISTER=1
TARGET=""
COORD_REPO="${TICK_REPO_ROOT:-}"

# Per-user, per-device install registry — one row per install dir, latest wins. Machine-local; never
# committed. Override the path with XYZ_REGISTRY; skip writing it with --no-register.
XYZ_REGISTRY="${XYZ_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv}"

# Optional multi-device rollup: if git-pulse (a GitHub-backed activity-sync tool) is present, drop a
# PATH-NORMALIZED projection of the registry (repo/dir name + date + version; never absolute paths)
# into git-pulse's repo under xyz/, and git-pulse's own sync carries it across devices. Best-effort and
# fail-open: absent git-pulse -> silently skipped. Set XYZ_GITPULSE_DIR to override or disable.
XYZ_GITPULSE_DIR="${XYZ_GITPULSE_DIR:-}"
HELD_LOCKS=""

usage() {
  cat <<'USAGE'
XYZ / tick installer — materialize the tick runtime into a dir and register the install.

Usage:
  ./install.sh [options] [target-dir]

Arguments:
  target-dir             Where to materialize the runtime (default: ./xyz-tick). Creates
                         <target-dir>/bin/tick and <target-dir>/src/*.js.

Options:
  --repo <path>          Record the coordinated repo (the one holding .tick/) in the registry.
                         Defaults to $TICK_REPO_ROOT if set, else "-".
  --no-register          Skip recording this install in the per-user registry
                         (default: $XDG_CONFIG_HOME/xyz/registry.tsv or ~/.config/xyz/registry.tsv;
                         override with XYZ_REGISTRY). Also skips the git-pulse projection.
  -h, --help             This message.

After install, use it with:
  export PATH="<target-dir>/bin:$PATH"
  export TICK_REPO_ROOT="<repo to coordinate>"   # where .tick/ lives
  tick --help
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo) COORD_REPO="${2:-}"; shift 2 ;;
    --no-register) REGISTER=0; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'install.sh: unknown option %q\n\n' "$1" >&2; usage >&2; exit 2 ;;
    *) if [ -z "$TARGET" ]; then TARGET="$1"; shift; else printf 'install.sh: unexpected argument %q\n' "$1" >&2; exit 2; fi ;;
  esac
done

TARGET="${TARGET:-xyz-tick}"

# Source sanity: we ship the repo's canonical modular runtime (bin/tick requires ../src/*).
[ -f "$SOURCE_DIR/bin/tick" ] || { printf 'install.sh: no bin/tick under %q — run this from a clone of the xyz repo.\n' "$SOURCE_DIR" >&2; exit 1; }
[ -d "$SOURCE_DIR/src" ]      || { printf 'install.sh: no src/ under %q — run this from a clone of the xyz repo.\n' "$SOURCE_DIR" >&2; exit 1; }

# Resolve target to an absolute path (create it first so `cd` succeeds).
mkdir -p "$TARGET/bin" "$TARGET/src"
TARGET="$(cd "$TARGET" && pwd)"

if [ "$TARGET" = "$SOURCE_DIR" ]; then
  printf 'install.sh: refusing to install into the source repo root (would clobber bin/tick). Pick a subdir.\n' >&2
  exit 1
fi

say() { printf '%s\n' "$*"; }

cleanup() {
  local entry owner
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    # GH-72: only delete a lock we still own (pid names us, or is gone) — never a peer's lock we may
    # have lost to a reclaim.
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
  case "$stem" in
    *.*) stem="${stem%.*}" ;;
  esac
  printf '%s/%s.lock' "$dir" "$stem"
}

acquire_advisory_lock() {
  local target="$1" label="$2" lockdir holder deadline empty_streak
  lockdir="$(advisory_lock_path "$target")"
  # Fail-open only after a real WALL-CLOCK wait on a stuck holder — never after a few lost fast races
  # (GH-72: the old attempt-count + `sleep 1` gave up in ~5s under contention and wrote UNLOCKED,
  # losing rows). Critical sections here are milliseconds, so retry fast (0.1s) and everyone drains.
  deadline=$(( $(date +%s) + ${XYZ_LOCK_WAIT_S:-30} ))
  empty_streak=0
  while :; do
    if mkdir "$lockdir" 2>/dev/null; then
      printf '%s\n' "$$" > "$lockdir/pid" 2>/dev/null || true
      remember_lock "$lockdir"
      ADVISORY_LOCK_DIR="$lockdir"
      return 0
    fi
    if [ "$(date +%s)" -ge "$deadline" ]; then
      say "  ($label lock $lockdir held too long — proceeding without lock)"
      ADVISORY_LOCK_DIR=""
      return 1
    fi
    holder="$(cat "$lockdir/pid" 2>/dev/null || true)"
    if [ -z "$holder" ]; then
      # GH-72: empty pid = winner mkdir'd but hasn't written its pid yet (sub-ms) — NOT stale; wait.
      # Only a pid ABSENT for ~2s straight is a genuinely orphaned mkdir (acquirer crashed) -> reclaim.
      empty_streak=$((empty_streak + 1))
      if [ "$empty_streak" -ge 20 ]; then
        say "  ($label reclaiming orphaned lock at $lockdir — no pid)"
        rm -rf "$lockdir" 2>/dev/null || true
        empty_streak=0
      fi
      sleep 0.1 2>/dev/null || sleep 1
      continue
    fi
    empty_streak=0
    if kill -0 "$holder" 2>/dev/null; then
      sleep 0.1 2>/dev/null || sleep 1   # live holder — wait for its (fast) release, then retry
      continue
    fi
    say "  ($label reclaiming stale lock at $lockdir, dead pid $holder)"
    rm -rf "$lockdir" 2>/dev/null || true
  done
}

release_advisory_lock() {
  local lockdir="${1:-}" owner
  [ -n "$lockdir" ] || return 0
  # GH-72: only delete the lock if WE still own it (pid names us, or is gone) — never a peer's lock
  # that a reclaim may have handed off.
  owner="$(cat "$lockdir/pid" 2>/dev/null || true)"
  if [ -z "$owner" ] || [ "$owner" = "$$" ]; then
    rm -rf "$lockdir" 2>/dev/null || true
  fi
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

say "Installing tick runtime into: $TARGET"
say ""
say "Runtime:"
cp "$SOURCE_DIR/bin/tick" "$TARGET/bin/tick"
chmod +x "$TARGET/bin/tick"
say "  runtime   bin/tick"
# Ship the whole module set — bin/tick require()s several src/* modules that transitively pull in the
# rest; copying all of src/*.js keeps the install self-consistent regardless of the require graph.
for f in "$SOURCE_DIR"/src/*.js; do
  cp "$f" "$TARGET/src/$(basename "$f")"
  say "  runtime   src/$(basename "$f")"
done

# --- call home -------------------------------------------------------------------------------------

# Best-effort tick version: the SCHEMA_VERSION anchor lives in src/events.js. Fallback: unknown.
tick_version() {
  local v
  v="$(sed -n "s/.*SCHEMA_VERSION[[:space:]]*=[[:space:]]*['\"]\([^'\"]*\)['\"].*/\1/p" "$SOURCE_DIR/src/events.js" 2>/dev/null | head -1)"
  printf '%s' "${v:-unknown}"
}

write_registry_projection() {
  local out="$1" tmp
  tmp="$out.tmp.$$"
  if {
       printf '# XYZ install status (normalized to install-dir name; absolute paths intentionally omitted).\n'
       printf '# Maintainer on another machine: locate the install by dir name, e.g.\n'
       printf '#   find ~ -type d -name "<dir>" -exec test -f "{}/bin/tick" \\; -print 2>/dev/null\n'
       printf '# install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n'
       awk -F'\t' 'BEGIN{OFS="\t"} /^#/{next} NF==0{next} {n=split($1,a,"/"); $1=a[n]; print}' "$XYZ_REGISTRY"
     } > "$tmp" 2>/dev/null && mv "$tmp" "$out"; then
    say "  publish   $(basename "$out") (normalized; git-pulse carries it)"
  else
    rm -f "$tmp" 2>/dev/null
    say "  (git-pulse publish failed — projection unchanged)"
  fi
  return 0
}

# Publish a path-normalized projection of the registry into git-pulse's sync repo when present, so XYZ
# install status rolls up across devices with NO new sync infrastructure. Normalized = col 1 absolute
# path -> bare dir name; the projection never contains a filesystem path. Best-effort / fail-open; the
# local registry stays the source of truth (it keeps absolute paths because a push tool cd's into them).
publish_registry_projection() {
  local gp="$XYZ_GITPULSE_DIR" dev cfg out cand
  cfg="${XDG_CONFIG_HOME:-$HOME/.config}/git-pulse/config.sh"
  if [ -z "$gp" ]; then
    gp="$( ( . "$cfg" 2>/dev/null; printf '%s' "${sync_repo_dir:-}" ) )"
    if [ -z "$gp" ] || [ ! -d "$gp/.git" ]; then
      for cand in "${XDG_CONFIG_HOME:-$HOME/.config}/git-pulse/repo" "$HOME/git-pulse-sync"; do
        [ -d "$cand/.git" ] && { gp="$cand"; break; }
      done
    fi
  fi
  [ -d "$gp/.git" ] || return 0
  dev="$( ( . "$cfg" 2>/dev/null; printf '%s' "${device_id:-}" ) )"
  [ -n "$dev" ] || dev="$(hostname -s 2>/dev/null || printf 'unknown-device')"
  mkdir -p "$gp/xyz" 2>/dev/null || { say "  (git-pulse xyz/ not writable — publish skipped)"; return 0; }
  out="$gp/xyz/registry-$dev.tsv"
  run_with_advisory_lock "$out" "git-pulse projection" write_registry_projection "$out"
  return 0
}

write_install_registry_row() {
  local reg="$1" target="$2" row="$3" ver="$4" src_commit="$5" coord="$6" tmp
  tmp="$reg.tmp.$$"
  # GH-72: build the WHOLE file under the lock — header (when $reg is new) + existing rows minus this
  # target + our row — then atomic mv. Bootstrapping the header here (instead of an UNLOCKED `> "$reg"`
  # in the caller) closes the first-writer truncation race where two "file missing" writers could both
  # `>`-truncate and drop a peer's just-written row (codex review, GH-72).
  if {
       if [ -f "$reg" ]; then
         awk -F'\t' -v t="$target" '$1 != t' "$reg"
       else
         printf '# XYZ install registry — per-user, per-device. Machine-local; do NOT commit.\n'
         printf '# install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n'
       fi
       printf '%s\n' "$row"
     } > "$tmp" 2>/dev/null && mv "$tmp" "$reg"; then
    say "  register  $target -> $reg (tick $ver, $src_commit, repo=$coord)"
    publish_registry_projection   # best-effort multi-device rollup; never fails the install
  else
    rm -f "$tmp" 2>/dev/null
    say "  (registry write failed — skipped)"
  fi
  return 0
}

# Record this install (one row per install dir, latest wins). Machine-local; never committed.
# Best-effort: a failure here never fails the install.
register_install() {
  [ "$REGISTER" -eq 1 ] || return 0
  local reg="$XYZ_REGISTRY" dir
  dir="$(dirname "$reg")"
  mkdir -p "$dir" 2>/dev/null || { say "  (registry dir $dir not writable — skipped)"; return 0; }

  local ts ver src_commit coord row
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  ver="$(tick_version)"
  src_commit="$(git -C "$SOURCE_DIR" rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
  coord="${COORD_REPO:-}"
  # Guard the literal "-" sentinel: cd "-" would jump to $OLDPWD and corrupt the row (agy QA r1).
  [ -n "$coord" ] && [ "$coord" != "-" ] && coord="$(cd "$coord" 2>/dev/null && pwd || printf '%s' "$COORD_REPO")"
  coord="${coord:--}"

  # GH-72: header bootstrap now happens INSIDE the locked write_install_registry_row (no unlocked
  # `> "$reg"` here) so two concurrent first-writers can't truncate each other's row.
  # One row per install dir: drop any prior row for this exact path (tab col 1), then append fresh.
  row="$(printf '%s\t%s\t%s\t%s\t%s' "$TARGET" "$ts" "$ver" "$src_commit" "$coord")"
  run_with_advisory_lock "$reg" "registry" write_install_registry_row "$reg" "$TARGET" "$row" "$ver" "$src_commit" "$coord"
}

say ""
say "Registry:"
register_install

say ""
say "tick runtime installed in $TARGET/"
say "Use it with:"
say "  export PATH=\"$TARGET/bin:\$PATH\""
say "  export TICK_REPO_ROOT=\"${COORD_REPO:-<repo to coordinate>}\""
say "  tick --help"
