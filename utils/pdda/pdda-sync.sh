#!/usr/bin/env bash
set -euo pipefail

# pdda-sync.sh — distribute this canonical clone's PDDA runtime to registered target repos.
#
# The canonical repo (this clone) is the single source of truth and the only writer. `register` enrolls a target and
# does the initial install (delegating to install.sh, which is the SOLE registry writer). `push` is the
# steady-state distributor: it copies files whose content has advanced and mirrors canonical-side deletions —
# always backing up the target's version first. A launchd job (install-agent) is an OPTIONAL wrapper
# over `push`.
#
# The synced file set is the auto-regenerated manifest (utils/pdda/pdda-sync-manifest.conf, expanded by
# pdda-manifest.sh) — shared with install.sh so the set is defined in exactly one place.
#
# See PROJECT/2-WORKING/PDDA-SYNC-TO-OTHER-REPOS.md for the full design.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$HERE/../.." && pwd)"   # canonical repo root
# shellcheck source=utils/pdda/pdda-manifest.sh
. "$HERE/pdda-manifest.sh"

# Per-user, per-device registry (written by install.sh; pdda-sync.sh only READS it). Same default path
# and override knob as install.sh so the two agree without coordination.
PDDA_REGISTRY="${PDDA_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv}"

# Gitignored canonical-side runtime state (created lazily, never tracked).
SYNC_TMP="${PDDA_SYNC_TMP:-$SOURCE_DIR/temp}"
STATE_DIR="$SYNC_TMP/pdda-sync-state"
MANIFEST_SNAP_DIR="$SYNC_TMP/pdda-sync-manifest"
BACKUP_DIR="$SYNC_TMP/pdda-sync-backups"
LOG_FILE="$SYNC_TMP/pdda-sync.log"
LOCK_DIR="$SYNC_TMP/pdda-sync.lock"

# Optional launchd scheduler (Phase 4). All overridable for testing; the live agent is opt-in.
LAUNCH_LABEL="${PDDA_SYNC_LABEL:-com.hiqs.rebalance.pdda-sync}"
LAUNCH_INTERVAL="${PDDA_SYNC_INTERVAL:-1800}"
LAUNCH_PLIST="${PDDA_SYNC_PLIST:-$HOME/Library/LaunchAgents/$LAUNCH_LABEL.plist}"

say() { printf '%s\n' "$*"; }
warn() { printf '%s\n' "$*" >&2; }

HELD_LOCKS=""
cleanup_advisory_locks() {
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
trap cleanup_advisory_locks EXIT INT TERM HUP

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
      warn "$label: lock $lockdir held too long; proceeding without lock"
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

# --- registry read helpers (READ-ONLY — install.sh owns all writes) ------------------------------

# Print every registered target path (col 1), skipping comments + blank lines.
registry_targets() {
  [ -f "$PDDA_REGISTRY" ] || return 0
  awk -F'\t' '!/^#/ && NF>0 && $1!="" {print $1}' "$PDDA_REGISTRY"
}

# True if a given absolute path is registered.
registry_has() {  # <target>
  local t
  while IFS= read -r t; do [ "$t" = "$1" ] && return 0; done < <(registry_targets)
  return 1
}

# Sanitize a target path into a filename-safe slug for per-target state/backup files.
slug_for() {  # <target>
  printf '%s' "$1" | tr '/ ' '__' | tr -cd 'A-Za-z0-9_.-'
}

# --- engine helpers (Phase 2) --------------------------------------------------------------------

# Create the gitignored temp/ layout lazily (no tracked files).
ensure_tmp() { mkdir -p "$STATE_DIR" "$MANIFEST_SNAP_DIR" "$BACKUP_DIR" "$(dirname "$LOG_FILE")"; }

# Append a timestamped line to the run log and echo it.
log_line() {  # <message>
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s %s\n' "$ts" "$*" | tee -a "$LOG_FILE"
}

# Portable content hash (first field of shasum).
hash_file() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'; }

# Portable mtime epoch.
mtime_epoch() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0; }

# Look up the last-synced source hash for a relpath in a per-target state file (empty if absent).
state_get() {  # <statefile> <rel>
  [ -f "$1" ] || return 0
  awk -F'\t' -v r="$2" '$1==r{print $2; exit}' "$1"
}

# Read one registry column for a target (1=target 2=utc 3=mode 4=source_commit 5=startup_docs).
registry_field() {  # <target> <col>
  [ -f "$PDDA_REGISTRY" ] || return 0
  awk -F'\t' -v t="$1" -v c="$2" '$1==t{print $c; exit}' "$PDDA_REGISTRY"
}

write_registry_remove() {
  local reg="$1" target="$2"
  local tmp="$reg.tmp.$$"
  awk -F'\t' -v t="$target" '$1!=t' "$reg" > "$tmp" && mv "$tmp" "$reg"
}

# Drop a target's row from the registry (used by remove/prune — NOT a duplicate of install.sh's
# install/upgrade writes; deletion is an operation install.sh never performs).
registry_remove() {  # <target>
  [ -f "$PDDA_REGISTRY" ] || return 0
  run_with_advisory_lock "$PDDA_REGISTRY" "registry" write_registry_remove "$PDDA_REGISTRY" "$1"
}

# Seed per-target sync state + manifest snapshot from what is currently on disk in the target, so the
# very next push is an all-skip no-op. Called by register after install.sh copies the runtime.
seed_target_state() {  # <target>
  ensure_tmp
  local target="$1" slug rel f cur; slug="$(slug_for "$target")"
  cur="$(pdda_manifest_expand "$SOURCE_DIR")"
  local tmp="$STATE_DIR/$slug.tsv.tmp.$$"; : > "$tmp"
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    f="$target/$rel"; [ -e "$f" ] && printf '%s\t%s\n' "$rel" "$(hash_file "$f")" >> "$tmp"
  done <<EOF
$cur
EOF
  mv "$tmp" "$STATE_DIR/$slug.tsv"
  printf '%s\n' "$cur" | grep . > "$MANIFEST_SNAP_DIR/$slug.tsv"
}

# mkdir-based lock with stale age-out.
acquire_lock() {
  ensure_tmp
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    local age now mt; now="$(date +%s)"; mt="$(mtime_epoch "$LOCK_DIR")"; age=$((now - mt))
    if [ "$age" -ge "${PDDA_SYNC_LOCK_STALE_S:-3600}" ]; then
      warn "pdda-sync: breaking stale lock (age ${age}s)"; rm -rf "$LOCK_DIR"; continue
    fi
    warn "pdda-sync: another run holds the lock ($LOCK_DIR, age ${age}s) — aborting"; return 1
  done
  printf '%s\n' "$$" > "$LOCK_DIR/pid" 2>/dev/null || true
}
release_lock() { rm -rf "$LOCK_DIR"; }

# Refuse to push from a dirty canonical repo (any manifest file modified/staged). Returns 1 if dirty.
dirty_source_check() {  # manifest on stdin
  git -C "$SOURCE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  local rel dirty=0
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    if [ -n "$(git -C "$SOURCE_DIR" status --porcelain -- "$rel" 2>/dev/null)" ]; then
      warn "  dirty source file: $rel"; dirty=1
    fi
  done
  return "$dirty"
}

# First declared `dir` root that resolves to zero tracked files (poisoning signal), else empty.
manifest_zero_root() {
  local conf line kind arg; conf="$(pdda_manifest_conf_path "$SOURCE_DIR")"
  [ -f "$conf" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line#"${line%%[![:space:]]*}"}"; line="${line%"${line##*[![:space:]]}"}"
    [ -z "$line" ] && continue
    case "$line" in \#*) continue ;; esac
    kind="${line%%[[:space:]]*}"; arg="${line#"$kind"}"
    arg="${arg#"${arg%%[![:space:]]*}"}"; arg="${arg%/}"
    [ "$kind" = dir ] || continue
    if git -C "$SOURCE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      [ -z "$(git -C "$SOURCE_DIR" ls-files -- "$arg")" ] && { printf '%s\n' "$arg"; return 0; }
    else
      [ -d "$SOURCE_DIR/$arg" ] || { printf '%s\n' "$arg"; return 0; }
    fi
  done < "$conf"
  return 1
}

# Keep only the newest N backup snapshots for a target.
prune_backups() {  # <slug>
  local d="$BACKUP_DIR/$1" n="${PDDA_SYNC_BACKUPS:-5}" count
  [ -d "$d" ] || return 0
  count="$(ls -1 "$d" 2>/dev/null | wc -l | tr -d ' ')"
  [ "$count" -le "$n" ] && return 0
  ls -1 "$d" | LC_ALL=C sort | head -n "$((count - n))" | while IFS= read -r old; do
    [ -n "$old" ] && rm -rf "$d/$old"
  done
}

# --- subcommands ---------------------------------------------------------------------------------

# manifest — print the expanded synced file set (debug / parity check with install.sh).
cmd_manifest() { pdda_manifest_expand "$SOURCE_DIR"; }

# push [<target>] — distribute the current runtime to one target (or all registered).
cmd_push() {
  local DRY=0 ALLOW_DIRTY=0 NO_DELETE=0 FORCE_DELETE=0 FORCE_RESYNC=0 ONE_TARGET=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run) DRY=1; shift ;;
      --allow-dirty) ALLOW_DIRTY=1; shift ;;
      --no-delete) NO_DELETE=1; shift ;;
      --force-delete) FORCE_DELETE=1; shift ;;
      --force-resync) FORCE_RESYNC=1; shift ;;
      --target) ONE_TARGET="${2:-}"; shift 2 ;;
      -*) warn "push: unknown option $1"; return 2 ;;
      *) ONE_TARGET="$1"; shift ;;
    esac
  done

  # Current expanded manifest (the set to push). Empty ⇒ refuse outright.
  local CUR_MANIFEST cur_count
  CUR_MANIFEST="$(pdda_manifest_expand "$SOURCE_DIR")" || { warn "push: manifest expand failed"; return 1; }
  cur_count="$(printf '%s\n' "$CUR_MANIFEST" | grep -c . || true)"
  if [ "$cur_count" -eq 0 ]; then warn "push: expanded manifest is empty — refusing to push nothing"; return 1; fi

  # Dirty-source guard.
  if [ "$ALLOW_DIRTY" -eq 0 ]; then
    if ! printf '%s\n' "$CUR_MANIFEST" | dirty_source_check; then
      warn "push: the canonical repo has uncommitted changes to manifest files — commit them or pass --allow-dirty"; return 1
    fi
  fi

  # Global poisoning signal: a declared root resolving to zero tracked files blocks deletes (unless forced).
  local zero_root deletes_blocked=0
  zero_root="$(manifest_zero_root || true)"
  if [ -n "$zero_root" ]; then
    if [ "$FORCE_DELETE" -eq 1 ]; then
      warn "push: manifest-poisoning — root '$zero_root' resolves to zero files (overridden by --force-delete)"
    else
      deletes_blocked=1
      warn "push: manifest-poisoning — root '$zero_root' resolves to zero files; DELETES blocked (pass --force-delete)"
    fi
  fi

  # Targets.
  local -a targets=()
  if [ -n "$ONE_TARGET" ]; then
    [ -d "$ONE_TARGET" ] || { warn "push: target is not a directory: $ONE_TARGET"; return 1; }
    targets=( "$(cd "$ONE_TARGET" && pwd)" )
  else
    local t; while IFS= read -r t; do [ -n "$t" ] && targets+=( "$t" ); done < <(registry_targets)
    [ "${#targets[@]}" -eq 0 ] && { say "push: no registered targets (register one first)"; return 0; }
  fi

  acquire_lock || return 1
  # shellcheck disable=SC2064
  trap 'release_lock; cleanup_advisory_locks' EXIT INT TERM HUP

  local MAX_SHRINK="${PDDA_SYNC_MAX_SHRINK:-25}"
  local n_new=0 n_upd=0 n_updb=0 n_skip=0 n_del=0 n_miss=0 n_div=0
  local utc; utc="$(date -u +%Y%m%dT%H%M%SZ)"
  [ "$DRY" -eq 1 ] && log_line "push START (dry-run) — ${#targets[@]} target(s), $cur_count manifest files" \
                    || log_line "push START — ${#targets[@]} target(s), $cur_count manifest files"

  local tgt slug statefile snapfile newstate rel src tgt_f src_hash tgt_hash last
  for tgt in "${targets[@]}"; do
    if [ ! -d "$tgt" ]; then log_line "  MISSING target (skip): $tgt"; n_miss=$((n_miss+1)); continue; fi
    slug="$(slug_for "$tgt")"; statefile="$STATE_DIR/$slug.tsv"; snapfile="$MANIFEST_SNAP_DIR/$slug.tsv"
    newstate="$(mktemp)"; : > "$newstate"
    log_line "  TARGET $tgt"

    # ---- copy / update phase ----
    while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      src="$SOURCE_DIR/$rel"; tgt_f="$tgt/$rel"; src_hash="$(hash_file "$src")"
      if [ ! -e "$tgt_f" ]; then
        if [ "$DRY" -eq 0 ]; then mkdir -p "$(dirname "$tgt_f")"; if ! cp "$src" "$tgt_f.pdda-tmp" || ! mv "$tgt_f.pdda-tmp" "$tgt_f"; then
          rm -f "$tgt_f.pdda-tmp" "$newstate"
          warn "push: write failed for $rel; sync state not advanced"; return 1
        fi; case "$rel" in *.sh) chmod +x "$tgt_f" ;; esac; fi
        printf '%s\t%s\n' "$rel" "$src_hash" >> "$newstate"; log_line "    new        $rel"; n_new=$((n_new+1)); continue
      fi
      tgt_hash="$(hash_file "$tgt_f")"; last="$(state_get "$statefile" "$rel")"

      # (1) Target already matches source — the only true no-op. Checked FIRST: testing the stamp
      # before the content is what let a target that had been changed out-of-band report as a clean
      # skip forever (GH-59).
      if [ "$src_hash" = "$tgt_hash" ]; then
        printf '%s\t%s\n' "$rel" "$src_hash" >> "$newstate"; n_skip=$((n_skip+1)); continue
      fi

      # GH-649: missing provenance or changed target bytes require deliberate adoption.
      # Preserve the prior stamp (or absence), even if source advanced; do not turn
      # migration into an implicit overwrite of a consumer's local work.
      if { [ -z "$last" ] || [ "$tgt_hash" != "$last" ]; } && [ "$FORCE_RESYNC" -eq 0 ]; then
        [ -z "$last" ] || printf '%s\t%s\n' "$rel" "$last" >> "$newstate"
        log_line "    diverged   $rel (changed out-of-band; preserved — --force-resync to overwrite)"
        n_div=$((n_div+1)); continue
      fi

      # (3) Overwrite. tgt_hash != src_hash is guaranteed here, so the target always loses bytes.
      # Back up only when those bytes might be UNRECOVERABLE — i.e. when the target is not provably
      # something we wrote ourselves:
      #   - no stamp        → unknown provenance (fresh target, or state cleared to recover from the
      #                       bug above); this is the case the old code clobbered with nothing kept
      #   - tgt != last     → the target changed since we wrote it: real local content
      #   - --force-resync  → divergent by construction (branch 2 was bypassed)
      # When a stamp exists and tgt = last, the target is byte-for-byte what canonical last pushed,
      # so it is reproducible from git and a backup buys nothing. Backing it up anyway is NOT free:
      # prune_backups keeps only the newest PDDA_SYNC_BACKUPS (default 5) snapshot dirs per target,
      # so five routine releases would evict the one snapshot holding a genuinely diverged target's
      # local edits — trading the data-loss risk this check exists to prevent for a slower one.
      local did_backup=0
      if [ -z "$last" ] || [ "$tgt_hash" != "$last" ] || [ "$FORCE_RESYNC" -eq 1 ]; then
        did_backup=1
        [ "$DRY" -eq 0 ] && { mkdir -p "$(dirname "$BACKUP_DIR/$slug/$utc/$rel")"; cp "$tgt_f" "$BACKUP_DIR/$slug/$utc/$rel"; }
      fi
      if [ "$DRY" -eq 0 ]; then
        if ! cp "$src" "$tgt_f.pdda-tmp" || ! mv "$tgt_f.pdda-tmp" "$tgt_f"; then
          rm -f "$tgt_f.pdda-tmp" "$newstate"
          warn "push: write failed for $rel; sync state not advanced"; return 1
        fi; case "$rel" in *.sh) chmod +x "$tgt_f" ;; esac
      fi
      printf '%s\t%s\n' "$rel" "$src_hash" >> "$newstate"
      # Label by what actually happened, not by a proxy for it: `updated+bak` must mean a backup
      # exists, or the summary lies about what is recoverable.
      if [ "$did_backup" -eq 1 ]; then
        log_line "    updated+bak $rel"; n_updb=$((n_updb+1))
      else
        log_line "    updated    $rel"; n_upd=$((n_upd+1))
      fi
    done <<EOF
$CUR_MANIFEST
EOF

    # ---- delete-mirror phase ----
    # pending_del = removals we did NOT perform this run (no-delete or poison-blocked). They stay in the
    # snapshot so a later run (e.g. --force-delete) still detects them — never silently forgotten.
    local pending_del=""
    if [ -f "$snapfile" ]; then
      local prev_count removed
      prev_count="$(grep -c . "$snapfile" 2>/dev/null || echo 0)"
      # paths that were in the previous snapshot but are gone from the current manifest
      removed="$(comm -23 <(LC_ALL=C sort -u "$snapfile") <(printf '%s\n' "$CUR_MANIFEST" | LC_ALL=C sort -u) 2>/dev/null || true)"
      if [ -n "$removed" ]; then
        local block=0
        if [ "$NO_DELETE" -eq 1 ]; then
          block=1; log_line "    (--no-delete: deletions deferred, kept in snapshot)"
        elif [ "$deletes_blocked" -eq 1 ]; then
          block=1; log_line "    (delete phase blocked by zero-root poisoning — pass --force-delete)"
        elif [ "$prev_count" -gt 0 ]; then
          local shrink=$(( (prev_count - cur_count) * 100 / prev_count ))
          if [ "$shrink" -gt "$MAX_SHRINK" ] && [ "$FORCE_DELETE" -eq 0 ]; then
            block=1; log_line "    POISON: manifest shrank ${shrink}% (>${MAX_SHRINK}%) — deletes blocked (pass --force-delete)"
          fi
        fi
        if [ "$block" -eq 1 ]; then
          pending_del="$removed"
        else
          while IFS= read -r rel; do
            [ -n "$rel" ] || continue
            tgt_f="$tgt/$rel"
            if [ -e "$tgt_f" ]; then
              if [ "$DRY" -eq 0 ]; then mkdir -p "$(dirname "$BACKUP_DIR/$slug/$utc/$rel")"; cp "$tgt_f" "$BACKUP_DIR/$slug/$utc/$rel" && rm -f "$tgt_f"; fi
              log_line "    deleted+bak $rel"; n_del=$((n_del+1))
            fi
          done <<EOF
$removed
EOF
        fi
      fi
    fi

    # ---- persist state + manifest snapshot (skip on dry-run) ----
    # Snapshot = current manifest PLUS any deferred deletions, so deletion tracking survives a blocked run.
    if [ "$DRY" -eq 0 ]; then
      mv "$newstate" "$statefile"
      if [ -n "$pending_del" ]; then
        printf '%s\n%s\n' "$CUR_MANIFEST" "$pending_del" | grep . | LC_ALL=C sort -u > "$snapfile"
      else
        printf '%s\n' "$CUR_MANIFEST" | grep . | LC_ALL=C sort -u > "$snapfile"
      fi
      prune_backups "$slug"
    else
      rm -f "$newstate"
    fi
  done

  release_lock; trap - EXIT INT TERM
  local drynote=""; [ "$DRY" -eq 1 ] && drynote=" (dry-run: nothing written)"
  log_line "push DONE — new=$n_new updated=$n_upd updated+bak=$n_updb skip=$n_skip diverged=$n_div deleted=$n_del missing=$n_miss$drynote"
  # A run that left targets out of sync must not close on a line that reads like success
  # (GUIDING-PRINCIPLES #8) — the count above is easy to skim past, so say it in words too.
  if [ "$n_div" -gt 0 ]; then
    warn "push: $n_div file(s) left DIVERGED — the target differs from canonical and was preserved, not updated."
    warn "push: re-run with --force-resync to overwrite them (each is backed up first), or inspect with \`pdda-sync.sh status\`."
  fi
  return 0
}

# Content-currency check used by `list`: returns 0 iff every manifest file exists in the target and its
# content matches the canonical repo (i.e. `status` would report behind=0 diverged=0), else 1. Collapses status's
# current/behind/diverged distinction to a single boolean — status stays the authoritative per-file report;
# this just keeps `list` from implying staleness it never verified. Reads the manifest from $1 to avoid
# re-expanding per target.
target_is_current() {  # <target> <manifest-text>
  local tgt="$1" rel tgt_f
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    tgt_f="$tgt/$rel"
    [ -e "$tgt_f" ] || return 1
    [ "$(hash_file "$tgt_f")" = "$(hash_file "$SOURCE_DIR/$rel")" ] || return 1
  done <<EOF
$2
EOF
  return 0
}

# list — registered targets with mode, source commit, and content currency. The currency column is
# content-aware (consistent with `status`): a target install.sh provisioned but `push` never stamped reads
# `current (unpushed)`, NOT a staleness-implying `not-yet-pushed`. `(unpushed)` marks the missing sync-state
# file (provenance), not drift.
cmd_list() {
  local CUR; CUR="$(pdda_manifest_expand "$SOURCE_DIR")"
  local t mode src slug synced unpushed
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    mode="$(registry_field "$t" 3)"; src="$(registry_field "$t" 4)"; slug="$(slug_for "$t")"
    if [ ! -d "$t" ]; then
      synced="MISSING"
    else
      unpushed=""; [ -f "$STATE_DIR/$slug.tsv" ] || unpushed=" (unpushed)"
      if target_is_current "$t" "$CUR"; then synced="current$unpushed"; else synced="out-of-sync$unpushed"; fi
    fi
    printf '%s\tmode=%s\tsrc=%s\t%s\n' "$t" "${mode:-?}" "${src:-?}" "$synced"
  done < <(registry_targets)
  return 0
}

# register <dir> — enroll a target + initial install (install.sh does the copy AND the registry write).
cmd_register() {
  local YES=0 target=""; local -a passthru=()
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --yes|-y) YES=1; shift ;;
      --with-startup-docs) passthru+=( "--with-startup-docs" ); shift ;;
      --mode) passthru+=( "--mode" "${2:-}" ); shift 2 ;;
      -*) warn "register: unknown option $1"; return 2 ;;
      *) target="$1"; shift ;;
    esac
  done
  [ -n "$target" ] || { warn "register: missing <target-repo-dir>"; return 2; }
  [ -d "$target" ] || { warn "register: not a directory: $target"; return 1; }
  target="$(cd "$target" && pwd)"
  git -C "$target" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { warn "register: $target is not a git repo (git init first)"; return 1; }

  # Confirm before the first write — friction only at the rare, consequential enrollment step.
  if [ "$YES" -ne 1 ]; then
    if [ -t 0 ]; then
      printf 'Register + install PDDA into %s ? [y/N] ' "$target"
      local ans; read -r ans </dev/tty 2>/dev/null || ans=""
      case "$ans" in y|Y|yes|YES) ;; *) say "register: aborted (no changes)"; return 0 ;; esac
    else
      warn "register: refusing to write without confirmation (no TTY) — pass --yes for unattended onboarding"
      return 1
    fi
  fi

  say "register: installing PDDA into $target ..."
  if [ "${#passthru[@]}" -gt 0 ]; then
    "$SOURCE_DIR/utils/pdda/pdda-install.sh" "${passthru[@]}" "$target" || { warn "register: install.sh failed"; return 1; }
  else
    "$SOURCE_DIR/utils/pdda/pdda-install.sh" "$target" || { warn "register: install.sh failed"; return 1; }
  fi
  # install.sh already wrote the registry row (the single registry writer). Seed sync state + snapshot.
  seed_target_state "$target"
  say "register: $target enrolled — state seeded, next push is all-skip."
}

# remove <dir> — de-register a target but leave its files in place.
cmd_remove() {
  local target="${1:-}"
  [ -n "$target" ] || { warn "remove: missing <target>"; return 2; }
  [ -d "$target" ] && target="$(cd "$target" && pwd)"
  registry_has "$target" || { warn "remove: not registered: $target"; return 1; }
  registry_remove "$target"
  local slug; slug="$(slug_for "$target")"
  rm -f "$STATE_DIR/$slug.tsv" "$MANIFEST_SNAP_DIR/$slug.tsv"
  say "remove: de-registered $target (files left intact)."
}

# prune — drop registry entries whose directory no longer exists.
cmd_prune() {
  local t slug pruned=0
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    if [ ! -d "$t" ]; then
      registry_remove "$t"; slug="$(slug_for "$t")"
      rm -f "$STATE_DIR/$slug.tsv" "$MANIFEST_SNAP_DIR/$slug.tsv"
      say "prune: dropped missing target $t"; pruned=$((pruned+1))
    fi
  done < <(registry_targets)
  [ "$pruned" -eq 0 ] && say "prune: nothing to prune."
  return 0
}

# status [<dir>] — read-only per-target summary (current / behind / diverged / missing / to-delete).
cmd_status() {
  local one="${1:-}"; local -a targets=()
  if [ -n "$one" ]; then
    [ -d "$one" ] && one="$(cd "$one" && pwd)"; targets=( "$one" )
  else
    local t; while IFS= read -r t; do [ -n "$t" ] && targets+=( "$t" ); done < <(registry_targets)
  fi
  [ "${#targets[@]}" -eq 0 ] && { say "status: no targets."; return 0; }
  local CUR; CUR="$(pdda_manifest_expand "$SOURCE_DIR")"
  local tgt slug statefile snapfile rel src tgt_f src_hash tgt_hash last
  for tgt in "${targets[@]}"; do
    if [ ! -d "$tgt" ]; then printf '%s\tMISSING (dir gone)\n' "$tgt"; continue; fi
    slug="$(slug_for "$tgt")"; statefile="$STATE_DIR/$slug.tsv"; snapfile="$MANIFEST_SNAP_DIR/$slug.tsv"
    local current=0 behind=0 diverged=0 missing=0 todelete=0
    while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      src="$SOURCE_DIR/$rel"; tgt_f="$tgt/$rel"; src_hash="$(hash_file "$src")"
      if [ ! -e "$tgt_f" ]; then missing=$((missing+1)); continue; fi
      tgt_hash="$(hash_file "$tgt_f")"; last="$(state_get "$statefile" "$rel")"
      if [ "$src_hash" = "$tgt_hash" ]; then current=$((current+1))
      elif [ -z "$last" ] || [ "$tgt_hash" != "$last" ]; then diverged=$((diverged+1))
      else behind=$((behind+1)); fi
    done <<EOF
$CUR
EOF
    if [ -f "$snapfile" ]; then
      todelete="$(comm -23 <(LC_ALL=C sort -u "$snapfile") <(printf '%s\n' "$CUR" | LC_ALL=C sort -u) 2>/dev/null | grep -c . || true)"
    fi
    printf '%s\tcurrent=%d behind=%d diverged=%d missing=%d to-delete=%d\n' "$tgt" "$current" "$behind" "$diverged" "$missing" "$todelete"
  done
  return 0
}

# Write the LaunchAgent plist (one agent that runs `push` over the whole registry on an interval).
write_agent_plist() {
  ensure_tmp
  mkdir -p "$(dirname "$LAUNCH_PLIST")"
  cat > "$LAUNCH_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$LAUNCH_LABEL</string>
	<key>ProgramArguments</key>
	<array>
		<string>$HERE/pdda-sync.sh</string>
		<string>push</string>
	</array>
	<key>StartInterval</key>
	<integer>$LAUNCH_INTERVAL</integer>
	<key>RunAtLoad</key>
	<true/>
	<key>WorkingDirectory</key>
	<string>$SOURCE_DIR</string>
	<key>EnvironmentVariables</key>
	<dict>
		<key>PATH</key>
		<string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
	</dict>
	<key>StandardOutPath</key>
	<string>$LOG_FILE</string>
	<key>StandardErrorPath</key>
	<string>$LOG_FILE</string>
</dict>
</plist>
PLIST
}

# install-agent [--no-load] — write the plist and (by default) load it into the per-user gui domain.
cmd_install_agent() {
  local LOAD=1
  [ "${1:-}" = "--no-load" ] && LOAD=0
  write_agent_plist
  say "install-agent: wrote $LAUNCH_PLIST (interval ${LAUNCH_INTERVAL}s, push over the whole registry)"
  if [ "$LOAD" -eq 0 ]; then say "install-agent: --no-load — not loaded into launchd"; return 0; fi
  local domain="gui/$(id -u)"
  launchctl bootout "$domain" "$LAUNCH_PLIST" >/dev/null 2>&1 || true   # idempotent: clear any prior load
  if launchctl bootstrap "$domain" "$LAUNCH_PLIST" >/dev/null 2>&1; then
    launchctl enable "$domain/$LAUNCH_LABEL" >/dev/null 2>&1 || true
    say "install-agent: loaded $LAUNCH_LABEL into $domain"
  else
    warn "install-agent: plist written but launchctl bootstrap failed — load manually:"
    warn "  launchctl bootstrap $domain \"$LAUNCH_PLIST\""
    return 1
  fi
}

# uninstall-agent — unload from launchd and remove the plist.
cmd_uninstall_agent() {
  local domain="gui/$(id -u)"
  launchctl bootout "$domain" "$LAUNCH_PLIST" >/dev/null 2>&1 || launchctl bootout "$domain/$LAUNCH_LABEL" >/dev/null 2>&1 || true
  rm -f "$LAUNCH_PLIST"
  say "uninstall-agent: unloaded $LAUNCH_LABEL and removed $LAUNCH_PLIST"
}

usage() {
  cat <<'USAGE'
pdda-sync.sh — distribute the PDDA runtime from the canonical repo to registered target repos.

Usage: pdda-sync.sh <command> [options]

Commands:
  register <dir>     Enroll a target repo + initial install (delegates to pdda-install.sh). [Phase 3]
  push [<dir>]       Distribute current runtime to one target, or all if omitted.      [Phase 2]
  list               List registered targets.
  status [<dir>]     Per-target behind/current/diverged summary.                       [Phase 3]
  remove <dir>       De-register a target (keeps its files).                            [Phase 3]
  prune              Drop registry entries whose directory is gone.                     [Phase 3]
  manifest           Print the expanded synced file set (parity/debug).
  install-agent      Install the optional launchd schedule around `push`.              [Phase 4]
  uninstall-agent    Remove the launchd schedule.                                      [Phase 4]
  help               This message.

push options:
  --dry-run          Preview copies AND deletions; leave targets and sync state unchanged (diagnostic log is written).
  --allow-dirty      Push even though the canonical repo has uncommitted manifest files.
  --no-delete        Copy/update only; defer canonical-side deletions (kept in the snapshot).
  --force-delete     Override the manifest-poisoning guard on the delete phase.
  --force-resync     Overwrite targets reported as DIVERGED (each is backed up first). Unstamped or
                     locally changed targets are preserved until this explicit adoption.

The registry is machine-local at ${XDG_CONFIG_HOME:-$HOME/.config}/pdda/registry.tsv (override with
PDDA_REGISTRY) and is written only by install.sh. State/backups live under temp/ (override PDDA_SYNC_TMP).
USAGE
}

cmd="${1:-help}"
[ "$#" -gt 0 ] && shift
case "$cmd" in
  register)        cmd_register "$@" ;;
  push)            cmd_push "$@" ;;
  list)            cmd_list "$@" ;;
  status)          cmd_status "$@" ;;
  remove)          cmd_remove "$@" ;;
  prune)           cmd_prune "$@" ;;
  manifest)        cmd_manifest "$@" ;;
  install-agent)   cmd_install_agent "$@" ;;
  uninstall-agent) cmd_uninstall_agent "$@" ;;
  help|-h|--help)  usage ;;
  *)               warn "pdda-sync.sh: unknown command $cmd"; usage >&2; exit 2 ;;
esac
