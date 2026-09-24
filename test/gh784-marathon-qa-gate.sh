#!/usr/bin/env bash
# gh784-marathon-qa-gate.sh — GH-784: marathon Wave QA receipt & checklist gate.
#
# Asserts that:
#   1. Every marathon plan doc carries '## Acceptance & Quality Checklist'.
#   2. Each wave defines the 3 mandatory checklist items:
#      - Wave N Proof of Done Test Suite Green
#      - Wave N Post-Build Codex QA Relay executed (receipt recorded under relay-system/...)
#      - Wave N CodeRabbit / Peer Review findings adjudicated
#   3. Checked items citing relay receipts verify the referenced file exists on disk.
#   4. Unexpanded placeholders in checked receipt paths are caught as errors.
#   5. --pre-pr (or promotion to 3-COMPLETED) requires all wave checklist items to be checked.
#   6. In-progress docs with unchecked items warn under observe mode, error under --pre-pr.
#   7. Non-marathon completed task docs are skipped without false positives.
#   8. CLI integration via `pdda.sh marathon-qa` correctly propagates findings and exit codes.
#   9. Falsifiable controls ensure checks fail when mutated.
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

# ── 1. Valid marathon plan with wave receipts on disk ───────────────────────
cat > "$FIXTURE_ROOT/relay-system/2026-09-24/wave1.codex.md" <<'EOF'
# Wave 1 Codex QA Receipt
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
EOF

out="$(python3 "$CHECKER" --root "$FIXTURE_ROOT" --pre-pr --doc "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-TEST.md" 2>&1)"
rc=$?
if [ $rc -eq 0 ] && ! echo "$out" | grep -q "ERROR"; then
  pass "1: Valid marathon plan with on-disk receipt passes --pre-pr cleanly"
else
  fail "1: Valid marathon plan failed: (rc=$rc) $out"
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

# ── 8. Non-marathon completed task doc in 3-COMPLETED skipped without false positive
cat > "$FIXTURE_ROOT/PROJECT/3-COMPLETED/GH-999-SIMPLE-TASK.md" <<'EOF'
---
title: Simple Non-Marathon Task
status: completed
gh_issue: 999
---

# Simple Non-Marathon Task
This is a standard single-issue task doc, not a marathon.
EOF

out="$(python3 "$CHECKER" --root "$FIXTURE_ROOT" --strict --doc "$FIXTURE_ROOT/PROJECT/3-COMPLETED/GH-999-SIMPLE-TASK.md" 2>&1)"
rc=$?
if [ $rc -eq 0 ] && ! echo "$out" | grep -q "ERROR"; then
  pass "8: Non-marathon completed doc in 3-COMPLETED skipped without false positive"
else
  fail "8: Non-marathon task doc falsely failed: (rc=$rc) $out"
fi

# ── 9. CLI integration via pdda.sh marathon-qa ──────────────────────────────
out="$(PDDA_REPO_ROOT="$FIXTURE_ROOT" bash "$PDDA" marathon-qa --root "$FIXTURE_ROOT" --doc "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-TEST.md" 2>&1)"
rc=$?
if [ $rc -eq 0 ] && echo "$out" | grep -q "SUMMARY \[pdda-check-marathon-qa\] errors=0"; then
  pass "9: pdda.sh marathon-qa CLI subcommand passes against valid marathon doc"
else
  fail "9: pdda.sh marathon-qa CLI subcommand failed: (rc=$rc) $out"
fi

out_fail="$(PDDA_MODE=full PDDA_REPO_ROOT="$FIXTURE_ROOT" bash "$PDDA" marathon-qa --root "$FIXTURE_ROOT" --doc "$FIXTURE_ROOT/PROJECT/2-WORKING/MARATHON-PLAN-MISSING-TRANSCRIPT.md" 2>&1)"
rc_fail=$?
if [ $rc_fail -ne 0 ] && echo "$out_fail" | grep -q "does not exist on disk"; then
  pass "9b: pdda.sh marathon-qa CLI propagates errors and returns non-zero"
else
  fail "9b: pdda.sh marathon-qa CLI failed to catch error: (rc=$rc_fail) $out_fail"
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
