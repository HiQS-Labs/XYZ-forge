"""GH-1191 probe battery for the claude-desktop task-sync planner (fixture snapshots only)."""
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
def stamp(dt): return dt.astimezone().strftime("%m-%d")
def row(sid, title, ago_h=2, archived=False, running=False, **extra):
    r = {"sessionId": sid, "title": title, "isArchived": archived, "isRunning": running,
         "lastActivityAt": iso(NOW - timedelta(hours=ago_h))}
    r.update(extra); return r
def snap(name, sessions, captured=None):
    p = BASE / f"{name}.json"
    p.write_text(json.dumps({"captured_at": time.time() if captured is None else captured, "sessions": sessions}))
    return str(p)
def run(*a):
    r = subprocess.run([sys.executable, str(S), *a], capture_output=True, text=True)
    try: j = json.loads(r.stdout)
    except ValueError: j = None
    return r.returncode, j, r.stderr.strip()
def desk(path, *extra): return run("--ide", "claude-desktop", "--desktop-snapshot", path, "--exclude-thread", SELF, *extra)
def sec(j): return (j or {}).get("ides", {}).get("claude-desktop", {})
def check(name, cond, detail):
    results.append({"probe": name, "pass": bool(cond), "detail": detail})
    print(("PASS " if cond else "FAIL ") + name, "|", json.dumps(detail)[:300])

# 1 happy path: one idle titled session -> one proposal, stamp = its own activity date
t = NOW - timedelta(hours=2)
rc, j, _ = desk(snap("happy", [row("local_a", "Fix login bug")]))
ren = sec(j).get("renamed", [])
check("happy-path proposal", rc == 0 and len(ren) == 1 and ren[0]["new"] == f"{stamp(t)} Fix login bug"
      and ren[0]["task_id"] == "local_a" and sec(j).get("error") is None, {"rc": rc, "renamed": ren})

# 2 skips: archived, running, self, outside window -> no proposals, counted as skipped
rc, j, _ = desk(snap("skips", [row("local_arch", "A", archived=True), row("local_run", "B", running=True),
                               row(SELF, "C"), row("local_old", "D", ago_h=48)]))
check("archived/running/self/old skipped", rc == 0 and sec(j).get("renamed") == [] and sec(j).get("skipped") == 4,
      {"rc": rc, "section": sec(j)})

# 3 idempotent: an already-stamped title proposes nothing; a wrong stamp is corrected
rc, j, _ = desk(snap("stamped", [row("local_s", f"{stamp(t)} Fix login bug"), row("local_w", "01-01 Old stamp")]))
ren = sec(j).get("renamed", [])
check("already stamped -> no proposal; stale stamp corrected", rc == 0 and len(ren) == 1
      and ren[0]["task_id"] == "local_w" and ren[0]["new"] == f"{stamp(t)} Old stamp", {"renamed": ren})

# 4 refusals: stale snapshot, missing activity, future activity, duplicate id, bad title
for name, path in [
    ("stale snapshot refused", snap("stale", [row("local_a", "X")], captured=time.time() - 301)),
    ("missing lastActivityAt refused", snap("noact", [{k: v for k, v in row("local_a", "X").items() if k != "lastActivityAt"}])),
    ("future lastActivityAt refused", snap("future", [row("local_a", "X", ago_h=-1)])),
    ("duplicate id refused", snap("dup", [row("local_a", "X"), row("local_a", "Y")])),
    ("non-string title refused", snap("badtitle", [row("local_a", None)])),
]:
    rc, j, _ = desk(path)
    check(name, rc == 3 and sec(j).get("error") and sec(j).get("renamed") == [], {"rc": rc, "error": sec(j).get("error")})

# 5 plan-only guards: --apply, --set-title, missing --exclude-thread -> argparse refusal (exit 2)
p = snap("guard", [row("local_a", "X")])
for name, args in [("--apply refused", ["--apply"]), ("--set-title refused", ["--set-title", "local_a", "T"])]:
    rc, _, err = desk(p, *args)
    check(name, rc == 2 and "plans only" in err, {"rc": rc, "stderr": err[-160:]})
rc, _, err = run("--ide", "claude-desktop", "--desktop-snapshot", p)
check("missing --exclude-thread refused", rc == 2 and "--exclude-thread" in err, {"rc": rc, "stderr": err[-160:]})

# 6 empty inventory: valid zero report (list_sessions excludes the caller)
rc, j, _ = desk(snap("empty", []))
check("empty inventory -> zero report", rc == 0 and sec(j).get("swept") == 0 and sec(j).get("renamed") == []
      and sec(j).get("error") is None, {"rc": rc, "section": sec(j)})

# 7 missing isRunning/isArchived -> conservative skip, not a proposal
r = row("local_m", "No flags"); del r["isRunning"]
rc, j, _ = desk(snap("noflags", [r]))
check("missing isRunning -> skipped", rc == 0 and sec(j).get("renamed") == [] and sec(j).get("skipped") == 1, {"section": sec(j)})

# 8 doctor on a fresh snapshot is green and reports native-tools-required
rc, j, _ = desk(p, "--doctor")
check("doctor green, native-tools-required", rc == 0 and j["ides"]["claude-desktop"]["ok"] is True
      and j["heartbeat"]["state"] == "native-tools-required", {"rc": rc, "report": j})

# 9 existing modes unchanged: claude-cloud planner still plans; help lists every adapter
cloud = BASE / "cloud.json"
cloud.write_text(json.dumps({"captured_at": time.time(), "sessions": [
    {"id": "cse_1", "title": "Cloud task", "environment_kind": "anthropic_cloud",
     "session_status": "SESSION_STATUS_IDLE", "updated_at": iso(t)}], "activity_at": {"cse_1": t.timestamp()}}))
rc, j, _ = run("--ide", "claude-cloud", "--claude-snapshot", str(cloud), "--exclude-thread", "cse_x")
ren = (j or {}).get("ides", {}).get("claude-cloud", {}).get("renamed", [])
check("claude-cloud unchanged", rc == 0 and len(ren) == 1 and ren[0]["new"] == f"{stamp(t)} Cloud task", {"renamed": ren})
r = subprocess.run([sys.executable, str(S), "--help"], capture_output=True, text=True)
check("help lists claude-desktop and --desktop-snapshot", "claude-desktop" in r.stdout and "--desktop-snapshot" in r.stdout, {})
r = subprocess.run([sys.executable, str(S), "--ide", "codex", "--apply"], capture_output=True, text=True)
check("codex plan-only guard unchanged", r.returncode == 2 and "Codex plans only" in r.stderr, {"stderr": r.stderr.strip()[-160:]})

shutil.rmtree(BASE, ignore_errors=True)
(OUT / "probe-results.json").write_text(json.dumps(results, indent=2) + "\n")
passed = sum(r["pass"] for r in results)
print(f"{passed}/{len(results)} probes passed")
sys.exit(0 if passed == len(results) else 1)
