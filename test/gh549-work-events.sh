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
# A two-party readiness barrier (impl QA r4). Without it the red control could pass by scheduling
# luck: if the second process is not scheduled until the first has already persisted its advance,
# it sees the new cursor and runs no child even with the lock removed, and the red assertion fails
# spuriously. Here each child announces arrival and waits for a peer, so the overlap the control
# claims to observe is FORCED rather than hoped for. A child that waits alone (the serialized
# case, where the second never gets this far) simply times out and proceeds -- that path is the
# positive assertion, which wants exactly one child.
bar = os.environ.get("GH549_BARRIER")
if bar:
    with open(bar, "a") as fh:
        fh.write("%d\n" % os.getpid())
    deadline = time.monotonic() + float(os.environ.get("GH549_BARRIER_WAIT", "6"))
    while time.monotonic() < deadline:
        try:
            if len(open(bar).read().split()) >= 2:
                break
        except Exception:
            pass
        time.sleep(0.05)
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
STARTS="$(grep -c '^start ' "$RUNLOG" 2>/dev/null | head -1)"; STARTS="${STARTS:-0}"
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
BARRIER="$WORK/conc_barrier"; : > "$BARRIER"
sqlite3 "$FXC/releases.db" "DELETE FROM connector_cursors;"
for i in 1 2; do
  GH549_RUNLOG="$RUNLOG" GH549_BARRIER="$BARRIER" GH549_BARRIER_WAIT=8 \
    XYZ_CONNECTOR_LOCK_WAIT_S=15 XYZ_CONNECTOR_WINDOW_S=40 \
    XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG_SLOW" \
    python3 "$GUARD2/releases_app.py" --root "$FXC" work reconcile >/dev/null 2>&1 &
done
wait
STARTS2="$(grep -c '^start ' "$RUNLOG" 2>/dev/null | head -1)"; STARTS2="${STARTS2:-0}"
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

echo "20. the connector lock fails CLOSED, and --reset is inside it (impl QA r4)"
# r4 graded the old fail-open fallback High: a lock we cannot take used to dispatch anyway, which
# silently re-enabled the round-3 race on exactly the paths nobody exercises. Point the lock at a
# path that cannot be created and assert the batch is DEFERRED, not dispatched unserialized.
: > "$RUNLOG"
sqlite3 "$FXC/releases.db" "DELETE FROM connector_cursors;"
NOLOCKDIR="$WORK/nolock"; rm -rf "$NOLOCKDIR"; mkdir -p "$NOLOCKDIR"
cp "$FXC/releases.db" "$NOLOCKDIR/releases.db"
python3 - "$ROOT" "$NOLOCKDIR/releases.db" "$WORK/stub_slow.py" "$RUNLOG" <<'PYFAILCLOSED'
import os, sys
root, db, stub, runlog = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
sys.path.insert(0, os.path.join(root, "utils", "py"))
os.environ["GH549_RUNLOG"] = runlog
os.environ["XYZ_WORK_CONNECTORS_REGISTRY"] = '{"github_board": "%s"}' % stub
import work_connectors as W
# A lock path that cannot be opened: its parent is a FILE, so open() raises ENOTDIR.
blocker = db + "-blocked"
open(blocker, "w").write("x")
real = W._ConnectorLock          # captured BEFORE the rebind, or the subclass recurses into itself
class Blocked(real):
    def __init__(self, db_path):
        real.__init__(self, db_path)
        self.path = os.path.join(blocker, "impossible.lock")
W._ConnectorLock = Blocked
try:
    out = W.dispatch(db, "t", connectors={"github_board": {"enabled": True}}, window_s=20)
finally:
    W._ConnectorLock = real
assert out == {}, "an unopenable lock still dispatched: %r" % (out,)
print("fail-closed-ok")
PYFAILCLOSED
[ $? -eq 0 ] \
  && ok "a lock that cannot be opened DEFERS the batch instead of dispatching unserialized" \
  || bad "the lock failed open — the round-3 race is reachable again"
STARTS3="$(grep -c '^start ' "$RUNLOG" 2>/dev/null | head -1)"; STARTS3="${STARTS3:-0}"
[ "$STARTS3" = "0" ] \
  && ok "and no connector child ran at all under the unopenable lock" \
  || bad "$STARTS3 child(ren) ran despite the lock being unavailable"
NLC="$(sqlite3 "$NOLOCKDIR/releases.db" "SELECT count(*) FROM connector_cursors;" 2>/dev/null)"
[ "$NLC" = "0" ] \
  && ok "and no cursor moved, so the batch stays replayable" \
  || bad "the deferred batch still wrote $NLC cursor row(s)"

# --reset now happens inside the lock, so "replay from zero" cannot be undone by an in-flight
# dispatch persisting its advance after the delete.
sqlite3 "$FXC/releases.db" "DELETE FROM connector_cursors;"
XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG" \
  python3 "$APP" --root "$FXC" work reconcile >/dev/null 2>&1
PRE="$(sqlite3 "$FXC/releases.db" "SELECT last_event_id FROM connector_cursors WHERE connector='github_board';")"
[ -n "$PRE" ] && [ "$PRE" -gt 0 ] || bad "fixture guard: cursor not advanced before the reset probe"
RS="$(XYZ_DEVICE_CONFIG_PATH="$WORK/recon_cfg.json" XYZ_WORK_CONNECTORS_REGISTRY="$REG" \
      python3 "$APP" --root "$FXC" work reconcile --reset 2>&1)"
case "$RS" in
  *"replayed through event"*) ok "--reset still replays from zero with the delete inside the lock" ;;
  *) bad "--reset stopped replaying after the lock change: $RS" ;;
esac

echo "21. work backfill — projects existing ledger state, idempotent, through the one seam (GH-564)"
FXD="$WORK/fx_backfill"; rm -rf "$FXD"; mkdir -p "$FXD"
( cd "$FXD" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXD/"
appd() { XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$APP" --root "$FXD" "$@"; }
# One row per mapping cell. Built through the verbs, never by SQL.
for N in 9911 9912 9913 9914 9915; do
  appd roadmap add --issue-num $N --issue-url "https://example.invalid/$N" --title "cell $N" \
       --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
done
appd roadmap update --issue-num 9911 --section "Completed" >/dev/null 2>&1
appd roadmap update --issue-num 9912 --status-marker "🚧" >/dev/null 2>&1
appd roadmap rate   --issue-num 9913 --rated 10/20/30/40 >/dev/null 2>&1
appd roadmap update --issue-num 9915 --section "Deferred · vision" --status-marker "🚧" >/dev/null 2>&1
CELLS="$(sqlite3 "$FXD/releases.db" "SELECT gh_number||':'||section||':'||status_marker FROM roadmap_items WHERE gh_number IN ('9911','9912','9913','9914','9915') ORDER BY gh_number;")"
case "$CELLS" in
  *"9911:Completed:🆕"*"9915:Deferred"*) ok "fixture rows built through the verbs, one per mapping cell" ;;
  *) bad "fixture guard: mapping cells not as intended: $CELLS" ;;
esac
# 21a — dry-run writes nothing.
EV0="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM work_events;")"
RC0="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM op_receipts;")"
DRY="$(appd work backfill --dry-run 2>&1)"
EV1="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM work_events;")"
RC1="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM op_receipts;")"
[ "$EV0" = "$EV1" ] && [ "$RC0" = "$RC1" ] \
  && ok "21a dry-run: zero events and zero receipts written" \
  || bad "21a dry-run wrote (events $EV0->$EV1, receipts $RC0->$RC1)"
case "$DRY" in *"would emit"*"0 written"*) ok "21a dry-run prints the plan and says 0 written" ;; *) bad "21a dry-run output: $DRY" ;; esac
# 21a red: strip the dry-run return in a copy → it writes.
DRYC="$WORK/app_nodry"; rm -rf "$DRYC"; mkdir -p "$DRYC"; cp -R "$ROOT/utils/py/." "$DRYC/"
python3 - "$DRYC/releases_app.py" <<'PYMUT'
import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
a='            print("dry-run: %d row(s), %d would emit, 0 written"'
assert s.count(a)==1, "21a red: backfill dry-run anchor must be unique"
i=s.index(a); j=s.rfind("        if args.dry_run:\n", 0, i)
assert j>0 and i-j<200, "21a red: the if is not right above the print"
s=s[:j]+"        if False:\n"+s[j+len("        if args.dry_run:\n"):]
io.open(p,"w",encoding="utf-8").write(s)
PYMUT
[ $? -eq 0 ] || bad "21a red control mutation failed"
FXD2="$WORK/fx_backfill_red"; rm -rf "$FXD2"; cp -R "$FXD" "$FXD2"
XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$DRYC/releases_app.py" --root "$FXD2" work backfill --dry-run >/dev/null 2>&1
EVR="$(sqlite3 "$FXD2/releases.db" "SELECT count(*) FROM work_events;")"
[ "$EVR" -gt "$EV0" ] && ok "21a red: without the dry-run return, --dry-run DOES write ($EV0 -> $EVR)" \
                       || bad "21a red control did not reproduce (events $EV0 -> $EVR)"
# 21b — the mapping, per cell.
appd work backfill >/dev/null 2>&1
bf_latest() { sqlite3 "$FXD/releases.db" "SELECT event FROM work_events WHERE gh_number=$1 AND payload LIKE '%\"source\": \"backfill\"%' ORDER BY id DESC LIMIT 1;"; }
[ "$(bf_latest 9911)" = "completed" ] && ok "21b Completed/🆕 -> completed (section wins; NOT pr_merged)" || bad "21b 9911 got '$(bf_latest 9911)'"
[ "$(bf_latest 9912)" = "in_flight" ] && ok "21b 🚧 -> in_flight" || bad "21b 9912 got '$(bf_latest 9912)'"
[ "$(bf_latest 9913)" = "rated" ]     && ok "21b rated 🆕 -> rated" || bad "21b 9913 got '$(bf_latest 9913)'"
[ "$(bf_latest 9914)" = "parked" ]    && ok "21b unrated 🆕 -> parked" || bad "21b 9914 got '$(bf_latest 9914)'"
[ -z "$(bf_latest 9915)" ]            && ok "21g Deferred + 🚧 -> skipped (Deferred is checked first)" || bad "21g 9915 emitted '$(bf_latest 9915)'"
PM="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM work_events WHERE event='pr_merged' AND payload LIKE '%backfill%';")"
[ "$PM" = "0" ] && ok "21b backfill never emits pr_merged" || bad "21b backfill emitted $PM pr_merged event(s)"
# 21g red: reorder the copy so Completed/marker run before the Deferred check.
MAPC="$WORK/app_map"; rm -rf "$MAPC"; mkdir -p "$MAPC"; cp -R "$ROOT/utils/py/." "$MAPC/"
python3 - "$MAPC/releases_app.py" <<'PYMUT'
import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
a='    if sec.lower().startswith("deferred"):\n        return None\n    if sec.lower().startswith("completed"):\n        return "completed"\n'
assert a in s, "21g red: precedence anchor missing"
s=s.replace(a,'    if sec.lower().startswith("completed"):\n        return "completed"\n    if marker == "\\U0001F6A7":\n        return "in_flight"\n    if sec.lower().startswith("deferred"):\n        return None\n',1)
io.open(p,"w",encoding="utf-8").write(s)
PYMUT
[ $? -eq 0 ] || bad "21g red control mutation failed"
FXD3="$WORK/fx_backfill_map"; rm -rf "$FXD3"; cp -R "$FXD" "$FXD3"
XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$MAPC/releases_app.py" --root "$FXD3" work backfill >/dev/null 2>&1
R9915="$(sqlite3 "$FXD3/releases.db" "SELECT event FROM work_events WHERE gh_number=9915 ORDER BY id DESC LIMIT 1;")"
[ "$R9915" = "in_flight" ] && ok "21g red: with the order swapped, Deferred/🚧 DOES emit in_flight — the order is load-bearing" \
                            || bad "21g red did not reproduce (got '$R9915')"
# 21c — second run emits zero.
EVA="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM work_events;")"
OUT2="$(appd work backfill 2>&1 | tail -1)"
EVB="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM work_events;")"
[ "$EVA" = "$EVB" ] && ok "21c a second backfill emits zero ($OUT2)" || bad "21c second run emitted $((EVB-EVA)) ($OUT2)"
# 21c red: strip the suppression in the copy → duplicates.
IDC="$WORK/app_noidem"; rm -rf "$IDC"; mkdir -p "$IDC"; cp -R "$ROOT/utils/py/." "$IDC/"
python3 - "$IDC/releases_app.py" <<'PYMUT'
import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
a='unless_latest_in=(event,), only_source="backfill")'
assert a in s, "21c red: suppression anchor missing"; s=s.replace(a,')',1)
s=s.replace('_emit_work_event(root, conn, event, gh, payload,\n                                 )','_emit_work_event(root, conn, event, gh, payload)',1)
io.open(p,"w",encoding="utf-8").write(s)
PYMUT
[ $? -eq 0 ] || bad "21c red control mutation failed"
python3 -m py_compile "$IDC/releases_app.py" || bad "21c red: mutated copy does not compile"
FXD4="$WORK/fx_backfill_idem"; rm -rf "$FXD4"; cp -R "$FXD" "$FXD4"
XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$IDC/releases_app.py" --root "$FXD4" work backfill >/dev/null 2>&1
EVD="$(sqlite3 "$FXD4/releases.db" "SELECT count(*) FROM work_events;")"
[ "$EVD" -gt "$EVA" ] && ok "21c red: without the transactional guard a second backfill DUPLICATES ($EVA -> $EVD)" \
                       || bad "21c red did not reproduce ($EVA -> $EVD)"
# 21d — receipts and check.
NBF="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM work_events WHERE payload LIKE '%\"source\": \"backfill\"%';")"
NRC="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM op_receipts WHERE op='work-emit';")"
ORPH21="$(sqlite3 "$FXD/releases.db" "SELECT count(*) FROM work_events w WHERE w.payload LIKE '%backfill%' AND NOT EXISTS (SELECT 1 FROM op_receipts r WHERE r.txn_id = w.txn_id AND r.op = 'work-emit');")"
[ "$NBF" -gt 0 ] && [ "$ORPH21" = "0" ] && ok "21d every backfill event ($NBF) has its own work-emit receipt, joined on txn_id (0 orphans)" \
                                          || bad "21d $ORPH21 of $NBF backfill events have no receipt"
appd check >/dev/null 2>&1 && ok "21d releases check is clean after backfill" || bad "21d check dirty after backfill"
# 21e — two concurrent backfills, exactly one event per row.
FXE2="$WORK/fx_backfill_conc"; rm -rf "$FXE2"; cp -R "$FXD" "$FXE2"
sqlite3 "$FXE2/releases.db" "DROP TRIGGER work_events_no_delete; DELETE FROM work_events WHERE payload LIKE '%backfill%'; CREATE TRIGGER work_events_no_delete BEFORE DELETE ON work_events BEGIN SELECT RAISE(ABORT,'work_events is append-only'); END;" 2>/dev/null
NROWS="$(sqlite3 "$FXE2/releases.db" "SELECT count(*) FROM roadmap_items WHERE gh_number IS NOT NULL AND gh_number!='' AND section NOT LIKE 'Deferred%';")"
for i in 1 2; do XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$APP" --root "$FXE2" work backfill >/dev/null 2>&1 & done; wait
NBF2="$(sqlite3 "$FXE2/releases.db" "SELECT count(*) FROM work_events WHERE payload LIKE '%\"source\": \"backfill\"%';")"
[ "$NBF2" = "$NROWS" ] && ok "21e two concurrent backfills produced exactly one event per row ($NBF2 = $NROWS), not two" \
                        || bad "21e concurrent backfills produced $NBF2 events for $NROWS rows"
# 21e red: move the decision BEFORE perform_write in a copy → duplicates under the same race.
RACE="$WORK/app_race"; rm -rf "$RACE"; mkdir -p "$RACE"; cp -R "$ROOT/utils/py/." "$RACE/"
python3 - "$RACE/releases_app.py" <<'PYMUT'
import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
a='''        if not suppress:
            return
        latest = _latest_event(c, gh_number, only_source=only_source, exclude_source=exclude_source)
        if latest in suppress:
            raise _AlreadyRecorded(latest)'''
assert a in s, "21e red: mutate anchor missing"
s=s.replace(a,'        return',1)
b='''    terminal_set = set(terminal)
'''
assert b in s, "21e red: terminal anchor missing"
s=s.replace(b,'''    terminal_set = set(terminal)
    if suppress:
        _pre = _latest_event(conn, gh_number, only_source=only_source, exclude_source=exclude_source)
        if _pre in suppress:
            raise _AlreadyRecorded(_pre)
        import time as _t; _t.sleep(0.4)
''',1)
io.open(p,"w",encoding="utf-8").write(s)
PYMUT
[ $? -eq 0 ] || bad "21e red control mutation failed"
FXE3="$WORK/fx_backfill_race"; rm -rf "$FXE3"; cp -R "$FXE2" "$FXE3"
sqlite3 "$FXE3/releases.db" "DROP TRIGGER work_events_no_delete; DELETE FROM work_events WHERE payload LIKE '%backfill%'; CREATE TRIGGER work_events_no_delete BEFORE DELETE ON work_events BEGIN SELECT RAISE(ABORT,'work_events is append-only'); END;" 2>/dev/null
for i in 1 2; do XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$RACE/releases_app.py" --root "$FXE3" work backfill >/dev/null 2>&1 & done; wait
NBF3="$(sqlite3 "$FXE3/releases.db" "SELECT count(*) FROM work_events WHERE payload LIKE '%\"source\": \"backfill\"%';")"
[ "$NBF3" -gt "$NROWS" ] && ok "21e red: with the read moved outside the transaction, the race DUPLICATES ($NBF3 > $NROWS)" \
                          || bad "21e red did not reproduce ($NBF3 vs $NROWS)"

echo "22. review_ready from open non-draft PRs, inside reconcile, fail-soft (GH-564)"
WRAP="$ROOT/test/lib/gh-prlist-wrapper.sh"
[ -x "$WRAP" ] || bad "fixture guard: $WRAP missing or not executable"
FXR="$WORK/fx_rr"; rm -rf "$FXR"; mkdir -p "$FXR"
( cd "$FXR" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXR/"
sqlite3 "$FXR/releases.db" "DELETE FROM connector_cursors;" 2>/dev/null
python3 "$MOCK" --reset --state "$WORK/mock22.json" >/dev/null 2>&1; python3 "$MOCK" --seed --state "$WORK/mock22.json" >/dev/null 2>&1
cat > "$WORK/rr_cfg.json" <<'PYCFG'
{"board_sync": {"project_owner": "noelsaw1", "project_number": 3, "repos": ["HiQS-Labs/XYZ-forge"], "status_field": "Status", "in_progress": "In progress"},
 "work_connectors": {"github_board": {"enabled": true, "project_owner": "noelsaw1", "project_number": 3,
                     "repos": ["HiQS-Labs/XYZ-forge"], "status_map": {"review_ready": "Todo"}}}}
PYCFG
prs3() { cat > "$WORK/prs.json" <<'PYJ'
[{"number": 700, "isDraft": false, "title": "feat: x", "body": "Closes #405"},
 {"number": 701, "isDraft": true,  "title": "wip",     "body": "Closes #9902"},
 {"number": 702, "isDraft": false, "title": "chore",   "body": "no linked issue"}]
PYJ
}
prs3
CALLS="$WORK/prlist_calls.log"; : > "$CALLS"
rr() { GH549_PRLIST_JSON="$WORK/prs.json" GH549_PRLIST_CALLS="$CALLS" GH549_MOCK="$MOCK" \
       XYZ_DEVICE_CONFIG_PATH="$WORK/rr_cfg.json" XYZ_BOARD_SYNC_GH_BIN="$WRAP" \
       XYZ_MOCK_BOARD_STATE="${MOCKSTATE:-$WORK/mock22.json}" XYZ_BOARD_SYNC_STATE_PATH="$WORK/sync22.json" "$@"; }
mock_col() { python3 "$MOCK" --dump --state "$1" 2>/dev/null | python3 -c "
import json,sys; d=json.load(sys.stdin); f=d.get('fields',{}).get('Status',{}); names={o['id']:o['name'] for o in f.get('options',[])}
it=next((i for i in d.get('items',[]) if i.get('number')==$2), None)
print('absent' if it is None else names.get(next(iter((it.get('field_values') or {}).values()), None),'unset'))"; }
R22="$(rr python3 "$APP" --root "$FXR" work reconcile 2>&1)"
RR405="$(sqlite3 "$FXR/releases.db" "SELECT event FROM work_events WHERE gh_number=405 ORDER BY id DESC LIMIT 1;")"
[ "$RR405" = "review_ready" ] && ok "22a an open non-draft PR closing #405 emitted review_ready" || bad "22a got '$RR405': $R22"
COL405="$(mock_col "$WORK/mock22.json" 405)"
[ "$COL405" = "Todo" ] && ok "22a and the card reached the configured review_ready column" || bad "22a card column: $COL405"
[ -z "$(sqlite3 "$FXR/releases.db" "SELECT event FROM work_events WHERE gh_number=9902;")" ] && ok "22b a DRAFT PR emitted nothing" || bad "22b draft PR emitted"
[ -z "$(sqlite3 "$FXR/releases.db" "SELECT event FROM work_events WHERE gh_number=702;")" ] && ok "22b a PR closing nothing emitted nothing" || bad "22b closes-nothing PR emitted"
grep -q -- '--repo HiQS-Labs/XYZ-forge' "$CALLS" && ok "22g the scan passed --repo from the connector's identity, not the CWD" || bad "22g no --repo in: $(cat "$CALLS")"
: > "$CALLS"; ( cd "$WORK" && rr python3 "$APP" --root "$FXR" work reconcile >/dev/null 2>&1 )
grep -q -- '--repo HiQS-Labs/XYZ-forge' "$CALLS" && ok "22g ...and still does from a directory with no git checkout" || bad "22g from no-git CWD: $(cat "$CALLS")"
# 22c — idempotent.
N405A="$(sqlite3 "$FXR/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=405 AND event='review_ready';")"
rr python3 "$APP" --root "$FXR" work reconcile >/dev/null 2>&1
N405B="$(sqlite3 "$FXR/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=405 AND event='review_ready';")"
[ "$N405A" = "$N405B" ] && [ "$N405A" = "1" ] && ok "22c a second reconcile emits no second review_ready" || bad "22c review_ready count $N405A -> $N405B"
# 21f — interleave, both directions, on a fresh fixture.
FXI="$WORK/fx_interleave"; rm -rf "$FXI"; mkdir -p "$FXI"
( cd "$FXI" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXI/"; sqlite3 "$FXI/releases.db" "DELETE FROM connector_cursors;" 2>/dev/null
python3 "$MOCK" --reset --state "$WORK/mock21f.json" >/dev/null 2>&1; python3 "$MOCK" --seed --state "$WORK/mock21f.json" >/dev/null 2>&1
prs21f() { cat > "$WORK/prs.json" <<'PYJ'
[{"number": 710, "isDraft": false, "title": "feat: y", "body": "Closes #9920"}]
PYJ
}
rr python3 "$APP" --root "$FXI" roadmap add --issue-num 9920 --issue-url "https://example.invalid/9920" --title "interleave" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
prs21f
MOCKSTATE="$WORK/mock21f.json" rr python3 "$APP" --root "$FXI" work backfill  >/dev/null 2>&1   # 9920 -> parked, source=backfill
MOCKSTATE="$WORK/mock21f.json" rr python3 "$APP" --root "$FXI" work reconcile >/dev/null 2>&1   # 405 -> review_ready (latest non-backfill was None)
SEQ="$(sqlite3 "$FXI/releases.db" "SELECT group_concat(event,',') FROM (SELECT event FROM work_events WHERE gh_number=9920 ORDER BY id);")"
case "$SEQ" in *",review_ready") ok "21f fixture: backfill then reconcile gives ...,review_ready ($SEQ)" ;; *) bad "21f fixture guard: unexpected sequence '$SEQ'" ;; esac
NBI="$(sqlite3 "$FXI/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9920;")"
MOCKSTATE="$WORK/mock21f.json" rr python3 "$APP" --root "$FXI" work backfill  >/dev/null 2>&1   # own latest is unchanged -> must skip
NBI2="$(sqlite3 "$FXI/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9920;")"
[ "$NBI" = "$NBI2" ] && ok "21f backfill after a review_ready does NOT re-emit — it compares against its OWN last projection" || bad "21f backfill re-emitted ($NBI -> $NBI2)"
MOCKSTATE="$WORK/mock21f.json" rr python3 "$APP" --root "$FXI" work reconcile >/dev/null 2>&1   # latest non-backfill is review_ready -> must skip
NBI3="$(sqlite3 "$FXI/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9920;")"
[ "$NBI2" = "$NBI3" ] && ok "21f reconcile after a backfill does NOT re-emit review_ready — it ignores backfill rows" || bad "21f reconcile re-emitted ($NBI2 -> $NBI3)"
# A completed issue with an open PR must stay put.
rr python3 "$APP" --root "$FXI" roadmap add --issue-num 9903 --issue-url "https://example.invalid/9903" --title "done" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
rr python3 "$APP" --root "$FXI" roadmap update --issue-num 9903 --section "Completed" >/dev/null 2>&1
MOCKSTATE="$WORK/mock21f.json" rr python3 "$APP" --root "$FXI" work backfill >/dev/null 2>&1
cat > "$WORK/prs.json" <<'PYJ'
[{"number": 703, "isDraft": false, "title": "late pr", "body": "Closes #9903"}]
PYJ
MOCKSTATE="$WORK/mock21f.json" rr python3 "$APP" --root "$FXI" work reconcile >/dev/null 2>&1
[ -z "$(sqlite3 "$FXI/releases.db" "SELECT event FROM work_events WHERE gh_number=9903 AND event='review_ready';")" ] \
  && ok "21f an open PR against a COMPLETED issue does not pull it back to review_ready" || bad "21f completed issue got review_ready"
# 21f red (i): drop only_source → the mutated backfill sees the global latest (review_ready) and re-emits.
SRC="$WORK/app_nosrc"; rm -rf "$SRC"; mkdir -p "$SRC"; cp -R "$ROOT/utils/py/." "$SRC/"
python3 - "$SRC/releases_app.py" <<'PYMUT'
import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
a='unless_latest_in=(event,), only_source="backfill")'
assert a in s, "21f red(i): only_source anchor missing"; s=s.replace(a,'unless_latest_in=(event,))',1)
io.open(p,"w",encoding="utf-8").write(s)
PYMUT
[ $? -eq 0 ] || bad "21f red(i) mutation failed"
FXR2="$WORK/fx_rr_nosrc"; rm -rf "$FXR2"; cp -R "$FXI" "$FXR2"
BFX="$(sqlite3 "$FXR2/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9920 AND payload LIKE '%backfill%';")"
MOCKSTATE="$WORK/mock21f.json" rr python3 "$SRC/releases_app.py" --root "$FXR2" work backfill >/dev/null 2>&1
BFY="$(sqlite3 "$FXR2/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9920 AND payload LIKE '%backfill%';")"
[ "$BFY" -gt "$BFX" ] && ok "21f red(i): with the global latest, backfill DOES re-emit after review_ready ($BFX -> $BFY) — the ping-pong" \
                       || bad "21f red(i) did not reproduce ($BFX -> $BFY)"
# 21f red (iii): drop exclude_source in reconcile → it re-emits review_ready after a backfill.
EXC="$WORK/app_noexc"; rm -rf "$EXC"; mkdir -p "$EXC"; cp -R "$ROOT/utils/py/." "$EXC/"
python3 - "$EXC/releases_app.py" <<'PYMUT'
import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
a='                                 exclude_source="backfill",\n'
assert a in s, "21f red(iii): exclude_source anchor missing"; s=s.replace(a,'',1)
io.open(p,"w",encoding="utf-8").write(s)
PYMUT
[ $? -eq 0 ] || bad "21f red(iii) mutation failed"
FXR7="$WORK/fx_rr_noexc"; rm -rf "$FXR7"; mkdir -p "$FXR7"
( cd "$FXR7" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXR7/"; sqlite3 "$FXR7/releases.db" "DELETE FROM connector_cursors;" 2>/dev/null
rr python3 "$APP" --root "$FXR7" roadmap add --issue-num 9920 --issue-url "https://example.invalid/9920" --title "interleave" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
prs21f
MOCKSTATE="$WORK/mock21f.json" rr python3 "$APP" --root "$FXR7" work reconcile >/dev/null 2>&1   # review_ready
MOCKSTATE="$WORK/mock21f.json" rr python3 "$APP" --root "$FXR7" work backfill  >/dev/null 2>&1   # rated (backfill) now global latest
RRX="$(sqlite3 "$FXR7/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9920 AND event='review_ready';")"
MOCKSTATE="$WORK/mock21f.json" rr python3 "$EXC/releases_app.py" --root "$FXR7" work reconcile >/dev/null 2>&1
RRY="$(sqlite3 "$FXR7/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9920 AND event='review_ready';")"
[ "$RRY" -gt "$RRX" ] && ok "21f red(iii): with backfill rows visible, reconcile DOES re-emit review_ready ($RRX -> $RRY)" \
                       || bad "21f red(iii) did not reproduce ($RRX -> $RRY)"
# 21f red (ii): drop completed from the suppression set.
SUP="$WORK/app_nosup"; rm -rf "$SUP"; mkdir -p "$SUP"; cp -R "$ROOT/utils/py/." "$SUP/"
python3 - "$SUP/releases_app.py" <<'PYMUT'
import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
a='terminal=("completed", "pr_merged"))'
assert a in s, "21f red(ii): terminal anchor missing"; s=s.replace(a,'terminal=("pr_merged",))',1)
io.open(p,"w",encoding="utf-8").write(s)
PYMUT
[ $? -eq 0 ] || bad "21f red(ii) mutation failed"
FXR3="$WORK/fx_rr_nosup"; rm -rf "$FXR3"; cp -R "$FXI" "$FXR3"
cat > "$WORK/prs.json" <<'PYJ'
[{"number": 703, "isDraft": false, "title": "late pr", "body": "Closes #9903"}]
PYJ
MOCKSTATE="$WORK/mock21f.json" rr python3 "$SUP/releases_app.py" --root "$FXR3" work reconcile >/dev/null 2>&1
[ -n "$(sqlite3 "$FXR3/releases.db" "SELECT event FROM work_events WHERE gh_number=9903 AND event='review_ready';")" ] \
  && ok "21f red(ii): without completed in the suppression set the card IS pulled back" || bad "21f red(ii) did not reproduce"
# 22a/22b red: source mutations.
EVN="$WORK/app_evname"; rm -rf "$EVN"; mkdir -p "$EVN"; cp -R "$ROOT/utils/py/." "$EVN/"
python3 - "$EVN/releases_app.py" <<'PYMUT'
import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
a='_emit_work_event(root, conn, "review_ready", n, {"pr": pr.get("number")},'
assert a in s, "22a red: event-name anchor missing"; s=s.replace(a,'_emit_work_event(root, conn, "updated", n, {"pr": pr.get("number")},',1)
b='        if not isinstance(pr, dict) or pr.get("isDraft"):\n            continue'
assert b in s, "22b red: isDraft anchor missing"; s=s.replace(b,'        if not isinstance(pr, dict):\n            continue',1)
c='        for n in _linked_issues(pr):'
assert c in s, "22b red: linked_issues anchor missing"; s=s.replace(c,'        for n in [pr.get("number")]:',1)
io.open(p,"w",encoding="utf-8").write(s)
PYMUT
[ $? -eq 0 ] || bad "22a/22b red mutation failed"
prs3
FXR4="$WORK/fx_rr_red"; rm -rf "$FXR4"; mkdir -p "$FXR4"
( cd "$FXR4" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXR4/"; sqlite3 "$FXR4/releases.db" "DELETE FROM connector_cursors;" 2>/dev/null
python3 "$MOCK" --reset --state "$WORK/mock22r.json" >/dev/null 2>&1; python3 "$MOCK" --seed --state "$WORK/mock22r.json" >/dev/null 2>&1
MOCKSTATE="$WORK/mock22r.json" rr python3 "$EVN/releases_app.py" --root "$FXR4" work reconcile >/dev/null 2>&1
[ -z "$(sqlite3 "$FXR4/releases.db" "SELECT 1 FROM work_events WHERE gh_number=405 AND event='review_ready';")" ] \
  && ok "22a red: with the event name swapped, 405 does NOT get review_ready" || bad "22a red did not reproduce"
[ -n "$(sqlite3 "$FXR4/releases.db" "SELECT 1 FROM work_events WHERE gh_number=701;")" ] \
  && ok "22b red: without the isDraft filter, the draft PR DOES emit (for its own number, since linked_issues is bypassed in the same copy)" || bad "22b red (draft) did not reproduce"
[ -n "$(sqlite3 "$FXR4/releases.db" "SELECT 1 FROM work_events WHERE gh_number=702;")" ] \
  && ok "22b red: with linked_issues bypassed, the closes-nothing PR DOES emit for its own number" || bad "22b red (linked) did not reproduce"
# 22d — gh fails → reconcile still replays, exit 0.
prs3; : > "$CALLS"
sqlite3 "$FXR/releases.db" "DELETE FROM connector_cursors;"
R22D="$(GH549_PRLIST_RC=1 rr python3 "$APP" --root "$FXR" work reconcile 2>&1)"; RC22D=$?
[ "$RC22D" = "0" ] && ok "22d with gh pr list failing, reconcile exits 0" || bad "22d rc=$RC22D: $R22D"
case "$R22D" in *"review-ready scan skipped"*"exited 1"*) ok "22d ...and says why" ;; *) bad "22d no reason printed: $R22D" ;; esac
case "$R22D" in *"replayed through event"*) ok "22d ...and still replayed" ;; *) bad "22d did not replay: $R22D" ;; esac
# 22f — one emission raises → the other lands, dispatch runs, rc 0. Red: remove the except → rc≠0.
EMF="$WORK/app_emitfail"; rm -rf "$EMF"; mkdir -p "$EMF"; cp -R "$ROOT/utils/py/." "$EMF/"
python3 - "$EMF/releases_app.py" <<'PYMUT'
import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
a='                     exclude_source=None, terminal=()):\n'
assert s.count(a)==1, "22f: emit signature anchor must be unique"
s=s.replace(a, a+'    if gh_number == 9904 and event == "review_ready":\n        raise RuntimeError("injected emission failure for 9904")\n',1)
io.open(p,"w",encoding="utf-8").write(s)
PYMUT
[ $? -eq 0 ] || bad "22f injection failed"
cat > "$WORK/prs.json" <<'PYJ'
[{"number": 704, "isDraft": false, "title": "a", "body": "Closes #9904"},
 {"number": 705, "isDraft": false, "title": "b", "body": "Closes #9905"}]
PYJ
FXR5="$WORK/fx_rr_emitfail"; rm -rf "$FXR5"; mkdir -p "$FXR5"
( cd "$FXR5" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXR5/"; sqlite3 "$FXR5/releases.db" "DELETE FROM connector_cursors;" 2>/dev/null
python3 "$MOCK" --reset --state "$WORK/mock22f.json" >/dev/null 2>&1; python3 "$MOCK" --seed --state "$WORK/mock22f.json" >/dev/null 2>&1
R22F="$(MOCKSTATE="$WORK/mock22f.json" rr python3 "$EMF/releases_app.py" --root "$FXR5" work reconcile 2>&1)"; RC22F=$?
[ "$RC22F" = "0" ] && ok "22f one emission raising: reconcile still exits 0" || bad "22f rc=$RC22F: $R22F"
[ -n "$(sqlite3 "$FXR5/releases.db" "SELECT 1 FROM work_events WHERE gh_number=9905 AND event='review_ready';")" ] \
  && ok "22f ...the OTHER issue's event still landed" || bad "22f 9905 did not land: $R22F"
case "$R22F" in *"GH-9904: FAILED"*) ok "22f ...and the failure was named" ;; *) bad "22f failure not reported: $R22F" ;; esac
CUR22F="$(sqlite3 "$FXR5/releases.db" "SELECT last_event_id FROM connector_cursors WHERE connector='github_board';")"
[ -n "$CUR22F" ] && [ "$CUR22F" -gt 0 ] && ok "22f ...and dispatch still ran (cursor $CUR22F)" || bad "22f dispatch did not run"
python3 - "$EMF/releases_app.py" <<'PYMUT'
import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
a='            except Exception as exc:                  # noqa: BLE001 — one issue must not stop the scan\n'
assert a in s, "22f red: except anchor missing"; s=s.replace(a,'            except _AlreadyRecorded:\n                raise\n            except ():\n',1)
io.open(p,"w",encoding="utf-8").write(s)
PYMUT
[ $? -eq 0 ] || bad "22f red mutation failed"
python3 -m py_compile "$EMF/releases_app.py" || bad "22f red: mutated copy does not compile"
FXR6="$WORK/fx_rr_emitfail_red"; rm -rf "$FXR6"; cp -R "$FXR5" "$FXR6"; sqlite3 "$FXR6/releases.db" "DELETE FROM connector_cursors;"
MOCKSTATE="$WORK/mock22f.json" rr python3 "$EMF/releases_app.py" --root "$FXR6" work reconcile >/dev/null 2>&1; RC22FR=$?
[ "$RC22FR" != "0" ] && ok "22f red: without the per-emission except, the verb FAILS (rc=$RC22FR)" || bad "22f red did not reproduce (rc=0)"
# 22e — kill switch: no gh call at all.
prs3; : > "$CALLS"
XYZ_WORK_CONNECTORS=0 rr python3 "$APP" --root "$FXR" work reconcile >/dev/null 2>&1
[ ! -s "$CALLS" ] && ok "22e XYZ_WORK_CONNECTORS=0: the scan made no gh call" || bad "22e gh was called under the kill switch: $(cat "$CALLS")"
rr python3 "$APP" --root "$FXR" work reconcile >/dev/null 2>&1
[ -s "$CALLS" ] && ok "22e red: without the switch the SAME command calls gh" || bad "22e red: gh not called"

echo "23. completed is a mapped column, user-overridable (GH-564)"
python3 - "$ROOT" <<'PYMAP'
import sys, os
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py"))
from work_connectors.github_board import column_for, DEFAULT_STATUS_MAP
assert column_for("completed", DEFAULT_STATUS_MAP) == "Done", "completed not mapped to Done"
m = dict(DEFAULT_STATUS_MAP); m["completed"] = ""
assert column_for("completed", m) is None, "empty override did not disable completed"
print("ok")
PYMAP
[ $? -eq 0 ] && ok "23 completed -> Done by default; a user's empty override disables it" || bad "23 completed mapping contract broken"
MAPR="$WORK/gb_nocompleted"; rm -rf "$MAPR"; mkdir -p "$MAPR"; cp -R "$ROOT/utils/py/." "$MAPR/"
python3 - "$MAPR/work_connectors/github_board.py" <<'PYMUT'
import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
a='    "completed": "Done",\n'
assert a in s, "23 red: completed anchor missing"; s=s.replace(a,"",1)
io.open(p,"w",encoding="utf-8").write(s)
PYMUT
[ $? -eq 0 ] || bad "23 red mutation failed"
R23="$(python3 - "$MAPR" <<'PYMAP'
import sys, os
sys.path.insert(0, sys.argv[1])
from work_connectors.github_board import column_for, DEFAULT_STATUS_MAP
print("mapped" if column_for("completed", DEFAULT_STATUS_MAP) else "unmapped")
PYMAP
)"
[ "$R23" = "unmapped" ] && ok "23 red: with the key deleted, completed is unmapped — the entry is load-bearing" || bad "23 red did not reproduce ($R23)"


echo "24. the producer-scoped lookup has no row cap (impl QA r1), and every backfill event has ITS OWN receipt"
FXK="$WORK/fx_cap"; rm -rf "$FXK"; mkdir -p "$FXK"
( cd "$FXK" && git init -q . && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init ) >/dev/null 2>&1
cp "$PRISTINE/releases.db" "$PRISTINE/releases.sql" "$FXK/"
appk() { XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$APP" --root "$FXK" "$@"; }
appk roadmap add --issue-num 9930 --issue-url "https://example.invalid/9930" --title "cap" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
appk work backfill >/dev/null 2>&1                                    # one backfill row for 9930
# Bury it under 60 newer non-backfill rows for the same issue, through the real verb.
for i in $(seq 1 60); do appk work emit --event updated --gh-number 9930 --payload-json "{\"n\":$i}" >/dev/null 2>&1; done
DEPTH="$(sqlite3 "$FXK/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9930;")"
[ "$DEPTH" -ge 61 ] || bad "fixture guard: only $DEPTH rows for 9930 — the cap probe would be vacuous"
python3 - "$ROOT" "$FXK/releases.db" <<'PYPROBE'
import sys, os, sqlite3
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py"))
import releases_app as R
c = sqlite3.connect(sys.argv[2])
own = R._latest_event(c, 9930, only_source="backfill")
assert own == "parked", "backfill's own latest hidden behind newer rows: %r" % (own,)
other = R._latest_event(c, 9930, exclude_source="backfill")
assert other == "updated", "exclude view wrong: %r" % (other,)
print("views-ok")
PYPROBE
[ $? -eq 0 ] && ok "24 backfill's own latest is still found under 60 newer rows from another producer" || bad "24 the lookup lost the producer row"
NB0="$(sqlite3 "$FXK/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9930 AND payload LIKE '%backfill%';")"
appk work backfill >/dev/null 2>&1
NB1="$(sqlite3 "$FXK/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9930 AND payload LIKE '%backfill%';")"
[ "$NB0" = "$NB1" ] && ok "24 ...so a backfill after 60 unrelated events still emits nothing" || bad "24 duplicate under depth ($NB0 -> $NB1)"
# Red: reinstate a LIMIT below the depth in a copy → the own-row is hidden and backfill duplicates.
CAPC="$WORK/app_cap"; rm -rf "$CAPC"; mkdir -p "$CAPC"; cp -R "$ROOT/utils/py/." "$CAPC/"
python3 - "$CAPC/releases_app.py" <<'PYMUT'
import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
a='                           ORDER BY id DESC""", (gh_number,))\n    for event, payload in rows:'
assert s.count(a)==1, "24 red: lookup anchor must be unique"
s=s.replace(a,'                           ORDER BY id DESC LIMIT 50""", (gh_number,))\n    for event, payload in rows:',1)
io.open(p,"w",encoding="utf-8").write(s)
PYMUT
[ $? -eq 0 ] || bad "24 red mutation failed"
FXK2="$WORK/fx_cap_red"; rm -rf "$FXK2"; cp -R "$FXK" "$FXK2"
XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$CAPC/releases_app.py" --root "$FXK2" work backfill >/dev/null 2>&1
NB2="$(sqlite3 "$FXK2/releases.db" "SELECT count(*) FROM work_events WHERE gh_number=9930 AND payload LIKE '%backfill%';")"
[ "$NB2" -gt "$NB0" ] && ok "24 red: with LIMIT 50 restored, the own-row is hidden and backfill DUPLICATES ($NB0 -> $NB2)" || bad "24 red did not reproduce ($NB0 -> $NB2)"
# Per-event receipts (impl QA r1 [Should]): every NEW backfill event's txn_id must have its own
# work-emit receipt — a join, not an aggregate count that unrelated receipts could satisfy.
FXP="$WORK/fx_rcpt"; rm -rf "$FXP"; cp -R "$FXD" "$FXP"
BEFORE_IDS="$(sqlite3 "$FXP/releases.db" "SELECT coalesce(max(id),0) FROM work_events;")"
appp() { XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$APP" --root "$FXP" "$@"; }
appp roadmap add --issue-num 9931 --issue-url "https://example.invalid/9931" --title "rcpt" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
appp roadmap add --issue-num 9932 --issue-url "https://example.invalid/9932" --title "rcpt" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
appp work backfill >/dev/null 2>&1
ORPHANS="$(sqlite3 "$FXP/releases.db" "SELECT count(*) FROM work_events w WHERE w.id > $BEFORE_IDS AND w.payload LIKE '%backfill%' AND NOT EXISTS (SELECT 1 FROM op_receipts r WHERE r.txn_id = w.txn_id AND r.op = 'work-emit');")"
NEWBF="$(sqlite3 "$FXP/releases.db" "SELECT count(*) FROM work_events WHERE id > $BEFORE_IDS AND payload LIKE '%backfill%';")"
[ "$NEWBF" -ge 2 ] || bad "fixture guard: expected >=2 new backfill events, got $NEWBF"
[ "$ORPHANS" = "0" ] && ok "24 every one of the $NEWBF new backfill events has its OWN work-emit receipt (join on txn_id)" || bad "24 $ORPHANS backfill event(s) have no receipt of their own"
# Red: a copy that bypasses perform_write and INSERTs the event directly → orphan detected.
BYP="$WORK/app_bypass"; rm -rf "$BYP"; mkdir -p "$BYP"; cp -R "$ROOT/utils/py/." "$BYP/"
python3 - "$BYP/releases_app.py" <<'PYMUT'
import io,sys; p=sys.argv[1]; s=io.open(p,encoding="utf-8").read()
a='''                _emit_work_event(root, conn, event, gh, payload,
                                 unless_latest_in=(event,), only_source="backfill")'''
assert s.count(a)==1, "24 red(bypass): backfill emit anchor must be unique"
s=s.replace(a,'''                conn.execute("INSERT INTO work_events(global_id, repo_id, gh_number, txn_id, event, payload, at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                             (new_gid("wev-"), _repo_id_for_event(conn), gh, "bypass-%d" % gh, event, json.dumps(payload), now_iso()))
                conn.commit()''',1)
io.open(p,"w",encoding="utf-8").write(s)
PYMUT
[ $? -eq 0 ] || bad "24 red(bypass) mutation failed"
FXP2="$WORK/fx_rcpt_red"; rm -rf "$FXP2"; cp -R "$FXD" "$FXP2"
B2="$(sqlite3 "$FXP2/releases.db" "SELECT coalesce(max(id),0) FROM work_events;")"
XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$APP" --root "$FXP2" roadmap add --issue-num 9933 --issue-url "https://example.invalid/9933" --title "rcpt" --created 2026-09-10 --doc-path "PROJECT/1-INBOX/x.md" >/dev/null 2>&1
XYZ_DEVICE_CONFIG_PATH=/dev/null XYZ_WORK_CONNECTORS=0 python3 "$BYP/releases_app.py" --root "$FXP2" work backfill >/dev/null 2>&1
ORPH2="$(sqlite3 "$FXP2/releases.db" "SELECT count(*) FROM work_events w WHERE w.id > $B2 AND w.payload LIKE '%backfill%' AND NOT EXISTS (SELECT 1 FROM op_receipts r WHERE r.txn_id = w.txn_id AND r.op = 'work-emit');")"
[ "$ORPH2" -gt 0 ] && ok "24 red: a copy that bypasses perform_write leaves $ORPH2 receipt-less event(s) — the join catches it" || bad "24 red(bypass) did not reproduce"

echo
echo "GH-549 work-state event stream: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
