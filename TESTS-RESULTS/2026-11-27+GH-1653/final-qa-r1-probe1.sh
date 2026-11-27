#!/usr/bin/env bash
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=utils/py python3 - <<'PY'
import builtins, multiprocessing as mp, tempfile
from pathlib import Path
from unittest.mock import patch
import jog_run as j
ctx = mp.get_context("fork")
a_ready, release_a, a_inside, b_inside = [ctx.Event() for _ in range(4)]
real_open = builtins.open
with tempfile.TemporaryDirectory(dir=Path.cwd()) as root:
    lock = Path(root) / "relay-driver.lock"
    def run(role):
        def gated_open(file, *args, **kwargs):
            if role == "A" and str(file) == str(lock / "pid") and args == ("w",):
                a_ready.set()
                if not release_a.wait(10):
                    raise RuntimeError("probe timed out")
            return real_open(file, *args, **kwargs)
        def enter(*_):
            (a_inside if role == "A" else b_inside).set()
            if role == "B" and not a_inside.wait(10):
                raise RuntimeError("A did not enter")
        with patch.multiple(j, driver_lock_path=lambda *_: (str(lock), str(lock)),
                            _require_jog_primary=lambda *_: None, _jog_resume_locked=enter):
            with patch("builtins.open", gated_open):
                try:
                    j.jog_resume(root, 1653)
                except j.ContractError as exc:
                    print(f"{role} refused: {exc}")
                    raise SystemExit(2)
    a = ctx.Process(target=run, args=("A",))
    b = ctx.Process(target=run, args=("B",))
    a.start()
    assert a_ready.wait(5), "A did not reach lock initialization"
    b.start()
    b_inside.wait(3)
    release_a.set()
    a.join(12)
    b.join(12)
    print(f"A entered={a_inside.is_set()} exit={a.exitcode}; B entered={b_inside.is_set()} exit={b.exitcode}")
    assert a_inside.is_set() and a.exitcode == 0
    assert not b_inside.is_set() and b.exitcode in (2, 4)
PY
