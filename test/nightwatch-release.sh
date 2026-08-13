#!/usr/bin/env bash
# gate-evidence: {"form":"deliberate-mutation","observed":true,"result":"--mutate-evidence unregisters a manifest gate and deletes a recorded control in a fixture copy of validate.sh/test-baselines; the audit goes from satisfied to two structural failures, and the unmutated inputs are re-checked green in the same run"}
# Nightwatch (release 0.3.0) — the executable goalpost for a FROZEN manifest, and for the four
# run-lifecycle behaviours the release is actually about.
#
# WHY THIS FILE EXISTS, and why it is not a copy of test/litmus-release.sh.
#
# Litmus's exit criterion was a question about METADATA: is each named gate registered, and does it
# declare an observed control? That was the right question there, because Litmus was about making
# checks capable of failing. Nightwatch is about what SURVIVES a run that goes wrong, and no amount
# of metadata can answer that. So this gate has two halves and needs both:
#
#   HALF A — the frozen manifest (structural). Each named entry has a gate that EXISTS, is
#            REGISTERED in validate.sh's TESTS array, and carries a RECORDED negative control under
#            test/baselines/. A gate absent from TESTS is indistinguishable from a gate that passes
#            (that is #461, and it is why registration is checked rather than assumed).
#
#   HALF B — the four lifecycle cases the release's own exit criterion names, EXECUTED, not audited:
#            an interrupted child, a cap-killed child, a restarted recovery, and no write outside the
#            allowlist. Half B delegates to the suites that already drive real children and kill
#            them, rather than growing a second copy of that harness here — a duplicate driver
#            fixture is a second thing to keep true, and this file's whole job is to have one answer.
#
# WHAT THIS DELIBERATELY DOES NOT PROVE. Half A reads a declaration and a filename; it cannot know
# that a recorded control was honestly recorded. That limit is inherited from Litmus and is stated
# rather than papered over. Half B closes part of it by EXECUTING behaviour, which is the upgrade
# this release's criterion asked for — "the evidence is a committed command rather than a closed
# backlog".
#
# THREE MODES, same shape as litmus-release.sh so an operator does not learn two conventions:
#
#   (default)         Suite mode, registered in validate.sh. GREEN while Nightwatch is in progress.
#                     Fails ONLY on a false completion claim — a CLOSED manifest issue whose gate is
#                     missing, unregistered, or has no recorded control. Remaining work is INFO, so
#                     an unfinished release does not paint the whole suite red. An always-red suite
#                     trains people to ignore it, which is #460's failure mode.
#
#   --release-gate    THE GOALPOST. Exits non-zero until every manifest entry is complete AND every
#                     lifecycle case passes. RED TODAY BY DESIGN; turning it green is what "done"
#                     means for 0.3.0.
#
#   --mutate-evidence The negative control for this file. Copies the inputs, breaks them in two
#                     specific ways, and requires the audit to notice both — then re-checks the
#                     unmutated inputs green in the same run, so a mutation that broke everything
#                     cannot pass for a detector.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

MODE=suite
case "${1:-}" in
  --release-gate)    MODE=gate ;;
  --mutate-evidence) MODE=mutate ;;
  --help|-h)         sed -n '3,45p' "$0"; exit 0 ;;
  "")                ;;
  *) printf 'usage: %s [--release-gate | --mutate-evidence]\n' "$0" >&2; exit 2 ;;
esac

PASS=0; FAIL=0; INFO=0
ok()   { printf '  PASS: %s\n' "$*"; PASS=$((PASS+1)); }
bad()  { printf '  FAIL: %s\n' "$*" >&2; FAIL=$((FAIL+1)); }
info() { printf '  INFO: %s\n' "$*"; INFO=$((INFO+1)); }

# ── The FROZEN manifest ───────────────────────────────────────────────────────────────────────────
# Frozen 2026-08-11 in RELEASES.md, before execution started. Eight entries, a fixed denominator
# rather than a percentage. Adding one here is a RE-SCOPE and must be matched in RELEASES.md — the
# audit below checks that the two agree, because a manifest that lives in two places will disagree.
#
# Format: <issue>|<gate test file, or '-' if the entry is satisfied by another issue's gate>|<note>
MANIFEST=(
  "408|test/gh408-tick-failure-visibility.sh|a lost tick claim is detectable by exit status and readable in the output"
  "409|test/gh409-claim-leak.sh|a turn that fails releases its claim on the paths that never reach rtl_enforce"
  "426|test/gh426-worktree-leak.sh|an isolated turn's creation is absent from BOTH the target and the harness"
  "388|test/gh388-run-log-durability.sh|the harness owns a durable run log; a killed phase leaves a content-bearing record"
  "387|test/gh387-gate-not-first-executor.sh|a cap-killed turn's artifact is reviewed before any gate executes it"
  "384|test/gh384-crash-recovery.sh|the crash-recovery report distinguishes a gated phase from an ungated one"
  "358|test/gh358-lock-instrumentation.sh|a lost concurrent-append record names its terminal lock state"
  # NOT a manifest entry: #514 was FILED while executing this release and is deliberately not
  # admitted. RELEASES.md's admission rule is explicit — "discovery is not admission" — and adding it
  # here would be a re-scope of a frozen boundary, which is the exact drift the freeze exists to
  # stop. It appears in LIFECYCLE below, because the exit criterion always named that case; what was
  # missing was a suite driving it, not a new manifest member. (Adding it here anyway would fail
  # manifest_matches_releases_md, which is that check doing its job.)
  "354|test/gh376-relay-drive-lock-parity.sh|Phase 1 only: clone-wide driver exclusion from a linked worktree (delivered by #376)"
)

# ── The lifecycle cases the exit criterion names ──────────────────────────────────────────────────
# Each names the suite that EXECUTES it. `-` means no suite exists yet, which is a REMAINING item and
# the honest reason this gate is red — not something to quietly omit from the list.
LIFECYCLE=(
  "interrupted child leaves a durable record|test/gh388-run-log-durability.sh"
  "cap-killed child is not first-executed by the gate|test/gh387-gate-not-first-executor.sh"
  "restarted recovery offers a documented action|test/gh384-crash-recovery.sh"
  "no write outside the allowlist|test/gh426-worktree-leak.sh"
  "hostile target write-set is REJECTED with an actionable refusal, not a traceback|test/gh514-write-set-trackable.sh"
)

registered_in_validate() {  # <test path> — is it in validate.sh's TESTS array?
  local base="${1##*/}" validate="${2:-$ROOT/validate.sh}"
  sed -n '/^TESTS=(/,/^)/p' "$validate" | /usr/bin/grep -qF "\"$base\""
}

control_recorded() {  # <issue> — is there a recorded negative control for it?
  local n="$1" baselines="${2:-$ROOT/test/baselines}"
  [ -f "$baselines/GH-$n-negative-control.md" ]
}

issue_state() {  # <issue> — OPEN | CLOSED | unknown (never fatal: gh may be absent or unauthed)
  local n="$1"
  command -v gh >/dev/null 2>&1 || { printf 'unknown'; return; }
  gh issue view "$n" --json state --jq .state 2>/dev/null | tr -d '\n' | tr '[:lower:]' '[:upper:]' \
    || printf 'unknown'
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
    # #354 and #387 are satisfied by another issue's gate, so a control filed under their own number
    # is not expected. Named explicitly rather than inferred, so the exemption is auditable.
    case "$n" in 354|387) have_ctl=1 ;; esac

    state="$(issue_state "$n")"
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
      # A CLOSED issue whose gate cannot be found is a FALSE COMPLETION CLAIM and fails hard in every
      # mode. This is the #401 -> #461 mistake the release exists to stop repeating: the issue said
      # done, the evidence was absent, and nothing disagreed.
      if [ "$state" = "CLOSED" ]; then
        FALSE_CLAIMS=$((FALSE_CLAIMS+1))
        bad "#$n is CLOSED but its gate is not complete —$why"
      else
        info "#$n remaining —$why  ($note)"
      fi
    fi
  done
}

run_lifecycle() {  # executes the behavioural half
  local entry name suite rc
  LIFE_PASS=0; LIFE_MISSING=0; LIFE_FAILED=0
  for entry in "${LIFECYCLE[@]}"; do
    name="${entry%%|*}"; suite="${entry##*|}"
    if [ "$suite" = "-" ]; then
      LIFE_MISSING=$((LIFE_MISSING+1))
      info "lifecycle NOT COVERED — $name (no suite drives this case yet)"
      continue
    fi
    if [ ! -f "$ROOT/$suite" ]; then
      LIFE_MISSING=$((LIFE_MISSING+1))
      info "lifecycle NOT COVERED — $name (named suite $suite is absent)"
      continue
    fi
    # Executed, not audited. This is the half a metadata check cannot do, and it is why this gate is
    # slow: it kills real children.
    if bash "$ROOT/$suite" >/dev/null 2>&1; then
      LIFE_PASS=$((LIFE_PASS+1))
      ok "lifecycle OK — $name (via ${suite##*/})"
    else
      rc=$?
      LIFE_FAILED=$((LIFE_FAILED+1))
      bad "lifecycle FAILED — $name (${suite##*/} exited $rc)"
    fi
  done
}

manifest_matches_releases_md() {
  # The manifest lives here AND in RELEASES.md. Two copies of a frozen list will disagree the first
  # time one is edited, and a release boundary that disagrees with itself is not frozen.
  local rel="$ROOT/RELEASES.md" line entry n missing=""
  [ -f "$rel" ] || { info "RELEASES.md absent — manifest cross-check skipped"; return 0; }
  line="$(awk '/^Codename: Nightwatch/,/^$/' "$rel" | /usr/bin/grep '^Manifest:')"
  if [ -z "$line" ]; then
    bad "RELEASES.md has no Manifest: line for Nightwatch — the frozen boundary is not recorded"
    return 1
  fi
  case "$line" in
    *"NOT YET FROZEN"*) bad "RELEASES.md still says the Nightwatch manifest is NOT YET FROZEN"; return 1 ;;
  esac
  for entry in "${MANIFEST[@]}"; do
    n="${entry%%|*}"
    printf '%s' "$line" | /usr/bin/grep -q "#$n" || missing="$missing #$n"
  done
  if [ -n "$missing" ]; then
    bad "RELEASES.md's frozen manifest does not name:$missing — this file and the ledger disagree"
    return 1
  fi
  ok "the frozen manifest here matches RELEASES.md's Nightwatch block (8 entries)"
}

# ── Mutation mode: the negative control for this audit ────────────────────────────────────────────
if [ "$MODE" = mutate ]; then
  echo "== nightwatch-release --mutate-evidence =="
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  cp "$ROOT/validate.sh" "$TMP/validate.sh"
  mkdir -p "$TMP/baselines"
  cp "$ROOT"/test/baselines/*.md "$TMP/baselines/" 2>/dev/null || true

  echo "-- baseline: the unmutated inputs"
  audit_manifest "$TMP/validate.sh" "$TMP/baselines"
  base_complete=$COMPLETE base_false=$FALSE_CLAIMS
  if [ "$base_false" -eq 0 ]; then
    ok "unmutated inputs report no false completion claims (complete=$base_complete)"
  else
    bad "unmutated inputs already report $base_false false claim(s) — the mutation below would prove nothing"
  fi

  echo "-- mutation 1: unregister a manifest gate from validate.sh (the #461 defect)"
  # Removing the line entirely, not commenting it: a commented line is still findable by a sloppy
  # grep, and a control that a sloppy implementation survives is not a control.
  /usr/bin/grep -v '"gh388-run-log-durability.sh"' "$TMP/validate.sh" > "$TMP/v2" && mv "$TMP/v2" "$TMP/validate.sh"
  audit_manifest "$TMP/validate.sh" "$TMP/baselines" >/dev/null 2>&1
  if [ "$COMPLETE" -lt "$base_complete" ]; then
    ok "unregistering a gate is DETECTED (complete $base_complete -> $COMPLETE)"
  else
    bad "unregistering a gate changed nothing — this audit does not read validate.sh's TESTS array"
  fi

  echo "-- mutation 2: delete a recorded negative control"
  cp "$ROOT/validate.sh" "$TMP/validate.sh"
  rm -f "$TMP/baselines/GH-409-negative-control.md"
  audit_manifest "$TMP/validate.sh" "$TMP/baselines" >/dev/null 2>&1
  if [ "$COMPLETE" -lt "$base_complete" ]; then
    ok "deleting a recorded control is DETECTED (complete $base_complete -> $COMPLETE)"
  else
    bad "deleting a control changed nothing — this audit does not read test/baselines/"
  fi

  echo "-- restore: the unmutated inputs must be green again in this same run"
  cp "$ROOT/validate.sh" "$TMP/validate.sh"
  cp "$ROOT"/test/baselines/*.md "$TMP/baselines/" 2>/dev/null || true
  audit_manifest "$TMP/validate.sh" "$TMP/baselines" >/dev/null 2>&1
  if [ "$COMPLETE" -eq "$base_complete" ]; then
    ok "restoring the inputs restores the verdict — the detector is not simply always-red"
  else
    bad "restored inputs do not reproduce the baseline verdict ($COMPLETE vs $base_complete)"
  fi

  printf '\n  nightwatch-release --mutate-evidence: %s passed, %s failed\n' "$PASS" "$FAIL"
  [ "$FAIL" -eq 0 ] || exit 1
  echo "  negative control OBSERVED in both directions"
  exit 0
fi

# ── Suite / gate modes ────────────────────────────────────────────────────────────────────────────
echo "== nightwatch-release (${MODE}) — release 0.3.0 frozen-manifest goalpost =="
echo
echo "-- half A: the frozen manifest"
manifest_matches_releases_md
audit_manifest

if [ "$MODE" = gate ]; then
  echo
  echo "-- half B: the lifecycle cases, EXECUTED (this is the slow half; it kills real children)"
  run_lifecycle
fi

echo
printf 'manifest: %s complete, %s remaining, %s false completion claim(s)\n' \
  "$COMPLETE" "$REMAINING" "$FALSE_CLAIMS"

if [ "$MODE" = gate ]; then
  printf 'lifecycle: %s passing, %s failing, %s NOT COVERED\n' \
    "$LIFE_PASS" "$LIFE_FAILED" "$LIFE_MISSING"
  echo
  if [ "$REMAINING" -eq 0 ] && [ "$FALSE_CLAIMS" -eq 0 ] \
     && [ "$LIFE_FAILED" -eq 0 ] && [ "$LIFE_MISSING" -eq 0 ]; then
    echo "GOALPOST MET — all 8 manifest entries complete and every lifecycle case executes green"
    exit 0
  fi
  echo "GOALPOST NOT MET — Nightwatch is not done."
  echo "  This is the correct state until the release is finished. Turning this command green is"
  echo "  what 0.3.0's exit criterion means; a closed backlog is not a substitute for it."
  exit 1
fi

# Suite mode: only a false completion claim is fatal. Remaining work is expected and reported.
if [ "$FAIL" -gt 0 ]; then
  printf '\n  nightwatch-release: %s passed, %s FAILED (false completion claim or ledger disagreement)\n' "$PASS" "$FAIL"
  exit 1
fi
printf '\n  nightwatch-release: %s passed, 0 failed, %s informational\n' "$PASS" "$INFO"
echo "  (suite mode is green while the release is in progress — run --release-gate for the goalpost)"
exit 0
