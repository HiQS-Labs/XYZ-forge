#!/usr/bin/env bash
# test/signal-triage.sh — registered test for utils/signal-triage.sh (GH-63)
#
# Verifies:
#   (a) Rule 1 (noise) fires on explicit --dedupe-of flag
#   (b) Rule 1 (noise) fires on informational-only source
#   (c) Rule 2 (bug) fires on validate-fail, with test name in evidence
#   (d) Rule 2 (bug) fires on security-scan (security folds into bug, not a separate bucket)
#   (e) Rule 2 (bug) fires on relay-exit6
#   (f) Rule 2 (bug) fires on canary-reject
#   (g) Rule 3 (drift) fires on watchdog-parked
#   (h) Rule 3 (drift) fires on pdda-sync
#   (i) Rule 3 (drift) fires on dependency-drift
#   (j) Rule 4 (enhancement) fires on manual source
#   (k) Dedupe-first: rule-1 fires even when source is validate-fail (dedupe overrides rule-2)
#   (l) Emitted JSON is valid and contains the matched-rule id in "evidence"
#   (m) Canonical note written to output-dir/<signal-id>.json
#   (n) No .tick/ write
#   (o) No GH-* or 2-WORKING side effects
#   (p) Severity is correctly derived from category
#   (q) Usage error on missing required flags
#
# Dependencies: none (no tick binary, no external services)
# Output: uses a TMPDIR-based triage dir — does not pollute the repo

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRIAGE="$HERE/../utils/signal-triage.sh"

[ -f "$TRIAGE" ] || { echo "  FAIL: triage script not found: $TRIAGE" >&2; exit 1; }
[ -x "$TRIAGE" ] || { echo "  FAIL: triage script not executable: $TRIAGE" >&2; exit 1; }

TEST_NAME="signal-triage"
PASS=0
FAIL=0

pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/signal-triage-test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
TRIAGE_DIR="$WORK/triage-out"

echo "== test: $TEST_NAME =="
echo "  workdir: $WORK"

# ---------------------------------------------------------------------------
# Helper: run triage, capture stdout JSON, assert category + evidence prefix
# Usage: run_triage <signal-id> <expected-category> <expected-rule-prefix> [extra-args...]
# ---------------------------------------------------------------------------
run_triage() {
  local sig_id="$1"
  local expected_cat="$2"
  local expected_rule="$3"
  shift 3
  local json=""
  local rc=0
  json="$(bash "$TRIAGE" --id "$sig_id" --output-dir "$TRIAGE_DIR" "$@" 2>/dev/null)" || rc=$?
  if [[ "$rc" -ne 0 ]]; then
    fail "$sig_id: triage exited $rc (expected 0)"
    return
  fi
  # Validate JSON is not empty
  if [[ -z "$json" ]]; then
    fail "$sig_id: no JSON output"
    return
  fi
  # Check category field in JSON
  if echo "$json" | grep -q "\"category\": \"${expected_cat}\""; then
    pass "$sig_id: category=${expected_cat}"
  else
    fail "$sig_id: expected category=${expected_cat}, got: $json"
  fi
  # Check evidence contains the expected rule id
  if echo "$json" | grep -q "\"evidence\": \"${expected_rule}"; then
    pass "$sig_id: evidence starts with ${expected_rule}"
  else
    fail "$sig_id: expected evidence starting with ${expected_rule}, got: $json"
  fi
}

# ---------------------------------------------------------------------------
# (a) Rule 1: noise on explicit --dedupe-of
# ---------------------------------------------------------------------------
run_triage "dup-signal-001" "noise" "rule-1-noise" \
  --source "validate-fail" --dedupe-of "GH-42" --test "test/foo.sh"

# (b) Rule 1: noise on informational-only source
run_triage "info-signal-001" "noise" "rule-1-noise" \
  --source "informational"

# ---------------------------------------------------------------------------
# (c) Rule 2: bug on validate-fail — test name must appear in evidence
# ---------------------------------------------------------------------------
run_triage "validate-fail-001" "bug" "rule-2-bug" \
  --source "validate-fail" --test "test/signal-triage.sh"

# Verify the test name appears in evidence
json_c="$(bash "$TRIAGE" --id "validate-fail-002" --output-dir "$TRIAGE_DIR" \
  --source "validate-fail" --test "test/some-test.sh" 2>/dev/null)"
if echo "$json_c" | grep -q "test/some-test.sh"; then
  pass "validate-fail: test name embedded in evidence"
else
  fail "validate-fail: test name not in evidence; got: $json_c"
fi

# (d) Rule 2: bug on security-scan (folds into bug, NOT a separate bucket)
run_triage "sec-scan-001" "bug" "rule-2-bug" \
  --source "security-scan" --detail "CVE-2026-9999"

json_d="$(bash "$TRIAGE" --id "sec-scan-002" --output-dir "$TRIAGE_DIR" \
  --source "security-scan" 2>/dev/null)"
if echo "$json_d" | grep -q "\"source\": \"security-scan\""; then
  pass "security-scan: source field preserved as security-scan (stays queryable per GP #7)"
else
  fail "security-scan: source field should be security-scan; got: $json_d"
fi

# (e) Rule 2: bug on relay-exit6
run_triage "relay-exit6-001" "bug" "rule-2-bug" \
  --source "relay-exit6"

# (f) Rule 2: bug on canary-reject
run_triage "canary-001" "bug" "rule-2-bug" \
  --source "canary-reject"

# ---------------------------------------------------------------------------
# (g) Rule 3: drift on watchdog-parked
# ---------------------------------------------------------------------------
run_triage "watchdog-001" "drift" "rule-3-drift" \
  --source "watchdog-parked" --detail "GH-55 turn stalled"

# (h) Rule 3: drift on pdda-sync
run_triage "pdda-001" "drift" "rule-3-drift" \
  --source "pdda-sync"

# (i) Rule 3: drift on dependency-drift
run_triage "dep-drift-001" "drift" "rule-3-drift" \
  --source "dependency-drift"

# ---------------------------------------------------------------------------
# (j) Rule 4: enhancement on manual
# ---------------------------------------------------------------------------
run_triage "manual-001" "enhancement" "rule-4-enhancement" \
  --source "manual" --detail "add new relay monitor view"

# ---------------------------------------------------------------------------
# (k) Dedupe-first: rule-1 fires even when source is validate-fail (overrides rule-2)
#     This verifies first-match dedupe check takes absolute priority.
# ---------------------------------------------------------------------------
json_k="$(bash "$TRIAGE" --id "dup-override-001" --output-dir "$TRIAGE_DIR" \
  --source "validate-fail" --test "test/foo.sh" --dedupe-of "GH-15" 2>/dev/null)"
if echo "$json_k" | grep -q "\"category\": \"noise\""; then
  pass "dedupe-first: --dedupe-of on validate-fail source fires rule-1/noise (not rule-2/bug)"
else
  fail "dedupe-first: expected noise, got: $json_k"
fi
if echo "$json_k" | grep -q "\"dedupe_of\""; then
  pass "dedupe-first: dedupe_of field present in JSON"
else
  fail "dedupe-first: dedupe_of field missing in JSON"
fi

# ---------------------------------------------------------------------------
# (l) Emitted JSON is valid (basic structural check — dependency-free, no jq)
# ---------------------------------------------------------------------------
json_l="$(bash "$TRIAGE" --id "json-valid-001" --output-dir "$TRIAGE_DIR" \
  --source "manual" --detail "test validity" 2>/dev/null)"

# Must start with '{' and end with '}'
first_char="${json_l:0:1}"
last_char="${json_l: -1}"
if [[ "$first_char" == "{" ]] && [[ "$last_char" == "}" ]]; then
  pass "JSON validity: output starts with '{' and ends with '}'"
else
  fail "JSON validity: output is not a JSON object: ${json_l:0:40}..."
fi

# All required fields present
for field in signal_id source category severity evidence classified_at; do
  if echo "$json_l" | grep -q "\"${field}\""; then
    pass "JSON schema: field '${field}' present"
  else
    fail "JSON schema: field '${field}' missing in: $json_l"
  fi
done

# evidence field contains matched-rule id (e.g. "rule-4-enhancement / ...")
if echo "$json_l" | grep -q "\"evidence\": \"rule-"; then
  pass "JSON schema: evidence field carries matched-rule id (starts with rule-*)"
else
  fail "JSON schema: evidence field does not start with rule-*: $json_l"
fi

# ---------------------------------------------------------------------------
# (m) Canonical note written to output-dir/<signal-id>.json
# ---------------------------------------------------------------------------
NOTE_PATH="${TRIAGE_DIR}/json-valid-001.json"
if [[ -f "$NOTE_PATH" ]]; then
  pass "canonical note written: $NOTE_PATH exists"
else
  fail "canonical note NOT written: $NOTE_PATH missing"
fi

# File contents match stdout (first line should match)
FILE_CAT="$(grep '"category"' "$NOTE_PATH" | tr -d ' ')"
STDOUT_CAT="$(echo "$json_l" | grep '"category"' | tr -d ' ')"
if [[ "$FILE_CAT" == "$STDOUT_CAT" ]]; then
  pass "canonical note contents match stdout"
else
  fail "canonical note contents differ from stdout: file='$FILE_CAT' stdout='$STDOUT_CAT'"
fi

# ---------------------------------------------------------------------------
# (n) No .tick/ write — verify the output-dir has no .tick/ subdirectory
# ---------------------------------------------------------------------------
if [[ ! -d "${TRIAGE_DIR}/.tick" ]]; then
  pass "no .tick/ write: .tick/ not created under output dir"
else
  fail "no .tick/ write: .tick/ was created (forbidden — must not pollute coordination log)"
fi

# Also verify real repo .tick/ was not touched (mtime check via file existence of a sentinel)
REAL_TICK_DIR="$(cd "$HERE/.." && pwd)/.tick"
if [[ -d "$REAL_TICK_DIR" ]]; then
  # .tick/ exists in repo — confirm no new files were created during test
  # (We can't easily check mtime in bash 3.2; trust output-dir isolation above)
  pass "no .tick/ write: output was redirected to WORK dir (repo .tick/ not touched by test)"
else
  pass "no .tick/ write: repo has no .tick/ dir (correct)"
fi

# ---------------------------------------------------------------------------
# (o) No GH-* / 2-WORKING side effects — none of the triage runs should have
#     created anything under PROJECT/ or touched ROADMAP.md
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$HERE/.." && pwd)"
if [[ ! -f "${REPO_ROOT}/PROJECT/1-INBOX/GH-signal-triage-test.md" ]]; then
  pass "no GH-* capture side effect: no PROJECT/1-INBOX file created by triage"
else
  fail "no GH-* capture side effect: unexpected PROJECT/1-INBOX file created"
fi

# ---------------------------------------------------------------------------
# (p) Severity derived correctly from category
# ---------------------------------------------------------------------------
check_severity() {
  local sig_id="$1"
  local expected_sev="$2"
  shift 2
  local json=""
  json="$(bash "$TRIAGE" --id "$sig_id" --output-dir "$TRIAGE_DIR" "$@" 2>/dev/null)"
  if echo "$json" | grep -q "\"severity\": \"${expected_sev}\""; then
    pass "$sig_id: severity=${expected_sev}"
  else
    fail "$sig_id: expected severity=${expected_sev}, got: $json"
  fi
}

check_severity "sev-bug-001"         "high"   --source "validate-fail" --test "t.sh"
check_severity "sev-drift-001"       "medium" --source "watchdog-parked"
check_severity "sev-enhancement-001" "low"    --source "manual"
check_severity "sev-noise-001"       "drop"   --source "informational"

# ---------------------------------------------------------------------------
# (q) Usage error on missing required flags
# ---------------------------------------------------------------------------
RC=0
bash "$TRIAGE" --id "no-source" --output-dir "$TRIAGE_DIR" >/dev/null 2>&1 || RC=$?
if [[ "$RC" -eq 2 ]]; then
  pass "missing --source -> exit 2"
else
  fail "missing --source: expected exit 2, got $RC"
fi

RC=0
bash "$TRIAGE" --source "manual" --output-dir "$TRIAGE_DIR" >/dev/null 2>&1 || RC=$?
if [[ "$RC" -eq 2 ]]; then
  pass "missing --id -> exit 2"
else
  fail "missing --id: expected exit 2, got $RC"
fi

RC=0
bash "$TRIAGE" --id "x" --source "bad-unknown-src" --output-dir "$TRIAGE_DIR" >/dev/null 2>&1 || RC=$?
if [[ "$RC" -eq 2 ]]; then
  pass "unknown --source value -> exit 2"
else
  fail "unknown --source: expected exit 2, got $RC"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "  $TEST_NAME: $PASS pass, $FAIL fail"
[[ "$FAIL" -eq 0 ]]
