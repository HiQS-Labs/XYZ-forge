#!/usr/bin/env bash
# cost.sh — Phase-1 cost signals (COST-OBSERVABILITY-PLAN): the `tick cost` verb writes
# deterministic cost.tokens / cost.human events, parseGeminiStats reads `gemini -o json`
# token stats verbatim, and the coordination analyzer IGNORES cost.* events (no regression).
source "$(dirname "$0")/_setup.sh" cost
export TICK_REPO_ROOT="$A"
tick_a init >/dev/null

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# read a single field out of the one matching cost event file (jsonl, one obj per file)
field() { # <glob-substring> <key>
  node -e '
    const fs=require("fs"),path=require("path");
    const dir=path.join(process.argv[1],".tick","events");
    if(!fs.existsSync(dir)){process.stdout.write("");process.exit(0);}
    const f=fs.readdirSync(dir).filter(x=>x.includes(process.argv[2])).sort().pop();
    if(!f){process.stdout.write("");process.exit(0);}
    const ev=JSON.parse(fs.readFileSync(path.join(dir,f),"utf8"));
    process.stdout.write(String(ev[process.argv[3]] ?? ""));
  ' "$A" "$1" "$2"
}

# --- (1) human-minutes -> cost.human event -------------------------------
"$TICK" cost TASK-A --agent noel --human-minutes 12 >/dev/null
[ "$(field human-TASK-A human_minutes)" = "12" ] \
  && pass "cost --human-minutes writes human_minutes=12" || fail "human_minutes not 12 (got '$(field human-TASK-A human_minutes)')"
[ "$(field human-TASK-A type)" = "cost.human" ] \
  && pass "human event typed cost.human" || fail "wrong type"

# --- (2) explicit tokens -> cost.tokens, total auto-summed ----------------
"$TICK" cost TASK-B --agent gemini --tokens-in 100 --tokens-out 40 --tool gemini >/dev/null
[ "$(field tokens-TASK-B tokens_in)" = "100" ]  && pass "tokens_in=100" || fail "tokens_in wrong"
[ "$(field tokens-TASK-B tokens_out)" = "40" ]  && pass "tokens_out=40" || fail "tokens_out wrong"
[ "$(field tokens-TASK-B tokens_total)" = "140" ] && pass "tokens_total auto-summed to 140" || fail "total not summed"
[ "$(field tokens-TASK-B tool)" = "gemini" ]    && pass "tool=gemini recorded" || fail "tool not recorded"

# --- (3) explicit --tokens-total overrides the sum -----------------------
"$TICK" cost TASK-C --agent gemini --tokens-in 100 --tokens-out 40 --tokens-total 999 >/dev/null
[ "$(field tokens-TASK-C tokens_total)" = "999" ] && pass "explicit --tokens-total honored" || fail "total override ignored"

# --- (4) parse gemini -o json verbatim (the real CLI shape) --------------
GJ="$WORK/gem.json"
cat >"$GJ" <<'JSON'
{"session_id":"x","response":"ok","stats":{"models":{
  "flash":{"tokens":{"input":3761,"candidates":26,"total":4738,"thoughts":951}},
  "main":{"tokens":{"input":11546,"candidates":1,"total":11547,"thoughts":0}}
}}}
JSON
"$TICK" cost TASK-D --agent gemini --from-gemini-json "$GJ" --tool gemini >/dev/null
# in = 3761+11546 = 15307 ; total = 4738+11547 = 16285 ; out = total-in = 978
[ "$(field tokens-TASK-D tokens_in)" = "15307" ]    && pass "gemini-json tokens_in summed across models" || fail "in=$(field tokens-TASK-D tokens_in)"
[ "$(field tokens-TASK-D tokens_total)" = "16285" ] && pass "gemini-json tokens_total summed" || fail "total wrong"
[ "$(field tokens-TASK-D tokens_out)" = "978" ]     && pass "gemini-json tokens_out = total-in" || fail "out wrong"

# --- (5) parseGeminiStats returns null on non-json / no stats ------------
nullres="$(node -e 'const {parseGeminiStats}=require(process.argv[1]); console.log(parseGeminiStats("not json")===null && parseGeminiStats(JSON.stringify({a:1}))===null ? "OK":"BAD")' "$ROOT/src/cost.js")"
[ "$nullres" = "OK" ] && pass "parseGeminiStats -> null on garbage/no-stats" || fail "parser should return null"

# --- (5b) parseGeminiStats handles warning-prefix preamble (the real gemini-cli format) -------
# gemini -o json emits color/YOLO warnings before the JSON object; the parser must skip them.
PREAMBLE_JSON="$(cat <<'PEOF'
Warning: 256-color support not detected.
YOLO mode is enabled. All tool calls will be automatically approved.
{"session_id":"x","response":"ok","stats":{"models":{"flash":{"tokens":{"input":100,"candidates":10,"total":200,"thoughts":90}}}}}
PEOF
)"
preamble_res="$(node -e 'const {parseGeminiStats}=require(process.argv[1]); const r=parseGeminiStats(process.argv[2]); console.log(r && r.tokens_in===100 && r.tokens_total===200 ? "OK" : "BAD:"+JSON.stringify(r))' "$ROOT/src/cost.js" "$PREAMBLE_JSON")"
[ "$preamble_res" = "OK" ] && pass "parseGeminiStats handles warning-prefix preamble" || fail "preamble parse failed: $preamble_res"

# --- (6) bad input -> usage error, no event ------------------------------
"$TICK" cost TASK-E --agent gemini >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && pass "cost with no signal -> usage error (exit 2)" || fail "expected exit 2, got $rc"

# Phase 2 tests run on a FRESH events root so totals/coverage are isolated from tests 1-6.
P2="$WORK/p2"; mkdir -p "$P2"
p2() { TICK_REPO_ROOT="$P2" "$TICK" "$@"; }
p2j() { TICK_REPO_ROOT="$P2" "$TICK" analyze --format json | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const r=JSON.parse(s);let v=r;for(const k of process.argv[1].split("."))v=v[k];process.stdout.write(typeof v==="object"?JSON.stringify(v):String(v))})' "$1"; }
p2 init >/dev/null
# Two done coordination tasks (REG-1 by alpha, REG-2 by beta).
p2 log task.created REG-1 --agent dispatcher >/dev/null; p2 claim REG-1 --agent alpha --paths "x/**" >/dev/null; p2 done REG-1 --agent alpha >/dev/null
p2 log task.created REG-2 --agent dispatcher >/dev/null; p2 claim REG-2 --agent beta  --paths "y/**" >/dev/null; p2 done REG-2 --agent beta  >/dev/null

# --- (7) NO REGRESSION: cost.* events don't change the COORDINATION metrics ---
# Phase 2 intentionally REPORTS cost, so the whole json changes; the invariant is narrower —
# the coordination subset (everything except .cost) must be byte-identical.
strip_cost() { node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const r=JSON.parse(s);delete r.cost;process.stdout.write(JSON.stringify(r))})'; }
before="$(TICK_REPO_ROOT="$P2" "$TICK" analyze --format json | strip_cost)"
p2 cost REG-1 --agent gemini --tokens-in 5 --tokens-out 5 >/dev/null
p2 cost REG-1 --agent noel  --human-minutes 3 >/dev/null
after="$(TICK_REPO_ROOT="$P2" "$TICK" analyze --format json | strip_cost)"
[ "$before" = "$after" ] && pass "coordination metrics unchanged by cost.* events (no regression)" \
  || fail "cost events leaked into coordination metrics"
TICK_REPO_ROOT="$P2" "$TICK" analyze --format json | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const r=JSON.parse(s);const names=(r.agents||[]).map(a=>a.agent);process.exit(names.includes("gemini")||names.includes("noel")?1:0)})' \
  && pass "cost-only agents absent from per-agent coordination table" || fail "cost-only agent leaked into agents[]"

# --- (8) PHASE 2: analyzer computes the cost section ----------------------
# REG-1 instrumented (5/5), REG-2 not -> 1 of 2 done-tasks instrumented => PARTIAL floor.
[ "$(p2j cost.tokens.tokens_total)" = "10" ]     && pass "cost.tokens_total summed (10)" || fail "tokens_total=$(p2j cost.tokens.tokens_total)"
[ "$(p2j cost.human_minutes_total)" = "3" ]      && pass "cost.human_minutes_total summed (3)" || fail "human total wrong"
[ "$(p2j cost.tokens.partial)" = "true" ]        && pass "partial flag true (1/2 done-tasks instrumented)" || fail "partial should be true"
[ "$(p2j cost.tokens.coverage)" = "1/2" ]        && pass "coverage reads 1/2 (done-tasks)" || fail "coverage=$(p2j cost.tokens.coverage)"
[ "$(p2j cost.per_unit.tokens_per_done)" = "5" ] && pass "tokens_per_done = 10/2 = 5 (floor)" || fail "per-done=$(p2j cost.per_unit.tokens_per_done)"
[ "$(p2j cost.run_type)" = "unspecified" ]       && pass "run_type defaults to unspecified" || fail "run_type=$(p2j cost.run_type)"
TICK_REPO_ROOT="$P2" "$TICK" analyze --format md | grep -q "PARTIAL (floor only)" && pass "md renders the loud-partial floor marker" || fail "md missing partial marker"

# --- (9) run_type honors TICK_RUN_TYPE; invalid -> unspecified -----------
[ "$(TICK_RUN_TYPE=symmetric p2j cost.run_type)" = "symmetric" ] && pass "TICK_RUN_TYPE=symmetric honored" || fail "run_type env not honored"
[ "$(TICK_RUN_TYPE=garbage   p2j cost.run_type)" = "unspecified" ] && pass "invalid TICK_RUN_TYPE -> unspecified (no auto-guess)" || fail "bad run_type not rejected"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
