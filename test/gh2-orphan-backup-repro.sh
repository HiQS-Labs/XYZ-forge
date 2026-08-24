#!/usr/bin/env bash
# GH-2: an empty mktemp-derived fixture must not redirect rtl_check onto the caller's repo.
#
# Each worker owns a disposable repo below $WORK.  It then forces mktemp -d to fail.  Bash's
# `cd ""` leaves the caller in that repo, which is the observed escape shape: code that derives
# RTL_ROOT after the failed cd treats real caller content as the fixture, copies an off-lane file
# into .tick/orphan-backups/, and removes the original.  The active polarity calls the shared
# resolved-containment guard at the use boundary.  The negative control stubs only that guard and
# must reproduce the relocation through the real relay-turn-lib.sh rtl_check implementation.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$HERE/relay-automation/relay-turn-lib.sh"
GUARD="$HERE/test/lib/fixture-guard.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh2-orphan-backup.XXXXXX")" || {
  echo "gh2-orphan-backup-repro: mktemp setup failed" >&2
  exit 1
}
. "$GUARD"
fixture_guard_init "$WORK"
cleanup(){
  [ -n "${WORK:-}" ] && [ -d "$WORK" ] && [ "$WORK" != "/" ] || return 0
  case "$WORK" in
    "${TMPDIR:-/tmp}"/gh2-orphan-backup.*) rm -rf "$WORK" ;;
    *) echo "gh2-orphan-backup-repro: REFUSING unsafe cleanup target: $WORK" >&2 ;;
  esac
}
trap cleanup EXIT

PASS=0
FAIL=0
pass(){ printf '  PASS: %s\n' "$*"; PASS=$((PASS + 1)); }
fail(){ printf '  FAIL: %s\n' "$*" >&2; FAIL=$((FAIL + 1)); }

WORKERS=6
SENTINEL='untracked project note — must not move'

seed_repo() { # <mode> <index>
  local mode="$1" index="$2" outer="$WORK/$mode-$index"
  mkdir -p "$outer/PROJECT"
  git -C "$outer" init -q
  git -C "$outer" config user.email gh2@example.test
  git -C "$outer" config user.name gh2
  printf 'tracked fixture\n' > "$outer/tracked.txt"
  git -C "$outer" add tracked.txt
  git -C "$outer" commit -qm init
  printf '%s\n' "$SENTINEL" > "$outer/PROJECT/untracked.md"
}

exercise_worker() { # <guarded|control> <index>
  local mode="$1" index="$2" outer="$WORK/$mode-$index" derived=""
  cd "$outer" || return 90

  # Deterministic stand-in for the parallel-load mktemp failure.  Keep the failure local to this
  # worker so the suite's own outer $WORK remains a valid, cleanup-safe sandbox.
  mktemp(){ return 1; }
  derived="$(mktemp -d "$WORK/intended-$mode-$index.XXXXXX" 2>/dev/null)" || :
  unset -f mktemp

  . "$GUARD"
  fixture_guard_init "$WORK"
  if [ "$mode" = control ]; then
    require_fixture(){ :; } # negative control: remove precisely the use-boundary containment check
  fi

  # This call must exit 2 in the active polarity.  In the control it permits the historic failure:
  # cd "" does not leave the caller repo, so pwd becomes the escaped RTL_ROOT.
  require_fixture "$derived" "mktemp-derived repo"
  cd "$derived" 2>/dev/null || :

  # shellcheck source=/dev/null
  . "$LIB"
  RTL_ROOT="$(pwd -P)"
  RTL_TOOL="gh2-repro"
  RTL_LOG=""
  RTL_LOG_REL=""
  RTL_ALLOW=("allowed-never-touched")
  RTL_VIOLATION=0
  unset RTL_ORPHAN_BACKUP
  rtl_check "PROJECT/untracked.md"
}

run_polarity() { # <guarded|control>
  local mode="$1" index
  for index in $(seq 1 "$WORKERS"); do
    seed_repo "$mode" "$index"
    ( (
      exercise_worker "$mode" "$index"
      )
      printf '%s\n' "$?" > "$WORK/$mode-$index.rc"
    ) &
  done
  wait
}

echo "== test: gh2-orphan-backup-repro =="
run_polarity guarded
run_polarity control

for index in $(seq 1 "$WORKERS"); do
  guarded="$WORK/guarded-$index"
  guarded_rc="$(cat "$WORK/guarded-$index.rc" 2>/dev/null || printf missing)"
  if [ "$guarded_rc" = 2 ] \
     && [ "$(cat "$guarded/PROJECT/untracked.md" 2>/dev/null)" = "$SENTINEL" ] \
     && [ ! -e "$guarded/.tick/orphan-backups" ]; then
    pass "guarded worker $index refused the empty root before relocation"
  else
    fail "guarded worker $index escaped (rc=$guarded_rc, sentinel/backup invariant broken)"
  fi

  control="$WORK/control-$index"
  control_rc="$(cat "$WORK/control-$index.rc" 2>/dev/null || printf missing)"
  backup_count="$(find "$control/.tick/orphan-backups" -type f -path '*/PROJECT/untracked.md' 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$control_rc" = 0 ] \
     && [ ! -e "$control/PROJECT/untracked.md" ] \
     && [ "$backup_count" = 1 ] \
     && find "$control/.tick/orphan-backups" -type f -path '*/PROJECT/untracked.md' -exec grep -Fqx "$SENTINEL" {} \;; then
    pass "negative-control worker $index detected the orphan-backup relocation"
  else
    fail "negative-control worker $index did not reproduce relocation (rc=$control_rc, backups=$backup_count)"
  fi
done

printf '\n  gh2-orphan-backup-repro: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
