#!/usr/bin/env python3
"""Focused follow-up: zero-minute admission against a 0-commit scratch repo."""
import json
import os
from pathlib import Path
import signal
import subprocess
import time

ROOT = Path('/Users/noelsaw/task-clones/ate-remediation-20261003')
CLONE = ROOT / 'verify'
OUT = ROOT / 'manual-contracts'
FIX = OUT / f'zero-budget-uncommitted-{time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())}-{os.getpid()}'
REPO = FIX / 'repo'
FIX.mkdir(parents=True)
REPO.mkdir()


def run(argv, cwd=None, timeout=10):
    p = subprocess.Popen(argv, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                         text=True, start_new_session=True)
    try:
        out, err = p.communicate(timeout=timeout)
        return {'rc': p.returncode, 'stdout': out, 'stderr': err}
    except subprocess.TimeoutExpired:
        try:
            os.killpg(p.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        try:
            out, err = p.communicate(timeout=1)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(p.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            out, err = p.communicate(timeout=2)
        return {'rc': None, 'stdout': out, 'stderr': err, 'outer_timeout': True}


def git(*args):
    return run(['git', *args], cwd=REPO, timeout=10)


git('init', '-q')
git('config', 'user.name', 'Manual Contract')
git('config', 'user.email', 'manual@example.invalid')
(REPO / 'seed.txt').write_text('seed\n')
(REPO / 'sentinel').write_text('preexisting\n')
grid = FIX / 'grid.yaml'
grid.write_text('''command_template: ["python3", "-c", "print('ok')"]\nvariation_keys: [mode]\nmode: [one]\nmodel: stub\nmessage: probe\nper_variation_timeout_seconds: 2\n''')
log = FIX / 'rows.jsonl'
prior = json.dumps({'schema_version': '1.0', 'run_id': 'prior', 'status': 'pass', 'exit_code': 0}) + '\n'
log.write_text(prior)
control = FIX / 'control.json'
old_control = '{"action":"abort","reason":"retain-me"}\n'
control.write_text(old_control)
before_head = git('rev-parse', 'HEAD')['rc']  # expected failure: repository has no commit
before_status = git('status', '--porcelain')['stdout']
cmd = ['python3', str(CLONE / 'utils/ate/scripts/run_variations.py'), '--repo', str(REPO),
       '--variations', str(grid), '--mock-classifier', '--log', str(log),
       '--control', str(control), '--minutes', '0']
result = run(cmd, cwd=FIX, timeout=15)
after_head = git('rev-parse', 'HEAD')
after_status = git('status', '--porcelain')['stdout']
obj = {
    'candidate_sha': run(['git', 'rev-parse', 'HEAD'], cwd=CLONE)['stdout'].strip(),
    'command': cmd,
    'rc': result['rc'],
    'stderr': result['stderr'],
    'preexisting_log_preserved': log.read_text() == prior,
    'control_preserved': control.read_text() == old_control,
    'head_before_had_commit': before_head == 0,
    'head_after_rc': after_head['rc'],
    'head_after': after_head['stdout'].strip(),
    'target_status_before': before_status,
    'target_status_after': after_status,
    'new_baseline_commit_created': before_head != 0 and after_head['rc'] == 0,
    'interpretation': 'No variation row was emitted, but zero-minute admission still rewrote control.json and created a baseline commit in this 0-commit target.'
}
(OUT / 'zero-budget-uncommitted.json').write_text(json.dumps(obj, indent=2) + '\n')
print(json.dumps(obj, indent=2))
