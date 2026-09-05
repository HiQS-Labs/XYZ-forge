#!/usr/bin/env bash
# GH-299 Gen 4 Phase 5: sandboxed CI campaign — a BOUNDED soak of the real harness in a disposable
# full clone (cwd=sandbox_root), proving 0 host contamination, 0 false positives, line-valid
# telemetry, and the Phase 4 bridge (clusters -> synthesized suites) end to end. The multi-hour
# unattended soak (>10,000 mutations) is the operator-run companion, not this suite.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh299-p5-campaign.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

CAMPAIGN="$ROOT/utils/py/gen4_campaign.py"
SCHEMA="$ROOT/utils/py/telemetry_schema.py"

echo "== test: gh-gen4-phase5-campaign =="

[ -x "$CAMPAIGN" ] && pass "utils/py/gen4_campaign.py exists and is executable" || fail "gen4_campaign.py missing"
if grep -q 'SUITE_RESULT=PASS' <<<"$(python3 "$CAMPAIGN" --mode suite 2>&1)"; then
  pass "gen4_campaign.py --mode suite passes (bounded soak, contamination control, vacuous-sandbox refusal)"
else
  fail "gen4_campaign.py --mode suite failed"
fi
ntargets="$(python3 "$CAMPAIGN" --mode targets | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")"
[ "$ntargets" -ge 8 ] && pass "default target list covers $ntargets real harness surfaces" || fail "only $ntargets default targets"

# Snapshot the HOST clone identity before the soak; it must be byte-identical afterwards.
HOST_BEFORE="$(git -C "$ROOT" rev-parse HEAD; git -C "$ROOT" config --get core.bare; git -C "$ROOT" remote -v; git -C "$ROOT" symbolic-ref -q HEAD; shasum -a 256 "$ROOT/.git/config")"
HOST_STATUS_BEFORE="$(git -C "$ROOT" status --porcelain)"

# Bounded soak against THIS repo: two fast targets, ~60 mutations, disposable clone under $WORK.
OUT="$WORK/out"
rc=0
python3 "$CAMPAIGN" --mode run --repo "$ROOT" --sandbox-root "$WORK/sb" --out "$OUT" --duration 240 --max-mutations 60 --batch 15 --seed 7 \
  --only ci-route --only adaptive-ate-cli --keep-sandbox --quiet --json > "$WORK/run.json" 2> "$WORK/run.err" || rc=$?
require_fixture "$OUT" "campaign out dir"
require_fixture_file "$OUT/campaign-report.json" "campaign report"
[ "$rc" -eq 0 ] && pass "bounded soak exits 0 (zero contamination + valid telemetry)" || fail "campaign rc=$rc: $(tail -3 "$WORK/run.err")"
python3 - "$OUT/campaign-report.json" <<'PY' && pass "report: 60 mutations, 0 contamination events, 0 host violations, telemetry line-valid" || fail "report verdict: $(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d['mutations'], d['verdict'])" "$OUT/campaign-report.json")"
import json, sys
d = json.load(open(sys.argv[1]))
v = d["verdict"]
sys.exit(0 if d["mutations"] == 60 and not d["contamination_events"] and not d["host_violations"] and v["telemetry_line_valid"] else 1)
PY
[ -f "$OUT/campaign-summary.md" ] && grep -q 'zero host violations: True' "$OUT/campaign-summary.md" && pass "markdown summary written with the containment verdict" || fail "summary missing/incorrect"
python3 "$SCHEMA" --mode validate --path "$OUT/telemetry.jsonl" >/dev/null && pass "campaign telemetry validates as TelemetryEvent JSONL" || fail "campaign telemetry invalid"
[ "$(grep -c '"phase":"fuzz"' "$OUT/telemetry.jsonl")" -eq 60 ] && pass "one telemetry row per mutation" || fail "telemetry row count != 60"

# Containment against the HOST clone (the clone this suite runs in): identity + working tree unchanged.
HOST_AFTER="$(git -C "$ROOT" rev-parse HEAD; git -C "$ROOT" config --get core.bare; git -C "$ROOT" remote -v; git -C "$ROOT" symbolic-ref -q HEAD; shasum -a 256 "$ROOT/.git/config")"
[ "$HOST_BEFORE" = "$HOST_AFTER" ] && pass "host clone identity (HEAD, core.bare, remotes, symbolic HEAD, .git/config) unchanged" || fail "host identity moved"
[ "$(git -C "$ROOT" status --porcelain)" = "$HOST_STATUS_BEFORE" ] && pass "host working tree unchanged by the soak" || fail "host working tree changed: $(git -C "$ROOT" status --porcelain | head -3)"
# The sandbox is a full clone, disjoint from the host, and its tree is at baseline (corpus aside).
SB="$WORK/sb/clone"
require_fixture "$SB" "sandbox clone"
[ -z "$(git -C "$SB" status --porcelain | grep -v '^?? .fuzz_corpus/' || true)" ] && pass "sandbox clone tree at baseline after the soak (only .fuzz_corpus/ untracked)" || fail "sandbox drifted: $(git -C "$SB" status --porcelain | head -3)"
[ -d "$SB/.fuzz_corpus" ] && pass "per-target corpora persisted in the sandbox (.fuzz_corpus/<target>/)" || fail "no corpus in sandbox"

# Negative control: a poisoning target is caught, the sandbox restored, the host never touched.
cat > "$WORK/poison-targets.json" <<'J'
[{"name": "poison", "target": "sh -c 'echo poisoned > POISON.txt; exit 0' x {mutant}", "base": ["a"], "timeout": 10}]
J
rc2=0
python3 "$CAMPAIGN" --mode run --repo "$ROOT" --sandbox-root "$WORK/sb2" --out "$WORK/out2" --duration 120 --max-mutations 10 --batch 5 --seed 3 \
  --targets "$WORK/poison-targets.json" --no-synth --keep-sandbox --quiet --json > "$WORK/run2.json" 2>/dev/null || rc2=$?
[ "$rc2" -eq 0 ] && pass "poisoning target: host bar still met (exit 0) — sandbox drift is a recorded finding, not a host violation" || fail "poison campaign rc=$rc2"
python3 -c "import json,sys; d=json.load(open(sys.argv[1])); v=d['verdict']; sys.exit(0 if len(d['contamination_events'])>=1 and not v['zero_sandbox_contamination'] and v['zero_host_violations'] else 1)" "$WORK/out2/campaign-report.json" \
  && pass "contamination events recorded; verdict: zero_sandbox_contamination=false, zero_host_violations=true" || fail "contamination not recorded"
[ ! -e "$WORK/sb2/clone/POISON.txt" ] && pass "sandbox restored to baseline after contamination" || fail "POISON.txt survived in the sandbox"
[ ! -e "$ROOT/POISON.txt" ] && pass "host clone never received the poison" || fail "POISON.txt reached the host"

# Vacuous configuration refused: a sandbox root inside the repo.
if python3 "$CAMPAIGN" --mode run --repo "$ROOT" --sandbox-root "$ROOT/.gen4-vacuous" --out "$WORK/out3" --duration 5 --max-mutations 1 --only ci-route --quiet >/dev/null 2>&1; then
  fail "sandbox inside the repo was accepted"
else
  pass "sandbox root inside the repo is refused"
fi
rm -rf "$ROOT/.gen4-vacuous"

echo "== gh-gen4-phase5-campaign: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
