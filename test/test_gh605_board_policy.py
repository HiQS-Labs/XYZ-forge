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
import mock_gh_board
import releases_app
import work_connectors
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

    def test_closing_pr_can_place_an_open_issue_without_a_ledger_row(self):
        open_issue = issue(1)
        for draft, expected in ((False, "In review"), (True, "In progress")):
            with self.subTest(draft=draft):
                pr = {"repo": "owner/repo", "kind": "pr", "number": 9,
                      "state": "OPEN", "draft": draft,
                      "updated_at": "2026-09-13T11:00:00Z",
                      "closing_issues": [{"repo": "owner/repo", "number": 1}]}
                plan = board_sync.plan_selection_policy(POLICY, [], [], [open_issue, pr], as_of=AS_OF)
                targets = {tuple(d["identity"]): d["status"] for d in plan["decisions"]}
                self.assertEqual(targets[("owner/repo", "issue", 1)], expected)
                self.assertFalse([u for u in plan["unresolved"]
                                  if tuple(u["identity"]) == ("owner/repo", "issue", 1)])

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
        for rows in ([ledger(1, 90, section="Completed")],
                     [ledger(1, 90), ledger(1, 80)],
                     [ledger(1, 90, identity_valid=False)]):
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
        self.assertEqual(present["changes"][0]["after"], "Done")
        self.assertEqual(present["decisions"][0]["reason"], "completed issue retained in Done")
        absent = board_sync.plan_selection_policy(POLICY, [], [], [closed], as_of=AS_OF)
        self.assertFalse(absent["changes"])

    def test_completed_issue_and_merged_pr_older_than_lookback_retained_in_done(self):
        closed = issue(1, "CLOSED", state_reason="COMPLETED", closed_at="2026-09-01T00:00:00Z")
        merged_pr = {"repo": "owner/repo", "kind": "pr", "number": 2, "state": "MERGED",
                     "merged_at": "2026-09-01T00:00:00Z"}
        not_planned = issue(3, "CLOSED", state_reason="NOT_PLANNED", closed_at="2026-09-01T00:00:00Z")
        board = [
            {"repo": "owner/repo", "kind": "issue", "number": 1, "item_id": "i1", "status": "Backlog"},
            {"repo": "owner/repo", "kind": "pr", "number": 2, "item_id": "i2", "status": "Backlog"},
            {"repo": "owner/repo", "kind": "issue", "number": 3, "item_id": "i3", "status": "Ready"},
        ]
        plan = board_sync.plan_selection_policy(POLICY, [], board, [closed, merged_pr, not_planned], as_of=AS_OF)
        changes = {c["identity"][-1]: c["after"] for c in plan["changes"]}
        self.assertEqual(changes[1], "Done")
        self.assertEqual(changes[2], "Done")
        self.assertEqual(changes[3], "Backlog")

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

    def test_valid_plus_invalid_ledger_identity_never_falls_through(self):
        valid = ledger(1, 90)
        invalid = ledger(1, 80, global_id="rmi-invalid", identity_valid=False)
        board = [{"repo": "owner/repo", "kind": "issue", "number": 1,
                  "item_id": "i1", "status": "Backlog"}]
        pr = {"repo": "owner/repo", "kind": "pr", "number": 9, "state": "OPEN",
              "draft": False, "closing_issues": [{"repo": "owner/repo", "number": 1}]}
        for github in ([issue(1)], [issue(1), pr]):
            with self.subTest(linked_pr=len(github) == 2):
                plan = board_sync.plan_selection_policy(
                    POLICY, [valid, invalid], board, github, as_of=AS_OF)
                issue_changes = [c for c in plan["changes"] if c["identity"][-1] == 1]
                self.assertFalse(issue_changes)
                self.assertTrue(any("identity" in u["reason"]
                                    for u in plan["unresolved"] if u["identity"][-1] == 1))

    def test_closed_issue_with_ambiguous_ledger_identity_is_preserved(self):
        board = [{"repo": "owner/repo", "kind": "issue", "number": 1,
                  "item_id": "i1", "status": "Ready"}]
        terminal = (
            issue(1, "CLOSED", state_reason="COMPLETED", closed_at="2026-09-12T12:00:00Z"),
            issue(1, "CLOSED", state_reason="COMPLETED", closed_at="2026-09-01T12:00:00Z"),
            issue(1, "CLOSED", state_reason="NOT_PLANNED", closed_at="2026-09-12T12:00:00Z"),
        )
        ambiguous_rows = (
            [ledger(1, 90), ledger(1, 80, global_id="rmi-duplicate")],
            [ledger(1, 90), ledger(1, 80, global_id="rmi-invalid", identity_valid=False)],
        )
        for closed in terminal:
            for rows in ambiguous_rows:
                with self.subTest(reason=closed["state_reason"], rows=len(rows)):
                    plan = board_sync.plan_selection_policy(
                        POLICY, rows, board, [closed], as_of=AS_OF)
                    self.assertFalse(plan["changes"])
                    self.assertTrue(any("identity" in u["reason"]
                                        for u in plan["unresolved"]))


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

    def test_malformed_add_set_and_clear_responses_are_indeterminate(self):
        cases = [
            (lambda audit: board_sync._add_item(
                {}, {"project": "p"}, "content", audit=audit), None),
            (lambda audit: board_sync._set_status_option(
                {}, {"project": "p", "status_field": "f"}, "item-1", "o", audit=audit),
             {"updateProjectV2ItemFieldValue": {"projectV2Item": {"id": "wrong"}}}),
            (lambda audit: board_sync._clear_status(
                {}, {"project": "p", "status_field": "f"}, "item-1", audit=audit),
             {"clearProjectV2ItemFieldValue": {"projectV2Item": None}}),
        ]
        for invoke, response in cases:
            with self.subTest(response=response):
                calls = []
                with mock.patch.object(board_sync, "_gql", return_value=response) as gql:
                    with self.assertRaises(board_sync.IndeterminateMutation):
                        invoke(calls.append)
                self.assertEqual(gql.call_count, 1)
                self.assertEqual([entry["phase"] for entry in calls], ["intent", "result"])
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

    def test_legacy_connector_batch_keeps_single_repo_replay_contract(self):
        conn = __import__("sqlite3").connect(":memory:")
        conn.executescript("""
          CREATE TABLE repos(id INTEGER PRIMARY KEY, slug TEXT);
          CREATE TABLE work_events(id INTEGER PRIMARY KEY, repo_id INTEGER, gh_number INTEGER,
                                   event TEXT, payload TEXT, at TEXT);
          INSERT INTO repos VALUES(1, 'recorded/owner');
          INSERT INTO work_events VALUES(1, 1, 7, 'in_flight', NULL, '2026-09-13T00:00:00Z');
        """)
        events = work_connectors.events_after(conn, 0)
        conn.close()
        self.assertNotIn("repo", events[0])

        cfg = {"repos": ["owner/repo"]}
        with mock.patch.object(board_sync, "set_issue_status", return_value="ok") as write:
            applied, _ = github_board.apply_event(cfg, events[0], github_board.DEFAULT_STATUS_MAP, {})
        self.assertTrue(applied)
        self.assertEqual(write.call_args.kwargs["repo"], "owner/repo")

    def test_preview_future_timestamp_is_invalid(self):
        preview = {"created_at": "2999-01-01T00:00:00Z", "as_of": "2999-01-01T00:00:00Z"}
        self.assertFalse(board_sync._preview_age_ok(preview))

    def test_preview_creation_and_evidence_clocks_share_one_fresh_window(self):
        now = dt.datetime.now(dt.timezone.utc)
        stamp = lambda value: value.isoformat().replace("+00:00", "Z")
        self.assertTrue(board_sync._preview_age_ok({
            "created_at": stamp(now - dt.timedelta(minutes=1)),
            "as_of": stamp(now - dt.timedelta(minutes=2)),
        }))
        for preview in (
            {"created_at": stamp(now), "as_of": stamp(now - dt.timedelta(minutes=16))},
            {"created_at": stamp(now - dt.timedelta(minutes=2)), "as_of": stamp(now - dt.timedelta(minutes=1))},
            {"created_at": stamp(now + dt.timedelta(minutes=1)), "as_of": stamp(now)},
        ):
            with self.subTest(preview=preview):
                self.assertFalse(board_sync._preview_age_ok(preview))

    def test_mock_add_preserves_pr_kind_and_refuses_unknown_content(self):
        with tempfile.TemporaryDirectory(prefix="gh605-mock-pr-") as tmp:
            state_path = Path(tmp) / "state.json"
            state = mock_gh_board.get_default_state()
            state["pull_requests"] = {"owner/repo": {
                "9": {"id": "pr-content-9", "state": "OPEN"}}}
            mock_gh_board.save_state(state, state_path)
            query = "mutation { addProjectV2ItemById(input: {}) { item { id } } }"
            response = mock_gh_board.handle_graphql(
                query, {"p": state["project_id"], "c": "pr-content-9"}, state, state_path)
            self.assertNotIn("errors", response)
            self.assertEqual(state["items"][0]["kind"], "pr")
            self.assertEqual(state["items"][0]["repository"], "owner/repo")
            self.assertEqual(state["items"][0]["number"], 9)
            count = len(state["items"])
            response = mock_gh_board.handle_graphql(
                query, {"p": state["project_id"], "c": "unknown"}, state, state_path)
            self.assertIn("errors", response)
            self.assertEqual(len(state["items"]), count)

    def test_mock_seed_reserves_item_id_before_add_and_set(self):
        with tempfile.TemporaryDirectory(prefix="gh605-mock-seed-") as tmp:
            state_path = Path(tmp) / "state.json"
            with mock.patch("sys.stdout", new_callable=__import__("io").StringIO):
                self.assertEqual(mock_gh_board.main(["--seed", "--state", str(state_path)]), 0)
            state = mock_gh_board.load_state(state_path)
            add = mock_gh_board.handle_graphql(
                "mutation { addProjectV2ItemById(input: {}) { item { id } } }",
                {"p": state["project_id"], "c": "ISS_mock_HiQS-Labs_XYZ-forge_124"},
                state, state_path)
            added_id = add["data"]["addProjectV2ItemById"]["item"]["id"]
            mock_gh_board.handle_graphql(
                "mutation { updateProjectV2ItemFieldValue(input: {}) { projectV2Item { id } } }",
                {"p": state["project_id"], "i": added_id, "f": "PVTF_status_001",
                 "o": "OPT_done_001"}, state, state_path)
            snapshot = mock_gh_board.handle_graphql(
                "query { node(id: $id) { ... on ProjectV2 { items(first: 100) { "
                "nodes { id fieldValueByName(name: $f) { ... on ProjectV2ItemFieldSingleSelectValue "
                "{ name } } } } } } }",
                {"id": state["project_id"], "f": "Status"}, state, state_path)
            items = snapshot["data"]["node"]["items"]["nodes"]
            by_number = {item["content"]["number"]: item for item in items}
            self.assertNotEqual(by_number[123]["id"], by_number[124]["id"])
            self.assertEqual(by_number[123]["fieldValueByName"]["name"], "In progress")
            self.assertEqual(by_number[124]["fieldValueByName"]["name"], "Done")

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

    def test_restore_exception_preserves_preexisting_unmatched_intent(self):
        class FakeLock:
            def __init__(self, _path): pass
            def acquire(self): return True
            def release(self): pass

        with tempfile.TemporaryDirectory(prefix="gh605-restore-error-") as tmp:
            result_path = Path(tmp) / "result.json"
            report_path = Path(tmp) / "restore.json"
            result_path.write_text(json.dumps({
                "schema": "github-board-policy-result@1", "policy": POLICY, "root": tmp,
                "operations": [
                    {"phase": "change", "identity": ["owner/repo", "issue", 1],
                     "before": "Backlog", "after": "Ready", "item_id": "item-1",
                     "added": False, "outcome": "success"},
                    {"phase": "intent", "request_id": "lost", "operation": "update"},
                ]}))
            board = [{"repo": "owner/repo", "kind": "issue", "number": 1,
                      "item_id": "item-1", "status": "Ready"}]
            with mock.patch.object(board_sync, "resolve_selection_policy", return_value=POLICY), \
                 mock.patch.object(board_sync, "_policy_board_cfg", return_value={}), \
                 mock.patch.object(board_sync, "fetch_board_items", return_value=board), \
                 mock.patch("work_connectors._ConnectorLock", FakeLock), \
                 mock.patch.object(board_sync, "option_id_for", side_effect=RuntimeError("preflight")):
                with self.assertRaisesRegex(RuntimeError, "preflight"):
                    board_sync.restore_policy_result(
                        result_path, write=True, report_path=report_path)
            persisted = json.loads(report_path.read_text())
            self.assertEqual(persisted["status"], "indeterminate")

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


class PolicyIntegrationTests(unittest.TestCase):
    class FakeLock:
        def __init__(self, _path): pass
        def acquire(self): return True
        def release(self): pass

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="gh605-policy-integration-")
        self.root = Path(self.tmp.name)
        self.as_of = (dt.datetime.now(dt.timezone.utc) -
                      dt.timedelta(seconds=1)).isoformat().replace("+00:00", "Z")
        (self.root / ".git").mkdir()
        with mock.patch.object(releases_app, "refresh_preview"), \
             mock.patch.object(releases_app, "_dispatch_work_connectors"), \
             mock.patch("sys.stdout", new_callable=__import__("io").StringIO):
            releases_app.main(["--root", str(self.root), "init", "--slug", "owner/repo"])
        conn = __import__("sqlite3").connect(self.root / "releases.db")
        repo_id = conn.execute("SELECT id FROM repos").fetchone()[0]
        now = releases_app.now_iso()
        for number, score in ((1, 90), (2, 80)):
            conn.execute("""INSERT INTO roadmap_items(
                global_id,repo_id,gh_number,title,section,position,status_marker,doc_path,
                issue_url,raw_text,first_seen,updated_at,rating_pri,rating_sev,
                rating_appeal,rating_effort)
                VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                (releases_app.new_gid("rmi-"), repo_id, number, "issue %d" % number,
                 "Queue / parked intake", number, "", "PROJECT/1-INBOX/GH-%d.md" % number,
                 "https://github.com/owner/repo/issues/%d" % number,
                 "- GH-%d issue (rated %d/1/1/1)" % (number, score), now, now,
                 score, 1, 1, 1))
        conn.commit(); conn.close()
        self.board = {
            1: {"repo": "owner/repo", "kind": "issue", "number": 1,
                "item_id": "item-1", "status": None},
        }
        self.fail_item = None
        self.failed_once = False
        self.ids = {"project": "project", "status_field": "field", "options": {
            "Ready": "ready", "Backlog": "backlog", "In progress": "progress",
            "In review": "review", "Done": "done"}}
        self.mock_state_path = self.root / "mock-board.json"
        self.mock_state = mock_gh_board.get_default_state()
        self.mock_state.update({
            "project_owner": "owner", "project_number": 4, "project_id": "project",
            "fields": {"Status": {"id": "field", "options": [
                {"id": value, "name": name} for name, value in self.ids["options"].items()]}},
            "issues": {"owner/repo": {
                "1": {"id": "content-1", "state": "OPEN"},
                "2": {"id": "content-2", "state": "OPEN"},
                "3": {"id": "content-3", "state": "OPEN"}}},
            "pull_requests": {"owner/repo": {}},
            "items": [{"id": "item-1", "content_id": "content-1",
                       "repository": "owner/repo", "number": 1, "field_values": {}}],
            "next_item_id": 2,
        })
        mock_gh_board.save_state(self.mock_state, self.mock_state_path)

    def tearDown(self):
        self.tmp.cleanup()

    def _board_snapshot(self, *_args, **_kwargs):
        return [dict(item) for item in self.board.values()]

    def _gql(self, query, variables):
        if "updateProjectV2ItemFieldValue" in query:
            item_id = variables["i"]
            if (item_id == self.fail_item or self.fail_item == "added" and item_id != "item-1") \
                    and not self.failed_once:
                self.failed_once = True
                raise RuntimeError("lost update response")
        response = mock_gh_board.handle_graphql(
            query, variables, self.mock_state, self.mock_state_path)
        if response.get("errors"):
            raise RuntimeError(response["errors"][0]["message"])
        data = response.get("data")
        if "addProjectV2ItemById" in query:
            number = int(str(variables["c"]).rsplit("-", 1)[1])
            item_id = data["addProjectV2ItemById"]["item"]["id"]
            self.board[number] = {"repo": "owner/repo", "kind": "issue", "number": number,
                                  "item_id": item_id, "status": None}
        elif "updateProjectV2ItemFieldValue" in query:
            number = next(number for number, item in self.board.items()
                          if item["item_id"] == variables["i"])
            option_to_name = {value: name for name, value in self.ids["options"].items()}
            self.board[number]["status"] = option_to_name[variables["o"]]
        elif "clearProjectV2ItemFieldValue" in query:
            number = next(number for number, item in self.board.items()
                          if item["item_id"] == variables["i"])
            self.board[number]["status"] = None
        return data

    def _patches(self):
        github = [issue(1), issue(2), issue(3)]
        return (
            mock.patch.object(board_sync, "resolve_selection_policy", return_value=POLICY),
            mock.patch.object(board_sync, "_policy_board_cfg", return_value={
                "project_owner": "owner", "project_number": 4, "repos": ["owner/repo"],
                "status_field": "Status"}),
            mock.patch.object(board_sync, "collect_github_state", return_value=github),
            mock.patch.object(board_sync, "fetch_board_items", side_effect=self._board_snapshot),
            mock.patch.object(board_sync, "resolve_ids", return_value=self.ids),
            mock.patch.object(board_sync, "_gql", side_effect=self._gql),
            mock.patch("work_connectors._ConnectorLock", self.FakeLock),
        )

    def _build_preview(self, as_of=None):
        as_of = as_of or self.as_of
        with self._patches()[0], self._patches()[1], self._patches()[2], self._patches()[3]:
            preview = board_sync.build_policy_preview(self.root, as_of=as_of)
        self.assertEqual(len(preview["changes"]), 2)
        self.assertTrue(preview["decisions"])
        return preview

    def test_real_apply_refuses_stale_evidence_even_with_fresh_creation(self):
        stale = (dt.datetime.now(dt.timezone.utc) - dt.timedelta(minutes=16)).isoformat()
        preview = self._build_preview(as_of=stale)
        preview_path = self.root / "preview-stale-evidence.json"
        result_path = self.root / "result-stale-evidence.json"
        preview_path.write_text(json.dumps(preview))
        with mock.patch.object(board_sync, "resolve_selection_policy", return_value=POLICY), \
             mock.patch.object(board_sync, "_gql") as gql:
            with self.assertRaisesRegex(RuntimeError, "older than 15 minutes"):
                board_sync.apply_policy_preview(self.root, preview_path, result_path)
        gql.assert_not_called()
        self.assertFalse(result_path.exists())

    def test_real_loader_preserves_invalid_source_identity_before_planning(self):
        cfg = {"project_owner": "owner", "project_number": 4,
               "repos": ["owner/repo"], "status_field": "Status"}
        self.board[1]["status"] = "Ready"

        def preview_for(github):
            with mock.patch.object(board_sync, "resolve_selection_policy", return_value=POLICY), \
                 mock.patch.object(board_sync, "_policy_board_cfg", return_value=cfg), \
                 mock.patch.object(board_sync, "collect_github_state", return_value=github), \
                 mock.patch.object(board_sync, "fetch_board_items",
                                   side_effect=self._board_snapshot):
                return board_sync.build_policy_preview(self.root, as_of=self.as_of)

        closed = issue(1, "CLOSED", state_reason="COMPLETED", closed_at=self.as_of)
        linked_pr = {"repo": "owner/repo", "kind": "pr", "number": 9,
                     "state": "OPEN", "draft": False,
                     "closing_issues": [{"repo": "owner/repo", "number": 1}]}
        conn = __import__("sqlite3").connect(self.root / "releases.db")
        for invalid_url in (None, "not a github issue URL",
                            "https://github.com/other/repo/issues/1"):
            with self.subTest(url=invalid_url):
                conn.execute("UPDATE roadmap_items SET issue_url=? WHERE gh_number=1",
                             (invalid_url,))
                conn.commit()
                for github in ([closed, issue(2)], [issue(1), issue(2), linked_pr]):
                    preview = preview_for(github)
                    issue_changes = [c for c in preview["changes"]
                                     if c["identity"] == ["owner/repo", "issue", 1]]
                    self.assertFalse(issue_changes)
                    self.assertTrue(any(
                        tuple(u["identity"]) == ("owner/repo", "issue", 1)
                        and "identity" in u["reason"]
                        for u in preview["unresolved"]))

        conn.execute("DELETE FROM roadmap_items WHERE gh_number=1")
        conn.commit(); conn.close()
        absent = preview_for([closed, issue(2)])
        self.assertEqual(next(c for c in absent["changes"]
                              if c["identity"] == ["owner/repo", "issue", 1])["after"],
                         "Done")

    def test_real_loader_valid_plus_invalid_rows_preserve_one_identity(self):
        with tempfile.TemporaryDirectory(prefix="gh605-invalid-pair-") as tmp:
            root = Path(tmp)
            (root / ".git").mkdir()
            conn = __import__("sqlite3").connect(root / "releases.db")
            conn.executescript("""
              CREATE TABLE schema_migrations(version INTEGER PRIMARY KEY, applied_at TEXT);
              INSERT INTO schema_migrations VALUES(8,'2026-09-13T00:00:00Z');
              CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT);
              INSERT INTO settings VALUES('generation','1');
              CREATE TABLE repos(id INTEGER PRIMARY KEY,slug TEXT);
              INSERT INTO repos VALUES(1,'owner/repo');
              CREATE TABLE roadmap_items(global_id TEXT,repo_id INTEGER,gh_number INTEGER,
                issue_url TEXT,section TEXT,status_marker TEXT,rating_pri INTEGER,
                rating_sev INTEGER,rating_appeal INTEGER,rating_effort INTEGER,rating_ovr INTEGER);
              CREATE TABLE work_events(id INTEGER PRIMARY KEY,repo_id INTEGER,gh_number INTEGER,
                event TEXT,payload TEXT,at TEXT);
              CREATE TABLE connector_cursors(connector TEXT,last_event_id INTEGER,
                last_attempt_at TEXT,last_error TEXT,updated_at TEXT);
              CREATE TABLE jog_queue(id INTEGER PRIMARY KEY,repo_id INTEGER,gh_number INTEGER,status TEXT);
            """)
            for gid, url in (("valid", "https://github.com/owner/repo/issues/1"),
                             ("invalid", "malformed")):
                conn.execute("INSERT INTO roadmap_items VALUES(?,?,?,?,?,?,?,?,?,?,?)",
                             (gid, 1, 1, url, "Queue / parked intake", "",
                              90, 1, 1, 1, None))
            conn.commit(); conn.close()
            board = [{"repo": "owner/repo", "kind": "issue", "number": 1,
                      "item_id": "item-1", "status": "Ready"}]
            github = [issue(1, "CLOSED", state_reason="COMPLETED",
                            closed_at=self.as_of)]
            with mock.patch.object(board_sync, "resolve_selection_policy", return_value=POLICY), \
                 mock.patch.object(board_sync, "_policy_board_cfg", return_value={}), \
                 mock.patch.object(board_sync, "collect_github_state", return_value=github), \
                 mock.patch.object(board_sync, "fetch_board_items", return_value=board):
                preview = board_sync.build_policy_preview(root, as_of=self.as_of)
            self.assertFalse(preview["changes"])
            self.assertTrue(any(tuple(u["identity"]) == ("owner/repo", "issue", 1)
                                and "identity" in u["reason"]
                                for u in preview["unresolved"]))

    def test_real_preview_apply_adds_absent_pr_with_mock_snapshot_identity(self):
        self.mock_state["pull_requests"] = {"owner/repo": {
            "9": {"id": "pr-content-9", "state": "OPEN", "draft": False,
                  "closing_issues": []}}}
        mock_gh_board.save_state(self.mock_state, self.mock_state_path)
        cfg = {"project_owner": "owner", "project_number": 4,
               "repos": ["owner/repo"], "status_field": "Status"}
        github = [issue(1), issue(2),
                  {"repo": "owner/repo", "kind": "pr", "number": 9,
                   "state": "OPEN", "draft": False, "closing_issues": []}]
        contexts = (
            mock.patch.object(board_sync, "resolve_selection_policy", return_value=POLICY),
            mock.patch.object(board_sync, "_policy_board_cfg", return_value=cfg),
            mock.patch.object(board_sync, "collect_github_state", return_value=github),
            mock.patch.object(board_sync, "resolve_ids", return_value=self.ids),
            mock.patch.object(board_sync, "_gql", side_effect=self._gql),
            mock.patch("work_connectors._ConnectorLock", self.FakeLock),
        )
        with contexts[0], contexts[1], contexts[2], contexts[3], contexts[4]:
            preview = board_sync.build_policy_preview(self.root, as_of=self.as_of)
        self.assertTrue(any(change["identity"] == ["owner/repo", "pr", 9]
                            for change in preview["changes"]))
        preview_path = self.root / "preview-pr.json"
        result_path = self.root / "result-pr.json"
        preview_path.write_text(json.dumps(preview))
        with contexts[0], contexts[1], contexts[2], contexts[3], contexts[4], contexts[5]:
            result = board_sync.apply_policy_preview(self.root, preview_path, result_path)
            snapshot = board_sync.fetch_board_items(cfg, cache=False)
        self.assertEqual(result["status"], "complete")
        pr = next(item for item in snapshot if item["kind"] == "pr" and item["number"] == 9)
        self.assertEqual(pr["status"], "In review")

    def test_real_preview_apply_failure_and_conditional_restore_chain(self):
        preview = self._build_preview()
        preview_path = self.root / "preview.json"
        result_path = self.root / "result.json"
        restore_path = self.root / "restore.json"
        preview_path.write_text(json.dumps(preview))
        self.fail_item = "added"
        patches = self._patches()
        with patches[0], patches[1], patches[2], patches[3], patches[4], patches[5], patches[6]:
            with self.assertRaises(board_sync.IndeterminateMutation):
                board_sync.apply_policy_preview(self.root, preview_path, result_path)
            partial = json.loads(result_path.read_text())
            self.assertEqual(partial["status"], "indeterminate")
            self.assertTrue(any(x.get("phase") == "change" and x.get("outcome") == "success"
                                for x in partial["operations"]))
            self.assertTrue(any(x.get("phase") == "result" and
                                x.get("outcome") == "indeterminate"
                                for x in partial["operations"]))
            report = board_sync.restore_policy_result(
                result_path, write=True, report_path=restore_path)
        self.assertEqual(report["status"], "indeterminate")
        self.assertIsNone(self.board[1]["status"])
        self.assertEqual(report["residual_added"][0]["item_id"], self.board[2]["item_id"])
        self.assertTrue(json.loads(restore_path.read_text())["operations"])

    def test_real_preview_complete_apply_has_nonempty_durable_audit(self):
        preview = self._build_preview()
        self.assertEqual(preview["unresolved"], [{
            "identity": ["owner/repo", "issue", 3],
            "reason": "duplicate/missing ledger or board identity",
        }])
        preview_path = self.root / "preview.json"
        result_path = self.root / "result.json"
        preview_path.write_text(json.dumps(preview))
        self.assertEqual(json.loads(preview_path.read_text())["unresolved"],
                         preview["unresolved"])
        patches = self._patches()
        with patches[0], patches[1], patches[2], patches[3], patches[4], patches[5], patches[6]:
            result = board_sync.apply_policy_preview(self.root, preview_path, result_path)
        self.assertEqual(result["status"], "complete")
        self.assertEqual(self.board[1]["status"], "Ready")
        self.assertEqual(self.board[2]["status"], "Ready")
        self.assertNotIn(3, self.board)
        persisted = json.loads(result_path.read_text())
        self.assertTrue(persisted["operations"])
        self.assertTrue(all(x.get("outcome") == "success" for x in persisted["operations"]
                            if x.get("phase") in ("change", "result")))

    def test_saved_preview_tamper_and_source_drift_refuse_before_write(self):
        base = self._build_preview()
        cases = {}
        decision = json.loads(json.dumps(base))
        decision["decisions"][0]["status"] = "Done"
        cases["decision"] = decision
        digest = json.loads(json.dumps(base)); digest["source_digest"] = "tampered"
        cases["digest"] = digest
        target = json.loads(json.dumps(base)); target["changes"][0]["after"] = "Done"
        cases["target"] = target
        unresolved = json.loads(json.dumps(base)); unresolved["unresolved"][0]["reason"] = "changed"
        cases["unresolved"] = unresolved
        for name, preview in cases.items():
            with self.subTest(name=name):
                preview_path = self.root / ("preview-%s.json" % name)
                result_path = self.root / ("result-%s.json" % name)
                preview_path.write_text(json.dumps(preview))
                patches = self._patches()
                with patches[0], patches[1], patches[2], patches[3], patches[4], \
                     mock.patch.object(board_sync, "_gql") as gql, patches[6]:
                    with self.assertRaisesRegex(RuntimeError, "preflight drift"):
                        board_sync.apply_policy_preview(self.root, preview_path, result_path)
                gql.assert_not_called()
        drift_path = self.root / "preview-drift.json"
        drift_result = self.root / "result-drift.json"
        drift_path.write_text(json.dumps(base))
        self.board[1]["status"] = "Backlog"
        patches = self._patches()
        with patches[0], patches[1], patches[2], patches[3], patches[4], \
             mock.patch.object(board_sync, "_gql") as gql, patches[6]:
            with self.assertRaisesRegex(RuntimeError, "preflight drift"):
                board_sync.apply_policy_preview(self.root, drift_path, drift_result)
        gql.assert_not_called()


if __name__ == "__main__":
    unittest.main()
