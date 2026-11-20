import json
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path

DURATION_S = 605
FG_TIMEOUT_S = 600

work_code = (
    "import sys, time, pathlib; "
    "out = pathlib.Path(sys.argv[1]); "
    "out.write_text('started\\n'); "
    f"time.sleep({DURATION_S}); "
    "out.write_text('started\\ncompleted\\n')"
)

results = {"started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}

with tempfile.TemporaryDirectory(prefix="ks07-real-10m-") as td:
    td_path = Path(td)
    fg_marker = td_path / "fg-marker.txt"
    bg_marker = td_path / "bg-marker.txt"

    def run_fg_red():
        t0 = time.monotonic()
        try:
            subprocess.run(
                [sys.executable, "-c", work_code, str(fg_marker)],
                timeout=FG_TIMEOUT_S,
                check=True,
                capture_output=True,
                text=True,
            )
            results["red_fg"] = {"killed": False, "elapsed_s": round(time.monotonic() - t0, 2)}
        except subprocess.TimeoutExpired:
            elapsed = round(time.monotonic() - t0, 2)
            marker_txt = fg_marker.read_text().strip() if fg_marker.exists() else ""
            results["red_fg"] = {
                "killed": True,
                "timeout_s": FG_TIMEOUT_S,
                "elapsed_s": elapsed,
                "marker_state": marker_txt,
                "completed_reached": "completed" in marker_txt,
            }

    def run_bg_green():
        t0 = time.monotonic()
        r = subprocess.run(
            [sys.executable, "-c", work_code, str(bg_marker)],
            check=False,
            capture_output=True,
            text=True,
        )
        elapsed = round(time.monotonic() - t0, 2)
        marker_txt = bg_marker.read_text().strip() if bg_marker.exists() else ""
        results["green_bg"] = {
            "returncode": r.returncode,
            "elapsed_s": elapsed,
            "marker_state": marker_txt,
            "completed_reached": "completed" in marker_txt,
        }

    t_fg = threading.Thread(target=run_fg_red)
    t_bg = threading.Thread(target=run_bg_green)
    t_fg.start()
    t_bg.start()
    t_fg.join()
    t_bg.join()

results["finished_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
assert results["red_fg"]["killed"] is True and results["red_fg"]["completed_reached"] is False, results
assert results["green_bg"]["returncode"] == 0 and results["green_bg"]["completed_reached"] is True, results
assert results["green_bg"]["elapsed_s"] >= 605.0, results

Path("/tmp/ks07-probe/red-green-probe.txt").write_text(json.dumps(results, indent=2) + "\n", encoding="utf-8")
Path("/tmp/ks07-probe/probe.rc").write_text("0\n", encoding="utf-8")
