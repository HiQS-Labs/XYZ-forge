#!/usr/bin/env bash
# GH-740: utils/py/hosted_lane_publish.py survives a merge landing during the hosted reconcile run.
# Real git fixture: a bare remote, a working clone, a racer clone, and a stub reconciler that writes
# schema-valid qualification receipts (they must satisfy wave_reconcile.qualification_summary and be
# accepted by the PRODUCTION consumer qualification_receipt_matches after publication). The red
# control is the plain `git push` the inline step used to do, run from the stale clone: rejected.
set -euo pipefail
GH740_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONDONTWRITEBYTECODE=1
python3 - "$GH740_ROOT" <<'PY'
import argparse
import ast
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

source = Path(sys.argv.pop())
sys.path.insert(0, str(source / 'utils/py'))
import wave_reconcile as wave  # noqa: E402  — the production receipt consumer is the judge

PUBLISH = source / 'utils/py/hosted_lane_publish.py'

STUB = r'''#!/usr/bin/env python3
# stub reconciler: appends a ledger transition, edits the doc, writes receipts on its FIRST call
# (like a qualifying run), records every argv, and can advance the remote mid-run (second race).
import hashlib, json, os, subprocess, sys
root = os.getcwd()
calls = os.environ['STUB_CALLS']
with open(calls, 'a') as f:
    f.write(json.dumps(sys.argv[1:]) + '\n')
n = sum(1 for _ in open(calls))
if n == 2 and os.environ.get('STUB_RACE_AGAIN'):
    subprocess.run(['bash', os.environ['STUB_RACE_AGAIN']], check=True)
with open('releases.sql', 'a') as f:
    f.write(f"-- transition by stub run {n}\n")
with open('PROJECT/2-WORKING/GH-740-fixture.md', 'a') as f:
    f.write(f"stub run {n}\n")
if n == 1 and not os.environ.get('STUB_NO_RECEIPTS'):
    tested = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
    landing = os.environ['STUB_LANDING']
    run = f"{tested[:9]}-4242"
    names = ['python:test_python_layer.py', 'gamma-poison-staleness-probe', 'gh740-fixture-suite']
    rows = [dict(event='run.start', run=run, runner='validate', commit=tested, mode='sequential', tier=3,
                 registered=len(names))]
    rows += [dict(event='suite', run=run, runner='validate', lane='sequential', name=name, rc=0) for name in names]
    rows.append(dict(event='run.summary', run=run, runner='validate', failed=0, total=len(names) + 3,
                     passed=len(names) + 3, envelope_rc='0', suite_events_match='yes',
                     run_set=len(names), registered=len(names)))
    raw = ''.join(json.dumps(r) + '\n' for r in rows).encode()
    folder = os.path.join('TESTS-RESULTS', '2026-09-21+GH-591', f'wave-{tested}')
    os.makedirs(folder)
    open(os.path.join(folder, 'validation.jsonl'), 'wb').write(raw)
    entry = dict(schema_version='wave-qualification@1', artifact_kind='pr', tested_commit=tested,
                 landing_commit=landing, result='pass', rc=0, gate='validate.sh --sequential',
                 timestamp='2026-09-21T00:00:00+00:00',
                 telemetry=os.path.join(folder, 'validation.jsonl'),
                 telemetry_sha256=hashlib.sha256(raw).hexdigest(), passed=len(names) + 3, total=len(names) + 3, pr=7)
    open(os.path.join(folder, 'provenance.jsonl'), 'w').write(json.dumps(entry, sort_keys=True) + '\n')
'''


def sh(*args, cwd, check=True, env=None):
    return subprocess.run(list(args), cwd=cwd, capture_output=True, text=True, check=check,
                          env={**os.environ, **(env or {})})


class PublishTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix='gh740-'))
        self.addCleanup(lambda: shutil.rmtree(self.tmp, ignore_errors=True))
        self.remote = self.tmp / 'origin.git'
        sh('git', 'init', '--quiet', '--bare', '--initial-branch=development', str(self.remote), cwd=self.tmp)
        seed = self.tmp / 'seed'
        sh('git', 'clone', '--quiet', str(self.remote), str(seed), cwd=self.tmp)
        self.git_id(seed)
        (seed / 'PROJECT/2-WORKING').mkdir(parents=True)
        (seed / 'releases.sql').write_text('-- generation: 1\n')
        (seed / 'PROJECT/2-WORKING/GH-740-fixture.md').write_text('---\nstatus: active\n---\n')
        (seed / 'utils').mkdir()
        (seed / 'utils/keep').write_text('')
        sh('git', 'add', '-A', cwd=seed)
        sh('git', 'commit', '--quiet', '-m', 'base', cwd=seed)
        (seed / 'PROJECT/2-WORKING/GH-740-fixture.md').write_text('---\nstatus: active\n---\nmerged PR #7\n')
        sh('git', 'commit', '--quiet', '-am', 'Merge PR #7', cwd=seed)
        self.landing = sh('git', 'rev-parse', 'HEAD', cwd=seed).stdout.strip()   # also the clone's HEAD at reconcile time = `tested`
        sh('git', 'push', '--quiet', 'origin', 'HEAD:development', cwd=seed)
        self.clone = self.tmp / 'clone'
        sh('git', 'clone', '--quiet', str(self.remote), str(self.clone), cwd=self.tmp)
        self.git_id(self.clone)
        self.racer = self.tmp / 'racer'
        sh('git', 'clone', '--quiet', str(self.remote), str(self.racer), cwd=self.tmp)
        self.git_id(self.racer)
        self.stub = self.tmp / 'stub.py'
        self.stub.write_text(STUB)
        self.calls = self.tmp / 'stub-calls.jsonl'
        self.race_script = self.tmp / 'race.sh'
        self.race_script.write_text(f'#!/usr/bin/env bash\nset -e\ncd "{self.racer}"\n'
                                    'git pull --quiet --rebase origin development\n'
                                    'echo "-- racer line $(date +%s%N)" >> releases.sql\n'
                                    'git commit --quiet -am "racer" && git push --quiet origin HEAD:development\n')
        self.env = {'STUB_CALLS': str(self.calls), 'STUB_LANDING': self.landing}

    def git_id(self, repo):
        sh('git', 'config', 'user.name', 'Fixture', cwd=repo)
        sh('git', 'config', 'user.email', 'fixture@example.invalid', cwd=repo)

    def reconcile(self, *extra_env):
        env = dict(self.env, **dict(extra_env))
        sh('python3', str(self.stub), '--pr', '7', '--catch-up', '--gate', '--qualify', cwd=self.clone, env=env)
        return env

    def race(self):
        sh('bash', str(self.race_script), cwd=self.tmp)

    def publish(self, env, expect_rc=0):
        result = sh('python3', str(PUBLISH), '--reconcile-args', '--pr 7 --catch-up --gate --qualify',
                    '--reconcile-cmd', f'python3 {self.stub}', cwd=self.clone, check=False, env=env)
        self.assertEqual(result.returncode, expect_rc, result.stdout + result.stderr)
        return result

    def remote_log(self):
        return sh('git', 'log', '--format=%s', f'origin/development', cwd=self.racer_synced()).stdout.split('\n')

    def racer_synced(self):
        sh('git', 'fetch', '--quiet', 'origin', cwd=self.racer)
        return self.racer

    def remote_file(self, path):
        return sh('git', 'show', f'origin/development:{path}', cwd=self.racer_synced()).stdout

    def stub_calls(self):
        return [json.loads(l) for l in self.calls.read_text().splitlines()] if self.calls.exists() else []

    def test_protected_publication_retains_receipts_without_pushing_development(self):
        from unittest.mock import patch
        import hosted_lane_publish as publisher
        import test_admission as admission
        self.reconcile()
        before = sh('git', 'rev-parse', 'HEAD', cwd=self.clone).stdout.strip()
        called = []
        def opened(repo, branch, full, title, body):
            called.append((repo, branch, full))
            return {'html_url': 'https://github.com/owner/repo/pull/1'}
        previous = os.getcwd()
        try:
            os.chdir(self.clone)
            with patch.object(publisher, 'pending_publication', return_value=[]), patch.object(admission, 'open_pr', side_effect=opened):
                self.assertEqual(publisher.main(['--protected', '--repo', 'owner/repo']), 0)
            self.assertEqual(len(called), 1)
            remote = sh('git', 'ls-remote', 'origin', 'refs/heads/development', cwd=self.clone).stdout.split()[0]
            self.assertEqual(remote, before)
            published = sh('git', 'ls-remote', 'origin', 'refs/heads/' + called[0][1], cwd=self.clone).stdout.split()[0]
            self.assertEqual(published, called[0][2])
            result = admission.inspect(self.clone, before)
            self.assertEqual(result['decision']['outcome'], 'no-add')
            self.assertFalse(result['approval_trusted'])
            paths = sh('git', 'diff', '--name-only', before, 'HEAD', cwd=self.clone).stdout.splitlines()
            self.assertTrue(any(p.endswith('/provenance.jsonl') for p in paths))
            # Recovery exclusion requires bot identity AND an allowlisted landed diff.
            pr = {'user': {'id':41898282}, 'head': {'ref':called[0][1]}, 'merge_commit_sha':called[0][2]}
            self.assertTrue(publisher.publication_landing(self.clone, pr))
            self.assertFalse(publisher.publication_landing(self.clone, {**pr, 'user':{'id':1}}))
            (self.clone/'runtime.py').write_text('print("unapproved runtime")\n')
            sh('git','add','runtime.py',cwd=self.clone); sh('git','commit','-qm','code cannot be disguised as reconciliation',cwd=self.clone)
            pr['merge_commit_sha'] = sh('git','rev-parse','HEAD',cwd=self.clone).stdout.strip()
            self.assertFalse(publisher.publication_landing(self.clone, pr))
        finally:
            os.chdir(previous)

    def test_no_race_is_one_commit_one_push(self):
        env = self.reconcile()
        out = self.publish(env)
        self.assertIn('pushed 4 declared path(s)', out.stdout)
        self.assertEqual(self.remote_log()[:2], ['chore: reconcile merged development work', 'Merge PR #7'])
        # the real helper staged exactly the declared paths under the bot identity
        self.assertEqual(sh('git', 'log', '-1', '--format=%an <%ae>', 'origin/development', cwd=self.racer_synced()).stdout.strip(),
                         'github-actions[bot] <41898282+github-actions[bot]@users.noreply.github.com>')
        staged = sh('git', 'show', '--name-only', '--format=', 'origin/development', cwd=self.racer).stdout.split()
        self.assertEqual(sorted(staged), sorted(['releases.sql', 'PROJECT/2-WORKING/GH-740-fixture.md',
                                                 f'TESTS-RESULTS/2026-09-21+GH-591/wave-{self.landing}/provenance.jsonl',
                                                 f'TESTS-RESULTS/2026-09-21+GH-591/wave-{self.landing}/validation.jsonl']))
        self.assertEqual(len(self.stub_calls()), 1)

    def test_race_publishes_receipts_first_then_recomputes_once(self):
        env = self.reconcile()
        self.race()
        # Red control — what the inline step did: the stale clone's plain push is rejected.
        stale = self.tmp / 'stale'
        shutil.copytree(self.clone, stale, symlinks=True)
        sh('git', 'add', '-A', cwd=stale)
        sh('git', 'commit', '--quiet', '-m', 'stale', cwd=stale)
        rejected = sh('git', 'push', 'origin', 'HEAD:development', cwd=stale, check=False)
        self.assertNotEqual(rejected.returncode, 0)
        self.assertIn('[rejected]', rejected.stderr)

        out = self.publish(env)
        log = self.remote_log()
        self.assertEqual(log[:4], ['chore: reconcile merged development work',
                                   f'chore: retain qualification receipts for {self.landing}',
                                   'racer', 'Merge PR #7'])
        self.assertIn('-- racer line', self.remote_file('releases.sql'))          # the racer's contribution survived
        self.assertIn('-- transition by stub run 2', self.remote_file('releases.sql'))
        self.assertNotIn('-- transition by stub run 1', self.remote_file('releases.sql'))  # stale bytes discarded
        calls = self.stub_calls()
        self.assertEqual(len(calls), 2)
        self.assertEqual(calls[1], ['--catch-up', '--gate', '--qualify', '--pr', '7', '--only-receipted', '--skip-pull'])
        # The PRODUCTION consumer accepts the published receipt; a corrupted copy is refused.
        sh('git', 'pull', '--quiet', '--ff-only', 'origin', 'development', cwd=self.clone)
        entries = wave.committed_qualifications(str(self.clone))
        self.assertEqual(len(entries), 1)
        meta = dict(number=7, artifactKind='pr', mergeCommit={'oid': self.landing})
        self.assertTrue(wave.qualification_receipt_matches(str(self.clone), entries[0], meta))
        telemetry = self.clone / entries[0]['telemetry']
        telemetry.write_bytes(telemetry.read_bytes() + b'\n')
        self.assertFalse(wave.qualification_receipt_matches(str(self.clone), entries[0], meta))
        self.assertIn('receipts published', out.stdout)

    def test_second_race_exits_loudly_with_receipts_kept_and_one_recompute(self):
        env = self.reconcile(('STUB_RACE_AGAIN', str(self.race_script)))
        self.race()
        result = self.publish(env, expect_rc=1)
        racing = sh('git', 'rev-parse', 'origin/development', cwd=self.racer_synced()).stdout.strip()
        self.assertIn(f'hosted-lane-publish: ERROR — push rejected after recompute; origin/development moved to {racing[:12]}', result.stderr)
        self.assertIn('nothing expensive was lost', result.stderr)
        log = self.remote_log()
        self.assertEqual(log[:3], ['racer', f'chore: retain qualification receipts for {self.landing}', 'racer'])
        self.assertEqual(len(self.stub_calls()), 2)

    def test_race_without_receipts_exits_without_retry(self):
        env = self.reconcile(('STUB_NO_RECEIPTS', '1'))
        self.race()
        result = self.publish(env, expect_rc=1)
        self.assertIn('no receipts this run', result.stderr)
        self.assertEqual(len(self.stub_calls()), 1)
        self.assertEqual(self.remote_log()[0], 'racer')

    def test_undeclared_artifact_is_refused_before_any_push(self):
        env = self.reconcile()
        (self.clone / 'utils/py').mkdir(parents=True)
        (self.clone / 'utils/py/unexpected.py').write_text('x = 1\n')
        result = self.publish(env, expect_rc=1)
        self.assertIn('Refusing undeclared reconciliation artifacts', result.stderr)
        self.assertIn('utils/py/unexpected.py', result.stderr)
        self.assertEqual(self.remote_log()[0], 'Merge PR #7')

    def test_retry_argv_coalesces_targets_for_the_production_parser(self):
        # GH-740 F6a: wave_reconcile's --pr/--commit are nargs="+" store options — a repeated option
        # overwrites. Build the parser from the PRODUCTION declarations and prove the coalesced argv
        # keeps every id; the naive repeated form is the red control.
        import importlib.util
        spec = importlib.util.spec_from_file_location('gh740_publish', PUBLISH)
        publish = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(publish)
        tree = ast.parse((source / 'utils/py/wave_reconcile.py').read_text())
        main = next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == 'main')
        parser = argparse.ArgumentParser()
        for node in ast.walk(main):
            if (isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute) and node.func.attr == 'add_argument'
                    and node.args and isinstance(node.args[0], ast.Constant)
                    and node.args[0].value in ('--pr', '--commit', '--catch-up', '--gate', '--qualify',
                                               '--only-receipted', '--skip-pull')):
                exec(compile(ast.fix_missing_locations(ast.Module(body=[ast.Expr(node)], type_ignores=[])), '<production-parser>', 'exec'),
                     {'parser': parser})
        argv = publish.retry_argv('--pr 42 --catch-up --gate --qualify', ['5', '6'], [])
        self.assertEqual(argv, ['--catch-up', '--gate', '--qualify', '--pr', '42', '5', '6', '--only-receipted', '--skip-pull'])
        self.assertEqual(parser.parse_args(argv).pr, ['42', '5', '6'])
        argv = publish.retry_argv('--catch-up --gate --qualify', ['5'], ['c' * 40])
        self.assertEqual(parser.parse_args(argv).commit, ['c' * 40])
        self.assertEqual(parser.parse_args(argv).pr, ['5'])
        # an existing --commit target coalesced with a receipt's commit target (and a receipt PR)
        argv = publish.retry_argv('--commit ' + 'b' * 40 + ' --catch-up --gate --qualify', ['5'], ['c' * 40])
        self.assertEqual(parser.parse_args(argv).commit, ['b' * 40, 'c' * 40])
        self.assertEqual(parser.parse_args(argv).pr, ['5'])
        # red control: the repeated-option form the parser overwrites
        self.assertEqual(parser.parse_args(['--pr', '42', '--pr', '5']).pr, ['5'])



unittest.main(verbosity=2)
PY
