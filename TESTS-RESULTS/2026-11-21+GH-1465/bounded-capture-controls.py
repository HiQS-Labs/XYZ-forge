#!/usr/bin/env python3
"""Manual red/green controls for the GH-1465 bounded gate output capture (not a registered suite, GH-831).

usage: bounded-capture-controls.py <source-root> <label>

<source-root> holds utils/py/proc_group.py (+ metamorphic_oracle.py). Run it against the approved base
6c3dc3aa2, the failed 08fee5d0f (red) and the repaired head (green). Prints one JSON object:
per case the observation and `ok` (did the case meet the required behavior). Exit 0 always; the JSON is the record.
"""
import json, os, pathlib, signal, sys, tempfile, threading, time
from unittest.mock import patch

root, label = pathlib.Path(sys.argv[1]).resolve(), sys.argv[2]
sys.dont_write_bytecode = True
sys.path.insert(0, str(root / "utils/py"))
import proc_group as pg  # noqa: E402
import metamorphic_oracle as mo  # noqa: E402

PY = sys.executable
cases = {}


def case(name, expect_red=False):
    def deco(fn):
        try:
            obs = fn()
            ok = bool(obs.pop("ok"))
        except TypeError as exc:  # an API the head under test does not have
            obs, ok = {"unsupported": str(exc)}, False
        except Exception as exc:  # noqa: BLE001 - a control must record, not die
            obs, ok = {"error": f"{type(exc).__name__}: {exc}"}, False
        cases[name] = dict(ok=ok, expect_red_on_08fee=expect_red, **obs)
        return fn
    return deco


def alive(pid):
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    return True


@case("1_pipe_holder_wall_timeout", expect_red=True)
def _():
    t = time.monotonic()
    r = pg.run_bounded(["/bin/sh", "-c", "sleep 1.5 & exit 0"], timeout=.15, grace=.05)
    el = time.monotonic() - t
    return dict(timed_out=r.timed_out, rc=r.rc, elapsed=round(el, 3), ok=r.timed_out and el < 1.0)


@case("2_pipe_holder_group_killed_promptly", expect_red=True)
def _():
    with tempfile.TemporaryDirectory() as d:
        pidfile = pathlib.Path(d) / "holder.pid"
        t = time.monotonic()
        r = pg.run_bounded(["/bin/sh", "-c", f"sleep 6 & echo $! > {pidfile}; exit 0"], timeout=.3, grace=.1)
        el = time.monotonic() - t
        pid = int(pidfile.read_text())
        dead = not alive(pid)
        if alive(pid):
            os.kill(pid, signal.SIGKILL)
    return dict(timed_out=r.timed_out, elapsed=round(el, 3), holder_dead_on_return=dead,
                ok=r.timed_out and el < 2.0 and dead)


@case("3_idempotence_detects_differing_prefix", expect_red=True)
def _():
    res = mo.check_idempotence([PY, "-c", 'import os; print(os.getpid()); print("x"*70000)'],
                               repetitions=2, timeout=5, cwd=tempfile.gettempdir())
    return dict(passed=res["passed"], hashes=res["stdout_hashes"], ok=res["passed"] is False)


@case("4_default_capture_is_complete")
def _():
    prog = "import sys\nfor i in range(20000):\n print('out-%d'%i)\n print('err-%d'%i, file=sys.stderr)\n"
    r = pg.run_bounded([PY, "-c", prog], timeout=20)
    exp_out = "".join("out-%d\n" % i for i in range(20000))
    exp_err = "".join("err-%d\n" % i for i in range(20000))
    return dict(stdout_len=len(r.stdout), stderr_len=len(r.stderr), rc=r.rc,
                ok=r.stdout == exp_out and r.stderr == exp_err and r.rc == 0)


@case("5_tail_mode_keeps_digest_of_complete_output")
def _():
    prog = 'import os; print(os.getpid()); print("x"*70000); print("last-line")'
    a = pg.run_bounded([PY, "-c", prog], timeout=10, capture_tail_bytes=4096)
    b = pg.run_bounded([PY, "-c", prog], timeout=10, capture_tail_bytes=4096)
    return dict(tails_equal=a.stdout == b.stdout, digests_differ=a.stdout_sha256 != b.stdout_sha256,
                truncated=a.truncated, tail_len=len(a.stdout), tail_end=a.stdout[-10:],
                ok=a.truncated and len(a.stdout) <= 4096 and a.stdout.endswith("last-line\n")
                and a.stdout_sha256 != b.stdout_sha256 and a.stdout == b.stdout)


@case("6_timeout_keeps_sentinel_diagnostics", expect_red=True)
def _():
    r = pg.run_bounded(["/bin/sh", "-c", "printf sentinel-out; printf sentinel-err >&2; sleep 1.5"],
                       timeout=.3, grace=.05)
    return dict(timed_out=r.timed_out, stdout=r.stdout, stderr=r.stderr,
                ok=r.timed_out and r.stdout == "sentinel-out" and r.stderr == "sentinel-err")


@case("7_timeout_excerpt_is_bounded_tail", expect_red=True)
def _():
    prog = ("import sys,time\nfor i in range(20000): print('out-%d'%i)\n"
            "sys.stdout.flush(); time.sleep(5)\n")
    t = time.monotonic()
    r = pg.run_bounded([PY, "-c", prog], timeout=1.0, grace=.1, capture_tail_bytes=4096)
    el = time.monotonic() - t
    return dict(timed_out=r.timed_out, elapsed=round(el, 3), tail_len=len(r.stdout), tail_end=r.stdout[-10:],
                truncated=r.truncated, ok=r.timed_out and el < 3 and 0 < len(r.stdout) <= 4096
                and r.stdout.endswith("out-19999\n") and r.truncated)


@case("8_ordinary_exit_code_and_streams")
def _():
    r = pg.run_bounded(["/bin/sh", "-c", "printf ok; printf error >&2; exit 7"], timeout=5)
    return dict(rc=r.rc, stdout=r.stdout, stderr=r.stderr, timed_out=r.timed_out,
                ok=(r.rc, r.stdout, r.stderr, r.timed_out) == (7, "ok", "error", False))


@case("9_text_mode_newline_semantics_preserved")
def _():
    r = pg.run_bounded(["/bin/sh", "-c", r"printf 'a\r\nb\rc\n'"], timeout=5)
    return dict(stdout=r.stdout, ok=r.stdout == "a\nb\nc\n")


@case("10_leader_exit_pipe_member_still_rss_guarded")
def _():
    with patch.object(pg, "group_rss_mb", return_value=(100, None)):
        t = time.monotonic()
        r = pg.run_bounded(["/bin/sh", "-c", "sleep 3 & exit 0"], timeout=10, max_rss_mb=1, rss_poll_s=.05)
        el = time.monotonic() - t
    return dict(rss_killed=r.rss_killed, elapsed=round(el, 3), ok=r.rss_killed and el < 2.0)


@case("11_termination_in_flight_completes_before_return")
def _():
    done = threading.Event()
    real = pg.kill_existing

    def slow_terminate(*a, **k):
        real(*a, **k)
        time.sleep(1.2)
        done.set()

    with patch.object(pg, "group_rss_mb", return_value=(100, None)), \
            patch.object(pg, "kill_existing", side_effect=slow_terminate):
        r = pg.run_bounded(["/bin/sh", "-c", "sleep 5"], timeout=10, max_rss_mb=1, rss_poll_s=.05)
        before_return = done.is_set()
    done.wait(3)
    return dict(rss_killed=r.rss_killed, completed_before_return=before_return, ok=r.rss_killed and before_return)


summary = dict(label=label, source_root=str(root), python=sys.version.split()[0],
               all_ok=all(c["ok"] for c in cases.values()),
               defect_cases_ok=all(c["ok"] for c in cases.values() if c["expect_red_on_08fee"]),
               cases=cases)
print(json.dumps(summary, sort_keys=True, indent=1))
