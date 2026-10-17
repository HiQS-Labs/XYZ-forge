import datetime, hashlib, json, os, pathlib, platform, signal, subprocess, time

TASK = pathlib.Path(__file__).resolve().parents[2]
OUT = TASK / 'temp/gh1111'
BASE = TASK.with_name(TASK.name + '-verify')
CANDIDATE = TASK.with_name(TASK.name + '-gate')

def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args], text=True).strip()

def identity(root):
    return {'head': git(root, 'rev-parse', 'HEAD'),
            'origin': git(root, 'remote', 'get-url', 'origin'),
            'config': git(root, 'config', '--local', '--list'),
            'status': git(root, 'status', '--porcelain=v1'),
            'worktrees': git(root, 'worktree', 'list', '--porcelain')}

def run(label, root, argv, timeout=900):
    env = dict(os.environ)
    for key in list(env):
        if key.startswith(('RELAY_', 'RT_', 'XYZ_VALIDATE_', 'GIT_')) or key in (
                'XYZ_HARNESS', 'TICK_REPO_ROOT', 'MARATHON_ROOT', 'ALLOW_PATHS',
                'PYTHONPATH', 'PYTHONHOME', 'XYZ_PYTHON', 'XYZ_HARNESS_DB'):
            env.pop(key, None)
    env['PYTHONDONTWRITEBYTECODE'] = '1'
    before = identity(root)
    start = time.monotonic()
    stamp = datetime.datetime.now(datetime.timezone.utc).isoformat()
    load = os.getloadavg()
    log = OUT / (label + '.log')
    with log.open('w') as stream:
        proc = subprocess.Popen(argv, cwd=root, env=env, stdout=stream,
                                stderr=subprocess.STDOUT, start_new_session=True)
        try:
            rc = proc.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGTERM)
            try: proc.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(proc.pid, signal.SIGKILL)
                proc.wait()
            rc = 124
    elapsed = time.monotonic() - start
    after = identity(root)
    raw = log.read_bytes()
    row = {'label': label, 'command': argv, 'cwd': str(root), 'timestamp': stamp,
           'elapsed_s': elapsed, 'rc': rc, 'identity_before': before,
           'identity_after': after, 'identity_equal': before == after,
           'load_before': load, 'load_after': os.getloadavg(),
           'platform': platform.platform(), 'python': platform.python_version(),
           'bash': subprocess.check_output(['/bin/bash', '--version'], text=True).splitlines()[0],
           'output_sha256': hashlib.sha256(raw).hexdigest(), 'output_bytes': len(raw),
           'output': raw.decode(errors='replace') if len(raw) < 40000 else None}
    with (OUT / 'measurements.jsonl').open('a') as stream:
        stream.write(json.dumps(row, sort_keys=True) + '\n')
    print(json.dumps({k: row[k] for k in ('label', 'elapsed_s', 'rc', 'identity_equal')}), flush=True)
    return row

if __name__ == '__main__':
    assert git(BASE, 'ls-files') == git(CANDIDATE, 'ls-files')
    assert not identity(BASE)['status'] and not identity(CANDIDATE)['status']
    for label, root in [('base-1', BASE), ('candidate-1', CANDIDATE),
                        ('candidate-2', CANDIDATE), ('base-2', BASE)]:
        row = run(label, root, ['/bin/bash', 'test/gh365-tier-fail-closed.sh'])
        assert row['rc'] == 0 and row['identity_equal'], row
