#!/usr/bin/env bash
# GH-360 — releases check: scoped --rebuild and non-catastrophic receipt-chain error message.
#
# Covers:
#   * Describing receipt-chain breaks as git-induced discontinuities rather than "spliced or forged".
#   * `releases check --rebuild` recording the break count in target_gid ('reanchor:N').
#   * `releases check` tolerating at most the re-anchored count and failing on subsequent breaks.
#   * Backwards compatibility with legacy `target_gid IS NULL` merge-rebuild receipts.
#   * Rejection of malformed / non-canonical rebuild scope target_gid values.
#   * Catching breaks that occur after a legacy `target_gid IS NULL` merge-rebuild receipt without dump divergence.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
APP="$ROOT_DIR/utils/py/releases_app.py"

pass=0; fail=0
ok(){ if [ "$2" = "0" ]; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1" >&2; fail=$((fail+1)); fi; }
is(){ [ "$1" = "$2" ]; }
has(){ printf '%s' "$1" | grep -Fq -- "$2"; }

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

# Helper to atomically update target_gid on merge-rebuild receipts and regenerate canonical releases.sql
set_rebuild_target_gid() {
  val="$1"
  python3 -c "
import sys, sqlite3
sys.path.insert(0, '$ROOT_DIR/utils/py')
import releases_app
conn = sqlite3.connect('$R/releases.db')
conn.row_factory = sqlite3.Row
conn.execute('DROP TRIGGER IF EXISTS op_no_update')
if '$val' == 'NULL':
    conn.execute(\"UPDATE op_receipts SET target_gid = NULL WHERE op = 'merge-rebuild'\")
else:
    conn.execute(\"UPDATE op_receipts SET target_gid = '$val' WHERE op = 'merge-rebuild'\")
conn.execute(\"\"\"CREATE TRIGGER op_no_update BEFORE UPDATE ON op_receipts
                 BEGIN SELECT RAISE(ABORT, 'op_receipts is append-only'); END;\"\"\")
conn.commit()
gen = releases_app.get_generation(conn)
dump_content = releases_app.dump_text(conn, gen)
open('$R/releases.sql', 'w').write(dump_content)
conn.close()
"
}

# 1. Initialize repo and verify clean check
ra init >/dev/null 2>&1 || { echo "init failed" >&2; exit 1; }

out="$(ra check 2>&1)"; rc=$?
[ $rc -eq 0 ]; ok "clean repo passes releases check (rc=0)" $?

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
[ $rc -eq 1 ]; ok "un-reanchored chain break fails check (rc=1)" $?
has "$out" "likely caused by git branch switching or rebasing"
ok "error message states git branch switching / rebasing as likely cause" $?

! has "$out" "spliced or forged"
ok "error message does NOT claim 'spliced or forged audit trail'" $?

has "$out" "run \`releases check --rebuild\` to re-anchor"
ok "error message gives remediation command 'releases check --rebuild'" $?

# 3. Run releases check --rebuild to re-anchor the break
out_rebuild="$(ra check --rebuild 2>&1)"; rc_rebuild=$?
[ $rc_rebuild -eq 0 ]; ok "releases check --rebuild succeeds (rc=0)" $?

# Verify the merge-rebuild receipt has target_gid = 'reanchor:2'
last_target_gid="$(sqlite3 "$R/releases.db" "SELECT target_gid FROM op_receipts WHERE op='merge-rebuild' ORDER BY id DESC LIMIT 1")"
is "$last_target_gid" "reanchor:2"; ok "merge-rebuild receipt recorded reanchor:2 in target_gid ($last_target_gid)" $?

out="$(ra check 2>&1)"; rc=$?
[ $rc -eq 0 ]; ok "after rebuild, releases check passes with tolerated break note (rc=0)" $?
has "$out" "2 merge fork(s) tolerated under the merge-rebuild receipt"
ok "check output announces 2 merge forks tolerated" $?

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
[ $rc -eq 1 ]; ok "subsequent break after previous rebuild fails check (rc=1)" $?
has "$out" "1 new receipt(s) break the chain (3 total break(s), 2 re-anchored)"
ok "error message distinguishes new breaks from previously re-anchored breaks" $?

# 5. Rebuild again to re-anchor the second break
out_rebuild2="$(ra check --rebuild 2>&1)"; rc_rebuild2=$?
[ $rc_rebuild2 -eq 0 ]; ok "second releases check --rebuild succeeds (rc=0)" $?

last_target_gid2="$(sqlite3 "$R/releases.db" "SELECT target_gid FROM op_receipts WHERE op='merge-rebuild' ORDER BY id DESC LIMIT 1")"
is "$last_target_gid2" "reanchor:4"; ok "second merge-rebuild receipt recorded reanchor:4 in target_gid ($last_target_gid2)" $?

out="$(ra check 2>&1)"; rc=$?
[ $rc -eq 0 ]; ok "after second rebuild, releases check passes (rc=0)" $?
has "$out" "4 merge fork(s) tolerated under the merge-rebuild receipt"
ok "check output announces 4 merge forks tolerated" $?

# 6. Legacy merge-rebuild receipt compatibility (target_gid IS NULL)
set_rebuild_target_gid "NULL"
out="$(ra check 2>&1)"; rc=$?
[ $rc -eq 0 ]; ok "legacy NULL target_gid merge-rebuild receipts pass when no new breaks exist (rc=0)" $?
! has "$out" "rule=dump-divergence"
ok "legacy check has no dump-divergence failure" $?

# 7. Malformed non-NULL rebuild scope rejection
# Set a malformed target_gid 'reanchor:bogus'
set_rebuild_target_gid "reanchor:bogus"
out="$(ra check 2>&1)"; rc=$?
[ $rc -eq 1 ]; ok "malformed non-NULL target_gid fails check (rc=1)" $?
has "$out" "FAIL: rule=malformed-reanchor-receipt"
ok "error output reports malformed-reanchor-receipt rule" $?
! has "$out" "rule=dump-divergence"
ok "malformed check has no dump-divergence failure" $?

# Non-canonical breaks:999 is rejected
set_rebuild_target_gid "breaks:999"
out="$(ra check 2>&1)"; rc=$?
[ $rc -eq 1 ]; ok "non-canonical breaks:999 fails check (rc=1)" $?
has "$out" "FAIL: rule=malformed-reanchor-receipt"
ok "error output reports malformed-reanchor-receipt on breaks:999" $?

# Non-canonical embedded string 'prefix reanchor:999 suffix' is rejected
set_rebuild_target_gid "prefix reanchor:999 suffix"
out="$(ra check 2>&1)"; rc=$?
[ $rc -eq 1 ]; ok "non-canonical embedded string fails check (rc=1)" $?
has "$out" "FAIL: rule=malformed-reanchor-receipt"
ok "error output reports malformed-reanchor-receipt on embedded string" $?

# 8. Break occurring AFTER legacy NULL target_gid receipt is caught without dump-divergence
set_rebuild_target_gid "NULL"
d_cur="$(sqlite3 "$R/releases.db" "SELECT state_digest_after FROM op_receipts ORDER BY id DESC LIMIT 1")"
python3 -c "
import sys, sqlite3
sys.path.insert(0, '$ROOT_DIR/utils/py')
import releases_app
conn = sqlite3.connect('$R/releases.db')
conn.row_factory = sqlite3.Row
conn.execute('DROP TRIGGER IF EXISTS op_no_update')
conn.execute(\"\"\"INSERT INTO op_receipts(op, target_gid, at, txn_id, session_id,
                                          state_digest_before, state_digest_after)
                 VALUES ('roadmap-add', 'rmi-test-after-legacy', '2026-08-31T23:59:59Z',
                         'txn-after-legacy', 'default', 'deadbeef00000000000000000000000000000000000000000000000000000099',
                         '$d_cur')\"\"\")
conn.execute(\"\"\"CREATE TRIGGER op_no_update BEFORE UPDATE ON op_receipts
                 BEGIN SELECT RAISE(ABORT, 'op_receipts is append-only'); END;\"\"\")
conn.commit()
gen = releases_app.get_generation(conn)
dump_content = releases_app.dump_text(conn, gen)
open('$R/releases.sql', 'w').write(dump_content)
conn.close()
"

out="$(ra check 2>&1)"; rc=$?
[ $rc -eq 1 ]; ok "break occurring after legacy NULL target_gid receipt fails check (rc=1)" $?
has "$out" "1 new receipt(s) break the chain"
ok "error output announces new break after legacy receipt" $?
! has "$out" "rule=dump-divergence"
ok "post-legacy check isolates receipt-chain failure without dump-divergence" $?

echo "gh360: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
