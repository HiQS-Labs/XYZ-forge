#!/usr/bin/env bash
# GH-698 F2/F4: the marathon planner reads the DB's canonical four-axis ratings —
# a rated row sequences into active lanes; an unrated row holds as `unrated`
# (red control). Fixture DB built via direct sqlite (test_gh605 pattern).
# GH-710: rows with gh_number NULL (doc-only rows are legal) — the planner must not
# crash on them, must point the `unrated` hint at the row's gid, and must count a
# row rated via `roadmap rate --gid` as rated. Fixture docs live under
# PROJECT/2-WORKING/ because that is the planner's capture-doc rule (_doc_of):
# a docs/ link never reaches the rated/unrated branch at all (it is `needs-doc`).
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
mkdir -p PROJECT/2-WORKING
cat > PROJECT/2-WORKING/alpha.md <<'EOF'
---
title: alpha
---
## Swarm Preflight Contract

```json
{"artifacts": ["PROJECT/2-WORKING/alpha.md"], "lanes": {}}
```
EOF
cat > PROJECT/2-WORKING/gamma.md <<'EOF'
---
title: gamma
complexity: 3
risk: 4
effort: 2
---
## Swarm Preflight Contract

```json
{"artifacts": ["PROJECT/2-WORKING/gamma.md"], "lanes": {}}
```
EOF
cat > PROJECT/2-WORKING/beta.md <<'EOF'
---
title: beta
---
## Swarm Preflight Contract

```json
{"artifacts": ["PROJECT/2-WORKING/beta.md"], "lanes": {}}
```
EOF
cat > PROJECT/2-WORKING/delta.md <<'EOF'
---
title: delta
---
## Swarm Preflight Contract

```json
{"artifacts": ["PROJECT/2-WORKING/delta.md"], "lanes": {}}
```
EOF
cat > PROJECT/2-WORKING/epsilon.md <<'EOF'
---
title: epsilon
---
## Swarm Preflight Contract

```json
{"artifacts": ["PROJECT/2-WORKING/epsilon.md"], "lanes": {}}
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
             NULL, 'Queue / parked intake', 1, NULL, 'PROJECT/2-WORKING/alpha.md',
             'https://example.invalid/issues/101', NULL, NULL, NULL,
             50, 50, 50, 50, NULL)""")
conn.execute("""INSERT INTO roadmap_items VALUES('g103', 103, 'gamma both-vocab row',
             NULL, 'Queue / parked intake', 3, NULL, 'PROJECT/2-WORKING/gamma.md',
             'https://example.invalid/issues/103', 3, 4, 2,
             70, 60, 50, 40, NULL)""")
conn.execute("""INSERT INTO roadmap_items VALUES('g102', 102, 'beta unrated row',
             NULL, 'Queue / parked intake', 2, NULL, 'PROJECT/2-WORKING/beta.md',
             'https://example.invalid/issues/102', NULL, NULL, NULL,
             NULL, NULL, NULL, NULL, NULL)""")
# GH-710: doc-only rows (gh_number NULL). g104 unrated; g105 rated only by its four
# columns (what `roadmap rate --gid` writes) — no gh, no legacy frontmatter.
conn.execute("""INSERT INTO roadmap_items VALUES('g104', NULL, 'delta doc-only unrated',
             NULL, 'Queue / parked intake', 4, NULL, 'PROJECT/2-WORKING/delta.md',
             NULL, NULL, NULL, NULL,
             NULL, NULL, NULL, NULL, NULL)""")
conn.execute("""INSERT INTO roadmap_items VALUES('g105', NULL, 'epsilon doc-only rated by gid',
             NULL, 'Queue / parked intake', 5, NULL, 'PROJECT/2-WORKING/epsilon.md',
             NULL, NULL, NULL, NULL,
             60, 60, 50, 60, NULL)""")
conn.commit()
conn.close()
PY

pass=0; fail=0
# The planner exits 4 (drift) / 5 (items held) by design on fixture data — capture the
# report AND the plan doc it writes (the report lists flags only; lanes, ranks and wave
# order live in PROJECT/2-WORKING/MARATHON-PLAN-<today>.md), and judge the CONTENT.
planner_rc=0
planner_out="$(QUEUE_PLAN_ROOT="$FX" bash "$ROOT/utils/marathon-plan.sh" 2>&1)" || planner_rc=$?
plan_doc="$(cat "$FX"/PROJECT/2-WORKING/MARATHON-PLAN-*.md 2>/dev/null || true)"

assert_in() {  # <label> <needle> <haystack>
  if grep -qF -- "$2" <<<"$3"; then
    pass=$((pass+1)); echo "  PASS: $1"
  else
    fail=$((fail+1)); echo "  FAIL: $1 (needle '$2' absent)"
  fi
}
assert_absent_from_unrated() {
  local unrated_lines
  unrated_lines="$(grep "unrated" <<<"$planner_out" || true)"
  if grep -qF -- "$2" <<<"$unrated_lines"; then
    fail=$((fail+1)); echo "  FAIL: $1"
  else
    pass=$((pass+1)); echo "  PASS: $1"
  fi
}
assert_before() {  # <label> <first> <second> <haystack> — first must appear before second
  local h="$4" a b
  a="${h%%"$2"*}"; b="${h%%"$3"*}"   # text before each needle; shorter prefix = earlier
  if grep -qF -- "$2" <<<"$h" && grep -qF -- "$3" <<<"$h" && [ "${#a}" -lt "${#b}" ]; then
    pass=$((pass+1)); echo "  PASS: $1"
  else
    fail=$((fail+1)); echo "  FAIL: $1"
  fi
}

[ -n "$plan_doc" ] && { pass=$((pass+1)); echo "  PASS: planner wrote the plan doc"; } \
  || { fail=$((fail+1)); echo "  FAIL: no MARATHON-PLAN doc written (rc=$planner_rc)"; echo "$planner_out" | tail -5; }

assert_in "rated row (GH-101) reaches the plan"        "[#101] GH-101 · alpha rated row" "$plan_doc"
assert_in "unrated row held with the unrated flag"     "INFO [unrated]  GH-102 · beta unrated row" "$planner_out"
assert_in "unrated hint for a gh row names --issue-num (red control)" "rate --issue-num 102 --rated" "$planner_out"
assert_in "both-vocab row (GH-103) reaches the plan"   "[#103] GH-103 · gamma both-vocab row" "$plan_doc"
assert_absent_from_unrated "both-vocab row never flagged unrated (DB precedence)" "GH-103"
# DB score precedence: GH-103 (rank 220) must ORDER before GH-101 (rank 200) in the scoring
# table — the assertions above would still pass if ordering used legacy frontmatter.
assert_in "GH-103 scored by the DB rank (220), not legacy cx/risk/effort" "gamma both-vocab row | db pri/sev/app/eff = —/—/—/— · rank 220" "$plan_doc"
assert_before "DB score precedence — GH-103 (rank 220) orders before GH-101 (rank 200)" "[#103] GH-103" "[#101] GH-101" "$plan_doc"
assert_absent_from_unrated "rated row never carries the unrated flag" "GH-101"

# GH-710 — NULL-gh rows must not crash the planner (pre-fix: TypeError, rc 1, no report at all).
case "$planner_rc" in
  4|5) pass=$((pass+1)); echo "  PASS: GH-710: planner exits $planner_rc (held/drift), not 1, with NULL-gh rows present" ;;
  *)   fail=$((fail+1)); echo "  FAIL: GH-710: planner rc=$planner_rc (expected 4 or 5)"; echo "$planner_out" | tail -5 ;;
esac
assert_in "GH-710: unrated NULL-gh row is held with the unrated flag" "INFO [unrated]  delta doc-only unrated" "$planner_out"
assert_in "GH-710: its hint names the row's gid, not --issue-num" "rate --gid g104 --rated P/S/A/E (row has no gh_number)" "$planner_out"
assert_in "GH-710: gid-rated NULL-gh row (g105) reaches the plan" "epsilon doc-only rated by gid | db pri/sev/app/eff" "$plan_doc"
assert_in "GH-710: g105 is scored by ITS OWN four columns (60+60+50+60 = 230)" "epsilon doc-only rated by gid | db pri/sev/app/eff = —/—/—/— · rank 230" "$plan_doc"
assert_absent_from_unrated "GH-710: gid-rated NULL-gh row never flagged unrated" "epsilon doc-only rated by gid"
assert_before "GH-710: g105 (230) orders before GH-103 (220) — DB rank applies to NULL-gh rows too" "epsilon doc-only rated by gid |" "[#103] GH-103" "$plan_doc"

echo "gh698-planner-db-ratings: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
