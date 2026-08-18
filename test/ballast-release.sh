#!/usr/bin/env bash
# gate-evidence: {"form":"deliberate-mutation","observed":true,"result":"--mutate-evidence builds a compliant fixture (gate present+registered, control recorded, manifest agreeing with a fixture RELEASES.md), then unregisters a gate, deletes a recorded control, and forges a stranger-run PASS record it never reads; each is detected, and the unmutated fixture is re-checked green in the same run"}
# Ballast (release 0.7.0) — the executable goalpost for POST-LAUNCH HARDENING.
#
# Ballast's sentence: THE LAUNCHED REPOSITORY HOLDS UP UNDER A STRANGER'S FIRST RUN AND AN OUTSIDE
# CONTRIBUTOR'S FIRST PUSH. Same two-half shape Litmus, Nightwatch, and Meter established — this
# file is written FIRST, before any manifest member is fixed, so a finished entry can be told from
# a claimed one (RELEASES.md's exit-criterion note).
#
#   HALF A — audits the FROZEN MANIFEST (structural, cheap, runs in suite mode). Each member's gate
#            EXISTS, is REGISTERED in validate.sh's TESTS array (a gate absent from TESTS is
#            indistinguishable from one that passes — the #461 defect), has a RECORDED negative
#            control under test/baselines/, and the manifest here agrees with RELEASES.md's
#            Ballast `Manifest-Members:` field in BOTH directions (a one-directional check, or one
#            that reads the prose `Manifest:` paragraph instead of the machine field, cannot fail —
#            see meter-release.sh's own history for exactly how that happened).
#
#   HALF B — EXECUTES the stranger's path rather than auditing it (--release-gate only; heavy, and
#            deliberately NOT run in suite mode). Three checks, one per manifest theme:
#              B1 (#15) — ten consecutive `bash validate.sh --parallel N` runs in a fresh clone,
#                         zero failing runs (a contention warning is allowed only where it names
#                         the contended suite, per #15's own contract).
#              B2 (#4)  — a fresh, ungated clone's `validate.sh --print-mode` surfaces the missing
#                         gate in-band, non-fatally, naming the one-command fix; with the gate
#                         installed, a forced-red validate.sh is REFUSED at the push boundary.
#              B3 (#14) — test/gh14-atomic-append.sh's cross-process stress case, run fresh: a
#                         writer killed mid-append loses no event, no reader observes a torn file.
#
# THREE MODES, same shape as litmus/nightwatch/meter-release.sh:
#
#   (default)         Suite mode, registered in validate.sh. GREEN while Ballast is in progress.
#                     Fails ONLY on a false completion claim (a CLOSED manifest issue whose gate is
#                     missing/unregistered/uncontrolled) or a ledger disagreement — an unfinished
#                     release does not paint the whole suite red (#460's failure mode).
#
#   --release-gate    THE GOALPOST. Exits non-zero until Half A and Half B both pass and every
#                     manifest entry is complete. RED UNTIL BALLAST IS DONE — by design, on arrival.
#                     Requires XYZ_BALLAST_STRANGER_CLONE (an absolute path to a fresh, disposable,
#                     durable-location clone — never /tmp, per GH-388's own-root durability rule).
#                     Without it, Half B reports NOT COVERED and the gate stays RED.
#
#   --mutate-evidence The negative control for this file. Builds a compliant fixture, breaks it in
#                     specific ways, requires each break to be detected, and re-checks the
#                     unmutated fixture green in the same run.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

MODE=suite
case "${1:-}" in
  --release-gate)    MODE=gate ;;
  --mutate-evidence) MODE=mutate ;;
  --help|-h)         /usr/bin/sed -n '3,45p' "$0"; exit 0 ;;
  "")                ;;
  *) printf 'usage: %s [--release-gate | --mutate-evidence]\n' "$0" >&2; exit 2 ;;
esac

PASS=0; FAIL=0; INFO=0
ok()   { printf '  PASS: %s\n' "$*"; PASS=$((PASS+1)); }
bad()  { printf '  FAIL: %s\n' "$*" >&2; FAIL=$((FAIL+1)); }
info() { printf '  INFO: %s\n' "$*"; INFO=$((INFO+1)); }

# ── The FROZEN manifest, post-#10-cut (2026-08-17) ───────────────────────────────────────────────
# Format: <issue>|<gate test file>|<recorded control file>|<note>
# A re-scope (an admission, a swap, a cut) must be matched in RELEASES.md's `Manifest-Members:`
# field — the cross-check below compares the two in BOTH directions.
MANIFEST=(
  "14|test/gh14-atomic-append.sh|test/baselines/GH-14-negative-control.md|atomic event append — appendEvent publishes via temp+rename"
  "15|test/gh528-parallel-contention-retry.sh|test/baselines/GH-15-parallel-contention-negative-control.md|parallel contention retry — extends the pre-existing GH-528 suite"
  "4|test/gh4-ungated-clone-warning.sh|test/baselines/GH-4-negative-control.md|ungated-clone warning travels with the repo, non-fatal"
  "3|test/gh430-state-dir-tracked-default.sh|test/baselines/GH-3-state-dir-negative-control.md|state-dir durability (GH-430 landed pre-Ballast; control completed here)"
)

# The documented entry path a stranger follows, verbatim from README.md's Quickstart.
HAPPY_PATH_CMD="${XYZ_BALLAST_HAPPY_PATH:-npm install && bash validate.sh}"
STRANGER_RUNS="${XYZ_BALLAST_STRANGER_RUNS:-10}"
STRANGER_PARALLEL="${XYZ_BALLAST_STRANGER_PARALLEL:-4}"

registered_in_validate() {  # <test path> — is it in validate.sh's TESTS array?
  local base="${1##*/}" validate="${2:-$ROOT/validate.sh}"
  /usr/bin/sed -n '/^TESTS=(/,/^)/p' "$validate" | /usr/bin/grep -qF "\"$base\""
}

control_recorded() {  # <control file, repo-relative> [<root>] — does it exist?
  local f="$1" root="${2:-$ROOT}"
  [ -f "$root/$f" ]
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
    STATE_CACHE="${STATE_CACHE}:${n}=unknown:"; ISSUE_STATE="unknown"; return
  fi
  local st
  st="$(gh issue view "$n" --json state --jq .state 2>/dev/null | tr -d '\n' | tr '[:lower:]' '[:upper:]')" || st="unknown"
  [ -z "$st" ] && st="unknown"
  STATE_CACHE="${STATE_CACHE}:${n}=${st}:"
  ISSUE_STATE="$st"
}

# ── Half A: the frozen manifest ───────────────────────────────────────────────────────────────────
audit_manifest() {  # [<validate.sh>] [<root>] — sets COMPLETE / REMAINING / FALSE_CLAIMS
  local validate="${1:-$ROOT/validate.sh}" root="${2:-$ROOT}"
  COMPLETE=0; REMAINING=0; FALSE_CLAIMS=0
  local entry n gate ctl note state have_gate have_reg have_ctl
  for entry in "${MANIFEST[@]}"; do
    n="${entry%%|*}"; entry="${entry#*|}"
    gate="${entry%%|*}"; entry="${entry#*|}"
    ctl="${entry%%|*}"; note="${entry#*|}"
    have_gate=0; have_reg=0; have_ctl=0
    [ -f "$root/$gate" ] && have_gate=1
    registered_in_validate "$gate" "$validate" && have_reg=1
    control_recorded "$ctl" "$root" && have_ctl=1

    get_issue_state "$n"
    state="$ISSUE_STATE"

    local why=""
    [ "$have_gate" -eq 0 ] && why="$why gate-missing($gate)"
    [ "$have_reg"  -eq 0 ] && why="$why not-registered-in-validate.sh"
    [ "$have_ctl"  -eq 0 ] && why="$why no-recorded-control($ctl)"

    if [ -n "$why" ]; then
      REMAINING=$((REMAINING+1))
      if [ "$state" = "CLOSED" ]; then
        FALSE_CLAIMS=$((FALSE_CLAIMS+1))
        bad "#$n is CLOSED but its gate is not complete —$why"
      else
        info "#$n remaining —$why  ($note)"
      fi
      continue
    fi

    case "$state" in
      CLOSED)
        COMPLETE=$((COMPLETE+1))
        ok "#$n complete — $gate registered, control recorded, issue CLOSED"
        ;;
      OPEN)
        REMAINING=$((REMAINING+1))
        info "#$n remaining — evidence machinery in place but the issue is still OPEN  ($note)"
        ;;
      *)
        REMAINING=$((REMAINING+1))
        info "#$n remaining — evidence machinery in place, issue state UNAVAILABLE (gh absent or unauthed); not credited  ($note)"
        ;;
    esac
  done
}

# ── The ledger cross-check, BIDIRECTIONAL ─────────────────────────────────────────────────────────
manifest_matches_releases_md() {
  local rel="${1:-$ROOT/RELEASES.md}" line n missing="" extra="" declared
  [ -f "$rel" ] || { info "RELEASES.md absent — manifest cross-check skipped"; return 0; }

  line="$(/usr/bin/awk '/^Codename: Ballast/,/^$/' "$rel" | /usr/bin/grep '^Manifest-Members:')"
  if [ -z "$line" ]; then
    bad "RELEASES.md's Ballast block has no machine-readable 'Manifest-Members:' field — the frozen boundary is not recorded in a form this gate can check (the prose Manifest: paragraph names cut/shipped members too and cannot be used)"
    return 1
  fi
  declared="${line#Manifest-Members:}"

  local entry
  for entry in "${MANIFEST[@]}"; do
    n="${entry%%|*}"
    printf ' %s ' "$declared" | /usr/bin/grep -q " $n " || missing="$missing #$n"
  done
  for n in $declared; do
    case "$n" in ''|*[!0-9]*) continue ;; esac
    printf '%s\n' "${MANIFEST[@]}" | /usr/bin/grep -q "^$n|" || extra="$extra #$n"
  done

  if [ -n "$missing" ] || [ -n "$extra" ]; then
    [ -n "$missing" ] && bad "RELEASES.md's Manifest-Members does not declare:$missing — this file names members the ledger does not"
    [ -n "$extra" ]   && bad "this file does not name:$extra — the ledger declares members this gate does not measure"
    return 1
  fi
  ok "the frozen manifest here matches RELEASES.md's Manifest-Members field in both directions ($declared)"
}

# ── Half B: the stranger's path, EXECUTED ─────────────────────────────────────────────────────────
run_stranger_path() {  # <fresh clone root> — sets STR_PASS / STR_FAIL / STR_MISSING
  local clone="${1:-}"
  STR_PASS=0; STR_FAIL=0; STR_MISSING=0

  if [ -z "$clone" ] || [ ! -d "$clone" ]; then
    STR_MISSING=$((STR_MISSING+1))
    info "stranger's path NOT COVERED — set XYZ_BALLAST_STRANGER_CLONE to a fresh, disposable, durable-location clone (never /tmp)"
    return 1
  fi
  case "$clone" in
    /tmp/*|/private/tmp/*|"${TMPDIR:-/nonexistent}"*)
      STR_FAIL=$((STR_FAIL+1))
      bad "XYZ_BALLAST_STRANGER_CLONE is under a tmp root ($clone) — gh388-run-log-durability fails a clone rooted there; use a durable location"
      return 1
      ;;
  esac

  # B1 (#15) — ten consecutive parallel runs, zero failing (contention-named is allowed)
  local i rc contention_only=1 any_fail=0
  for i in $(seq 1 "$STRANGER_RUNS"); do
    local log; log="$(mktemp -t ballast-stranger-run.XXXXXX)"
    if (cd "$clone" && bash validate.sh --parallel "$STRANGER_PARALLEL" >"$log" 2>&1); then
      rc=0
    else
      rc=$?
    fi
    if [ "$rc" -ne 0 ]; then
      any_fail=1
      if /usr/bin/grep -q "WARNING (GH-528)" "$log" && ! /usr/bin/grep -qE '^failed:$' "$log"; then
        : # contention-only, named — acceptable per #15's contract
        rm -f "$log"
      else
        contention_only=0
        local fail_log="$clone/../ballast-fail-$i.log"
        cp "$log" "$fail_log"
        rm -f "$log"
        bad "stranger run $i/$STRANGER_RUNS FAILED (not contention-only) — see $fail_log"
      fi
    else
      rm -f "$log"
    fi
  done
  if [ "$any_fail" -eq 0 ]; then
    STR_PASS=$((STR_PASS+1)); ok "B1 (#15): $STRANGER_RUNS/$STRANGER_RUNS consecutive parallel runs, zero failures"
  elif [ "$contention_only" -eq 1 ]; then
    STR_PASS=$((STR_PASS+1)); ok "B1 (#15): $STRANGER_RUNS consecutive parallel runs, failures were contention-only and named"
  else
    STR_FAIL=$((STR_FAIL+1))
  fi

  # B2 (#4) — ungated clone warns in-band, non-fatally; gated + forced-red push is refused
  rm -f "$clone/.git/hooks/pre-push"
  local out2 rc2
  out2="$(cd "$clone" && bash validate.sh --print-mode 2>&1)"; rc2=$?
  if [ "$rc2" -eq 0 ] && printf '%s' "$out2" | /usr/bin/grep -q "NOT INSTALLED in this clone"; then
    STR_PASS=$((STR_PASS+1)); ok "B2a (#4): ungated stranger clone warns in-band, non-fatally"
  else
    STR_FAIL=$((STR_FAIL+1)); bad "B2a (#4): ungated stranger clone did not warn correctly (rc=$rc2)"
  fi

  (cd "$clone" && bash githooks/install.sh >/dev/null 2>&1)
  local stub; stub="$(cd "$clone" && git rev-parse --git-common-dir 2>/dev/null)/hooks/pre-push"
  case "$stub" in /*) ;; *) stub="$clone/$stub" ;; esac
  if [ -x "$stub" ]; then
    cp "$clone/validate.sh" "$clone/validate.sh.bak"
    printf '#!/usr/bin/env bash\necho "forced red for B2b"\nexit 1\n' > "$clone/validate.sh"
    chmod +x "$clone/validate.sh"
    local push_out push_rc
    push_out="$(cd "$clone" && printf 'refs/heads/x %s refs/heads/x 0000000000000000000000000000000000000000\n' "$(printf 'a%.0s' $(seq 1 40))" | "$stub" 2>&1)"; push_rc=$?
    mv "$clone/validate.sh.bak" "$clone/validate.sh"
    if [ "$push_rc" -ne 0 ] && printf '%s' "$push_out" | /usr/bin/grep -qi "refused"; then
      STR_PASS=$((STR_PASS+1)); ok "B2b (#4): a forced-red validate.sh is REFUSED at the push boundary (gated)"
    else
      STR_FAIL=$((STR_FAIL+1)); bad "B2b (#4): a forced-red push was NOT refused (rc=$push_rc): $push_out"
    fi
  else
    STR_FAIL=$((STR_FAIL+1)); bad "B2b (#4): could not resolve the installed pre-push stub at $stub"
  fi

  # B3 (#14) — the atomic-append cross-process stress case, run fresh
  if (cd "$clone" && bash test/gh14-atomic-append.sh >/dev/null 2>&1); then
    STR_PASS=$((STR_PASS+1)); ok "B3 (#14): a writer killed mid-append loses no event; no reader observes a torn file"
  else
    STR_FAIL=$((STR_FAIL+1)); bad "B3 (#14): gh14-atomic-append.sh failed in the fresh clone"
  fi

  [ "$STR_FAIL" -eq 0 ]
}

# ── Mutation mode: the negative control for this audit ────────────────────────────────────────────
if [ "$MODE" = mutate ]; then
  echo "== ballast-release --mutate-evidence =="
  TMP="$(mktemp -d -t ballast-mutate.XXXXXX)"
  case "$TMP" in "") echo "mktemp returned EMPTY — refusing (#564)" >&2; exit 2 ;; esac
  trap 'rm -rf "$TMP"' EXIT

  MUT_PASS=0; MUT_FAIL=0
  mut_ok()  { printf '  PASS: %s\n' "$*"; MUT_PASS=$((MUT_PASS+1)); }
  mut_bad() { printf '  FAIL: %s\n' "$*" >&2; MUT_FAIL=$((MUT_FAIL+1)); }

  # A compliant fixture root: one manifest member, its gate present+registered, its control present.
  FIX="$TMP/fixture"
  mkdir -p "$FIX/test/baselines"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$FIX/test/fixture-gate.sh"
  printf 'TESTS=(\n  "fixture-gate.sh"\n)\n' > "$FIX/validate.sh"
  printf '# fixture control\npre-fix: FAIL. post-fix: PASS.\n' > "$FIX/test/baselines/fixture-control.md"
  FIX_MANIFEST_ENTRY="999|test/fixture-gate.sh|test/baselines/fixture-control.md|fixture member"

  fixture_audit() {  # runs audit_manifest against MANIFEST=($FIX_MANIFEST_ENTRY) on $FIX
    local saved=("${MANIFEST[@]}")
    MANIFEST=("$FIX_MANIFEST_ENTRY")
    STATE_CACHE=":999=CLOSED:"  # force CLOSED so completeness is testable without gh
    audit_manifest "$FIX/validate.sh" "$FIX" >/dev/null 2>&1
    MANIFEST=("${saved[@]}")
  }

  echo "-- baseline: the unmutated fixture"
  fixture_audit
  if [ "$FALSE_CLAIMS" -eq 0 ] && [ "$COMPLETE" -eq 1 ]; then
    mut_ok "unmutated fixture: #999 complete, 0 false claims — the control is discriminating, not always-red"
  else
    mut_bad "unmutated fixture already reports complete=$COMPLETE false_claims=$FALSE_CLAIMS — the mutations below would prove nothing"
  fi

  echo "-- mutation 1: unregister the gate (remove it from TESTS but leave the file)"
  printf 'TESTS=(\n)\n' > "$FIX/validate.sh"
  fixture_audit
  if [ "$FALSE_CLAIMS" -eq 1 ]; then
    mut_ok "an unregistered gate on a CLOSED issue is DETECTED as a false completion claim"
  else
    mut_bad "an unregistered gate was NOT detected (false_claims=$FALSE_CLAIMS)"
  fi
  printf 'TESTS=(\n  "fixture-gate.sh"\n)\n' > "$FIX/validate.sh"

  echo "-- mutation 2: delete the recorded control"
  mv "$FIX/test/baselines/fixture-control.md" "$TMP/fixture-control.keep"
  fixture_audit
  if [ "$FALSE_CLAIMS" -eq 1 ]; then
    mut_ok "a deleted recorded control on a CLOSED issue is DETECTED as a false completion claim"
  else
    mut_bad "a deleted control was NOT detected (false_claims=$FALSE_CLAIMS)"
  fi
  mv "$TMP/fixture-control.keep" "$FIX/test/baselines/fixture-control.md"

  echo "-- mutation 3: forge a passing stranger-run record — Half B must not read it"
  # Half B EXECUTES; it has no code path that consults a record file. This proves that property:
  # planting a fake "PASS" file where a cache might live changes nothing, because nothing reads it.
  FORGED="$TMP/forged-stranger-run-PASS.md"
  printf 'stranger run: 10/10 PASS (FORGED — this file was never produced by a real run)\n' > "$FORGED"
  # No clone provided -> Half B must report NOT COVERED regardless of the forged file sitting next
  # to it, proving the verdict comes from executing the path, not from any file it might trust.
  run_stranger_path "" >/dev/null 2>&1
  if [ "$STR_MISSING" -eq 1 ] && [ "$STR_PASS" -eq 0 ]; then
    mut_ok "a forged stranger-run PASS record has NO EFFECT — Half B still reports NOT COVERED with no clone to execute against"
  else
    mut_bad "Half B's verdict changed in the presence of a forged record (missing=$STR_MISSING pass=$STR_PASS) — it may be reading a cached claim instead of executing"
  fi
  rm -f "$FORGED"

  echo "-- mutation 4: ledger declares a member this file does not measure (direction 2)"
  REL_FIX="$TMP/RELEASES.md"
  { echo "Codename: Ballast"; echo "Manifest-Members: 14 15 4 3 999"; echo; } > "$REL_FIX"
  saved=("${MANIFEST[@]}")
  if manifest_matches_releases_md "$REL_FIX" >/dev/null 2>&1; then
    mut_bad "a ledger declaring an unmeasured #999 was ACCEPTED — direction 2 does not work"
  else
    mut_ok "a ledger declaring an unmeasured #999 is DETECTED (direction 2 works)"
  fi

  echo "-- mutation 5: this file measures a member the ledger drops (direction 1)"
  { echo "Codename: Ballast"; echo "Manifest-Members: 14 15 4"; echo; } > "$REL_FIX"
  if manifest_matches_releases_md "$REL_FIX" >/dev/null 2>&1; then
    mut_bad "a ledger missing #3 was ACCEPTED — direction 1 does not work"
  else
    mut_ok "a ledger missing #3 is DETECTED (direction 1 works)"
  fi

  echo "-- restore: the unmutated fixture and ledger must be green again in this same run"
  fixture_audit
  { echo "Codename: Ballast"; echo "Manifest-Members: 14 15 4 3"; echo; } > "$REL_FIX"
  if [ "$FALSE_CLAIMS" -eq 0 ] && [ "$COMPLETE" -eq 1 ] && manifest_matches_releases_md "$REL_FIX" >/dev/null 2>&1; then
    mut_ok "restoring the inputs restores the verdict — the detector is not simply always-red"
  else
    mut_bad "restored inputs do not reproduce the baseline verdict (complete=$COMPLETE false_claims=$FALSE_CLAIMS)"
  fi

  printf '\n  ballast-release --mutate-evidence: %s passed, %s failed\n' "$MUT_PASS" "$MUT_FAIL"
  [ "$MUT_FAIL" -eq 0 ] || exit 1
  echo "  negative control OBSERVED (gate unregistration, control deletion, forged stranger-run record; ledger both directions)"
  exit 0
fi

# ── Suite / gate modes ────────────────────────────────────────────────────────────────────────────
echo "== ballast-release (${MODE}) — release 0.7.0 post-launch-hardening goalpost =="
echo
echo "-- the frozen manifest"
manifest_matches_releases_md
audit_manifest

if [ "$MODE" = gate ]; then
  echo
  echo "-- half B: the stranger's path, EXECUTED (this can take a while — $STRANGER_RUNS runs)"
  run_stranger_path "${XYZ_BALLAST_STRANGER_CLONE:-}"
fi

echo
printf 'manifest: %s complete, %s remaining, %s false completion claim(s)\n' \
  "$COMPLETE" "$REMAINING" "$FALSE_CLAIMS"

if [ "$MODE" = gate ]; then
  printf "stranger's path: %s passing, %s failing, %s NOT COVERED\n" "$STR_PASS" "$STR_FAIL" "$STR_MISSING"
  echo
  if [ "$REMAINING" -eq 0 ] && [ "$FALSE_CLAIMS" -eq 0 ] \
     && [ "$STR_FAIL" -eq 0 ] && [ "$STR_MISSING" -eq 0 ]; then
    echo "GOALPOST MET — the launched repository holds up under a stranger's first run and an outside contributor's first push"
    exit 0
  fi
  echo "GOALPOST NOT MET — Ballast is not done."
  echo "  This is the correct state until every manifest member is complete AND the stranger's path"
  echo "  has been executed fresh, green. A closed backlog is not a substitute for it."
  exit 1
fi

# Suite mode: only a false completion claim or a ledger disagreement is fatal.
if [ "$FAIL" -gt 0 ]; then
  printf '\n  ballast-release: %s passed, %s FAILED (false completion claim or ledger disagreement)\n' "$PASS" "$FAIL"
  exit 1
fi
printf '\n  ballast-release: %s passed, 0 failed, %s informational\n' "$PASS" "$INFO"
echo "  (suite mode is green while Ballast is in progress — run --release-gate for the goalpost)"
exit 0
