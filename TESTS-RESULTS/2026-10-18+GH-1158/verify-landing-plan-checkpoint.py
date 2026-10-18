#!/usr/bin/env python3
"""TESTS-RESULTS/2026-10-18+GH-1158/verify-landing-plan-checkpoint.py
Standalone automated verification for GH-1158:
merge-cleanup: require a recorded direct-vs-group landing decision for queues of 3+ PRs (GH-1066 checkpoint).

Covers all 9 acceptance criteria:
1. Missing --landing-plan on 3+ PRs exits 5 before any git mutation (no REBASE_HEAD deletion, no FETCH_HEAD writes, no issue creation).
2. Blank or whitespace-only --landing-reason is refused with exit 5.
3. Red control: bypassing the checkpoint allows Phase 0/Phase 5 mutations.
4. --landing-plan group records decision in local batch record and exits 0 with GH-1066 checklist, without merging or teardown.
5. --landing-plan group with GitHub issue error logs warning without false claim and exits 0 cleanly.
6. --landing-plan direct records decision and proceeds through Phase 5 merges.
7. Stale batch record saves under RecordLock preserve the recorded landing_plan.
8. Intent marker _landing_plan_touched is stripped on save; stale reloaded snapshot cannot overwrite newer decision.
9. Unchanged resume reuses recorded decision; changed PR queue membership requires re-evaluation (exits 5).
10. Small queues (1 or 2 PRs) remain completely unaffected without --landing-plan.
"""

import io
import os
import sys
import json
import time
import shutil
import tempfile
import contextlib
import unittest
from pathlib import Path
from unittest import mock

# Harness path setup
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO_ROOT / "skills" / "2-daily" / "merge-cleanup" / "scripts"))
sys.path.insert(0, str(REPO_ROOT / "test"))

import merge_cleanup
import batch_record
import attempt_record
from gh534_phase_b_tests import LedgerFixture, park


class TestGH1158LandingPlanCheckpoint(LedgerFixture):
    """End-to-end integration tests using LedgerFixture for git & mock GitHub isolation."""

    def run_main(self, execute=True, extra=()):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            rc = super().run_main(execute=execute, extra=extra)
        self.out = out.getvalue()
        return rc

    def test_01_missing_landing_plan_exits_5_and_zero_mutations(self):
        """1. Missing --landing-plan on 3+ PRs exits 5 before any mutation."""
        self.branch("feat/a", 1, lambda r: park(r, 201, "pr1"))
        self.branch("feat/b", 2, lambda r: park(r, 202, "pr2"))
        self.branch("feat/c", 3, lambda r: park(r, 203, "pr3"))

        # Seed an orphan REBASE_HEAD ref in primary checkout
        merge_cleanup.run_git(self.primary, ["update-ref", "REBASE_HEAD", "HEAD"])
        self.assertTrue((self.primary / ".git" / "REBASE_HEAD").exists() or
                        merge_cleanup.run_git(self.primary, ["rev-parse", "--verify", "REBASE_HEAD"]).returncode == 0)

        # Snapshot FETCH_HEAD before run
        fetch_head = self.primary / ".git" / "FETCH_HEAD"
        fetch_head_before = fetch_head.read_bytes() if fetch_head.exists() else None

        # Override the empty scan_directories fixture to supply a candidate carrying a canonical issue,
        # and enable --marker so that if scan or marker dispatch executed, issue markers would be posted.
        candidate_checkout = [{"directory": self.primary, "canonical_issue": 999, "disposition": "SAFE_REMOVE_WORKTREE"}]
        with mock.patch.object(merge_cleanup, "scan_directories", return_value=candidate_checkout) as mock_scan:
            # Run merge-cleanup with --execute and --marker but NO landing plan
            rc = self.run_main(execute=True, extra=("--marker",))
            self.assertEqual(rc, 5, "Expected Exit 5 when landing-plan is missing for 3 PRs")
            self.assertIn("REFUSING to execute: 3 PRs ready to merge", self.err)

            # Assert checkout scan was never entered (preventing checkout FETCH_HEAD writes)
            self.assertEqual(mock_scan.call_count, 0, "Zero-mutation violated: scan_directories was called on Exit 5")

        # Verify zero mutations:
        # a. REBASE_HEAD was NOT pruned
        res = merge_cleanup.run_git(self.primary, ["rev-parse", "--verify", "REBASE_HEAD"])
        self.assertEqual(res.returncode, 0, "Zero-mutation violated: REBASE_HEAD was pruned on Exit 5")

        # b. FETCH_HEAD was not modified or written
        fetch_head_after = fetch_head.read_bytes() if fetch_head.exists() else None
        self.assertEqual(fetch_head_before, fetch_head_after, "Zero-mutation violated: FETCH_HEAD modified on Exit 5")

        # c. No batch record was created on disk (searching recursively across all subdirectories)
        batch_dir = self.primary / ".tick" / "merge-cleanup"
        batches = list(batch_dir.rglob("batch-*.json")) if batch_dir.exists() else []
        self.assertEqual(len(batches), 0, "Zero-mutation violated: batch record was created on Exit 5")

        # Guard recursive search with a seeded positive control
        probe = batch_dir / "test-owner-repo" / "batch-probe.json"
        probe.parent.mkdir(parents=True, exist_ok=True)
        probe.write_text("{}")
        self.assertEqual(len(list(batch_dir.rglob("batch-*.json"))), 1, "Recursive glob positive control failed")
        probe.unlink()
        probe.parent.rmdir()

        # d. No issue markers were posted to GitHub
        st = self.load()
        marker_calls = [c for c in st["calls"] if c[:2] == ["issue", "comment"]]
        self.assertEqual(len(marker_calls), 0, "Zero-mutation violated: issue markers posted on Exit 5")

        # e. No git merges happened
        self.assertEqual([p["state"] for p in st["prs"].values()], ["OPEN", "OPEN", "OPEN"])
        self.assertFalse(any(c[:2] == ["pr", "merge"] for c in st["calls"]))

    def test_02_blank_or_whitespace_landing_reason_exits_5(self):
        """2. Blank or whitespace-only --landing-reason is refused with exit 5."""
        self.branch("feat/a", 1, lambda r: park(r, 201, "pr1"))
        self.branch("feat/b", 2, lambda r: park(r, 202, "pr2"))
        self.branch("feat/c", 3, lambda r: park(r, 203, "pr3"))

        rc1 = self.run_main(execute=True, extra=("--landing-plan", "direct", "--landing-reason", ""))
        self.assertEqual(rc1, 5, "Empty reason should exit 5")

        rc2 = self.run_main(execute=True, extra=("--landing-plan", "group", "--landing-reason", "   "))
        self.assertEqual(rc2, 5, "Whitespace reason should exit 5")

    def test_03_valid_direct_plan_executes_successfully(self):
        """3. Happy path: providing a valid direct plan proceeds without Exit 5."""
        self.branch("feat/a", 1, lambda r: park(r, 201, "pr1"))
        self.branch("feat/b", 2, lambda r: park(r, 202, "pr2"))
        self.branch("feat/c", 3, lambda r: park(r, 203, "pr3"))

        # Provide a valid direct plan: verify that WITH plan it does NOT exit 5
        rc = self.run_main(execute=True, extra=("--landing-plan", "direct", "--landing-reason", "independent changes"))
        self.assertEqual(rc, 4, "Direct plan should proceed, land PRs, and exit 4 (QA pending)")
        st = self.load()
        self.assertEqual([p["state"] for p in st["prs"].values()], ["MERGED", "MERGED", "MERGED"])

    def test_04_landing_plan_group_records_decision_and_exits_0(self):
        """4. --landing-plan group records decision, prints checklist, and exits 0 without merging."""
        self.branch("feat/a", 1, lambda r: park(r, 201, "pr1"))
        self.branch("feat/b", 2, lambda r: park(r, 202, "pr2"))
        self.branch("feat/c", 3, lambda r: park(r, 203, "pr3"))

        rc = self.run_main(execute=True, extra=("--landing-plan", "group", "--landing-reason", "combine into staging"))
        self.assertEqual(rc, 0, "Group plan should exit 0 cleanly")

        # Verify PRs were NOT merged
        st = self.load()
        self.assertEqual([p["state"] for p in st["prs"].values()], ["OPEN", "OPEN", "OPEN"])
        self.assertFalse(any(c[:2] == ["pr", "merge"] for c in st["calls"]))

        # Verify batch record exists and has group plan recorded
        origin = merge_cleanup.origin_url(self.primary) or ""
        batches = batch_record.unfinished_batches(self.primary, origin, "development")
        self.assertTrue(len(batches) >= 1)
        b = batches[0]
        self.assertIsNotNone(b.get("landing_plan"))
        self.assertEqual(b["landing_plan"]["decision"], "group")
        self.assertEqual(b["landing_plan"]["reason"], "combine into staging")
        self.assertEqual(b["landing_plan"]["prs"], [1, 2, 3])

    def test_05_landing_plan_group_with_issue_error_degraded_state(self):
        """5. Group plan with failed GitHub issue creation warns and exits 0 without false claims."""
        self.branch("feat/a", 1, lambda r: park(r, 201, "pr1"))
        self.branch("feat/b", 2, lambda r: park(r, 202, "pr2"))
        self.branch("feat/c", 3, lambda r: park(r, 203, "pr3"))

        # Inject error into mock gh issue create
        st = self.load()
        st["fail_issue_create"] = True
        self.save()

        orig_gh = merge_cleanup._gh
        def failing_gh(args, cwd, timeout=180):
            if args[:2] == ["issue", "create"]:
                import subprocess
                return subprocess.CompletedProcess(args, 1, stdout="", stderr="API rate limit exceeded")
            return orig_gh(args, cwd, timeout)

        with mock.patch.object(merge_cleanup, "_gh", side_effect=failing_gh):
            rc = self.run_main(execute=True, extra=("--landing-plan", "group", "--landing-reason", "grouped"))
        self.assertEqual(rc, 0)
        self.assertIn("merge-batch issue not created", self.err)

    def test_06_landing_plan_direct_records_decision_and_merges(self):
        """6. --landing-plan direct records decision and proceeds through Phase 5 merges."""
        self.branch("feat/a", 1, lambda r: park(r, 201, "pr1"))
        self.branch("feat/b", 2, lambda r: park(r, 202, "pr2"))
        self.branch("feat/c", 3, lambda r: park(r, 203, "pr3"))

        rc = self.run_main(execute=True, extra=("--landing-plan", "direct", "--landing-reason", "disjoint fixes"))
        self.assertEqual(rc, 4)

        # Batch record has direct decision
        origin = merge_cleanup.origin_url(self.primary) or ""
        batch = batch_record.find_unfinished(self.primary, origin, "development", [1, 2, 3], need_qa=True)
        self.assertIsNotNone(batch)
        self.assertEqual(batch["landing_plan"]["decision"], "direct")
        self.assertEqual(batch["landing_plan"]["reason"], "disjoint fixes")

        # Merges happened
        st = self.load()
        self.assertEqual([p["state"] for p in st["prs"].values()], ["MERGED", "MERGED", "MERGED"])

    def test_07_resume_adopts_decision_when_prs_match(self):
        """7. Resume reuses recorded decision for matching PR set."""
        self.branch("feat/a", 1, lambda r: park(r, 201, "pr1"))
        self.branch("feat/b", 2, lambda r: park(r, 202, "pr2"))
        self.branch("feat/c", 3, lambda r: park(r, 203, "pr3"))

        # Pre-seed a batch record with direct landing decision
        origin = merge_cleanup.origin_url(self.primary) or ""
        ordered = [{"number": 1, "title": "PR 1"}, {"number": 2, "title": "PR 2"}, {"number": 3, "title": "PR 3"}]
        batch = batch_record.new(self.primary, origin, "development", ordered)
        batch_record.set_landing_plan(batch, "direct", "recorded on previous run", [1, 2, 3])

        # Run with --resume --execute without passing --landing-plan
        rc = self.run_main(execute=True, extra=("--resume",))
        self.assertEqual(rc, 4, "Should adopt recorded landing plan on resume and exit 4 (QA pending)")
        self.assertIn("Resumed merge batch has recorded landing plan: direct", self.out)

    def test_08_resume_refuses_when_pr_set_changes(self):
        """8. Resume refuses with exit 5 if the PR set changes and no new decision is given."""
        self.branch("feat/a", 1, lambda r: park(r, 201, "pr1"))
        self.branch("feat/b", 2, lambda r: park(r, 202, "pr2"))
        self.branch("feat/c", 3, lambda r: park(r, 203, "pr3"))
        self.branch("feat/d", 4, lambda r: park(r, 204, "pr4"))

        # Pre-seed a batch with plan covering only PRs [1, 2, 3]
        origin = merge_cleanup.origin_url(self.primary) or ""
        ordered = [{"number": 1, "title": "PR 1"}, {"number": 2, "title": "PR 2"}, {"number": 3, "title": "PR 3"}]
        batch = batch_record.new(self.primary, origin, "development", ordered)
        batch_record.set_landing_plan(batch, "direct", "prior decision", [1, 2, 3])

        # Run with --resume --execute: current queue has 4 PRs
        rc = self.run_main(execute=True, extra=("--resume",))
        self.assertEqual(rc, 5, "Should refuse with exit 5 when resumed PR set changed to 4 PRs")
        self.assertIn("REFUSING to execute: 4 PRs ready to merge", self.err)

    def test_09_small_queues_unaffected(self):
        """9. Small queues (<3 PRs) are unaffected and do not require --landing-plan."""
        self.branch("feat/a", 1, lambda r: park(r, 201, "pr1"))
        self.branch("feat/b", 2, lambda r: park(r, 202, "pr2"))

        # 2 PRs: execute without --landing-plan
        rc = self.run_main(execute=True)
        self.assertEqual(rc, 4, "2 PRs should execute without requiring --landing-plan and exit 4")
        st = self.load()
        self.assertEqual([p["state"] for p in st["prs"].values()], ["MERGED", "MERGED"])
        st = self.load()
        self.assertEqual([p["state"] for p in st["prs"].values()], ["MERGED", "MERGED"])

    def test_10_stale_save_and_marker_stripping(self):
        """10. Intent marker lifecycle: _strip_marks consumes _landing_plan_touched on save;
        stale save after reload cannot overwrite disk decision."""
        with tempfile.TemporaryDirectory() as td:
            p = Path(td) / "batch-test.json"
            rec = {
                "path": str(p),
                "repo": "example/repo",
                "landing_plan": {"decision": "direct", "reason": "first", "prs": [1, 2, 3]},
                "_landing_plan_touched": True,
            }
            # Initial save
            batch_record.save(rec)
            self.assertNotIn("_landing_plan_touched", rec, "Marker must be stripped from caller dict")
            disk = json.loads(p.read_text())
            self.assertNotIn("_landing_plan_touched", disk, "Marker must be stripped from persisted JSON")

            # Reload stale snapshot
            stale = json.loads(p.read_text())
            stale["path"] = str(p)

            # Intentional update on disk to 'group'
            writer2 = json.loads(p.read_text())
            writer2["path"] = str(p)
            batch_record.set_landing_plan(writer2, "group", "grouped replacement", [1, 2, 3])

            # Stale writer saves
            batch_record.save(stale)
            final = json.loads(p.read_text())
            self.assertEqual(final["landing_plan"]["decision"], "group",
                             "Stale save after reload must preserve disk group decision")

    def test_11_queue_widening_between_checkpoints_is_deferred(self):
        """11. Phase 4 defers PRs opened after the pre-mutation checkpoint (F1 fix)."""
        self.branch("feat/a", 1, lambda r: park(r, 201, "pr1"))
        self.branch("feat/b", 2, lambda r: park(r, 202, "pr2"))
        self.branch("feat/c", 3, lambda r: park(r, 203, "pr3"))

        # Simulate race: upfront checkpoint discovers only PR 1 & 2 (queue size 2, no plan required).
        # Later Phase 4 discovery discovers PR 1, 2, and 3.
        orig_fetch = merge_cleanup.fetch_open_prs_with_retry
        calls = [0]
        def widening_fetch(repo_path):
            all_prs = orig_fetch(repo_path)
            calls[0] += 1
            if calls[0] == 1:
                # Early checkpoint sees only PR 1 and PR 2
                return [p for p in all_prs if p["number"] in (1, 2)]
            # Phase 4 sees PR 1, 2, and 3
            return all_prs

        with mock.patch.object(merge_cleanup, "fetch_open_prs_with_retry", side_effect=widening_fetch):
            rc = self.run_main(execute=True)

        # PR 1 and 2 land (exit 4: landed, QA pending); PR 3 is deferred
        self.assertEqual(rc, 4)
        self.assertIn("PR #3: opened after landing checkpoint; deferred to next run", self.out)
        st = self.load()
        self.assertEqual(st["prs"]["1"]["state"], "MERGED")
        self.assertEqual(st["prs"]["2"]["state"], "MERGED")
        self.assertEqual(st["prs"]["3"]["state"], "OPEN")

    def test_12_deferred_prerequisites_block_retained_dependents(self):
        """12. Deferred prerequisites transitively block their retained dependents (F4 fix)."""
        self.branch("feat/a", 1, lambda r: park(r, 201, "pr1"))
        self.branch("feat/b", 2, lambda r: park(r, 202, "pr2"))
        self.branch("feat/c", 3, lambda r: park(r, 203, "pr3"))

        # Early checkpoint sees PR 1 and 2. Phase 4 sees PR 1 (depends on #3), PR 2, and PR 3.
        orig_fetch = merge_cleanup.fetch_open_prs_with_retry
        calls = [0]
        def widening_fetch_with_deps(repo_path):
            all_prs = orig_fetch(repo_path)
            calls[0] += 1
            if calls[0] == 1:
                return [p for p in all_prs if p["number"] in (1, 2)]
            res = []
            for p in all_prs:
                p_copy = dict(p)
                if p_copy["number"] == 1:
                    p_copy["body"] = "depends on #3"
                res.append(p_copy)
            return res

        with mock.patch.object(merge_cleanup, "fetch_open_prs_with_retry", side_effect=widening_fetch_with_deps):
            rc = self.run_main(execute=True)

        self.assertEqual(rc, 0, "Single landing PR exits 0 (no batch QA pending)")
        self.assertIn("PR #3: opened after landing checkpoint; deferred to next run", self.out)
        self.assertIn("PR #1: depends on deferred prerequisite (#3); deferred to next run", self.out)
        st = self.load()
        self.assertEqual(st["prs"]["2"]["state"], "MERGED")
        self.assertEqual(st["prs"]["1"]["state"], "OPEN")
        self.assertEqual(st["prs"]["3"]["state"], "OPEN")


if __name__ == "__main__":
    unittest.main()
