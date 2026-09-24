#!/usr/bin/env bash
# GH-648 L4 / #285: real short-cap processes, isolated coordination/telemetry.
# No git, real agents, network, or writes outside .relay-scratch.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$ROOT/utils/py" GH648_ROOT="$ROOT" python3 <<'PY'
import contextlib
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import pystub  # GH-788: stub header that survives a spaced interpreter path
import tempfile
import time
from types import SimpleNamespace
from unittest.mock import patch

root = Path(os.environ['GH648_ROOT'])
scratch = root / '.relay-scratch'
scratch.mkdir(exist_ok=True)

class Boundary:
    def __init__(self, *args): pass
    def turn_prompt(self, *args): return 'fixture'
    def drift_brief(self, *args): return ''
    def before(self): return 0
    def enforce(self, *args): return 0
    def apply_reviewer_turn_env(self, *args, **kwargs): pass

class Diagnostics:
    def __init__(self, **kwargs): pass
    def start(self): pass
    def stop(self): pass
    def classify(self): return 'timeout-unclassified', 'fixture'

class Logger:
    def __init__(self, **kwargs): pass
    def __enter__(self): return self
    def __exit__(self, *args): pass

receipts = []
with tempfile.TemporaryDirectory(prefix='gh648-l4-', dir=scratch) as tmp:
    work = Path(tmp)
    stub = work / 'sleeper'
    stub.write_text(pystub.launcher() + '''
import os, pathlib, signal, time
pathlib.Path(os.environ['GH648_STARTED']).write_text(str(os.getpid()))
if os.environ.get('GH648_DESCENDANT') == '1':
    child = os.fork()
    if child == 0:
        signal.signal(signal.SIGTERM, signal.SIG_IGN)
        signal.signal(signal.SIGHUP, signal.SIG_IGN)
        pathlib.Path(os.environ['GH648_STARTED'] + '.child').write_text(str(os.getpid()))
        time.sleep(5)
        pathlib.Path(os.environ['GH648_FINISHED']).write_text('descendant natural completion')
        os._exit(0)
    while not pathlib.Path(os.environ['GH648_STARTED'] + '.child').exists():
        time.sleep(0.01)
print('sleeping for five seconds', flush=True)
time.sleep(5)
pathlib.Path(os.environ['GH648_FINISHED']).write_text('natural completion')
''')
    stub.chmod(0o755)

    def run_case(lane, pty_mode, mutant=False, descendant=False):
        name = f'{lane}-pty{pty_mode}' + ('-descendant' if descendant else '') + ('-no-kill' if mutant else '')
        fixture = work / name
        fixture.mkdir()
        source = root / 'utils/py' / f'{lane}-turn.py'
        spec = importlib.util.spec_from_file_location('adapter', source)
        adapter = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(adapter)
        launched = []
        real_popen = subprocess.Popen
        real_run = subprocess.run
        def launch(*args, **kwargs):
            proc = real_popen(*args, **kwargs)
            launched.append(proc)
            return proc
        def run(cmd, **kwargs):
            # agy's informational repository lookup must not reach git.
            if cmd[0] == 'git':
                assert cmd == ['git', 'rev-parse', '--show-toplevel'], cmd
                return SimpleNamespace(returncode=0, stdout='')
            return real_run(cmd, **kwargs)
        env = dict(PATH=os.environ['PATH'], PYTHONDONTWRITEBYTECODE='1',
                   XYZ_ROOT=str(root), RELAY_AGENT=lane, RELAY_TASK='FIXTURE',
                   RELAY_FILE=str(fixture / 'relay.md'), RELAY_TURN_TIMEOUT_S='1',
                   RELAY_TURN_IDLE_S='0', RELAY_WORKTREE_ISOLATION='0',
                   AGY_PTY=str(pty_mode), GH648_DESCENDANT=str(int(descendant)), GH648_STARTED=str(fixture / 'started'),
                   GH648_FINISHED=str(fixture / 'finished'))
        env.update({f'{lane.upper()}_BIN': str(stub), f'{lane.upper()}_AGENT': lane,
                    f'{lane.upper()}_TURN_ROOT': str(fixture),
                    f'{lane.upper()}_LOG': str(fixture / 'turn.log')})
        output = io.StringIO()
        try:
            with contextlib.ExitStack() as stack:
                stack.enter_context(patch.dict(os.environ, env, clear=True))
                stack.enter_context(patch.object(sys, 'argv', [str(source)]))
                stack.enter_context(patch.object(adapter, 'RelayTurnLib', Boundary))
                stack.enter_context(patch.object(adapter, 'resolve_turn_root', return_value=str(fixture)))
                stack.enter_context(patch.object(adapter, 'claim_task_or_exit', return_value=(str(fixture), '')))
                stack.enter_context(patch.object(adapter, 'TurnDiagnostics', Diagnostics))
                stack.enter_context(patch.dict(sys.modules, {'harness_turn_logger': SimpleNamespace(HarnessTurnLogger=Logger)}))
                stack.enter_context(patch.object(subprocess, 'Popen', side_effect=launch))
                stack.enter_context(patch.object(subprocess, 'run', side_effect=run))
                stack.enter_context(contextlib.redirect_stderr(output))
                if lane == 'agy':
                    stack.enter_context(patch.object(adapter, 'agy_auth_preflight', return_value=True))
                    stack.enter_context(patch.object(adapter, 'agy_validate_model', return_value=True))
                    stack.enter_context(patch.object(adapter, '_probe_idle_blocker', return_value=('unknown', 'fixture')))
                    if mutant:
                        stack.enter_context(patch.object(adapter, '_kill_turn_group', return_value=None))
                started = time.monotonic()
                try:
                    adapter.main()
                except SystemExit as exc:
                    rc = exc.code
                elapsed = time.monotonic() - started
            assert len(launched) == 1, (name, len(launched))
            proc = launched[0]
            assert (fixture / 'started').read_text() == str(proc.pid), name
            assert rc == 7, (name, rc, output.getvalue())
            assert 'exceeded 1s wall-clock cap' in output.getvalue(), (name, output.getvalue())
            assert (fixture / 'turn.log').stat().st_size > 0, name
            # Snapshot before cleanup: cleanup cannot turn a leaking child green.
            dead = proc.poll() is not None
            fast = elapsed < 4
            natural = (fixture / 'finished').exists()
            receipts.append(dict(case=name, exit_code=rc, elapsed_s=round(elapsed, 3),
                                 child_dead=dead, natural_completion=natural,
                                 source_sha256=hashlib.sha256(source.read_bytes()).hexdigest()))
            assert dead and fast and not natural, ('cap containment', name, dead, elapsed, natural)
            if lane == 'agy':
                if descendant:
                    child_pid = int((fixture / 'started.child').read_text())
                    assert child_pid != proc.pid and child_pid > 1, name
                # SIGKILL delivery/reaping is asynchronous; bound the observation wait.
                deadline = time.monotonic() + 1
                while True:
                    try:
                        os.killpg(proc.pid, 0)
                    except ProcessLookupError:
                        receipts[-1]['group_absent'] = True
                        break
                    if time.monotonic() >= deadline:
                        receipts[-1]['group_absent'] = False
                        raise AssertionError(('process group remains', name))
                    time.sleep(0.01)
        finally:
            for proc in launched:
                if lane == 'agy':
                    try: os.killpg(proc.pid, signal.SIGKILL)
                    except ProcessLookupError: pass
                elif proc.poll() is None:
                    proc.kill()
                proc.wait(timeout=3)

    for lane, mode in (('codex', 0), ('agy', 0), ('agy', 1)):
        run_case(lane, mode)
        print('PASS:', lane, 'pty=' + str(mode), flush=True)
    for mode in (0, 1):
        run_case('agy', mode, descendant=True)
        print('PASS: resistant descendant pty=' + str(mode), flush=True)
    try:
        run_case('agy', 0, mutant=True)
    except AssertionError as exc:
        assert exc.args[0][0] == 'cap containment', exc
        assert receipts[-1]['child_dead'] is False, receipts[-1]
        print('PASS: no-kill mutation rejected for a live child', flush=True)
    else:
        raise AssertionError('no-kill mutation escaped the oracle')
receipt = dict(outcome='fix-required: resistant descendants survived leader exit; fixed in this lane',
               fixing_commit='pending harness commit; production fix and regression in this lane',
               cases=receipts)
(scratch / 'gh648-l4-receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps(receipt, sort_keys=True))
PY
