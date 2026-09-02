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
fast_body="$(awk '/FAST_TESTS=\(/{f=1;next} f&&/^ *\)/{exit} f' "$WF")"
fast_list="$(grep -oE '"[a-zA-Z0-9._-]+\.sh"' <<<"$fast_body" | tr -d '"' || true)"
check "the Fast Gate list was actually extracted (not an empty awk range)" \
  test -n "$fast_list"
# An empty extraction is not the only silent failure. The regex above only recognises QUOTED names,
# so a valid-but-unquoted array entry is dropped without a word and every downstream assertion then
# vouches for a list that is missing it. Count what the array body contains and require the parse to
# account for all of it. (Codex review round 2, 2026-09-02.)
# Strip a terminal backslash before counting: a legitimate `"a.sh" \` continuation would otherwise
# count as a third field and fail the parity check on correct input. (Codex review round 3.)
body_tokens="$(awk '{sub(/#.*/,""); sub(/\\[[:space:]]*$/,""); n+=NF} END{print n+0}' <<<"$fast_body")"
parsed_tokens="$(grep -c . <<<"$fast_list" || true)"
check "every Fast Gate array entry was parsed ($parsed_tokens parsed of $body_tokens in the array body)" \
  test "$parsed_tokens" -eq "$body_tokens"
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
# THE GUARANTEE IS AN ALLOWLIST GRAMMAR OVER THE RESOLVED RUN BODY.
#
# Two earlier shapes failed here, and the second failure is the instructive one:
#
#   * A BLOCKLIST of narrowing selectors. Codex round 2: it missed --print-mode and --list, both of
#     which exit before a suite runs. A list of ways to break a claim is never finished.
#   * An allowlist grammar over text joined on SHELL backslash continuations. Codex round 3: the
#     joiner understood `\` but not YAML. Switch the step's scalar from `run: |` to `run: >` and
#     write the invocation on two un-backslashed lines, and YAML folds them into
#     `./validate.sh --parallel 6 --tier 1` while the joiner captures only the first — so the
#     grammar passed on a fragment it had never seen executed, and the lanes went unreached.
#
# So the command is now taken from the RESOLVED run scalar, and the scalar style is pinned besides.

# (a) Pin the scalar style. A literal block (`run: |`) is the only style under which one physical
# line is one command; every folding style makes text-level reasoning about this step unsound. This
# assertion is unconditional and needs no YAML parser, so it holds even where PyYAML is absent.
check "the canary step uses a LITERAL block scalar (run: |), not a folding one" \
  matches '^        run: \|[[:space:]]*$' "$full_step"

# (b) Resolve the run body. With PyYAML this is what the runner will actually execute — immune to
# folding, quoting and continuation style alike. Without it, fall back to the literal-block text,
# which (a) has just established is equivalent. The fallback is announced, never silent.
run_body=""
if python3 -c 'import yaml' >/dev/null 2>&1; then
  run_body="$(python3 - "$WF" <<'PY'
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]))
for job in (doc.get("jobs") or {}).values():
    for step in (job.get("steps") or []):
        if str(step.get("name", "")).startswith("Run validate.sh suite"):
            sys.stdout.write(step.get("run", ""))
            raise SystemExit(0)
raise SystemExit(1)
PY
)" || run_body=""
  check "the canary step's run body resolved through a real YAML parser" test -n "$run_body"
else
  echo "  NOTE: PyYAML absent — falling back to the literal-block text pinned by (a)"
  run_body="$(awk '/^        run: \|/{f=1;next} f && /^      - name: /{exit} f' <<<"$full_step")"
fi

# (c) Collapse shell continuations, drop comments and blanks. What survives is one logical command
# per line — the unit the grammar is stated over.
logical="$(awk '
  { sub(/#.*/, ""); }
  { line = $0
    cont = (line ~ /\\[[:space:]]*$/)
    sub(/\\[[:space:]]*$/, "", line)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
    if (line != "") buf = (buf == "" ? line : buf " " line)
    if (!cont && buf != "") { print buf; buf = "" } }
  END { if (buf != "") print buf }' <<<"$run_body")"

# (d) The WHOLE body is asserted, not just the line that mentions validate.sh. Codex round 3 was
# explicit that finding one acceptable fragment is not execution proof: a second command appended
# below could re-narrow the run and a fragment-scoped check would never look at it.
n_cmds="$(grep -c . <<<"$logical" || true)"
check "the canary step runs exactly 2 commands — the shell pin and the gate (found $n_cmds)" \
  test "$n_cmds" -eq 2
check "  the first is the shell pin" matches '^set -euo pipefail$' "$(head -1 <<<"$logical")"
canary_cmd="$(tail -1 <<<"$logical")"
check "  the second invokes the gate" matches '\./validate\.sh' "$canary_cmd"

# (e) The grammar itself:  ./validate.sh --parallel <N> [--skip <NAME>]...
grammar_bad=""; n_parallel=0
# Deliberate word-splitting: this IS the tokenizer. `set --` is safe here; the suite takes no args.
# shellcheck disable=SC2086
set -- $canary_cmd
[ "${1:-}" = "./validate.sh" ] || grammar_bad="entry point is '${1:-<empty>}', not ./validate.sh"
shift || true
while [ "$#" -gt 0 ]; do
  case "$1" in
    --parallel)
      n_parallel=$((n_parallel + 1))
      case "${2:-}" in
        ''|*[!0-9]*) grammar_bad="$grammar_bad; --parallel wants an integer, got '${2:-<missing>}'" ;;
      esac
      shift 2 || break ;;
    --skip)
      [ -n "${2:-}" ] || { grammar_bad="$grammar_bad; --skip with no value"; break; }
      shift 2 || break ;;
    *)
      grammar_bad="$grammar_bad; unexpected token '$1' — only --parallel N and --skip NAME are allowed, because every other flag can narrow or short-circuit the run"
      shift ;;
  esac
done
# EXACTLY one --parallel. Zero would inherit validate.sh's default, which is the thing pinning it
# exists to prevent; more than one is ambiguous. Codex round 3 flagged that the loop counted neither.
[ "$n_parallel" -eq 1 ] || grammar_bad="$grammar_bad; expected exactly one --parallel, found $n_parallel"
check "the canary's command matches './validate.sh --parallel N [--skip NAME]...' exactly (bad:${grammar_bad:- none})" \
  test -z "$grammar_bad"

# Redundant with the grammar above, kept ONLY because it names the offender in the failure message.
# The grammar is what makes the guarantee; do not delete it and keep just this list.
for sel in --tier --subsystem --auto --paths-file --print-mode --list; do
  # NB: `fmatches`, and NO stray `--`. The helper supplies its own end-of-options marker, so an
  # extra one is swallowed as the PATTERN — which is exactly how the first draft of this loop
  # searched for the string "--" instead of the flag and passed against every negative control.
  check "the canary's command does not narrow or short-circuit the run with '$sel'" \
    not fmatches "$sel" "$canary_cmd"
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
