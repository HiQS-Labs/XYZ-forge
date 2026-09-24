#!/usr/bin/env bash
# gh784-marathon-qa-gate.sh — GH-784: marathon Wave QA receipt & checklist gate.
#
# Asserts that:
#   1. Every marathon plan doc carries '## Acceptance & Quality Checklist'.
#   2. All declared waves in the plan have a corresponding wave checklist section.
#   3. Each wave defines the 3 mandatory checklist items:
#      - Wave N Proof of Done Test Suite Green
#      - Wave N Post-Build Codex QA Relay executed (with receipt citation)
#      - Wave N CodeRabbit / Peer Review findings adjudicated
#   4. Checked Codex items MUST cite a concrete receipt path under relay-system/.
#   5. Checked items citing relay receipts verify the referenced file exists on disk.
#   6. Unexpanded placeholders in checked receipt paths are caught as errors.
#   7. --pre-pr (or promotion to 3-COMPLETED) requires all wave checklist items to be checked.
#   8. In-progress docs with unchecked items warn under observe mode, error under --pre-pr.
#   9. Non-marathon docs with generic checklists are skipped without false positives.
#  10. CLI integration via `pdda.sh marathon-qa` captures child errors and honors --pre-pr/--strict.
#  11. Falsifiable controls ensure checks fail when mutated.
source "$(dirname "$0")/_setup.sh" gh784-marathon-qa-gate
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
CHECKER="$REPO/utils/pdda/check_marathon_qa.py"
PDDA="$REPO/utils/pdda/pdda.sh"

[ -f "$CHECKER" ] || fail "A0: checker missing at $CHECKER"
[ -f "$PDDA" ] || fail "A0: pdda.sh missing at $PDDA"

FIXTURE_ROOT="$WORK/fixture-repo"
mkdir -p "$FIXTURE_ROOT/PROJECT/2-WORKING" \
         "$FIXTURE_ROOT/PROJECT/3-COMPLETED" \
         "$FIXTURE_ROOT/relay-system/2026-09-24"

# ── 1. Valid marathon plan with complete wave receipts on disk ──────────────
cat > "$FIXTURE_ROOT/relay-system/2026-09-24/wave1.codex.md" <<'EOF'
# Wave 1 Codex QA Receipt
Status: Approved
EOF
cat > "$FIXTURE_ROOT/relay-system/2026-09-24/wave2.codex.md" <<'EOF'
# Wave 2 Codex QA Receipt
Status: Approved
EOF

cat > "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-TEST.md" <<'EOF'
---
title: Test Marathon Plan
marathon_gid: M-TEST-001
doc_type: marathon
status: active
---

# Test Marathon

### Waves:
- Wave 1: Foundation
- Wave 2: Hardening

## Acceptance & Quality Checklist

### Wave 1
- [x] Wave 1 Proof of Done Test Suite Green (runnable command + test exit 0)
- [x] Wave 1 Post-Build Codex QA Relay executed (receipt recorded under `relay-system/2026-09-24/wave1.codex.md`)
- [x] Wave 1 CodeRabbit / Peer Review findings adjudicated

### Wave 2
- [x] Wave 2 Proof of Done Test Suite Green (runnable command + test exit 0)
- [x] Wave 2 Post-Build Codex QA Relay executed (receipt recorded under `relay-system/2026-09-24/wave2.codex.md`)
- [x] Wave 2 CodeRabbit / Peer Review findings adjudicated
EOF

out="$(python3 "$CHECKER" --root "$FIXTURE_ROOT" --pre-pr --doc "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-TEST.md" 2>&1)"
rc=$?
if [ $rc -eq 0 ] && ! echo "$out" | grep -q "ERROR"; then
  pass "1: Valid marathon plan with on-disk receipt passes --pre-pr cleanly"
else
  fail "1: Valid marathon plan failed: (rc=$rc) $out"
fi

# ── 1b. Missing wave checklist section (F1 blocker control) ──────────────────
cat > "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-OMITTED-WAVE.md" <<'EOF'
---
title: Plan With Omitted Wave
marathon_gid: M-TEST-001B
doc_type: marathon
status: active
---

# Plan With Omitted Wave

### Waves:
- Wave 1: Foundation
- Wave 2: Hardening

## Acceptance & Quality Checklist

### Wave 1
- [x] Wave 1 Proof of Done Test Suite Green (runnable command + test exit 0)
- [x] Wave 1 Post-Build Codex QA Relay executed (receipt recorded under `relay-system/2026-09-24/wave1.codex.md`)
- [x] Wave 1 CodeRabbit / Peer Review findings adjudicated
EOF

out="$(python3 "$CHECKER" --root "$FIXTURE_ROOT" --pre-pr --doc "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-OMITTED-WAVE.md" 2>&1)"
rc=$?
if [ $rc -ne 0 ] && echo "$out" | grep -q "Wave 2 declared in plan but missing its '### Wave 2' checklist section"; then
  pass "1b: Declared wave without checklist section is caught as error (F1)"
else
  fail "1b: Expected error on omitted Wave 2 checklist section, got rc=$rc: $out"
fi

# ── 2. Missing '## Acceptance & Quality Checklist' in marathon plan ──────────
cat > "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-NO-CHECKLIST.md" <<'EOF'
---
title: Marathon Without Checklist
marathon_gid: M-TEST-002
doc_type: marathon
status: active
---

# Marathon Without Checklist

### Waves:
- Wave 1: Core
EOF

out="$(python3 "$CHECKER" --root "$FIXTURE_ROOT" --pre-pr --doc "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-NO-CHECKLIST.md" 2>&1)"
rc=$?
if [ $rc -ne 0 ] && echo "$out" | grep -q "missing '## Acceptance & Quality Checklist' section"; then
  pass "2: Missing checklist section in marathon plan is flagged as error under --pre-pr"
else
  fail "2: Expected error on missing checklist section, got rc=$rc: $out"
fi

# ── 3. Missing mandatory wave item (missing Codex QA) ────────────────────────
cat > "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-INCOMPLETE-ITEMS.md" <<'EOF'
---
title: Incomplete Checklist Items
marathon_gid: M-TEST-003
doc_type: marathon
status: active
---

# Incomplete Checklist Items

## Acceptance & Quality Checklist

### Wave 1
- [x] Wave 1 Proof of Done Test Suite Green (runnable command + test exit 0)
- [x] Wave 1 CodeRabbit / Peer Review findings adjudicated
EOF

out="$(python3 "$CHECKER" --root "$FIXTURE_ROOT" --strict --doc "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-INCOMPLETE-ITEMS.md" 2>&1)"
rc=$?
if [ $rc -ne 0 ] && echo "$out" | grep -q "Wave 1 missing mandatory Post-Build Codex QA Relay checklist item"; then
  pass "3: Missing mandatory Post-Build Codex QA Relay checklist item is flagged as error"
else
  fail "3: Expected error on missing mandatory item, got rc=$rc: $out"
fi

# ── 3b. Checked Codex item with no receipt citation at all (F2 blocker control)
cat > "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-NO-RECEIPT-CITATION.md" <<'EOF'
---
title: No Receipt Citation
marathon_gid: M-TEST-003B
doc_type: marathon
status: active
---

# No Receipt Citation

## Acceptance & Quality Checklist

### Wave 1
- [x] Wave 1 Proof of Done Test Suite Green (runnable command + test exit 0)
- [x] Wave 1 Post-Build Codex QA Relay executed
- [x] Wave 1 CodeRabbit / Peer Review findings adjudicated
EOF

out="$(python3 "$CHECKER" --root "$FIXTURE_ROOT" --pre-pr --doc "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-NO-RECEIPT-CITATION.md" 2>&1)"
rc=$?
if [ $rc -ne 0 ] && echo "$out" | grep -q "Post-Build Codex QA Relay item missing receipt citation"; then
  pass "3b: Checked Codex item with no receipt citation is caught as error (F2)"
else
  fail "3b: Expected error on missing receipt citation, got rc=$rc: $out"
fi

# ── 4. Checked item with nonexistent transcript path ────────────────────────
cat > "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-MISSING-TRANSCRIPT.md" <<'EOF'
---
title: Missing Transcript
marathon_gid: M-TEST-004
doc_type: marathon
status: active
---

# Missing Transcript

## Acceptance & Quality Checklist

### Wave 1
- [x] Wave 1 Proof of Done Test Suite Green (runnable command + test exit 0)
- [x] Wave 1 Post-Build Codex QA Relay executed (receipt recorded under `relay-system/2026-09-24/does-not-exist.codex.md`)
- [x] Wave 1 CodeRabbit / Peer Review findings adjudicated
EOF

out="$(python3 "$CHECKER" --root "$FIXTURE_ROOT" --strict --doc "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-MISSING-TRANSCRIPT.md" 2>&1)"
rc=$?
if [ $rc -ne 0 ] && echo "$out" | grep -q "checked but transcript 'relay-system/2026-09-24/does-not-exist.codex.md' does not exist on disk"; then
  pass "4: Checked item with missing on-disk transcript is flagged as error"
else
  fail "4: Expected error on missing on-disk transcript, got rc=$rc: $out"
fi

# ── 5. Checked item with unexpanded placeholder in transcript path ──────────
cat > "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-PLACEHOLDER.md" <<'EOF'
---
title: Placeholder Transcript
marathon_gid: M-TEST-005
doc_type: marathon
status: active
---

# Placeholder Transcript

## Acceptance & Quality Checklist

### Wave 1
- [x] Wave 1 Proof of Done Test Suite Green (runnable command + test exit 0)
- [x] Wave 1 Post-Build Codex QA Relay executed (receipt recorded under `relay-system/<YYYY-MM-DD>/<label>.codex.md`)
- [x] Wave 1 CodeRabbit / Peer Review findings adjudicated
EOF

out="$(python3 "$CHECKER" --root "$FIXTURE_ROOT" --strict --doc "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-PLACEHOLDER.md" 2>&1)"
rc=$?
if [ $rc -ne 0 ] && echo "$out" | grep -q "checked but transcript path contains unexpanded placeholder"; then
  pass "5: Checked item with unexpanded placeholder transcript is flagged as error"
else
  fail "5: Expected error on unexpanded placeholder in transcript, got rc=$rc: $out"
fi

# ── 6. In-flight doc with unchecked items: warn in observe mode, error in --pre-pr
cat > "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-IN-FLIGHT.md" <<'EOF'
---
title: In Flight Marathon
marathon_gid: M-TEST-006
doc_type: marathon
status: active
---

# In Flight Marathon

## Acceptance & Quality Checklist

### Wave 1
- [ ] Wave 1 Proof of Done Test Suite Green (runnable command + test exit 0)
- [ ] Wave 1 Post-Build Codex QA Relay executed (receipt recorded under `relay-system/2026-09-24/wave1.codex.md`)
- [ ] Wave 1 CodeRabbit / Peer Review findings adjudicated
EOF

out_observe="$(python3 "$CHECKER" --root "$FIXTURE_ROOT" --mode observe --doc "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-IN-FLIGHT.md" 2>&1)"
rc_observe=$?
out_prepr="$(python3 "$CHECKER" --root "$FIXTURE_ROOT" --pre-pr --doc "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-IN-FLIGHT.md" 2>&1)"
rc_prepr=$?

if [ $rc_observe -eq 0 ] && echo "$out_observe" | grep -q "WARN \[pdda-check-marathon-qa\].*item pending verification"; then
  pass "6a: In-flight unchecked item emits WARN and exits 0 in observe mode"
else
  fail "6a: Expected observe mode WARN + exit 0, got rc=$rc_observe: $out_observe"
fi

if [ $rc_prepr -ne 0 ] && echo "$out_prepr" | grep -q "ERROR \[pdda-check-marathon-qa\].*cannot open PR or complete marathon without verified wave QA"; then
  pass "6b: In-flight unchecked item emits ERROR and exits non-zero under --pre-pr"
else
  fail "6b: Expected --pre-pr ERROR + exit 1, got rc=$rc_prepr: $out_prepr"
fi

# ── 7. Completed doc with unchecked items in 3-COMPLETED fails ──────────────
cat > "$FIXTURE_ROOT/PROJECT/3-COMPLETED/MARATHON-PLAN-UNVERIFIED-COMPLETED.md" <<'EOF'
---
title: Prematurely Completed Marathon
marathon_gid: M-TEST-007
doc_type: marathon
status: completed
---

# Prematurely Completed Marathon

## Acceptance & Quality Checklist

### Wave 1
- [ ] Wave 1 Proof of Done Test Suite Green (runnable command + test exit 0)
- [ ] Wave 1 Post-Build Codex QA Relay executed (receipt recorded under `relay-system/2026-09-24/wave1.codex.md`)
- [ ] Wave 1 CodeRabbit / Peer Review findings adjudicated
EOF

out="$(python3 "$CHECKER" --root "$FIXTURE_ROOT" --strict --doc "$FIXTURE_ROOT/PROJECT/3-COMPLETED/MARATHON-PLAN-UNVERIFIED-COMPLETED.md" 2>&1)"
rc=$?
if [ $rc -ne 0 ] && echo "$out" | grep -q "unverified item:.*cannot open PR or complete marathon"; then
  pass "7: Completed marathon doc with unchecked items in 3-COMPLETED fails"
else
  fail "7: Expected error on unverified completed marathon doc, got rc=$rc: $out"
fi

# ── 8. Non-marathon doc with generic checklist skipped (F4 control) ─────────
cat > "$FIXTURE_ROOT/PROJECT/3-COMPLETED/GH-999-SIMPLE-TASK.md" <<'EOF'
---
title: Simple Non-Marathon Task
doc_type: bugfix
status: completed
gh_issue: 999
---

# Simple Non-Marathon Task

## Acceptance & Quality Checklist
- [x] Unit checks pass
EOF

out="$(python3 "$CHECKER" --root "$FIXTURE_ROOT" --pre-pr --doc "$FIXTURE_ROOT/PROJECT/3-COMPLETED/GH-999-SIMPLE-TASK.md" 2>&1)"
rc=$?
if [ $rc -eq 0 ] && ! echo "$out" | grep -q "ERROR"; then
  pass "8: Non-marathon doc with generic checklist skipped without false positive (F4)"
else
  fail "8: Non-marathon task doc falsely failed: (rc=$rc) $out"
fi

# ── 9. CLI integration via pdda.sh marathon-qa (F3 dispatcher tests) ────────
# 9a: Valid doc passes cleanly
out="$(PDDA_REPO_ROOT="$FIXTURE_ROOT" bash "$PDDA" marathon-qa --root "$FIXTURE_ROOT" --doc "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-TEST.md" 2>&1)"
rc=$?
if [ $rc -eq 0 ] && echo "$out" | grep -q "SUMMARY \[pdda-check-marathon-qa\] errors=0"; then
  pass "9a: pdda.sh marathon-qa passes against valid marathon doc"
else
  fail "9a: pdda.sh marathon-qa failed: (rc=$rc) $out"
fi

# 9b: Missing doc under observe mode with --pre-pr MUST fail (F3)
out_observe_fail="$(PDDA_MODE=observe PDDA_REPO_ROOT="$FIXTURE_ROOT" bash "$PDDA" marathon-qa --root "$FIXTURE_ROOT" --pre-pr --doc "$FIXTURE_ROOT/nonexistent.md" 2>&1)"
rc_observe_fail=$?
if [ $rc_observe_fail -ne 0 ] && echo "$out_observe_fail" | grep -q "failed to read file"; then
  pass "9b: pdda.sh marathon-qa --pre-pr enforces error under observe mode (F3)"
else
  fail "9b: pdda.sh marathon-qa --pre-pr failed to enforce error: (rc=$rc_observe_fail) $out_observe_fail"
fi

# 9c: Unrecognized argument MUST fail with non-zero code (F3)
out_bad_flag="$(PDDA_MODE=full PDDA_REPO_ROOT="$FIXTURE_ROOT" bash "$PDDA" marathon-qa --invalid-test-flag 2>&1)"
rc_bad_flag=$?
if [ $rc_bad_flag -ne 0 ] && echo "$out_bad_flag" | grep -q "check_marathon_qa.py exited with error"; then
  pass "9c: pdda.sh marathon-qa propagates child argument errors (F3)"
else
  fail "9c: pdda.sh marathon-qa failed to catch invalid flag: (rc=$rc_bad_flag) $out_bad_flag"
fi

# 9d: Missing transcript propagates error under full mode
out_fail="$(PDDA_MODE=full PDDA_REPO_ROOT="$FIXTURE_ROOT" bash "$PDDA" marathon-qa --root "$FIXTURE_ROOT" --doc "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-MISSING-TRANSCRIPT.md" 2>&1)"
rc_fail=$?
if [ $rc_fail -ne 0 ] && echo "$out_fail" | grep -q "does not exist on disk"; then
  pass "9d: pdda.sh marathon-qa propagates missing transcript error and returns non-zero"
else
  fail "9d: pdda.sh marathon-qa failed to catch missing transcript: (rc=$rc_fail) $out_fail"
fi

# ── 10. Mutation test: falsify the receipt existence check ──────────────────
# Verify that deleting the on-disk receipt turns a previously passing check red
rm -f "$FIXTURE_ROOT/relay-system/2026-09-24/wave1.codex.md"
out_mutated="$(python3 "$CHECKER" --root "$FIXTURE_ROOT" --pre-pr --doc "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-TEST.md" 2>&1)"
rc_mutated=$?
if [ $rc_mutated -ne 0 ] && echo "$out_mutated" | grep -q "does not exist on disk"; then
  pass "10: Mutation control: removing on-disk receipt turns clean check red (falsifiable)"
else
  fail "10: Mutation control failed to turn red! rc=$rc_mutated: $out_mutated"
fi

echo "All gh784-marathon-qa-gate tests passed."
exit 0
