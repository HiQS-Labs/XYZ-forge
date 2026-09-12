#!/usr/bin/env bash
# GH-424: real ledger writes in isolated temporary directories; no git or network commands.
set -euo pipefail
GH424_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONDONTWRITEBYTECODE=1
python3 - "$GH424_ROOT" <<'PY'
import contextlib
import importlib.util
import io
import os
from pathlib import Path
import sqlite3
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

source = Path(sys.argv.pop())
sys.path.insert(0, str(source / 'utils/py'))

def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod

app = load('gh424_app', os.environ.get('GH424_APP', source / 'utils/py/releases_app.py'))
wave = load('gh424_wave', os.environ.get('GH424_WAVE', source / 'utils/py/wave_reconcile.py'))
artifacts = ('releases.db', 'releases.sql',
             'RELEASES-PREVIEW.html', 'LEADERBOARD.html', 'LEADERBOARD.md')

class MarkerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='gh424-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        # WriterLock only requires a private directory for its lock and audit sidecars.
        # This is not a git checkout and nothing invokes git against it.
        (self.root / '.git').mkdir()
        (self.root / '.pdda-mode').write_text('ROADMAP_SOURCE=releases\n')
        self.cli('init', '--slug', 'gh424-fixture')
        self.doc = 'PROJECT/1-INBOX/GH-424-test.md'
        (self.root / self.doc).parent.mkdir(parents=True)
        (self.root / self.doc).write_text('# fixture\n')
        for n in (424, 425):
            self.cli('roadmap', 'add', '--issue-num', str(n), '--title', f'fixture {n}',
                     '--created', '2026-09-08', '--issue-url', f'https://example.test/issues/{n}',
                     '--doc-path', self.doc)
        for name in artifacts[2:]:
            (self.root / name).write_text(f'original {name}\n')
        self.cli('check')

    def cli(self, *args, expected=0):
        output = io.StringIO()
        rc = 0
        with patch.object(sys, 'argv', ['releases', '--root', str(self.root), *args]), \
             contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
            try:
                app.main()
            except SystemExit as exc:
                rc = exc.code
        self.assertEqual(rc, expected, output.getvalue())
        return output.getvalue()

    def rows(self):
        with sqlite3.connect(self.root / 'releases.db') as conn:
            conn.row_factory = sqlite3.Row
            return [dict(r) for r in conn.execute('SELECT * FROM roadmap_items ORDER BY gh_number')]

    def snapshot(self):
        result = {n: (self.root / n).read_bytes() if (self.root / n).exists() else None
                  for n in artifacts}
        self.assertTrue(result['releases.db'])
        self.assertTrue(result['releases.sql'])
        return result

    def test_marker_writes_preserve_fields_and_receipt_bulk(self):
        before = self.rows()
        for row in before:
            with patch.object(app, 'now_iso', return_value='2099-01-01T00:00:00Z'):
                self.cli('roadmap', 'update', '--issue-num', str(row['gh_number']), '--status-marker', '✅')
        after = self.rows()
        self.assertEqual(len(after), 2)
        for old, new in zip(before, after):
            self.assertEqual(new['status_marker'], '✅')
            self.assertEqual(new['updated_at'], '2099-01-01T00:00:00Z')
            for key in old.keys() - {'updated_at', 'status_marker'}:
                self.assertEqual(new[key], old[key], key)
        with sqlite3.connect(self.root / 'releases.db') as conn:
            receipts = conn.execute("SELECT op, target_gid, at FROM op_receipts WHERE op='roadmap-update'").fetchall()
        self.assertEqual(receipts, [('roadmap-update', r['global_id'], '2099-01-01T00:00:00Z') for r in before])
        self.cli('check')
        # Identical raw_text must not short-circuit an explicitly supplied marker.
        self.cli('roadmap', 'update', '--gid', after[0]['global_id'],
                 '--raw-text', after[0]['raw_text'], '--status-marker', '🚧')
        self.assertEqual(self.rows()[0]['status_marker'], '🚧')
        self.cli('roadmap', 'update', '--issue-num', '424', '--status-marker', '🆕', '--section', 'In progress')
        self.assertEqual(self.rows()[0]['status_marker'], '🆕')
        self.assertEqual(self.rows()[0]['section'], 'In progress')
        self.cli('check')

    def test_marker_and_issue_url_update_together(self):
        old = self.rows()[0]
        url = 'https://github.com/test/repo/issues/424'
        self.cli('roadmap', 'update', '--issue-num', '424',
                 '--raw-text', old['raw_text'], '--status-marker', '⛔', '--issue-url', url)
        row = self.rows()[0]
        self.assertEqual(row['status_marker'], '⛔')
        self.assertEqual(row['issue_url'], url)
        self.assertEqual(row['raw_text'], old['raw_text'])
        self.cli('check')

    def test_refusals_and_dry_run_do_not_write(self):
        before = self.snapshot()
        self.cli('roadmap', 'update', '--issue-num', '424', '--status-marker', 'typo', expected=2)
        self.cli('roadmap', 'update', '--status-marker', '✅', expected=3)
        self.cli('roadmap', 'update', '--issue-num', '999', '--status-marker', '✅', expected=3)
        self.cli('roadmap', 'update', '--issue-num', '424', '--gid', 'rmi-no', '--status-marker', '✅', expected=3)
        self.cli('roadmap', 'update', '--issue-num', '424', expected=3)
        out = self.cli('roadmap', 'update', '--issue-num', '424', '--status-marker', '✅', '--dry-run')
        self.assertIn('status_marker: -> ✅', out)
        self.assertEqual(before, self.snapshot())

    def test_legacy_verbs_do_not_infer_marker(self):
        self.cli('roadmap', 'update', '--issue-num', '424', '--raw-text', '- **GH-424 · fixture** ✅ done')
        self.cli('roadmap', 'move', '--issue-num', '424', '--section', 'Completed')
        self.cli('roadmap', 'repoint', '--issue-num', '424', '--doc-path', self.doc)
        self.cli('roadmap', 'rate', '--issue-num', '424', '--rated', '1/1/1/1')
        self.cli('roadmap', 'sync')
        self.assertEqual(self.rows()[0]['status_marker'], '🆕')
        self.cli('check')

    def exercise_rollback(self, absent=False):
        if absent:
            for name in artifacts[2:]:
                (self.root / name).unlink()
        before = self.snapshot() if not absent else {
            n: (self.root / n).read_bytes() if (self.root / n).exists() else None for n in artifacts}
        journal = wave.RollbackJournal()
        self.addCleanup(journal.cleanup)
        calls = []

        def run(cmd, **kwargs):
            calls.append(cmd)
            if 'update' in cmd:
                # First per-issue ledger mutation, through the real CLI writer.
                self.cli(*cmd[cmd.index('roadmap'):])
                return SimpleNamespace(returncode=0, stdout='', stderr='')
            # A second successful ledger write, then an injected downstream failure.
            self.cli('roadmap', 'update', '--issue-num', '425', '--section', 'Completed')
            for name in artifacts[2:]:
                (self.root / name).write_text(f'regenerated {name}\n')
            return SimpleNamespace(returncode=1, stdout='', stderr='GH424 injected after second write')

        with patch.object(wave.subprocess, 'run', side_effect=run), \
             patch.object(wave, 'harness_tool', side_effect=lambda root, path: str(source / path)):
            self.assertTrue(wave.update_roadmap_entry(str(self.root), 424, 42, '2026-09-08', journal=journal))
            self.assertNotEqual(before['releases.db'], (self.root / 'releases.db').read_bytes())
            with self.assertRaises(wave.ReconcileError) as raised:
                wave.run_subprocesses(str(self.root), journal=journal)
            self.assertEqual(raised.exception.code, 6)
            journal.rollback()
        self.assertEqual(len(calls), 2)
        after = {n: (self.root / n).read_bytes() if (self.root / n).exists() else None for n in artifacts}
        # Run the consistency check even when byte comparisons will fail:
        # names generation-mismatch, not just generic dirty bytes.
        check = io.StringIO()
        with contextlib.redirect_stdout(check), contextlib.redirect_stderr(check):
            try:
                self.cli('check')
            except AssertionError as exc:
                print(exc)
        if check.getvalue():
            print(check.getvalue())
        self.assertEqual([n for n in artifacts if before[n] != after[n]], [],
                         'rollback must restore every artifact before the FIRST ledger write')
        self.cli('check')

    def test_rollback_restores_all_artifacts_before_first_write(self):
        self.exercise_rollback()

    def test_rollback_removes_originally_absent_artifacts(self):
        self.exercise_rollback(absent=True)

unittest.main(verbosity=2)
PY
