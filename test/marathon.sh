#!/usr/bin/env bash
# marathon.sh test: the multi-phase orchestrator parses MARATHON.yaml, runs phases in depends_on
# order via marathon-drive (STUBBED), HALTS on the first failure (later phases NOT started), and
# emits marathon.complete only when every phase is approved. (Phase 4 / M5)
source "$(dirname "$0")/_setup.sh" marathon
REPO="$(cd "$(dirname "$0")/.." && pwd)"
MSH="$REPO/relay-automation/marathon.sh"
YBIN="$REPO/bin/marathon-yaml"

mkdir -p "$A/briefs"
for p in p1 p2 p3 a b; do printf 'brief for %s\n' "$p" > "$A/briefs/$p.md"; done

# Stub marathon-drive: record "id|cap|reviewer|artifact|relay-task" per phase; exit 4 if id ==
# STUB_FAIL_PHASE. (GH-116: relay-task column captures marathon.sh's --relay-task override, if any.)
STUB="$WORK/drive.sh"
cat > "$STUB" <<'STUB'
#!/usr/bin/env bash
set -u
pid=""; cap=""; rev=""; art=""; rtask=""
while (($#)); do case "$1" in
  --phase-id) pid="$2"; shift 2;;
  --round-cap) cap="$2"; shift 2;;
  --reviewer) rev="$2"; shift 2;;
  --artifact) art="$2"; shift 2;;
  --relay-task) rtask="$2"; shift 2;;
  *) shift;;
esac; done
printf '%s|%s|%s|%s|%s\n' "$pid" "$cap" "$rev" "$art" "$rtask" >> "$WORK/phases-ran"
[ "$pid" = "${STUB_FAIL_PHASE:-__none__}" ] && exit 4
exit 0
STUB
chmod +x "$STUB"

run_marathon() {  # <plan> <extra-args…>
  local plan="$1"; shift
  MARATHON_ROOT="$A" MARATHON_DRIVE="$STUB" MARATHON_YAML_BIN="$YBIN" TICK_BIN="$TICK" \
    bash "$MSH" --plan "$plan" "$@"
}

cat > "$A/m.yaml" <<'YAML'
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
  - id: p3
    reviewer: codex
    depends_on: p2
    brief: briefs/p3.md
YAML

# --- (1) full chain: order + round-cap math + marathon.complete ------------
rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
run_marathon "$A/m.yaml" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "full chain exits 0" || fail "chain exit=$rc"
[ "$(cut -d'|' -f1 "$WORK/phases-ran" | paste -sd, -)" = "p1,p2,p3" ] \
  && pass "phases run in execution order p1,p2,p3" || fail "order: [$(cat "$WORK/phases-ran")]"
grep -q "^p2|7|gemini|src/p2.js|$" "$WORK/phases-ran" \
  && pass "p2: round-cap=7 (2*3+1), reviewer + artifact passed through" || fail "p2 args: [$(grep p2 "$WORK/phases-ran")]"
grep -q "^p1|5|codex||$" "$WORK/phases-ran" \
  && pass "p1: round-cap=5 (default max_review_rounds=2)" || fail "p1 cap: [$(grep p1 "$WORK/phases-ran")]"
cp "$WORK/phases-ran" "$WORK/phases-ran.no-retry-baseline"   # GH-116: reused by test (8) below
ls "$A/.tick/events/" 2>/dev/null | grep -q "marathon.complete" \
  && pass "marathon.complete emitted on full success" || fail "marathon.complete missing"

# --- (2) halt on failure: p2 fails -> p3 NOT started, exit 4, no complete --
rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
STUB_FAIL_PHASE=p2 run_marathon "$A/m.yaml" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 4 ] && pass "halt propagates the failing phase's exit (4)" || fail "halt exit=$rc (expected 4)"
[ "$(cut -d'|' -f1 "$WORK/phases-ran" | paste -sd, -)" = "p1,p2" ] \
  && pass "chain halts after p2 — p3 NOT started" || fail "ran: [$(cat "$WORK/phases-ran")]"
ls "$A/.tick/events/" 2>/dev/null | grep -q "marathon.complete" \
  && fail "marathon.complete must NOT be emitted on halt" || pass "no marathon.complete on halt"

# --- (3) depends_on reorders authored-out-of-order phases -----------------
cat > "$A/r.yaml" <<'YAML'
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
run_marathon "$A/r.yaml" >/dev/null 2>&1
[ "$(cut -d'|' -f1 "$WORK/phases-ran" | paste -sd, -)" = "a,b" ] \
  && pass "orchestrator runs in depends_on order (a before b)" || fail "ran: [$(cat "$WORK/phases-ran")]"

# --- (4) a phase with no brief -> hard error (exit 2) ---------------------
printf 'name: nb\nphases:\n  - id: p1\n    reviewer: codex\n' > "$A/nobrief.yaml"
rm -f "$WORK/phases-ran"
run_marathon "$A/nobrief.yaml" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && pass "phase without a brief -> error (exit 2)" || fail "no-brief exit=$rc (expected 2)"

# --- (5) malformed plan -> halt before running ANY phase -----------------
printf 'name: bad\nphases:\n  - id: p1\n    reviewer: claude\n    brief: briefs/p1.md\n' > "$A/bad.yaml"
rm -f "$WORK/phases-ran"
run_marathon "$A/bad.yaml" >/dev/null 2>&1; rc=$?
{ [ "$rc" -eq 2 ] && [ ! -f "$WORK/phases-ran" ]; } \
  && pass "malformed plan halts before any phase runs (exit 2)" || fail "bad plan: rc=$rc, ran=[$(cat "$WORK/phases-ran" 2>/dev/null)]"

# --- (6) GH-116: --retry overrides only the named phase's relay task -------
rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
run_marathon "$A/m.yaml" --retry p2 >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "--retry run still exits 0 (full chain)" || fail "--retry chain exit=$rc"
grep -q "^p2|7|gemini|src/p2.js|MARATHON-P2-TURN-2$" "$WORK/phases-ran" \
  && pass "--retry p2: relay-task overridden to MARATHON-P2-TURN-2 (first unused suffix)" \
  || fail "--retry p2 relay-task: [$(grep p2 "$WORK/phases-ran")]"
grep -q "^p1|5|codex||$" "$WORK/phases-ran" \
  && pass "--retry p2: p1's task-name derivation unaffected (no --relay-task)" \
  || fail "--retry p2 p1 unaffected: [$(grep p1 "$WORK/phases-ran")]"
grep -q "^p3|5|codex||$" "$WORK/phases-ran" \
  && pass "--retry p2: p3's task-name derivation unaffected (no --relay-task)" \
  || fail "--retry p2 p3 unaffected: [$(grep p3 "$WORK/phases-ran")]"

# --- (7) GH-116: --retry bumps past an already-used suffix ------------------
rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
TICK_REPO_ROOT="$A" "$TICK" log task.created "MARATHON-P2-TURN-2" --agent test >/dev/null 2>&1
run_marathon "$A/m.yaml" --retry p2 >/dev/null 2>&1
grep -q "^p2|7|gemini|src/p2.js|MARATHON-P2-TURN-3$" "$WORK/phases-ran" \
  && pass "--retry p2: MARATHON-P2-TURN-2 already used -> bumps to -3 (checked via tick info, not hardcoded)" \
  || fail "--retry bump: [$(grep p2 "$WORK/phases-ran")]"

# --- (8) GH-116: a plan run without --retry is byte-for-byte unchanged -----
rm -f "$WORK/phases-ran"; rm -rf "$A/.tick"
run_marathon "$A/m.yaml" >/dev/null 2>&1
diff -q "$WORK/phases-ran.no-retry-baseline" "$WORK/phases-ran" >/dev/null 2>&1 \
  && pass "no --retry: phases-ran byte-for-byte unchanged" \
  || fail "no-retry drift: [$(diff "$WORK/phases-ran.no-retry-baseline" "$WORK/phases-ran")]"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
