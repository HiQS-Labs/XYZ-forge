#!/usr/bin/env bash
# #54 — `check --rebuild` must REFUSE merge damage, by name, instead of throwing.
#
# The rebuild is the merge-resolution path. When it is handed a dump a text merge mangled, the
# operator is mid-merge and needs to know which line to fix. Before this, they got a Python
# traceback from inside load_dump: correct in that nothing was written, useless in that it named
# neither the problem nor the fix.
#
# Every fixture here is built by actually merging two divergent branches and mangling the dump the
# way a real merge would — not by hand-writing a broken file. A refusal test whose fixture cannot
# occur in practice proves the refusal works on inputs nobody will ever supply.
#
# The three shapes, all measured from real merges:
#   1. two '-- generation:' headers   — a union where the branches made unequal numbers of writes
#   2. a duplicated `settings` row    — a union where they made equal numbers of writes
#   3. the same global_id twice       — both branches edited ONE release; no union can settle this
#
# Usage: bash test/gh54-merged-dump-refusals.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
# shellcheck source=/dev/null
source "$HERE/_setup.sh" gh54-merged-dump-refusals

APP="$ROOT_DIR/utils/py/releases_app.py"
command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 required" >&2; exit 1; }

RA() { python3 "$APP" --root "$1" "${@:2}"; }

diverge() { # <dir> <extra writes on side A> — two branches that both wrote; leaves you on s-b
  local R="$1" extra="$2" i=0
  case "$R" in "$WORK"/*) ;; *) echo "REFUSING: $R outside WORK" >&2; exit 2 ;; esac
  mkdir -p "$R"
  git -C "$R" init -q; git -C "$R" config user.email t@t; git -C "$R" config user.name t
  RA "$R" init --slug m > /dev/null
  git -C "$R" add -A; git -C "$R" commit -qm base
  git -C "$R" branch s-a; git -C "$R" branch s-b
  git -C "$R" checkout -q s-a
  RA "$R" add --version 1.0.0 --status draft --tracking-issue TMP-AAAAAA --description "A one." > /dev/null
  while [ "$i" -lt "$extra" ]; do
    RA "$R" add --version "1.$i.9" --status draft --tracking-issue "TMP-AAAA0$i" --description "A extra." > /dev/null
    i=$((i+1))
  done
  git -C "$R" commit -qam a
  git -C "$R" checkout -q s-b
  RA "$R" add --version 2.0.0 --status draft --tracking-issue TMP-BBBBBB --description "B one." > /dev/null
  git -C "$R" commit -qam b
}

naive_union() { # <dir> — exactly what git's built-in merge=union leaves behind
  local R="$1"
  { git -C "$R" show s-b:releases.sql; git -C "$R" show s-a:releases.sql; } \
    | awk '!seen[$0]++' > "$R/releases.sql"
}

rows_now() { sqlite3 "$1/releases.db" 'SELECT COUNT(*) FROM releases'; }

assert_refused() { # <label> <dir> <expected rule> <outfile>
  local label="$1" R="$2" rule="$3" out="$4" before after
  before="$(rows_now "$R")"
  RA "$R" check --rebuild > "$out" 2>&1
  local rc=$?
  after="$(rows_now "$R")"

  [ "$rc" != "0" ] \
    && pass "$label: refused (rc=$rc)" \
    || fail "$label: --rebuild SUCCEEDED on a mangled dump; see $out"
  grep -q "rule=$rule" "$out" \
    && pass "$label: names rule=$rule, so the operator knows which line to fix" \
    || { sed 's/^/    /' "$out" >&2; fail "$label: expected rule=$rule; see $out"; }
  [ "$(grep -c 'Traceback' "$out")" = "0" ] \
    && pass "$label: no Python traceback — a refusal, not a crash" \
    || fail "$label: threw a traceback instead of refusing; see $out"
  [ "$before" = "$after" ] \
    && pass "$label: the live DB is untouched ($before rows before and after)" \
    || fail "$label: the live DB CHANGED during a refused rebuild ($before -> $after)"
}

# ── 1. two generation headers (unequal write counts) ────────────────────────────────────────────
R1="$WORK/twohdr"; diverge "$R1" 2; naive_union "$R1"
H="$(grep -c '^-- generation: ' "$R1/releases.sql")"
[ "$H" -gt 1 ] \
  && pass "fixture is real: a naive union of unequal-write branches produced $H generation headers" \
  || fail "fixture did not reproduce the two-header shape; the assertions below would be vacuous"
assert_refused "two-header dump" "$R1" "dump-multi-generation" "$WORK/o1"

# ── 2. duplicated settings row (header deduped, but the settings rows still differ) ─────────────
# Note the write counts must be UNEQUAL. With equal counts both sides emit a byte-identical
# `generation` settings row, the union dedupes it, and there is nothing to catch — which is exactly
# why the equal-write union looks deceptively clean. The duplicate only appears when the generation
# values differ, i.e. when one branch wrote more times than the other.
R2="$WORK/dupset"; diverge "$R2" 2
{ git -C "$R2" show s-b:releases.sql | grep '^-- generation'
  { git -C "$R2" show s-b:releases.sql; git -C "$R2" show s-a:releases.sql; } \
    | grep -v '^-- generation' | awk '!seen[$0]++'
} > "$R2/releases.sql"
S="$(grep -c 'INSERT INTO settings(' "$R2/releases.sql")"
[ "$S" -gt 1 ] \
  && pass "fixture is real: header-deduped union still left $S settings rows" \
  || fail "fixture did not reproduce the duplicate-settings shape"
assert_refused "duplicate settings row" "$R2" "dump-duplicate-setting" "$WORK/o2"

# ── 3. the same global_id twice — a real content conflict ───────────────────────────────────────
# Both branches edit ONE release. A union keeps both versions of that row, and no merge rule can
# decide which is right: that is a human decision, and the refusal must say so rather than pick.
R3="$WORK/dupgid"; diverge "$R3" 0
GID="$(sqlite3 "$R3/releases.db" "SELECT global_id FROM releases LIMIT 1")"
[ -n "$GID" ] && pass "fixture has a release to duplicate ($GID)" || fail "no release in the fixture"
# take the dump's own row for that GID and append a second, differing copy
grep "INSERT INTO releases(" "$R3/releases.sql" | grep "$GID" | head -1 \
  | sed "s/B one\./B one EDITED ON THE OTHER BRANCH./" >> "$R3/releases.sql"
D="$(grep -c "$GID" "$R3/releases.sql")"
[ "$D" -gt 1 ] \
  && pass "fixture is real: global_id $GID now appears $D times, as a union of two edits would leave it" \
  || fail "could not duplicate the GID row"
assert_refused "same global_id twice" "$R3" "dump-duplicate-gid" "$WORK/o3"
grep -qi "both branches edited" "$WORK/o3" \
  && pass "the GID refusal explains it is a CONTENT conflict, not a mechanical one" \
  || fail "the duplicate-GID refusal did not explain why no union can settle it"

# ── 4. POSITIVE CONTROL: a correctly merged dump still rebuilds ─────────────────────────────────
# Without this, every refusal above is satisfiable by a rebuild that refuses everything.
R4="$WORK/good"; diverge "$R4" 0
{ git -C "$R4" show s-b:releases.sql | grep '^-- generation'
  { git -C "$R4" show s-b:releases.sql; git -C "$R4" show s-a:releases.sql; } \
    | grep -v '^-- generation' | awk '!seen[$0]++' | grep -v 'INSERT INTO settings('
  git -C "$R4" show s-a:releases.sql | grep 'INSERT INTO settings(' | head -2
} > "$R4/releases.sql"

if RA "$R4" check --rebuild > "$WORK/o4" 2>&1; then
  pass "POSITIVE CONTROL: a correctly merged dump still rebuilds (the refusals are not blanket)"
  R4ROWS="$(rows_now "$R4")"
  [ "$R4ROWS" = "2" ] \
    && pass "POSITIVE CONTROL: both sides' releases survived (2 rows)" \
    || fail "expected 2 releases after a clean merge, got $R4ROWS"
else
  sed 's/^/    /' "$WORK/o4" >&2
  fail "POSITIVE CONTROL FAILED: a correctly merged dump was refused; the new checks are too strict"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
[ "$FAIL" = "0" ] || exit 1
exit 0
