#!/usr/bin/env bash
# Hermetic main-path regression: no git commands, network, or real advisors.
# Policy: idle-unknown kills at the existing idle threshold, with its honest label.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/.relay-scratch"
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$ROOT/utils/py" GH648_ROOT="$ROOT" python3 <<'PY'
import contextlib, io, os, pathlib, subprocess, sys, tempfile
from types import SimpleNamespace
from unittest.mock import patch
import consult as c
import turn_diagnostics as td

root = pathlib.Path(os.environ['GH648_ROOT'])
class Idle:
    def __init__(self, **kwargs): pass
    def start(self): pass
    def stop(self): pass
    def idle_seconds(self): return 100
    def classify(self):
        d = td.TurnDiagnostics(root_pid=1)
        d.samples = [(1., 0., 1), (2., 0., 1), (3., 0., 1)]
        d._network_state_observed = 'none'
        return d.classify()

with tempfile.TemporaryDirectory(dir=root / '.relay-scratch', prefix='gh648-l3-') as work:
    work = pathlib.Path(work)
    def run_case(name, mode, timeout=None, json_mode=False):
        out = work / name
        out.mkdir()
        wt = out / 'isolated'
        wt.mkdir()
        launched = []
        caps = []
        real_launch = c.guarded_with_timeout
        def launch(cmd, cwd, log, cap, env, **kwargs):
            caps.append(cap)
            body = '{"response":"audit finding at source.py:42"}' if json_mode else 'audit finding at source.py:42'
            code = 'print(' + repr(body) + ', flush=True)'
            if mode != 'complete': code += '; import time; time.sleep(30)'
            proc = real_launch([sys.executable, '-c', code], cwd, log, cap, env, own_group=True)
            launched.append(proc)
            # Wait for actual substantive output before exercising the bound.
            import time
            deadline = time.monotonic() + 5
            while pathlib.Path(log).stat().st_size == 0 and time.monotonic() < deadline:
                time.sleep(.01)
            assert pathlib.Path(log).stat().st_size > 0
            return proc
        def repository_stub(cmd, **kwargs):
            assert cmd[0] == 'git', cmd
            return SimpleNamespace(returncode=0, stdout='')
        env = {'CONSULT_ROOT': str(wt), 'XYZ_ROOT': str(root), 'CONSULT_IDLE_S': '1' if mode == 'idle' else '0',
               'XYZ_WRITE_OPS_LOG': '0', 'CONSULT_GEMINI_JSON': '1' if json_mode else '0'}
        if timeout is not None: env['CONSULT_TIMEOUT'] = str(timeout)
        output = io.StringIO()
        try:
            with patch.dict(os.environ, env, clear=True), patch.object(sys, 'argv', ['consult', '--prompt', 'review', '--models', 'gemini', '--out', str(out)]), \
                 patch.object(c, 'RelayTurnLib'), patch.object(c, 'resolve_tick_repo_root', return_value=str(wt)), \
                 patch.object(c, 'resolve_tick_bin', return_value=''), patch.object(c.subprocess, 'run', side_effect=repository_stub), \
                 patch.object(c.tempfile, 'mkdtemp', return_value=str(wt)), patch.object(c, 'guarded_with_timeout', side_effect=launch), \
                 patch.object(c, 'TurnDiagnostics', Idle), contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
                try: c.main()
                except SystemExit as exc: rc = exc.code
        finally:
            for proc in launched:
                if proc.poll() is None: proc.kill()
                proc.wait()
        transcript = next(out.glob('consult-*/consult.gemini.' + ('json' if json_mode else 'md')))
        return rc, output.getvalue(), transcript, caps

    rc, stdout, transcript, caps = run_case('default', 'complete')
    assert caps == [600], caps
    assert rc == 0 and '1 answered, 0 failed' in stdout
    assert transcript.read_text() == 'audit finding at source.py:42\n'
    rc, stdout, transcript, caps = run_case('wall', 'wall', 1)
    marker = 'PARTIAL — hit the 1s cap, no verdict'
    assert caps == [1] and rc == 5
    assert marker in stdout and marker in transcript.read_text()
    assert 'audit finding at source.py:42' in stdout and 'audit finding at source.py:42' in transcript.read_text()
    assert '0 answered, 1 failed' in stdout
    rc, stdout, transcript, _ = run_case('idle', 'idle', 10)
    idle_marker = 'PARTIAL — killed at idle threshold [timeout-idle-unknown], no verdict'
    assert rc == 5 and idle_marker in stdout and transcript.read_text().startswith('**' + idle_marker + '**')
    assert 'hit the 10s cap' not in stdout + transcript.read_text()
    assert 'exceeded' not in transcript.read_text()
    rc, stdout, transcript, _ = run_case('json', 'wall', 1, True)
    import json
    assert json.loads(transcript.read_text())['response'] == 'audit finding at source.py:42'
    assert marker in stdout and marker in pathlib.Path(str(transcript) + '.PARTIAL.md').read_text()
    assert rc == 5
    rc, stdout, transcript, _ = run_case('json-idle', 'idle', 10, True)
    assert transcript.read_text() == '{"response":"audit finding at source.py:42"}\n'
    assert idle_marker in stdout and idle_marker in pathlib.Path(str(transcript) + '.PARTIAL.md').read_text()
    assert rc == 5
print('PASS: default 600s, override, wall partial, truthful idle kill, completion, wall/idle JSON preservation')
PY
