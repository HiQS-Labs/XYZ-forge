PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=utils/py python3 - <<'PY'
import json, multiprocessing as mp, tempfile
from pathlib import Path
from unittest.mock import patch
import jog_run as j, rtl
ctx = mp.get_context("fork")
read, proceed = ctx.Event(), ctx.Event()
key, sha = "GH-1653-jog-publish", "a" * 40
with tempfile.TemporaryDirectory(dir=Path.cwd()) as coord:
    record = Path(coord) / ".tick" / "attempts" / key
    def reserve():
        with patch.multiple(rtl, attempt_origin=lambda *_: "b" * 64,
                            attempt_git=lambda _r, cmd, *_: "marathon/one" if cmd == "branch" else sha):
            return rtl.lane_attempt_reserve(coord, key, coord, kind="manual")[1]
    first = reserve()
    rtl.lane_attempt_finish(first, "completed", sha, archive=False)
    def settle():
        original = j._jog_live_publication_row
        def pause(path, issue_key):
            row = original(path, issue_key)
            if row and row["id"] == first["id"]:
                read.set()
                assert proceed.wait(10)
            return row
        with patch.multiple(j, _jog_live_publication_row=pause, _git=lambda *_: sha.encode()):
            j.jog_settle_publication_attempt(coord, coord, 1653, "marathon/one", False)
    p = ctx.Process(target=settle)
    p.start()
    assert read.wait(5), "settlement did not observe A"
    def rotate():
        rtl.lane_attempt_finish(first, "completed", sha, archive=True)
        reserve()
    other = ctx.Process(target=rotate)
    other.start()
    other.join(2)
    rotated_while_paused = other.exitcode == 0
    proceed.set()
    p.join(12)
    other.join(12)
    live = json.loads(record.read_text().splitlines()[-1]) if record.exists() else None
    print(f"rotation finished while A paused={rotated_while_paused}; settlement={p.exitcode} rotation={other.exitcode}; live={live}")
    assert p.exitcode == 0
    assert (rotated_while_paused and live and live["state"] == "active" and live["id"] != first["id"]) or (
        not rotated_while_paused and other.exitcode in (0, 1) and (live is None or live["state"] == "active"))
PY
