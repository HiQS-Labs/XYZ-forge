import datetime as dt
import json
import os
from pathlib import Path
import sys
import tempfile
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

    def test_recent_completed_issue_needs_no_ledger_row(self):
        gh = [issue(7, "CLOSED", state_reason="COMPLETED",
                    closed_at="2026-09-07T12:00:00Z")]
        plan = board_sync.plan_selection_policy(POLICY, [], [], gh, as_of=AS_OF)
        self.assertEqual(plan["decisions"][0]["status"], "Done")

    def test_invalid_or_future_terminal_date_preserves_existing_card(self):
        board = [{"repo": "owner/repo", "kind": "issue", "number": 1,
                  "item_id": "i1", "status": "Done"}]
        for stamp in ("garbage", "2026-09-14T00:00:00Z"):
            with self.subTest(stamp=stamp):
                gh = [issue(1, "CLOSED", state_reason="COMPLETED", closed_at=stamp)]
                plan = board_sync.plan_selection_policy(POLICY, [], board, gh, as_of=AS_OF)
                self.assertFalse(plan["changes"])
                self.assertEqual(plan["unresolved"][0]["reason"], "unknown closure date")

    def test_non_draft_closing_pr_wins_in_both_input_orders(self):
        open_issue = issue(1)
        review = {"repo": "owner/repo", "kind": "pr", "number": 8, "state": "OPEN",
                  "draft": False, "closing_issues": [{"repo": "owner/repo", "number": 1}]}
        draft = {"repo": "owner/repo", "kind": "pr", "number": 9, "state": "OPEN",
                 "draft": True, "updated_at": "2026-09-13T11:00:00Z",
                 "closing_issues": [{"repo": "owner/repo", "number": 1}]}
        for prs in ((review, draft), (draft, review)):
            with self.subTest(order=[p["number"] for p in prs]):
                plan = board_sync.plan_selection_policy(POLICY, [ledger(1, 90)], [],
                                                         [open_issue, *prs], as_of=AS_OF)
                targets = {tuple(d["identity"]): d["status"] for d in plan["decisions"]}
                self.assertEqual(targets[("owner/repo", "issue", 1)], "In review")

    def test_unknown_pr_state_or_date_is_preserved(self):
        board = [{"repo": "owner/repo", "kind": "pr", "number": 9,
                  "item_id": "p9", "status": "In review"}]
        for row in (
            {"repo": "owner/repo", "kind": "pr", "number": 9, "state": "MYSTERY"},
            {"repo": "owner/repo", "kind": "pr", "number": 9, "state": "CLOSED",
             "closed_at": "garbage", "merged_at": None},
        ):
            with self.subTest(row=row):
                plan = board_sync.plan_selection_policy(POLICY, [], board, [row], as_of=AS_OF)
                self.assertFalse(plan["changes"])
                self.assertTrue(plan["unresolved"])

    def test_reopen_unknown_and_duplicates_preserve(self):
        rows = [ledger(1, 90, section="Completed")]
        board = [{"repo": "owner/repo", "kind": "issue", "number": 1, "item_id": "a", "status": "Done"},
                 {"repo": "owner/repo", "kind": "issue", "number": 1, "item_id": "b", "status": "Done"},
                 {"repo": "foreign/repo", "kind": "issue", "number": 1, "item_id": "x", "status": "Ready"}]
        plan = board_sync.plan_selection_policy(POLICY, rows, board, [issue(1)], as_of=AS_OF)
        self.assertFalse(plan["changes"])
        self.assertTrue(plan["unresolved"])
        self.assertEqual(len(plan["warnings"]), 2)

    def test_open_pr_does_not_override_reopened_or_duplicate_ledger_issue(self):
        pr = {"repo": "owner/repo", "kind": "pr", "number": 9, "state": "OPEN",
              "draft": False, "closing_issues": [{"repo": "owner/repo", "number": 1}]}
        board = [{"repo": "owner/repo", "kind": "issue", "number": 1,
                  "item_id": "i1", "status": "Done"}]
        for rows in ([ledger(1, 90, section="Completed")], [ledger(1, 90), ledger(1, 80)]):
            with self.subTest(rows=len(rows)):
                plan = board_sync.plan_selection_policy(POLICY, rows, board, [issue(1), pr], as_of=AS_OF)
                issue_changes = [c for c in plan["changes"] if c["identity"][-1] == 1]
                self.assertFalse(issue_changes)
                self.assertTrue(any("cannot override" in u["reason"] for u in plan["unresolved"]))

    def test_existing_unset_terminal_card_moves_but_absent_one_is_not_added(self):
        closed = issue(1, "CLOSED", state_reason="COMPLETED", closed_at="2026-09-01T00:00:00Z")
        board = [{"repo": "owner/repo", "kind": "issue", "number": 1,
                  "item_id": "i1", "status": None}]
        present = board_sync.plan_selection_policy(POLICY, [], board, [closed], as_of=AS_OF)
        self.assertEqual(present["changes"][0]["after"], "Backlog")
        absent = board_sync.plan_selection_policy(POLICY, [], [], [closed], as_of=AS_OF)
        self.assertFalse(absent["changes"])

    def test_unrated_ready_card_is_reported_and_preserved(self):
        row = ledger(1, 90)
        row["ratings"] = {"pri": None, "sev": None, "appeal": None, "effort": None, "ovr": None}
        board = [{"repo": "owner/repo", "kind": "issue", "number": 1,
                  "item_id": "i1", "status": "Ready"}]
        plan = board_sync.plan_selection_policy(POLICY, [row], board, [issue(1)], as_of=AS_OF)
        self.assertFalse(plan["changes"])
        self.assertIn("unrated Ready", plan["unresolved"][0]["reason"])

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

    def test_add_success_status_failure_preserves_added_item_id(self):
        cfg = {"project_owner": "owner", "project_number": 4,
               "repos": ["owner/repo"], "status_field": "Status"}
        ids = {"project": "p", "status_field": "f", "options": {"Ready": "ready"}}
        calls, added = [], []
        with mock.patch.object(board_sync, "content_node", return_value={"id": "content"}), \
             mock.patch.object(board_sync, "resolve_ids", return_value=ids), \
             mock.patch.object(board_sync, "_gql", side_effect=[
                 {"addProjectV2ItemById": {"item": {"id": "new-item"}}},
                 RuntimeError("status response lost")]):
            with self.assertRaises(board_sync.IndeterminateMutation):
                board_sync.set_issue_status(
                    cfg, 1, "Ready", snapshot={}, audit=calls.append,
                    policy_mode=True, repo="owner/repo", on_added=added.append)
        self.assertEqual(added, ["new-item"])
        self.assertEqual([x["phase"] for x in calls],
                         ["intent", "result", "intent", "result"])
        self.assertEqual(calls[-1]["outcome"], "indeterminate")

    def test_clear_uses_existing_writer_seam(self):
        calls = []
        with mock.patch.object(board_sync, "_gql", return_value={"clearProjectV2ItemFieldValue": {"projectV2Item": {"id": "i"}}}):
            board_sync._clear_status({}, {"project": "p", "status_field": "f"}, "i", audit=calls.append)
        self.assertEqual(calls[0]["operation"], "clearProjectV2ItemFieldValue")

    def test_intent_audit_failure_prevents_remote_request(self):
        invoke = mock.Mock()
        with self.assertRaisesRegex(OSError, "audit unavailable"):
            board_sync._remote_request(
                "op", {}, invoke, audit=mock.Mock(side_effect=OSError("audit unavailable")))
        invoke.assert_not_called()

    def test_result_audit_failure_is_indeterminate_after_one_request(self):
        phases = []
        def audit(entry):
            phases.append(entry["phase"])
            if entry["phase"] == "result":
                raise OSError("audit unavailable")
        invoke = mock.Mock(return_value={"ok": True})
        with self.assertRaises(board_sync.IndeterminateMutation):
            board_sync._remote_request("op", {}, invoke, audit=audit)
        invoke.assert_called_once_with()
        self.assertEqual(phases, ["intent", "result"])

    def test_policy_managed_board_refuses_raw_replay_before_network(self):
        cfg = {"project_owner": "owner", "project_number": 4, "repos": ["owner/repo"],
               "status_field": "Status", "status_map": {}}
        with mock.patch.object(board_sync, "resolve_selection_policy", return_value=POLICY), \
             mock.patch.object(board_sync, "fetch_board_issues") as fetch:
            with self.assertRaisesRegex(RuntimeError, "policy-managed"):
                github_board.run({"config": cfg, "events": [{"id": 1}]})
        fetch.assert_not_called()

    def test_policy_guard_is_board_scoped_not_repo_intersection_scoped(self):
        cfg = {"project_owner": "owner", "project_number": 4, "repos": ["owner/other"],
               "status_field": "Status", "status_map": {}}
        with mock.patch.object(board_sync, "resolve_selection_policy", return_value=POLICY), \
             mock.patch.object(board_sync, "fetch_board_issues") as fetch:
            with self.assertRaisesRegex(RuntimeError, "policy-managed"):
                github_board.run({"config": cfg, "events": [{"id": 1}]})
        fetch.assert_not_called()

    def test_connector_routes_event_by_recorded_repository_identity(self):
        cfg = {"repos": ["owner/repo", "owner/other"]}
        event = {"id": 1, "repo": "owner/other", "gh_number": 7, "event": "in_flight"}
        with mock.patch.object(board_sync, "set_issue_status", return_value="ok") as write:
            applied, _ = github_board.apply_event(cfg, event, github_board.DEFAULT_STATUS_MAP, {})
        self.assertTrue(applied)
        self.assertEqual(write.call_args.kwargs["repo"], "owner/other")
        with self.assertRaisesRegex(RuntimeError, "unknown repository"):
            github_board.apply_event(cfg, dict(event, repo="foreign/repo"),
                                     github_board.DEFAULT_STATUS_MAP, {})

    def test_preview_future_timestamp_is_invalid(self):
        preview = {"created_at": "2999-01-01T00:00:00Z", "as_of": "2999-01-01T00:00:00Z"}
        self.assertFalse(board_sync._preview_age_ok(preview))

    def test_unmatched_intent_is_detected_by_request_id(self):
        operations = [
            {"phase": "intent", "request_id": "a"},
            {"phase": "intent", "request_id": "b"},
            {"phase": "result", "request_id": "a"},
        ]
        self.assertEqual([x["request_id"] for x in board_sync._unmatched_intents(operations)], ["b"])

    def test_explicit_indeterminate_result_remains_unresolved(self):
        operations = [
            {"phase": "intent", "request_id": "a"},
            {"phase": "result", "request_id": "a", "outcome": "indeterminate"},
        ]
        self.assertEqual(board_sync._unmatched_intents(operations)[0]["outcome"], "indeterminate")

    def test_resolver_uses_repository_owner_union_and_valid_balanced_query(self):
        cfg = {"project_owner": "owner", "project_number": 4, "status_field": "Status",
               "in_progress": "In progress", "repos": ["owner/repo"]}
        project = {"id": "p", "field": {"id": "f", "options": [
            {"id": "ip", "name": "In progress"}, {"id": "r", "name": "Ready"}]}}
        for owner_kind in ("User", "Organization"):
            seen = []
            def gql(query, variables):
                seen.append(query)
                return {"repositoryOwner": {"__typename": owner_kind, "projectV2": project}}
            with mock.patch.object(board_sync, "_gql", side_effect=gql):
                ids = board_sync.resolve_ids(cfg, force=True, cache=False)
            self.assertEqual(ids["project"], "p")
            self.assertIn("repositoryOwner", seen[0])
            self.assertIn("... on User", seen[0])
            self.assertIn("... on Organization", seen[0])
            self.assertEqual(seen[0].count("{"), seen[0].count("}"))
        with mock.patch.object(board_sync, "_gql", return_value={"repositoryOwner": None}):
            with self.assertRaisesRegex(RuntimeError, "repository owner"):
                board_sync.resolve_ids(cfg, force=True, cache=False)

    def test_project_snapshot_query_is_balanced(self):
        seen = []
        def gql(query, variables):
            seen.append(query)
            return {"node": {"items": {"nodes": [],
                    "pageInfo": {"hasNextPage": False, "endCursor": None}}}}
        with mock.patch.object(board_sync, "resolve_ids", return_value={"project": "p"}), \
             mock.patch.object(board_sync, "_gql", side_effect=gql):
            self.assertEqual(board_sync.fetch_board_items({"status_field": "Status"}, cache=False), [])
        self.assertEqual(seen[0].count("{"), seen[0].count("}"))

    def test_shared_writer_validates_destination_before_add(self):
        cfg = {"project_owner": "owner", "project_number": 4,
               "repos": ["owner/repo"], "status_field": "Status"}
        with mock.patch.object(board_sync, "option_id_for", side_effect=RuntimeError("missing")), \
             mock.patch.object(board_sync, "content_node") as content, \
             mock.patch.object(board_sync, "_add_item") as add:
            with self.assertRaisesRegex(RuntimeError, "missing"):
                board_sync.set_issue_status(cfg, 1, "Missing", snapshot={},
                                            policy_mode=True, repo="owner/repo")
        content.assert_not_called()
        add.assert_not_called()

    def test_durable_json_replace_and_existing_apply_result_refusal(self):
        with tempfile.TemporaryDirectory(prefix="gh605-audit-") as tmp:
            path = Path(tmp) / "audit.json"
            board_sync._write_json(path, {"nonempty": True})
            self.assertEqual(json.loads(path.read_text()), {"nonempty": True})
            preview = Path(tmp) / "preview.json"
            preview.write_text(json.dumps({"schema": "github-board-policy-preview@1",
                                           "created_at": AS_OF, "as_of": AS_OF}))
            with self.assertRaisesRegex(RuntimeError, "already exists"):
                with mock.patch.object(board_sync, "_preview_age_ok", return_value=True):
                    board_sync.apply_policy_preview(tmp, preview, path)

    def test_apply_releases_lock_when_fresh_preflight_fails(self):
        class FakeLock:
            released = False
            def __init__(self, _path): pass
            def acquire(self): return True
            def release(self): self.released = True

        with tempfile.TemporaryDirectory(prefix="gh605-lock-") as tmp:
            preview_path = Path(tmp) / "preview.json"
            result_path = Path(tmp) / "result.json"
            preview_path.write_text(json.dumps({
                "schema": "github-board-policy-preview@1", "created_at": AS_OF,
                "as_of": AS_OF, "policy": POLICY, "warnings": [], "changes": []}))
            lock = FakeLock(None)
            with mock.patch.object(board_sync, "_preview_age_ok", return_value=True), \
                 mock.patch.object(board_sync, "resolve_selection_policy", return_value=POLICY), \
                 mock.patch("work_connectors._ConnectorLock", return_value=lock), \
                 mock.patch.object(board_sync, "build_policy_preview", side_effect=RuntimeError("fresh fail")):
                with self.assertRaisesRegex(RuntimeError, "fresh fail"):
                    board_sync.apply_policy_preview(tmp, preview_path, result_path)
            self.assertTrue(lock.released)
            self.assertFalse(result_path.exists())

    def test_apply_refuses_same_status_with_replaced_item_id_before_mutation(self):
        class FakeLock:
            def __init__(self, _path): pass
            def acquire(self): return True
            def release(self): pass

        change = {"identity": ["owner/repo", "issue", 1], "item_id": "old-item",
                  "before": "Ready", "after": "In progress", "reason": "test"}
        preview = {"schema": "github-board-policy-preview@1", "created_at": AS_OF,
                   "as_of": AS_OF, "policy": POLICY, "ledger_generation": 1,
                   "source_digest": "digest", "decisions": [], "changes": [change],
                   "warnings": [], "unresolved": [], "observations": []}
        fresh = dict(preview)
        fresh.pop("schema"); fresh.pop("created_at"); fresh.pop("policy")
        with tempfile.TemporaryDirectory(prefix="gh605-cas-") as tmp:
            preview_path = Path(tmp) / "preview.json"
            result_path = Path(tmp) / "result.json"
            preview_path.write_text(json.dumps(preview))
            replacement = [{"repo": "owner/repo", "kind": "issue", "number": 1,
                            "item_id": "replacement", "status": "Ready"}]
            with mock.patch.object(board_sync, "_preview_age_ok", return_value=True), \
                 mock.patch.object(board_sync, "resolve_selection_policy", return_value=POLICY), \
                 mock.patch("work_connectors._ConnectorLock", FakeLock), \
                 mock.patch.object(board_sync, "build_policy_preview", return_value=fresh), \
                 mock.patch.object(board_sync, "_policy_board_cfg", return_value={}), \
                 mock.patch.object(board_sync, "option_id_for", return_value=({}, "opt")), \
                 mock.patch.object(board_sync, "fetch_board_items", return_value=replacement), \
                 mock.patch.object(board_sync, "set_issue_status") as mutate:
                with self.assertRaisesRegex(RuntimeError, "board item changed"):
                    board_sync.apply_policy_preview(tmp, preview_path, result_path)
            mutate.assert_not_called()

    def test_apply_missing_destination_option_makes_zero_mutations(self):
        class FakeLock:
            def __init__(self, _path): pass
            def acquire(self): return True
            def release(self): pass

        change = {"identity": ["owner/repo", "issue", 1], "item_id": "i1",
                  "before": "Ready", "after": "Missing", "reason": "test"}
        preview = {"schema": "github-board-policy-preview@1", "created_at": AS_OF,
                   "as_of": AS_OF, "policy": POLICY, "ledger_generation": 1,
                   "source_digest": "digest", "decisions": [], "changes": [change],
                   "warnings": [], "unresolved": [], "observations": []}
        fresh = {k: v for k, v in preview.items() if k not in ("schema", "created_at", "policy")}
        with tempfile.TemporaryDirectory(prefix="gh605-option-") as tmp:
            preview_path = Path(tmp) / "preview.json"
            result_path = Path(tmp) / "result.json"
            preview_path.write_text(json.dumps(preview))
            with mock.patch.object(board_sync, "_preview_age_ok", return_value=True), \
                 mock.patch.object(board_sync, "resolve_selection_policy", return_value=POLICY), \
                 mock.patch("work_connectors._ConnectorLock", FakeLock), \
                 mock.patch.object(board_sync, "build_policy_preview", return_value=fresh), \
                 mock.patch.object(board_sync, "_policy_board_cfg", return_value={}), \
                 mock.patch.object(board_sync, "option_id_for", side_effect=RuntimeError("missing option")), \
                 mock.patch.object(board_sync, "set_issue_status") as mutate:
                with self.assertRaisesRegex(RuntimeError, "missing option"):
                    board_sync.apply_policy_preview(tmp, preview_path, result_path)
            mutate.assert_not_called()
            self.assertFalse(result_path.exists())

    def test_restore_reports_partial_added_card_and_unmatched_intent(self):
        with tempfile.TemporaryDirectory(prefix="gh605-restore-") as tmp:
            result_path = Path(tmp) / "result.json"
            result_path.write_text(json.dumps({
                "schema": "github-board-policy-result@1", "policy": POLICY,
                "root": tmp, "operations": [
                    {"phase": "change", "identity": ["owner/repo", "issue", 1],
                     "before": None, "after": "Ready", "item_id": "new-1",
                     "added": True, "outcome": "pending"},
                    {"phase": "intent", "request_id": "lost", "operation": "update"},
                ]}))
            board = [{"repo": "owner/repo", "kind": "issue", "number": 1,
                      "item_id": "new-1", "status": None}]
            with mock.patch.object(board_sync, "resolve_selection_policy", return_value=POLICY), \
                 mock.patch.object(board_sync, "fetch_board_items", return_value=board):
                report = board_sync.restore_policy_result(result_path)
            self.assertEqual(report["status"], "indeterminate")
            self.assertEqual(report["residual_added"][0]["item_id"], "new-1")
            self.assertFalse(report["changes"])

    def test_restore_unset_status_clears_with_durable_request_audit(self):
        class FakeLock:
            def __init__(self, _path): pass
            def acquire(self): return True
            def release(self): pass

        with tempfile.TemporaryDirectory(prefix="gh605-clear-") as tmp:
            result_path = Path(tmp) / "result.json"
            report_path = Path(tmp) / "restore.json"
            result_path.write_text(json.dumps({
                "schema": "github-board-policy-result@1", "policy": POLICY, "root": tmp,
                "operations": [{"phase": "change",
                    "identity": ["owner/repo", "issue", 1], "before": None,
                    "after": "In progress", "item_id": "item-1", "added": False,
                    "outcome": "success"}]}))
            board = [{"repo": "owner/repo", "kind": "issue", "number": 1,
                      "item_id": "item-1", "status": "In progress"}]
            response = {"clearProjectV2ItemFieldValue": {"projectV2Item": {"id": "item-1"}}}
            with mock.patch.object(board_sync, "resolve_selection_policy", return_value=POLICY), \
                 mock.patch.object(board_sync, "_policy_board_cfg", return_value={}), \
                 mock.patch.object(board_sync, "fetch_board_items", return_value=board), \
                 mock.patch("work_connectors._ConnectorLock", FakeLock), \
                 mock.patch.object(board_sync, "resolve_ids",
                                   return_value={"project": "p", "status_field": "f"}), \
                 mock.patch.object(board_sync, "_gql", return_value=response) as gql:
                report = board_sync.restore_policy_result(
                    result_path, write=True, report_path=report_path)
            self.assertEqual(report["status"], "complete")
            self.assertIn("clearProjectV2ItemFieldValue", gql.call_args.args[0])
            persisted = json.loads(report_path.read_text())
            self.assertEqual([x["phase"] for x in persisted["operations"]],
                             ["restore", "intent", "result"])

    def test_restore_preserves_concurrently_changed_status(self):
        with tempfile.TemporaryDirectory(prefix="gh605-restore-drift-") as tmp:
            result_path = Path(tmp) / "result.json"
            result_path.write_text(json.dumps({
                "schema": "github-board-policy-result@1", "policy": POLICY, "root": tmp,
                "operations": [{"phase": "change",
                    "identity": ["owner/repo", "issue", 1], "before": "Ready",
                    "after": "In progress", "item_id": "item-1", "added": False,
                    "outcome": "success"}]}))
            board = [{"repo": "owner/repo", "kind": "issue", "number": 1,
                      "item_id": "item-1", "status": "Operator changed"}]
            with mock.patch.object(board_sync, "resolve_selection_policy", return_value=POLICY), \
                 mock.patch.object(board_sync, "fetch_board_items", return_value=board):
                report = board_sync.restore_policy_result(result_path)
            self.assertEqual(report["status"], "partial")
            self.assertFalse(report["changes"])
            self.assertIn("preserved", report["warnings"][0])

    def test_fetch_board_items_refuses_missing_cursor_and_preserves_opaque(self):
        ids = {"project": "p", "status_field": "f"}
        malformed = {"node": {"items": {"nodes": [],
                                           "pageInfo": {"hasNextPage": True, "endCursor": None}}}}
        with mock.patch.object(board_sync, "resolve_ids", return_value=ids), \
             mock.patch.object(board_sync, "_gql", return_value=malformed):
            with self.assertRaisesRegex(RuntimeError, "fresh cursor"):
                board_sync.fetch_board_items({"status_field": "Status"}, cache=False)
        opaque = {"node": {"items": {"nodes": [{"id": "opaque", "content": None,
                                                     "fieldValueByName": {"name": "Ready"}}],
                                        "pageInfo": {"hasNextPage": False, "endCursor": None}}}}
        with mock.patch.object(board_sync, "resolve_ids", return_value=ids), \
             mock.patch.object(board_sync, "_gql", return_value=opaque):
            items = board_sync.fetch_board_items({"status_field": "Status"}, cache=False)
        self.assertEqual(items[0]["kind"], "opaque")
        self.assertEqual(items[0]["item_id"], "opaque")


if __name__ == "__main__":
    unittest.main()
