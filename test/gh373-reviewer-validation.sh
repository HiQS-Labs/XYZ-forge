#!/usr/bin/env bash
set -euo pipefail

# GH-373 — the legacy Bash fallback must advertise and validate only lanes it can dispatch.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRIVE="$ROOT/relay-automation/marathon-drive.sh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh373-reviewer.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
PASS=0
FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }

echo "== test: gh373-reviewer-validation =="

if bash -n "$DRIVE"; then
  pass "frozen fallback remains syntactically valid"
else
  fail "frozen fallback has a syntax error"
fi

help="$(XYZ_PYTHON=0 bash "$DRIVE" --help)"
if [[ "$help" != *gemini* && "$help" == *"codex' or 'agy'"* ]]; then
  pass "help advertises only dispatchable reviewer lanes"
else
  fail "help still advertises Gemini or omits the codex/agy contract"
fi

printf '# no-op phase brief\n' > "$WORK/brief.md"
set +e
out="$(XYZ_PYTHON=0 MARATHON_ROOT="$WORK" AIDER_BIN=/usr/bin/true \
  bash "$DRIVE" --phase-brief "$WORK/brief.md" --builder codex --reviewer aider --dry-run 2>&1)"
rc=$?
set -e
if [[ "$rc" -eq 2 && "$out" == *"reviewer 'aider' must start with codex/agy"* ]]; then
  pass "reviewer validation rejects a routed but non-QA lane with the live allowlist"
else
  fail "reviewer validation drifted (rc=$rc out=$out)"
fi

if rg -q 'GH-373' "$DRIVE" && ! rg -q 'gemini' "$DRIVE"; then
  pass "GH-373 marker sits on a Gemini-free fallback"
else
  fail "fallback still contains Gemini validation or lacks its GH-373 marker"
fi

echo "  gh373-reviewer-validation: $PASS pass, $FAIL fail"
[[ "$FAIL" -eq 0 ]]
