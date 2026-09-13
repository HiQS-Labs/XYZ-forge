import datetime as dt
import json
import os
from pathlib import Path
import sqlite3
import sys
import tempfile
import unittest


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
                     status_marker TEXT,section TEXT,rating_pri INTEGER,rating_sev INTEGER,
                     rating_appeal INTEGER,rating_effort INTEGER)""")
        conn.execute("INSERT INTO roadmap_items VALUES('g',1,'🚧','In progress',1,1,1,1)")
        current = conn.execute("SELECT * FROM roadmap_items").fetchone()
        event = app._extract_roadmap_update(conn, "roadmap-update", "g", current)
        self.assertEqual(event[0], "updated")
        self.assertFalse(event[2]["transition"])
        conn.execute("UPDATE roadmap_items SET section='Completed'")
        event = app._extract_roadmap_update(conn, "roadmap-update", "g", current)
        self.assertEqual(event[0], "completed")
        self.assertTrue(event[2]["transition"])
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
          CREATE TABLE roadmap_items(global_id TEXT,gh_number INTEGER,issue_url TEXT,section TEXT,
            status_marker TEXT,rating_pri INTEGER,rating_sev INTEGER,rating_appeal INTEGER,
            rating_effort INTEGER,rating_ovr INTEGER);
          CREATE TABLE work_events(id INTEGER PRIMARY KEY,repo_id INTEGER,gh_number INTEGER,event TEXT,payload TEXT,at TEXT);
          CREATE TABLE connector_cursors(connector TEXT,last_event_id INTEGER,last_attempt_at TEXT,last_error TEXT,updated_at TEXT);
        """)
        conn.execute("INSERT INTO roadmap_items VALUES(?,?,?,?,?,?,?,?,?,?)",
                     ("rmi-a", 1, "https://github.com/HiQS-Labs/XYZ-forge/issues/1",
                      "In progress", "🚧", 80, 70, 60, 50, None))
        conn.commit()
        conn.close()

    def tearDown(self):
        self.tmp.cleanup()

    def add_event(self, event, payload, at, event_id=None):
        conn = sqlite3.connect(self.db)
        conn.execute("INSERT INTO work_events(id,repo_id,gh_number,event,payload,at) VALUES(?,?,?,?,?,?)",
                     (event_id, 1, 1, event, json.dumps(payload) if payload is not None else None, at))
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
            self.add_event("jog_running", {"status": "running"}, at)
            report = app.load_work_evidence(self.db, as_of="2026-09-13T12:00:00Z")
            self.assertEqual(report["issues"][0]["activity"], "unknown")

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


if __name__ == "__main__":
    unittest.main()
