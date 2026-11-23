"""GH-1230 probe battery: claude-desktop titles cover running and old sessions (fixture snapshots only)."""
import json, subprocess, sys, time, shutil
from datetime import datetime, timezone, timedelta
from pathlib import Path

REPO = Path(sys.argv[1]); OUT = Path(sys.argv[2])
S = REPO / "skills/3-weekly/task-sync/scripts/task_sync.py"
BASE = OUT / "fixtures"; shutil.rmtree(BASE, ignore_errors=True); BASE.mkdir(parents=True)
results = []
NOW = datetime.now(timezone.utc)
SELF = "local_self"

def iso(dt): return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"
def stamp(ago_h): return (NOW - timedelta(hours=ago_h)).astimezone().strftime("%m-%d")
def row(sid, title="T", ago_h=2, archived=False, running=False, **extra):
    r = {"sessionId": sid, "title": title, "isArchived": archived, "isRunning": running,
         "lastActivityAt": iso(NOW - timedelta(hours=ago_h))}
    r.update(extra); return r
def snap(name, sessions):
    p = BASE / f"{name}.json"; p.write_text(json.dumps({"captured_at": time.time(), "sessions": sessions})); return str(p)
def desk(path, *extra):
    r = subprocess.run([sys.executable, str(S), "--ide", "claude-desktop", "--desktop-snapshot", path,
                        "--exclude-thread", SELF, "--no-pin", *extra], capture_output=True, text=True)
    try: j = json.loads(r.stdout)
    except ValueError: j = None
    return r.returncode, ((j or {}).get("ides", {}).get("claude-desktop", {})), r.stderr.strip()
def renames(sec): return {x["task_id"]: x["new"] for x in sec.get("renamed", [])}
def check(name, cond, detail):
    results.append({"probe": name, "pass": bool(cond), "detail": detail})
    print(("PASS " if cond else "FAIL ") + name, "|", json.dumps(detail)[:300])

# 1 R3: running row with a wrong stamp -> proposed with its own activity date
rc, sec, _ = desk(snap("running", [row("local_r", "01-01 Live work", running=True)]))
check("running row, wrong stamp -> proposed", rc == 0 and renames(sec) == {"local_r": f"{stamp(2)} Live work"}, {"rc": rc, "section": sec})

# 2 R2: idle row active 3 days ago with a wrong stamp -> proposed with that day's date
rc, sec, _ = desk(snap("old", [row("local_o", "01-01 Old work", ago_h=72)]))
check("3-day-old row, wrong stamp -> proposed", rc == 0 and renames(sec) == {"local_o": f"{stamp(72)} Old work"}, {"rc": rc, "section": sec})

# 3 correct stamp on an old row -> not proposed, but swept
rc, sec, _ = desk(snap("oldok", [row("local_k", f"{stamp(240)} Settled", ago_h=240)]))
check("old row, correct stamp -> not proposed", rc == 0 and sec.get("renamed") == [] and sec.get("swept") == 1, {"rc": rc, "section": sec})

# 4 --hours no longer limits claude-desktop titles
rc, sec, _ = desk(snap("hours", [row("local_h", "Untitled work", ago_h=10)]), "--hours", "1")
check("--hours 1 does not hide a 10h-old row", rc == 0 and renames(sec) == {"local_h": f"{stamp(10)} Untitled work"}, {"rc": rc, "section": sec})

# 5 fail-closed rules unchanged: archived, self, non-boolean running -> skipped
r = row("local_n"); r["isRunning"] = "yes"
rc, sec, _ = desk(snap("excluded", [row("local_x", archived=True), row(SELF), r]))
check("archived/self/non-boolean running -> skipped", rc == 0 and sec.get("renamed") == [] and sec.get("skipped") == 3 and sec.get("error") is None, {"rc": rc, "section": sec})

# 6 running row without activity -> skipped, no error
r = row("local_ra", "B", running=True); del r["lastActivityAt"]
rc, sec, _ = desk(snap("runbad", [r]))
check("running row missing activity -> skipped, no error", rc == 0 and sec.get("skipped") == 1 and sec.get("renamed") == [] and sec.get("error") is None, {"rc": rc, "section": sec})

# 7 idle row with bad activity -> aborts
r = row("local_i"); r["lastActivityAt"] = "not-a-date"
rc, sec, _ = desk(snap("idlebad", [r]))
check("idle row invalid activity -> refused", rc == 3 and "lastActivityAt" in (sec.get("error") or ""), {"rc": rc, "error": sec.get("error")})

# 8 future activity on an idle row still aborts; on a running row it is skipped
r = row("local_f", ago_h=-2)
rc, sec, _ = desk(snap("future", [r]))
r2 = row("local_fr", ago_h=-2, running=True)
rc2, sec2, _ = desk(snap("futurerun", [r2]))
check("future activity: idle refused, running skipped", rc == 3 and rc2 == 0 and sec2.get("skipped") == 1 and sec2.get("renamed") == [], {"idle": [rc, sec.get("error")], "running": sec2})

shutil.rmtree(BASE, ignore_errors=True)
(OUT / "probe-results.json").write_text(json.dumps(results, indent=2) + "\n")
passed = sum(r["pass"] for r in results)
print(f"{passed}/{len(results)} probes passed")
sys.exit(0 if passed == len(results) else 1)
