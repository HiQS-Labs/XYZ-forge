"""GH-1105 probe battery for the claude / claude-cloud task-sync adapters."""
import json, os, subprocess, sys, time, hashlib, shutil
from datetime import datetime, timezone, timedelta
from pathlib import Path

REPO = Path(sys.argv[1]); OUT = Path(sys.argv[2])
S = REPO / "skills/3-weekly/task-sync/scripts/task_sync.py"
BASE = OUT / "fixtures"; shutil.rmtree(BASE, ignore_errors=True)
results = []

def iso(dt): return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"
NOW = datetime.now(timezone.utc)
def mk(root, sid, recs, proj="-proj"):
    d = root / "projects" / proj; d.mkdir(parents=True, exist_ok=True)
    p = d / f"{sid}.jsonl"
    p.write_text("".join(json.dumps(r) + "\n" for r in recs)); return p
def turn(sid, dt, text="hi"):
    return [{"type": "user", "timestamp": iso(dt), "sessionId": sid, "message": {"role": "user", "content": text}},
            {"type": "assistant", "timestamp": iso(dt + timedelta(seconds=5)), "sessionId": sid, "message": {"content": []}}]
def run(*a):
    r = subprocess.run([sys.executable, str(S), *a], capture_output=True, text=True)
    try: j = json.loads(r.stdout)
    except ValueError: j = None
    return r.returncode, j, r.stderr.strip()
def digest(root): return hashlib.sha256(b"".join(p.read_bytes() for p in sorted((root / "projects").rglob("*")) if p.is_file())).hexdigest()
def check(name, cond, detail):
    results.append({"probe": name, "pass": bool(cond), "detail": detail}); print(("PASS " if cond else "FAIL ") + name, "|", json.dumps(detail)[:300])
def stamp(dt): return dt.astimezone().strftime("%m-%d")

# 1 happy path
r1 = BASE / "happy"; two = NOW - timedelta(hours=20)
p = mk(r1, "s-ai", turn("s-ai", two) + [{"type": "ai-title", "aiTitle": "Fix login bug", "sessionId": "s-ai"}])
os.utime(p, (time.time() - 60, time.time() - 60)); m0 = p.stat().st_mtime_ns; l0 = len(p.read_text().splitlines())
rc, j, _ = run("--ide", "claude", "--claude-root", str(r1))
check("1a dry-run proposes stamp", rc == 0 and j["ides"]["claude"]["renamed"] == [{"task_id": "s-ai", "old": "Fix login bug", "new": f"{stamp(two)} Fix login bug"}], j)
check("1b dry-run writes nothing", len(p.read_text().splitlines()) == l0, l0)
rc, j, _ = run("--ide", "claude", "--claude-root", str(r1), "--apply")
lines = p.read_text().splitlines()
check("1c apply appends exactly one custom-title line", rc == 0 and len(lines) == l0 + 1 and json.loads(lines[-1]) == {"type": "custom-title", "customTitle": f"{stamp(two)} Fix login bug", "sessionId": "s-ai"}, lines[-1])
check("1d mtime preserved", p.stat().st_mtime_ns == m0, [m0, p.stat().st_mtime_ns])
rc, j, _ = run("--ide", "claude", "--claude-root", str(r1), "--apply")
check("1e re-run is a no-op", rc == 0 and j["ides"]["claude"]["renamed"] == [] and len(p.read_text().splitlines()) == l0 + 1, j["ides"]["claude"])

# 2 red controls
rc, j, _ = run("--ide", "claude", "--claude-root", str(BASE / "missing"))
check("2a missing root -> error, exit 3", rc == 3 and "not found" in j["ides"]["claude"]["error"], j["ides"]["claude"]["error"])
r2 = BASE / "reds"
nonl = mk(r2, "s-nonl", turn("s-nonl", two) + [{"type": "ai-title", "aiTitle": "No newline", "sessionId": "s-nonl"}])
nonl.write_text(nonl.read_text().rstrip("\n"))
mk(r2, "s-fresh", turn("s-fresh", NOW - timedelta(minutes=2)) + [{"type": "ai-title", "aiTitle": "Fresh", "sessionId": "s-fresh"}])
mk(r2, "s-run", turn("s-run", two) + [{"type": "ai-title", "aiTitle": "Running", "sessionId": "s-run"}])
mk(r2, "s-agent", turn("s-agent", two) + [{"type": "ai-title", "aiTitle": "Agent", "sessionId": "s-agent"}, {"type": "agent-name", "agentName": "builder", "sessionId": "s-agent"}])
mk(r2, "s-none", turn("s-none", two, "please refactor the parser") + [{"type": "last-prompt", "lastPrompt": "please refactor the parser", "sessionId": "s-none"}])
(r2 / "sessions").mkdir(); (r2 / "sessions" / f"{os.getpid()}.json").write_text(json.dumps({"pid": os.getpid(), "sessionId": "s-run"}))
d0 = digest(r2)
rc, j, _ = run("--ide", "claude", "--claude-root", str(r2), "--apply")
c = j["ides"]["claude"]
check("2b no-newline/fresh/running/agent sessions untouched; no title -> needs_summary", rc == 0 and c["renamed"] == [] and digest(r2) == d0
      and c["needs_summary"] == [{"task_id": "s-none", "workspace_path": "-proj", "summary_source": "please refactor the parser"}], c)
(r2 / "sessions" / "bad.json").write_text("{not json")
rc, j, _ = run("--ide", "claude", "--claude-root", str(r2), "--apply")
check("2c unparseable registry entry -> error, no write", rc == 3 and "registry" in j["ides"]["claude"]["error"] and digest(r2) == d0, j["ides"]["claude"]["error"])
(r2 / "sessions" / "bad.json").unlink()
# changed between read and write: monkeypatch via direct adapter call
sys.path.insert(0, str(S.parent)); import importlib; claude = importlib.import_module("adapters.claude")
r3 = BASE / "race"; pr = mk(r3, "s-race", turn("s-race", two) + [{"type": "ai-title", "aiTitle": "Race", "sessionId": "s-race"}])
a = claude.ClaudeLocalAdapter(root=str(r3), apply=True); orig = a._read
def racing(path):
    info = orig(path)
    with path.open("a") as f: f.write(json.dumps({"type": "system", "sessionId": "s-race"}) + "\n")
    return info
a._read = racing; before = pr.read_text(); rep = a.sweep(hours=24)
check("2d file changed between read and write -> skipped, no title appended", rep["renamed"] == [] and rep["skipped"] == 1 and "custom-title" not in pr.read_text(), rep)
r4 = BASE / "doctor"; mk(r4, "s-nots", [{"type": "ai-title", "aiTitle": "x", "sessionId": "s-nots"}, {"type": "user", "sessionId": "s-nots", "message": {"content": "hi"}}])
rc, j, _ = run("--ide", "claude", "--claude-root", str(r4), "--doctor")
check("2e doctor red names missing timestamp", rc == 3 and any("timestamp" in x for x in j["ides"]["claude"]["reds"]), j["ides"]["claude"])
rc, j, _ = run("--ide", "claude", "--claude-root", str(r1), "--doctor")
check("2f doctor green on valid root; missing sessions/ = nothing running", rc == 0 and j["ides"]["claude"]["ok"], j["ides"]["claude"])

# 3 sidecar
r5 = BASE / "sidecar"; big = [{"type": "custom-title", "customTitle": "Old head title", "sessionId": "s-side"}] + turn("s-side", two)
big += [{"type": "system", "sessionId": "s-side", "pad": "x" * 2000} for _ in range(70)]
ps = mk(r5, "s-side", big + turn("s-side", two + timedelta(minutes=1)))
(ps.parent / "s-side").mkdir(); (ps.parent / "s-side" / "custom-title.json").write_text(json.dumps({"customTitle": "Sidecar title"}))
rc, j, _ = run("--ide", "claude", "--claude-root", str(r5), "--apply")
check("3a tail empty -> sidecar label used and stamped", rc == 0 and j["ides"]["claude"]["renamed"][0]["old"] == "Sidecar title" and j["ides"]["claude"]["renamed"][0]["new"].endswith(" Sidecar title"), j["ides"]["claude"]["renamed"])
rc, j, _ = run("--ide", "claude", "--claude-root", str(r5), "--apply")
check("3b re-run no-op after stamp lands in tail", rc == 0 and j["ides"]["claude"]["renamed"] == [], j["ides"]["claude"])

# set-title
rc, j, _ = run("--ide", "claude", "--claude-root", str(r1), "--set-title", "s-ai", "Reviewed auth PR")
check("4a set-title dry-run stamps with own activity date", rc == 0 and j["ides"]["claude"]["renamed"] == [{"old": f"{stamp(two)} Fix login bug", "new": f"{stamp(two)} Reviewed auth PR"}], j)
rc, j, _ = run("--ide", "claude", "--claude-root", str(r2), "--set-title", "s-run", "x", "--apply")
check("4b set-title refuses a running session", rc == 3 and "running" in j["ides"]["claude"]["error"], j["ides"]["claude"])

# 5 cloud planner
def snap(path, sessions, activity, age=0):
    path.write_text(json.dumps({"captured_at": time.time() - age, "sessions": sessions, "activity_at": activity}))
sess = [{"id": "c-idle", "title": "Docs pass", "environment_kind": "anthropic_cloud", "session_status": "SESSION_STATUS_IDLE", "updated_at": iso(NOW - timedelta(hours=1))},
        {"id": "c-run", "title": "Busy", "environment_kind": "anthropic_cloud", "session_status": "SESSION_STATUS_RUNNING", "updated_at": iso(NOW)},
        {"id": "c-bridge", "title": "Local mirror", "environment_kind": "bridge", "session_status": "SESSION_STATUS_IDLE", "updated_at": iso(NOW)},
        {"id": "c-self", "title": "Heartbeat", "environment_kind": "anthropic_cloud", "session_status": "SESSION_STATUS_IDLE", "updated_at": iso(NOW)}]
sp = BASE / "cloud.json"; BASE.mkdir(exist_ok=True); act = time.time() - 3600
snap(sp, sess, {"c-idle": act})
rc, j, _ = run("--ide", "claude-cloud", "--claude-snapshot", str(sp), "--exclude-thread", "c-self")
c = j["ides"]["claude-cloud"]
check("5a only idle anthropic_cloud sessions proposed (running/bridge/self skipped)", rc == 0 and [x["task_id"] for x in c["renamed"]] == ["c-idle"] and c["skipped"] == 3 and c["execution"] == "native-tools-required", c)
snap(sp, sess, {"c-idle": act}, age=400)
rc, j, _ = run("--ide", "claude-cloud", "--claude-snapshot", str(sp), "--exclude-thread", "c-self")
check("5b stale snapshot refused", rc == 3 and "stale" in j["ides"]["claude-cloud"]["error"], j["ides"]["claude-cloud"]["error"])
snap(sp, sess, {})
rc, j, _ = run("--ide", "claude-cloud", "--claude-snapshot", str(sp), "--exclude-thread", "c-self")
check("5c missing activity aborts", rc == 3 and "activity" in j["ides"]["claude-cloud"]["error"], j["ides"]["claude-cloud"]["error"])
for extra in (["--apply"], ["--set-title", "c-idle", "x"]):
    rc, j, err = run("--ide", "claude-cloud", "--claude-snapshot", str(sp), "--exclude-thread", "c-self", *extra)
    check(f"5d claude-cloud refuses {extra[0]}", rc == 2 and "plans only" in err, err[-160:])
rc, j, err = run("--ide", "claude-cloud", "--exclude-thread", "c-self")
check("5e claude-cloud requires --claude-snapshot", rc == 2 and "--claude-snapshot" in err, err[-160:])

# 6 existing behavior
rc, j, err = run("--ide", "codex", "--exclude-thread", "x")
check("6a codex guard unchanged", rc == 2 and "Codex requires --codex-snapshot" in err, err[-160:])
rc, j, err = run("--ide", "codex", "--codex-snapshot", "x", "--exclude-thread", "x", "--apply")
check("6b codex plan-only guard unchanged", rc == 2 and "Codex plans only" in err, err[-160:])
rc, j, _ = run("--ide", "zcode", "--zcode-db", str(BASE / "nope.sqlite"))
check("6c zcode path unchanged (missing DB -> named error)", rc == 3 and "zcode: task index DB not found" in j["ides"]["zcode"]["error"], j["ides"]["zcode"]["error"])

(OUT / "probe-results.json").write_text(json.dumps(results, indent=2) + "\n")
shutil.rmtree(BASE)
print(f"{sum(r['pass'] for r in results)}/{len(results)} PASS")
sys.exit(0 if all(r["pass"] for r in results) else 1)
