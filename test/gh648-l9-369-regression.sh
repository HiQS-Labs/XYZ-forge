#!/usr/bin/env bash
# GH-648 L9 / GH-369 regression baseline (verification-only): a multi-process CLI
# run under rtl_run_bounded must lose its ENTIRE process group at the cap —
# parent, child, and grandchild. Any survivor reopens GH-369.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT="$ROOT"
export PYTHONPATH="$ROOT/utils/py:${PYTHONPATH:-}"

python3 -B - <<'PY'
import os
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, os.path.join(os.environ['REPO_ROOT'], 'utils', 'py'))
import rtl  # noqa: E402

MARK = 'gh648l9-proc-family'
work = tempfile.mkdtemp(prefix='gh648l9.')
fam = os.path.join(work, 'family.py')
grandchild = "import time; time.sleep(60)  # gh648l9-grandchild"
with open(fam, 'w') as fh:
    fh.write("import subprocess, sys, time\n")
    fh.write("subprocess.Popen([sys.executable, '-c', %r])\n" % grandchild)
    fh.write("time.sleep(60)  # gh648l9-child\n")

cap = 2
t0 = time.monotonic()
rc = rtl.rtl_run_bounded(cap, [sys.executable, fam], cwd=os.environ['REPO_ROOT'])
elapsed = time.monotonic() - t0
time.sleep(1.0)  # let the kernel finish reaping

out = subprocess.run(['pgrep', '-f', 'gh648l9'], capture_output=True, text=True)
survivors = [ln.strip() for ln in out.stdout.splitlines() if ln.strip()]

problems = []
if rc != 7:
    problems.append('expected rtl_run_bounded rc=7 on timeout, got %r' % rc)
if elapsed >= 10:
    problems.append('cap did not bound the run (elapsed %.1fs for a 60s workload)' % elapsed)
if survivors:
    problems.append('process-group survivors past the cap: %s' % survivors)

if problems:
    print('FAIL gh648-l9-369-regression:')
    for problem in problems:
        print('  -', problem)
    sys.exit(1)
print('gh648-l9-369-regression: parent, child, and grandchild all died at the cap; rc=7')
PY
