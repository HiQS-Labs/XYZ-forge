#!/usr/bin/env bash
# test/pdda-roadmap-coverage.sh — ROADMAP coverage must include active docs and parked GH inbox
# captures; also covers GH-189 (issue-doc-sync's 3-COMPLETED blind spot + the new
# roadmap-issue-state check) since this is the repo's only test/*pdda* fixture-repo harness.
source "$(dirname "$0")/_setup.sh" pdda-roadmap-coverage
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Consolidated runtime: roadmap-coverage is now a subcommand of the single utils/pdda/pdda.sh dispatcher.
CHECK="$ROOT/utils/pdda/pdda.sh"
CHECK_ARGS="roadmap-coverage"
TMP="$WORK/pdda"

mkdir -p "$TMP/PROJECT/1-INBOX" "$TMP/PROJECT/2-WORKING" "$TMP/PROJECT/3-COMPLETED" "$TMP/PROJECT/4-MISC"

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
printf '%s' "$OUTPUT" | grep -F "captured GH issue doc is not parked in ROADMAP.md" >/dev/null \
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


# --------------------------------------------------------------------------------------------------
# GH-189 — issue-doc-sync's 3-COMPLETED blind spot + the new roadmap-issue-state check
# --------------------------------------------------------------------------------------------------
# Cached issue-state file (PDDA_ISSUE_SYNC_SOURCE=cache) keeps this deterministic and offline: no
# live `gh` call, no network dependency, and #503 is deliberately left OUT of the cache to reproduce
# the gh-offline/no-cached-state degrade path.
GH_CACHE="$TMP/.pdda-gh-state.tsv"
cat >"$GH_CACHE" <<'EOF_CACHE'
501	CLOSED
502	OPEN
EOF_CACHE

# Scenario 1: a 3-COMPLETED doc whose frontmatter status is still a non-terminal lead word
# ("captured") while its issue is CLOSED — the exact GH-107 shape that motivated GH-189: sweeping a
# doc to 3-COMPLETED (the check's own recommended remediation) used to silence this check forever.
cat >"$TMP/PROJECT/3-COMPLETED/GH-501-STALE-COMPLETED.md" <<'EOF_501'
---
title: Swept to 3-COMPLETED but never reconciled
status: captured — not yet started
created: 2026-06-24
updated: 2026-06-24
owner: test
goal: reproduce GH-189
gh_issue: 501
---

Body.
EOF_501

# Scenario 2 (inverse, direction (b) no-regression proof): a 2-WORKING doc whose status already
# reads a terminal word ("shipped") while its issue is still OPEN — check_issue_doc_sync's
# pre-existing logic, unrelated to this fix, must keep firing.
cat >"$TMP/PROJECT/2-WORKING/GH-502-SHIPPED-BUT-OPEN.md" <<'EOF_502'
---
title: Doc claims done, issue still open
status: shipped
created: 2026-06-24
updated: 2026-06-24
owner: test
goal: reproduce direction (b), no regression
gh_issue: 502
---

## Status

| What was just completed | What's next |
|---|---|
| seeded | verify |
EOF_502

# Scenario 3: a doc tracking an issue with no cached (and no live, gh-offline) state — must degrade
# to an INFO "not evaluated" note, never a false warning or a hard error.
cat >"$TMP/PROJECT/2-WORKING/GH-503-NO-STATE.md" <<'EOF_503'
---
title: Issue state unavailable
status: Active
created: 2026-06-24
updated: 2026-06-24
owner: test
goal: reproduce gh-offline degrade
gh_issue: 503
---

## Status

| What was just completed | What's next |
|---|---|
| seeded | verify |
EOF_503

# ROADMAP.md ledger entries for the same three issues, exercising the new roadmap-issue-state check:
# #501 still carries a non-terminal 🆕 marker while its issue is CLOSED (should warn); #502 is
# deliberately NOT given a ROADMAP entry (issue-doc-sync direction (b) doesn't need one); #503 has no
# cached state either, so its ledger entry must also degrade to INFO, not a false warning.
cat >>"$TMP/ROADMAP.md" <<'EOF_GH189_ROADMAP'

## GH-189 regression ledger

- **GH-501 test entry** 🆕 **captured 2026-06-24** — still shows a non-terminal marker. → [#501](https://github.com/example/repo/issues/501)
- **GH-503 test entry** 🆕 **captured 2026-06-24** — issue state unavailable in this fixture. → [#503](https://github.com/example/repo/issues/503)
EOF_GH189_ROADMAP

ISSUE_DOC_SYNC_OUTPUT="$(
  PDDA_MODE=full \
  PDDA_REPO_ROOT="$TMP" \
  PDDA_WORKING_DIR="$TMP/PROJECT/2-WORKING" \
  PDDA_COMPLETED_DIR="$TMP/PROJECT/3-COMPLETED" \
  PDDA_ROADMAP="$TMP/ROADMAP.md" \
  PDDA_ACTIVITY_LOG="$TMP/activity.jsonl" \
  PDDA_GH_STATE_CACHE="$GH_CACHE" \
  PDDA_ISSUE_SYNC_SOURCE=cache \
  bash "$CHECK" issue-doc-sync 2>&1
)"

# GH-189 direction (c) — the 3-COMPLETED scan — was DELETED from the sync-managed upstream script by
# the 2026-08-03 PDDA sync (cfd56b0): `non-terminal` went from 4 occurrences in pdda.sh to 0, and the
# behaviour existed nowhere else in the repo. It now lives in utils/pdda-local-checks.sh, outside the
# sync surface, so the next upstream sync cannot delete it again. Directions (a) and (b) below still
# run against pdda.sh, which is what makes this a targeted move rather than a fork of the checker.
COMPLETED_STATUS_OUTPUT="$(
  PDDA_MODE=full \
  PDDA_REPO_ROOT="$TMP" \
  PDDA_WORKING_DIR="$TMP/PROJECT/2-WORKING" \
  PDDA_COMPLETED_DIR="$TMP/PROJECT/3-COMPLETED" \
  PDDA_ROADMAP="$TMP/ROADMAP.md" \
  PDDA_ACTIVITY_LOG="$TMP/activity.jsonl" \
  PDDA_GH_STATE_CACHE="$GH_CACHE" \
  PDDA_ISSUE_SYNC_SOURCE=cache \
  bash "$ROOT/utils/pdda-local-checks.sh" completed-status 2>&1
)"

printf '%s' "$COMPLETED_STATUS_OUTPUT" | grep -F "GH-501-STALE-COMPLETED.md" >/dev/null \
  && printf '%s' "$COMPLETED_STATUS_OUTPUT" | grep -F "non-terminal" >/dev/null \
  && pass "a 3-COMPLETED doc with a non-terminal status is flagged (GH-189, restored locally)" \
  || fail "the stale-status 3-COMPLETED doc was not flagged: $COMPLETED_STATUS_OUTPUT"

printf '%s' "$ISSUE_DOC_SYNC_OUTPUT" | grep -F "GH-502-SHIPPED-BUT-OPEN.md" >/dev/null \
  && printf '%s' "$ISSUE_DOC_SYNC_OUTPUT" | grep -F "doc status reads 'shipped'" >/dev/null \
  && pass "issue-doc-sync direction (b) still flags a 2-WORKING doc claiming done while its issue is OPEN (no regression)" \
  || fail "issue-doc-sync no longer flags the pre-existing direction (b) shipped-but-open case"

printf '%s' "$ISSUE_DOC_SYNC_OUTPUT" | grep -F "issue #503 state unavailable" >/dev/null \
  && pass "issue-doc-sync reports 'state unavailable' for a doc with no cached/live issue state" \
  || fail "issue-doc-sync did not degrade gracefully for the no-cached-state doc"

# This assertion used to require INFO severity — "no false WARN for a doc that isn't drifted". The
# 2026-08-03 PDDA sync (cfd56b0) deliberately raised it to WARN, with the reasoning stated in
# `utils/pdda/pdda.sh`: *"A check that could not run is NOT a check that passed. Warn, so `run` and
# the Stop hook say so."* That is the better contract — it is the same principle GH-400 applies to
# acceptance fidelity, where an unverifiable claim must be visibly absent rather than quietly
# assumed — so the TEST was stale, not the runtime. Unlike the GH-189 and GH-284 behaviours restored
# above, nothing was deleted here and there is nothing to restore.
#
# What still has to hold: the state must be REPORTED (never silently skipped) and must never
# escalate to ERROR, because an unreachable issue state is not a defect in the doc.
printf '%s\n' "$ISSUE_DOC_SYNC_OUTPUT" | grep -E '^(INFO|WARN) .*GH-503-NO-STATE\.md' >/dev/null \
  && pass "unevaluable issue state is reported for the no-cached-state doc (WARN since cfd56b0, was INFO)" \
  || fail "the no-cached-state doc was silently skipped: $ISSUE_DOC_SYNC_OUTPUT"

! printf '%s\n' "$ISSUE_DOC_SYNC_OUTPUT" | grep -E '^ERROR .*GH-503-NO-STATE\.md' >/dev/null \
  && pass "an unreachable issue state never escalates to ERROR" \
  || fail "unevaluable state was raised to ERROR for the no-cached-state doc"

ROADMAP_ISSUE_STATE_OUTPUT="$(
  PDDA_MODE=full \
  PDDA_REPO_ROOT="$TMP" \
  PDDA_ROADMAP="$TMP/ROADMAP.md" \
  PDDA_ACTIVITY_LOG="$TMP/activity.jsonl" \
  PDDA_GH_STATE_CACHE="$GH_CACHE" \
  PDDA_ISSUE_SYNC_SOURCE=cache \
  bash "$ROOT/utils/pdda-local-checks.sh" roadmap-issue-state 2>&1
)"

printf '%s' "$ROADMAP_ISSUE_STATE_OUTPUT" | grep -F "issue #501 is CLOSED but the ledger entry's status marker is still non-terminal" >/dev/null \
  && pass "roadmap-issue-state flags a ledger entry whose non-terminal marker drifted from a CLOSED issue (GH-189)" \
  || fail "roadmap-issue-state did not flag the stale non-terminal ledger entry"

printf '%s' "$ROADMAP_ISSUE_STATE_OUTPUT" | grep -F "issue #503 state unavailable" >/dev/null \
  && pass "roadmap-issue-state degrades to INFO 'state unavailable' for a ledger entry with no cached/live issue state" \
  || fail "roadmap-issue-state did not degrade gracefully for the no-cached-state ledger entry"

! printf '%s\n' "$ROADMAP_ISSUE_STATE_OUTPUT" | grep -E '^(WARN|ERROR) .*#503' >/dev/null \
  && pass "roadmap-issue-state raises no false warning/error for the no-cached-state ledger entry" \
  || fail "roadmap-issue-state raised a false warning/error for the no-cached-state ledger entry"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
