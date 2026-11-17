import json, os, pathlib, sqlite3, subprocess, sys, tempfile
source = pathlib.Path.cwd()
assert source.name.endswith('-verify') and (source / '.git').is_dir()
sys.path.insert(0, str(source / 'utils/py'))
import jog_run
import releases_app as app
from harness_paths import primary_config_key
vulnerable = '--expect-vulnerable' in sys.argv
out = pathlib.Path(sys.argv[1]); out.mkdir(parents=True, exist_ok=True)
def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args], text=True, stderr=subprocess.DEVNULL).strip()
def init(root):
    root.mkdir(); git(root, 'init', '-b', 'development'); git(root, 'config', 'user.name', 'Fixture'); git(root, 'config', 'user.email', 'fixture@example.invalid')
with tempfile.TemporaryDirectory(prefix='gh1491-safety-') as tmp:
    base = pathlib.Path(tmp); root = base / 'root'; init(root)
    (root / '.gitignore').write_text('scratch.log\n.tick/\n')
    git(root, 'add', '.'); git(root, 'commit', '-m', 'base')
    initial = git(root, 'rev-parse', 'HEAD')
    (root / 'scratch.log').write_text('tracked destination\n'); git(root, 'add', '-f', 'scratch.log'); git(root, 'commit', '-m', 'destination')
    remote = base / 'remote.git'; subprocess.run(['git', 'clone', '--bare', str(root), str(remote)], check=True, capture_output=True)
    git(root, 'remote', 'add', 'origin', str(remote)); git(root, 'switch', '-c', 'lane', initial)
    (root / 'scratch.log').write_text('valuable ignored log\n')
    refused = False
    try: jog_run._jog_align_target(str(root))
    except (Exception, SystemExit): refused = True
    preserved = (root / 'scratch.log').read_text() == 'valuable ignored log\n'
    assert (not preserved) if vulnerable else (preserved and refused)
    queue = base / 'queue'; init(queue); git(queue, 'remote', 'add', 'origin', str(remote)); git(queue, 'config', primary_config_key(str(queue)), str(queue))
    def cli(*args):
        subprocess.run([sys.executable, str(source / 'utils/py/releases_app.py'), '--root', str(queue), *args], check=True, capture_output=True)
    cli('init'); cli('jog', 'add', '901')
    def row():
        with sqlite3.connect(queue / 'releases.db') as c: return c.execute('SELECT global_id,status,attempt_count FROM jog_queue WHERE gh_number=901').fetchone()
    selected = row(); app.jog_set_status(str(queue), 901, 'parked')
    refused_lease = False
    try:
        if vulnerable: app.jog_acquire_lease(str(queue), 901, os.getpid())
        else: app.jog_acquire_lease(str(queue), 901, os.getpid(), expected_global_id=selected[0])
    except (Exception, SystemExit): refused_lease = True
    after = row()
    assert (after[1] == 'running') if vulnerable else (refused_lease and after[1:] == ('parked', 0))
    if not vulnerable:
        app.jog_set_status(str(queue), 901, 'pending')
        try: app.jog_acquire_lease(str(queue), 901, os.getpid(), expected_global_id='wrong-identity')
        except (Exception, SystemExit): pass
        else: raise AssertionError('identity mismatch accepted')
        assert row()[1:] == ('pending', 0)
        app.jog_acquire_lease(str(queue), 901, os.getpid(), expected_global_id=selected[0])
        assert row()[1:] == ('running', 1)
    result = {'vulnerable_control': vulnerable, 'ignored_preserved': preserved, 'alignment_refused': refused, 'held_lease_refused': refused_lease, 'held_status': after[1], 'head': git(source, 'rev-parse', 'HEAD')}
    (out / 'result.json').write_text(json.dumps(result, indent=2)); print(json.dumps(result))
