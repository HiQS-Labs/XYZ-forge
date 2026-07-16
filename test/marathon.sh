#!/usr/bin/env bash
# marathon.sh test: the multi-phase orchestrator parses MARATHON.yaml, runs phases in depends_on
# order via marathon-drive (STUBBED), HALTS on the first failure (later phases NOT started), and
# emits marathon.complete only when every phase is approved. (Phase 4 / M5)
source "$(dirname "$0")/_setup.sh" marathon
unset MARATHON_LANE_NS
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MSH="$REPO/relay-automation/marathon.sh"
YBIN="$REPO/bin/marathon-yaml"

mkdir -p "$A/briefs" "$A/PROJECT/2-WORKING"
for p in p1 p2 p3 a b; do printf 'brief for %s\n' "$p" > "$A/briefs/$p.md"; done

# Stub marathon-drive: record "id|cap|reviewer|artifact|relay-task|turn-timeout|lane-ns" per phase;
# exit 4 if id == STUB_FAIL_PHASE. (GH-116: relay-task column captures marathon.sh's --relay-task
# override, if any. GH-207: lane-ns captures the marathon-scoped lane key passed from plan name.)
STUB="$WORK/drive.sh"
cat > "$STUB" <<'STUB'
#!/usr/bin/env bash
set -u
pid=""; cap=""; rev=""; art=""; rtask=""; timeout="${RELAY_TURN_TIMEOUT_S:-}"; lane_ns="${MARATHON_LANE_NS:-}"
while (($#)); do case "$1" in
  --phase-id) pid="$2"; shift 2;;
  --round-cap) cap="$2"; shift 2;;
  --reviewer) rev="$2"; shift 2;;
  --artifact) art="$2"; shift 2;;
  --relay-task) rtask="$2"; shift 2;;
  *) shift;;
esac; done
printf '%s|%s|%s|%s|%s|%s|%s\n' "$pid" "$cap" "$rev" "$art" "$rtask" "$timeout" "$lane_ns" >> "$WORK/phases-ran"
[ "$pid" = "${STUB_FAIL_PHASE:-__none__}" ] && exit 4
exit 0
STUB
chmod +x "$STUB"

run_marathon() {  # <plan> <extra-args…>
  local plan="$1"; shift
  RELAY_TURN_TIMEOUT_S= MARATHON_ROOT="$A" MARATHON_DRIVE="$STUB" MARATHON_YAML_BIN="$YBIN" TICK_BIN="$TICK" \
    bash "$MSH" --plan "$plan" "$@"
}

cat > "$A/PROJECT/2-WORKING/m.yaml" <<'YAML'
name: chain
phases:
  - id: p1
    reviewer: codex
    max_review_rounds: 2
    brief: briefs/p1.md
  - id: p2
    reviewer: gemini
    depends_on: p1
    max_review_rounds: 3
    brief: briefs/p2.md
    artifact: src/p2.js
    turn_timeout_s: 1200
  - id: p3
    reviewer: codex
    depends_on: p2
    brief: briefs/p3.md
YAML

# --- (1) full chain: order + round-cap math + marathon.complete ------------
rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
run_marathon "$A/PROJECT/2-WORKING/m.yaml" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "full chain exits 0" || fail "chain exit=$rc"
[ "$(cut -d'|' -f1 "$WORK/phases-ran" | paste -sd, -)" = "p1,p2,p3" ] \
  && pass "phases run in execution order p1,p2,p3" || fail "order: [$(cat "$WORK/phases-ran")]"
grep -q "^p2|7|gemini|src/p2.js||1200|chain--p2$" "$WORK/phases-ran" \
  && pass "p2: round-cap=7, reviewer + artifact passed through, timeout exported, lane namespace set" || fail "p2 args: [$(grep p2 "$WORK/phases-ran")]"
grep -q "^p1|5|codex||||chain--p1$" "$WORK/phases-ran" \
  && pass "p1: round-cap=5, no timeout override by default, lane namespace set" || fail "p1 cap/env: [$(grep p1 "$WORK/phases-ran")]"
cp "$WORK/phases-ran" "$WORK/phases-ran.no-retry-baseline"   # GH-116: reused by test (8) below
ls "$A/.tick/events/" 2>/dev/null | grep -q "marathon.complete" \
  && pass "marathon.complete emitted on full success" || fail "marathon.complete missing"

# --- (2) halt on failure: p2 fails -> p3 NOT started, exit 4, no complete --
rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
STUB_FAIL_PHASE=p2 run_marathon "$A/PROJECT/2-WORKING/m.yaml" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 4 ] && pass "halt propagates the failing phase's exit (4)" || fail "halt exit=$rc (expected 4)"
[ "$(cut -d'|' -f1 "$WORK/phases-ran" | paste -sd, -)" = "p1,p2" ] \
  && pass "chain halts after p2 — p3 NOT started" || fail "ran: [$(cat "$WORK/phases-ran")]"
ls "$A/.tick/events/" 2>/dev/null | grep -q "marathon.complete" \
  && fail "marathon.complete must NOT be emitted on halt" || pass "no marathon.complete on halt"

# --- (3) depends_on reorders authored-out-of-order phases -----------------
cat > "$A/PROJECT/2-WORKING/r.yaml" <<'YAML'
name: reorder
phases:
  - id: b
    reviewer: codex
    depends_on: a
    brief: briefs/b.md
  - id: a
    reviewer: gemini
    brief: briefs/a.md
YAML
rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
run_marathon "$A/PROJECT/2-WORKING/r.yaml" >/dev/null 2>&1
[ "$(cut -d'|' -f1 "$WORK/phases-ran" | paste -sd, -)" = "a,b" ] \
  && pass "orchestrator runs in depends_on order (a before b)" || fail "ran: [$(cat "$WORK/phases-ran")]"

# --- (4) a phase with no brief -> hard error (exit 2) ---------------------
printf 'name: nb\nphases:\n  - id: p1\n    reviewer: codex\n' > "$A/PROJECT/2-WORKING/nobrief.yaml"
rm -f "$WORK/phases-ran"
run_marathon "$A/PROJECT/2-WORKING/nobrief.yaml" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && pass "phase without a brief -> error (exit 2)" || fail "no-brief exit=$rc (expected 2)"

# --- (5) malformed plan -> halt before running ANY phase -----------------
printf 'name: bad\nphases:\n  - id: p1\n    reviewer: claude\n    brief: briefs/p1.md\n' > "$A/PROJECT/2-WORKING/bad.yaml"
rm -f "$WORK/phases-ran"
run_marathon "$A/PROJECT/2-WORKING/bad.yaml" >/dev/null 2>&1; rc=$?
{ [ "$rc" -eq 2 ] && [ ! -f "$WORK/phases-ran" ]; } \
  && pass "malformed plan halts before any phase runs (exit 2)" || fail "bad plan: rc=$rc, ran=[$(cat "$WORK/phases-ran" 2>/dev/null)]"

# --- (6) GH-116: --retry overrides only the named phase's relay task -------
rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
run_marathon "$A/PROJECT/2-WORKING/m.yaml" --retry p2 >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "--retry run still exits 0 (full chain)" || fail "--retry chain exit=$rc"
grep -q "^p2|7|gemini|src/p2.js|MARATHON-P2-TURN-2|1200|chain--p2$" "$WORK/phases-ran" \
  && pass "--retry p2: relay-task overridden to MARATHON-P2-TURN-2 (first unused suffix), lane namespace preserved" \
  || fail "--retry p2 relay-task: [$(grep p2 "$WORK/phases-ran")]"
grep -q "^p1|5|codex||||chain--p1$" "$WORK/phases-ran" \
  && pass "--retry p2: p1's task-name derivation unaffected (no --relay-task)" \
  || fail "--retry p2 p1 unaffected: [$(grep p1 "$WORK/phases-ran")]"
grep -q "^p3|5|codex||||chain--p3$" "$WORK/phases-ran" \
  && pass "--retry p2: p3's task-name derivation unaffected (no --relay-task)" \
  || fail "--retry p2 p3 unaffected: [$(grep p3 "$WORK/phases-ran")]"

# --- (7) GH-116: --retry bumps past an already-used suffix ------------------
rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
TICK_REPO_ROOT="$A" "$TICK" log task.created "MARATHON-P2-TURN-2" --agent test >/dev/null 2>&1
run_marathon "$A/PROJECT/2-WORKING/m.yaml" --retry p2 >/dev/null 2>&1
grep -q "^p2|7|gemini|src/p2.js|MARATHON-P2-TURN-3|1200|chain--p2$" "$WORK/phases-ran" \
  && pass "--retry p2: MARATHON-P2-TURN-2 already used -> bumps to -3 (checked via tick info, not hardcoded), lane namespace preserved" \
  || fail "--retry bump: [$(grep p2 "$WORK/phases-ran")]"

# --- (8) GH-116: a plan run without --retry is byte-for-byte unchanged -----
rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
run_marathon "$A/PROJECT/2-WORKING/m.yaml" >/dev/null 2>&1
diff -q "$WORK/phases-ran.no-retry-baseline" "$WORK/phases-ran" >/dev/null 2>&1 \
  && pass "no --retry: phases-ran byte-for-byte unchanged" \
  || fail "no-retry drift: [$(diff "$WORK/phases-ran.no-retry-baseline" "$WORK/phases-ran")]"

# --- (9) GH-205: exit 7 with artifact + green gate resumes into review -----
MD_BIN="$REPO/relay-automation/marathon-drive.sh"
CODEX_OK="$WORK/codex-ok"; AGY_OK="$WORK/agy-ok"
printf '#!/usr/bin/env bash\nexit 0\n' > "$CODEX_OK"
printf '#!/usr/bin/env bash\nexit 0\n' > "$AGY_OK"
chmod +x "$CODEX_OK" "$AGY_OK"
mkdir -p "$A/briefs" "$A/src"
printf 'gh205 brief\n' > "$A/briefs/gh205.md"
git -C "$A" add briefs/gh205.md >/dev/null 2>&1
git -C "$A" commit -q -m "seed gh205 brief" >/dev/null 2>&1
RD_RESUME="$WORK/relay-drive-resume.sh"
cat > "$RD_RESUME" <<'STUB'
#!/usr/bin/env bash
set -eu
relay=""; task=""
while (($#)); do
  case "$1" in
    --relay-file) relay="$2"; shift 2 ;;
    --relay-task) task="$2"; shift 2 ;;
    *) shift ;;
  esac
done
count=0
[ -f "$WORK/rd-resume-count" ] && count="$(cat "$WORK/rd-resume-count")"
count=$((count + 1))
printf '%s\n' "$count" > "$WORK/rd-resume-count"
if [ "$count" -eq 1 ]; then
  printf 'artifact\n' > "$A/src/gh205.js"
  printf '\n### Round 1 · Builder · codex\nTimed out after producing the artifact.\n' >> "$relay"
  TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent codex --paths "phases/**,src/gh205.js" >/dev/null 2>&1 || true
  TICK_REPO_ROOT="$A" "$TICK" release "$task" --agent codex --to agy >/dev/null 2>&1 || true
  exit 7
fi
sed -i '' 's/^STATUS:[[:space:]]*.*/STATUS: Approved/' "$relay"
printf '\n### Round 1 · Reviewer · agy\n**Verdict:** Approved\n' >> "$relay"
TICK_REPO_ROOT="$A" "$TICK" claim "$task" --agent agy --paths "phases/**" >/dev/null 2>&1 || true
TICK_REPO_ROOT="$A" "$TICK" done "$task" --agent agy >/dev/null 2>&1 || true
exit 0
STUB
chmod +x "$RD_RESUME"
rm -f "$WORK/rd-resume-count"; rm -rf "$A/.tick" "$A/phases"; rm -f "$A/src/gh205.js"
MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD_RESUME" TICK_BIN="$TICK" CODEX_BIN="$CODEX_OK" AGY_BIN="$AGY_OK" \
  bash "$MD_BIN" --phase-id gh205 --builder codex --reviewer agy --phase-brief "$A/briefs/gh205.md" \
  --artifact src/gh205.js --pre-advance-cmd "test -f '$A/src/gh205.js'" >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && pass "GH-205: timeout + artifact + green gate resumes and phase completes" || fail "GH-205 recovery run exit=$rc"
[ "$(cat "$WORK/rd-resume-count" 2>/dev/null)" = "2" ] \
  && pass "GH-205: marathon-drive re-entered relay-drive for the reviewer round after exit 7" \
  || fail "GH-205: expected 2 relay-drive calls, saw [$(cat "$WORK/rd-resume-count" 2>/dev/null)]"
grep -q '^STATUS: Approved' "$A/phases/gh205/RELAY.md" \
  && pass "GH-205: resumed reviewer round approved the relay" || fail "GH-205: relay not approved"

# --- (10) GH-205: exit 7 with no artifact still halts ----------------------
RD_HANG="$WORK/relay-drive-hang.sh"
cat > "$RD_HANG" <<'STUB'
#!/usr/bin/env bash
set -eu
count=0
[ -f "$WORK/rd-hang-count" ] && count="$(cat "$WORK/rd-hang-count")"
count=$((count + 1))
printf '%s\n' "$count" > "$WORK/rd-hang-count"
exit 7
STUB
chmod +x "$RD_HANG"
printf 'gh205 hang brief\n' > "$A/briefs/gh205-hang.md"
git -C "$A" add briefs/gh205-hang.md >/dev/null 2>&1
git -C "$A" commit -q -m "seed gh205 hang brief" >/dev/null 2>&1
rm -f "$WORK/rd-hang-count"; rm -rf "$A/.tick" "$A/phases"; rm -f "$A/src/gh205-hang.js"
MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$RD_HANG" TICK_BIN="$TICK" CODEX_BIN="$CODEX_OK" AGY_BIN="$AGY_OK" \
  bash "$MD_BIN" --phase-id gh205-hang --builder codex --reviewer agy --phase-brief "$A/briefs/gh205-hang.md" \
  --artifact src/gh205-hang.js --pre-advance-cmd "test -f '$A/src/gh205-hang.js'" >/dev/null 2>&1
rc=$?
[ "$rc" -eq 7 ] && pass "GH-205: timeout with no artifact still halts (exit 7)" || fail "GH-205 no-artifact timeout should exit 7, got $rc"
[ "$(cat "$WORK/rd-hang-count" 2>/dev/null)" = "1" ] \
  && pass "GH-205: no-artifact timeout does not re-enter relay-drive" \
  || fail "GH-205: no-artifact timeout should stop after one relay-drive call"
grep -q 'reason: timeout-no-artifact' "$A/phases/gh205-hang/ESCALATION.md" \
  && pass "GH-205: no-artifact timeout escalation reason recorded" \
  || fail "GH-205: missing timeout-no-artifact escalation reason"

# --- (11) GH-206: vendored .xyz/ splits harness-home from repo-root --------
V="$WORK/vendor-consumer"
mkdir -p "$V"
git -C "$V" init -q
git -C "$V" config user.email t@example.com
git -C "$V" config user.name test
printf '.tick/\n.xyz/.tick/\n' > "$V/.gitignore"
printf 'brief for vendored p1\n' > "$V/briefs-p1.tmp"
mkdir -p "$V/briefs" "$V/PROJECT/2-WORKING"
mv "$V/briefs-p1.tmp" "$V/briefs/p1.md"
cat > "$V/PROJECT/2-WORKING/vendored.yaml" <<'YAML'
name: vendored
phases:
  - id: p1
    reviewer: codex
    brief: briefs/p1.md
YAML
mkdir -p "$V/.xyz"
cp -R "$REPO/relay-automation" "$V/.xyz/"
cp -R "$REPO/bin" "$V/.xyz/"
cp -R "$REPO/src" "$V/.xyz/"
cp -R "$REPO/utils" "$V/.xyz/"
cat > "$V/.xyz/relay-automation/marathon-drive.sh" <<STUB
#!/usr/bin/env bash
set -eu
phase_brief=""; phases_dir=""
while ((\$#)); do
  case "\$1" in
    --phase-brief) phase_brief="\$2"; shift 2 ;;
    --phases-dir)  phases_dir="\$2"; shift 2 ;;
    *)             shift ;;
  esac
done
printf '%s|%s|%s|%s\n' "\$phase_brief" "\$phases_dir" "\${MARATHON_ROOT:-}" "\${TICK_BIN:-}" >> "$WORK/vendored-drive-ran"
exit 0
STUB
chmod +x "$V/.xyz/relay-automation/marathon-drive.sh"
rm -f "$WORK/vendored-drive-ran"; rm -rf "$V/.tick"
(
  cd "$V"
  unset MARATHON_HOME MARATHON_ROOT MARATHON_DRIVE MARATHON_YAML_BIN TICK_BIN XYZ_APPEND_BIN
  ./.xyz/relay-automation/marathon.sh --plan PROJECT/2-WORKING/vendored.yaml
) >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && pass "GH-206: vendored marathon.sh runs with zero env overrides" \
  || fail "GH-206: vendored marathon.sh exit=$rc"
IFS='|' read -r vendored_brief vendored_phases vendored_root vendored_tick < "$WORK/vendored-drive-ran"
vendored_tick_home="$(cd "$(dirname "$vendored_tick")/.." && pwd -P)"
[[ "$vendored_brief" == "$vendored_root/briefs/p1.md" \
   && "$vendored_phases" == "$vendored_root/phases" \
   && "$vendored_root" == "$(git -C "$V" rev-parse --show-toplevel)" \
   && "$vendored_tick_home" == "$vendored_root/.xyz" \
   && "$vendored_tick" != "$vendored_root/bin/tick" ]] \
  && pass "GH-206: vendored run resolves repo-local briefs/phases separately from harness-local tick" \
  || fail "GH-206: vendored root split wrong: [$(cat "$WORK/vendored-drive-ran" 2>/dev/null)]"
ls "$V/.tick/events/" 2>/dev/null | grep -q "marathon.complete" \
  && pass "GH-206: vendored run emits marathon.complete in the consumer repo tick log" \
  || fail "GH-206: vendored run missing consumer repo marathon.complete"

# --- (12) GH-212: a plan outside PROJECT/2-WORKING/ is refused by default -------
rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
printf 'name: outside\nphases:\n  - id: p1\n    reviewer: codex\n    brief: briefs/p1.md\n' > "$A/outside.yaml"
OUTSIDE_OUT="$(run_marathon "$A/outside.yaml" 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && pass "GH-212: plan outside PROJECT/2-WORKING/ is refused by default (exit 2)" \
  || fail "GH-212: expected exit 2 for an outside-PROJECT/2-WORKING plan, got $rc: $OUTSIDE_OUT"
printf '%s\n' "$OUTSIDE_OUT" | grep -q "resolves outside PROJECT/2-WORKING" \
  && pass "GH-212: refusal names the plan-location convention" \
  || fail "GH-212: expected a plan-location error message, got: $OUTSIDE_OUT"
[ ! -f "$WORK/phases-ran" ] && pass "GH-212: refused plan runs zero phases" \
  || fail "GH-212: refused plan should not run any phase: [$(cat "$WORK/phases-ran")]"

# --- (13) GH-212: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 overrides the refusal ---
rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
OVERRIDE_OUT="$(MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 run_marathon "$A/outside.yaml" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "GH-212: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 permits a plan outside PROJECT/2-WORKING/" \
  || fail "GH-212: override run exit=$rc: $OVERRIDE_OUT"
[ "$(cut -d'|' -f1 "$WORK/phases-ran" | paste -sd, -)" = "p1" ] \
  && pass "GH-212: override run actually executes the phase" \
  || fail "GH-212: override run: [$(cat "$WORK/phases-ran" 2>/dev/null)]"

# --- (14) GH-212: a plan under the harness's own home is exempt, no override needed --
rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
mkdir -p "$WORK/fake-home"
printf 'name: homeplan\nphases:\n  - id: p1\n    reviewer: codex\n    brief: briefs/p1.md\n' > "$WORK/fake-home/homeplan.yaml"
HOME_OUT="$(MARATHON_HOME="$WORK/fake-home" run_marathon "$WORK/fake-home/homeplan.yaml" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "GH-212: a plan under MARATHON_HOME (harness-owned reference material) is exempt" \
  || fail "GH-212: harness-home-exempt plan exit=$rc: $HOME_OUT"
[ "$(cut -d'|' -f1 "$WORK/phases-ran" | paste -sd, -)" = "p1" ] \
  && pass "GH-212: harness-home-exempt plan actually executes the phase" \
  || fail "GH-212: harness-home plan: [$(cat "$WORK/phases-ran" 2>/dev/null)]"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
