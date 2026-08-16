#!/usr/bin/env bash
# test/tree-hygiene-guard.sh — issue #12 regression guard: keep non-source-tree content OUT of the
# repo root, and keep the xyz skill file in skill format.
#
# Background (issue #12, implementing PROJECT/1-INBOX/GLM-5.3-audit.txt recommendation 2): the dead
# `ingestion/` scaffold moved to docs/ingestion/ with ingest.js deleted outright, the checked-in
# marathon run logs moved to PROJECT/4-MISC/marathon-run-records/, and the 2,214-line
# skills/xyz/SKILL.md was split into a concise SKILL.md plus the exhaustive MANUAL.md. This guard
# asserts none of that grows back:
#   (a) no top-level ingestion/ directory
#   (b) no top-level marathon-system/ directory — a marathon run may RECREATE it at runtime
#       (utils/py/marathon_drive.py's default phases dir), but checked-in run records live under
#       PROJECT/4-MISC/marathon-run-records/ and a fresh run's output must not be committed back
#   (c) skills/xyz/SKILL.md stays in skill format (<= 350 lines; long form lives in MANUAL.md)
#
# Read-only assertions against the real tree — no fixtures, no git operations.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: tree-hygiene-guard (issue #12) =="

# Guard the resolved root at the use boundary (GH-564/GH-567): an empty or wrong REPO would turn
# the directory checks into false passes against some other tree. Anchor on paths that must exist
# in THIS repo before asserting anything about it.
if [ -z "$REPO" ] || [ ! -d "$REPO/skills/xyz" ] || [ ! -f "$REPO/README.md" ]; then
  fail "could not resolve the repository root (REPO='$REPO') — refusing to assert against the wrong tree"
  echo "  tree-hygiene-guard: $PASS passed, $FAIL failed"
  exit 1
fi

# (a) no top-level ingestion/ — docs live in docs/ingestion/, ingest.js is deleted.
if [ -e "$REPO/ingestion" ]; then
  fail "top-level ingestion/ exists — the scaffold docs belong in docs/ingestion/ and ingest.js was deleted (issue #12)"
else
  pass "no top-level ingestion/ directory"
fi

# (b) no top-level marathon-system/ — checked-in run records live in PROJECT/4-MISC/marathon-run-records/.
if [ -e "$REPO/marathon-system" ]; then
  fail "top-level marathon-system/ exists — checked-in run records live in PROJECT/4-MISC/marathon-run-records/ (issue #12); a marathon may create this dir at runtime, but its output must not be committed back"
else
  pass "no top-level marathon-system/ directory"
fi

# (c) skills/xyz/SKILL.md exists and stays in skill format (<= 350 lines).
SKILL="$REPO/skills/xyz/SKILL.md"
if [ ! -f "$SKILL" ]; then
  fail "skills/xyz/SKILL.md is missing"
else
  lines="$(wc -l < "$SKILL" | tr -d '[:space:]')"
  if [ "$lines" -le 350 ]; then
    pass "skills/xyz/SKILL.md is $lines lines (<= 350; long form lives in skills/xyz/MANUAL.md)"
  else
    fail "skills/xyz/SKILL.md is $lines lines (> 350) — move long-form content into skills/xyz/MANUAL.md"
  fi
fi

if [ "$FAIL" -gt 0 ]; then
  echo "  tree-hygiene-guard: $PASS passed, $FAIL failed"
  exit 1
fi
echo "  tree-hygiene-guard: $PASS passed, $FAIL failed"
exit 0
