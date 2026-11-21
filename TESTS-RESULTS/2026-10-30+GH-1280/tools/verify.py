#!/usr/bin/env python3
"""GH-1280 contract-review fix verification (F1–F3), real harness, disposable gen4 clones.
Writes ev/09-verify.json. Campaign tooling only."""
import json, os, subprocess, sys, threading, time

SP = os.path.dirname(os.path.realpath(__file__))
PY = "/opt/homebrew/bin/python3"
res, t0 = [], time.time()


def prep(name, *args, extra_canaries=None):
    p = json.loads(subprocess.run([PY, os.path.join(SP, "prep.py"), name] + list(args), capture_output=True,
                                  text=True, check=True).stdout)
    if extra_canaries:
        for f in (p["contract"], p["replay"]):
            c = json.load(open(f)); c["canaries"].update(extra_canaries); json.dump(c, open(f, "w"), indent=1)
    return p


def sup(p, timeout=900):
    r = subprocess.run([PY, os.path.join(SP, "supervisor.py"), "--contract", p["contract"]], cwd=SP,
                       capture_output=True, text=True, timeout=timeout)
    rep = os.path.join(p["out"], "supervisor-report.json")
    return r, (json.load(open(rep)) if os.path.exists(rep) else None)


def record(name, ok, detail):
    res.append({"check": name, "pass": bool(ok), "detail": detail, "t": round(time.time() - t0, 1)})
    print(("PASS " if ok else "FAIL ") + name, flush=True)


# F1: natural real-harness budget exit; the watcher must write its own report and sweep
p = prep("v1", "--wall", "300", "--max", "100", "--batch", "25", "--streak", "100000")
r, rep = sup(p)
record("F1 real run reaches budget, watcher reports and sweeps",
       r.returncode == 0 and rep and rep["events"] == 100 and not rep["survivors_after_sweep"] and not rep["canaries_moved"],
       {"rc": r.returncode, "stderr": r.stderr[-400:], "report": rep and {k: rep[k] for k in (
           "stop_reason", "events", "gen4_rc", "swept_pids", "survivors_after_sweep", "canaries_moved", "per_target")}})

# F3a: invalid baseline refuses launch
p = prep("v2", "--wall", "60", "--max", "50", "--batch", "25", "--streak", "100000",
         extra_canaries={"missing_dep": "test -e %s/does-not-exist" % SP})
r, rep = sup(p, timeout=60)
record("F3 invalid baseline refuses launch", r.returncode == 3 and "invalid canary baseline" in r.stderr
       and not os.path.exists(os.path.join(p["out"], "telemetry.jsonl")), {"rc": r.returncode, "stderr": r.stderr[-300:]})

# F3b: an observation that becomes invalid mid-run stops the run at the next launch
flag = os.path.join(SP, "v3-flag")
open(flag, "w").write("present\n")
p = prep("v3", "--wall", "300", "--max", "400", "--batch", "25", "--streak", "100000",
         extra_canaries={"flag_present": "test -e %s" % flag})
box = {}
th = threading.Thread(target=lambda: box.update(out=sup(p)))
th.start()
tel = os.path.join(p["out"], "telemetry.jsonl")
while not (os.path.exists(tel) and sum(1 for _ in open(tel)) >= 10):
    time.sleep(0.5)
os.remove(flag)
at = sum(1 for _ in open(tel))
th.join()
r, rep = box["out"]
evs = [json.loads(l) for l in open(tel)]
ran_after = sum(1 for e in evs[at:] if e["exit_code"] != 125)
record("F3 invalid mid-run observation stops the run",
       rep and "CANARY VIOLATION" in rep["stop_reason"] and "flag_present" in rep["stop_reason"] and ran_after <= 1
       and not rep["survivors_after_sweep"],
       {"events_at_removal": at, "executed_after": ran_after, "report": rep and {k: rep[k] for k in (
           "stop_reason", "events", "gated_events", "survivors_after_sweep")}})

# F2: slow canary (8 s) near the deadline; discovery processes must end before the discovery deadline
p = prep("v4", "--wall", "75", "--max", "10000", "--batch", "25", "--streak", "100000", "--reserve", "30",
         "--total", "120", extra_canaries={"slow": "sleep 8; echo slow"})
r, rep = sup(p, timeout=300)
ok = rep and rep["discovery_processes_ended_epoch"] <= rep["discovery_deadline"] and not rep["survivors_after_sweep"]
record("F2 slow canary: discovery ends before its deadline",
       ok, rep and {"stop_reason": rep["stop_reason"], "events": rep["events"], "gated": rep["gated_events"],
                    "ended_minus_deadline_s": round(rep["discovery_processes_ended_epoch"] - rep["discovery_deadline"], 1),
                    "watcher_stop_minus_launch_s": round(rep["watcher_stop_epoch"] - rep["launch_epoch"], 1),
                    "survivors": rep["survivors_after_sweep"]})

# F2: replay gate honours the total deadline reserve (v4 total 120 s, replay reserve 300 s → already refused)
c = json.load(open(p["replay"]))
r = subprocess.run(["/usr/bin/sandbox-exec", "-f", p["profile"], PY, os.path.join(SP, "supervisor.py"), "--gate", p["replay"],
                    "--", "-c", "print('ran')"], capture_output=True, text=True)
record("F2 replay refused inside the total-deadline reserve", r.returncode == 125 and "total deadline" in r.stderr,
       {"rc": r.returncode, "stderr": r.stderr[-200:]})

json.dump({"elapsed_s": round(time.time() - t0, 1), "checks": res}, open(os.path.join(SP, "ev", "09-verify.json"), "w"), indent=1)
print("all pass" if all(x["pass"] for x in res) else "SOME CHECKS FAILED")
