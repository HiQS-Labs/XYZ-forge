#!/usr/bin/env bash
# gh351-manifest-unship.sh — GH-351: manifest unship retraction verb.
#
# Asserts:
#   1. `manifest unship` retracts a shipped manifest item back to dialed_in.
#   2. Retraction requires `--reason` (empty is refused).
#   3. An auditable event is recorded in `manifest_state_events` (from_state=shipped, to_state=dialed_in).
#   4. Exclusivity check: refusing unship if the issue is already dialed in or dialed into another release.
#   5. Transition legality: refusing unship on an item that is not in state 'shipped'.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
APP="$ROOT_DIR/utils/py/releases_app.py"

pass=0; fail=0
ok(){ if [ "$2" = "0" ]; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1"; fail=$((fail+1)); fi; }
is(){ [ "$1" = "$2" ]; }
has(){ printf '%s' "$1" | grep -Fq "$2"; }

echo "== test: gh351-manifest-unship =="

command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 required" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh351-unship.XXXXXX")"
[ -n "$WORK" ] && [ -d "$WORK" ] || { echo "mktemp failed" >&2; exit 1; }
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

mkrepo(){
  local r="$WORK/$1"
  mkdir -p "$r"
  git -C "$r" init -q -b main
  git -C "$r" config user.email test@invalid
  git -C "$r" config user.name test
  printf '%s\n' "$r"
}

R="$(mkrepo repo)"
require_fixture "$R" "fixture repo"

ra(){
  require_fixture "$R" "fixture repo"
  python3 "$APP" --root "$R" "$@"
}

# 1. Initialize repository and add a release
ra init --slug test-repo >/dev/null
REL="$(ra add --version 1.0.0 --status active --tracking-issue https://github.com/Org/Repo/issues/100 --description "v1.0.0" | grep -o 'rel-[0-9A-HJKMNP-TV-Z]\{26\}')"
[ -n "$REL" ] || { echo "failed to create release" >&2; exit 1; }

# 2. Dial in an issue and ship it
ra manifest dial-in --gid "$REL" https://github.com/Org/Repo/issues/1 --reason "first feature" >/dev/null
ra manifest ship --gid "$REL" https://github.com/Org/Repo/issues/1 --evidence "https://github.com/Org/Repo/pull/2" >/dev/null

STATE_SHIPPED="$(sqlite3 "$R/releases.db" "SELECT state FROM manifest_items WHERE release_id=(SELECT id FROM releases WHERE global_id='$REL');")"
ok "manifest item successfully reached shipped state" "$(is "$STATE_SHIPPED" "shipped"; echo $?)"

# 3. Retraction without reason is refused (rule=unship-needs-reason)
out="$(ra manifest unship --gid "$REL" https://github.com/Org/Repo/issues/1 2>&1 || true)"
ok "unship without --reason is refused" "$(has "$out" "rule=unship-needs-reason"; echo $?)"

# 4. Retraction with reason succeeds and transitions state back to dialed_in
out="$(ra manifest unship --gid "$REL" https://github.com/Org/Repo/issues/1 --reason "PR was reverted due to bug" 2>&1)"
ok "unship with --reason succeeds" "$(has "$out" "un-shipped (shipped -> dialed_in)"; echo $?)"

STATE_UNSHIPPED="$(sqlite3 "$R/releases.db" "SELECT state FROM manifest_items WHERE release_id=(SELECT id FROM releases WHERE global_id='$REL');")"
ok "manifest item state is dialed_in after unship" "$(is "$STATE_UNSHIPPED" "dialed_in"; echo $?)"

# 5. Verify manifest_state_events record
EVENT="$(sqlite3 "$R/releases.db" "SELECT from_state, to_state, reason FROM manifest_state_events ORDER BY id DESC LIMIT 1;")"
ok "manifest_state_events recorded shipped -> dialed_in with reason" "$(is "$EVENT" "shipped|dialed_in|PR was reverted due to bug"; echo $?)"

# 6. Unshipping an already dialed_in item refuses transition
out="$(ra manifest unship --gid "$REL" https://github.com/Org/Repo/issues/1 --reason "retract again" 2>&1 || true)"
ok "unshipping an item in dialed_in state is refused" "$(has "$out" "rule=transition"; echo $?)"

# 7. Same-release exclusivity: ship, redial in same release, attempt unship -> rule=manifest-duplicate
ra manifest dial-in --gid "$REL" https://github.com/Org/Repo/issues/2 --reason "feature 2" >/dev/null
ra manifest ship --gid "$REL" https://github.com/Org/Repo/issues/2 --evidence "https://github.com/Org/Repo/pull/3" >/dev/null
ra manifest dial-in --gid "$REL" https://github.com/Org/Repo/issues/2 --reason "feature 2 redial" >/dev/null

EVENTS_BEFORE="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM manifest_state_events;")"
out="$(ra manifest unship --gid "$REL" https://github.com/Org/Repo/issues/2 --reason "try unship duplicate" 2>&1 || true)"
ok "unship when issue already dialed_in in same release is refused with manifest-duplicate" "$(has "$out" "rule=manifest-duplicate"; echo $?)"
EVENTS_AFTER="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM manifest_state_events;")"
ok "state events not mutated after manifest-duplicate refusal" "$(is "$EVENTS_BEFORE" "$EVENTS_AFTER"; echo $?)"

# 8. Cross-release exclusivity: ship in REL1, dial in REL2, attempt unship in REL1 -> rule=dialed-in-elsewhere
REL2="$(ra add --version 2.0.0 --status active --tracking-issue https://github.com/Org/Repo/issues/200 --description "v2.0.0" | grep -o 'rel-[0-9A-HJKMNP-TV-Z]\{26\}')"
ra manifest dial-in --gid "$REL" https://github.com/Org/Repo/issues/3 --reason "feature 3" >/dev/null
ra manifest ship --gid "$REL" https://github.com/Org/Repo/issues/3 --evidence "https://github.com/Org/Repo/pull/4" >/dev/null
ra manifest dial-in --gid "$REL2" https://github.com/Org/Repo/issues/3 --reason "handed to v2" >/dev/null

EVENTS_BEFORE="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM manifest_state_events;")"
out="$(ra manifest unship --gid "$REL" https://github.com/Org/Repo/issues/3 --reason "try unship cross-held" 2>&1 || true)"
ok "unship when issue dialed_in elsewhere is refused with dialed-in-elsewhere" "$(has "$out" "rule=dialed-in-elsewhere"; echo $?)"
EVENTS_AFTER="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM manifest_state_events;")"
ok "state events not mutated after dialed-in-elsewhere refusal" "$(is "$EVENTS_BEFORE" "$EVENTS_AFTER"; echo $?)"

# 9. Consistency check passes after unship
out="$(ra check 2>&1)"
ok "releases check passes after manifest unship" "$([ $? -eq 0 ] && echo 0 || echo 1)"

echo "gh351: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
