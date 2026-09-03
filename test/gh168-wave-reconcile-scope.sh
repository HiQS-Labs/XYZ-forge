#!/usr/bin/env bash
# GH-168: trailing marathon-plan drift is fatal only when attributable to the reconciled PR.
# The PR-specific failure is the witnessed red control for the attribution gate.
source "$(dirname "$0")/_setup.sh" gh168-wave-reconcile-scope
XYZ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RECONCILE_PY="$XYZ_ROOT/utils/py/wave_reconcile.py"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh168-wave-reconcile-scope =="

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh168-reconcile.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT
. "$(dirname "$0")/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

make_repo() {
  local name="$1"
  local repo="$WORK/$name"
  mkdir -p "$repo"
  require_fixture "$repo" "$name fixture root"
  git -C "$repo" init -q -b development
  git -C "$repo" config user.name "Test Agent"
  git -C "$repo" config user.email "test@example.com"
  mkdir -p "$repo/PROJECT/2-WORKING" "$repo/PROJECT/3-COMPLETED" \
    "$repo/PROJECT/4-MISC" "$repo/utils/py" "$repo/utils/pdda" "$repo/utils/timeline"
  cp "$RECONCILE_PY" "$XYZ_ROOT/utils/py/harness_paths.py" "$repo/utils/py/"

  cat > "$repo/ROADMAP.md" <<'ROADMAPEOF'
# Test Roadmap

### In progress
- **GH-5001 · Reconciled work** 🚧 **active** — ready to close. → [doc](PROJECT/2-WORKING/GH-5001-OWN.md)
- **GH-5999 · Pre-existing drift** 🚧 **active** — unrelated backlog item. → [doc](PROJECT/2-WORKING/GH-5999-UNRELATED.md)

### Completed
ROADMAPEOF

  cat > "$repo/PROJECT/2-WORKING/GH-5001-OWN.md" <<'DOCEOF'
---
gh_issue: 5001
status: In Progress
updated: 2026-08-24
---

# GH-5001

## Lessons Learned (For Future Agents)
- Planner drift must be attributed before rollback.
DOCEOF

  cat > "$repo/PROJECT/2-WORKING/GH-5999-UNRELATED.md" <<'DOCEOF'
---
gh_issue: 5999
status: In Progress
updated: 2026-08-24
---

# GH-5999

## Lessons Learned (For Future Agents)
- This item predates the reconcile under test.
DOCEOF

  cat > "$repo/manifest.json" <<'MANIFESTEOF'
{
  "prs": [
    {"number": 6001, "title": "fix: complete GH-5001", "state": "MERGED",
     "mergedAt": "2026-08-24T00:00:00Z", "baseRefName": "development",
     "headRefName": "fix/5001", "body": "Closes #5001", "url": "https://example/pr/6001"}
  ],
  "issues": [{"number": 5001, "state": "CLOSED"}]
}
MANIFESTEOF

  printf '#!/usr/bin/env python3\nprint("MOCK: releases_app OK")\n' > "$repo/utils/py/releases_app.py"
  printf '#!/usr/bin/env python3\nprint("MOCK: timeline OK")\n' > "$repo/utils/timeline/export_timeline.py"
  printf '#!/usr/bin/env bash\necho "MOCK: roadmap dashboard OK"\n' > "$repo/utils/roadmap-dashboard.sh"
  printf '#!/usr/bin/env bash\necho "MOCK: pdda OK"\n' > "$repo/utils/pdda/pdda.sh"
  cat > "$repo/utils/marathon-plan.sh" <<'PLANEOF'
#!/usr/bin/env bash
case "${PLAN_MODE:-clean}" in
  unrelated)
    printf '%s\n' '{"severity":"warn","check":"marathon-plan/already-landed","file":"PROJECT/2-WORKING/GH-5999-UNRELATED.md","message":"all fix_probes report landed","action":"verify-and-close"}'
    exit 4
    ;;
  owned)
    printf '%s\n' '{"severity":"warn","check":"marathon-plan/already-landed","file":"PROJECT/2-WORKING/GH-5001-OWN.md","message":"all fix_probes report landed","action":"verify-and-close"}'
    exit 4
    ;;
  clean)
    printf '%s\n' '{"severity":"info","check":"marathon-plan/summary","file":"","message":"drift=false held=0","action":"summary"}'
    exit 0
    ;;
esac
PLANEOF
  chmod +x "$repo/utils/roadmap-dashboard.sh" "$repo/utils/pdda/pdda.sh" \
    "$repo/utils/marathon-plan.sh" "$repo/utils/timeline/export_timeline.py"

  git -C "$repo" add -A
  git -C "$repo" commit -qm "fixture: wave reconcile scope"
  printf '%s\n' "$repo"
}

run_reconcile() {
  local repo="$1"
  PLAN_MODE="$2" python3 "$repo/utils/py/wave_reconcile.py" \
    --root "$repo" --pr 6001 --offline "$repo/manifest.json" --skip-pull --allow-dirty
}

# Unrelated pre-existing drift warns and preserves the correct reconciliation.
R_UNRELATED="$(make_repo unrelated)"
out="$(run_reconcile "$R_UNRELATED" unrelated 2>&1)"; rc=$?
[ "$rc" -eq 0 ] \
  && pass "unrelated pre-existing planner drift does not roll back reconciliation" \
  || fail "unrelated drift aborted reconcile (rc=$rc): $out"
grep -q "pre-existing unrelated drift/held items" <<<"$out" \
  && grep -q "GH-5999" <<<"$out" \
  && pass "warning block names the unrelated held item" \
  || fail "warning block did not name GH-5999: $out"
[ -f "$R_UNRELATED/PROJECT/3-COMPLETED/GH-5001-OWN.md" ] \
  && [ ! -f "$R_UNRELATED/PROJECT/2-WORKING/GH-5001-OWN.md" ] \
  && pass "successful reconcile keeps the PR-specific doc promotion" \
  || fail "successful reconcile lost or rolled back the doc promotion"
[ "$(grep -c '^- \*\*GH-5001\b' "$R_UNRELATED/ROADMAP.md")" -eq 1 ] \
  && grep -q '^### Completed' "$R_UNRELATED/ROADMAP.md" \
  && grep -q 'GH-5001.*SHIPPED' "$R_UNRELATED/ROADMAP.md" \
  && pass "promotion writer moves one ROADMAP entry to Completed" \
  || fail "ROADMAP promotion did not leave exactly one shipped GH-5001 entry"

# Negative control: the same planner state attributed to this PR remains fatal and rolls back.
R_OWNED="$(make_repo owned)"
roadmap_before="$(cksum < "$R_OWNED/ROADMAP.md")"
out="$(run_reconcile "$R_OWNED" owned 2>&1)"; rc=$?
[ "$rc" -eq 6 ] && grep -q "attributable to the reconciled PR" <<<"$out" \
  && pass "PR-owned planner drift remains fatal (witnessed red control)" \
  || fail "PR-owned drift was not rejected (rc=$rc): $out"
[ -f "$R_OWNED/PROJECT/2-WORKING/GH-5001-OWN.md" ] \
  && [ ! -f "$R_OWNED/PROJECT/3-COMPLETED/GH-5001-OWN.md" ] \
  && [ "$roadmap_before" = "$(cksum < "$R_OWNED/ROADMAP.md")" ] \
  && pass "PR-owned drift rolls back both doc and ROADMAP mutations" \
  || fail "fatal PR-owned drift did not fully roll back"

# A second clean reconcile is byte-for-byte inert and never duplicates the ledger bullet.
R_IDEMPOTENT="$(make_repo idempotent)"
out="$(run_reconcile "$R_IDEMPOTENT" clean 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || fail "first clean reconcile failed (rc=$rc): $out"
roadmap_once="$(cksum < "$R_IDEMPOTENT/ROADMAP.md")"
doc_once="$(cksum < "$R_IDEMPOTENT/PROJECT/3-COMPLETED/GH-5001-OWN.md")"
out="$(run_reconcile "$R_IDEMPOTENT" clean 2>&1)"; rc=$?
[ "$rc" -eq 0 ] \
  && [ "$roadmap_once" = "$(cksum < "$R_IDEMPOTENT/ROADMAP.md")" ] \
  && [ "$doc_once" = "$(cksum < "$R_IDEMPOTENT/PROJECT/3-COMPLETED/GH-5001-OWN.md")" ] \
  && [ "$(grep -c '^- \*\*GH-5001\b' "$R_IDEMPOTENT/ROADMAP.md")" -eq 1 ] \
  && pass "second reconcile is a byte-for-byte no-op with one ledger entry" \
  || fail "second reconcile changed files or duplicated GH-5001 (rc=$rc): $out"

echo "  gh168-wave-reconcile-scope: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
