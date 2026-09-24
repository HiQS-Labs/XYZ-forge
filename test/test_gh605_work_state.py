import datetime as dt
import contextlib
import io
import json
import os
from pathlib import Path
import shutil
import sqlite3
import sys
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "utils" / "py"))
import releases_app as app


class ClassifierTests(unittest.TestCase):
    def test_section_precedence_and_queue(self):
        cases = [
            ("Completed", "🚧", False, "completed"),
            (" Deferred · vision ", "🚧", False, "deferred"),
            ("In progress", "", False, "in_flight"),
            ("Queue / parked intake", "", True, "rated"),
            ("Queue / parked intake", "", False, "parked"),
        ]
        self.assertTrue(cases)
        for section, marker, rated, expected in cases:
            self.assertEqual(app._live_roadmap_event(section, marker, rated), expected)

    def test_metadata_update_is_informational_but_section_change_transitions(self):
        conn = sqlite3.connect(":memory:")
        conn.row_factory = sqlite3.Row
        conn.execute("""CREATE TABLE roadmap_items(global_id TEXT,gh_number INTEGER,
                     repo_id INTEGER,
                     status_marker TEXT,section TEXT,rating_pri INTEGER,rating_sev INTEGER,
                     rating_appeal INTEGER,rating_effort INTEGER)""")
        conn.execute("INSERT INTO roadmap_items VALUES('g',1,7,'🚧','In progress',1,1,1,1)")
        current = conn.execute("SELECT * FROM roadmap_items").fetchone()
        event = app._extract_roadmap_update(conn, "roadmap-update", "g", current)
        self.assertEqual(event[0], "updated")
        self.assertFalse(event[2]["transition"])
        conn.execute("UPDATE roadmap_items SET section='Completed'")
        event = app._extract_roadmap_update(conn, "roadmap-update", "g", current)
        self.assertEqual(event[0], "completed")
        self.assertTrue(event[2]["transition"])
        self.assertEqual(event[3], 7)
        conn.close()


class EvidenceTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="gh605-state-")
        self.root = Path(self.tmp.name)
        (self.root / ".git").mkdir()
        self.db = self.root / "releases.db"
        conn = sqlite3.connect(self.db)
        conn.executescript("""
          CREATE TABLE schema_migrations(version INTEGER PRIMARY KEY, applied_at TEXT);
          INSERT INTO schema_migrations VALUES(8,'2026-09-13T00:00:00Z');
          CREATE TABLE settings(key TEXT PRIMARY KEY,value TEXT); INSERT INTO settings VALUES('generation','9');
          CREATE TABLE repos(id INTEGER PRIMARY KEY,slug TEXT); INSERT INTO repos VALUES(1,'HiQS-Labs/XYZ-forge');
          CREATE TABLE roadmap_items(global_id TEXT,repo_id INTEGER,gh_number INTEGER,issue_url TEXT,section TEXT,
            status_marker TEXT,rating_pri INTEGER,rating_sev INTEGER,rating_appeal INTEGER,
            rating_effort INTEGER,rating_ovr INTEGER);
          CREATE TABLE work_events(id INTEGER PRIMARY KEY,repo_id INTEGER,gh_number INTEGER,event TEXT,payload TEXT,at TEXT);
          CREATE TABLE connector_cursors(connector TEXT,last_event_id INTEGER,last_attempt_at TEXT,last_error TEXT,updated_at TEXT);
          CREATE TABLE jog_queue(id INTEGER PRIMARY KEY,repo_id INTEGER,gh_number INTEGER,status TEXT);
        """)
        conn.execute("INSERT INTO roadmap_items VALUES(?,?,?,?,?,?,?,?,?,?,?)",
                     ("rmi-a", 1, 1, "https://github.com/HiQS-Labs/XYZ-forge/issues/1",
                      "In progress", "🚧", 80, 70, 60, 50, None))
        conn.commit()
        conn.close()

    def tearDown(self):
        self.tmp.cleanup()

    def add_event(self, event, payload, at, event_id=None, repo_id=1):
        conn = sqlite3.connect(self.db)
        conn.execute("INSERT INTO work_events(id,repo_id,gh_number,event,payload,at) VALUES(?,?,?,?,?,?)",
                     (event_id, repo_id, 1, event, json.dumps(payload) if payload is not None else None, at))
        conn.commit()
        conn.close()

    def test_legacy_metadata_start_is_unknown(self):
        self.add_event("in_flight", {"marker": "🚧"}, "2026-09-12T12:00:00Z")
        report = app.load_work_evidence(self.db, as_of="2026-09-13T12:00:00Z")
        self.assertTrue(report["issues"])
        self.assertIsNone(report["issues"][0]["recent_start"])
        self.assertEqual(report["issues"][0]["activity"], "unknown")

    def test_tagged_transition_qualifies_until_superseded(self):
        self.add_event("in_flight", {"source": "roadmap-update", "transition": True},
                       "2026-09-12T12:00:00Z", 1)
        report = app.load_work_evidence(self.db, as_of="2026-09-13T12:00:00Z")
        self.assertEqual(report["issues"][0]["activity"], "recent")
        self.add_event("rated", {"source": "roadmap-update", "transition": True},
                       "2026-09-13T00:00:00Z", 2)
        report = app.load_work_evidence(self.db, as_of="2026-09-13T12:00:00Z")
        self.assertIsNone(report["issues"][0]["recent_start"])

    def test_backfill_rerating_and_metadata_do_not_supersede_a_real_start(self):
        self.add_event("in_flight", {"source": "roadmap-update", "transition": True},
                       "2026-09-12T12:00:00Z", 1)
        for event, payload in (
            ("in_flight", {"source": "backfill", "transition": True}),
            ("rated", {"rated": "90/80/70/60"}),
            ("updated", {"source": "roadmap-update", "transition": False}),
        ):
            self.add_event(event, payload, "2026-09-13T00:00:00Z")
            report = app.load_work_evidence(self.db, as_of="2026-09-13T12:00:00Z")
            self.assertEqual(report["issues"][0]["activity"], "recent")
            self.assertEqual(report["issues"][0]["latest_event"]["event"], event)

    def test_mismatched_issue_url_cannot_supply_activity(self):
        conn = sqlite3.connect(self.db)
        conn.execute("UPDATE roadmap_items SET issue_url=?",
                     ("https://github.com/HiQS-Labs/XYZ-forge/issues/99",))
        conn.commit(); conn.close()
        self.add_event("in_flight", {"source": "roadmap-update", "transition": True},
                       "2026-09-12T12:00:00Z")
        report = app.load_work_evidence(self.db, as_of="2026-09-13T12:00:00Z")
        self.assertFalse(report["issues"][0]["identity_valid"])
        self.assertIsNone(report["issues"][0]["recent_start"])

    def test_future_and_malformed_times_are_unknown(self):
        for at in ("not-a-time", "2026-09-14T00:00:00Z"):
            conn = sqlite3.connect(self.db)
            conn.execute("DELETE FROM work_events")
            conn.commit(); conn.close()
            self.add_event("in_flight", {"source": "roadmap-update", "transition": True}, at)
            report = app.load_work_evidence(self.db, as_of="2026-09-13T12:00:00Z")
            self.assertEqual(report["issues"][0]["activity"], "unknown")

    def test_backfill_never_qualifies_as_a_start(self):
        for event in ("in_flight", "jog_running", "jog_leased"):
            conn = sqlite3.connect(self.db)
            conn.execute("DELETE FROM work_events")
            conn.execute("DELETE FROM jog_queue")
            conn.execute("INSERT INTO jog_queue(repo_id,gh_number,status) VALUES(1,1,'running')")
            conn.commit(); conn.close()
            self.add_event(event, {"source": "backfill", "transition": True},
                           "2026-09-12T12:00:00Z")
            report = app.load_work_evidence(self.db, as_of="2026-09-13T12:00:00Z")
            self.assertEqual(report["issues"][0]["activity"], "unknown")

    def test_jog_running_and_leased_require_one_consistent_current_row(self):
        for event, status in (("jog_running", "running"), ("jog_leased", "leased")):
            conn = sqlite3.connect(self.db)
            conn.execute("DELETE FROM work_events")
            conn.execute("DELETE FROM jog_queue")
            conn.execute("INSERT INTO jog_queue(repo_id,gh_number,status) VALUES(1,1,?)", (status,))
            conn.commit(); conn.close()
            self.add_event(event, {"source": "jog", "transition": True},
                           "2026-09-12T12:00:00Z")
            report = app.load_work_evidence(self.db, as_of="2026-09-13T12:00:00Z")
            self.assertEqual(report["issues"][0]["activity"], "recent")
        conn = sqlite3.connect(self.db)
        conn.execute("INSERT INTO jog_queue(repo_id,gh_number,status) VALUES(1,1,'running')")
        conn.commit(); conn.close()
        report = app.load_work_evidence(self.db, as_of="2026-09-13T12:00:00Z")
        self.assertEqual(report["issues"][0]["activity"], "unknown")
        self.assertTrue(any("ambiguous multiple jog rows" in w for w in report["warnings"]))

    def test_roadmap_repo_id_cannot_borrow_a_matching_other_repo(self):
        conn = sqlite3.connect(self.db)
        conn.execute("INSERT INTO repos VALUES(2,'Other-Owner/XYZ-forge')")
        conn.execute("UPDATE roadmap_items SET repo_id=2")
        conn.commit(); conn.close()
        self.add_event("in_flight", {"source": "roadmap-update", "transition": True},
                       "2026-09-12T12:00:00Z", repo_id=1)
        report = app.load_work_evidence(self.db, as_of="2026-09-13T12:00:00Z")
        self.assertFalse(report["issues"][0]["identity_valid"])
        self.assertIsNone(report["issues"][0]["recent_start"])

    def test_read_only_uri_handles_space_hash_and_question_mark(self):
        odd_dir = self.root / "space # question ?"
        odd_dir.mkdir()
        (odd_dir / ".git").mkdir()
        odd_db = odd_dir / "releases #?.db"
        shutil.copy2(self.db, odd_db)
        report = app.load_work_evidence(odd_db, as_of="2026-09-13T12:00:00Z")
        self.assertTrue(report["schema_ready"])
        self.assertEqual(len(report["issues"]), 1)

    def test_unsupported_root_returns_structured_unready(self):
        unsupported = self.root / "unsupported"
        unsupported.mkdir()
        unsupported_db = unsupported / "releases.db"
        shutil.copy2(self.db, unsupported_db)
        report = app.load_work_evidence(unsupported_db, as_of="2026-09-13T12:00:00Z")
        self.assertFalse(report["schema_ready"])
        self.assertIn("unsupported ledger root", report["error"])

    def test_sidecar_refuses_before_open(self):
        (Path(str(self.db) + "-wal")).write_bytes(b"nonempty")
        report = app.load_work_evidence(self.db, as_of="2026-09-13T12:00:00Z")
        self.assertFalse(report["schema_ready"])
        self.assertIn("ambiguous", report["error"])

    def test_schema_seven_reports_unready_without_writing(self):
        old = self.root / "old.db"
        conn = sqlite3.connect(old)
        conn.execute("CREATE TABLE schema_migrations(version INTEGER PRIMARY KEY,applied_at TEXT)")
        conn.execute("INSERT INTO schema_migrations VALUES(7,'2026-09-01T00:00:00Z')")
        conn.commit(); conn.close()
        before = old.read_bytes()
        report = app.load_work_evidence(old, as_of="2026-09-13T12:00:00Z")
        self.assertFalse(report["schema_ready"])
        self.assertEqual(report["schema_version"], 7)
        self.assertEqual(old.read_bytes(), before)

    def test_wal_header_without_sidecars_refuses_before_open_for_schema_seven_and_eight(self):
        for version in (7, 8):
            wal_db = self.root / ("wal-%s.db" % version)
            if version == 8:
                shutil.copy2(self.db, wal_db)
                conn = sqlite3.connect(wal_db)
            else:
                conn = sqlite3.connect(wal_db)
                conn.execute("CREATE TABLE schema_migrations(version INTEGER PRIMARY KEY,applied_at TEXT)")
                conn.execute("INSERT INTO schema_migrations VALUES(7,'2026-09-01T00:00:00Z')")
                conn.commit()
            self.assertEqual(conn.execute("PRAGMA journal_mode=WAL").fetchone()[0].lower(), "wal")
            conn.execute("PRAGMA wal_checkpoint(TRUNCATE)")
            conn.close()
            # Some SQLite builds retain empty sidecars after close. Remove them to
            # construct the header-without-sidecars input this test is about.
            for suffix in ("-wal", "-shm"):
                Path(str(wal_db) + suffix).unlink(missing_ok=True)
            for suffix in ("-wal", "-shm"):
                self.assertFalse(Path(str(wal_db) + suffix).exists())
            before = wal_db.read_bytes()
            report = app.load_work_evidence(wal_db, as_of="2026-09-13T12:00:00Z")
            self.assertFalse(report["schema_ready"])
            self.assertIn("header uses WAL", report["error"])
            self.assertEqual(wal_db.read_bytes(), before)
            self.assertFalse(Path(str(wal_db) + "-wal").exists())
            self.assertFalse(Path(str(wal_db) + "-shm").exists())

    def test_schema_eight_status_preserves_db_dump_config_and_sidecars(self):
        dump = self.root / "releases.sql"
        config = self.root / "device.json"
        dump.write_bytes(b"nonempty logical dump\n")
        config.write_bytes(b'{"work_connectors": {}}\n')
        before = {p.name: p.read_bytes() for p in (self.db, dump, config)}
        before_names = sorted(p.name for p in self.root.iterdir())
        report = app.load_work_evidence(self.db, as_of="2026-09-13T12:00:00Z")
        self.assertTrue(report["schema_ready"])
        self.assertEqual({p.name: p.read_bytes() for p in (self.db, dump, config)}, before)
        self.assertEqual(sorted(p.name for p in self.root.iterdir()), before_names)


class MultiRepositoryWriteTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="gh605-multi-repo-")
        self.root = Path(self.tmp.name)
        (self.root / ".git").mkdir()
        with contextlib.redirect_stdout(io.StringIO()):
            app.main(["--root", str(self.root), "init", "--slug", "owner/repo-a"])
        self.gid_a = app.new_gid("rmi-")
        self.gid_b = app.new_gid("rmi-")
        conn = sqlite3.connect(self.root / "releases.db")
        repo_a = conn.execute("SELECT id FROM repos WHERE slug='owner/repo-a'").fetchone()[0]
        repo_gid_b = app.new_gid("repo-")
        cols = {row[1] for row in conn.execute("PRAGMA table_info(repos)")}
        if "updated_at" in cols:
            conn.execute("INSERT INTO repos(global_id,slug,updated_at) VALUES(?,?,?)",
                         (repo_gid_b, "owner/repo-b", app.now_iso()))
        else:
            conn.execute("INSERT INTO repos(global_id,slug) VALUES(?,?)",
                         (repo_gid_b, "owner/repo-b"))
        repo_b = conn.execute("SELECT id FROM repos WHERE slug='owner/repo-b'").fetchone()[0]
        now = app.now_iso()
        for gid, repo_id, slug in ((self.gid_a, repo_a, "owner/repo-a"),
                                   (self.gid_b, repo_b, "owner/repo-b")):
            conn.execute("""INSERT INTO roadmap_items(
                global_id,repo_id,gh_number,title,section,position,status_marker,doc_path,
                issue_url,raw_text,first_seen,updated_at)
                VALUES(?,?,?,?,?,?,?,?,?,?,?,?)""",
                (gid, repo_id, 77, "same number", "Queue / parked intake", 1, "",
                 "PROJECT/1-INBOX/GH-77.md", "https://github.com/%s/issues/77" % slug,
                 "- GH-77 same number", now, now))
        conn.commit()
        conn.close()

    def tearDown(self):
        self.tmp.cleanup()

    def _run_update(self, *argv):
        with mock.patch.object(app, "refresh_preview"), \
             mock.patch.object(app, "_dispatch_work_connectors"), \
             contextlib.redirect_stdout(io.StringIO()), \
             contextlib.redirect_stderr(io.StringIO()):
            return app.main(["--root", str(self.root), "roadmap", "update", *argv])

    def _run_roadmap(self, verb, *argv):
        with mock.patch.object(app, "refresh_preview"), \
             mock.patch.object(app, "_dispatch_work_connectors"), \
             contextlib.redirect_stdout(io.StringIO()), \
             contextlib.redirect_stderr(io.StringIO()):
            return app.main(["--root", str(self.root), "roadmap", verb, *argv])

    def test_gid_write_targets_repo_b_event_and_ambiguous_number_refuses(self):
        self._run_update("--gid", self.gid_b, "--section", "In progress")
        conn = sqlite3.connect(self.root / "releases.db")
        rows = dict(conn.execute("SELECT global_id,section FROM roadmap_items"))
        event = conn.execute("""SELECT r.slug,e.event FROM work_events e
                                JOIN repos r ON r.id=e.repo_id ORDER BY e.id DESC LIMIT 1""").fetchone()
        conn.close()
        self.assertEqual(rows[self.gid_a], "Queue / parked intake")
        self.assertEqual(rows[self.gid_b], "In progress")
        self.assertEqual(event, ("owner/repo-b", "in_flight"))

        with self.assertRaises(SystemExit):
            self._run_update("--issue-num", "77", "--status-marker", "🚧")
        conn = sqlite3.connect(self.root / "releases.db")
        after = dict(conn.execute("SELECT global_id,section FROM roadmap_items"))
        event_count = conn.execute("SELECT COUNT(*) FROM work_events").fetchone()[0]
        conn.close()
        self.assertEqual(after, rows)
        self.assertEqual(event_count, 1)

    def test_force_rerating_replaces_complete_score_and_override_token(self):
        conn = sqlite3.connect(self.root / "releases.db")
        conn.execute("""UPDATE roadmap_items SET raw_text=?,rating_pri=?,rating_sev=?,
                     rating_appeal=?,rating_effort=?,rating_ovr=? WHERE global_id=?""",
                     ("- GH-77 same number (rated 80/70/60/50 ovr 240)",
                      80, 70, 60, 50, 240, self.gid_b))
        conn.commit(); conn.close()

        self._run_roadmap("rate", "--gid", self.gid_b, "--rated", "10/20/30/40", "--force")
        conn = sqlite3.connect(self.root / "releases.db")
        raw, *stored = conn.execute(
            "SELECT raw_text,rating_pri,rating_sev,rating_appeal,rating_effort,rating_ovr "
            "FROM roadmap_items WHERE global_id=?", (self.gid_b,)).fetchone()
        conn.close()
        self.assertEqual(raw.count("rated "), 1)
        self.assertNotIn("ovr ", raw)
        parsed = app.parse_rating(raw, "same number")
        self.assertEqual(stored, [parsed[c] for c in app.RATING_COLUMNS])

        self._run_roadmap("rate", "--gid", self.gid_b, "--rated", "11/22/33/44",
                          "--ovr", "300", "--force")
        conn = sqlite3.connect(self.root / "releases.db")
        raw, *stored = conn.execute(
            "SELECT raw_text,rating_pri,rating_sev,rating_appeal,rating_effort,rating_ovr "
            "FROM roadmap_items WHERE global_id=?", (self.gid_b,)).fetchone()
        conn.close()
        self.assertEqual(raw.count("rated "), 1)
        self.assertEqual(raw.count("ovr "), 1)
        parsed = app.parse_rating(raw, "same number")
        self.assertEqual(stored, [parsed[c] for c in app.RATING_COLUMNS])

    def test_repoint_refuses_ambiguous_issue_number_without_mutation(self):
        conn = sqlite3.connect(self.root / "releases.db")
        before = dict(conn.execute("SELECT global_id,doc_path FROM roadmap_items"))
        conn.close()
        with self.assertRaises(SystemExit):
            self._run_roadmap("repoint", "--issue-num", "77", "--doc-path", "ignored.md")
        conn = sqlite3.connect(self.root / "releases.db")
        after = dict(conn.execute("SELECT global_id,doc_path FROM roadmap_items"))
        conn.close()
        self.assertEqual(after, before)


class JogLifecycleWriteTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="gh605-jog-writer-")
        self.root = Path(self.tmp.name)
        (self.root / ".git").mkdir()
        with contextlib.redirect_stdout(io.StringIO()):
            app.main(["--root", str(self.root), "init", "--slug", "owner/repo"])
        self.roadmap_gid = app.new_gid("rmi-")
        self.jog_gid = app.new_gid("jog-")
        conn = sqlite3.connect(self.root / "releases.db")
        repo_id = conn.execute("SELECT id FROM repos").fetchone()[0]
        now = app.now_iso()
        conn.execute("""INSERT INTO roadmap_items(
            global_id,repo_id,gh_number,title,section,position,status_marker,doc_path,
            issue_url,raw_text,first_seen,updated_at,rating_pri,rating_sev,
            rating_appeal,rating_effort)
            VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            (self.roadmap_gid, repo_id, 1, "jog item", "In progress", 1, "🚧",
             "PROJECT/2-WORKING/GH-1.md", "https://github.com/owner/repo/issues/1",
             "- GH-1 jog item", now, now, 80, 70, 60, 50))
        conn.execute("""INSERT INTO jog_queue(global_id,repo_id,gh_number,position,status,
                     created_at,updated_at,attempt_count,lease_pid,failure_reason)
                     VALUES(?,?,?,?,?,?,?,?,?,?)""",
                     (self.jog_gid, repo_id, 1, 1, "pending", now, now, 0, None, None))
        conn.commit(); conn.close()

    def tearDown(self):
        self.tmp.cleanup()

    def _writer(self, fn, *args):
        with mock.patch.object(app, "refresh_preview"), \
             mock.patch.object(app, "_dispatch_work_connectors"), \
             contextlib.redirect_stdout(io.StringIO()), \
             contextlib.redirect_stderr(io.StringIO()):
            return fn(*args)

    def _roadmap_start(self):
        self._writer(app.main, ["--root", str(self.root), "roadmap", "update",
                                "--gid", self.roadmap_gid, "--section",
                                "Queue / parked intake", "--status-marker", "🆕"])
        self._writer(app.main, ["--root", str(self.root), "roadmap", "update",
                                "--gid", self.roadmap_gid, "--section", "In progress",
                                "--status-marker", "🚧"])

    def _assert_unverified(self):
        as_of = (dt.datetime.now(dt.timezone.utc) + dt.timedelta(seconds=1)).isoformat()
        report = app.load_work_evidence(self.root / "releases.db", as_of=as_of)
        self.assertEqual(report["issues"][0]["activity"], "unknown")

    def test_actual_drop_retry_skip_and_readd_supersede_a_roadmap_start(self):
        self._roadmap_start()
        self._writer(app.main, ["--root", str(self.root), "jog", "drop", "GH-1",
                                "--reason", "test drop"])
        self._assert_unverified()
        self._writer(app.main, ["--root", str(self.root), "jog", "retry", "GH-1"])
        self._assert_unverified()
        self._writer(app.main, ["--root", str(self.root), "jog", "retry", "GH-1"])
        self._writer(app.main, ["--root", str(self.root), "jog", "skip", "GH-1",
                                "--reason", "test skip"])
        self._assert_unverified()
        self._writer(app.main, ["--root", str(self.root), "jog", "add", "GH-1"])
        self._assert_unverified()
        conn = sqlite3.connect(self.root / "releases.db")
        events = [row[0] for row in conn.execute(
            "SELECT event FROM work_events WHERE event LIKE 'jog_%' ORDER BY id")]
        conn.close()
        self.assertEqual(events, ["jog_dropped", "jog_pending", "jog_parked",
                                  "jog_pending"])

    def test_actual_clear_emits_one_owned_archived_event_per_changed_row(self):
        self._roadmap_start()
        conn = sqlite3.connect(self.root / "releases.db")
        repo_id = conn.execute("SELECT id FROM repos").fetchone()[0]
        now = app.now_iso()
        second_gid = app.new_gid("jog-")
        conn.execute("UPDATE jog_queue SET status='parked' WHERE global_id=?", (self.jog_gid,))
        conn.execute("""INSERT INTO jog_queue(global_id,repo_id,gh_number,position,status,
                     created_at,updated_at,attempt_count) VALUES(?,?,?,?,?,?,?,?)""",
                     (second_gid, repo_id, 2, 2, "failed", now, now, 1))
        conn.commit(); conn.close()
        self._writer(app.main, ["--root", str(self.root), "jog", "clear"])
        conn = sqlite3.connect(self.root / "releases.db")
        events = conn.execute(
            "SELECT repo_id,gh_number,event,payload FROM work_events "
            "WHERE event='jog_archived' ORDER BY id").fetchall()
        conn.close()
        self.assertEqual([(row[0], row[1], row[2]) for row in events],
                         [(repo_id, 1, "jog_archived"), (repo_id, 2, "jog_archived")])
        self.assertEqual({json.loads(row[3])["jog_global_id"] for row in events},
                         {self.jog_gid, second_gid})
        self._assert_unverified()

    def test_clear_batch_event_failure_rolls_back_rows_receipt_and_events(self):
        conn = sqlite3.connect(self.root / "releases.db")
        repo_id = conn.execute("SELECT id FROM repos").fetchone()[0]
        now = app.now_iso()
        conn.execute("UPDATE jog_queue SET status='parked' WHERE global_id=?", (self.jog_gid,))
        conn.execute("""INSERT INTO jog_queue(global_id,repo_id,gh_number,position,status,
                     created_at,updated_at,attempt_count) VALUES(?,?,?,?,?,?,?,?)""",
                     (app.new_gid("jog-"), repo_id, 2, 2, "failed", now, now, 1))
        conn.commit(); conn.close()
        original = app._record_work_event
        calls = 0

        def fail_second(*args, **kwargs):
            nonlocal calls
            calls += 1
            if calls == 2:
                raise RuntimeError("event insertion failed")
            return original(*args, **kwargs)

        with mock.patch.object(app, "_record_work_event", side_effect=fail_second):
            with self.assertRaisesRegex(RuntimeError, "event insertion failed"):
                self._writer(app.main, ["--root", str(self.root), "jog", "clear"])
        conn = sqlite3.connect(self.root / "releases.db")
        self.assertEqual([row[0] for row in conn.execute(
            "SELECT status FROM jog_queue ORDER BY id")], ["parked", "failed"])
        self.assertEqual(conn.execute(
            "SELECT COUNT(*) FROM op_receipts WHERE op='jog-clear'").fetchone()[0], 0)
        self.assertEqual(conn.execute("SELECT COUNT(*) FROM work_events").fetchone()[0], 0)
        conn.close()

    def test_actual_orphan_recovery_emits_pending_and_parked_transitions(self):
        self._roadmap_start()
        conn = sqlite3.connect(self.root / "releases.db")
        conn.execute("UPDATE jog_queue SET status='running',attempt_count=1,lease_pid=99999999")
        conn.commit(); conn.close()
        self._writer(app.jog_reconcile_orphan_leases, str(self.root))
        conn = sqlite3.connect(self.root / "releases.db")
        conn.execute("UPDATE jog_queue SET status='running',attempt_count=3,lease_pid=99999999")
        conn.commit(); conn.close()
        self._writer(app.jog_reconcile_orphan_leases, str(self.root))
        conn = sqlite3.connect(self.root / "releases.db")
        events = [row[0] for row in conn.execute(
            "SELECT event FROM work_events ORDER BY id")]
        conn.close()
        self.assertEqual(events[-2:], ["jog_pending", "jog_parked"])
        self._assert_unverified()

    def test_real_lease_and_all_terminal_statuses_emit_owned_lifecycle_events(self):
        self._writer(app.jog_acquire_lease, str(self.root), 1, 4242)
        conn = sqlite3.connect(self.root / "releases.db")
        receipt = conn.execute("SELECT txn_id,target_gid FROM op_receipts WHERE op='jog-lease'").fetchone()
        event = conn.execute("SELECT txn_id,repo_id,event,payload FROM work_events ORDER BY id DESC LIMIT 1").fetchone()
        repo_id = conn.execute("SELECT id FROM repos WHERE slug='owner/repo'").fetchone()[0]
        conn.close()
        self.assertEqual(receipt[1], "GH-1")
        self.assertEqual(event[:3], (receipt[0], repo_id, "in_flight"))
        self.assertEqual(json.loads(event[3])["jog_global_id"], self.jog_gid)

        for status in ("failed", "parked", "completed", "dropped", "archived"):
            self._writer(app.jog_set_status, str(self.root), 1, status, "test")
            conn = sqlite3.connect(self.root / "releases.db")
            latest = conn.execute("SELECT txn_id,event,repo_id,payload FROM work_events ORDER BY id DESC LIMIT 1").fetchone()
            status_receipt = conn.execute(
                "SELECT txn_id,target_gid FROM op_receipts WHERE op=? ORDER BY id DESC LIMIT 1",
                ("jog-%s" % status,)).fetchone()
            conn.close()
            self.assertEqual(latest[0], status_receipt[0])
            self.assertEqual(status_receipt[1], "GH-1")
            self.assertEqual(latest[1], "jog_%s" % status)
            self.assertEqual(latest[2], repo_id)
            self.assertEqual(json.loads(latest[3])["status"], status)
        as_of = (dt.datetime.now(dt.timezone.utc) + dt.timedelta(seconds=1)).isoformat()
        report = app.load_work_evidence(self.root / "releases.db", as_of=as_of)
        self.assertEqual(report["issues"][0]["latest_lifecycle"]["event"], "jog_archived")
        self.assertEqual(report["issues"][0]["activity"], "unknown")

    def test_real_lease_resolves_unique_queue_row_in_second_repository(self):
        conn = sqlite3.connect(self.root / "releases.db")
        now = app.now_iso()
        conn.execute("INSERT INTO repos(global_id,slug,updated_at) VALUES(?,?,?)",
                     (app.new_gid("repo-"), "owner/repo-b", now))
        repo_b = conn.execute(
            "SELECT id FROM repos WHERE slug='owner/repo-b'").fetchone()[0]
        conn.execute("UPDATE jog_queue SET repo_id=? WHERE global_id=?",
                     (repo_b, self.jog_gid))
        conn.commit(); conn.close()

        self._writer(app.jog_acquire_lease, str(self.root), 1, 4242)
        conn = sqlite3.connect(self.root / "releases.db")
        row = conn.execute(
            "SELECT repo_id,status,lease_pid FROM jog_queue WHERE global_id=?",
            (self.jog_gid,)).fetchone()
        receipt = conn.execute(
            "SELECT txn_id,target_gid FROM op_receipts WHERE op='jog-lease'").fetchone()
        event = conn.execute(
            "SELECT txn_id,repo_id,event,payload FROM work_events ORDER BY id DESC LIMIT 1"
        ).fetchone()
        conn.close()
        self.assertEqual(row, (repo_b, "running", 4242))
        self.assertEqual(receipt[1], "GH-1")
        self.assertEqual(event[:3], (receipt[0], repo_b, "in_flight"))
        self.assertEqual(json.loads(event[3])["jog_global_id"], self.jog_gid)

    def test_repeated_terminal_commands_compact_active_positions_only_once(self):
        conn = sqlite3.connect(self.root / "releases.db")
        repo_id = conn.execute("SELECT id FROM repos").fetchone()[0]
        now = app.now_iso()
        for number, position in ((2, 2), (3, 3)):
            conn.execute("""INSERT INTO jog_queue(global_id,repo_id,gh_number,position,status,
                         created_at,updated_at,attempt_count) VALUES(?,?,?,?,?,?,?,?)""",
                         (app.new_gid("jog-"), repo_id, number, position, "pending",
                          now, now, 0))
        conn.commit(); conn.close()

        def active_positions():
            check = sqlite3.connect(self.root / "releases.db")
            rows = check.execute(
                "SELECT gh_number,position FROM jog_queue "
                "WHERE status IN ('pending','running') ORDER BY position"
            ).fetchall()
            check.close()
            return rows

        drop = ["--root", str(self.root), "jog", "drop", "GH-1",
                "--reason", "test drop"]
        self._writer(app.main, drop)
        self.assertEqual(active_positions(), [(2, 1), (3, 2)])
        self._writer(app.main, drop)
        self.assertEqual(active_positions(), [(2, 1), (3, 2)])

        skip = ["--root", str(self.root), "jog", "skip", "GH-2",
                "--reason", "test skip"]
        self._writer(app.main, skip)
        self.assertEqual(active_positions(), [(3, 1)])
        self._writer(app.main, skip)
        self.assertEqual(active_positions(), [(3, 1)])

        conn = sqlite3.connect(self.root / "releases.db")
        conn.execute("""INSERT INTO jog_queue(global_id,repo_id,gh_number,position,status,
                     created_at,updated_at,attempt_count) VALUES(?,?,?,?,?,?,?,?)""",
                     (app.new_gid("jog-"), repo_id, 4, 2, "pending", now, now, 0))
        conn.commit(); conn.close()
        self._writer(app.jog_set_status, str(self.root), 3, "failed", "test")
        self.assertEqual(active_positions(), [(4, 1)])
        self._writer(app.jog_set_status, str(self.root), 3, "failed", "test again")
        self.assertEqual(active_positions(), [(4, 1)])
        self._writer(app.jog_set_status, str(self.root), 3, "archived", "test")
        self.assertEqual(active_positions(), [(4, 1)])

        conn = sqlite3.connect(self.root / "releases.db")
        events = [row[0] for row in conn.execute(
            "SELECT event FROM work_events WHERE gh_number IN (1,2,3) ORDER BY id")]
        conn.close()
        self.assertEqual(events.count("jog_dropped"), 1)
        self.assertEqual(events.count("jog_parked"), 1)
        self.assertEqual(events.count("jog_failed"), 1)

    def test_metadata_update_does_not_supersede_real_jog_start(self):
        self._writer(app.jog_acquire_lease, str(self.root), 1, 4242)
        self._writer(app.main, ["--root", str(self.root), "roadmap", "update",
                                "--gid", self.roadmap_gid, "--raw-text",
                                "- **GH-1 · jog item** metadata only"])
        as_of = (dt.datetime.now(dt.timezone.utc) + dt.timedelta(seconds=1)).isoformat()
        report = app.load_work_evidence(self.root / "releases.db",
                                        as_of=as_of)
        self.assertEqual(report["issues"][0]["activity"], "recent")
        self.assertEqual(report["issues"][0]["latest_event"]["event"], "updated")

    def test_ambiguous_same_number_jog_rows_refuse_and_roll_back(self):
        conn = sqlite3.connect(self.root / "releases.db")
        now = app.now_iso()
        repo_gid = app.new_gid("repo-")
        conn.execute("INSERT INTO repos(global_id,slug,updated_at) VALUES(?,?,?)",
                     (repo_gid, "other/repo", now))
        other_repo = conn.execute("SELECT id FROM repos WHERE slug='other/repo'").fetchone()[0]
        conn.execute("""INSERT INTO jog_queue(global_id,repo_id,gh_number,position,status,
                     created_at,updated_at,attempt_count) VALUES(?,?,?,?,?,?,?,?)""",
                     (app.new_gid("jog-"), other_repo, 1, 1, "pending", now, now, 0))
        conn.commit(); conn.close()
        with self.assertRaises(SystemExit):
            self._writer(app.jog_acquire_lease, str(self.root), 1, 4242)
        conn = sqlite3.connect(self.root / "releases.db")
        self.assertEqual(set(r[0] for r in conn.execute("SELECT status FROM jog_queue")), {"pending"})
        self.assertEqual(conn.execute("SELECT COUNT(*) FROM work_events").fetchone()[0], 0)
        conn.close()


if __name__ == "__main__":
    unittest.main()
