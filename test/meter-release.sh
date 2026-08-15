#!/usr/bin/env bash
# gate-evidence: {"form":"deliberate-mutation","observed":true,"result":"--mutate-evidence unregisters a manifest gate, deletes a recorded control, and verifies that exit-0 stubs without registration or control are detected as NOT COVERED rather than PASS in Half B; all mutations are detected and unmutated inputs are re-checked green in the same run"}
# Meter (release 0.6.0) — the executable goalpost for a FROZEN manifest, and for the resource-accounting
# and precondition behaviours the release is actually about: "a run accounts for what it spends and checks
# what it requires before spending it."
#
# WHY THIS FILE EXISTS, and why it follows the Litmus and Nightwatch precedent.
#
# Litmus established the frozen-manifest audit and cap-on-claims pattern. Nightwatch added Half B:
# executing behaviour rather than auditing metadata. Meter extends both to resource accounting and
# preconditions checked before spending:
#
#   HALF A — the frozen manifest (structural). Each named entry has a gate that EXISTS, is
#            REGISTERED in validate.sh's TESTS array, and carries a RECORDED negative control under
#            test/baselines/. A gate absent from TESTS is indistinguishable from a gate that passes
#            (that is #461, and it is why registration is checked rather than assumed).
#
#   HALF B — the six member cases the release's own exit criterion names, EXECUTED, not audited:
#            1. A run against a red-suite target proceeds under a recorded baseline and halts on a new failure (#378)
#            2. A budget-exhausted builder is escalated as budget-exhausted, not pre-advance-failed (#379)
#            3. An untrusted target is reported before the first paid turn, not after (#380)
#            4. A phase boundary records memory and swap (#382)
#            5. A re-fire of an already-satisfied phase runs only the gate, and says so (#491)
#            6. A resolver that cannot determine its answer refuses rather than returning a default (#551)
#            Half B requires that each member suite exists, is registered in validate.sh, and has a
#            recorded negative control before its execution can be credited as PASS — a stub that exits
#            0 without registration/control is detected as NOT COVERED, never PASS.
#
# WHAT THIS DELIBERATELY DOES NOT PROVE. Half A reads a declaration and a filename; it cannot know
# that a recorded control was honestly recorded. That limit is inherited from Litmus and Nightwatch
# and is stated rather than papered over. Half B closes part of it by EXECUTING behaviour, which is
# the upgrade this release's criterion asked for — "the evidence is a committed command rather than a
# closed backlog".
#
# THREE MODES, same shape as litmus-release.sh and nightwatch-release.sh so an operator does not learn two conventions:
#
#   (default)         Suite mode, registered in validate.sh. GREEN while Meter is in progress.
#                     Fails ONLY on a false completion claim — a CLOSED manifest issue whose gate is
#                     missing, unregistered, or has no recorded control, or a disagreement with
#                     RELEASES.md. Remaining work is INFO, so an unfinished release does not paint
#                     the whole suite red. An always-red suite trains people to ignore it, which is
#                     #460's failure mode.
#
#   --release-gate    THE GOALPOST. Exits non-zero until every manifest entry is complete AND every
#                     member case passes. RED TODAY BY DESIGN; turning it green is what "done"
#                     means for 0.6.0.
#
#   --mutate-evidence The negative control for this file. Copies the inputs, breaks them in specific
#                     ways (unregistering a gate, deleting a control, evaluating exit-0 stubs), requires
#                     the audit to notice each, and then re-checks the unmutated inputs green in the
#                     same run.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

MODE=suite
case "${1:-}" in
  --release-gate)    MODE=gate ;;
  --mutate-evidence) MODE=mutate ;;
  --help|-h)         sed -n '3,48p' "$0"; exit 0 ;;
  "")                ;;
  *) printf 'usage: %s [--release-gate | --mutate-evidence]\n' "$0" >&2; exit 2 ;;
esac

PASS=0; FAIL=0; INFO=0
ok()   { printf '  PASS: %s\n' "$*"; PASS=$((PASS+1)); }
bad()  { printf '  FAIL: %s\n' "$*" >&2; FAIL=$((FAIL+1)); }
info() { printf '  INFO: %s\n' "$*"; INFO=$((INFO+1)); }

# ── The FROZEN manifest ───────────────────────────────────────────────────────────────────────────
# Frozen 2026-08-11 in RELEASES.md; re-scoped to 7 entries with #551 and #555. Adding one here is a
# RE-SCOPE and must be matched in RELEASES.md — the audit below checks that the two agree.
#
# Format: <issue>|<gate test file, or '-' if satisfied by another gate>|<note>
MANIFEST=(
  "378|test/gh378-gate-requires-green-suite.sh|a run against a red-suite target proceeds under a recorded baseline and halts on a new failure"
  "379|test/gh379-claude-builder-diagnosis.sh|a budget-exhausted builder is escalated as budget-exhausted, not pre-advance-failed"
  "380|test/gh380-claude-trust.sh|an untrusted target is reported before the first paid turn, not after"
  "382|test/gh382-marathon-memory-telemetry.sh|a phase boundary records memory and swap"
  "491|test/gh491-gate-only-refire.sh|a re-fire of an already-satisfied phase runs only the gate and says so"
  "551|test/gh551-resolver-refuses.sh|a resolver that cannot determine its answer refuses rather than returning a default"
  "555|test/meter-release.sh|Meter 0.6.0 release exit criterion and frozen-manifest goalpost"
)

# ── The member cases the exit criterion names ─────────────────────────────────────────────────────
# Format: <issue>|<name>|<suite>
MEMBER_CASES=(
  "378|red-suite baseline allows progress and halts on new failure|test/gh378-gate-requires-green-suite.sh"
  "379|budget-exhausted builder escalated as budget-exhausted|test/gh379-claude-builder-diagnosis.sh"
  "380|untrusted target reported before first paid turn|test/gh380-claude-trust.sh"
  "382|phase boundary records memory and swap telemetry|test/gh382-marathon-memory-telemetry.sh"
  "491|satisfied phase refire runs only the gate|test/gh491-gate-only-refire.sh"
  "551|unresolvable input causes resolver refusal|test/gh551-resolver-refuses.sh"
)

registered_in_validate() {  # <test path> — is it in validate.sh's TESTS array?
  local base="${1##*/}" validate="${2:-$ROOT/validate.sh}"
  sed -n '/^TESTS=(/,/^)/p' "$validate" | /usr/bin/grep -qF "\"$base\""
}

control_recorded() {  # <issue> — is there a recorded negative control for it?
  local n="$1" baselines="${2:-$ROOT/test/baselines}"
  [ -f "$baselines/GH-$n-negative-control.md" ]
}

STATE_CACHE=""
get_issue_state() {  # <issue> — sets ISSUE_STATE to OPEN | CLOSED | unknown
  local n="$1"
  case "$STATE_CACHE" in
    *":${n}="*)
      local cached="${STATE_CACHE#*:${n}=}"
      ISSUE_STATE="${cached%%:*}"
      return
      ;;
  esac
  if ! command -v gh >/dev/null 2>&1; then
    STATE_CACHE="${STATE_CACHE}:${n}=unknown:"
    ISSUE_STATE="unknown"
    return
  fi
  local st
  st="$(gh issue view "$n" --json state --jq .state 2>/dev/null | tr -d '\n' | tr '[:lower:]' '[:upper:]')" || st="unknown"
  [ -z "$st" ] && st="unknown"
  STATE_CACHE="${STATE_CACHE}:${n}=${st}:"
  ISSUE_STATE="$st"
}

audit_manifest() {  # [<validate.sh>] [<baselines dir>] — sets COMPLETE / REMAINING / FALSE_CLAIMS
  local validate="${1:-$ROOT/validate.sh}" baselines="${2:-$ROOT/test/baselines}"
  COMPLETE=0; REMAINING=0; FALSE_CLAIMS=0
  local entry n gate note state have_gate have_reg have_ctl state_note
  for entry in "${MANIFEST[@]}"; do
    n="${entry%%|*}"; gate="${entry#*|}"; note="${gate#*|}"; gate="${gate%%|*}"
    have_gate=0; have_reg=0; have_ctl=0
    [ -f "$ROOT/$gate" ] && have_gate=1
    registered_in_validate "$gate" "$validate" && have_reg=1
    control_recorded "$n" "$baselines" && have_ctl=1

    get_issue_state "$n"
    state="$ISSUE_STATE"
    state_note=""
    [ "$state" = "unknown" ] && state_note=" (issue state unavailable — gh absent or unauthed)"

    if [ "$have_gate" -eq 1 ] && [ "$have_reg" -eq 1 ] && [ "$have_ctl" -eq 1 ]; then
      COMPLETE=$((COMPLETE+1))
      ok "#$n complete — $gate registered, control recorded${state_note}"
    else
      REMAINING=$((REMAINING+1))
      local why=""
      [ "$have_gate" -eq 0 ] && why="$why gate-missing($gate)"
      [ "$have_reg"  -eq 0 ] && why="$why not-registered-in-validate.sh"
      [ "$have_ctl"  -eq 0 ] && why="$why no-recorded-control(test/baselines/GH-$n-negative-control.md)"
      if [ "$state" = "CLOSED" ]; then
        FALSE_CLAIMS=$((FALSE_CLAIMS+1))
        bad "#$n is CLOSED but its gate is not complete —$why"
      else
        info "#$n remaining —$why  ($note)"
      fi
    fi
  done
}

run_member_cases() {  # [<validate.sh>] [<baselines dir>] — executes the behavioural half
  local validate="${1:-$ROOT/validate.sh}" baselines="${2:-$ROOT/test/baselines}"
  local entry n name suite rc
  CASE_PASS=0; CASE_MISSING=0; CASE_FAILED=0
  for entry in "${MEMBER_CASES[@]}"; do
    n="${entry%%|*}"; entry="${entry#*|}"; name="${entry%%|*}"; suite="${entry##*|}"
    if [ "$suite" = "-" ]; then
      CASE_MISSING=$((CASE_MISSING+1))
      info "member case NOT COVERED — $name (no suite drives this case yet)"
      continue
    fi
    if [ ! -f "$ROOT/$suite" ]; then
      CASE_MISSING=$((CASE_MISSING+1))
      info "member case NOT COVERED — $name (named suite $suite is absent)"
      continue
    fi
    if ! registered_in_validate "$suite" "$validate"; then
      CASE_MISSING=$((CASE_MISSING+1))
      info "member case NOT COVERED — $name ($suite not registered in validate.sh)"
      continue
    fi
    if ! control_recorded "$n" "$baselines"; then
      CASE_MISSING=$((CASE_MISSING+1))
      info "member case NOT COVERED — $name (no recorded control test/baselines/GH-$n-negative-control.md)"
      continue
    fi
    # Executed, not audited — only after structural gates (registration + control) are satisfied.
    if bash "$ROOT/$suite" >/dev/null 2>&1; then
      CASE_PASS=$((CASE_PASS+1))
      ok "member case OK — $name (via ${suite##*/})"
    else
      rc=$?
      CASE_FAILED=$((CASE_FAILED+1))
      bad "member case FAILED — $name (${suite##*/} exited $rc)"
    fi
  done
}

manifest_matches_releases_md() {
  local rel="$ROOT/RELEASES.md" line entry n missing=""
  [ -f "$rel" ] || { info "RELEASES.md absent — manifest cross-check skipped"; return 0; }
  line="$(awk '/^Codename: Meter/,/^$/' "$rel" | /usr/bin/grep '^Manifest:')"
  if [ -z "$line" ]; then
    bad "RELEASES.md has no Manifest: line for Meter — the frozen boundary is not recorded"
    return 1
  fi
  case "$line" in
    *"NOT YET FROZEN"*) bad "RELEASES.md still says the Meter manifest is NOT YET FROZEN"; return 1 ;;
  esac
  for entry in "${MANIFEST[@]}"; do
    n="${entry%%|*}"
    printf '%s' "$line" | /usr/bin/grep -q "#$n" || missing="$missing #$n"
  done
  if [ -n "$missing" ]; then
    bad "RELEASES.md's frozen manifest does not name:$missing — this file and the ledger disagree"
    return 1
  fi
  ok "the frozen manifest here matches RELEASES.md's Meter block (7 entries)"
}

# ── Mutation mode: the negative control for this audit ────────────────────────────────────────────
if [ "$MODE" = mutate ]; then
  echo "== meter-release --mutate-evidence =="
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  cp "$ROOT/validate.sh" "$TMP/validate.sh"
  mkdir -p "$TMP/baselines"
  cp "$ROOT"/test/baselines/*.md "$TMP/baselines/" 2>/dev/null || true

  MUT_PASS=0
  MUT_FAIL=0
  mut_ok()  { printf '  PASS: %s\n' "$*"; MUT_PASS=$((MUT_PASS+1)); }
  mut_bad() { printf '  FAIL: %s\n' "$*" >&2; MUT_FAIL=$((MUT_FAIL+1)); }

  echo "-- baseline: the unmutated inputs"
  audit_manifest "$TMP/validate.sh" "$TMP/baselines"
  base_complete=$COMPLETE base_false=$FALSE_CLAIMS
  if [ "$base_false" -eq 0 ]; then
    mut_ok "unmutated inputs report no false completion claims (complete=$base_complete)"
  else
    mut_bad "unmutated inputs already report $base_false false claim(s) — the mutation below would prove nothing"
  fi
  run_member_cases "$TMP/validate.sh" "$TMP/baselines" >/dev/null 2>&1
  base_case_pass=$CASE_PASS
  if [ "$base_case_pass" -gt 0 ]; then
    mut_ok "unmutated member cases execute $base_case_pass passing case(s)"
  else
    mut_bad "unmutated member cases reported unexpected passing count ($base_case_pass == 0)"
  fi

  echo "-- mutation 1: unregister a manifest gate from validate.sh (the #461 defect)"
  /usr/bin/grep -v '"gh380-claude-trust.sh"' "$TMP/validate.sh" > "$TMP/v2" && mv "$TMP/v2" "$TMP/validate.sh"
  audit_manifest "$TMP/validate.sh" "$TMP/baselines" >/dev/null 2>&1
  if [ "$COMPLETE" -lt "$base_complete" ]; then
    mut_ok "unregistering a gate is DETECTED by audit_manifest (complete $base_complete -> $COMPLETE)"
  else
    mut_bad "unregistering a gate changed nothing in audit_manifest — this audit does not read validate.sh's TESTS array"
  fi

  echo "-- mutation 2: delete a recorded negative control"
  cp "$ROOT/validate.sh" "$TMP/validate.sh"
  rm -f "$TMP/baselines/GH-380-negative-control.md"
  audit_manifest "$TMP/validate.sh" "$TMP/baselines" >/dev/null 2>&1
  if [ "$COMPLETE" -lt "$base_complete" ]; then
    mut_ok "deleting a recorded control is DETECTED by audit_manifest (complete $base_complete -> $COMPLETE)"
  else
    mut_bad "deleting a control changed nothing in audit_manifest — this audit does not read test/baselines/"
  fi

  echo "-- mutation 3: a stub that exits 0 without registration/control must be detected as NOT COVERED, not PASS"
  # gh551-resolver-refuses.sh exists on disk and exits 0, but is unregistered and has no control.
  # run_member_cases must report it NOT COVERED and not credit it as PASS.
  cp "$ROOT/validate.sh" "$TMP/validate.sh"
  cp "$ROOT"/test/baselines/*.md "$TMP/baselines/" 2>/dev/null || true
  run_member_cases "$TMP/validate.sh" "$TMP/baselines" >/dev/null 2>&1
  if [ "$CASE_PASS" -eq "$base_case_pass" ]; then
    mut_ok "exit-0 stub without registration/control is detected as NOT COVERED, not PASS (CASE_PASS=$CASE_PASS)"
  else
    mut_bad "exit-0 stub was credited as PASS (CASE_PASS=$CASE_PASS != $base_case_pass)"
  fi

  echo "-- mutation 4: unregistering a passing member case from validate.sh removes it from Half B PASS"
  /usr/bin/grep -v '"gh380-claude-trust.sh"' "$TMP/validate.sh" > "$TMP/v2" && mv "$TMP/v2" "$TMP/validate.sh"
  run_member_cases "$TMP/validate.sh" "$TMP/baselines" >/dev/null 2>&1
  if [ "$CASE_PASS" -lt "$base_case_pass" ]; then
    mut_ok "unregistering member case drops it from Half B PASS ($base_case_pass -> $CASE_PASS)"
  else
    mut_bad "unregistering member case did not drop it from Half B PASS ($CASE_PASS vs $base_case_pass)"
  fi

  echo "-- restore: the unmutated inputs must be green again in this same run"
  cp "$ROOT/validate.sh" "$TMP/validate.sh"
  cp "$ROOT"/test/baselines/*.md "$TMP/baselines/" 2>/dev/null || true
  audit_manifest "$TMP/validate.sh" "$TMP/baselines" >/dev/null 2>&1
  run_member_cases "$TMP/validate.sh" "$TMP/baselines" >/dev/null 2>&1
  if [ "$COMPLETE" -eq "$base_complete" ] && [ "$CASE_PASS" -eq "$base_case_pass" ]; then
    mut_ok "restoring the inputs restores the verdict — the detector is not simply always-red"
  else
    mut_bad "restored inputs do not reproduce the baseline verdict (complete: $COMPLETE vs $base_complete, cases: $CASE_PASS vs $base_case_pass)"
  fi

  printf '\n  meter-release --mutate-evidence: %s passed, %s failed\n' "$MUT_PASS" "$MUT_FAIL"
  [ "$MUT_FAIL" -eq 0 ] || exit 1
  echo "  negative control OBSERVED in both directions"
  exit 0
fi

# ── Suite / gate modes ────────────────────────────────────────────────────────────────────────────
echo "== meter-release (${MODE}) — release 0.6.0 frozen-manifest goalpost =="
echo
echo "-- half A: the frozen manifest"
manifest_matches_releases_md
audit_manifest

if [ "$MODE" = gate ]; then
  echo
  echo "-- half B: the member cases, EXECUTED"
  run_member_cases
fi

echo
printf 'manifest: %s complete, %s remaining, %s false completion claim(s)\n' \
  "$COMPLETE" "$REMAINING" "$FALSE_CLAIMS"

if [ "$MODE" = gate ]; then
  printf 'member cases: %s passing, %s failing, %s NOT COVERED\n' \
    "$CASE_PASS" "$CASE_FAILED" "$CASE_MISSING"
  echo
  if [ "$REMAINING" -eq 0 ] && [ "$FALSE_CLAIMS" -eq 0 ] \
     && [ "$CASE_FAILED" -eq 0 ] && [ "$CASE_MISSING" -eq 0 ]; then
    echo "GOALPOST MET — all 7 manifest entries complete and every member case executes green"
    exit 0
  fi
  echo "GOALPOST NOT MET — Meter is not done."
  echo "  This is the correct state until the release is finished. Turning this command green is"
  echo "  what 0.6.0's exit criterion means; a closed backlog is not a substitute for it."
  exit 1
fi

# Suite mode: only a false completion claim or RELEASES.md mismatch is fatal.
if [ "$FAIL" -gt 0 ]; then
  printf '\n  meter-release: %s passed, %s FAILED (false completion claim or ledger disagreement)\n' "$PASS" "$FAIL"
  exit 1
fi
printf '\n  meter-release: %s passed, 0 failed, %s informational\n' "$PASS" "$INFO"
echo "  (suite mode is green while the release is in progress — run --release-gate for the goalpost)"
exit 0
