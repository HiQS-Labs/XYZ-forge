#!/usr/bin/env bash
# GH-698 F2/F4: the marathon planner reads the DB's canonical four-axis ratings —
# a rated row sequences into active lanes; an unrated row holds as `unrated`
# (red control). Fixture DB built via direct sqlite (test_gh605 pattern).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# GH-1 adoption: this suite creates mktemp fixtures and drives git through them —
# arm the shared fixture guard and require_fixture at the use boundary.
. "$ROOT/test/lib/fixture-guard.sh"
export QUEUE_PLAN_ROOT FIX
FIX="$(mktemp -d)"
# GH-177/GH-567: non-empty + directory checks chained to an abort, before the cd —
# the shape mktemp-trap-guard's segment scan recognizes.
[ -n "$FIX" ] && [ -d "$FIX" ] || exit 1
fixture_guard_init "$FIX"
FX="$FIX/planner-root"
mkdir "$FX"
require_fixture "$FX" "planner fixture root"
trap 'rm -rf "$FIX"' EXIT

cd "$FX"
git init -q
git config user.email gh698@example.invalid
git config user.name gh698
printf 'ROADMAP_SOURCE = releases\n' > .pdda-mode
mkdir -p docs
cat > docs/alpha.md <<'EOF'
---
title: alpha
---
## Swarm Preflight Contract

```json
{"artifacts": ["docs/alpha.md"], "lanes": {}}
```
EOF
cat > docs/beta.md <<'EOF'
---
title: beta
---
## Swarm Preflight Contract

```json
{"artifacts": ["docs/beta.md"], "lanes": {}}
```
EOF
git add -A && git commit -qm seed

python3 - <<'PY'
import sqlite3
conn = sqlite3.connect('releases.db')
conn.execute("""CREATE TABLE roadmap_items(global_id TEXT, gh_number INTEGER,
             title TEXT, status_marker TEXT, section TEXT, position INTEGER,
             raw_text TEXT, doc_path TEXT, issue_url TEXT,
             complexity INTEGER, risk INTEGER, effort INTEGER,
             rating_pri INTEGER, rating_sev INTEGER, rating_appeal INTEGER,
             rating_effort INTEGER, rating_ovr INTEGER)""")
conn.execute("""INSERT INTO roadmap_items VALUES('g101', 101, 'alpha rated row',
             NULL, 'Queue / parked intake', 1, NULL, 'docs/alpha.md',
             'https://example.invalid/issues/101', NULL, NULL, NULL,
             50, 50, 50, 50, NULL)""")
conn.execute("""INSERT INTO roadmap_items VALUES('g102', 102, 'beta unrated row',
             NULL, 'Queue / parked intake', 2, NULL, 'docs/beta.md',
             'https://example.invalid/issues/102', NULL, NULL, NULL,
             NULL, NULL, NULL, NULL, NULL)""")
conn.commit()
conn.close()
PY

pass=0; fail=0
# The planner exits 4 (drift) / 5 (items held) by design on fixture data — capture
# the report either way; the assertions below judge the CONTENT, not the rc.
planner_out="$(QUEUE_PLAN_ROOT="$FX" bash "$ROOT/utils/marathon-plan.sh" --dry-run 2>&1 || true)"

assert_present() {
  if grep -q "$2" <<<"$planner_out"; then
    pass=$((pass+1)); echo "  PASS: $1"
  else
    fail=$((fail+1)); echo "  FAIL: $1 (needle '$2' absent)"
  fi
}
assert_absent_from_unrated() {
  local unrated_lines
  unrated_lines="$(grep "unrated" <<<"$planner_out" || true)"
  if grep -q "$2" <<<"$unrated_lines"; then
    fail=$((fail+1)); echo "  FAIL: $1"
  else
    pass=$((pass+1)); echo "  PASS: $1"
  fi
}

assert_present "rated row (GH-101) reaches the plan"        "GH-101"
assert_present "unrated row held with the unrated flag"     "unrated"
assert_present "unrated flag names GH-102 (red control)"    "GH-102"
assert_absent_from_unrated "rated row never carries the unrated flag" "GH-101"

echo "gh698-planner-db-ratings: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
