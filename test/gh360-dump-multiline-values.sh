#!/usr/bin/env bash
# #360 — a dumped value containing a newline must round-trip through parse_dump.
#
# business_digest/dump_text happily WRITE a multi-line value (a roadmap_items raw_text, a release
# description pasted from a doc). INSERT_RE was compiled without re.DOTALL, so `(.*)` could never
# match across the newline: parse_dump's multi-line buffer grew forever, swallowed every INSERT
# after it, and `check --rebuild` refused with rule=dump-parse naming a line that was fine.
#
# That killed the ONLY documented git-merge resolution path for any ledger holding such a value —
# measured on LTVera-Pandas 2026-08-31, where one roadmap_items raw_text carried a bulleted list.
#
# Usage: bash test/gh360-dump-multiline-values.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
# shellcheck source=/dev/null
source "$HERE/_setup.sh" gh360-dump-multiline-values

APP="$ROOT_DIR/utils/py/releases_app.py"
command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 required" >&2; exit 1; }

RA() { python3 "$APP" --root "$1" "${@:2}"; }

R="$WORK/multiline"
case "$R" in "$WORK"/*) ;; *) echo "REFUSING: $R outside WORK" >&2; exit 2 ;; esac
mkdir -p "$R"
git -C "$R" init -q; git -C "$R" config user.email t@t; git -C "$R" config user.name t
RA "$R" init --slug m > /dev/null

DESC='Line one.
  - a bulleted continuation
  - and another'
RA "$R" add --version 1.0.0 --status draft --tracking-issue TMP-AAAAAA --description "$DESC" > /dev/null

# ── the fixture must be real: the dump has to actually contain a multi-line statement ───────────
python3 - "$R/releases.sql" <<'PY'
import sys
lines = open(sys.argv[1]).read().split("\n")
bad = [l for l in lines if l.startswith("INSERT INTO ") and not l.rstrip().endswith(");")]
sys.exit(0 if bad else 1)
PY
[ $? = 0 ] \
  && pass "fixture is real: the dump contains an INSERT whose value spans lines" \
  || fail "the dump has no multi-line statement; every assertion below would be vacuous"

# ── plain check must pass ───────────────────────────────────────────────────────────────────────
RA "$R" check > "$WORK/o1" 2>&1 \
  && pass "check passes on a ledger holding a multi-line value" \
  || { sed 's/^/    /' "$WORK/o1" >&2; fail "check failed on a multi-line value; see $WORK/o1"; }

# ── the rebuild — the merge-resolution path — must not refuse its own dump ──────────────────────
BEFORE="$(sqlite3 "$R/releases.db" 'SELECT COUNT(*) FROM releases')"
RA "$R" check --rebuild > "$WORK/o2" 2>&1
RC=$?
[ "$RC" = "0" ] \
  && pass "--rebuild accepts the dump the app itself wrote (rc=0)" \
  || { sed 's/^/    /' "$WORK/o2" >&2; fail "--rebuild refused its own dump; see $WORK/o2"; }
grep -q "rule=dump-parse" "$WORK/o2" \
  && { sed 's/^/    /' "$WORK/o2" >&2; fail "--rebuild refused with dump-parse — the DOTALL bug is back"; } \
  || pass "no rule=dump-parse refusal"

# ── and the value must survive the round trip byte for byte ─────────────────────────────────────
AFTER="$(sqlite3 "$R/releases.db" 'SELECT COUNT(*) FROM releases')"
[ "$BEFORE" = "$AFTER" ] \
  && pass "the rebuild preserved every release row ($BEFORE)" \
  || fail "the rebuild lost rows ($BEFORE -> $AFTER)"
GOT="$(sqlite3 "$R/releases.db" "SELECT description FROM releases WHERE version='1.0.0'")"
[ "$GOT" = "$DESC" ] \
  && pass "the multi-line description round-tripped unchanged" \
  || { printf '    got: %q\n    want: %q\n' "$GOT" "$DESC" >&2; fail "the multi-line value was mangled by the rebuild"; }

RA "$R" check > "$WORK/o3" 2>&1 \
  && pass "check still passes after the rebuild" \
  || { sed 's/^/    /' "$WORK/o3" >&2; fail "check failed after the rebuild; see $WORK/o3"; }

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
[ "$FAIL" = "0" ] || exit 1
exit 0
