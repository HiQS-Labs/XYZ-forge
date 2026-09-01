#!/usr/bin/env bash
# GH-346: HARNESS-MODELS-REGISTRY.generated.md must match what harnesses.db would render.
#
# The gap this closes. Two files share a name and only one is machine-owned:
#
#   HARNESS-MODELS-REGISTRY.md            hand-written narrative — grades, evidence, flags.
#                                         Nothing generates it. Not checked here.
#   HARNESS-MODELS-REGISTRY.generated.md  rendered from harnesses.db by `harness_app.py gen`,
#                                         and its own header says DO NOT HAND-EDIT.
#
# Nothing ran `gen`. Not a hook, not CI, not validate.sh — the chain
# turn -> HarnessTurnLogger -> harnesses.db -> generated view had no final arrow, so the view
# drifted from the database it claims to render for as long as nobody remembered. Measured on
# 2026-08-31: SIX models present in the DB were missing from the committed view, including one
# recorded by a relay turn the same day.
#
# A generated file that silently disagrees with its source is worse than no generated file: it
# reads as authoritative. This makes the omission loud.
#
# Read-only: renders to a scratch directory and compares. It never rewrites the committed view --
# the fix is for a human to run `gen` and commit the result, so the diff is reviewable.
source "$(dirname "$0")/_setup.sh" gh346-registry-view-freshness
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VIEW="$ROOT/HARNESS-MODELS-REGISTRY.generated.md"
DB="$ROOT/harnesses.db"

if [ ! -f "$DB" ]; then
  pass "no harnesses.db in this clone — nothing to render (skipping)"
  echo "  $TEST_NAME: $PASS pass, $FAIL fail"
  exit 0
fi

[ -f "$VIEW" ] && pass "generated view is present" || fail "missing: $VIEW"

# Render into a scratch dir. harness_app.py resolves the view path beside XYZ_HARNESS_DB, so
# pointing that at a COPY of the DB keeps both the real DB and the committed view untouched.
cp "$DB" "$WORK/harnesses.db"
if XYZ_HARNESS_DB="$WORK/harnesses.db" python3 "$ROOT/utils/py/harness_app.py" gen >/dev/null 2>&1; then
  pass "harness_app.py gen renders without error"
else
  fail "harness_app.py gen failed — the generated view cannot be verified"
  echo "  $TEST_NAME: $PASS pass, $FAIL fail"
  exit 0
fi

FRESH="$WORK/HARNESS-MODELS-REGISTRY.generated.md"
if [ ! -f "$FRESH" ]; then
  fail "gen produced no view at $FRESH"
elif cmp -s "$VIEW" "$FRESH"; then
  pass "committed view matches what harnesses.db renders today"
else
  echo "  --- drift (committed vs freshly rendered) ---" >&2
  diff "$VIEW" "$FRESH" | head -20 >&2
  fail "HARNESS-MODELS-REGISTRY.generated.md is stale — run: python3 utils/py/harness_app.py gen"
fi

# The hand-written file must NOT be mistaken for the generated one, in either direction.
if grep -q "DO NOT HAND-EDIT" "$ROOT/HARNESS-MODELS-REGISTRY.md" 2>/dev/null; then
  fail "HARNESS-MODELS-REGISTRY.md carries the generated header — the two files have been confused"
else
  pass "the hand-written registry is not marked generated (the two stay distinct)"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
