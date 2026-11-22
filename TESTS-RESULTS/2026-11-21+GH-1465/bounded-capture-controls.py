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


def exited(pid):
    """True once pid is gone or only a zombie (a launcher not yet reaped has still exited)."""
    import subprocess
    out = subprocess.run(["ps", "-o", "stat=", "-p", str(pid)], capture_output=True, text=True).stdout.strip()
    return out == "" or out.startswith("Z")


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
    h = res["stdout_hashes"]
    return dict(passed=res["passed"], completed=res["completed"], exit_codes=res["exit_codes"], hashes=h,
                ok=res["passed"] is False and res["completed"] and res["exit_codes"] == [0, 0]
                and len(set(h)) == 2)


@case("4_default_capture_is_complete")
def _():
    prog = "import sys\nfor i in range(20000):\n print('out-%d'%i)\n print('err-%d'%i, file=sys.stderr)\n"
    r = pg.run_bounded([PY, "-c", prog], timeout=20)
    exp_out = "".join("out-%d\n" % i for i in range(20000))
    exp_err = "".join("err-%d\n" % i for i in range(20000))
    return dict(stdout_len=len(r.stdout), stderr_len=len(r.stderr), rc=r.rc,
                ok=r.stdout == exp_out and r.stderr == exp_err and r.rc == 0)


@case("5_tail_mode_digest_covers_complete_output")
def _():
    import hashlib
    def prog(tag):
        return f'print("{tag}"); print("x"*70000); print("last-line")'
    a = pg.run_bounded([PY, "-c", prog("P1")], timeout=10, capture_tail_bytes=4096)
    b = pg.run_bounded([PY, "-c", prog("P2")], timeout=10, capture_tail_bytes=4096)
    want = lambda tag: hashlib.sha256((tag + "\n" + "x" * 70000 + "\nlast-line\n").encode()).hexdigest()
    return dict(tails_equal=a.stdout == b.stdout, digest_a=a.stdout_sha256, digest_b=b.stdout_sha256,
                truncated=a.truncated, capture_complete=a.capture_complete, tail_len=len(a.stdout),
                tail_end=a.stdout[-10:],
                ok=a.truncated and a.capture_complete and len(a.stdout) <= 4096
                and a.stdout.endswith("last-line\n") and a.stdout == b.stdout
                and a.stdout_sha256 == want("P1") and b.stdout_sha256 == want("P2"))


@case("6_timeout_keeps_sentinel_diagnostics", expect_red=True)
def _():
    r = pg.run_bounded(["/bin/sh", "-c", "printf sentinel-out; printf sentinel-err >&2; sleep 1.5"],
                       timeout=.3, grace=.05)
    return dict(timed_out=r.timed_out, stdout=r.stdout, stderr=r.stderr,
                ok=r.timed_out and r.stdout == "sentinel-out" and r.stderr == "sentinel-err")


@case("7_timeout_excerpt_is_bounded_tail")
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
    with tempfile.TemporaryDirectory() as d:
        pidfile = pathlib.Path(d) / "leader.pid"
        seen = {"over_cap_after_leader_exit": False, "over_cap_before_leader_exit": False}

        def rss(pgid, **_):
            try:
                leader = int(pidfile.read_text())
            except (OSError, ValueError):
                return 0, None  # launcher not started yet: under the cap
            if not exited(leader):
                return 0, None  # launcher still running: under the cap
            seen["over_cap_after_leader_exit"] = True  # only a post-exit sample is ever over the cap
            return 100, None

        with patch.object(pg, "group_rss_mb", side_effect=rss):
            t = time.monotonic()
            r = pg.run_bounded(["/bin/sh", "-c", f"sleep 3 & echo $$ > {pidfile}; exit 0"], timeout=10,
                               max_rss_mb=1, rss_poll_s=.05)
            el = time.monotonic() - t
    return dict(rss_killed=r.rss_killed, elapsed=round(el, 3), **seen,
                ok=r.rss_killed and el < 2.0 and seen["over_cap_after_leader_exit"])


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



@case("12_multibyte_output_across_read_boundaries")
def _():
    r = pg.run_bounded([PY, "-c", "import sys; sys.stdout.buffer.write('\u00e9'.encode()*100001)"], timeout=10)
    return dict(chars=len(r.stdout), ok=r.stdout == "\u00e9" * 100001)


@case("13_cancellation_mid_run_leaves_no_live_group")
def _():
    with tempfile.TemporaryDirectory() as d:
        pidfile = pathlib.Path(d) / "holder.pid"

        class Stop(Exception):
            pass

        def boom(*_):
            raise Stop()

        old = signal.signal(signal.SIGALRM, boom)
        signal.setitimer(signal.ITIMER_REAL, .5)
        raised = False
        try:
            pg.run_bounded(["/bin/sh", "-c", f"sleep 30 & echo $! > {pidfile}; sleep 30"], timeout=20, grace=.2)
        except Stop:
            raised = True
        finally:
            signal.setitimer(signal.ITIMER_REAL, 0)
            signal.signal(signal.SIGALRM, old)
        time.sleep(.2)
        pid = int(pidfile.read_text())
        live = alive(pid)
        if live:
            os.kill(pid, signal.SIGKILL)
    return dict(original_exception_preserved=raised, group_member_alive=live, ok=raised and not live)


@case("14_reader_error_is_raised_not_returned")
def _():
    real = os.read

    def failing(fd, n):
        if n == getattr(pg, "_CHUNK", -1):
            raise OSError(5, "injected EIO")
        return real(fd, n)

    with patch.object(pg.os, "read", side_effect=failing):
        try:
            r = pg.run_bounded(["/bin/sh", "-c", "printf data; exit 0"], timeout=5)
            return dict(returned_rc=r.rc, stdout=r.stdout, ok=False)
        except OSError as exc:
            return dict(raised=str(exc), ok="injected EIO" in str(exc))


@case("15_escaped_descendant_abandoned_with_frozen_snapshot")
def _():
    # A descendant in its own session survives killpg and keeps the pipes open past grace + 5.
    holder = ("import os,time\nos.setsid()\nprint('late', flush=True)\ntime.sleep(8)\nprint('later', flush=True)\n")
    cmd = ["/bin/sh", "-c", f"printf early; {PY} -c \"{holder}\" & exit 0"]
    t = time.monotonic()
    r = pg.run_bounded(cmd, timeout=.3, grace=.1)
    el = time.monotonic() - t
    first = (r.stdout, r.stdout_sha256, r.capture_complete)
    time.sleep(5)  # let the escapee emit more after the snapshot was taken
    stable = (r.stdout, r.stdout_sha256, r.capture_complete) == first
    return dict(timed_out=r.timed_out, elapsed=round(el, 3), stdout=r.stdout, capture_complete=r.capture_complete,
                snapshot_stable_after_later_output=stable,
                ok=r.timed_out and el < 7.5 and r.capture_complete is False and stable and "later" not in r.stdout)

summary = dict(label=label, source_root=str(root), python=sys.version.split()[0],
               all_ok=all(c["ok"] for c in cases.values()),
               defect_cases_ok=all(c["ok"] for c in cases.values() if c["expect_red_on_08fee"]),
               cases=cases)
print(json.dumps(summary, sort_keys=True, indent=1))
