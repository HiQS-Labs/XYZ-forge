#!/usr/bin/env python3
"""GH-1280 smoke step 3: required controls. Writes ev/03-controls.json. Campaign tooling only."""
import json, os, subprocess, sys, threading, time

SP = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, SP)
import supervisor as sup  # noqa: E402

PY = "/opt/homebrew/bin/python3"
CLONE = os.path.join(SP, "sb-ctl", "clone")
HP = ["utils/py/harness.py", "factory-primitive"]
results, t0 = [], time.time()


def run(argv, cwd=CLONE, timeout=60, env=None):
    e = dict(os.environ, PYTHONDONTWRITEBYTECODE="1", **(env or {}))
    r = subprocess.run(argv, cwd=cwd, capture_output=True, text=True, timeout=timeout, env=e)
    return {"argv": argv, "rc": r.returncode, "stdout": r.stdout[-1500:], "stderr": r.stderr[-1500:]}


def record(name, ok, expect, steps):
    results.append({"control": name, "pass": bool(ok), "expect": expect, "steps": steps,
                    "t": round(time.time() - t0, 1)})
    print(("PASS " if ok else "FAIL ") + name, flush=True)


# (a) known-good
s = [run([PY] + HP + ["--run-root", "temp/factory-primitive/gh1280/good", "init", "--daily-cap", "1", "--max-call-cost", "0"]),
     run([PY] + HP + ["--run-root", "temp/factory-primitive/gh1280/good", "tick", "--slot", "1"])]
record("known-good init+tick", s[0]["rc"] == 0 and s[1]["rc"] == 0, "rc 0, rc 0", s)

# (b) known-invalid
s = [run([PY] + HP + ["--run-root", "../outside", "status"])]
record("known-invalid run root", s[0]["rc"] == 2 and "run root must stay under" in s[0]["stderr"]
       and not os.path.exists(os.path.join(SP, "sb-ctl", "outside")), "rc 2 run-root refusal, nothing created", s)

# (c) idempotence oracle: witnessed red, then green
red_cmd = "%s -c \"import random; open('temp/factory-primitive/gh1280/idem-red.txt','a').write(str(random.random()))\"" % PY
s = [run([PY, "utils/py/domain_oracles.py", "--mode", "idempotence", "--cmd", red_cmd, "--cwd", CLONE, "--repetitions", "3", "--json"])]
red_ok = s[0]["rc"] == 1
s += [run([PY] + HP + ["--run-root", "temp/factory-primitive/gh1280/idem", "init", "--daily-cap", "1", "--max-call-cost", "0"]),
      run([PY] + HP + ["--run-root", "temp/factory-primitive/gh1280/idem", "tick", "--slot", "1"])]
green_cmd = "%s utils/py/harness.py factory-primitive --run-root temp/factory-primitive/gh1280/idem tick --slot 1" % PY
s += [run([PY, "utils/py/domain_oracles.py", "--mode", "idempotence", "--cmd", green_cmd, "--cwd", CLONE, "--repetitions", "3", "--json"])]
record("idempotence oracle red then green", red_ok and s[-1]["rc"] == 0, "red cmd rc 1 (FAIL), repeated completed tick rc 0 (PASS)", s)

# (d) OS sandbox: witnessed red (outside write denied), then green (in-root write succeeds)
ctl = json.load(open(os.path.join(SP, "contract-ctl-replay.json")))
json.dump(sup.canaries(ctl["canaries"]), open(ctl["baseline"], "w"))
wrap = ["/usr/bin/sandbox-exec", "-f", os.path.join(SP, "profile-ctl.sb"), PY, os.path.join(SP, "supervisor.py"), "--gate",
        os.path.join(SP, "contract-ctl-replay.json"), "--"] + HP
outside = os.path.join(SP, "outside-probe", "manifest.json")
s = [run(wrap + ["generate-manifest", "--output", outside])]
red_ok = s[0]["rc"] != 0 and not os.path.exists(os.path.dirname(outside))
s += [run(wrap + ["generate-manifest", "--output", "temp/factory-primitive/ate-smoke/manifest.json"])]
green_ok = s[-1]["rc"] == 0 and os.path.exists(os.path.join(CLONE, "temp/factory-primitive/ate-smoke/manifest.json"))
record("sandbox denies outside write, allows in-root", red_ok and green_ok, "outside: refused, path absent; in-root: rc 0, file exists", s)


# (e) supervisor launch gate + watcher on a stub target
def prep(name, *args):
    return json.loads(subprocess.run([PY, os.path.join(SP, "prep.py"), name] + list(args),
                                     capture_output=True, text=True, check=True).stdout)


p = prep("stub1", "--wall", "300", "--max", "200", "--batch", "25", "--streak", "50", "--stub", "0")
s = [run([PY, os.path.join(SP, "supervisor.py"), "--contract", p["contract"]], cwd=SP, timeout=420)]
evs = [json.loads(l) for l in open(os.path.join(p["out"], "telemetry.jsonl"))]
gated = [i for i, e in enumerate(evs) if e["exit_code"] == 125]
executed = len(evs) - len(gated)
rep = json.load(open(os.path.join(p["out"], "supervisor-report.json")))
ok = (executed == 51 and gated and gated[0] == 51 and all(i >= 51 for i in gated)
      and "no-new-signal" in rep["stop_reason"] and not rep["survivors_after_sweep"])
s.append({"executed": executed, "first_gated_index": gated[0] if gated else None, "gated": len(gated),
          "stop_reason": rep["stop_reason"], "survivors": rep["survivors_after_sweep"]})
record("gate stops exactly at streak 50", ok, "51 executed (1 new + 50 seen), event 52 gated, no survivors", s)

p = prep("stub2", "--wall", "120", "--max", "200", "--batch", "25", "--streak", "100000", "--stub", "0.5")
box = {}
th = threading.Thread(target=lambda: box.update(r=run([PY, os.path.join(SP, "supervisor.py"), "--contract", p["contract"]],
                                                      cwd=SP, timeout=300)))
th.start()
tel = os.path.join(p["out"], "telemetry.jsonl")
while not (os.path.exists(tel) and sum(1 for _ in open(tel)) >= 5):
    time.sleep(0.5)
with open(os.path.join(SP, "canary", "canary.txt"), "a") as fh:
    fh.write("deliberate canary edit (control e-b)\n")
touched = sum(1 for _ in open(tel))
th.join()
rep = json.load(open(os.path.join(p["out"], "supervisor-report.json")))
evs = [json.loads(l) for l in open(tel)]
after = [e for e in evs[touched:] if e["exit_code"] != 125]
ok = "CANARY VIOLATION" in rep["stop_reason"] and len(after) <= 1 and not rep["survivors_after_sweep"]
record("canary edit stops the run", ok, "stop reason CANARY VIOLATION; at most the in-flight case after the edit; no survivors",
       [box.get("r"), {"events_at_edit": touched, "executed_after_edit": len(after), "stop_reason": rep["stop_reason"],
                       "survivors": rep["survivors_after_sweep"], "elapsed_s": rep["elapsed_s"]}])

json.dump({"elapsed_s": round(time.time() - t0, 1), "controls": results}, open(os.path.join(SP, "ev", "03-controls.json"), "w"), indent=1)
print("all pass" if all(r["pass"] for r in results) else "SOME CONTROLS FAILED")
sys.exit(0 if all(r["pass"] for r in results) else 1)
