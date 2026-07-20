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
    TICK_REPO_ROOT="$A" TICK_BIN="$TICK" CLAUDE_BIN="$NOOP" AGY_BIN="$NOOP" XYZ_APPEND_BIN="$XYZ_APPEND_BIN" \
    XYZ_JSON_PATH="$xj" STUB_RD_EXIT="$rexit" XYZ_HARNESS_CONTEXT="$ctx" \
    bash "$MARATHON_DRIVE" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
      --reviewer agy --pre-advance-cmd "true" "$@"
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
mkdir -p "$A/briefs" "$A/PROJECT/2-WORKING"; printf 'b1\n' > "$A/briefs/p1.md"; printf 'b2\n' > "$A/briefs/p2.md"
cat > "$A/PROJECT/2-WORKING/gh75plan.yaml" <<'YAML'
name: gh75plan
phases:
  - id: p1
    reviewer: agy
    brief: briefs/p1.md
  - id: p2
    reviewer: agy
    depends_on: p1
    brief: briefs/p2.md
YAML
MARATHON_ROOT="$A" MARATHON_DRIVE="$MARATHON_DRIVE" MARATHON_RELAY_DRIVE="$STUB_RD" \
  MARATHON_AGENT_CMD="$NOOP" MARATHON_YAML_BIN="$YBIN" TICK_BIN="$TICK" TICK_REPO_ROOT="$A" \
  CLAUDE_BIN="$NOOP" AGY_BIN="$NOOP" CODEX_BIN="$NOOP" \
  XYZ_APPEND_BIN="$XYZ_APPEND_BIN" XYZ_JSON_PATH="$XMS" STUB_RD_EXIT=0 \
  bash "$MARATHON_SH" --plan "$A/PROJECT/2-WORKING/gh75plan.yaml" --pre-advance-cmd "true" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "marathon.sh 2-phase run exits 0" || fail "marathon.sh exit=$rc"
[ "$(count "$XMS")" = "1" ] && pass "marathon.sh 2-phase → exactly ONE record (not per-phase)" || fail "marathon.sh count=$(count "$XMS") (expected 1)"
[ "$(field "$XMS" 0 harness)" = "marathon" ] && pass "marathon.sh record harness=marathon" || fail "harness=$(field "$XMS" 0 harness)"
[ "$(field "$XMS" 0 sessionId)" = "gh75plan" ] && pass "marathon.sh sessionId = plan name" || fail "sessionId=$(field "$XMS" 0 sessionId)"
case "$(field "$XMS" 0 description)" in *"2 of 2 phase"*) pass "marathon.sh desc = 'N of M phase(s) approved'";; *) fail "desc=$(field "$XMS" 0 description)";; esac
reset_a

# ── (M6) marathon.sh HALT (phase 1 fails) → exactly ONE harness:marathon RED record ────────
# GH-75 review Blocker: an orchestrated halt used to emit nothing (each phase silenced; the success
# tail skipped). It must record a red whole-run record — not be silently absent.
XMH="$WORK/msh-halt.json"; reset_a
mkdir -p "$A/briefs" "$A/PROJECT/2-WORKING"; printf 'b1\n' > "$A/briefs/p1.md"; printf 'b2\n' > "$A/briefs/p2.md"
cat > "$A/PROJECT/2-WORKING/gh75halt.yaml" <<'YAML'
name: gh75halt
phases:
  - id: p1
    reviewer: agy
    brief: briefs/p1.md
  - id: p2
    reviewer: agy
    depends_on: p1
    brief: briefs/p2.md
YAML
MARATHON_ROOT="$A" MARATHON_DRIVE="$MARATHON_DRIVE" MARATHON_RELAY_DRIVE="$STUB_RD" \
  MARATHON_AGENT_CMD="$NOOP" MARATHON_YAML_BIN="$YBIN" TICK_BIN="$TICK" TICK_REPO_ROOT="$A" \
  CLAUDE_BIN="$NOOP" AGY_BIN="$NOOP" CODEX_BIN="$NOOP" \
  XYZ_APPEND_BIN="$XYZ_APPEND_BIN" XYZ_JSON_PATH="$XMH" STUB_RD_EXIT=4 \
  bash "$MARATHON_SH" --plan "$A/PROJECT/2-WORKING/gh75halt.yaml" --pre-advance-cmd "true" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 4 ] && pass "marathon.sh halt propagates the phase exit (4)" || fail "marathon.sh halt exit=$rc"
[ "$(count "$XMH")" = "1" ] && pass "marathon.sh halt → exactly ONE record (not silently absent)" || fail "marathon.sh halt count=$(count "$XMH") (expected 1)"
[ "$(field "$XMH" 0 health)" = "red" ] && pass "marathon.sh halt health=red" || fail "halt health=$(field "$XMH" 0 health)"
[ "$(field "$XMH" 0 harness)" = "marathon" ] && pass "marathon.sh halt harness=marathon" || fail "halt harness=$(field "$XMH" 0 harness)"
case "$(field "$XMH" 0 description)" in *"halted at phase 1 of 2"*) pass "marathon.sh halt desc names the failing phase";; *) fail "halt desc=$(field "$XMH" 0 description)";; esac
reset_a

# ── (M7) XYZ_SESSION_ID overrides the constant 'p1' sessionId (swarm distinguishability) ────
XSID="$WORK/md-sid.json"; reset_a
run_md_sid() {  # <xyz-json> <ctx> <session-id>
  MARATHON_ROOT="$A" MARATHON_RELAY_DRIVE="$STUB_RD" MARATHON_AGENT_CMD="$NOOP" \
    TICK_REPO_ROOT="$A" TICK_BIN="$TICK" CLAUDE_BIN="$NOOP" AGY_BIN="$NOOP" XYZ_APPEND_BIN="$XYZ_APPEND_BIN" \
    XYZ_JSON_PATH="$1" STUB_RD_EXIT=0 XYZ_HARNESS_CONTEXT="$2" XYZ_SESSION_ID="$3" \
    bash "$MARATHON_DRIVE" --phases-dir "$A/phases" --phase-brief "$BRIEF" \
      --reviewer agy --pre-advance-cmd "true"
}
run_md_sid "$XSID" swarm gh-99-run-alpha >/dev/null 2>&1
[ "$(field "$XSID" 0 sessionId)" = "gh-99-run-alpha" ] && pass "XYZ_SESSION_ID overrides sessionId (not the constant p1)" || fail "sessionId=$(field "$XSID" 0 sessionId)"
[ "$(field "$XSID" 0 harness)" = "swarm" ] && pass "XYZ_SESSION_ID run still tags harness=swarm" || fail "harness=$(field "$XSID" 0 harness)"
# without the override, sessionId falls back to PHASE_ID (p1)
reset_a
run_md "$WORK/md-nosid.json" "" 0 >/dev/null 2>&1
[ "$(field "$WORK/md-nosid.json" 0 sessionId)" = "p1" ] && pass "sessionId falls back to PHASE_ID when unset" || fail "fallback sessionId=$(field "$WORK/md-nosid.json" 0 sessionId)"
reset_a

# ── Relay --review-once: every outcome emits (GH-75 review Should) ──────────
seed_ro() {  # <task> <file> <status>
  printf 'STATUS: %s\n# review-once thread\n' "$3" > "$A/$2"
  tick_a log task.created "$1" --agent builder --paths "$2" >/dev/null 2>&1
  tick_a claim   "$1" --agent builder --paths "$2" >/dev/null 2>&1
  tick_a release "$1" --agent builder --to reviewer >/dev/null 2>&1
}

# (RO1) reviewer approves → exit 0, relay/green
APPROVE="$WORK/ro-approve.sh"
cat > "$APPROVE" <<EOF
#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="$A"
"$TICK" take "\$RELAY_TASK" --agent "\$RELAY_AGENT" >/dev/null 2>&1 || true
tmp="\$(mktemp)"; sed 's/^STATUS:.*/STATUS: Approved/' "\$RELAY_FILE" > "\$tmp" && mv "\$tmp" "\$RELAY_FILE"
"$TICK" done "\$RELAY_TASK" --agent "\$RELAY_AGENT" >/dev/null 2>&1 || true
exit 0
EOF
chmod +x "$APPROVE"
XRO1="$WORK/ro-green.json"; seed_ro RELAY-RO1 ro1.md "In progress"
XYZ_JSON_PATH="$XRO1" bash "$RELAY_DRIVE" --relay-file "$A/ro1.md" --relay-task RELAY-RO1 --agent-cmd "$APPROVE" --review-once >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "review-once approval exits 0" || fail "review-once approve exit=$rc"
[ "$(count "$XRO1")" = "1" ] && [ "$(field "$XRO1" 0 health)" = "green" ] && pass "review-once approval → relay/green record" || fail "ro1 count=$(count "$XRO1") health=$(field "$XRO1" 0 health)"

# (RO2) reviewer hands back (changes requested) → exit 5, relay/orange.
# GH-245: a genuine changes-requested handback appends its findings to the relay file — that content
# evidence is what marks a real review (a bare token move with no findings is Run A, now a stall).
HANDBACK="$WORK/ro-handback.sh"
cat > "$HANDBACK" <<EOF
#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="$A"
"$TICK" take "\$RELAY_TASK" --agent "\$RELAY_AGENT" >/dev/null 2>&1 || true
printf '\n### Reviewer · Round 1\nVERDICT: FAIL\nBasis: changes requested.\n' >> "\$RELAY_FILE"
"$TICK" release "\$RELAY_TASK" --agent "\$RELAY_AGENT" --to builder >/dev/null 2>&1 || true
exit 0
EOF
chmod +x "$HANDBACK"
XRO2="$WORK/ro-orange.json"; seed_ro RELAY-RO2 ro2.md "In progress"
XYZ_JSON_PATH="$XRO2" bash "$RELAY_DRIVE" --relay-file "$A/ro2.md" --relay-task RELAY-RO2 --agent-cmd "$HANDBACK" --review-once >/dev/null 2>&1; rc=$?
[ "$rc" -eq 5 ] && pass "review-once handback exits 5" || fail "review-once handback exit=$rc"
[ "$(count "$XRO2")" = "1" ] && [ "$(field "$XRO2" 0 health)" = "orange" ] && pass "review-once handback → relay/orange record" || fail "ro2 count=$(count "$XRO2") health=$(field "$XRO2" 0 health)"

# (RO3) reviewer does nothing → exit 3, relay/red
XRO3="$WORK/ro-red.json"; seed_ro RELAY-RO3 ro3.md "In progress"
XYZ_JSON_PATH="$XRO3" bash "$RELAY_DRIVE" --relay-file "$A/ro3.md" --relay-task RELAY-RO3 --agent-cmd "$NOOP" --review-once >/dev/null 2>&1; rc=$?
[ "$rc" -eq 3 ] && pass "review-once stall exits 3" || fail "review-once stall exit=$rc"
[ "$(count "$XRO3")" = "1" ] && [ "$(field "$XRO3" 0 health)" = "red" ] && pass "review-once stall → relay/red record" || fail "ro3 count=$(count "$XRO3") health=$(field "$XRO3" 0 health)"

# ── (R5) multi-round no-progress → relay/red (same bug class as the review-once stall) ─────
XNP="$WORK/relay-noprogress.json"
printf 'STATUS: In progress\n# stalled thread\n' > "$A/rn.md"
tick_a log task.created RELAY-NP --agent builder --paths rn.md >/dev/null 2>&1
tick_a claim RELAY-NP --agent builder --paths rn.md >/dev/null 2>&1
tick_a release RELAY-NP --agent builder --to reviewer >/dev/null 2>&1
XYZ_JSON_PATH="$XNP" bash "$RELAY_DRIVE" --relay-file "$A/rn.md" --relay-task RELAY-NP --agent-cmd "$NOOP" --round-cap 3 >/dev/null 2>&1; rc=$?
[ "$rc" -eq 3 ] && pass "multi-round no-progress exits 3" || fail "no-progress exit=$rc"
[ "$(count "$XNP")" = "1" ] && [ "$(field "$XNP" 0 health)" = "red" ] && pass "multi-round no-progress → relay/red record" || fail "np count=$(count "$XNP") health=$(field "$XNP" 0 health)"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
