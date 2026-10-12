"""One-off fixture evidence for two review findings; not a CI suite/case/registration."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

SOURCE = Path('/private/tmp/XYZ-forge-gh1037-sync-fixes-2026-10-12-verify')
OUT = Path('/Users/noelsaw/Documents/Codex/2026-10-12/task-2/task-results/sync-fixes')
ROOT = Path('/private/tmp/xyz1037-distribution-green-20261012')
if ROOT.exists() or ROOT.parent.resolve() != Path('/tmp').resolve():
    raise RuntimeError('fresh owned fixture root required')
ROOT.mkdir()
records = []
env = dict(os.environ, PYTHONDONTWRITEBYTECODE='1')
env.pop('XYZ_FORGE_ROOT', None)

def command(cwd, argv, check=True):
    r = subprocess.run(argv, cwd=cwd, env=env, capture_output=True, text=True, errors='replace', timeout=90)
    records.append({'cwd': str(cwd), 'argv': argv, 'rc': r.returncode, 'stdout': r.stdout, 'stderr': r.stderr})
    if check and r.returncode:
        raise RuntimeError(records[-1])
    return r

def git(root, *args):
    return command(root, ['git', '-C', str(root), *args]).stdout.strip()

def fixture_repo(root):
    root.mkdir()
    git(root, 'init', '-q', '-b', 'main')
    git(root, 'config', 'user.name', 'Distribution Fixture')
    git(root, 'config', 'user.email', 'fixture@example.invalid')
    git(root, 'commit', '--allow-empty', '-qm', 'fixture seed')

child = ROOT / 'mini-child'
fixture_repo(child)
git(child, 'remote', 'add', 'origin', str(child))
publisher = [sys.executable, '-B', str(SOURCE / 'utils/py/xyz_mini_sync.py'), '--dest', str(child), '--apply']
command(SOURCE, publisher)
entry = child / 'skills/weekly-planner'
seeded = entry.exists()
git(child, 'rm', '-r', '--', 'skills/weekly-planner')
git(child, 'commit', '-qm', 'fixture child removes its adapted entry')
command(SOURCE, publisher)
absent_after_first = not entry.exists()
command(SOURCE, publisher)
recreated_after_second = entry.exists()
mini = {'seeded': seeded, 'absent_after_first_publication': absent_after_first,
        'recreated_after_second_publication': recreated_after_second,
        'accepted_behavior': seeded and absent_after_first and not recreated_after_second,
        'child': str(child), 'push': False, 'origin': str(child)}

source_copy = ROOT / 'manager-source'
command(ROOT, ['git', 'clone', '--no-local', '--quiet', str(SOURCE), str(source_copy)])
bundle = source_copy / 'skills/3-weekly/skills-army-hq'
collection = ROOT / 'pulse-collection'
fixture_repo(collection)
shutil.copytree(bundle, collection / 'skills-army-hq')
shutil.copyfile(bundle / 'README.md', collection / 'README.md')
for name in ('intake.py', 'sync.py'):
    (collection / name).symlink_to('skills-army-hq/scripts/' + name)
(collection / '.gitignore').write_text('.deploy-skills*\ntargets.json\ncatalog.md\nchangelog.md\nbackups/\n.staging/\n*.zip\n*.lock\n__pycache__/\n*.pyc\n')
git(collection, 'add', '-A')
git(collection, 'commit', '-qm', 'fixture pulse payloads')
cli = [sys.executable, '-B', str(bundle / 'scripts/intake.py'), '--root', str(collection), '--apply']
command(ROOT, cli + ['init', '--adopt-existing'])
target_state = json.loads((collection / 'targets.json').read_text())
if any(t['enabled'] for t in target_state['targets']):
    raise RuntimeError('real target writes forbidden')
before = git(collection, 'rev-parse', 'HEAD')
with (bundle / 'README.md').open('a') as f:
    f.write('\nFixture manager README update.\n')
git(source_copy, 'add', '--', str(bundle / 'README.md'))
git(source_copy, 'commit', '-qm', 'fixture README payload update')
update = command(ROOT, cli + ['update', 'skills-army-hq', '--source', str(bundle)])
after = git(collection, 'rev-parse', 'HEAD')
dirty = git(collection, 'status', '--porcelain=v1')
manager = {'head_before': before, 'head_after': after, 'status': dirty,
           'warning': update.stderr, 'all_targets_disabled': True,
           'root_readme_refreshed': (collection / 'README.md').read_bytes() == (bundle / 'README.md').read_bytes(),
           'accepted_behavior': before != after and not dirty and 'committed skills-army-hq' in update.stderr,
           'collection': str(collection), 'network_publish': False}
report = {'tested_candidate': '11597ea6ba4fb491da70681d21e793eec5ec4d94', 'mini': mini, 'manager': manager, 'commands': records}
(OUT / 'distribution-falsifiers.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({'mini': mini, 'manager': manager}, indent=2))
if not (mini['accepted_behavior'] and manager['accepted_behavior']):
    raise SystemExit(1)
