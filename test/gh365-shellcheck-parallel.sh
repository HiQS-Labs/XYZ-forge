#!/usr/bin/env bash
# gh365-shellcheck-parallel.sh — GH-365 step 5: census the ShellCheck call sites, then prove the
# parallel scan is verdict-equivalent to the serial one, with a mutation-flip red on BOTH shapes.
#
# The #365 profile measured the tracked-scripts scan at ~44.7s serial (the largest fixed cost
# before the suites). The census finding this suite PINS: ci-local.sh is the ONE local scan site
# (the hosted ci.yml job is the other), and NO registered suite executes shellcheck — every other
# occurrence in test/ is a `# shellcheck source=/disable=` directive or a text marker check. So
# there is no scan duplication to dedupe locally; the work is width, and width must not change
# verdicts.
source "$(dirname "$0")/_setup.sh" gh365-shellcheck-parallel
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
command -v shellcheck >/dev/null 2>&1 || { echo "  SKIP: shellcheck not installed"; exit 0; }

echo "== test: gh365-shellcheck-parallel =="

# ── S1. census (pinned — a new scan site must be an explicit decision, not drift) ────────────────
_sites="$(grep -rln 'shellcheck -S error\|shellcheck "' "$REPO/ci-local.sh" "$REPO/.github/workflows/ci.yml" 2>/dev/null | wc -l | tr -d ' ')"
[ "$_sites" -le 2 ] \
  && pass "S1: exactly the two canonical scan sites (ci-local.sh + hosted workflow; found $_sites)" \
  || fail "S1: scan-site census drifted — found $_sites files running shellcheck scans"
_suite_exec=0
for f in "$REPO"/test/*.sh; do
  # this census suite itself must run shellcheck to test the shapes — self is the one exemption
  case "$f" in */gh365-shellcheck-parallel.sh) continue ;; esac
  # an EXECUTION is shellcheck as a command with a flag/operand — not a directive comment, not a
  # marker-string check (ci-workflow.sh greps the WORKFLOW for the marker, it does not scan)
  if grep -qE '(^|[^#[:alnum:]_-])(shellcheck) (-|[[:alnum:]])' "$f" 2>/dev/null \
     && ! grep -qE '^\s*#[^!]*shellcheck (source|disable|enable)' <(grep -E 'shellcheck' "$f" | grep -vE '^\s*#' | head -5) 2>/dev/null; then
    _matches="$(grep -E 'shellcheck' "$f" | grep -vE '^\s*#' | grep -E 'shellcheck +(-|[[:alnum:]])' | head -2)"
    [ -n "$_matches" ] && { echo "    exec-site: $f"; _suite_exec=$((_suite_exec + 1)); }
  fi
done
[ "$_suite_exec" -eq 0 ] \
  && pass "S1b: no registered suite executes shellcheck (directives and marker checks only)" \
  || fail "S1b: $_suite_exec suite(s) execute shellcheck — the census changed; update the census or remove the duplication"

# ── S2. verdict equivalence + mutation-flip on both shapes ───────────────────────────────────────
CORPUS="$WORK/corpus"
mkdir -p "$CORPUS"
require_fixture "$CORPUS" "shellcheck corpus"
printf '#!/usr/bin/env bash\necho ok\n' > "$CORPUS/clean-one.sh"
printf '#!/usr/bin/env bash\nprintf "%%s" hi\n' > "$CORPUS/clean-two.sh"
scan() {  # <dir> <width> — the ci-local shape, factored so both shapes are THE SAME code
  ( cd "$1" && git init -q . 2>/dev/null; git add -A 2>/dev/null
    git ls-files -z -- '*.sh' | xargs -0 -P "$2" -n 1 shellcheck -S error )
}
if scan "$CORPUS" 4 >/dev/null 2>&1; then
  pass "S2: parallel shape is green on a clean corpus"
else
  fail "S2: parallel shape RED on a clean corpus (not verdict-equivalent): $(scan "$CORPUS" 4 2>&1 | head -3)"
fi
scan "$CORPUS" 1 >/dev/null 2>&1 && pass "S2b: serial shape (P1) green on the same corpus" \
  || fail "S2b: serial shape RED on a clean corpus"

# the mutation flip: a shebangless script is the one simple input that reliably fires at
# severity=error (SC2148 — probed empirically; SC2086 and friends sit below the threshold).
# BOTH shapes must go red AND name the file.
printf 'echo no-shebang\n' > "$CORPUS/mutant.sh"
_par_out="$(scan "$CORPUS" 4 2>&1)"; _par_rc=$?
_ser_out="$(scan "$CORPUS" 1 2>&1)"; _ser_rc=$?
if [ "$_par_rc" -ne 0 ] && grep -q "mutant.sh" <<<"$_par_out"; then
  pass "S3 MUTATION RED (parallel): the flip is rejected and the file is named"
else
  fail "S3: parallel shape accepted the mutant (rc=$_par_rc): $_par_out"
fi
if [ "$_ser_rc" -ne 0 ] && grep -q "mutant.sh" <<<"$_ser_out"; then
  pass "S3b MUTATION RED (serial): same flip, same rejection"
else
  fail "S3b: serial shape accepted the mutant (rc=$_ser_rc): $_ser_out"
fi
# findings equivalence: same finding COUNT and same SC codes across shapes (ordering may differ)
_par_codes="$(printf '%s\n' "$_par_out" | grep -oE 'SC[0-9]+' | LC_ALL=C sort | tr '\n' ' ')"
_ser_codes="$(printf '%s\n' "$_ser_out" | grep -oE 'SC[0-9]+' | LC_ALL=C sort | tr '\n' ' ')"
[ -n "$_par_codes" ] && [ "$_par_codes" = "$_ser_codes" ] \
  && pass "S4: both shapes report the identical SC-code set ($_par_codes)" \
  || fail "S4: shape divergence — parallel '$_par_codes' vs serial '$_ser_codes'"

# ── S5. ci-local wiring pins ─────────────────────────────────────────────────────────────────────
grep -q 'XYZ_SHELLCHECK_JOBS:-4' "$REPO/ci-local.sh" \
  && pass "S5: ci-local scan defaults to the balanced 4-worker width (XYZ_SHELLCHECK_JOBS override)" \
  || fail "S5: ci-local lost the parallel width or its override"
grep -q 'shellcheck -S error' "$REPO/ci-local.sh" \
  && pass "S5b: severity contract unchanged (-S error)" \
  || fail "S5b: severity flag drifted from the workflow's contract"
grep -q 'git ls-files -z' "$REPO/ci-local.sh" \
  && pass "S5c: NUL-safe file enumeration (names with spaces survive)" \
  || fail "S5c: file enumeration is not NUL-safe"

echo "== gh365-shellcheck-parallel: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ] || exit 1
exit 0
