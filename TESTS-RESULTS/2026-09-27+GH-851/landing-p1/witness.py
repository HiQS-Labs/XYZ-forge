"""PR #880 Codex P1 witness: a timed-out bounded git call must not leave its descendants running.
A git alias stands in for `git push` + its pre-push hook: it backgrounds a grandchild that records its
pid, then blocks. run_git(timeout=2) must return rc 124 AND the grandchild must be gone.
Usage: python3 witness.py <merge-cleanup scripts dir>"""
import os, sys, tempfile, time
from pathlib import Path
sys.path.insert(0, sys.argv[1])
from scan_clones import run_git
d = Path(tempfile.mkdtemp())
os.system(f"git init -q {d}")
pidf = d / "grandchild.pid"
res = run_git(d, ["-c", f"alias.hang=!sh -c 'sleep 300 & echo $! > {pidf}; sleep 300'", "hang"], timeout=2)
time.sleep(1)
pid = int(pidf.read_text())
try:
    os.kill(pid, 0); alive = True
except ProcessLookupError:
    alive = False
if alive:
    os.kill(pid, 9)
print(f"rc={res.returncode} grandchild_alive_after_timeout={alive}")
print("PASS" if res.returncode == 124 and not alive else "FAIL")
sys.exit(0 if res.returncode == 124 and not alive else 1)
