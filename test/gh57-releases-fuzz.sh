#!/usr/bin/env bash
# GH-57 — generated scenarios for the SQLite RELEASES merge and recovery ledger.
#
# This deliberately drives the public CLI and resolver against short-lived git repositories.
# The production ledger is never opened: every fixture, child process output, lock, dump, and
# generated Markdown view lives below $WORK.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
APP="$ROOT/utils/py/releases_app.py"
RESOLVER="$ROOT/utils/releases-merge-resolve.sh"

pass=0
fail=0
ok() {
  local label="$1" rc="$2"
  if [ "$rc" -eq 0 ]; then
    printf '  PASS: %s\n' "$label"
    pass=$((pass + 1))
  else
    printf '  FAIL: %s\n' "$label" >&2
    fail=$((fail + 1))
  fi
}
has() { printf '%s' "$1" | grep -Fq -- "$2"; }
same() { [ "$1" = "$2" ]; }

printf '== test: gh57-releases-fuzz ==\n'
command -v python3 >/dev/null 2>&1 || { echo 'python3 required' >&2; exit 1; }
command -v sqlite3 >/dev/null 2>&1 || { echo 'sqlite3 required' >&2; exit 1; }
[ -f "$APP" ] || { echo "missing app: $APP" >&2; exit 1; }
[ -x "$RESOLVER" ] || { echo "missing resolver: $RESOLVER" >&2; exit 1; }

# Required containment contract: every fixture is a descendant of this one root.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh57-fuzz.XXXXXX")"
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
cleanup() {
  # fixture-guard deliberately rejects its root; validate the exact mktemp prefix before removal.
  case "${WORK:-}" in
    "${TMPDIR:-/tmp}"/gh57-fuzz.*) [ -d "$WORK" ] && rm -rf "$WORK" ;;
    *) echo "gh57: REFUSING cleanup outside gh57 workspace: ${WORK:-<empty>}" >&2 ;;
  esac
}
trap cleanup EXIT

repo() { # <name> -> git fixture path
  local r="$WORK/$1"
  mkdir -p "$r"
  require_fixture "$r" "fixture repo"
  git -C "$r" init -q
  git -C "$r" config user.email gh57@test.invalid
  git -C "$r" config user.name gh57
  printf '%s\n' "$r"
}
ra() { # <root> <releases-app args...>
  local r="$1"
  shift
  require_fixture "$r" "releases fixture"
  python3 "$APP" --root "$r" "$@"
}
sql() {
  local r="$1"
  shift
  require_fixture "$r" "sqlite fixture"
  sqlite3 "$r/releases.db" "$1"
}
file_hash() {
  local f="$1"
  require_fixture_file "$f" "fixture artifact"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$f" | awk '{print $1}'
  else
    md5 -q "$f"
  fi
}
add_release() { # <root> <version> <issue suffix> [description]
  local r="$1" version="$2" issue="$3" description="${4:-seed.}"
  ra "$r" add --version "$version" --status draft --description "$description" \
    --tracking-issue "https://github.com/GH57/ledger/issues/$issue" >/dev/null
}

union_dump() { # <repo> <header-side> -> correctly deduped GID-keyed dump
  local r="$1" header_side="$2"
  require_fixture "$r" "merge fixture"
  { git -C "$r" show "$header_side:releases.sql" | grep '^-- generation: '
    { git -C "$r" show s-a:releases.sql; git -C "$r" show s-b:releases.sql; } |
      grep -v '^-- generation: ' | awk '!seen[$0]++'
  } > "$r/releases.sql"
}
resolved_union_dump() { # <repo> <header/settings side> -> canonical dump a resolver can rebuild
  local r="$1" winning_side="$2"
  require_fixture "$r" "merge fixture"
  { git -C "$r" show "$winning_side:releases.sql" | grep '^-- generation: '
    { git -C "$r" show s-a:releases.sql; git -C "$r" show s-b:releases.sql; } |
      grep -v -E '^-- generation: |^INSERT INTO settings\(' | awk '!seen[$0]++'
    git -C "$r" show "$winning_side:releases.sql" | grep '^INSERT INTO settings('
  } > "$r/releases.sql"
}
naive_union() { # <repo> -> intentionally keeps all differing headers/settings rows
  local r="$1"
  require_fixture "$r" "merge fixture"
  { git -C "$r" show s-a:releases.sql; git -C "$r" show s-b:releases.sql; } |
    awk '!seen[$0]++' > "$r/releases.sql"
}
diverge() { # <name> <extra writes on side A>, leaves a real merge conflict on s-b
  local name="$1" extra="$2" i=0 r
  r="$(repo "$name")"
  ra "$r" init --slug "gh57-$name" >/dev/null
  git -C "$r" add releases.db releases.sql
  git -C "$r" commit -qm base
  git -C "$r" branch s-a
  git -C "$r" branch s-b
  git -C "$r" checkout -q s-a
  add_release "$r" 1.0.0 101 'side A.'
  while [ "$i" -lt "$extra" ]; do
    add_release "$r" "1.$((i + 1)).0" "$((110 + i))" "side A extra $i."
    i=$((i + 1))
  done
  git -C "$r" add releases.db releases.sql
  git -C "$r" commit -qm side-a
  git -C "$r" checkout -q s-b
  add_release "$r" 2.0.0 201 'side B.'
  git -C "$r" add releases.db releases.sql
  git -C "$r" commit -qm side-b
  git -C "$r" merge s-a -m merge >"$WORK/$name.merge.out" 2>&1 || true
  printf '%s\n' "$r"
}
refused_rebuild() { # <root> <rule> <label>
  local r="$1" rule="$2" label="$3" before after out rc
  before="$(file_hash "$r/releases.db")"
  out="$(ra "$r" check --rebuild 2>&1)"; rc=$?
  after="$(file_hash "$r/releases.db")"
  ok "$label refuses rebuild" "$( [ "$rc" -ne 0 ]; echo $? )"
  ok "$label names rule=$rule" "$( has "$out" "rule=$rule"; echo $? )"
  ok "$label leaves the live DB untouched" "$( same "$before" "$after"; echo $? )"
}

# ── Scenario 1: divergent branches merge through GID rows, not physical ids ─────────────────────
printf '%s\n' '-- Scenario 1: concurrent branch divergence and GID-keyed merge'
R1="$(diverge s1 0)"
union_dump "$R1" s-b
ra "$R1" check --rebuild >"$WORK/s1.rebuild.out" 2>&1; RC=$?
ok 'disjoint branch dumps rebuild successfully' "$RC"
COUNT="$(sql "$R1" 'SELECT COUNT(*) FROM releases')"
DISTINCT="$(sql "$R1" 'SELECT COUNT(DISTINCT global_id) FROM releases')"
ok 'ULID GIDs do not collide across concurrent branch writes' "$( [ "$COUNT" = 2 ] && [ "$DISTINCT" = 2 ]; echo $? )"
ROWIDS_BEFORE="$(sql "$R1" 'SELECT global_id || ":" || id FROM releases ORDER BY global_id')"
ra "$R1" check --rebuild >"$WORK/s1.rebuild-again.out" 2>&1; RC=$?
ROWIDS_AFTER="$(sql "$R1" 'SELECT global_id || ":" || id FROM releases ORDER BY global_id')"
ok 'rebuild deterministically renumbers physical rowids from GID-keyed dump order' "$( [ "$RC" -eq 0 ] && same "$ROWIDS_BEFORE" "$ROWIDS_AFTER"; echo $? )"
CHECK="$(ra "$R1" check 2>&1)"; RC=$?
ok 'merged receipt chain remains intact after merge-rebuild' "$( [ "$RC" -eq 0 ] && has "$CHECK" 'receipt chain intact'; echo $? )"

# ── Scenario 2: unequal writes create a multi-header refusal; resolver handles repaired merge ──
printf '%s\n' '-- Scenario 2: unequal write counts and generation headers'
R2="$(diverge s2 2)"
naive_union "$R2"
HEADERS="$(grep -c '^-- generation: ' "$R2/releases.sql")"
ok 'unequal-write union reproduces multiple generation headers' "$( [ "$HEADERS" -gt 1 ]; echo $? )"
refused_rebuild "$R2" dump-multi-generation 'multi-generation dump'
resolved_union_dump "$R2" s-a
git -C "$R2" add releases.sql
RES_OUT="$(bash "$RESOLVER" --root "$R2" 2>&1)"; RC=$?
ok 'releases-merge-resolve rebuilds the manually resolved unequal-write merge' "$RC"
CHECK="$(ra "$R2" check 2>&1)"; RC=$?
ok 'resolver leaves unequal-write merge ledger clean' "$( [ "$RC" -eq 0 ] && has "$CHECK" 'check: clean'; echo $? )"

# ── Scenario 3: the two text-merge collisions must be named and fail closed ─────────────────────
printf '%s\n' '-- Scenario 3: duplicate settings and content collision'
R3A="$(diverge s3-settings 2)"
union_dump "$R3A" s-a
SETTINGS="$(grep -c '^INSERT INTO settings(' "$R3A/releases.sql")"
ok 'header-repaired unequal union still carries duplicate settings rows' "$( [ "$SETTINGS" -gt 3 ]; echo $? )"
refused_rebuild "$R3A" dump-duplicate-setting 'duplicate settings dump'

R3B="$(repo s3-gid)"
ra "$R3B" init --slug s3-gid >/dev/null
add_release "$R3B" 3.0.0 301 'content collision seed.'
GID_LINE="$(awk '/^INSERT INTO releases\(/ { print; exit }' "$R3B/releases.sql")"
COLLISION_LINE="$(printf '%s\n' "$GID_LINE" | sed 's/content collision seed\./content collision edited on another branch./')"
printf '%s\n' "$COLLISION_LINE" >> "$R3B/releases.sql"
ok 'fixture contains two differing rows for one release GID' "$( [ "$(grep -F "$(sql "$R3B" 'SELECT global_id FROM releases LIMIT 1')" "$R3B/releases.sql" | wc -l | tr -d ' ')" -gt 1 ]; echo $? )"
refused_rebuild "$R3B" dump-duplicate-gid 'duplicate GID content collision'

# ── Scenario 4: every injected crash blocks writers until the explicit recovery check ───────────
printf '%s\n' '-- Scenario 4: crash injection and journal recovery'
for BOUNDARY in pre-commit post-commit post-stage mid-rename post-rename; do
  R4="$(repo "s4-$BOUNDARY")"
  ra "$R4" init --slug "s4-$BOUNDARY" >/dev/null
  # mid-rename is between the dump and generated-view renames, so make that second output real.
  ra "$R4" gen >/dev/null
  CRASH_OUT="$(RELEASES_APP_CRASH_AT="$BOUNDARY" ra "$R4" add --version 4.0.0 --status draft --description crash --tracking-issue "https://github.com/GH57/ledger/issues/401" 2>&1)"; RC=$?
  ok "[$BOUNDARY] injected writer exits 70" "$( [ "$RC" -eq 70 ]; echo $? )"
  BLOCK_OUT="$(ra "$R4" add --version 4.1.0 --status draft --description blocked --tracking-issue "https://github.com/GH57/ledger/issues/402" 2>&1)"; RC=$?
  ok "[$BOUNDARY] a live journal refuses the next write until check" "$( [ "$RC" -ne 0 ] && has "$BLOCK_OUT" 'rule=journal-live'; echo $? )"
  RECOVERY="$(ra "$R4" check 2>&1)"; RC=$?
  ok "[$BOUNDARY] check recovers the journal and verifies the trio" "$( [ "$RC" -eq 0 ] && has "$RECOVERY" 'check: clean'; echo $? )"
done

# ── Scenario 5: the writer lock belongs to the git common-dir, not the ledger DB ────────────────
printf '%s\n' '-- Scenario 5: writer lock contention in git common-dir'
R5="$(repo s5)"
ra "$R5" init --slug s5 >/dev/null
GIT_COMMON="$(git -C "$R5" rev-parse --path-format=absolute --git-common-dir)"
# macOS can spell the same temporary directory as /private/var/... and /var/....  Use the fixture's
# lexical spelling for fixture-guard, while proving it resolves to git's declared common-dir.
COMMON="$R5/.git"
require_fixture "$COMMON" 'git common-dir'
ok 'writer lock fixture targets the resolved git common-dir' "$( same "$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$COMMON")" "$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$GIT_COMMON")"; echo $? )"
LOCK="$COMMON/releases-app.lock"
READY="$WORK/s5.lock-ready"
python3 - "$LOCK" "$READY" <<'PY' &
import fcntl, sys, time
lock, ready = sys.argv[1:]
with open(lock, "a+") as fh:
    fcntl.flock(fh.fileno(), fcntl.LOCK_EX)
    open(ready, "w").write("ready\n")
    time.sleep(15)
PY
HOLDER=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do [ -f "$READY" ] && break; sleep 0.1; done
DB_BEFORE="$(file_hash "$R5/releases.db")"
LOCK_OUT="$(RELEASES_APP_LOCK_WAIT=0 ra "$R5" add --version 5.0.0 --status draft --description locked --tracking-issue "https://github.com/GH57/ledger/issues/501" 2>&1)"; RC=$?
DB_AFTER="$(file_hash "$R5/releases.db")"
ok 'writer contention is refused with the writer-lock rule and exit 4' "$( [ "$RC" -eq 4 ] && has "$LOCK_OUT" 'rule=writer-lock'; echo $? )"
ok 'lock refusal leaves the committed DB unchanged' "$( same "$DB_BEFORE" "$DB_AFTER"; echo $? )"
kill "$HOLDER" 2>/dev/null || true
wait "$HOLDER" 2>/dev/null || true
add_release "$R5" 5.0.0 501 'unlocked.'; RC=$?
ok 'the same writer succeeds after the common-dir lock is released' "$RC"

# ── Scenario 6: valid-looking torn input gets dump-load, never a partial live replacement ──────
printf '%s\n' '-- Scenario 6: malformed and torn dump protection'
R6="$(repo s6)"
ra "$R6" init --slug s6 >/dev/null
add_release "$R6" 6.0.0 601 'torn dump seed.'
REPO_LINE="$(awk '/^INSERT INTO repos\(/ { print; exit }' "$R6/releases.sql")"
TORN_REPO_LINE="$(printf '%s\n' "$REPO_LINE" | sed "s/'repo-[^']*'/'repo-01ARZ3NDEKTSV4RRFFQ69G5FAV'/")"
printf '%s\n' "$TORN_REPO_LINE" >> "$R6/releases.sql"
refused_rebuild "$R6" dump-load 'torn dump with duplicate repo natural key'

# ── Scenario 7: human Markdown is read-only and drift is reported beside the generated view ────
printf '%s\n' '-- Scenario 7: generated Markdown drift report'
R7="$(repo s7)"
ra "$R7" init --slug s7 >/dev/null
add_release "$R7" 7.0.0 701 'generated view seed.'
printf '%s\n' \
  'Release: 7.0.0' \
  'Status: Draft' \
  'Description: generated view seed.' \
  'Tracking Issue: https://github.com/GH57/ledger/issues/701' \
  '' \
  'Release: 7.1.0' \
  'Status: Draft' \
  'Description: hand-edited Markdown only.' \
  'Tracking Issue: https://github.com/GH57/ledger/issues/702' > "$R7/RELEASES.md"
ra "$R7" gen >"$WORK/s7.gen.out" 2>&1; RC=$?
ok 'gen produces the side-by-side generated Markdown and drift report' "$( [ "$RC" -eq 0 ] && [ -f "$R7/RELEASES.generated.md" ] && [ -f "$R7/RELEASES.generated.md.drift" ]; echo $? )"
DRIFT="$(cat "$R7/RELEASES.generated.md.drift")"
ok 'modified RELEASES.md appears in RELEASES.generated.md.drift' "$( has "$DRIFT" '[hand-edit] blocks in RELEASES.md with no DB counterpart: 7.1.0'; echo $? )"

printf '\n== gh57-releases-fuzz: %d passed, %d failed ==\n' "$pass" "$fail"
exit "$fail"
