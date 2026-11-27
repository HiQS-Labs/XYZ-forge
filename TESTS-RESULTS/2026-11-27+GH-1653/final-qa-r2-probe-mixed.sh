#!/usr/bin/env bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=utils/py python3 - <<'PY'
import builtins, multiprocessing as mp, tempfile
from pathlib import Path
from unittest.mock import patch
import jog_run as j

ctx = mp.get_context("fork")
ready, release, a_inside, b_inside = [ctx.Event() for _ in range(4)]
real_open = builtins.open
with tempfile.TemporaryDirectory(dir=Path.cwd()) as root:
    lock = Path(root) / "relay-driver.lock"

    def run(role):
        def gated_open(file, *args, **kwargs):
            if role == "A" and str(file) == str(lock / "pid") and args == ("w",):
                ready.set()
                assert release.wait(10), "A timed out"
            return real_open(file, *args, **kwargs)

        def retry_body(*_):
            b_inside.set()
            assert a_inside.wait(10), "A never entered"

        with patch.multiple(j, driver_lock_path=lambda *_: (str(lock), str(lock)),
                            _require_jog_primary=lambda *_: None,
                            validate_marathon_executor=lambda *_: None,
                            _jog_resume_locked=lambda *_: a_inside.set(),
                            _jog_retry_gate_locked=retry_body):
            with patch("builtins.open", gated_open):
                try:
                    if role == "A":
                        j.jog_resume(root, 1653)
                    else:
                        j.jog_retry_gate(root, 1653, None)
                except j.ContractError as exc:
                    print(f"{role} refused: {exc}")
                    raise SystemExit(2)

    a = ctx.Process(target=run, args=("A",))
    b = ctx.Process(target=run, args=("B",))
    a.start()
    try:
        assert ready.wait(5), "resume did not reach PID write"
        b.start()
        b_inside.wait(3)
    finally:
        release.set()
    a.join(12)
    b.join(12)
    print(f"resume entered={a_inside.is_set()} exit={a.exitcode}; "
          f"retry-gate entered={b_inside.is_set()} exit={b.exitcode}")
    assert a_inside.is_set() and a.exitcode == 0
    assert not b_inside.is_set() and b.exitcode in (2, 4)
PY
