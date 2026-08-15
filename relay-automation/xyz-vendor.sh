#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  xyz-vendor.sh <target-repo> [--no-register]
  xyz-vendor.sh -h | --help

Materialize a vendored xyz harness snapshot into <target-repo>/.xyz/.

Safety note: `xyz-sync update` refuses a dirty or non-canonical harness source by default before
calling this script. For an intentional reviewed override, set XYZ_SYNC_ALLOW_UNSAFE_SOURCE=1.
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
      note "$label: lock $lockdir held too long; proceeding without lock"
      ADVISORY_LOCK_DIR=""
      return 1
    fi
    holder="$(cat "$lockdir/pid" 2>/dev/null || true)"
    if [ -z "$holder" ]; then
      # GH-72: empty pid = winner mkdir'd but hasn't written its pid yet (sub-ms) — NOT stale; wait.
      # Only a pid ABSENT for ~2s straight is a genuinely orphaned mkdir (acquirer crashed) -> reclaim.
      empty_streak=$((empty_streak + 1))
      if [ "$empty_streak" -ge 20 ]; then
        note "$label: reclaiming orphaned lock ($lockdir, no pid)"
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
    note "$label: reclaiming stale lock ($lockdir, dead pid $holder)"
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
  local target="$1" label="$2"
  shift 2
  if ! acquire_advisory_lock "$target" "$label"; then
    # GH-72: lock unavailable within the deadline (only under a genuinely stuck holder or pathological
    # load). This is a best-effort registry/projection side-effect, so SKIP the update rather than
    # perform an UNLOCKED read-modify-write that could drop a peer's row. The vendor still succeeds.
    note "$label: update skipped — lock unavailable"
    return 0
  fi
  local lockdir="$ADVISORY_LOCK_DIR" rc
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

write_registry_row() {
  local reg="$1" target="$2" row="$3" tmp
  tmp="$reg.tmp.$$"
  # GH-72: build the WHOLE file under the lock — header (when $reg is new) + existing rows minus this
  # target + our row — then atomic mv. Bootstrapping the header here (instead of an UNLOCKED `> "$reg"`
  # in the caller) closes the first-writer truncation race: two "file missing" writers could otherwise
  # both `>`-truncate, dropping a peer's just-written row (codex review, GH-72).
  if {
       if [ -f "$reg" ]; then
         awk -F '\t' -v t="$target" 'BEGIN{OFS="\t"} /^#/{print; next} NF==0{next} $1 != t {print}' "$reg"
       else
         printf '# XYZ install registry — per-user, per-device. Machine-local; do NOT commit.\n'
         printf '# install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n'
       fi
       printf '%s\n' "$row"
     } > "$tmp" 2>/dev/null && mv "$tmp" "$reg"; then
    note "registry: updated $reg"
  else
    rm -f "$tmp" 2>/dev/null
    note "registry: write failed; skipped"
  fi
  return 0
}

# reconcile_ignore_state — ONE function owning BOTH directions of one invariant. (GH-314, GH-440)
#
# Vendoring is the only step that knows the harness is about to start writing to specific paths in
# somebody else's repo, so it is the only place that can check whether that repo will accept them.
# The invariant has two halves and they are NOT two features:
#
#   MUST BE IGNORED   `.xyz/` and `/.tick/` are per-device runtime state. Nothing in them is
#                     meaningful when shared, and an unrelated `git add -A` will commit them.
#   MUST BE TRACKABLE `phases/` and `relay-system/` are what the harness itself `git add`s. A
#                     pre-existing ignore rule on either makes the add raise and HALT the chain
#                     mid-run — including AFTER a phase has already passed its gate (GH-314 Halt B).
#
# Treating these as two independent append paths is how this bug survived 51 days: GH-440 was
# "fixed" by adding a second `printf >> .gitignore` line, which left GH-440's own direction working
# and GH-314's completely absent. One function, one invariant, both directions.
#
# THE ASYMMETRY IS DELIBERATE. The first half we FIX (appending an ignore rule is additive and
# reversible). The second half we REFUSE, loudly, and do not touch the target's .gitignore.
# Auto-un-ignoring would publish builder/reviewer transcripts a repo had explicitly decided to
# withhold — on a public target that is an irreversible disclosure, made silently, by an install
# script. `git add -f` is the same mistake one layer down. Refusing is recoverable; publishing is
# not. (Operator decision, recorded on #314.)
reconcile_ignore_state() {
  local gitignore="$TARGET_REPO/.gitignore"
  local _p

  # --- direction 2 FIRST: paths that MUST remain trackable ------------------------------------
  # Checked before any mutation so a refusal leaves the target's .gitignore exactly as it was.
  # A half-applied install that also refuses is the worst of both outcomes.
  # `git check-ignore -v` is the authority, not a grep of .gitignore: it honors nested ignore
  # files, $GIT_DIR/info/exclude, and core.excludesFile, and it reports WHICH rule matched and
  # where. A grep would miss every one of those and report a clean repo that halts on the first
  # phase. Non-git targets and old git both fall through to no finding rather than a false alarm.
  #
  # BOTH the bare and trailing-slash forms are queried, and that is not belt-and-braces. A
  # directory-only pattern (`/phases/`) matches ONLY when the queried path also ends in `/` — on a
  # repo where the directory does not exist yet, git cannot infer it is a directory, so
  # `check-ignore -- phases` returns "not ignored" against a rule that will absolutely block the
  # harness the moment it creates that directory. Caught by this suite's own `/phases/` case after
  # the bare-form-only version passed the first two. A check whose query shape does not cover the
  # rule shapes that exist reports clean for the ones it never asked about.
  local _blocked="" _hit
  if git -C "$TARGET_REPO" rev-parse --git-dir >/dev/null 2>&1; then
    for _p in phases phases/ relay-system relay-system/; do
      if _hit="$(git -C "$TARGET_REPO" check-ignore -v -- "$_p" 2>/dev/null)"; then
        case "$_blocked" in
          *"$_hit"$'\n'*) ;;                       # same rule already reported via the other form
          *) _blocked="${_blocked}${_hit}"$'\n' ;;
        esac
      fi
    done
  fi

  if [ -n "$_blocked" ]; then
  {
    printf 'xyz-vendor.sh: this repo IGNORES paths the harness must be able to commit.\n\n'
    printf '  A marathon writes its relay thread under phases/ and archives transcripts under\n'
    printf '  relay-system/, then git-adds both. An ignore rule on either makes that add fail and\n'
    printf '  HALT the chain mid-run — including after a phase has already passed its gate, which\n'
    printf '  destroys the record of why it stopped.\n\n'
    printf '  The rules in the way (file:line:pattern <TAB> path):\n'
    printf '%s' "$_blocked" | sed 's/^/    /'
    printf '\n  REFUSING to vendor rather than editing your .gitignore for you. Un-ignoring these\n'
    printf '  would publish builder and reviewer transcripts this repo evidently chose to withhold,\n'
    printf '  and on a public repo that is not undoable. `git add -f` is the same mistake.\n\n'
    printf '  Two ways forward, both yours to pick:\n'
    printf '    1. Remove or narrow the rules above, then re-run this command.\n'
    printf '    2. Keep them, and do not run marathons in this repo — driven relays need those paths.\n'
  } >&2
  exit 6
  fi

  # --- direction 1: paths that MUST be ignored ------------------------------------------------
  if [ ! -f "$gitignore" ]; then
    : > "$gitignore"
  fi
  for _p in '.xyz/' '/.tick/'; do
    if ! grep -Fqx "$_p" "$gitignore" 2>/dev/null; then
      printf '%s\n' "$_p" >> "$gitignore"
    fi
  done
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

  # GH-72: header bootstrap now happens INSIDE the locked write_registry_row (no unlocked `> "$reg"`).
  # Schema stays aligned with install.sh; vendored copies are identified by install_dir=.xyz and
  # coordinated_repo=<target repo>.
  row="$(printf '%s\t%s\t%s\t%s\t%s' "$VENDOR_DIR" "$ts" "$ver" "$src_commit" "$TARGET_REPO")"
  run_with_advisory_lock "$reg" "registry" write_registry_row "$reg" "$VENDOR_DIR" "$row"
  return 0
}

# Directories mirrored VERBATIM into the vendored copy. This is a full mirror, not a curated
# manifest: the old make-pkg-derived list silently dropped any newly-added lane (e.g. the aider ↔
# OpenRouter gateway shipped in GH-77 but was never added to the manifest, so vendored repos never
# got it). Copying whole dirs makes the vendored .xyz a COMPLETE, drift-free XYZ install — every
# relay / marathon / consult / aider / self-improve feature runs standalone, per repo, with no
# dependency on the central xyz-3-agents-swarm checkout.
#   relay-automation/  all turn shims (codex/agy/aider/gemini/claude), consult, marathon runtime,
#                      the self-improve loop, hooks/, docs, example configs
#   bin/               tick, validate-relay-block, marathon-yaml
#   src/               the tick/marathon JS core
#   test/              the shim + feature tests, so a vendored repo can self-verify
#   skills/            the consult / relay-xyz / xyz skill definitions travel with the harness
VENDOR_DIRS="relay-automation bin src utils test skills"

materialize_vendor() {
  local d

  rm -rf "$STAGE_DIR"
  mkdir -p "$STAGE_DIR"

  for d in $VENDOR_DIRS; do
    [ -d "$HARNESS_ROOT/$d" ] || die "missing $d/ under $HARNESS_ROOT (cannot build a complete vendor)"
    mkdir -p "$STAGE_DIR/$d"
    # Trailing '/.' copies the directory *contents* (incl. nested hooks/, fixtures/) into the stage.
    cp -Rp "$HARNESS_ROOT/$d/." "$STAGE_DIR/$d/"
  done

  # GH-110: cp -Rp on macOS/BSD faithfully mirrors Finder-created .DS_Store cruft from the source
  # tree into every vendored copy. Strip it post-copy rather than reaching for rsync --exclude (no
  # new dependency, stays consistent with the existing cp -Rp pattern above).
  find "$STAGE_DIR" -name '.DS_Store' -delete

  # Runnability sanity — the two files every feature ultimately depends on.
  [ -f "$STAGE_DIR/bin/tick" ] || die "vendor incomplete: bin/tick missing after mirror"
  [ -f "$STAGE_DIR/relay-automation/relay-turn-lib.sh" ] \
    || die "vendor incomplete: relay-turn-lib.sh missing after mirror"

  {
    printf 'source_commit=%s\n' "$(git -C "$HARNESS_ROOT" rev-parse HEAD 2>/dev/null || printf 'unknown')"
    printf 'tick_version=%s\n' "$(tick_version)"
    printf 'vendored_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } > "$STAGE_DIR/VERSION"

  # GH-312: carry TARGET-owned runtime state across the swap. $STAGE_DIR is mirrored purely from
  # $HARNESS_ROOT, and none of these paths are in VENDOR_DIRS, so the `rm -rf` below would delete
  # whatever the target accumulated -- relay threads, tick event logs, GH-75 telemetry -- unread.
  # `.xyz/` is gitignored (ensure_gitignore), so nothing under it was ever hashed into a git object:
  # there is no reflog, stash, or `git fsck --lost-found` recovery. A destroyed relay thread is gone.
  #
  # Preservation rather than a warning or a refusal: both of those still depend on an operator
  # reading output at the right moment, and this script's own docs frame `update` as deliberate
  # (pinned + manual) but never as destructive. This makes it non-destructive by default.
  #
  # The list is state that BELONGS TO THE TARGET, not harness code:
  #   relay-system/         relay threads (what vendoring is sold on -- per-repo isolation)
  #   .tick/                tick event logs / claim state
  #   .relay-driver.lock    live driver lock (a running relay or marathon)
  #   XYZ.json{,.lock/}     GH-75 completion telemetry + its mkdir advisory lock
  #   XYZ.heartbeat.json    liveness stamp
  for _keep in relay-system .tick .relay-driver.lock XYZ.json XYZ.json.lock XYZ.heartbeat.json; do
    [ -e "$VENDOR_DIR/$_keep" ] || continue
    rm -rf "$STAGE_DIR/$_keep"
    cp -Rp "$VENDOR_DIR/$_keep" "$STAGE_DIR/$_keep" \
      || die "failed to preserve target runtime state: $_keep (aborting before the destructive swap)"
  done

  rm -rf "$VENDOR_DIR"
  mv "$STAGE_DIR" "$VENDOR_DIR"
}

# Reconcile BEFORE materializing: this is a precondition on the target, not a post-install step.
# Running it after would leave `.xyz/` on disk, unregistered, in a repo we just refused to vendor.
reconcile_ignore_state
materialize_vendor
register_vendor

note "vendored harness -> $VENDOR_DIR"
