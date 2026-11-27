#!/usr/bin/env bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=utils/py python3 - <<'PROBE'
import builtins, multiprocessing as mp, tempfile
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
import jog_run as j

ctx = mp.get_context("fork")
ready, release, a_inside, b_inside = [ctx.Event() for _ in range(4)]
real_open = builtins.open
with tempfile.TemporaryDirectory(dir=Path.cwd()) as root:
    lock = Path(root) / "relay-driver.lock"
    (Path(root) / "releases.db").touch()

    def run(role):
        def gated_open(file, *args, **kwargs):
            if role == "A" and str(file) == str(lock / "pid") and args == ("w",):
                ready.set()
                assert release.wait(10), "resume timed out"
            return real_open(file, *args, **kwargs)

        def stop_wake(_):
            b_inside.set()
            assert a_inside.wait(10), "resume never entered"
            raise SystemExit(0)

        with patch.multiple(j, driver_lock_path=lambda *_: (str(lock), str(lock)),
                            _require_jog_primary=lambda *_: None,
                            validate_marathon_executor=lambda *_: None,
                            _execution_root=lambda *_: root,
                            validate_checkpoint_options=lambda *_: None,
                            _jog_resume_locked=lambda *_: a_inside.set(),
                            jog_reconcile_orphan_leases=stop_wake), patch("builtins.open", gated_open):
            try:
                if role == "A":
                    j.jog_resume(root, 1653)
                else:
                    j.jog_run_main(SimpleNamespace(root=root))
            except j.ContractError as exc:
                print(f"{role} refused: {exc}", flush=True)
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
          f"wake entered={b_inside.is_set()} exit={b.exitcode}")
    assert a_inside.is_set() and a.exitcode == 0
    assert not b_inside.is_set() and b.exitcode in (2, 4)
PROBE
