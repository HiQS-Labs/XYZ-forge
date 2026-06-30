#!/usr/bin/env bash
# test/pdda-roadmap-coverage.sh — ROADMAP coverage must include active docs and parked GH inbox captures
source "$(dirname "$0")/_setup.sh" pdda-roadmap-coverage
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Consolidated runtime: roadmap-coverage is now a subcommand of the single utils/pdda/pdda.sh dispatcher.
CHECK="$ROOT/utils/pdda/pdda.sh"
CHECK_ARGS="roadmap-coverage"
TMP="$WORK/pdda"

mkdir -p "$TMP/PROJECT/1-INBOX" "$TMP/PROJECT/2-WORKING" "$TMP/PROJECT/4-MISC"

cat >"$TMP/PROJECT/2-WORKING/ACTIVE.md" <<'EOF_WORKING'
---
title: Active doc
status: Active
created: 2026-06-24
updated: 2026-06-24
owner: test
goal: test coverage
---

## Status

| What was just completed | What's next |
|---|---|
| seeded | verify |
EOF_WORKING

cat >"$TMP/PROJECT/1-INBOX/GH-1234-TEST.md" <<'EOF_INBOX'
---
gh_issue: 1234
source: https://example.com/issues/1234
title: Test intake
status: Proposed (1-INBOX — not yet active)
created: 2026-06-24
doc_type: bugfix
---

Short capture.
EOF_INBOX

cat >"$TMP/ROADMAP.md" <<'EOF_ROADMAP'
# Roadmap

## In progress

- Active doc → [ACTIVE.md](PROJECT/2-WORKING/ACTIVE.md)
EOF_ROADMAP

set +e
OUTPUT="$(
  PDDA_MODE=full \
  PDDA_REPO_ROOT="$TMP" \
  PDDA_WORKING_DIR="$TMP/PROJECT/2-WORKING" \
  PDDA_INBOX_DIR="$TMP/PROJECT/1-INBOX" \
  PDDA_ROADMAP="$TMP/ROADMAP.md" \
  PDDA_ACTIVITY_LOG="$TMP/activity.jsonl" \
  bash "$CHECK" $CHECK_ARGS 2>&1
)"
STATUS=$?
set -e

[ "$STATUS" -ne 0 ] && pass "coverage check fails when a GH inbox capture is not parked in ROADMAP.md" \
  || fail "coverage check passed even though the GH inbox capture was missing from ROADMAP.md"
printf '%s' "$OUTPUT" | grep -Fq "captured GH issue doc is not parked in ROADMAP.md" \
  && pass "missing parked GH inbox capture reports the correct failure" \
  || fail "missing parked GH inbox capture did not report the expected error"

cat >>"$TMP/ROADMAP.md" <<'EOF_QUEUE'

## Queue / parked intake

- Test intake → [GH-1234-TEST.md](PROJECT/1-INBOX/GH-1234-TEST.md)
EOF_QUEUE

PDDA_MODE=full \
PDDA_REPO_ROOT="$TMP" \
PDDA_WORKING_DIR="$TMP/PROJECT/2-WORKING" \
PDDA_INBOX_DIR="$TMP/PROJECT/1-INBOX" \
PDDA_ROADMAP="$TMP/ROADMAP.md" \
PDDA_ACTIVITY_LOG="$TMP/activity.jsonl" \
bash "$CHECK" $CHECK_ARGS >/dev/null 2>&1 \
  && pass "coverage check passes once the GH inbox capture is parked in ROADMAP.md" \
  || fail "coverage check still failed after adding the GH inbox capture to ROADMAP.md"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
