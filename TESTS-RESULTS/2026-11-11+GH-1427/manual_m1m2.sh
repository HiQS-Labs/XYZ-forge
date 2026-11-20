#!/usr/bin/env bash
# GH-1427 manual check M1/M2 (NOT a suite; receipt evidence only). Usage: m1m2.sh <harness-clone>
set -u
H="$1"; SHIM="$H/relay-automation/claude-turn.sh"; TICK="$H/bin/tick"
unset XYZ_HARNESS RELAY_WORKTREE_ISOLATION CLAUDE_MAX_BUDGET CLAUDE_MAX_TURNS CLAUDE_LOG RELAY_ROLE RELAY_DRIVER_LOCKED ALLOW_PATHS
export XYZ_HARNESS_LOGGING=0 XYZ_DEVICE_CONFIG_PATH=/dev/null
W="$(mktemp -d -t gh1427m.XXXXXX)"; A="$W/host"; mkdir -p "$A"
git -C "$A" init -q; git -C "$A" config user.email t@t; git -C "$A" config user.name t
printf 'STATUS: Open\n# relay\n' >"$A/relay.md"; printf '.tick/\n' >"$A/.gitignore"   # NOTE: relay-system/logs/ NOT ignored (vendored-host shape)
git -C "$A" add -A; git -C "$A" commit -qm seed
export TICK_REPO_ROOT="$A" TICK_BIN="$TICK"; "$TICK" init >/dev/null
echo "host ignores relay-system/logs? $(git -C "$A" check-ignore -q relay-system/logs/x.log && echo yes || echo no)"
FAKE="$W/claude"; cat >"$FAKE" <<'F'
#!/usr/bin/env bash
[ -n "${ARGV_OUT:-}" ] && printf '%s\n' "$*" >"$ARGV_OUT"
case "${FAKE_MODE:-budget}" in
  budget) printf '{"type":"result","subtype":"error_max_budget_usd","is_error":true,"total_cost_usd":0.5104,"errors":["Reached maximum budget ($0.50)"],"usage":{"input_tokens":120,"cache_read_input_tokens":40000,"output_tokens":3500}}\n'; exit 1 ;;
  *) printf '{"type":"result","subtype":"success","is_error":false,"result":"ok","total_cost_usd":0.06,"usage":{"input_tokens":10,"cache_read_input_tokens":2000,"output_tokens":5}}\n'; exit 0 ;;
esac
F
chmod +x "$FAKE"
seed(){ "$TICK" log task.created "$1" --agent claude-a >/dev/null; "$TICK" claim "$1" --agent claude-a --paths "z/**" >/dev/null; "$TICK" release "$1" --agent claude-a --to claude-builder >/dev/null; }
run(){ RELAY_AGENT=claude-builder CLAUDE_AGENT=claude-builder RELAY_FILE="$A/relay.md" RELAY_TASK="$1" RELAY_PEER=codex \
  CLAUDE_BIN="$FAKE" CLAUDE_TURN_ROOT="$A" bash "$SHIM" 2>"$W/$1.err" >/dev/null; echo $?; }
costrows(){ ls "$A"/.tick/events/*-tokens-"$1".jsonl 2>/dev/null | wc -l | tr -d " "; }
echo "== M1 budget-stop (fake CLI exit 1) =="
seed M1-BUDGET; rc=$(FAKE_MODE=budget run M1-BUDGET); echo "shim exit: $rc"
grep -E "claude -p failed" "$W/M1-BUDGET.err"
LOG="$(ls "$A"/relay-system/logs/*/claude-turn-M1-BUDGET-*.log 2>/dev/null | head -1)"
echo "json log after turn: $([ -n "$LOG" ] && [ -s "$LOG" ] && echo PRESENT || echo MISSING)"
echo "stderr sibling: $(ls "$A"/relay-system/logs/*/claude-turn-M1-BUDGET-*.log.stderr >/dev/null 2>&1 && echo PRESENT || echo MISSING)"
echo "tick cost rows for M1-BUDGET: $(costrows M1-BUDGET)"
cat "$A"/.tick/events/*-tokens-M1-BUDGET.jsonl 2>/dev/null | head -2
echo "== M1 success (fake CLI exit 0) =="
seed M1-OK; rc=$(FAKE_MODE=ok run M1-OK); echo "shim exit: $rc"; echo "tick cost rows for M1-OK: $(costrows M1-OK)"
echo "== M2 role defaults (argv of the CLI) =="
for role in builder reviewer; do
  seed M2-$role; ARGV_OUT="$W/argv-$role" FAKE_MODE=ok RELAY_DRIVER_LOCKED=1 RELAY_ROLE=$role run M2-$role >/dev/null
  echo "$role: $(grep -oE -- '--max-turns [^ ]+ --max-budget-usd [^ ]+' "$W/argv-$role")"
done
seed M2-ovr; ARGV_OUT="$W/argv-ovr" FAKE_MODE=ok RELAY_DRIVER_LOCKED=1 RELAY_ROLE=reviewer CLAUDE_MAX_BUDGET=1.25 run M2-ovr >/dev/null
echo "reviewer+CLAUDE_MAX_BUDGET=1.25: $(grep -oE -- '--max-turns [^ ]+ --max-budget-usd [^ ]+' "$W/argv-ovr")"
seed M2-ovrb; ARGV_OUT="$W/argv-ovrb" FAKE_MODE=ok RELAY_DRIVER_LOCKED=1 RELAY_ROLE=builder CLAUDE_MAX_BUDGET=1.25 CLAUDE_MAX_TURNS=7 run M2-ovrb >/dev/null
echo "builder+CLAUDE_MAX_BUDGET=1.25,TURNS=7: $(grep -oE -- '--max-turns [^ ]+ --max-budget-usd [^ ]+' "$W/argv-ovrb")"
echo "== ESCALATION builder_diag parse on the M1 log =="
[ -n "$LOG" ] && python3 -c "
import json,sys;d=json.load(open(sys.argv[1]))
print(', '.join(f'{k}={d[k]}' for k in ['is_error','subtype','errors','terminal_reason','total_cost_usd'] if k in d))" "$LOG"
echo "host git status after all turns:"; git -C "$A" status --porcelain
rm -rf "$W"
