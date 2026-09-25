#!/usr/bin/env bash
# GH-813 acceptance probe (NOT a gate suite): N rounds x 10 concurrent `harness_app.py log`
# workers, each round against a FRESH database, stderr kept. Prints failed rounds, error classes
# with their raising line, failure latency, and rounds whose DB does not hold exactly 10 rows.
# Usage: repro-concurrent-init.sh <repo-root> <scratch-dir> <rounds>
set -u
R="$1"; W="$2"; N="$3"
export PYTHONPATH="$R/utils/py"; bad=0
for r in $(seq 1 "$N"); do
  mkdir -p "$W/$r"; pids=()
  for i in $(seq 1 10); do
    ( s=$(python3 -c 'import time;print(time.time())')
      XYZ_HARNESS_DB="$W/$r/harnesses.db" python3 "$R/utils/py/harness_app.py" log --device-id "d$i" \
        --harness-id codex --model-id deepseek/deepseek-v4-pro --gateway openrouter --reasoning-effort high \
        --shim codex-turn.py --task-scope "w$i" --seconds 0.5 --exit-code 0 >/dev/null 2>"$W/$r/err$i"; rc=$?
      e=$(python3 -c 'import time;print(time.time())')
      [ "$rc" -ne 0 ] && python3 -c "print(round($e-$s,2))" > "$W/$r/t$i"; exit "$rc" ) & pids+=($!)
  done
  e=0; for p in "${pids[@]}"; do wait "$p" || e=$((e+1)); done
  [ "$e" -gt 0 ] && bad=$((bad+1))
done
echo "failed rounds: $bad/$N"
echo "error classes:"; for f in $(grep -l . "$W"/*/err* 2>/dev/null); do tail -1 "$f"; done | sort | uniq -c
echo "raising frames:"; for f in $(grep -l . "$W"/*/err* 2>/dev/null); do grep -E 'line [0-9]+, in' "$f" | tail -1 | sed -E 's#File ".*/(utils/py/[^"]+)"#\1#'; done | sort | uniq -c
echo "failure latency (s):"; cat "$W"/*/t* 2>/dev/null | sort -n | tr '\n' ' '; echo
echo "rounds with row count != 10:"; n=0; for r in $(seq 1 "$N"); do c=$(sqlite3 "$W/$r/harnesses.db" "select count(*) from invocation_logs" 2>/dev/null); [ "$c" = 10 ] || n=$((n+1)); done; echo "$n"
