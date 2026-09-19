#!/usr/bin/env bash
# gh589-consult-no-tick.sh — GH-589 criterion 4: consult runs in the exported XYZ mini package with
# no bin/tick, PROJECT/ or releases.db; an explicit broken TICK_BIN stays fatal; empty output is not an answer.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
echo "== test: gh589-consult-no-tick =="
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh589-notick.XXXXXX")"
cleanup(){ [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT
. "$HERE/lib/fixture-guard.sh"
require_forge_root .git   # GH-708: forge-root only — witnessed skip in a vendored .xyz/
fixture_guard_init "$WORK"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

BARE="$WORK/remote.git"; git init -q --bare "$BARE"; git -C "$BARE" symbolic-ref HEAD refs/heads/main
PKG="$WORK/pkg"; git clone -q "$BARE" "$PKG" 2>/dev/null; git -C "$PKG" symbolic-ref HEAD refs/heads/main
SRC="$WORK/src"; git clone -q "$REPO" "$SRC"
python3 "$SRC/utils/py/xyz_mini_sync.py" --dest "$PKG" --apply >/dev/null 2>"$WORK/pub.err" && pass "publisher built the package" || { fail "publisher: $(tail -2 "$WORK/pub.err")"; exit 1; }
[ ! -e "$PKG/bin/tick" ] && [ ! -e "$PKG/PROJECT" ] && [ ! -e "$PKG/releases.db" ] && pass "package has no bin/tick, PROJECT/ or releases.db" || fail "governance leaked"

BIN="$WORK/bin"; mkdir -p "$BIN"
printf '#!/usr/bin/env bash\nprintf "model: stub\\nprovider: stub\\nsandbox: read-only\\n\\n[Pass] via \\`README.md:1\\` \\"XYZ mini\\".\\n"\n' >"$BIN/codex"
printf '#!/usr/bin/env bash\ncase "${1:-}" in whoami|models) echo stub; exit 0;; esac\nprintf "[Pass] via \\`README.md:1\\` \\"XYZ mini\\".\\n"\n' >"$BIN/agy"
printf '#!/usr/bin/env bash\ncase "${1:-}" in whoami|models) echo stub; exit 0;; esac\nexit 0\n' >"$BIN/agy-empty"
chmod +x "$BIN"/*
scrub(){ env -i HOME="$HOME" TMPDIR="${TMPDIR:-/tmp}" PATH="$BIN:/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin" GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null "$@"; }
consult(){ local out="$1"; shift; scrub env "$@" bash "$PKG/relay-automation/consult.sh" --prompt smoke --models codex,agy --out "$out" --label t; }
two(){ [ -s "$(find "$1" -name 't.codex.md' | head -1)" ] && [ -s "$(find "$1" -name 't.agy.md' | head -1)" ]; }

OUT="$WORK/a"; mkdir -p "$OUT"; consult "$OUT" >/dev/null 2>"$WORK/a.err"; rc=$?
[ $rc -eq 0 ] && two "$OUT" && grep -q "tick not found" "$WORK/a.err" && pass "4. Python lane: exit 0, two transcripts, degrade warning, no tick" || fail "4. rc=$rc $(tail -2 "$WORK/a.err")"
OUT="$WORK/b"; mkdir -p "$OUT"; consult "$OUT" XYZ_PYTHON=0 >/dev/null 2>&1; rc=$?
[ $rc -eq 0 ] && two "$OUT" && pass "4. Bash lane (XYZ_PYTHON=0) also runs clean" || fail "4. bash lane rc=$rc"
OUT="$WORK/c"; mkdir -p "$OUT"; consult "$OUT" TICK_BIN=/nonexistent/tick >/dev/null 2>"$WORK/c.err"; rc=$?
[ $rc -ne 0 ] && grep -q "TICK_BIN is set but not an executable file" "$WORK/c.err" && pass "explicit broken TICK_BIN is fatal" || fail "explicit TICK_BIN rc=$rc"
OUT="$WORK/d"; mkdir -p "$OUT"; consult "$OUT" AGY_BIN="$BIN/agy-empty" >"$WORK/d.out" 2>&1; rc=$?
[ $rc -eq 0 ] && grep -q "1 answered, 1 failed" "$WORK/d.out" && pass "exit-0 empty agy counts as failed (degraded, not a full panel)" || fail "empty agy rc=$rc $(grep answered "$WORK/d.out")"

echo "gh589-consult-no-tick: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
