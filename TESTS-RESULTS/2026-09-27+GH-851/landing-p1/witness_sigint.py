"""PR #880 Agy review blocker witness: an interrupt (Ctrl-C) during a bounded git call must end git's
process group too. A child Python calls run_git(timeout=60) on a git alias that backgrounds a grandchild
(standing in for the pre-push hook's gate), then receives SIGINT. The grandchild must be gone.
Usage: python3 witness_sigint.py <merge-cleanup scripts dir>"""
import os, signal, subprocess, sys, tempfile, time
from pathlib import Path
d = Path(tempfile.mkdtemp()); os.system(f"git init -q {d}")
pidf = d / "grandchild.pid"
code = (f"import sys; sys.path.insert(0, {sys.argv[1]!r}); from scan_clones import run_git; from pathlib import Path; "
        f"run_git(Path({str(d)!r}), ['-c', \"alias.hang=!sh -c 'sleep 300 & echo $! > {pidf}; sleep 300'\", 'hang'], timeout=60)")
child = subprocess.Popen([sys.executable, "-c", code], stderr=subprocess.DEVNULL)
for _ in range(100):
    if pidf.exists() and pidf.read_text().strip(): break
    time.sleep(0.1)
child.send_signal(signal.SIGINT); child.wait(timeout=30); time.sleep(1)
pid = int(pidf.read_text())
try: os.kill(pid, 0); alive = True
except ProcessLookupError: alive = False
if alive: os.kill(pid, 9)
print(f"child_rc={child.returncode} grandchild_alive_after_sigint={alive}")
print("PASS" if not alive else "FAIL"); sys.exit(0 if not alive else 1)
