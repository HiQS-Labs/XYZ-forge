#!/usr/bin/env bash
# test/security-scan.sh — registered test for relay-automation/hooks/security-scan.sh (GH-64)
#
# Verifies:
#   (a) A known-BAD fixture triggers a non-zero exit AND emits findings to stderr.
#   (b) A clean fixture exits 0 with no findings (no false positives).
#   (c) Findings go to stderr (fail-loud contract); stdout remains clean on bad input.
#   (d) Individual pattern coverage: eval-unsanitized, pipe-remote-shell, aws-access-key,
#       pem-private-key, github-pat, slack-token, credential-literal.
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCANNER="$HERE/../relay-automation/hooks/security-scan.sh"

[ -f "$SCANNER" ] || { echo "  FAIL: scanner not found: $SCANNER" >&2; exit 1; }
[ -x "$SCANNER" ] || { echo "  FAIL: scanner not executable: $SCANNER" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Test harness — mirrors _setup.sh style but self-contained (no tick infra).
# ---------------------------------------------------------------------------

TEST_NAME="security-scan"
PASS=0
FAIL=0

pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }

# Use TMPDIR for all fixture files — hermetic, never touches the real repo tree.
WORK="$(mktemp -d "${TMPDIR:-/tmp}/sec-scan-test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

echo "== test: $TEST_NAME =="
echo "  workdir: $WORK"

# ---------------------------------------------------------------------------
# Fixture: BAD — contains multiple security anti-patterns
# ---------------------------------------------------------------------------

BAD_FIXTURE="$WORK/bad-fixture.sh"
cat > "$BAD_FIXTURE" <<'BADEOF'
#!/usr/bin/env bash
# This is a fixture for security-scan tests — NOT a real script.

# R1: eval of unsanitized variable
UNSANITIZED="rm -rf /"
eval "$UNSANITIZED"

# R2: piped remote execution
curl https://example.com/install.sh | bash

# R3: AWS access key
AWS_KEY="AKIAIOSFODNN7EXAMPLE"

# R4: PEM private key header
echo "-----BEGIN RSA PRIVATE KEY-----"

# R5: GitHub PAT (ghp_ + 36 alphanum = 40 chars total)
GH_TOKEN="ghp_aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890"

# R6: Slack token
SLACK_BOT="xoxb-secrettoken"

# R7: Generic credential literal
password="hunter2secret"
BADEOF

# ---------------------------------------------------------------------------
# Fixture: CLEAN — innocuous script with no findings
# ---------------------------------------------------------------------------

CLEAN_FIXTURE="$WORK/clean-fixture.sh"
cat > "$CLEAN_FIXTURE" <<'CLEANEOF'
#!/usr/bin/env bash
# This is a clean fixture for security-scan tests.
set -euo pipefail

greet() {
  local name="${1:-world}"
  echo "Hello, $name"
}

greet "$@"
CLEANEOF

# ---------------------------------------------------------------------------
# Test (a): BAD fixture → non-zero exit AND findings on stderr
# ---------------------------------------------------------------------------

SCANNER_RC=0
SCANNER_STDERR="$WORK/stderr-bad.txt"
SCANNER_STDOUT="$WORK/stdout-bad.txt"

bash "$SCANNER" "$BAD_FIXTURE" \
  >"$SCANNER_STDOUT" 2>"$SCANNER_STDERR" || SCANNER_RC=$?

if [[ "$SCANNER_RC" -ne 0 ]]; then
  pass "bad fixture: scanner exits non-zero ($SCANNER_RC)"
else
  fail "bad fixture: scanner should exit non-zero, got 0"
fi

if grep -q "SECURITY:" "$SCANNER_STDERR" 2>/dev/null; then
  pass "bad fixture: findings written to stderr"
else
  fail "bad fixture: no SECURITY: lines found on stderr"
fi

# Stdout should not contain SECURITY: lines (findings belong on stderr only).
if ! grep -q "SECURITY:" "$SCANNER_STDOUT" 2>/dev/null; then
  pass "fail-loud: SECURITY findings go to stderr, not stdout"
else
  fail "fail-loud: SECURITY findings leaked to stdout"
fi

# ---------------------------------------------------------------------------
# Test (b): CLEAN fixture → exit 0, no findings
# ---------------------------------------------------------------------------

CLEAN_RC=0
CLEAN_STDERR="$WORK/stderr-clean.txt"
CLEAN_STDOUT="$WORK/stdout-clean.txt"

bash "$SCANNER" "$CLEAN_FIXTURE" \
  >"$CLEAN_STDOUT" 2>"$CLEAN_STDERR" || CLEAN_RC=$?

if [[ "$CLEAN_RC" -eq 0 ]]; then
  pass "clean fixture: scanner exits 0"
else
  fail "clean fixture: scanner should exit 0, got $CLEAN_RC"
fi

if ! grep -q "SECURITY:" "$CLEAN_STDERR" 2>/dev/null; then
  pass "clean fixture: no false positives on stderr"
else
  fail "clean fixture: false positive findings emitted"
  cat "$CLEAN_STDERR" >&2
fi

# ---------------------------------------------------------------------------
# Test (c): fail-loud contract — individual pattern checks
# ---------------------------------------------------------------------------

check_pattern() {
  local label="$1" content="$2"
  local tmpf="$WORK/pattern-${label}.sh"
  printf '%s\n' "$content" > "$tmpf"
  local rc=0 stderr_out
  stderr_out="$(bash "$SCANNER" "$tmpf" 2>&1 >/dev/null)" || rc=$?
  if [[ "$rc" -ne 0 ]] && echo "$stderr_out" | grep -q "SECURITY:"; then
    pass "pattern[$label]: detected and flagged"
  else
    fail "pattern[$label]: not detected (rc=$rc)"
    echo "    stderr: $stderr_out" >&2
  fi
}

check_pattern "eval-var"         'eval "$MYVAR"'
check_pattern "eval-dollar"      'eval $MYVAR'
check_pattern "pipe-curl-sh"     'curl https://example.com/x.sh | sh'
check_pattern "pipe-wget-bash"   'wget -qO- http://x.io/go.sh | bash'
check_pattern "aws-key"          'export KEY=AKIAIOSFODNN7EXAMPLE'
check_pattern "pem-rsa"          '-----BEGIN RSA PRIVATE KEY-----'
check_pattern "pem-openssh"      '-----BEGIN OPENSSH PRIVATE KEY-----'
check_pattern "github-pat"       'TOKEN=ghp_aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890'
check_pattern "slack-bot"        'SLACK=xoxb-abc123'
check_pattern "cred-password"    'password="mysecretpass"'
check_pattern "cred-api-key"     'api_key=supersecretvalue'

# ---------------------------------------------------------------------------
# Test (d): clean patterns that must NOT fire (no false positives)
# ---------------------------------------------------------------------------

check_clean_pattern() {
  local label="$1" content="$2"
  local tmpf="$WORK/clean-pat-${label}.sh"
  printf '%s\n' "$content" > "$tmpf"
  local rc=0 stderr_out
  stderr_out="$(bash "$SCANNER" "$tmpf" 2>&1 >/dev/null)" || rc=$?
  if [[ "$rc" -eq 0 ]] && ! echo "$stderr_out" | grep -q "SECURITY:"; then
    pass "no-fp[$label]: correctly clean"
  else
    fail "no-fp[$label]: false positive (rc=$rc)"
    echo "    stderr: $stderr_out" >&2
  fi
}

# eval of a literal string (not a variable) — common in build scripts
check_clean_pattern "eval-literal"  'eval "set -x"'
# password variable with only a reference (not a literal value)
check_clean_pattern "password-ref"  'password="$ENV_PASSWORD"'
# api_key set from environment
check_clean_pattern "api-key-ref"   'api_key="${API_KEY}"'
# curl piped to grep — not a shell
check_clean_pattern "curl-pipe-grep" 'curl https://x.io/data | grep foo'

# ---------------------------------------------------------------------------
# Baseline (GH-64) — a pre-approved finding is still printed but doesn't fail the scan;
# --no-baseline bypasses it; a NON-baselined finding in the same file still fails.
# ---------------------------------------------------------------------------

BASE_DIR="$WORK/baseline-fixture"
mkdir -p "$BASE_DIR"
BASE_FIXTURE="$BASE_DIR/mixed.sh"
cat > "$BASE_FIXTURE" <<'MIXEDEOF'
#!/usr/bin/env bash
eval "$KNOWN_GOOD"
eval "$BRAND_NEW_ONE"
MIXEDEOF
BASE_FILE="$WORK/baseline.txt"
printf '# comment line, ignored\n\nmixed.sh\teval-unsanitized\teval "$KNOWN_GOOD"\n' > "$BASE_FILE"

RC=0
STDERR_BASE="$WORK/stderr-baseline.txt"
( cd "$BASE_DIR" && bash "$SCANNER" --baseline "$BASE_FILE" "mixed.sh" ) >/dev/null 2>"$STDERR_BASE" || RC=$?
[[ "$RC" -ne 0 ]] && pass "baseline: still exits non-zero when a non-baselined finding remains" \
  || fail "baseline: should still fail on the non-baselined line, got exit 0"
grep -q "SECURITY (baselined):.*KNOWN_GOOD" "$STDERR_BASE" 2>/dev/null \
  && pass "baseline: baselined finding is still PRINTED (not hidden)" \
  || fail "baseline: baselined finding missing from output — GUIDING-PRINCIPLES #8 violation risk"
grep -qE '^SECURITY: .*BRAND_NEW_ONE' "$STDERR_BASE" 2>/dev/null \
  && pass "baseline: non-baselined finding still reported as a plain SECURITY line" \
  || fail "baseline: non-baselined finding not reported: $(cat "$STDERR_BASE")"

# Baseline every line in the fixture → clean, exit 0.
printf '# comment\nmixed.sh\teval-unsanitized\teval "$KNOWN_GOOD"\nmixed.sh\teval-unsanitized\teval "$BRAND_NEW_ONE"\n' > "$BASE_FILE"
RC=0
( cd "$BASE_DIR" && bash "$SCANNER" --baseline "$BASE_FILE" "mixed.sh" ) >/dev/null 2>/dev/null || RC=$?
[[ "$RC" -eq 0 ]] && pass "baseline: fully-baselined fixture exits 0" || fail "baseline: expected exit 0, got $RC"

# --no-baseline bypasses the baseline file entirely, even when it would fully cover the fixture.
RC=0
STDERR_NOBASE="$WORK/stderr-nobaseline.txt"
( cd "$BASE_DIR" && bash "$SCANNER" --no-baseline --baseline "$BASE_FILE" "mixed.sh" ) >/dev/null 2>"$STDERR_NOBASE" || RC=$?
[[ "$RC" -ne 0 ]] && pass "baseline: --no-baseline ignores the baseline file (raw scan fails)" \
  || fail "baseline: --no-baseline should still fail raw, got exit 0"
! grep -q "baselined" "$STDERR_NOBASE" 2>/dev/null \
  && pass "baseline: --no-baseline output has no 'baselined' labels" \
  || fail "baseline: --no-baseline leaked a baselined label"

# --tsv emits `file\trule\ttext` — the format the baseline file itself uses, so a reviewer can
# paste a row straight in.
TSV_OUT="$(cd "$BASE_DIR" && bash "$SCANNER" --no-baseline --tsv "mixed.sh" 2>/dev/null || true)"
TSV_EXPECT="$(printf 'mixed.sh\teval-unsanitized\teval "$KNOWN_GOOD"')"
printf '%s\n' "$TSV_OUT" | grep -qF "$TSV_EXPECT" \
  && pass "baseline: --tsv emits tab-separated file/rule/text" \
  || fail "baseline: --tsv output malformed: $TSV_OUT"

# ---------------------------------------------------------------------------
# GH-64 active gate: the REAL repo, scanned with the checked-in baseline, must be clean. This is
# what turns the scanner from an advisory tool into a genuine blocking gate in validate.sh — any
# newly introduced eval/secret/curl-pipe pattern fails validate.sh until it's fixed or (after human
# review) added to relay-automation/hooks/security-scan-baseline.txt.
# ---------------------------------------------------------------------------

RC=0
REAL_OUT="$(bash "$SCANNER" 2>&1)" || RC=$?
[[ "$RC" -eq 0 ]] && pass "GH-64 active gate: the real repo tree is clean against the checked-in baseline" \
  || fail "GH-64 active gate: real repo has NON-baselined findings — fix them or review+add to the baseline: $REAL_OUT"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
echo "security-scan: $PASS pass, $FAIL fail"
[[ "$FAIL" -eq 0 ]]
