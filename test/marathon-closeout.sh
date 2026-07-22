#!/usr/bin/env bash
# Regression test for marathon-closeout.sh (GH-273 Phase 3).
# Hermetic: git and gh are PATH-shadowed; no real repository or network is touched.
set -u
set -o pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CLOSEOUT="$HERE/../relay-automation/marathon-closeout.sh"
PASS=0
FAIL=0

pass() { printf '  PASS: %s\n' "$*"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL: %s\n' "$*" >&2; FAIL=$((FAIL + 1)); }

WORK="$(mktemp -d -t marathon-closeout.XXXXXX)" || { echo "FAIL: mktemp failed" >&2; exit 1; }
[[ -n "$WORK" && -d "$WORK" ]] || { echo "FAIL: invalid temp directory" >&2; exit 1; }
trap 'rm -rf "$WORK"' EXIT

FAKE_BIN="$WORK/bin"
REPO="$WORK/repo"
mkdir -p "$FAKE_BIN" "$REPO"
printf 'manual operator edit\n' >"$REPO/manual.txt"

cat >"$FAKE_BIN/git" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$GIT_LOG"
case "$*" in
  "rev-parse --is-inside-work-tree") printf 'true\n' ;;
  "branch --show-current") printf '%s\n' "${STUB_HEAD:-marathon/gh-273}" ;;
esac
if [[ -n "${GIT_FAIL_ON:-}" && "$*" == *"$GIT_FAIL_ON"* ]]; then exit 1; fi
exit 0
EOF

cat >"$FAKE_BIN/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$GH_LOG"
case "$*" in
  "pr create "*) printf '%s\n' 'https://example.invalid/pull/273' ;;
  "pr checks "*) exit "${GH_CHECKS_RC:-0}" ;;
  "pr view "*) printf '%s\n' "${GH_MERGEABLE:-MERGEABLE}" ;;
esac
exit 0
EOF
chmod +x "$FAKE_BIN/git" "$FAKE_BIN/gh"

export PATH="$FAKE_BIN:$PATH"
export GIT_LOG="$WORK/git.log"
export GH_LOG="$WORK/gh.log"

reset_logs() { rm -f "$GIT_LOG" "$GH_LOG"; }
contains_line() { grep -Fqx -- "$2" "$1" 2>/dev/null; }

echo "== test: marathon-closeout =="

# 1. Dry-run renders every operation without invoking either shadow binary or changing files.
reset_logs
before="$(cksum "$REPO/manual.txt")"
out="$(bash "$CLOSEOUT" --dry-run --repo "$REPO" --head marathon/gh-273 \
  --message 'close the marathon' --title 'GH-273 closeout' --notes 'tested notes')"
rc=$?
after="$(cksum "$REPO/manual.txt")"
if [[ $rc -eq 0 && ! -e "$GIT_LOG" && ! -e "$GH_LOG" && "$before" == "$after" ]]; then
  pass "dry-run executes no git/gh command and mutates nothing"
else
  fail "dry-run was not inert (rc=$rc)"
fi
for expected in \
  "git add -A" \
  "git commit -m close\\ the\\ marathon" \
  "git push -u origin marathon/gh-273" \
  "gh pr create --base development --head marathon/gh-273" \
  "gh pr checks" \
  "gh pr merge" \
  "git switch development" \
  "git pull --ff-only origin development"
do
  if grep -Fq -- "$expected" <<<"$out"; then pass "dry-run prints: $expected"; else fail "dry-run missing: $expected"; fi
done

# 2. Happy path runs the complete sequence; `git add -A` captures pre-existing manual edits.
reset_logs
GH_CHECKS_RC=0 GH_MERGEABLE=MERGEABLE \
  bash "$CLOSEOUT" --repo "$REPO" --message 'close the marathon' \
    --title 'GH-273 closeout' --notes 'tested notes' >"$WORK/happy.out" 2>"$WORK/happy.err"
rc=$?
if [[ $rc -eq 0 ]]; then pass "green, mergeable PR exits 0"; else fail "happy path rc=$rc"; fi
contains_line "$GIT_LOG" "add -A" \
  && pass "manual pre-existing edits are included with git add -A" \
  || fail "closeout did not stage all edits"
contains_line "$GIT_LOG" "commit -m close the marathon" \
  && contains_line "$GIT_LOG" "push -u origin marathon/gh-273" \
  && contains_line "$GIT_LOG" "switch development" \
  && contains_line "$GIT_LOG" "pull --ff-only origin development" \
  && contains_line "$GH_LOG" "pr merge https://example.invalid/pull/273 --merge" \
  && pass "happy path commits, pushes, merges, switches, and pulls" \
  || fail "happy path command sequence incomplete"

# 3. Red checks use the documented policy exit 4 and halt before merge/switch/pull.
reset_logs
GH_CHECKS_RC=1 GH_MERGEABLE=MERGEABLE \
  bash "$CLOSEOUT" --repo "$REPO" >"$WORK/red.out" 2>"$WORK/red.err"
rc=$?
if [[ $rc -eq 4 ]]; then pass "red checks exit 4"; else fail "red checks expected exit 4, got $rc"; fi
if ! grep -q '^pr merge ' "$GH_LOG" 2>/dev/null \
  && ! grep -q '^switch ' "$GIT_LOG" 2>/dev/null \
  && ! grep -q '^pull ' "$GIT_LOG" 2>/dev/null; then
  pass "red checks halt before merge and local branch update"
else
  fail "red checks allowed post-check commands"
fi

# 4. An unmergeable PR also exits 4 and never attempts the merge.
reset_logs
GH_CHECKS_RC=0 GH_MERGEABLE=CONFLICTING \
  bash "$CLOSEOUT" --repo "$REPO" >"$WORK/conflict.out" 2>"$WORK/conflict.err"
rc=$?
if [[ $rc -eq 4 && ! $(grep -c '^pr merge ' "$GH_LOG" 2>/dev/null) -gt 0 ]]; then
  pass "unmergeable PR exits 4 before merge"
else
  fail "unmergeable PR handling rc=$rc"
fi

# 5. Command failures normalize to exit 3; argument/precondition errors use exit 2.
reset_logs
GIT_FAIL_ON='push -u' GH_CHECKS_RC=0 GH_MERGEABLE=MERGEABLE \
  bash "$CLOSEOUT" --repo "$REPO" >"$WORK/fail.out" 2>"$WORK/fail.err"
rc=$?
if [[ $rc -eq 3 ]]; then pass "git/gh command failure exits 3"; else fail "command failure expected exit 3, got $rc"; fi

bash "$CLOSEOUT" --dry-run --repo "$REPO" >"$WORK/usage.out" 2>"$WORK/usage.err"
rc=$?
if [[ $rc -eq 2 ]]; then pass "invalid dry-run invocation exits 2"; else fail "usage expected exit 2, got $rc"; fi

if bash -n "$CLOSEOUT" && bash -n "$0"; then pass "scripts are bash -n clean"; else fail "bash syntax check failed"; fi

printf '== marathon-closeout: %d passed, %d failed ==\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
