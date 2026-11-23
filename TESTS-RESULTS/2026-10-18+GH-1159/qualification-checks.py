"""GH-1159 manual checks: python3 gh1159_checks.py <new_scripts_dir> <base_scripts_dir> <forge_root>"""
import importlib, json, subprocess, sys, tempfile
from pathlib import Path
new, base, forge = map(Path, sys.argv[1:4])

def load(d, name):
    for m in ("batch_record", "attempt_record", "ledger_merge", "merge_cleanup"):
        sys.modules.pop(m, None)
    sys.path.insert(0, str(d))
    try:
        return importlib.import_module(name)
    finally:
        sys.path.remove(str(d))

def rec(tmp):
    return {"path": str(Path(tmp) / "b.json"), "integration": "development", "issue": None,
            "planned": [{"pos": 1, "pr": 1, "title": "t", "hard": [], "soft": {}, "files": ["a"]},
                        {"pos": 2, "pr": 2, "title": "u", "hard": [], "soft": {}, "files": ["a"]}],
            "outcomes": {"1": {"status": "merged", "merge_oid": "d" * 40},
                         "2": {"status": "merged", "merge_oid": "e" * 40}},
            "landed_order": [1, 2], "sweep_inputs": {}, "verdict": None}

def sweep(mod, primary, *q):
    with tempfile.TemporaryDirectory() as t:
        r = rec(t); mod.finalize_sweep_inputs(r, primary, "ex/ample", *q)
        s = dict(r["sweep_inputs"]); s.pop("computed_at")
        return s, mod.script_block(r)

ok = True
def check(name, cond, detail=""):
    global ok; ok &= bool(cond); print(("PASS " if cond else "FAIL ") + name + (f" — {detail}" if detail else ""))

nb, bb = load(new, "batch_record"), load(base, "batch_record")
nm = load(new, "merge_cleanup")
forge_q = nm.resolve_merge_policy(forge)["qualification"]
print("Forge policy:", json.dumps(nm.resolve_merge_policy(forge)))

# (b) Forge's key reproduces today's sweep inputs and rendered block byte for byte (primary=/tmp → full gate → deferred)
ns, nblk = sweep(nb, Path("/tmp"), forge_q); bs, bblk = sweep(bb, Path("/tmp"))
ns.pop("full_suite")
check("(b) Forge key: sweep_inputs identical to base", ns == bs, ns["command"])
check("(b) Forge key: rendered block identical to base", nblk == bblk)

# (a) foreign-shaped repo, no key: no Forge workflow/gate/branch in the issue
with tempfile.TemporaryDirectory() as t:
    subprocess.run(["git", "init", "-q", t], check=True)
    q = nm.resolve_merge_policy(Path(t))["qualification"]
    fs, fblk = sweep(nb, Path(t), q)
    hits = [w for w in ("wave-reconcile", "validate.sh", "development") if w in fblk]
    check("(a) no key: qualification None", q is None)
    check("(a) no key: rendered block free of Forge tokens", not hits, f"hits={hits}")
    check("(a) no key: says no sweep command declared", nb.NO_SWEEP_COMMAND in fblk)
    # (c) invalid value fails closed
    for bad in ({"full_suite": "sometimes"}, {"full_suite": "none", "sweep_command": "x"},
                {"full_suite": "per_batch", "extra": 1}, {"full_suite": "per_batch", "sweep_command": ""}, "promotion"):
        (Path(t) / ".merge-cleanup.json").write_text(json.dumps({"qualification": bad}))
        try:
            nm.resolve_merge_policy(Path(t)); check(f"(c) fails closed: {bad}", False)
        except ValueError as e:
            check(f"(c) fails closed: {bad}", True, str(e).split(": ", 1)[1][:70])
    # per_batch / none render
    ps, pblk = sweep(nb, Path(t), {"full_suite": "per_batch", "sweep_command": "make test"})
    check("per_batch: throwaway clone + grouped declared command", ps["command"].endswith('cd "$T" && ( make test )') and "Gate:" not in pblk)
    gs, _ = sweep(nb, Path(t), {"full_suite": "per_batch", "sweep_command": "make lint; make test"})
    syn = subprocess.run(["bash", "-n", "-c", gs["command"]], capture_output=True, text=True)
    check("per_batch: `;` command stays grouped and parses", gs["command"].endswith("( make lint; make test )") and syn.returncode == 0, syn.stderr)
    xs, xblk = sweep(nb, Path(t), {"full_suite": "none"})
    check("none: plain statement, no command, no gate", "declares no full suite" in xblk and not xs["command"] and "Gate:" not in xblk)
    os_, oblk = sweep(nb, Path(t), {"full_suite": "promotion"})
    check("promotion w/o command: deferred, says no sweep_command declared", os_["deferred"] and "declares no `sweep_command`" in oblk and "wave-reconcile" not in oblk)

# Red control: Forge's file without the key → deferred command disappears
with tempfile.TemporaryDirectory() as t:
    data = json.loads((forge / ".merge-cleanup.json").read_text()); data.pop("qualification")
    (Path(t) / ".merge-cleanup.json").write_text(json.dumps(data))
    rs, rblk = sweep(nb, Path(t), nm.resolve_merge_policy(Path(t))["qualification"])
    check("red control: key dropped → no wave-reconcile command", "wave-reconcile" not in rblk and not rs["command"])

# Adjacent path: an OLD persisted record (pre-GH-1159 sweep_inputs) renders exactly as base did
with tempfile.TemporaryDirectory() as t:
    r = rec(t); bb.finalize_sweep_inputs(r, Path("/tmp"), "ex/ample")
    check("old record renders unchanged", nb.script_block(r) == bb.script_block(r))
print("ALL PASS" if ok else "SOME FAILED"); sys.exit(0 if ok else 1)
