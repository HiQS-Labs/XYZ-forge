#!/usr/bin/env bash
# GH-648 L6 / #521: Muse wall-cap attribution, without live agents or git.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$ROOT/utils/py" GH648_ROOT="$ROOT" python3 <<'PY'
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import sys
sys.path.insert(0, os.path.join(os.environ["GH648_ROOT"], "test", "lib"))
import pystub  # GH-788: stub header that survives a spaced interpreter path
import tempfile
from types import SimpleNamespace
from unittest.mock import patch
import turn_diagnostics as td

root = Path(os.environ['GH648_ROOT'])
scratch = root / '.relay-scratch'
scratch.mkdir(exist_ok=True)
spec = importlib.util.spec_from_file_location('muse_adapter', root / 'utils/py/muse-turn.py')
muse = importlib.util.module_from_spec(spec)
spec.loader.exec_module(muse)

class Logger:
    def __init__(self, **kwargs): pass
    def __enter__(self): return self
    def __exit__(self, *args): pass

with tempfile.TemporaryDirectory(prefix='gh648-l6-', dir=scratch) as tmp:
    work = Path(tmp)
    stub = work / 'muse-stub'
    stub.write_text(pystub.launcher() + '''
import os, pathlib, sys, time
assert sys.argv[1] == 'exec'
assert '--trust-workspace' in sys.argv
assert pathlib.Path(sys.argv[sys.argv.index('--prompt-file') + 1]).read_text()
print('muse: workspace root: fixture', flush=True)
if os.environ['L6_MODE'] == 'stall':
    time.sleep(30)
elif os.environ['L6_MODE'] == 'healthy':
    print('Review complete: fixture result', flush=True)
''')
    stub.chmod(0o755)

    def run_case(name, network='none', mode='stall', off_lane=False, mutation=''):
        fixture = work / name
        fixture.mkdir()
        log = fixture / 'turn.log'
        calls = []

        class Boundary:
            def __init__(self, *args): pass
            def turn_prompt(self, *args): return 'Take your Muse relay turn.'
            def drift_brief(self, *args): return ''
            def before(self): pass
            def worktree_begin(self): return str(fixture)
            def worktree_end(self, wt):
                assert wt == str(fixture)
                return off_lane
            def enforce(self, *args):
                calls.append('enforce')
                return 0
            def apply_reviewer_turn_env(self, *args, **kwargs): pass

        class Diagnostics(td.TurnDiagnostics):
            # Stub observations, retain the real L1 classifier and serializer.
            # OS probes and the historical prompt's cause are not tested here.
            def start(self):
                calls.append('start')
                self.samples = [(1., 0., 1), (2., 0., 1), (3., 0., 1)]
                self._network_state_observed = network
            def stop(self): calls.append('stop')
            def classify(self):
                if mutation == 'old-label':
                    return 'timeout-idle-no-progress', 'no progress'
                return super().classify()
            def emit_termination_record(self, *args, **kwargs):
                if mutation == 'missing-record':
                    return self.termination_record(*args)
                return super().emit_termination_record(*args, **kwargs)

        env = dict(PATH=os.environ['PATH'], PYTHONDONTWRITEBYTECODE='1',
                   XYZ_ROOT=str(root), RELAY_AGENT='muse', MUSE_AGENT='muse',
                   RELAY_FILE=str(fixture / 'relay.md'), RELAY_TASK='FIXTURE',
                   MUSE_BIN=str(stub), MUSE_LOG=str(log), MUSE_MODEL='fixture',
                   RELAY_TURN_TIMEOUT_S='1', RELAY_WORKTREE_ISOLATION='1',
                   L6_MODE=mode)
        output = io.StringIO()
        mkstemp = tempfile.mkstemp
        with contextlib.ExitStack() as stack:
            stack.enter_context(patch.dict(os.environ, env, clear=True))
            stack.enter_context(patch.object(sys, 'argv', ['muse-turn.py']))
            stack.enter_context(patch.object(muse, 'RelayTurnLib', Boundary))
            stack.enter_context(patch.object(muse, 'resolve_turn_root', return_value=str(fixture)))
            stack.enter_context(patch.object(muse, 'resolve_model', return_value=('fixture', 'test')))
            stack.enter_context(patch.object(muse, 'claim_task_or_exit', return_value=(str(fixture), '')))
            stack.enter_context(patch.object(muse, 'TurnDiagnostics', Diagnostics))
            stack.enter_context(patch.object(muse.tempfile, 'mkstemp',
                                            side_effect=lambda **kw: mkstemp(dir=fixture, **kw)))
            stack.enter_context(patch.dict(sys.modules, {
                'harness_turn_logger': SimpleNamespace(HarnessTurnLogger=Logger)}))
            stack.enter_context(contextlib.redirect_stderr(output))
            try: muse.main()
            except SystemExit as exc: rc = exc.code
        assert calls == ['start', 'stop', 'enforce'], calls
        transcript = log.read_text()
        assert transcript.strip(), 'empty input cannot pass'
        records = [json.loads(line) for line in transcript.splitlines() if line.startswith('{')]
        if mode == 'stall':
            expected = {'none': td.REASON_IDLE, 'established': td.REASON_IDLE_IN_FLIGHT,
                        'unclassified': td.REASON_UNCLASSIFIED, None: td.REASON_UNCLASSIFIED}[network]
            assert rc == (6 if off_lane else 7), (rc, output.getvalue())
            assert len(records) == 1, ('termination record count', records)
            record = records[0]
            assert record['event'] == 'turn-termination'
            assert record['termination'] == 'wall-cap', record
            assert record['reason'] == expected, ('truthful attribution', record)
            assert record['exit_code'] == 7 and record['observed_at'] > 0
            assert 'cpu=0.00s/s' in record['detail'] and 'samples=3' in record['detail']
            assert 'no progress' not in transcript and 'no-progress' not in transcript
            assert expected in output.getvalue()
        else:
            assert rc == (0 if mode == 'healthy' else 5), (rc, output.getvalue())
            assert not records, records
            if mode == 'healthy': assert 'Review complete' in transcript
        print('PASS:', name, flush=True)

    run_case('stall-unknown')
    run_case('backend-in-flight', 'established')
    run_case('probe-failed', 'unclassified')
    run_case('probe-not-observed', None)
    run_case('cap-then-containment', off_lane=True)
    run_case('healthy', mode='healthy')
    run_case('banner-only', mode='banner')
    for mutation, marker in [('old-label', 'truthful attribution'),
                             ('missing-record', 'termination record count')]:
        try: run_case(mutation, mutation=mutation)
        except AssertionError as exc:
            assert isinstance(exc.args[0], tuple) and exc.args[0][0] == marker, exc
            print('PASS: rejected mutation', mutation, flush=True)
        else: raise AssertionError('mutation escaped: ' + mutation)
PY
