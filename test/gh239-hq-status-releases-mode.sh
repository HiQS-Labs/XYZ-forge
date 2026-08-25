#!/bin/bash
# test/gh239-hq-status-releases-mode.sh
# Tests GH-239: hq status and rollup read from releases DB in releases-mode repos.

set -eu
source test/_setup.sh "GH-239" || { echo "setup failed"; exit 1; }

root="$(cd "$HERE/.." && pwd)"

export XYZ_PATH="$root"
export HQ_SEARCH_ROOTS="$WORK"

# 1. Legacy repo
mkdir -p "$WORK/repo-legacy"
cd "$WORK/repo-legacy"
git init >/dev/null 2>&1
touch .pdda-mode ROADMAP.md
cd "$root"

out="$(bash utils/hq/hq.sh status "repo-legacy")"
echo "$out" | grep -q "ROADMAP ✓" || fail "legacy repo missing ROADMAP ✓"

# 2. Releases-mode repo (healthy)
mkdir -p "$WORK/repo-healthy/utils/py"
cd "$WORK/repo-healthy"
git init >/dev/null 2>&1
echo "ROADMAP_SOURCE=releases" > .pdda-mode
cp "$root/utils/py/releases_app.py" "utils/py/"
python3 utils/py/releases_app.py init >/dev/null
# Wait 1s to ensure ROADMAP-DASHBOARD.md is newer than releases.db
sleep 1
touch ROADMAP-DASHBOARD.md
cd "$root"

out="$(bash utils/hq/hq.sh status "repo-healthy")"
echo "$out" | grep -q "RELEASES-DB ✓ (dashboard ✓" || fail "healthy repo missing RELEASES-DB ✓ or dashboard ✓"

# 3. Releases-mode repo (broken DB)
mkdir -p "$WORK/repo-broken"
cd "$WORK/repo-broken"
git init >/dev/null 2>&1
echo "ROADMAP_SOURCE=releases" > .pdda-mode
# No releases.db or CLI here
cd "$root"

out="$(bash utils/hq/hq.sh status "repo-broken")"
echo "$out" | grep -q "RELEASES-DB ✗ (releases-mode declared, but releases.db or CLI missing)" || fail "broken repo missing degrade message"

echo "  PASS: status tests"

# 4. Rollup aggregation
echo "  Testing rollup.sh..."
export HQ_PDDA_REGISTRY_DIR="$WORK/test-rollup/registry"
mkdir -p "$HQ_PDDA_REGISTRY_DIR"
echo -e "repo-healthy\t\t\t\t" > "$HQ_PDDA_REGISTRY_DIR/registry-test.tsv"
export PDDA_REGISTRY_JSON="[{\"repo\": \"repo-healthy\", \"path\": \"$WORK/repo-healthy\"}]"
export AGY_BIN="echo"
export MARATHON_SCAN_BIN="echo"
export MARATHON_LIVE_BIN="echo"
export RELEASES_CYCLE_BIN="echo"

cd "$root"
out="$(bash utils/hq/rollup.sh 2>&1 || true)"
echo "$out" | grep -q "scanning repo-healthy" || fail "rollup did not scan repo-healthy"
echo "$out" | grep -q "\[releases DB\]" || fail "rollup did not use releases DB for repo-healthy"
echo "  PASS: rollup tests"

echo "== GH-239 ALL PASSED =="
