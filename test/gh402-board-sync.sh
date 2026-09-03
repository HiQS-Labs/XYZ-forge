#!/usr/bin/env bash
# gh402-board-sync.sh — GH-402 Phase 1: board_sync.py extraction, strength classification,
# empty-input refusal, kill-switch, settings env tier, and a witnessed-red mutation leg.
#
# OFFLINE BY DESIGN: this suite exercises the offline half (scan/config/kill-switch/reconcile-
# refusal). The live write path (add → set status → delete round-trip on the real board) is NOT
# suite-pinned — it was proven once by the Phase 0 spike (2026-09-02, receipts in
# PROJECT/2-WORKING/GH-402-BOARD-SYNC.md) and needs a token + network by definition.
#
# Witnessed-red discipline (plan v5, N2): the mutation leg breaks the PDDA extractor in a
# COPY of the module and asserts the fixture issue disappears from scan output — proving
# the positive assertions above it are load-bearing, not decorative. An extractor that
# silently matched nothing would turn this suite red, not green.
#
# GH-1 adoption: require_fixture comes from the SHARED test/lib/fixture-guard.sh — sourced,
# never re-implemented (the adoption ledger verifies this by derivation).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL="$ROOT/utils/py/board_sync.py"

. "$ROOT/test/lib/fixture-guard.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  ok  - $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL- $1"; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh402-board-sync.XXXXXX")"
fixture_guard_init "$WORK"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

# ── fixture: a populated fake checkout ─────────────────────────────────────────
FIX="$WORK/fixture"
mkdir -p "$FIX/PROJECT/2-WORKING" "$FIX/.tick/events" "$WORK/clones/SomeRepo-gh125"
touch "$FIX/PROJECT/2-WORKING/GH-123-TEST.md"          # strong: pdda_doc
touch "$FIX/PROJECT/2-WORKING/GH-402-BOARD-SYNC.md"    # strong: pdda_doc (multi-word slug)
git -C "$FIX" init -q
git -C "$FIX" commit -q --allow-empty -m "seed" 2>/dev/null
git -C "$FIX" branch "fix/gh124-lane"                  # strong: branch
git -C "$FIX" branch "marathon/gh-391-emit"            # strong: branch (digits only, no suffix bleed)
git -C "$FIX" branch "feat/GH-132-case"                # strong: uppercase GH- (review r1 F2)
git -C "$FIX" branch "chore/gh133-cleanup"             # strong: non-fix/feat/marathon prefix (review r2 #4)
git -C "$FIX" branch "unrelated"                       # negative: no gh ref
printf '%s\n' '{"schema_version":"0.2.0","type":"task.claimed","task":"RELAY-gh126-lane","agent":"agy"}' \
  > "$FIX/.tick/events/2026-09-02T00-00-00.000Z-agy-claimed-RELAY-gh126-lane.jsonl"   # strong: tick_event
printf '%s\n' '{"schema_version":"0.2.0","type":"task.memory","task":"RELAY-gh130-lane","agent":"agy"}' \
  > "$FIX/.tick/events/2026-09-02T00-00-01.000Z-agy-memory-RELAY-gh130-lane.jsonl"    # negative: memory verb
python3 - "$FIX/releases.db" <<'PY'
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1])
conn.execute("CREATE TABLE roadmap_items (gh_number INTEGER, status_marker TEXT)")
conn.execute("INSERT INTO roadmap_items VALUES (128, '🚧')")   # weak: stale_marker
conn.execute("INSERT INTO roadmap_items VALUES (129, '✅')")   # negative: done marker
conn.execute("CREATE TABLE jog_queue (gh_number INTEGER, status TEXT)")
conn.execute("INSERT INTO jog_queue VALUES (127, 'running')")  # strong: jog_running
conn.execute("INSERT INTO jog_queue VALUES (131, 'completed')")# negative
conn.commit(); conn.close()
PY
require_fixture "$FIX" "fixture checkout"
require_fixture_file "$FIX/releases.db" "fixture releases db"
require_fixture "$WORK/clones/SomeRepo-gh125" "fixture clone dir"
[ -f "$TOOL" ] || { echo "board_sync.py missing at $TOOL" >&2; exit 1; }

export XYZ_BOARD_SYNC_CLONE_DIRS="$WORK/clones"   # env tier steers the clone scan at the fixture

echo "GH-402 board_sync Phase 1:"
SCAN_OUT="$(python3 "$TOOL" scan --root "$FIX" 2>&1)"; SCAN_RC=$?

# ── 1. extraction: every strong source lands ───────────────────────────────────
echo "1. extraction (strong sources)"
for want in \
  "gh-123.*strong.*pdda_doc" \
  "gh-402.*strong.*pdda_doc" \
  "gh-124.*strong.*branch" \
  "gh-391.*strong.*branch" \
  "gh-132.*strong.*branch" \
  "gh-133.*strong.*branch" \
  "gh-126.*strong.*tick_event" \
  "gh-127.*strong.*jog_running"; do
  if grep -Eq "$want" <<<"$SCAN_OUT"; then ok "$want"; else bad "$want (scan rc=$SCAN_RC)"; fi
done

# ── 2. writer precision: weak signals are classified weak, never strong ────────
echo "2. strength classification (S2)"
if grep -Eq "gh-125[[:space:]]+weak[[:space:]]+clone_dir" <<<"$SCAN_OUT"; then
  ok "clone dir is weak (presence is not work)"
else bad "clone dir not classified weak"; fi
if grep -Eq "gh-128[[:space:]]+weak[[:space:]]+stale_marker" <<<"$SCAN_OUT"; then
  ok "stale 🚧 marker is weak"
else bad "stale marker not classified weak"; fi

# ── 3. negatives: what must NOT appear ─────────────────────────────────────────
echo "3. negatives"
grep -q "gh-130" <<<"$SCAN_OUT" && bad "memory-verb event leaked (gh-130)" || ok "non-claim verbs ignored"
grep -q "gh-129" <<<"$SCAN_OUT" && bad "✅ marker leaked as candidate" || ok "done markers ignored"
grep -q "gh-131" <<<"$SCAN_OUT" && bad "completed jog row leaked" || ok "non-running jog rows ignored"
grep -Eq "gh-391[0-9]" <<<"$SCAN_OUT" && bad "branch digits bled into suffix" || ok "branch number extraction bounded"

# ── 4. empty-input refusal: zero candidates fails, populated or void ───────────
# (clone_dirs is root-independent by design — per-device folders — so these legs must
#  also empty that source or the fixture's clone dir leaks into the "empty" world.)
echo "4. empty-input refusal"
EMPTY="$WORK/empty"; mkdir -p "$EMPTY/PROJECT/2-WORKING"
EMPTY_OUT="$(XYZ_BOARD_SYNC_CLONE_DIRS="" python3 "$TOOL" scan --root "$EMPTY" 2>&1)"; EMPTY_RC=$?
if [ "$EMPTY_RC" -ne 0 ] && grep -q "refusing" <<<"$EMPTY_OUT"; then
  ok "zero candidates over a populated checkout refuses (rc=$EMPTY_RC)"
else bad "empty scan passed green (rc=$EMPTY_RC): $EMPTY_OUT"; fi
VOID="$WORK/void"; mkdir -p "$VOID"
VOID_OUT="$(XYZ_BOARD_SYNC_CLONE_DIRS="" python3 "$TOOL" scan --root "$VOID" 2>&1)"; VOID_RC=$?
if [ "$VOID_RC" -ne 0 ] && grep -q "refusing" <<<"$VOID_OUT"; then
  ok "surface-less (void) root refuses too (S-2 residual gap closed)"
else bad "void scan passed green (rc=$VOID_RC): $VOID_OUT"; fi

# ── 5. kill-switch: XYZ_BOARD_SYNC=0 no-ops everywhere (N1) ─────────────────────
echo "5. kill-switch"
KS_OUT="$(XYZ_BOARD_SYNC=0 python3 "$TOOL" scan --root "$FIX" 2>&1)"; KS_RC=$?
if [ "$KS_RC" -eq 0 ] && grep -q "kill-switch" <<<"$KS_OUT"; then
  ok "kill-switch no-ops"
else bad "kill-switch not honored (rc=$KS_RC): $KS_OUT"; fi

# ── 6. settings env tier: XYZ_BOARD_SYNC_<KEY> overrides (N3: implemented in-tool) ──
echo "6. settings env tier"
CFG_OUT="$(XYZ_BOARD_SYNC_PROJECT_NUMBER=99 python3 "$TOOL" config 2>&1)"
if grep -q '"project_number": 99' <<<"$CFG_OUT"; then
  ok "env tier overrides nested board_sync setting"
else bad "env tier ignored: $CFG_OUT"; fi
if grep -Eq "token_file.*reserved" <<<"$CFG_OUT"; then
  ok "config output marks token_file reserved (no secret material)"
else bad "token_file annotation missing"; fi

# ── 7. witnessed red: break the PDDA extractor in a copy, watch coverage vanish ─
echo "7. witnessed red (extractor break)"
MUT="$WORK/mutated"; mkdir -p "$MUT"
cp "$ROOT/utils/py/board_sync.py" "$MUT/board_sync.py"
cp "$ROOT/utils/py/device_config.py" "$MUT/device_config.py"
require_fixture "$MUT" "mutation copy dir"
require_fixture_file "$MUT/board_sync.py" "mutated module copy"
# Portable rewrite (QA r1 S-5): `sed -i ''` is BSD-only and silently no-ops the mutation
# under GNU sed (the ubuntu canary runs this suite) — which would fake the witnessed red.
sed 's/GH-\*\.md/ZZ-*.md/' "$MUT/board_sync.py" > "$MUT/board_sync.py.tmp" && mv "$MUT/board_sync.py.tmp" "$MUT/board_sync.py"
MUT_OUT="$(python3 "$MUT/board_sync.py" scan --root "$FIX" 2>&1)"; MUT_RC=$?
if [ "$MUT_RC" -eq 0 ] && ! grep -q "gh-123" <<<"$MUT_OUT"; then
  ok "broken extractor drops gh-123 (this suite would be red — the pin holds)"
else bad "mutated extractor still found gh-123 — the witnessed red did not fire"; fi
if grep -Eq "gh-124.*branch" <<<"$MUT_OUT"; then
  ok "mutation isolated to the pdda extractor (branches still found)"
else bad "mutation leaked beyond the pdda extractor"; fi

# ── 8. weak-only reconcile NEVER writes, even with --write (entry≠start at the
#     writer — the plan's core invariant, pinned fully offline: no strong candidate
#     means board_add is never called, so no network is touched) ──────────────────
echo "8. weak-only reconcile refuses to write (S-4)"
WONLY="$WORK/weakonly"; mkdir -p "$WONLY/PROJECT/2-WORKING" "$WORK/clones2/Repo2-gh125"
python3 - "$WONLY/releases.db" <<'PY'
import sqlite3, sys
conn = sqlite3.connect(sys.argv[1])
conn.execute("CREATE TABLE roadmap_items (gh_number INTEGER, status_marker TEXT)")
conn.execute("INSERT INTO roadmap_items VALUES (128, '🚧')")
conn.commit(); conn.close()
PY
require_fixture "$WONLY" "weak-only fixture checkout"
require_fixture_file "$WONLY/releases.db" "weak-only releases db"
REC_OUT="$(XYZ_BOARD_SYNC_CLONE_DIRS="$WORK/clones2" python3 "$TOOL" reconcile --root "$WONLY" --write 2>&1)"; REC_RC=$?
if [ "$REC_RC" -eq 0 ] \
   && grep -q "gh-128.*weak-only" <<<"$REC_OUT" \
   && grep -q "gh-125.*weak-only" <<<"$REC_OUT" \
   && ! grep -Eq "would add|added \+ Status" <<<"$REC_OUT"; then
  ok "weak-only candidates log and never write, even with --write"
else bad "weak-only reconcile wrote or misreported (rc=$REC_RC): $REC_OUT"; fi

# ── 9. loud-error contracts (QA r1 N-2, N-3) ────────────────────────────────────
echo "9. loud errors + state-path override"
python3 "$TOOL" --write scan --root "$FIX" >/dev/null 2>&1
if [ $? -ne 0 ]; then ok "flag-before-subcommand is a loud usage error"; else bad "--write before subcommand silently accepted"; fi
GARBAGE_OUT="$(python3 "$TOOL" touch nonsense-issue 2>&1)"; GARBAGE_RC=$?
if [ "$GARBAGE_RC" -ne 0 ]; then ok "touch with unparseable issue fails (rc=$GARBAGE_RC)"; else bad "touch accepted garbage"; fi
STATE_OUT="$(XYZ_BOARD_SYNC_STATE_PATH="$WORK/state.json" python3 "$TOOL" config 2>&1)"
# pathlib collapses the double slash $TMPDIR's trailing '/' puts in $WORK; normalize the
# expectation with a pure string op (no path re-capture — mktemp-trap-guard watches those).
if grep -q "\"state_path\": \"${WORK//\/\///}/state.json\"" <<<"$STATE_OUT"; then
  ok "XYZ_BOARD_SYNC_STATE_PATH overrides state path (offline-pinnable)"
else bad "state path override ignored: $STATE_OUT"; fi

# ── 10. reconcile over an idle clone: "nothing to reconcile" is reachable (r1 F3) ──
# The empty-input refusal belongs to the explicit scan verb; the sweeper-shaped entry
# point must exit 0 on a clean repo or Phase 2 hooks crash on idle clones.
echo "10. reconcile on empty"
IDLE="$WORK/idle"; mkdir -p "$IDLE/PROJECT/2-WORKING"
IDLE_OUT="$(XYZ_BOARD_SYNC_CLONE_DIRS="" python3 "$TOOL" reconcile --root "$IDLE" --write 2>&1)"; IDLE_RC=$?
if [ "$IDLE_RC" -eq 0 ] && grep -q "nothing to reconcile" <<<"$IDLE_OUT"; then
  ok "reconcile over an idle clone exits 0 with 'nothing to reconcile'"
else bad "idle reconcile failed (rc=$IDLE_RC): $IDLE_OUT"; fi

# ── 11. JSON-file string→list coercion (r1 F6) — via a fixture device_config ────
echo "11. config coercion"
DEVCFG="$WORK/device_config.json"
printf '%s\n' '{"board_sync": {"repos": "HiQS-Labs/XYZ-forge"}}' > "$DEVCFG"
require_fixture_file "$DEVCFG" "fixture device config"
CO_OUT="$(XYZ_DEVICE_CONFIG_PATH="$DEVCFG" XYZ_BOARD_SYNC_CLONE_DIRS="" python3 "$TOOL" config 2>&1)"
if grep -q '"repos": \[' <<<"$CO_OUT" && grep -q '"HiQS-Labs/XYZ-forge"' <<<"$CO_OUT"; then
  ok "a string repos value from device_config.json is coerced to a list"
else bad "string repos not coerced: $CO_OUT"; fi

echo
echo "GH-402 board_sync Phase 1: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
