#!/usr/bin/env bash
# test/xyz-harness-hooks.sh — GH-75: the completion hooks wired into the three harnesses.
#
# Drives the REAL relay-drive.sh, marathon-drive.sh, and marathon.sh to their terminal points and
# asserts XYZ.json gets exactly ONE well-formed record with the right harness tag + health, and that
# nesting never double-emits. XYZ_JSON_PATH + XYZ_APPEND_BIN point the writer at a throwaway file.
#
# QA gates covered:
#   - standalone /relay Approved/Closed → 1 relay/green record
#   - standalone /relay Escalated → 1 relay/orange; round-cap → 1 relay/red (not silently absent)
#   - a relay running nested (XYZ_HARNESS_CONTEXT=marathon-phase) emits NOTHING
#   - bare marathon-drive → harness:marathon; swarm-context marathon-drive → harness:swarm
#   - marathon-drive under marathon.sh (marathon-phase) stays silent
#   - a marathon.sh N-phase run → exactly 1 harness:marathon record (not N, not N+1)
source "$(dirname "$0")/_setup.sh" xyz-harness-hooks

REPO="$(cd "$(dirname "$0")/.." && pwd)"
export TICK_BIN="$TICK"
export XYZ_APPEND_BIN="$REPO/utils/telemetry/append-xyz-completion.sh"
RELAY_DRIVE="$REPO/relay-automation/relay-drive.sh"
MARATHON_DRIVE="$REPO/relay-automation/marathon-drive.sh"
MARATHON_SH="$REPO/relay-automation/marathon.sh"
YBIN="$REPO/bin/marathon-yaml"

tick_a init >/dev/null

count()   { python3 -c "import json,sys; print(len(json.load(open(sys.argv[1]))))" "$1" 2>/dev/null || echo 0; }
field()   { python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d[int(sys.argv[2])][sys.argv[3]])" "$1" "$2" "$3" 2>/dev/null; }

# ── Relay: seed a token/file and drive relay-drive to a terminal state ───────
# Noop turn-taker (does nothing) — used where the terminal state is pre-arranged before the loop.
NOOP="$WORK/noop.sh"; printf '#!/usr/bin/env bash\nexit 0\n' > "$NOOP"; chmod +x "$NOOP"

# ── (R1) Approved + token done → relay/green, exactly one record ─────────────
XJ="$WORK/relay-green.json"
printf 'STATUS: Approved\n# GH-XX my relay thread\n' > "$A/rg.md"
tick_a log task.created RELAY-G --agent a1 --paths rg.md >/dev/null 2>&1
tick_a claim RELAY-G --agent a1 --paths rg.md >/dev/null 2>&1
tick_a done  RELAY-G --agent a1 >/dev/null 2>&1
XYZ_JSON_PATH="$XJ" bash "$RELAY_DRIVE" --relay-file "$A/rg.md" --relay-task RELAY-G --agent-cmd "$NOOP" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "relay Approved exits 0" || fail "relay green exit=$rc"
[ "$(count "$XJ")" = "1" ] && pass "relay green writes exactly one record" || fail "relay green count=$(count "$XJ")"
[ "$(field "$XJ" 0 harness)" = "relay" ] && pass "relay green harness=relay" || fail "harness=$(field "$XJ" 0 harness)"
[ "$(field "$XJ" 0 health)" = "green" ] && pass "relay green health=green" || fail "health=$(field "$XJ" 0 health)"
[ "$(field "$XJ" 0 title)" = "GH-XX my relay thread" ] && pass "relay title from '# ' heading" || fail "title=$(field "$XJ" 0 title)"
[ "$(field "$XJ" 0 sessionId)" = "rg" ] && pass "relay sessionId = thread slug" || fail "sessionId=$(field "$XJ" 0 sessionId)"

# re-run once more → prepends a second record (append, not clobber)
XYZ_JSON_PATH="$XJ" bash "$RELAY_DRIVE" --relay-file "$A/rg.md" --relay-task RELAY-G --agent-cmd "$NOOP" >/dev/null 2>&1
[ "$(count "$XJ")" = "2" ] && pass "re-run prepends (2 records), no clobber" || fail "re-run count=$(count "$XJ")"

# ── (R2) nested (XYZ_HARNESS_CONTEXT=marathon-phase) emits NOTHING ──────────
XJN="$WORK/relay-nested.json"
XYZ_JSON_PATH="$XJN" XYZ_HARNESS_CONTEXT=marathon-phase bash "$RELAY_DRIVE" \
  --relay-file "$A/rg.md" --relay-task RELAY-G --agent-cmd "$NOOP" >/dev/null 2>&1
[ ! -e "$XJN" ] && pass "nested relay (marathon-phase) writes NO record" || fail "nested relay emitted: $(cat "$XJN" 2>/dev/null)"

# ── (R3) Escalated at loop top → relay/orange ──────────────────────────────
XJO="$WORK/relay-orange.json"
printf 'STATUS: Escalated\n# escalated thread\n' > "$A/ro.md"
tick_a log task.created RELAY-O --agent a1 --paths ro.md >/dev/null 2>&1
tick_a claim RELAY-O --agent a1 --paths ro.md >/dev/null 2>&1
tick_a release RELAY-O --agent a1 --to reviewer >/dev/null 2>&1
XYZ_JSON_PATH="$XJO" bash "$RELAY_DRIVE" --relay-file "$A/ro.md" --relay-task RELAY-O --agent-cmd "$NOOP" --round-cap 2 >/dev/null 2>&1; rc=$?
[ "$rc" -eq 4 ] && pass "relay Escalated exits 4" || fail "relay orange exit=$rc"
[ "$(count "$XJO")" = "1" ] && pass "relay Escalated writes one record (not silently absent)" || fail "orange count=$(count "$XJO")"
[ "$(field "$XJO" 0 health)" = "orange" ] && pass "relay Escalated health=orange" || fail "health=$(field "$XJO" 0 health)"

# ── (R4) round-cap fallback → relay/red ────────────────────────────────────
# A turn-taker that keeps handing the token back and forth (progress each turn, never terminal) so the
# loop reaches the cap fallback rather than the no-progress guard.
XJR="$WORK/relay-red.json"
PINGPONG="$WORK/pingpong.sh"
cat > "$PINGPONG" <<EOF
#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="$A"
me="\$RELAY_AGENT"; other=a2; [ "\$me" = a2 ] && other=a1
"$TICK" take "\$RELAY_TASK" --agent "\$me" >/dev/null 2>&1 || true
"$TICK" release "\$RELAY_TASK" --agent "\$me" --to "\$other" >/dev/null 2>&1 || true
exit 0
EOF
chmod +x "$PINGPONG"
printf 'STATUS: In progress\n# capped thread\n' > "$A/rr.md"
tick_a log task.created RELAY-R --agent a1 --paths rr.md >/dev/null 2>&1
tick_a claim RELAY-R --agent a1 --paths rr.md >/dev/null 2>&1
tick_a release RELAY-R --agent a1 --to a2 >/dev/null 2>&1
XYZ_JSON_PATH="$XJR" bash "$RELAY_DRIVE" --relay-file "$A/rr.md" --relay-task RELAY-R --agent-cmd "$PINGPONG" --round-cap 2 >/dev/null 2>&1; rc=$?
[ "$rc" -eq 4 ] && pass "relay round-cap exits 4" || fail "relay red exit=$rc"
[ "$(count "$XJR")" = "1" ] && pass "relay round-cap writes one record (not silently absent)" || fail "red count=$(count "$XJR")"
[ "$(field "$XJR" 0 health)" = "red" ] && pass "relay round-cap health=red" || fail "health=$(field "$XJR" 0 health)"

# ── Marathon-drive: real driver + STUB relay-drive + stub agent ─────────────
printf '.tick/\n' > "$A/.gitignore"
git -C "$A" add .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m "gh75 test init" >/dev/null 2>&1
INIT_HEAD="$(git -C "$A" rev-parse HEAD)"

STUB_RD="$WORK/stub-relay-drive.sh"
cat > "$STUB_RD" <<'STUB'
#!/usr/bin/env bash
set -u
exit "${STUB_RD_EXIT:-0}"
STUB
chmod +x "$STUB_RD"

BRIEF="$WORK/gh75-brief.md"; printf '## Do the thing\nbody\n' > "$BRIEF"

reset_a() { rm -rf "$A/.tick" "$A/phases" "$A/relay-system"; git -C "$A" reset -q --hard "$INIT_HEAD" >/dev/null 2>&1 || true; }

run_md() {  # <xyz-json> <ctx-or-empty> <relay-exit> <extra-args…>
  # ctx="" is passed as an empty XYZ_HARNESS_CONTEXT, which the hook treats identically to unset
  # (→ harness:marathon) — the bare-run case.
  local xj="$1" ctx="$2" rexit="$3"; shift 3
  MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" MARATHON_AGENT_CMD="$NOOP" \
    TICK_REPO_ROOT="$A" TICK_BIN="$TICK" XYZ_APPEND_BIN="$XYZ_APPEND_BIN" \
    XYZ_JSON_PATH="$xj" STUB_RD_EXIT="$rexit" XYZ_HARNESS_CONTEXT="$ctx" \
    bash "$MARATHON_DRIVE" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
      --reviewer gemini --pre-advance-cmd "true" "$@"
}

# ── (M1) bare marathon-drive success → harness:marathon, green ─────────────
XM="$WORK/md-bare.json"; reset_a
run_md "$XM" "" 0 >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "bare marathon-drive success exits 0" || fail "bare md exit=$rc"
[ "$(count "$XM")" = "1" ] && pass "bare marathon-drive writes one record" || fail "bare md count=$(count "$XM")"
[ "$(field "$XM" 0 harness)" = "marathon" ] && pass "bare marathon-drive harness=marathon" || fail "harness=$(field "$XM" 0 harness)"
[ "$(field "$XM" 0 health)" = "green" ] && pass "bare marathon-drive health=green" || fail "health=$(field "$XM" 0 health)"
[ "$(field "$XM" 0 title)" = "gh75-brief" ] && pass "marathon title = phase-brief basename" || fail "title=$(field "$XM" 0 title)"

# ── (M2) swarm-context marathon-drive → harness:swarm ──────────────────────
XS="$WORK/md-swarm.json"; reset_a
run_md "$XS" swarm 0 >/dev/null 2>&1
[ "$(count "$XS")" = "1" ] && pass "swarm-context marathon-drive writes one record" || fail "swarm md count=$(count "$XS")"
[ "$(field "$XS" 0 harness)" = "swarm" ] && pass "swarm-context marathon-drive harness=swarm (not marathon)" || fail "harness=$(field "$XS" 0 harness)"

# ── (M3) marathon-phase context → SILENT (marathon.sh owns the record) ─────
XP="$WORK/md-phase.json"; reset_a
run_md "$XP" marathon-phase 0 >/dev/null 2>&1
[ ! -e "$XP" ] && pass "marathon-phase marathon-drive writes NO record" || fail "marathon-phase emitted: $(cat "$XP" 2>/dev/null)"

# ── (M4) bare marathon-drive halt (relay exit 4) → marathon/red ────────────
XH="$WORK/md-halt.json"; reset_a
run_md "$XH" "" 4 >/dev/null 2>&1; rc=$?
[ "$rc" -eq 4 ] && pass "bare marathon-drive halt exits 4" || fail "halt exit=$rc"
[ "$(count "$XH")" = "1" ] && pass "halt writes one record (not silently absent)" || fail "halt count=$(count "$XH")"
[ "$(field "$XH" 0 health)" = "red" ] && pass "halt health=red" || fail "health=$(field "$XH" 0 health)"
case "$(field "$XH" 0 description)" in *"halted at phase"*) pass "halt description says 'halted at phase'";; *) fail "desc=$(field "$XH" 0 description)";; esac

# ── (M5) marathon.sh N-phase → exactly ONE harness:marathon record ─────────
XMS="$WORK/msh.json"; reset_a
mkdir -p "$A/briefs"; printf 'b1\n' > "$A/briefs/p1.md"; printf 'b2\n' > "$A/briefs/p2.md"
cat > "$A/gh75plan.yaml" <<'YAML'
name: gh75plan
phases:
  - id: p1
    reviewer: codex
    brief: briefs/p1.md
  - id: p2
    reviewer: gemini
    depends_on: p1
    brief: briefs/p2.md
YAML
MARATHON_ROOT="$A" MARATHON_DRIVE="$MARATHON_DRIVE" MARATHON_RELAY_DRIVE="$STUB_RD" \
  MARATHON_AGENT_CMD="$NOOP" MARATHON_YAML_BIN="$YBIN" TICK_BIN="$TICK" TICK_REPO_ROOT="$A" \
  XYZ_APPEND_BIN="$XYZ_APPEND_BIN" XYZ_JSON_PATH="$XMS" STUB_RD_EXIT=0 \
  bash "$MARATHON_SH" --plan "$A/gh75plan.yaml" --pre-advance-cmd "true" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "marathon.sh 2-phase run exits 0" || fail "marathon.sh exit=$rc"
[ "$(count "$XMS")" = "1" ] && pass "marathon.sh 2-phase → exactly ONE record (not per-phase)" || fail "marathon.sh count=$(count "$XMS") (expected 1)"
[ "$(field "$XMS" 0 harness)" = "marathon" ] && pass "marathon.sh record harness=marathon" || fail "harness=$(field "$XMS" 0 harness)"
[ "$(field "$XMS" 0 sessionId)" = "gh75plan" ] && pass "marathon.sh sessionId = plan name" || fail "sessionId=$(field "$XMS" 0 sessionId)"
case "$(field "$XMS" 0 description)" in *"2 of 2 phase"*) pass "marathon.sh desc = 'N of M phase(s) approved'";; *) fail "desc=$(field "$XMS" 0 description)";; esac
reset_a

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
