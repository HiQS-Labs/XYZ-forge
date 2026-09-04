#!/usr/bin/env bash
# GH-414 — source-comment references must resolve in both source and built trees.
source "$(dirname "$0")/_setup.sh" gh414-comment-reference-check
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PDDA="$ROOT/utils/pdda/pdda.sh"
SOURCE="$WORK/source"
ARTIFACT="$WORK/artifact"
mkdir -p "$SOURCE/src" "$SOURCE/decisions" "$ARTIFACT/src"
require_fixture "$SOURCE" "GH-414 source fixture"
require_fixture "$ARTIFACT" "GH-414 built-artifact fixture"

cat >"$SOURCE/src/events.js" <<'EOF'
// The source tree retains both ADRs.
// See decisions/2026-06-18-epoch-fencing.md.
// See decisions/2026-07-01-cross-agent-dep-conflict.md.
module.exports = {};
EOF
printf '# epoch fencing\n' >"$SOURCE/decisions/2026-06-18-epoch-fencing.md"
printf '# dependency drift\n' >"$SOURCE/decisions/2026-07-01-cross-agent-dep-conflict.md"

# This is the pre-fix public-tree shape: its source file survives the build but the two cited ADRs
# do not.  It must fail even though the source tree above is clean.
cp "$SOURCE/src/events.js" "$ARTIFACT/src/events.js"
run_governance() {
  PDDA_MODE=full PDDA_REPO_ROOT="$SOURCE" PDDA_COMMENT_REFERENCE_ARTIFACT="$ARTIFACT" \
    PDDA_GOVERNANCE_DOCS="" PDDA_ACTIVITY_LOG=/dev/null bash "$PDDA" governance 2>&1
}

rc=0; out="$(run_governance)" || rc=$?
[ "$rc" -ne 0 ] \
  && pass "red control: missing ADR citations in the built artifact fail governance" \
  || fail "red control: governance passed despite the built artifact dropping both ADRs: $out"
for adr in decisions/2026-06-18-epoch-fencing.md decisions/2026-07-01-cross-agent-dep-conflict.md; do
  printf '%s\n' "$out" | grep -F "comment reference '$adr'" >/dev/null \
    && pass "red control names dropped artifact citation $adr" \
    || fail "red control did not name dropped artifact citation $adr: $out"
done

mkdir -p "$ARTIFACT/decisions"
cp "$SOURCE/decisions/2026-06-18-epoch-fencing.md" "$ARTIFACT/decisions/"
cp "$SOURCE/decisions/2026-07-01-cross-agent-dep-conflict.md" "$ARTIFACT/decisions/"
rc=0; out="$(run_governance)" || rc=$?
[ "$rc" -eq 0 ] \
  && pass "the same comments pass once both cited ADRs are retained in the built artifact" \
  || fail "clean source and artifact should pass (rc=$rc): $out"

printf '// See decisions/does-not-exist.md.\n' >>"$SOURCE/src/events.js"
rc=0; out="$(run_governance)" || rc=$?
[ "$rc" -ne 0 ] \
  && pass "a nonexistent source-comment path fails the check" \
  || fail "a nonexistent source-comment path passed: $out"
printf '%s\n' "$out" | grep -F "comment reference 'decisions/does-not-exist.md' in source tree" >/dev/null \
  && pass "the source-tree failure identifies the dead comment reference" \
  || fail "the source-tree failure did not identify the dead comment reference: $out"

grep -q '^# Red control' "$ROOT/test/baselines/GH-414-negative-control.md" \
  && pass "the observed pre-fix artifact failure is recorded" \
  || fail "GH-414 negative-control baseline is missing"

# -- gitignored runtime state is not a dead reference (pristine-checkout control) ---------------
# src/project.js legitimately cites .tick/STATE.md -- generated, gitignored state that a pristine
# checkout never has. With the ignore rule present the citation must pass; with it removed the
# same citation must fail again (the red direction: the exemption is what carries control A).
PRISTINE="$WORK/pristine"
mkdir -p "$PRISTINE/src"
require_fixture "$PRISTINE" "GH-414 pristine fixture"
cat >"$PRISTINE/src/project.js" <<'JSEOF'
/**
 * Reads the event log, projects it, and writes both `.tick/STATE.md` and
 * `.tick/rejected.jsonl`.
 */
module.exports = {};
JSEOF
printf '/.tick/\n' >"$PRISTINE/.gitignore"
git -C "$PRISTINE" init -q .
rc=0; out="$(PDDA_MODE=full PDDA_REPO_ROOT="$PRISTINE" PDDA_GOVERNANCE_DOCS="" PDDA_ACTIVITY_LOG=/dev/null bash "$PDDA" governance 2>&1)" || rc=$?
[ "$rc" -eq 0 ] \
  && pass "gitignored runtime citation (.tick/STATE.md) is not a dead reference" \
  || fail "gitignored citation still reported dead (fresh-clone false positive persists): $out"
mv "$PRISTINE/.gitignore" "$PRISTINE/.gitignore.bak"
rc=0; out="$(PDDA_MODE=full PDDA_REPO_ROOT="$PRISTINE" PDDA_GOVERNANCE_DOCS="" PDDA_ACTIVITY_LOG=/dev/null bash "$PDDA" governance 2>&1)" || rc=$?
mv "$PRISTINE/.gitignore.bak" "$SOURCE/.gitignore"
[ "$rc" -ne 0 ] \
  && pass "red control: the same citation fails without the ignore rule (check can fail)" \
  || fail "red control: governance passed without the ignore rule -- the exemption is not what carried control A: $out"


# -- GH-514: a negation rule re-includes the path, so a missing re-included ref must FAIL ----
# check-ignore exit 0 means "a pattern matched", not "ignored" — the exemption must read the
# final matching RULE and treat `!`-rules as re-included, or a dead re-included ref goes silent.
cat >"$PRISTINE/.gitignore" <<'IGNEOF'
*.md
!docs/real.md
IGNEOF
cat >"$PRISTINE/src/reexport.js" <<'JSEOF'
// See docs/real.md for the companion note.
JSEOF
rc=0; out="$(PDDA_MODE=full PDDA_REPO_ROOT="$PRISTINE" PDDA_GOVERNANCE_DOCS="" PDDA_ACTIVITY_LOG=/dev/null bash "$PDDA" governance 2>&1)" || rc=$?
if [ "$rc" -ne 0 ] && grep -Fq "comment reference 'docs/real.md'" <<<"$out"; then
  pass "a re-included (negation-rule) missing reference still fails — not swallowed by the exemption"
else
  fail "negation control: rc=$rc, expected docs/real.md reported dead: $out"
fi

# -- the generated-state skip is REPORTED (INFO), not silent ---------------------------------
rm -f "$PRISTINE/src/reexport.js"
printf '/.tick/\n' >"$PRISTINE/.gitignore"
rc=0; out="$(PDDA_MODE=full PDDA_REPO_ROOT="$PRISTINE" PDDA_GOVERNANCE_DOCS="" PDDA_ACTIVITY_LOG=/dev/null bash "$PDDA" governance 2>&1)" || rc=$?
[ "$rc" -eq 0 ] && grep -Fq "generated/ignored state" <<<"$out" \
  && pass "generated-state exemption is reported as an INFO finding, not invisible" \
  || fail "expected rc 0 with a visible generated-state INFO finding: rc=$rc out=$out"

# -- scanner failure degrades to the bash row builder — to slow, never to silence ------------
rm -f "$PRISTINE/.gitignore"
rc=0; out="$(PDDA_MODE=full PDDA_REPO_ROOT="$PRISTINE" PDDA_COMMENT_SCAN=/bin/false \
  PDDA_GOVERNANCE_DOCS="" PDDA_ACTIVITY_LOG=/dev/null bash "$PDDA" governance 2>&1)" || rc=$?
if [ "$rc" -ne 0 ] && grep -Fq "comment reference '.tick/STATE.md'" <<<"$out"; then
  pass "a failing Python scanner degrades to the bash builder and still catches the dead ref"
else
  fail "scanner-degrade control: rc=$rc — silence instead of findings: $out"
fi

echo "== gh414-comment-reference-check: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
