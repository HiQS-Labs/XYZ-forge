#!/usr/bin/env bash
# GH-268 items 7 + 8 — the two "fix in a follow-up" findings from the beta onboarding report.
#
#   7. "Relay handoff is manual, and only the first turn cues the next step ... the Reviewer turn did
#      not tell the user to return to the Producer window."
#   8. "The review loop checks the change, not the surrounding code; no code-check gate ran ... An
#      independent full audit of the same branch found 20 issues (1 critical, 4 high) — all in the
#      original file the relay built on but never reviewed. Fix: run the target repo's own checks in
#      the per-phase gate the harness already supports ... and consider prompting the reviewer to
#      sweep the file, not just the diff."
#
# Three deliverables are pinned here: the hand-off cue in both relay templates, the reviewer
# file-sweep prompt in both, and relay-automation/target-checks.sh (detection, exit codes, and the
# one that matters most — that "no checks ran" is never reported as a pass).
source "$(dirname "$0")/_setup.sh" gh268-relay-cue-and-target-checks
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TC="$ROOT/relay-automation/target-checks.sh"

# ── item 7: the hand-off cue must be in BOTH templates ───────────────────────────────────
# Both, because a repo can meet a relay through either path: new-relay.sh scaffolds a standalone
# thread, marathon_drive.py renders the per-phase one. Fixing one and not the other leaves half the
# users with the reported behavior.
rendered="$(bash "$ROOT/relay-automation/new-relay.sh" --title "gh268 cue check" --reviewer agy --print 2>/dev/null)"
printf '%s' "$rendered" | grep -Fq "Hand off explicitly" \
  && pass "new-relay template carries the hand-off cue" \
  || fail "new-relay template has no hand-off cue"
printf '%s' "$rendered" | grep -Fq "EVERY turn, not just the first" \
  && pass "new-relay cue says EVERY turn (the reported defect was first-turn-only)" \
  || fail "new-relay cue does not say it applies to every turn"
printf '%s' "$rendered" | grep -Fq "take your turn" \
  && pass "new-relay cue names the words to say to the other window" \
  || fail "cue must name the actual phrase, not just 'hand off'"

# The marathon template lives in the Python twin — the executing lane since GH-264.
py="$ROOT/utils/py/marathon_drive.py"
grep -Fq "HAND OFF EXPLICITLY (GH-268)" "$py" \
  && pass "marathon relay template carries the hand-off cue" \
  || fail "marathon relay template has no hand-off cue"
# Twice: once in the BUILDER block, once in the REVIEWER block. The report's specific complaint was
# that the REVIEWER turn was the one that failed to cue, so a builder-only fix would miss it.
[ "$(grep -c 'HAND OFF EXPLICITLY (GH-268)' "$py")" -ge 2 ] \
  && pass "the cue appears in both the builder and reviewer blocks" \
  || fail "cue must be in BOTH turn blocks — the reviewer turn is the one the report flagged"

# ── item 8b: the reviewer file-sweep prompt, in both templates ───────────────────────────
printf '%s' "$rendered" | grep -Fq "not just the diff" \
  && pass "new-relay template tells the reviewer to sweep the whole file" \
  || fail "new-relay template has no file-sweep prompt"
grep -Fq "NOT JUST THE DIFF (GH-268)" "$py" \
  && pass "marathon relay template tells the reviewer to sweep the whole file" \
  || fail "marathon relay template has no file-sweep prompt"
# The phrase is line-wrapped in the template, so flatten whitespace before matching rather than
# reflowing the template to suit the test.
printf '%s' "$rendered" | tr -s '[:space:]' ' ' | grep -Fq "are IN SCOPE" \
  && pass "the prompt states pre-existing defects are in scope" \
  || fail "prompt must say pre-existing defects are in scope, not merely 'read more'"

# Phase 3's own QA checklist asks for this: a reviewer that SKIPPED the sweep must be visibly
# distinguishable in the transcript from one that ran it and found nothing. A prompt to "look
# harder" is unfalsifiable; a required declaration is not.
printf '%s' "$rendered" | grep -Fq "swept file: yes" \
  && pass "new-relay requires an explicit 'swept file: yes/no' declaration" \
  || fail "the sweep must be declared, not assumed — no 'swept file:' line required"
grep -Fq "swept file: yes" "$py" \
  && pass "marathon template requires the same declaration" \
  || fail "marathon template does not require a 'swept file:' declaration"

# ── item 8a: target-checks.sh ────────────────────────────────────────────────────────────
[ -x "$TC" ] && pass "target-checks.sh exists and is executable" \
  || fail "relay-automation/target-checks.sh missing or not executable"

# detect: nothing there -> exit 3, and it must SAY that a gate running nothing is not a pass.
EMPTY="$WORK/empty"; mkdir -p "$EMPTY"
out="$(bash "$TC" detect --root "$EMPTY" 2>&1)"; rc=$?
[ "$rc" -eq 3 ] && pass "detect exits 3 when the target has no checks" \
  || fail "expected exit 3 for an empty target, got $rc"
printf '%s' "$out" | grep -Fq "not a passing gate" \
  && pass "the no-checks message says an empty gate is not a pass" \
  || fail "an empty gate must be described as a non-gate: $out"

# The PHP/WordPress shape is the one the report was written against.
PHP="$WORK/php"; mkdir -p "$PHP"
printf '<?php\nfunction gh268_ok() { return 1; }\n' > "$PHP/plugin.php"
printf '{"require-dev":{"wp-coding-standards/wpcs":"^3.0"}}\n' > "$PHP/composer.json"
out="$(bash "$TC" detect --root "$PHP" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "detect exits 0 when the target has checks" \
  || fail "expected exit 0 for a PHP target, got $rc"
printf '%s' "$out" | grep -Fq "php -l" \
  && pass "a PHP target is gated on php -l (the report's own example)" \
  || fail "php -l not detected for a *.php target: $out"
printf '%s' "$out" | grep -Fq "WordPress" \
  && pass "a wpcs composer dep asks for the WordPress ruleset by name" \
  || fail "WordPress ruleset not selected despite a wpcs dependency: $out"

# run: a real syntax error must FAIL the gate. This is the assertion the whole file is for —
# everything else is plumbing around making this one possible.
if command -v php >/dev/null 2>&1; then
  printf '<?php\nfunction gh268_broken( {\n' > "$PHP/bad.php"
  bash "$TC" run --root "$PHP" >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 1 ] && pass "a real PHP syntax error FAILS the gate (exit 1)" \
    || fail "broken PHP did not fail the gate (exit $rc)"
  rm -f "$PHP/bad.php"
  bash "$TC" run --root "$PHP" >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 0 ] && pass "clean PHP passes the gate (exit 0)" \
    || fail "clean PHP did not pass (exit $rc)"
else
  pass "php not installed — syntax-error case skipped (detection cases above still ran)"
fi

# All-skipped must NOT be a pass. A machine with no linters installed would otherwise hand back a
# green gate for a repo nobody checked — the same false-green class as GH-319, one layer out.
SKIP="$WORK/skiponly"; mkdir -p "$SKIP"
printf '{"require-dev":{"wp-coding-standards/wpcs":"^3.0"}}\n' > "$SKIP/composer.json"
out="$(bash "$TC" run --root "$SKIP" 2>&1)"; rc=$?
if printf '%s' "$out" | grep -Fq "SKIP"; then
  [ "$rc" -eq 3 ] && pass "a run where every check was skipped exits 3, not 0" \
    || fail "all-skipped must not report success (exit $rc): $out"
  printf '%s' "$out" | grep -Fq "NO GATE, not as a pass" \
    && pass "all-skipped says plainly that nothing was gated" \
    || fail "all-skipped must state it is not a pass: $out"
else
  pass "phpcs is installed here — all-skipped case not reachable, detection cases still ran"
fi

# --strict turns a missing tool into a failure rather than a skip.
if ! command -v phpcs >/dev/null 2>&1; then
  bash "$TC" run --root "$SKIP" --strict >/dev/null 2>&1; rc=$?
  [ "$rc" -eq 1 ] && pass "--strict makes an uninstalled tool a failure" \
    || fail "--strict should fail on a missing tool, got $rc"
fi

# ── the wiring: a cross-repo lane with no validate.sh gets this gate by default ──────────
# Without it, GH-238's runnability preflight refused the lane outright and the operator either
# passed a gate by hand or ran ungated — which is how the report's lane had no code check at all.
grep -Fq "target-checks.sh" "$py" \
  && pass "marathon_drive wires target-checks.sh for a --target-root with no validate.sh" \
  || fail "no target-checks.sh wiring in the executing lane — the gate seam is still unwired"

# ── item 9 fallout: findings from the Codex cross-vendor consult, each pinned ────────────
# The cross-model re-test was not ceremonial — Codex returned two Blockers against the first draft
# of the code above. These cases exist so those exact regressions cannot come back.

DRV="$ROOT/relay-automation/marathon-drive.sh"
BRIEF="$WORK/brief.md"; printf '## brief\nbody\n' > "$BRIEF"

mk_repo() {  # <dir> [validate-body]
  mkdir -p "$1"; git init -q "$1"
  git -C "$1" config user.email gh268@t; git -C "$1" config user.name gh268
  [ -n "${2:-}" ] && printf '%s' "$2" > "$1/validate.sh"
  printf 'x\n' > "$1/seed.txt"
  git -C "$1" add -A >/dev/null 2>&1; git -C "$1" commit -q -m init
}

# [Blocker] "A target that has validate.sh does NOT keep using it" — it fell to the else branch and
# ran the HARNESS's validate.sh against a foreign repo, while the code comment claimed otherwise.
HASV="$WORK/has-validate"
mk_repo "$HASV" '#!/usr/bin/env bash
exit 0
'
out="$(bash "$DRV" --target-root "$HASV" --phase-brief "$BRIEF" --reviewer agy --builder codex --dry-run 2>&1)"
printf '%s' "$out" | grep -Fq "$HASV/validate.sh" \
  && pass "a --target-root with its own validate.sh is gated on the TARGET's copy" \
  || fail "gate did not select the target's validate.sh: $(printf '%s' "$out" | grep -i gate)"
printf '%s' "$out" | grep -Fq "$ROOT/validate.sh" \
  && fail "gate selected the HARNESS validate.sh for a foreign target — Codex Blocker 1 is back" \
  || pass "the harness validate.sh is not used against a foreign target"

# [Blocker] project-local tooling. A WordPress plugin installs PHPCS at vendor/bin/phpcs and almost
# never has it on PATH; the first draft skipped it, ran php -l, and exited 0 "because one check ran".
VEND="$WORK/vendored"; mkdir -p "$VEND/vendor/bin"
printf '<?php\nfunction gh268_v(){return 1;}\n' > "$VEND/plugin.php"
printf '{"require-dev":{"wp-coding-standards/wpcs":"^3.0"}}\n' > "$VEND/composer.json"
printf '#!/usr/bin/env bash\necho vendor-local-phpcs-ran\nexit 0\n' > "$VEND/vendor/bin/phpcs"
chmod +x "$VEND/vendor/bin/phpcs"
out="$(bash "$TC" run --root "$VEND" 2>&1)"
printf '%s' "$out" | grep -Fq "vendor-local-phpcs-ran" \
  && pass "a project-local vendor/bin tool is RUN, not skipped as 'not installed'" \
  || fail "vendor/bin/phpcs was not used — the WordPress ruleset silently never ran: $out"
printf '%s' "$out" | grep -Fq "SKIP phpcs" \
  && fail "phpcs reported as skipped despite existing at vendor/bin" \
  || pass "no false 'not installed' skip when the tool is project-local"

# The auto-wired gate must be --strict: nobody CHOSE it, so a detected-but-missing tool must fail
# rather than quietly narrow the gate to whatever happened to be installed.
NOV="$WORK/no-validate"
mk_repo "$NOV"
printf '<?php\nfunction gh268_n(){return 1;}\n' > "$NOV/plugin.php"
out="$(bash "$DRV" --target-root "$NOV" --phase-brief "$BRIEF" --reviewer agy --builder codex --dry-run 2>&1)"
printf '%s' "$out" | grep -Fq "target-checks.sh" \
  && pass "a --target-root with no validate.sh falls back to target-checks.sh" \
  || fail "no target-checks fallback for a target lacking validate.sh: $out"
printf '%s' "$out" | grep -Fq -- "--strict" \
  && pass "the auto-wired gate is --strict (a missing detected tool fails it)" \
  || fail "auto-wired gate is not --strict — a missing tool would silently narrow it: $out"

# A partial run must SAY it is partial. Exit 0 here means "what ran, passed", not "checked".
PART="$WORK/partial"; mkdir -p "$PART"
printf '<?php\nfunction gh268_p(){return 1;}\n' > "$PART/plugin.php"
printf '{"require-dev":{"wp-coding-standards/wpcs":"^3.0"}}\n' > "$PART/composer.json"
out="$(bash "$TC" run --root "$PART" 2>&1)"
if printf '%s' "$out" | grep -Fq "SKIP"; then
  printf '%s' "$out" | grep -Fq "PARTIAL GATE" \
    && pass "a run with skipped checks is labelled PARTIAL GATE, not a clean pass" \
    || fail "partial run did not say so: $out"
fi

# ── item 9 fallout, second vendor: findings the agy cross-vendor relay caught that Codex missed ──

# [Blocker] the prefix substitution was unguarded. php-lint's command starts with `find`, not `php`,
# so substituting produced "/path/to/phpfind . -name ..." — a command-not-found that fails the gate
# for a reason unrelated to the code under review.
detected="$(bash "$TC" detect --root "$PHP" 2>/dev/null)"
printf '%s' "$detected" | grep -Fq "phpfind" \
  && fail "prefix substitution mangled the php-lint command — agy Blocker 1 is back" \
  || pass "php-lint's command is not mangled by tool-path substitution"

# A project-local tool that is NOT the leading word must still be reachable: PATH-prefixed, not
# string-spliced. Prove the local binary is the one that runs.
LOCALPHP="$WORK/localphp"; mkdir -p "$LOCALPHP/vendor/bin"
printf '<?php\nfunction gh268_lp(){return 1;}\n' > "$LOCALPHP/a.php"
printf '#!/usr/bin/env bash\necho "LOCAL-PHP-SAW: $*"\nexit 0\n' > "$LOCALPHP/vendor/bin/php"
chmod +x "$LOCALPHP/vendor/bin/php"
out="$(bash "$TC" run --root "$LOCALPHP" 2>&1)"; rc=$?
printf '%s' "$out" | grep -Fq "phpfind" \
  && fail "a project-local non-leading tool still mangles the command: $out" \
  || pass "a project-local non-leading tool is reached via PATH, not string splicing"
[ "$rc" -ne 127 ] && pass "the resulting command is executable (not command-not-found)" \
  || fail "command-not-found from the substitution path: $out"

# [Blocker] xargs empty-match. GNU xargs runs the command ONCE on empty input, so `php -l` with no
# arguments reads stdin and hangs — permanently blocking a lane. -r is the portable guard.
printf '%s' "$detected" | grep -Fq "xargs -0 -r" \
  && pass "php-lint passes -r so an empty match cannot hang the lane on GNU xargs" \
  || fail "php-lint's xargs has no -r — empty input hangs the lane on ubuntu CI"

# [Should] bash -c does not inherit this script's pipefail, so a failing find would be masked by a
# passing xargs and the gate would report green.
printf '%s' "$detected" | grep -Fq "set -o pipefail" \
  && pass "php-lint sets pipefail so a failing find cannot be masked" \
  || fail "php-lint pipeline can mask a find failure"

echo "  gh268-relay-cue-and-target-checks: $PASS pass, $FAIL fail"
exit 0
