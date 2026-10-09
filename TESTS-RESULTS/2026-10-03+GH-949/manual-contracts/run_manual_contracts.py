#!/usr/bin/env python3
"""Bounded manual acceptance checks for candidate 76ad7e4e; no repo suite/gate."""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

ROOT = Path('/Users/noelsaw/task-clones/ate-remediation-20261003')
CLONE = ROOT / 'verify'
EVIDENCE = ROOT / 'manual-contracts'
FIX = EVIDENCE / f'fixtures-{time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())}-{os.getpid()}'
PY_UTILS = CLONE / 'utils' / 'py'
ATE = CLONE / 'utils' / 'ate' / 'scripts'
sys.path.insert(0, str(PY_UTILS))
sys.path.insert(0, str(ATE))

from metamorphic_oracle import check_idempotence  # noqa: E402
from domain_oracles import check_host_containment  # noqa: E402


def bounded(argv, *, cwd=None, timeout=10, env=None):
    """Run in a separate session and reap its whole group on any outer timeout."""
    p = subprocess.Popen(argv, cwd=cwd, env=env, stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE, text=True, start_new_session=True)
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


def git(cwd: Path, *args: str):
    r = bounded(['git', *args], cwd=cwd, timeout=10)
    if r['rc'] != 0:
        raise RuntimeError(f'git {args} failed ({r["rc"]}): {r["stderr"]}')
    return r['stdout'].strip()


def init_repo(path: Path, *, linked=False):
    path.mkdir(parents=True, exist_ok=True)
    git(path, 'init', '-q')
    git(path, 'config', 'user.name', 'Manual Contract')
    git(path, 'config', 'user.email', 'manual@example.invalid')
    (path / 'seed.txt').write_text('seed\n')
    git(path, 'add', 'seed.txt')
    git(path, 'commit', '-qm', 'seed')
    if linked:
        git(path, 'config', 'extensions.worktreeConfig', 'true')
        wt = path.parent / (path.name + '-linked')
        git(path, 'worktree', 'add', '-qb', 'manual-host', str(wt))
        git(wt, 'config', '--worktree', 'user.name', 'Manual Contract')
        git(wt, 'config', '--worktree', 'user.email', 'manual@example.invalid')
        return wt
    return path


def check(label, ok, detail=None):
    return {'check': label, 'passed': bool(ok), 'detail': detail}


def main():
    FIX.mkdir(parents=True, exist_ok=True)
    results = []

    # A zero-minute run may inspect its scratch repo, but must not report a run
    # as successful or append a fabricated row over a pre-existing log.
    zero = FIX / 'zero-budget'
    target = init_repo(zero / 'target')
    head_before = git(target, 'rev-parse', 'HEAD')
    status_before = git(target, 'status', '--porcelain')
    grid = zero / 'grid.yaml'
    grid.write_text('''command_template: ["python3", "-c", "print('ok')"]\nvariation_keys: [mode]\nmode: [one]\nmodel: stub\nmessage: probe\nper_variation_timeout_seconds: 2\n''')
    log = zero / 'rows.jsonl'
    prior = json.dumps({'schema_version': '1.0', 'run_id': 'prior', 'iteration': 9,
                        'engine': 'ate_variations', 'status': 'pass', 'exit_code': 0}) + '\n'
    log.write_text(prior)
    control = zero / 'control.json'
    control.write_text('{"action":"abort"}\n')
    run = bounded(['python3', str(ATE / 'run_variations.py'), '--repo', str(target),
                   '--variations', str(grid), '--mock-classifier', '--log', str(log),
                   '--control', str(control), '--minutes', '0'], cwd=zero, timeout=15)
    results.append(check('zero budget rejects no-work and preserves prior row',
                         run['rc'] == 2 and log.read_text() == prior and
                         git(target, 'rev-parse', 'HEAD') == head_before and
                         git(target, 'status', '--porcelain') == status_before,
                         {'rc': run['rc'], 'stderr': run['stderr'],
                          'row_bytes_preserved': log.read_text() == prior,
                          'target_head_unchanged': git(target, 'rev-parse', 'HEAD') == head_before,
                          'target_status_unchanged': git(target, 'status', '--porcelain') == status_before}))

    # Filter the deliberately fake historical line from each process log, then
    # ask both actual consumers to parse and render only the schema-1.0 row.
    row_inputs = {
        'spawn_error': ROOT / 'manual-state/after/missing-command/rows.jsonl',
        'term': ROOT / 'manual-process/after/term.jsonl',
        'int': ROOT / 'manual-process/after/int.jsonl',
    }
    for name, src in row_inputs.items():
        parsed = [json.loads(s) for s in src.read_text().splitlines() if s.strip()]
        rows = [r for r in parsed if r.get('schema_version') == '1.0']
        filtered = FIX / f'{name}-schema-rows.jsonl'
        filtered.write_text(''.join(json.dumps(r) + '\n' for r in rows))
        ci = bounded(['python3', str(ATE / 'checkin.py'), '--log', str(filtered), '--json'],
                     cwd=FIX, timeout=10)
        ci_obj = json.loads(ci['stdout']) if ci['rc'] == 0 else {}
        dry = bounded(['python3', str(ATE / 'compile_issue.py'), '--log', str(filtered),
                       '--repo', 'manual/example', '--test-name', name, '--dry-run'],
                      cwd=FIX, timeout=10)
        category = rows[0].get('classification', {}).get('category') if rows else None
        results.append(check(f'{name} full row accepted by checkin and compile_issue dry-run',
                             len(rows) == 1 and ci['rc'] == 0 and ci_obj.get('n_records') == 1 and
                             ci_obj.get('failed') == 1 and dry['rc'] == 0 and
                             'Total variations logged: 1' in dry['stdout'] and
                             (category or 'uncategorized') in dry['stdout'],
                             {'source': str(src), 'schema_rows': len(rows), 'category': category,
                              'checkin_rc': ci['rc'], 'checkin_summary': ci_obj,
                              'compile_issue_rc': dry['rc'],
                              'dry_run_contains_one_record': 'Total variations logged: 1' in dry['stdout'],
                              'dry_run_stderr': dry['stderr']}))

    # Direct library calls must not install CLI signal handlers; completed
    # concurrent runs pass, while concurrent timed-out runs fail incomplete.
    normal = FIX / 'normal.py'
    normal.write_text('print("stable")\n')
    slow = FIX / 'slow.py'
    slow.write_text('import time\ntime.sleep(2)\nprint("late")\n')
    before_handlers = (signal.getsignal(signal.SIGINT), signal.getsignal(signal.SIGTERM))
    normal_result = check_idempotence(['python3', str(normal)], repetitions=2, concurrent=True,
                                      concurrency=2, cwd=str(FIX), timeout=3)
    timeout_result = check_idempotence(['python3', str(slow)], repetitions=2, concurrent=True,
                                       concurrency=2, cwd=str(FIX), timeout=0.15)
    after_handlers = (signal.getsignal(signal.SIGINT), signal.getsignal(signal.SIGTERM))
    results.append(check('concurrent idempotence normal pass and timeout failure are incomplete; no signal handlers installed',
                         normal_result.get('passed') is True and normal_result.get('completed') is True and
                         timeout_result.get('passed') is False and timeout_result.get('completed') is False and
                         before_handlers == after_handlers,
                         {'normal': normal_result, 'timeout': timeout_result,
                          'signal_handlers_unchanged': before_handlers == after_handlers}))

    work = init_repo(FIX / 'containment-work')
    missing_host = FIX / 'does-not-exist-host'
    missing_result = check_host_containment(['/usr/bin/true'], str(work), str(missing_host), timeout=3)
    results.append(check('containment rejects absent host metadata',
                         missing_result.get('passed') is False and bool(missing_result.get('reasons')),
                         {'passed': missing_result.get('passed'), 'reasons': missing_result.get('reasons'),
                          'host_errors': (missing_result.get('host_before') or {}).get('errors')}))

    no_config = init_repo(FIX / 'host-no-config')
    (no_config / '.git/config').unlink()
    no_config_result = check_host_containment(['/usr/bin/true'], str(work), str(no_config), timeout=3)
    results.append(check('containment rejects unreadable/missing host config',
                         no_config_result.get('passed') is False and bool(no_config_result.get('reasons')),
                         {'passed': no_config_result.get('passed'), 'reasons': no_config_result.get('reasons'),
                          'host_errors': (no_config_result.get('host_before') or {}).get('errors')}))

    host = init_repo(FIX / 'host-linked-parent', linked=True)
    head_before = git(host, 'rev-parse', 'HEAD')
    cmd = ['git', '-C', str(host), 'commit', '--allow-empty', '-qm', 'manual head change']
    linked_result = check_host_containment(cmd, str(work), str(host), timeout=5)
    results.append(check('containment detects linked-worktree HEAD change',
                         linked_result.get('passed') is False and
                         any('head_tip changed' in x or 'branches changed' in x for x in linked_result.get('reasons', [])),
                         {'head_before': head_before, 'head_after': git(host, 'rev-parse', 'HEAD'),
                          'passed': linked_result.get('passed'), 'reasons': linked_result.get('reasons'),
                          'worktree_config_before': (linked_result.get('host_before') or {}).get('worktree_config_sha256')}))

    payload = {'candidate_sha': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=CLONE, text=True).strip(),
               'completed_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
               'results': results,
               'passed': all(r['passed'] for r in results)}
    (EVIDENCE / 'results.json').write_text(json.dumps(payload, indent=2) + '\n')
    print(json.dumps(payload, indent=2))
    return 0 if payload['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
