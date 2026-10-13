"""GH-1001 A2/A3 manual check (plan QA S2) — not a registered suite.

Extracts `_preflight_check_issue_closed` from a marathon_drive.py source file and runs it with
stubbed commands: no real git or gh process is started. Usage:
    python3 issue_closed_repo_probe.py <path/to/marathon_drive.py>
Prints one line per case and exits 0 only if every case meets the fixed behaviour.
"""
import ast
import re
import sys
from types import SimpleNamespace as NS

SRC = sys.argv[1]
fn = next(n for n in ast.walk(ast.parse(open(SRC).read()))
          if isinstance(n, ast.FunctionDef) and n.name == "_preflight_check_issue_closed")

ORIGINS = {"/harness": "https://github.com/example/harness.git",
           "/consumer": "https://github.com/example/consumer.git"}


def run(states, origin_ok=True, mocked=False):
    calls, errs, logs = [], [], []

    def cmd(argv, **kw):
        calls.append((tuple(argv), kw.get("cwd")))
        if argv[0] == "git":
            return ORIGINS[argv[2]] if origin_ok else ""
        if argv[1:3] == ["repo", "view"]:
            return {"/harness": "example/harness", "/consumer": "example/consumer"}[kw.get("cwd")]
        if argv[1:3] == ["issue", "view"]:
            return states[argv[argv.index("--repo") + 1]]
        raise AssertionError(argv)

    ns = dict(os=NS(environ={"MOCK_GH_ISSUE_STATE": "CLOSED"} if mocked else {}), re=re, sys=sys,
              shutil=NS(which=lambda _: "/stub/gh"), _cmd_out=cmd, root="/harness",
              _gate_root="/consumer", lane_issue_number=lambda: "1", lane_state_key="GH1",
              relay_task="T", _RESULT={}, args=NS(target_root="/consumer", phase_id="GH1"),
              xyz_debug_log_append=lambda *a, **k: logs.append(a[3]), eprint=errs.append)
    exec(compile(ast.Module(body=[fn], type_ignores=[]), SRC, "exec"), ns)
    try:
        ns[fn.name]()
        rc = 0
    except SystemExit as e:
        rc = e.code
    return rc, calls, errs, logs


ok = True


def case(name, cond, detail):
    global ok
    ok &= bool(cond)
    print(f"{'PASS' if cond else 'FAIL'}: {name} — {detail}")


rc, calls, errs, logs = run({"example/harness": "CLOSED", "example/consumer": "OPEN"})
case("harness CLOSED, consumer OPEN -> continue", rc == 0 and calls[0][0][2] == "/consumer",
     f"rc={rc} first_call={calls[0]}")
rc, calls, errs, logs = run({"example/harness": "OPEN", "example/consumer": "CLOSED"})
case("harness OPEN, consumer CLOSED -> exit 4 naming consumer",
     rc == 4 and any("example/consumer" in e for e in errs) and any("example/consumer" in m for m in logs),
     f"rc={rc} stderr={errs} log={logs}")
rc, calls, errs, logs = run({"example/harness": "OPEN", "example/consumer": "CLOSED"}, origin_ok=False)
fallback = [c for c in calls if c[0][1:3] == ("repo", "view")]
case("forced gh repo view fallback runs with cwd=consumer", rc == 4 and fallback and fallback[0][1] == "/consumer",
     f"rc={rc} fallback={fallback}")
rc, calls, errs, logs = run({}, mocked=True)
case("mocked-state branch keeps working", rc == 4 and calls == [] and any("mocked state" in e for e in errs),
     f"rc={rc} stderr={errs}")
sys.exit(0 if ok else 1)
