#!/usr/bin/env bash
# test/gh778-review-code-skill.sh — GH-778: review-code-xyz ground-truth review skill, plus the
# GH-1060 split: PR review moved to review-pr-xyz (claim validation first, report-only).
source "$(dirname "$0")/_setup.sh" gh778-review-code-skill

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$REPO/skills/2-daily/review-code-xyz"
SKILL_FILE="$SKILL_DIR/SKILL.md"
INSTALLER="$SKILL_DIR/install.sh"
PR_DIR="$REPO/skills/2-daily/review-pr-xyz"
PR_FILE="$PR_DIR/SKILL.md"
ARCH_FILE="$REPO/ARCHITECTURE.md"

echo "== test: gh778-review-code-skill =="

# --- 1. File existence & basic structure ---
[ -f "$SKILL_FILE" ] && pass "skills/2-daily/review-code-xyz/SKILL.md exists" || fail "missing SKILL.md"
[ -f "$INSTALLER" ] && pass "skills/2-daily/review-code-xyz/install.sh exists" || fail "missing install.sh"
[ -x "$INSTALLER" ] && pass "install.sh is executable" || fail "install.sh is not executable"
[ ! -e "$REPO/skills/2-daily/review-code" ] && pass "old review-code folder is gone (GH-1060)" || fail "old review-code folder still present"
[ -f "$PR_FILE" ] && [ -x "$PR_DIR/install.sh" ] && pass "review-pr-xyz SKILL.md + executable install.sh exist" || fail "review-pr-xyz incomplete"

# --- 2. YAML frontmatter validation ---
grep -q "^name: review-code-xyz$" "$SKILL_FILE" && pass "frontmatter has name: review-code-xyz" || fail "missing name in frontmatter"
grep -q "^name: review-pr-xyz$" "$PR_FILE" && pass "frontmatter has name: review-pr-xyz" || fail "missing review-pr-xyz name"
grep -q "description:" "$SKILL_FILE" && pass "frontmatter has description" || fail "missing description in frontmatter"

# --- 3. Recital and Core Discipline Presence ---
grep -q "Review-Code Discipline:" "$SKILL_FILE" && pass "recital block present" || fail "missing recital block"
grep -q "/recon" "$SKILL_FILE" && pass "/recon integrated" || fail "missing /recon reference"
grep -q "/debug-mantra" "$SKILL_FILE" && pass "/debug-mantra integrated" || fail "missing /debug-mantra reference"
grep -q "/workhorse" "$SKILL_FILE" && pass "/workhorse integrated" || fail "missing /workhorse reference"
grep -q "/unstuck" "$SKILL_FILE" && pass "/unstuck integrated" || fail "missing /unstuck reference"
grep -q "hand off to \[\`review-pr-xyz\`\]" "$SKILL_FILE" && pass "PR targets hand off to review-pr-xyz" || fail "missing review-pr-xyz handoff"
grep -q -- "--pr <PR#>" "$SKILL_FILE" && fail "review-code-xyz still advertises --pr mode" || pass "review-code-xyz has no --pr mode"

# --- 3b. review-pr-xyz: claims before code, report-only ---
grep -q "Review-PR Discipline:" "$PR_FILE" && pass "review-pr-xyz recital present" || fail "missing review-pr-xyz recital"
grep -q "## Phase 1: Claim Validation" "$PR_FILE" && pass "claim validation phase present" || fail "missing claim validation phase"
grep -q "Early exit:" "$PR_FILE" && pass "invalid core claim exits early" || fail "missing early exit"
grep -q "Never commit to, push to" "$PR_FILE" && pass "report-only rail present" || fail "missing report-only rail"
grep -q "/workhorse\|/unstuck" "$PR_FILE" && fail "review-pr-xyz pulls in the fix loop" || pass "review-pr-xyz has no workhorse/unstuck fix loop"

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
grep -q "\[review-code-xyz\](skills/2-daily/review-code-xyz/SKILL.md)" "$ARCH_FILE" && pass "ARCHITECTURE.md has review-code-xyz link" || fail "missing ARCHITECTURE.md link"
grep -q "\[review-pr-xyz\](skills/2-daily/review-pr-xyz/SKILL.md)" "$ARCH_FILE" && pass "ARCHITECTURE.md has review-pr-xyz link" || fail "missing review-pr-xyz ARCHITECTURE.md link"
n_daily="$(find "$REPO/skills/2-daily" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
grep -q "### \`2-daily\` — A few times a day ($n_daily)" "$ARCH_FILE" && pass "ARCHITECTURE.md 2-daily count matches disk ($n_daily)" || fail "2-daily count does not match disk ($n_daily)"

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
ln -s "$FOREIGN" "$A/claude/review-code-xyz"
set +e
run_installer >"$WORK/out-foreign" 2>&1
rc_for=$?
set -e
[ "$rc_for" -ne 0 ] && [ "$(readlink "$A/claude/review-code-xyz")" = "$FOREIGN" ] && pass "installer refuses live foreign link" || fail "installer replaced live foreign link"

rm -f "$A/claude/review-code-xyz"
ln -s "$WORK/nowhere/review-code-xyz" "$A/claude/review-code-xyz"
run_installer >"$WORK/out-dangling" 2>&1
rc_dan=$?
[ "$rc_dan" -eq 0 ] && [ "$(readlink "$A/claude/review-code-xyz")" -ef "$SKILL_DIR" ] && pass "installer replaces dangling link" || fail "installer failed to replace dangling link"

# --- 8. Negative control mutation (falsification) ---
TMP_COPY="$WORK/skill_mutated.md"
cp "$SKILL_FILE" "$TMP_COPY"
sed -i.bak '/Review-Code Discipline:/d' "$TMP_COPY"
grep -q "Review-Code Discipline:" "$TMP_COPY" && fail "negative control: mutation failed to delete recital" || pass "negative control: mutation successfully detected missing recital"

echo "  gh778-review-code-skill: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
