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
  # capture-then-match: a pipe into grep -q loses the producer's exit status (gh139)
  TRG="$(sqlite3 "$FX/releases.db" "SELECT 1 FROM sqlite_master WHERE type='trigger' AND name='$t';")"
  [ "$TRG" = "1" ] && ok "trigger $t present" || bad "trigger $t missing"
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

echo "12. connector dispatch: concurrent, bounded, isolated"
# Three stub connectors. Each reads its batch as JSON on stdin and reports on stdout, exactly
# as a real connector does; none of them touches the database.
cat > "$WORK/stub_ok.py" <<'PYSTUB'
import json, sys
b = json.load(sys.stdin)
print("advanced_to: %d" % max(e["id"] for e in b["events"]))
PYSTUB
cat > "$WORK/stub_fail.py" <<'PYSTUB'
import json, sys
json.load(sys.stdin)
sys.stderr.write("deliberate connector failure\n")
sys.exit(3)
PYSTUB
cat > "$WORK/stub_slow.py" <<'PYSTUB'
import json, sys, time
b = json.load(sys.stdin)
time.sleep(5)
print("advanced_to: %d" % max(e["id"] for e in b["events"]))
PYSTUB

cat > "$WORK/dispatch_probe.py" <<'PYPROBE'
import json, os, sqlite3, sys, time
root = os.environ["GH549_ROOT"]
sys.path.insert(0, os.path.join(root, "utils", "py"))
import work_connectors as WC

db  = sys.argv[1]
work = sys.argv[2]
mode = sys.argv[3]
os.environ["XYZ_WORK_CONNECTORS_REGISTRY"] = json.dumps({
    "s_ok":   os.path.join(work, "stub_ok.py"),
    "s_fail": os.path.join(work, "stub_fail.py"),
    "s_slow": os.path.join(work, "stub_slow.py"),
    "s_slow2": os.path.join(work, "stub_slow.py"),
})
cfg = {"enabled": True}

if mode == "isolation":
    # one failing, one succeeding: the good one must still advance, the bad one must not
    res = WC.dispatch(db, "2026-09-10T00:00:00Z",
                      connectors={"s_ok": cfg, "s_fail": cfg}, window_s=30)
    c = sqlite3.connect(db)
    rows = dict(c.execute("SELECT connector, last_event_id FROM connector_cursors").fetchall())
    errs = dict(c.execute("SELECT connector, last_error IS NOT NULL FROM connector_cursors").fetchall())
    print("ok_advanced=%s fail_stuck=%s fail_recorded=%s" % (
        rows.get("s_ok", 0) > 0, rows.get("s_fail", 0) == 0, bool(errs.get("s_fail"))))

elif mode == "concurrency":
    # two 5s sleepers under one 30s window: concurrent launch finishes in ~5s, serial in ~10s
    t0 = time.monotonic()
    WC.dispatch(db, "2026-09-10T00:00:00Z",
                connectors={"s_slow": cfg, "s_slow2": cfg}, window_s=30)
    print("elapsed=%.2f" % (time.monotonic() - t0))

elif mode == "window":
    # the same two sleepers under a 2s TOTAL window: both are killed, neither advances,
    # and the whole call still returns in about one window rather than two.
    #
    # Reset the cursors first. The concurrency run above advanced them to the last event, so
    # without this there would be nothing pending, dispatch would return {} in 0.00s, and both
    # assertions would pass for the wrong reason.
    c = sqlite3.connect(db)
    c.execute("DELETE FROM connector_cursors WHERE connector IN ('s_slow','s_slow2')")
    c.commit()
    pending = c.execute("SELECT count(*) FROM work_events").fetchone()[0]
    c.close()
    if not pending:
        print("elapsed=0 advanced=NO-EVENTS")
        raise SystemExit(0)
    t0 = time.monotonic()
    res = WC.dispatch(db, "2026-09-10T00:00:00Z",
                      connectors={"s_slow": cfg, "s_slow2": cfg}, window_s=2)
    print("elapsed=%.2f dispatched=%d advanced=%s" % (time.monotonic() - t0, len(res),
                                                      [v[0] for v in res.values()]))
PYPROBE

FXC="$WORK/ledgerC"; mkdir -p "$FXC"; require_fixture "$FXC" "gh549 dispatch fixture"
( cd "$FXC" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXC/"
EVN="$(sqlite3 "$FXC/releases.db" "SELECT count(*) FROM work_events;")"
[ "${EVN:-0}" -gt 0 ] || bad "  dispatch fixture has no events — every dispatch assertion would be vacuous"

ISO="$(GH549_ROOT="$ROOT" python3 "$WORK/dispatch_probe.py" "$FXC/releases.db" "$WORK" isolation 2>&1)"
case "$ISO" in
  *"ok_advanced=True fail_stuck=True fail_recorded=True"*)
    ok "two connectors, one failing: the good one advanced, the bad one did not, its error was recorded" ;;
  *) bad "connector isolation wrong: $ISO" ;;
esac

CONC="$(GH549_ROOT="$ROOT" python3 "$WORK/dispatch_probe.py" "$FXC/releases.db" "$WORK" concurrency 2>&1)"
CSEC="$(printf '%s' "$CONC" | sed -n 's/.*elapsed=\([0-9.]*\).*/\1/p')"
if [ -n "$CSEC" ] && python3 -c "import sys; sys.exit(0 if float('$CSEC') < 8.0 else 1)"; then
  ok "two 5s connectors finished in ${CSEC}s — launched concurrently, not serially"
else
  bad "dispatch is serial: two 5s connectors took ${CSEC:-?}s (serial would be ~10s)"
fi

WIN="$(GH549_ROOT="$ROOT" python3 "$WORK/dispatch_probe.py" "$FXC/releases.db" "$WORK" window 2>&1)"
case "$WIN" in
  *"dispatched=2"*) : ;;
  *) bad "  the window probe dispatched nothing — both window assertions would be vacuous ($WIN)" ;;
esac
WSEC="$(printf '%s' "$WIN" | sed -n 's/.*elapsed=\([0-9.]*\).*/\1/p')"
if [ -n "$WSEC" ] && python3 -c "import sys; sys.exit(0 if 1.5 < float('$WSEC') < 6.0 else 1)"; then
  ok "two hung connectors cost ONE ${WSEC}s window, not one timeout each"
else
  bad "the window is not one total deadline: ${WSEC:-?}s (expected ~2s, serial would be ~4s)"
fi
case "$WIN" in
  *"advanced=[None, None]"*) ok "a connector killed at the deadline does not advance its cursor" ;;
  *) bad "a timed-out connector advanced anyway: $WIN" ;;
esac

echo "13. dispatch never changes a host verb's exit code"
FXD="$WORK/ledgerD"; mkdir -p "$FXD"; require_fixture "$FXD" "gh549 host-rc fixture"
( cd "$FXD" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXD/"
cat > "$WORK/devcfg.json" <<'PYCFG'
{"work_connectors": {"github_board": {"enabled": true, "project_owner": "nobody", "project_number": 1}}}
PYCFG
XYZ_DEVICE_CONFIG_PATH="$WORK/devcfg.json" XYZ_CONNECTOR_WINDOW_S=2 \
  python3 "$APP" --root "$FXD" roadmap add --issue-num 9920 --issue-url "https://example.invalid/9920" \
  --title "host rc" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/rc.md" >/dev/null 2>&1
RC=$?
[ "$RC" -eq 0 ] && ok "a ledger verb exits 0 even with a connector configured that cannot succeed" \
                || bad "connector failure changed the host exit code (rc=$RC)"
ROW="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM roadmap_items WHERE gh_number=9920;")"
[ "$ROW" = "1" ] && ok "and the ledger row is committed regardless" || bad "ledger row missing after dispatch"
python3 "$APP" --root "$FXD" check >/dev/null 2>&1 \
  && ok "and check is clean after a dispatching write" || bad "check dirty after a dispatching write"

echo "14. work emit — one row, real txn_id, its own receipt"
FXE="$WORK/ledgerE"; mkdir -p "$FXE"; require_fixture "$FXE" "gh549 work-emit fixture"
( cd "$FXE" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXE/"
EB="$(sqlite3 "$FXE/releases.db" "SELECT count(*) FROM work_events;")"
XYZ_DEVICE_CONFIG_PATH=/dev/null python3 "$APP" --root "$FXE" work emit \
  --event pr_merged --gh-number 549 --payload-json '{"pr":548}' >/dev/null 2>&1
EA="$(sqlite3 "$FXE/releases.db" "SELECT count(*) FROM work_events;")"
[ "$((EA - EB))" = "1" ] \
  && ok "one work emit creates EXACTLY one row (not zero, not two)" \
  || bad "work emit wrote $((EA - EB)) rows, expected 1"
ROW="$(sqlite3 "$FXE/releases.db" "SELECT event||'|'||gh_number||'|'||(length(txn_id)>8) FROM work_events ORDER BY id DESC LIMIT 1;")"
case "$ROW" in
  "pr_merged|549|1") ok "the row carries the real transaction id minted inside perform_write" ;;
  *) bad "work emit row wrong: $ROW" ;;
esac
RCPT="$(sqlite3 "$FXE/releases.db" "SELECT op FROM op_receipts ORDER BY id DESC LIMIT 1;")"
[ "$RCPT" = "work-emit" ] \
  && ok "and it went through perform_write — its own receipt is on the chain" \
  || bad "no work-emit receipt (last op was '$RCPT') — it bypassed the single write path"
XYZ_DEVICE_CONFIG_PATH=/dev/null python3 "$APP" --root "$FXE" check >/dev/null 2>&1 \
  && ok "check is clean after work emit" || bad "check dirty after work emit"

echo "15. work reconcile — replay, idempotence, reset"
cat > "$WORK/stub_ok2.py" <<'PYSTUB'
import json, sys
b = json.load(sys.stdin)
print("advanced_to: %d" % max(e["id"] for e in b["events"]))
PYSTUB
cat > "$WORK/recon_cfg.json" <<'PYCFG'
{"work_connectors": {"github_board": {"enabled": true, "project_owner": "someone", "project_number": 1}}}
PYCFG
REG="{\"github_board\":\"$WORK/stub_ok2.py\"}"
NOCFG="$(XYZ_DEVICE_CONFIG_PATH=/dev/null python3 "$APP" --root "$FXE" work reconcile 2>&1)"
case "$NOCFG" in
  *"no connectors enabled"*) ok "unconfigured reconcile is a no-op that says so" ;;
  *) bad "unconfigured reconcile did something: $NOCFG" ;;
esac
R1="$(XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG" \
      python3 "$APP" --root "$FXE" work reconcile 2>&1)"
case "$R1" in
  *"replayed through event"*) ok "reconcile replays the events after the cursor" ;;
  *) bad "reconcile did not replay: $R1" ;;
esac
R2="$(XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG" \
      python3 "$APP" --root "$FXE" work reconcile 2>&1)"
case "$R2" in
  *"nothing to replay"*) ok "a second run is idempotent — the cursor is current" ;;
  *) bad "reconcile was not idempotent: $R2" ;;
esac
R3="$(XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG" \
      python3 "$APP" --root "$FXE" work reconcile --reset 2>&1)"
case "$R3" in
  *"replayed through event"*) ok "--reset replays from the beginning (the rebuild recovery path)" ;;
  *) bad "--reset did not replay: $R3" ;;
esac
# Red control: an overshot cursor IN THE TABLE skips real events. This is why a connector is
# never trusted to set that number itself — the guard below is what keeps it from doing so.
LAST="$(sqlite3 "$FXE/releases.db" "SELECT max(id) FROM work_events;")"
[ -n "$LAST" ] && [ "$LAST" -gt 0 ] \
  || bad "fixture guard: no work_events rows — the overshoot control would be vacuous"
sqlite3 "$FXE/releases.db" "UPDATE connector_cursors SET last_event_id = $((LAST + 5)) WHERE connector='github_board';"
R4="$(XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG" \
      python3 "$APP" --root "$FXE" work reconcile 2>&1)"
case "$R4" in
  *"nothing to replay"*) ok "red control: an overshot cursor skips real events — which is why replay is cursor-driven, not scan-driven" ;;
  *) bad "an overshot cursor still replayed: $R4" ;;
esac

echo "15b. a connector cannot advance its own cursor out of the batch it was handed (impl QA r1)"
# The child's stdout is untrusted input. Reset the cursor so there IS a real batch to dispatch,
# then have the stub report a number beyond it. The old behaviour stored that number verbatim,
# permanently skipping every event up to it.
sqlite3 "$FXE/releases.db" "DELETE FROM connector_cursors WHERE connector='github_board';"
cat > "$WORK/stub_overshoot.py" <<'PYSTUB'
import json, sys
b = json.load(sys.stdin)
print("advanced_to: %d" % (max(e["id"] for e in b["events"]) + 5))
PYSTUB
REG_OVER="{\"github_board\":\"$WORK/stub_overshoot.py\"}"
BATCH="$(sqlite3 "$FXE/releases.db" "SELECT count(*) FROM work_events;")"
[ "$BATCH" -gt 0 ] || bad "fixture guard: nothing to dispatch — the overshoot guard test would be vacuous"
R5="$(XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG_OVER" \
      python3 "$APP" --root "$FXE" work reconcile 2>&1)"
case "$R5" in
  *"overshoots the dispatched batch"*) ok "an overshooting connector is REFUSED, with the reason named" ;;
  *) bad "overshoot was not refused: $R5" ;;
esac
CUR="$(sqlite3 "$FXE/releases.db" "SELECT last_event_id FROM connector_cursors WHERE connector='github_board';")"
[ "$CUR" = "0" ] \
  && ok "and its cursor did NOT move — the batch stays replayable" \
  || bad "the cursor advanced to $CUR despite the refusal"
ERRTXT="$(sqlite3 "$FXE/releases.db" "SELECT last_error FROM connector_cursors WHERE connector='github_board';")"
case "$ERRTXT" in
  *overshoot*) ok "the refusal is recorded on the cursor row, not just printed" ;;
  *) bad "no overshoot error persisted (last_error=$ERRTXT)" ;;
esac
# A backwards report is equally a failed run: it would replay events already acknowledged.
XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG" \
  python3 "$APP" --root "$FXE" work reconcile >/dev/null 2>&1
cat > "$WORK/stub_back.py" <<'PYSTUB'
import json, sys
json.load(sys.stdin)
print("advanced_to: 1")
PYSTUB
REG_BACK="{\"github_board\":\"$WORK/stub_back.py\"}"
sqlite3 "$FXE/releases.db" "DELETE FROM connector_cursors WHERE connector='github_board';"
XYZ_DEVICE_CONFIG_PATH=/dev/null python3 "$APP" --root "$FXE" work emit \
  --event pr_merged --gh-number 552 --payload-json '{"pr":559}' >/dev/null 2>&1
sqlite3 "$FXE/releases.db" "INSERT INTO connector_cursors(connector,last_event_id,updated_at) VALUES('github_board',2,'x') ON CONFLICT(connector) DO UPDATE SET last_event_id=2;"
R6="$(XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG_BACK" \
      python3 "$APP" --root "$FXE" work reconcile 2>&1)"
case "$R6" in
  *"does not move the cursor forward"*) ok "a backwards report is refused too, so acknowledged events are not replayed" ;;
  *) bad "a backwards advanced_to was accepted: $R6" ;;
esac

echo "15c. red control — the bounds guard is load-bearing"
# Strip the guard and the same overshoot lands. Without this, 15b would pass against a build
# that never had the check, because a stub COULD legitimately report the batch maximum.
# releases_app.py puts its OWN directory first on sys.path before importing work_connectors, so
# PYTHONPATH cannot shadow the module. Mutate a full copy of utils/py and run the copy's app.
GUARDED="$WORK/wc_guarded"; rm -rf "$GUARDED"; mkdir -p "$GUARDED"
cp -R "$ROOT/utils/py/." "$GUARDED/"
python3 - "$GUARDED/work_connectors/__init__.py" <<'PYMUT'
import io, sys
p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()
anchor = "        elif advanced > batch_max:"
assert anchor in s, "red control found no anchor to mutate — the guard moved; fix this control"
s = s.replace(anchor, "        elif False:", 1)
io.open(p, "w", encoding="utf-8").write(s)
PYMUT
[ $? -eq 0 ] || bad "red control mutation failed"
grep -q "elif False:" "$GUARDED/work_connectors/__init__.py" \
  || bad "red control: the mutation did not land in the copy the app will import"
sqlite3 "$FXE/releases.db" "DELETE FROM connector_cursors WHERE connector='github_board';"
MAXID="$(sqlite3 "$FXE/releases.db" "SELECT max(id) FROM work_events;")"
XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG_OVER" \
  python3 "$GUARDED/releases_app.py" --root "$FXE" work reconcile >/dev/null 2>&1
CUR2="$(sqlite3 "$FXE/releases.db" "SELECT last_event_id FROM connector_cursors WHERE connector='github_board';")"
[ "$CUR2" = "$((MAXID + 5))" ] \
  && ok "red control: without the guard the overshoot IS stored ($CUR2 > $MAXID) — the guard is what stops it" \
  || bad "red control did not reproduce the defect (cursor=$CUR2, expected $((MAXID + 5)))"
sqlite3 "$FXE/releases.db" "DELETE FROM connector_cursors WHERE connector='github_board';"

echo "16. the merge emitter keys on the issue, never the PR"
MC="$ROOT/skills/merge-cleanup/scripts/merge_cleanup.py"
cat > "$WORK/mcprobe.py" <<'PYPROBE'
import sys, os
sys.path.insert(0, os.path.join(os.environ["GH549_ROOT"], "skills", "merge-cleanup", "scripts"))
import merge_cleanup as M
print("linked=%s" % M.linked_issues({"title": "feat: x", "body": "Closes #549 and fixes #402"}))
print("none=%s" % M.linked_issues({"title": "chore", "body": "no refs at all"}))
print("dry=%s" % M.emit_pr_merged(".", {"number": 1, "title": "t", "body": "Closes #1"}, dry_run=True))
PYPROBE
MCOUT="$(GH549_ROOT="$ROOT" python3 "$WORK/mcprobe.py" 2>&1)"
case "$MCOUT" in
  *"linked=[549, 402]"*) ok "a merged PR's closed issues are what get the event" ;;
  *) bad "linked-issue extraction wrong: $MCOUT" ;;
esac
case "$MCOUT" in
  *"none=[]"*) ok "a PR that closes nothing emits nothing — no card for a non-work-item" ;;
  *) bad "a PR with no linked issue still produced one: $MCOUT" ;;
esac
case "$MCOUT" in
  *"dry=0"*) ok "a dry run emits nothing" ;;
  *) bad "dry run emitted an event: $MCOUT" ;;
esac

echo "17. the VENDORED github_board connector, through normal config, offline (impl QA r2)"
# The registry names work_connectors.github_board. Round 2 found the module did not exist, so
# every ordinary configured run failed to import instead of touching a board. This leg drives the
# real vendored connector -- NO XYZ_WORK_CONNECTORS_REGISTRY overlay anywhere -- against the
# offline mock, which is the only path a real user ever takes.
MOCK="$ROOT/utils/py/mock_gh_board.py"
[ -f "$ROOT/utils/py/work_connectors/github_board.py" ] \
  || bad "the registry's github_board module does not exist — every configured run would fail to import"
python3 "$MOCK" --reset --state "$WORK/mock17.json" >/dev/null 2>&1
python3 "$MOCK" --seed  --state "$WORK/mock17.json" >/dev/null 2>&1
cat > "$WORK/board_cfg.json" <<'PYCFG'
{"board_sync": {"project_owner": "noelsaw1", "project_number": 3,
                "repos": ["HiQS-Labs/XYZ-forge"], "status_field": "Status",
                "in_progress": "In progress"},
 "work_connectors": {"github_board": {"enabled": true, "project_owner": "noelsaw1",
                     "project_number": 3, "repos": ["HiQS-Labs/XYZ-forge"],
                     "status_map": {"pr_merged": "Done", "rated": ""}}}}
PYCFG
FXB="$WORK/fx_board"; rm -rf "$FXB"; mkdir -p "$FXB"
( cd "$FXB" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXB/"
sqlite3 "$FXB/releases.db" "DELETE FROM connector_cursors;" 2>/dev/null
XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$APP" --root "$FXB" work emit \
  --event pr_merged --gh-number 405 --payload-json '{"pr":559}' >/dev/null 2>&1
NEV="$(sqlite3 "$FXB/releases.db" "SELECT count(*) FROM work_events WHERE event='pr_merged';")"
[ "$NEV" -gt 0 ] || bad "fixture guard: no pr_merged event to feed the connector — leg 17 would be vacuous"
B4="$(python3 "$MOCK" --dump --state "$WORK/mock17.json" 2>/dev/null | python3 -c "
import json,sys
d=json.load(sys.stdin)
# The mock stores status as an option id under field_values, keyed by the Status field id --
# resolve it back to the column NAME, so this asserts the column and not an opaque id.
f=d.get('fields',{}).get('Status',{})
names={o['id']:o['name'] for o in f.get('options',[])}
it=next((i for i in d.get('items',[]) if i.get('number')==405), None)
print('absent' if it is None else names.get(next(iter((it.get('field_values') or {}).values()), None),'unset'))" 2>/dev/null)"
R17="$(XYZ_DEVICE_CONFIG_PATH="$WORK/board_cfg.json" XYZ_BOARD_SYNC_GH_BIN="$MOCK" \
       XYZ_MOCK_BOARD_STATE="$WORK/mock17.json" XYZ_BOARD_SYNC_STATE_PATH="$WORK/sync17.json" \
       python3 "$APP" --root "$FXB" work reconcile 2>&1)"
case "$R17" in
  *"replayed through event"*) ok "the vendored connector runs from normal config with no registry overlay" ;;
  *) bad "the vendored connector did not complete: $R17" ;;
esac
AFTER="$(python3 "$MOCK" --dump --state "$WORK/mock17.json" 2>/dev/null | python3 -c "
import json,sys
d=json.load(sys.stdin)
# The mock stores status as an option id under field_values, keyed by the Status field id --
# resolve it back to the column NAME, so this asserts the column and not an opaque id.
f=d.get('fields',{}).get('Status',{})
names={o['id']:o['name'] for o in f.get('options',[])}
it=next((i for i in d.get('items',[]) if i.get('number')==405), None)
print('absent' if it is None else names.get(next(iter((it.get('field_values') or {}).values()), None),'unset'))" 2>/dev/null)"
[ "$AFTER" = "Done" ] \
  && ok "and it MOVED THE CARD to the configured column (was '$B4', now '$AFTER')" \
  || bad "the card did not reach the configured column (was '$B4', now '$AFTER')"
CUR17="$(sqlite3 "$FXB/releases.db" "SELECT last_event_id FROM connector_cursors WHERE connector='github_board';")"
[ -n "$CUR17" ] && [ "$CUR17" -gt 0 ] \
  && ok "and its cursor advanced, so the batch is acknowledged" \
  || bad "the cursor did not advance (last_event_id=$CUR17)"
# The column mapping is user config, not code: an empty mapping means 'do not place this one'.
python3 - "$ROOT" <<'PYMAP'
import sys, os
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py"))
from work_connectors.github_board import column_for, DEFAULT_STATUS_MAP
m = dict(DEFAULT_STATUS_MAP); m.update({"pr_merged": "Shipped", "rated": ""})
assert column_for("pr_merged", m) == "Shipped", "a user override did not win"
assert column_for("rated", m) is None, "an empty mapping did not disable the transition"
assert column_for("no_such_event", m) is None, "an unknown event was not skipped"
print("mapping-ok")
PYMAP
[ $? -eq 0 ] \
  && ok "the event -> column mapping is user config: an override wins and an empty value disables it" \
  || bad "the status_map override contract is broken"

echo "18. XYZ_WORK_CONNECTORS=0 is a GLOBAL kill switch, not just a hot-path one (impl QA r2)"
# Round 2 found the switch was checked only in _dispatch_work_connectors, so `work reconcile`,
# which calls dispatch() directly, sailed past it. The check now lives in load_connectors, which
# is the one function both paths go through. The stub writes a sentinel file if it ever runs.
cat > "$WORK/stub_sentinel.py" <<'PYSTUB'
import json, os, sys
b = json.load(sys.stdin)
open(os.environ["GH549_SENTINEL"], "w").write("ran")
print("advanced_to: %d" % max(e["id"] for e in b["events"]))
PYSTUB
SENT="$WORK/killswitch.sentinel"; rm -f "$SENT"
sqlite3 "$FXB/releases.db" "DELETE FROM connector_cursors;"
REG_SENT="{\"github_board\":\"$WORK/stub_sentinel.py\"}"
KS="$(GH549_SENTINEL="$SENT" XYZ_WORK_CONNECTORS=0 XYZ_DEVICE_CONFIG_PATH="$WORK/board_cfg.json" \
      XYZ_WORK_CONNECTORS_REGISTRY="$REG_SENT" python3 "$APP" --root "$FXB" work reconcile 2>&1)"
[ ! -f "$SENT" ] \
  && ok "with the switch off, work reconcile spawned NO connector child" \
  || bad "the kill switch did not stop reconcile — the connector ran anyway"
CUR18="$(sqlite3 "$FXB/releases.db" "SELECT count(*) FROM connector_cursors;")"
[ "$CUR18" = "0" ] \
  && ok "and no cursor was written" \
  || bad "the kill switch left $CUR18 cursor row(s) behind"
case "$KS" in
  *"no connectors enabled"*|*"XYZ_WORK_CONNECTORS=0"*) ok "and it says why, rather than looking like an empty config" ;;
  *) bad "the switch was silent about itself: $KS" ;;
esac
# Red control: the same command with the switch OFF must run the child. Without this, leg 18
# would pass against a build where the connector was broken for some entirely other reason.
rm -f "$SENT"
KS2="$(GH549_SENTINEL="$SENT" XYZ_DEVICE_CONFIG_PATH="$WORK/board_cfg.json" \
       XYZ_WORK_CONNECTORS_REGISTRY="$REG_SENT" python3 "$APP" --root "$FXB" work reconcile 2>&1)"
[ -f "$SENT" ] \
  && ok "red control: without the switch the SAME command does run the child — the switch is what stopped it" \
  || bad "red control: the child did not run even with the switch off ($KS2)"

echo "19. two overlapping dispatches are serialized, and a cursor never goes backwards (impl QA r3)"
# perform_write releases the WriterLock BEFORE dispatching, deliberately -- a governance writer
# must not hold it across network time. The consequence round 3 found is that two ledger writes
# can dispatch overlapping batches: A reads cursor 0 and takes event 1, B reads cursor 0 and takes
# events 1 and 2, and whichever finishes LAST decides the board. If A finishes last the card is
# set back to event 1's column and the cursor regresses -- a projection stuck at a stale state.
FXC="$WORK/fx_conc"; rm -rf "$FXC"; mkdir -p "$FXC"
( cd "$FXC" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXC/"
sqlite3 "$FXC/releases.db" "DELETE FROM connector_cursors;"
for N in 601 602; do
  XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$APP" --root "$FXC" work emit \
    --event pr_merged --gh-number "$N" --payload-json '{"pr":559}' >/dev/null 2>&1
done
NCONC="$(sqlite3 "$FXC/releases.db" "SELECT count(*) FROM work_events;")"
[ "$NCONC" -ge 2 ] || bad "fixture guard: need >=2 events to overlap two dispatches, have $NCONC"
cat > "$WORK/stub_slow.py" <<'PYSTUB'
import json, os, sys, time
b = json.load(sys.stdin)
with open(os.environ["GH549_RUNLOG"], "a") as fh:
    fh.write("start %d\n" % os.getpid())
time.sleep(1.5)
with open(os.environ["GH549_RUNLOG"], "a") as fh:
    fh.write("end %d\n" % os.getpid())
print("advanced_to: %d" % max(e["id"] for e in b["events"]))
PYSTUB
REG_SLOW="{\"github_board\":\"$WORK/stub_slow.py\"}"
RUNLOG="$WORK/conc_runs.log"

# Two `work reconcile` processes fired together. Under the lock the second WAITS, then reads the
# cursor the first advanced and finds nothing left -- so exactly ONE child ever runs.
: > "$RUNLOG"
sqlite3 "$FXC/releases.db" "DELETE FROM connector_cursors;"
for i in 1 2; do
  GH549_RUNLOG="$RUNLOG" XYZ_CONNECTOR_LOCK_WAIT_S=15 XYZ_CONNECTOR_WINDOW_S=30 \
    XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG_SLOW" \
    python3 "$APP" --root "$FXC" work reconcile >/dev/null 2>&1 &
done
wait
STARTS="$(grep -c '^start ' "$RUNLOG" 2>/dev/null || echo 0)"
[ "$STARTS" = "1" ] \
  && ok "two concurrent dispatches ran exactly ONE child — the second saw the advanced cursor" \
  || bad "the connector lock did not serialize: $STARTS children ran"
MAXID2="$(sqlite3 "$FXC/releases.db" "SELECT max(id) FROM work_events;")"
CURC="$(sqlite3 "$FXC/releases.db" "SELECT last_event_id FROM connector_cursors WHERE connector='github_board';")"
[ "$CURC" = "$MAXID2" ] \
  && ok "and the cursor finished at the NEWEST event ($CURC), not an older batch's" \
  || bad "the cursor finished at $CURC, expected $MAXID2"

# Red control: without the lock the SAME two commands both dispatch the same batch.
GUARD2="$WORK/wc_nolock"; rm -rf "$GUARD2"; mkdir -p "$GUARD2"
cp -R "$ROOT/utils/py/." "$GUARD2/"
python3 - "$GUARD2/work_connectors/__init__.py" <<'PYMUT2'
import io, sys
p = sys.argv[1]
s = io.open(p, encoding="utf-8").read()
anchor = "                fcntl.flock(self.fh.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)"
assert anchor in s, "red control found no flock call to remove — the lock moved; fix this control"
s = s.replace(anchor, "                pass  # lock removed by the red control", 1)
io.open(p, "w", encoding="utf-8").write(s)
PYMUT2
[ $? -eq 0 ] || bad "red control mutation failed"
grep -q "lock removed by the red control" "$GUARD2/work_connectors/__init__.py" \
  || bad "red control: the mutation did not land in the copy the app will import"
: > "$RUNLOG"
sqlite3 "$FXC/releases.db" "DELETE FROM connector_cursors;"
for i in 1 2; do
  GH549_RUNLOG="$RUNLOG" XYZ_CONNECTOR_LOCK_WAIT_S=15 XYZ_CONNECTOR_WINDOW_S=30 \
    XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG_SLOW" \
    python3 "$GUARD2/releases_app.py" --root "$FXC" work reconcile >/dev/null 2>&1 &
done
wait
STARTS2="$(grep -c '^start ' "$RUNLOG" 2>/dev/null || echo 0)"
[ "$STARTS2" -ge 2 ] \
  && ok "red control: without the lock BOTH dispatches ran the same batch ($STARTS2 children) — the lock is what stops it" \
  || bad "red control did not reproduce the overlap ($STARTS2 children)"

# The cursor is monotonic in the store itself, independent of the lock — the second line of
# defence, so an out-of-order persist can never re-deliver acknowledged events.
sqlite3 "$FXC/releases.db" "DELETE FROM connector_cursors;"
python3 - "$ROOT" "$FXC/releases.db" <<'PYMONO'
import sys, os
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py"))
import work_connectors as W
db = sys.argv[2]
W._persist(db, {"github_board": (9, None)}, "t1")
W._persist(db, {"github_board": (4, None)}, "t2")   # an older batch persisting late
import sqlite3
c = sqlite3.connect(db)
got = c.execute("SELECT last_event_id FROM connector_cursors WHERE connector='github_board'").fetchone()[0]
assert got == 9, "cursor regressed to %s" % got
print("monotonic-ok")
PYMONO
[ $? -eq 0 ] \
  && ok "a late older persist cannot lower the cursor (9 stays 9)" \
  || bad "the cursor is not monotonic — an older batch lowered it"
sqlite3 "$FXC/releases.db" "DELETE FROM connector_cursors;"

echo
echo "GH-549 work-state event stream: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
