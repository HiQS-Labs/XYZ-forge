#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh648-l1.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$ROOT/utils/py" GH648_MODULE="$ROOT/utils/py/turn_diagnostics.py" GH648_WORK="$WORK" python3 <<'PY'
import io, json, os, pathlib, subprocess, sys
from types import SimpleNamespace
from unittest.mock import patch
import turn_diagnostics as td

passed = 0
def check(value, label):
    global passed
    if not value: raise AssertionError(label)
    passed += 1
def check_mutation(oracle, mutant, label):
    green = subprocess.run(
        [sys.executable, "-c", oracle, os.environ["GH648_MODULE"]],
        capture_output=True, text=True,
    )
    check(green.returncode == 0, f"{label}: production oracle passes: {green.stderr}")
    red = subprocess.run(
        [sys.executable, "-c", oracle, str(mutant)],
        capture_output=True, text=True,
    )
    check(red.returncode != 0 and "AssertionError" in red.stderr,
          f"{label}: assertion rejects mutation: {red.stderr}")

def idle_diag():
    d = td.TurnDiagnostics(root_pid=4242)
    d.samples = [(1.0, 0.0, 1), (2.0, 0.0, 1), (3.0, 0.0, 1)]
    return d
def observed_idle(network):
    d = idle_diag()
    d._network_probe_attempted = True
    d._network_state_observed = network
    return d

# New files count as progress even when start() observed an empty baseline.
for kind in ("empty-directory", "missing-transcript"):
    target = pathlib.Path(os.environ["GH648_WORK"]) / kind
    if kind == "empty-directory":
        target.mkdir()
    with patch.object(td.threading.Thread, "start"), \
         patch.object(td, "_descendant_cpu_seconds", return_value=(0.0, 1)), \
         patch.object(td, "_security_dialog_present", return_value=False), \
         patch.object(td, "_network_state", return_value="established") as probe, \
         patch.object(td.time, "monotonic", side_effect=(1.0, 2.0, 3.0, 4.0)):
        d = td.TurnDiagnostics(worktree=str(target), root_pid=4242)
        d.start()
        check(d.mtime_start == 0.0, f"{kind}: real empty baseline")
        d._sample(); d._sample()
        output = target / "output.txt" if target.is_dir() else target
        output.write_text("turn made progress\n")
        d._sample()
        check(d.mtime_last > 0.0, f"{kind}: file creation observed")
        check(d.idle_seconds() == 1.0, f"{kind}: creation resets idle clock")
        check(not probe.called, f"{kind}: progressing turn skips idle probe")
        record = d.termination_record(td.TERMINATION_WALL_CAP)
        check(record["reason"] == td.REASON_SLOW_PROGRESS,
              f"{kind}: wall cap preserves file progress")
        check("worktree-progress=yes" in record["detail"], f"{kind}: honest detail")

stub = pathlib.Path(os.environ["GH648_WORK"]) / "bin"
stub.mkdir()
lsof = stub / "lsof"
lsof.write_text('''#!/bin/sh
case "$GH648_LSOF_MODE" in
 established) printf 'nhttps://api.example.test:443\n'; exit 0;;
 none) exit 1;;
 error) printf 'lsof: probe failed\n' >&2; exit 1;;
 *) exit 2;;
esac
''')
lsof.chmod(0o755)
os.environ["PATH"] = str(stub) + os.pathsep + os.environ.get("PATH", "")
for mode, expected in (("established", "established"), ("none", "none"), ("error", "unclassified"), ("fail", "unclassified")):
    os.environ["GH648_LSOF_MODE"] = mode
    check(td._network_state(4242) == expected, f"lsof {mode} maps to {expected}")

real_run, real_tree_pids = td.subprocess.run, td._tree_pids
with patch.object(td, "_tree_pids", side_effect=OSError("process discovery failed")):
    state = td._network_state(4242)
check(state == "unclassified", "process discovery failure is best-effort")
record = observed_idle(state).termination_record(td.TERMINATION_IDLE_KILL)
check(record["reason"] == td.REASON_UNCLASSIFIED and record["exit_code"] == 7,
      "process discovery failure preserves exit 7")
for failure in (FileNotFoundError("lsof unavailable"),
                subprocess.TimeoutExpired("lsof", 5.0)):
    with patch.object(td, "_tree_pids", return_value=[4242]), \
         patch.object(td.subprocess, "run", side_effect=failure):
        state = td._network_state(4242)
    check(state == "unclassified", f"{type(failure).__name__}: probe fails safely")
    record = observed_idle(state).termination_record(td.TERMINATION_IDLE_KILL)
    check(record["reason"] == td.REASON_UNCLASSIFIED and record["exit_code"] == 7,
          f"{type(failure).__name__}: attribution preserves exit 7")
seen = {}
def capture_run(cmd, **_kwargs):
    seen["cmd"] = cmd
    return SimpleNamespace(returncode=0, stdout=b"nhttps://api.example.test:443\n", stderr=b"")
td._tree_pids = lambda root_pid: [root_pid, 4343, 4444]
td.subprocess.run = capture_run
check(td._network_state(4242) == "established", "descendant probe remains functional")
check(seen["cmd"][seen["cmd"].index("-p") + 1] == "4242,4343,4444",
      "lsof queries root and descendant PIDs")
td.subprocess.run, td._tree_pids = real_run, real_tree_pids

reason, detail = observed_idle("established").classify()
check(reason == td.REASON_IDLE_IN_FLIGHT, "established connection is in-flight")
check("established outbound connection" in detail, "in-flight detail preserves evidence")
check(reason != "timeout-idle-no-progress", "idle trace never overclaims no-progress")
reason, detail = observed_idle("none").classify()
check(reason == td.REASON_IDLE, "successful empty probe is idle-unknown")
check(reason == "timeout-idle-unknown", "idle label is explicit")
check("cause remains unknown" in detail, "idle detail stays honest")
reason, detail = observed_idle("unclassified").classify()
check(reason == td.REASON_UNCLASSIFIED, "probe failure degrades to unclassified")
check("probe failed" in detail, "probe failure is observable")
reason, detail = idle_diag().classify()
check(reason == td.REASON_UNCLASSIFIED, "unattempted probe remains unclassified")
check("never established" in detail, "missing live observation is observable")

records = [td.termination_record(k, "r", "d", observed_at=123.0) for k in
           (td.TERMINATION_IDLE_KILL, td.TERMINATION_WALL_CAP, td.TERMINATION_CHILD_ORPHAN)]
check(len({r["termination"] for r in records}) == 3, "termination kinds differ")
check(all(r["event"] == "turn-termination" for r in records), "event named")
check(all(r["exit_code"] == 7 for r in records), "exit remains 7")
check(all(r["observed_at"] == 123.0 for r in records), "timestamp preserved")
check(td.termination_record("surprise", "r", "d")["termination"] == "unknown", "foreign kind closes")
d = observed_idle("none")
record = d.termination_record(td.TERMINATION_IDLE_KILL, observed_at=456.0)
check(record["reason"] == td.REASON_IDLE, "record classified")
check(record["termination"] == "idle-kill", "record mechanism")
stream = io.StringIO()
emitted = d.emit_termination_record(td.TERMINATION_WALL_CAP, observed_at=789.0, stream=stream)
decoded = json.loads(stream.getvalue())
check(decoded == emitted, "JSON matches return")
check(decoded["termination"] == "wall-cap", "wall cap differs")

# The live sampler, not post-reap classify(), owns the one-shot probe.
probe_calls = []
td._network_state = lambda pid: probe_calls.append(pid) or "established"
d = td.TurnDiagnostics(root_pid=4242)
real_cpu_probe = td._descendant_cpu_seconds
td._descendant_cpu_seconds = lambda _pid: (0.0, 1)
td._security_dialog_present = lambda: False
td._newest_mtime = lambda _root: 0.0
times = iter((1.0, 2.0, 3.0, 4.0))
td.time.monotonic = lambda: next(times)
d._sample(); d._sample(); d._sample(); d._sample()
check(probe_calls == [4242], "idle network probe runs once while tree is live")
check(d.classify()[0] == td.REASON_IDLE_IN_FLIGHT, "cached live probe drives classification")
td._descendant_cpu_seconds = real_cpu_probe

# CPU spent by exited children remains in the cumulative sampled total.
snapshots = iter(({11: 0.0}, {11: 1.0}, {22: 1.0}, {33: 1.0}))
td._descendant_cpu_by_pid = lambda _pid: next(snapshots)
d = td.TurnDiagnostics(root_pid=4242)
times = iter((0.0, 1.0, 2.0, 3.0))
td.time.monotonic = lambda: next(times)
d._sample(); d._sample(); d._sample(); d._sample()
check([sample[1] for sample in d.samples] == [0.0, 1.0, 2.0, 3.0],
      "exited descendants retain their peak CPU")
check(d.cpu_ratio() == 1.0, "short-lived CPU-bound children remain CPU-bound")

# A startup CPU burst followed by a long hang is idle overall, not CPU-bound.
d = observed_idle("none")
d.samples = [(0.0, 0.0, 1), (1.0, 1.0, 1), (100.0, 1.0, 1)]
check(d.cpu_ratio() == 0.01, "CPU ratio uses full observed wall window")
check(d.classify()[0] == td.REASON_IDLE, "startup burst does not mask long idle hang")

source = pathlib.Path(os.environ["GH648_MODULE"]).read_text()
mutated = source.replace('if network == "established":', 'if network == "none":', 1)
check(mutated != source, "mutation changed classifier")
mutant = pathlib.Path(os.environ["GH648_WORK"]) / "turn_diagnostics_mutant.py"
mutant.write_text(mutated)
oracle = '''import importlib.util,sys
s=importlib.util.spec_from_file_location("mutant",sys.argv[1]);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
d=m.TurnDiagnostics(root_pid=1);d.samples=[(1.,0.,1),(2.,0.,1),(3.,0.,1)]
d._network_probe_attempted=True;d._network_state_observed="established"
assert d.classify()[0] == m.REASON_IDLE_IN_FLIGHT
'''
check_mutation(oracle, mutant, "in-flight classification")

tree_mutated = source.replace('pids = ",".join(str(pid) for pid in _tree_pids(root_pid))',
                              'pids = str(root_pid)', 1)
check(tree_mutated != source, "tree mutation changed network probe")
tree_mutant = pathlib.Path(os.environ["GH648_WORK"]) / "turn_diagnostics_tree_mutant.py"
tree_mutant.write_text(tree_mutated)
tree_oracle = '''import importlib.util,sys,types
s=importlib.util.spec_from_file_location("mutant",sys.argv[1]);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
seen={};m._tree_pids=lambda root:[root,2,3]
def run(cmd,**kwargs): seen["cmd"]=cmd;return types.SimpleNamespace(returncode=1,stdout=b"",stderr=b"")
m.subprocess.run=run;m._network_state(1)
assert seen["cmd"][seen["cmd"].index("-p")+1] == "1,2,3"
'''
check_mutation(tree_oracle, tree_mutant, "root-only network probe")

ratio_mutated = source.replace('span = self.samples[-1][0] - t0',
                               'span = 1.0', 1)
check(ratio_mutated != source, "mutation changed CPU denominator")
ratio_mutant = pathlib.Path(os.environ["GH648_WORK"]) / "turn_diagnostics_ratio_mutant.py"
ratio_mutant.write_text(ratio_mutated)
ratio_oracle = '''import importlib.util,sys
s=importlib.util.spec_from_file_location("mutant",sys.argv[1]);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
d=m.TurnDiagnostics(root_pid=1);d.samples=[(0.,0.,1),(1.,1.,1),(100.,1.,1)]
assert d.cpu_ratio() == .01
'''
check_mutation(ratio_oracle, ratio_mutant, "CPU window")

missing_probe_mutated = source.replace('if network is None:', 'if False:', 1)
check(missing_probe_mutated != source, "mutation removed missing-probe guard")
missing_probe_mutant = pathlib.Path(os.environ["GH648_WORK"]) / "turn_diagnostics_missing_probe_mutant.py"
missing_probe_mutant.write_text(missing_probe_mutated)
missing_probe_oracle = '''import importlib.util,sys
s=importlib.util.spec_from_file_location("mutant",sys.argv[1]);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
d=m.TurnDiagnostics(root_pid=1);d.samples=[(1.,0.,1),(2.,0.,1),(3.,0.,1)]
assert d.classify()[0] == m.REASON_UNCLASSIFIED
'''
check_mutation(missing_probe_oracle, missing_probe_mutant, "missing live probe")

pid_peak_mutated = source.replace(
    'self._pid_cpu_peaks[pid] = max(self._pid_cpu_peaks.get(pid, 0.0), seconds)',
    'self._pid_cpu_peaks = {pid: seconds}', 1,
)
check(pid_peak_mutated != source, "mutation removed per-PID CPU retention")
pid_peak_mutant = pathlib.Path(os.environ["GH648_WORK"]) / "turn_diagnostics_pid_peak_mutant.py"
pid_peak_mutant.write_text(pid_peak_mutated)
pid_peak_oracle = '''import importlib.util,sys
s=importlib.util.spec_from_file_location("mutant",sys.argv[1]);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
snapshots=iter(({11:0.},{11:1.},{22:1.},{33:1.}));m._descendant_cpu_by_pid=lambda _pid:next(snapshots)
m._security_dialog_present=lambda:False;m._newest_mtime=lambda _root:0.;times=iter((0.,1.,2.,3.));m.time.monotonic=lambda:next(times)
d=m.TurnDiagnostics(root_pid=1);d._sample();d._sample();d._sample();d._sample()
assert [x[1] for x in d.samples] == [0.,1.,2.,3.]
'''
check_mutation(pid_peak_oracle, pid_peak_mutant, "per-PID CPU retention")

# Run each acceptance oracle on production first, then on a deliberate defect.
# Requiring AssertionError also prevents import/runtime failures counting as red.
acceptance_mutations = (
    ("discovery-failure",
     '    try:\n        pids = ",".join(str(pid) for pid in _tree_pids(root_pid))',
     '    pids = ",".join(str(pid) for pid in _tree_pids(root_pid))\n    try:',
     '''def fail(_pid): raise OSError("process discovery failed")
m._tree_pids=fail
try:
    result=m._network_state(1)
except OSError:
    result="escaped"
assert result == "unclassified"
'''),
    ("termination-kinds",
     'kind = termination if termination in TERMINATION_KINDS else TERMINATION_UNKNOWN',
     'kind = TERMINATION_UNKNOWN',
     '''kinds = ("idle-kill", "wall-cap", "child-orphan", "unknown")
records = [m.termination_record(k, "r", "d") for k in kinds]
assert [r["termination"] for r in records] == list(kinds)
assert all(r["exit_code"] == 7 for r in records)
'''),
    ("failed-probe",
     'if network == "unclassified":', 'if False:',
     '''d=m.TurnDiagnostics(root_pid=1)
d.samples=[(1.,0.,1),(2.,0.,1),(3.,0.,1)]
d._network_probe_attempted=True;d._network_state_observed="unclassified"
r=d.termination_record("idle-kill")
assert r["reason"] == m.REASON_UNCLASSIFIED
assert r["exit_code"] == 7
'''),
)
for label, original, replacement, assertions in acceptance_mutations:
    oracle = '''import importlib.util,sys
s=importlib.util.spec_from_file_location("subject",sys.argv[1])
m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
''' + assertions
    check(source.count(original) == 1, f"{label}: mutation has one target")
    mutant = pathlib.Path(os.environ["GH648_WORK"]) / f"{label}.py"
    mutant.write_text(source.replace(original, replacement, 1))
    check_mutation(oracle, mutant, label)
print(f"PASS: {passed} assertions")
PY
