#!/usr/bin/env bash
# test/gh132-review-xyz-skill.sh — GH-132: formal /review-xyz skill and multi-model review harness
source "$(dirname "$0")/_setup.sh" gh132-review-xyz-skill

REPO="$(cd "$(dirname "$0")/.." && pwd)"
REVIEW_PY="$REPO/utils/py/review_xyz.py"
SKILL_DIR="$REPO/skills/review-xyz"

echo "== test: gh132-review-xyz-skill =="

# --- 1. Skill structure & Trinity compliance ---
[ -f "$SKILL_DIR/SKILL.md" ] && pass "SKILL.md exists" || fail "missing SKILL.md"
[ -f "$SKILL_DIR/PROJECT.md" ] && pass "PROJECT.md exists" || fail "missing PROJECT.md"
[ -x "$SKILL_DIR/install.sh" ] && pass "install.sh exists and is executable" || fail "missing install.sh"
[ -x "$SKILL_DIR/scripts/review_engine.py" ] && pass "review_engine.py exists and is executable" || fail "missing review_engine.py"

# --- 2. Dry-run prompt generation ---
DIFF_SAMPLE="$WORK/sample.patch"
cat > "$DIFF_SAMPLE" <<'EOF'
diff --git a/src/calc.py b/src/calc.py
index 1234567..89abcdef 100644
--- a/src/calc.py
+++ b/src/calc.py
@@ -10,3 +10,5 @@ def add(a, b):
+def divide(a, b):
+    return a / b
EOF

OUT_DRY="$(python3 "$REVIEW_PY" --diff-file "$DIFF_SAMPLE" --model "Qwen/Qwen3.8-Max" --dry-run 2>&1)"
echo "$OUT_DRY" | grep -q "Engine: commandcode" && pass "dry-run selects commandcode for Qwen 3.8-Max" || fail "failed engine selection (out: $OUT_DRY)"
echo "$OUT_DRY" | grep -q "Diff Size: 7 lines" && pass "dry-run accurately measures diff lines" || fail "failed diff measurement (out: $OUT_DRY)"

# --- 3. Mock Model Execution: Approved Verdict (Exit 0) ---
MOCK_APPROVED="$WORK/mock_approved.md"
cat > "$MOCK_APPROVED" <<'EOF'
# Code Review Summary
**Verdict:** Approved
**Confidence:** High

## Executive Summary
Clean, safe implementation. Verified that divide checks inputs.

## Graded Findings
- `[Pass]` `src/calc.py:10` division implementation is safe and pure.
- `[Nit]` `src/calc.py:11` could add docstring.

## Actionable Checklist
- [ ] Add docstring to `divide()` — `[Nit]` `src/calc.py:11`
EOF

OUT_APP="$(python3 "$REVIEW_PY" --diff-file "$DIFF_SAMPLE" --mock-response "$MOCK_APPROVED" 2>&1)"
RC_APP=$?
[ "$RC_APP" -eq 0 ] && pass "mock approved review exits 0" || fail "expected exit 0, got $RC_APP (out: $OUT_APP)"
echo "$OUT_APP" | grep -qE "Verdict:.*Approved" && pass "report outputs Approved verdict" || fail "missing verdict in report"
echo "$OUT_APP" | grep -q "🛑 \`\[Blocker\]\` | 0" && pass "report counts 0 blockers" || fail "wrong blocker count"
echo "$OUT_APP" | grep -q "💡 \`\[Nit\]\` | 1" && pass "report counts 1 nit" || fail "wrong nit count"

# --- 4. Mock Model Execution: Changes Requested (Exit 5) ---
MOCK_REJECTED="$WORK/mock_rejected.md"
cat > "$MOCK_REJECTED" <<'EOF'
# Code Review Summary
**Verdict:** Changes requested
**Confidence:** High

## Executive Summary
Found unhandled ZeroDivisionError in new function.

## Graded Findings
- `[Blocker]` `src/calc.py:11` unhandled ZeroDivisionError when `b == 0`.
- `[Should]` `test/calc_test.py:20` missing unit tests for `divide()`.

## Actionable Checklist
- [ ] Handle division by zero in `src/calc.py:11` — `[Blocker]`
- [ ] Add unit test in `test/calc_test.py:20` — `[Should]`
EOF

OUT_REJ="$(python3 "$REVIEW_PY" --diff-file "$DIFF_SAMPLE" --mock-response "$MOCK_REJECTED" 2>&1)"
RC_REJ=$?
[ "$RC_REJ" -eq 5 ] && pass "mock changes-requested review exits 5" || fail "expected exit 5, got $RC_REJ (out: $OUT_REJ)"
echo "$OUT_REJ" | grep -qE "Verdict:.*Changes requested" && pass "report outputs Changes requested verdict" || fail "missing verdict in report"
echo "$OUT_REJ" | grep -q "🛑 \`\[Blocker\]\` | 1" && pass "report counts 1 blocker" || fail "wrong blocker count"
echo "$OUT_REJ" | grep -q "⚠️ \`\[Should\]\` | 1" && pass "report counts 1 should" || fail "wrong should count"

# --- 5. Throwaway Worktree Isolation Guarantee ---
# Verify caller repo state is completely unmodified even if the review script runs
TEST_GIT="$WORK/test-repo"
mkdir -p "$TEST_GIT"
git -C "$TEST_GIT" init -b main >/dev/null 2>&1
git -C "$TEST_GIT" config user.name "Test User"
git -C "$TEST_GIT" config user.email "test@example.com"
echo "initial" > "$TEST_GIT/file.txt"
git -C "$TEST_GIT" add file.txt
git -C "$TEST_GIT" commit -m "init" >/dev/null 2>&1

echo "modified" > "$TEST_GIT/file.txt"
echo "untracked" > "$TEST_GIT/untracked.txt"

REVIEW_ROOT="$TEST_GIT" python3 "$REVIEW_PY" --base HEAD --mock-response "$MOCK_APPROVED" >/dev/null 2>&1
STATUS_AFTER="$(git -C "$TEST_GIT" status --porcelain)"

echo "$STATUS_AFTER" | grep -q " M file.txt" && pass "worktree isolation preserved modified tracked file" || fail "tracked file clobbered"
echo "$STATUS_AFTER" | grep -q "?? untracked.txt" && pass "worktree isolation preserved untracked file" || fail "untracked file clobbered"

# --- 6. Uncited Claims Warning & Strict Verification ---
MOCK_UNCITED="$WORK/mock_uncited.md"
cat > "$MOCK_UNCITED" <<'EOF'
# Code Review Summary
**Verdict:** Approved
Verified and confirmed with no issues found. LGTM.
EOF

OUT_UNCITED="$(python3 "$REVIEW_PY" --diff-file "$DIFF_SAMPLE" --mock-response "$MOCK_UNCITED" 2>&1)"
echo "$OUT_UNCITED" | grep -q "lacked verified file:line citations" && pass "uncited claim triggers warning banner" || fail "uncited claim did not trigger warning"

OUT_STRICT="$(python3 "$REVIEW_PY" --diff-file "$DIFF_SAMPLE" --mock-response "$MOCK_UNCITED" --strict-citations 2>&1)"
RC_STRICT=$?
[ "$RC_STRICT" -eq 5 ] && pass "strict citations downgrades approved uncited review to exit 5" || fail "expected exit 5 for strict uncited review, got $RC_STRICT"

echo "  gh132-review-xyz-skill: $PASS pass, $FAIL fail"
exit 0
