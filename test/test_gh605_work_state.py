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


if __name__ == "__main__":
    unittest.main()
