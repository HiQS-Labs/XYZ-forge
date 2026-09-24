#!/usr/bin/env bash
# GH-648 L5 / #237: silent socket-holding agy through consult's main path.
# No real advisors, git commands, or network listeners. All artifacts stay in scratch.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$ROOT/utils/py" GH648_ROOT="$ROOT" python3 <<'PY'
import contextlib
import io
import os
from pathlib import Path
import subprocess
import sys
import pystub  # GH-788: stub header that survives a spaced interpreter path
import tempfile
import time
from types import SimpleNamespace
from unittest.mock import patch
import consult as c
import turn_diagnostics as td

root = Path(os.environ['GH648_ROOT'])
scratch = root / '.relay-scratch'
scratch.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix='gh648-l5-', dir=scratch) as tmp:
    work = Path(tmp)
    # A launch blocker must leave an actionable transcript, not just False.
    auth_log = work / 'startup.md'
    with patch.object(c.subprocess, 'run', side_effect=FileNotFoundError('missing agy executable')):
        assert c.agy_auth_preflight('/missing/agy', str(auth_log)) is False
    assert auth_log.is_file() and auth_log.stat().st_size > 0
    assert 'FileNotFoundError: missing agy executable' in auth_log.read_text()
    assert 'auth pre-flight could not run' in auth_log.read_text()
    print('PASS: startup exception surfaced', flush=True)

    advisor = work / 'agy-stub'
    advisor.write_text(pystub.launcher() + '''
import os, pathlib, socket, sys, time
assert '--dangerously-skip-permissions' in sys.argv
assert '--print-timeout' in sys.argv
assert len(sys.argv[sys.argv.index('-p') + 1]) > 10000
# A socketpair models a pending backend without opening a listening port.
a, b = socket.socketpair()
pathlib.Path(os.environ['L5_READY']).write_text(str(os.getpid()))
time.sleep(float(os.environ['L5_DELAY']))
print('Review complete; evidence at source.py:42', flush=True)
a.close()
b.close()
''')
    advisor.chmod(0o755)

    def run_case(name, network, complete=False, mutant=False):
        fixture = work / name
        fixture.mkdir()
        wt = fixture / 'isolated'
        wt.mkdir()
        ready = fixture / 'ready'
        launched = []
        observed = []
        real_launch = c.guarded_with_timeout
        real_diag = td.TurnDiagnostics

        class Diagnostics:
            # Deterministic CPU/time/network observations, real shared classifier.
            # This tests consult attribution, not the OS-specific socket probe.
            def __init__(self, **kwargs):
                self.proc = launched[-1]
                assert kwargs['root_pid'] == self.proc.pid
                self.out = Path(kwargs['worktree'])
            def start(self): pass
            def stop(self): pass
            def idle_seconds(self):
                return 0 if complete else 100
            def classify(self):
                assert self.proc.poll() is None
                assert ready.read_text() == str(self.proc.pid)
                assert self.out.stat().st_size == 0
                diag = real_diag(root_pid=self.proc.pid, worktree=str(self.out))
                diag.samples = [(1., 0., 1), (2., 0., 1), (3., 0., 1)]
                diag._network_state_observed = network
                reason, detail = diag.classify()
                observed.append(reason)
                return ('timeout-idle', 'no progress') if mutant else (reason, detail)

        def launch(cmd, cwd, log, cap, env, **kwargs):
            assert cmd[0] == str(advisor) and cwd == str(wt)
            proc = real_launch(cmd, cwd, log, cap, env, own_group=True)
            assert proc is not None
            launched.append(proc)
            deadline = time.monotonic() + 5
            while not ready.exists() and proc.poll() is None and time.monotonic() < deadline:
                time.sleep(.01)
            assert ready.exists(), 'advisor never reached its silent socket wait'
            return proc

        def repository_stub(cmd, **kwargs):
            assert cmd[0] == 'git', cmd
            return SimpleNamespace(returncode=0, stdout='')

        env = dict(PATH=os.environ['PATH'], PYTHONDONTWRITEBYTECODE='1',
                   CONSULT_ROOT=str(fixture), XYZ_ROOT=str(root), AGY_BIN=str(advisor),
                   CONSULT_TIMEOUT='10', CONSULT_IDLE_S='1', XYZ_WRITE_OPS_LOG='0',
                   L5_READY=str(ready), L5_DELAY='.2' if complete else '30')
        output = io.StringIO()
        try:
            with contextlib.ExitStack() as stack:
                stack.enter_context(patch.dict(os.environ, env, clear=True))
                stack.enter_context(patch.object(sys, 'argv', ['consult', '--models', 'agy', '--out', str(fixture),
                                                             '--prompt', 'Review timeout attribution and evidence. ' * 300]))
                stack.enter_context(patch.object(c, 'RelayTurnLib'))
                stack.enter_context(patch.object(c, 'resolve_tick_repo_root', return_value=str(fixture)))
                stack.enter_context(patch.object(c, 'resolve_tick_bin', return_value=''))
                stack.enter_context(patch.object(c.subprocess, 'run', side_effect=repository_stub))
                stack.enter_context(patch.object(c.tempfile, 'mkdtemp', return_value=str(wt)))
                stack.enter_context(patch.object(c, 'agy_auth_preflight', return_value=True))
                stack.enter_context(patch.object(c, 'guarded_with_timeout', side_effect=launch))
                stack.enter_context(patch.object(c, 'TurnDiagnostics', Diagnostics))
                stack.enter_context(patch.object(c, 'CONSULT_POLL_S', .02))
                stack.enter_context(contextlib.redirect_stdout(output))
                stack.enter_context(contextlib.redirect_stderr(output))
                try: c.main()
                except SystemExit as exc: rc = exc.code
            assert len(launched) == 1 and launched[0].poll() is not None
            transcript = next(fixture.glob('consult-*/consult.agy.md')).read_text()
            stdout = output.getvalue()
            assert transcript.strip() and stdout.strip()
            if complete:
                assert rc == 0 and '1 answered, 0 failed' in stdout
                assert 'Review complete' in transcript and 'PARTIAL' not in transcript
            else:
                expected = 'timeout-idle-in-flight' if network == 'established' else 'timeout-idle-unknown'
                marker = 'PARTIAL — killed at idle threshold [' + expected + '], no verdict'
                assert observed == [expected], observed
                assert rc == 5 and '0 answered, 1 failed' in stdout
                assert marker in stdout and marker in transcript, ('truthful attribution', transcript, stdout)
                assert 'no progress' not in transcript and 'timeout-idle-exceeded' not in transcript
            print('PASS:', name, flush=True)
        finally:
            for proc in launched:
                if proc.poll() is None: proc.kill()
                proc.wait(timeout=3)

    run_case('slow-completion', 'established', complete=True)
    run_case('silent-in-flight', 'established')
    run_case('silent-unknown', 'none')
    try:
        run_case('old-label-mutation', 'established', mutant=True)
    except AssertionError as exc:
        assert isinstance(exc.args[0], tuple) and exc.args[0][0] == 'truthful attribution', exc
        print('PASS: old no-progress label mutation rejected', flush=True)
    else:
        raise AssertionError('old-label mutation escaped the oracle')
PY
