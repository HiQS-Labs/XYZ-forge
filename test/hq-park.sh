#!/usr/bin/env bash
# GH-128 Phase 2: HQ `park` — issue-first intake writer.
# Hermetic — fixture registries + fixture target git repos under a temp dir, and a STUBBED gh
# (HQ_GH_BIN) so no network/real issue is touched. Covers: preview-writes-nothing, --create writes
# the capture doc + ROADMAP pointer with correct frontmatter, slug/stopword handling, dup-guard abort,
# Tier C plain-issue-only, and unresolved.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
HQ="$HERE/../utils/hq/hq.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: hq-park (GH-128 intake writer) =="

command -v git >/dev/null 2>&1 || { echo "  SKIP: git absent"; echo "== hq-park: 0 passed, 0 failed =="; exit 0; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$TMP"   # GH-10: pin the sandbox root

# --- fixture: git-pulse PDDA registry (marks beta-app as PDDA-governed) ---
PDDA_DIR="$TMP/gitpulse/pdda"; mkdir -p "$PDDA_DIR"
printf 'beta-app\t2026-07-04T00:00:00Z\tobserve\tabc1234\tyes\n' > "$PDDA_DIR/registry-testdev.tsv"

# --- fixture: Tier B target (PDDA on disk, no XYZ install; resolves via filesystem) ---
BETA="$TMP/repos/beta-app"
git init -q "$BETA"
git -C "$BETA" remote add origin https://github.com/testorg/beta-app.git
printf 'observe\n' > "$BETA/.pdda-mode"
mkdir -p "$BETA/PROJECT/1-INBOX" "$BETA/utils/pdda"
printf '# Roadmap\n\n## Ledger\n\n### Queue / parked intake\n\n### In progress\n' > "$BETA/ROADMAP.md"
printf '#!/usr/bin/env bash\nexit 0\n' > "$BETA/utils/pdda/pdda.sh"; chmod +x "$BETA/utils/pdda/pdda.sh"

# --- fixture: Tier C bare repo (no PDDA) ---
GAMMA="$TMP/repos/gamma-bare"; git init -q "$GAMMA"

# --- stub gh (HQ_GH_BIN): create -> URL#777; list -> dup iff HQ_TEST_DUP=1 ---
STUB="$TMP/gh-stub"
cat > "$STUB" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = issue ] && [ "${2:-}" = create ]; then
  echo "https://github.com/testorg/beta-app/issues/777"
elif [ "${1:-}" = issue ] && [ "${2:-}" = list ]; then
  [ "${HQ_TEST_DUP:-0}" = 1 ] && echo '[{"number":5,"title":"dup"}]' || echo '[]'
fi
EOF
chmod +x "$STUB"

export HQ_PDDA_REGISTRY_DIR="$PDDA_DIR"
export HQ_XYZ_REGISTRY="$TMP/none.tsv"          # deliberately absent -> forces filesystem resolution
export HQ_REBALANCE_DB="$TMP/none.db"           # absent -> rebalance rung degrades to empty
export HQ_SEARCH_ROOTS="$TMP/repos"
export HQ_GH_BIN="$STUB"

REQ="add a CI status badge to the README"

# ---- 1. preview writes nothing ----
OUT="$(bash "$HQ" park beta-app "$REQ")"; rc=$?
[ "$rc" = 0 ] && pass "park preview rc=0" || fail "preview rc=$rc"
grep -q "PREVIEW (writes nothing)" <<<"$(printf '%s\n' "$OUT")" && pass "preview labeled" || fail "no preview label"
grep -q "CI-STATUS-BADGE-README" <<<"$(printf '%s\n' "$OUT")" && pass "slug drops stopwords (add/a)" \
  || fail "slug: $(printf '%s\n' "$OUT" | grep -i 'capture doc')"
[ -z "$(ls -A "$BETA/PROJECT/1-INBOX")" ] && pass "1-INBOX still empty after preview" || fail "preview wrote files"
grep -q 'GH-' "$BETA/ROADMAP.md" && fail "preview mutated ROADMAP" || pass "ROADMAP untouched by preview"

# ---- 2. --create writes issue-backed capture doc + ROADMAP pointer ----
OUT="$(bash "$HQ" park --create beta-app "$REQ")"; rc=$?
[ "$rc" = 0 ] && pass "park --create rc=0" || fail "create rc=$rc: $OUT"
DOC="$BETA/PROJECT/1-INBOX/GH-777-CI-STATUS-BADGE-README.md"
[ -f "$DOC" ] && pass "capture doc written at expected path" || fail "no capture doc: $(ls "$BETA/PROJECT/1-INBOX")"
grep -q '^gh_issue: 777' "$DOC" && pass "frontmatter gh_issue=777" || fail "gh_issue wrong"
grep -q 'issues/777' "$DOC" && pass "frontmatter source URL set" || fail "source URL missing"
grep -q '^status: Proposed (1-INBOX' "$DOC" && pass "status = Proposed(1-INBOX)" || fail "status wrong"
grep -q 'GH-777 · ' "$BETA/ROADMAP.md" && pass "ROADMAP pointer inserted" || fail "no ROADMAP pointer"
# pointer landed under the Queue heading, not the In-progress heading
awk '/### Queue/{q=NR} /GH-777/{g=NR} /### In progress/{p=NR} END{exit !(q<g && g<p)}' "$BETA/ROADMAP.md" \
  && pass "pointer placed under Queue heading" || fail "pointer misplaced"
grep -q "NOT committed" <<<"$(printf '%s\n' "$OUT")" && pass "reports files left uncommitted" || fail "no uncommitted notice"

# ---- 2b. --title overrides the derived (truncated) title; slug + filename follow the title ----
bash "$HQ" park --create --title "focus5: clean custom title" beta-app "$REQ" >/dev/null 2>&1
DOCT="$BETA/PROJECT/1-INBOX/GH-777-FOCUS5-CLEAN-CUSTOM-TITLE.md"
[ -f "$DOCT" ] && pass "--title drives the capture filename (slug from title)" \
  || fail "no title-slug doc: $(ls "$BETA/PROJECT/1-INBOX")"
grep -q '^title: "focus5: clean custom title"' "$DOCT" && pass "--title overrides frontmatter title" \
  || fail "--title not applied to frontmatter"
grep -q '^# focus5: clean custom title' "$DOCT" && pass "--title used as doc H1" || fail "--title H1 missing"
grep -q 'CI status badge' "$DOCT" && pass "full request preserved as body under --title" \
  || fail "request body lost under --title"

# ---- 3. dup-guard aborts before writing ----
rm -f "$BETA/PROJECT/1-INBOX/GH-778-"*.md
OUT="$(HQ_TEST_DUP=1 bash "$HQ" park --create beta-app "a different new request here" 2>&1)"; rc=$?
[ "$rc" = 1 ] && pass "dup-guard aborts rc=1" || fail "dup rc=$rc"
grep -qi "duplicate" <<<"$(printf '%s\n' "$OUT")" && pass "dup message shown" || fail "no dup message"

# ---- 4. Tier C: plain issue only, no capture doc ----
OUT="$(bash "$HQ" park gamma-bare "$REQ")"; rc=$?
[ "$rc" = 0 ] && pass "Tier C preview rc=0" || fail "tierC rc=$rc"
grep -q "Tier C" <<<"$(printf '%s\n' "$OUT")" && pass "Tier C detected" || fail "not Tier C: $OUT"
grep -qi "plain GitHub issue only" <<<"$(printf '%s\n' "$OUT")" && pass "Tier C = plain issue only" || fail "tierC wording"

# ---- 5. unresolved target ----
bash "$HQ" park nope-not-here "$REQ" >/dev/null 2>&1; rc=$?
[ "$rc" = 1 ] && pass "unresolved park rc=1" || fail "unresolved rc=$rc"

echo "== hq-park: $PASS passed, $FAIL failed =="
[ "$FAIL" = 0 ]
