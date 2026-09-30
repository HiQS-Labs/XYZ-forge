"""A2 probe: unified zcode adapter vs QA'd original on identical copies."""
import json, sqlite3, subprocess, sys, os
from datetime import datetime, timedelta

TS = "skills/3-weekly/task-sync/scripts/task_sync.py"
ORIG = "/Users/noelsaw/Documents/GH Repos/XYZ-forge/utils/zcode/task-stamp/scripts/sweep_tasks.py"

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
    p = f"/tmp/ts-probes/{f}"
    if os.path.exists(p): os.remove(p)
shutil.copy("/tmp/ts-probes/zcode-copy.sqlite", "/tmp/ts-probes/a.sqlite")
shutil.copy("/tmp/ts-probes/zcode-copy.sqlite", "/tmp/ts-probes/b.sqlite")
for p in ("/tmp/ts-probes/a.sqlite", "/tmp/ts-probes/b.sqlite"):
    seed(p)

u = subprocess.run(["python3", TS, "--ide", "zcode", "--zcode-db", "/tmp/ts-probes/a.sqlite",
                    "--apply", "--all", "--hours", "9999"], capture_output=True, text=True)
o = subprocess.run(["python3", ORIG, "--db", "/tmp/ts-probes/b.sqlite", "--sweep", "--all"],
                   capture_output=True, text=True)
assert u.returncode == 0, u.stderr[-500:]
assert o.returncode == 0, o.stderr[-500:]
uj = json.loads(u.stdout)["ides"]["zcode"]; oj = json.loads(o.stdout)

def state(path):
    conn = sqlite3.connect(path)
    rows = conn.execute("SELECT task_id, title, pinned, title_overridden FROM tasks WHERE workspace_key='ws-test'").fetchall()
    conn.close()
    return {r[0]: (r[1], r[2], r[3]) for r in rows}

sa, sb = state("/tmp/ts-probes/a.sqlite"), state("/tmp/ts-probes/b.sqlite")
checks = []
checks.append(("rename sets identical", {(r['task_id'], r['new']) for r in uj['renamed']} == {(r['task_id'], r['new']) for r in oj['renamed']}))
checks.append(("final title/pinned state identical", {k: v[:2] for k, v in sa.items()} == {k: v[:2] for k, v in sb.items()}))
import sqlite3 as _s
_t2upd = _s.connect('/tmp/ts-probes/a.sqlite').execute("SELECT updated_at FROM tasks WHERE task_id='t2-stale'").fetchone()[0]
from datetime import datetime as _dt
_exp = _dt.fromtimestamp(_t2upd/1000).strftime("%m-%d")
checks.append((f"t2 restamped from its own updated_at ({_exp}), not wall-clock",
               sa['t2-stale'][0].startswith(f"{_exp} stale stamp task")))
checks.append(("t3 bare date untouched", sa['t3-bare'][0] == "09-29"))
checks.append(("t4 pinned by window", sa['t4-active'][1] == 1))
checks.append(("t1 stamped from 10-day-old updated_at, still unpinned",
               sa['t1-raw-old'][0].startswith(datetime.fromtimestamp(sa['t1-raw-old'][0] and __import__('sqlite3').connect('/tmp/ts-probes/a.sqlite').execute("SELECT updated_at FROM tasks WHERE task_id='t1-raw-old'").fetchone()[0]/1000).strftime("%m-%d")) and "Fix the relay driver lock parity" in sa['t1-raw-old'][0]))
checks.append(("t5 cron-owned skipped by both", "t5-cron" not in {r['task_id'] for r in uj['renamed']} and "t5-cron" not in {r['task_id'] for r in oj['renamed']}))
checks.append(("needs_summary lists t1 (raw title)", any(r['task_id'] == 't1-raw-old' for r in uj['needs_summary'])))
# idempotency
u2 = subprocess.run(["python3", TS, "--ide", "zcode", "--zcode-db", "/tmp/ts-probes/a.sqlite",
                     "--apply", "--all", "--hours", "9999"], capture_output=True, text=True)
u2j = json.loads(u2.stdout)["ides"]["zcode"]
checks.append(("second run: zero writes (idempotent)", len(u2j['renamed']) == 0 and len(u2j['pinned']) == 0))
fails = 0
for name, ok in checks:
    print(("PASS" if ok else "FAIL"), "-", name)
    fails += 0 if ok else 1
sys.exit(1 if fails else 0)
