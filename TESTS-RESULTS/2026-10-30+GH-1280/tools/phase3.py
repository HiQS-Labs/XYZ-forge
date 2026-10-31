#!/usr/bin/env python3
"""GH-1280 Phase 3: replay and disposition of long-run signals, behind the replay contract gate.

Every replay runs as sandbox-exec(profile-long) -> supervisor --gate contract-long-replay.json ->
harness, in the disposable long clone, so the total-deadline reserve and canaries still apply.
R1 replays the first and last telemetry exemplar of every (target, class) pair; a stateful
mismatch is retried with its batch prefix (gen4 resets the clone per batch, seed = batch).
R2 replays the status-first candidate twice plus its clean control. R3 replays one fp-genman
contamination seed. R4 checks gen4's 234-member "unclassified stderr" cluster against the
supervisor's run-root-guard rule. Writes ev/11-phase3.json. Campaign tooling only."""
import collections, json, os, subprocess, sys, time

SP = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, SP)
from supervisor import classify, signature, EXPECTED  # noqa: E402

PY = "/opt/homebrew/bin/python3"
CLONE = os.path.join(SP, "sb-long", "clone")
HEAD = ["/usr/bin/sandbox-exec", "-f", os.path.join(SP, "profile-long.sb"), PY,
        os.path.join(SP, "supervisor.py"), "--gate", os.path.join(SP, "contract-long-replay.json"), "--",
        "utils/py/harness.py", "factory-primitive"]
t0 = time.time()


def reset():
    subprocess.run(["git", "-C", CLONE, "reset", "-q", "--hard"], check=True)
    subprocess.run(["git", "-C", CLONE, "clean", "-fdq"], check=True)
    subprocess.run(["rm", "-rf", os.path.join(CLONE, "temp", "factory-primitive")], check=True)


def run(args):
    r = subprocess.run(HEAD + args, cwd=CLONE, capture_output=True, text=True, timeout=60,
                       env={"PATH": "/usr/bin:/bin", "HOME": os.path.join(SP, "sb-long", "home"),
                            "TMPDIR": os.path.join(SP, "sb-long", "tmp"), "PYTHONDONTWRITEBYTECODE": "1",
                            "LANG": "en_US.UTF-8"})
    if r.returncode == 125:
        raise SystemExit("replay gate refused: " + r.stderr.strip()[-300:])
    return r.returncode, r.stdout, r.stderr


def mutant(e):
    a = e["extra"]["argv"]
    return a[a.index("factory-primitive") + 1:]


evs = [json.loads(l) for l in open(os.path.join(SP, "out-long", "telemetry.jsonl"))]
by_seed = collections.defaultdict(list)
for e in evs:
    by_seed[e["extra"]["seed"]].append(e)
targets = json.load(open(os.path.join(SP, "targets-long.json")))
seed0 = json.load(open(os.path.join(SP, "contract-long.json")))["seed"]
tname = lambda e: targets[(e["extra"]["seed"] - seed0 - 1) % len(targets)]["name"]

out = {"R1": [], "R2": None, "R3": None, "R4": None}

# R1: first and last exemplar per (target, class)
groups = collections.OrderedDict()
for e in evs:
    k = (tname(e), classify(e["exit_code"], e["extra"].get("stderr_sample", "")))
    groups.setdefault(k, []).append(e)
for (t, cls), members in groups.items():
    for e in {id(x): x for x in (members[0], members[-1])}.values():
        reset()
        rc, so, se = run(mutant(e))
        got = classify(rc, se)
        row = {"target": t, "class": cls, "seed": e["extra"]["seed"], "index": e["extra"]["index"],
               "mutant": mutant(e), "recorded_rc": e["exit_code"], "rc": rc, "class_replayed": got,
               "sig_match": signature(t, rc, got, se) == signature(t, e["exit_code"], cls, e["extra"].get("stderr_sample", "")),
               "with_prefix": False}
        if (rc, got) != (e["exit_code"], cls):  # stateful: replay its batch prefix first
            reset()
            for p in by_seed[e["extra"]["seed"]]:
                if p["extra"]["index"] >= e["extra"]["index"]:
                    break
                run(mutant(p))
            rc, so, se = run(mutant(e))
            got = classify(rc, se)
            row.update(rc=rc, class_replayed=got, with_prefix=True,
                       sig_match=signature(t, rc, got, se) == signature(t, e["exit_code"], cls, e["extra"].get("stderr_sample", "")))
        row["match"] = (rc, got) == (e["exit_code"], cls)
        out["R1"].append(row)
        print(("OK   " if row["match"] else "DIFF ") + "%s %s seed %s idx %s%s" % (
            t, cls, row["seed"], row["index"], " (prefix)" if row["with_prefix"] else ""), flush=True)

# R2: status-first candidate, twice, plus clean control
R = ["--run-root", "temp/factory-primitive/c1"]
seqs = []
for label, steps in [("status-first #1", ["status", "init", "tick"]), ("status-first #2", ["status", "init", "tick"]),
                     ("clean control", ["init", "tick"])]:
    reset()
    rcs = []
    for s in steps:
        a = R + ([s, "--daily-cap", "1", "--max-call-cost", "0"] if s == "init" else [s, "--slot", "1"] if s == "tick" else [s])
        rc, so, se = run(a)
        rcs.append({"step": s, "rc": rc, "stderr_tail": se.strip()[-200:]})
    seqs.append({"label": label, "steps": rcs})
out["R2"] = {"sequences": seqs,
             "reproduced": all([x["rc"] for x in s["steps"]] == [0, 2, 1] for s in seqs[:2]) and [x["rc"] for x in seqs[2]["steps"]] == [0, 0]}
reset()
rc, so, se = run(R + ["status"])
out["R2"]["state_db_created_by_status"] = os.path.exists(os.path.join(CLONE, "temp/factory-primitive/c1/instances/C/state.db"))
print("R2 reproduced=%s db_created=%s" % (out["R2"]["reproduced"], out["R2"]["state_db_created_by_status"]), flush=True)

# R3: fp-genman writes its --output where told (contamination seed 12810, "NaN")
e = next(x for x in by_seed[12810] if "NaN" in mutant(x))
reset()
rc, so, se = run(mutant(e))
st = subprocess.run(["git", "-C", CLONE, "status", "--porcelain"], capture_output=True, text=True).stdout.split("\n")
out["R3"] = {"mutant": mutant(e), "rc": rc, "porcelain": [x for x in st if x], "stderr_tail": se.strip()[-200:]}
print("R3 rc=%s porcelain=%s" % (rc, out["R3"]["porcelain"]), flush=True)

# R4: gen4's unclassified rc=2 cluster vs the supervisor's run-root-guard rule
rr = [e for e in evs if e["exit_code"] == 2 and classify(2, e["extra"].get("stderr_sample", "")) == "run-root-guard"]
out["R4"] = {"run_root_guard_events": len(rr), "gen4_cluster_members": 234,
             "all_match_rule": all("run root must stay under" in e["extra"]["stderr_sample"] for e in rr)}
print("R4 %s" % out["R4"], flush=True)

reset()
out["elapsed_s"] = round(time.time() - t0, 1)
json.dump(out, open(os.path.join(SP, "ev", "11-phase3.json"), "w"), indent=1)
print("R1 %d/%d match" % (sum(r["match"] for r in out["R1"]), len(out["R1"])))
