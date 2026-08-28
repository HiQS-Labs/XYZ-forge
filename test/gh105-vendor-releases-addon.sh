#!/usr/bin/env bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_setup.sh" gh105-vendor-releases-addon
export XYZ_HARNESS_LOGGING=0

# Test Tier 2 vendoring (GH-105)
TEST_REPO="$WORK/target_repo"
git init -q "$TEST_REPO"
git -C "$TEST_REPO" commit --allow-empty -m "initial commit"

# Materialize with RELEASES
bash "$HERE/../relay-automation/xyz-vendor.sh" --no-register --with-releases "$TEST_REPO" >/dev/null

[ -f "$TEST_REPO/.xyz/utils/py/releases_app.py" ] || fail "missing releases_app.py"
[ -f "$TEST_REPO/.xyz/utils/releases-merge-resolve.sh" ] || fail "missing releases-merge-resolve.sh"
[ -f "$TEST_REPO/.xyz/RELEASES-DB-FAQS.md" ] || fail "missing RELEASES-DB-FAQS.md"
[ -d "$TEST_REPO/.xyz/utils/timeline" ] || fail "missing utils/timeline"

# GH-312: test that updating preserves state
mkdir -p "$TEST_REPO/.xyz/relay-system"
touch "$TEST_REPO/.xyz/relay-system/dummy.md"
touch "$TEST_REPO/.xyz/.relay-driver.lock"
touch "$TEST_REPO/.xyz/XYZ.json"

bash "$HERE/../relay-automation/xyz-vendor.sh" --no-register --with-releases "$TEST_REPO" >/dev/null

[ -f "$TEST_REPO/.xyz/relay-system/dummy.md" ] || fail "lost relay-system state on update"
[ -f "$TEST_REPO/.xyz/.relay-driver.lock" ] || fail "lost .relay-driver.lock on update"
[ -f "$TEST_REPO/.xyz/XYZ.json" ] || fail "lost XYZ.json on update"

pass "Tier 2 payload pinned and GH-312 state preserved"
exit 0
