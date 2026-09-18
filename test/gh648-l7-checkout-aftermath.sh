#!/usr/bin/env bash
# GH-648 L7 / #242: real child timeout; modeled Git boundary (no repository mutations).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$ROOT/utils/py" GH648_ROOT="$ROOT" python3 <<'PYTEST'
import ast
import contextlib
import io
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from unittest.mock import patch
import rtl

root = Path(os.environ['GH648_ROOT'])
scratch = root / '.relay-scratch'
scratch.mkdir(exist_ok=True)
source = ast.parse((root / 'utils/py/relay_drive.py').read_text())
main = next(n for n in source.body if isinstance(n, ast.FunctionDef) and n.name == 'main')
loop = next(n for n in main.body if isinstance(n, ast.While))
# Execute the driver's actual capture and failed-turn blocks, with surrounding IO stubbed.
capture = next(n for n in loop.body if isinstance(n, (ast.Assign, ast.Try))
               and any(isinstance(t, ast.Name) and t.id == 'checkout_before'
                       for t in ast.walk(n)))
failure = next(n for n in loop.body if isinstance(n, ast.If)
               and ast.unparse(n.test) == 'res_code != 0')
launch = next(n for n in loop.body if isinstance(n, ast.If)
              and ast.unparse(n.test) == 'os.access(args.agent_cmd, os.X_OK)')
assert loop.body.index(capture) < loop.body.index(launch) < loop.body.index(failure)

def execute(node, namespace):
    exec(compile(ast.Module(body=[node], type_ignores=[]), '<driver boundary>', 'exec'), namespace)

with tempfile.TemporaryDirectory(prefix='gh648-l7-', dir=scratch) as tmp:
    fixture = Path(tmp)
    state = fixture / 'checkout'
    original_head = 'a' * 40
    development_head = 'b' * 40
    calls = []
    moved = False
    conflict = False

    def git(cmd, **kwargs):
        assert cmd[:3] == ['git', '-C', str(fixture)], cmd
        args = cmd[3:]
        calls.append(args)
        branch, head = state.read_text().splitlines()
        rc, out, err = 0, '', ''
        if args == ['symbolic-ref', '--quiet', 'HEAD']:
            rc, out = (0, branch) if branch else (1, '')
        elif args == ['rev-parse', '--verify', 'HEAD']:
            out = head
        elif args == ['rev-parse', '--verify', 'refs/heads/operator']:
            out = development_head if moved else original_head
        elif args in (['switch', '--no-guess', '--', 'operator'],
                      ['switch', '--detach', original_head]):
            if conflict:
                rc, err = 1, 'local changes would be overwritten'
            else:
                state.write_text(('refs/heads/operator' if '--no-guess' in args else '')
                                 + '\n' + original_head + '\n')
        else:
            raise AssertionError(('unexpected Git command', args))
        result = subprocess.CompletedProcess(cmd, rc, out + ('\n' if out else ''), err)
        if kwargs.get('check') and rc:
            raise subprocess.CalledProcessError(rc, cmd, result.stdout, result.stderr)
        return result

    for name, detached, timeout, mutation in [
        ('branch-timeout', False, True, False),
        ('detached-timeout', True, True, False),
        ('healthy-switch', False, False, False),
        ('no-restore-control', False, True, True),
    ]:
        calls.clear()
        start = ('', original_head) if detached else ('refs/heads/operator', original_head)
        state.write_text('\n'.join(start) + '\n')
        namespace = dict(checkout_snapshot=rtl.checkout_snapshot,
                         restore_checkout_after_timeout=rtl.restore_checkout_after_timeout,
                         progress_main_tree=str(fixture), sys=sys, subprocess=subprocess,
                         judge_terminal=lambda *a, **kw: ('none', True),
                         file_status=lambda: 'Open', role='builder', pre_turn={},
                         write_escalation_reason=lambda reason: None)
        with patch.object(rtl.subprocess, 'run', side_effect=git):
            execute(capture, namespace)
        child = ('from pathlib import Path; import time; '
                 + 'Path(' + repr(str(state)) + ').write_text('
                 + repr('refs/heads/development\n' + development_head + '\n') + '); '
                 + ('time.sleep(30)' if timeout else ''))
        rc = rtl.rtl_run_bounded(0.5, [sys.executable, '-c', child])
        assert rc == (7 if timeout else 0), rc
        assert state.read_text().startswith('refs/heads/development\n'), 'child never switched'
        namespace['res_code'] = rc
        if mutation:
            namespace['restore_checkout_after_timeout'] = lambda *a: True
        with patch.object(rtl.subprocess, 'run', side_effect=git):
            try: execute(failure, namespace)
            except SystemExit as exc: assert exc.code == rc
        observed = tuple(state.read_text().splitlines())
        if mutation:
            try:
                assert observed == start, 'checkout branch/HEAD drifted'
            except AssertionError as exc:
                assert str(exc) == 'checkout branch/HEAD drifted'
                print('PASS: no-restore mutation rejected by preservation assertion')
            else:
                raise AssertionError('no-restore mutation escaped')
        elif timeout:
            assert observed == start, (name, observed, start)
            print('PASS:', name)
        else:
            assert observed == ('refs/heads/development', development_head)
            assert not any(c[0] == 'switch' for c in calls)
            print('PASS:', name)

    for name in ['unchanged', 'moved-ref', 'dirty-conflict']:
        calls.clear()
        state.write_text('refs/heads/operator\n' + original_head + '\n')
        with patch.object(rtl.subprocess, 'run', side_effect=git):
            before = rtl.checkout_snapshot(str(fixture))
            if name != 'unchanged':
                state.write_text('refs/heads/development\n' + development_head + '\n')
            moved, conflict = name == 'moved-ref', name == 'dirty-conflict'
            output = io.StringIO()
            with contextlib.redirect_stderr(output):
                ok = rtl.restore_checkout_after_timeout(str(fixture), before)
            assert ok == (name == 'unchanged'), (name, output.getvalue())
            if name == 'moved-ref': assert not any(c[0] == 'switch' for c in calls)
            if not ok:
                assert 'manual recovery' in output.getvalue()
                assert state.read_text().startswith('refs/heads/development\n')
        print('PASS:', name)
    # Snapshot failure must not prevent dispatch or replace the timeout exit.
    for error in [RuntimeError('not a repository'),
                  subprocess.CalledProcessError(128, ['git'], stderr='unborn HEAD'),
                  OSError('git unavailable'), ValueError('invalid root'),
                  subprocess.TimeoutExpired(['git'], 10)]:
        namespace['checkout_snapshot'] = lambda root, error=error: (_ for _ in ()).throw(error)
        namespace['restore_checkout_after_timeout'] = rtl.restore_checkout_after_timeout
        namespace['checkout_before'] = ('stale', 'stale')
        namespace['res_code'] = 7
        output = io.StringIO()
        with contextlib.redirect_stderr(output), patch.object(
                rtl.subprocess, 'run', side_effect=AssertionError('unexpected Git operation')):
            execute(capture, namespace)
            assert namespace['checkout_before'] is None
            try:
                execute(failure, namespace)
            except SystemExit as exc:
                assert exc.code == 7
            else:
                raise AssertionError('timeout exit lost')
        assert 'snapshot unavailable' in output.getvalue()
        assert 'manual recovery' in output.getvalue()
        print('PASS: snapshot failure:', type(error).__name__)

    with contextlib.redirect_stderr(io.StringIO()), patch.object(
            rtl.subprocess, 'run', side_effect=AssertionError('unexpected Git operation')):
        assert rtl.restore_checkout_after_timeout(str(fixture), None) is False
    print('PASS: missing snapshot recovery performs no Git operations')

PYTEST

