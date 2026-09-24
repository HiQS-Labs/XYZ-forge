#!/usr/bin/env bash
# GH-492: isolated ledger fixtures, stubbed GitHub, no git commands or shared setup.
set -euo pipefail
GH492_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONDONTWRITEBYTECODE=1
python3 -B - "$GH492_ROOT" <<'PY'
import hashlib
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
sys.path.insert(0, str(Path(sys.argv[1]) / 'test' / 'lib'))
import pystub  # GH-788: stub header that survives a spaced interpreter path

source = Path(sys.argv[1])
app = Path(os.environ.get('GH492_APP', source / 'utils/py/releases_app.py'))
with tempfile.TemporaryDirectory(prefix='gh492-', dir=os.environ.get('GH492_TMPDIR')) as work:
    root = Path(work)
    # Only the ledger's lock-directory contract is needed; never call git in this fixture.
    (root / '.git').mkdir()
    (root / '.pdda-mode').write_text('observe\nROADMAP_SOURCE=releases\n')
    stub = root / 'gh'
    stub.write_text(pystub.launcher() + '''import json, os, sys
from pathlib import Path
if sys.argv[1] == 'api':
    path = sys.argv[2]
    assert path.startswith('repos/example/repo/issues/'), sys.argv
    number = path.rsplit('/', 1)[-1]
    print(json.dumps({'number': int(number),
                      'html_url': 'https://github.com/example/repo/issues/' + number,
                      'state': 'open' if number == '2' else 'closed', 'labels': []}))
    raise SystemExit(0)
assert sys.argv[1:3] == ['issue', 'view'], sys.argv
assert sys.argv[4:] == ['--json', 'state,stateReason'], sys.argv
url = sys.argv[3]
assert url.startswith('https://github.com/example/repo/issues/'), url
with open(os.environ['GH492_CALLS'], 'a') as f:
    f.write(url + '\\n')
number = url.rsplit('/', 1)[-1]
mode = os.environ.get('GH492_MODE', '')
if mode == 'failure' and number == '2':
    sys.exit(9)
if mode == 'malformed':
    print('[]')
elif mode == 'unknown':
    print(json.dumps({'state': 'CLOSED', 'stateReason': None}))
else:
    data = {'1': ('CLOSED', 'COMPLETED'), '2': ('OPEN', None),
            '3': ('CLOSED', 'NOT_PLANNED'), '5': ('CLOSED', 'COMPLETED')}
    state, reason = data[number]
    print(json.dumps({'state': state, 'stateReason': reason}))
''')
    stub.chmod(0o755)
    env = dict(os.environ, RELEASES_GH_BIN=str(stub), GH492_CALLS=str(root / 'calls'))
    # Do not inherit operator fault-injection or clock settings into the fixture.
    for key in ('RELEASES_APP_CRASH_AT', 'RELEASES_APP_NOW'):
        env.pop(key, None)

    def run(*args, expected=0, overrides=None):
        result = subprocess.run([sys.executable, '-B', str(app), '--root', str(root), *args],
                                env=dict(env, **(overrides or {})), capture_output=True, text=True)
        assert result.returncode == expected, (args, result.returncode, result.stdout, result.stderr)
        return result.stdout + result.stderr

    def snapshot():
        result = {}
        for name in ('releases.db', 'releases.sql'):
            path = root / name
            assert path.stat().st_size > 0
            result[name] = (path.stat().st_mtime_ns, hashlib.sha256(path.read_bytes()).hexdigest())
        return result

    def rows():
        with sqlite3.connect(root / 'releases.db') as conn:
            return conn.execute('SELECT gh_number,section,updated_at,raw_text FROM roadmap_items ORDER BY gh_number').fetchall()

    run('init', '--slug', 'example/repo')
    for number in (1, 2, 3, 4, 5):
        run('roadmap', 'add', '--issue-num', str(number), '--issue-url',
            f'https://github.com/example/repo/issues/{number}', '--title', f'Issue {number}',
            '--created', '2026-09-08', '--doc-path', f'PROJECT/1-INBOX/GH-{number}.md')
        run('roadmap', 'move', '--issue-num', str(number), '--section',
            'Completed' if number == 4 else 'In progress')
    before_rows = rows()
    assert len(before_rows) == 5
    before = snapshot()
    for flags in ((), ('--dry-run',)):
        output = run('roadmap', 'reconcile-state', *flags)
        assert 'would move GH-1: In progress -> Completed' in output, output
        assert 'would move GH-3: In progress -> Deferred · vision' in output, output
        assert 'would move GH-5: In progress -> Completed' in output, output
        assert 'GH-2' not in output and 'GH-4' not in output, output
        assert snapshot() == before, 'dry run changed DB/dump digest or mtime'
    print('PASS: default and explicit dry-run preserve DB/dump bytes and mtime')

    for overrides in ({'RELEASES_GH_BIN': str(root / 'missing-gh')},
                      {'GH492_MODE': 'failure'}, {'GH492_MODE': 'malformed'},
                      {'GH492_MODE': 'unknown'}):
        output = run('roadmap', 'reconcile-state', '--apply', expected=3, overrides=overrides)
        assert 'refusing to guess issue state' in output, output
        assert snapshot() == before, 'failed lookup partially wrote the sweep'
    print('PASS: missing CLI, later lookup failure, malformed JSON and unknown reason refuse without writes')

    # Cached PDDA warning shares its issue table and never performs a remote lookup.
    cache = root / 'cache.tsv'
    cache.write_text('1\tCLOSED\n2\tOPEN\n3\tCLOSED\n4\tCLOSED\n5\tCLOSED\n')
    def pdda():
        result = subprocess.run(['bash', str(source / 'utils/pdda/pdda.sh'), 'issue-doc-sync'],
            env=dict(env, PDDA_REPO_ROOT=str(root), PDDA_ISSUE_SYNC_SOURCE='cache',
                     PDDA_GH_STATE_CACHE=str(cache), PDDA_ACTIVITY_LOG=str(root / 'activity.jsonl'),
                     PDDA_MODE='full', PDDA_FORMAT='json'), capture_output=True, text=True)
        assert result.returncode == 0, (result.stdout, result.stderr)
        return result.stdout
    output = pdda()
    assert 'reconcile-roadmap-state' in output and 'issue #1 is CLOSED' in output, output
    assert 'issue #2 is CLOSED' not in output, output
    assert snapshot() == before
    print('PASS: cached section drift warns without changing the ledger or blocking full mode')

    # GH-605: the sweep's row changes, one receipt and all per-row terminal events are one
    # transaction. Fail the second event insert and prove every surface rolls back.
    with sqlite3.connect(root / 'releases.db') as conn:
        baseline_counts = (
            conn.execute("SELECT value FROM settings WHERE key='generation'").fetchone()[0],
            conn.execute("SELECT COUNT(*) FROM op_receipts").fetchone()[0],
            conn.execute("SELECT COUNT(*) FROM work_events").fetchone()[0],
        )
        conn.execute("""CREATE TRIGGER gh605_fail_deferred BEFORE INSERT ON work_events
                        WHEN NEW.event='deferred' BEGIN SELECT RAISE(ABORT,'gh605 injected'); END""")
        conn.commit()
    output = run('roadmap', 'reconcile-state', '--apply', expected=1)
    with sqlite3.connect(root / 'releases.db') as conn:
        after_failure = (
            conn.execute("SELECT value FROM settings WHERE key='generation'").fetchone()[0],
            conn.execute("SELECT COUNT(*) FROM op_receipts").fetchone()[0],
            conn.execute("SELECT COUNT(*) FROM work_events").fetchone()[0],
        )
        conn.execute('DROP TRIGGER gh605_fail_deferred')
        conn.commit()
    assert after_failure == baseline_counts, (baseline_counts, after_failure, output)
    assert rows() == before_rows, 'event insert failure left roadmap row mutations behind'
    assert not list((root / '.git').glob('*journal*.json')), 'precommit journal survived rollback'
    print('PASS: injected second terminal-event failure rolls back rows, receipt, events and generation')

    output = run('roadmap', 'reconcile-state', '--apply')
    after_rows = rows()
    assert [r[1] for r in after_rows] == ['Completed', 'In progress', 'Deferred · vision', 'Completed', 'Completed'], after_rows
    assert after_rows[1] == before_rows[1] and after_rows[3] == before_rows[3]
    assert [r[3] for r in after_rows] == [r[3] for r in before_rows], 'raw text changed'
    with sqlite3.connect(root / 'releases.db') as conn:
        assert conn.execute("SELECT COUNT(*) FROM op_receipts WHERE op='roadmap-reconcile-state'").fetchone()[0] == 1
        terminal_events = conn.execute("""SELECT event,txn_id,payload FROM work_events
                                          WHERE json_extract(payload,'$.source')='roadmap-reconcile-state'
                                          ORDER BY id""").fetchall()
        assert [r[0] for r in terminal_events] == ['completed', 'deferred', 'completed'], terminal_events
        assert len({r[1] for r in terminal_events}) == 1, terminal_events
    assert 'reconcile-roadmap-state' not in pdda()
    print('PASS: apply corrects both closure reasons, preserves open/terminal rows and records one transaction')

    after = snapshot()
    (root / 'calls').write_text('')
    output = run('roadmap', 'reconcile-state', '--apply')
    assert 'no changes; nothing written' in output, output
    assert snapshot() == after, 'second sweep wrote state or receipts'
    assert (root / 'calls').read_text().splitlines() == ['https://github.com/example/repo/issues/2']
    print('PASS: second sweep writes nothing and never queries terminal rows')
PY
