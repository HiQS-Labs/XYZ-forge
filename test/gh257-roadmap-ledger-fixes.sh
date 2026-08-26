#!/usr/bin/env bash
# test/gh257-roadmap-ledger-fixes.sh — regression suite for GH-257:
# 1. validate --raw-text on roadmap add and update against renderer bold bullet shape
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
  "- **** empty title GH-255"
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
# Case 4: roadmap update with malformed --raw-text is REFUSED
# -----------------------------------------------------------------------------
for bad_input in \
  "- [ ] #255 bad update" \
  "-   **GH-255 · extra spaces**" \
  "- **GH-255 unclosed title"
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
# Case 5: roadmap update --dry-run prints changes and mutates nothing
# -----------------------------------------------------------------------------
out="$(app --root "$R" roadmap update --issue-num 255 \
  --raw-text "- **GH-255 · dry run title** 🆕 — [doc](PROJECT/1-INBOX/GH-255-test.md) · [#255](https://github.com/org/repo/issues/255)" \
  --dry-run)"
case "$out" in
  *"raw_text: "*"- **GH-255 · dry run title**"*) pass "roadmap update --dry-run reported planned diff" ;;
  *) fail "expected dry-run diff output, got: $out" ;;
esac

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
# Case 8: roadmap update synchronizes rating columns (unrated -> rated -> unrated)
# -----------------------------------------------------------------------------
# Unrated -> Rated
RATED_TEXT="- **GH-255 · rated title** 🆕 (rated 80/70/90/60 ovr 320) — [#255](https://github.com/org/repo/issues/255)"
app --root "$R" roadmap update --issue-num 255 --raw-text "$RATED_TEXT"
pri="$(sqlite3 "$R/releases.db" "SELECT rating_pri FROM roadmap_items WHERE gh_number = 255")"
ovr="$(sqlite3 "$R/releases.db" "SELECT rating_ovr FROM roadmap_items WHERE gh_number = 255")"
[ "$pri" = "80" ] || fail "expected rating_pri=80, got '$pri'"
[ "$ovr" = "320" ] || fail "expected rating_ovr=320, got '$ovr'"
pass "roadmap update correctly populated rating columns"

# Rated -> Unrated (must reset rating columns to NULL, not leave old scores)
UNRATED_TEXT="- **GH-255 · unrated again** 🆕 — [#255](https://github.com/org/repo/issues/255)"
app --root "$R" roadmap update --issue-num 255 --raw-text "$UNRATED_TEXT"
pri_cleared="$(sqlite3 "$R/releases.db" "SELECT rating_pri FROM roadmap_items WHERE gh_number = 255")"
[ -z "$pri_cleared" ] || fail "expected rating_pri to be cleared/NULL, got '$pri_cleared'"
pass "roadmap update correctly cleared rating columns to NULL on unrated line"

# -----------------------------------------------------------------------------
# Case 9: renderer (utils/roadmap-dashboard.sh) emits stderr warning on dropped rows
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
# Case 10: staleness guard outputs diagnostic guidance when regeneration produces no diff
# -----------------------------------------------------------------------------
# Base commit with clean dashboard and ledger
cd "$R"
bash "$R/utils/roadmap-dashboard.sh"
git add .pdda-mode releases.db releases.sql ROADMAP-DASHBOARD.md utils/ PROJECT/
git -c user.email=t@t -c user.name=t commit -q -m "v1 clean"
BASE_COMMIT="$(git rev-parse HEAD)"

# Simulate a commit where ledger is touched but dashboard did not drift (e.g. dropped row)
touch releases.sql
echo "-- simulated extra comment" >> releases.sql
git add releases.sql
git -c user.email=t@t -c user.name=t commit -q -m "ledger touched without dashboard drift"
TOUCHED_COMMIT="$(git rev-parse HEAD)"
cd "$root"

rc=0
guard_out="$(bash "$GUARD" "$R" "$TOUCHED_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
[ "$rc" -eq 1 ] || fail "guard should refuse push when ledger is touched without dashboard, got $rc"
case "$guard_out" in
  *"produces NO diff (GH-243 / GH-257)"*"releases roadmap update"*)
    pass "staleness guard provided dropped-row diagnostic explanation when dashboard had no diff"
    ;;
  *) fail "expected no-diff diagnostic explanation in guard output, got: $guard_out" ;;
esac

# -----------------------------------------------------------------------------
# Case 11: staleness guard outputs standard fix when drift IS detected
# -----------------------------------------------------------------------------
cd "$R"
# Add a new row to ledger that will cause dashboard drift
app --root "$R" roadmap add --issue-num 256 --issue-url "https://github.com/org/repo/issues/256" \
  --title "test 256" --created "2026-08-26" --doc-path "PROJECT/1-INBOX/GH-255-test.md" \
  --raw-text "- **GH-256 · new drift row** 🆕 — [#256](https://github.com/org/repo/issues/256)"
git add releases.db releases.sql
git -c user.email=t@t -c user.name=t commit -q -m "ledger changed with real dashboard drift"
DRIFT_COMMIT="$(git rev-parse HEAD)"
cd "$root"

rc=0
guard_drift_out="$(bash "$GUARD" "$R" "$DRIFT_COMMIT" "$BASE_COMMIT" 2>&1)" || rc=$?
[ "$rc" -eq 1 ] || fail "guard should refuse drifted range, got $rc"
case "$guard_drift_out" in
  *"Fix (one command, then commit the result into the same push):"*)
    pass "staleness guard provided standard fix when drift was present"
    ;;
  *) fail "expected standard fix text, got: $guard_drift_out" ;;
esac

echo "== GH-257 ALL PASSED =="
