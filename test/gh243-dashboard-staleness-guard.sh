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


# 7. GH-315: jog-queue-only ledger write, renderer in-sync, no dashboard change -> ALLOW
# (jog rows have no dashboard projection; a no-diff regen is the expected outcome, not a
# dropped-row symptom). The fixture needs a renderer whose --check passes to reach the
# guard's no-drift branch at all.
mkdir -p "$R/utils"
printf '#!/usr/bin/env bash\nexit 0\n' > "$R/utils/roadmap-dashboard.sh"
chmod +x "$R/utils/roadmap-dashboard.sh"
cd "$R"
git add utils/roadmap-dashboard.sh
git -c user.email=t@t -c user.name=t commit -q -m "add passing renderer"
RENDERED="$(git rev-parse HEAD)"
{ echo "-- dump v3"
  echo "INSERT INTO settings(key, value) VALUES('generation', '9');"
  echo "INSERT INTO jog_queue VALUES('seed');"
  echo "INSERT INTO op_receipts(op, target_gid) VALUES('jog-add', 'seed');"
} > releases.sql
git add releases.sql
git -c user.email=t@t -c user.name=t commit -q -m "jog-only ledger write"
JOG_ONLY="$(git rev-parse HEAD)"
cd "$root"
bash "$GUARD" "$R" "$JOG_ONLY" "$RENDERED" \
  || fail "jog-queue-only ledger write must pass the no-drift branch (GH-315), got $?"

# 7b. Same shape, marathon fan-out: `releases marathon add` writes marathons + issue_refs
# alongside the op_receipts/generation rows test 7 already covers, and neither new table is
# projected by the renderer -> ALLOW. issue_refs is included because `marathon add` creates
# that row itself whenever the tracking URL is new, so a marathons-only allowance would still
# refuse the common case.
#
# WHAT THIS PROVES, EXACTLY: that the shell classifier accepts the canonical marathon dump
# lines. It does NOT prove the two tables lack a dashboard projection — the fixture renderer
# above is a stub that always exits 0, so no real rendering happens here. That claim rests on
# `roadmap list` being a flat SELECT * FROM roadmap_items (utils/py/releases_app.py:3554) with
# issue_url a denormalized TEXT column, not a foreign key (:605). See #474.
cd "$R"
{ echo "-- dump v3b"
  echo "INSERT INTO settings(key, value) VALUES('generation', '10');"
  echo "INSERT INTO issue_refs(global_id, url) VALUES('ref-1', 'https://example.invalid/1');"
  echo "INSERT INTO marathons(global_id, tracking_ref_gid) VALUES('mar-1', 'ref-1');"
  echo "INSERT INTO op_receipts(op, target_gid) VALUES('marathon-add', 'mar-1');"
} > releases.sql
git add releases.sql
git -c user.email=t@t -c user.name=t commit -q -m "marathon-only ledger write"
MARATHON_ONLY="$(git rev-parse HEAD)"
cd "$root"
bash "$GUARD" "$R" "$MARATHON_ONLY" "$RENDERED" \
  || fail "marathon-only ledger write must pass the no-drift branch, got $?"

# 8. Control: a roadmap_items data change in the same no-drift shape still refuses.
# This is the red control for 7 AND 7b — it is what proves the allowlist opened the gate for
# unprojected tables only, and not for everything.
cd "$R"
{ echo "-- dump v4"; echo "INSERT INTO roadmap_items VALUES('r1');"; } > releases.sql
git add releases.sql
git -c user.email=t@t -c user.name=t commit -q -m "roadmap-only ledger write"
ROADMAP_ONLY="$(git rev-parse HEAD)"
cd "$root"
rc=0; out="$(bash "$GUARD" "$R" "$ROADMAP_ONLY" "$RENDERED" 2>&1)" || rc=$?
[ "$rc" -eq 1 ] || fail "expected no-drift refusal (1) for non-jog data, got $rc"
grep -q "NO diff" <<<"$out" || fail "expected the no-diff refusal message"

echo "== GH-243 ALL PASSED =="
