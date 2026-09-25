#!/usr/bin/env bash
# test/gh798-status-skill.sh — GH-798: status skill and review-code DRY / helper audit
source "$(dirname "$0")/_setup.sh" gh798-status-skill

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$REPO/skills/2-daily/status"
SKILL_FILE="$SKILL_DIR/SKILL.md"
INSTALLER="$SKILL_DIR/install.sh"
REVIEW_CODE_FILE="$REPO/skills/2-daily/review-code/SKILL.md"
ARCH_FILE="$REPO/ARCHITECTURE.md"

echo "== test: gh798-status-skill =="

# --- 1. File existence & basic structure ---
[ -f "$SKILL_FILE" ] && pass "skills/2-daily/status/SKILL.md exists" || fail "missing status/SKILL.md"
[ -f "$INSTALLER" ] && pass "skills/2-daily/status/install.sh exists" || fail "missing status/install.sh"
[ -x "$INSTALLER" ] && pass "install.sh is executable" || fail "status/install.sh is not executable"

# --- 2. YAML frontmatter validation ---
grep -q "^name: status$" "$SKILL_FILE" && pass "frontmatter has name: status" || fail "missing name in frontmatter"
grep -q "description:" "$SKILL_FILE" && pass "frontmatter has description" || fail "missing description in frontmatter"

# --- 3. Recital and Core Discipline Presence ---
grep -q "Status Discipline:" "$SKILL_FILE" && pass "recital block present" || fail "missing recital block"
grep -q "/recon" "$SKILL_FILE" && pass "/recon integrated" || fail "missing /recon reference"
grep -q "/debug-mantra" "$SKILL_FILE" && pass "/debug-mantra integrated" || fail "missing /debug-mantra reference"
grep -q "/merge-cleanup" "$SKILL_FILE" && pass "/merge-cleanup integrated" || fail "missing /merge-cleanup reference"

# --- 4. Quality gates & multi-checkout rules ---
grep -q "A doc is a hypothesis-zero claim, never evidence" "$SKILL_FILE" && pass "hypothesis-zero doc rule present" || fail "missing hypothesis-zero rule"
grep -q "The local checkout is not the only checkout" "$SKILL_FILE" && pass "multi-checkout discovery rule present" || fail "missing multi-checkout rule"
grep -q "Ground Truth vs. Documentation Gap Matrix" "$SKILL_FILE" && pass "gap matrix schema present" || fail "missing gap matrix schema"

# --- 5. Review-code DRY and centralized helper audit ---
grep -q "Lane E. Centralized Helpers & DRY" "$REVIEW_CODE_FILE" && pass "review-code has Lane E DRY" || fail "missing Lane E in review-code"
grep -q "Centralized Helper Adherence" "$REVIEW_CODE_FILE" && pass "review-code has helper adherence check" || fail "missing helper adherence check"
grep -q "Parallel Subsystem / Reinvention Trap" "$REVIEW_CODE_FILE" && pass "review-code has parallel subsystem trap" || fail "missing parallel subsystem trap"

# --- 6. ARCHITECTURE.md registration ---
grep -q "\[status\](skills/2-daily/status/SKILL.md)" "$ARCH_FILE" && pass "ARCHITECTURE.md has status link" || fail "missing ARCHITECTURE.md link"
grep -q "### \`2-daily\` — A few times a day (16)" "$ARCH_FILE" && pass "ARCHITECTURE.md has updated 2-daily count (16)" || fail "missing updated 2-daily count"

# --- 7. Installer gh678 compliance (in sandbox) ---
H="$WORK/home"; A="$H/apps"
mkdir -p "$A/claude" "$A/codex" "$A/gemcfg" "$A/antigrav" "$A/antigravcli" "$A/agents"
run_installer() {
  HOME="$H" CLAUDE_SKILLS_DIR="$A/claude" CODEX_SKILLS_DIR="$A/codex" \
  GEMINI_CONFIG_SKILLS_DIR="$A/gemcfg" ANTIGRAVITY_SKILLS_DIR="$A/antigrav" \
  ANTIGRAVITY_CLI_SKILLS_DIR="$A/antigravcli" AGENTS_SKILLS_DIR="$A/agents" \
  bash "$INSTALLER"
}

FOREIGN="$WORK/foreign"; mkdir -p "$FOREIGN"; echo "foreign" > "$FOREIGN/SKILL.md"
ln -s "$FOREIGN" "$A/claude/status"
set +e
run_installer >"$WORK/out-foreign" 2>&1
rc_for=$?
set -e
[ "$rc_for" -ne 0 ] && [ "$(readlink "$A/claude/status")" = "$FOREIGN" ] && pass "installer refuses live foreign link" || fail "installer replaced live foreign link"

rm -f "$A/claude/status"
ln -s "$WORK/nowhere/status" "$A/claude/status"
run_installer >"$WORK/out-dangling" 2>&1
rc_dan=$?
[ "$rc_dan" -eq 0 ] && [ "$(readlink "$A/claude/status")" -ef "$SKILL_DIR" ] && pass "installer replaces dangling link" || fail "installer failed to replace dangling link"

# --- 8. Negative control mutation (falsification) ---
# 8a: Recital deletion on status/SKILL.md must fail recital check
TMP_COPY="$WORK/skill_mutated.md"
cp "$SKILL_FILE" "$TMP_COPY"
sed -i.bak '/Status Discipline:/d' "$TMP_COPY"
grep -q "Status Discipline:" "$TMP_COPY" && fail "negative control 8a: mutation failed to delete recital" || pass "negative control 8a: mutation successfully detected missing recital"

# 8b: Lane E deletion on review-code/SKILL.md must fail Lane E check
TMP_REV="$WORK/review_code_mutated.md"
cp "$REVIEW_CODE_FILE" "$TMP_REV"
sed -i.bak '/Lane E. Centralized Helpers & DRY/d' "$TMP_REV"
grep -q "Lane E. Centralized Helpers & DRY" "$TMP_REV" && fail "negative control 8b: mutation failed to delete Lane E" || pass "negative control 8b: mutation successfully detected missing Lane E"

echo "  gh798-status-skill: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
