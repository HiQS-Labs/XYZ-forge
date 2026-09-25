#!/usr/bin/env bash
# GH-421: in-process CLI fixtures; never invokes git or network.
set -euo pipefail
GH421_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$GH421_ROOT/test/lib/fixture-guard.sh"
require_forge_root .github/workflows/wave-reconcile.yml   # GH-708: forge-root only — witnessed skip in a vendored .xyz/
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

    # GH-693: Lessons Learned is advisory. The GH-684 skip-and-report shape stays in the code for the next
    # real backlog-doc defect, but its one trigger is gone: a doc without the section now promotes with a
    # WARN on the catch-up path and on an explicit landing alike.
    def test_catch_up_promotes_a_lessons_less_backlog_doc_with_a_warning(self):
        doc = self.add_backlog_issue(lessons=False)
        out = self.apply('--catch-up')
        self.assertNotIn(wave.SKIP_MARKER, out)
        self.assertIn('wave-reconcile: ' + wave.WARN_MARKER + 'Doc GH-422-fixture.md has no', out)
        self.assertIn('Highly recommended, not required (GH-693)', out)
        self.assertEqual(self.manifest_states(), ['shipped', 'shipped'])      # both landed
        self.assertTrue((self.root / 'PROJECT/3-COMPLETED/GH-422-fixture.md').exists())
        self.assertFalse((self.root / doc).exists())
        self.assertEqual(wave.catch_up_prs(str(self.root), 'test/repo', self.offline), [])

    def test_explicit_landing_with_a_lessons_less_doc_warns_and_lands(self):
        # Was the GH-684 preservation pin for exit 5; the explicit path now warns and lands too.
        doc = self.add_backlog_issue(lessons=False)
        out = self.apply(targets=['--pr', '43'])
        self.assertIn('wave-reconcile: ' + wave.WARN_MARKER + 'Doc GH-422-fixture.md has no', out)
        self.assertTrue((self.root / 'PROJECT/3-COMPLETED/GH-422-fixture.md').exists())
        self.assertFalse((self.root / doc).exists())

    def test_planner_drift_for_a_lessons_less_issue_is_owned(self):
        # GH-693: a lessons-less backlog doc is reconciled like any other, so it is IN the ownership
        # set — its own planner drift is attributable and fatal (exit 6, rolled back), no longer
        # "pre-existing unrelated" as it was while GH-684 skipped it.
        doc = self.add_backlog_issue(lessons=False)
        self.planner_finding = {"check": "marathon-plan/already-closed", "file": doc,
                                "message": 'issue #422 is CLOSED but the ledger lists it under "In progress"'}
        before = self.snapshot()
        with self.assertRaises(SystemExit) as stopped:
            self.apply('--catch-up')
        self.assertEqual(stopped.exception.code, 6)
        self.assertEqual(before, self.snapshot())

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

    # GH-740: the hosted publish step's bounded retry. Same enumeration and ownership as the run it
    # retries; landings without a committed, matching receipt are deferred, never qualified.
    def only_receipted(self, receipted, targets=(), discover=None, issue_state='CLOSED', lookup=None):
        older=dict(self.pr,number=90,mergedAt='2026-09-07T00:00:00Z',mergeCommit={'oid':'b'*40})
        lookup=lookup or {'90':older,'42':self.pr}
        def default_discover(root,slug,offline,qualification_metadata=None):
            qualification_metadata.update({('pr','90'):older,('pr','42'):self.pr})
            return ['90','42']
        argv=['wave','--root',str(self.root),*targets,'--catch-up','--qualify','--gate','--only-receipted',
              '--skip-pull','--skip-branch-check']
        out=io.StringIO()
        with patch.object(sys,'argv',argv), \
             patch.object(wave,'catch_up_prs',side_effect=discover or default_discover), \
             patch.object(wave,'qualify_landings') as qualify, \
             patch.object(wave,'committed_qualifications',return_value=[{'pr':n} for n in receipted]), \
             patch.object(wave,'qualification_receipt_matches',side_effect=lambda root,entry,meta: entry['pr']==meta['number']), \
             patch.object(wave,'check_provenance_receipts'), \
             patch.object(wave,'fetch_issue_state',return_value=issue_state), \
             patch.object(wave,'fetch_pr_metadata',side_effect=lambda root,value,*a,**k: lookup[str(value)]), \
             patch.object(wave,'check_porcelain_cleanliness',return_value=''), \
             patch.object(wave,'verify_rollback_completeness'), \
             patch.object(wave,'github_slug_from_origin',return_value='test/repo'), \
             patch.object(wave,'harness_tool',side_effect=lambda root,path:str(source/path)), \
             patch.object(wave.subprocess,'run',side_effect=self.run_command), \
             contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            wave.main()
        qualify.assert_not_called()
        return out.getvalue()

    def test_only_receipted_defers_the_unreceipted_older_closer_and_keeps_newest_owner(self):
        out=self.only_receipted(receipted=[42])
        self.assertIn('deferred PR #90',out)
        self.assertNotIn('deferred PR #42',out)
        doc=(self.root/self.doc.replace('2-WORKING','3-COMPLETED')).read_text()
        self.assertIn('updated: 2026-09-08',doc)
        self.assertNotIn('updated: 2026-09-07',doc)
        self.assertIn('PR #42',self.rows('SELECT * FROM roadmap_items')[0]['raw_text'])

    def test_only_receipted_with_both_receipted_still_lets_the_newest_closer_own(self):
        # The newer closer already had a committed receipt; the older one was receipted this run.
        out=self.only_receipted(receipted=[90,42])
        self.assertNotIn('deferred',out)
        doc=(self.root/self.doc.replace('2-WORKING','3-COMPLETED')).read_text()
        self.assertIn('updated: 2026-09-08',doc)
        self.assertNotIn('updated: 2026-09-07',doc)

    def test_only_receipted_refuses_an_explicit_unreceipted_target(self):
        with self.assertRaises(SystemExit) as stopped:
            self.only_receipted(receipted=[42],targets=['--pr','90'])
        self.assertEqual(stopped.exception.code,6)

    def test_only_receipted_requires_catch_up_and_qualify(self):
        for argv in (['wave','--root',str(self.root),'--pr','42','--gate','--only-receipted'],
                     ['wave','--root',str(self.root),'--catch-up','--gate','--only-receipted']):
            with self.subTest(argv=argv[3:]), patch.object(sys,'argv',argv), \
                 contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as stopped:
                wave.main()
            self.assertEqual(stopped.exception.code,2)

    def test_only_receipted_explicit_target_keeps_open_issue_merge_evidence(self):
        # GH-740 F6: after the receipts commit lands, discovery no longer lists this PR (it is
        # receipted) and skips its OPEN issue — the publisher names it explicitly, and its
        # merge-evidence write survives with zero qualification.
        reference=dict(self.pr,number=5,body='References #421',mergeCommit={'oid':'5'*40})
        def discover(root,slug,offline,qualification_metadata=None):
            return []   # what catch_up_prs returns once #5 is receipted and #421 is OPEN
        with patch.object(wave,'extract_linked_issues',return_value=([],[421])):
            out=self.only_receipted(receipted=[5],targets=['--pr','5'],discover=discover,issue_state='OPEN',
                                    lookup={'5':reference})
        self.assertIn('Issue #421 referenced without a closing keyword and OPEN — recording merge evidence only',out)
        doc=(self.root/self.doc).read_text()   # still active — the issue is open
        self.assertIn('## Merge evidence',doc)
        self.assertIn('PR #5',doc)

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
        self.assertIn('pending_publication(repo)', self.workflow)
        self.assertIn("if: steps.publication.outputs.pending != 'true'", self.workflow)
        self.assertIn('publication_landing', self.workflow)
        self.assertIn('EXTRA=(--protected)', self.workflow)
        self.assertEqual(data['jobs']['reconcile']['permissions']['pull-requests'], 'write')
        self.assertNotIn('.protected)" = false', self.workflow)


    # GH-740: the publish step is utils/py/hosted_lane_publish.py (the former inline Python, moved).
    # These tests drive the module with git patched out; test/gh740-hosted-lane-publish.sh drives it
    # against a real bare remote.
    def publish_module(self):
        import importlib.util
        spec = importlib.util.spec_from_file_location('gh421_publish', source / 'utils/py/hosted_lane_publish.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def publish(self, paths, pushes=(True,), recomputed=None, targets=(['7'], [])):
        """Run main() with git patched out. `pushes` is the sequence of push outcomes; `recomputed`
        is what changed_paths() returns after the one recompute. Returns the recorded calls."""
        module = self.publish_module()
        calls = dict(commits=[], git=[], pushes=list(pushes), recompute=[])
        def fake_git(*args, check=True):
            calls['git'].append(args)
            return SimpleNamespace(returncode=0, stdout='', stderr='')
        def fake_commit(paths, message):
            calls['commits'].append((list(paths), message))
            return 'f' * 40
        def fake_push():
            return calls['pushes'].pop(0)
        changed = [sorted(paths), sorted(recomputed or [])]   # changed_paths() returns sorted paths
        with patch.object(module, 'git', side_effect=fake_git), \
             patch.object(module, 'commit', side_effect=fake_commit), \
             patch.object(module, 'push', side_effect=fake_push), \
             patch.object(module, 'changed_paths', side_effect=lambda: changed.pop(0)), \
             patch.object(module, 'remote_head', return_value='d' * 40), \
             patch.object(module, 'receipt_targets', return_value=targets), \
             patch.object(module, 'recompute', side_effect=lambda argv, cmd: calls['recompute'].append(argv)), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            rc = module.main(['--reconcile-args', '--pr 7 --catch-up --gate --qualify'])
        calls['rc'] = rc
        return calls

    RECEIPTS = ['TESTS-RESULTS/2026-09-13+GH-591/wave-' + 'a'*40 + '/provenance.jsonl',
                'TESTS-RESULTS/2026-09-13+GH-591/wave-' + 'a'*40 + '/validation.jsonl']
    PATHS = ['releases.db', 'releases.sql',
             'PROJECT/2-WORKING/GH-421-fixture.md', 'PROJECT/3-COMPLETED/GH-421-fixture.md',
             # GH-721: the deletion side of a 1-INBOX -> 3-COMPLETED capture promotion (GH-698 item 2)
             'PROJECT/1-INBOX/GH-421-fixture.md',
             'PROJECT/2-WORKING/MARATHON-PLAN-2026-09-08.md']

    def test_report_step_and_permissions(self):
        # GH-684: the reconcile log is tee'd outside the tree, the final step always runs, and it
        # reports the JOB's status (a rejected push after a green reconcile is still red).
        # GH-740/741: the publish step is the module, its log is tee'd too, and the report gets both
        # step outcomes so it can name the step that actually failed.
        for marker in ('issues: write', 'id: reconcile', '2>&1 | tee "$RUNNER_TEMP/reconcile.log"',
                       'echo "RECONCILE_ARGS=${ARGS[*]}" >> "$GITHUB_ENV"',
                       'id: publish', 'python3 utils/py/hosted_lane_publish.py --reconcile-args "$RECONCILE_ARGS"',
                       '2>&1 | tee "$RUNNER_TEMP/publish.log"',
                       '- name: Report hosted lane', 'if: always()', '--status "${{ job.status }}"',
                       'python3 utils/py/hosted_lane_report.py', '--log "$RUNNER_TEMP/reconcile.log"',
                       '--run-url "$RUN_URL"', '--reconcile-outcome "${{ steps.reconcile.outcome }}"',
                       '--publish-outcome "${{ steps.publish.outcome }}"', '--publish-log "$RUNNER_TEMP/publish.log"'):
            self.assertIn(marker, self.workflow)
        self.assertNotIn('issues: read', self.workflow)
        self.assertNotIn('shell: python3 {0}', self.workflow)   # no inline publish Python remains
        self.assertLess(self.workflow.index('- name: Commit declared artifacts and push'),
                        self.workflow.index('- name: Report hosted lane'))
        try:
            import yaml
        except ImportError:
            return
        data = yaml.safe_load(self.workflow)
        job = data['jobs']['reconcile']
        self.assertEqual(job['permissions']['issues'], 'write')
        self.assertEqual([s.get('id') for s in job['steps'][-3:-1]], ['reconcile', 'publish'])
        self.assertEqual(job['steps'][-1]['name'], 'Report hosted lane')
        self.assertEqual(job['steps'][-1]['if'], "always() && steps.publication.outputs.pending != 'true'")

    def test_publish_allowlist_and_plan_lands(self):
        module = self.publish_module()
        paths = self.PATHS + self.RECEIPTS
        self.assertEqual(module.declared_paths(sorted(paths)), sorted(paths))
        self.assertEqual(module.receipt_paths(paths), self.RECEIPTS)
        with self.assertRaisesRegex(SystemExit, 'undeclared'):
            module.declared_paths(paths + ['utils/py/unexpected.py'])
        with self.assertRaisesRegex(SystemExit, 'undeclared'):
            module.declared_paths(paths + ['TESTS-RESULTS/arbitrary/provenance.jsonl'])
        with self.assertRaisesRegex(SystemExit, 'undeclared'):
            module.declared_paths(paths + ['PROJECT/1-INBOX/scratch-note.md'])
        for sha in ('a'*39, 'a'*41, 'g'*40):
            with self.subTest(sha=sha), self.assertRaisesRegex(SystemExit, 'undeclared'):
                module.declared_paths(paths + ['TESTS-RESULTS/2026-09-13+GH-591/wave-'+sha+'/provenance.jsonl'])
        # fast path: one explicit-path commit, one push, nothing else touches git
        calls = self.publish(paths)
        self.assertEqual(calls['rc'], 0)
        self.assertEqual(calls['commits'], [(sorted(paths), 'chore: reconcile merged development work')])
        self.assertEqual(calls['recompute'], [])
        self.assertEqual(calls['git'], [])
        # an undeclared path is refused before any commit or push
        with patch.object(module, 'changed_paths', return_value=paths + ['utils/py/unexpected.py']), \
             patch.object(module, 'commit') as commit, patch.object(module, 'push') as push:
            with self.assertRaisesRegex(SystemExit, 'undeclared'):
                module.main([])
        commit.assert_not_called(); push.assert_not_called()
        # nothing to commit
        with patch.object(module, 'changed_paths', return_value=[]), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(module.main([]), 0)

    def test_publish_recovers_from_a_raced_push_with_receipts_first_and_one_recompute(self):
        paths = self.PATHS + self.RECEIPTS
        recomputed = ['releases.db', 'releases.sql', 'PROJECT/3-COMPLETED/GH-421-fixture.md']
        calls = self.publish(paths, pushes=(False, True, True), recomputed=recomputed)
        self.assertEqual(calls['rc'], 0)
        self.assertEqual([c[0] for c in calls['commits']], [sorted(paths), self.RECEIPTS, sorted(recomputed)])
        self.assertEqual(calls['commits'][1][1], 'chore: retain qualification receipts for ' + 'a'*40)
        self.assertIn(('reset', '--hard', 'origin/development'), calls['git'])
        self.assertIn(('checkout', 'f'*40, '--', *self.RECEIPTS), calls['git'])   # receipt FILES lifted, nothing rebased
        self.assertFalse(any('rebase' in c or 'push' in c for c in calls['git']))
        self.assertEqual(calls['recompute'], [['--catch-up', '--gate', '--qualify', '--pr', '7', '--only-receipted', '--skip-pull']])
        # a second race: receipts stay published, exactly one recompute, loud exit
        with self.assertRaises(SystemExit) as stopped:
            self.publish(paths, pushes=(False, True, False), recomputed=recomputed)
        self.assertEqual(stopped.exception.code, 1)
        # no receipts in the raced commit: no retry at all
        with self.assertRaises(SystemExit) as stopped:
            self.publish(self.PATHS, pushes=(False,))
        self.assertEqual(stopped.exception.code, 1)
        # receipts-only publication exhausts its own ≤3-attempt loop: three receipt commits, no recompute
        module = self.publish_module()
        recorded = dict(commits=[], recompute=[])
        with patch.object(module, 'git', return_value=SimpleNamespace(returncode=0, stdout='', stderr='')), \
             patch.object(module, 'commit', side_effect=lambda paths, message: recorded['commits'].append(message) or 'f'*40), \
             patch.object(module, 'push', side_effect=[False, False, False, False]), \
             patch.object(module, 'changed_paths', return_value=sorted(paths)), \
             patch.object(module, 'remote_head', return_value='d'*40), \
             patch.object(module, 'recompute', side_effect=lambda argv, cmd: recorded['recompute'].append(argv)), \
             contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as stopped:
                module.main(['--reconcile-args', '--pr 7 --catch-up --gate --qualify'])
        self.assertEqual(stopped.exception.code, 1)
        self.assertEqual(recorded['commits'], ['chore: reconcile merged development work'] + ['chore: retain qualification receipts for ' + 'a'*40] * 3)
        self.assertEqual(recorded['recompute'], [])


unittest.main(verbosity=2)
PY
