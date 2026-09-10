#!/usr/bin/env bash
# GH-418: hermetic planner source regression. No git, network, or shared fixtures.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHONDONTWRITEBYTECODE=1 python3 - "$HERE/.." <<'PY'
import builtins
import contextlib
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import runpy
import sqlite3
import sys
import tempfile
from types import SimpleNamespace
from unittest.mock import patch

repo = Path(sys.argv[1]).resolve()
sys.path.insert(0, str(repo / 'utils/py'))
import releases_app

engine_path = Path(os.environ.get('GH418_ENGINE_PATH', repo / 'utils/py/_marathon_plan.py'))
spec = importlib.util.spec_from_file_location('_marathon_plan', engine_path)
engine = importlib.util.module_from_spec(spec)
spec.loader.exec_module(engine)
sys.modules['_marathon_plan'] = engine
cli_path = Path(os.environ.get('GH418_CLI_PATH', repo / 'utils/py/marathon_plan.py'))
scratch = os.environ.get('GH418_SCRATCH')
work = Path(tempfile.mkdtemp(prefix='gh418.', dir=scratch)).resolve()
print('fixture:', work)
print('engine sha256:', hashlib.sha256(engine_path.read_bytes()).hexdigest())

# Every fixture lives under the allocated root. No external subprocess is needed;
# unexpected git/gh/other calls fail at their use boundary.
def no_process(*args, **kwargs):
    raise AssertionError('unexpected subprocess: %r' % (args,))


def fixture(name, mode):
    root = work / name
    root.mkdir()
    (root / '.git').mkdir()  # Releases lock directory only; not a git checkout.
    (root / '.pdda-mode').write_text(mode)
    (root / '.branches').write_text('')
    (root / '.base-files').write_text('[]')
    (root / 'PROJECT/2-WORKING').mkdir(parents=True)
    # Use the actual write verbs, not hand-authored roadmap rows.
    with contextlib.redirect_stdout(io.StringIO()):
        releases_app.cmd_init(SimpleNamespace(root=str(root), slug='gh418-fixture'))
    (root / 'ROADMAP.md').write_text('# Roadmap\n## Ledger\n### Queue / parked intake\n'
                                    '- **GH-999 · stale-only** 🆕\n')
    return root


def park(root, number=418):
    doc = 'PROJECT/2-WORKING/GH-%s-db-only.md' % number
    contract = {'target': {'repo': '.', 'ref': 'development'}, 'gate': 'true',
                'fix_probes': [{'type': 'path_absent', 'path': 'MISSING'}],
                'artifacts': ['src/item%s.py' % number]}
    (root / doc).write_text('---\ntitle: DB-only item\ncomplexity: 2\nrisk: 2\neffort: 2\n---\n'
                            '## Swarm Preflight Contract\n```json\n' + json.dumps(contract) + '\n```\n')
    with contextlib.redirect_stdout(io.StringIO()):
        releases_app.cmd_roadmap_add(SimpleNamespace(
            root=str(root), issue_num=number, title='DB-only item', created='2026-09-08',
            issue_url='https://github.com/o/r/issues/%s' % number,
            doc_path=doc, raw_text=None, dry_run=False))


def plan(root, override=None, forbid_markdown=False, args=()):
    env = {k: v for k, v in os.environ.items() if not k.startswith(('QUEUE_PLAN_', 'XYZ_'))}
    env.update(QUEUE_PLAN_ROOT=str(root), QUEUE_PLAN_TODAY='2026-09-08',
               QUEUE_PLAN_NOW='2026-09-08T00:00:00Z', QUEUE_PLAN_GH='off',
               QUEUE_PLAN_BRANCH='development', QUEUE_PLAN_BRANCHES_FILE=str(root / '.branches'),
               QUEUE_PLAN_ZONES_FILE=str(repo / 'utils/marathon-plan-zones.default.json'),
               QUEUE_PLAN_BASE_FILES_FILE=str(root / '.base-files'), TMPDIR=str(work))
    if override is not None:
        env['QUEUE_PLAN_ROADMAP'] = str(override)
    output, errors = io.StringIO(), io.StringIO()
    real_open = builtins.open
    def guarded_open(path, mode='r', *a, **kw):
        if forbid_markdown and isinstance(path, (str, os.PathLike)):
            if Path(path).resolve() == (root / 'ROADMAP.md').resolve() and 'r' in mode:
                raise AssertionError('releases-mode read of frozen ROADMAP.md')
        return real_open(path, mode, *a, **kw)
    # tempfile caches its directory: pin it as well as TMPDIR for in-process CLI runs.
    with patch.dict(os.environ, env, clear=True), patch.object(tempfile, 'tempdir', str(work)), \
         patch.object(sys, 'argv', [str(cli_path), *args]), patch('builtins.open', guarded_open), \
         contextlib.redirect_stdout(output), contextlib.redirect_stderr(errors):
        try:
            runpy.run_path(str(cli_path), run_name='__main__')
        except SystemExit as exc:
            rc = exc.code
    doc = root / 'PROJECT/2-WORKING/MARATHON-PLAN-2026-09-08.md'
    text = doc.read_text() if doc.exists() else ''
    return rc, output.getvalue(), errors.getvalue(), text


def db_only(result):
    rc, out, err, doc = result
    assert out.strip() and doc.strip(), (rc, out, err)
    assert '| [#418]' in doc and '**Wave 1:** #418' in doc, 'DB-only #418 absent from active plan'
    assert rc == 0, (rc, out, err)
    assert '#999' not in doc, 'stale-only #999 leaked into plan'


with patch('subprocess.run', no_process), patch('subprocess.check_output', no_process), \
     patch('subprocess.check_call', no_process):
    # First assertion is also the pre-fix replay: spaced mode syntax is already
    # accepted by the shared resolver but the old planner ignores it.
    root = fixture('spaced-mode', 'ROADMAP_SOURCE = releases # canonical\n')
    park(root)
    result = plan(root)
    (work / 'db-only-report.txt').write_text(result[1] + result[2])
    (work / 'db-only-plan.md').write_text(result[3])
    db_only(result)
    assert 'releases.db (roadmap_items)' in result[3] and 'ROADMAP.md' not in result[3]
    print('PASS: DB-only CLI-parked item appears; stale markdown excluded; real source named')

    # Dynamic canary covers the shipped Python planner path, including failed DB
    # reads: any current-state read of ROADMAP.md fails immediately.
    db_only(plan(root, forbid_markdown=True))
    (root / '.pdda-mode').write_text('ROADMAP_SOURCE=releases\n')
    db_only(plan(root, forbid_markdown=True))
    original_loader = engine.Engine._load_ledger_from_db
    def stale_read(self, db_path):
        self._read_file_safe(str(root / 'ROADMAP.md'))
        return original_loader(self, db_path)
    with patch.object(engine.Engine, '_load_ledger_from_db', stale_read):
        try:
            plan(root, forbid_markdown=True)
        except AssertionError as exc:
            assert str(exc) == 'releases-mode read of frozen ROADMAP.md', str(exc)
        else:
            raise AssertionError('stale-read canary failed to detect the injected read')
    print('PASS: negative control detects an injected releases-mode ROADMAP.md read')
    (root / 'ROADMAP.md').unlink()
    db_only(plan(root, forbid_markdown=True))
    print('PASS: releases-mode never reads ROADMAP.md (present or absent)')

    # Empty authoritative ledger is valid; missing/corrupt/unmigrated DB is an error.
    empty = fixture('empty', 'ROADMAP_SOURCE=releases\n')
    rc, out, err, doc = plan(empty, forbid_markdown=True)
    assert rc == 0 and 'items=0' in out and doc.strip() and '#999' not in doc
    print('PASS: empty DB stays empty, without stale-file fallback')
    for kind in ('missing', 'corrupt', 'no-table'):
        broken = fixture(kind, 'ROADMAP_SOURCE=releases\n')
        (broken / 'releases.db').unlink()
        if kind == 'corrupt':
            (broken / 'releases.db').write_text('not sqlite')
        elif kind == 'no-table':
            with sqlite3.connect(broken / 'releases.db') as conn:
                conn.execute('CREATE TABLE unrelated (id INTEGER)')
        rc, out, err, doc = plan(broken, forbid_markdown=True)
        assert rc == 3 and 'releases.db' in err and not doc, (kind, rc, err)
        if kind == 'missing':
            assert not (broken / 'releases.db').exists()
    print('PASS: missing/corrupt/unmigrated DB fails closed without creating a DB')

    legacy = fixture('legacy', '# ROADMAP_SOURCE=releases\nROADMAP_SOURCE=markdown\n')
    park(legacy)
    rc, out, err, doc = plan(legacy)
    assert rc == 5 and '#999' in doc and '#418' not in doc and 'source: ../../ROADMAP.md' in doc
    (legacy / 'ROADMAP.md').unlink()
    assert plan(legacy)[0] == 3  # A shadow DB cannot silently replace the legacy ledger.
    print('PASS: legacy mode still uses markdown, including with a shadow DB')

    override = work / 'override.md'
    override.write_text('# Roadmap\n## Ledger\n### Queue / parked intake\n- **GH-777 · fixture override**\n')
    rc, out, err, doc = plan(root, override=override)
    assert rc == 5 and '#777' in doc and '#418' not in doc and 'override.md' in doc
    assert plan(root, override=work / 'absent.md')[0] == 3
    print('PASS: explicit test-only override retained and accurately labelled')

    # Read-only DB consumption: neither ledger nor dump may change while planning.
    before = {p.name: p.read_bytes() for p in (root / 'releases.db', root / 'releases.sql')}
    db_only(plan(root, forbid_markdown=True))
    assert before == {p.name: p.read_bytes() for p in (root / 'releases.db', root / 'releases.sql')}
    print('PASS: planner leaves DB and dump byte-identical')

print('PASS: GH-418 planner ledger source')
PY
