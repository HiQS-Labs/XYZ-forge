#!/usr/bin/env bash
# test/gh778-review-code-skill.sh — GH-778: review-code-xyz ground-truth review skill, plus the
# GH-1060 split: PR review moved to review-pr-xyz (claim validation first, report-only).
source "$(dirname "$0")/_setup.sh" gh778-review-code-skill

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$REPO/skills/2-daily/review-code-xyz"
SKILL_FILE="$SKILL_DIR/SKILL.md"
INSTALLER="$SKILL_DIR/install.sh"
ARCH_FILE="$REPO/ARCHITECTURE.md"

echo "== test: gh778-review-code-skill =="

# --- 1. File existence & basic structure ---
[ -f "$SKILL_FILE" ] && pass "skills/2-daily/review-code-xyz/SKILL.md exists" || fail "missing SKILL.md"
[ -f "$INSTALLER" ] && pass "skills/2-daily/review-code-xyz/install.sh exists" || fail "missing install.sh"
[ -x "$INSTALLER" ] && pass "install.sh is executable" || fail "install.sh is not executable"
[ ! -e "$REPO/skills/2-daily/review-code" ] && pass "old review-code folder is gone (GH-1060)" || fail "old review-code folder still present"

# --- 2. YAML frontmatter validation ---
grep -q "^name: review-code-xyz$" "$SKILL_FILE" && pass "frontmatter has name: review-code-xyz" || fail "missing name in frontmatter"
grep -q "description:" "$SKILL_FILE" && pass "frontmatter has description" || fail "missing description in frontmatter"

# --- 3. Recital and Core Discipline Presence ---
grep -q "Review-Code Discipline:" "$SKILL_FILE" && pass "recital block present" || fail "missing recital block"
grep -q "/recon" "$SKILL_FILE" && pass "/recon integrated" || fail "missing /recon reference"
grep -q "/debug-mantra" "$SKILL_FILE" && pass "/debug-mantra integrated" || fail "missing /debug-mantra reference"
grep -q "/workhorse" "$SKILL_FILE" && pass "/workhorse integrated" || fail "missing /workhorse reference"
grep -q "/unstuck" "$SKILL_FILE" && pass "/unstuck integrated" || fail "missing /unstuck reference"
grep -q "hand off to \[\`review-pr-xyz\`\]" "$SKILL_FILE" && pass "PR targets hand off to review-pr-xyz" || fail "missing review-pr-xyz handoff"

# --- 4. Quality gates & anti-patterns ---
grep -q "A check that cannot fail is not a check" "$SKILL_FILE" && pass "mutation check rule present" || fail "missing mutation check rule"
grep -q "An empty input passes every check" "$SKILL_FILE" && pass "empty input guard rule present" || fail "missing empty input guard rule"
grep -q "Symptom-Fix Trap" "$SKILL_FILE" && pass "symptom-fix trap audit present" || fail "missing symptom-fix trap"
grep -q "Reversibility Decision Matrix" "$SKILL_FILE" && pass "reversibility matrix present" || fail "missing reversibility matrix"
PR_SKILL_FILE="$REPO/skills/2-daily/review-pr-xyz/SKILL.md"
GH1587_REVIEW_CODE_PINS=(
  "TOCTOU interleaving"
  "sibling-endpoint guard parity"
  "warm-state deploy, IAM, and service-account upgrade transitions"
  "native framework/runtime capabilities"
  "Bounded Mutation Scope (3–5 high-leverage mutations)"
  "Test-Honesty Body Audit"
  "Historical-Invariant Test-Inversion Check"
  "multi-invocation resume-key stability"
)
check_gh1587_review_code_pins() {
  local f="$1" pin
  for pin in "${GH1587_REVIEW_CODE_PINS[@]}"; do
    grep -qF -- "$pin" "$f" || return 1
  done
  return 0
}
check_gh1587_review_pr_pins() {
  local f="$1"
  grep -qF -- "Test-invariance / historical-invariant claim" "$f"
}
for gh1587_pin in "${GH1587_REVIEW_CODE_PINS[@]}"; do
  grep -qF -- "$gh1587_pin" "$SKILL_FILE" \
    && pass "GH-1587 pin present in review-code-xyz: $gh1587_pin" \
    || fail "GH-1587 pin missing in review-code-xyz: $gh1587_pin"
done
check_gh1587_review_code_pins "$SKILL_FILE" \
  && pass "GH-1587 contract checker passes on review-code-xyz" \
  || fail "GH-1587 contract checker failed on review-code-xyz"
check_gh1587_review_pr_pins "$PR_SKILL_FILE" \
  && pass "GH-1587 pin present in review-pr-xyz: Test-invariance / historical-invariant claim" \
  || fail "GH-1587 pin missing in review-pr-xyz: Test-invariance / historical-invariant claim"

# --- 5. Finding categories ---
for cat in "\[Blocker\]" "\[Should\]" "\[Nit\]" "\[Pass\]"; do
  grep -q "$cat" "$SKILL_FILE" && pass "finding category $cat present" || fail "missing category $cat"
done

# --- 6. ARCHITECTURE.md registration ---
grep -q "\[review-code-xyz\](skills/2-daily/review-code-xyz/SKILL.md)" "$ARCH_FILE" && pass "ARCHITECTURE.md has review-code-xyz link" || fail "missing ARCHITECTURE.md link"
n_daily="$(find "$REPO/skills/2-daily" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
# GH-1266 (366e492a7) dropped manual counts from tier headings; verify heading + table row parity against disk.
n_arch_daily="$(grep -cE "\]\(skills/2-daily/[^)]+/SKILL\.md\)" "$ARCH_FILE" || true)"
grep -q "### \`2-daily\` — A few times a day" "$ARCH_FILE" && [ "$n_arch_daily" -eq "$n_daily" ] && pass "ARCHITECTURE.md 2-daily count matches disk ($n_daily)" || fail "2-daily count does not match disk (arch=$n_arch_daily disk=$n_daily)"

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
for gh1587_pin in "${GH1587_REVIEW_CODE_PINS[@]}"; do
  cp "$SKILL_FILE" "$WORK/skill_gh1587_mut.md"
  python3 - "$WORK/skill_gh1587_mut.md" "$gh1587_pin" <<'PYMUT'
import sys, pathlib
p = pathlib.Path(sys.argv[1])
p.write_text(p.read_text().replace(sys.argv[2], ""))
PYMUT
  if cmp -s "$SKILL_FILE" "$WORK/skill_gh1587_mut.md"; then
    fail "negative control: mutation made no change for $gh1587_pin"
  elif check_gh1587_review_code_pins "$WORK/skill_gh1587_mut.md"; then
    fail "negative control: contract checker passed despite removing $gh1587_pin"
  else
    pass "negative control: contract checker rejected removal of $gh1587_pin"
  fi
done
cp "$PR_SKILL_FILE" "$WORK/pr_gh1587_mut.md"
sed -i.bak '/Test-invariance \/ historical-invariant claim/d' "$WORK/pr_gh1587_mut.md"
if cmp -s "$PR_SKILL_FILE" "$WORK/pr_gh1587_mut.md"; then
  fail "negative control: mutation made no change for review-pr-xyz test-invariance row"
elif check_gh1587_review_pr_pins "$WORK/pr_gh1587_mut.md"; then
  fail "negative control: contract checker passed despite removing review-pr-xyz test-invariance row"
else
  pass "negative control: contract checker rejected removal of review-pr-xyz test-invariance row"
fi

echo "  gh778-review-code-skill: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
