#!/usr/bin/env bash
# gh549-work-events.sh — GH-549: the work-state event stream at the single ledger write seam.
#
# Proves:
#   1. Migration 008 creates work_events + connector_cursors and stamps version 8.
#   2. work_events is append-only: UPDATE and DELETE are both refused by name.
#   3. work_events is in the canonical dump but NOT in the business-digest view of it.
#   4. connector_cursors is in NEITHER — it is device-local, written after the transaction.
#   5. Real ledger verbs emit the right event: roadmap add -> parked, rate -> rated,
#      update --status-marker 🚧 -> in_flight.
#   6. The extractor registry is TOTAL: every op reachable from a perform_write caller is
#      either mapped or allowlisted, and an unclassified op raises.
#   7. `check --rebuild` round-trips work_events (dump -> DB) without loss.
#   8. RED CONTROL A: emitting work_events ABOVE dump_text's include_receipts guard puts it
#      inside business_digest and makes `check` report receipt-chain. Proves the placement is
#      what protects the chain.
#   9. RED CONTROL B: adding connector_cursors to dump_text makes a post-transaction cursor
#      advance fail dump-divergence, while the SHIPPED code stays clean under the identical
#      advance. Proves cursors must stay out of the dump (Codex plan-QA r1 blocker).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/utils/py/releases_app.py"

. "$ROOT/test/lib/fixture-guard.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS + 1)); echo "  ok  - $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL- $1"; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh549-work-events.XXXXXX")"
fixture_guard_init "$WORK"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

[ -f "$APP" ] || { echo "releases_app.py missing at $APP" >&2; exit 1; }

# ── a real ledger fixture: a git checkout (the writer lock needs a git common-dir, GH-448) ──
FX="$WORK/ledger"; mkdir -p "$FX"
require_fixture "$FX" "gh549 ledger fixture"
( cd "$FX" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
cp "$ROOT/releases.db" "$ROOT/releases.sql" "$FX/" 2>/dev/null || {
  echo "gh549: no ledger to copy from $ROOT" >&2; exit 1; }
app() { python3 "$APP" --root "$FX" "$@"; }

echo "GH-549 work-state event stream:"

echo "1. migration 008"
app migrate >/dev/null 2>&1
VER="$(sqlite3 "$FX/releases.db" "SELECT version FROM schema_migrations WHERE version=8;" 2>/dev/null)"
[ "$VER" = "8" ] && ok "schema_migrations carries version 8" || bad "version 8 not stamped (got '$VER')"
OBJ="$(sqlite3 "$FX/releases.db" "SELECT group_concat(name,',') FROM sqlite_master WHERE name IN ('work_events','connector_cursors','work_events_no_update','work_events_no_delete') ORDER BY name;" 2>/dev/null)"
case "$OBJ" in
  *work_events*) ok "work_events, connector_cursors and both triggers exist" ;;
  *) bad "expected objects missing (got '$OBJ')" ;;
esac
for t in work_events_no_update work_events_no_delete; do
  sqlite3 "$FX/releases.db" "SELECT 1 FROM sqlite_master WHERE type='trigger' AND name='$t';" \
    | grep -q 1 && ok "trigger $t present" || bad "trigger $t missing"
done

echo "2. work_events is append-only (witnessed refusals)"
RID="$(sqlite3 "$FX/releases.db" "SELECT id FROM repos LIMIT 1;")"
sqlite3 "$FX/releases.db" "INSERT INTO work_events(global_id,repo_id,gh_number,txn_id,event,payload,at) VALUES ('wev-01M25ZRSCSHSA1SRZVK8ZPQJBS',$RID,1,'txn-t','probe',NULL,'2026-09-10T00:00:00Z');" 2>/dev/null
U="$(sqlite3 "$FX/releases.db" "UPDATE work_events SET event='x' WHERE txn_id='txn-t';" 2>&1)"
case "$U" in *"append-only"*) ok "UPDATE refused: work_events is append-only" ;;
  *) bad "UPDATE was NOT refused (got '$U')" ;; esac
D="$(sqlite3 "$FX/releases.db" "DELETE FROM work_events WHERE txn_id='txn-t';" 2>&1)"
case "$D" in *"append-only"*) ok "DELETE refused: work_events is append-only" ;;
  *) bad "DELETE was NOT refused (got '$D')" ;; esac
sqlite3 "$FX/releases.db" "DROP TRIGGER work_events_no_delete; DELETE FROM work_events WHERE txn_id='txn-t'; CREATE TRIGGER work_events_no_delete BEFORE DELETE ON work_events BEGIN SELECT RAISE(ABORT,'work_events is append-only'); END;" 2>/dev/null

echo "5. real verbs emit the right events"
app roadmap add --issue-num 9901 --issue-url "https://example.invalid/9901" \
    --title "gh549 fixture" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
app roadmap rate --issue-num 9901 --rated 10/20/30/40 >/dev/null 2>&1
app roadmap update --issue-num 9901 --status-marker "🚧" >/dev/null 2>&1
EV="$(sqlite3 "$FX/releases.db" "SELECT group_concat(event,',') FROM (SELECT event FROM work_events WHERE gh_number=9901 ORDER BY id);")"
[ -n "$EV" ] || bad "no events emitted at all — the fixture proves nothing"
[ "$EV" = "parked,rated,in_flight" ] \
  && ok "roadmap add/rate/update emitted parked,rated,in_flight" \
  || bad "wrong event sequence (got '$EV')"
app check >/dev/null 2>&1 && ok "check is clean after three emitting writes" || bad "check failed after emission"

echo "6. dump placement (the load-bearing decision), with rows present"
ROWS="$(sqlite3 "$FX/releases.db" "SELECT count(*) FROM work_events;")"
[ "${ROWS:-0}" -gt 0 ] || bad "no work_events rows - the placement probe would pass vacuously"
cat > "$WORK/place.py" <<'PYPROBE'
import sys, os, sqlite3
sys.path.insert(0, os.path.join(os.environ["GH549_ROOT"], "utils", "py"))
import releases_app as R
conn = sqlite3.connect(sys.argv[1]); conn.row_factory = sqlite3.Row
full = R.dump_text(conn, 0)
biz  = R.dump_text(conn, 0, include_receipts=False, include_generation=False)
print("full_we=%s biz_we=%s full_cc=%s" % ("work_events" in full, "work_events" in biz,
                                           "connector_cursors" in full))
PYPROBE
PLACE="$(GH549_ROOT="$ROOT" python3 "$WORK/place.py" "$FX/releases.db")"
case "$PLACE" in
  "full_we=True biz_we=False full_cc=False")
    ok "work_events is in the canonical dump but NOT in the business-digest view"
    ok "connector_cursors is in neither — device-local by design" ;;
  *) bad "dump placement wrong: $PLACE" ;;
esac

echo "7. the extractor registry is total"
cat > "$WORK/cov.py" <<'PYPROBE'
import sys, os, re
root = os.environ["GH549_ROOT"]
sys.path.insert(0, os.path.join(root, "utils", "py"))
import releases_app as R
src = open(os.path.join(root, "utils", "py", "releases_app.py"), encoding="utf-8").read()
# Derive the op inventory from source rather than hardcoding a count (Codex plan-QA r4):
# every literal passed as perform_write's `op` argument.
ops = set(re.findall(r'perform_write\(\s*root,\s*conn,\s*"([a-z0-9-]+)"', src))
ops |= set(re.findall(r'perform_write\([^,]+,\s*conn,\s*"([a-z0-9-]+)"', src))
unclassified = []
for op in sorted(ops):
    try:
        R.extractor_for(op)
    except KeyError:
        unclassified.append(op)
print("ops=%d unclassified=%s" % (len(ops), ",".join(unclassified) or "none"))
PYPROBE
COV="$(GH549_ROOT="$ROOT" python3 "$WORK/cov.py")"
case "$COV" in
  *"unclassified=none"*) ok "every derived op is mapped or allowlisted ($COV)" ;;
  *) bad "unclassified ops found: $COV" ;;
esac
cat > "$WORK/raises.py" <<'PYPROBE'
import sys, os
sys.path.insert(0, os.path.join(os.environ["GH549_ROOT"], "utils", "py"))
import releases_app as R
try:
    R.extractor_for("a-brand-new-verb")
    print("NO")
except KeyError:
    print("YES")
PYPROBE
RAISES="$(GH549_ROOT="$ROOT" python3 "$WORK/raises.py")"
[ "$RAISES" = "YES" ] && ok "an unclassified op raises, so a new verb cannot silently drop a state" \
                      || bad "unclassified op did not raise"

# Snapshot BEFORE the rebuild: a merge-rebuild receipt re-anchors the chain, and the chain
# rule tolerates re-anchors — so a fixture taken after step 8 would absorb control A's break
# and the control would pass vacuously.
PRISTINE="$WORK/pristine"; mkdir -p "$PRISTINE"
require_fixture "$PRISTINE" "gh549 pre-rebuild ledger snapshot"
cp "$FX/releases.db" "$FX/releases.sql" "$PRISTINE/"

echo "8. rebuild round-trips work_events"
BEFORE="$(sqlite3 "$FX/releases.db" "SELECT count(*) FROM work_events;")"
app check --rebuild >/dev/null 2>&1
AFTER="$(sqlite3 "$FX/releases.db" "SELECT count(*) FROM work_events;")"
[ "$BEFORE" -gt 0 ] || bad "fixture had zero events — round-trip proves nothing"
[ "$BEFORE" = "$AFTER" ] && ok "check --rebuild preserved all $AFTER work_events rows" \
                         || bad "rebuild lost rows ($BEFORE -> $AFTER)"

echo "9. RED CONTROL A — work_events above the include_receipts guard breaks the chain"
MUTA="$WORK/mutA.py"
python3 - "$APP" "$MUTA" <<'PYMUT'
import sys
src = open(sys.argv[1], encoding="utf-8").read()
anchor = '        if _table_exists(conn, "work_events"):'
tail = '    return "\\n".join(out) + "\\n"'
assert anchor in src, "MUTA: work_events emit anchor not found - the control would be a no-op"
assert tail in src, "MUTA: dump_text return anchor not found - the control would be a no-op"
i = src.index(anchor)
j = src.index(tail, i)
block = src[i:j]
dedented = "\n".join(l[4:] if l.startswith("    ") else l for l in block.split("\n"))
out = src[:i] + src[j:]
k = out.index("    if include_receipts:")
mutated = out[:k] + dedented + out[k:]
assert mutated != src, "MUTA: mutation produced an identical file"
open(sys.argv[2], "w", encoding="utf-8").write(mutated)
PYMUT
FXA="$WORK/ledgerA"; mkdir -p "$FXA"; require_fixture "$FXA" "gh549 red-control-A fixture"
( cd "$FXA" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXA/"
python3 "$MUTA" --root "$FXA" roadmap add --issue-num 9902 --issue-url "https://example.invalid/9902" \
    --title "red A one" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/y.md" >/dev/null 2>&1
python3 "$MUTA" --root "$FXA" roadmap add --issue-num 9903 --issue-url "https://example.invalid/9903" \
    --title "red A two" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/z.md" >/dev/null 2>&1
MUTA_OUT="$(python3 "$MUTA" --root "$FXA" check 2>&1)"
[ -n "$MUTA_OUT" ] || bad "  control A produced no output at all — it proves nothing"
case "$MUTA_OUT" in
  *"rule=receipt-chain"*) ok "mutated placement makes check report receipt-chain (the red fires)" ;;
  *) bad "RED CONTROL A did not fire — the placement is not what protects the chain" ;;
esac

echo "10. RED CONTROL B — connector_cursors in the dump breaks the dump comparison"
MUTB="$WORK/mutB.py"
python3 - "$APP" "$MUTB" <<'PYMUT'
import sys
src = open(sys.argv[1], encoding="utf-8").read()
anchor = '        if _table_exists(conn, "work_events"):'
assert anchor in src, "MUTB: anchor not found - the control would be a no-op"
add = ('        if _table_exists(conn, "connector_cursors"):\n'
       '            _emit(w, "connector_cursors",\n'
       '                  ["connector", "last_event_id", "last_attempt_at", "last_error", "updated_at"],\n'
       '                  _rows(conn, "SELECT connector, last_event_id, last_attempt_at, last_error, "\n'
       '                              "updated_at FROM connector_cursors ORDER BY connector"))\n')
mutated = src.replace(anchor, add + anchor, 1)
assert mutated != src, "MUTB: mutation produced an identical file"
open(sys.argv[2], "w", encoding="utf-8").write(mutated)
PYMUT
FXB="$WORK/ledgerB"; mkdir -p "$FXB"; require_fixture "$FXB" "gh549 red-control-B fixture"
( cd "$FXB" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXB/"
python3 "$MUTB" --root "$FXB" roadmap add --issue-num 9904 --issue-url "https://example.invalid/9904" \
    --title "red B" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/d.md" >/dev/null 2>&1
python3 "$MUTB" --root "$FXB" check >/dev/null 2>&1 \
  && ok "  baseline: mutated build is clean before any cursor exists" \
  || bad "  baseline: mutated build was already dirty — the next assertion would prove nothing"
# a connector advancing its cursor, exactly as the dispatcher will, AFTER the transaction
sqlite3 "$FXB/releases.db" "INSERT INTO connector_cursors(connector,last_event_id,last_attempt_at,last_error,updated_at) VALUES ('github_board',1,'2026-09-10T00:00:00Z',NULL,'2026-09-10T00:00:00Z');"
MUTB_OUT="$(python3 "$MUTB" --root "$FXB" check 2>&1)"
[ -n "$MUTB_OUT" ] || bad "  control B produced no output at all — it proves nothing"
case "$MUTB_OUT" in
  *"rule=dump-divergence"*) ok "cursor in the dump + post-transaction advance => dump-divergence (the red fires)" ;;
  *) bad "RED CONTROL B did not fire — cursors could be tracked without breaking check" ;;
esac
if python3 "$APP" --root "$FXB" check >/dev/null 2>&1; then
  ok "SHIPPED code is clean under the identical cursor advance (the fix holds)"
else
  bad "shipped code also failed — the fix does not hold"
fi

echo "11. shared nested-block config resolution (device_config.resolve_device_block)"
# Absent config is a silent no-op; a malformed file must be distinguishable from it. That
# distinction is the whole reason profile_resolve.py re-opens the file by hand today.
cat > "$WORK/cfgprobe.py" <<'PYPROBE'
import sys, os, json, tempfile
sys.path.insert(0, os.path.join(os.environ["GH549_ROOT"], "utils", "py"))
import device_config as D

DEF = {"owner": "", "number": 0, "repos": [], "on": False}

def probe(path):
    os.environ["XYZ_DEVICE_CONFIG_PATH"] = path
    return D.resolve_device_block("work_connectors", DEF, "XYZ_WC")

tmp = tempfile.mkdtemp()
missing = os.path.join(tmp, "nope.json")
cfg, err = probe(missing)
print("absent_err=%s absent_defaults=%s" % (err is None, cfg == DEF))

bad = os.path.join(tmp, "bad.json")
open(bad, "w").write("{not json")
cfg, err = probe(bad)
print("malformed_err=%s" % (err is not None))

empty = os.path.join(tmp, "empty.json")
open(empty, "w").write("")
cfg, err = probe(empty)
print("empty_is_absent=%s" % (err is None))

good = os.path.join(tmp, "good.json")
json.dump({"work_connectors": {"owner": "someone", "number": 7, "repos": "o/n"}}, open(good, "w"))
cfg, err = probe(good)
print("file_tier=%s list_coerced=%s" % (cfg["owner"] == "someone" and cfg["number"] == 7,
                                        cfg["repos"] == ["o/n"]))

os.environ["XYZ_WC_OWNER"] = "envwins"
os.environ["XYZ_WC_NUMBER"] = "42"
cfg, err = probe(good)
print("env_wins=%s int_coerced=%s" % (cfg["owner"] == "envwins", cfg["number"] == 42))
PYPROBE
CFGOUT="$(GH549_ROOT="$ROOT" python3 "$WORK/cfgprobe.py" 2>&1)"
[ -n "$CFGOUT" ] || bad "config probe produced no output"
case "$CFGOUT" in *"absent_err=True absent_defaults=True"*)
  ok "an absent config is a silent no-op returning the defaults" ;;
  *) bad "absent config not handled: $CFGOUT" ;; esac
case "$CFGOUT" in *"malformed_err=True"*)
  ok "a malformed config reports an error instead of looking absent" ;;
  *) bad "malformed config was indistinguishable from absent: $CFGOUT" ;; esac
case "$CFGOUT" in *"empty_is_absent=True"*)
  ok "an empty config file counts as absent, not malformed" ;;
  *) bad "empty file misclassified: $CFGOUT" ;; esac
case "$CFGOUT" in *"file_tier=True list_coerced=True"*)
  ok "the file tier resolves, and a bare string where a list belongs is coerced" ;;
  *) bad "file tier wrong: $CFGOUT" ;; esac
case "$CFGOUT" in *"env_wins=True int_coerced=True"*)
  ok "the env tier outranks the file and coerces to the default's type" ;;
  *) bad "env tier wrong: $CFGOUT" ;; esac

# board_sync must behave identically after being migrated onto the shared resolver.
BS="$(XYZ_DEVICE_CONFIG_PATH=/dev/null python3 "$ROOT/utils/py/board_sync.py" config 2>&1)"
case "$BS" in
  *'"project_owner"'*) ok "board_sync config still resolves through the shared block resolver" ;;
  *) bad "board_sync config broke after the migration: $BS" ;;
esac

echo
echo "GH-549 work-state event stream: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
