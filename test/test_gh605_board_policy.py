import datetime as dt
import json
import os
from pathlib import Path
import sys
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "utils" / "py"))
import board_sync
from work_connectors import github_board


POLICY = {
    "project_owner": "owner", "project_number": 4, "repos": ["owner/repo"],
    "ready_top_n": 2, "done_lookback_days": 7, "activity_lookback_days": 3,
    "status_field": "Status", "ready": "Ready", "in_progress": "In progress",
    "in_review": "In review", "done": "Done", "backlog": "Backlog",
}
AS_OF = "2026-09-13T12:00:00Z"


def ledger(number, score, **extra):
    row = {"repo": "owner/repo", "kind": "issue", "number": number,
           "global_id": "rmi-%02d" % number, "section": "Queue / parked intake",
           "marker": "", "activity": "unknown", "recent_start": None,
           "ratings": {"pri": score, "sev": 1, "appeal": 1, "effort": 1, "ovr": None}}
    row.update(extra)
    return row


def issue(number, state="OPEN", **extra):
    row = {"repo": "owner/repo", "kind": "issue", "number": number, "state": state}
    row.update(extra)
    return row


class PlannerTests(unittest.TestCase):
    def test_pending_singular_repo_policy_is_consumable(self):
        import tempfile
        with tempfile.TemporaryDirectory(prefix="gh605-policy-") as tmp:
            path = Path(tmp) / "device.json"
            path.write_text(json.dumps({"github_board_selection_policy": {
                "project_owner": "owner", "project_number": 4, "repo": "owner/repo",
                "ready_top_n": 10, "done_lookback_days": 7,
                "implementation_status": "pending"}}))
            with mock.patch.dict(os.environ, {"XYZ_DEVICE_CONFIG_PATH": str(path)}, clear=False):
                policy = board_sync.resolve_selection_policy(required=True)
        self.assertEqual(policy["repos"], ["owner/repo"])
        self.assertEqual(policy["implementation_status"], "pending")

    def test_exact_top_n_and_excess_demotion(self):
        rows = [ledger(3, 90), ledger(1, 90), ledger(2, 80)]
        gh = [issue(1), issue(2), issue(3)]
        board = [{"repo": "owner/repo", "kind": "issue", "number": 2,
                  "item_id": "i2", "status": "Ready"}]
        plan = board_sync.plan_selection_policy(POLICY, rows, board, gh, as_of=AS_OF)
        self.assertEqual(plan["ready_selected"], [["owner/repo", "issue", 1],
                                                   ["owner/repo", "issue", 3]])
        change = next(c for c in plan["changes"] if c["identity"][-1] == 2)
        self.assertEqual(change["after"], "Backlog")

    def test_recent_terminal_and_open_pr_precedence(self):
        rows = [ledger(1, 90), ledger(2, 80)]
        gh = [issue(1, "CLOSED", state_reason="COMPLETED", closed_at="2026-09-07T12:00:00Z"),
              issue(2),
              {"repo": "owner/repo", "kind": "pr", "number": 9, "state": "OPEN",
               "draft": False, "closing_issues": [{"repo": "owner/repo", "number": 2}]}]
        plan = board_sync.plan_selection_policy(POLICY, rows, [], gh, as_of=AS_OF)
        targets = {tuple(d["identity"]): d["status"] for d in plan["decisions"]}
        self.assertEqual(targets[("owner/repo", "issue", 1)], "Done")
        self.assertEqual(targets[("owner/repo", "pr", 9)], "In review")
        self.assertEqual(targets[("owner/repo", "issue", 2)], "In review")

    def test_reopen_unknown_and_duplicates_preserve(self):
        rows = [ledger(1, 90, section="Completed")]
        board = [{"repo": "owner/repo", "kind": "issue", "number": 1, "item_id": "a", "status": "Done"},
                 {"repo": "owner/repo", "kind": "issue", "number": 1, "item_id": "b", "status": "Done"},
                 {"repo": "foreign/repo", "kind": "issue", "number": 1, "item_id": "x", "status": "Ready"}]
        plan = board_sync.plan_selection_policy(POLICY, rows, board, [issue(1)], as_of=AS_OF)
        self.assertFalse(plan["changes"])
        self.assertTrue(plan["unresolved"])
        self.assertEqual(len(plan["warnings"]), 2)

    def test_start_to_park_does_not_manufacture_progress(self):
        rows = [ledger(1, 90, recent_start=None, activity="unknown")]
        plan = board_sync.plan_selection_policy(POLICY, rows, [], [issue(1)], as_of=AS_OF)
        self.assertEqual(plan["decisions"][0]["status"], "Ready")

    def test_invalid_ledger_identity_is_preserved_unresolved(self):
        rows = [ledger(1, 90, identity_valid=False)]
        board = [{"repo": "owner/repo", "kind": "issue", "number": 1,
                  "item_id": "a", "status": "Ready"}]
        plan = board_sync.plan_selection_policy(POLICY, rows, board, [issue(1)], as_of=AS_OF)
        self.assertFalse(plan["changes"])
        self.assertTrue(plan["unresolved"])


class WriterAuditTests(unittest.TestCase):
    def test_add_audits_intent_before_result(self):
        calls = []
        with mock.patch.object(board_sync, "_gql", return_value={"addProjectV2ItemById": {"item": {"id": "new"}}}):
            value = board_sync._add_item({}, {"project": "p"}, "content", audit=calls.append)
        self.assertEqual(value, "new")
        self.assertEqual([x["phase"] for x in calls], ["intent", "result"])

    def test_lost_response_is_indeterminate_and_not_retried(self):
        calls = []
        with mock.patch.object(board_sync, "_gql", side_effect=RuntimeError("lost")) as gql:
            with self.assertRaises(board_sync.IndeterminateMutation):
                board_sync._add_item({}, {"project": "p"}, "content", audit=calls.append)
        self.assertEqual(gql.call_count, 1)
        self.assertEqual(calls[-1]["outcome"], "indeterminate")

    def test_clear_uses_existing_writer_seam(self):
        calls = []
        with mock.patch.object(board_sync, "_gql", return_value={"clearProjectV2ItemFieldValue": {"projectV2Item": {"id": "i"}}}):
            board_sync._clear_status({}, {"project": "p", "status_field": "f"}, "i", audit=calls.append)
        self.assertEqual(calls[0]["operation"], "clearProjectV2ItemFieldValue")

    def test_policy_managed_board_refuses_raw_replay_before_network(self):
        cfg = {"project_owner": "owner", "project_number": 4, "repos": ["owner/repo"],
               "status_field": "Status", "status_map": {}}
        with mock.patch.object(board_sync, "resolve_selection_policy", return_value=POLICY), \
             mock.patch.object(board_sync, "fetch_board_issues") as fetch:
            with self.assertRaisesRegex(RuntimeError, "policy-managed"):
                github_board.run({"config": cfg, "events": [{"id": 1}]})
        fetch.assert_not_called()


if __name__ == "__main__":
    unittest.main()
