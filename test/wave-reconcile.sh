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
cp "$RECONCILE_PY" "$XYZ_ROOT/utils/py/harness_paths.py" "$REPO/utils/py/"

# Create minimal ROADMAP.md
cat << 'EOF' > "$REPO/ROADMAP.md"
# Test Roadmap

### In progress
- **GH-999 · Test Feature** 🚧 **active 2026-08-22** — test description. rated 80/80/80/80. → [GH-999-TEST.md](PROJECT/2-WORKING/GH-999-TEST.md) · [#999](https://github.com/HiQS-Labs/XYZ-forge/issues/999)
- **GH-777 · Declined Feature** 🚧 **active 2026-08-22** — declined feature. rated 50/50/50/50. → [GH-777-DECLINED.md](PROJECT/2-WORKING/GH-777-DECLINED.md) · [#777](https://github.com/HiQS-Labs/XYZ-forge/issues/777)
- **GH-444 ** 🚧 **active 2026-08-22** separatorless description

### Completed
- **GH-888 · Old Feature** ✅ **SHIPPED 2026-08-20 (PR #888)** — old summary.
- **GH-222 ** ✅ **SHIPPED 2026-08-21 (PR #222)** — mangled entry.
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

cat << 'EOF' > "$REPO/PROJECT/2-WORKING/GH-444.md"
---
gh_issue: 444
title: "GH-444: Separatorless"
status: In Progress
created: 2026-08-22
updated: 2026-08-22
---
# GH-444: Separatorless
## Lessons Learned (For Future Agents)
- Always preserve separatorless formatting when archiving entries.
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

# Create mock provenance receipts. GH-425: --gate now verifies the receipt actually
# attributes to the PR being reconciled (pr/pr_number, or an exact merge-commit match) —
# a bare non-empty TESTS-RESULTS/ no longer satisfies it. One line per PR this fixture
# reconciles below (1001, 1002, 1003).
{
  echo '{"pr": 1001, "status": "PASS", "trials": 10}'
  echo '{"pr": 1002, "status": "PASS", "trials": 10}'
  echo '{"pr": 1003, "status": "PASS", "trials": 10}'
} > "$REPO/TESTS-RESULTS/2026-08-22/provenance.jsonl"

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
      "number": 1003,
      "title": "feat(core): separatorless",
      "state": "MERGED",
      "mergedAt": "2026-08-22T19:00:00Z",
      "baseRefName": "development",
      "headRefName": "feat/gh444",
      "body": "Closes #444"
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
  ],
  "commits": [
    {
      "sha": "c0ffee1234567890",
      "committedAt": "2026-08-22T20:00:00Z",
      "message": "fix(GH-999): direct express landing\n\nCloses #999"
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

cat << 'EOF' > "$REPO/utils/leaderboard.sh"
#!/usr/bin/env bash
echo "MOCK: leaderboard OK"
exit 0
EOF
chmod +x "$REPO/utils/leaderboard.sh"

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

# GH-707: rollback telemetry uses the tick envelope but remains analytics, not
# coordination. A live .tick must still project cleanly and expose no phantom
# task. The copied pre-#702 projector is the red control: the former bare record
# reproduces the projection crash when both defensive filter lines are removed.
mkdir -p "$REPO/.tick/events"
PYTHONDONTWRITEBYTECODE=1 python3 - "$REPO" <<'PY'
import json
import sys

sys.path.insert(0, sys.argv[1] + "/utils/py")
from wave_reconcile import RollbackJournal

RollbackJournal(sys.argv[1]).rollback()
events = list(__import__("pathlib").Path(sys.argv[1], ".tick", "events").glob("*wave-reconcile-rollback.jsonl"))
assert len(events) == 1, events
record = json.loads(events[0].read_text())
assert record["schema_version"] == "0.2.0"
assert record["type"] == "wave_reconcile.rollback"
assert record["agent"] == "wave_reconcile"
assert record["reason"] == "uncommitted-mutations"
assert record["ts"].endswith("Z")
assert "task" not in record
PY
TICK_BIN="$XYZ_ROOT/bin/tick"
if TICK_REPO_ROOT="$REPO" "$TICK_BIN" project >/dev/null 2>&1 \
  && ! grep -qE '^- (undefined|lane) ' "$REPO/.tick/STATE.md"; then
  pass "GH-707 rollback envelope projects without a phantom task"
else
  fail "GH-707 rollback envelope projects without a phantom task" "projection failed or phantom present" "clean projection"
fi

OLD_TICK="$WORK/pre-gh702-tick"
mkdir -p "$OLD_TICK" "$WORK/pre-gh702-root/.tick/events"
cp -R "$XYZ_ROOT/bin" "$XYZ_ROOT/src" "$OLD_TICK/"
sed -i.bak \
  -e "/typeof ev.task !== 'string'/d" \
  -e "/!ev.type.startsWith('task.')/d" \
  "$OLD_TICK/src/project.js"
rm "$OLD_TICK/src/project.js.bak"
printf '%s\n' '{"event":"wave-reconcile-rollback","reason":"uncommitted-mutations","at":0}' \
  > "$WORK/pre-gh702-root/.tick/events/rollback.jsonl"
if TICK_REPO_ROOT="$WORK/pre-gh702-root" "$OLD_TICK/bin/tick" project >/dev/null 2>&1; then
  fail "GH-707 red control reproduces the old bare-record defect" "projection unexpectedly succeeded" "projection failure"
else
  pass "GH-707 red control reproduces the old bare-record defect"
fi
rm -f "$REPO/.tick/events/"*wave-reconcile-rollback.jsonl "$REPO/.tick/STATE.md" "$REPO/.tick/REJECTED.jsonl"

# Test 3: Hermetic dry-run proves zero mutation
hash_before="$(git -C "$REPO" status --porcelain; git -C "$REPO" rev-parse HEAD)"
out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 1001 --offline "$REPO/manifest.json" --skip-pull --dry-run 2>&1)"
rc=$?
hash_after="$(git -C "$REPO" status --porcelain; git -C "$REPO" rev-parse HEAD)"
assert_eq "Dry-run exits 0" "$rc" "0"
assert_eq "Dry-run preserves exact byte-state of repo" "$hash_after" "$hash_before"

# Test 3b: Direct-commit reconciliation uses commit identity without inventing a PR
out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --commit c0ffee --offline "$REPO/manifest.json" --skip-pull --dry-run 2>&1)"
rc=$?
assert_eq "Direct-commit dry-run exits 0" "$rc" "0"
if grep -q "Processing commit c0ffee123456" <<<"$out" && ! grep -q "Processing PR" <<<"$out"; then
  pass "Direct-commit reconciliation preserves commit identity"
else
  fail "Direct-commit reconciliation preserves commit identity" "$out" "Processing commit c0ffee123456"
fi

# Test 4: Missing ## Lessons Learned is advisory (GH-693) — WARN, promotion proceeds, exit 0.
# (Was a fail-closed exit 5 from GH-165 to GH-693.) --dry-run keeps the fixture in 2-WORKING for Test 5;
# test/gh693-lessons-learned-advisory.sh proves the real move.
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
out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 1001 --offline "$REPO/manifest.json" --skip-pull --dry-run 2>&1)"
rc=$?
set -e
assert_eq "Missing lessons learned is a WARN, not a refusal (exit 0)" "$rc" "0"
if grep -q "wave-reconcile: WARN — Doc GH-999-TEST.md has no '## Lessons Learned" <<< "$out"; then
  pass "WARN names the doc and the missing section"
else
  fail "WARN names the doc and the missing section" "$out" "wave-reconcile: WARN — Doc GH-999-TEST.md has no '## Lessons Learned"
fi
if grep -q "Moved -> GH-999-TEST.md" <<< "$out"; then
  pass "promotion proceeds past the WARN"
else
  fail "promotion proceeds past the WARN" "$out" "Moved -> GH-999-TEST.md"
fi

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
set +e
out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 1001 1002 1003 --offline "$REPO/manifest.json" --skip-pull --gate 2>&1)"
rc=$?
set -e
[ "$rc" -eq 0 ] || echo "TEST 5 FAILED (rc=$rc): $out"
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


# Verify GH-444 separatorless roadmap entry is archived and formatted correctly
if grep -q "GH-444.*SHIPPED 2026-08-22 (PR #1003).*— separatorless" "$REPO/ROADMAP.md"; then
  pass "ROADMAP.md entry archived separator-less fixture entry with correct formatting"
else
  fail "ROADMAP.md entry archived separator-less fixture entry with correct formatting" "not found" "GH-444...SHIPPED...— separatorless"
fi

gh444_line=$(grep -m 1 "GH-444" "$REPO/ROADMAP.md")
expected_line="- **GH-444** ✅ **SHIPPED 2026-08-22 (PR #1003)** — separatorless description"
if [ "$gh444_line" = "$expected_line" ]; then
  pass "Archived line carries no nested/mismatched bold markers"
else
  fail "Archived line carries no nested/mismatched bold markers" "$expected_line" "$gh444_line"
fi

gh222_line=$(grep -m 1 "GH-222" "$REPO/ROADMAP.md")
expected_gh222_line="- **GH-222** ✅ **SHIPPED 2026-08-21 (PR #222)** — mangled entry."
if [ "$gh222_line" = "$expected_gh222_line" ]; then
  pass "Mangled GH-222 entry is fixed and canonicalized"
else
  fail "Mangled GH-222 entry is fixed and canonicalized" "$expected_gh222_line" "$gh222_line"
fi

echo "=== wave-reconcile.sh Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
