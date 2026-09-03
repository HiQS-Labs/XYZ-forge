#!/usr/bin/env bash
# GH-232: wave_reconcile must honor linked issue open/closed state and frontmatter
# umbrella/multiphase declarations, keeping active docs in 2-WORKING and roadmap entries
# in In progress until the issue is officially closed, with --force-promote override.
source "$(dirname "$0")/_setup.sh" gh232-wave-reconcile-multiphase
XYZ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RECONCILE_PY="$XYZ_ROOT/utils/py/wave_reconcile.py"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh232-wave-reconcile-multiphase =="

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh232-reconcile.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT
. "$(dirname "$0")/lib/fixture-guard.sh"
TODAY="$(date +%Y-%m-%d)"
fixture_guard_init "$WORK"

REPO="$WORK/fixture-repo"
mkdir -p "$REPO"
git -C "$REPO" init -q -b development
git -C "$REPO" config user.name "Test Agent"
git -C "$REPO" config user.email "test@example.com"
mkdir -p "$REPO/PROJECT/2-WORKING" "$REPO/PROJECT/3-COMPLETED" "$REPO/PROJECT/4-MISC" \
  "$REPO/utils/py" "$REPO/utils/pdda" "$REPO/utils/timeline" "$REPO/TESTS-RESULTS/$TODAY"
cp "$RECONCILE_PY" "$XYZ_ROOT/utils/py/harness_paths.py" "$REPO/utils/py/"
require_fixture_file "$REPO/utils/py/wave_reconcile.py" "reconciler-copy"

cat > "$REPO/ROADMAP.md" <<ROADMAPEOF
# Test Roadmap

### In progress
- **GH-5001 · Multi-phase umbrella feature** 🚧 **active $TODAY** — phase 1 of 3. rated 80/80/80/80. → [GH-5001-MULTIPHASE.md](PROJECT/2-WORKING/GH-5001-MULTIPHASE.md) · [#5001](https://github.com/HiQS-Labs/XYZ-forge/issues/5001)
- **GH-5002 · Single-phase completed feature** 🚧 **active $TODAY** — single phase. rated 80/80/80/80. → [GH-5002-SINGLEPHASE.md](PROJECT/2-WORKING/GH-5002-SINGLEPHASE.md) · [#5002](https://github.com/HiQS-Labs/XYZ-forge/issues/5002)

### Completed
ROADMAPEOF

cat > "$REPO/PROJECT/2-WORKING/GH-5001-MULTIPHASE.md" <<DOCEOF
---
gh_issue: 5001
title: "GH-5001"
status: In Progress
created: $TODAY
updated: $TODAY
multiphase: true
---

# GH-5001

## Lessons Learned (For Future Agents)
- Multi-phase features stay active while later phases remain in progress.
DOCEOF

cat > "$REPO/PROJECT/2-WORKING/GH-5002-SINGLEPHASE.md" <<DOCEOF
---
gh_issue: 5002
title: "GH-5002"
status: In Progress
created: $TODAY
updated: $TODAY
---

# GH-5002

## Lessons Learned (For Future Agents)
- Single-phase items promote cleanly on issue closure.
DOCEOF

echo '{"status": "PASS"}' > "$REPO/TESTS-RESULTS/$TODAY/provenance.jsonl"

# Subprocess stubs
printf '#!/usr/bin/env python3\nprint("MOCK: releases_app OK")\n' > "$REPO/utils/py/releases_app.py"
chmod +x "$REPO/utils/py/releases_app.py"
printf '#!/usr/bin/env bash\necho "MOCK: roadmap-dashboard OK"\n' > "$REPO/utils/roadmap-dashboard.sh"
chmod +x "$REPO/utils/roadmap-dashboard.sh"
printf '#!/usr/bin/env python3\nprint("MOCK: timeline OK")\n' > "$REPO/utils/timeline/export_timeline.py"
printf '#!/usr/bin/env bash\necho "MOCK: pdda run OK"\n' > "$REPO/utils/pdda/pdda.sh"
chmod +x "$REPO/utils/timeline/export_timeline.py"
chmod +x "$REPO/utils/pdda/pdda.sh"
printf '#!/usr/bin/env bash\necho "MOCK: marathon-plan OK"\nexit 0\n' > "$REPO/utils/marathon-plan.sh"
chmod +x "$REPO/utils/marathon-plan.sh"

# Manifest 1: PR 6001 links both 5001 (OPEN) and 5002 (CLOSED)
cat > "$REPO/manifest.json" <<'MANIFESTEOF'
{
  "prs": [
    {"number": 6001, "title": "feat: phase 1 of 5001 + full 5002", "state": "MERGED",
     "mergedAt": "2026-08-25T00:00:00Z", "baseRefName": "development", "headRefName": "feat/x",
     "body": "Closes #5002. Advances GH-5001 (Phase 1).", "url": "https://example/pr/6001"}
  ],
  "issues": [
    {"number": 5001, "state": "OPEN"},
    {"number": 5002, "state": "CLOSED"}
  ]
}
MANIFESTEOF

git -C "$REPO" add -A && git -C "$REPO" commit -qm "fixture: initial setup"
require_fixture_file "$REPO/manifest.json" "manifest"

# Test 1: Reconcile PR 6001 with 5001 OPEN and 5002 CLOSED
out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 6001 --offline "$REPO/manifest.json" --skip-pull 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "reconcile exits 0 on mixed open/closed PR" || fail "reconcile failed (rc=$rc): $out"

# Check 5001 (OPEN): doc stays in 2-WORKING, evidence recorded, ROADMAP stays in In progress
[ -f "$REPO/PROJECT/2-WORKING/GH-5001-MULTIPHASE.md" ] && [ ! -f "$REPO/PROJECT/3-COMPLETED/GH-5001-MULTIPHASE.md" ] \
  && pass "OPEN-issue multi-phase doc stays in 2-WORKING" || fail "OPEN-issue multi-phase doc was moved"

grep -q "## Merge evidence" "$REPO/PROJECT/2-WORKING/GH-5001-MULTIPHASE.md" \
  && pass "OPEN-issue multi-phase doc records merge evidence in place" || fail "Merge evidence missing from 5001 doc"

# Check ROADMAP.md: 5001 must be under In progress, NOT under Completed
in_prog="$(sed -n '/### In progress/,/### Completed/p' "$REPO/ROADMAP.md")"
grep -q "GH-5001" <<<"$in_prog" \
  && pass "OPEN-issue multi-phase entry stays under '### In progress' in ROADMAP.md" \
  || fail "OPEN-issue entry missing from '### In progress'"

completed="$(sed -n '/### Completed/,$p' "$REPO/ROADMAP.md")"
grep -q "GH-5001" <<<"$completed" \
  && fail "OPEN-issue entry was prematurely moved to '### Completed' in ROADMAP.md" \
  || pass "OPEN-issue entry NOT present in '### Completed' in ROADMAP.md"

# Check 5002 (CLOSED): doc moves to 3-COMPLETED, ROADMAP moves to Completed
[ -f "$REPO/PROJECT/3-COMPLETED/GH-5002-SINGLEPHASE.md" ] && [ ! -f "$REPO/PROJECT/2-WORKING/GH-5002-SINGLEPHASE.md" ] \
  && pass "CLOSED-issue doc promotes to 3-COMPLETED" || fail "CLOSED-issue doc not promoted"

completed="$(sed -n '/### Completed/,$p' "$REPO/ROADMAP.md")"
grep -q "GH-5002" <<<"$completed" \
  && pass "CLOSED-issue entry moves to '### Completed' in ROADMAP.md" \
  || fail "CLOSED-issue entry missing from '### Completed'"

# Test 2: --force-promote overrides OPEN state and promotes 5001 to 3-COMPLETED and ROADMAP Completed
git -C "$REPO" add -A && git -C "$REPO" commit -qm "fixture: post-reconcile 1" 2>/dev/null || true
out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 6001 --offline "$REPO/manifest.json" --skip-pull --force-promote 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "reconcile with --force-promote exits 0" || fail "--force-promote failed (rc=$rc): $out"

[ -f "$REPO/PROJECT/3-COMPLETED/GH-5001-MULTIPHASE.md" ] && [ ! -f "$REPO/PROJECT/2-WORKING/GH-5001-MULTIPHASE.md" ] \
  && pass "--force-promote successfully promotes 5001 doc to 3-COMPLETED" \
  || fail "--force-promote failed to move 5001 doc to 3-COMPLETED"

completed="$(sed -n '/### Completed/,$p' "$REPO/ROADMAP.md")"
grep -q "GH-5001" <<<"$completed" \
  && pass "--force-promote moves 5001 entry to '### Completed' in ROADMAP.md" \
  || fail "--force-promote failed to move 5001 entry in ROADMAP.md"

# Test 3: Frontmatter multiphase: true preserves 2-WORKING even with legacy offline manifest (unknown issue state)
cat > "$REPO/ROADMAP.md" <<ROADMAPEOF
# Test Roadmap

### In progress
- **GH-5003 · Frontmatter umbrella** 🚧 **active $TODAY** — phase 1. rated 80/80/80/80. → [GH-5003-UMBRELLA.md](PROJECT/2-WORKING/GH-5003-UMBRELLA.md) · [#5003](https://github.com/HiQS-Labs/XYZ-forge/issues/5003)

### Completed
ROADMAPEOF

cat > "$REPO/PROJECT/2-WORKING/GH-5003-UMBRELLA.md" <<DOCEOF
---
gh_issue: 5003
title: "GH-5003"
status: In Progress
created: $TODAY
updated: $TODAY
umbrella: true
---

# GH-5003

## Lessons Learned (For Future Agents)
- Umbrella frontmatter sentinel.
DOCEOF

cat > "$REPO/manifest_legacy.json" <<'MANIFESTEOF'
{
  "prs": [
    {"number": 6002, "title": "feat: phase 1 of umbrella", "state": "MERGED",
     "mergedAt": "2026-08-25T00:00:00Z", "baseRefName": "development", "headRefName": "feat/x",
     "body": "Advances GH-5003.", "url": "https://example/pr/6002"}
  ]
}
MANIFESTEOF

git -C "$REPO" add -A && git -C "$REPO" commit -qm "fixture: setup 5003 umbrella" 2>/dev/null || true
out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 6002 --offline "$REPO/manifest_legacy.json" --skip-pull 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && pass "reconcile with frontmatter umbrella and legacy manifest exits 0" || fail "umbrella test failed: $out"

[ -f "$REPO/PROJECT/2-WORKING/GH-5003-UMBRELLA.md" ] && [ ! -f "$REPO/PROJECT/3-COMPLETED/GH-5003-UMBRELLA.md" ] \
  && pass "Frontmatter umbrella: true keeps doc in 2-WORKING under legacy manifest" \
  || fail "Frontmatter umbrella was improperly promoted"

in_prog="$(sed -n '/### In progress/,/### Completed/p' "$REPO/ROADMAP.md")"
grep -q "GH-5003" <<<"$in_prog" \
  && pass "Frontmatter umbrella: true preserves entry under '### In progress' in ROADMAP.md" \
  || fail "Frontmatter umbrella entry moved from '### In progress'"

echo "  gh232-wave-reconcile-multiphase: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
