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

echo "== gh414-comment-reference-check: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
