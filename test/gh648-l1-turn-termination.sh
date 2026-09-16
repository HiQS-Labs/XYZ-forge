#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh648-l1.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$ROOT/utils/py" GH648_MODULE="$ROOT/utils/py/turn_diagnostics.py" GH648_WORK="$WORK" python3 <<'PY'
import io, json, os, pathlib, subprocess, sys
import turn_diagnostics as td

passed = 0
def check(value, label):
    global passed
    if not value: raise AssertionError(label)
    passed += 1
def idle_diag():
    d = td.TurnDiagnostics(root_pid=4242)
    d.samples = [(1.0, 0.0, 1), (2.0, 0.0, 1), (3.0, 0.0, 1)]
    return d

stub = pathlib.Path(os.environ["GH648_WORK"]) / "bin"
stub.mkdir()
lsof = stub / "lsof"
lsof.write_text('''#!/bin/sh
case "$GH648_LSOF_MODE" in
 established) printf 'nhttps://api.example.test:443\n'; exit 0;;
 none) exit 1;;
 *) exit 2;;
esac
''')
lsof.chmod(0o755)
os.environ["PATH"] = str(stub) + os.pathsep + os.environ.get("PATH", "")
for mode, expected in (("established", "established"), ("none", "none"), ("fail", "unclassified")):
    os.environ["GH648_LSOF_MODE"] = mode
    check(td._network_state(4242) == expected, f"lsof {mode} maps to {expected}")

td._network_state = lambda _pid: "established"
reason, detail = idle_diag().classify()
check(reason == td.REASON_IDLE_IN_FLIGHT, "established connection is in-flight")
check("established outbound connection" in detail, "in-flight detail preserves evidence")
check(reason != "timeout-idle-no-progress", "idle trace never overclaims no-progress")
td._network_state = lambda _pid: "none"
reason, detail = idle_diag().classify()
check(reason == td.REASON_IDLE, "successful empty probe is idle-unknown")
check(reason == "timeout-idle-unknown", "idle label is explicit")
check("cause remains unknown" in detail, "idle detail stays honest")
td._network_state = lambda _pid: "unclassified"
reason, detail = idle_diag().classify()
check(reason == td.REASON_UNCLASSIFIED, "probe failure degrades to unclassified")
check("probe failed" in detail, "probe failure is observable")

records = [td.termination_record(k, "r", "d", observed_at=123.0) for k in
           (td.TERMINATION_IDLE_KILL, td.TERMINATION_WALL_CAP, td.TERMINATION_CHILD_ORPHAN)]
check(len({r["termination"] for r in records}) == 3, "termination kinds differ")
check(all(r["event"] == "turn-termination" for r in records), "event named")
check(all(r["exit_code"] == 7 for r in records), "exit remains 7")
check(all(r["observed_at"] == 123.0 for r in records), "timestamp preserved")
check(td.termination_record("surprise", "r", "d")["termination"] == "unknown", "foreign kind closes")
td._network_state = lambda _pid: "none"
d = idle_diag()
record = d.termination_record(td.TERMINATION_IDLE_KILL, observed_at=456.0)
check(record["reason"] == td.REASON_IDLE, "record classified")
check(record["termination"] == "idle-kill", "record mechanism")
stream = io.StringIO()
emitted = d.emit_termination_record(td.TERMINATION_WALL_CAP, observed_at=789.0, stream=stream)
decoded = json.loads(stream.getvalue())
check(decoded == emitted, "JSON matches return")
check(decoded["termination"] == "wall-cap", "wall cap differs")

source = pathlib.Path(os.environ["GH648_MODULE"]).read_text()
mutated = source.replace('if network == "established":', 'if network == "none":', 1)
check(mutated != source, "mutation changed classifier")
mutant = pathlib.Path(os.environ["GH648_WORK"]) / "turn_diagnostics_mutant.py"
mutant.write_text(mutated)
oracle = '''import importlib.util,sys
s=importlib.util.spec_from_file_location("mutant",sys.argv[1]);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
m._network_state=lambda _pid:"established"
d=m.TurnDiagnostics(root_pid=1);d.samples=[(1.,0.,1),(2.,0.,1),(3.,0.,1)]
assert d.classify()[0] == m.REASON_IDLE_IN_FLIGHT
'''
red = subprocess.run([sys.executable, "-c", oracle, str(mutant)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
check(red.returncode != 0, "mutation turns oracle red")
print(f"PASS: {passed} assertions")
PY
