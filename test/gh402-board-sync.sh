#!/usr/bin/env bash
# gh402-board-sync.sh — GH-402 Phase 1: board_sync.py extraction, strength classification,
# empty-input refusal, kill-switch, settings env tier, and a witnessed-red mutation leg.
#
# OFFLINE BY DESIGN: this suite exercises the offline half (scan/config/kill-switch).
# The live write path (add → set status → delete round-trip on the real board) is NOT
# suite-pinned — it was proven once by the Phase 0 spike (2026-09-02, receipts in
# PROJECT/2-WORKING/GH-402-BOARD-SYNC.md) and needs a token + network by definition.
#
# Witnessed-red discipline (plan v5, N2): the mutation leg breaks the PDDA extractor in a
# COPY of the module and asserts the fixture issue disappears from scan output — proving
# the positive assertions above it are load-bearing, not decorative. An extractor that
# silently matched nothing would turn this suite red, not green.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL="$ROOT/utils/py/board_sync.py"

PASS=0; FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  ok  - $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL- $1"; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh402-board-sync.XXXXXX")"
WORK="$(cd "$WORK" && pwd)"   # canonicalize ($TMPDIR's trailing slash makes a literal // that
                              # resolved-parent comparisons would otherwise mismatch)
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

require_fixture() {  # containment, not a null check (GH-567): must exist AND live under $WORK.
  local p="$1" parent
  case "$p" in
    "$WORK"/*) ;;
    *) echo "  FAIL- fixture escapes sandbox: $p" >&2; return 1 ;;
  esac
  # Lexical only so far — resolve the parent to catch $WORK/../../real (QA r1 N-4).
  parent="$(cd "${p%/*}" 2>/dev/null && pwd)" || return 1
  case "$parent" in
    "$WORK"|"$WORK"/*) [ -e "$p" ] ;;
    *) echo "  FAIL- fixture resolves outside sandbox: $p" >&2; return 1 ;;
  esac
}

# ── fixture: a populated fake checkout ─────────────────────────────────────────
FIX="$WORK/fixture"
mkdir -p "$FIX/PROJECT/2-WORKING" "$FIX/.tick/events" "$WORK/clones/SomeRepo-gh125"
touch "$FIX/PROJECT/2-WORKING/GH-123-TEST.md"          # strong: pdda_doc
touch "$FIX/PROJECT/2-WORKING/GH-402-BOARD-SYNC.md"    # strong: pdda_doc (multi-word slug)
git -C "$FIX" init -q
git -C "$FIX" commit -q --allow-empty -m "seed" 2>/dev/null
git -C "$FIX" branch "fix/gh124-lane"                  # strong: branch
git -C "$FIX" branch "marathon/gh-391-emit"            # strong: branch (digits only, no suffix bleed)
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
for f in "$FIX" "$FIX/releases.db" "$WORK/clones/SomeRepo-gh125"; do
  require_fixture "$f" || { echo "fixture missing: $f" >&2; exit 1; }
done
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
  "gh-126.*strong.*tick_event" \
  "gh-127.*strong.*jog_running"; do
  if printf '%s\n' "$SCAN_OUT" | grep -Eq "$want"; then ok "$want"; else bad "$want (scan rc=$SCAN_RC)"; fi
done

# ── 2. writer precision: weak signals are classified weak, never strong ────────
echo "2. strength classification (S2)"
if printf '%s\n' "$SCAN_OUT" | grep -Eq "gh-125[[:space:]]+weak[[:space:]]+clone_dir"; then
  ok "clone dir is weak (presence is not work)"
else bad "clone dir not classified weak"; fi
if printf '%s\n' "$SCAN_OUT" | grep -Eq "gh-128[[:space:]]+weak[[:space:]]+stale_marker"; then
  ok "stale 🚧 marker is weak"
else bad "stale marker not classified weak"; fi

# ── 3. negatives: what must NOT appear ─────────────────────────────────────────
echo "3. negatives"
printf '%s\n' "$SCAN_OUT" | grep -q "gh-130" && bad "memory-verb event leaked (gh-130)" || ok "non-claim verbs ignored"
printf '%s\n' "$SCAN_OUT" | grep -q "gh-129" && bad "✅ marker leaked as candidate" || ok "done markers ignored"
printf '%s\n' "$SCAN_OUT" | grep -q "gh-131" && bad "completed jog row leaked" || ok "non-running jog rows ignored"
printf '%s\n' "$SCAN_OUT" | grep -Eq "gh-391[0-9]" && bad "branch digits bled into suffix" || ok "branch number extraction bounded"

# ── 4. empty-input refusal: a populated checkout with zero candidates fails ────
# (clone_dirs is root-independent by design — per-device folders — so this leg must
#  also empty that source or the fixture's clone dir leaks into the "empty" world.)
echo "4. empty-input refusal"
EMPTY="$WORK/empty"; mkdir -p "$EMPTY/PROJECT/2-WORKING"
EMPTY_OUT="$(XYZ_BOARD_SYNC_CLONE_DIRS="" python3 "$TOOL" scan --root "$EMPTY" 2>&1)"; EMPTY_RC=$?
if [ "$EMPTY_RC" -ne 0 ] && printf '%s\n' "$EMPTY_OUT" | grep -q "refusing"; then
  ok "zero candidates over a populated checkout refuses (rc=$EMPTY_RC)"
else bad "empty scan passed green (rc=$EMPTY_RC): $EMPTY_OUT"; fi
VOID="$WORK/void"; mkdir -p "$VOID"
VOID_OUT="$(XYZ_BOARD_SYNC_CLONE_DIRS="" python3 "$TOOL" scan --root "$VOID" 2>&1)"; VOID_RC=$?
if [ "$VOID_RC" -ne 0 ] && printf '%s\n' "$VOID_OUT" | grep -q "refusing"; then
  ok "surface-less (void) root refuses too (S-2 residual gap closed)"
else bad "void scan passed green (rc=$VOID_RC): $VOID_OUT"; fi

# ── 5. kill-switch: XYZ_BOARD_SYNC=0 no-ops everywhere (N1) ─────────────────────
echo "5. kill-switch"
KS_OUT="$(XYZ_BOARD_SYNC=0 python3 "$TOOL" scan --root "$FIX" 2>&1)"; KS_RC=$?
if [ "$KS_RC" -eq 0 ] && printf '%s\n' "$KS_OUT" | grep -q "kill-switch"; then
  ok "kill-switch no-ops"
else bad "kill-switch not honored (rc=$KS_RC): $KS_OUT"; fi

# ── 6. settings env tier: XYZ_BOARD_SYNC_<KEY> overrides (N3: implemented in-tool) ──
echo "6. settings env tier"
CFG_OUT="$(XYZ_BOARD_SYNC_PROJECT_NUMBER=99 python3 "$TOOL" config 2>&1)"
if printf '%s\n' "$CFG_OUT" | grep -q '"project_number": 99'; then
  ok "env tier overrides nested board_sync setting"
else bad "env tier ignored: $CFG_OUT"; fi
if printf '%s\n' "$CFG_OUT" | grep -Eq "token_file.*reserved"; then
  ok "config output marks token_file reserved (no secret material)"
else bad "token_file annotation missing"; fi

# ── 7. witnessed red: break the PDDA extractor in a copy, watch coverage vanish ─
echo "7. witnessed red (extractor break)"
MUT="$WORK/mutated"; mkdir -p "$MUT"
cp "$ROOT/utils/py/board_sync.py" "$MUT/board_sync.py"
cp "$ROOT/utils/py/device_config.py" "$MUT/device_config.py"
require_fixture "$MUT/board_sync.py" || { bad "mutation copy missing"; exit 1; }
# Portable rewrite (QA r1 S-5): `sed -i ''` is BSD-only and silently no-ops the mutation
# under GNU sed (the ubuntu canary runs this suite) — which would fake the witnessed red.
sed 's/GH-\*\.md/ZZ-*.md/' "$MUT/board_sync.py" > "$MUT/board_sync.py.tmp" && mv "$MUT/board_sync.py.tmp" "$MUT/board_sync.py"
MUT_OUT="$(python3 "$MUT/board_sync.py" scan --root "$FIX" 2>&1)"; MUT_RC=$?
if [ "$MUT_RC" -eq 0 ] && ! printf '%s\n' "$MUT_OUT" | grep -q "gh-123"; then
  ok "broken extractor drops gh-123 (this suite would be red — the pin holds)"
else bad "mutated extractor still found gh-123 — the witnessed red did not fire"; fi
if printf '%s\n' "$MUT_OUT" | grep -Eq "gh-124.*branch"; then
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
require_fixture "$WONLY/releases.db" || { bad "weak-only fixture missing"; exit 1; }
REC_OUT="$(XYZ_BOARD_SYNC_CLONE_DIRS="$WORK/clones2" python3 "$TOOL" reconcile --root "$WONLY" --write 2>&1)"; REC_RC=$?
if [ "$REC_RC" -eq 0 ] \
   && printf '%s\n' "$REC_OUT" | grep -q "gh-128.*weak-only" \
   && printf '%s\n' "$REC_OUT" | grep -q "gh-125.*weak-only" \
   && ! printf '%s\n' "$REC_OUT" | grep -Eq "would add|added \+ Status"; then
  ok "weak-only candidates log and never write, even with --write"
else bad "weak-only reconcile wrote or misreported (rc=$REC_RC): $REC_OUT"; fi

# ── 9. loud-error contracts (QA r1 N-2, N-3) ────────────────────────────────────
echo "9. loud errors + state-path override"
python3 "$TOOL" --write scan --root "$FIX" >/dev/null 2>&1
if [ $? -ne 0 ]; then ok "flag-before-subcommand is a loud usage error"; else bad "--write before subcommand silently accepted"; fi
GARBAGE_OUT="$(python3 "$TOOL" touch nonsense-issue 2>&1)"; GARBAGE_RC=$?
if [ "$GARBAGE_RC" -ne 0 ]; then ok "touch with unparseable issue fails (rc=$GARBAGE_RC)"; else bad "touch accepted garbage"; fi
STATE_OUT="$(XYZ_BOARD_SYNC_STATE_PATH="$WORK/state.json" python3 "$TOOL" config 2>&1)"
if printf '%s\n' "$STATE_OUT" | grep -q "\"state_path\": \"$WORK/state.json\""; then
  ok "XYZ_BOARD_SYNC_STATE_PATH overrides state path (offline-pinnable)"
else bad "state path override ignored: $STATE_OUT"; fi

echo
echo "GH-402 board_sync Phase 1: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
