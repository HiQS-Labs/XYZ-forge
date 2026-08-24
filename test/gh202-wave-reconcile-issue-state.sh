#!/usr/bin/env bash
# GH-202: wave_reconcile must (1) tolerate marathon-plan exit 5 (items held is normal planning
# state, not a reconcile failure) and (2) keep capture docs ACTIVE when the linked issue is OPEN —
# promotion requires the issue closed. Pre-fix behavior recorded on the issue (2026-08-24).
source "$(dirname "$0")/_setup.sh" gh202-wave-reconcile-issue-state
XYZ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RECONCILE_PY="$XYZ_ROOT/utils/py/wave_reconcile.py"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh202-wave-reconcile-issue-state =="

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh202-reconcile.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT
. "$(dirname "$0")/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

REPO="$WORK/fixture-repo"
mkdir -p "$REPO"
git -C "$REPO" init -q -b development
git -C "$REPO" config user.name "Test Agent"
git -C "$REPO" config user.email "test@example.com"
mkdir -p "$REPO/PROJECT/2-WORKING" "$REPO/PROJECT/3-COMPLETED" "$REPO/PROJECT/4-MISC" \
  "$REPO/utils/py" "$REPO/utils/pdda" "$REPO/utils/timeline" "$REPO/TESTS-RESULTS/2026-08-24"
cp "$RECONCILE_PY" "$REPO/utils/py/wave_reconcile.py"
require_fixture_file "$REPO/utils/py/wave_reconcile.py" "reconciler-copy"

cat > "$REPO/ROADMAP.md" <<'ROADMAPEOF'
# Test Roadmap

### In progress
- **GH-3001 · Open-issue umbrella** 🚧 **active 2026-08-24** — phases remain. rated 80/80/80/80. → [GH-3001-OPEN.md](PROJECT/2-WORKING/GH-3001-OPEN.md) · [#3001](https://github.com/HiQS-Labs/XYZ-forge/issues/3001)
- **GH-3002 · Done work** 🚧 **active 2026-08-24** — complete. rated 80/80/80/80. → [GH-3002-DONE.md](PROJECT/2-WORKING/GH-3002-DONE.md) · [#3002](https://github.com/HiQS-Labs/XYZ-forge/issues/3002)

### Completed
ROADMAPEOF

cat > "$REPO/PROJECT/2-WORKING/GH-3001-OPEN.md" <<'DOCEOF'
---
gh_issue: 3001
title: "GH-3001"
status: In Progress
created: 2026-08-24
updated: 2026-08-24
---

# GH-3001

## Lessons Learned (For Future Agents)
- Promote only when the linked issue is actually closed.
DOCEOF

cat > "$REPO/PROJECT/2-WORKING/GH-3002-DONE.md" <<'DOCEOF'
---
gh_issue: 3002
title: "GH-3002"
status: In Progress
created: 2026-08-24
updated: 2026-08-24
---

# GH-3002

## Lessons Learned (For Future Agents)
- Promote only when the linked issue is actually closed.
DOCEOF

echo '{"status": "PASS"}' > "$REPO/TESTS-RESULTS/2026-08-24/provenance.jsonl"

# Subprocess stubs — marathon-plan deliberately exits 5 (items held): the reconcile must CONTINUE.
printf '#!/usr/bin/env python3\nprint("MOCK: releases_app OK")\n' > "$REPO/utils/py/releases_app.py"
chmod +x "$REPO/utils/py/releases_app.py"
printf '#!/usr/bin/env bash\necho "MOCK: roadmap-dashboard OK"\n' > "$REPO/utils/roadmap-dashboard.sh"
chmod +x "$REPO/utils/roadmap-dashboard.sh"
printf '#!/usr/bin/env python3\nprint("MOCK: timeline OK")\n' > "$REPO/utils/timeline/export_timeline.py"
printf '#!/usr/bin/env bash\necho "MOCK: pdda run OK"\n' > "$REPO/utils/pdda/pdda.sh"
chmod +x "$REPO/utils/timeline/export_timeline.py"
chmod +x "$REPO/utils/pdda/pdda.sh"
printf '#!/usr/bin/env bash\necho "MOCK: marathon-plan reports items held"\nexit 5\n' > "$REPO/utils/marathon-plan.sh"
chmod +x "$REPO/utils/marathon-plan.sh"

# Manifest: ONE merged PR linking BOTH issues; issue 3001 OPEN, 3002 CLOSED.
cat > "$REPO/manifest.json" <<'MANIFESTEOF'
{
  "prs": [
    {"number": 4001, "title": "feat: lands 3001 phase + all of 3002", "state": "MERGED",
     "mergedAt": "2026-08-24T00:00:00Z", "baseRefName": "development", "headRefName": "feat/x",
     "body": "Closes #3002. Advances GH-3001 (phase 1 of 2).", "url": "https://example/pr/4001"}
  ],
  "issues": [
    {"number": 3001, "state": "OPEN"},
    {"number": 3002, "state": "CLOSED"}
  ]
}
MANIFESTEOF

git -C "$REPO" add -A && git -C "$REPO" commit -qm "fixture: docs, stubs, manifest"
require_fixture_file "$REPO/manifest.json" "manifest"

out="$(python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 4001 --offline "$REPO/manifest.json" --skip-pull 2>&1)"; rc=$?

[ "$rc" -eq 0 ] && pass "reconcile exits 0 despite marathon-plan exit 5 (items held tolerated)" \
  || fail "reconcile aborted (rc=$rc): $out"
grep -q "items held" <<<"$out" && pass "exit-5 tolerance is logged, not silent" || fail "no items-held log line"
[ -f "$REPO/PROJECT/2-WORKING/GH-3001-OPEN.md" ] && [ ! -f "$REPO/PROJECT/3-COMPLETED/GH-3001-OPEN.md" ] \
  && pass "OPEN-issue doc stays in 2-WORKING (no promotion)" || fail "OPEN-issue doc was moved/promoted"
grep -q "## Merge evidence" "$REPO/PROJECT/2-WORKING/GH-3001-OPEN.md" \
  && pass "OPEN-issue doc records merge evidence in place" || fail "no merge evidence recorded"
[ -f "$REPO/PROJECT/3-COMPLETED/GH-3002-DONE.md" ] && [ ! -f "$REPO/PROJECT/2-WORKING/GH-3002-DONE.md" ] \
  && pass "CLOSED-issue doc promotes to 3-COMPLETED (existing behavior preserved)" || fail "CLOSED-issue doc not promoted"

# Idempotency: re-running does not duplicate the evidence block
git -C "$REPO" add -A && git -C "$REPO" commit -qm "fixture: post-first-reconcile" 2>/dev/null || true
python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 4001 --offline "$REPO/manifest.json" --skip-pull >/dev/null 2>&1
n="$(grep -c "## Merge evidence" "$REPO/PROJECT/2-WORKING/GH-3001-OPEN.md")"
[ "$n" -eq 1 ] && pass "merge-evidence recording is idempotent" || fail "evidence duplicated ($n blocks)"

# Negative control: manifest WITHOUT issues key (legacy shape) still promotes (backward compat)
cat > "$REPO/manifest2.json" <<'MANIFEST2EOF'
{
  "prs": [
    {"number": 4001, "title": "feat: lands 3001 phase + all of 3002", "state": "MERGED",
     "mergedAt": "2026-08-24T00:00:00Z", "baseRefName": "development", "headRefName": "feat/x",
     "body": "Closes #3002. Advances GH-3001.", "url": "https://example/pr/4001"}
  ]
}
MANIFEST2EOF
cat > "$REPO/PROJECT/2-WORKING/GH-3001-OPEN.md" <<'DOCEOF'
---
gh_issue: 3001
title: "GH-3001"
status: In Progress
created: 2026-08-24
updated: 2026-08-24
---

# GH-3001

## Lessons Learned (For Future Agents)
- Legacy manifest compatibility.
DOCEOF
git -C "$REPO" add -A && git -C "$REPO" commit -qm "fixture: restore 3001 for legacy manifest" 2>/dev/null || true
python3 "$REPO/utils/py/wave_reconcile.py" --root "$REPO" --pr 4001 --offline "$REPO/manifest2.json" --skip-pull >/dev/null 2>&1
[ -f "$REPO/PROJECT/3-COMPLETED/GH-3001-OPEN.md" ] \
  && pass "legacy manifest (no issues key): unknown state still promotes — backward compatible" \
  || fail "legacy manifest behavior changed (regression)"

echo "  gh202-wave-reconcile-issue-state: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
