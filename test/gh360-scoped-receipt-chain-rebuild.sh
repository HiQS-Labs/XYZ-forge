#!/usr/bin/env bash
# GH-360 — releases check: scoped --rebuild and non-catastrophic receipt-chain error message.
#
# Covers:
#   * Describing receipt-chain breaks as git-induced discontinuities rather than "spliced or forged".
#   * `releases check --rebuild` recording the break count in target_gid ('reanchor:N').
#   * `releases check` tolerating at most the re-anchored count and failing on subsequent breaks.
#   * Backwards compatibility with legacy `target_gid IS NULL` merge-rebuild receipts.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
APP="$ROOT_DIR/utils/py/releases_app.py"

pass=0; fail=0
ok()   { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1" >&2; fail=$((fail+1)); fi }
has()  { printf '%s' "$1" | grep -Fq -- "$2"; }

echo "== test: gh360-scoped-receipt-chain-rebuild =="
command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 required" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh360-rebuild.XXXXXX")"
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
cleanup() {
  case "${WORK:-}" in
    "${TMPDIR:-/tmp}"/gh360-rebuild.*) [ -d "$WORK" ] && rm -rf "$WORK" ;;
    *) echo "gh360: REFUSING cleanup outside the workspace: ${WORK:-<empty>}" >&2 ;;
  esac
}
trap cleanup EXIT

R="$WORK/r"
mkdir -p "$R"; require_fixture "$R" "gh360 fixture"
git -C "$R" init -q -b main
git -C "$R" config user.email gh360@test.invalid
git -C "$R" config user.name gh360
ra() { require_fixture "$R" "gh360 fixture"; python3 "$APP" --root "$R" "$@"; }

# 1. Initialize repo and verify clean check
ra init >/dev/null 2>&1 || { echo "init failed" >&2; exit 1; }

out="$(ra check 2>&1)"; rc=$?
ok "clean repo passes releases check (rc=0)" "[ $rc -eq 0 ]"

# 2. Simulate a branch fork where two branches author operations from the same ancestor
# Save the ancestor DB and dump
cp "$R/releases.sql" "$WORK/ancestor.sql"
cp "$R/releases.db" "$WORK/ancestor.db"

# Branch A operation
ra roadmap add --issue-num 101 --issue-url https://example.com/101 --title "Item 101" --created 2026-08-31 --doc-path "PROJECT/2-WORKING/101.md" >/dev/null 2>&1
cp "$R/releases.sql" "$WORK/branch_a.sql"

# Restore ancestor and do Branch B operation
cp "$WORK/ancestor.sql" "$R/releases.sql"
cp "$WORK/ancestor.db" "$R/releases.db"
ra roadmap add --issue-num 102 --issue-url https://example.com/102 --title "Item 102" --created 2026-08-31 --doc-path "PROJECT/2-WORKING/102.md" >/dev/null 2>&1
cp "$R/releases.sql" "$WORK/branch_b.sql"

# Union the dumps to simulate merge conflict resolution (combines rows and receipts)
python3 -c "
import re
lines_a = open('$WORK/branch_a.sql').read().splitlines()
lines_b = open('$WORK/branch_b.sql').read().splitlines()
max_gen = 1
for ln in lines_a + lines_b:
    m = re.match(r'^-- generation: (\d+)$', ln.strip())
    if m:
        max_gen = max(max_gen, int(m.group(1)))
out_lines = ['-- generation: %d' % max_gen]
seen_settings = set()
seen_other = set()
for ln in lines_a + lines_b:
    ln_s = ln.strip()
    if not ln_s or ln_s.startswith('--'):
        continue
    if 'INSERT INTO settings' in ln:
        m = re.search(r\"VALUES\('([^']+)'\", ln)
        if m:
            k = m.group(1)
            if k in seen_settings:
                continue
            seen_settings.add(k)
            if k == 'generation':
                ln = \"INSERT INTO settings(key, value) VALUES('generation', '%d');\" % max_gen
    elif ln in seen_other:
        continue
    else:
        seen_other.add(ln)
    out_lines.append(ln)
open('$R/releases.sql', 'w').write('\n'.join(out_lines) + '\n')
"

# Load DB directly from merged dump without running check --rebuild (so chain break is present)
python3 -c "
import os, sys, sqlite3
sys.path.insert(0, '$ROOT_DIR/utils/py')
import releases_app
db_path = '$R/releases.db'
if os.path.exists(db_path):
    os.unlink(db_path)
tconn = sqlite3.connect(db_path, isolation_level=None)
tconn.row_factory = sqlite3.Row
tconn.execute('PRAGMA foreign_keys = ON')
releases_app.apply_migrations(tconn, stamp_ledger=False)
dump_text = open('$R/releases.sql').read()
parsed = releases_app.parse_dump(dump_text)
releases_app.load_dump(tconn, parsed, skip_schema_migrations=False)
tconn.close()
"

out="$(ra check 2>&1)"; rc=$?
ok "un-reanchored chain break fails check (rc=1)" "[ $rc -eq 1 ]"
if has "$out" "likely caused by git branch switching or rebasing"; then
  ok "error message states git branch switching / rebasing as likely cause" "true"
else
  echo "DEBUG output: $out" >&2
  ok "error message states git branch switching / rebasing as likely cause" "false"
fi
if ! has "$out" "spliced or forged"; then
  ok "error message does NOT claim 'spliced or forged audit trail'" "true"
else
  ok "error message does NOT claim 'spliced or forged audit trail'" "false"
fi
if has "$out" "run \`releases check --rebuild\` to re-anchor"; then
  ok "error message gives remediation command 'releases check --rebuild'" "true"
else
  ok "error message gives remediation command 'releases check --rebuild'" "false"
fi

# 3. Run releases check --rebuild to re-anchor the break
out_rebuild="$(ra check --rebuild 2>&1)"; rc_rebuild=$?
ok "releases check --rebuild succeeds (rc=0)" "[ $rc_rebuild -eq 0 ]"

# Verify the merge-rebuild receipt has target_gid = 'reanchor:2'
last_target_gid="$(sqlite3 "$R/releases.db" "SELECT target_gid FROM op_receipts WHERE op='merge-rebuild' ORDER BY id DESC LIMIT 1")"
ok "merge-rebuild receipt recorded reanchor:2 in target_gid ($last_target_gid)" "[ '$last_target_gid' = 'reanchor:2' ]"

out="$(ra check 2>&1)"; rc=$?
ok "after rebuild, releases check passes with tolerated break note (rc=0)" "[ $rc -eq 0 ]"
if has "$out" "2 merge fork(s) tolerated under the merge-rebuild receipt"; then
  ok "check output announces 2 merge forks tolerated" "true"
else
  echo "DEBUG check output: $out" >&2
  ok "check output announces 2 merge forks tolerated" "false"
fi

# 4. Introduce a SECOND break occurring AFTER the rebuild
# Save rebuilt state
cp "$R/releases.sql" "$WORK/rebuilt.sql"
cp "$R/releases.db" "$WORK/rebuilt.db"

# Branch C operation
ra roadmap add --issue-num 103 --issue-url https://example.com/103 --title "Item 103" --created 2026-08-31 --doc-path "PROJECT/2-WORKING/103.md" >/dev/null 2>&1
cp "$R/releases.sql" "$WORK/branch_c.sql"

# Restore rebuilt and do Branch D operation
cp "$WORK/rebuilt.sql" "$R/releases.sql"
cp "$WORK/rebuilt.db" "$R/releases.db"
ra roadmap add --issue-num 104 --issue-url https://example.com/104 --title "Item 104" --created 2026-08-31 --doc-path "PROJECT/2-WORKING/104.md" >/dev/null 2>&1
cp "$R/releases.sql" "$WORK/branch_d.sql"

# Union branch C and D dumps
python3 -c "
import re
lines_c = open('$WORK/branch_c.sql').read().splitlines()
lines_d = open('$WORK/branch_d.sql').read().splitlines()
max_gen = 1
for ln in lines_c + lines_d:
    m = re.match(r'^-- generation: (\d+)$', ln.strip())
    if m:
        max_gen = max(max_gen, int(m.group(1)))
out_lines = ['-- generation: %d' % max_gen]
seen_settings = set()
seen_other = set()
for ln in lines_c + lines_d:
    ln_s = ln.strip()
    if not ln_s or ln_s.startswith('--'):
        continue
    if 'INSERT INTO settings' in ln:
        m = re.search(r\"VALUES\('([^']+)'\", ln)
        if m:
            k = m.group(1)
            if k in seen_settings:
                continue
            seen_settings.add(k)
            if k == 'generation':
                ln = \"INSERT INTO settings(key, value) VALUES('generation', '%d');\" % max_gen
    elif ln in seen_other:
        continue
    else:
        seen_other.add(ln)
    out_lines.append(ln)
open('$R/releases.sql', 'w').write('\n'.join(out_lines) + '\n')
"

# Reload DB from new merged dump (without running check --rebuild yet)
python3 -c "
import os, sys, sqlite3
sys.path.insert(0, '$ROOT_DIR/utils/py')
import releases_app
db_path = '$R/releases.db'
if os.path.exists(db_path):
    os.unlink(db_path)
tconn = sqlite3.connect(db_path, isolation_level=None)
tconn.row_factory = sqlite3.Row
tconn.execute('PRAGMA foreign_keys = ON')
releases_app.apply_migrations(tconn, stamp_ledger=False)
dump_text = open('$R/releases.sql').read()
parsed = releases_app.parse_dump(dump_text)
releases_app.load_dump(tconn, parsed, skip_schema_migrations=False)
tconn.close()
"

out="$(ra check 2>&1)"; rc=$?
ok "subsequent break after previous rebuild fails check (rc=1)" "[ $rc -eq 1 ]"
if has "$out" "1 new receipt(s) break the chain (3 total break(s), 2 re-anchored)"; then
  ok "error message distinguishes new breaks from previously re-anchored breaks" "true"
else
  echo "DEBUG output: $out" >&2
  ok "error message distinguishes new breaks from previously re-anchored breaks" "false"
fi

# 5. Rebuild again to re-anchor the second break
out_rebuild2="$(ra check --rebuild 2>&1)"; rc_rebuild2=$?
ok "second releases check --rebuild succeeds (rc=0)" "[ $rc_rebuild2 -eq 0 ]"

last_target_gid2="$(sqlite3 "$R/releases.db" "SELECT target_gid FROM op_receipts WHERE op='merge-rebuild' ORDER BY id DESC LIMIT 1")"
ok "second merge-rebuild receipt recorded reanchor:4 in target_gid ($last_target_gid2)" "[ '$last_target_gid2' = 'reanchor:4' ]"

out="$(ra check 2>&1)"; rc=$?
ok "after second rebuild, releases check passes (rc=0)" "[ $rc -eq 0 ]"
if has "$out" "4 merge fork(s) tolerated under the merge-rebuild receipt"; then
  ok "check output announces 4 merge forks tolerated" "true"
else
  echo "DEBUG check output: $out" >&2
  ok "check output announces 4 merge forks tolerated" "false"
fi

# 6. Legacy merge-rebuild receipt compatibility (target_gid IS NULL)
# Update dump and DB so merge-rebuild receipts have NULL target_gid
sed -i.bak "s/'reanchor:[0-9]*'/NULL/g" "$R/releases.sql"
python3 -c "
import sqlite3
conn = sqlite3.connect('$R/releases.db')
conn.execute('DROP TRIGGER IF EXISTS op_no_update')
conn.execute('UPDATE op_receipts SET target_gid = NULL WHERE op = \"merge-rebuild\"')
conn.execute(\"\"\"CREATE TRIGGER op_no_update BEFORE UPDATE ON op_receipts
                 BEGIN SELECT RAISE(ABORT, 'op_receipts is append-only'); END;\"\"\")
conn.commit()
conn.close()
"
out="$(ra check 2>&1)"; rc=$?
ok "legacy NULL target_gid merge-rebuild receipts pass when no new breaks exist (rc=0)" "[ $rc -eq 0 ]"

echo "gh360: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
