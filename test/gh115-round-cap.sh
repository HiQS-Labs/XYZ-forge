#!/usr/bin/env bash
source "$(dirname "$0")/_setup.sh" gh115-round-cap

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export TICK_BIN="$TICK"

printf 'STATUS: Open\nNEXT: test (Builder)\n# relay body\n' >"$A/relay.md"
printf '.tick/\nbin/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1
export RELAY_TARGET_ROOT="$A"

STUB="$WORK/agent"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
"$TICK_BIN" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "relay.md" >/dev/null 2>&1

count=1
[ -f "$RELAY_TARGET_ROOT/.stub_count" ] && count=$(cat "$RELAY_TARGET_ROOT/.stub_count")
echo $((count+1)) > "$RELAY_TARGET_ROOT/.stub_count"

if [ "$STUB_PROGRESS" = "yes" ]; then
  echo "- [x] task $count" >> "$RELAY_FILE"
fi

if [ "$STUB_APPROVE_AT" = "$count" ]; then
  sed -i.bak -e 's/^STATUS: .*/STATUS: Approved/' "$RELAY_FILE"
  "$TICK_BIN" done "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
else
  if [ "$RELAY_AGENT" = "test" ]; then next="other"; else next="test"; fi
  "$TICK_BIN" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to "$next" >/dev/null 2>&1
fi
STUB_EOF
chmod +x "$STUB"

export TICK_REPO_ROOT="$A"
tick_a init >/dev/null

reset_relay() {
    git -C "$A" reset --hard HEAD >/dev/null 2>&1
    echo 1 > "$A/.stub_count"
}

# Test 1: Stalled run (no progress) -> exits 4, reason cap-stalled
reset_relay
tick_a log task.created TASK --agent dispatcher >/dev/null
tick_a claim TASK --agent dispatcher --paths relay.md >/dev/null
tick_a release TASK --agent dispatcher --to test >/dev/null

export STUB_PROGRESS="no"
export STUB_APPROVE_AT="99"
out="$(python3 "$ROOT/utils/py/relay_drive.py" --relay-file "$A/relay.md" --agent-cmd "$STUB" --relay-task TASK --round-cap 2 2>&1)"
rc=$?

if [ "$rc" -eq 4 ] && grep -q "cap-stalled" <<<"$out"; then
    pass "Stalled run exits 4 and reports cap-stalled"
else
    fail "Stalled run should exit 4 with cap-stalled. rc=$rc out=$out"
fi

# Test 2: Progressing run grants extension, eventually approves -> exits 0, records extension
reset_relay
tick_a log task.created TASK2 --agent dispatcher >/dev/null
tick_a claim TASK2 --agent dispatcher --paths relay.md >/dev/null
tick_a release TASK2 --agent dispatcher --to test >/dev/null

export STUB_PROGRESS="yes"
export STUB_APPROVE_AT="3" # cap is 2, extension to 3 allows approval on 3rd attempt
out="$(python3 "$ROOT/utils/py/relay_drive.py" --relay-file "$A/relay.md" --agent-cmd "$STUB" --relay-task TASK2 --round-cap 2 2>&1)"
rc=$?

if [ "$rc" -eq 0 ] && grep -q "bounded extension granted" <<<"$out"; then
    if grep -q "Extension · System" "$A/relay.md"; then
        pass "Progressing run grants extension, approves, and records it"
    else
        fail "Progressing run approved but missed durable extension record in relay.md"
    fi
else
    fail "Progressing run should approve after extension. rc=$rc out=$out"
fi

# Test 3: Progressing run hits hard ceiling -> exits 4, reason cap-progressing-extended
reset_relay
tick_a log task.created TASK3 --agent dispatcher >/dev/null
tick_a claim TASK3 --agent dispatcher --paths relay.md >/dev/null
tick_a release TASK3 --agent dispatcher --to test >/dev/null

export STUB_PROGRESS="yes"
export STUB_APPROVE_AT="99" # never approves
out="$(python3 "$ROOT/utils/py/relay_drive.py" --relay-file "$A/relay.md" --agent-cmd "$STUB" --relay-task TASK3 --round-cap 2 2>&1)"
rc=$?

if [ "$rc" -eq 4 ] && grep -q "bounded extension granted" <<<"$out" && grep -q "cap-progressing-extended" <<<"$out"; then
    pass "Progressing run hits hard ceiling and escalates"
else
    fail "Progressing run at ceiling should escalate. rc=$rc out=$out"
fi

# Test 4: Check CLI precedence for --round-cap in marathon_drive.py
cat >"$A/brief.md" <<'BRIEF_EOF'
round-cap: 2
BRIEF_EOF

export XYZ_HARNESS_CONTEXT=marathon
export PATH="$A:$PATH"
export TICK_BIN="$TICK"

# a) brief-only -> cap 2
out="$(python3 "$ROOT/utils/py/marathon_drive.py" --phase-brief "$A/brief.md" --reviewer codex --builder agy --dry-run 2>&1)"
if grep -q "round-cap=2" <<<"$out"; then
    pass "marathon-drive respects round-cap: in brief when no CLI arg given"
else
    fail "marathon-drive ignored brief round-cap: out=$out"
fi

# b) --round-cap=7
out="$(python3 "$ROOT/utils/py/marathon_drive.py" --phase-brief "$A/brief.md" --reviewer codex --builder agy --round-cap=7 --dry-run 2>&1)"
if grep -q "round-cap=7" <<<"$out"; then
    pass "marathon-drive --round-cap=7 overrides brief"
else
    fail "marathon-drive ignored --round-cap=7: out=$out"
fi

# c) --round-cap 9
out="$(python3 "$ROOT/utils/py/marathon_drive.py" --phase-brief "$A/brief.md" --reviewer codex --builder agy --round-cap 9 --dry-run 2>&1)"
if grep -q "round-cap=9" <<<"$out"; then
    pass "marathon-drive --round-cap 9 overrides brief"
else
    fail "marathon-drive ignored --round-cap 9: out=$out"
fi

# Test 5: Integration test for Marathon durable escalation record + stale reason check
reset_relay
mkdir -p "$ROOT/.relay-scratch"
echo "stale-reason" > "$ROOT/.relay-scratch/escalation-reason"

STUB5="$WORK/agent5"
cat >"$STUB5" <<'STUB_EOF'
#!/usr/bin/env bash
"$TICK_BIN" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "$RELAY_FILE" >/dev/null 2>&1
if [ "$RELAY_AGENT" = "agy" ]; then next="codex"; else next="agy"; fi
"$TICK_BIN" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to "$next" >/dev/null 2>&1
STUB_EOF
chmod +x "$STUB5"

export STUB_PROGRESS="no"
export STUB_APPROVE_AT="99"
export MARATHON_ROOT="$A"  # GH-115 self-fix: was $ROOT (the real repo), landing this test's commit on the live clone
export MARATHON_AGENT_CMD="$STUB5"
out="$(python3 "$ROOT/utils/py/marathon_drive.py" --phase-brief "$A/brief.md" --reviewer codex --builder agy --phase-id p1 --relay-task TASK6 --phases-dir "$A/phases" --round-cap 1 --force --pre-advance-cmd true 2>&1)"
rc=$?

if [ "$rc" -eq 4 ]; then
    esc_file="$A/phases/p1/ESCALATION.md"
    if [ -f "$esc_file" ]; then
        if grep -q "reason: cap-stalled" "$esc_file"; then
            pass "marathon-drive correctly captured cap-stalled in durable ESCALATION.md (stale data ignored)"
        elif grep -q "reason: stale-reason" "$esc_file"; then
            fail "marathon-drive recorded stale-reason in durable ESCALATION.md (stale data permitted)"
        else
            fail "marathon-drive ESCALATION.md missing cap-stalled reason. Content: $(cat "$esc_file")"
        fi
    else
        fail "marathon-drive failed to create durable ESCALATION.md"
    fi
else
    fail "marathon-drive should exit 4 on cap-stalled. rc=$rc out=$out"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
