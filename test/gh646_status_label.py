"""Isolated, nonempty stdlib proof for GH-646. No live gh, installs or tracked DB writes."""
import argparse
import contextlib
import copy
import io
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "utils" / "py"))
import releases_app as app
import express
import wave_reconcile as wave
import work_connectors as connectors
from work_connectors import github_labels as labels


class Fixture:
    def __init__(self, old=False, events=True):
        self.tmp = tempfile.TemporaryDirectory(prefix="gh646-")
        self.root = self.tmp.name
        subprocess.run(["git", "init", "-q", self.root], check=True)
        subprocess.run(["git", "-C", self.root, "remote", "add", "origin",
                        "https://github.com/owner/project.git"], check=True)
        registry = {v: migration for v, migration in app.MIGRATIONS.items() if not old or v < 9}
        with mock.patch.object(app, "MIGRATIONS", registry), contextlib.redirect_stdout(io.StringIO()):
            app.cmd_init(argparse.Namespace(root=self.root, slug="owner/project"))
        self.db = str(Path(self.root) / "releases.db")
        self.conn = app.connect(self.db)
        self.number = 646
        if events:
            self.add(self.number)
        else:
            with mock.patch.object(app, "_record_work_event", return_value=None):
                self.add(self.number)

    def add(self, number):
        args = argparse.Namespace(root=self.root, issue_num=number,
                                  issue_url="https://github.com/owner/project/issues/%d" % number,
                                  title="fixture", created="2026-09-16", doc_path="PROJECT/fixture.md",
                                  raw_text=None, dry_run=False)
        with contextlib.redirect_stdout(io.StringIO()):
            app.cmd_roadmap_add(args)
        return self.conn.execute("SELECT global_id FROM roadmap_items WHERE gh_number = ?",
                                 (number,)).fetchone()[0]

    @property
    def gid(self):
        return self.conn.execute("SELECT global_id FROM roadmap_items WHERE gh_number = ?",
                                 (self.number,)).fetchone()[0]

    def row(self, gid=None):
        return dict(self.conn.execute("SELECT * FROM roadmap_items WHERE global_id = ?",
                                      (gid or self.gid,)).fetchone())

    def update(self, gid=None, **fields):
        opts = dict(root=self.root, gid=gid or self.gid, issue_num=None, raw_text=None,
                    section=None, status_marker=None, issue_url=None, accepted_start=False, dry_run=False)
        opts.update(fields)
        with contextlib.redirect_stdout(io.StringIO()):
            app.cmd_roadmap_update(argparse.Namespace(**opts))

    def batch(self, last=0):
        return {"config": {"repos": ["owner/project"]},
                "events": connectors.label_events_after(self.conn, last, self.db)}

    def close(self):
        self.conn.close()
        self.tmp.cleanup()


class Native:
    """Mutable native issue snapshot; gh edits affect ONLY the exact requested label."""
    def __init__(self):
        self.issues = {}
        self.mutations = []
        self.definitions = True
        self.fail_edit = False
        self.fail_readback = False

    def issue(self, repo="owner/project", number=646):
        key = (repo, number)
        if key not in self.issues:
            self.issues[key] = dict(number=number, html_url="https://github.com/%s/issues/%d" % key,
                                    state="open", labels=[{"name": "unrelated"}])
        return self.issues[key]

    def read(self, repo, number, url, timeout=10):
        issue = copy.deepcopy(self.issue(repo, number))
        if self.fail_readback and self.mutations:
            issue["labels"] = [{"name": "unrelated"}]
        if ("pull_request" in issue or issue["html_url"] != url
                or issue["state"] not in ("open", "closed")):
            raise ValueError("native issue identity/state unavailable or pull request")
        return issue

    def gh(self, argv, **kwargs):
        if argv[1] == "api":
            if self.definitions:
                return subprocess.CompletedProcess(argv, 0, 'HTTP/2.0 200 OK\r\n\r\n{"name":"in-progress"}', "")
            return subprocess.CompletedProcess(argv, 1, "HTTP/2.0 404 Not Found\n\n{}", "not found")
        if argv[1:3] == ["label", "create"]:
            self.definitions = True
            return subprocess.CompletedProcess(argv, 0, "", "")
        if argv[1:3] != ["issue", "edit"]:
            raise AssertionError("unexpected gh call %r" % argv)
        if self.fail_edit:
            return subprocess.CompletedProcess(argv, 1, "", "fixture permission outage")
        number = int(argv[3])
        repo = argv[argv.index("--repo") + 1]
        issue = self.issue(repo, number)
        add = "--add-label" in argv
        flag = "--add-label" if add else "--remove-label"
        label = argv[argv.index(flag) + 1]
        assert label == labels.LABEL
        names = {entry["name"] for entry in issue["labels"]}
        names.add(label) if add else names.discard(label)
        issue["labels"] = [{"name": name} for name in sorted(names)]
        self.mutations.append((repo, number, "add" if add else "remove", label))
        return subprocess.CompletedProcess(argv, 0, "", "")

    @contextlib.contextmanager
    def patched(self):
        # Qualify batches before this scope: subprocess mocks must not intercept fixture Git.
        with mock.patch.object(app, "read_native_issue", self.read), \
                mock.patch.object(labels, "read_native_issue", self.read), \
                mock.patch.object(labels.subprocess, "run", self.gh):
            yield self


class StatusLabelTests(unittest.TestCase):
    def setUp(self):
        self.env = mock.patch.dict(os.environ, {"XYZ_WORK_CONNECTORS": "0"})
        self.env.start()
        self.fx = Fixture()
        self.native = Native()

    def tearDown(self):
        self.fx.close()
        self.env.stop()

    def start(self, **opts):
        # Native mock only, so owned origin qualification still runs real isolated Git.
        with mock.patch.object(app, "read_native_issue", self.native.read):
            self.fx.update(accepted_start=True, **opts)

    def project(self, batch=None):
        batch = batch or self.fx.batch()
        with self.native.patched(), contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(labels.run(batch), 0)
        return int(output.getvalue().split("advanced_to: ")[1])

    def test_migration_metadata_never_establishes_label(self):
        self.fx.close()
        self.fx = Fixture(old=True)
        self.fx.update(section="In progress", status_marker="🚧")
        count = self.fx.conn.execute("SELECT count(*) FROM work_events").fetchone()[0]
        historical = [dict(r) for r in self.fx.conn.execute("SELECT * FROM op_receipts")]
        with contextlib.redirect_stdout(io.StringIO()):
            app.perform_migration(self.fx.root, self.fx.conn)
        self.assertIsNone(self.fx.row()["status_label"])
        self.fx.update(raw_text="- **GH-646 · fixture metadata**")
        self.assertIsNone(self.fx.row()["status_label"])
        batch = self.fx.batch(count)
        self.project(batch)
        self.assertEqual(self.native.mutations, [])
        self.assertEqual([dict(r) for r in self.fx.conn.execute("SELECT * FROM op_receipts LIMIT ?",
                                                              (len(historical),))], historical)
        migration = self.fx.conn.execute("SELECT * FROM op_receipts WHERE op = 'migrate'").fetchone()
        self.assertEqual(migration["state_digest_before"], historical[-1]["state_digest_after"])
        self.assertEqual(self.fx.conn.execute("SELECT count(*) FROM work_events").fetchone()[0], count + 1)
        self.start()
        self.assertEqual(self.fx.row()["status_label"], "in-progress")
        evidence = app.load_work_evidence(self.fx.db)
        self.assertTrue(evidence["issues"][0]["recent_start"])
        self.project()
        self.assertEqual(len(self.native.mutations), 1)

    def test_ordinary_active_appearance_never_establishes_label(self):
        # Legacy section/marker transitions retain their event compatibility, but
        # only an explicitly qualified admission establishes the new label.
        self.fx.conn.execute(
            "UPDATE roadmap_items SET issue_url='https://github.com/foreign/project/issues/646'"
        )
        self.fx.update(section="In progress", status_marker="🚧")
        self.assertIsNone(self.fx.row()["status_label"])
        self.assertEqual(app.latest_owned_lifecycle(self.fx.conn, 1, 646)["event"], "in_flight")

        self.fx.conn.execute(
            "UPDATE roadmap_items SET issue_url='https://github.com/owner/project/issues/646', "
            "section='Queue / parked intake', status_marker='🆕'"
        )
        self.native.issue()["state"] = "closed"
        self.fx.update(section="In progress", status_marker="🚧")
        self.assertIsNone(self.fx.row()["status_label"])

        self.native.issue()["state"] = "open"
        self.native.issue()["pull_request"] = {}
        self.fx.update(section="Queue / parked intake", status_marker="🆕")
        self.fx.update(section="In progress", status_marker="🚧")
        self.assertIsNone(self.fx.row()["status_label"])

        del self.native.issue()["pull_request"]
        self.start()
        self.assertEqual(self.fx.row()["status_label"], "in-progress")

    def test_duplicate_metadata_and_restart_authority(self):
        self.fx.update(section="In progress", status_marker="🚧")
        self.start()
        first = app.latest_owned_lifecycle(self.fx.conn, 1, 646)
        count = self.fx.conn.execute("SELECT count(*) FROM work_events").fetchone()[0]
        self.start()
        self.assertEqual(self.fx.conn.execute("SELECT count(*) FROM work_events").fetchone()[0], count)
        self.fx.update(raw_text="- **GH-646 · metadata**")
        self.assertEqual(app.latest_owned_lifecycle(self.fx.conn, 1, 646), first)
        self.assertEqual(self.fx.row()["status_label"], "in-progress")
        self.fx.update(section="Completed")
        self.assertIsNone(self.fx.row()["status_label"])
        self.start()
        self.assertGreater(app.latest_owned_lifecycle(self.fx.conn, 1, 646)["id"], first["id"])

    def test_active_appearance_changes_preserve_original_start(self):
        self.start()
        first = app.latest_owned_lifecycle(self.fx.conn, 1, 646)
        original = app.load_work_evidence(self.fx.db)["issues"][0]
        self.assertTrue(original["recent_start"])
        for fields in ({"section": "Queue"},
                       {"section": "In progress", "status_marker": "🆕"}):
            with self.subTest(fields=fields):
                self.fx.update(**fields)
                self.assertEqual(app.latest_owned_lifecycle(self.fx.conn, 1, 646), first)
                self.assertEqual(self.fx.row()["status_label"], "in-progress")
                latest = self.fx.conn.execute("SELECT event,payload FROM work_events ORDER BY id DESC LIMIT 1").fetchone()
                self.assertEqual(latest["event"], "updated")
                self.assertFalse(json.loads(latest["payload"])["transition"])
                current = app.load_work_evidence(self.fx.db)["issues"][0]
                self.assertEqual(current["recent_start"]["id"], original["recent_start"]["id"])
                self.assertEqual(current["recent_start"]["at"], original["recent_start"]["at"])

    def test_unchanged_legacy_admission_and_dry_run(self):
        # Simulate restored legacy appearance without accepted provenance.
        self.fx.conn.execute("UPDATE roadmap_items SET section='In progress',status_marker='🚧'")
        self.start(dry_run=True)
        self.assertIsNone(self.fx.row()["status_label"])
        self.start()
        ev = app.latest_owned_lifecycle(self.fx.conn, 1, 646)
        self.assertEqual(ev["event"], "in_flight")
        self.assertEqual(ev["payload"]["source"], "roadmap-update")
        self.assertTrue(ev["payload"]["accepted_start"])
        self.assertTrue(app.load_work_evidence(self.fx.db)["issues"][0]["recent_start"])

    def test_concurrent_duplicate_admission_rechecked_inside_lock(self):
        original = self.native.read
        raced = False
        def read(*args,**kwargs):
            nonlocal raced
            if not raced:
                raced = True
                with mock.patch.object(app,"read_native_issue",original):
                    self.fx.update(accepted_start=True)
            return original(*args,**kwargs)
        with mock.patch.object(app,"read_native_issue",read):
            self.fx.update(accepted_start=True)
        self.assertEqual(self.fx.row()["status_label"],"in-progress")
        self.assertEqual(self.fx.conn.execute("SELECT count(*) FROM work_events WHERE event='in_flight'").fetchone()[0],1)

    def test_terminal_precedence_and_nonempty_lifecycle_loop(self):
        self.start()
        self.native.definitions = False
        self.project()
        self.native.issue()["state"] = "closed"
        self.fx.update(section="Completed")
        self.assertEqual(self.fx.row()["status_marker"], "🚧")
        self.assertIsNone(self.fx.row()["status_label"])
        self.project()
        self.assertEqual([mutation[2] for mutation in self.native.mutations], ["add", "remove"])
        self.assertEqual(self.native.issue()["labels"], [{"name": "unrelated"}])
        self.native.issue()["state"] = "open"
        self.project()
        self.assertIsNone(self.fx.row()["status_label"])

    def test_cancelled_and_explicit_inactive_open_removal(self):
        for section in ("Deferred · vision", "Queue / parked intake"):
            with self.subTest(section=section):
                self.start()
                self.project()
                self.fx.update(section=section, status_marker="🆕")
                self.assertIsNone(self.fx.row()["status_label"])
                self.project()
                self.assertNotIn({"name": "in-progress"}, self.native.issue()["labels"])
        self.assertEqual(len(self.native.mutations), 4)

    def test_failed_removal_reopen_replay_and_cursor_retention(self):
        self.start()
        self.project()
        active_cursor = self.fx.conn.execute("SELECT max(id) FROM work_events").fetchone()[0]
        connectors._persist(self.fx.db, {"github_labels": (active_cursor, None)}, app.now_iso())
        self.fx.update(section="Completed")
        batch = self.fx.batch(active_cursor)
        self.native.fail_edit = True
        with self.native.patched(), self.assertRaises(RuntimeError):
            labels.run(batch)
        # The parent's conservative failure path must not acknowledge even partial success.
        connectors._persist(self.fx.db, {"github_labels": (None, "fixture outage")}, app.now_iso())
        self.assertEqual(connectors.cursor_for(self.fx.conn, "github_labels"), active_cursor)
        self.assertIn("fixture outage", self.fx.conn.execute(
            "SELECT last_error FROM connector_cursors WHERE connector='github_labels'").fetchone()[0])
        self.native.fail_edit = False
        self.native.issue()["state"] = "open"  # reopen before failed cleanup gets replayed
        self.project(batch)
        self.assertEqual(self.native.mutations[-1][2], "remove")

    def test_owned_identity_and_pr_refusal(self):
        self.fx.conn.execute("UPDATE roadmap_items SET issue_url='https://github.com/foreign/project/issues/646'")
        with self.assertRaises(SystemExit):
            self.start()
        self.assertIsNone(self.fx.row()["status_label"])
        with self.assertRaises(ValueError):
            self.project()
        self.fx.conn.execute("UPDATE roadmap_items SET issue_url='https://github.com/owner/project/issues/646'")
        self.native.issue()["pull_request"] = {}
        with self.assertRaises(SystemExit):
            self.start()
        self.assertEqual(self.native.mutations, [])

    def test_disallowed_repo_and_native_closed_do_not_add(self):
        self.start()
        batch = self.fx.batch()
        batch["config"]["repos"] = ["foreign/project"]
        with mock.patch.object(labels,"read_native_issue") as read, \
                mock.patch.object(labels.subprocess,"run") as gh, contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(labels.run(batch),0)
        read.assert_not_called()
        gh.assert_not_called()
        self.assertEqual(self.native.mutations,[])
        self.native.issue()["state"] = "closed"
        self.project()
        self.assertEqual(self.native.mutations, [])

    def test_source_unavailable_pending_journal(self):
        self.start()
        journal = Path(app.git_common_dir(self.fx.root)) / app.JOURNAL_NAME
        journal.write_text("{}")  # isolated fixture artifact, not project source
        batch = self.fx.batch()
        self.assertTrue(batch["events"])
        with self.native.patched(), self.assertRaisesRegex(ValueError, "source unavailable"):
            labels.run(batch)
        self.assertEqual(self.native.mutations, [])

    def test_ambiguous_owned_rows_refuse(self):
        self.start()
        row = self.fx.row()
        row.pop("id")
        row["global_id"] = app.new_gid("rmi-")
        with self.assertRaises(sqlite3.IntegrityError):
            self.fx.conn.execute("INSERT INTO roadmap_items(%s) VALUES(%s)" %
                                 (",".join(row), ",".join("?" for _ in row)), tuple(row.values()))
        # Defensive snapshot refusal even for an externally corrupted/noncanonical source.
        real = self.fx.conn
        class Ambiguous:
            def execute(self, sql, params=()):
                result = real.execute(sql, params)
                if sql.startswith("SELECT * FROM roadmap_items WHERE repo_id"):
                    rows = result.fetchall()
                    return mock.Mock(fetchall=lambda: rows + rows)
                return result
        batch = {"config":{"repos":["owner/project"]},
                 "events":connectors.label_events_after(Ambiguous(),0,self.fx.db)}
        with self.assertRaises(ValueError):
            self.project(batch)

    def test_same_number_foreign_rows_never_borrow_owner(self):
        now = app.now_iso()
        self.fx.conn.execute("INSERT INTO repos(global_id,slug,updated_at) VALUES(?,?,?)",
                             (app.new_gid("repo-"), "foreign/project", now))
        row = self.fx.row()
        row.pop("id")
        row.update(global_id=app.new_gid("rmi-"), repo_id=2,
                   issue_url="https://github.com/owner/project/issues/646")
        self.fx.conn.execute("INSERT INTO roadmap_items(%s) VALUES(%s)" %
                             (",".join(row), ",".join("?" for _ in row)), tuple(row.values()))
        with self.assertRaises(SystemExit):
            self.start(gid=row["global_id"])
        self.assertEqual(express.qualified_roadmap_row(self.fx.root, "owner/project", 646)["global_id"], self.fx.gid)

    def test_roundtrip_new_old_and_corrupt_field(self):
        self.start()
        dumped = app.dump_text(self.fx.conn, app.get_generation(self.fx.conn))
        tables = app.parse_dump(dumped)
        self.assertGreater(len(tables["roadmap_items"]), 0)
        for old in (False, True):
            clone = sqlite3.connect(":memory:", isolation_level=None)
            clone.row_factory = sqlite3.Row
            app.apply_migrations(clone, stamp_ledger=False)
            rows = copy.deepcopy(tables)
            if old:
                for row in rows["roadmap_items"]:
                    row.pop("status_label")
            app.load_dump(clone, rows)
            self.assertEqual(clone.execute("SELECT status_label FROM roadmap_items").fetchone()[0],
                             None if old else "in-progress")
            if not old:
                self.assertEqual(app.business_digest(clone), app.business_digest(self.fx.conn))
            clone.close()
        with self.assertRaises(sqlite3.IntegrityError):
            self.fx.conn.execute("UPDATE roadmap_items SET status_label='invalid'")

    def test_schema8_evidence_supported_labels_unavailable(self):
        self.fx.close()
        self.fx = Fixture(old=True)
        evidence = app.load_work_evidence(self.fx.db)
        self.assertTrue(evidence["schema_ready"])
        self.assertFalse(evidence["status_label_supported"])
        self.assertTrue(evidence["issues"])
        with self.assertRaises(SystemExit):
            self.start()
        with self.assertRaises(ValueError):
            self.project()

    def test_zero_event_completed_cancelled_qualified_repair(self):
        for section in ("Completed", "Deferred · vision"):
            with self.subTest(section=section):
                self.fx.close()
                self.fx = Fixture(events=False)
                self.assertEqual(self.fx.conn.execute("SELECT count(*) FROM work_events").fetchone()[0],0)
                self.fx.conn.execute("UPDATE roadmap_items SET section=?,status_label=NULL", (section,))
                self.native.issue()["state"] = "closed"
                self.native.issue()["labels"].append({"name": "in-progress"})
                with contextlib.redirect_stdout(io.StringIO()):
                    app.cmd_work_emit(argparse.Namespace(root=self.fx.root, event="label_repair",
                        gh_number=None, roadmap_gid=self.fx.gid, payload_json=None))
                self.assertEqual(self.fx.conn.execute("SELECT count(*) FROM work_events").fetchone()[0], 1)
                self.assertIsNone(app.latest_owned_lifecycle(self.fx.conn, 1, 646))
                self.project()
                self.assertEqual(self.native.mutations[-1][2], "remove")
        self.assertEqual(len(self.native.mutations), 2)

    def test_repair_rejects_active_foreign_and_open_conflict(self):
        self.start()
        opts = argparse.Namespace(root=self.fx.root, event="label_repair", gh_number=None,
                                  roadmap_gid=self.fx.gid, payload_json=None)
        with self.assertRaises(SystemExit):
            app.cmd_work_emit(opts)
        self.fx.close()
        self.fx = Fixture(events=False)
        opts.roadmap_gid = self.fx.gid
        opts.root = self.fx.root
        self.fx.conn.execute("UPDATE roadmap_items SET section='Completed',status_label=NULL")
        self.native.issue()["labels"].append({"name": "in-progress"})
        with contextlib.redirect_stdout(io.StringIO()):
            app.cmd_work_emit(opts)
        with self.assertRaisesRegex(ValueError, "unresolved-label-conflict"):
            self.project()
        self.fx.conn.execute("UPDATE roadmap_items SET issue_url='https://github.com/foreign/project/issues/646'")
        with self.assertRaises(SystemExit):
            app.cmd_work_emit(opts)
        self.assertEqual(self.native.mutations, [])

    def test_board_payload_unchanged_repair_only_no_child(self):
        legacy = connectors.events_after(self.fx.conn, 0)
        self.assertEqual(set(legacy[0]), {"id", "gh_number", "event", "payload", "at"})
        prior = legacy[-1]["id"]
        connectors._persist(self.fx.db, {"github_board": (prior, None)}, app.now_iso())
        self.fx.conn.execute("UPDATE roadmap_items SET section='Completed'")
        with contextlib.redirect_stdout(io.StringIO()):
            app.cmd_work_emit(argparse.Namespace(root=self.fx.root, event="label_repair",
                gh_number=None, roadmap_gid=self.fx.gid, payload_json=None))
        maximum = self.fx.conn.execute("SELECT max(id) FROM work_events").fetchone()[0]
        with mock.patch.object(connectors, "_launch") as launch:
            result = connectors._dispatch_locked(self.fx.db, app.now_iso(), {"github_board": {}}, 1)
        launch.assert_not_called()
        self.assertEqual(result["github_board"], (maximum, None))
        self.assertEqual(connectors.cursor_for(self.fx.conn, "github_board"), maximum)
        self.assertEqual(connectors.events_after(self.fx.conn, 0)[0], legacy[0])

    def test_backfill_safe_skip_partial_and_over500_replay(self):
        other = self.fx.add(647)
        self.start()
        self.start(gid=other)
        # 501 metadata events are bounded and drain without skipping the second active issue.
        for _ in range(501):
            self.fx.conn.execute("INSERT INTO work_events(global_id,repo_id,gh_number,txn_id,event,payload,at) "
                                 "VALUES(?,1,646,'fixture','updated',?,?)",
                                 (app.new_gid("wev-"), json.dumps({"source":"roadmap-update","transition":False}), app.now_iso()))
        maximum = self.fx.conn.execute("SELECT max(id) FROM work_events").fetchone()[0]
        cursor, rounds = 0, 0
        while cursor < maximum and rounds < 10:
            batch = self.fx.batch(cursor)
            self.assertGreater(len(batch["events"]), 0)
            self.assertLessEqual(len(batch["events"]), 500)
            next_cursor = self.project(batch)
            self.assertGreater(next_cursor, cursor)
            cursor, rounds = next_cursor, rounds + 1
        self.assertEqual(cursor, maximum)
        self.assertGreaterEqual(rounds, 3)
        self.assertEqual({mutation[1] for mutation in self.native.mutations}, {646,647})
        self.assertEqual(len(self.native.mutations), 2)
        self.fx.conn.execute("UPDATE roadmap_items SET status_label=NULL")
        batch = self.fx.batch()
        for ev in batch["events"]:
            ev["payload"] = {"source":"backfill"}
        before = len(self.native.mutations)
        self.project(batch)
        self.assertEqual(len(self.native.mutations), before)

    def test_opt_out_no_network(self):
        with mock.patch.object(connectors, "_launch") as launch:
            self.assertEqual(connectors.dispatch(self.fx.db, app.now_iso()), {})
        launch.assert_not_called()

    def test_owned_opted_out_repo_before_included_start_progresses(self):
        now = app.now_iso()
        self.fx.conn.execute("INSERT INTO repos(global_id,slug,updated_at) VALUES(?,?,?)",
                             (app.new_gid("repo-"),"excluded/project",now))
        row = self.fx.row()
        row.pop("id")
        row.update(global_id=app.new_gid("rmi-"),repo_id=2,section="In progress",
                   status_marker="🚧",status_label="in-progress",
                   issue_url="https://github.com/excluded/project/issues/646")
        self.fx.conn.execute("INSERT INTO roadmap_items(%s) VALUES(%s)" %
                             (",".join(row),",".join("?" for _ in row)),tuple(row.values()))
        self.fx.conn.execute("INSERT INTO work_events(global_id,repo_id,gh_number,txn_id,event,payload,at) "
                             "VALUES(?,2,646,'fixture','in_flight',?,?)",
                             (app.new_gid("wev-"),json.dumps({"source":"roadmap-update","transition":True}),now))
        self.start()
        batch = self.fx.batch()
        with self.native.patched(), mock.patch.object(labels,"read_native_issue",wraps=self.native.read) as read, \
                contextlib.redirect_stdout(io.StringIO()) as output:
            self.assertEqual(labels.run(batch),0)
        self.assertEqual(int(output.getvalue().split("advanced_to: ")[1]),batch["events"][-1]["id"])
        self.assertEqual({call.args[0] for call in read.call_args_list},{"owner/project"})
        self.assertEqual([mutation[0] for mutation in self.native.mutations],["owner/project"])
        # Opt-out must not hide malformed owned URL/number defects.
        self.fx.conn.execute("UPDATE roadmap_items SET issue_url='https://github.com/foreign/project/issues/646' WHERE repo_id=2")
        with self.assertRaises(ValueError):
            self.project()

    def test_native_rest_validation(self):
        issue = self.native.issue()
        for change in ({"pull_request":{}}, {"number":42}, {"html_url":"https://github.com/foreign/project/issues/646"},
                       {"state":"unknown"}):
            data = dict(issue, **change)
            with mock.patch.object(app.subprocess, "run", return_value=subprocess.CompletedProcess([],0,json.dumps(data),"")):
                with self.assertRaises(ValueError):
                    app.read_native_issue("owner/project",646,issue["html_url"])

    def test_close_during_definition_and_after_add_retains_conflict(self):
        self.start()
        batch = self.fx.batch()
        original = self.native.gh
        for when in ("definition", "add"):
            with self.subTest(when=when):
                self.native.issue()["state"] = "open"
                self.native.issue()["labels"] = [{"name":"unrelated"}]
                self.native.mutations.clear()
                def raced(argv, **kwargs):
                    result = original(argv, **kwargs)
                    if (when == "definition" and argv[1] == "api"
                            or when == "add" and "--add-label" in argv):
                        self.native.issue()["state"] = "closed"
                    return result
                with self.native.patched(), mock.patch.object(labels.subprocess, "run", raced), \
                        self.assertRaisesRegex(RuntimeError, "native-state-conflict"):
                    labels.run(batch)
                self.assertEqual(len(self.native.mutations), 0 if when == "definition" else 1)
                # Closed-current-state replay must clean any raced add, not reactivate.
                self.project(batch)
                self.assertNotIn({"name":"in-progress"}, self.native.issue()["labels"])

    def test_foreign_url_closure_preserves_owned_start_and_sweeps_valid_row(self):
        self.start()
        first = app.latest_owned_lifecycle(self.fx.conn, 1, 646)
        self.fx.update(issue_url="https://github.com/foreign/project/issues/646")
        other = self.fx.add(647)
        queried = []
        def native(argv, **kwargs):
            if argv[0] == "git":
                return subprocess.CompletedProcess(argv, 0, "https://github.com/owner/project.git\n", "")
            queried.append(argv[3])
            return subprocess.CompletedProcess(argv, 0, json.dumps({"state":"CLOSED", "stateReason":"COMPLETED"}), "")
        with mock.patch.object(app.subprocess, "run", side_effect=native), contextlib.redirect_stdout(io.StringIO()):
            app.cmd_roadmap_reconcile_state(argparse.Namespace(root=self.fx.root, apply=True))
        self.assertEqual(self.fx.row()["section"], "In progress")
        self.assertEqual(self.fx.row()["status_label"], "in-progress")
        self.assertEqual(app.latest_owned_lifecycle(self.fx.conn, 1, 646), first)
        self.assertEqual(self.fx.row(other)["section"], "Completed")
        self.assertEqual(queried, ["https://github.com/owner/project/issues/647"])

    def test_direct_close_with_caught_up_cursor_and_cancellation(self):
        for reason, section in (("COMPLETED","Completed"), ("NOT_PLANNED","Deferred · vision")):
            with self.subTest(reason=reason):
                self.start()
                cursor = self.project()
                connectors._persist(self.fx.db, {"github_labels":(cursor,None)}, app.now_iso())
                self.native.issue()["state"] = "closed"
                issue = subprocess.CompletedProcess([],0,json.dumps({"state":"CLOSED","stateReason":reason}),"")
                args = argparse.Namespace(root=self.fx.root, apply=False)
                with mock.patch.object(app.subprocess,"run",return_value=issue), contextlib.redirect_stdout(io.StringIO()):
                    app.cmd_roadmap_reconcile_state(args)
                self.assertEqual(self.fx.row()["status_label"],"in-progress")
                args.apply = True
                with mock.patch.object(app.subprocess,"run",return_value=issue), contextlib.redirect_stdout(io.StringIO()):
                    app.cmd_roadmap_reconcile_state(args)
                self.assertEqual(self.fx.row()["section"],section)
                self.assertIsNone(self.fx.row()["status_label"])
                self.project(self.fx.batch(cursor))
                self.assertEqual(self.native.mutations[-1][2],"remove")
                self.native.issue()["state"] = "open"

    def test_express_refuses_before_activation_and_requalifies_before_snapshot(self):
        args = argparse.Namespace(root=self.fx.root, repo="owner/project", issue=646,
                                  dry_run=False, _expect_driver=set(), release=None)
        with mock.patch.object(express,"qualify_root_repository"), \
                mock.patch.object(express,"cmd_check",side_effect=SystemExit(3)), \
                mock.patch.object(express,"run_releases") as command:
            with self.assertRaises(SystemExit):
                express.cmd_land(args)
        command.assert_not_called()
        self.assertIsNone(self.fx.row()["status_label"])
        order = []
        def check(*a, **kw):
            order.append(("check",self.fx.row()["status_label"]))
            return {"suite":"test/fixture.sh","paths":[]}
        def admission(root,*argv,**kwargs):
            order.append(("admit",argv))
            with mock.patch.object(app,"read_native_issue",self.native.read):
                app.main(["--root",root]+list(argv))
        class SnapshotStop(Exception):
            pass
        def snapshot(*a):
            order.append(("snapshot",None))
            raise SnapshotStop()
        with mock.patch.object(express,"qualify_root_repository"), \
                mock.patch.object(express,"cmd_check",side_effect=check), \
                mock.patch.object(express,"run_releases",side_effect=admission), \
                mock.patch.object(express,"snapshot_paths",side_effect=snapshot), \
                contextlib.redirect_stdout(io.StringIO()):
            for _ in range(2):  # interrupted admission retry never supersedes effective start
                with self.assertRaises(SnapshotStop):
                    express.cmd_land(args)
        self.assertEqual([entry[0] for entry in order[:4]],["check","admit","check","snapshot"])
        self.assertEqual(order[0][1],None)
        self.assertEqual(order[2][1],"in-progress")
        starts = self.fx.conn.execute("SELECT count(*) FROM work_events WHERE event='in_flight'").fetchone()[0]
        self.assertEqual(starts,1)

    def test_express_dry_run_no_admission_write_and_foreign_row_refused(self):
        args = argparse.Namespace(root=self.fx.root, repo="owner/project", issue=646,
                                  dry_run=True, _expect_driver=set(), release=None)
        before = app.get_generation(self.fx.conn)
        def admission(root,*argv,**kwargs):
            self.assertIn("--dry-run",argv)
            with mock.patch.object(app,"read_native_issue",self.native.read):
                app.main(["--root",root]+list(argv))
        with mock.patch.object(express,"qualify_root_repository"), \
                mock.patch.object(express,"cmd_check",return_value={"suite":"test/fixture.sh","paths":[]}) as check, \
                mock.patch.object(express,"run_releases",side_effect=admission), \
                mock.patch.object(express,"snapshot_paths",return_value={}), \
                mock.patch.object(express,"change_paths",return_value=[]), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(express.cmd_land(args)["sha"],"dry-run")
        self.assertEqual(check.call_count,2)
        self.assertEqual(app.get_generation(self.fx.conn),before)
        self.assertIsNone(self.fx.row()["status_label"])
        self.fx.conn.execute("UPDATE repos SET slug='foreign/project'")
        with mock.patch.object(express,"qualify_root_repository"), \
                mock.patch.object(express,"cmd_check",return_value={"suite":"test/fixture.sh","paths":[]}), \
                mock.patch.object(express,"run_releases") as command, \
                mock.patch.object(express,"refuse",side_effect=SystemExit(3)), self.assertRaises(SystemExit):
            express.cmd_land(args)
        command.assert_not_called()

    def test_express_registration_and_resume_do_not_start(self):
        args = argparse.Namespace(root=self.fx.root, repo="owner/project", issue=646,
                                  dry_run=False, release="rel-fixture", doc_path=None)
        issue = subprocess.CompletedProcess([],0,json.dumps(dict(title="fixture",url=self.fx.row()["issue_url"],
            state="OPEN",createdAt="2026-09-16T00:00:00Z")),"")
        with mock.patch.object(express,"gh",return_value=issue), \
                mock.patch.object(express,"run_releases") as command, contextlib.redirect_stdout(io.StringIO()):
            express.cmd_ledger(args)
        self.assertEqual(command.call_count,1)
        self.assertEqual(command.call_args.args[1:3],("manifest","dial-in"))
        self.assertIsNone(self.fx.row()["status_label"])
        # Existing receipt-based resume's clean-tree/dry-run path never invokes admission.
        with mock.patch.object(express,"git",return_value=subprocess.CompletedProcess([],0,"", "")), \
                mock.patch.object(express,"qualify_resume_identity",return_value=self.fx.row()), \
                mock.patch.object(express,"resolve_landing_commit",return_value="a"*40), \
                mock.patch.object(express,"run_releases") as command, contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(express.cmd_resume(argparse.Namespace(root=self.fx.root,issue=646,
                sha=None,suite="test/fixture.sh",dry_run=True))["sha"],"a"*40)
        command.assert_not_called()

    def test_express_land_and_run_reject_second_owned_foreign_repository(self):
        self.fx.conn.execute("INSERT INTO repos(global_id,slug,updated_at) VALUES(?,?,?)",
                             (app.new_gid("repo-"),"foreign/project",app.now_iso()))
        foreign = self.fx.row()
        foreign.pop("id")
        foreign.update(global_id=app.new_gid("rmi-"),repo_id=2,
                       issue_url="https://github.com/foreign/project/issues/646")
        self.fx.conn.execute("INSERT INTO roadmap_items(%s) VALUES(%s)" %
                             (','.join(foreign),','.join('?' for _ in foreign)),tuple(foreign.values()))
        self.assertIsNotNone(express.qualified_roadmap_row(self.fx.root,"foreign/project",646))
        args = argparse.Namespace(root=self.fx.root,repo="foreign/project",issue=646,
                                  dry_run=True,_expect_driver=set(),release=None)
        for action in (express.cmd_land,express.cmd_run):
            with self.subTest(action=action.__name__), tempfile.TemporaryDirectory() as home:
                def snapshot():
                    return {str(p):p.read_bytes() if p.is_file() else None
                            for root in (Path(home),Path(self.fx.root)) for p in root.rglob('*')}
                before = snapshot()
                with mock.patch.dict(os.environ,{"HOME":home}), \
                        mock.patch.object(express.subprocess,"run",return_value=subprocess.CompletedProcess([],0,
                            json.dumps({"nameWithOwner":"owner/project"}),"")) as process, \
                        mock.patch.object(express,"cmd_check",return_value={"suite":"test/fixture.sh","paths":[]}), \
                        mock.patch.object(express,"cmd_docs") as docs, \
                        mock.patch.object(express,"cmd_ledger") as ledger, \
                        mock.patch.object(express,"run_releases") as command, \
                        mock.patch.object(express,"gh") as remote, \
                        mock.patch.object(express,"reconcile_gated") as reconcile, \
                        mock.patch.object(express,"snapshot_paths",return_value={}), \
                        mock.patch.object(express,"change_paths",return_value=[]), \
                        self.assertRaises(SystemExit):
                    action(args)
                docs.assert_not_called(); ledger.assert_not_called(); command.assert_not_called()
                remote.assert_not_called(); reconcile.assert_not_called()
                self.assertEqual(process.call_args.kwargs["cwd"],self.fx.root)
                self.assertNotIn("GH_REPO",process.call_args.kwargs["env"])
                self.assertEqual(snapshot(),before)

    def test_express_manifest_state_uses_exact_issue_url_in_both_orders(self):
        # Minimal pre-existing state-reader schema: deliberately same issue number.
        with tempfile.TemporaryDirectory(prefix="gh646-manifest-") as root:
            conn = sqlite3.connect(str(Path(root)/"releases.db"))
            conn.executescript("CREATE TABLE releases(id INTEGER, global_id TEXT);"
                               "CREATE TABLE issue_refs(id INTEGER, url TEXT);"
                               "CREATE TABLE manifest_items(id INTEGER,release_id INTEGER,issue_ref_id INTEGER,state TEXT);"
                               "INSERT INTO releases VALUES(1,'rel-fixture');"
                               "INSERT INTO issue_refs VALUES(1,'https://github.com/owner/project/issues/646');"
                               "INSERT INTO issue_refs VALUES(2,'https://github.com/foreign/project/issues/646');")
            for owned,foreign in (("dialed_in","shipped"),("shipped","dialed_in")):
                for order in ((1,2),(2,1)):
                    conn.execute("DELETE FROM manifest_items")
                    for index,ref in enumerate(order,1):
                        conn.execute("INSERT INTO manifest_items VALUES(?,?,?,?)",
                                     (index,1,ref,owned if ref==1 else foreign))
                    conn.commit()
                    self.assertEqual(express.check_manifest_state(root,
                        "https://github.com/owner/project/issues/646","rel-fixture"),owned)
                    self.assertEqual(express.check_manifest_state(root,
                        "https://github.com/foreign/project/issues/646","rel-fixture"),foreign)
                    args = argparse.Namespace(root=root,repo="owner/project",issue=646,
                        dry_run=False,release="rel-fixture",sha="a"*40,suite="test/fixture.sh")
                    owned_url = "https://github.com/owner/project/issues/646"
                    def ship(_root,*argv,**kw):
                        self.assertEqual(argv[:3],("manifest","ship",owned_url))
                        conn.execute("UPDATE manifest_items SET state='shipped' WHERE issue_ref_id=1")
                        conn.commit()
                    with mock.patch.object(express,"git",return_value=subprocess.CompletedProcess([],0,"","")), \
                            mock.patch.object(express,"resolve_landing_commit",return_value="a"*40), \
                            mock.patch.object(express,"qualify_resume_identity",return_value={"issue_url":owned_url}), \
                            mock.patch.object(express,"find_committed_receipt",return_value="fixture-receipt"), \
                            mock.patch.object(express,"gh",return_value=subprocess.CompletedProcess([],0,'{"state":"CLOSED"}',"")), \
                            mock.patch.object(express,"run_releases",side_effect=ship) as command, \
                            mock.patch.object(express,"persist_closeout",return_value=False), \
                            mock.patch.object(express,"reconcile_gated"), \
                            mock.patch.object(express,"write_tick"), contextlib.redirect_stdout(io.StringIO()):
                        express.cmd_resume(args)
                    self.assertEqual(command.call_count,1 if owned=="dialed_in" else 0)
                    self.assertEqual(conn.execute("SELECT state FROM manifest_items WHERE issue_ref_id=1").fetchone()[0],"shipped")
                    self.assertEqual(conn.execute("SELECT state FROM manifest_items WHERE issue_ref_id=2").fetchone()[0],foreign)
            conn.close()

    def test_express_missing_ledger_identity_preview_never_creates_database(self):
        self.fx.conn.close()
        Path(self.fx.db).rename(Path(self.fx.root)/"saved-ledger.db")
        for action in (express.cmd_land,express.cmd_resume):
            args = argparse.Namespace(root=self.fx.root,repo="owner/project",issue=646,
                                      dry_run=True,_expect_driver=set(),release=None,sha=None,suite="test/fixture.sh")
            with self.subTest(action=action.__name__), tempfile.TemporaryDirectory() as home:
                def snapshot():
                    return {str(p):p.read_bytes() if p.is_file() else None
                            for root in (Path(home),Path(self.fx.root)) for p in root.rglob('*')}
                before = snapshot()
                with mock.patch.dict(os.environ,{"HOME":home}), \
                        mock.patch.object(express,"cmd_check",return_value={"suite":"test/fixture.sh","paths":[]}), \
                        mock.patch.object(express,"git",return_value=subprocess.CompletedProcess([],0,"development","")) as git, \
                        mock.patch.object(express,"resolve_landing_commit",return_value="a"*40), \
                        mock.patch.object(express.subprocess,"run",return_value=subprocess.CompletedProcess([],0,
                            json.dumps({"nameWithOwner":"owner/project"}),"")), \
                        mock.patch.object(express,"run_releases") as command, \
                        self.assertRaises(SystemExit):
                    # Resume's cleanliness query must be empty; root git identity remains explicit.
                    git.side_effect = lambda root,*argv,**kw: subprocess.CompletedProcess([],0,
                        "development" if argv==("branch","--show-current") else "","")
                    action(args)
                command.assert_not_called()
                self.assertEqual(snapshot(),before)
                self.assertFalse(Path(self.fx.db).exists())
        self.fx.conn = app.connect(str(Path(self.fx.root)/"saved-ledger.db"))

    def test_wave_closeout_qualifies_owned_gid_in_both_orders_and_foreign_only(self):
        owned_gid = self.fx.gid
        self.start()
        self.fx.conn.execute("INSERT INTO repos(global_id,slug,updated_at) VALUES(?,?,?)",
                             (app.new_gid("repo-"),"foreign/project",app.now_iso()))
        foreign = self.fx.row(owned_gid)
        foreign.pop("id")
        foreign.update(global_id=app.new_gid("rmi-"),repo_id=2,
                       issue_url="https://github.com/foreign/project/issues/646")
        self.fx.conn.execute("INSERT INTO roadmap_items(%s) VALUES(%s)" %
                             (','.join(foreign),','.join('?' for _ in foreign)),tuple(foreign.values()))
        foreign_gid = foreign["global_id"]
        destination = "PROJECT/3-COMPLETED/GH-646-fixture.md"
        Path(self.fx.root,destination).parent.mkdir(parents=True)
        Path(self.fx.root,destination).write_text("# completed fixture\n")
        source = Path(__file__).resolve().parents[1]
        original_write = wave.ledger_write
        for foreign_first in (False,True):
            self.fx.conn.execute("UPDATE roadmap_items SET id=? WHERE global_id=?",
                                 (20 if foreign_first else 1,owned_gid))
            self.fx.conn.execute("UPDATE roadmap_items SET id=? WHERE global_id=?",
                                 (10 if foreign_first else 30,foreign_gid))
            self.fx.conn.execute("UPDATE roadmap_items SET section='In progress',status_marker='🚧',"
                                 "status_label='in-progress',doc_path='PROJECT/fixture.md' WHERE global_id=?",(owned_gid,))
            before_foreign = self.fx.row(foreign_gid)
            with mock.patch.object(wave,"github_slug_from_origin",return_value="owner/project"), \
                    mock.patch.object(wave,"harness_tool",side_effect=lambda root,path: str(source/path)), \
                    mock.patch.object(wave,"ledger_write",wraps=original_write) as writer, \
                    contextlib.redirect_stdout(io.StringIO()):
                self.assertTrue(wave.update_roadmap_entry(self.fx.root,646,"a"*40,"2026-09-16",doc_path=destination))
            self.assertEqual(writer.call_count,2)
            for call in writer.call_args_list:
                self.assertIn(owned_gid,call.args[1]); self.assertNotIn("--issue-num",call.args[1])
            self.assertEqual(self.fx.row(owned_gid)["section"],"Completed")
            self.assertIsNone(self.fx.row(owned_gid)["status_label"])
            self.assertEqual(self.fx.row(owned_gid)["doc_path"],destination)
            self.assertEqual(self.fx.row(foreign_gid),before_foreign)
        self.fx.conn.execute("DELETE FROM roadmap_items WHERE global_id=?",(owned_gid,))
        before_foreign = self.fx.row(foreign_gid)
        with mock.patch.object(wave,"github_slug_from_origin",return_value="owner/project"), \
                mock.patch.object(wave,"ledger_write") as writer, contextlib.redirect_stdout(io.StringIO()):
            self.assertFalse(wave.update_roadmap_entry(self.fx.root,646,"a"*40,"2026-09-16"))
        writer.assert_not_called()
        self.assertEqual(self.fx.row(foreign_gid),before_foreign)

    def test_wave_foreign_only_row_cannot_be_completed_by_root_issue_number(self):
        self.start()
        gid = self.fx.gid
        self.fx.conn.execute("UPDATE repos SET slug='foreign/project'")
        self.fx.conn.execute("UPDATE roadmap_items SET issue_url='https://github.com/foreign/project/issues/646'")
        before = self.fx.row(gid)
        generation = app.get_generation(self.fx.conn)
        source = Path(__file__).resolve().parents[1]
        with mock.patch.object(wave,"github_slug_from_origin",return_value="owner/project"), \
                mock.patch.object(wave,"harness_tool",side_effect=lambda root,path: str(source/path)), \
                contextlib.redirect_stdout(io.StringIO()):
            self.assertFalse(wave.update_roadmap_entry(self.fx.root,646,"a"*40,"2026-09-16"))
        self.assertEqual(self.fx.row(gid),before)
        self.assertEqual(app.get_generation(self.fx.conn),generation)

    def test_express_admission_dry_refusal_has_no_filesystem_writes(self):
        args = argparse.Namespace(root=self.fx.root, repo="owner/project", issue=646,
                                  dry_run=True, _expect_driver=set(), release=None)
        with tempfile.TemporaryDirectory(prefix="gh646-telemetry-") as home:
            for absent in (False, True):
                if absent:
                    args.issue = 999
                else:
                    self.fx.conn.execute("UPDATE repos SET slug='foreign/project'")
                def snapshot():
                    return {str(p): p.read_bytes() if p.is_file() else None
                            for root in (Path(home),Path(self.fx.root)) for p in root.rglob('*')}
                before = snapshot()
                with mock.patch.dict(os.environ,{"HOME":home}), \
                        mock.patch.object(express,"qualify_root_repository"), \
                        mock.patch.object(express,"cmd_check",return_value={"suite":"test/fixture.sh","paths":[]}), \
                        mock.patch.object(express,"run_releases") as command, self.assertRaises(SystemExit):
                    express.cmd_land(args)
                command.assert_not_called()
                after = snapshot()
                self.assertEqual(set(after),set(before))
                self.assertEqual(after,before)

    def test_express_resume_committed_receipt_cannot_authorize_foreign_repo(self):
        root = self.fx.root
        (Path(root)/".gitignore").write_text(".tick/\n")
        express.git(root,"branch","-M","development")
        self.fx.conn.execute("INSERT INTO repos(global_id,slug,updated_at) VALUES(?,?,?)",
                             (app.new_gid("repo-"),"foreign/project",app.now_iso()))
        foreign = self.fx.row()
        foreign.pop("id")
        foreign.update(global_id=app.new_gid("rmi-"),repo_id=2,
                       issue_url="https://github.com/foreign/project/issues/646")
        self.fx.conn.execute("INSERT INTO roadmap_items(%s) VALUES(%s)" %
                             (','.join(foreign),','.join('?' for _ in foreign)),tuple(foreign.values()))
        for key,value in (("user.name","fixture"),("user.email","fixture@example.test")):
            express.git(root,"config",key,value)
        express.git(root,"add",".")
        express.git(root,"commit","-qm","fix: fixture\n\nCloses #646")
        sha = express.git(root,"rev-parse","HEAD").stdout.strip()
        express.write_receipt(root,sha,646,"test/fixture.sh",0)
        express.git(root,"add",".")
        express.git(root,"commit","-qm","fixture: real legacy receipt")
        self.assertTrue(express.find_committed_receipt(root,sha,646,"test/fixture.sh"))
        args = argparse.Namespace(root=root,repo="foreign/project",issue=646,sha=sha,
                                  suite="test/fixture.sh",dry_run=False,release=None)
        repo = subprocess.CompletedProcess([],0,json.dumps({"nameWithOwner":"owner/project"}),"")
        original = subprocess.run
        with tempfile.TemporaryDirectory(prefix="gh646-telemetry-") as home, \
                mock.patch.dict(os.environ,{"HOME":home,"GH_REPO":"foreign/project"}), \
                mock.patch.object(express,"resolve_landing_commit",return_value=sha), \
                mock.patch.object(express.subprocess,"run",wraps=subprocess.run) as process, \
                mock.patch.object(express,"gh",return_value=subprocess.CompletedProcess([],0,
                    json.dumps({"state":"OPEN"}),"")) as remote, \
                mock.patch.object(express,"active_release",return_value=None), \
                mock.patch.object(express,"persist_closeout",return_value=False), \
                mock.patch.object(express,"run_releases") as command, \
                mock.patch.object(express,"reconcile_gated") as reconcile:
            def run(argv,**kw):
                if argv[:2] == ["gh","repo"]:
                    self.assertEqual(kw["cwd"],root)
                    self.assertNotIn("GH_REPO",kw["env"])
                    return repo
                return original(argv,**kw)
            process.side_effect = run
            with self.assertRaises(SystemExit):
                express.cmd_resume(args)
            remote.assert_not_called(); command.assert_not_called(); reconcile.assert_not_called()
            args.dry_run = True
            with self.assertRaises(SystemExit):
                express.cmd_resume(args)
            args.repo = "owner/project"
            with mock.patch.object(app,"read_native_issue",self.native.read), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(express.cmd_resume(args)["sha"],sha)
            remote.assert_not_called(); command.assert_not_called(); reconcile.assert_not_called()
        self.assertIsNone(self.fx.row()["status_label"])

    def test_label_readback_mismatch_and_definition_permission_refuse(self):
        self.start()
        batch = self.fx.batch()
        self.native.fail_readback = True
        with self.native.patched(), self.assertRaisesRegex(RuntimeError,"readback failed"):
            labels.run(batch)
        self.native.fail_readback = False
        self.native.issue()["labels"] = [{"name":"unrelated"}]
        self.native.mutations.clear()
        forbidden = subprocess.CompletedProcess([],1,"HTTP/2.0 403 Forbidden\n\n{}","fixture denied")
        with self.native.patched(), mock.patch.object(labels.subprocess,"run",return_value=forbidden), \
                self.assertRaisesRegex(RuntimeError,"definition lookup failed"):
            labels.run(batch)
        self.assertEqual(self.native.mutations,[])

    def test_admission_rejects_combined_fields_and_closed_native(self):
        with self.assertRaises(SystemExit):
            self.start(raw_text="- **GH-646 · unrelated**")
        self.native.issue()["state"] = "closed"
        with self.assertRaises(SystemExit):
            self.start()
        self.assertIsNone(self.fx.row()["status_label"])

    def test_corrupt_label_and_future_authority_refuse(self):
        self.start()
        batch = self.fx.batch()
        batch["events"][-1]["current"]["latest_lifecycle"]["at"] = "2099-01-01T00:00:00Z"
        with self.assertRaisesRegex(ValueError,"timestamp unavailable or future"):
            self.project(batch)
        self.assertEqual(self.native.mutations,[])
        self.fx.conn.execute("PRAGMA ignore_check_constraints=ON")
        self.fx.conn.execute("UPDATE roadmap_items SET status_label='unexpected'")
        with self.assertRaisesRegex(ValueError,"identity/label"):
            self.project()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mutant", choices=("metadata", "terminal", "identity", "cursor", "appearance"))
    opts, extra = parser.parse_known_args()
    # Each optional isolated-process mutant must turn its named falsifiable assertion red.
    target = None
    if opts.mutant in ("metadata", "terminal", "appearance"):
        original = app._sync_status_labels
        def broken(conn, before, op, gid, accepted_start=False):
            original(conn, before, op, gid, accepted_start)
            if opts.mutant in ("metadata", "appearance"):
                conn.execute("UPDATE roadmap_items SET status_label='in-progress' WHERE section='In progress'")
            else:
                for row_gid, row in before.items():
                    current = conn.execute("SELECT section,status_marker FROM roadmap_items WHERE global_id=?",
                                           (row_gid,)).fetchone()
                    if app._live_roadmap_event(current["section"],current["status_marker"],False) in ("completed","deferred"):
                        conn.execute("UPDATE roadmap_items SET status_label=? WHERE global_id=?",
                                     (row["status_label"], row_gid))
        app._sync_status_labels = broken
        target = ({"metadata": "test_migration_metadata_never_establishes_label",
                   "appearance": "test_ordinary_active_appearance_never_establishes_label",
                   "terminal": "test_terminal_precedence_and_nonempty_lifecycle_loop"}[opts.mutant])
    elif opts.mutant == "identity":
        original = app.resolve_roadmap_identity
        def broken(row, repos, origin=None):
            result = original(row, repos, origin)
            result.update(identity_valid=True, repo=app._repo_from_issue_url(row["issue_url"])[0])
            return result
        app.resolve_roadmap_identity = broken
        target = "test_owned_identity_and_pr_refusal"
    elif opts.mutant == "cursor":
        original = connectors._persist
        def broken(path, results, at):
            return original(path, {name: (advance if advance is not None else 999, None)
                                   for name,(advance,error) in results.items()}, at)
        connectors._persist = broken
        target = "test_failed_removal_reopen_replay_and_cursor_retention"
    suite = (unittest.defaultTestLoader.loadTestsFromName("StatusLabelTests." + target, sys.modules[__name__])
             if target else unittest.defaultTestLoader.loadTestsFromTestCase(StatusLabelTests))
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    sys.exit(main())
