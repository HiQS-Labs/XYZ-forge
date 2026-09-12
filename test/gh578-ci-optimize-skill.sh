#!/usr/bin/env bash
# test/gh578-ci-optimize-skill.sh — GH-578: ci-optimize transferable CI/CD audit & optimization skill
source "$(dirname "$0")/_setup.sh" gh578-ci-optimize-skill

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_FILE="$REPO/skills/ci-optimize/SKILL.md"

echo "== test: gh578-ci-optimize-skill =="

# --- 1. File existence & basic structure ---
[ -f "$SKILL_FILE" ] && pass "skills/ci-optimize/SKILL.md exists" || fail "missing skills/ci-optimize/SKILL.md"

# --- 2. YAML frontmatter validation ---
grep -q "^name: ci-optimize$" "$SKILL_FILE" && pass "frontmatter has name: ci-optimize" || fail "missing name in frontmatter"
grep -q "description:" "$SKILL_FILE" && pass "frontmatter has description" || fail "missing description in frontmatter"

# --- 3. 12 Foundational Principles presence ---
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
  grep -q "### $i\." "$SKILL_FILE" && pass "Principle $i exists" || fail "missing Principle $i"
done

grep -q "Gate at the Push Boundary" "$SKILL_FILE" && pass "Principle 1 title match" || fail "missing Principle 1 content"
grep -q "Tier Tests by Subsystem" "$SKILL_FILE" && pass "Principle 2 title match" || fail "missing Principle 2 content"
grep -q "Run in Parallel" "$SKILL_FILE" && pass "Principle 3 title match" || fail "missing Principle 3 content"
grep -q "Never Attribute a Flake" "$SKILL_FILE" && pass "Principle 4 title match" || fail "missing Principle 4 content"
grep -q "Mutation-Heavy Suites Run in a Disposable Full Clone" "$SKILL_FILE" && pass "Principle 5 title match" || fail "missing Principle 5 content"
grep -q "Keep a Receipt with Every Gate Result" "$SKILL_FILE" && pass "Principle 6 title match" || fail "missing Principle 6 content"
grep -q "Every New Test Gets a Red Control" "$SKILL_FILE" && pass "Principle 7 title match" || fail "missing Principle 7 content"
grep -q "Test Seams are Explicit" "$SKILL_FILE" && pass "Principle 8 title match" || fail "missing Principle 8 content"
grep -q "Hosted CI Strategy" "$SKILL_FILE" && pass "Principle 9 title match" || fail "missing Principle 9 content"
grep -q "Guard Ported Components with Twin Freeze" "$SKILL_FILE" && pass "Principle 10 title match" || fail "missing Principle 10 content"
grep -q "Contention Has an Owner" "$SKILL_FILE" && pass "Principle 11 title match" || fail "missing Principle 11 content"
grep -q "Explicitly Disclose What the Gate/Reviewer Did Not Sweep" "$SKILL_FILE" && pass "Principle 12 title match" || fail "missing Principle 12 content"

# --- 4. Evidence-contract specifics ---
grep -q "show-ref" "$SKILL_FILE" && pass "Principle 5 includes git show-ref comparison" || fail "missing show-ref in Principle 5"
grep -q "20–25 runs each" "$SKILL_FILE" && pass "Principle 4 includes matched sample batches" || fail "missing matched batch sample in Principle 4"

# --- 5. Anti-Patterns section ---
grep -q "## Anti-Patterns: What to Skip" "$SKILL_FILE" && pass "Anti-patterns section exists" || fail "missing Anti-patterns section"

# --- 6. 4-Wave Roadmap & Scorecard ---
grep -q "## Phased Adoption Roadmap" "$SKILL_FILE" && pass "Phased Adoption Roadmap section exists" || fail "missing Roadmap section"
grep -q "Wave 1" "$SKILL_FILE" && pass "Wave 1 present" || fail "missing Wave 1"
grep -q "Wave 4" "$SKILL_FILE" && pass "Wave 4 present" || fail "missing Wave 4"
grep -q "## CI/CD Audit Scorecard & Rubric" "$SKILL_FILE" && pass "Scorecard section exists" || fail "missing Scorecard section"
grep -q "20–24 Points" "$SKILL_FILE" && pass "Scorecard assessment tiers exist" || fail "missing Scorecard assessment tiers"

# --- 7. Negative control mutation ---
TMP_COPY="$WORK/skill_mutated.md"
cp "$SKILL_FILE" "$TMP_COPY"
sed -i.bak '/### 5\./d' "$TMP_COPY"
grep -q "### 5\." "$TMP_COPY" && fail "negative control: mutation did not delete Principle 5" || pass "negative control: mutation successfully detected missing Principle 5"

echo "  gh578-ci-optimize-skill: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
