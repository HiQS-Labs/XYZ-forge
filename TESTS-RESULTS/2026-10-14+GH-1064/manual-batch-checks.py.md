# manual_batch_checks.py (GH-1064 manual check; GH-831 keeps it out of the suites)

Run: `python3 manual_batch_checks.py <repo> [TestClass[.method]]`, unsandboxed (GH-177).

```python
#!/usr/bin/env python3
"""GH-1064 manual checks (GH-831: kept out of the repo's suites). The scenarios formerly drafted as
TestBatchIssue, run against the existing gh534 phase B fixture.
Usage: python3 manual_batch_checks.py <repo> [unittest args, e.g. -k name]"""
import contextlib, io, json, os, sys, unittest
import unittest.mock as mock
from pathlib import Path

REPO = Path(sys.argv.pop(1)).resolve()
sys.path.insert(0, str(REPO / "test"))
from gh534_phase_b_tests import LedgerFixture, _git, commit_all, park, merge_cleanup  # noqa: E402
import batch_record  # noqa: E402


def batch_of(primary):
    paths = sorted(Path(primary).glob(".tick/merge-cleanup/*/batch-*.json"))
    return json.loads(paths[-1].read_text()) if paths else None


class _Fixture(LedgerFixture):
    def run_main(self, execute=True, extra=(), teardown_ok=True):
        argv = ["merge_cleanup.py", "--primary", str(self.primary), "--root", str(self.tmp / "no-roots")] + list(extra)
        if execute:
            argv.append("--execute")
        err = io.StringIO()
        with mock.patch.object(sys, "argv", argv), \
             mock.patch.object(merge_cleanup, "prune_dangling_skill_symlinks") as pruner, \
             mock.patch.object(merge_cleanup, "teardown_checkout", return_value=teardown_ok) as teardown, \
             mock.patch.object(merge_cleanup, "scan_directories", return_value=[]), \
             contextlib.redirect_stderr(err):
            rc = merge_cleanup.main()
        self.pruner, self.teardown, self.err = pruner, teardown, err.getvalue()
        return rc


class TestHeldPr(_Fixture):
    def test_held_pr_is_recorded_as_skipped_and_the_free_one_lands(self):
        self.branch("feat/held", 1, lambda r: park(r, 200, "held"), labels=["do-not-merge"])
        self.branch("feat/b", 2, lambda r: park(r, 201, "free"))
        self.assertEqual(self.run_main(), 4, self.err)
        rec = batch_of(self.primary)
        self.assertEqual(rec["outcomes"]["1"]["status"], "skipped: hold-label 'do-not-merge'")
        self.assertEqual((rec["outcomes"]["2"]["status"], rec["outcomes"]["2"]["reconcile"]), ("merged", "ok"))
        self.teardown.assert_not_called()
        self.pruner.assert_called_once()


class TestBatchIssue(_Fixture):
    """GH-1064: the script-owned merge-batch record and issue, for queues of 2+ PRs."""

    def files(self, n, *paths):
        self.st["prs"][str(n)]["files"] = [{"path": p} for p in paths]
        self.save()

    def issue(self):
        issues = self.load().get("issues", {})
        self.assertEqual(len(issues), 1, f"expected exactly one batch issue, got {list(issues)}")
        return next(iter(issues.items()))

    def verdict(self, text):
        f = self.tmp / f"verdict-{len(os.listdir(self.tmp))}.md"
        f.write_text(text)
        never = AssertionError("--record-sweep reached Phase 0 / discovery")  # it must do neither
        with mock.patch.object(merge_cleanup, "prepare_primary_landing", side_effect=never), \
             mock.patch.object(merge_cleanup, "fetch_open_prs_with_retry", side_effect=never):
            return self.run_main(execute=False, extra=["--record-sweep", str(f)])

    def oid(self, n):
        return self.load()["prs"][str(n)]["mergeCommit"]

    def test_two_pr_queue_opens_the_issue_before_the_first_merge_and_exits_4(self):
        self.branch("feat/a", 1, lambda r: park(r, 200, "from PR 1"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "from PR 2"))
        self.files(1, "releases.sql", "a.txt")
        self.files(2, "releases.sql", "b.txt")
        rc = self.run_main()
        self.assertEqual(rc, 4, self.err)
        names = [c[:2] for c in self.load()["calls"]]
        self.assertLess(names.index(["issue", "create"]), names.index(["pr", "merge"]), "issue opened after a merge")
        _, body = self.issue()
        self.assertIn("| 1 | #1 PR 1 | — | — | merged |", body)
        self.assertIn("| 2 | #2 PR 2 | — | #1: releases.sql | merged |", body, "soft-edge files missing from the plan")
        rec = batch_of(self.primary)
        self.assertEqual(rec["landed_order"], [1, 2])
        self.assertEqual({n: o["reconcile"] for n, o in rec["outcomes"].items()}, {"1": "ok", "2": "ok"})
        self.assertEqual(rec["sweep_inputs"]["range"], f"{self.oid(1)}^1..{self.oid(2)}")
        self.assertEqual(rec["sweep_inputs"]["shared_files"], {"releases.sql": [1, 2]}, "a single-PR file was listed as shared")
        self.assertIn("QA pending", body)
        self.pruner.assert_called_once()  # Phase 6 ran before exit 4
        # A Phase 6 failure outranks QA pending: the QA-only resume tears down a failing checkout → 2.
        doomed = [{"disposition": "SAFE_REMOVE_CLONE", "path": str(self.tmp / "doomed")}]
        with mock.patch.object(merge_cleanup, "refresh_for_teardown", return_value=doomed):
            self.assertEqual(self.run_main(extra=["--resume"], teardown_ok=False), 2, self.err)
        self.assertTrue(batch_record.qa_pending(batch_of(self.primary)), "QA is still pending under the 2")

    def test_resume_continues_the_batch_and_a_new_landing_reopens_qa(self):
        """R2/R6/R7: one landed + one handed off, a partial verdict, a repaired resume, then QA-only resumes."""
        self.branch("feat/a", 1, lambda r: (r / "README.md").write_text("A\n"))
        self.branch("feat/b", 2, lambda r: (r / "README.md").write_text("B\n"))
        self.files(1, "README.md")
        self.files(2, "README.md")
        self.st["prs"]["2"]["body"] = "Depends on #1"  # hard edge: the sorter records no soft reason
        self.save()
        self.assertEqual(self.run_main(), 3, self.err)
        rec = batch_of(self.primary)
        self.assertEqual(rec["planned"][1]["hard"], [1])
        self.assertEqual(rec["planned"][1]["soft"], {})
        self.assertEqual(rec["outcomes"]["2"]["status"], "handoff")
        self.assertEqual(self.verdict("verdict: clean\nran gh436 on PR 1's landing\n"), 0, self.err)
        self.assertEqual(batch_of(self.primary)["verdict"]["covers"], [1])
        w = self.clone("repair-2")  # repair PR 2 on top of the new development
        _git(w, "checkout", "-q", "feat/b")
        _git(w, "merge", "origin/development", check=False)
        (w / "README.md").write_text("B\n")
        commit_all(w, "resolve")
        _git(w, "push", "-q", "origin", "feat/b")
        self.assertEqual(self.run_main(extra=["--resume"]), 4, self.err)
        rec = batch_of(self.primary)
        self.assertEqual(rec["landed_order"], [1, 2])
        self.assertEqual(rec["sweep_inputs"]["range"], f"{self.oid(1)}^1..{self.oid(2)}")
        self.assertEqual(rec["sweep_inputs"]["shared_files"], {"README.md": [1, 2]}, "R7: file lists lost across resume")
        self.assertEqual(rec["verdict"]["covers"], [1], "the partial verdict must stay partial")
        self.assertEqual(self.run_main(extra=["--resume"]), 4, "QA-only resume with an empty queue")
        self.assertEqual(self.verdict("verdict: clean\nran gh436 on both landings\n"), 0, self.err)
        self.assertEqual(self.run_main(extra=["--resume"]), 0, self.err)
        self.issue()  # still exactly one issue across all five runs

    def test_pre_merge_stop_is_recorded_against_the_pr_in_hand(self):
        self.branch("feat/a", 1, lambda r: park(r, 200, "x"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "y"))
        red = {"green": False, "failures": ["releases check: FAIL: rule=synthetic"], "diagnostics": []}
        with mock.patch.object(merge_cleanup, "pre_merge_ledger_gate", return_value=red):
            rc = self.run_main()
        self.assertEqual(rc, 2)
        self.assertFalse(any(c[:2] == ["pr", "merge"] for c in self.load()["calls"]))
        out = batch_of(self.primary)["outcomes"]
        self.assertTrue(out["1"]["status"].startswith("stopped:"), out)
        self.assertIn("releases check: FAIL: rule=synthetic", out["1"]["status"])
        self.assertEqual(out["2"]["status"], "unattempted")
        self.assertIn("stopped:", self.issue()[1])

    def test_post_merge_stop_keeps_the_merge_and_names_the_reconcile_failure(self):
        self.branch("feat/a", 1, lambda r: park(r, 200, "x"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "y"))
        with mock.patch.object(merge_cleanup, "run_post_merge_reconcile", return_value=False):
            rc = self.run_main()
        self.assertEqual(rc, 2)
        out = batch_of(self.primary)["outcomes"]
        self.assertEqual((out["1"]["status"], out["1"]["merge_oid"]), ("merged", self.oid(1)))
        self.assertTrue(out["1"]["reconcile"].startswith("failed:"), out)
        self.assertEqual(out["2"]["status"], "unattempted")

    def test_record_sweep_keeps_caller_sections_and_refuses_bad_input(self):
        self.branch("feat/a", 1, lambda r: park(r, 200, "x"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "y"))
        self.assertEqual(self.run_main(), 4, self.err)
        n, body = self.issue()
        body = body.replace("## Findings\n", "## Findings\nfound X in the review\n")
        body = body.replace("## Post-deployment carry-overs\n", "## Post-deployment carry-overs\n- [ ] #1: operator verification\n")
        st = self.load()
        st["issues"][n] = body
        self.st = st
        self.save()
        for bad in ("", "hello\n", "verdict: clean\n", "verdict: findings\nno checklist\n"):
            self.assertEqual(self.verdict(bad), 2, f"accepted {bad!r}")
        self.assertIsNone(batch_of(self.primary)["verdict"], "a refused verdict was stored")
        self.assertEqual(self.verdict("verdict: findings\n- [ ] #2: retry path unverified (log line 12)\n"), 0, self.err)
        after = self.load()["issues"][n]
        self.assertIn("found X in the review\n", after)
        self.assertIn("- [ ] #1: operator verification\n", after)
        self.assertIn("**findings** covering #1, #2", after)
        self.assertNotIn("QA pending", after)



class TestGh1074ResumeKeepsHistory(_Fixture):
    """GH-1074: resume never loses merge history or reports QA complete."""
    def two_landed(self):
        self.branch("feat/a", 1, lambda r: park(r, 200, "x"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "y"))
        self.assertEqual(self.run_main(), 4, self.err)

    def test_s1_resume_with_unrelated_new_pr_still_reports_qa_pending(self):
        self.two_landed()
        self.st = self.load()
        self.branch("feat/c", 3, lambda r: (r / "C.md").write_text("c\n"))
        rc = self.run_main(extra=["--resume"])
        print("S1 rc", rc, "batch landed", batch_of(self.primary)["landed_order"])
        self.assertEqual(rc, 4, "QA for #1,#2 silently dropped")

    def test_s2_record_missing_landed_order(self):
        self.two_landed()
        p = sorted(Path(self.primary).glob(".tick/merge-cleanup/*/batch-*.json"))[-1]
        rec = json.loads(p.read_text()); rec.pop("landed_order"); p.write_text(json.dumps(rec))
        rc = self.run_main(extra=["--resume"])
        print("S2 rc", rc)
        self.assertEqual(rc, 4)

    def test_s3_merged_pr_requeued_keeps_merged_status(self):
        self.two_landed()
        st = self.load(); st["prs"]["1"]["state"] = "OPEN"; self.st = st; self.save()  # stale OPEN listing
        rc = self.run_main(extra=["--resume"])
        out = batch_of(self.primary)["outcomes"]["1"]
        print("S3 rc", rc, out)
        self.assertEqual(out["status"], "merged")


if __name__ == "__main__":
    unittest.main()
```
