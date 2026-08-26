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
grep -q "ROADMAP ✓" <<<"$out" || fail "legacy repo missing ROADMAP ✓"

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
grep -q "RELEASES-DB ✓ (dashboard ✓" <<<"$out" || fail "healthy repo missing RELEASES-DB ✓ or dashboard ✓"

# 3. Releases-mode repo (broken DB)
mkdir -p "$WORK/repo-broken"
cd "$WORK/repo-broken"
git init >/dev/null 2>&1
echo "ROADMAP_SOURCE=releases" > .pdda-mode
# No releases.db or CLI here
cd "$root"

out="$(bash utils/hq/hq.sh status "repo-broken")"
grep -q "RELEASES-DB ✗ (releases-mode declared, but releases.db or CLI missing)" <<<"$out" || fail "broken repo missing degrade message"

echo "  PASS: status tests"

# 4. Rollup aggregation — assert on the CONTENT the releases branch emits and on the exit
#    status, not just the pre-python echoes (those print even when the branch is broken).
echo "  Testing rollup.sh..."
export HQ_PDDA_REGISTRY_DIR="$WORK/test-rollup/registry"
mkdir -p "$HQ_PDDA_REGISTRY_DIR"
echo -e "repo-healthy\t\t\t\t" > "$HQ_PDDA_REGISTRY_DIR/registry-test.tsv"
export PDDA_REGISTRY_JSON="[{\"repo\": \"repo-healthy\", \"path\": \"$WORK/repo-healthy\"}]"
export AGY_BIN="echo"
export MARATHON_SCAN_BIN="echo"
export MARATHON_LIVE_BIN="echo"
export RELEASES_CYCLE_BIN="echo"
export HQ_OBSIDIAN_VAULT="$WORK/vault"

# seed one open roadmap item so the releases branch has something real to aggregate
cd "$WORK/repo-healthy"
python3 utils/py/releases_app.py roadmap add --issue-num 7 --issue-url "https://gh/7" \
  --title "Rollup item seven" --created 2026-08-25 --doc-path "PROJECT/1-INBOX/GH-7-x.md" >/dev/null \
  || fail "could not seed roadmap item"
cd "$root"

rollup_rc=0
out="$(bash utils/hq/rollup.sh 2>&1)" || rollup_rc=$?
[ "$rollup_rc" -eq 0 ] || fail "rollup exited $rollup_rc: $out"
grep -q "scanning repo-healthy" <<<"$out" || fail "rollup did not scan repo-healthy"
grep -q "\[releases DB\]" <<<"$out" || fail "rollup did not use releases DB for repo-healthy"
[ -f "$WORK/vault/HQ-Daily-Rollup.md" ] || fail "rollup did not write HQ-Daily-Rollup.md"
grep -q "=== REPO: repo-healthy ===" "$WORK/vault/HQ-Daily-Rollup.md" || fail "rollup output missing repo-healthy roadmap block"
grep -q "Rollup item seven" "$WORK/vault/HQ-Daily-Rollup.md" || fail "rollup output missing the seeded roadmap item"
echo "  PASS: rollup tests"

echo "== GH-239 ALL PASSED =="
