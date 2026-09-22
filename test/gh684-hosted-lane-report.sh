#!/usr/bin/env bash
# GH-684: utils/py/hosted_lane_report.py keeps exactly one hosted-reconcile-attention issue.
# A recording stub `gh` sits first on PATH; it never reaches the network. Every mutating call must
# carry the run URL in its body — that assertion is the suite's red control (a mutant that drops the
# URL is witnessed failing). The skip line the suite feeds is built from wave_reconcile.SKIP_MARKER,
# never retyped, so this consumer and the emitter cannot drift.
set -euo pipefail
GH684_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONDONTWRITEBYTECODE=1
python3 - "$GH684_ROOT" <<'PY'
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import stat
import sys
import tempfile
import unittest
from unittest.mock import patch

source = Path(sys.argv.pop())
sys.path.insert(0, str(source / 'utils/py'))
spec = importlib.util.spec_from_file_location('gh684_report', source / 'utils/py/hosted_lane_report.py')
report = importlib.util.module_from_spec(spec)
spec.loader.exec_module(report)
from wave_reconcile import SKIP_MARKER  # the emitter's literal

STUB = r'''#!/usr/bin/env bash
# recording gh stub: appends argv as JSON; `issue list` answers from $OPEN_ISSUES; mutating calls
# must carry $EXPECT_URL in their --body (the red control).
set -euo pipefail
python3 - "$@" <<'INNER'
import json, os, sys
argv = sys.argv[1:]
with open(os.environ['GH_CALLS'], 'a') as f:
    f.write(json.dumps(argv) + '\n')
if argv[:2] == ['issue', 'list']:
    print(os.environ.get('OPEN_ISSUES', '[]'))
    sys.exit(0)
mutating = argv[:2] in (['issue', 'create'], ['issue', 'comment'], ['issue', 'close'], ['label', 'create'])
if argv[:2] in (['issue', 'create'], ['issue', 'comment']):
    body = argv[argv.index('--body') + 1]
    if os.environ['EXPECT_URL'] not in body:
        sys.stderr.write('stub gh: body lacks the run URL\n')
        sys.exit(9)
sys.exit(0)
INNER
'''

RUN_URL = 'https://github.com/test/repo/actions/runs/123'
ERROR_LINE = "wave-reconcile: ERROR — Doc GH-505-X.md is missing mandatory '## Lessons Learned (For Future Agents)' section."
SKIP_LINE = f"wave-reconcile: {SKIP_MARKER}GH-505 — Doc GH-505-X.md is missing mandatory section (backlog item)"


class ReportTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix='gh684-'))
        self.addCleanup(lambda: __import__('shutil').rmtree(self.tmp, ignore_errors=True))
        gh = self.tmp / 'bin' / 'gh'
        gh.parent.mkdir()
        gh.write_text(STUB)
        gh.chmod(gh.stat().st_mode | stat.S_IXUSR)
        self.calls_file = self.tmp / 'calls.jsonl'
        self.env = patch.dict(os.environ, {'PATH': f"{gh.parent}{os.pathsep}{os.environ['PATH']}",
                                           'GH_CALLS': str(self.calls_file), 'EXPECT_URL': RUN_URL,
                                           'OPEN_ISSUES': '[]'})
        self.env.start()
        self.addCleanup(self.env.stop)

    def log(self, *lines):
        path = self.tmp / 'reconcile.log'
        path.write_text('\n'.join(lines) + ('\n' if lines else ''))
        return str(path)

    def run_report(self, status, log, open_issues=(), extra=()):
        os.environ['OPEN_ISSUES'] = json.dumps([{'number': n} for n in open_issues])
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            rc = report.main(['--status', status, '--log', log, '--run-url', RUN_URL, *extra])
        self.assertEqual(rc, 0)
        return out.getvalue()

    def publish_log(self, *lines):
        path = self.tmp / 'publish.log'
        path.write_text('\n'.join(lines) + ('\n' if lines else ''))
        return str(path)

    def calls(self):
        if not self.calls_file.exists():
            return []
        return [json.loads(line) for line in self.calls_file.read_text().splitlines()]

    def verbs(self):
        return [tuple(c[:2]) for c in self.calls()]

    def body_of(self, verb):
        call = next(c for c in self.calls() if tuple(c[:2]) == verb)
        return call[call.index('--body') + 1]

    def test_red_run_with_error_opens_one_labelled_issue(self):
        self.run_report('failure', self.log('wave-reconcile: Processing PR #683...', ERROR_LINE))
        self.assertEqual(self.verbs(), [('issue', 'list'), ('label', 'create'), ('issue', 'create')])
        body = self.body_of(('issue', 'create'))
        self.assertIn(RUN_URL, body)
        self.assertIn('`failure`', body)
        self.assertIn(ERROR_LINE[len(report.ERROR_PREFIX):], body)
        create = next(c for c in self.calls() if c[:2] == ['issue', 'create'])
        self.assertEqual(create[create.index('--label') + 1], report.DEFAULT_LABEL)

    def test_red_run_with_open_issue_comments_and_never_creates(self):
        self.run_report('failure', self.log(ERROR_LINE), open_issues=[7])
        self.assertEqual(self.verbs(), [('issue', 'list'), ('issue', 'comment')])
        self.assertEqual(self.calls()[1][2], '7')

    def test_green_run_with_skip_reports_and_never_closes(self):
        for open_issues, expected in (([], [('issue', 'list'), ('label', 'create'), ('issue', 'create')]),
                                      ([7], [('issue', 'list'), ('issue', 'comment')])):
            with self.subTest(open_issues=open_issues):
                self.calls_file.unlink(missing_ok=True)
                out = self.run_report('success', self.log('wave-reconcile: Processing PR #43...', SKIP_LINE,
                                                          'wave-reconcile: 1 backlog item(s) skipped — GH-505'),
                                      open_issues=open_issues)
                self.assertEqual(self.verbs(), expected)
                self.assertNotIn(('issue', 'close'), self.verbs())
                body = self.body_of(expected[-1])
                self.assertIn('Skipped backlog item(s) (1)', body)
                self.assertIn(SKIP_LINE[len('wave-reconcile: '):], body)
                self.assertIn('1 skipped', out)

    def test_green_run_without_skips_closes_the_open_issue(self):
        self.run_report('success', self.log('wave-reconcile: Wave reconciliation completed successfully! ✅'),
                        open_issues=[7])
        self.assertEqual(self.verbs(), [('issue', 'list'), ('issue', 'comment'), ('issue', 'close')])
        self.assertIn(RUN_URL, self.body_of(('issue', 'comment')))
        self.assertEqual(self.calls()[2][2], '7')

    def test_green_run_with_nothing_open_makes_no_mutating_call(self):
        out = self.run_report('success', self.log('wave-reconcile: Wave reconciliation completed successfully! ✅'))
        self.assertEqual(self.verbs(), [('issue', 'list')])   # discovery only
        self.assertIn('nothing open', out)

    def test_failure_with_missing_log_still_reports(self):
        # A run that died before the tee (or a rejected push after a green reconcile) has no ERROR line.
        self.run_report('failure', str(self.tmp / 'absent.log'))
        self.assertEqual(self.verbs(), [('issue', 'list'), ('label', 'create'), ('issue', 'create')])
        self.assertIn('none captured', self.body_of(('issue', 'create')))

    def test_summary_line_is_not_a_skip(self):
        # The end-of-run summary deliberately does not start with the marker; only real skips count.
        error, skips = report.summarize(['wave-reconcile: 2 backlog item(s) skipped — GH-1, GH-2', SKIP_LINE])
        self.assertIsNone(error)
        self.assertEqual(skips, [SKIP_LINE])

    # GH-741: a --qualify run's reconcile log is full of the test suite's own expected ERROR lines.
    QUALIFY_LOG = ('wave-reconcile: Processing PR #731...',
                   'test_new_schema_cannot_fall_through (Qualification) ... wave-reconcile: ERROR — --gate failure: No provenance.jsonl entry matches PR #425',
                   'ok',
                   'wave-reconcile: ERROR — Malformed merged-PR recovery response: pull request lacks merged_at or base.ref',
                   'wave-reconcile: ERROR — Malformed merged-PR recovery response: invalid merged_at timestamp',
                   'ok',
                   'wave-reconcile: Wave reconciliation completed successfully! ✅')
    REJECTED = ' ! [rejected]          HEAD -> development (fetch first)'

    def test_green_reconcile_red_publish_names_the_publish_step_not_a_test_line(self):
        # Replay of run 35623940059 (#735): reconcile green, push rejected. The old scan would have
        # blamed the last test-emitted line; the outcome-aware path names the publish step.
        log = self.log(*self.QUALIFY_LOG)
        self.assertEqual(report.summarize(report.read_log(log))[0],
                         'wave-reconcile: ERROR — Malformed merged-PR recovery response: invalid merged_at timestamp')  # red control: old behaviour
        publish = self.publish_log('hosted-lane-publish: pushing 1 declared path(s)', self.REJECTED,
                                   "error: failed to push some refs to 'https://github.com/test/repo'")
        self.run_report('failure', log, extra=['--reconcile-outcome', 'success', '--publish-outcome', 'failure',
                                                '--publish-log', publish])
        body = self.body_of(('issue', 'create'))
        self.assertIn('(step: publish)', body)
        self.assertIn('failed to push some refs', body)
        self.assertNotIn('merged_at', body)
        # With the publisher's own terminal line present, that line wins over the raw git tail.
        self.calls_file.unlink()
        publish = self.publish_log(self.REJECTED, 'hosted-lane-publish: ERROR — push rejected; origin/development moved to abc1234')
        self.run_report('failure', log, extra=['--reconcile-outcome', 'success', '--publish-outcome', 'failure',
                                                '--publish-log', publish])
        self.assertIn('Terminal error (step: publish): `push rejected; origin/development moved to abc1234`',
                      self.body_of(('issue', 'create')))

    def test_red_reconcile_still_reports_its_own_last_error_and_publish_skips_count(self):
        log = self.log(*self.QUALIFY_LOG[:-1], ERROR_LINE)
        publish = self.publish_log('hosted-lane-publish: nothing to do')
        self.run_report('failure', log, extra=['--reconcile-outcome', 'failure', '--publish-outcome', 'skipped',
                                                '--publish-log', publish])
        self.assertIn(f"Terminal error (step: reconcile): `{ERROR_LINE[len(report.ERROR_PREFIX):]}`",
                      self.body_of(('issue', 'create')))
        # A skip emitted by the recompute (publish log) still demands attention on a green job.
        self.calls_file.unlink()
        self.run_report('success', self.log('wave-reconcile: Wave reconciliation completed successfully! ✅'),
                        open_issues=[7], extra=['--reconcile-outcome', 'success', '--publish-outcome', 'success',
                                                '--publish-log', self.publish_log(SKIP_LINE)])
        self.assertEqual(self.verbs(), [('issue', 'list'), ('issue', 'comment')])
        self.assertNotIn(('issue', 'close'), self.verbs())

    def test_red_control_mutant_without_run_url_is_caught(self):
        # Witnessed: a body that drops the run URL trips the stub, and the tool fails closed.
        with patch.object(report, 'body_for', lambda status, run_url, error, skips, step=None: 'no url here'):
            with self.assertRaises(SystemExit) as stopped:
                self.run_report('failure', self.log(ERROR_LINE))
        self.assertIn('gh issue create failed', str(stopped.exception))


unittest.main(verbosity=2)
PY
