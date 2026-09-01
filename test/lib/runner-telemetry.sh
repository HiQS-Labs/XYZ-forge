#!/usr/bin/env bash
# runner-telemetry.sh — retained JSONL telemetry for validate.sh and ci-local.sh (GH-365 step 2).
#
# WHY: the #365 baseline profile had to instrument runners BY HAND to learn where 27 minutes
# went, and a campaign's validity (identity intact, clean tree, no contention-masked skips)
# had to be reconstructed from prose. This lib makes every run emit its own reconstructable
# record as a matter of course.
#
# CONTRACT (sourced by both runners; one implementation, same discipline as runner-envelope.sh):
#   rt_begin <here> <runner> <mode> <width> [tier] [registered]
#       opens ONE append-only JSONL file under ${XYZ_VALIDATE_TELEMETRY:-<here>/.tick/telemetry}/
#       (gitignored working location — a run cited as evidence commits its receipt + provenance
#       in the SAME PR, per GH-430; the store is deliberately NOT harnesses.db) and writes the
#       run.start record: run id, commit, host, runner, mode, width, tier, registered denominator.
#   rt_now_ms                 — sub-second wall clock (perl Time::HiRes; bash 3.2 has no
#                               EPOCHREALTIME, macOS date has no %N).
#   rt_emit <event> <lane> <name> <started_ms> <ended_ms> <rc> [k=v ...]
#       appends one record. Fields are enum/filename/int controlled — never free text — so
#       printf assembly cannot produce invalid JSON. Parallel workers append with >> (O_APPEND,
#       sub-PIPE_BUF lines are atomic); records are append-ordered, and consumers sort by
#       (started_ms, ts_ms) to reconstruct execution order.
#   rt_suite <lane> <name> <started_ms> <ended_ms> <rc> <logfile>
#       rt_emit plus out_bytes, out_sha256 (first 12 hex), and skip_lines — lines matching
#       '^\s*SKIP[:)]' in the suite's captured output. skip_lines > 0 in a green suite is the
#       contention-skip shape PR #367 introduced (gh346 routing assertions SKIP under the driver
#       lock): a campaign treating that run as equivalent is INVALID, not equivalent (#365 step 3).
#   rt_extra <k=v ...>        — append a record emitted by the SUITE itself (the subdivision
#       seam: heavy suites may add fixture/waits/subprocess/assertion phase records; adoption
#       is incremental, the runner never guesses assertion counts it cannot see).
#   rt_summary <passed> <failed> <total> [k=v ...]
#       run.summary record; the envelope assert outcome rides along as envelope_rc/envelope_drift
#       when the runner sets RT_ENVELOPE_RC / RT_ENVELOPE_DRIFT.
#
# Every timestamp is epoch-ms. Lanes: pool | driver-lock | retry | non-suite | stage.
rt_now_ms() { perl -MTime::HiRes -e 'print int(Time::HiRes::time()*1000)'; }

rt_hash12() {  # <file> — first 12 hex of sha256, "-" when absent
  [ -n "${1:-}" ] && [ -f "$1" ] || { printf '%s' "-"; return 0; }
  shasum -a 256 "$1" | cut -c1-12
}

rt_skip_lines() {  # <file> — count of SKIP verdict lines in a suite's output
  [ -n "${1:-}" ] && [ -f "$1" ] || { printf '0'; return 0; }
  grep -cE '^[[:space:]]*(SKIP[:)]|skipped[ :])' "$1" 2>/dev/null || printf '0'
}

rt_begin() {
  local here="$1" runner="$2" mode="$3" width="${4:-1}" tier="${5:-3}" registered="${6:-0}"
  RT_RUNNER="$runner"; RT_MODE="$mode"; RT_WIDTH="$width"; RT_TIER="$tier"
  local dir="${XYZ_VALIDATE_TELEMETRY:-$here/.tick/telemetry}"
  mkdir -p "$dir" 2>/dev/null || { RT_FILE=""; return 0; }   # telemetry is best-effort: never gate a run on it
  local ts pid commit host
  ts="$(rt_now_ms)"; pid="$$"
  commit="$(git -C "$here" rev-parse --verify HEAD 2>/dev/null || printf unknown)"
  host="$(hostname -s 2>/dev/null || printf unknown)"
  RT_RUN_ID="$(printf '%s' "$commit" | cut -c1-9)-$pid"
  RT_FILE="$dir/$runner-$mode-$ts-$pid.jsonl"
  printf '{"v":1,"ts_ms":%s,"run":"%s","runner":"%s","event":"run.start","commit":"%s","host":"%s","mode":"%s","width":%s,"tier":%s,"registered":%s}\n' \
    "$ts" "$RT_RUN_ID" "$runner" "$commit" "$host" "$mode" "$width" "$tier" "$registered" >> "$RT_FILE"
}

rt_emit() {  # <event> <lane> <name> <started_ms> <ended_ms> <rc> [k=v ...]
  [ -n "${RT_FILE:-}" ] || return 0
  local event="$1" lane="$2" name="$3" s="$4" e="$5" rc="$6"; shift 6
  local ts extra k v
  ts="$(rt_now_ms)"
  extra=""
  for kv in "$@"; do
    k="${kv%%=*}"; v="${kv#*=}"
    extra="$extra,\"$k\":\"$v\""
  done
  printf '{"v":1,"ts_ms":%s,"run":"%s","runner":"%s","event":"%s","lane":"%s","name":"%s","started_ms":%s,"ended_ms":%s,"duration_ms":%s,"rc":%s%s}\n' \
    "$ts" "$RT_RUN_ID" "$RT_RUNNER" "$event" "$lane" "$name" "$s" "$e" "$(( e - s ))" "$rc" "$extra" >> "$RT_FILE"
}

rt_suite() {  # <lane> <name> <started_ms> <ended_ms> <rc> <logfile>
  [ -n "${RT_FILE:-}" ] || return 0
  local lane="$1" name="$2" s="$3" e="$4" rc="$5" log="$6"
  local ts bytes hash skips
  ts="$(rt_now_ms)"
  if [ -n "$log" ] && [ -f "$log" ]; then bytes="$(wc -c < "$log" | tr -d ' ')"; else bytes=0; fi
  hash="$(rt_hash12 "$log")"
  skips="$(rt_skip_lines "$log")"
  # queued_ms: dispatch-list build time (when POOL/LANE arrays were formed) — an approximation
  # of queue entry, since xargs does not expose dequeue time. Honest for lane ordering and
  # concurrency reconstruction; not a per-worker queue-residency measurement.
  printf '{"v":1,"ts_ms":%s,"run":"%s","runner":"%s","event":"suite","lane":"%s","name":"%s","queued_ms":%s,"started_ms":%s,"ended_ms":%s,"duration_ms":%s,"rc":%s,"worker":%s,"out_bytes":%s,"out_sha256":"%s","skip_lines":%s}\n' \
    "$ts" "$RT_RUN_ID" "$RT_RUNNER" "$lane" "$name" "${RT_DISPATCH_MS:-$s}" "$s" "$e" "$(( e - s ))" "$rc" "${BASHPID:-$$}" "$bytes" "$hash" "$skips" >> "$RT_FILE"
}

rt_extra() {  # [k=v ...] — a suite-emitted subdivision record (event=extra, lane=extra)
  [ -n "${RT_FILE:-}" ] || return 0
  local ts extra k v kv
  ts="$(rt_now_ms)"
  extra=""
  for kv in "$@"; do
    k="${kv%%=*}"; v="${kv#*=}"
    extra="$extra,\"$k\":\"$v\""
  done
  printf '{"v":1,"ts_ms":%s,"run":"%s","runner":"%s","event":"extra","lane":"extra","name":"suite-emitted"%s}\n' \
    "$ts" "$RT_RUN_ID" "$RT_RUNNER" "$extra" >> "$RT_FILE"
}

rt_summary() {  # <passed> <failed> <total> [k=v ...]
  [ -n "${RT_FILE:-}" ] || return 0
  local ts extra k v kv passed="$1" failed="$2" total="$3"
  ts="$(rt_now_ms)"
  extra=""
  shift 3
  for kv in "$@"; do
    k="${kv%%=*}"; v="${kv#*=}"
    extra="$extra,\"$k\":\"$v\""
  done
  printf '{"v":1,"ts_ms":%s,"run":"%s","runner":"%s","event":"run.summary","passed":%s,"failed":%s,"total":%s,"envelope_rc":"%s","envelope_drift":"%s"%s}\n' \
    "$ts" "$RT_RUN_ID" "$RT_RUNNER" "$passed" "$failed" "$total" "${RT_ENVELOPE_RC:-n/a}" "${RT_ENVELOPE_DRIFT:-n/a}" "$extra" >> "$RT_FILE"
}
