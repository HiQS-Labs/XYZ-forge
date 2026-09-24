#!/usr/bin/env bash
# test/gh778-review-code-skill.sh — GH-778: review-code and review-PR ground-truth review skill
source "$(dirname "$0")/_setup.sh" gh778-review-code-skill

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$REPO/skills/2-daily/review-code"
SKILL_FILE="$SKILL_DIR/SKILL.md"
INSTALLER="$SKILL_DIR/install.sh"
ARCH_FILE="$REPO/ARCHITECTURE.md"

echo "== test: gh778-review-code-skill =="

# --- 1. File existence & basic structure ---
[ -f "$SKILL_FILE" ] && pass "skills/2-daily/review-code/SKILL.md exists" || fail "missing SKILL.md"
[ -f "$INSTALLER" ] && pass "skills/2-daily/review-code/install.sh exists" || fail "missing install.sh"
[ -x "$INSTALLER" ] && pass "install.sh is executable" || fail "install.sh is not executable"

# --- 2. YAML frontmatter validation ---
grep -q "^name: review-code$" "$SKILL_FILE" && pass "frontmatter has name: review-code" || fail "missing name in frontmatter"
grep -q "description:" "$SKILL_FILE" && pass "frontmatter has description" || fail "missing description in frontmatter"

# --- 3. Recital and Core Discipline Presence ---
grep -q "Review-Code Discipline:" "$SKILL_FILE" && pass "recital block present" || fail "missing recital block"
grep -q "/recon" "$SKILL_FILE" && pass "/recon integrated" || fail "missing /recon reference"
grep -q "/debug-mantra" "$SKILL_FILE" && pass "/debug-mantra integrated" || fail "missing /debug-mantra reference"
grep -q "/workhorse" "$SKILL_FILE" && pass "/workhorse integrated" || fail "missing /workhorse reference"
grep -q "/unstuck" "$SKILL_FILE" && pass "/unstuck integrated" || fail "missing /unstuck reference"
grep -q "review-PR" "$SKILL_FILE" && pass "review-PR target mode present" || fail "missing review-PR reference"

# --- 4. Quality gates & anti-patterns ---
grep -q "A check that cannot fail is not a check" "$SKILL_FILE" && pass "mutation check rule present" || fail "missing mutation check rule"
grep -q "An empty input passes every check" "$SKILL_FILE" && pass "empty input guard rule present" || fail "missing empty input guard rule"
grep -q "Symptom-Fix Trap" "$SKILL_FILE" && pass "symptom-fix trap audit present" || fail "missing symptom-fix trap"
grep -q "Reversibility Decision Matrix" "$SKILL_FILE" && pass "reversibility matrix present" || fail "missing reversibility matrix"

# --- 5. Finding categories ---
for cat in "\[Blocker\]" "\[Should\]" "\[Nit\]" "\[Pass\]"; do
  grep -q "$cat" "$SKILL_FILE" && pass "finding category $cat present" || fail "missing category $cat"
done

# --- 6. ARCHITECTURE.md registration ---
grep -q "\[review-code\](skills/2-daily/review-code/SKILL.md)" "$ARCH_FILE" && pass "ARCHITECTURE.md has review-code link" || fail "missing ARCHITECTURE.md link"
grep -q "### \`2-daily\` — A few times a day (15)" "$ARCH_FILE" && pass "ARCHITECTURE.md has updated 2-daily count (15)" || fail "missing updated 2-daily count"

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
ln -s "$FOREIGN" "$A/claude/review-code"
set +e
run_installer >"$WORK/out-foreign" 2>&1
rc_for=$?
set -e
[ "$rc_for" -ne 0 ] && [ "$(readlink "$A/claude/review-code")" = "$FOREIGN" ] && pass "installer refuses live foreign link" || fail "installer replaced live foreign link"

rm -f "$A/claude/review-code"
ln -s "$WORK/nowhere/review-code" "$A/claude/review-code"
run_installer >"$WORK/out-dangling" 2>&1
rc_dan=$?
[ "$rc_dan" -eq 0 ] && [ "$(readlink "$A/claude/review-code")" -ef "$SKILL_DIR" ] && pass "installer replaces dangling link" || fail "installer failed to replace dangling link"

# --- 8. Negative control mutation (falsification) ---
TMP_COPY="$WORK/skill_mutated.md"
cp "$SKILL_FILE" "$TMP_COPY"
sed -i.bak '/Review-Code Discipline:/d' "$TMP_COPY"
grep -q "Review-Code Discipline:" "$TMP_COPY" && fail "negative control: mutation failed to delete recital" || pass "negative control: mutation successfully detected missing recital"

echo "  gh778-review-code-skill: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
