#!/usr/bin/env bash
# GH-1427 live smoke (manual check, bounded). Usage: smoke.sh <harness-clone>
set -u
H="$1"; SHIM="$H/relay-automation/claude-turn.sh"; TICK="$H/bin/tick"
unset XYZ_HARNESS RELAY_WORKTREE_ISOLATION CLAUDE_MAX_BUDGET CLAUDE_MAX_TURNS CLAUDE_LOG CLAUDE_BIN ALLOW_PATHS
export XYZ_HARNESS_LOGGING=0 XYZ_DEVICE_CONFIG_PATH=/dev/null RELAY_DRIVER_LOCKED=1 RELAY_ROLE=builder
W="$(mktemp -d -t gh1427s.XXXXXX)"; A="$W/host"; mkdir -p "$A"
git -C "$A" init -q; git -C "$A" config user.email t@t; git -C "$A" config user.name t
printf 'NEXT: Producer\nSTATUS: Open\n# relay smoke\n\nThis is a harness smoke test. Do not read or edit any other file. Append exactly one line `smoke: ok` at the end of this file and stop.\n' >"$A/relay.md"
printf '.tick/\n' >"$A/.gitignore"; git -C "$A" add -A; git -C "$A" commit -qm seed
export TICK_REPO_ROOT="$A" TICK_BIN="$TICK"; "$TICK" init >/dev/null
claude --version
seed(){ "$TICK" log task.created "$1" --agent claude-a >/dev/null; "$TICK" claim "$1" --agent claude-a --paths "z/**" >/dev/null; "$TICK" release "$1" --agent claude-a --to claude-builder >/dev/null; }
run(){ RELAY_AGENT=claude-builder CLAUDE_AGENT=claude-builder RELAY_FILE="$A/relay.md" RELAY_TASK="$1" RELAY_PEER=codex CLAUDE_TURN_ROOT="$A" bash "$SHIM" 2>"$W/$1.err" >/dev/null; echo $?; }
report(){ local t=$1; local log; log="$(ls "$A"/relay-system/logs/*/claude-turn-$t-*.log 2>/dev/null | head -1)"
  grep -E "claude -p failed|CLI diagnostics" "$W/$t.err" | sed "s|$W|<W>|g"
  echo "json log: $([ -n "$log" ] && [ -s "$log" ] && echo PRESENT || echo MISSING)"
  [ -n "$log" ] && python3 -c "
import json,sys;d=json.load(open(sys.argv[1]));u=d.get('usage',{})
print('subtype=%s is_error=%s errors=%s total_cost_usd=%s'%(d.get('subtype'),d.get('is_error'),d.get('errors'),d.get('total_cost_usd')))
print('usage: input=%s cache_read=%s output=%s -> expected tokens_in=%s tokens_out=%s'%(u.get('input_tokens',0),u.get('cache_read_input_tokens',0),u.get('output_tokens',0),u.get('input_tokens',0)+u.get('cache_read_input_tokens',0),u.get('output_tokens',0)))" "$log"
  echo "tick cost rows: $(ls "$A"/.tick/events/*-tokens-$t.jsonl 2>/dev/null | wc -l | tr -d ' ')"
  cat "$A"/.tick/events/*-tokens-$t.jsonl 2>/dev/null | python3 -c "import sys,json;[print('row: tokens_in=%s tokens_out=%s'%(j['tokens_in'],j['tokens_out'])) for j in map(json.loads,sys.stdin)]"; }
echo "== MAIN: builder turn, CLAUDE_MAX_BUDGET=0.01 =="
seed SMOKE-BUDGET; echo "shim exit: $(CLAUDE_MAX_BUDGET=0.01 run SMOKE-BUDGET)"; report SMOKE-BUDGET
echo "== ADJACENT: rerun, default builder ceiling, trivial relay =="
seed SMOKE-OK; echo "shim exit: $(run SMOKE-OK)"; report SMOKE-OK
grep -E "max-budget|smoke: ok" "$A/relay.md" | head -2
echo "host status:"; git -C "$A" status --porcelain
rm -rf "$W"
