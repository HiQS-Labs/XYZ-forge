#!/usr/bin/env bash
# gh365-validate-telemetry.sh — GH-365 step 2: retained phase/suite/worker JSONL telemetry.
#
# The #365 baseline had to be measured by hand; now every validate.sh / ci-local.sh run emits a
# reconstructable record (one shared implementation: test/lib/runner-telemetry.sh). This suite
# witnesses:
#   A. the emitter's unit contract — valid JSON per line, required keys, sane types;
#   B. a REAL validate.sh end-to-end in a fixture: run.start denominator, pool suite events with
#      bytes/hash/skip_lines, a deterministic retry classified contended, sequential-mode events,
#      and a run.summary carrying envelope validity;
#   C. the wiring pins — both runners source the ONE lib, ci-local times every step() uniformly,
#      and the real-repo denominator is what the file says it is (no inherited stale count);
#   D. the skip_lines metric — a suite printing SKIP verdict lines is COUNTED, because a
#      contention-skip in a green suite is exactly what step 3 must be able to invalidate.
source "$(dirname "$0")/_setup.sh" gh365-validate-telemetry
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

echo "== test: gh365-validate-telemetry =="

# ── A. unit contract ─────────────────────────────────────────────────────────────────────────────
. "$REPO/test/lib/runner-telemetry.sh"
export XYZ_VALIDATE_TELEMETRY="$WORK/telemetry"
rt_begin "$REPO" "unit" "parallel" 4 3 307
[ -n "$RT_FILE" ] && [ -f "$RT_FILE" ] || fail "A1: rt_begin wrote no file"
_s="$(rt_now_ms)"
printf '  PASS: unit probe\n  SKIP: unit skip reason\n' > "$WORK/unit.log"
rt_suite pool "demo-suite.sh" "$_s" "$(( _s + 150 ))" 0 "$WORK/unit.log"
rt_emit stage stage "envelope-assert" "$_s" "$(( _s + 5 ))" 0
rt_extra "phase=fixture" "ms=12"
RT_ENVELOPE_RC=0; RT_ENVELOPE_DRIFT=none
rt_summary 305 2 307 "suite_events=1"
python3 - "$RT_FILE" <<'PY' || fail "A2: telemetry lines are not all valid JSON with the required keys"
import json, sys
required_suite = {"v","ts_ms","run","runner","event","lane","name","started_ms","ended_ms","duration_ms","rc","worker","out_bytes","out_sha256","skip_lines","queued_ms"}
seen = {"run.start":0,"suite":0,"stage":0,"extra":0,"run.summary":0}
for line in open(sys.argv[1]):
    r = json.loads(line)                      # invalid JSON raises -> nonzero exit
    ev = r["event"]; seen[ev] += 1
    if ev == "suite":
        missing = required_suite - set(r)
        assert not missing, f"suite event missing {missing}"
        for k in ("ts_ms","started_ms","ended_ms","duration_ms","rc","worker","out_bytes","skip_lines","queued_ms"):
            assert isinstance(r[k], int), f"{k} is not an int: {r[k]!r}"
assert seen["run.start"] == 1 and seen["run.summary"] == 1 and seen["suite"] == 1
PY
pass "A2: every line is valid JSON; suite events carry the full key set with int fields"
_sk="$(grep -c '"skip_lines":1' "$RT_FILE" || true)"
[ "$_sk" = "1" ] || fail "A3: skip_lines did not count this suite's own SKIP line"
pass "A3: skip_lines counted the SKIP line in the input log"
unset XYZ_VALIDATE_TELEMETRY RT_FILE

# ── B. end-to-end: REAL validate.sh in a fixture, real telemetry, stub suites ────────────────────
mkfixture() {
  local r="$WORK/vt-repo"
  rm -rf "$r"; mkdir -p "$r"
  require_fixture "$r" "telemetry fixture"
  git -C "$r" init -q; git -C "$r" config user.email t@t; git -C "$r" config user.name t
  mkdir -p "$r/test/lib" "$r/utils/pdda" "$r/utils/py" "$r/utils/hq" "$r/relay-automation" "$r/githooks"
  cp "$REPO/validate.sh" "$r/validate.sh"; chmod +x "$r/validate.sh"
  cp "$REPO/test/lib/clone-identity.sh"   "$r/test/lib/clone-identity.sh"
  cp "$REPO/test/lib/runner-envelope.sh"  "$r/test/lib/runner-envelope.sh"
  cp "$REPO/test/lib/runner-telemetry.sh" "$r/test/lib/runner-telemetry.sh"
  cp "$REPO/relay-automation/gate-env.sh" "$r/relay-automation/gate-env.sh"
  cp "$REPO/utils/ci-route.sh" "$r/utils/ci-route.sh"; chmod +x "$r/utils/ci-route.sh"
  cp "$REPO/utils/py/gate_env.py" "$r/utils/py/gate_env.py"
  printf '#!/usr/bin/env bash\necho stub-pdda ran\nexit 0\n' > "$r/utils/pdda/pdda.sh"; chmod +x "$r/utils/pdda/pdda.sh"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$r/utils/hq/hq.sh"
  # The real repo gitignores .tick/ (line 1 of its .gitignore) — the telemetry store lives under
  # .tick/telemetry, and in a fixture WITHOUT that ignore the GH-365 envelope correctly flags the
  # telemetry file itself as tracked-tree drift (observed: clone-identity-invariant went red on
  # the very first run of this suite — the detector catching its own instrumentation). The
  # fixture mirrors the real repo's ignore so the run under test stays green.
  printf '.tick/\n' > "$r/.gitignore"
  printf '%s' "$r"
}
FB="$(mkfixture)"
# ONE registered suite for the hq subsystem, doing three jobs at once: it prints a PASS and a
# SKIP line (skip_lines must count), and it fails its FIRST invocation and passes from the second
# on (deterministic contention shape for the retry lane). The marker lives under $WORK — OUTSIDE
# the fixture repo — because the GH-365 envelope brackets the tracked tree: a marker inside the
# fixture would trip the very tree-drift detection this step shipped, and the run must stay green.
cat > "$FB/test/hq.sh" <<STUB
#!/usr/bin/env bash
echo "  PASS: probe"
echo "  SKIP: driver lock held — routing assertions not evaluated"
if [ -f "$WORK/vt-marker" ]; then exit 0; fi
mkdir -p "$WORK" 2>/dev/null; touch "$WORK/vt-marker"
echo "  FAIL: simulated contention failure (first pass)" >&2
exit 1
STUB
chmod +x "$FB/test/hq.sh"
printf 'utils/hq/hq.sh\n' > "$FB/paths.txt"
git -C "$FB" add -A >/dev/null 2>&1; git -C "$FB" commit -qm base >/dev/null 2>&1

export XYZ_VALIDATE_TELEMETRY="$FB/.tick/telemetry"
out="$(cd "$FB" && WORK="$WORK" bash validate.sh --paths-file "$FB/paths.txt" --parallel 2 2>&1)"; rc=$?
unset XYZ_VALIDATE_TELEMETRY
TEL="$(ls -t "$FB/.tick/telemetry"/*.jsonl 2>/dev/null | head -1)"
[ -n "$TEL" ] && [ -f "$TEL" ] && [ "$rc" -eq 0 ] \
  && pass "B1: fixture run green and retained a JSONL record" \
  || fail "B1: fixture run rc=$rc / telemetry=$(ls "$FB/.tick/telemetry" 2>/dev/null): $(printf '%s' "$out" | tail -4)"

python3 - "$TEL" <<'PY' || fail "B2: run.start/summary or suite-event shape wrong in the e2e record"
import json, sys
recs = [json.loads(l) for l in open(sys.argv[1])]
start = [r for r in recs if r["event"] == "run.start"]
summ  = [r for r in recs if r["event"] == "run.summary"]
assert len(start) == 1 and len(summ) == 1, (len(start), len(summ))
assert start[0]["mode"] == "parallel" and start[0]["width"] == 2
assert start[0]["registered"] > 0
suites = [r for r in recs if r["event"] == "suite"]
names = {r["name"]: r for r in suites}
assert "hq.sh" in names, names.keys()
hq = names["hq.sh"]
assert hq["lane"] in ("pool", "driver-lock", "sequential", "retry")  # last event = the retry-lane verdict
# the POOL attempt itself must have been recorded: pool workers are fresh bash -c processes that
# inherit only exported functions — an unexported emitter silently drops every pooled event
# (observed in the first full pool run at this head). The retry record must not mask it.
pool_evts = [r for r in suites if r["name"] == "hq.sh" and r["lane"] == "pool"]
assert pool_evts, "no pool-lane suite event recorded — the pool workers cannot see the emitter (export -f missing?)"
assert pool_evts[0]["rc"] == 1, pool_evts[0]  # the failing-first pass is what the pool saw
assert hq["rc"] == 0 and hq["skip_lines"] == 1 and hq["out_bytes"] > 0
assert hq["out_sha256"] != "-" and len(hq["out_sha256"]) == 12
assert summ[0]["envelope_rc"] == "0"
PY
pass "B2: run.start carries mode/width/registered; the suite event carries rc/skip_lines/bytes/hash"

# retry lane: the failing-first stub must appear as a retry event classified contended
grep -q '"event":"retry"' "$TEL" && grep -q '"classified":"contended"' "$TEL" \
  && pass "B3: a pool failure that passes alone is retained as a retry event (classified=contended)" \
  || fail "B3: no retry/contended record for the failing-first stub"

# sequential mode: same fixture, sequential runner, sequential-lane events. The marker from the
# parallel run is left IN PLACE so the stub passes immediately — this leg asserts recording, not
# the retry machinery (already witnessed above).
export XYZ_VALIDATE_TELEMETRY="$FB/.tick/telemetry"
out="$(cd "$FB" && WORK="$WORK" bash validate.sh --paths-file "$FB/paths.txt" --sequential 2>&1)"; rc=$?
unset XYZ_VALIDATE_TELEMETRY
TEL2="$(ls -t "$FB/.tick/telemetry"/*.jsonl 2>/dev/null | head -1)"
[ "$TEL2" != "$TEL" ] || fail "B4: sequential run wrote no NEW telemetry file"
grep -q '"mode":"sequential"' "$TEL2" && grep -q '"lane":"sequential"' "$TEL2" \
  && pass "B4: sequential mode records lane=sequential suite events" \
  || fail "B4: sequential record missing mode/lane fields"

# ── C. wiring pins — ONE implementation, both runners, uniform step timing ────────────────────────
grep -q 'test/lib/runner-telemetry.sh' "$REPO/validate.sh" \
  && pass "C1: validate.sh sources the shared telemetry lib" \
  || fail "C1: validate.sh does not source runner-telemetry.sh"
grep -q 'test/lib/runner-telemetry.sh' "$REPO/ci-local.sh" \
  && pass "C2: ci-local.sh sources the shared telemetry lib" \
  || fail "C2: ci-local.sh does not source runner-telemetry.sh"
grep -q 'rt_emit stage stage "$name"' "$REPO/ci-local.sh" \
  && pass "C3: ci-local times every step() through one hook" \
  || fail "C3: ci-local step() lost its uniform stage timing"
grep -Eq 'rt_suite sequential "\$t"' "$REPO/ci-local.sh" \
  && pass "C4: ci-local records a per-suite event in the qualifying loop" \
  || fail "C4: ci-local suite loop lost its telemetry hook"
grep -q 'vp_run_one "\$t" "driver-lock"' "$REPO/validate.sh" && grep -q "vp_run_one \"\$1\" pool" "$REPO/validate.sh" \
  && pass "C5: validate.sh tags pool vs driver-lock lanes on every suite event" \
  || fail "C5: lane tagging missing from vp_run_one call sites"
grep -q 'runner-telemetry.sh' "$REPO/test/gh35-test-tiers.sh" \
  && pass "C6: gh35 fixtures copy the telemetry lib (tier paths source it)" \
  || fail "C6: gh35 mkfixture does not copy runner-telemetry.sh"

# ── D. the explicit denominator — parse the registry, trust no inherited count ───────────────────
_decl="$(sed -n '/^TESTS=(/,/^)/p' "$REPO/validate.sh" | grep -oE '"[^"]+\.sh"' | wc -l | tr -d ' ')"
_list="$(bash "$REPO/validate.sh" --list | wc -l | tr -d ' ')"
[ "$_decl" = "$_list" ] \
  && pass "D1: TESTS parse ($_decl) equals --list output ($_list) — the denominator is live, not inherited" \
  || fail "D1: denominator drift: TESTS parse=$_decl vs --list=$_list"
python3 - "$TEL" "$_decl" <<'PY' || fail "D2: run.start denominator does not match the live registry"
import json, sys
start = [json.loads(l) for l in open(sys.argv[1]) if '"run.start"' in l][0]
assert start["registered"] == int(sys.argv[2]), (start["registered"], sys.argv[2])
PY
pass "D2: fixture run.start registered == live TESTS count ($_decl)"

echo "== gh365-validate-telemetry: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ] || exit 1
exit 0
