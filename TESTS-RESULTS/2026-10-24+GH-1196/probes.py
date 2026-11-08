"""GH-1196 probe battery: claude-desktop pin proposals (fixture snapshots only)."""
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
def row(sid, title="T", ago_h=2, archived=False, running=False, **extra):
    r = {"sessionId": sid, "title": title, "isArchived": archived, "isRunning": running,
         "lastActivityAt": iso(NOW - timedelta(hours=ago_h))}
    r.update(extra); return r
def snap(name, sessions):
    p = BASE / f"{name}.json"; p.write_text(json.dumps({"captured_at": time.time(), "sessions": sessions})); return str(p)
def desk(path, *extra):
    r = subprocess.run([sys.executable, str(S), "--ide", "claude-desktop", "--desktop-snapshot", path,
                        "--exclude-thread", SELF, *extra], capture_output=True, text=True)
    try: j = json.loads(r.stdout)
    except ValueError: j = None
    return r.returncode, ((j or {}).get("ides", {}).get("claude-desktop", {})), r.stderr.strip()
def ids(sec, key): return sorted(x["task_id"] for x in sec.get(key, []))
def check(name, cond, detail):
    results.append({"probe": name, "pass": bool(cond), "detail": detail})
    print(("PASS " if cond else "FAIL ") + name, "|", json.dumps(detail)[:300])

# 1 unpinned active idle session -> one pin proposal (and its rename)
rc, sec, _ = desk(snap("happy", [row("local_a", "Fix bug")]))
check("unpinned active -> pin proposed", rc == 0 and ids(sec, "pinned") == ["local_a"]
      and sec["pinned"][0]["title"] == "Fix bug" and ids(sec, "renamed") == ["local_a"], {"rc": rc, "pinned": sec.get("pinned")})

# 2 pinned:true never proposed; pinned:false and missing key both proposed
rc, sec, _ = desk(snap("pinstates", [row("local_p", pinned=True), row("local_f", pinned=False), row("local_m")]))
check("already pinned skipped; false/missing proposed", rc == 0 and ids(sec, "pinned") == ["local_f", "local_m"], {"pinned": ids(sec, "pinned")})

# 3 running session -> pinned but not renamed
rc, sec, _ = desk(snap("running", [row("local_r", "Live", running=True)]))
check("running -> pin, no rename", rc == 0 and ids(sec, "pinned") == ["local_r"] and sec.get("renamed") == [], {"section": sec})

# 4 archived and self -> neither pin nor rename
rc, sec, _ = desk(snap("excluded", [row("local_x", archived=True), row(SELF)]))
check("archived/self -> no pin, no rename", rc == 0 and sec.get("pinned") == [] and sec.get("renamed") == [] and sec.get("skipped") == 2, {"section": sec})

# 5 outside --pin-hours -> no pin (but still renamed inside --hours)
rc, sec, _ = desk(snap("window", [row("local_o", ago_h=10)]), "--pin-hours", "6")
check("outside pin window -> no pin", rc == 0 and sec.get("pinned") == [] and ids(sec, "renamed") == ["local_o"], {"section": sec})

# 6 --no-pin -> no pins at all
rc, sec, _ = desk(snap("nopin", [row("local_a"), row("local_r", running=True)]), "--no-pin")
check("--no-pin -> no pins", rc == 0 and sec.get("pinned") == [] and ids(sec, "renamed") == ["local_a"], {"section": sec})

# 7 never unpins: --unpin-days still refused
rc, _, err = desk(snap("unpin", [row("local_a")]), "--unpin-days", "3")
check("--unpin-days refused", rc == 2 and "plans only" in err, {"rc": rc, "stderr": err[-160:]})

# 8 running row without activity keeps today's skip: no error, no pin, no rename
r = row("local_run", "B", running=True); del r["lastActivityAt"]
rc, sec, _ = desk(snap("badrunning", [r]))
check("running row missing activity -> skipped, no error", rc == 0 and sec.get("error") is None and sec.get("skipped") == 1
      and sec.get("pinned") == [] and sec.get("renamed") == [], {"rc": rc, "section": sec})

# 9 idle row with bad activity still aborts (unchanged)
r = row("local_i"); r["lastActivityAt"] = "not-a-date"
rc, sec, _ = desk(snap("badidle", [r]))
check("idle row invalid activity -> refused", rc == 3 and "lastActivityAt" in (sec.get("error") or ""), {"rc": rc, "error": sec.get("error")})

# 10 isRunning absent -> skipped for pins and titles; the same row with isRunning:false is eligible
r = row("local_flag", "B"); del r["isRunning"]
rc, sec, _ = desk(snap("noflag", [r]))
rc2, sec2, _ = desk(snap("flagfalse", [row("local_flag", "B")]))
check("isRunning absent -> skipped; false -> eligible", rc == 0 and sec.get("skipped") == 1 and sec.get("pinned") == []
      and sec.get("renamed") == [] and sec.get("error") is None and ids(sec2, "pinned") == ["local_flag"]
      and ids(sec2, "renamed") == ["local_flag"], {"absent": sec, "false": sec2})

# 11 isArchived absent -> skipped for pins and titles; the same row with isArchived:false is eligible
r = row("local_arch_flag", "B"); del r["isArchived"]
rc, sec, _ = desk(snap("noarch", [r]))
rc2, sec2, _ = desk(snap("archfalse", [row("local_arch_flag", "B")]))
check("isArchived absent -> skipped; false -> eligible", rc == 0 and sec.get("skipped") == 1 and sec.get("pinned") == []
      and sec.get("renamed") == [] and sec.get("error") is None and ids(sec2, "pinned") == ["local_arch_flag"]
      and ids(sec2, "renamed") == ["local_arch_flag"], {"absent": sec, "false": sec2})

shutil.rmtree(BASE, ignore_errors=True)
(OUT / "probe-results.json").write_text(json.dumps(results, indent=2) + "\n")
passed = sum(r["pass"] for r in results)
print(f"{passed}/{len(results)} probes passed")
sys.exit(0 if passed == len(results) else 1)
