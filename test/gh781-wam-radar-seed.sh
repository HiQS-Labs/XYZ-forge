#!/usr/bin/env bash
# test/gh781-wam-radar-seed.sh — GH-781: whack-a-mole seeds candidate clusters from a recent radar
# report, freshness-gated, re-verified under its own two-signal rule, with the yield reported and
# the umbrella citing the radar class. Pins the load-bearing phrases; a negative control proves
# the pins bite.
source "$(dirname "$0")/_setup.sh" gh781-wam-radar-seed

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_FILE="$REPO/skills/3-weekly/whack-a-mole/SKILL.md"

echo "== test: gh781-wam-radar-seed =="
[ -f "$SKILL_FILE" ] && pass "whack-a-mole SKILL.md exists" || fail "missing $SKILL_FILE"

pin() { grep -Fq -- "$2" "$SKILL_FILE" && pass "$1" || fail "$1 (missing '$2')"; }

# --- 1. The seed step and its sources ---
pin "seed subsection" "### Seed from radar (when a recent report exists)"
pin "reads dated radar reports" 'PROJECT/1-INBOX/RADAR-REPORT-*.md'
pin "reads the live radar issue" 'gh issue list --label radar --state open'
pin "seeds from ranked and carried targets" '`### Ranked targets` / `### Carried targets`'

# --- 2. Freshness gate ---
pin "freshness gate" "**2× this run's window**"
pin "stale report is said out loud" "too old — not seeded"

# --- 3. Seeds never become evidence ---
pin "seeds are hints" "**Seeds are hints, not evidence.**"
pin "two-signal rule still applies" "Every item still passes §3's two-signal rule"
pin "out-of-window members not scored" '`prior only` and never scored'
pin "non-reproducing seed is reported" '`not reproduced`, never silently dropped'
pin "normal scan still runs" "Clusters radar missed still"

# --- 4. Yield line and ledger link ---
pin "yield line" 'Seeded from RADAR-REPORT-<date>: N targets, M confirmed, K not reproduced'
pin "absence is a stated result" '`no radar report found`'
pin "umbrella cites the radar class" '`class RADAR-<id>`'

# --- 5. Ordering: seed runs inside §2, before ranking detection and before §3 clustering ---
seed=$(grep -n '^### Seed from radar' "$SKILL_FILE" | cut -d: -f1)
scan=$(grep -n '^## 2\. Scan' "$SKILL_FILE" | cut -d: -f1)
rank=$(grep -n "^### Detect the repo's ranking system" "$SKILL_FILE" | cut -d: -f1)
clus=$(grep -n '^## 3\. Cluster' "$SKILL_FILE" | cut -d: -f1)
[ -n "$seed" ] && [ -n "$scan" ] && [ -n "$rank" ] && [ -n "$clus" ] \
  && [ "$scan" -lt "$seed" ] && [ "$seed" -lt "$rank" ] && [ "$rank" -lt "$clus" ] \
  && pass "seed step sits in §2 before clustering" || fail "seed step misplaced (scan=$scan seed=$seed rank=$rank cluster=$clus)"

# --- 6. Negative control: dropping the re-verification rule must be detected ---
MUT="$(mktemp "${TMPDIR:-/tmp}/gh781-wam.XXXXXX")"
grep -Fv '**Seeds are hints, not evidence.**' "$SKILL_FILE" >"$MUT"
grep -Fq '**Seeds are hints, not evidence.**' "$MUT" && fail "negative control: mutation left the rule in place" \
  || pass "negative control: a seed step without re-verification fails the pin"
rm -f "$MUT"

echo "  gh781-wam-radar-seed: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
