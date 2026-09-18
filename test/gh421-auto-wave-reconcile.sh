#!/usr/bin/env bash
# GH-421: in-process CLI fixtures; never invokes git or network.
set -euo pipefail
GH421_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONDONTWRITEBYTECODE=1
python3 - "$GH421_ROOT" <<'PY'
import contextlib
import importlib.util
import io
import json
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
app = load('gh421_app', source / 'utils/py/releases_app.py')
wave = load('gh421_wave', os.environ.get('GH421_WAVE', source / 'utils/py/wave_reconcile.py'))

class ReconcileTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='gh421-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / '.git').mkdir()
        (self.root / '.pdda-mode').write_text('ROADMAP_SOURCE=releases\n')
        self.cli('init', '--slug', 'test/repo')
        self.cli('add', '--status', 'active', '--description', 'fixture',
                 '--tracking-issue', 'https://github.com/test/repo/issues/99')
        self.gid = self.rows('SELECT global_id FROM releases')[0]['global_id']
        self.doc = 'PROJECT/2-WORKING/GH-421-fixture.md'
        (self.root / self.doc).parent.mkdir(parents=True)
        (self.root / self.doc).write_text('---\nstatus: 2-WORKING\nupdated: 2026-09-01\n---\n## Lessons Learned\nFixture.\n')
        self.cli('roadmap', 'add', '--issue-num', '421', '--title', 'fixture',
                 '--created', '2026-09-01', '--issue-url', 'https://github.com/test/repo/issues/421',
                 '--doc-path', self.doc)
        self.cli('manifest', 'dial-in', '--gid', self.gid, 'https://github.com/test/repo/issues/421')
        self.pr = dict(number=42, state='MERGED', baseRefName='development', title='fixture',
                       body='Closes #421', mergedAt='2026-09-08T00:00:00Z', mergeCommit={'oid': 'a'*40})
        self.offline = {'prs': [self.pr], 'issues': [{'number': 421, 'state': 'CLOSED'}]}
        (self.root / 'offline.json').write_text(json.dumps(self.offline))
        (self.root / 'TESTS-RESULTS').mkdir()
        (self.root / 'TESTS-RESULTS/provenance.jsonl').write_text('{"pr":42}\n')
        self.calls = []
        self.fail_after = None
        self.planner_finding = None  # GH-684: a real-shaped marathon-plan exit-4 finding, when set

    def test_pre_merge_ignores_supporting_notes_in_active_and_completed_dirs(self):
        for stage in ('2-WORKING', '3-COMPLETED'):
            for name in ('GH-421-canonical.md', '421-canonical.md'):
                with self.subTest(stage=stage, name=name), tempfile.TemporaryDirectory() as root:
                    folder = Path(root) / 'PROJECT' / stage
                    folder.mkdir(parents=True)
                    canonical = folder / name
                    canonical.write_text('canonical task document')
                    (folder / 'recon-GH-421-notes.md').write_text('supporting notes')
                    (folder / 'GH-4210-unrelated.md').write_text('unrelated task')
                    seen = []
                    real_listdir = os.listdir
                    def git_output(command, **kwargs):
                        if command[1] == 'log':
                            return 'Fix task\nCloses #421\n'
                        if command[1] == 'diff':
                            return ''
                        return 'a' * 40 + '\n'
                    with patch.object(wave.subprocess, 'check_output', side_effect=git_output), \
                         patch.object(wave, 'github_slug_from_origin', return_value='test/repo'), \
                         patch.object(wave.os, 'listdir', side_effect=lambda p: sorted(real_listdir(p), reverse=True)), \
                         patch.object(wave, 'validate_frontmatter_schema', side_effect=lambda p: seen.append(p)), \
                         patch.object(wave, 'validate_lessons_learned', return_value=None), \
                         patch.object(wave, 'validate_pre_merge_receipts', return_value=None), \
                         contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()), \
                         self.assertRaises(SystemExit) as stopped:
                        wave.run_pre_merge(root, SimpleNamespace(pr=None, offline=True))
                    self.assertEqual(stopped.exception.code, 0)
                    self.assertEqual(seen, [str(canonical)])

    def rows(self, sql):
        with contextlib.closing(sqlite3.connect(self.root / 'releases.db')) as conn:
            conn.row_factory = sqlite3.Row
            return [dict(row) for row in conn.execute(sql)]

    def cli(self, *args):
        with patch.object(sys, 'argv', ['releases', '--root', str(self.root), *args]), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            app.main()

    def snapshot(self):
        files = {str(p.relative_to(self.root)): p.read_bytes() for p in self.root.rglob('*')
                 if p.is_file() and '.git' not in p.parts}
        self.assertTrue(files['releases.db'])
        self.assertTrue(files['releases.sql'])
        return files

    def run_command(self, cmd, **kwargs):
        self.calls.append(cmd)
        rc = 0
        if 'releases_app.py' in cmd[1]:
            args = cmd[2:]
            if args[:1] == ['--root']:
                args = args[2:]
            self.cli(*args)
        elif 'marathon-plan.sh' in cmd[1] and self.planner_finding is not None:
            # GH-684: the planner reports closed-issue drift the way _marathon_plan.py emits it (exit 4,
            # one JSON finding per line) so ownership attribution is exercised, not a green stub.
            return SimpleNamespace(returncode=4, stdout=json.dumps(self.planner_finding) + '\n', stderr='')
        elif 'marathon-plan.sh' in cmd[1] and '--dry-run' not in cmd:
            (self.root / 'PROJECT/2-WORKING/MARATHON-PLAN-2026-09-08.md').write_text('plan\n')
        elif 'pdda' in cmd[1] or '--dry-run' in cmd:
            pass
        else:
            raise AssertionError(f'unexpected subprocess (git/network forbidden): {cmd}')
        if self.fail_after and self.fail_after in ' '.join(cmd):
            rc = 1
        return SimpleNamespace(returncode=rc, stdout='', stderr='injected' if rc else '')

    def apply(self, *flags, targets=None):
        if targets is None:
            targets = [] if '--commit' in flags else ['--pr', '42']
        argv = ['wave', '--root', str(self.root), *targets, '--offline', str(self.root / 'offline.json'),
                '--skip-pull', '--skip-branch-check', '--gate', *flags]
        output = io.StringIO()
        with patch.object(sys, 'argv', argv), \
             patch.object(wave, 'check_porcelain_cleanliness', return_value=''), \
             patch.object(wave, 'verify_rollback_completeness'), \
             patch.object(wave, 'github_slug_from_origin', return_value='test/repo'), \
             patch.object(wave, 'harness_tool', side_effect=lambda root, path: str(source / path)), \
             patch.object(wave.subprocess, 'run', side_effect=self.run_command), \
             contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
            wave.main()
        return output.getvalue()

    def test_direct_commit_with_catch_up(self):
        sha = 'b' * 40
        self.offline['commits'] = [dict(sha=sha, message='Closes #421', committedAt='2026-09-09T00:00:00Z')]
        (self.root / 'offline.json').write_text(json.dumps(self.offline))
        (self.root / 'TESTS-RESULTS/provenance.jsonl').write_text(json.dumps({'commit': sha}) + '\n{"pr":42}\n')
        out = self.apply('--commit', sha, '--catch-up')
        self.assertIn('commit ' + sha[:12], out)
        self.assertEqual(self.rows('SELECT status_marker FROM roadmap_items')[0]['status_marker'], '✅')
        self.assertEqual(self.rows('SELECT state FROM manifest_items')[0]['state'], 'shipped')

    def test_declined_marker_uses_existing_enum(self):
        self.pr['state'] = 'CLOSED'
        (self.root / 'offline.json').write_text(json.dumps(self.offline))
        self.apply()
        self.assertEqual(self.rows('SELECT status_marker FROM roadmap_items')[0]['status_marker'], '⛔')

    def test_lifecycle_and_second_apply(self):
        self.apply()
        row = self.rows('SELECT * FROM roadmap_items')[0]
        self.assertEqual(row['status_marker'], '✅')
        self.assertEqual(row['section'], 'Completed')
        self.assertEqual(row['doc_path'], self.doc.replace('2-WORKING', '3-COMPLETED'))
        self.assertFalse((self.root / self.doc).exists())
        self.assertEqual(self.rows('SELECT state FROM manifest_items')[0]['state'], 'shipped')
        self.assertEqual(self.rows('SELECT reason FROM manifest_state_events')[-1]['reason'], 'a'*40)
        self.assertTrue((self.root / 'PROJECT/2-WORKING/MARATHON-PLAN-2026-09-08.md').is_file())
        before = self.snapshot()
        self.calls.clear()
        self.apply()
        self.assertEqual(before, self.snapshot())
        # GH-421 idempotency: a repeat apply must not repeat a ledger-mutating write (it
        # already shipped/repointed once). Read/regen calls (releases check, dashboard,
        # plan, PDDA) MAY run again — they're deterministic and existing suites (gh202,
        # gh425, gh454) already pin them running on every real reconciliation.
        mutating = [c for c in self.calls
                    if any(pair[0] in c and pair[1] in c for pair in
                           (('manifest', 'ship'), ('roadmap', 'repoint'), ('roadmap', 'update')))]
        self.assertEqual(mutating, [], f"repeat apply re-wrote the ledger: {mutating}")
        self.cli('check')

    def test_open_issue_and_empty_closers(self):
        self.offline['issues'][0]['state'] = 'OPEN'
        (self.root / 'offline.json').write_text(json.dumps(self.offline))
        self.apply()
        self.assertTrue((self.root / self.doc).is_file())
        self.assertEqual(self.rows('SELECT state FROM manifest_items')[0]['state'], 'dialed_in')
        self.assertNotEqual(self.rows('SELECT status_marker FROM roadmap_items')[0]['status_marker'], '✅')
        self.offline['prs'][0]['body'] = ''
        # GH-425: --gate's provenance check is unconditional (attributes evidence to the PR
        # itself, not to whichever issue it closes) — keep the valid PR-42 receipt from setUp
        # so this repeat apply's --gate still passes; the scenario under test is the open-issue
        # idempotency, not provenance.
        (self.root / 'offline.json').write_text(json.dumps(self.offline))
        before = self.snapshot()
        self.calls.clear()
        self.apply()
        self.assertEqual(before, self.snapshot())
        mutating = [c for c in self.calls
                    if any(pair[0] in c and pair[1] in c for pair in
                           (('manifest', 'ship'), ('roadmap', 'repoint'), ('roadmap', 'update')))]
        self.assertEqual(mutating, [], f"repeat apply re-wrote the ledger: {mutating}")

    def test_rollback_each_boundary(self):
        for boundary in ('manifest ship', 'roadmap repoint', 'roadmap update', 'roadmap sync',
                         'releases_app.py --root', 'marathon-plan.sh', 'pdda'):
            with self.subTest(boundary=boundary):
                before = self.snapshot()
                self.fail_after = boundary
                with self.assertRaises(SystemExit):
                    self.apply()
                self.assertEqual(before, self.snapshot())
                self.cli('check')

    def test_dry_run_transitions(self):
        before = self.snapshot()
        dry = self.apply('--dry-run')
        self.assertEqual(before, self.snapshot())
        live = self.apply()
        plans = lambda out: [line for line in out.splitlines() if line.startswith('TRANSITION ')]
        self.assertTrue(plans(dry))
        self.assertEqual(plans(dry), plans(live))

    def test_no_manifest_and_missing_evidence(self):
        self.cli('manifest', 'cut', '--gid', self.gid, 'https://github.com/test/repo/issues/421', '--reason', 'fixture')
        self.apply()
        self.assertEqual(self.rows('SELECT section FROM roadmap_items')[0]['section'], 'Completed')

    def test_missing_merge_sha_rolls_back(self):
        self.offline['prs'][0]['mergeCommit'] = None
        (self.root / 'offline.json').write_text(json.dumps(self.offline))
        before = self.snapshot()
        with self.assertRaises(SystemExit):
            self.apply()
        self.assertEqual(before, self.snapshot())

    def test_three_close_events_and_catch_up(self):
        for n, pr in ((422, 43), (423, 44)):
            doc = self.doc.replace('421', str(n))
            (self.root / doc).write_text((self.root / self.doc).read_text())
            self.cli('roadmap', 'add', '--issue-num', str(n), '--title', 'fixture',
                     '--created', '2026-09-01', '--issue-url', f'https://github.com/test/repo/issues/{n}',
                     '--doc-path', doc)
            self.cli('manifest', 'dial-in', '--gid', self.gid, f'https://github.com/test/repo/issues/{n}')
            self.offline['prs'].append(dict(self.pr, number=pr, body=f'Closes #{n}', mergeCommit={'oid': str(pr)[0]*40}))
            self.offline['issues'].append(dict(number=n, state='CLOSED'))
        (self.root / 'offline.json').write_text(json.dumps(self.offline))
        (self.root / 'TESTS-RESULTS/provenance.jsonl').write_text(''.join(json.dumps({'pr':n})+'\n' for n in (42,43,44)))
        self.assertEqual(wave.catch_up_prs(str(self.root), 'test/repo', self.offline), ['42','43','44'])
        # Replay three close events through the real reconciler, serially as the workflow does.
        for n in (42, 43, 44):
            self.apply('--pr', str(n))
        self.assertEqual([r['state'] for r in self.rows('SELECT state FROM manifest_items')], ['shipped']*3)
        self.assertEqual([r['section'] for r in self.rows('SELECT section FROM roadmap_items')], ['Completed']*3)
        self.assertEqual(wave.catch_up_prs(str(self.root), 'test/repo', self.offline), [])

    def test_catch_up_finds_roadmap_only_drift(self):
        # No active document or dialed-in manifest remains, but the roadmap is stale.
        (self.root / self.doc).unlink()
        self.cli('manifest', 'ship', '--gid', self.gid,
                 'https://github.com/test/repo/issues/421', '--evidence', 'a'*40)
        self.assertEqual(wave.catch_up_prs(str(self.root), 'test/repo', self.offline), ['42'])
        self.apply('--catch-up')
        self.assertEqual(wave.catch_up_prs(str(self.root), 'test/repo', self.offline), [])

    def test_roadmap_catch_up_preserves_repository_identity(self):
        for number, url in [(422, 'https://github.com/other/repo/issues/422'),
                            (423, 'not-an-issue-url')]:
            self.cli('roadmap', 'add', '--issue-num', str(number), '--title', 'foreign or corrupt',
                     '--created', '2026-09-01', '--issue-url', url,
                     '--doc-path', f'PROJECT/1-INBOX/GH-{number}-fixture.md')
        # Neither row may be looked up as a same-number issue in this repository.
        with patch.object(wave, 'fetch_issue_state', wraps=wave.fetch_issue_state) as lookup:
            self.assertEqual(wave.catch_up_prs(str(self.root), 'test/repo', self.offline), ['42'])
        self.assertEqual([call.args[1] for call in lookup.call_args_list], [421])

    def test_catch_up_applies_missed_event(self):
        self.apply('--catch-up')
        self.assertEqual(self.rows('SELECT state FROM manifest_items')[0]['state'], 'shipped')
        self.assertEqual(wave.catch_up_prs(str(self.root), 'test/repo', self.offline), [])

    # ── GH-684: a defective BACKLOG doc stops only itself ──────────────────────────────────────────
    LESSONS = '## Lessons Learned\nFixture.\n'

    def add_backlog_issue(self, lessons):
        """A second closed issue (#422) whose only closer, PR 43, is recovered by --catch-up alone."""
        doc = 'PROJECT/2-WORKING/GH-422-fixture.md'
        (self.root / doc).write_text('---\nstatus: 2-WORKING\nupdated: 2026-09-01\n---\n' + (self.LESSONS if lessons else ''))
        self.cli('roadmap', 'add', '--issue-num', '422', '--title', 'backlog',
                 '--created', '2026-09-01', '--issue-url', 'https://github.com/test/repo/issues/422',
                 '--doc-path', doc)
        self.cli('manifest', 'dial-in', '--gid', self.gid, 'https://github.com/test/repo/issues/422')
        self.offline['prs'].append(dict(number=43, state='MERGED', baseRefName='development', title='backlog',
                                        body='Closes #422', mergedAt='2026-09-09T00:00:00Z', mergeCommit={'oid': 'c'*40}))
        self.offline['issues'].append({'number': 422, 'state': 'CLOSED'})
        (self.root / 'offline.json').write_text(json.dumps(self.offline))
        with open(self.root / 'TESTS-RESULTS/provenance.jsonl', 'a') as f:
            f.write('{"pr":43}\n')   # --gate evidence exists for the recovered landing, as --qualify would leave it
        return doc

    def manifest_states(self):
        return [row['state'] for row in self.rows('SELECT state FROM manifest_items ORDER BY id')]

    def test_catch_up_skips_defective_backlog_doc_reports_it_and_retries(self):
        doc = self.add_backlog_issue(lessons=False)
        out = self.apply('--catch-up')                       # exits normally: the rest of the batch lands
        self.assertEqual(out.count('wave-reconcile: ' + wave.SKIP_MARKER), 1)
        self.assertIn('wave-reconcile: ' + wave.SKIP_MARKER + 'GH-422 — Doc GH-422-fixture.md is missing', out)
        self.assertIn('1 backlog item(s) skipped — GH-422', out)
        self.assertEqual(self.manifest_states(), ['shipped', 'dialed_in'])     # 421 shipped, 422 untouched
        self.assertTrue((self.root / 'PROJECT/3-COMPLETED/GH-421-fixture.md').exists())
        self.assertTrue((self.root / doc).exists())                            # still active, no lifecycle write
        # Retry source intact — with the receipt present — until the doc is repaired.
        self.assertEqual(wave.catch_up_prs(str(self.root), 'test/repo', self.offline), ['43'])
        self.assertIn(wave.SKIP_MARKER + 'GH-422', self.apply('--catch-up'))
        (self.root / doc).write_text('---\nstatus: 2-WORKING\nupdated: 2026-09-01\n---\n' + self.LESSONS)
        out = self.apply('--catch-up')
        self.assertNotIn(wave.SKIP_MARKER, out)
        self.assertEqual(self.manifest_states(), ['shipped', 'shipped'])
        self.assertTrue((self.root / 'PROJECT/3-COMPLETED/GH-422-fixture.md').exists())
        self.assertEqual(wave.catch_up_prs(str(self.root), 'test/repo', self.offline), [])

    def test_explicit_landing_with_defective_doc_still_fails_closed(self):
        # Preservation pin: naming the landing on the command line keeps the fail-closed exit 5.
        self.add_backlog_issue(lessons=False)
        before = self.snapshot()
        with self.assertRaises(SystemExit) as stopped:
            self.apply(targets=['--pr', '43'])
        self.assertEqual(stopped.exception.code, 5)
        self.assertEqual(before, self.snapshot())

    def test_planner_drift_for_a_skipped_issue_is_unrelated(self):
        doc = self.add_backlog_issue(lessons=False)
        self.planner_finding = {"check": "marathon-plan/already-closed", "file": doc,
                                "message": 'issue #422 is CLOSED but the ledger lists it under "In progress"'}
        out = self.apply('--catch-up')                       # the skipped issue left the ownership set
        self.assertIn(wave.SKIP_MARKER + 'GH-422', out)
        self.assertIn('pre-existing unrelated drift', out)
        self.assertEqual(self.manifest_states(), ['shipped', 'dialed_in'])

    def test_planner_drift_for_a_reconciled_issue_stays_fatal(self):
        # Red control for the ownership exclusion: the same finding naming the issue this run DID
        # reconcile is still attributable, still fatal, still rolled back.
        self.add_backlog_issue(lessons=False)
        self.planner_finding = {"check": "marathon-plan/already-closed", "file": self.doc,
                                "message": 'issue #421 is CLOSED but the ledger lists it under "In progress"'}
        before = self.snapshot()
        with self.assertRaises(SystemExit) as stopped:
            self.apply('--catch-up')
        self.assertEqual(stopped.exception.code, 6)
        self.assertEqual(before, self.snapshot())

    def test_doc_write_failure_and_legacy(self):
        before = self.snapshot()
        original = wave.validate_and_update_doc
        def fail(*args, **kwargs):
            original(*args, **kwargs)
            wave.die('injected after doc move', code=6)
        with patch.object(wave, 'validate_and_update_doc', side_effect=fail):
            with self.assertRaises(SystemExit):
                self.apply()
        self.assertEqual(before, self.snapshot())
        # A legacy adopter with placeholder DB files retains its markdown transition.
        legacy = self.root / 'legacy'
        legacy.mkdir()
        (legacy / 'releases.db').touch()
        (legacy / 'ROADMAP.md').write_text('### In progress\n- **GH-421** — fixture\n### Completed\n')
        journal = wave.RollbackJournal()
        self.addCleanup(journal.cleanup)
        wave.update_roadmap_entry(str(legacy), 421, 42, '2026-09-08', journal=journal)
        self.assertIn('### Completed\n- **GH-421** ✅ **SHIPPED', (legacy / 'ROADMAP.md').read_text())

    def test_corrupt_ledger_fails_closed(self):
        (self.root / 'releases.db').write_bytes(b'broken database')
        before = self.snapshot()
        with self.assertRaises(SystemExit):
            self.apply()
        self.assertEqual(before, self.snapshot())

    def test_supporting_note_cannot_steal_canonical_closeout(self):
        recon=self.root/'PROJECT/2-WORKING/recon-gh421-support.md'
        recon.write_text((self.root/self.doc).read_text())
        before=recon.read_bytes()
        original=wave.os.listdir
        def listdir(path):
            names=original(path)
            if str(path)==str(recon.parent):
                return sorted(names,key=lambda name: name!=recon.name)
            return names
        with patch.object(wave.os,'listdir',side_effect=listdir):
            self.apply()
        self.assertTrue((self.root/self.doc.replace('2-WORKING','3-COMPLETED')).is_file())
        self.assertEqual(before,recon.read_bytes())
        self.assertEqual(self.rows('SELECT doc_path FROM roadmap_items')[0]['doc_path'],
                         self.doc.replace('2-WORKING','3-COMPLETED'))

    def test_legacy_row_does_not_block_attributable_pr(self):
        self.cli('roadmap','add','--issue-num','52','--title','legacy',
                 '--created','2026-09-01','--issue-url','https://github.com/test/repo/issues/52',
                 '--doc-path','PROJECT/1-INBOX/GH-52-legacy.md')
        self.offline['issues'].append({'number':52,'state':'CLOSED'})
        before=self.snapshot()
        out=io.StringIO()
        with contextlib.redirect_stdout(out):
            self.assertEqual(wave.catch_up_prs(str(self.root),'test/repo',self.offline),['42'])
        self.assertIn('WARNING',out.getvalue())
        self.assertIn('GH-52',out.getvalue())
        self.assertEqual(before,self.snapshot())

    def test_recovery_covers_no_issue_and_open_reference_prs(self):
        def pr(number,body='',date='2026-09-11T00:00:00Z'):
            return dict(number=number,title='fixture',body=body,merged_at=date,
                        merge_commit_sha=str(number)*40,base={'ref':'development'})
        pages=[[pr(1,date='2026-09-01T00:00:00Z'),pr(2)],
               [pr(3,'References #421'),pr(4),pr(5),pr(6,date=None)]]
        def command(args,**kwargs):
            self.assertIn('--paginate',args)
            self.assertIn('--slurp',args)
            self.assertIn('per_page=100',args[-1])
            return SimpleNamespace(returncode=0,stdout=json.dumps(pages),stderr='')
        metadata={}
        with patch.object(wave.subprocess,'check_output',side_effect=lambda args,**kw:
                          'false\n' if '--is-shallow-repository' in args else '2026-09-10T00:00:00Z\n'), \
             patch.object(wave.subprocess,'run',side_effect=command), \
             patch.object(wave,'committed_qualifications',return_value=[{'pr':4},{'pr':5}]), \
             patch.object(wave,'qualification_receipt_matches',side_effect=lambda root,entry,meta:
                          entry['pr']==meta['number']==4):
            self.assertEqual(wave.unreconciled_prs(str(self.root),'test/repo',metadata),['2','3','5'])
        self.assertEqual(metadata[('pr','3')]['body'],'References #421')
        self.assertEqual(metadata[('pr','2')]['mergeCommit']['oid'],'2'*40)
        # PR #5 carried a number-shaped but invalid receipt; it MUST remain recoverable.
        self.assertIn(('pr','5'),metadata)

    def test_recovery_fails_closed_on_missing_history_or_api_error(self):
        with patch.object(wave.subprocess,'check_output',return_value=''):
            with self.assertRaises(wave.ReconcileError):
                wave.unreconciled_prs(str(self.root),'test/repo',{})
        with patch.object(wave.subprocess,'check_output',side_effect=lambda args,**kw:
                          'false\n' if '--is-shallow-repository' in args else '2026-09-10T00:00:00Z\n'), \
             patch.object(wave.subprocess,'run',return_value=SimpleNamespace(returncode=1,stdout='',stderr='API unavailable')):
            with self.assertRaises(wave.ReconcileError):
                wave.unreconciled_prs(str(self.root),'test/repo',{})

    def test_recovery_rejects_shallow_and_malformed_metadata(self):
        with patch.object(wave.subprocess,'check_output',return_value='true\n'):
            with self.assertRaisesRegex(wave.ReconcileError,'non-shallow'):
                wave.unreconciled_prs(str(self.root),'test/repo',{})
        for record in ({'base':{'ref':'development'}}, {'merged_at':None},
                       {'merged_at':42,'base':{'ref':'development'}}):
            with self.subTest(record=record), \
                 patch.object(wave.subprocess,'check_output',side_effect=['false\n','2026-09-10T00:00:00Z\n']), \
                 patch.object(wave,'committed_qualifications',return_value=[]), \
                 patch.object(wave.subprocess,'run',return_value=SimpleNamespace(returncode=0,stdout=json.dumps([[record]]),stderr='')):
                with self.assertRaisesRegex(wave.ReconcileError,'Malformed'):
                    wave.unreconciled_prs(str(self.root),'test/repo',{})

    def test_recovered_closers_have_one_newest_lifecycle_owner(self):
        # Merge order differs from PR number order. Both require qualification.
        older=dict(self.pr,number=90,mergedAt='2026-09-07T00:00:00Z',mergeCommit={'oid':'b'*40})
        def discover(root,slug,offline,qualification_metadata=None):
            qualification_metadata.update({('pr','90'):older,('pr','42'):self.pr})
            return ['90','42']
        argv=['wave','--root',str(self.root),'--catch-up','--qualify','--gate','--skip-pull','--skip-branch-check']
        with patch.object(sys,'argv',argv), \
             patch.object(wave,'catch_up_prs',side_effect=discover), \
             patch.object(wave,'qualify_landings') as qualify, \
             patch.object(wave,'check_provenance_receipts'), \
             patch.object(wave,'fetch_issue_state',return_value='CLOSED'), \
             patch.object(wave,'check_porcelain_cleanliness',return_value=''), \
             patch.object(wave,'verify_rollback_completeness'), \
             patch.object(wave,'github_slug_from_origin',return_value='test/repo'), \
             patch.object(wave,'harness_tool',side_effect=lambda root,path:str(source/path)), \
             patch.object(wave.subprocess,'run',side_effect=self.run_command), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            wave.main()
        self.assertEqual([p['number'] for p in qualify.call_args.args[1]],[90,42])
        self.assertEqual(self.rows('SELECT reason FROM manifest_state_events')[-1]['reason'],'a'*40)
        row=self.rows('SELECT * FROM roadmap_items')[0]
        self.assertIn('PR #42',row['raw_text'])
        doc=(self.root/self.doc.replace('2-WORKING','3-COMPLETED')).read_text()
        self.assertIn('updated: 2026-09-08',doc)
        self.assertNotIn('updated: 2026-09-07',doc)

    def test_qualified_empty_sweep_writes_nothing(self):
        before=self.snapshot()
        argv=['wave','--root',str(self.root),'--catch-up','--qualify','--gate','--skip-pull','--skip-branch-check']
        with patch.object(sys,'argv',argv), \
             patch.object(wave,'catch_up_prs',return_value=[]), \
             patch.object(wave,'qualify_landings') as qualify, \
             patch.object(wave,'run_subprocesses') as regenerate, \
             patch.object(wave,'check_porcelain_cleanliness',return_value=''), \
             patch.object(wave,'github_slug_from_origin',return_value='test/repo'), \
             contextlib.redirect_stdout(io.StringIO()):
            wave.main()
        qualify.assert_not_called()
        regenerate.assert_not_called()
        self.assertEqual(before,self.snapshot())

    def test_live_catch_up_pagination_and_foreign_reference(self):
        pages = [[], [dict(source={'issue': dict(number=42, pull_request={'url':'pr'},
                 repository_url='https://api.github.com/repos/test/repo')}),
                 dict(source={'issue': dict(number=999, pull_request={'url':'foreign'},
                 repository_url='https://api.github.com/repos/foreign/repo')})]]
        def command(cmd, **kwargs):
            self.assertIn('--paginate', cmd)
            self.assertIn('--slurp', cmd)
            return SimpleNamespace(returncode=0, stdout=json.dumps(pages), stderr='')
        with patch.object(wave, 'fetch_issue_state', return_value='CLOSED'), \
             patch.object(wave.subprocess, 'run', side_effect=command), \
             patch.object(wave, 'fetch_pr_metadata', return_value=self.pr) as fetch:
            self.assertEqual(wave.catch_up_prs(str(self.root), 'test/repo'), ['42'])
            fetch.assert_called_once_with(str(self.root), 42)
        with patch.object(wave, 'fetch_issue_state', return_value='CLOSED'), \
             patch.object(wave.subprocess, 'run', side_effect=command), \
             patch.object(wave, 'fetch_pr_metadata', return_value=dict(self.pr, body='References #421')):
            output=io.StringIO()
            with contextlib.redirect_stdout(output):
                self.assertEqual(wave.catch_up_prs(str(self.root), 'test/repo'), [])
            self.assertIn('WARNING',output.getvalue())
            self.assertIn('GH-421',output.getvalue())


class WorkflowTests(unittest.TestCase):
    def setUp(self):
        self.workflow = Path(os.environ.get('GH421_WORKFLOW', source / '.github/workflows/wave-reconcile.yml')).read_text()
        self.assertTrue(self.workflow.strip())

    def test_trigger_permissions_and_queue(self):
        import re
        for marker in ('types: [closed]', 'branches: [development]', 'queue: max',
                       'cancel-in-progress: false', 'ref: development', 'fetch-depth: 0',
                       'github.event.pull_request.merged == true', "github.event.pull_request.base.ref == 'development'",
                       '--pr "$PR_NUMBER" --catch-up --gate --qualify', '--catch-up --gate --qualify',
                       'timeout-minutes: 120', 'python3 -m pip install --quiet --break-system-packages pytest'):
            self.assertIn(marker, self.workflow)
        self.assertIsNone(re.search(r'^  push:', self.workflow, re.M))
        self.assertIn('permissions:\n  contents: read', self.workflow)
        self.assertIn('    permissions:\n      contents: write', self.workflow)
        self.assertIn('permissions:\n  contents: read', (source / '.github/workflows/ci.yml').read_text())
        try:
            import yaml
        except ImportError:
            return  # Structural checks above stay mandatory on stock Python.
        data = yaml.safe_load(self.workflow)
        triggers = data.get('on', data.get(True))
        self.assertEqual(set(triggers), {'pull_request', 'workflow_dispatch', 'schedule'})
        self.assertEqual(data['concurrency'], dict(group='wave-reconcile', **{'cancel-in-progress': False}, queue='max'))
        self.assertEqual(data['jobs']['reconcile']['permissions']['contents'], 'write')
        self.assertEqual(data['permissions'], {'contents':'read'})
        self.assertIn('run: bash test/gh421-auto-wave-reconcile.sh', (source / '.github/workflows/ci.yml').read_text())

    PUBLISH_HEAD = 'shell: python3 {0}\n        run: |\n'

    def publish_script(self, workflow=None):
        # GH-684: bounded to the publication step's own run: block — a step appended after it (the
        # hosted-lane report) must not leak into the compiled Python.
        import textwrap
        block = (workflow or self.workflow).split(self.PUBLISH_HEAD, 1)[1].split('      - name:', 1)[0]
        return textwrap.dedent(block)

    def publish(self, paths, reject_push=False):
        script = self.publish_script()
        calls = []
        def command(argv):
            calls.append(argv[1:])
            if argv[1] == 'diff':
                return b'\0'.join(p.encode() for p in paths) + (b'\0' if paths else b'')
            if argv[1] == 'ls-files':
                return b''
            if argv[1] == 'push' and reject_push:
                raise wave.subprocess.CalledProcessError(1, argv)
            return b''
        with patch.object(wave.subprocess, 'check_output', side_effect=command):
            exec(compile(script, 'workflow-publish', 'exec'), {})
        return calls

    def test_publish_extraction_is_bounded_to_its_step(self):
        appended = self.workflow.rstrip('\n') + '\n      - name: Something after publication\n        run: echo later\n'
        for label, text in (('base', self.workflow), ('appended', appended)):
            with self.subTest(label=label):
                script = self.publish_script(text)
                self.assertIn("git('push', 'origin', 'HEAD:development')", script)
                compile(script, 'workflow-publish', 'exec')

    def test_report_step_and_permissions(self):
        # GH-684: the reconcile log is tee'd outside the tree, the final step always runs, and it
        # reports the JOB's status (a rejected push after a green reconcile is still red).
        for marker in ('issues: write', 'id: reconcile', '2>&1 | tee "$RUNNER_TEMP/reconcile.log"',
                       '- name: Report hosted lane', 'if: always()', '--status "${{ job.status }}"',
                       'python3 utils/py/hosted_lane_report.py', '--log "$RUNNER_TEMP/reconcile.log"',
                       '--run-url "$RUN_URL"'):
            self.assertIn(marker, self.workflow)
        self.assertNotIn('issues: read', self.workflow)
        self.assertLess(self.workflow.index(self.PUBLISH_HEAD), self.workflow.index('- name: Report hosted lane'))
        try:
            import yaml
        except ImportError:
            return
        data = yaml.safe_load(self.workflow)
        job = data['jobs']['reconcile']
        self.assertEqual(job['permissions']['issues'], 'write')
        self.assertEqual(job['steps'][-1]['name'], 'Report hosted lane')
        self.assertEqual(job['steps'][-1]['if'], 'always()')

    def test_publish_allowlist_and_plan_lands(self):
        paths = ['releases.db', 'releases.sql',
                 'PROJECT/2-WORKING/GH-421-fixture.md', 'PROJECT/3-COMPLETED/GH-421-fixture.md',
                 'PROJECT/2-WORKING/MARATHON-PLAN-2026-09-08.md']
        paths += ['TESTS-RESULTS/2026-09-13+GH-591/wave-' + 'a'*40 + '/provenance.jsonl',
                  'TESTS-RESULTS/2026-09-13+GH-591/wave-' + 'a'*40 + '/validation.jsonl']
        calls = self.publish(paths)
        self.assertIn(['add', '-A', '--', *sorted(paths)], calls)
        self.assertEqual(calls[-1], ['push', 'origin', 'HEAD:development'])
        with self.assertRaisesRegex(SystemExit, 'undeclared'):
            self.publish(paths + ['utils/py/unexpected.py'])
        with self.assertRaisesRegex(SystemExit, 'undeclared'):
            self.publish(paths + ['TESTS-RESULTS/arbitrary/provenance.jsonl'])
        for sha in ('a'*39, 'a'*41, 'g'*40):
            with self.subTest(sha=sha), self.assertRaisesRegex(SystemExit, 'undeclared'):
                self.publish(paths + ['TESTS-RESULTS/2026-09-13+GH-591/wave-'+sha+'/provenance.jsonl'])
        with self.assertRaises(wave.subprocess.CalledProcessError):
            self.publish(paths, reject_push=True)
        with self.assertRaises(SystemExit) as result:
            self.publish([])
        self.assertEqual(result.exception.code, 0)


unittest.main(verbosity=2)
PY
