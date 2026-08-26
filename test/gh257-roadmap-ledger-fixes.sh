#!/usr/bin/env bash
# test/gh257-roadmap-ledger-fixes.sh — regression suite for GH-257:
# 1. validate --raw-text on roadmap add and update against renderer bold bullet shape (single line)
# 2. emit warning on dropped unparseable rows in roadmap-dashboard.sh
# 3. roadmap update subcommand for parked raw_text with auditable receipt and rating sync
# 4. staleness guard diagnostic guidance when regeneration yields no diff
set -euo pipefail
source test/_setup.sh "GH-257" || { echo "setup failed"; exit 1; }

root="$(cd "$HERE/.." && pwd)"
app() { python3 "$root/utils/py/releases_app.py" "$@"; }
RENDERER="$root/utils/roadmap-dashboard.sh"
GUARD="$root/githooks/dashboard-staleness-guard.sh"

R="$WORK/repo"
mkdir -p "$R/utils/py"
cp -r "$root/utils/"* "$R/utils/"
cd "$R"
git init -q .
git -c user.email=t@t -c user.name=t commit -q --allow-empty -m base
echo "ROADMAP_SOURCE=releases" > .pdda-mode
mkdir -p PROJECT/1-INBOX
touch PROJECT/1-INBOX/GH-255-test.md

app --root "$R" init --slug "test-repo"

# -----------------------------------------------------------------------------
# Case 1: roadmap add with malformed --raw-text is REFUSED at step 1
# -----------------------------------------------------------------------------
for bad_input in \
  "- [ ] #255 malformed checkbox" \
  "-   **GH-255 · repeated spaces** 🆕" \
  "-	**GH-255 · tab after dash** 🆕" \
  "- **GH-255 unclosed bold" \
  "- **** empty title GH-255" \
  $'- **GH-255 · title**\n- [ ] #999 smuggled row' \
  $'- **GH-255 · title**\r\nmalformed continuation'
do
  rc=0
  out="$(app --root "$R" roadmap add --issue-num 255 --issue-url "https://github.com/org/repo/issues/255" \
    --title "test 255" --created "2026-08-26" --doc-path "PROJECT/1-INBOX/GH-255-test.md" \
    --raw-text "$bad_input" 2>&1)" || rc=$?

  [ "$rc" -ne 0 ] || fail "malformed raw_text '$bad_input' should be refused on add, got rc=0"
  case "$out" in
    *"rule=invalid-raw-text"*) pass "roadmap add refused malformed raw_text: '$bad_input'" ;;
    *) fail "expected invalid-raw-text rule for '$bad_input', got: $out" ;;
  esac
done

# -----------------------------------------------------------------------------
# Case 2: roadmap add with mismatched issue number in --raw-text is REFUSED
# -----------------------------------------------------------------------------
rc=0
out="$(app --root "$R" roadmap add --issue-num 255 --issue-url "https://github.com/org/repo/issues/255" \
  --title "test 255" --created "2026-08-26" --doc-path "PROJECT/1-INBOX/GH-255-test.md" \
  --raw-text "- **GH-999 · wrong issue** 🆕" 2>&1)" || rc=$?

[ "$rc" -ne 0 ] || fail "mismatched issue number in raw_text should be refused, got rc=0"
case "$out" in
  *"rule=invalid-raw-text"*"GH-255"*) pass "roadmap add refused mismatched issue number" ;;
  *) fail "expected issue number mismatch refusal, got: $out" ;;
esac

# -----------------------------------------------------------------------------
# Case 3: roadmap add with valid --raw-text SUCCEEDS
# -----------------------------------------------------------------------------
app --root "$R" roadmap add --issue-num 255 --issue-url "https://github.com/org/repo/issues/255" \
  --title "test 255" --created "2026-08-26" --doc-path "PROJECT/1-INBOX/GH-255-test.md" \
  --raw-text "- **GH-255 · valid initial title** 🆕 — [doc](PROJECT/1-INBOX/GH-255-test.md) · [#255](https://github.com/org/repo/issues/255)"
pass "roadmap add succeeded with valid raw_text"

# -----------------------------------------------------------------------------
# Case 4: roadmap update with symmetric negative controls is REFUSED
# -----------------------------------------------------------------------------
for bad_input in \
  "- [ ] #255 bad update" \
  "-   **GH-255 · extra spaces**" \
  "-	**GH-255 · tab after dash**" \
  "- **GH-255 unclosed title" \
  "- **** empty title GH-255" \
  $'- **GH-255 · title**\n- [ ] #999 bad line' \
  $'- **GH-255 · title**\r\ncontinuation'
do
  rc=0
  out="$(app --root "$R" roadmap update --issue-num 255 --raw-text "$bad_input" 2>&1)" || rc=$?
  [ "$rc" -ne 0 ] || fail "malformed raw_text '$bad_input' on update should be refused, got rc=0"
  case "$out" in
    *"rule=invalid-raw-text"*) pass "roadmap update refused malformed raw_text: '$bad_input'" ;;
    *) fail "expected invalid-raw-text on roadmap update for '$bad_input', got: $out" ;;
  esac
done

# -----------------------------------------------------------------------------
# Case 5: roadmap update --dry-run prints changes and PROVABLY mutates nothing
# -----------------------------------------------------------------------------
raw_before="$(sqlite3 "$R/releases.db" "SELECT raw_text FROM roadmap_items WHERE gh_number = 255")"
out="$(app --root "$R" roadmap update --issue-num 255 \
  --raw-text "- **GH-255 · dry run title** 🆕 — [doc](PROJECT/1-INBOX/GH-255-test.md) · [#255](https://github.com/org/repo/issues/255)" \
  --dry-run)"
case "$out" in
  *"raw_text: "*"- **GH-255 · dry run title**"*) pass "roadmap update --dry-run reported planned diff" ;;
  *) fail "expected dry-run diff output, got: $out" ;;
esac
raw_after="$(sqlite3 "$R/releases.db" "SELECT raw_text FROM roadmap_items WHERE gh_number = 255")"
[ "$raw_before" = "$raw_after" ] || fail "dry-run must not mutate database"
pass "dry-run verified non-mutating against database"

# -----------------------------------------------------------------------------
# Case 6: roadmap update SUCCEEDS and generates roadmap-update receipt
# -----------------------------------------------------------------------------
NEW_TEXT="- **GH-255 · updated title** 🆕 — [doc](PROJECT/1-INBOX/GH-255-test.md) · [#255](https://github.com/org/repo/issues/255)"
app --root "$R" roadmap update --issue-num 255 --raw-text "$NEW_TEXT"
pass "roadmap update succeeded for GH-255"

list_out="$(app --root "$R" roadmap list --json)"
case "$list_out" in
  *"- **GH-255 · updated title**"*) pass "roadmap list reflects updated raw_text" ;;
  *) fail "roadmap list did not show updated raw_text: $list_out" ;;
esac

grep -q "roadmap-update" "$R/releases.sql" || fail "releases.sql missing roadmap-update receipt event"
pass "releases.sql carries roadmap-update receipt"

# -----------------------------------------------------------------------------
# Case 7: roadmap update is IDEMPOTENT (no-op on unchanged text)
# -----------------------------------------------------------------------------
receipt_count_before="$(grep -c "roadmap-update" "$R/releases.sql" || true)"
out="$(app --root "$R" roadmap update --issue-num 255 --raw-text "$NEW_TEXT")"
case "$out" in
  *"unchanged; nothing written"*) pass "roadmap update idempotent when text unchanged" ;;
  *) fail "expected unchanged text report, got: $out" ;;
esac
receipt_count_after="$(grep -c "roadmap-update" "$R/releases.sql" || true)"
[ "$receipt_count_before" -eq "$receipt_count_after" ] || fail "idempotent update must not write extra receipts"
pass "idempotent update wrote zero additional receipts"

# -----------------------------------------------------------------------------
# Case 8: roadmap update synchronizes ALL FIVE rating columns
# -----------------------------------------------------------------------------
# Unrated -> Rated
RATED_TEXT="- **GH-255 · rated title** 🆕 (rated 80/70/90/60 ovr 320) — [#255](https://github.com/org/repo/issues/255)"
app --root "$R" roadmap update --issue-num 255 --raw-text "$RATED_TEXT"
read pri sev app_score eff ovr <<<"$(sqlite3 "$R/releases.db" "SELECT rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr FROM roadmap_items WHERE gh_number = 255" | tr '|' ' ')"
[ "$pri" = "80" ] && [ "$sev" = "70" ] && [ "$app_score" = "90" ] && [ "$eff" = "60" ] && [ "$ovr" = "320" ] \
  || fail "expected rating columns (80 70 90 60 320), got ($pri $sev $app_score $eff $ovr)"
pass "roadmap update correctly populated all 5 rating columns"

# Rated -> Unrated (must reset all 5 rating columns to NULL, not leave old scores)
UNRATED_TEXT="- **GH-255 · unrated again** 🆕 — [#255](https://github.com/org/repo/issues/255)"
app --root "$R" roadmap update --issue-num 255 --raw-text "$UNRATED_TEXT"
cleared_counts="$(sqlite3 "$R/releases.db" "SELECT COUNT(*) FROM roadmap_items WHERE gh_number = 255 AND (rating_pri IS NOT NULL OR rating_sev IS NOT NULL OR rating_appeal IS NOT NULL OR rating_effort IS NOT NULL OR rating_ovr IS NOT NULL)")"
[ "$cleared_counts" = "0" ] || fail "expected all rating columns to be NULL, found non-null values"
pass "roadmap update correctly cleared all 5 rating columns to NULL on unrated line"

# -----------------------------------------------------------------------------
# Case 9: schema-behind refusal on pre-migration ledger without rating columns
# -----------------------------------------------------------------------------
R_OLD="$WORK/pre_migration_repo"
mkdir -p "$R_OLD/utils/py"
cp -r "$root/utils/"* "$R_OLD/utils/"
cd "$R_OLD"
git init -q .
echo "ROADMAP_SOURCE=releases" > .pdda-mode
mkdir -p PROJECT/1-INBOX
touch PROJECT/1-INBOX/GH-100-test.md
app --root "$R_OLD" init --slug "old-repo"
app --root "$R_OLD" roadmap add --issue-num 100 --issue-url "https://github.com/org/repo/issues/100" \
  --title "old 100" --created "2026-08-26" --doc-path "PROJECT/1-INBOX/GH-100-test.md" \
  --raw-text "- **GH-100 · old initial** 🆕 — [#100](https://github.com/org/repo/issues/100)"

# Simulate pre-migration schema by dropping rating columns
sqlite3 "$R_OLD/releases.db" <<'EOSQL'
CREATE TABLE roadmap_items_old AS SELECT id, global_id, repo_id, gh_number, title, section, position, status_marker, complexity, risk, effort, doc_path, issue_url, raw_text, first_seen, updated_at FROM roadmap_items;
DROP TABLE roadmap_items;
ALTER TABLE roadmap_items_old RENAME TO roadmap_items;
EOSQL

rc=0
out="$(app --root "$R_OLD" roadmap update --issue-num 100 \
  --raw-text "- **GH-100 · rated line on old ledger** 🆕 (rated 80/70/90/60) — [#100](https://github.com/org/repo/issues/100)" 2>&1)" || rc=$?
[ "$rc" -ne 0 ] || fail "rated update against pre-migration ledger should be refused, got rc=0"
case "$out" in
  *"rule=schema-behind"*) pass "roadmap update refused rated line on pre-migration ledger with schema-behind" ;;
  *) fail "expected schema-behind refusal, got: $out" ;;
esac

# -----------------------------------------------------------------------------
# Case 10: renderer (utils/roadmap-dashboard.sh) emits stderr warning on dropped rows
# -----------------------------------------------------------------------------
MOCK_SRC="$WORK/mock_roadmap.md"
cat > "$MOCK_SRC" <<'EOFMOCK'
# ROADMAP
## Ledger
### Queue / parked intake
- **GH-1 · valid row** 🟢 — [doc](doc.md)
- [ ] #999 malformed row
- #1000 another dropped bullet
- **GH-1001 unclosed bold
EOFMOCK

MOCK_OUT="$WORK/mock_dashboard.md"
err_out="$(ROADMAP_DASHBOARD_SOURCE="$MOCK_SRC" ROADMAP_DASHBOARD_OUTPUT="$MOCK_OUT" bash "$RENDERER" 2>&1 >/dev/null)" || true
case "$err_out" in
  *"roadmap-dashboard: warning: dropped 3 unparseable row(s): #999, #1000, #1001"*)
    pass "renderer warned on dropped unparseable rows (including unclosed bold) on stderr"
    ;;
  *) fail "expected warning naming dropped rows #999, #1000, #1001, got: $err_out" ;;
esac

# -----------------------------------------------------------------------------
# Case 11: End-to-end historical reproduction of malformed row diagnosis & fix
# -----------------------------------------------------------------------------
cd "$R"
bash "$R/utils/roadmap-dashboard.sh"
git add .pdda-mode releases.db releases.sql ROADMAP-DASHBOARD.md utils/ PROJECT/
git -c user.email=t@t -c user.name=t commit -q -m "v1 clean base"
BASE_COMMIT="$(git rev-parse HEAD)"

# Simulate the historical bug: a malformed row (- [ ] #256 ...) is directly injected into ledger
sqlite3 "$R/releases.db" <<'EOSQL'
INSERT INTO roadmap_items (global_id, repo_id, gh_number, title, section, position, status_marker, doc_path, issue_url, raw_text, first_seen, updated_at)
VALUES ('rmi-01M0ZVV0000000000000000256', 1, 256, 'bad 256', 'Queue / parked intake', 99, '🆕', 'PROJECT/1-INBOX/GH-255-test.md', 'https://github.com/org/repo/issues/256', '- [ ] #256 historical malformed row', datetime('now'), datetime('now'));
EOSQL
python3 -c "import sys; sys.path.insert(0, '$root/utils/py'); import releases_app as rel; root = rel.resolve_root('$R'); conn = rel.connect(rel.artifact_paths(root)['db']); gen = rel.get_generation(conn); open(rel.artifact_paths(root)['dump'], 'w').write(rel.dump_text(conn, gen)); conn.close()"

# 1. Regenerating dashboard yields warnings and dropped row:
dash_warn="$(bash "$R/utils/roadmap-dashboard.sh" 2>&1 >/dev/null)" || true
case "$dash_warn" in
  *"warning: dropped 1 unparseable row(s): #256"*) pass "end-to-end: renderer detected injected malformed row #256" ;;
  *) fail "expected dropped row warning for #256, got: $dash_warn" ;;
esac

# 2. Commit the ledger change only (dashboard unchanged because row was dropped)
git add releases.db releases.sql
git -c user.email=t@t -c user.name=t commit -q -m "ledger has bad row #256, dashboard unchanged"
BAD_COMMIT="$(git rev-parse HEAD)"
cd "$root"

# 3. Staleness guard catches it and outputs no-diff diagnosis:
# Add uncommitted modification in working tree to PROVE guard is isolated to commit projection
echo "dirty working tree modification" >> "$R/ROADMAP-DASHBOARD.md"

GUARD_TMP="$WORK/guard_isolated_tmp"
mkdir -p "$GUARD_TMP"

rc=0
guard_out="$(TMPDIR="$GUARD_TMP" bash "$GUARD" "$R" "$BAD_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
[ "$rc" -eq 1 ] || fail "guard should refuse bad commit, got $rc"
case "$guard_out" in
  *"produces NO diff (GH-243 / GH-257)"*"releases roadmap update"*)
    pass "end-to-end: staleness guard accurately diagnosed no-diff dropped row (even with dirty working tree)"
    ;;
  *) fail "expected no-diff diagnostic output from guard, got: $guard_out" ;;
esac
[ "$(find "$GUARD_TMP" -maxdepth 1 -name "staleness-guard.*" | wc -l)" -eq 0 ] || fail "expected no leftover guard roots in GUARD_TMP after no-diff refusal"
pass "guard cleaned up temporary root after no-diff refusal"

# Restore working tree
git -C "$R" checkout ROADMAP-DASHBOARD.md

# 4. Multi-ref push test with BAD_COMMIT FIRST and clean BASE_COMMIT LAST
# Proves per-ref evaluation does not merely inspect the last ref in the list
rc=0
guard_multi_out="$(TMPDIR="$GUARD_TMP" bash "$GUARD" "$R" "$BAD_COMMIT" "$BASE_COMMIT" "$BASE_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
[ "$rc" -eq 1 ] || fail "guard should refuse multi-ref push with bad commit first, got $rc"
case "$guard_multi_out" in
  *"produces NO diff (GH-243 / GH-257)"*)
    pass "end-to-end: multi-ref push correctly evaluates bad ref first and clean ref last"
    ;;
  *) fail "expected no-diff refusal in multi-ref push, got: $guard_multi_out" ;;
esac
[ "$(find "$GUARD_TMP" -maxdepth 1 -name "staleness-guard.*" | wc -l)" -eq 0 ] || fail "expected no leftover guard roots in GUARD_TMP after multi-ref refusal"
pass "guard cleaned up temporary root after multi-ref refusal"

# Cross-ref test: Ref 1 touches ledger only (BAD_COMMIT), Ref 2 touches dashboard only
cd "$R"
git checkout -q -b branch-dash-only "$BASE_COMMIT"
echo "# modified dashboard" >> ROADMAP-DASHBOARD.md
git add ROADMAP-DASHBOARD.md
git -c user.email=t@t -c user.name=t commit -q -m "dashboard only commit"
DASH_ONLY_COMMIT="$(git rev-parse HEAD)"
git checkout -q -
cd "$root"

rc=0
guard_cross_out="$(TMPDIR="$GUARD_TMP" bash "$GUARD" "$R" "$BAD_COMMIT" "$BASE_COMMIT" "$DASH_ONLY_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
[ "$rc" -eq 1 ] || fail "cross-ref push should refuse bad ledger ref despite separate dashboard ref, got $rc"
case "$guard_cross_out" in
  *"produces NO diff (GH-243 / GH-257)"*)
    pass "end-to-end: cross-ref push enforces per-ref consistency and refuses stale ledger ref"
    ;;
  *) fail "expected refusal on cross-ref push, got: $guard_cross_out" ;;
esac
[ "$(find "$GUARD_TMP" -maxdepth 1 -name "staleness-guard.*" | wc -l)" -eq 0 ] || fail "expected no leftover guard roots in GUARD_TMP after cross-ref refusal"
pass "guard cleaned up temporary root after cross-ref refusal"

# 5. Projection failure test:
# Create a commit where ledger is touched, but utils/roadmap-dashboard.sh is missing from that commit.
# The projection fails to run the script and must fail closed (drift_detected=1), refusing the push
# and cleaning up temporary directory without consulting working tree.
cd "$R"
git checkout -q -b branch-proj-fail "$BAD_COMMIT"
git rm -q utils/roadmap-dashboard.sh
git -c user.email=t@t -c user.name=t commit -q -m "commit without renderer script"
PROJ_FAIL_COMMIT="$(git rev-parse HEAD)"
git checkout -q -
cd "$root"

rc=0
guard_fail_out="$(TMPDIR="$GUARD_TMP" bash "$GUARD" "$R" "$PROJ_FAIL_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
[ "$rc" -eq 1 ] || fail "guard should refuse when commit projection fails renderer lookup, got $rc"
case "$guard_fail_out" in
  *"without regenerating ROADMAP-DASHBOARD.md"*)
    pass "end-to-end: projection failure fails closed as drift and refuses without working tree fallback"
    ;;
  *) fail "expected drift refusal on projection failure, got: $guard_fail_out" ;;
esac
[ "$(find "$GUARD_TMP" -maxdepth 1 -name "staleness-guard.*" | wc -l)" -eq 0 ] || fail "expected no leftover guard roots in GUARD_TMP after projection failure refusal"
pass "guard cleaned up temporary root after projection failure refusal"

# 6. Hostile root pivot/rename test:
# Create a commit where roadmap-dashboard.sh tries to replace the guard root with a symlink to VICTIM_DIR
VICTIM_DIR="$WORK/victim_dir"
mkdir -p "$VICTIM_DIR"
touch "$VICTIM_DIR/important_file"

cd "$R"
git checkout -q -b branch-hostile-pivot "$BAD_COMMIT"
cat > utils/roadmap-dashboard.sh <<'EOFPIVOT'
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD_ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
rm -rf "$GUARD_ROOT_DIR" 2>/dev/null || true
ln -s "$VICTIM_DIR" "$GUARD_ROOT_DIR" 2>/dev/null || true
exit 0
EOFPIVOT
chmod +x utils/roadmap-dashboard.sh
git add utils/roadmap-dashboard.sh
git -c user.email=t@t -c user.name=t commit -q -m "commit with hostile pivot script"
PIVOT_COMMIT="$(git rev-parse HEAD)"
git checkout -q "$BASE_COMMIT"
cd "$root"

rc=0
guard_pivot_out="$(TMPDIR="$GUARD_TMP" VICTIM_DIR="$VICTIM_DIR" bash "$GUARD" "$R" "$PIVOT_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
[ "$rc" -eq 1 ] || fail "guard should refuse on pivot attempt, got $rc"
[ -f "$VICTIM_DIR/important_file" ] || fail "hostile pivot must not delete victim files"
pass "end-to-end: hostile root symlink pivot safely refused and protected external directories"

# Clean up hostile test artifacts in GUARD_TMP
rm -rf "$GUARD_TMP"/staleness-guard.* 2>/dev/null || true

# 7. Remediation: use roadmap update to fix raw_text
cd "$R"
git checkout -q "$BAD_COMMIT"
app --root "$R" roadmap update --issue-num 256 --raw-text "- **GH-256 · fixed title** 🆕 — [#256](https://github.com/org/repo/issues/256)"
bash "$R/utils/roadmap-dashboard.sh"
grep -q "GH-256 · fixed title" "$R/ROADMAP-DASHBOARD.md" || fail "remediated row not in dashboard"
pass "end-to-end: roadmap update remediated row and dashboard now includes it"

git add releases.db releases.sql ROADMAP-DASHBOARD.md
git -c user.email=t@t -c user.name=t commit -q -m "remediated row #256 and regenerated dashboard"
REMEDIATED_COMMIT="$(git rev-parse HEAD)"
cd "$root"

# 8. Staleness guard now passes cleanly and leaves no temporary files:
TMPDIR="$GUARD_TMP" bash "$GUARD" "$R" "$REMEDIATED_COMMIT" "$BASE_COMMIT"
[ "$(find "$GUARD_TMP" -maxdepth 1 -name "staleness-guard.*" | wc -l)" -eq 0 ] || fail "expected no leftover guard roots in GUARD_TMP after clean pass"
pass "end-to-end: staleness guard passes after roadmap update and leaves 0 temporary artifacts"

echo "== GH-257 ALL PASSED =="
