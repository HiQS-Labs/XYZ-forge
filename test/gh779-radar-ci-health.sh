#!/usr/bin/env bash
# test/gh779-radar-ci-health.sh — GH-779: radar reads trunk CI, re-runs new guards on open PRs,
# and reports classes that regressed after being declared fixed (rule + mechanical guard).
# Each section is pinned by its load-bearing phrases, and a negative control proves the pins bite.
source "$(dirname "$0")/_setup.sh" gh779-radar-ci-health

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_FILE="$REPO/skills/3-weekly/radar/SKILL.md"

echo "== test: gh779-radar-ci-health =="
[ -f "$SKILL_FILE" ] && pass "radar SKILL.md exists" || fail "missing $SKILL_FILE"

pin() { grep -Fq -- "$2" "$SKILL_FILE" && pass "$1" || fail "$1 (missing '$2')"; }

# --- 1. Signal 9: trunk CI health ---
pin "signal 9 heading" "9. **Trunk CI health**"
pin "reads trunk workflow runs" 'gh run list --branch <trunk>'
pin "reads failing logs" 'gh run view <id> --log-failed'
pin "reports consecutive red days" "**consecutive red days**"
pin "reports first red commit" "**first red commit**"
pin "2-day red trunk is a regression target" "Red for **≥2 calendar days** is a **Potential Regression** target"
pin "unavailable CI is never green" "never reported as green"
pin "recital counts 9 signals" "Mine 9 evidence signals"

# --- 2. Step 2b: new-guard re-run ---
pin "new-guard subsection" "### New-guard re-run (collisions with zero file overlap)"
pin "runs guards added in window" "**added or tightened in the window**"
pin "merges PR head with trunk" 'git merge --no-commit origin/<trunk>'
pin "predating PR is a collision" "A PR that fails a guard it predates is a **collision**"
pin "unrunnable guard is not a pass" "reported as unavailable, never as a pass"

# --- 3. Report: regressed after declared fixed ---
pin "report bullet" "**Regressed After Declared Fixed**"
pin "table header" "| Class | Declared fixed | Came back | Rule | Mechanical guard |"
pin "prose-only is a finding" '`prose only` is itself a finding'
pin "carried into Sink A" "same table into Sink A"

# --- 4. Ordering: the new-guard pass lives in Step 2b, before Step 3 ---
g=$(grep -n '^### New-guard re-run' "$SKILL_FILE" | cut -d: -f1)
b=$(grep -n '^## Step 2b' "$SKILL_FILE" | cut -d: -f1)
s3=$(grep -n '^## Step 3' "$SKILL_FILE" | cut -d: -f1)
[ -n "$g" ] && [ -n "$b" ] && [ -n "$s3" ] && [ "$b" -lt "$g" ] && [ "$g" -lt "$s3" ] \
  && pass "new-guard re-run sits inside Step 2b" || fail "new-guard re-run misplaced (2b=$b guard=$g step3=$s3)"

# --- 5. Negative control: deleting signal 9 must be detected ---
MUT="$(mktemp "${TMPDIR:-/tmp}/gh779-radar.XXXXXX")"
grep -Fv '9. **Trunk CI health**' "$SKILL_FILE" >"$MUT"
grep -Fq '9. **Trunk CI health**' "$MUT" && fail "negative control: mutation left signal 9 in place" \
  || pass "negative control: a radar without signal 9 fails the pin"
rm -f "$MUT"

echo "  gh779-radar-ci-health: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
