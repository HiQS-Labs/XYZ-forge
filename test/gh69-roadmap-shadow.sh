#!/usr/bin/env bash
# GH-69 — the ROADMAP.md shadow: `releases roadmap sync` mirrors the ledger into roadmap_items.
#
# Shadow-phase contract under test (the GH-32 Phase-0 pattern, applied to a second subsystem):
#   * ROADMAP.md is the ONLY thing anyone edits; sync READS it and mirrors. It must never write
#     the markdown (pinned by hash).
#   * A no-change sync is a NO-OP: no write, no generation bump, no dump churn. Without this pin,
#     wiring sync into any routine path would grind the generation counter and make every clone's
#     releases.sql conflict with every other's for no content reason.
#   * Rows are GID-keyed (rmi-) and ride the SAME dump/rebuild/merge machinery as releases —
#     pinned by a full `check --rebuild` round-trip, not by reading the code.
#   * A duplicate GH-key in the markdown is refused by name, not resolved by pick-one.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
APP="$ROOT_DIR/utils/py/releases_app.py"

pass=0; fail=0
ok()   { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1" >&2; fail=$((fail+1)); fi }
has()  { printf '%s' "$1" | grep -Fq -- "$2"; }

echo "== test: gh69-roadmap-shadow =="
command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 required" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh69-shadow.XXXXXX")"
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
cleanup() {
  case "${WORK:-}" in
    "${TMPDIR:-/tmp}"/gh69-shadow.*) [ -d "$WORK" ] && rm -rf "$WORK" ;;
    *) echo "gh69: REFUSING cleanup outside the workspace: ${WORK:-<empty>}" >&2 ;;
  esac
}
trap cleanup EXIT

R="$WORK/r"
mkdir -p "$R"; require_fixture "$R" "shadow fixture"
git -C "$R" init -q -b main
git -C "$R" config user.email gh69@test.invalid
git -C "$R" config user.name gh69
ra() { require_fixture "$R" "shadow fixture"; python3 "$APP" --root "$R" "$@"; }
gen_now() { sqlite3 "$R/releases.db" "SELECT value FROM settings WHERE key='generation'"; }
sha() { shasum -a 256 "$1" | awk '{print $1}'; }

ra init --slug gh69 >/dev/null

cat > "$R/ROADMAP.md" <<'MD'
# Fixture roadmap
## Ledger
### In progress
- **GH-1 · containment gate** 🆕 **active** — narrative body. cx/risk/eff 2/3/2. → [doc](PROJECT/2-WORKING/GH-1.md) · [#1](https://github.com/HiQS-Suite/XYZ-forge/issues/1)
### Queue / parked intake
- **GH-32 · releases app** 🚧 — queued body. → [#32](https://github.com/HiQS-Suite/XYZ-forge/issues/32)
- **Title-keyed entry, no GH number** — keyed by title alone.
### Custom section the planner skips
- **GH-40 · lives under a heading the PLANNER does not read** — the shadow still mirrors it: its job is what the file says, not what the planner sees.
## After the ledger
- **not an entry** — outside ## Ledger, must not be captured.
MD

# ── 1. first sync: capture, fields, and the markdown untouched ──────────────────────────────────
MD_HASH="$(sha "$R/ROADMAP.md")"
out="$(ra roadmap sync 2>&1)"; rc=$?
ok "first sync succeeds (rc=$rc)" "[ $rc -eq 0 ]"
ok "  and captured all four ledger entries" "has \"\$out\" '+4 added'"
ok "  and ROADMAP.md is byte-identical (shadow never writes the markdown)" \
   "[ \"\$(sha '$R/ROADMAP.md')\" = \"$MD_HASH\" ]"
ok "  and the planner-invisible section IS mirrored (mirror the file, not the planner)" \
   "[ \"\$(sqlite3 '$R/releases.db' \"SELECT section FROM roadmap_items WHERE gh_number=40\")\" = 'Custom section the planner skips' ]"
ok "  and nothing outside ## Ledger leaked in" \
   "[ \"\$(sqlite3 '$R/releases.db' 'SELECT COUNT(*) FROM roadmap_items')\" = '4' ]"
ok "  and cx/risk/eff parsed as integers" \
   "[ \"\$(sqlite3 '$R/releases.db' 'SELECT complexity||risk||effort FROM roadmap_items WHERE gh_number=1')\" = '232' ]"
ok "  and the doc link + issue url landed" \
   "[ -n \"\$(sqlite3 '$R/releases.db' \"SELECT doc_path FROM roadmap_items WHERE gh_number=1 AND issue_url LIKE '%issues/1'\")\" ]"
ok "  and raw_text is the entry verbatim (lossless)" \
   "[ \"\$(sqlite3 '$R/releases.db' \"SELECT raw_text LIKE '- **GH-1%narrative body%' FROM roadmap_items WHERE gh_number=1\")\" = '1' ]"
ok "  and check is clean after the sync" "ra check >/dev/null 2>&1"
G1="$(gen_now)"

# ── 2. idempotence: a no-change sync writes NOTHING ─────────────────────────────────────────────
DUMP_HASH="$(sha "$R/releases.sql")"
out="$(ra roadmap sync 2>&1)"; rc=$?
ok "no-change sync is a no-op (rc=$rc)" "[ $rc -eq 0 ] && has \"\$out\" 'already in sync'"
ok "  and the generation did not move" "[ \"\$(gen_now)\" = \"$G1\" ]"
ok "  and the dump is byte-identical (no churn for clones to conflict over)" \
   "[ \"\$(sha '$R/releases.sql')\" = \"$DUMP_HASH\" ]"

# ── 3. dry run reports the diff and writes nothing ──────────────────────────────────────────────
sed -i '' 's/queued body\./queued body, EDITED./' "$R/ROADMAP.md"
out="$(ra roadmap sync --dry-run 2>&1)"; rc=$?
ok "dry run names the pending update (rc=$rc)" "[ $rc -eq 0 ] && has \"\$out\" 'DRY RUN' && has \"\$out\" '~1 updated'"
ok "  and wrote nothing" "[ \"\$(gen_now)\" = \"$G1\" ] && [ \"\$(sha '$R/releases.sql')\" = \"$DUMP_HASH\" ]"

# ── 4. update keeps the GID; removal deletes the row ────────────────────────────────────────────
GID32="$(sqlite3 "$R/releases.db" "SELECT global_id FROM roadmap_items WHERE gh_number=32")"
sed -i '' '/Title-keyed entry/d' "$R/ROADMAP.md"
out="$(ra roadmap sync 2>&1)"; rc=$?
ok "edit+removal sync applies both (rc=$rc)" "[ $rc -eq 0 ] && has \"\$out\" '~1 updated' && has \"\$out\" '1 removed,'"
ok "  and GH-32's GID is stable across the update" \
   "[ \"\$(sqlite3 '$R/releases.db' \"SELECT global_id FROM roadmap_items WHERE gh_number=32\")\" = \"$GID32\" ]"
ok "  and the removed row is gone" \
   "[ \"\$(sqlite3 '$R/releases.db' 'SELECT COUNT(*) FROM roadmap_items')\" = '3' ]"
ok "  and the receipt chain is still intact" "ra check 2>&1 | grep -q 'receipt chain intact'"

# ── 5. the shadow rides the merge machinery: full rebuild round-trip ────────────────────────────
git -C "$R" add -A; git -C "$R" commit -qm shadow
BEFORE="$(sqlite3 "$R/releases.db" "SELECT group_concat(global_id||':'||gh_number, ',') FROM roadmap_items ORDER BY id")"
out="$(ra check --rebuild 2>&1)"; rc=$?
ok "check --rebuild accepts a dump carrying roadmap rows (rc=$rc)" "[ $rc -eq 0 ]"
AFTER="$(sqlite3 "$R/releases.db" "SELECT group_concat(global_id||':'||gh_number, ',') FROM roadmap_items ORDER BY id")"
ok "  and every shadow row survived the dump -> DB round-trip, GIDs intact" \
   "[ -n \"$BEFORE\" ] && [ \"$BEFORE\" = \"$AFTER\" ]"
ok "  and check is clean on the rebuilt DB" "ra check >/dev/null 2>&1"
rm -f "$R/releases.db.bak"

# ── 6. a duplicate GH key in the markdown is refused by name ────────────────────────────────────
# insert INSIDE the ledger (an append lands after '## After the ledger' and is correctly ignored)
python3 - "$R/ROADMAP.md" <<'PYIN'
import sys
p=sys.argv[1]; s=open(p).read()
s=s.replace("### Custom section the planner skips",
            "- **GH-32 \u00b7 a second entry claiming the same number** \u2014 ambiguous.\n### Custom section the planner skips")
open(p,"w").write(s)
PYIN
G5="$(gen_now)"
out="$(ra roadmap sync 2>&1)"; rc=$?
ok "duplicate GH number refuses (rc=$rc)" "[ $rc -ne 0 ]"
ok "  and names the rule" "has \"\$out\" 'rule=roadmap-duplicate-gh'"
ok "  and nothing was written" "[ \"\$(gen_now)\" = \"$G5\" ]"

echo
echo "  gh69-roadmap-shadow: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
