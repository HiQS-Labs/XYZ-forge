#!/usr/bin/env bash
# Receipt attribution plus disposable Git qualification fixtures; no network or shared setup.
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec python3 -B - "$ROOT" "$@" <<'PY'
import contextlib
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

root = Path(sys.argv.pop(1))
sys.path.insert(0, str(root / "utils/py"))
import wave_reconcile as wave

SHA = "a1" * 20
META = {"number": 425, "state": "MERGED", "baseRefName": "development",
        "title": "Receipt check", "body": "", "mergeCommit": {"oid": SHA}}


class Receipts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=os.environ.get("GH425_SCRATCH"))
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        self.results = self.repo / "TESTS-RESULTS"
        # Any accidental external command (including git) fails the suite.
        self.external = patch.object(wave.subprocess, "run",
                                     side_effect=AssertionError("unexpected subprocess"))
        self.external.start()
        self.addCleanup(self.external.stop)

    def receipt(self, content, name="run/provenance.jsonl"):
        path = self.results / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def gate(self, meta=None):
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            try:
                wave.check_provenance_receipts(str(self.repo), META if meta is None else meta)
                code = 0
            except wave.ReconcileError as exc:
                code = exc.code
        return code, out.getvalue()

    def test_wrong_pr_is_rejected(self):
        path = self.receipt('{"pr": 999, "status": "PASS"}\n')
        self.assertGreater(path.stat().st_size, 0)
        code, output = self.gate()
        self.assertEqual(code, 6, f"unrelated PR #999 was accepted for PR #425:\n{output}")

    def test_matching_pr_names_receipt_and_field(self):
        for field in ("pr", "pr_number"):
            for value in (425, "425"):
                with self.subTest(field=field, value=value):
                    self.receipt(json.dumps({field: value}) + "\n")
                    code, output = self.gate()
                    self.assertEqual(code, 0, output)
                    self.assertIn("TESTS-RESULTS/run/provenance.jsonl:1", output)
                    self.assertIn(f"{field}=425", output)
                    self.assertNotIn("compliant", output)

    def test_merge_commit_matches_exactly(self):
        self.receipt(json.dumps({"commit": SHA}) + "\n")
        code, output = self.gate()
        self.assertEqual(code, 0, output)
        self.assertIn(f"commit={SHA}", output)

    def test_unattributable_receipts_fail(self):
        for record in ({}, {"issue": 425}, {"pr": 4250}, {"pr": True},
                       {"pr": 425.0}, {"pr": {"number": 425}},
                       {"message": "PR #425 passed"}, {"commit": SHA[:6]},
                       {"commit": "b2" * 20}, {"commit": None},
                       {"pr": 999, "commit": SHA},
                       {"pr": 425, "pr_number": 999}):
            with self.subTest(record=record):
                self.receipt(json.dumps(record) + "\n")
                self.assertEqual(self.gate()[0], 6)

    def test_short_sha_matches_candidate_prefix(self):
        self.receipt(json.dumps({"commit": SHA[:8]}) + "\n")
        code, output = self.gate()
        self.assertEqual(code, 0, output)
        self.assertIn(f"commit={SHA[:8]}", output)

    def test_squashed_branch_commit_lineage_matches(self):
        squash_sha = "c3" * 20
        branch_head = "d4" * 20
        branch_commit_1 = "e5" * 20
        branch_commit_2 = "f6" * 20
        meta = {
            "number": 565,
            "state": "MERGED",
            "mergeCommit": {"oid": squash_sha},
            "headRefOid": branch_head,
            "commits": [{"oid": branch_commit_1}, {"oid": branch_commit_2}],
        }
        for commit_val in (branch_head, branch_head[:8], branch_commit_1, branch_commit_2[:10]):
            with self.subTest(commit_val=commit_val):
                self.receipt(json.dumps({"commit": commit_val}) + "\n")
                code, output = self.gate(meta=meta)
                self.assertEqual(code, 0, output)
                self.assertIn(f"commit={commit_val}", output)

    def test_missing_directory_fails(self):
        code, output = self.gate()
        self.assertEqual(code, 6)
        self.assertIn("directory missing", output)

    def test_empty_or_malformed_receipts_fail(self):
        for content in ("", "\n", "not json\n", "null\n", "[]\n", "425\n", '"425"\n'):
            with self.subTest(content=content):
                self.receipt(content)
                self.assertEqual(self.gate()[0], 6)

    def test_later_record_and_error_log(self):
        self.receipt('{"pr":999}\n')
        self.receipt('bad json\nnull\n{"pr_number":425}\n', "second/error_log.jsonl")
        code, output = self.gate()
        self.assertEqual(code, 0, output)
        self.assertIn("second/error_log.jsonl:3", output)

    def test_names_and_symlinks_are_not_evidence(self):
        self.receipt('{"issue":425}\n', "PR-425/provenance.jsonl")
        other = self.repo / "outside.jsonl"
        other.write_text('{"pr":425}\n')
        (self.results / "provenance.jsonl").symlink_to(other)
        self.assertEqual(self.gate()[0], 6)

    def test_missing_identity_cannot_match_null(self):
        self.receipt('{"pr":null,"commit":null}\n')
        self.assertEqual(self.gate({})[0], 6)

    def test_metadata_requests_merge_commit(self):
        with patch.object(wave.subprocess, "run") as run:
            run.return_value.returncode = 0
            run.return_value.stdout = json.dumps(META)
            self.assertEqual(wave.fetch_pr_metadata(str(self.repo), 425), META)
            fields = run.call_args.args[0][-1].split(",")
            self.assertIn("mergeCommit", fields)
            self.assertIn("headRefOid", fields)
            self.assertIn("commits", fields)

    def test_cli_gate_and_ungated_path(self):
        (self.repo / ".git").mkdir()
        for flag, receipt_pr, expected in (("--gate", 999, 6),
                                           ("--require-receipts", 999, 6),
                                           ("--gate", 425, 0),
                                           ("--require-receipts", 425, 0),
                                           (None, 999, 0)):
            self.receipt(json.dumps({"pr": receipt_pr}) + "\n")
            with self.subTest(flag=flag, receipt_pr=receipt_pr), contextlib.ExitStack() as stack:
                for name, value in (("check_porcelain_cleanliness", None),
                                    ("check_current_branch", None),
                                    ("github_slug_from_origin", "example/repo"),
                                    ("fetch_pr_metadata", META),
                                    ("run_subprocesses", None),
                                    ("run_validation_gate", None)):
                    stack.enter_context(patch.object(wave, name, return_value=value))
                argv = ["wave-reconcile", "--root", str(self.repo), "--pr", "425", "--skip-pull"]
                stack.enter_context(patch.object(sys, "argv", argv + ([flag] if flag else [])))
                output = stack.enter_context(contextlib.redirect_stdout(io.StringIO()))
                stack.enter_context(contextlib.redirect_stderr(output))
                code = 0
                try:
                    wave.main()
                except SystemExit as exc:
                    code = exc.code
                self.assertEqual(code, expected, output.getvalue())
                self.assertEqual(wave.run_subprocesses.call_count, int(expected == 0))


    def test_cli_commit_landing_gate_express_receipt(self):
        """GH-592 red control: --commit <sha> --gate on a direct (express) landing.
        (a) no receipt -> 6 with the matcher's message; (b) the receipt the express
        driver's own helper writes for A -> gate passes; (c) same receipt vs a
        declared commit B -> 6 (B is declared, so the matcher, not exit 4, decides)."""
        import importlib.util
        spec = importlib.util.spec_from_file_location("express", root / "utils/py/express.py")
        express = importlib.util.module_from_spec(spec)
        with patch.object(sys, "argv", ["express"]):
            spec.loader.exec_module(express)
        (self.repo / ".git").mkdir()
        sha_a, sha_b = "c3" * 20, "d4" * 20
        manifest = self.repo / "offline.json"
        manifest.write_text(json.dumps({"commits": [
            {"sha": sha_a, "message": "fix(GH-592): demo [express]\n\nCloses #592", "committedAt": "2026-09-13T00:00:00Z"},
            {"sha": sha_b, "message": "fix(GH-591): other [express]\n\nCloses #591", "committedAt": "2026-09-13T00:00:00Z"},
        ], "issues": [{"number": 592, "state": "OPEN"}, {"number": 591, "state": "OPEN"}]}))

        def run_cli(commit):
            with contextlib.ExitStack() as stack:
                for name, value in (("check_porcelain_cleanliness", None),
                                    ("check_current_branch", None),
                                    ("github_slug_from_origin", "example/repo"),
                                    ("run_subprocesses", None),
                                    ("run_validation_gate", None)):
                    stack.enter_context(patch.object(wave, name, return_value=value))
                stack.enter_context(patch.object(sys, "argv", [
                    "wave-reconcile", "--root", str(self.repo), "--commit", commit, "--gate",
                    "--offline", str(manifest), "--skip-pull", "--skip-branch-check", "--dry-run"]))
                output = stack.enter_context(contextlib.redirect_stdout(io.StringIO()))
                stack.enter_context(contextlib.redirect_stderr(output))
                code = 0
                try:
                    wave.main()
                except SystemExit as exc:
                    code = exc.code
                return code, output.getvalue()

        # (a) RED: no receipt anywhere
        self.results.mkdir()
        code, out = run_cli(sha_a)
        self.assertEqual(code, 6, out)
        self.assertIn("No provenance.jsonl or error_log.jsonl entry matches", out)
        # (b) GREEN: the express driver's own writer produced the receipt for A
        rel = express.write_receipt(str(self.repo), sha_a, 592, "test/gh592-demo.sh", 0)
        self.assertTrue((self.repo / rel).is_file(), rel)
        rec = json.loads((self.repo / rel).read_text().splitlines()[0])
        self.assertEqual((rec["commit"], rec["gate"], rec["rc"], rec["command"]),
                         (sha_a, "express-suite", 0, "bash test/gh592-demo.sh"))
        code, out = run_cli(sha_a)
        self.assertNotEqual(code, 6, out)
        self.assertIn(f"Provenance receipt matched for PR #{sha_a[:12]}", out)
        # (c) RED again: the same receipt is not evidence for a different declared commit
        code, out = run_cli(sha_b)
        self.assertEqual(code, 6, out)
        self.assertIn("No provenance.jsonl or error_log.jsonl entry matches", out)
        # the shared predicate rejects failed / wrong-suite / wrong-issue records
        self.assertTrue(express.valid_express_receipt(rec, sha_a, 592, "test/gh592-demo.sh"))
        for bad in ({**rec, "rc": 1, "result": "fail"}, {**rec, "command": "bash test/other.sh"},
                    {**rec, "issue": 591}, {**rec, "commit": sha_b}, {**rec, "rc": "0"}):
            self.assertFalse(express.valid_express_receipt(bad, sha_a, 592, "test/gh592-demo.sh"), bad)
        # and find_receipt is by content, so a second write for the same landing is a no-op
        self.assertEqual(express.write_receipt(str(self.repo), sha_a, 592, "test/gh592-demo.sh", 0), rel)
        self.assertEqual(len((self.repo / rel).read_text().splitlines()), 1)
        # explicit PR identity is not express evidence (the real matcher treats it as conflicting)
        self.assertFalse(express.valid_express_receipt({**rec, "pr": 999}, sha_a, 592, "test/gh592-demo.sh"))
        # bare and test/-prefixed suite spellings are one expectation
        self.assertTrue(express.valid_express_receipt(rec, sha_a, 592, "gh592-demo.sh"))
        # I5: an unterminated prior line must not swallow the next record
        (self.repo / rel).write_text((self.repo / rel).read_text().rstrip("\n") + "\n{")
        rel2 = express.write_receipt(str(self.repo), sha_b, 592, "test/gh592-demo.sh", 0)
        self.assertEqual(rel2, rel)
        lines = (self.repo / rel2).read_text().splitlines()
        self.assertEqual(len(lines), 3, lines)
        self.assertEqual(json.loads(lines[-1])["commit"], sha_b)
        code, out = run_cli(sha_b)
        self.assertNotEqual(code, 6, out)
        # I5 variant: a VALID prior record that merely lacks its final newline is preserved intact
        (self.repo / rel).write_text((self.repo / rel).read_text().rstrip("\n"))
        sha_d = "f6" * 20
        express.write_receipt(str(self.repo), sha_d, 592, "test/gh592-demo.sh", 0)
        lines = (self.repo / rel).read_text().splitlines()
        self.assertEqual([json.loads(l)["commit"] for l in lines if l.startswith("{\"")], [sha_a, sha_b, sha_d])
        # a symlinked provenance.jsonl is not evidence for express either — falsifiable: the
        # ONLY record for sha_c lives behind a symlink in a directory that sorts FIRST
        # ("0-link" < "2026-…"), so removing the symlink guard would make find_receipt return it.
        sha_c = "e5" * 20
        outside = self.repo / "outside-provenance.jsonl"
        outside.write_text(json.dumps({**rec, "commit": sha_c}) + "\n")
        (self.repo / "TESTS-RESULTS" / "0-link").mkdir()
        (self.repo / "TESTS-RESULTS" / "0-link" / "provenance.jsonl").symlink_to(outside)
        self.assertTrue(express.valid_express_receipt(json.loads(outside.read_text()), sha_c, 592, "test/gh592-demo.sh"))
        self.assertIsNone(express.find_receipt(str(self.repo), sha_c, 592, "test/gh592-demo.sh"))
        self.assertEqual(express.find_receipt(str(self.repo), sha_a, 592, "test/gh592-demo.sh"), rel)
        # and the writer refuses to write THROUGH a symlink at the receipt path
        linked_dir = self.repo / "TESTS-RESULTS" / ("%s+GH-590-express" % express.datetime.datetime.now(express.datetime.timezone.utc).strftime("%Y-%m-%d"))
        linked_dir.mkdir()
        (linked_dir / "provenance.jsonl").symlink_to(outside)
        with self.assertRaises(SystemExit):
            with contextlib.redirect_stderr(io.StringIO()):
                express.write_receipt(str(self.repo), sha_c, 590, "test/gh590-demo.sh", 0)
        self.assertEqual(len(outside.read_text().splitlines()), 1)  # nothing was appended through the link
class Qualification(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='gh591-qualification-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / 'source'
        self.root.mkdir()
        import subprocess
        self.subprocess = subprocess
        self.git('init', '-b', 'development')
        self.git('config', 'user.name', 'Fixture')
        self.git('config', 'user.email', 'fixture@example.invalid')
        self.git('remote', 'add', 'origin', 'https://example.invalid/fixture/repo')
        self.bin = Path(self.tmp.name) / 'bin'
        self.bin.mkdir()
        (self.bin / 'npm').write_text('#!/bin/sh\nexit 0\n')
        (self.bin / 'npm').chmod(0o755)
        (self.root / 'validate.sh').write_text('''#!/bin/sh
test "$1" = --sequential || exit 7
test -z "${XYZ_VALIDATE_SKIP:-}" || exit 8
test -z "${RT_SHARD:-}" || exit 9
test -z "${XYZ_HARNESS_DB:-}" || exit 10
test -z "${PYTEST_ADDOPTS:-}" || exit 11
test "$TICK_REPO_ROOT" = "$(pwd -P)" || exit 12
if [ "${GH591_FIXTURE:-}" = red ]; then exit 42; fi
if [ "${GH591_FIXTURE:-}" = drift ]; then git config core.bare true; exit 0; fi
python3 - <<'FIXTURE'
import os,json,pathlib,subprocess
sha=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()
rows=[dict(event='run.start',commit=sha,mode='sequential',tier=3,registered=1)]
rows += [dict(event='suite',lane=lane,name=name,rc=0) for lane,name in
         [('sequential','fixture.sh'),('non-suite','python:test_python_layer.py'),
          ('non-suite','gamma-poison-staleness-probe')]]
rows.append(dict(event='run.summary',passed=4,failed=0,total=4,envelope_rc='0',
                 suite_events_match='yes',run_set='1',registered='1'))
for row in rows: row.update(run=sha[:9]+'-'+str(os.getppid()),runner='validate')
if os.environ.get('GH591_FIXTURE') == 'wrong-run':
    for row in rows: row['run']='unrelated'
if os.environ.get('GH591_FIXTURE') == 'empty': rows=[]
if os.environ.get('GH591_FIXTURE') == 'nonobject': rows=[None]
if os.environ.get('GH591_FIXTURE') == 'partial': rows.pop()
p=pathlib.Path(os.environ.get('XYZ_VALIDATE_TELEMETRY','.tick/telemetry'))
p.mkdir(parents=True)
(p/'validate-sequential-nested-0.jsonl').write_text('{}')
(p/('validate-sequential-fixture-'+str(os.getppid())+'.jsonl')).write_text(''.join(json.dumps(r)+'\\n' for r in rows))
FIXTURE
''')
        (self.root / '.gitignore').write_text('.tick/\n')
        self.git('add', 'validate.sh', '.gitignore')
        self.git('commit', '-m', 'qualification fixture')
        self.sha = self.git('rev-parse', 'HEAD').strip()
        self.meta = dict(META, mergeCommit={'oid': self.sha})
        self.journal = wave.RollbackJournal()
        self.addCleanup(self.journal.cleanup)

    def git(self, *args):
        return self.subprocess.check_output(['git', *args], cwd=self.root,
                                            stderr=self.subprocess.DEVNULL, text=True)

    def qualify(self, mode='', metas=None):
        with patch.dict(os.environ, PATH=str(self.bin)+os.pathsep+os.environ['PATH'],
                        GH591_FIXTURE=mode, XYZ_VALIDATE_SKIP='fixture.sh', RT_SHARD='1',
                        XYZ_HARNESS_DB='/external/sentinel.db', TICK_REPO_ROOT='/external/tick',
                        PYTEST_ADDOPTS='-k only_one'):
            wave.qualify_landings(str(self.root), metas or [self.meta], self.journal)

    def receipt(self):
        files = list((self.root/'TESTS-RESULTS').rglob('provenance.jsonl'))
        self.assertEqual(len(files), 1)
        return json.loads(files[0].read_text().splitlines()[0])

    def test_full_gate_produces_attributable_retained_proof(self):
        self.qualify()
        entry = self.receipt()
        self.assertEqual(entry['tested_commit'], self.sha)
        self.assertTrue(wave.qualification_receipt_matches(str(self.root), entry, self.meta))
        wave.check_provenance_receipts(str(self.root), self.meta)
        self.assertEqual(wave.committed_qualifications(str(self.root)), [])

    def test_red_partial_and_identity_drift_produce_no_receipt(self):
        for mode in ('red', 'partial', 'drift', 'empty', 'nonobject', 'wrong-run'):
            with self.subTest(mode=mode), self.assertRaises(wave.ReconcileError) as caught:
                self.qualify(mode)
            self.assertEqual(caught.exception.code, 6)
            self.assertFalse(list(self.root.rglob('provenance.jsonl')))
            self.assertEqual(self.git('rev-parse','HEAD').strip(), self.sha)
            self.assertEqual(self.git('status','--porcelain'), '')

    def test_wrong_landing_fails_before_qualification(self):
        with self.assertRaises(wave.ReconcileError):
            self.qualify(metas=[dict(self.meta, mergeCommit={'oid':'b'*40})])
        self.assertFalse(list(self.root.rglob('provenance.jsonl')))

    def test_committed_proof_makes_replay_idempotent(self):
        self.qualify()
        self.git('add','TESTS-RESULTS')
        self.git('commit','-m','generated proof and reconciliation')
        before={str(p):p.read_bytes() for p in (self.root/'TESTS-RESULTS').rglob('*') if p.is_file()}
        self.qualify('red')  # Would fail if the valid committed proof were not reused.
        self.assertEqual(before,{str(p):p.read_bytes() for p in (self.root/'TESTS-RESULTS').rglob('*') if p.is_file()})

    def test_new_schema_cannot_fall_through_to_legacy_pr_match(self):
        self.qualify()
        entry=self.receipt()
        for key,value in [('result','fail'),('rc',False),('tested_commit','c'*40),
                          ('landing_commit','d'*40),('schema_version','wave-qualification@99'),
                          ('telemetry_sha256','0'*64),('pr',999)]:
            with self.subTest(key=key):
                bad=dict(entry, **{key:value})
                path=next((self.root/'TESTS-RESULTS').rglob('provenance.jsonl'))
                path.write_text(json.dumps(bad)+'\n')
                with self.assertRaises(wave.ReconcileError) as caught:
                    wave.check_provenance_receipts(str(self.root), self.meta)
                self.assertEqual(caught.exception.code,6)

    def test_incomplete_or_quarantined_telemetry_is_rejected(self):
        self.qualify()
        entry = self.receipt()
        rows = [json.loads(line) for line in (self.root/entry['telemetry']).read_text().splitlines()]
        for index, field, value in [(0,'registered',0),(-1,'failed',1),(-1,'run_set','0'),
                                    (-1,'suite_events_match','no'),(-1,'envelope_rc','2')]:
            with self.subTest(field=field):
                broken = [dict(row) for row in rows]
                broken[index][field] = value
                with self.assertRaises(ValueError):
                    wave.qualification_summary('\n'.join(json.dumps(row) for row in broken), self.sha)

    def test_bounded_runner_timeout_refuses_receipts(self):
        from proc_group import BoundedResult
        with patch('proc_group.run_bounded', return_value=BoundedResult(None,'','',True,1,5400)) as bounded:
            with self.assertRaises(wave.ReconcileError) as caught:
                self.qualify()
            self.assertEqual(caught.exception.code,6)
            self.assertEqual(bounded.call_args.kwargs['timeout'],5400)
        self.assertFalse(list(self.root.rglob('provenance.jsonl')))

    def test_receipts_participate_in_rollback(self):
        self.qualify()
        self.journal.rollback()
        self.assertFalse(list(self.root.rglob('provenance.jsonl')))
        self.assertFalse(list(self.root.rglob('validation.jsonl')))

    def test_batch_qualifies_once_and_retains_each_landing(self):
        self.qualify(metas=[self.meta,dict(self.meta,number=426)])
        path=next((self.root/'TESTS-RESULTS').rglob('provenance.jsonl'))
        self.assertEqual({json.loads(line)['pr'] for line in path.read_text().splitlines()},{425,426})
unittest.main(verbosity=2)
PY
