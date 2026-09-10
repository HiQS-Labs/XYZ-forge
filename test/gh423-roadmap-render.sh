#!/usr/bin/env bash
# GH-423: hermetic renderer/parser contract. No git commands, network, or caller DB writes.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONDONTWRITEBYTECODE=1
python3 - "$ROOT_DIR" <<'PY'
import contextlib
import io
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(sys.argv[1])
sys.path.insert(0, str(ROOT / 'utils/py'))
import releases_app as app
import _marathon_plan as planner


class RoadmapRender(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='gh423-', dir=os.environ.get('GH423_TEST_TMP'))
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.conn = sqlite3.connect(self.root / 'releases.db')
        self.conn.row_factory = sqlite3.Row
        self.addCleanup(self.conn.close)
        self.conn.execute('''CREATE TABLE roadmap_items (
            global_id TEXT, gh_number INTEGER, title TEXT, section TEXT, position INTEGER,
            raw_text TEXT, status_marker TEXT, doc_path TEXT, issue_url TEXT,
            complexity INTEGER, risk INTEGER, effort INTEGER,
            rating_pri INTEGER, rating_sev INTEGER, rating_appeal INTEGER,
            rating_effort INTEGER, rating_ovr INTEGER)''')
        self.rows = [
            ('rmi-b', 423, 'GH-423 · DB-only renderer', 'Queue / parked intake', 2,
             '- **GH-423 · DB-only renderer** 🆕 rated 70/80/90/60\n  continuation [doc](PROJECT/2-WORKING/GH-423.md)'),
            ('rmi-a', 422, 'GH-422 · Link bullet', 'Queue / parked intake', 1,
             '- [GH-422 · Link bullet](PROJECT/2-WORKING/GH-422.md) 🆕'),
            ('rmi-c', None, 'TMP-parked idea', 'Queue / parked intake', 2, ''),
            ('rmi-d', 421, 'GH-421 · Finished', 'Completed', 1,
             '- **GH-421 · Finished** ✅'),
            ('rmi-e', 424, 'GH-424 · Fallback', 'In progress', 1, '   '),
        ]
        self.conn.executemany('''INSERT INTO roadmap_items
            (global_id, gh_number, title, section, position, raw_text) VALUES (?,?,?,?,?,?)''', self.rows)
        self.conn.execute('''UPDATE roadmap_items SET status_marker='🚧',
            doc_path='PROJECT/2-WORKING/GH-424.md', issue_url='https://github.com/acme/repo/issues/424',
            rating_pri=10, rating_sev=20, rating_appeal=30, rating_effort=40, rating_ovr=150
            WHERE gh_number=424''')
        self.conn.commit()

    def parse_both(self, rendered):
        self.assertTrue(rendered.strip())
        path = self.root / 'rendered.md'
        path.write_text(rendered)
        engine = planner.Engine.__new__(planner.Engine)
        planned = engine._parse_ledger(rendered)
        mirrored = app.parse_roadmap_ledger(path)
        self.assertTrue(planned)
        self.assertTrue(mirrored)
        expected = {(r[1], r[2]) for r in self.rows}
        self.assertEqual({(r['gh_number'], r['title']) for r in mirrored}, expected)
        self.assertEqual({(engine._gh_issue_of(r), r['title']) for r in planned}, expected)
        self.assertEqual(len(planned), len(self.rows))
        self.assertEqual(sum(app._is_ledger_bullet(l) for l in rendered.splitlines()), len(self.rows))
        return planned, mirrored

    def test_roundtrip_and_verbatim_order(self):
        rendered = app.roadmap_render(self.conn)
        planned, mirrored = self.parse_both(rendered)
        self.assertEqual(rendered, app.roadmap_render(self.conn))
        for row in self.rows:
            if row[5].strip():
                self.assertIn(row[5] + '\n\n', rendered)
        queue = [r['title'] for r in planned if r['section'] == 'Queue / parked intake']
        self.assertEqual(queue, [self.rows[i][2] for i in (1, 0, 2)])
        fallback = next(r for r in mirrored if r['gh_number'] == 424)
        self.assertEqual(fallback['rating_ovr'], 150)
        self.assertEqual(fallback['doc_path'], 'PROJECT/2-WORKING/GH-424.md')
        self.assertEqual(fallback['status_marker'], '🚧')

    def test_planner_reader_uses_explicit_render(self):
        rendered = app.roadmap_render(self.conn)
        path = self.root / 'rendered.md'
        path.write_text(rendered)
        engine = planner.Engine.__new__(planner.Engine)
        engine.ROOT, engine.ROADMAP = str(self.root), str(path)
        engine.QUEUE_DIR = str(self.root)  # GH-418: SOURCE_LINK is now computed pre-read
        # Stop at scheduling, after the production reader selects and parses its whole input.
        # No network, git, preflight, or marathon side effects are needed to prove this boundary.
        class ReaderComplete(Exception):
            pass
        with patch.dict(os.environ, {'QUEUE_PLAN_ROADMAP': str(path)}), \
             patch.object(engine, '_parse_ledger', wraps=engine._parse_ledger) as read, \
             patch.object(engine, '_gh_issue_of', side_effect=ReaderComplete):
            with self.assertRaises(ReaderComplete):
                engine.run(str(self.root / 'unused-plan.md'))
            read.assert_called_once_with(rendered)
        self.parse_both(rendered)

    def test_cli_stdout_out_and_read_only(self):
        db = self.root / 'releases.db'
        before = db.read_bytes()
        cmd = [sys.executable, str(ROOT / 'utils/py/releases_app.py'), '--root', str(self.root), 'roadmap', 'render']
        first = subprocess.run(cmd, capture_output=True, text=True, check=True)
        self.parse_both(first.stdout)
        out = self.root / 'ledger with spaces.md'
        second = subprocess.run(cmd + ['--out', out.name], cwd=self.root,
                                capture_output=True, text=True, check=True)
        self.assertEqual(second.stdout, '')
        self.assertEqual(out.read_text(), first.stdout)
        self.assertEqual(db.read_bytes(), before)
        self.assertEqual(sorted(p.name for p in self.root.iterdir()),
                         ['ledger with spaces.md', 'releases.db', 'rendered.md'])

    def test_output_refusals_and_untracked_roadmap(self):
        out = self.root / 'ROADMAP.md'
        out.write_text('frozen sentinel\n')
        argv = ['--root', str(self.root), 'roadmap', 'render', '--out', str(out)]
        for code in (0, 128):
            with patch.object(app.subprocess, 'run', return_value=subprocess.CompletedProcess([], code)) as git, \
                 contextlib.redirect_stderr(io.StringIO()) as err:
                with self.assertRaises(SystemExit) as refused:
                    app.main(argv)
                self.assertEqual(refused.exception.code, 3)
                self.assertIn('rule=roadmap-render-output', err.getvalue())
                self.assertEqual(git.call_args.args[0],
                    ['git', '-C', str(self.root.resolve()), 'ls-files', '--error-unmatch', '--', 'ROADMAP.md'])
                self.assertEqual(out.read_text(), 'frozen sentinel\n')
        alias = self.root / 'alias.md'
        alias.symlink_to(out)
        with patch.object(app.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0)), \
             contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit):
                app.main(argv[:-1] + [str(alias)])
        with patch.object(app.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1)):
            app.main(argv)
        self.parse_both(out.read_text())
        before = (self.root / 'releases.db').read_bytes()
        with contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit):
                app.main(argv[:-1] + [str(self.root / 'releases.db')])
        self.assertEqual((self.root / 'releases.db').read_bytes(), before)

    def test_tracked_roadmap_symlink_and_git_unavailable(self):
        target = self.root / 'frozen.md'
        target.write_text('sentinel')
        out = self.root / 'ROADMAP.md'
        out.symlink_to(target)
        argv = ['--root', str(self.root), 'roadmap', 'render', '--out', str(out)]
        for result in (subprocess.CompletedProcess([], 0), FileNotFoundError('git')):
            with patch.object(app.subprocess, 'run') as git, contextlib.redirect_stderr(io.StringIO()):
                if isinstance(result, Exception):
                    git.side_effect = result
                else:
                    git.return_value = result
                with self.assertRaises(SystemExit) as refused:
                    app.main(argv)
                self.assertEqual(refused.exception.code, 3)
                self.assertEqual(target.read_text(), 'sentinel')
                self.assertTrue(out.is_symlink())

    def test_fallback_synthesizes_missing_gh_prefix(self):
        self.conn.execute("UPDATE roadmap_items SET title='Plain fallback' WHERE gh_number=424")
        rendered = app.roadmap_render(self.conn)
        self.assertIn('- **GH-424 · Plain fallback**', rendered)
        item = next(r for r in planner.Engine.__new__(planner.Engine)._parse_ledger(rendered)
                    if r['title'] == 'GH-424 · Plain fallback')
        self.assertEqual(planner.Engine._gh_issue_of(item), 424)

    def test_empty_schema_and_custom_section_preserved(self):
        with sqlite3.connect(':memory:') as empty:
            self.assertEqual(app.roadmap_render(empty), '## Ledger\n')
        self.conn.execute("DELETE FROM roadmap_items")
        self.assertEqual(app.roadmap_render(self.conn), '## Ledger\n')
        self.conn.execute('''INSERT INTO roadmap_items
            (global_id,title,section,position,raw_text) VALUES
            ('rmi-custom','Custom item','Custom section',1,'- **Custom item**')''')
        rendered = app.roadmap_render(self.conn)
        self.assertIn('### Custom section\n\n- **Custom item**', rendered)
        # The planner's section filter is intentional; rendering must not relabel source state.
        self.assertEqual(planner.Engine.__new__(planner.Engine)._parse_ledger(rendered), [])

    def test_negative_control_missing_row_is_detected(self):
        self.parse_both(app.roadmap_render(self.conn))
        self.conn.execute('DELETE FROM roadmap_items WHERE gh_number=423')
        with self.assertRaises(AssertionError) as omitted:
            self.parse_both(app.roadmap_render(self.conn))
        self.assertIn('GH-423', str(omitted.exception))
        print('NEGATIVE CONTROL: DB-only GH-423 omission trips the round-trip assertion')


unittest.main(argv=[sys.argv[0]], verbosity=2)
PY
