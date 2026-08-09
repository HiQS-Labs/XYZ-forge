#!/usr/bin/env bash
# test/pdda-local-checks.sh — the checks the PDDA sync deleted, and the drift detector for them.
#
# On 2026-08-03 the sync in `cfd56b0` replaced `utils/pdda/**` wholesale and silently removed three
# behaviours this repo had added upstream: GH-189's 3-COMPLETED stale-status scan, GH-189's whole
# `roadmap-issue-state` SUBCOMMAND, and GH-284 Phase 3's missing-`Milestone:` warning. Their tests
# stayed, so CI went red on `development` and stayed red — read as "pre-existing noise" rather than
# as three features having been deleted. They now live in utils/pdda-local-checks.sh, outside the
# sync surface.
#
# This file is the guard on that arrangement. It is deliberately FALSIFIABLE: each check is run
# against a fixture that must trip it AND a fixture that must not, so a check that silently stopped
# detecting anything fails here instead of going quiet. A test that only asserted "exit 0" would
# pass against a check whose body had been deleted — which is exactly the failure being guarded.
source "$(dirname "$0")/_setup.sh" pdda-local-checks
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOCAL="$ROOT/utils/pdda-local-checks.sh"
TMP="$WORK/local"

mkdir -p "$TMP/PROJECT/2-WORKING" "$TMP/PROJECT/3-COMPLETED"

run_local() { # <subcommand>
  PDDA_MODE=full \
  PDDA_REPO_ROOT="$TMP" \
  PDDA_WORKING_DIR="$TMP/PROJECT/2-WORKING" \
  PDDA_COMPLETED_DIR="$TMP/PROJECT/3-COMPLETED" \
  PDDA_ROADMAP="$TMP/ROADMAP.md" \
  PDDA_ACTIVITY_LOG=/dev/null \
  PDDA_GH_STATE_CACHE="$TMP/.pdda-gh-state.tsv" \
  PDDA_ISSUE_SYNC_SOURCE=cache \
  PDDA_RELEASES_FILE="$TMP/RELEASES.md" \
  bash "$LOCAL" "$1" 2>&1
}

printf '601\tCLOSED\n602\tOPEN\n' >"$TMP/.pdda-gh-state.tsv"

# ── completed-status (GH-189, doc side) ───────────────────────────────────────────────────────────
cat >"$TMP/PROJECT/3-COMPLETED/GH-601-STALE.md" <<'EOF'
---
title: swept but never reconciled
status: captured — not yet started
gh_issue: 601
---
Body.
EOF
cat >"$TMP/PROJECT/3-COMPLETED/GH-602-CLEAN.md" <<'EOF'
---
title: properly reconciled
status: shipped 2026-08-03
gh_issue: 602
---
Body.
EOF

out="$(run_local completed-status)"
printf '%s' "$out" | grep -Fq "GH-601-STALE.md" \
  && pass "completed-status flags a 3-COMPLETED doc still reading a non-terminal status" \
  || fail "the stale completed doc was not flagged: $out"
printf '%s' "$out" | grep -Fq "GH-602-CLEAN.md" \
  && fail "a correctly-reconciled completed doc was wrongly flagged: $out" \
  || pass "completed-status leaves a terminal-status doc alone (no false positive)"

# ── roadmap-issue-state (GH-189, ledger side) ─────────────────────────────────────────────────────
cat >"$TMP/ROADMAP.md" <<'EOF'
# Roadmap

## Ledger

- **GH-601 entry** 🆕 **captured 2026-08-03** — marker still non-terminal. → [#601](https://github.com/example/repo/issues/601)
- **GH-602 entry** ✅ **SHIPPED 2026-08-03** — issue still open. → [#602](https://github.com/example/repo/issues/602)
EOF

out="$(run_local roadmap-issue-state)"
printf '%s' "$out" | grep -Fq "issue #601 is CLOSED but the ledger entry's status marker is still non-terminal" \
  && pass "roadmap-issue-state flags a non-terminal marker on a CLOSED issue" \
  || fail "the stale ledger marker was not flagged: $out"
printf '%s' "$out" | grep -Fq "issue #602 is still OPEN" \
  && pass "roadmap-issue-state flags a shipped marker on a still-OPEN issue (the inverse direction)" \
  || fail "the shipped-but-open ledger entry was not flagged: $out"

# ── release-milestone (GH-284 Phase 3) ────────────────────────────────────────────────────────────
cat >"$TMP/RELEASES.md" <<'EOF'
Release: 9.0.0
Status: Draft
Target Date: 2999-01-01
Codename: Nokey
Description: dated, unshipped, no milestone
GH_URL:

Release: 9.1.0
Status: Draft
Target Date: 2999-01-01
Codename: Haskey
Description: dated, unshipped, has one
GH_URL:
Milestone: Something
EOF

out="$(run_local release-milestone)"
printf '%s' "$out" | grep -Fq "release '9.0.0' has a Target Date but no 'Milestone:'" \
  && pass "release-milestone flags a dated, unshipped release with no join key" \
  || fail "the milestone-less release was not flagged: $out"
printf '%s' "$out" | grep -Fq "release '9.1.0'" \
  && fail "a release carrying a Milestone was wrongly flagged: $out" \
  || pass "release-milestone leaves a release with a Milestone alone (no false positive)"

# ── drift detector: the terminal-word list is COPIED from pdda.sh and must not silently diverge ────
# utils/pdda-local-checks.sh carries its own copy of PDDA_TERMINAL_STATUS_WORDS precisely so an
# upstream refactor cannot delete it. The cost of a copy is drift, so compare the two directly: if
# upstream changes what "done" means, this fails loudly instead of the two definitions disagreeing.
local_words="$(grep -E '^PDDA_TERMINAL_STATUS_WORDS=' "$LOCAL" | head -1)"
upstream_words="$(grep -E '^PDDA_TERMINAL_STATUS_WORDS=' "$ROOT/utils/pdda/pdda.sh" | head -1)"
if [ -z "$upstream_words" ]; then
  pass "upstream no longer defines PDDA_TERMINAL_STATUS_WORDS — the local copy is now the only definition"
elif [ "$local_words" = "$upstream_words" ]; then
  pass "the local terminal-word list still matches upstream's"
else
  fail "terminal-word list drifted from upstream — reconcile utils/pdda-local-checks.sh:
  local:    $local_words
  upstream: $upstream_words"
fi

# ── the real repository passes its own restored checks ────────────────────────────────────────────
# Warn-only by contract, so this asserts the checks RUN and REPORT rather than asserting silence —
# an "exit 0" assertion would pass against a deleted check body, which is the bug being guarded.
real_out="$(PDDA_ACTIVITY_LOG=/dev/null bash "$LOCAL" run 2>&1)"; real_rc=$?
# GH-460: grep the output through a FILE, never `printf "$real_out" | grep -q`. `grep -q` exits the
# instant it matches, and once this output outgrew the 64KB pipe buffer printf was still writing when
# the reader vanished — SIGPIPE, EPIPE, and under _setup.sh's `set -o pipefail` that became the
# pipeline's status, breaking the && chain and failing an assertion whose subject had not changed.
# That is the whole of the "tier1 flake": five consecutive runs went pass/fail/fail/pass/fail on
# identical code, because whether printf finished before grep exited was a race against a buffer every
# new 3-COMPLETED doc pushed it further past. Reading from a file has no reader to lose.
#
# The failure message now names WHICH summary is missing. It used to dump the entire run output and
# name nothing, which is why this was read as the GH-268 frontmatter WARN at the top of the dump —
# a warn-only advisory that was never the assertion — on two separate occasions.
real_out_file="$WORK/real-out.txt"
printf '%s\n' "$real_out" > "$real_out_file"
missing=""
for _c in completed-status roadmap-issue-state release-milestone; do
  grep -Fq "SUMMARY [pdda-local-check-$_c]" "$real_out_file" || missing="$missing pdda-local-check-$_c"
done
[ -z "$missing" ] \
  && pass "all three checks execute against the real repository and emit a summary" \
  || fail "check(s) did not run against the real repo:$missing
$real_out"
[ "$real_rc" -eq 0 ] \
  && pass "the local checks stay warn-only and never gate the exit code" \
  || fail "local checks gated the exit code (rc=$real_rc) — they are advisory by contract"

echo "  pdda-local-checks: $PASS pass, $FAIL fail"
exit 0
