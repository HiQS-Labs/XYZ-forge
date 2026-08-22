#!/usr/bin/env bash
# Autonomous Fuzzing Loop — execute every synthetic shell test and leave a concise, parseable log.
# Supports --jsonl <path> to emit structured telemetry conforming to schema_version: "1.0".
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
TEST_DIR="${FUZZ_TEST_DIR:-$ROOT/test/synthetic}"
JSONL_OUT="${FUZZ_JSONL_PATH:-}"

# Parse optional arguments
PRINT_SELECTION=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --jsonl)
      JSONL_OUT="$2"
      shift 2
      ;;
    --test-dir)
      TEST_DIR="$2"
      shift 2
      ;;
    --print-selection)
      PRINT_SELECTION=1
      shift
      ;;
    *)
      shift
      ;;
  esac
done

# #141 Phase 1: consume the AUTHORITATIVE registry instead of re-deriving membership with our
# own find. Two selectors over one directory is how a suite ends up gated but never fuzzed (or
# the reverse) — the exact divergence this closes. Membership = every file under TEST_DIR the
# registry can reach: direct `synthetic/<name>` entries AND root-level wrappers (resolved by the
# test/synthetic/... path inside the wrapper), so both registration forms count. Falls back to
# the old find, ANNOUNCED, only when the registry is unavailable. --test-dir to any other
# directory keeps the old behavior (ad-hoc scratch runs own their own list).
discover_tests() {
  local dir="$1" listed entry base tgt cand
  if [ "$dir" = "$ROOT/test/synthetic" ] && [ -f "$ROOT/validate.sh" ]; then
    listed="$(bash "$ROOT/validate.sh" --list 2>/dev/null || true)"
    if [ -n "$listed" ]; then
      while IFS= read -r entry; do
        [ -n "$entry" ] || continue
        base="${entry#test/}"
        case "$base" in
          synthetic/*)
            cand="$ROOT/test/$base"
            ;;
          *)
            # root-level entry: a suite in its own right, or a wrapper whose exec target
            # lives under synthetic/ — resolve wrappers to what they actually run
            [ -f "$ROOT/test/$base" ] || continue
            tgt="$(grep -o 'test/synthetic/[^"'"'"' ]*\.sh' "$ROOT/test/$base" 2>/dev/null | head -1 || true)"
            [ -n "$tgt" ] || continue
            cand="$ROOT/$tgt"
            ;;
        esac
        case "$cand" in
          "$dir"/*) [ -f "$cand" ] && printf '%s\n' "$cand" ;;
        esac
      done <<<"$listed" | LC_ALL=C sort -u
      return
    fi
    printf 'fuzz-loop: validate.sh --list unavailable — falling back to independent find (membership may diverge from the registry)\n' >&2
  fi
  find "$dir" -type f -name '*.sh' -print | LC_ALL=C sort
}

if [ "$PRINT_SELECTION" -eq 1 ]; then
  # Introspection mode (#141 Phase 1): print the resolved selection and exit — the registry
  # regression drives this instead of duplicating the resolver.
  [ -d "$TEST_DIR" ] || {
    printf 'FUZZ_SUMMARY|status=ERROR|reason=missing-test-dir|test_dir=%s\n' "$TEST_DIR" >&2
    exit 2
  }
  discover_tests "$TEST_DIR"
  exit 0
fi

[ -d "$TEST_DIR" ] || {
  printf 'FUZZ_SUMMARY|status=ERROR|reason=missing-test-dir|test_dir=%s\n' "$TEST_DIR" >&2
  exit 2
}

if [ -n "$JSONL_OUT" ]; then
  mkdir -p "$(dirname "$JSONL_OUT")"
fi

total=0
passed=0
failed=0
session_id="$(date -u +"%Y%m%d%H%M%S")"

printf 'FUZZ_START|test_dir=%s\n' "$TEST_DIR"

# discover_tests keeps the counters in this shell via process substitution (a pipeline would put
# the loop in a subshell and lose the totals) and, on the default root, derives membership from
# the authoritative registry — see the #141 Phase 1 note above.
while IFS= read -r test_script; do
  [ -n "$test_script" ] || continue
  total=$((total + 1))
  started_ms="$(python3 -c 'import time; print(int(time.time() * 1000))')"
  output="$(bash "$test_script" 2>&1)"
  status=$?
  finished_ms="$(python3 -c 'import time; print(int(time.time() * 1000))')"
  duration_ms=$((finished_ms - started_ms))
  elapsed=$(( (duration_ms + 999) / 1000 ))
  test_rel="${test_script#$ROOT/}"
  test_name="$(basename "$test_script")"
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  if [ "$status" -eq 0 ]; then
    passed=$((passed + 1))
    printf 'FUZZ_RESULT|status=PASS|test=%s|exit_code=0|duration_ms=%s\n' \
      "$test_script" "$duration_ms"
    res_status="pass"
  else
    failed=$((failed + 1))
    printf 'FUZZ_RESULT|status=FAIL|test=%s|exit_code=%s|duration_ms=%s\n' \
      "$test_script" "$status" "$duration_ms" >&2
    [ -z "$output" ] || printf '%s\n' "$output" | sed 's/^/  | /' >&2
    res_status="fail"
  fi

  # #141 Phase 2: classification is DERIVED, not aliased. severity grades the DOCUMENTED harness
  # exit classes rather than the pass/fail bit (containment 6 and timeout 7 are the scary
  # families, usage 2 is cheap, other nonzero is medium); likely_cause inspects the captured
  # output — a traceback or timeout marker says something the exit code alone cannot. The nested
  # `status` key is gone entirely: it was a pure alias of top-level status (GH-141's review
  # counted it as the third alias), and consumers key on the top-level field.
  sev="high"
  case "$status" in
    0) sev="none" ;;
    2) sev="low" ;;
    3|4|5) sev="medium" ;;
    6|7) sev="high" ;;
  esac
  cause=""
  if [ "$status" -ne 0 ]; then
    cause="synthetic_invariant_failure"
    if grep -q 'Traceback (most recent call last)' <<<"$output"; then
      cause="unhandled_traceback"
    elif [ "$status" -eq 7 ] || grep -qiE 'timed? ?out|exceeded.*cap' <<<"$output"; then
      cause="timeout"
    fi
  fi

  if [ -n "$JSONL_OUT" ]; then
    python3 -c '
import sys, json
out_path, session_id, run_idx, timestamp, name, path, status, exit_code, dur_ms, sev, cause = sys.argv[1:12]
record = {
    "schema_version": "1.0",
    "run_id": f"fuzz-{session_id}-{run_idx}",
    "timestamp": timestamp,
    "engine": "fuzz_loop",
    "test_name": name,
    "test_path": path,
    "status": status,
    "exit_code": int(exit_code),
    "duration_ms": int(dur_ms),
    "turn_count": 1,
    "prompt_tokens": None,
    "completion_tokens": None,
    "total_tokens": None,
    "tokens_source": "unsupported",
    "classification": {
        "category": "deterministic_synthetic_fuzz",
        "likely_cause": cause or None,
        "severity": sev,
    }
}
try:
    with open(out_path, "a", encoding="utf-8") as f:
        f.write(json.dumps(record) + "\n")
except Exception as e:
    sys.stderr.write(f"fuzz-loop: failed to write telemetry to {out_path}: {e}\n")
' "$JSONL_OUT" "$session_id" "$total" "$timestamp" "$test_name" "$test_rel" "$res_status" "$status" "$duration_ms" "$sev" "$cause"
  fi
done < <(discover_tests "$TEST_DIR")

summary_status=PASS
[ "$failed" -eq 0 ] || summary_status=FAIL
printf 'FUZZ_SUMMARY|status=%s|total=%s|passed=%s|failed=%s\n' \
  "$summary_status" "$total" "$passed" "$failed"
[ "$failed" -eq 0 ]
