#!/usr/bin/env bash
# Real short-cap child + real tick projection; stub only git/diagnostic boundaries.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PYTHONDONTWRITEBYTECODE=1
export PYTHONPATH="$ROOT/utils/py${PYTHONPATH:+:$PYTHONPATH}"
export GH648_ROOT="$ROOT"
python3 <<'PY'
import os
import pathlib
import subprocess
import sys
import tempfile

root = pathlib.Path(os.environ['GH648_ROOT'])
scratch = root / '.relay-scratch'
scratch.mkdir(exist_ok=True)
# No git operations: this suite exercises the adapter and production token branch
# independently of the shared core's existing commit/containment test coverage.
with tempfile.TemporaryDirectory(prefix='gh648-l2-', dir=scratch) as tmp:
    work = pathlib.Path(tmp)
    core = (root / 'relay-automation/relay-turn-lib.sh').read_text()
    start = core.index('  local _relay_file="${RELAY_FILE:-}" _peer="${RELAY_PEER:-}"', core.index('rtl_enforce()'))
    end = core.index('  # (5) GH-68:', start)
    handoff = work / 'handoff.sh'
    handoff.write_text('''source "$GH648_ROOT/relay-automation/relay-turn-lib.sh"
rtl_tick_bin() { printf '%s\\n' "$TICK_BIN"; }
rtl_trace() { :; }
rtl_log_always() { :; }
run_handoff() {
local task="$RELAY_TASK" agent="$RELAY_AGENT"
''' + core[start:end] + '\n}\nrun_handoff\n')
    driver = work / 'driver.py'
    driver.write_text('''import importlib.util, os, pathlib, subprocess, sys, types
from unittest.mock import patch
import rtl
spec = importlib.util.spec_from_file_location('adapter', os.environ['GH648_ADAPTER'])
adapter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(adapter)
class Boundary:
    def __init__(self, *args): pass
    def turn_prompt(self, *args): return 'fixture'
    def drift_brief(self, *args): return ''
    def before(self): return 0
    def worktree_begin(self): return os.environ['COMMANDCODE_TURN_ROOT']
    def worktree_end(self, wt): return os.environ.get('GH648_OFFLANE') == '1'
    def enforce(self, *args):
        pathlib.Path(os.environ['GH648_ENFORCED']).write_text('enforced')
        subprocess.run(['bash', os.environ['GH648_HANDOFF']], check=True)
        return int(os.environ.get('GH648_ENFORCE_RC', '0'))
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
with patch.object(adapter, 'RelayTurnLib', Boundary), patch.object(adapter, 'TurnDiagnostics', Diagnostics), patch.dict(sys.modules, {'harness_turn_logger': types.SimpleNamespace(HarnessTurnLogger=Logger)}):
    adapter.main()
''')
    stub = work / 'cmd'
    stub.write_text('#!' + sys.executable + '\nimport os, time\nif os.environ["GH648_MODE"] != "timeout-empty": print("fixture output", flush=True)\nif os.environ["GH648_MODE"].startswith("timeout"): time.sleep(30)\n')
    stub.chmod(0o755)
    adapter = os.environ.get('GH648_ADAPTER', str(root / 'utils/py/commandcode-turn.py'))
    for name, mode, status, offlane, enforce_rc, expected_rc in (
        ('timeout', 'timeout', 'Open', False, 0, 7),
        ('timeout-empty', 'timeout-empty', 'Open', False, 0, 7),
        ('timeout-approved', 'timeout', 'Approved', False, 0, 7),
        ('timeout-offlane', 'timeout', 'Open', True, 0, 6),
        ('timeout-enforce', 'timeout', 'Open', False, 6, 6),
        ('healthy', 'healthy', 'Open', False, 0, 0),
        ('healthy-approved', 'healthy', 'Approved', False, 0, 0),
    ):
        fixture = work / name
        fixture.mkdir()
        relay = fixture / 'relay.md'
        relay.write_text(f'STATUS: {status}\nNEXT: commandcode (Reviewer)\n')
        env = dict(os.environ, TICK_REPO_ROOT=str(fixture), TICK_BIN=str(root / 'bin/tick'),
                   XYZ_ROOT=str(root), COMMANDCODE_TURN_ROOT=str(fixture),
                   COMMANDCODE_BIN=str(stub), COMMANDCODE_AGENT='commandcode',
                   COMMANDCODE_LOG=str(fixture / 'turn.log'), RELAY_AGENT='commandcode',
                   RELAY_PEER='agy', RELAY_TASK='RETRY-TURN', RELAY_FILE=str(relay),
                   RELAY_TURN_TIMEOUT_S='1', RELAY_WORKTREE_ISOLATION='1' if offlane else '0',
                   GH648_MODE=mode, GH648_ADAPTER=adapter, GH648_HANDOFF=str(handoff),
                   GH648_ENFORCED=str(fixture / 'enforced'), GH648_OFFLANE=str(int(offlane)),
                   GH648_ENFORCE_RC=str(enforce_rc), ALLOW_PATHS='')
        def tick(*args):
            return subprocess.run([env['TICK_BIN'], *args], env=env, text=True,
                                  capture_output=True, check=True).stdout
        tick('log', 'task.created', 'RETRY-TURN', '--agent', 'agy')
        tick('claim', 'RETRY-TURN', '--agent', 'agy', '--paths', 'relay.md')
        tick('release', 'RETRY-TURN', '--agent', 'agy', '--to', 'commandcode')
        result = subprocess.run([sys.executable, str(driver)], env=env, text=True, capture_output=True)
        assert result.returncode == expected_rc, (name, result.returncode, result.stderr)
        assert (fixture / 'enforced').read_text() == 'enforced', name
        info = tick('info', 'RETRY-TURN')
        assert info.strip(), name
        fields = dict(line.split(':', 1) for line in info.splitlines() if ':' in line)
        fields = {k: v.strip() for k, v in fields.items()}
        if mode.startswith('timeout'):
            if mode == 'timeout-empty':
                assert (fixture / 'turn.log').stat().st_size == 0, name
            assert fields['status'] == 'open', (name, info)
            assert not fields.get('handoff-to'), (name, info)
            assert 'NEXT: commandcode' in relay.read_text(), name
            claim = tick('claim', 'RETRY-TURN', '--agent', 'commandcode', '--paths', 'relay.md')
            assert 'won:' in claim, (name, claim)
            tick('release', 'RETRY-TURN', '--agent', 'commandcode')
            # Prove recovery through the adapter, not just a standalone claim.
            # Reuse the exact task ID and role after the interrupted review.
            relay.write_text('STATUS: Open\nNEXT: commandcode (Reviewer)\n')
            retry_env = dict(env, GH648_MODE='healthy', GH648_OFFLANE='0',
                             GH648_ENFORCE_RC='0', RELAY_WORKTREE_ISOLATION='0')
            retry = subprocess.run([sys.executable, str(driver)], env=retry_env,
                                   text=True, capture_output=True)
            assert retry.returncode == 0, (name, retry.returncode, retry.stderr)
            retry_info = tick('info', 'RETRY-TURN')
            retry_fields = dict(line.split(':', 1) for line in retry_info.splitlines() if ':' in line)
            retry_fields = {k: v.strip() for k, v in retry_fields.items()}
            assert retry_fields.get('status') == 'open', (name, retry_info)
            assert retry_fields.get('handoff-to') == 'agy', (name, retry_info)
        elif status == 'Approved':
            assert fields['status'] == 'done', (name, info)
        else:
            assert fields['status'] == 'open' and fields.get('handoff-to') == 'agy', (name, info)
        print('PASS:', name, flush=True)
print('gh648-l2-token-aftermath: 7 cases passed')
PY
