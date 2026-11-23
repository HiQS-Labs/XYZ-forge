#!/usr/bin/env python3
"""GH-1280 campaign setup: write a sandbox profile, gate contract and gen4 target list for one
sandbox root. Campaign tooling only (no suite, no production code).

usage: prep.py NAME --wall S --max N --batch B --streak K [--quiet-batches Q] [--stub] [--seed S]
  writes SP/sb-NAME/{home,tmp}, SP/profile-NAME.sb, SP/contract-NAME.json,
         SP/contract-NAME-replay.json, SP/targets-NAME.json, SP/out-NAME/
"""
import argparse, json, os

SP = os.path.dirname(os.path.realpath(__file__))
TASK = "/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30"
PRIMARY = "/Users/noelsaw/Documents/GH Repos/XYZ-forge"
PY = "/opt/homebrew/bin/python3"


def git(repo, args):
    return 'git -C "%s" --no-optional-locks %s' % (repo, args)


CANARIES = {
    "primary_head": git(PRIMARY, "rev-parse HEAD"),
    "primary_status": git(PRIMARY, "status --porcelain"),
    "primary_config": git(PRIMARY, "config --local --list"),
    "primary_ledger": 'shasum "%s/releases.db"' % PRIMARY,
    "task_head": git(TASK, "rev-parse HEAD"),
    "task_status": git(TASK, "status --porcelain"),
    "task_config": git(TASK, "config --local --list"),
    "canary_file": 'shasum "%s/canary/canary.txt"' % SP,
}
SWEEP = ["harness\\.py factory-primitive", "gen4_campaign\\.py", "gh1280/profile-"]

TRACK_A = [  # name, base argv after `factory-primitive`
    ("fp-help", ["--help"]),
    ("fp-genman", ["generate-manifest", "--output", "temp/factory-primitive/ate-smoke/manifest.json"]),
    ("fp-status", ["--run-root", "temp/factory-primitive/fz", "status"]),
    ("fp-init", ["--run-root", "temp/factory-primitive/fz", "init", "--daily-cap", "1", "--max-call-cost", "0"]),
]


def profile(root):
    return ("(version 1)\n(allow default)\n(deny network*)\n(deny file-write*)\n"
            '(allow file-write* (subpath "%s") (literal "/dev/null") (literal "/dev/zero")'
            ' (literal "/dev/tty") (literal "/dev/dtracehelper") (subpath "/dev/fd"))\n' % root)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("name")
    ap.add_argument("--wall", type=int, required=True)
    ap.add_argument("--max", type=int, required=True)
    ap.add_argument("--batch", type=int, required=True)
    ap.add_argument("--streak", type=int, required=True)
    ap.add_argument("--quiet-batches", type=int)
    ap.add_argument("--corpus-cap", type=int, default=100)
    ap.add_argument("--total", type=int, help="total window seconds from launch (discovery + postprocessing)")
    ap.add_argument("--reserve", type=int, default=0, help="watcher stops this many seconds before the discovery deadline")
    ap.add_argument("--seed", type=int, default=1280)
    ap.add_argument("--stub", help="sleep seconds for a stub target (supervisor controls)")
    a = ap.parse_args()
    root = os.path.join(SP, "sb-" + a.name)
    out = os.path.join(SP, "out-" + a.name)
    for d in (root, os.path.join(root, "home"), os.path.join(root, "tmp"), out):
        os.makedirs(d, exist_ok=True)
    prof = os.path.join(SP, "profile-%s.sb" % a.name)
    open(prof, "w").write(profile(root))
    contract = os.path.join(SP, "contract-%s.json" % a.name)
    replay = os.path.join(SP, "contract-%s-replay.json" % a.name)
    head = "/usr/bin/sandbox-exec -f %s %s %s/supervisor.py --gate %%s --" % (prof, PY, SP)
    if a.stub:
        targets = [{"name": "stub", "target": (head % contract) + " %s/stub.py {mutant}" % SP,
                    "base": ["status"], "timeout": 30, "env": {"STUB_SLEEP": a.stub}}]
    else:
        targets = [{"name": n, "target": (head % contract) + " utils/py/harness.py factory-primitive {mutant}",
                    "base": b, "timeout": 30} for n, b in TRACK_A]
    env = {"PATH": "/usr/bin:/bin", "HOME": root + "/home", "TMPDIR": root + "/tmp",
           "PYTHONDONTWRITEBYTECODE": "1", "LANG": "C.UTF-8"}
    tfile = os.path.join(SP, "targets-%s.json" % a.name)
    json.dump(targets, open(tfile, "w"), indent=1)
    c = {"name": a.name, "target_names": [t["name"] for t in targets], "seed": a.seed, "batch": a.batch,
         "streak_stop": a.streak, "quiet_batch_stop": a.quiet_batches, "max_mutations": a.max,
         "canaries": CANARIES, "sweep_patterns": SWEEP, "telemetry": os.path.join(out, "telemetry.jsonl"),
         "stopfile": os.path.join(root, "STOP"), "baseline": os.path.join(root, "baseline.json"),
         "wall_s": a.wall, "total_s": a.total or a.wall, "reserve_s": a.reserve, "replay_reserve_s": 300, "report": os.path.join(out, "supervisor-report.json"),
         "gen4_cwd": TASK, "gen4_env": env, "gen4_log": os.path.join(out, "gen4.log"),
         "gen4_argv": [PY, TASK + "/utils/py/gen4_campaign.py", "--mode", "run", "--no-synth", "--repo", TASK,
                       "--sandbox-root", root, "--out", out, "--targets", tfile, "--max-mutations", str(a.max),
                       "--batch", str(a.batch), "--corpus-cap", str(a.corpus_cap), "--seed", str(a.seed),
                       "--duration", str(a.wall), "--keep-sandbox", "--json"]}
    json.dump(c, open(contract, "w"), indent=1)
    r = dict(c, telemetry=os.path.join(out, "no-discovery-telemetry.jsonl"), stopfile=os.path.join(root, "STOP-replay"),
             streak_stop=None, quiet_batch_stop=None, max_mutations=10 ** 9, mode="replay")
    json.dump(r, open(replay, "w"), indent=1)
    print(json.dumps({"contract": contract, "replay": replay, "targets": tfile, "profile": prof, "root": root, "out": out}))


if __name__ == "__main__":
    main()
