#!/usr/bin/env bash
# GH-138: HQ `promote` command (PDDA 1-INBOX -> 2-WORKING) + the marathon-plan glob broadening.
# Hermetic: a temp git repo resolved purely via HQ_SEARCH_ROOTS (no registries), stubbed to nothing
# else. Proves: preview writes nothing; --create moves + scaffolds a doc that passes the REAL pdda
# frontmatter + status-table checks; refusals (no doc / overwrite); and that a MARATHON-<date>.md
# (no -PLAN-) is now detected where the old MARATHON-PLAN-*.md glob would have missed it.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
HQ="$HERE/../utils/hq/hq.sh"
LIB="$HERE/../utils/hq/hq-lib.sh"
PDDA="$HERE/../utils/pdda/pdda.sh"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: hq-promote (GH-138) =="

command -v git >/dev/null 2>&1 || { echo "  SKIP: git absent"; echo "== hq-promote: 0 passed, 0 failed =="; exit 0; }
# GH-177: mktemp -d can fail silently under a sandboxed shell (empty stdout, non-zero rc). The old
# `cd "$(mktemp -d)" && pwd -P` idiom let `cd ""` succeed and silently stay at the CWD (the repo
# root), so the EXIT trap below then rm -rf'd the entire repository — twice (2026-07-07, 2026-07-17).
# Verify mktemp actually succeeded and returned a real directory BEFORE it's wired into a destructive
# trap; canonicalize (macOS /tmp -> /private/tmp) only as a separate step afterward.
TMP="$(mktemp -d)" || { echo "FAIL: mktemp -d failed" >&2; exit 1; }
[ -n "$TMP" ] && [ -d "$TMP" ] || { echo "FAIL: mktemp -d returned an invalid path" >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT
TMP="$(cd "$TMP" && pwd -P)"

ROOTS="$TMP/roots"; REPO="$ROOTS/myproj"
mkdir -p "$REPO/PROJECT/1-INBOX" "$REPO/PROJECT/2-WORKING"
( cd "$REPO" && git init -q && git config user.email t@t && git config user.name t && git remote add origin git@github.com:Test/myproj.git )
: > "$REPO/.pdda-mode"   # marks Tier A/B (has_pdda) for cmd_promote

# a park-style 1-INBOX capture doc: has title/status/created, but NOT updated/owner/goal
cat > "$REPO/PROJECT/1-INBOX/GH-42-SAMPLE-THING.md" <<'EOF'
---
gh_issue: 42
source: https://github.com/Test/myproj/issues/42
title: "Sample thing to promote"
status: Proposed (1-INBOX — not yet active)
created: 2026-07-05
doc_type: feedback
---

# Sample thing to promote

## Request

Do the sample thing.
EOF
( cd "$REPO" && git add -A && git commit -q -m init )

# resolve purely via filesystem (registries pointed at nothing)
hqp(){ env HQ_XYZ_REGISTRY="$TMP/none.tsv" HQ_REBALANCE_DB="$TMP/none.db" \
           HQ_PDDA_REGISTRY_DIR="$TMP/nopdda" HQ_SEARCH_ROOTS="$ROOTS" bash "$HQ" "$@"; }

# ---- 1. preview writes nothing ----
OUT="$(hqp promote --gh-issue 42 myproj 2>&1)"; rc=$?
{ [ "$rc" = 0 ] && printf '%s' "$OUT" | grep -q PREVIEW \
    && [ -f "$REPO/PROJECT/1-INBOX/GH-42-SAMPLE-THING.md" ] \
    && [ ! -e "$REPO/PROJECT/2-WORKING/GH-42-SAMPLE-THING.md" ]; } \
  && pass "preview (no --create) previews + writes nothing" \
  || fail "preview rc=$rc / files moved unexpectedly"

# ---- 2. --create moves the doc ----
OUT="$(hqp promote --create --gh-issue 42 myproj 2>&1)"; rc=$?
{ [ "$rc" = 0 ] \
    && [ ! -e "$REPO/PROJECT/1-INBOX/GH-42-SAMPLE-THING.md" ] \
    && [ -f "$REPO/PROJECT/2-WORKING/GH-42-SAMPLE-THING.md" ]; } \
  && pass "--create git-mv's the doc from 1-INBOX to 2-WORKING" \
  || fail "--create rc=$rc / doc not moved"

MOVED="$REPO/PROJECT/2-WORKING/GH-42-SAMPLE-THING.md"

# ---- 3. the promoted doc passes the REAL pdda frontmatter + status-table checks ----
FM="$(env PDDA_MODE=observe PDDA_WORKING_DIR="$REPO/PROJECT/2-WORKING" bash "$PDDA" frontmatter 2>&1)"
printf '%s' "$FM" | grep -q 'errors=0' \
  && pass "promoted doc passes pdda frontmatter (title/status/created/updated/owner/goal present)" \
  || fail "pdda frontmatter not clean: $(printf '%s' "$FM" | grep -i error | head -2)"

ST="$(env PDDA_MODE=observe PDDA_WORKING_DIR="$REPO/PROJECT/2-WORKING" bash "$PDDA" status-table 2>&1)"
printf '%s' "$ST" | grep -q 'errors=0' \
  && pass "promoted doc passes pdda status-table (exact header + non-blank cells)" \
  || fail "pdda status-table not clean: $(printf '%s' "$ST" | grep -i error | head -2)"

# scaffold honesty: status flipped off 'Proposed', operator-TODO present
grep -q '^status: Promoted from 1-INBOX' "$MOVED" \
  && pass "status frontmatter flipped off the 1-INBOX 'Proposed' state" \
  || fail "status line not upgraded"

# ---- 4. re-promoting when no matching 1-INBOX doc remains -> refuse (non-zero) ----
OUT="$(hqp promote --create --gh-issue 42 myproj 2>&1)"; rc=$?
{ [ "$rc" != 0 ] && printf '%s' "$OUT" | grep -qi 'nothing to promote'; } \
  && pass "refuses (non-zero) when no PROJECT/1-INBOX/GH-N-*.md exists" \
  || fail "expected refusal, got rc=$rc"

# ---- 5. overwrite guard: a 1-INBOX doc whose dest already exists -> refuse ----
cat > "$REPO/PROJECT/1-INBOX/GH-42-SAMPLE-THING.md" <<'EOF'
---
title: "dup"
status: Proposed (1-INBOX — not yet active)
created: 2026-07-05
---
# dup
EOF
OUT="$(hqp promote --create --gh-issue 42 myproj 2>&1)"; rc=$?
{ [ "$rc" != 0 ] && printf '%s' "$OUT" | grep -qi 'already exists'; } \
  && pass "refuses to overwrite an existing 2-WORKING doc" \
  || fail "expected overwrite refusal, got rc=$rc"

# ---- 6. GLOB REGRESSION: MARATHON-<date>.md (no -PLAN-) is detected as the local marathon plan ----
# shellcheck source=/dev/null
. "$LIB"
: > "$REPO/PROJECT/2-WORKING/MARATHON-2026-07-04.md"
LM="$(hq_inspect_repo "$REPO" | grep '^LOCAL_MARATHON=')"
[ "$LM" = "LOCAL_MARATHON=MARATHON-2026-07-04.md" ] \
  && pass "marathon glob now matches MARATHON-<date>.md (was MARATHON-PLAN-*.md only)" \
  || fail "MARATHON-<date>.md not detected: got '$LM'"

echo "== hq-promote: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
