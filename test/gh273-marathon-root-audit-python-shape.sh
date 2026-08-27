#!/usr/bin/env bash
# GH-273: marathon-root-audit must recognize python3-spelled driver invocations — the exact
# GH-195 blind spot (test/gh115-round-cap.sh committed a live transcript onto the real clone
# because a direct `python3 marathon_drive.py` call was invisible to a `bash <driver>.sh`
# matcher). Pins, against isolated copies of the audit:
#   1. an UNSCOPED python3 invocation FAILS the audit (the GH-195 pin)
#   2. the same invocation with MARATHON_ROOT passes
#   3. scoping via continuation-group anchor args passes (args live BELOW the program token)
#   4. the `python3 - "<path>" <<'PY'` heredoc-argv shape — which READS the driver without
#      running it — is NOT an invocation and must not be flagged
#   5. a fixture-resident driver copy (path under a $WORK-derived var) passes
source "$(dirname "$0")/_setup.sh" gh273-marathon-root-audit-python-shape
XYZ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT_SRC="$XYZ_ROOT/test/marathon-root-audit.sh"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh273-marathon-root-audit-python-shape =="

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh273-audit.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT
. "$(dirname "$0")/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

[ -f "$AUDIT_SRC" ] || { echo "gh273: missing audit at $AUDIT_SRC" >&2; exit 1; }

# Each scenario gets its own directory holding ONE copy of the audit plus probe scripts;
# the audit scans its own directory and excludes itself by basename.
new_scenario_dir() {
  local d="$WORK/$1"
  mkdir -p "$d"
  cp "$AUDIT_SRC" "$d/audit.sh"
  chmod +x "$d/audit.sh"
  printf '%s\n' "$d"
}

# ── 1+2: the GH-195 pin — an unscoped python3 invocation fails; MARATHON_ROOT passes ──────────
D="$(new_scenario_dir unscoped)"
# The unsafe probe line is assembled from split tokens ON PURPOSE: the audit scans every
# test/*.sh — including this pinning file — and a literal unscoped python3 invocation in a
# heredoc would fail the audit from inside its own pin. The split renders byte-identical
# output in the probe file while never appearing contiguously in this source.
printf '%s\n' \
  'ROOT="/real/harness-repo"' \
  'python3 "$ROOT/utils/py/marathon_''drive.py" --phase-brief brief.md --round-cap 2' \
  > "$D/p1-unsafe.sh"
out="$(bash "$D/audit.sh" 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && pass 'unscoped python3 driver invocation FAILS the audit (the GH-195 pin)' \
  || fail "unscoped python3 invocation passed the audit"
grep -q "p1-unsafe.sh.*marathon_drive" <<<"$out" \
  && pass "  and the failure names the file and the python driver" \
  || fail "  failure did not name the python driver: $out"

D="$(new_scenario_dir scoped)"
cat > "$D/p2-scoped.sh" <<'PROBE'
ROOT="/real/harness-repo"
MARATHON_ROOT="$WORK/mroot" python3 "$ROOT/utils/py/marathon_drive.py" --phase-brief brief.md --round-cap 2
PROBE
out="$(bash "$D/audit.sh" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass 'the same invocation with MARATHON_ROOT passes' \
  || fail "MARATHON_ROOT-scoped python3 invocation failed the audit: $out"
grep -q "PASS: p2-scoped.sh.*marathon_drive" <<<"$out" \
  && pass "  and is reported as rooted" \
  || fail "  scoped invocation not reported: $out"

# ── 3: scoping args sit BELOW the program token — the continuation group must cover them ──────
D="$(new_scenario_dir anchors)"
cat > "$D/p3-anchor.sh" <<'PROBE'
DRIVER="/real/harness-repo/utils/py/marathon_drive.py"
python3 "$DRIVER" \
  --phase-brief "$A/brief.md" \
  --round-cap 2
PROBE
out="$(bash "$D/audit.sh" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "fixture-anchored args on the continuation group pass (gh438/gh115 shape)" \
  || fail "continuation-group anchor shape failed the audit: $out"

# ── 4: the heredoc-argv reader is NOT an invocation ───────────────────────────────────────────
D="$(new_scenario_dir heredoc)"
cat > "$D/p4-reader.sh" <<'PROBE'
ROOT="/real/harness-repo"
# reads the driver source without running it (gh390/gh322/gh342 shape)
python3 - "$ROOT/utils/py/marathon_drive.py" <<'PY'
import sys
print(open(sys.argv[1]).readline())
PY
# baseline so the audit has a real invocation to check in this scenario
MARATHON_ROOT="$WORK/mroot" python3 "$ROOT/utils/py/marathon_drive.py" --phase-brief b.md --round-cap 2
PROBE
out="$(bash "$D/audit.sh" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "python3 - <path> <<'PY' reader is not flagged as an invocation" \
  || fail "heredoc-argv reader was flagged: $out"
n_matches="$(grep -c "p4-reader.sh" <<<"$out")"
[ "$n_matches" -eq 1 ] && pass "  exactly one invocation matched in the file (the baseline, not the reader)" \
  || fail "  expected 1 match, saw $n_matches: $out"

# ── 5: a fixture-resident driver copy is safe by construction ─────────────────────────────────
D="$(new_scenario_dir resident)"
cat > "$D/p5-resident.sh" <<'PROBE'
WT="$WORK/harness-wt"
R1="$A/relay1.md"
python3 "$WT/utils/py/relay_drive.py" --relay-file "$R1" --agent-cmd /bin/true --dry-run
PROBE
out="$(bash "$D/audit.sh" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "fixture-resident relay_drive.py copy passes (gh376/poll-relay shape)" \
  || fail "fixture-resident driver copy failed the audit: $out"
grep -q "PASS: p5-resident.sh.*relay_drive" <<<"$out" \
  && pass "  and is reported as checked" \
  || fail "  fixture-resident invocation not reported: $out"

# ── 6: QA round 1 — unquoted spellings must not bypass the audit ──────────────────────────────
D="$(new_scenario_dir unquoted)"
# Split-token assembly again: the unsafe unquoted literal must not appear in THIS file.
printf '%s\n' \
  'ROOT="/real/harness-repo"' \
  'python3 $ROOT/utils/py/marathon_''drive.py --phase-brief brief.md --round-cap 2' \
  > "$D/p6-unquoted.sh"
out="$(bash "$D/audit.sh" 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && pass 'unquoted python3 <driver-path> spelling FAILS the audit (QA r1 Blocker)' \
  || fail "unquoted python3 invocation bypassed the audit"
grep -q "p6-unquoted.sh.*marathon_drive" <<<"$out" \
  && pass "  and the failure names the unquoted python driver" \
  || fail "  failure did not name the unquoted driver: $out"

D="$(new_scenario_dir unquoted-var)"
printf '%s\n' \
  'DRIVER="/real/harness-repo/utils/py/marathon_''drive.py"' \
  'MARATHON_ROOT="$WORK/mroot" python3 $DRIVER --phase-brief b.md --round-cap 2' \
  > "$D/p6b-unquoted-var.sh"
out="$(bash "$D/audit.sh" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass 'unquoted var-alias python3 invocation with MARATHON_ROOT on line passes' \
  || fail "unquoted var-alias scoped invocation failed the audit: $out"

# ── 7: QA round 1 — an env prefix binds to ITS command, not the next one after ';'/&&' ─────────
D="$(new_scenario_dir segment)"
printf '%s\n' \
  'ROOT="/real/harness-repo"' \
  'MARATHON_ROOT="$WORK/mroot" true; python3 $ROOT/utils/py/marathon_''drive.py --phase-brief b.md' \
  > "$D/p7-segment.sh"
out="$(bash "$D/audit.sh" 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && pass "scoping env in a ';'-separated OTHER command does not whitelist (QA r1)" \
  || fail "segment boundary hole: foreign-command env prefix whitelisted the invocation"

D="$(new_scenario_dir segment-ok)"
printf '%s\n' \
  'ROOT="/real/harness-repo"' \
  'MARATHON_ROOT="$WORK/mroot" python3 $ROOT/utils/py/marathon_''drive.py --phase-brief b.md --round-cap 2' \
  > "$D/p7b-segment-ok.sh"
out="$(bash "$D/audit.sh" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "same-command env prefix still passes" \
  || fail "same-command env prefix wrongly failed: $out"

# ── 8: QA round 2 — the segment finder must recognize VARIABLE spellings too ──────────────────
# Without this, invocation_segment fell back to whole-group semantics and a foreign-command
# env prefix could whitelist a 'python3 $DRIVER' invocation.
D="$(new_scenario_dir segment-var)"
printf '%s\n' \
  'DRIVER="/real/harness-repo/utils/py/marathon_''drive.py"' \
  'MARATHON_ROOT="$WORK/mroot" true; python3 $DRIVER --phase-brief b.md' \
  > "$D/p8-segment-var.sh"
out="$(bash "$D/audit.sh" 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && pass 'foreign-command env prefix does not whitelist a variable-spelled invocation (QA r2)' \
  || fail "segment fallback hole: variable invocation whitelisted by foreign-command prefix"

D="$(new_scenario_dir segment-var-ok)"
printf '%s\n' \
  'DRIVER="/real/harness-repo/utils/py/marathon_''drive.py"' \
  'MARATHON_ROOT="$WORK/mroot" python3 $DRIVER --phase-brief b.md --round-cap 2' \
  > "$D/p8b-segment-var-ok.sh"
out="$(bash "$D/audit.sh" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass 'same-command env prefix passes for variable spellings too' \
  || fail "variable invocation wrongly failed: $out"

echo "  gh273-marathon-root-audit-python-shape: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
