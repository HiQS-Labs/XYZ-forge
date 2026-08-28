#!/usr/bin/env bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_setup.sh" gh105-vendor-releases-addon
export XYZ_HARNESS_LOGGING=0

# Isolate the registry
export XYZ_REGISTRY="$WORK/registry"
mkdir -p "$XYZ_REGISTRY"

# Test Tier 2 vendoring (GH-105)
TEST_REPO="$WORK/target_repo"
git init -q "$TEST_REPO"
git -C "$TEST_REPO" commit --allow-empty -m "initial commit"

# Materialize with RELEASES (register it, no --no-register)
bash "$HERE/../relay-automation/xyz-vendor.sh" --with-releases "$TEST_REPO" >/dev/null

[ -f "$TEST_REPO/.xyz/utils/py/releases_app.py" ] || fail "missing releases_app.py"
[ -f "$TEST_REPO/.xyz/utils/releases-merge-resolve.sh" ] || fail "missing releases-merge-resolve.sh"
[ -f "$TEST_REPO/.xyz/RELEASES-DB-FAQS.md" ] || fail "missing RELEASES-DB-FAQS.md"
[ -d "$TEST_REPO/.xyz/utils/timeline" ] || fail "missing utils/timeline"

# Initialize representative ledger state at the target root
echo "ledger content db" > "$TEST_REPO/releases.db"
echo "ledger content sql" > "$TEST_REPO/releases.sql"

# Fingerprint the ledger state
DB_HASH=$(shasum "$TEST_REPO/releases.db" | awk '{print $1}')
SQL_HASH=$(shasum "$TEST_REPO/releases.sql" | awk '{print $1}')

# GH-312: test that updating preserves state and sticky detection works
mkdir -p "$TEST_REPO/.xyz/relay-system"
touch "$TEST_REPO/.xyz/relay-system/dummy.md"
touch "$TEST_REPO/.xyz/.relay-driver.lock"
touch "$TEST_REPO/.xyz/XYZ.json"

# Update via xyz-sync.sh without re-supplying the tier flag
bash "$HERE/../relay-automation/xyz-sync.sh" update "$TEST_REPO" >/dev/null

# Assert the Tier 2 payload remains present
[ -f "$TEST_REPO/.xyz/utils/py/releases_app.py" ] || fail "lost releases_app.py on update"
[ -f "$TEST_REPO/.xyz/RELEASES-DB-FAQS.md" ] || fail "lost RELEASES-DB-FAQS.md on update"

# Assert ledger artifacts are unchanged
[ -f "$TEST_REPO/releases.db" ] || fail "lost releases.db on update"
[ -f "$TEST_REPO/releases.sql" ] || fail "lost releases.sql on update"

NEW_DB_HASH=$(shasum "$TEST_REPO/releases.db" | awk '{print $1}')
NEW_SQL_HASH=$(shasum "$TEST_REPO/releases.sql" | awk '{print $1}')

[ "$DB_HASH" = "$NEW_DB_HASH" ] || fail "releases.db content altered on update"
[ "$SQL_HASH" = "$NEW_SQL_HASH" ] || fail "releases.sql content altered on update"

# Assert GH-312 state preserved
[ -f "$TEST_REPO/.xyz/relay-system/dummy.md" ] || fail "lost relay-system state on update"
[ -f "$TEST_REPO/.xyz/.relay-driver.lock" ] || fail "lost .relay-driver.lock on update"
[ -f "$TEST_REPO/.xyz/XYZ.json" ] || fail "lost XYZ.json on update"

pass "Tier 2 payload pinned, target ledger state preserved, and sticky detection exercised"
exit 0
