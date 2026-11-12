#!/usr/bin/env bash
# GH-1427 live smoke (manual check, bounded). Usage: manual_smoke.sh <harness-clone> [<out-dir>]
# With <out-dir>, keeps a credential-free accounting projection of each real result JSON
# (type/subtype/is_error/errors/total_cost_usd + usage/modelUsage token fields) and compares it to the tick row.
set -u
H="$1"; OUT="${2:-}"; SHIM="$H/relay-automation/claude-turn.sh"; TICK="$H/bin/tick"
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
  [ -n "$log" ] && python3 - "$log" "$OUT" "$t" "$A" <<'PY'
import glob, json, os, sys
log, out, task, host = sys.argv[1:5]
d = json.load(open(log))
U = ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens", "output_tokens")
M = ("inputTokens", "cacheReadInputTokens", "cacheCreationInputTokens", "outputTokens", "costUSD")
proj = {k: d.get(k) for k in ("type", "subtype", "is_error", "errors", "total_cost_usd", "num_turns")}
proj["usage"] = {k: (d.get("usage") or {}).get(k, 0) for k in U}
proj["modelUsage"] = {m: {k: v.get(k, 0) for k in M} for m, v in (d.get("modelUsage") or {}).items()}
print("subtype=%s is_error=%s errors=%s total_cost_usd=%s" % (d.get("subtype"), d.get("is_error"), d.get("errors"), d.get("total_cost_usd")))
u = proj["usage"]; ui, uo = u["input_tokens"] + u["cache_read_input_tokens"], u["output_tokens"]
mi = sum(v["inputTokens"] + v["cacheReadInputTokens"] for v in proj["modelUsage"].values())
mo = sum(v["outputTokens"] for v in proj["modelUsage"].values())
exp_in, exp_out, src = (ui, uo, "usage") if (ui or uo) else (mi, mo, "modelUsage")
print("usage: in(input+cache_read)=%s out=%s | modelUsage sum: in=%s out=%s | expected from %s: in=%s out=%s" % (ui, uo, mi, mo, src, exp_in, exp_out))
for m, v in proj["modelUsage"].items():
    print("  modelUsage[%s]: input=%s cache_read=%s output=%s costUSD=%s" % (m, v["inputTokens"], v["cacheReadInputTokens"], v["outputTokens"], v["costUSD"]))
rows = [json.load(open(f)) for f in sorted(glob.glob(os.path.join(host, ".tick", "events", "*-tokens-%s.jsonl" % task)))]
for r in rows:
    print("row: tokens_in=%s tokens_out=%s" % (r["tokens_in"], r["tokens_out"]))
ok = len(rows) == 1 and rows[0]["tokens_in"] == exp_in and rows[0]["tokens_out"] == exp_out and (exp_in or exp_out)
print("COMPARE %s: rows=%d expected=(%s,%s) -> %s" % (task, len(rows), exp_in, exp_out, "MATCH" if ok else "MISMATCH"))
if out:
    os.makedirs(out, exist_ok=True)
    json.dump({"result_projection": proj, "tick_rows": [{k: r[k] for k in ("type", "task", "tokens_in", "tokens_out", "tool")} for r in rows]},
              open(os.path.join(out, "accounting-%s.json" % task), "w"), indent=2, sort_keys=True)
PY
  echo "tick cost rows: $(ls "$A"/.tick/events/*-tokens-$t.jsonl 2>/dev/null | wc -l | tr -d ' ')"; }
echo "== MAIN: builder turn, CLAUDE_MAX_BUDGET=0.01 =="
seed SMOKE-BUDGET; echo "shim exit: $(CLAUDE_MAX_BUDGET=0.01 run SMOKE-BUDGET)"; report SMOKE-BUDGET
echo "== ADJACENT: rerun, default builder ceiling, trivial relay =="
seed SMOKE-OK; echo "shim exit: $(run SMOKE-OK)"; report SMOKE-OK
grep -E "max-budget|smoke: ok" "$A/relay.md" | head -2
echo "host status:"; git -C "$A" status --porcelain
rm -rf "$W"
