#!/bin/bash
# test/gh243-dashboard-staleness-guard.sh — the GH-243 push guard: a roadmap-ledger write without a
# dashboard regeneration is refused, releases-mode only, and only when a real range exists.
set -eu
source test/_setup.sh "GH-243" || { echo "setup failed"; exit 1; }

root="$(cd "$HERE/.." && pwd)"
GUARD="$root/githooks/dashboard-staleness-guard.sh"

# Fixture: a releases-mode repo with a base commit, then a ledger-only commit on top.
R="$WORK/fixture"
mkdir -p "$R"
cd "$R"
git init -q .
git -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
echo "ROADMAP_SOURCE=releases" > .pdda-mode
echo "-- dump v1" > releases.sql
echo "dash v1" > ROADMAP-DASHBOARD.md
git add .pdda-mode releases.sql ROADMAP-DASHBOARD.md
git -c user.email=t@t -c user.name=t commit -q -m "v1"
BASE="$(git rev-parse HEAD)"

echo "-- dump v2" > releases.sql
git add releases.sql
git -c user.email=t@t -c user.name=t commit -q -m "ledger write, no dashboard"
LEDGER_ONLY="$(git rev-parse HEAD)"
cd "$root"

# 1. Ledger write without dashboard -> refuse (exit 1) with the regen instruction.
rc=0; out="$(bash "$GUARD" "$R" "$LEDGER_ONLY" "$BASE" 2>&1)" || rc=$?
[ "$rc" -eq 1 ] || fail "expected refusal (1), got $rc"
grep -q "roadmap-dashboard.sh" <<<"$out" || fail "refusal missing the regeneration instruction"

# 2. Same range with the dashboard regenerated in it -> pass.
cd "$R"
echo "dash v2" > ROADMAP-DASHBOARD.md
git add ROADMAP-DASHBOARD.md
git -c user.email=t@t -c user.name=t commit -q -m "regen dashboard"
FIXED="$(git rev-parse HEAD)"
cd "$root"
bash "$GUARD" "$R" "$FIXED" "$BASE" || fail "regenerated range should pass, got $?"

# 3. Legacy-mode repo (no releases marker) -> guard is inert even on a ledger-only range.
cd "$R"; : > .pdda-mode; cd "$root"
bash "$GUARD" "$R" "$LEDGER_ONLY" "$BASE" || fail "legacy-mode repo must not be guarded, got $?"
cd "$R"; echo "ROADMAP_SOURCE=releases" > .pdda-mode; cd "$root"

# 4. New branch (all-zero remote sha) -> no range, no refusal.
bash "$GUARD" "$R" "$LEDGER_ONLY" "0000000000000000000000000000000000000000" \
  || fail "new-branch push must fall through, got $?"

# 5. Non-ledger range (docs commit only) -> pass.
cd "$R"
echo "readme" > README.md
git add README.md
git -c user.email=t@t -c user.name=t commit -q -m docs
DOCS="$(git rev-parse HEAD)"
cd "$root"
bash "$GUARD" "$R" "$DOCS" "$FIXED" || fail "non-ledger range must pass, got $?"

# 6. Usage error -> exit 2.
rc=0; bash "$GUARD" >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] || fail "expected usage exit 2, got $rc"

echo "== GH-243 ALL PASSED =="
