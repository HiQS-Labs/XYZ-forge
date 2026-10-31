#!/usr/bin/env python3
"""GH-1280 Phase 3 follow-up. (a) Replay fp-genman seed 12994 idx 0-1 from gen4's reset state
(no ignored `temp/`; phase3.py's reset left one behind). (b) Is the clean-control tick rc=1 caused
by the sandbox profile? Same init+tick with and without sandbox-exec, in the disposable long clone.
Writes ev/12-phase3b.json. Campaign tooling only."""
import json, os, subprocess

SP = os.path.dirname(os.path.realpath(__file__))
PY = "/opt/homebrew/bin/python3"
CLONE = os.path.join(SP, "sb-long", "clone")
GATE = ["/usr/bin/sandbox-exec", "-f", os.path.join(SP, "profile-long.sb"), PY, os.path.join(SP, "supervisor.py"),
        "--gate", os.path.join(SP, "contract-long-replay.json"), "--"]
H = ["utils/py/harness.py", "factory-primitive"]
ENV = {"PATH": "/usr/bin:/bin", "HOME": os.path.join(SP, "sb-long", "home"), "TMPDIR": os.path.join(SP, "sb-long", "tmp"),
       "PYTHONDONTWRITEBYTECODE": "1", "LANG": "en_US.UTF-8"}


def reset():
    subprocess.run(["git", "-C", CLONE, "reset", "-q", "--hard"], check=True)
    subprocess.run(["git", "-C", CLONE, "clean", "-fdxq"], check=True)


def run(args, sandbox=True):
    argv = (GATE + H + args) if sandbox else ([PY] + H + args)
    r = subprocess.run(argv, cwd=CLONE, capture_output=True, text=True, timeout=120, env=ENV)
    if r.returncode == 125:
        raise SystemExit("replay gate refused: " + r.stderr[-300:])
    return {"argv": args, "sandbox": sandbox, "rc": r.returncode, "stdout": r.stdout[-300:], "stderr": r.stderr[-400:]}


out = {}
reset()
out["a_genman_12994"] = [run(["generate-manifest", "--output", "temp"]),
                         run(["generate-manifest", "--output", "temp/factory-primitive/ate-smoke/man ifest.json"])]
R = ["--run-root", "temp/factory-primitive/tk"]
for sb in (True, False):
    reset()
    out["b_tick_sandbox_%s" % sb] = [run(R + ["init", "--daily-cap", "1", "--max-call-cost", "0"], sb),
                                    run(R + ["tick", "--slot", "1"], sb)]
reset()
json.dump(out, open(os.path.join(SP, "ev", "12-phase3b.json"), "w"), indent=1)
for k, v in out.items():
    print(k, [(x["rc"], x["stderr"].strip().splitlines()[-1][:120] if x["stderr"].strip() else x["stdout"].strip()[:120]) for x in v])
