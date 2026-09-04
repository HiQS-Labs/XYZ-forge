#!/bin/bash
# test/gh269-roadmap-retired.sh — verify ROADMAP.md is retired and tools operate on releases.db
set -eu
source test/_setup.sh "GH-269" || { echo "setup failed"; exit 1; }

root="$(cd "$HERE/.." && pwd)"

# ── 1. Static canary: ROADMAP.md must not exist at repo root ────────────────────────
if [ -f "$root/ROADMAP.md" ]; then
  fail "ROADMAP.md is present at repo root — file must be retired in releases-mode"
else
  pass "ROADMAP.md is absent at repo root"
fi

# ── 2. Active tools execute without ROADMAP.md ───────────────────────────────────────
rc=0
out="$(QUEUE_PLAN_GH=off python3 "$root/utils/py/marathon_plan.py" --dry-run 2>&1)" || rc=$?
# exit 0 (clean) or 4 (drift present) are valid execution verdicts; exit 3 (ROADMAP unparseable) is failure
if [ "${rc:-0}" -eq 3 ]; then
  fail "marathon_plan.py failed with exit 3 (unparseable/missing ROADMAP): $out"
else
  pass "marathon_plan.py executed without ROADMAP.md (exit ${rc:-0})"
fi

# ── 3. Roadmap dashboard passes check ────────────────────────────────────────────────
if bash "$root/utils/roadmap-dashboard.sh" --check; then
  pass "roadmap-dashboard.sh --check passed from releases.db source"
else
  fail "roadmap-dashboard.sh --check failed with no ROADMAP.md"
fi

# ── 4. PDDA doc checks pass without ROADMAP.md ───────────────────────────────────────
if PDDA_REPO_ROOT="$root" bash "$root/utils/pdda/pdda.sh" roadmap-coverage >/dev/null 2>&1; then
  pass "pdda.sh roadmap-coverage passed from releases.db"
else
  fail "pdda.sh roadmap-coverage failed when ROADMAP.md is absent"
fi

if PDDA_REPO_ROOT="$root" bash "$root/utils/pdda/pdda.sh" roadmap >/dev/null 2>&1; then
  pass "pdda.sh roadmap passed cleanly when ROADMAP.md is absent"
else
  fail "pdda.sh roadmap failed when ROADMAP.md is absent"
fi

# ── 5. Fixture test: releases roadmap move and update CLI verbs ──────────────────────
R="$WORK/fixture"
mkdir -p "$R/PROJECT/2-WORKING" "$R/PROJECT/3-COMPLETED" "$R/utils/py"
cp "$root/utils/py/releases_app.py" "$R/utils/py/"
cp "$root/utils/py/harness_paths.py" "$R/utils/py/"

cd "$R"
git init -q .
git -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
echo "ROADMAP_SOURCE=releases" > .pdda-mode
python3 "$R/utils/py/releases_app.py" --root "$R" init >/dev/null 2>&1

# Add a test item
python3 "$R/utils/py/releases_app.py" --root "$R" roadmap add \
  --issue-num 999 \
  --issue-url "https://github.com/HiQS-Labs/XYZ-forge/issues/999" \
  --title "Test Issue" \
  --created "2026-09-04" \
  --doc-path "PROJECT/2-WORKING/GH-999-TEST.md" >/dev/null

# Verify row exists in Queue / parked intake
sec="$(sqlite3 "$R/releases.db" "SELECT section FROM roadmap_items WHERE gh_number = 999")"
[ "$sec" = "Queue / parked intake" ] || fail "expected Queue / parked intake, got $sec"
pass "fixture: roadmap add inserted item into Queue / parked intake"

# Move row to Completed via roadmap move
python3 "$R/utils/py/releases_app.py" --root "$R" roadmap move \
  --issue-num 999 \
  --section "Completed" >/dev/null

sec="$(sqlite3 "$R/releases.db" "SELECT section FROM roadmap_items WHERE gh_number = 999")"
[ "$sec" = "Completed" ] || fail "expected Completed, got $sec"
pass "fixture: roadmap move moved item to Completed"

# Verify roadmap sync is a clean no-op in releases mode with no ROADMAP.md
sync_out="$(python3 "$R/utils/py/releases_app.py" --root "$R" roadmap sync 2>&1)"
grep -q "skipped — releases-mode repo" <<<"$sync_out" || fail "roadmap sync should skip in releases mode"
pass "fixture: roadmap sync gracefully skips with no ROADMAP.md"

cd "$root"
pass "all GH-269 roadmap retirement checks passed"
