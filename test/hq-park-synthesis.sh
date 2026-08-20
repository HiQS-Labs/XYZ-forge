#!/usr/bin/env bash
# GH-164 Phase 1: hq park's fuller PDDA-skeleton capture template + optional synthesis passthrough
# (HQ_PARK_* env vars) + dashboard regeneration wired into --create. Hermetic — mirrors
# test/hq-park.sh's fixture pattern (fixture registries + target repo + stubbed gh).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
HQ="$HERE/../utils/hq/hq.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: hq-park-synthesis (GH-164 Phase 1) =="

command -v git >/dev/null 2>&1 || { echo "  SKIP: git absent"; echo "== hq-park-synthesis: 0 passed, 0 failed =="; exit 0; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$TMP"   # GH-10: pin the sandbox root

PDDA_DIR="$TMP/gitpulse/pdda"; mkdir -p "$PDDA_DIR"
printf 'beta-app\t2026-07-04T00:00:00Z\tobserve\tabc1234\tyes\n' > "$PDDA_DIR/registry-testdev.tsv"

BETA="$TMP/repos/beta-app"
git init -q "$BETA"
git -C "$BETA" remote add origin https://github.com/testorg/beta-app.git
printf 'observe\n' > "$BETA/.pdda-mode"
mkdir -p "$BETA/PROJECT/1-INBOX" "$BETA/utils/pdda" "$BETA/utils"
printf '# Roadmap\n\n## Ledger\n\n### Queue / parked intake\n\n### In progress\n\n### Completed\n\n### Deferred · vision\n' > "$BETA/ROADMAP.md"
printf '#!/usr/bin/env bash\nexit 0\n' > "$BETA/utils/pdda/pdda.sh"; chmod +x "$BETA/utils/pdda/pdda.sh"
cp "$HERE/../utils/roadmap-dashboard.sh" "$BETA/utils/roadmap-dashboard.sh"; chmod +x "$BETA/utils/roadmap-dashboard.sh"

STUB="$TMP/gh-stub"
cat > "$STUB" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = issue ] && [ "${2:-}" = create ]; then
  echo "https://github.com/testorg/beta-app/issues/900"
elif [ "${1:-}" = issue ] && [ "${2:-}" = list ]; then
  echo '[]'
fi
EOF
chmod +x "$STUB"

export HQ_PDDA_REGISTRY_DIR="$PDDA_DIR"
export HQ_XYZ_REGISTRY="$TMP/none.tsv"
export HQ_REBALANCE_DB="$TMP/none.db"
export HQ_SEARCH_ROOTS="$TMP/repos"
export HQ_GH_BIN="$STUB"

REQ="add an idea intake pipeline"

# ── (1) bare park --create, ZERO synthesis env vars: TODO-stub skeleton, valid + complete ─────────
unset HQ_PARK_COMPLEXITY HQ_PARK_RISK HQ_PARK_EFFORT HQ_PARK_PHASES HQ_PARK_WHY HQ_PARK_KEY_CONCEPTS HQ_PARK_NON_GOALS HQ_PARK_RELATED
OUT="$(bash "$HQ" park --create beta-app "$REQ")"; rc=$?
[ "$rc" = 0 ] && pass "bare --create (no synthesis env) rc=0" || fail "bare create rc=$rc: $OUT"
DOC="$BETA/PROJECT/1-INBOX/GH-900-IDEA-INTAKE-PIPELINE.md"
[ -f "$DOC" ] && pass "capture doc written" || fail "no capture doc: $(ls "$BETA/PROJECT/1-INBOX")"
grep -q '^complexity: 2$' "$DOC" && pass "default complexity=2" || fail "default complexity wrong"
grep -q '^risk: 1$' "$DOC" && pass "default risk=1" || fail "default risk wrong"
grep -q '^effort: 2$' "$DOC" && pass "default effort=2" || fail "default effort wrong"
grep -q '^phases: 1$' "$DOC" && pass "default phases=1" || fail "default phases wrong"
grep -q '^ratings_provisional: true$' "$DOC" && pass "ratings_provisional: true" || fail "ratings_provisional missing"
grep -q '^non_goals:' "$DOC" && pass "non_goals: key present" || fail "non_goals missing"
grep -q '^related:' "$DOC" && pass "related: key present" || fail "related missing"
grep -q '^goal: >' "$DOC" && pass "goal: key present" || fail "goal missing"
grep -q '^## Key concepts' "$DOC" && pass "## Key concepts section present" || fail "Key concepts missing"
grep -q '^## Idea' "$DOC" && pass "## Idea section present (renamed from Request)" || fail "## Idea missing"
grep -q "$REQ" "$DOC" && pass "request text preserved under Idea" || fail "request text missing"
grep -q '^## Why' "$DOC" && pass "## Why section present" || fail "## Why missing"
grep -q 'TODO: why this matters' "$DOC" && pass "Why falls back to a TODO stub when not synthesized" || fail "Why TODO-stub missing"
grep -q '^## Phase 0 — Explore & scope' "$DOC" && pass "Phase 0 section present" || fail "Phase 0 section missing"
grep -q '^### Checklist' "$DOC" && pass "### Checklist present" || fail "Checklist missing"
grep -q '^### QA checklist' "$DOC" && pass "### QA checklist present" || fail "QA checklist missing"
grep -q '^## Status' "$DOC" && pass "## Status table present" || fail "Status table missing"
grep -q 'What was just completed | What.s next' "$DOC" && pass "Status table has the exact PDDA headers" || fail "Status headers wrong"
# still valid per the target's own frontmatter check (same gate cmd_park already runs)
( cd "$BETA" && PDDA_ONLY_FILE="PROJECT/1-INBOX/GH-900-IDEA-INTAKE-PIPELINE.md" bash utils/pdda/pdda.sh frontmatter >/dev/null 2>&1 )
pass "target's own pdda.sh frontmatter check accepted (stubbed to exit 0 — real gate exercised in hq-park.sh)"

# ── (2) dashboard regeneration wired into --create ("only if present") ─────────────────────────────
if command -v node >/dev/null 2>&1; then
  [ -f "$BETA/ROADMAP-DASHBOARD.md" ] && pass "ROADMAP-DASHBOARD.md regenerated after --create" || fail "dashboard was not regenerated"
  grep -q 'GH-900' "$BETA/ROADMAP-DASHBOARD.md" 2>/dev/null && pass "regenerated dashboard reflects the new ROADMAP pointer" || fail "dashboard content stale/missing the new entry"
else
  echo "  SKIP: node absent — dashboard regen assertions skipped"
fi

# ── (3) dashboard script ABSENT in target: no failure, no false claim ──────────────────────────────
rm -rf "$BETA/PROJECT" "$BETA/.tick"; mkdir -p "$BETA/PROJECT/1-INBOX"
rm -f "$BETA/ROADMAP-DASHBOARD.md" "$BETA/utils/roadmap-dashboard.sh"
printf '# Roadmap\n\n### Queue / parked intake\n\n### In progress\n' > "$BETA/ROADMAP.md"
OUT="$(bash "$HQ" park --create beta-app "a second unrelated idea" 2>&1)"; rc=$?
[ "$rc" = 0 ] && pass "--create still succeeds when utils/roadmap-dashboard.sh is absent" || fail "create failed without dashboard script: $OUT (rc=$rc)"
[ -f "$BETA/ROADMAP-DASHBOARD.md" ] && fail "a dashboard file appeared despite the script being absent" || pass "no phantom dashboard file when the script is absent"
printf '%s\n' "$OUT" | grep -qi 'dashboard' && fail "claimed dashboard action with no script present" || pass "no false dashboard claim when the script is absent"

# ── (4) synthesis passthrough via HQ_PARK_* env vars populates the real fields ─────────────────────
rm -rf "$BETA/PROJECT"; mkdir -p "$BETA/PROJECT/1-INBOX"
printf '# Roadmap\n\n### Queue / parked intake\n\n### In progress\n' > "$BETA/ROADMAP.md"
STUB2="$TMP/gh-stub2"
cat > "$STUB2" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = issue ] && [ "${2:-}" = create ]; then
  echo "https://github.com/testorg/beta-app/issues/901"
elif [ "${1:-}" = issue ] && [ "${2:-}" = list ]; then
  echo '[]'
fi
EOF
chmod +x "$STUB2"; export HQ_GH_BIN="$STUB2"
export HQ_PARK_COMPLEXITY=4 HQ_PARK_RISK=3 HQ_PARK_EFFORT=3 HQ_PARK_PHASES=2
export HQ_PARK_WHY="This closes a real gap found during GH-161-164 intake."
export HQ_PARK_KEY_CONCEPTS="first bullet|second bullet|third bullet"
export HQ_PARK_NON_GOALS="not a replacement for HQ|not auto-firing anything"
export HQ_PARK_RELATED="utils/hq/hq.sh|utils/hq/hq-lib.sh"
OUT="$(bash "$HQ" park --create beta-app "synthesized idea via the skill" 2>&1)"; rc=$?
[ "$rc" = 0 ] && pass "--create with full synthesis passthrough rc=0" || fail "synthesis create rc=$rc: $OUT"
DOC2="$BETA/PROJECT/1-INBOX/GH-901-SYNTHESIZED-IDEA-VIA.md"
[ -f "$DOC2" ] || DOC2="$(ls "$BETA"/PROJECT/1-INBOX/GH-901-*.md 2>/dev/null | head -1)"
[ -n "$DOC2" ] && [ -f "$DOC2" ] && pass "synthesized capture doc written" || fail "no synthesized capture doc found"
grep -q '^complexity: 4$' "$DOC2" && pass "synthesized complexity=4 passed through" || fail "complexity passthrough failed"
grep -q '^risk: 3$' "$DOC2" && pass "synthesized risk=3 passed through" || fail "risk passthrough failed"
grep -q '^effort: 3$' "$DOC2" && pass "synthesized effort=3 passed through" || fail "effort passthrough failed"
grep -q '^phases: 2$' "$DOC2" && pass "synthesized phases=2 passed through" || fail "phases passthrough failed"
grep -q 'This closes a real gap found during GH-161-164 intake.' "$DOC2" && pass "synthesized Why text passed through (no TODO fallback)" || fail "Why passthrough failed"
grep -q '^- first bullet$' "$DOC2" && grep -q '^- second bullet$' "$DOC2" && grep -q '^- third bullet$' "$DOC2" \
  && pass "pipe-delimited Key Concepts rendered as 3 separate bullets" || fail "Key Concepts bullet split failed"
grep -q '^  - not a replacement for HQ$' "$DOC2" && grep -q '^  - not auto-firing anything$' "$DOC2" \
  && pass "pipe-delimited non_goals rendered as a real YAML list" || fail "non_goals passthrough failed"
grep -q '^  - utils/hq/hq.sh$' "$DOC2" && grep -q '^  - utils/hq/hq-lib.sh$' "$DOC2" \
  && pass "pipe-delimited related rendered as a real YAML list" || fail "related passthrough failed"
unset HQ_PARK_COMPLEXITY HQ_PARK_RISK HQ_PARK_EFFORT HQ_PARK_PHASES HQ_PARK_WHY HQ_PARK_KEY_CONCEPTS HQ_PARK_NON_GOALS HQ_PARK_RELATED

echo "== hq-park-synthesis: $PASS passed, $FAIL failed =="
[ "$FAIL" = 0 ]
