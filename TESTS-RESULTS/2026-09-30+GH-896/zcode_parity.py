"""A2 probe: unified zcode adapter vs QA'd original on identical copies."""
import json, sqlite3, subprocess, sys, os
from datetime import datetime, timedelta

TS = "skills/3-weekly/task-sync/scripts/task_sync.py"
ORIG = os.environ.get("TASK_SYNC_ZCODE_ORIGINAL")
SEED = os.environ.get("TASK_SYNC_ZCODE_SEED")
if not ORIG or not os.path.isfile(ORIG) or not SEED or not os.path.isfile(SEED):
    sys.exit("Set TASK_SYNC_ZCODE_ORIGINAL and TASK_SYNC_ZCODE_SEED to existing fixture inputs")
PROBE_ROOT = os.path.abspath(os.environ.get("TASK_SYNC_PROBE_ROOT", "temp/task-sync-probes"))
os.makedirs(PROBE_ROOT, exist_ok=True)

def seed(path):
    conn = sqlite3.connect(path)
    now_ms = int(datetime.now().timestamp() * 1000)
    h = lambda n: int((datetime.now().timestamp() - n*3600) * 1000)
    rows = [
        # ws, id, title, overridden, pinned, updated_ms
        ("ws-test", "t1-raw-old",   "Fix the relay driver lock parity", 0, 0, h(24*10)),
        ("ws-test", "t2-stale",     "09-15 stale stamp task",           1, 0, h(3)),
        ("ws-test", "t3-bare",      "09-29",                            1, 0, h(2)),
        ("ws-test", "t4-active",    "Active task needs pin",            1, 0, h(1)),
        ("ws-test", "t5-cron",      "automation owned raw title",       0, 0, h(1), "automation-x"),
    ]
    for r in rows:
        ws, tid, title, ovr, pinned, upd = r[0], r[1], r[2], r[3], r[4], r[5]
        cron = r[6] if len(r) > 6 else None
        conn.execute(
            "INSERT OR REPLACE INTO tasks (workspace_key, workspace_path, task_id, title,"
            " title_overridden, pinned, updated_at, created_at, deleted, archived, meta_json,"
            " searchable_text, cron_automation_id, last_unread_at, mode)"
            " VALUES (?,?,?,?,?,?,?,?,0,0,'{}','',?,0,'build')",
            (ws, "/tmp/test", tid, title, ovr, pinned, upd, now_ms, cron),
        )
    conn.commit(); conn.close()

import shutil
for f in ("a.sqlite", "b.sqlite"):
    p = f"{PROBE_ROOT}/{f}"
    if os.path.exists(p): os.remove(p)
shutil.copy(SEED, f"{PROBE_ROOT}/a.sqlite")
shutil.copy(SEED, f"{PROBE_ROOT}/b.sqlite")
for p in (f"{PROBE_ROOT}/a.sqlite", f"{PROBE_ROOT}/b.sqlite"):
    seed(p)

u = subprocess.run(["python3", TS, "--ide", "zcode", "--zcode-db", f"{PROBE_ROOT}/a.sqlite",
                    "--apply", "--all", "--hours", "9999"], capture_output=True, text=True)
o = subprocess.run(["python3", ORIG, "--db", f"{PROBE_ROOT}/b.sqlite", "--sweep", "--all"],
                   capture_output=True, text=True)
assert u.returncode == 0, u.stderr[-500:]
assert o.returncode == 0, o.stderr[-500:]
uj = json.loads(u.stdout)["ides"]["zcode"]; oj = json.loads(o.stdout)

def state(path):
    conn = sqlite3.connect(path)
    rows = conn.execute("SELECT task_id, title, pinned, title_overridden FROM tasks WHERE workspace_key='ws-test'").fetchall()
    conn.close()
    return {r[0]: (r[1], r[2], r[3]) for r in rows}

sa, sb = state(f"{PROBE_ROOT}/a.sqlite"), state(f"{PROBE_ROOT}/b.sqlite")
checks = []
checks.append(("rename sets identical", {(r['task_id'], r['new']) for r in uj['renamed']} == {(r['task_id'], r['new']) for r in oj['renamed']}))
checks.append(("final title/pinned state identical", {k: v[:2] for k, v in sa.items()} == {k: v[:2] for k, v in sb.items()}))
import sqlite3 as _s
_t2upd = _s.connect(f'{PROBE_ROOT}/a.sqlite').execute("SELECT updated_at FROM tasks WHERE task_id='t2-stale'").fetchone()[0]
from datetime import datetime as _dt
_exp = _dt.fromtimestamp(_t2upd/1000).strftime("%m-%d")
checks.append((f"t2 restamped from its own updated_at ({_exp}), not wall-clock",
               sa['t2-stale'][0].startswith(f"{_exp} stale stamp task")))
checks.append(("t3 bare date untouched", sa['t3-bare'][0] == "09-29"))
checks.append(("t4 pinned by window", sa['t4-active'][1] == 1))
checks.append(("t1 stamped from 10-day-old updated_at, still unpinned",
               sa['t1-raw-old'][0].startswith(datetime.fromtimestamp(sa['t1-raw-old'][0] and __import__('sqlite3').connect(f'{PROBE_ROOT}/a.sqlite').execute("SELECT updated_at FROM tasks WHERE task_id='t1-raw-old'").fetchone()[0]/1000).strftime("%m-%d")) and "Fix the relay driver lock parity" in sa['t1-raw-old'][0]))
checks.append(("t5 cron-owned skipped by both", "t5-cron" not in {r['task_id'] for r in uj['renamed']} and "t5-cron" not in {r['task_id'] for r in oj['renamed']}))
checks.append(("needs_summary lists t1 (raw title)", any(r['task_id'] == 't1-raw-old' for r in uj['needs_summary'])))
# idempotency
u2 = subprocess.run(["python3", TS, "--ide", "zcode", "--zcode-db", f"{PROBE_ROOT}/a.sqlite",
                     "--apply", "--all", "--hours", "9999"], capture_output=True, text=True)
u2j = json.loads(u2.stdout)["ides"]["zcode"]
checks.append(("second run: zero writes (idempotent)", len(u2j['renamed']) == 0 and len(u2j['pinned']) == 0))
# -- A1 zcode doctor faults (final-QA r1 Should) -----------------------------
def check(name, ok):
    checks.append((name, ok))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "skills", "3-weekly", "task-sync", "scripts"))
import core as _core
from adapters import zcode as _zc

ad = _zc.ZcodeAdapter(db_path=f"{PROBE_ROOT}/definitely-missing.sqlite", apply=False)
d = ad.doctor()
check("A1 zcode doctor fault: missing store -> red, named message",
      d["ok"] is False and "not found" in d["reds"][0])

import shutil as _sh, sqlite3 as _s2
import os as _os
if _os.path.exists(f"{PROBE_ROOT}/nocol.sqlite"):
    _sh.rmtree(f"{PROBE_ROOT}/nocol.sqlite") if _os.path.isdir(f"{PROBE_ROOT}/nocol.sqlite") else _os.remove(f"{PROBE_ROOT}/nocol.sqlite")
_sh.copy(f"{PROBE_ROOT}/a.sqlite", f"{PROBE_ROOT}/nocol.sqlite")
_c = _s2.connect(f"{PROBE_ROOT}/nocol.sqlite")
_c.execute("CREATE TABLE tasks_drop AS SELECT workspace_key, workspace_path, workspace_identity, task_id, title, title_overridden, pinned, updated_at, deleted, archived, cron_automation_id FROM tasks")
_c.execute("DROP TABLE tasks")
_c.execute("ALTER TABLE tasks_drop RENAME TO tasks")
_c.commit(); _c.close()
ad2 = _zc.ZcodeAdapter(db_path=f"{PROBE_ROOT}/nocol.sqlite", apply=False)
d2 = ad2.doctor()
check("A1 zcode doctor fault: dropped columns -> red, named message",
      d2["ok"] is False and "missing expected columns" in d2["reds"][0])

ad3 = _zc.ZcodeAdapter(db_path=f"{PROBE_ROOT}/a.sqlite", apply=False)
d3 = ad3.doctor()
check("A1 zcode doctor green on healthy copy", d3["ok"] is True and d3.get("journal_mode") == "wal")

fails = 0
for name, ok in checks:
    print(("PASS" if ok else "FAIL"), "-", name)
    fails += 0 if ok else 1
sys.exit(1 if fails else 0)
