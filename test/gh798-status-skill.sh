#!/usr/bin/env bash
# test/gh798-status-skill.sh — GH-798: status skill and review-code DRY / helper audit
source "$(dirname "$0")/_setup.sh" gh798-status-skill

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$REPO/skills/2-daily/where-are-we-at"
SKILL_FILE="$SKILL_DIR/SKILL.md"
INSTALLER="$SKILL_DIR/install.sh"
REVIEW_CODE_FILE="$REPO/skills/2-daily/review-code/SKILL.md"
ARCH_FILE="$REPO/ARCHITECTURE.md"

echo "== test: gh798-status-skill =="

# --- 1. File existence & basic structure ---
[ -f "$SKILL_FILE" ] && pass "skills/2-daily/where-are-we-at/SKILL.md exists" || fail "missing where-are-we-at/SKILL.md"
[ -f "$INSTALLER" ] && pass "skills/2-daily/where-are-we-at/install.sh exists" || fail "missing where-are-we-at/install.sh"
[ -x "$INSTALLER" ] && pass "install.sh is executable" || fail "where-are-we-at/install.sh is not executable"

# --- 2. YAML frontmatter validation ---
grep -q "^name: where-are-we-at$" "$SKILL_FILE" && pass "frontmatter has name: where-are-we-at" || fail "missing name in frontmatter"
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

# Lane E subsections must explicitly bind required severities:
grep -q 'is a `\[Blocker\]`' <<<"$(awk '/1\. \*\*Centralized Helper Adherence:\*\*/,/2\. \*\*Parallel Subsystem/' "$REVIEW_CODE_FILE")" && pass "Lane E helper adherence binds to [Blocker]" || fail "Lane E helper adherence not bound to [Blocker]"
grep -q 'mandatory `\[Blocker\]`' <<<"$(awk '/2\. \*\*Parallel Subsystem \/ Reinvention Trap:\*\*/,/3\. \*\*Intra-Diff/' "$REVIEW_CODE_FILE")" && pass "Lane E parallel subsystem binds to [Blocker]" || fail "Lane E parallel subsystem not bound to [Blocker]"
grep -q 'is a `\[Should\]`' <<<"$(awk '/3\. \*\*Intra-Diff & Cross-Module Duplication \(DRY\):\*\*/,/(\*\*Graph & Source Lookup|\-\-\-)/' "$REVIEW_CODE_FILE")" && pass "Lane E code duplication binds to [Should]" || fail "Lane E duplication not bound to [Should]"

# Phase 4 categories must bind required severities:
grep -q "reinventing a parallel subsystem" <<<"$(awk '/\[Blocker\]/,/\[Should\]/' "$REVIEW_CODE_FILE")" && pass "review-code binds parallel subsystem to [Blocker]" || fail "parallel subsystem is not under [Blocker]"
grep -q "bypassing established centralized helpers" <<<"$(awk '/\[Blocker\]/,/\[Should\]/' "$REVIEW_CODE_FILE")" && pass "review-code binds helper bypass to [Blocker]" || fail "helper bypass is not under [Blocker]"
grep -q "non-DRY duplicate logic" <<<"$(awk '/\[Should\]/,/\[Nit\]/' "$REVIEW_CODE_FILE")" && pass "review-code binds duplicate logic to [Should]" || fail "duplicate logic is not under [Should]"

# --- 6. ARCHITECTURE.md registration ---
grep -q "\[where-are-we-at\](skills/2-daily/where-are-we-at/SKILL.md)" "$ARCH_FILE" && pass "ARCHITECTURE.md has where-are-we-at link" || fail "missing ARCHITECTURE.md link"
grep -q "### \`2-daily\` — A few times a day (16)" "$ARCH_FILE" && pass "ARCHITECTURE.md has updated 2-daily count (16)" || fail "missing updated 2-daily count"

# --- 7. Installer gh678 compliance (in sandbox) ---
H="$WORK/home"; A="$H/apps"
mkdir -p "$A/claude" "$A/codex" "$A/gemcfg" "$A/antigrav" "$A/agents"
run_installer() {
  HOME="$H" CLAUDE_SKILLS_DIR="$A/claude" CODEX_SKILLS_DIR="$A/codex" \
  GEMINI_CONFIG_SKILLS_DIR="$A/gemcfg" ANTIGRAVITY_SKILLS_DIR="$A/antigrav" \
  AGENTS_SKILLS_DIR="$A/agents" \
  bash "$INSTALLER"
}

FOREIGN="$WORK/foreign"; mkdir -p "$FOREIGN"; echo "foreign" > "$FOREIGN/SKILL.md"
ln -s "$FOREIGN" "$A/claude/where-are-we-at"
set +e
run_installer >"$WORK/out-foreign" 2>&1
rc_for=$?
set -e
[ "$rc_for" -ne 0 ] && [ "$(readlink "$A/claude/where-are-we-at")" = "$FOREIGN" ] && pass "installer refuses live foreign link" || fail "installer replaced live foreign link"

rm -f "$A/claude/where-are-we-at"
ln -s "$WORK/nowhere/where-are-we-at" "$A/claude/where-are-we-at"
run_installer >"$WORK/out-dangling" 2>&1
rc_dan=$?
[ "$rc_dan" -eq 0 ] && [ "$(readlink "$A/claude/where-are-we-at")" -ef "$SKILL_DIR" ] && pass "installer replaces dangling link" || fail "installer failed to replace dangling link"

# --- 8. Negative control mutation (falsification) ---
# 8a: Recital deletion on where-are-we-at/SKILL.md must fail recital check
TMP_COPY="$WORK/skill_mutated.md"
cp "$SKILL_FILE" "$TMP_COPY"
sed -i.bak '/Status Discipline:/d' "$TMP_COPY"
grep -q "Status Discipline:" "$TMP_COPY" && fail "negative control 8a: mutation failed to delete recital" || pass "negative control 8a: mutation successfully detected missing recital"

# 8b: Mutating [Blocker] to [Nit] in Phase 4 must fail the Blocker check
TMP_REV="$WORK/review_code_mutated.md"
cp "$REVIEW_CODE_FILE" "$TMP_REV"
sed -i.bak 's/\[Blocker\]/\[Nit\]/g' "$TMP_REV"
if grep -q "reinventing a parallel subsystem" <<<"$(awk '/\[Blocker\]/,/\[Should\]/' "$TMP_REV")"; then
  fail "negative control 8b: severity mutation failed to turn Blocker check red"
else
  pass "negative control 8b: severity mutation correctly made Blocker check fail (red)"
fi

# 8c: Mutating Lane E helper severity to [Nit] must fail Lane E helper check
TMP_LANE_E1="$WORK/review_code_lane_e1.md"
cp "$REVIEW_CODE_FILE" "$TMP_LANE_E1"
sed -i.bak 's/is a `\[Blocker\]`/is a `[Nit]`/g' "$TMP_LANE_E1"
if grep -q 'is a `\[Blocker\]`' <<<"$(awk '/1\. \*\*Centralized Helper Adherence:\*\*/,/2\. \*\*Parallel Subsystem/' "$TMP_LANE_E1")"; then
  fail "negative control 8c: Lane E1 helper mutation failed to turn check red"
else
  pass "negative control 8c: Lane E1 helper mutation correctly made check fail (red)"
fi

# 8d: Mutating Lane E parallel subsystem severity to [Nit] must fail Lane E parallel check
TMP_LANE_E2="$WORK/review_code_lane_e2.md"
cp "$REVIEW_CODE_FILE" "$TMP_LANE_E2"
sed -i.bak 's/mandatory `\[Blocker\]`/mandatory `[Nit]`/g' "$TMP_LANE_E2"
if grep -q 'mandatory `\[Blocker\]`' <<<"$(awk '/2\. \*\*Parallel Subsystem \/ Reinvention Trap:\*\*/,/3\. \*\*Intra-Diff/' "$TMP_LANE_E2")"; then
  fail "negative control 8d: Lane E2 parallel subsystem mutation failed to turn check red"
else
  pass "negative control 8d: Lane E2 parallel subsystem mutation correctly made check fail (red)"
fi

# 8e: Mutating Lane E duplication severity to [Nit] must fail Lane E duplication check
TMP_LANE_E3="$WORK/review_code_lane_e3.md"
cp "$REVIEW_CODE_FILE" "$TMP_LANE_E3"
sed -i.bak 's/is a `\[Should\]`/is a `[Nit]`/g' "$TMP_LANE_E3"
if grep -q 'is a `\[Should\]`' <<<"$(awk '/3\. \*\*Intra-Diff & Cross-Module Duplication \(DRY\):\*\*/,/(\*\*Graph & Source Lookup|\-\-\-)/' "$TMP_LANE_E3")"; then
  fail "negative control 8e: Lane E3 duplication mutation failed to turn check red"
else
  pass "negative control 8e: Lane E3 duplication mutation correctly made check fail (red)"
fi

echo "  gh798-status-skill: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
