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

## -----------------------------------------------------------------------------
# Case 10: roadmap render emits stderr warning on dropped unparseable rows (rehomed under GH-567)
# -----------------------------------------------------------------------------
# Red control (negative): verify no dropped-row warning when ledger is well-formed
clean_err="$(app --root "$R" roadmap render 2>&1 >/dev/null)" || true
case "$clean_err" in
  *"warning: dropped"*) fail "well-formed ledger unexpectedly warned on dropped rows: $clean_err" ;;
  *) pass "red control (negative): well-formed ledger emits no dropped-row warning" ;;
esac

# Inject malformed rows directly into database (bypassing write-time validation) to test render-time protection
REPO_ID="$(sqlite3 "$R/releases.db" "SELECT id FROM repos LIMIT 1;")"
sqlite3 "$R/releases.db" <<EOSQL
INSERT INTO roadmap_items (global_id, repo_id, gh_number, title, section, position, raw_text, first_seen, updated_at)
VALUES ('rmi-01M27JVPAPE8HRJQDY8JSV1999', $REPO_ID, 999, 'bad checkbox', 'Queue / parked intake', 90, '- [ ] #999 malformed row', '2026-09-10T00:00:00Z', '2026-09-10T00:00:00Z');
INSERT INTO roadmap_items (global_id, repo_id, gh_number, title, section, position, raw_text, first_seen, updated_at)
VALUES ('rmi-01M27JVPAPE8HRJQDY8JSV2000', $REPO_ID, 1000, 'dropped bullet', 'Queue / parked intake', 91, '- #1000 another dropped bullet', '2026-09-10T00:00:00Z', '2026-09-10T00:00:00Z');
INSERT INTO roadmap_items (global_id, repo_id, gh_number, title, section, position, raw_text, first_seen, updated_at)
VALUES ('rmi-01M27JVPAPE8HRJQDY8JSV2001', $REPO_ID, 1001, 'unclosed bold', 'Queue / parked intake', 92, '- **GH-1001 unclosed bold', '2026-09-10T00:00:00Z', '2026-09-10T00:00:00Z');
EOSQL

render_out="$WORK/rendered_ledger.md"
render_err="$(app --root "$R" roadmap render 2>&1 > "$render_out")" || true

case "$render_err" in
  *"warning: dropped 3 unparseable row(s): #999, #1000, #1001"*)
    pass "roadmap render warned on dropped unparseable rows on stderr"
    ;;
  *) fail "expected warning naming dropped rows #999, #1000, #1001 on stderr, got: $render_err" ;;
esac

# Red control (falsification): verify the malformed rows are genuinely omitted from rendered markdown output
if grep -q "malformed row" "$render_out" || grep -q "unclosed bold" "$render_out"; then
  fail "unparseable rows should be dropped from rendered output"
else
  pass "red control (positive): unparseable rows are omitted from rendered markdown output"
fi

# Clean up injected rows
sqlite3 "$R/releases.db" "DELETE FROM roadmap_items WHERE gh_number IN (999, 1000, 1001);"

## -----------------------------------------------------------------------------
# Cases 11-12 (roadmap-dashboard and staleness guard):
# Retired under GH-567 alongside ROADMAP-DASHBOARD.md, utils/roadmap-dashboard.sh,
# and githooks/dashboard-staleness-guard.sh.
# -----------------------------------------------------------------------------

echo "== GH-257 ALL PASSED =="
