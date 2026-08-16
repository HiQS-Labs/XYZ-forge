#!/usr/bin/env bash
# GH-192: hermetic regression lock for utils/hq/rollup.sh's marathon-readiness bridge.
#
# Stubs agy (AGY_BIN) so no real network/CLI call happens, and reuses marathon-scan.sh's own
# fixture pattern (a fixture repo + stub swarm-preflight.sh) so the marathon section is a REAL
# classification, not a stub — proving the bridge actually invokes marathon-scan.sh and embeds its
# verbatim output. Cases: (A) ROADMAP has queued items -> agy-synthesized section + marathon
# section both present; (B) ROADMAP has none -> file still written (the one deliberate behavior
# change from before GH-192), placeholder + marathon section both present, agy never invoked;
# (C) marathon-scan.sh itself exits non-zero (via the MARATHON_SCAN_BIN test seam) -> visible
# failure banner, not a silent drop; (D) agy is entirely ABSENT from PATH and ROADMAP is empty ->
# rollup still succeeds and writes the marathon section (the actual consult-flagged Blocker fix:
# agy is only required when the ROADMAP scrape is non-empty, not unconditionally at startup).

set -uo pipefail
# strict-mode: -e exempt — assertion-style test with expected-nonzero probes handled explicitly.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
ROLLUP="$ROOT/utils/hq/rollup.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/hq-rollup.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

echo "== test: hq-rollup =="
echo "  workdir: $WORK"

REPO="$WORK/repos/repo-a"
mkdir -p "$REPO/.git" "$REPO/PROJECT/2-WORKING" "$REPO/utils"

cat >"$REPO/utils/swarm-preflight.sh" <<'EOF'
#!/usr/bin/env bash
set -uo pipefail
ISSUE=""
while (($# > 0)); do
  case "$1" in
    --gh-issue) ISSUE="${2:-}"; shift 2 ;;
    --target-root|--project-doc|--format|--dry-run) shift ;;
    *) shift ;;
  esac
done
if [[ "$ISSUE" == "101" ]]; then
  echo '{"readiness":{"ready":true}}'; exit 0
fi
echo '{"readiness":{"ready":false}}'; exit 6
EOF
chmod +x "$REPO/utils/swarm-preflight.sh"

cat >"$REPO/PROJECT/2-WORKING/MARATHON-PLAN-2026-07-09.md" <<'EOF'
---
title: repo-a-marathon
status: Active
---

# repo-a-marathon

## Recommended waves

**Wave 1:** #101
EOF

AGY_STUB="$WORK/agy-stub"
AGY_MARKER_FILE="$WORK/agy-invoked"
cat >"$AGY_STUB" <<EOF
#!/usr/bin/env bash
touch "$AGY_MARKER_FILE"
echo "AGY-STUB-SYNTHESIS-MARKER"
EOF
chmod +x "$AGY_STUB"

PDDA_DIR="$WORK/pdda"
mkdir -p "$PDDA_DIR"
XYZ_REG="$WORK/xyz.tsv"
cat >"$XYZ_REG" <<EOF
$REPO/.xyz	2026-07-09T00:00:00Z	0.2.0	a1	$REPO
EOF

VAULT="$WORK/vault"
OUT="$VAULT/HQ-Daily-Rollup.md"

run_rollup() {
  HQ_OBSIDIAN_VAULT="$VAULT" \
  HQ_XYZ_REGISTRY="$XYZ_REG" \
  HQ_PDDA_REGISTRY_DIR="$PDDA_DIR" \
  HQ_SEARCH_ROOTS="$WORK/repos" \
  HQ_MARATHON_SCAN_TODAY="2026-07-09" \
  HQ_MARATHON_SCAN_NOW="2026-07-09T12:00:00Z" \
  HQ_MARATHON_LIVE_TODAY="2026-07-09" \
  HQ_MARATHON_LIVE_NOW="2026-07-09T12:00:00Z" \
  AGY_BIN="${TEST_AGY_BIN:-$AGY_STUB}" \
  MARATHON_SCAN_BIN="${TEST_MARATHON_SCAN_BIN:-$ROOT/utils/hq/marathon-scan.sh}" \
  MARATHON_LIVE_BIN="${TEST_MARATHON_LIVE_BIN:-$ROOT/utils/hq/marathon-live.sh}" \
  bash "$ROLLUP"
}

echo "-- Case A: populated ROADMAP.md --"
cat >"$REPO/ROADMAP.md" <<'EOF'
# Roadmap
## Ledger
### Queue / parked intake
- **Test item** some description
EOF

run_rollup >"$WORK/case-a.log" 2>&1
rc=$?
[[ $rc -eq 0 ]] && pass "case A: rollup exits 0" || fail "case A: rollup rc=$rc ($(cat "$WORK/case-a.log"))"
[[ -f "$OUT" ]] && pass "case A: report written" || fail "case A: report missing"
[[ -f "$AGY_MARKER_FILE" ]] && pass "case A: agy stub was invoked" || fail "case A: agy stub never ran"

grep -q "AGY-STUB-SYNTHESIS-MARKER" "$OUT" \
  && pass "case A: agy-synthesized ROADMAP section present" || fail "case A: agy section missing"
grep -q "^## Marathon Readiness (cross-repo preflight)$" "$OUT" \
  && pass "case A: marathon section heading present" || fail "case A: marathon section heading missing"
grep -q "^### HQ MARATHON" "$OUT" \
  && pass "case A: embedded report's H1 demoted to H3 (nests under the H2 section)" \
  || fail "case A: embedded report's heading not demoted: $(grep '^#* HQ MARATHON' "$OUT")"
grep -q "^# HQ MARATHON" "$OUT" \
  && fail "case A: embedded report's H1 leaked through undemoted" \
  || pass "case A: no bare H1 from the embedded report"
grep -q '| #101 | .*| ✅ ready (exit 0) |' "$OUT" \
  && pass "case A: real marathon-scan classification embedded verbatim" \
  || fail "case A: marathon-scan classification missing/wrong: $(grep '#101' "$OUT")"
grep -q "^generated_by:" "$OUT" \
  && fail "case A: marathon-scan's own frontmatter leaked into the rollup" \
  || pass "case A: marathon-scan's frontmatter stripped"

# GH-218 Phase 2: the live cross-repo status is embedded as its own demoted section too.
grep -q "^## Live Marathons (cross-repo, right now)$" "$OUT" \
  && pass "case A: GH-218 live-marathon section heading present" || fail "case A: live-marathon section heading missing"
grep -q "^### HQ Marathon — Live cross-repo status" "$OUT" \
  && pass "case A: embedded live report's H1 demoted to H3 (nests under its H2)" \
  || fail "case A: live report heading not demoted: $(grep '^#* HQ Marathon — Live' "$OUT")"
grep -q '| repo-a | .* | ⚪ idle | ' "$OUT" \
  && pass "case A: real marathon-live classification embedded verbatim (repo-a idle)" \
  || fail "case A: marathon-live classification missing: $(grep 'repo-a' "$OUT" | grep -i idle)"

echo "-- Case B: empty ROADMAP.md, agy must NOT be invoked --"
rm -f "$AGY_MARKER_FILE" "$OUT"
cat >"$REPO/ROADMAP.md" <<'EOF'
# Roadmap
## Ledger
### Completed
- Nothing relevant to the queue/parked scrape here.
EOF

run_rollup >"$WORK/case-b.log" 2>&1
rc=$?
[[ $rc -eq 0 ]] && pass "case B: rollup exits 0" || fail "case B: rollup rc=$rc ($(cat "$WORK/case-b.log"))"
[[ -f "$OUT" ]] && pass "case B: report STILL written despite empty ROADMAP scrape" || fail "case B: report missing"
[[ -f "$AGY_MARKER_FILE" ]] && fail "case B: agy stub ran even though ROADMAP scrape was empty" \
  || pass "case B: agy stub correctly skipped"
grep -q "_No parked or active items found in any ROADMAP.md._" "$OUT" \
  && pass "case B: placeholder ROADMAP text present" || fail "case B: placeholder missing"
grep -q '| #101 | .*| ✅ ready (exit 0) |' "$OUT" \
  && pass "case B: marathon section still present on a quiet ROADMAP day" \
  || fail "case B: marathon section missing"

echo "-- Case C: marathon-scan.sh itself fails (non-zero exit) --"
FAILING_MARATHON_STUB="$WORK/marathon-scan-fail-stub"
cat >"$FAILING_MARATHON_STUB" <<'EOF'
#!/usr/bin/env bash
echo "simulated marathon-scan crash: boom" >&2
exit 3
EOF
chmod +x "$FAILING_MARATHON_STUB"

rm -f "$AGY_MARKER_FILE" "$OUT"
TEST_MARATHON_SCAN_BIN="$FAILING_MARATHON_STUB" run_rollup >"$WORK/case-c.log" 2>&1
rc=$?
[[ $rc -eq 0 ]] && pass "case C: rollup still exits 0 despite marathon-scan.sh failing" \
  || fail "case C: rollup rc=$rc ($(cat "$WORK/case-c.log"))"
[[ -f "$OUT" ]] && pass "case C: report still written" || fail "case C: report missing"
grep -q "_marathon scan failed (exit 3): .*simulated marathon-scan crash: boom" "$OUT" \
  && pass "case C: visible failure banner present, not a silent drop" \
  || fail "case C: failure banner missing/wrong: $(grep 'marathon scan failed' "$OUT")"

echo "-- Case D: agy entirely absent from PATH, ROADMAP empty (the consult-flagged Blocker) --"
rm -f "$AGY_MARKER_FILE" "$OUT"
NONEXISTENT_AGY="$WORK/no-such-agy-binary"
TEST_AGY_BIN="$NONEXISTENT_AGY" run_rollup >"$WORK/case-d.log" 2>&1
rc=$?
[[ $rc -eq 0 ]] && pass "case D: rollup succeeds even though agy is entirely absent from PATH" \
  || fail "case D: rollup rc=$rc ($(cat "$WORK/case-d.log"))"
[[ -f "$OUT" ]] && pass "case D: report still written with agy absent" || fail "case D: report missing"
grep -q "_No parked or active items found in any ROADMAP.md._" "$OUT" \
  && pass "case D: placeholder ROADMAP text present" || fail "case D: placeholder missing"
grep -q '| #101 | .*| ✅ ready (exit 0) |' "$OUT" \
  && pass "case D: marathon section reaches Obsidian even without agy installed" \
  || fail "case D: marathon section missing"

echo "-- Case E: marathon-live.sh itself fails (non-zero exit) -> visible banner, not a silent drop --"
FAILING_LIVE_STUB="$WORK/marathon-live-fail-stub"
cat >"$FAILING_LIVE_STUB" <<'EOF'
#!/usr/bin/env bash
echo "simulated marathon-live crash: kaboom" >&2
exit 4
EOF
chmod +x "$FAILING_LIVE_STUB"

rm -f "$AGY_MARKER_FILE" "$OUT"
cat >"$REPO/ROADMAP.md" <<'EOF'
# Roadmap
## Ledger
### Queue / parked intake
- **Test item** some description
EOF
TEST_MARATHON_LIVE_BIN="$FAILING_LIVE_STUB" run_rollup >"$WORK/case-e.log" 2>&1
rc=$?
[[ $rc -eq 0 ]] && pass "case E: rollup still exits 0 despite marathon-live.sh failing" \
  || fail "case E: rollup rc=$rc ($(cat "$WORK/case-e.log"))"
grep -q "_marathon live-status failed (exit 4): .*simulated marathon-live crash: kaboom" "$OUT" \
  && pass "case E: visible live-status failure banner present, not a silent drop" \
  || fail "case E: live failure banner missing/wrong: $(grep 'marathon live-status failed' "$OUT")"
grep -q '| #101 | .*| ✅ ready (exit 0) |' "$OUT" \
  && pass "case E: marathon-scan section still intact when only live-status failed" \
  || fail "case E: marathon-scan section lost on live-status failure"

echo "== hq-rollup: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
