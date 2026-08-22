#!/usr/bin/env bash
source "$(dirname "$0")/_setup.sh" wave-reconcile
XYZ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RECONCILE_PY="$XYZ_ROOT/utils/py/wave_reconcile.py"

PASS=0
FAIL=0

pass() {
  echo "  ✅ PASS: $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "  ❌ FAIL: $1 (got: $2, expected: $3)"
  FAIL=$((FAIL + 1))
}

assert_eq() {
  local desc="$1"
  local got="$2"
  local exp="$3"
  if [ "$got" = "$exp" ]; then
    pass "$desc"
  else
    fail "$desc" "$got" "$exp"
  fi
}

echo "=== Running wave-reconcile.sh test suite ==="

# Test 1: Usage & Help
out="$(python3 "$RECONCILE_PY" --help 2>&1)"
if grep -q "Post-Merge Wave & Marathon Lifecycle Reconciler" <<< "$out"; then
  pass "Top-level help lists canonical purpose"
else
  fail "Top-level help lists canonical purpose" "$out" "Post-Merge Wave..."
fi

# Setup hermetic git fixture repo
REPO="$WORK/fixture-repo"
mkdir -p "$REPO"
git -C "$REPO" init -q -b development
git -C "$REPO" config user.name "Test Agent"
git -C "$REPO" config user.email "test@example.com"

mkdir -p "$REPO/PROJECT/2-WORKING" "$REPO/PROJECT/3-COMPLETED" "$REPO/PROJECT/4-MISC" "$REPO/utils/py" "$REPO/utils/pdda" "$REPO/utils/timeline" "$REPO/TESTS-RESULTS/2026-08-22"
cp "$RECONCILE_PY" "$REPO/utils/py/wave_reconcile.py"

# Create minimal ROADMAP.md
cat << 'EOF' > "$REPO/ROADMAP.md"
# Test Roadmap

### In progress
- **GH-999 · Test Feature** 🚧 **active 2026-08-22** — test description. rated 80/80/80/80. → [GH-999-TEST.md](PROJECT/2-WORKING/GH-999-TEST.md) · [#999](https://github.com/HiQS-Suite/XYZ-forge/issues/999)
- **GH-777 · Declined Feature** 🚧 **active 2026-08-22** — declined feature. rated 50/50/50/50. → [GH-777-DECLINED.md](PROJECT/2-WORKING/GH-777-DECLINED.md) · [#777](https://github.com/HiQS-Suite/XYZ-forge/issues/777)

### Completed
- **GH-888 · Old Feature** ✅ **SHIPPED 2026-08-20 (PR #888)** — old summary.
EOF

# Create active docs
cat << 'EOF' > "$REPO/PROJECT/2-WORKING/GH-999-TEST.md"
---
gh_issue: 999
title: "GH-999: Test Feature"
status: In Progress
created: 2026-08-22
updated: 2026-08-22
---

# GH-999: Test Feature

## Lessons Learned (For Future Agents)
- Always verify porcelain cleanliness and isolated worktree boundaries.
EOF

cat << 'EOF' > "$REPO/PROJECT/2-WORKING/GH-777-DECLINED.md"
---
gh_issue: 777
title: "GH-777: Declined Feature"
status: In Progress
created: 2026-08-22
updated: 2026-08-22
---

# GH-777: Declined Feature
Testing unmerged routing to 4-MISC.
EOF

# Create mock provenance receipt
echo '{"status": "PASS", "trials": 10}' > "$REPO/TESTS-RESULTS/2026-08-22/provenance.jsonl"

# Create mock offline manifest with both merged and closed/unmerged PRs
cat << 'EOF' > "$REPO/manifest.json"
{
  "prs": [
    {
      "number": 1001,
      "title": "feat(core): implement GH-999 test feature",
      "state": "MERGED",
      "mergedAt": "2026-08-22T19:00:00Z",
      "baseRefName": "development",
      "headRefName": "feat/gh999",
      "body": "Closes #999"
    },
    {
      "number": 1002,
      "title": "feat(core): duplicate of existing approach",
      "state": "CLOSED",
      "mergedAt": null,
      "baseRefName": "development",
      "headRefName": "feat/gh777",
      "body": "Closes #777"
    }
  ]
}
EOF

# Mock subordinate scripts
cat << 'EOF' > "$REPO/utils/py/releases_app.py"
#!/usr/bin/env python3
import sys
if "check" in sys.argv or "sync" in sys.argv:
    print("MOCK: releases_app OK")
    sys.exit(0)
sys.exit(0)
EOF
chmod +x "$REPO/utils/py/releases_app.py"

cat << 'EOF' > "$REPO/utils/roadmap-dashboard.sh"
#!/usr/bin/env bash
echo "MOCK: roadmap-dashboard OK"
exit 0
EOF
chmod +x "$REPO/utils/roadmap-dashboard.sh"

cat << 'EOF' > "$REPO/utils/marathon-plan.sh"
#!/usr/bin/env bash
echo "MOCK: marathon-plan OK"
exit 0
EOF
chmod +x "$REPO/utils/marathon-plan.sh"

cat << 'EOF' > "$REPO/utils/timeline/export_timeline.py"
#!/usr/bin/env python3
import sys
print("MOCK: export_timeline OK")
sys.exit(0)
EOF
chmod +x "$REPO/utils/timeline/export_timeline.py"

cat << 'EOF' > "$REPO/utils/pdda/pdda.sh"
#!/usr/bin/env bash
echo "MOCK: pdda run OK"
exit 0
EOF
chmod +x "$REPO/utils/pdda/pdda.sh"

# Mock releases DB files
touch "$REPO/releases.db" "$REPO/releases.sql"

git -C "$REPO" add -A
git -C "$REPO" commit -q -m "initial fixture state"

# Test 2: Dirty tree rejection
touch "$REPO/untracked-dirt.txt"
set +e
out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 1001 --offline "$REPO/manifest.json" --skip-pull 2>&1)"
rc=$?
set -e
assert_eq "Dirty working tree is rejected (exit 3)" "$rc" "3"
rm "$REPO/untracked-dirt.txt"

# Test 3: Hermetic dry-run proves zero mutation
hash_before="$(git -C "$REPO" status --porcelain; git -C "$REPO" rev-parse HEAD)"
out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 1001 --offline "$REPO/manifest.json" --skip-pull --dry-run 2>&1)"
rc=$?
hash_after="$(git -C "$REPO" status --porcelain; git -C "$REPO" rev-parse HEAD)"
assert_eq "Dry-run exits 0" "$rc" "0"
assert_eq "Dry-run preserves exact byte-state of repo" "$hash_after" "$hash_before"

# Test 4: Missing ## Lessons Learned rejection
cat << 'EOF' > "$REPO/PROJECT/2-WORKING/GH-999-TEST.md"
---
gh_issue: 999
title: "GH-999: Test Feature Missing Lessons"
status: In Progress
---
# GH-999
No lessons learned section here.
EOF
git -C "$REPO" add -A && git -C "$REPO" commit -q -m "missing lessons"

set +e
out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 1001 --offline "$REPO/manifest.json" --skip-pull 2>&1)"
rc=$?
set -e
assert_eq "Missing lessons learned is rejected (exit 5)" "$rc" "5"

# Restore valid doc
cat << 'EOF' > "$REPO/PROJECT/2-WORKING/GH-999-TEST.md"
---
gh_issue: 999
title: "GH-999: Test Feature"
status: In Progress
created: 2026-08-22
updated: 2026-08-22
---

# GH-999: Test Feature

## Lessons Learned (For Future Agents)
- Verified doc promotion.
EOF
git -C "$REPO" add -A && git -C "$REPO" commit -q -m "valid doc restored"

# Test 5: Live reconciliation execution with merged and unmerged PRs
out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 1001 1002 --offline "$REPO/manifest.json" --skip-pull --gate 2>&1)"
rc=$?
assert_eq "Live reconciliation exits 0" "$rc" "0"

# Verify merged doc moved to 3-COMPLETED and frontmatter updated
if [ -f "$REPO/PROJECT/3-COMPLETED/GH-999-TEST.md" ] && [ ! -f "$REPO/PROJECT/2-WORKING/GH-999-TEST.md" ]; then
  pass "Merged active doc moved from 2-WORKING to 3-COMPLETED"
else
  fail "Merged active doc moved from 2-WORKING to 3-COMPLETED" "missing" "present"
fi

if grep -q "status: Complete" "$REPO/PROJECT/3-COMPLETED/GH-999-TEST.md"; then
  pass "Merged doc frontmatter status updated to Complete"
else
  fail "Merged doc frontmatter status updated to Complete" "not found" "status: Complete"
fi

# Verify unmerged/declined doc moved to 4-MISC
if [ -f "$REPO/PROJECT/4-MISC/GH-777-DECLINED.md" ] && [ ! -f "$REPO/PROJECT/2-WORKING/GH-777-DECLINED.md" ]; then
  pass "Unmerged/declined active doc moved from 2-WORKING to 4-MISC"
else
  fail "Unmerged/declined active doc moved from 2-WORKING to 4-MISC" "missing" "present"
fi

if grep -q "status: Declined" "$REPO/PROJECT/4-MISC/GH-777-DECLINED.md"; then
  pass "Unmerged doc frontmatter status updated to Declined"
else
  fail "Unmerged doc frontmatter status updated to Declined" "not found" "status: Declined"
fi

# Verify ROADMAP.md has SHIPPED badge under Completed
if grep -q "GH-999.*SHIPPED 2026-08-22 (PR #1001)" "$REPO/ROADMAP.md"; then
  pass "ROADMAP.md entry archived to Completed with shipping badge"
else
  fail "ROADMAP.md entry archived to Completed" "not found" "SHIPPED 2026-08-22"
fi

echo "=== wave-reconcile.sh Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
