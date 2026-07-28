#!/usr/bin/env bash
# GH-284 Phase 3 — RELEASES.md gains `Milestone:`, the release -> issue-set join key.
#
# A release must resolve to a SET of issues before it can drive marathon selection, and `GH_URL:`
# holds exactly one link. The linkage lives in GitHub (a milestone), so it maintains itself as issues
# open and close; RELEASES.md carries only the milestone TITLE.
#
# This file is also the first test the `pdda.sh releases` check has ever had — before Phase 3 it had
# none, so the pre-existing behaviors it must not break (empty version -> error, bad date -> warn,
# overdue -> warn, never gates the exit code) are pinned here too, not just the new field.
source "$(dirname "$0")/_setup.sh" gh284-p3-release-milestone
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PDDA="$ROOT/utils/pdda/pdda.sh"

# PDDA_RELEASES_FILE points the check at a fixture instead of the repo's real ledger.
run_releases() {  # <fixture-file>
  PDDA_RELEASES_FILE="$1" PDDA_ACTIVITY_LOG=/dev/null bash "$PDDA" releases 2>&1
}
run_current() {   # <fixture-file>
  PDDA_RELEASES_FILE="$1" PDDA_ACTIVITY_LOG=/dev/null bash "$PDDA" releases-current 2>&1
}

# ── (1) the new warning fires on a dated, unshipped release with no Milestone ────────────
F="$WORK/no-milestone.md"
cat > "$F" <<'EOF'
Release: 1.0.0
Status: Draft
Target Date: 2999-01-01
Codename: Testcodename
Description: no milestone here
GH_URL:
EOF
out="$(run_releases "$F")"; rc=$?
printf '%s' "$out" | grep -Fq "no 'Milestone:'" \
  && pass "dated unshipped release with no Milestone is warned" \
  || fail "expected a missing-Milestone warning, got: $out"
printf '%s' "$out" | grep -q "^WARN" \
  && pass "the missing-Milestone finding is a WARN, not an error" \
  || fail "missing-Milestone should be warn severity: $out"
[ "$rc" -eq 0 ] && pass "the check still never gates the exit code" \
  || fail "releases check must never block (exit $rc)"

# ── (2) supplying the Milestone silences it ──────────────────────────────────────────────
F="$WORK/with-milestone.md"
cat > "$F" <<'EOF'
Release: 1.0.0
Status: Draft
Target Date: 2999-01-01
Codename: Testcodename
Description: has a milestone
GH_URL:
Milestone: Quicksilver
EOF
out="$(run_releases "$F")"
printf '%s' "$out" | grep -Fq "no 'Milestone:'" \
  && fail "Milestone was present but the warning still fired: $out" \
  || pass "a populated Milestone silences the warning"

# ── (3) scoping: undated and shipped blocks stay quiet ───────────────────────────────────
# The example/placeholder block has no Target Date; backfilling history buys nothing.
F="$WORK/quiet.md"
cat > "$F" <<'EOF'
Release: 0.1.0
Status: Draft
Target Date:
Codename: n/a
Description: placeholder, no date
GH_URL:

Release: 0.9.0
Status: Shipped
Target Date: 2000-01-01
Codename: Ancient
Description: already out, never had a milestone
GH_URL:
EOF
out="$(run_releases "$F")"
printf '%s' "$out" | grep -Fq "no 'Milestone:'" \
  && fail "undated/shipped blocks must not be warned about: $out" \
  || pass "undated and Shipped blocks are exempt from the Milestone warning"

# ── (4) the pre-existing behaviors this check already had must survive ───────────────────
F="$WORK/legacy.md"
cat > "$F" <<'EOF'
Release:
Status: Draft
Target Date:
Codename: n/a
Description: empty version
GH_URL:
Milestone: X

Release: 2.0.0
Status: Draft
Target Date: not-a-date
Codename: n/a
Description: malformed date
GH_URL:
Milestone: X

Release: 3.0.0
Status: Draft
Target Date: 2000-01-01
Codename: n/a
Description: overdue and unshipped
GH_URL:
Milestone: X
EOF
out="$(run_releases "$F")"; rc=$?
printf '%s' "$out" | grep -Fq "has no version" \
  && pass "empty Release: version still reported" \
  || fail "empty-version error regressed: $out"
printf '%s' "$out" | grep -Fq "is not a valid YYYY-MM-DD date" \
  && pass "malformed Target Date still warned" \
  || fail "bad-date warning regressed: $out"
printf '%s' "$out" | grep -Fq "overdue" \
  && pass "overdue unshipped release still warned" \
  || fail "overdue warning regressed: $out"
[ "$rc" -eq 0 ] && pass "an error finding still does not gate the exit code" \
  || fail "the releases check must stay warn-only in spirit (exit $rc)"

# ── (5) the roll-up surfaces the join key, and says so when it is missing ────────────────
F="$WORK/rollup.md"
cat > "$F" <<'EOF'
Release: 4.0.0
Status: Draft
Target Date: 2999-01-01
Codename: Withkey
Description: has one
GH_URL:
Milestone: Quicksilver

Release: 5.0.0
Status: Draft
Target Date: 2999-01-01
Codename: Withoutkey
Description: has none
GH_URL:
EOF
out="$(run_current "$F")"
printf '%s' "$out" | grep -Fq "Milestone: Quicksilver" \
  && pass "releases-current prints the milestone when set" \
  || fail "roll-up did not show the milestone: $out"
printf '%s' "$out" | grep -Fq "cannot resolve to an issue set" \
  && pass "releases-current says so explicitly when the milestone is absent" \
  || fail "roll-up must not silently omit a missing milestone: $out"

# ── (6) the field must not shift the other parsed fields ─────────────────────────────────
# Milestone was appended to a \037-delimited record. A mis-ordered read would silently hand
# `line_no` to `milestone` (or vice versa) and every assertion above could still pass by accident.
F="$WORK/ordering.md"
cat > "$F" <<'EOF'
Release: 6.0.0
Status: Draft
Target Date: 2999-01-01
Codename: Ordercheck
Description: DESCRIPTION-SENTINEL
GH_URL: GHURL-SENTINEL
Milestone: MILESTONE-SENTINEL
EOF
out="$(run_current "$F")"
printf '%s' "$out" | grep -Fq "DESCRIPTION-SENTINEL" \
  && pass "Description still lands in the Description slot" \
  || fail "field ordering broke: Description missing from $out"
printf '%s' "$out" | grep -Fq "GHURL-SENTINEL" \
  && pass "GH_URL still lands in the GH_URL slot" \
  || fail "field ordering broke: GH_URL missing from $out"
printf '%s' "$out" | grep -Fq "Milestone: MILESTONE-SENTINEL" \
  && pass "Milestone lands in its own slot, not shifted" \
  || fail "field ordering broke: Milestone missing or shifted in $out"

# ── (7) the repo's own ledger satisfies the contract it just documented ──────────────────
out="$(PDDA_ACTIVITY_LOG=/dev/null bash "$PDDA" releases 2>&1)"
printf '%s' "$out" | grep -Fq "no 'Milestone:'" \
  && fail "this repo's own RELEASES.md has a dated release with no Milestone: $out" \
  || pass "the repo's RELEASES.md carries a Milestone for every dated, unshipped release"

echo "  gh284-p3-release-milestone: $PASS pass, $FAIL fail"
exit 0
