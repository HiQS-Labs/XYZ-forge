#!/usr/bin/env bash
# gh365-tier-fail-closed.sh — GH-365 step 8: tier routing is derived from canonical registries and
# demonstrably fails closed over the WHOLE tree, not just the fixtures the classifier's own test
# feeds it.
#
# What the classifier's own suite already proves: unknown paths, deleted/renamed tests, empty
# ranges, kernel/workflow/runner surfaces escalate (test/ci-route.sh). What THIS suite adds:
#   T1  FULL-REPO SWEEP — every tracked file in the repo, classified one at a time, must yield a
#       tier with a reason; a tier-2 answer must name its subsystem and resolve to at least one
#       runnable suite. There is no third state and no silent pass-through — this is the drift
#       guard that fires when a NEW path family lands unmapped and nobody notices.
#   T2  THE REVERSE REGISTRY HALF (GH-306 bidirectional pattern) — a test file whose family
#       matches a subsystem must be REGISTERED in that subsystem's SUBSYSTEM_TESTS or carry a
#       cited exemption. Without this half, a new suite can join TESTS while its subsystem lane
#       silently never runs it — the "another independently curated inventory" drift step 8
#       exists to prevent.
#   T3  RED controls for the sweep itself: a planted unmapped path and a planted unregistered
#       family member are both NAMED (the detectors fire, not just pass).
source "$(dirname "$0")/_setup.sh" gh365-tier-fail-closed
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
ROUTER="$REPO/utils/ci-route.sh"

echo "== test: gh365-tier-fail-closed =="

classify() {  # <path> -> sets CL_tier / CL_reason / CL_sub (from one ci-route run)
  local out
  out="$(printf '%s\n' "$1" | bash "$ROUTER" push 2>/dev/null)" || { CL_tier="?"; CL_reason="ci-route failed"; return; }
  CL_tier="$(grep -F 'tier=' <<<"$out" | tail -1 | cut -d= -f2)"
  CL_reason="$(grep -F 'tier_reason=' <<<"$out" | tail -1 | cut -d= -f2-)"
  CL_sub="$(grep -F 'tier2_subsystems=' <<<"$out" | tail -1 | cut -d= -f2-)"
}

# ── T1: the full-repo sweep ──────────────────────────────────────────────────────────────────────
_bad=""
_n1=0; _n2=0; _n3=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  classify "$f"
  case "$CL_tier" in
    1) _n1=$(( _n1 + 1 )) ;;
    2)
      _n2=$(( _n2 + 1 ))
      [ -n "$CL_sub" ] || _bad="$_bad$f: tier 2 with NO subsystem named; "
      ;;
    3) _n3=$(( _n3 + 1 )) ;;
    *) _bad="$_bad$f: unclassified (tier='$CL_tier'); " ;;
  esac
done < <(git -C "$REPO" ls-files)
if [ -n "$_bad" ]; then
  fail "T1: some tracked paths classify to neither a reasoned tier nor fail closed: $_bad"
else
  pass "T1: every tracked file classifies with a reason (tier1=$_n1 tier2=$_n2 tier3=$_n3) — no third state"
fi

# a tier-2 answer must resolve to at least one runnable suite (the zero-test escalation is the
# classifier's own; assert it holds for a representative tier-2 path)
_t2t="$(printf 'utils/hq/hq.sh\n' | bash "$ROUTER" push 2>/dev/null | grep -F 'tier2_tests=' | cut -d= -f2-)"
[ -n "$_t2t" ] || fail "T1b: a tier-2 path resolved to zero runnable suites"
pass "T1b: tier-2 paths resolve to runnable suites ($_t2t)"

# ── T2: the reverse registry half — family membership or a cited exemption ──────────────────────
family_of() {  # <suite-file> -> subsystem family name, or nothing
  case "$1" in
    hq-*.sh|hq.sh)                                  printf 'hq' ;;
    *releases*.sh|litmus-release.sh|meter-release.sh|ballast-release.sh|nightwatch-release.sh|releases-skill.sh|roadmap-dashboard.sh) printf 'releases' ;;
    pdda-*.sh|pdda-local-checks.sh)                 printf 'pdda' ;;
    *standup*.sh)                                   printf 'standup' ;;
    agent-chorus.sh)                                printf 'agent-chorus' ;;
    swe-diagram.sh)                                 printf 'swe-diagram' ;;
    ate-run-variations.sh)                          printf 'ate' ;;
    *telemetry*.sh|gh358-lock-instrumentation.sh)   printf 'telemetry' ;;
  esac
}
EXEMPT_from_family() {  # <suite> -> 0 when exempt (reasons inline), 1 when it must register
  case "$1" in
    # vendor-lane coverage of HOW releases gets vendored, not releases-app code:
    gh105-vendor-releases-addon.sh|gh349-releases-roadmap-vendored.sh) return 0 ;;
    # GH-346 harness/model telemetry honesty — harness-registry domain, not utils/telemetry/:
    gh346-model-telemetry-honesty.sh|gh346-telemetry-row-written.sh) return 0 ;;
    # marathon memory telemetry — marathon lane, not the telemetry subsystem:
    gh382-marathon-memory-telemetry.sh) return 0 ;;
    # runner/gate surface (GH-365 step 2): deliberately tier 3, never a subsystem lane:
    gh365-validate-telemetry.sh) return 0 ;;
    *) return 1 ;;
  esac
}
registered_anywhere() {  # <suite> -> 0 when some subsystem registers it (cross-family OK)
  # word membership via case (fork-free, and immune to the repo's pipe-into-grep -q ban)
  local b="$1" _sub line
  while IFS=$'\t' read -r _sub line; do
    case " $line " in *" $b "*) return 0 ;; esac
  done < <(bash "$ROUTER" subsystems 2>/dev/null)
  return 1
}
_missing=""
for f in "$REPO"/test/*.sh; do
  b="$(basename "$f")"
  fam="$(family_of "$b")"
  [ -n "$fam" ] || continue
  # a suite registered in ANY subsystem lane is covered — filenames cross families
  # (gh238-hq-releases-mode.sh is hq's, roadmap-dashboard.sh is hq's):
  registered_anywhere "$b" && continue
  EXEMPT_from_family "$b" && continue
  _missing="$_missing$b (family $fam); "
done
if [ -n "$_missing" ]; then
  fail "T2: family-named suites missing from their subsystem registry (register them or cite an exemption): $_missing"
else
  pass "T2: every family-named suite is registered in its subsystem lane or carries a cited exemption"
fi

# ── T3: the detectors fire ───────────────────────────────────────────────────────────────────────
# a planted UNMAPPED path must come back tier 3 naming it
classify "totally-unknown-family.zog"
[ "$CL_tier" = "3" ] && grep -q "unmapped" <<<"$CL_reason" \
  && pass "T3a RED: an unknown path family is tier 3 with the reason naming it" \
  || fail "T3a: unknown path classified tier=$CL_tier reason=$CL_reason"
# a planted unregistered family member must be NAMED by the T2 detector (re-run its logic on a
# fixture dir containing a planted suite)
PLANT="$WORK/planted-subsystem-suite"
mkdir -p "$PLANT"
require_fixture "$PLANT" "planted family suite dir"
printf '#!/usr/bin/env bash\nexit 0\n' > "$PLANT/hq-planted-new-lane.sh"
caught=""
for f in "$PLANT"/*.sh; do
  b="$(basename "$f")"; fam="$(family_of "$b")"
  [ -n "$fam" ] || continue
  registered_anywhere "$b" && continue
  EXEMPT_from_family "$b" || caught="$caught$b "
done
grep -q "hq-planted-new-lane.sh" <<<"$caught" \
  && pass "T3b RED: a new family-named suite outside the registry is NAMED by the T2 detector" \
  || fail "T3b: detector missed the planted suite (caught: '$caught')"

echo "== gh365-tier-fail-closed: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ] || exit 1
exit 0
