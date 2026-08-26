#!/usr/bin/env bash
# GH-197 — Two-tier xyz-vendor.sh: Tier 1 core harness default, Tier 2 opt-in RELEASES overlay + onboarding SOP.
# Covers:
#   1. Tier 1 default vendor: zero overlay files in .xyz/, core harness intact, tier=1 in VERSION.
#   2. Tier 2 explicit opt-in (--with-releases): full overlay + RELEASES-DB-FAQS.md in .xyz/, tier=2 in VERSION.
#   3. Sticky Tier 2 auto-detection via releases.db at target root (LTVera-Pandas shape).
#   4. GH-312 pin: RELEASES overlay runtime state lives at target root, writing nothing under .xyz/.
#   5. xyz-releases-onboard.sh happy path: legacy RELEASES.md -> DB, banner prepended, reconcile clean, no commit made.
#   6. Gitignore carve-out: appended exactly once, only when a *.db-style rule exists.
#   7. Shared-tracking-URL collision: report + nonzero stop, no auto-filing.
#   8. Re-vendor preserves adoption (sticky Tier 2 across update).

source "$(dirname "$0")/_setup.sh" gh197-vendor-tier-split

ROOT="$(cd -P "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/relay-automation/xyz-vendor.sh"
ONBOARD="$ROOT/relay-automation/xyz-releases-onboard.sh"
SYNC="$ROOT/relay-automation/xyz-sync.sh"
APP="$ROOT/utils/py/releases_app.py"

for f in "$VENDOR" "$ONBOARD" "$SYNC" "$APP"; do
  [ -f "$f" ] && pass "file exists: ${f#$ROOT/}" || fail "missing file: ${f#$ROOT/}"
done

export XYZ_REGISTRY="$WORK/registry.tsv"

# --- 1. Tier 1 default vendor (no flag) ---
mkdir -p "$WORK/tier1"; git init -q "$WORK/tier1"; T1_REPO="$(cd "$WORK/tier1" && pwd -P)"
"$VENDOR" "$T1_REPO" >/dev/null 2>&1 || fail "Tier 1 vendor exited non-zero"

[ -d "$T1_REPO/.xyz" ] && pass "Tier 1: .xyz/ materialized" || fail "Tier 1: .xyz/ missing"
[ -x "$T1_REPO/.xyz/bin/tick" ] && pass "Tier 1: bin/tick present and executable" || fail "Tier 1: bin/tick missing or not executable"
[ -f "$T1_REPO/.xyz/relay-automation/relay-turn-lib.sh" ] && pass "Tier 1: relay-turn-lib.sh present" || fail "Tier 1: relay-turn-lib.sh missing"
[ -f "$T1_REPO/.xyz/utils/swarm-preflight.sh" ] && pass "Tier 1: utils/swarm-preflight.sh present" || fail "Tier 1: utils/swarm-preflight.sh missing"
[ -f "$T1_REPO/.xyz/utils/py/rtl.py" ] && pass "Tier 1: utils/py/rtl.py present" || fail "Tier 1: utils/py/rtl.py missing"

# Assert zero overlay files land in Tier 1
[ ! -e "$T1_REPO/.xyz/relay-automation/xyz-releases-onboard.sh" ] && pass "Tier 1: xyz-releases-onboard.sh excluded" || fail "Tier 1: xyz-releases-onboard.sh present"
[ ! -e "$T1_REPO/.xyz/utils/py/releases_app.py" ] && pass "Tier 1: releases_app.py excluded" || fail "Tier 1: releases_app.py present"
[ ! -e "$T1_REPO/.xyz/utils/py/releases_cycle.py" ] && pass "Tier 1: releases_cycle.py excluded" || fail "Tier 1: releases_cycle.py present"
[ ! -e "$T1_REPO/.xyz/utils/releases-merge-resolve.sh" ] && pass "Tier 1: releases-merge-resolve.sh excluded" || fail "Tier 1: releases-merge-resolve.sh present"
[ ! -e "$T1_REPO/.xyz/utils/release-lanes.sh" ] && pass "Tier 1: release-lanes.sh excluded" || fail "Tier 1: release-lanes.sh present"
[ ! -e "$T1_REPO/.xyz/utils/timeline" ] && pass "Tier 1: utils/timeline excluded" || fail "Tier 1: utils/timeline present"
[ ! -e "$T1_REPO/.xyz/RELEASES-DB-FAQS.md" ] && pass "Tier 1: RELEASES-DB-FAQS.md excluded" || fail "Tier 1: RELEASES-DB-FAQS.md present"
grep -Fqx 'tier=1' "$T1_REPO/.xyz/VERSION" && pass "Tier 1: VERSION has tier=1" || fail "Tier 1: VERSION missing tier=1"

# --- 2. Tier 2 explicit opt-in (--with-releases) ---
mkdir -p "$WORK/tier2"; git init -q "$WORK/tier2"; T2_REPO="$(cd "$WORK/tier2" && pwd -P)"
"$VENDOR" "$T2_REPO" --with-releases >/dev/null 2>&1 || fail "Tier 2 vendor exited non-zero"

[ -f "$T2_REPO/.xyz/relay-automation/xyz-releases-onboard.sh" ] && pass "Tier 2: xyz-releases-onboard.sh present" || fail "Tier 2: xyz-releases-onboard.sh missing"
[ -f "$T2_REPO/.xyz/utils/py/releases_app.py" ] && pass "Tier 2: releases_app.py present" || fail "Tier 2: releases_app.py missing"
[ -f "$T2_REPO/.xyz/utils/py/releases_cycle.py" ] && pass "Tier 2: releases_cycle.py present" || fail "Tier 2: releases_cycle.py missing"
[ -f "$T2_REPO/.xyz/utils/releases-merge-resolve.sh" ] && pass "Tier 2: releases-merge-resolve.sh present" || fail "Tier 2: releases-merge-resolve.sh missing"
[ -f "$T2_REPO/.xyz/utils/release-lanes.sh" ] && pass "Tier 2: release-lanes.sh present" || fail "Tier 2: release-lanes.sh missing"
[ -d "$T2_REPO/.xyz/utils/timeline" ] && pass "Tier 2: utils/timeline present" || fail "Tier 2: utils/timeline missing"
[ -f "$T2_REPO/.xyz/utils/timeline/export_timeline.py" ] && pass "Tier 2: timeline export_timeline.py present" || fail "Tier 2: timeline exporter missing"
[ -f "$T2_REPO/.xyz/RELEASES-DB-FAQS.md" ] && pass "Tier 2: RELEASES-DB-FAQS.md staged into .xyz/" || fail "Tier 2: RELEASES-DB-FAQS.md missing from .xyz/"
grep -Fqx 'tier=2' "$T2_REPO/.xyz/VERSION" && pass "Tier 2: VERSION has tier=2" || fail "Tier 2: VERSION missing tier=2"

# --- 3. Sticky Tier 2 auto-detection via releases.db at target root ---
mkdir -p "$WORK/sticky"; git init -q "$WORK/sticky"; STICKY_REPO="$(cd "$WORK/sticky" && pwd -P)"
touch "$STICKY_REPO/releases.db"
out="$("$VENDOR" "$STICKY_REPO" 2>&1)"; rc=$?
[ "$rc" = 0 ] && pass "Sticky Tier 2: vendor exited 0" || fail "Sticky Tier 2: vendor failed (exit $rc)"
grep -Fq "releases.db detected at target root" <<< "$out" \
  && pass "Sticky Tier 2: emitted auto-detect notification on stdout" \
  || fail "Sticky Tier 2: missing stdout notification"
[ -f "$STICKY_REPO/.xyz/relay-automation/xyz-releases-onboard.sh" ] && pass "Sticky Tier 2: landed xyz-releases-onboard.sh" || fail "Sticky Tier 2: missing xyz-releases-onboard.sh"
[ -f "$STICKY_REPO/.xyz/utils/py/releases_app.py" ] && pass "Sticky Tier 2: landed releases_app.py without --with-releases flag" || fail "Sticky Tier 2: missing overlay"
[ -f "$STICKY_REPO/.xyz/RELEASES-DB-FAQS.md" ] && pass "Sticky Tier 2: landed RELEASES-DB-FAQS.md" || fail "Sticky Tier 2: missing FAQ doc"
grep -Fqx 'tier=2' "$STICKY_REPO/.xyz/VERSION" && pass "Sticky Tier 2: VERSION has tier=2" || fail "Sticky Tier 2: VERSION missing tier=2"

# --- 4. GH-312 pin: RELEASES overlay runtime state lives at target root, writing nothing under .xyz/ ---
mkdir -p "$WORK/gh312_pin"; git init -q "$WORK/gh312_pin"; PIN_REPO="$(cd "$WORK/gh312_pin" && pwd -P)"
"$VENDOR" "$PIN_REPO" --with-releases >/dev/null 2>&1

# Snapshot .xyz/ tree structure and file checksums before releases operations
( cd "$PIN_REPO/.xyz" && find . | sort ) > "$WORK/xyz_tree_before.txt"
( cd "$PIN_REPO/.xyz" && find . -type f -exec cksum {} + | sort ) > "$WORK/xyz_cksum_before.txt"

cat > "$PIN_REPO/RELEASES.md" <<'EOF'
Release: 0.1.0
Status: shipped
Codename: Genesis
Target Date: 2026-01-01
Tracking Issue: https://github.com/test-org/pin-repo/issues/1
Description: Initial release.
EOF

python3 "$PIN_REPO/.xyz/utils/py/releases_app.py" --root "$PIN_REPO" init --slug "pin-repo" >/dev/null 2>&1 || fail "PIN: releases init failed"
python3 "$PIN_REPO/.xyz/utils/py/releases_app.py" --root "$PIN_REPO" import "$PIN_REPO/RELEASES.md" >/dev/null 2>&1 || fail "PIN: releases import failed"
python3 "$PIN_REPO/.xyz/utils/py/releases_app.py" --root "$PIN_REPO" check >/dev/null 2>&1 || fail "PIN: releases check failed"

[ -f "$PIN_REPO/releases.db" ] && pass "GH-312 pin: releases.db lives at target root" || fail "GH-312 pin: releases.db not at root"
[ -f "$PIN_REPO/releases.sql" ] && pass "GH-312 pin: releases.sql lives at target root" || fail "GH-312 pin: releases.sql not at root"

# Snapshot .xyz/ tree structure and file checksums after releases operations
( cd "$PIN_REPO/.xyz" && find . | sort ) > "$WORK/xyz_tree_after.txt"
( cd "$PIN_REPO/.xyz" && find . -type f -exec cksum {} + | sort ) > "$WORK/xyz_cksum_after.txt"

diff -u "$WORK/xyz_tree_before.txt" "$WORK/xyz_tree_after.txt" \
  && pass "GH-312 pin: .xyz/ directory tree unchanged by releases operations (no additions/removals)" \
  || fail "GH-312 pin: .xyz/ directory tree changed by releases operations"
diff -u "$WORK/xyz_cksum_before.txt" "$WORK/xyz_cksum_after.txt" \
  && pass "GH-312 pin: .xyz/ file contents byte-identical after releases operations" \
  || fail "GH-312 pin: .xyz/ file contents mutated by releases operations"

# --- 5. xyz-releases-onboard.sh happy path ---
mkdir -p "$WORK/onboard_happy"; git init -q "$WORK/onboard_happy"; OB_REPO="$(cd "$WORK/onboard_happy" && pwd -P)"
git -C "$OB_REPO" remote add origin "https://github.com/test-org/happy-repo.git"
"$VENDOR" "$OB_REPO" >/dev/null 2>&1 || fail "Initial Tier 1 vendor of OB_REPO failed"

cat > "$OB_REPO/RELEASES.md" <<'EOF'
Release: 0.1.0
Status: shipped
Codename: Alpha
Target Date: 2026-01-10
Tracking Issue: #101
Description: Alpha milestone.

Release: 0.2.0
Status: draft
Codename: Beta
Target Date: 2026-02-20
Tracking Issue: #102
Description: Beta milestone.
EOF

out="$("$ONBOARD" "$OB_REPO" 2>&1)"; rc=$?
[ "$rc" = 0 ] && pass "Onboard happy path: exited 0" || fail "Onboard happy path: failed with exit $rc ($out)"
[ -f "$OB_REPO/releases.db" ] && pass "Onboard happy path: releases.db created" || fail "Onboard happy path: releases.db missing"
[ -f "$OB_REPO/releases.sql" ] && pass "Onboard happy path: releases.sql created" || fail "Onboard happy path: releases.sql missing"
grep -Fq "<!-- This file is app-managed (GH-32)" "$OB_REPO/RELEASES.md" \
  && pass "Onboard happy path: app-managed banner prepended to RELEASES.md" \
  || fail "Onboard happy path: missing app-managed banner"

# Check reconcile mapped MIG- refs to github URLs
url_count=$(sqlite3 "$OB_REPO/releases.db" "SELECT count(*) FROM issue_refs WHERE url LIKE 'https://github.com/test-org/happy-repo/issues/%';")
[ "$url_count" = "2" ] && pass "Onboard happy path: both MIG- refs reconciled to full URLs" || fail "Onboard happy path: reconciled $url_count/2 URLs"

# Check consistency check clean
python3 "$APP" --root "$OB_REPO" check >/dev/null 2>&1 \
  && pass "Onboard happy path: releases check passes cleanly" \
  || fail "Onboard happy path: releases check failed"

# Check commit command printed on stdout, but NO commit was made
grep -Fq "git commit -m" <<< "$out" \
  && pass "Onboard happy path: commit command printed" \
  || fail "Onboard happy path: commit command not printed"
[ "$(git -C "$OB_REPO" rev-list --count HEAD 2>/dev/null || echo 0)" = 0 ] \
  && pass "Onboard happy path: no git commit was made automatically" \
  || fail "Onboard happy path: unexpectedly created a git commit"

# --- 6. Gitignore carve-out appended exactly once, only when *.db rule exists ---
mkdir -p "$WORK/gi_repo"; git init -q "$WORK/gi_repo"; GI_REPO="$(cd "$WORK/gi_repo" && pwd -P)"
git -C "$GI_REPO" remote add origin "https://github.com/test-org/gi-repo.git"
printf '*.db\nbuild/\n' > "$GI_REPO/.gitignore"
cat > "$GI_REPO/RELEASES.md" <<'EOF'
Release: 0.1.0
Status: draft
Codename: Single
Target Date: 2026-03-01
Tracking Issue: #201
Description: Single release.
EOF

"$ONBOARD" "$GI_REPO" >/dev/null 2>&1 || fail "GI repo onboard failed"
grep -Fqx '!releases.db' "$GI_REPO/.gitignore" \
  && pass "Gitignore carve-out: !releases.db appended when *.db exists" \
  || fail "Gitignore carve-out: !releases.db missing"

carve_count=$(grep -c '^\!releases\.db$' "$GI_REPO/.gitignore")
[ "$carve_count" = 1 ] && pass "Gitignore carve-out: present exactly once" || fail "Gitignore carve-out: count is $carve_count (expected 1)"

# 6b. Idempotent assertion: onboarding a repo that ALREADY has !releases.db in .gitignore preserves it exactly once
mkdir -p "$WORK/pre_carved_repo"; git init -q "$WORK/pre_carved_repo"; PC_REPO="$(cd "$WORK/pre_carved_repo" && pwd -P)"
git -C "$PC_REPO" remote add origin "https://github.com/test-org/pc-repo.git"
printf '*.db\n!releases.db\nbuild/\n' > "$PC_REPO/.gitignore"
cat > "$PC_REPO/RELEASES.md" <<'EOF'
Release: 0.1.0
Status: draft
Codename: PreCarved
Target Date: 2026-03-01
Tracking Issue: #401
Description: Pre-carved release.
EOF

"$ONBOARD" "$PC_REPO" >/dev/null 2>&1 || fail "Pre-carved repo onboard failed"
carve_count_pc=$(grep -c '^\!releases\.db$' "$PC_REPO/.gitignore" || echo 0)
[ "$carve_count_pc" = 1 ] && pass "Gitignore carve-out: preserved exactly once when already present in .gitignore" || fail "Gitignore carve-out: duplicate added ($carve_count_pc)"

# 6c. Missing .gitignore with .git/info/exclude rule creates .gitignore with carve-out
mkdir -p "$WORK/exclude_repo"; git init -q "$WORK/exclude_repo"; EX_REPO="$(cd "$WORK/exclude_repo" && pwd -P)"
git -C "$EX_REPO" remote add origin "https://github.com/test-org/ex-repo.git"
mkdir -p "$EX_REPO/.git/info"
printf '*.db\n' >> "$EX_REPO/.git/info/exclude"
cat > "$EX_REPO/RELEASES.md" <<'EOF'
Release: 0.1.0
Status: draft
Codename: Exclude
Target Date: 2026-03-01
Tracking Issue: #402
Description: Exclude release.
EOF

[ ! -f "$EX_REPO/.gitignore" ] || fail "Exclude repo: .gitignore should not exist prior to onboard"
"$ONBOARD" "$EX_REPO" >/dev/null 2>&1 || fail "Exclude repo onboard failed"
[ -f "$EX_REPO/.gitignore" ] && pass "Gitignore carve-out: .gitignore created when rule lives in info/exclude" || fail "Gitignore carve-out: .gitignore was not created"
grep -Fqx '!releases.db' "$EX_REPO/.gitignore" \
  && pass "Gitignore carve-out: !releases.db added to newly-created .gitignore" \
  || fail "Gitignore carve-out: !releases.db missing from newly-created .gitignore"
! git -C "$EX_REPO" check-ignore -q releases.db \
  && pass "Gitignore carve-out: releases.db is now trackable despite info/exclude rule" \
  || fail "Gitignore carve-out: releases.db remains ignored"

# 6d. Negative case: repo without *.db ignore rule does NOT get !releases.db appended
mkdir -p "$WORK/no_gi_repo"; git init -q "$WORK/no_gi_repo"; NGI_REPO="$(cd "$WORK/no_gi_repo" && pwd -P)"
git -C "$NGI_REPO" remote add origin "https://github.com/test-org/no-gi-repo.git"
printf 'node_modules/\n' > "$NGI_REPO/.gitignore"
cat > "$NGI_REPO/RELEASES.md" <<'EOF'
Release: 0.1.0
Status: draft
Codename: Plain
Target Date: 2026-03-01
Tracking Issue: #301
Description: Plain release.
EOF

"$ONBOARD" "$NGI_REPO" >/dev/null 2>&1 || fail "NGI repo onboard failed"
! grep -q '!releases\.db' "$NGI_REPO/.gitignore" \
  && pass "Gitignore carve-out: NOT added when *.db rule is absent" \
  || fail "Gitignore carve-out: unexpectedly added without *.db rule"

# --- 7. Shared-tracking-URL collision detection & recovery ---
mkdir -p "$WORK/collide_repo"; git init -q "$WORK/collide_repo"; COL_REPO="$(cd "$WORK/collide_repo" && pwd -P)"
git -C "$COL_REPO" remote add origin "https://github.com/test-org/col-repo.git"
cat > "$COL_REPO/RELEASES.md" <<'EOF'
Release: 0.1.0
Status: shipped
Codename: First
Target Date: 2026-01-01
Tracking Issue: #555
Description: First release.

Release: 0.2.0
Status: draft
Codename: Second
Target Date: 2026-02-01
Tracking Issue: #555
Description: Second release reusing the same tracking issue.
EOF

if col_out="$("$ONBOARD" "$COL_REPO" 2>&1)"; then
  col_rc=0
else
  col_rc=$?
fi
[ "$col_rc" -ne 0 ] \
  && pass "Shared-tracking-URL collision: non-zero exit on collision ($col_rc)" \
  || fail "Shared-tracking-URL collision: unexpectedly succeeded (exit $col_rc)"

grep -qi "collision" <<< "$col_out" \
  && pass "Shared-tracking-URL collision: reports collision on stderr/stdout" \
  || fail "Shared-tracking-URL collision: collision message not found ($col_out)"

grep -Fq "https://github.com/test-org/col-repo/issues/555" <<< "$col_out" \
  && pass "Shared-tracking-URL collision: names colliding URL in report" \
  || fail "Shared-tracking-URL collision: colliding URL not named"

grep -Fq "0.1.0" <<< "$col_out" && grep -Fq "0.2.0" <<< "$col_out" \
  && pass "Shared-tracking-URL collision: names both colliding versions in report" \
  || fail "Shared-tracking-URL collision: colliding versions not named in report"

# Ensure target repo was NOT mutated and left half-onboarded
[ ! -e "$COL_REPO/releases.db" ] \
  && pass "Shared-tracking-URL collision: releases.db was NOT created at root" \
  || fail "Shared-tracking-URL collision: releases.db leaked to target root"
[ ! -e "$COL_REPO/releases.sql" ] \
  && pass "Shared-tracking-URL collision: releases.sql was NOT created at root" \
  || fail "Shared-tracking-URL collision: releases.sql leaked to target root"
! grep -q "<!-- This file is app-managed" "$COL_REPO/RELEASES.md" \
  && pass "Shared-tracking-URL collision: RELEASES.md was NOT mutated" \
  || fail "Shared-tracking-URL collision: RELEASES.md was mutated"

# Verify recovery / retry path: fix the collision in RELEASES.md and re-run onboarding
cat > "$COL_REPO/RELEASES.md" <<'EOF'
Release: 0.1.0
Status: shipped
Codename: First
Target Date: 2026-01-01
Tracking Issue: #555
Description: First release.

Release: 0.2.0
Status: draft
Codename: Second
Target Date: 2026-02-01
Tracking Issue: #556
Description: Second release with fixed tracking issue.
EOF

if col_retry_out="$("$ONBOARD" "$COL_REPO" 2>&1)"; then
  col_retry_rc=0
else
  col_retry_rc=$?
fi
[ "$col_retry_rc" = 0 ] \
  && pass "Shared-tracking-URL collision: recovery succeeds on retry after fixing duplicate" \
  || fail "Shared-tracking-URL collision: retry failed after fixing duplicate ($col_retry_out)"
[ -f "$COL_REPO/releases.db" ] \
  && pass "Shared-tracking-URL collision: releases.db created on successful retry" \
  || fail "Shared-tracking-URL collision: releases.db missing on retry"

# --- 7b. Full-URL duplicate fixture: two releases using the same canonical URL directly ---
mkdir -p "$WORK/collide_full_url_repo"; git init -q "$WORK/collide_full_url_repo"; FULL_COL_REPO="$(cd "$WORK/collide_full_url_repo" && pwd -P)"
git -C "$FULL_COL_REPO" remote add origin "https://github.com/test-org/full-col-repo.git"
cat > "$FULL_COL_REPO/RELEASES.md" <<'EOF'
Release: 1.0.0
Status: shipped
Codename: FullOne
Target Date: 2026-01-01
Tracking Issue: https://github.com/test-org/full-col-repo/issues/999
Description: First canonical release.

Release: 1.1.0
Status: draft
Codename: FullTwo
Target Date: 2026-02-01
Tracking Issue: https://github.com/test-org/full-col-repo/issues/999
Description: Second canonical release reusing the same full URL.
EOF

if full_col_out="$("$ONBOARD" "$FULL_COL_REPO" 2>&1)"; then
  full_col_rc=0
else
  full_col_rc=$?
fi
[ "$full_col_rc" -ne 0 ] \
  && pass "Full-URL collision: non-zero exit on full URL collision ($full_col_rc)" \
  || fail "Full-URL collision: unexpectedly succeeded (exit $full_col_rc)"

grep -qi "collision" <<< "$full_col_out" \
  && pass "Full-URL collision: reports collision on stderr/stdout" \
  || fail "Full-URL collision: collision message not found ($full_col_out)"

grep -Fq "https://github.com/test-org/full-col-repo/issues/999" <<< "$full_col_out" \
  && pass "Full-URL collision: names colliding URL in report" \
  || fail "Full-URL collision: colliding URL not named"

grep -Fq "1.0.0" <<< "$full_col_out" && grep -Fq "1.1.0" <<< "$full_col_out" \
  && pass "Full-URL collision: names both colliding versions in report" \
  || fail "Full-URL collision: colliding versions not named in report"

[ ! -e "$FULL_COL_REPO/releases.db" ] \
  && pass "Full-URL collision: releases.db was NOT created at root" \
  || fail "Full-URL collision: releases.db leaked to target root"
[ ! -e "$FULL_COL_REPO/releases.sql" ] \
  && pass "Full-URL collision: releases.sql was NOT created at root" \
  || fail "Full-URL collision: releases.sql leaked to target root"
! grep -q "<!-- This file is app-managed" "$FULL_COL_REPO/RELEASES.md" \
  && pass "Full-URL collision: RELEASES.md was NOT mutated" \
  || fail "Full-URL collision: RELEASES.md was mutated"

# Verify recovery for full URL duplicate
cat > "$FULL_COL_REPO/RELEASES.md" <<'EOF'
Release: 1.0.0
Status: shipped
Codename: FullOne
Target Date: 2026-01-01
Tracking Issue: https://github.com/test-org/full-col-repo/issues/999
Description: First canonical release.

Release: 1.1.0
Status: draft
Codename: FullTwo
Target Date: 2026-02-01
Tracking Issue: https://github.com/test-org/full-col-repo/issues/1000
Description: Second canonical release with distinct URL.
EOF

if full_col_retry_out="$("$ONBOARD" "$FULL_COL_REPO" 2>&1)"; then
  full_col_retry_rc=0
else
  full_col_retry_rc=$?
fi
[ "$full_col_retry_rc" = 0 ] \
  && pass "Full-URL collision: recovery succeeds on retry after fixing duplicate URL" \
  || fail "Full-URL collision: retry failed after fixing duplicate URL ($full_col_retry_out)"
[ -f "$FULL_COL_REPO/releases.db" ] \
  && pass "Full-URL collision: releases.db created on successful retry" \
  || fail "Full-URL collision: releases.db missing on retry"

# --- 8. Re-vendor preserves adoption (sticky Tier 2 across update) ---
# Use the onboarded happy repo (which has releases.db at root)
"$SYNC" update "$OB_REPO" >/dev/null 2>&1 || fail "Re-vendor sync update failed"
[ -f "$OB_REPO/.xyz/relay-automation/xyz-releases-onboard.sh" ] \
  && pass "Re-vendor preserves adoption: xyz-releases-onboard.sh preserved" \
  || fail "Re-vendor preserves adoption: xyz-releases-onboard.sh lost"
[ -f "$OB_REPO/.xyz/utils/py/releases_app.py" ] \
  && pass "Re-vendor preserves adoption: Tier 2 overlay preserved after sync update" \
  || fail "Re-vendor preserves adoption: overlay lost after sync update"
[ -f "$OB_REPO/.xyz/RELEASES-DB-FAQS.md" ] \
  && pass "Re-vendor preserves adoption: RELEASES-DB-FAQS.md preserved" \
  || fail "Re-vendor preserves adoption: FAQ doc lost"
grep -Fqx 'tier=2' "$OB_REPO/.xyz/VERSION" \
  && pass "Re-vendor preserves adoption: VERSION remains tier=2" \
  || fail "Re-vendor preserves adoption: VERSION tier changed"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
