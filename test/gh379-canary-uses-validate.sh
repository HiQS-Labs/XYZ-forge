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
#
# TWO HOUSE RULES THIS FILE OBEYS ON PURPOSE — do not "simplify" them back:
#   * NO `eval` in the check helper. The `check "label" "shell string"` idiom common elsewhere in
#     test/ trips security-scan.sh's `eval-unsanitized` rule. Here `check` takes a COMMAND and its
#     arguments and runs them directly, so there is no second parse and nothing to sanitize.
#   * NO piping a command into a quiet grep. GH-139 bans that shape under test/ (and counts it by
#     static text scan, so even a comment containing it fails the guard) because a quiet grep exits
#     at its first match, the writer then dies of SIGPIPE, and the result is nondeterministically
#     red under `set -o pipefail`. Match against a here-string instead — that is what `matches` does.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
WF="$REPO/.github/workflows/ci.yml"
V="$REPO/validate.sh"

PASS=0; FAIL=0
ok()  { echo "  PASS: $*"; PASS=$((PASS + 1)); }
bad() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }

# check <label> <command> [args...] — runs the command directly. No eval, no re-parse.
check() { local label="$1"; shift; if "$@"; then ok "$label"; else bad "$label"; fi; }
# not <command> [args...] — inverts a check without needing a shell string.
not()   { ! "$@"; }
# matches <extended-regex> <text> — here-string, never a pipe (GH-139).
matches()  { grep -qE -- "$1" <<<"$2"; }
# fmatches <literal> <text> — same, fixed-string. Use this for anything containing regex
# metacharacters or leading dashes; hand-escaping a flag name into an ERE is how the 2026-09-02
# draft of the tier-selector check ended up vacuous.
fmatches() { grep -qF -- "$1" <<<"$2"; }

echo "== test: gh379-canary-uses-validate =="

[ -f "$WF" ] || { bad "workflow missing at .github/workflows/ci.yml"; echo "  failed: $FAIL"; exit 1; }

# ── 1. the canary invokes validate.sh, with an EXPLICIT concurrency mode ─────────────────────────
# Explicit, not inherited: boundary-macos pins --sequential for exactly this reason (GH-544), and a
# canary that inherits a default cannot say what it ran.
check "canary invokes ./validate.sh with an explicit --parallel N" \
  grep -qE '\./validate\.sh --parallel [0-9]+' "$WF"

# ── 2. it does NOT reimplement the runner ────────────────────────────────────────────────────────
# The exact shape that regressed: scraping the registry out of validate.sh's source.
check "no CI step scrapes the TESTS array out of validate.sh" \
  not grep -q "sed -n '/^TESTS=(/" "$WF"

# The FULL-suite step specifically must not loop. The Fast Gate step (route=fast) still iterates a
# short, hand-curated list, which is a different and defensible shape — it is a selected subset, not
# a re-derivation of the registry. The FAST_TESTS block below guards that list instead.
# NB: a naive awk range `/start/,/^      - name: /` terminates on its OWN first line, because the
# step-name line matches both patterns — it captures one line and every assertion built on it passes
# vacuously. Skip the opening line before looking for the next step.
full_step="$(awk '/- name: Run validate.sh suite/{f=1; next} f && /^      - name: /{exit} f' "$WF")"
# Guard the extraction itself. An awk range that captures nothing makes the next assertion vacuous —
# which is the exact failure mode this file has already shipped once.
check "the full-suite step was actually extracted (not an empty awk range)" \
  matches 'validate\.sh' "$full_step"
check "the FULL-suite step does not iterate suites itself" \
  not matches 'bash "test/' "$full_step"

# The Fast Gate's curated list is a SECOND registry that gh306-registry-bidirectional.sh does not
# cover. A name that no longer exists on disk would silently shrink that lane.
fast_list="$(awk '/FAST_TESTS=\(/,/^          \)/' "$WF" | grep -oE '"[a-zA-Z0-9._-]+\.sh"' | tr -d '"' || true)"
check "the Fast Gate list was actually extracted (not an empty awk range)" \
  test -n "$fast_list"
gone=""
while IFS= read -r t; do
  [ -n "$t" ] || continue
  [ -f "$REPO/test/$t" ] || gone="$gone $t"
done <<<"$fast_list"
check "every Fast Gate suite name still exists on disk (missing:${gone:- none})" test -z "$gone"

# ── 3. the three non-shell lanes are actually REACHED ────────────────────────────────────────────
# These live outside TESTS=(...), which is why a '.sh'-only scrape missed them, and running them on
# Linux is the headline claim of GH-379.
#
# THE ASSERTION BELOW WAS VACUOUS UNTIL 2026-09-02, and Codex found it. It used to check only that
# validate.sh still MENTIONS the three lane labels — which proves nothing about the canary, because
# ownership is a property of validate.sh, not of how the canary calls it. Negative control at the
# time: rewriting the canary command as `./validate.sh --parallel 6 --tier 1` — a mode that exits
# long before any of the three lanes runs — left this suite at 23 pass, 0 fail.
#
# The lanes are tier-3 lanes. So the property that has to hold is TWO-part: validate.sh still owns
# them, AND the canary's own command selects nothing narrower than tier 3. Anything that shrinks the
# run set below the full registry breaks the coverage claim, so every selector is rejected by name.
for lane in "python:test_python_layer.py" "clone-identity-invariant" "gamma-poison-staleness-probe"; do
  check "validate.sh still owns the non-shell lane '$lane'" \
    grep -Fq "$lane" "$V"
done
# Scoped to full_step, not the whole file: the Fast Gate step legitimately runs a narrower selection,
# and matching workflow-wide would let its flags satisfy — or falsely fail — this check.
for sel in --tier --subsystem --auto --paths-file; do
  # NB: `fmatches`, and NO stray `--`. The helper supplies its own end-of-options marker, so an
  # extra one is swallowed as the PATTERN — which is exactly how the first draft of this loop
  # searched for the string "--" instead of the flag and passed against every negative control.
  check "the canary's command does not narrow the run set with '$sel' (tier 3 is what reaches the non-shell lanes)" \
    not fmatches "$sel" "$full_step"
done

# ── 4. --skip is a real, guarded mechanism, not a comment ────────────────────────────────────────
# Each of these is a property the old hand-rolled skip list did NOT have.
check "validate.sh accepts --skip" grep -q -- '--skip)' "$V"

rc=0; out="$(bash "$V" --skip 2>&1)" || rc=$?
check "--skip with no value is a usage error (exit 2)" test "$rc" -eq 2
check "  and says what it wanted" matches 'requires a suite name' "$out"

rc=0; out="$(bash "$V" --skip definitely-not-a-suite.sh --sequential 2>&1)" || rc=$?
check "an UNREGISTERED --skip name is refused (exit 2), so a typo cannot silently skip nothing" \
  test "$rc" -eq 2
check "  and the refusal explains why a no-op skip is dangerous" \
  matches 'not in the registry' "$out"
# NB: the marker MUST be one validate.sh actually emits. It prints "Running <suite>" in sequential
# mode and "[parallel] <suite> rc=N" in the pool. An earlier draft of this assertion grepped for
# `=== <suite> ===` — the format of the CI for-loop this whole issue DELETED — so it could never
# fail and proved nothing. Checked against a real run before trusting it.
check "  and no suite ran before the refusal" \
  not matches '^(Running |\[parallel\] )' "$out"

# The zero-test refusal has to FIRE, not merely exist as a string. Under bash 3.2 + `set -u` it once
# died on an empty-array expansion one line early, so the message never printed while the exit code
# stayed 1 — meaning an exit-code-only assertion could not tell the two apart. Skipping every
# registered suite is the only input that exercises it.
all_skips=()
while IFS= read -r t; do all_skips+=(--skip "${t#test/}"); done < <(bash "$V" --list 2>/dev/null)
check "the registry listed at least one suite to skip" test "${#all_skips[@]}" -gt 0
rc=0; out="$(bash "$V" ${all_skips[@]+"${all_skips[@]}"} --sequential 2>&1)" || rc=$?
check "skipping EVERY suite refuses (exit 1) rather than reporting a zero-test green" test "$rc" -eq 1
check "  and it says so, instead of dying on an unbound variable" \
  matches 'refusing a zero-test green' "$out"

# ── 5. every skip the canary asks for is a registered suite ──────────────────────────────────────
# Belt and braces with section 4: that proves the guard exists, this proves the workflow currently
# satisfies it, so a rename in TESTS breaks the gate here rather than in CI.
registry="$(bash "$V" --list 2>/dev/null || true)"
skips="$(grep -oE -- '--skip [a-zA-Z0-9._-]+\.sh' "$WF" | awk '{print $2}' | sort -u || true)"
if [ -z "$skips" ]; then
  ok "no --skip entries in the workflow (nothing to validate)"
else
  missing=""
  while IFS= read -r s; do
    [ -n "$s" ] || continue
    grep -qxF "test/$s" <<<"$registry" || missing="$missing $s"
  done <<<"$skips"
  check "every --skip name in ci.yml is a registered suite (drift:${missing:- none})" \
    test -z "$missing"
fi

# ── 6. a skip can never be silent ────────────────────────────────────────────────────────────────
check "validate.sh announces quarantined suites in the header" \
  grep -q 'QUARANTINE (GH-379)' "$V"
check "validate.sh repeats them in the summary" \
  grep -q 'QUARANTINED (GH-379)' "$V"
check "a quarantined run disqualifies itself as promotion evidence" \
  grep -q 'NOT promotion evidence: a run that omits suites cannot qualify one' "$V"

# ── 7. boundary-macos keeps its own pin (do not 'consistency-fix' it) ────────────────────────────
# The macOS job is the promotion boundary and stays sequential on purpose (GH-528 Phase 2 unmet).
# Asserted here so a future tidy-up of this file does not drag it along.
check "boundary-macos still pins --sequential (it is the promotion boundary, not the canary)" \
  grep -qE 'run: \./validate\.sh --sequential' "$WF"

echo
echo "  gh379-canary-uses-validate: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
