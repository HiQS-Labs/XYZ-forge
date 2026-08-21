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
  "diff --cached --quiet") exit "${GIT_CACHED_DIFF_RC:-1}" ;;
esac
if [[ -n "${GIT_FAIL_ON:-}" && "$*" == *"$GIT_FAIL_ON"* ]]; then exit 1; fi
exit 0
EOF

cat >"$FAKE_BIN/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$GH_LOG"
case "$*" in
  "pr list "*) printf '%s\n' "${GH_EXISTING_PR:-}" ;;
  "pr create "*) printf '%s\n' 'https://example.invalid/pull/273' ;;
  "pr checks "*) exit "${GH_CHECKS_RC:-0}" ;;
  "pr view "*) printf '%s\n' "${GH_MERGEABLE:-MERGEABLE}" ;;
esac
if [[ -n "${GH_FAIL_ON:-}" && "$*" == *"$GH_FAIL_ON"* ]]; then exit 1; fi
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
  "git diff --cached --quiet" \
  "git commit -m close\\ the\\ marathon" \
  "git push -u origin marathon/gh-273" \
  "gh pr list --head marathon/gh-273 --base development --state open" \
  "gh pr create --base development --head marathon/gh-273" \
  "gh pr checks" \
  "gh pr merge" \
  "git switch development" \
  "git pull --ff-only origin development"
do
  if grep -Fq -- "$expected" <<<"$out"; then pass "dry-run prints: $expected"; else fail "dry-run missing: $expected"; fi
done

# 2. Happy path runs the complete sequence with skip-gate-check for mock environment.
reset_logs
GIT_CACHED_DIFF_RC=1 GH_CHECKS_RC=0 GH_MERGEABLE=MERGEABLE \
  bash "$CLOSEOUT" --repo "$REPO" --skip-gate-check --message 'close the marathon' \
    --title 'GH-273 closeout' --notes 'tested notes' >"$WORK/happy.out" 2>"$WORK/happy.err"
rc=$?
if [[ $rc -eq 0 ]]; then pass "green, mergeable PR exits 0"; else fail "happy path rc=$rc"; fi
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
  bash "$CLOSEOUT" --repo "$REPO" --skip-gate-check >"$WORK/red.out" 2>"$WORK/red.err"
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
  bash "$CLOSEOUT" --repo "$REPO" --skip-gate-check >"$WORK/conflict.out" 2>"$WORK/conflict.err"
rc=$?
if [[ $rc -eq 4 && ! $(grep -c '^pr merge ' "$GH_LOG" 2>/dev/null) -gt 0 ]]; then
  pass "unmergeable PR exits 4 before merge"
else
  fail "unmergeable PR handling rc=$rc"
fi

# 5. Command failures normalize to exit 3; argument/precondition errors use exit 2.
reset_logs
GIT_FAIL_ON='push -u' GH_CHECKS_RC=0 GH_MERGEABLE=MERGEABLE \
  bash "$CLOSEOUT" --repo "$REPO" --skip-gate-check >"$WORK/fail.out" 2>"$WORK/fail.err"
rc=$?
if [[ $rc -eq 3 ]]; then pass "git/gh command failure exits 3"; else fail "command failure expected exit 3, got $rc"; fi

bash "$CLOSEOUT" --dry-run --repo "$REPO" >"$WORK/usage.out" 2>"$WORK/usage.err"
rc=$?
if [[ $rc -eq 2 ]]; then pass "invalid dry-run invocation exits 2"; else fail "usage expected exit 2, got $rc"; fi

# 6. --open-only creates (or reuses) a PR but never checks, merges, switches, or pulls.
reset_logs
GH_CHECKS_RC=0 GH_MERGEABLE=MERGEABLE \
  bash "$CLOSEOUT" --open-only --skip-gate-check --repo "$REPO" --notes 'open-only notes' >"$WORK/open.out" 2>"$WORK/open.err"
rc=$?
if [[ $rc -eq 0 ]] \
  && contains_line "$GH_LOG" "pr create --base development --head marathon/gh-273 --title Marathon closeout --body open-only notes" \
  && ! grep -q '^pr checks \|^pr view \|^pr merge ' "$GH_LOG" 2>/dev/null \
  && ! grep -q '^switch \|^pull ' "$GIT_LOG" 2>/dev/null; then
  pass "open-only stops after opening the PR"
else
  fail "open-only ran commands beyond PR creation (rc=$rc)"
fi

# 7. A clean index does not make closeout fail by attempting an empty commit.
reset_logs
GIT_CACHED_DIFF_RC=0 GH_CHECKS_RC=0 GH_MERGEABLE=MERGEABLE \
  bash "$CLOSEOUT" --open-only --skip-gate-check --repo "$REPO" >"$WORK/clean.out" 2>"$WORK/clean.err"
rc=$?
if [[ $rc -eq 0 ]] && ! grep -q '^commit ' "$GIT_LOG" 2>/dev/null \
  && grep -q '^push ' "$GIT_LOG" 2>/dev/null; then
  pass "clean index skips commit and still opens the PR"
else
  fail "clean-index closeout did not skip commit safely (rc=$rc)"
fi

# 8. An already-open PR is reused rather than triggering duplicate creation.
reset_logs
GH_EXISTING_PR='https://example.invalid/pull/existing' GIT_CACHED_DIFF_RC=1 \
  bash "$CLOSEOUT" --open-only --skip-gate-check --repo "$REPO" >"$WORK/existing.out" 2>"$WORK/existing.err"
rc=$?
if [[ $rc -eq 0 ]] && contains_line "$GH_LOG" "pr list --head marathon/gh-273 --base development --state open --json url --jq .[0].url" \
  && ! grep -q '^pr create ' "$GH_LOG" 2>/dev/null; then
  pass "existing open PR is reused without duplicate creation"
else
  fail "existing-PR reuse failed (rc=$rc)"
fi

# 9. marathon.sh delegates a successful run to open-only closeout with deterministic plan/event notes.
MARATHON="$HERE/../relay-automation/marathon.sh"
YAML_BIN="$HERE/../bin/marathon-yaml"
DRIVE="$WORK/marathon-drive.sh"
cat >"$DRIVE" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$DRIVE"
mkdir -p "$REPO/PROJECT/2-WORKING" "$REPO/briefs"
printf 'brief\n' >"$REPO/briefs/closeout.md"
cat >"$REPO/PROJECT/2-WORKING/closeout.yaml" <<'EOF'
name: closeout-plan
phases:
  - id: p1
    reviewer: agy
    brief: briefs/closeout.md
EOF
reset_logs
GIT_CACHED_DIFF_RC=1 XYZ_SKIP_GATE_CHECK=1 MARATHON_ROOT="$REPO" MARATHON_DRIVE="$DRIVE" MARATHON_YAML_BIN="$YAML_BIN" \
  MARATHON_CLOSEOUT_BIN="$CLOSEOUT" TICK_BIN="$HERE/../bin/tick" \
  bash "$MARATHON" --plan "$REPO/PROJECT/2-WORKING/closeout.yaml" --closeout-pr >"$WORK/marathon.out" 2>"$WORK/marathon.err"
rc=$?
if [[ $rc -eq 0 ]] && grep -Fq -- 'pr create --base development --head marathon/gh-273 --title Marathon: closeout-plan --body Marathon plan: closeout-plan' "$GH_LOG" \
  && grep -Fq -- 'Phases approved: 1/1' "$GH_LOG" && grep -Fq -- 'Tick events:' "$GH_LOG" \
  && ! grep -q '^pr checks \|^pr view \|^pr merge ' "$GH_LOG" 2>/dev/null; then
  pass "marathon --closeout-pr opens only a deterministic closeout PR"
else
  fail "marathon closeout delegation failed (rc=$rc)"
fi

# 10. PR creation failure is reported but never changes a successful marathon exit code.
reset_logs
GH_FAIL_ON='pr create' GIT_CACHED_DIFF_RC=1 XYZ_SKIP_GATE_CHECK=1 MARATHON_ROOT="$REPO" MARATHON_DRIVE="$DRIVE" MARATHON_YAML_BIN="$YAML_BIN" \
  MARATHON_CLOSEOUT_BIN="$CLOSEOUT" TICK_BIN="$HERE/../bin/tick" \
  bash "$MARATHON" --plan "$REPO/PROJECT/2-WORKING/closeout.yaml" --closeout-pr >"$WORK/marathon-fail.out" 2>"$WORK/marathon-fail.err"
rc=$?
if [[ $rc -eq 0 ]] && grep -q 'closeout PR failed after successful marathon' "$WORK/marathon-fail.out"; then
  pass "closeout PR failure is non-fatal after marathon success"
else
  fail "marathon propagated closeout PR failure (rc=$rc)"
fi

if bash -n "$CLOSEOUT" && bash -n "$0"; then pass "scripts are bash -n clean"; else fail "bash syntax check failed"; fi

printf '== marathon-closeout: %d passed, %d failed ==\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
