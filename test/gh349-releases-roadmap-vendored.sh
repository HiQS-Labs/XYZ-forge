#!/usr/bin/env bash
# GH-349 — releases ledger: roadmap layer generalisation for vendored installs
#
# Tests:
#   1. parse_roadmap_ledger accepts link-style bullets: `- [Title](doc_path) — ...`
#   2. parse_roadmap_ledger extracts issue and PR URLs from any GitHub org/repo
#   3. roadmap sync successfully populates roadmap_items from link-style bullets in legacy mode
#   4. roadmap sync refuses with rule=roadmap-empty-parse when parsing 0 entries from a non-empty ledger (prevents table deletion)
#   5. review regressions (LTVera-Pandas #322): anchored GH key, umbrella titles, doc_path vs URL,
#      issue_url anchoring, task-list checkboxes
#   6. this repo's own ROADMAP.md parses with no duplicate GH keys
#   5. RELEASES-DB-FAQS.md contains the canonical rating system documentation
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
APP="$ROOT_DIR/utils/py/releases_app.py"

pass=0; fail=0
ok()   { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1" >&2; fail=$((fail+1)); fi }
has()  { printf '%s' "$1" | grep -Fq -- "$2"; }

echo "== test: gh349-releases-roadmap-vendored =="
command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 required" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh349-vendored.XXXXXX")"
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
cleanup() {
  case "${WORK:-}" in
    "${TMPDIR:-/tmp}"/gh349-vendored.*) [ -d "$WORK" ] && rm -rf "$WORK" ;;
    *) echo "gh349: REFUSING cleanup outside the workspace: ${WORK:-<empty>}" >&2 ;;
  esac
}
trap cleanup EXIT

R="$WORK/r"
mkdir -p "$R"; require_fixture "$R" "vendored roadmap fixture"
git -C "$R" init -q -b main
git -C "$R" config user.email gh349@test.invalid
git -C "$R" config user.name gh349
ra() { require_fixture "$R" "vendored roadmap fixture"; python3 "$APP" --root "$R" "$@"; }

ra init --slug test-vendored-repo >/dev/null
ra migrate >/dev/null

# ── 1. Create link-style ROADMAP.md with external orgs ──────────────────────────────
cat > "$R/ROADMAP.md" <<'MD'
# Vendored Repo Roadmap

## Ledger

### Queue / parked intake
- [GH-349 — releases ledger roadmap layer never generalised to a vendored install](PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md) - narrative body. (rated 85/70/90/60) -> [#349](https://github.com/ExternalOrg/CustomRepo/issues/349)
- [GH-420 — external pull request tracking](docs/pr-420.md) - narrative body. (rated 50/40/60/70 ovr 220) -> [#420](https://github.com/OtherOrg/AnotherRepo/pull/420)
- [Un-numbered item with link](docs/plans/item.md) - plain title. (rated 60/60/60/60)
### In progress
- **GH-100 · traditional bold bullet** 🚧 — standard bold form. (rated 75/65/80/55) -> [#100](https://github.com/CustomOrg/CustomRepo/issues/100)
MD

# ── 2. Sync link-style bullets in legacy mode ───────────────────────────────────────
out="$(ra roadmap sync 2>&1)"; rc=$?
ok "sync succeeds with link-style bullets (rc=$rc)" "[ $rc -eq 0 ]"
ok "  and captured all 4 ledger entries" "has \"\$out\" '+4 added'"

count="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items")"
ok "  and database has 4 roadmap items" "[ \"$count\" = '4' ]"

# Verify link-style item fields
gh349_title="$(sqlite3 "$R/releases.db" "SELECT title FROM roadmap_items WHERE gh_number=349")"
ok "  and GH-349 title extracted correctly" "[ \"$gh349_title\" = 'GH-349 — releases ledger roadmap layer never generalised to a vendored install' ]"

gh349_doc="$(sqlite3 "$R/releases.db" "SELECT doc_path FROM roadmap_items WHERE gh_number=349")"
ok "  and GH-349 doc_path extracted correctly" "[ \"$gh349_doc\" = 'PROJECT/2-WORKING/GH-349-RELEASES-ROADMAP-VENDORED.md' ]"

gh349_url="$(sqlite3 "$R/releases.db" "SELECT issue_url FROM roadmap_items WHERE gh_number=349")"
ok "  and GH-349 external org issue URL extracted correctly" "[ \"$gh349_url\" = 'https://github.com/ExternalOrg/CustomRepo/issues/349' ]"

gh349_pri="$(sqlite3 "$R/releases.db" "SELECT rating_pri FROM roadmap_items WHERE gh_number=349")"
ok "  and GH-349 rating_pri extracted correctly" "[ \"$gh349_pri\" = '85' ]"

# Verify PR URL extraction on external org
gh420_url="$(sqlite3 "$R/releases.db" "SELECT issue_url FROM roadmap_items WHERE gh_number=420")"
ok "  and GH-420 external org pull URL extracted correctly" "[ \"$gh420_url\" = 'https://github.com/OtherOrg/AnotherRepo/pull/420' ]"

gh420_ovr="$(sqlite3 "$R/releases.db" "SELECT rating_ovr FROM roadmap_items WHERE gh_number=420")"
ok "  and GH-420 rating_ovr extracted correctly" "[ \"$gh420_ovr\" = '220' ]"

# ── 3. Re-sync without changes is a no-op ───────────────────────────────────────────
out="$(ra roadmap sync 2>&1)"; rc=$?
ok "second sync is no-op (rc=$rc)" "[ $rc -eq 0 ]"
ok "  and reports already in sync" "has \"\$out\" 'already in sync'"

# ── 4. Empty-parse refusal guard ───────────────────────────────────────────────────
# Simulate format drift / malformed ledger where 0 entries are parsed from non-empty ledger
cat > "$R/ROADMAP.md" <<'MD'
# Malformed Roadmap

## Ledger

### Queue / parked intake
Some unbulleted drift prose that parses to 0 entries.
MD

out="$(ra roadmap sync 2>&1)"; rc=$?
ok "sync refuses on 0 parsed entries from non-empty ledger (rc=$rc)" "[ $rc -ne 0 ]"
ok "  and refusal cites rule=roadmap-empty-parse" "has \"\$out\" 'rule=roadmap-empty-parse'"

count_after="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items")"
ok "  and existing roadmap_items were NOT deleted" "[ \"$count_after\" = '4' ]"

# ── 5. RELEASES-DB-FAQS.md rating documentation ─────────────────────────────────────
faqs="$ROOT_DIR/RELEASES-DB-FAQS.md"
ok "RELEASES-DB-FAQS.md exists" "[ -f \"$faqs\" ]"
ok "  and documents canonical rating grammar" "grep -Fq 'rated <pri>/<sev>/<appeal>/<effort>' \"$faqs\""
ok "  and documents cheapness effort axis" "grep -Fq 'cheapness' \"$faqs\""
ok "  and documents legacy cx/risk/eff separation" "grep -Fq 'cx/risk/eff' \"$faqs\""

# ── 6. Review regressions (LTVera-Pandas #322 review of PR #350) ────────────────────
# Four defects the first cut of this fix introduced or left standing:
#   a. an unanchored GH search harvested a number out of a title that merely MENTIONS one,
#      colliding with the real entry and making `roadmap sync` refuse on XYZ-forge's own ledger
#   b. a multi-issue umbrella title was keyed to whichever issue it named first
#   c. `doc_path` was filled with the link target even when that target was a GitHub URL
#   d. `issue_url` took the first URL anywhere in the block, so a hook citing another repo or a
#      PR in passing silently re-keyed the entry
#   e. markdown task-list items (`- [ ]`) parsed as entries with an empty title
cat > "$R/ROADMAP.md" <<'MD'
# Review Regression Roadmap

## Ledger

### Queue / parked intake
- [ ] a task-list checkbox that is not a ledger entry
- [x] another checkbox that is not a ledger entry
- [GH-500 — issue-linked bullet with no PDDA doc](https://github.com/ExternalOrg/CustomRepo/issues/500) - the link target is the issue itself, not a document.
- [GH-501 — hook cites other work in passing](docs/plans/gh-501.md) - the canonical issue lived in [otherrepo#2](https://github.com/ExternalOrg/OtherRepo/issues/2) and it shipped via [#502](https://github.com/ExternalOrg/CustomRepo/pull/502).
- [#503 — a hash-prefixed title is a real key](docs/plans/gh-503.md) - narrative body.
### In progress
- **Execution checklist for GH-500 + GH-501** — a bold title that MENTIONS issues it is not keyed by.
- **#601/#602/#603 · umbrella wave heading** — names three issues; none of them is its key.
- **GH-701..706 · umbrella wave range** — a dotted RANGE is six issues, not issue 701.
- **GH-707 — 2026 planning cycle** — an em-dash before a number is NOT a range; this IS keyed.
MD

out="$(ra roadmap sync 2>&1)"; rc=$?
ok "review-regression ledger syncs (rc=$rc)" "[ $rc -eq 0 ]"

count6="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items")"
ok "  and task-list checkboxes are not entries (7 rows, not 9)" "[ \"$count6\" = '7' ]"

box="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items WHERE title = '' OR title = 'x'")"
ok "  and no empty-titled checkbox row was stored" "[ \"$box\" = '0' ]"

mention="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE 'Execution checklist%'")"
ok "  and a title that only MENTIONS GH-500/GH-501 is not keyed by either" "[ \"$mention\" = 'NULL' ]"

umbrella="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE '#601%'")"
ok "  and a multi-issue umbrella title carries no key" "[ \"$umbrella\" = 'NULL' ]"

hash_key="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items WHERE gh_number = 503")"
ok "  and a hash-prefixed single-issue title IS keyed" "[ \"$hash_key\" = '1' ]"

rng="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE 'GH-701%'")"
ok "  and a dotted RANGE umbrella carries no key (agy QA)" "[ \"$rng\" = 'NULL' ]"

dash="$(sqlite3 "$R/releases.db" "SELECT COALESCE(gh_number,'NULL') FROM roadmap_items WHERE title LIKE 'GH-707%'")"
ok "  but an em-dash before a number is NOT a range — that title keeps its key" "[ \"$dash\" = '707' ]"

doc500="$(sqlite3 "$R/releases.db" "SELECT COALESCE(doc_path,'NULL') FROM roadmap_items WHERE gh_number=500")"
ok "  and an issue-linked bullet leaves doc_path NULL, not a URL" "[ \"$doc500\" = 'NULL' ]"

url500="$(sqlite3 "$R/releases.db" "SELECT issue_url FROM roadmap_items WHERE gh_number=500")"
ok "  and that bullet's own link target becomes issue_url" "[ \"$url500\" = 'https://github.com/ExternalOrg/CustomRepo/issues/500' ]"

url501="$(sqlite3 "$R/releases.db" "SELECT COALESCE(issue_url,'NULL') FROM roadmap_items WHERE gh_number=501")"
ok "  and a hook citing a foreign repo/PR does not re-key the entry" "[ \"$url501\" = 'NULL' ]"

doc501="$(sqlite3 "$R/releases.db" "SELECT doc_path FROM roadmap_items WHERE gh_number=501")"
ok "  and its real doc_path still resolves" "[ \"$doc501\" = 'docs/plans/gh-501.md' ]"

# ── 7. This repo's own ROADMAP.md still parses, with no duplicate keys ──────────────
# The regression that made this review necessary: the widened key search created a second
# GH-111 in XYZ-forge's own ledger, which `roadmap sync` refuses on outright.
self_dup="$(python3 - "$ROOT_DIR" <<'PY'
import collections, importlib.util, os, sys
root = sys.argv[1]
spec = importlib.util.spec_from_file_location("ra", os.path.join(root, "utils/py/releases_app.py"))
m = importlib.util.module_from_spec(spec)
sys.argv = ["ra"]
try:
    spec.loader.exec_module(m)
except SystemExit:
    pass
e = m.parse_roadmap_ledger(os.path.join(root, "ROADMAP.md"))
c = collections.Counter(x["gh_number"] for x in e if x["gh_number"])
print("%d %s" % (len(e), ",".join(str(k) for k, v in sorted(c.items()) if v > 1) or "none"))
PY
)"
ok "this repo's own ROADMAP.md parses a non-empty ledger" "[ \"${self_dup%% *}\" -gt 0 ]"
ok "  and yields no duplicate GH keys (would refuse roadmap sync)" "[ \"${self_dup##* }\" = 'none' ]"



echo "Results: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
