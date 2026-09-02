#!/usr/bin/env bash
# GH-379 — the Ubuntu canary must CALL validate.sh, never reimplement it.
#
# WHY THIS SUITE EXISTS
#
# The canary's slowest step used to scrape the TESTS array out of validate.sh with sed/grep and run
# its own serial for-loop, so it could carry three skips. Nothing detected that, because everything
# still "ran tests" and the job still went green half the time. Three separate losses hid inside a
# step that looked fine:
#
#   1. PARALLELISM. GH-528 measured 946.0s -> 184.3s at --parallel 8 with BYTE-IDENTICAL pass/fail
#      sets. The hand-rolled loop was serial: 13m 14s, 88% of the job's wall, 100% of the repo's
#      sampled runner-minute bill.
#   2. THE CONTENTION-RETRY. validate.sh re-runs a pooled failure alone before believing it — the
#      mechanism that separates a real red from contention. A bare for-loop has no such filter, so
#      every flake read as a defect and every defect read as a possible flake.
#   3. THREE NON-SHELL LANES. python:test_python_layer.py, clone-identity-invariant and
#      gamma-poison-staleness-probe are NOT members of the TESTS array. A '.sh'-only scrape cannot
#      see them, so they had never executed on Linux at all. That is the serious half: a coverage
#      hole wearing the costume of a speed optimization.
#
# A comment in ci.yml saying "call validate.sh" would not have prevented any of it — the previous
# loop also carried a confident comment. Only an assertion does, so these are assertions.
#
# THE NEGATIVE CONTROL that pins this suite: restore the scrape in ci.yml
# (`sed -n '/^TESTS=(/,/^)/p' validate.sh`) and assertions 2 and 3 must go red. If they do not, this
# suite is decorative and should be deleted rather than trusted.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
WF="$REPO/.github/workflows/ci.yml"
V="$REPO/validate.sh"

PASS=0; FAIL=0
ok()   { echo "  PASS: $*"; PASS=$((PASS + 1)); }
bad()  { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }

echo "== test: gh379-canary-uses-validate =="

[ -f "$WF" ] || { bad "workflow missing at .github/workflows/ci.yml"; echo "  failed: $FAIL"; exit 1; }

# ── 1. the canary invokes validate.sh, with an EXPLICIT concurrency mode ─────────────────────────
# Explicit, not inherited: boundary-macos pins --sequential for exactly this reason (GH-544), and a
# canary that inherits a default cannot say what it ran.
check "canary invokes ./validate.sh with an explicit --parallel N" \
  "grep -qE '\\./validate\\.sh --parallel [0-9]+' '$WF'"

# ── 2. it does NOT reimplement the runner ────────────────────────────────────────────────────────
# The exact shape that regressed: scraping the registry out of validate.sh's source.
check "no CI step scrapes the TESTS array out of validate.sh" \
  "! grep -q \"sed -n '/^TESTS=(/\" '$WF'"

# The FULL-suite step specifically must not loop. The Fast Gate step (route=fast) still iterates a
# short, hand-curated list, which is a different and defensible shape — it is a selected subset, not
# a re-derivation of the registry. Assertion 5b guards that list instead of demanding a rewrite.
# NB: a naive awk range `/start/,/^      - name: /` terminates on its OWN first line, because the
# step-name line matches both patterns — it captures one line and every assertion built on it passes
# vacuously. Skip the opening line before looking for the next step.
full_step="$(awk '/- name: Run validate.sh suite/{f=1; next} f && /^      - name: /{exit} f' "$WF")"
check "the FULL-suite step does not iterate suites itself" \
  "! printf '%s' \"\$full_step\" | grep -qE 'bash \"test/'"

# 5b. The Fast Gate's curated list is a SECOND registry that gh306-registry-bidirectional.sh does
# not cover. A name that no longer exists on disk would silently shrink that lane.
fast_list="$(awk '/FAST_TESTS=\(/,/^          \)/' "$WF" | grep -oE '"[a-zA-Z0-9._-]+\.sh"' | tr -d '"' || true)"
if [ -n "$fast_list" ]; then
  gone=""
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    [ -f "$REPO/test/$t" ] || gone="$gone $t"
  done <<<"$fast_list"
  check "every Fast Gate suite name still exists on disk (missing:${gone:- none})" "[ -z '$gone' ]"
fi

# ── 3. the three non-shell lanes are reachable ───────────────────────────────────────────────────
# These live outside TESTS=(...), which is why a '.sh'-only scrape missed them. This asserts the
# thing that actually matters — that the canary's runner is one that KNOWS about them — by checking
# validate.sh still owns them and the canary defers to validate.sh.
for lane in "python:test_python_layer.py" "clone-identity-invariant" "gamma-poison-staleness-probe"; do
  check "validate.sh still owns the non-shell lane '$lane'" \
    "grep -Fq '$lane' '$V'"
done

# ── 4. --skip is a real, guarded mechanism, not a comment ────────────────────────────────────────
# Each of these is a property the old hand-rolled skip list did NOT have.
check "validate.sh accepts --skip" \
  "grep -q -- '--skip)' '$V'"

rc=0; out="$(bash "$V" --skip 2>&1)" || rc=$?
check "--skip with no value is a usage error (exit 2)" "[ $rc -eq 2 ]"
check "  and says what it wanted" "printf '%s' \"\$out\" | grep -q 'requires a suite name'"

rc=0; out="$(bash "$V" --skip definitely-not-a-suite.sh --sequential 2>&1)" || rc=$?
check "an UNREGISTERED --skip name is refused (exit 2), so a typo cannot silently skip nothing" \
  "[ $rc -eq 2 ]"
check "  and the refusal explains why a no-op skip is dangerous" \
  "printf '%s' \"\$out\" | grep -q 'not in the registry'"
check "  and no suite ran before the refusal" \
  "! printf '%s' \"\$out\" | grep -qE '^=== .*\\.sh ==='"

# ── 5. every skip the canary asks for is a registered suite ──────────────────────────────────────
# Belt and braces with assertion 4: that one proves the guard exists, this one proves the workflow
# currently satisfies it, so a rename in TESTS breaks the gate here rather than in CI.
registry="$(bash "$V" --list 2>/dev/null || true)"
skips="$(grep -oE -- '--skip [a-zA-Z0-9._-]+\.sh' "$WF" | awk '{print $2}' | sort -u || true)"
if [ -z "$skips" ]; then
  ok "no --skip entries in the workflow (nothing to validate)"
else
  missing=""
  while IFS= read -r s; do
    [ -n "$s" ] || continue
    printf '%s\n' "$registry" | grep -qx "test/$s" || missing="$missing $s"
  done <<<"$skips"
  check "every --skip name in ci.yml is a registered suite (drift:${missing:- none})" \
    "[ -z '$missing' ]"
fi

# ── 6. a skip can never be silent ────────────────────────────────────────────────────────────────
check "validate.sh announces quarantined suites in the header" \
  "grep -q 'QUARANTINE (GH-379)' '$V'"
check "validate.sh repeats them in the summary" \
  "grep -q 'QUARANTINED (GH-379)' '$V'"
check "a quarantined run disqualifies itself as promotion evidence" \
  "grep -q 'NOT promotion evidence: a run that omits suites cannot qualify one' '$V'"
check "skipping every suite is refused rather than reported green" \
  "grep -q 'every suite was skipped' '$V'"

# ── 7. boundary-macos keeps its own pin (do not 'consistency-fix' it) ────────────────────────────
# The macOS job is the promotion boundary and stays sequential on purpose (GH-528 Phase 2 unmet).
# Asserted here so a future tidy-up of this file does not drag it along.
check "boundary-macos still pins --sequential (it is the promotion boundary, not the canary)" \
  "grep -qE 'run: \\./validate\\.sh --sequential' '$WF'"

echo
echo "  gh379-canary-uses-validate: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
