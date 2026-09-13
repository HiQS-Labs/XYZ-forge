#!/usr/bin/env bash
# Focused, git-free receipts test. All fixtures are temporary; no shared setup hooks.
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


unittest.main(verbosity=2)
PY
