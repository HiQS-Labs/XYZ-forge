#!/usr/bin/env bash
# test/gh90-allowlist-directory.sh — GH-90.
#
# A bare DIRECTORY on ALLOW_PATHS used to be unmatchable BY CONSTRUCTION. git collapses an
# all-untracked new directory to `dir/` in porcelain output; rtl_in_allow's exact compare failed on
# the trailing slash, and GH-59's ancestor rule requires a concrete allowlisted FILE beneath the
# directory — which a bare directory entry does not have. So the turn did real work, had it reverted,
# and reported a CONTAINMENT VIOLATION. That message names the builder, not the lane spec, which is
# why Daybreak wave 1 (2026-08-20) spent a full marathon turn and an escalation on it.
#
# THE POINT OF THIS FILE IS THAT THE FIX DID NOT WIDEN CONTAINMENT.
#
# A suite that only asserted "a directory lane now works" would pass just as happily against a build
# that turned every allowlist entry into a bare prefix — which is precisely what GH-59 removed on
# purpose. So C3 is GH-59's negative control (`green` must never reach `greenfield/output.txt`), C4
# pins that the directory semantics are opt-in per entry rather than ambient, and C6 executes a real
# off-lane write and requires it to still fail with exit 6.
#
# Hermetic: stubbed agy binary, throwaway git repos, no network.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
LIB="$ROOT/relay-automation/relay-turn-lib.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh90.XXXXXX")"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$WORK"   # GH-10: pin the sandbox root
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

echo "== test: gh90-allowlist-directory =="
echo "  workdir: $WORK"

# ── Fixture repo ──────────────────────────────────────────────────────────────────────────────────
A="$WORK/repo"; mkdir -p "$A/fixtures/lens-2" "$A/greenfield"
git -C "$A" init -q 2>/dev/null; git -C "$A" symbolic-ref HEAD refs/heads/main 2>/dev/null
printf 'STATUS: Open\nNEXT: Producer\n# relay body\n' >"$A/relay.md"
printf 'x\n' >"$A/collect.sh"
printf 'x\n' >"$A/green"
printf 'x\n' >"$A/fixtures/lens-2/in.json"
printf 'x\n' >"$A/greenfield/output.txt"
printf '.tick/\n*.log\nbin/\n' >"$A/.gitignore"
git -C "$A" -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1
git -C "$A" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1

# Ask rtl_in_allow a question in a fresh shell, so no state leaks between cases.
# <allow-csv> <path-to-test...> → prints "path=YES|NO" per path.
ask() {
  local csv="$1"; shift
  ALLOW_CSV="$csv" RTL_TOOL=test bash -c '
    set -uo pipefail
    source "$0" >/dev/null 2>&1
    rtl_init "$1" "$1/relay.md" "$ALLOW_CSV" >/dev/null 2>&1
    shift 2
    for p in "$@"; do
      if rtl_in_allow "$p"; then printf "%s=YES\n" "$p"; else printf "%s=NO\n" "$p"; fi
    done
  ' "$LIB" "$A" -- "$@" 2>/dev/null
}

expect() { # <label> <allow-csv> <path> <YES|NO>
  local label="$1" csv="$2" p="$3" want="$4" got
  got="$(ask "$csv" "$p" | head -1)"
  [ "$got" = "$p=$want" ] \
    && pass "$label" \
    || fail "$label — expected $p=$want, got '${got:-<none>}'"
}

# ── Case 1: THE FIX — a bare entry naming an EXISTING directory covers the lane ───────────────────
# All three forms git can emit for that lane: the collapsed porcelain form, a file beneath it, and a
# deeper path. Before GH-90 every one of these answered NO.
expect "C1 collapsed porcelain form 'fixtures/' matches the directory lane" \
  "fixtures" "fixtures/" YES
expect "C1b a file directly beneath the directory lane matches" \
  "fixtures" "fixtures/lens-2/in.json" YES
expect "C1c a newly nested path beneath the directory lane matches" \
  "fixtures" "fixtures/lens-7/new/deep.json" YES

# ── Case 2: a TRAILING SLASH declares a lane for a directory that does not exist yet ──────────────
# This is the case rtl_init cannot infer — the turn is about to create the directory, so there is
# nothing on disk to test. The slash is the only available signal, and it must not require the path
# to exist.
[ ! -e "$A/nofixtures" ] || fail "C2 precondition: nofixtures/ should not exist"
expect "C2 a trailing-slash entry works for a not-yet-created directory" \
  "nofixtures/" "nofixtures/" YES
expect "C2b and for a file the turn creates inside it" \
  "nofixtures/" "nofixtures/lens-9/out.json" YES

# ── Case 3: GH-59's NEGATIVE CONTROL — a file entry is never a bare prefix ────────────────────────
# `green` is a real FILE here, so nothing about it declares a directory. If this ever answers YES,
# the fix regressed into the ambient prefix matching GH-59 deliberately removed.
expect "C3 THE PIN — a file entry does NOT match a same-prefix sibling directory" \
  "green" "greenfield/" NO
expect "C3b nor a file inside that sibling directory" \
  "green" "greenfield/output.txt" NO
expect "C3c and the file entry itself still matches exactly" \
  "green" "green" YES

# ── Case 4: the directory semantics are OPT-IN PER ENTRY, not ambient ─────────────────────────────
# One directory entry alongside one file entry: the file entry must not acquire prefix behaviour by
# sitting in the same allowlist as a directory entry.
expect "C4 a directory entry does not confer prefix matching on its file peers" \
  "fixtures,collect.sh" "collect.sh.bak" NO
expect "C4b while the directory peer in the same allowlist still covers its lane" \
  "fixtures,collect.sh" "fixtures/lens-3/a.json" YES

# ── Case 5: GH-59's own rule still stands on its own ──────────────────────────────────────────────
# A collapsed `dir/` that is a TRUE ANCESTOR of a concrete allowlisted file is still allowed, with no
# directory entry involved. This is the behaviour GH-90 had to preserve, not replace.
expect "C5 GH-59 intact — 'greenfield/' allowed as ancestor of an allowlisted file beneath it" \
  "greenfield/output.txt" "greenfield/" YES
expect "C5b and a SIBLING of that file is still refused" \
  "greenfield/output.txt" "greenfield/other.txt" NO

# ── Case 6: END TO END — a directory lane survives a real isolated turn, an off-lane write does not ─
# C1-C5 test the predicate. This tests the harness: worktree seed, copy-back, and the exit-6 verdict.
# Without it, the suite would pass against a build where rtl_in_allow is right but nothing calls it.
SHIM="$ROOT/relay-automation/agy-turn.sh"
TICK="$ROOT/bin/tick"
mkdir -p "$A/bin"; ln -sf "$TICK" "$A/bin/tick"

# GH-441: keep token ops inside the fixture, never the ambient repo's .tick/ log.
for _t in dirlane offlane; do
  TICK_REPO_ROOT="$A" "$TICK" log     task.created "T90-$_t" --agent claude-a >/dev/null 2>&1
  TICK_REPO_ROOT="$A" "$TICK" claim   "T90-$_t" --agent claude-a --paths "relay.md" >/dev/null 2>&1
  TICK_REPO_ROOT="$A" "$TICK" release "T90-$_t" --agent claude-a --to agy >/dev/null 2>&1
done

mkdir -p "$WORK/bin"
cat >"$WORK/bin/agy-stub" <<'STUB'
#!/usr/bin/env bash
# Writes into the CURRENT DIRECTORY, which under isolation is the throwaway worktree — that is what
# rtl.worktree_end() diffs. Writing to $AGY_TURN_ROOT would land outside the worktree entirely.
printf 'stub: took the turn\n'   # non-empty transcript; an empty one is its own failure (exit 5)
if [ "${STUB_MODE:-dirlane}" = dirlane ]; then
  mkdir -p ./fixtures/lens-3
  printf '{"lens":3}\n' >./fixtures/lens-3/in.json     # a NEW subdir inside the directory lane
  printf 'built\n'      >>./collect.sh                 # and an ordinary file lane, unchanged behaviour
fi
[ "${STUB_MODE:-dirlane}" = offlane ] && printf 'off-lane\n' >>./elsewhere.md
printf '\n## agy-stub\nSTATUS: Approved\n' >>"$AGY_TURN_ROOT/relay.md"
exit 0
STUB
chmod +x "$WORK/bin/agy-stub"

run_turn() { # <stub-mode> <allow-csv> <logfile>
  RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK="T90-$1" AGY_AGENT=agy \
    TICK_REPO_ROOT="$A" \
    AGY_BIN="$WORK/bin/agy-stub" AGY_TURN_ROOT="$A" AGY_LOG="$3" STUB_MODE="$1" \
    ALLOW_PATHS="$2" RELAY_WORKTREE_ISOLATION=1 \
    bash "$SHIM" >/dev/null 2>&1; echo $?
}

if [ -x "$SHIM" ]; then
  dlog="$WORK/dirlane.log"; : >"$dlog"
  rc="$(run_turn dirlane "relay.md,fixtures,collect.sh" "$dlog")"
  [ "$rc" = "0" ] \
    && pass "C6 a directory lane completes the turn cleanly (exit 0 — it used to be 6)" \
    || fail "C6 THE BUG — a directory lane did not complete cleanly (exit $rc; 6 = the original defect)"
  [ -f "$A/fixtures/lens-3/in.json" ] \
    && pass "C6b the turn's new file inside the directory lane was copied back to the repo" \
    || fail "C6b the directory lane's new file never reached the repo"
  grep -q 'built' "$A/collect.sh" 2>/dev/null \
    && pass "C6c the ordinary FILE lane in the same allowlist still copied back" \
    || fail "C6c the file lane regressed"

  # THE COUNTER-PIN. Without this, C6 would pass against a build with containment deleted.
  ologf="$WORK/offlane.log"; : >"$ologf"
  rc_off="$(run_turn offlane "relay.md,fixtures" "$ologf")"
  [ "$rc_off" = "6" ] \
    && pass "C7 a write OUTSIDE the directory lane still fails the turn (exit 6)" \
    || fail "C7 off-lane write did not fail — containment is gone (got $rc_off)"
  [ ! -f "$A/elsewhere.md" ] \
    && pass "C7b the off-lane file did not reach the fixture repo" \
    || fail "C7b an off-lane write reached the fixture repo"
  [ -f "$ROOT/elsewhere.md" ] \
    && fail "GH-426 regression: the stub's off-lane creation reached the harness root"
else
  fail "C6 shim not executable: $SHIM"
fi

# ── Case 8: the residual case is NAMED, not silent ────────────────────────────────────────────────
# An entry for a directory that does not exist yet AND carries no trailing slash is byte-identical to
# a mistyped file path, so it cannot be refused at init. It can be explained at the moment it costs
# something: the off-lane report must say which entry is being read as a file and how to declare it.
hint="$(ALLOW_CSV="notyet" RTL_TOOL=test bash -c '
  set -uo pipefail
  source "$0" >/dev/null 2>&1
  rtl_init "$1" "$1/relay.md" "$ALLOW_CSV" >/dev/null 2>&1
  rtl_offlane_hint "notyet/lens-4/out.json"
' "$LIB" "$A" 2>&1)"
case "$hint" in
  *'"notyet"'*'trailing slash'*) pass "C8 the off-lane report names the file-vs-directory lane mistake" ;;
  *) fail "C8 no GH-90 hint emitted — the residual case is still a bare 'containment violation': $hint" ;;
esac
# And it must stay ADVISORY: a genuinely unrelated off-lane path gets no hint at all.
quiet="$(ALLOW_CSV="notyet" RTL_TOOL=test bash -c '
  set -uo pipefail
  source "$0" >/dev/null 2>&1
  rtl_init "$1" "$1/relay.md" "$ALLOW_CSV" >/dev/null 2>&1
  rtl_offlane_hint "totally/unrelated.md"
' "$LIB" "$A" 2>&1)"
case "$quiet" in
  *'trailing slash'*) fail "C8b the hint fires on unrelated paths — it would become noise: $quiet" ;;
  *) pass "C8b an unrelated off-lane path gets no hint" ;;
esac

echo
echo "  ${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ]
