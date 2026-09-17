from __future__ import annotations

import json
import os
import sqlite3
import subprocess
import tempfile
import time
import unittest
from dataclasses import replace
from pathlib import Path
from unittest.mock import patch

from src.flightdeck.aggregate import FlightdeckAggregator
from src.flightdeck.connectors import native_item_identity, read_xyz_work, read_rebalance
from src.flightdeck.contract import ConnectorConfig, empty_batch
from src.flightdeck.manual_harness import write_fixtures, instant
from utils.py.releases_cycle import read_work_status

ROOT = Path(__file__).resolve().parents[2]
AS_OF = "2026-09-17T20:00:00Z"


def ledger(root, version=9):
    subprocess.run(["git", "init", "-q", str(root)], check=True)
    subprocess.run(["git", "-C", str(root), "remote", "add", "origin", "https://github.com/Example/Project.git"], check=True)
    cx = sqlite3.connect(root / "releases.db")
    cx.executescript("""
        CREATE TABLE schema_migrations(version INTEGER);
        CREATE TABLE settings(key TEXT,value TEXT);
        CREATE TABLE repos(id TEXT,slug TEXT);
        CREATE TABLE roadmap_items(global_id TEXT,repo_id TEXT,gh_number INTEGER,issue_url TEXT,section TEXT,status_marker TEXT,
            rating_pri INTEGER,rating_sev INTEGER,rating_appeal INTEGER,rating_effort INTEGER,rating_ovr INTEGER,status_label TEXT);
        CREATE TABLE work_events(id INTEGER,repo_id TEXT,gh_number INTEGER,event TEXT,payload TEXT,at TEXT);
        CREATE TABLE connector_cursors(connector TEXT,last_event_id INTEGER,last_attempt_at TEXT,last_error TEXT,updated_at TEXT);
        INSERT INTO settings VALUES('generation','7');
        INSERT INTO repos VALUES('r1','Example/Project');
    """)
    cx.execute("INSERT INTO schema_migrations VALUES(?)", (version,))
    for number in (1, 2):
        cx.execute("INSERT INTO roadmap_items VALUES(?,?,?,?,?,?,?,?,?,?,?,?)", (f"rmi{number}", "r1", number,
                   f"https://github.com/Example/Project/issues/{number}", "In progress", "🚧", 50, 50, 50, 50, None, "in-progress"))
        cx.execute("INSERT INTO work_events VALUES(?,?,?,?,?,?)", (number, "r1", number, "in_flight",
                   json.dumps({"source": "roadmap-update", "transition": True}), "2026-09-10T20:00:00Z"))
    cx.commit()
    cx.close()


class WorkStatusTests(unittest.TestCase):
    def test_native_wal_coordination_preserves_records_and_schema(self):
        from src.flightdeck.connectors import _sqlite_rows

        with tempfile.TemporaryDirectory() as tmp:
            config = write_fixtures(Path(tmp))
            cx = sqlite3.connect(config.rebalance_db)
            self.assertEqual(cx.execute("PRAGMA journal_mode=WAL").fetchone()[0], "wal")
            before_dump = tuple(cx.iterdump())
            self.assertGreater(cx.execute("SELECT COUNT(*) FROM github_items").fetchone()[0], 0)
            cx.close()
            before_bytes = config.rebalance_db.read_bytes()
            probes = []

            def guarded_rows(conn, sql, params=()):
                if not probes:
                    for statement in (
                        "UPDATE github_items SET state='closed'",
                        "DELETE FROM github_items",
                        "CREATE TABLE forbidden_reader_schema(value TEXT)",
                    ):
                        with self.assertRaises(sqlite3.OperationalError):
                            conn.execute(statement)
                        probes.append(statement)
                return _sqlite_rows(conn, sql, params)

            with patch("src.flightdeck.connectors._sqlite_rows", side_effect=guarded_rows):
                batch = read_rebalance(config, time.monotonic() + 2)
            self.assertGreater(len(batch["issues"]), 0)
            self.assertEqual(len(probes), 3)
            self.assertEqual(before_bytes, config.rebalance_db.read_bytes())
            cx = sqlite3.connect(f"{config.rebalance_db.resolve().as_uri()}?mode=ro", uri=True)
            try:
                self.assertEqual(before_dump, tuple(cx.iterdump()))
            finally:
                cx.close()
            # SQLite may create or change normal WAL/SHM coordination files.

    def test_descendants_are_stopped_even_when_parent_exits(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            script = root / "utils/py/releases_app.py"
            script.parent.mkdir(parents=True)
            (root / "releases.db").write_bytes(b"nonempty sentinel")
            for inherited in (True, False):
                pid_file = root / "child.pid"
                script.write_text("import subprocess,sys,pathlib\n"
                    "def load_work_evidence(path,as_of=None):\n"
                    f" p=subprocess.Popen([sys.executable,'-c','import time;time.sleep(10)'],stdout={'None' if inherited else 'subprocess.DEVNULL'})\n"
                    f" pathlib.Path({str(pid_file)!r}).write_text(str(p.pid))\n"
                    " return {'schema_ready':True,'issues':[{'number':1}]}\n")
                report = read_work_status(root, root, time.monotonic() + 0.3)
                self.assertEqual(report.get("error_code"), "reader-timeout" if inherited else None)
                pid = int(pid_file.read_text())
                for _ in range(100):
                    try:
                        os.kill(pid, 0)
                    except ProcessLookupError:
                        break
                    time.sleep(0.01)
                else:
                    self.fail("isolated reader descendant survived group cleanup")

    def test_final_root_errors_withhold_confirmation_in_both_orders(self):
        with tempfile.TemporaryDirectory() as tmp:
            a, b = (Path(tmp) / "a").resolve(), (Path(tmp) / "b").resolve()
            row = {"identity_valid": True, "repo": "Example/Project", "number": 1,
                   "status_label_supported": True, "status_label": "in-progress",
                   "recent_start": {"at": AS_OF, "event": "in_flight"}}
            good = {"schema_ready": True, "status_label_supported": True, "issues": [row]}
            bad_reports = [
                {"schema_ready": False, "error_code": "missing-source", "issues": []},
                {**good, "status_label_supported": False, "issues": []},
                {**good, "issues": [row] * 2001},
            ]
            for bad in bad_reports:
                for reverse in (False, True):
                    reports = {a: bad if reverse else good, b: good if reverse else bad}
                    config = ConnectorConfig(None, None, None, None, None, frozenset(), xyz_roots=(a, b))
                    with patch("src.flightdeck.connectors.read_work_status", side_effect=lambda _h, r, *_args: reports[r]):
                        batch = read_xyz_work(config, time.monotonic() + 1)
                    self.assertGreater(len(batch["issues"]), 0)
                    self.assertTrue(all(e["roots_complete"] is False for e in batch["issues"][0]["work_evidence"]))

    def test_unqualified_rows_are_issue_scoped_and_unknown_rows_counted(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            good = {"identity_valid": True, "repo": "Example/Project", "number": 2,
                    "status_label_supported": True, "status_label": "in-progress",
                    "recent_start": {"at": AS_OF, "event": "in_flight"}}
            invalid = {**good, "identity_valid": False, "number": 1}
            unresolved = {**invalid, "repo": None, "number": 3}
            config = ConnectorConfig(None, None, None, None, None, frozenset(), xyz_roots=(root,))
            batches = []
            for rows in ([good, invalid, unresolved], [unresolved, invalid, good]):
                report = {"schema_ready": True, "status_label_supported": True, "issues": rows}
                with patch("src.flightdeck.connectors.read_work_status", return_value=report), patch("src.flightdeck.connectors.utc_now", return_value=AS_OF):
                    batch = read_xyz_work(config, time.monotonic() + 1)
                self.assertEqual(batch["source"]["availability"], "ok")
                self.assertEqual(batch["source"]["roots"][0]["excluded_rows"], 1)
                by_number = {r["number"]: r["work_evidence"] for r in batch["issues"]}
                self.assertEqual(set(by_number), {1, 2})
                self.assertTrue(by_number[2][0]["roots_complete"])
                self.assertIsNone(by_number[2][0]["error"])
                marker = by_number[1][0]
                self.assertEqual(marker["error"], "unqualified-ledger-row")
                self.assertTrue(marker["roots_complete"])
                self.assertTrue(all(marker[k] is None for k in ("status_label", "start", "lifecycle")))
                batches.append(batch)
            self.assertEqual(batches[0], batches[1])

    def test_real_helper_null_url_and_canonical_duplicate_do_not_poison_peers(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            ledger(root)
            cx = sqlite3.connect(root / "releases.db")
            cx.execute("CREATE UNIQUE INDEX owned_issue ON roadmap_items(repo_id,gh_number)")
            cx.execute("INSERT INTO repos VALUES('r2','Project')")
            for gid, repo_id, number in (("legacy1", "r2", 1), ("historical3", "r1", 3)):
                cx.execute("INSERT INTO roadmap_items VALUES(?,?,?,NULL,'In progress','🚧',50,50,50,50,NULL,'in-progress')", (gid, repo_id, number))
            cx.execute("INSERT INTO work_events VALUES(3,'r1',3,'in_flight',?,?)", (json.dumps({"source": "roadmap-update", "transition": True}), AS_OF))
            cx.commit(); cx.close()
            before = (root / "releases.db").read_bytes()
            report = read_work_status(ROOT, root, time.monotonic() + 2, AS_OF)
            invalid = [r for r in report["issues"] if not r["identity_valid"]]
            self.assertEqual(len(invalid), 2)
            self.assertTrue(all(r["recent_start"] is None for r in invalid))
            config = ConnectorConfig(None, None, None, None, None, frozenset(), xyz_roots=(root,))
            batches = []
            for rows in (report["issues"], list(reversed(report["issues"]))):
                with patch("src.flightdeck.connectors.read_work_status", return_value={**report, "issues": rows}), patch("src.flightdeck.connectors.utc_now", return_value=AS_OF):
                    batches.append(read_xyz_work(config, time.monotonic() + 2))
            self.assertEqual(batches[0], batches[1])
            by_number = {r["number"]: r["work_evidence"] for r in batches[0]["issues"]}
            self.assertEqual(batches[0]["source"]["roots"][0]["excluded_rows"], 0)
            self.assertTrue(by_number[2][0]["roots_complete"])
            self.assertIsNone(by_number[2][0]["error"])
            self.assertEqual(sum(e["error"] == "unqualified-ledger-row" for e in by_number[1]), 1)
            self.assertEqual(by_number[3][0]["error"], "unqualified-ledger-row")
            self.assertTrue(all(e[k] is None for e in by_number[3] for k in ("status_label", "start", "lifecycle")))
            self.assertEqual(before, (root / "releases.db").read_bytes())

    def test_newest_native_case_variant_wins_before_quiet_lookup_cap(self):
        with tempfile.TemporaryDirectory() as tmp:
            config = write_fixtures(Path(tmp))
            cx = sqlite3.connect(config.rebalance_db)
            row = list(cx.execute("SELECT * FROM github_items WHERE number=440 AND item_type='issue'").fetchone())
            row[0] = row[0].upper()
            row[4] = "closed"
            # Update text is older, but the native observation is newer, and
            # its offset represents the same UTC instant as AS_OF.
            row[-2:] = ["2020-01-01T00:00:00Z", "2026-09-17T13:00:00-07:00"]
            cx.execute("INSERT INTO github_items VALUES(" + ",".join("?" for _ in row) + ")", row)
            cx.commit(); cx.close()
            config = replace(config, established_issues=(("github.com/binoidcbd/ltvera-pandas", 440),))
            batch = read_rebalance(config, time.monotonic() + 2)
            issue = next(row for row in batch["issues"] if row["number"] == 440)
            self.assertEqual(issue["state"], "closed")

    def test_uri_metacharacter_files_use_intended_readonly_database(self):
        with tempfile.TemporaryDirectory() as tmp:
            config = write_fixtures(Path(tmp))
            for name in ("cache#fragment.db", "cache?query.db"):
                intended = Path(tmp) / name
                intended.write_bytes(config.rebalance_db.read_bytes())
                before = intended.read_bytes()
                batch = read_rebalance(replace(config, rebalance_db=intended), time.monotonic() + 1)
                self.assertGreater(len(batch["issues"]), 0)
                self.assertEqual(before, intended.read_bytes())
                self.assertFalse((Path(tmp) / "cache").exists())
                self.assertFalse(any(Path(str(intended) + suffix).exists() for suffix in ("-wal", "-shm", "-journal")))

    def test_equal_time_contradictory_native_copies_remain_uncertain(self):
        with tempfile.TemporaryDirectory() as tmp:
            config = write_fixtures(Path(tmp))
            cx = sqlite3.connect(config.rebalance_db)
            row = list(cx.execute("SELECT * FROM github_items WHERE number=440 AND item_type='issue'").fetchone())
            row[0], row[4] = row[0].upper(), "closed"
            cx.execute("INSERT INTO github_items VALUES(" + ",".join("?" for _ in row) + ")", row)
            cx.commit(); cx.close()
            batch = read_rebalance(config, time.monotonic() + 1)
            issue = next(row for row in batch["issues"] if row["number"] == 440)
            self.assertTrue(issue["native_conflict"])

    def test_real_helper_reads_nonempty_schema9_without_mutation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            ledger(root)
            before = (root / "releases.db").read_bytes()
            report = read_work_status(ROOT, root, time.monotonic() + 2, AS_OF)
            self.assertTrue(report["schema_ready"], report)
            self.assertTrue(report["status_label_supported"])
            self.assertEqual(len(report["issues"]), 2)
            self.assertEqual(report["issues"][0]["recent_start"]["freshness"], "stale")
            self.assertEqual(report["generation"], 7)
            self.assertEqual(before, (root / "releases.db").read_bytes())
            self.assertFalse(any((root / f"releases.db{suffix}").exists() for suffix in ("-wal", "-shm", "-journal")))

    def test_schema8_missing_and_unsafe_state_are_not_inactive(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.assertEqual(read_work_status(ROOT, root, time.monotonic() + 1)["error_code"], "missing-source")
            ledger(root, 8)
            report = read_work_status(ROOT, root, time.monotonic() + 2, AS_OF)
            self.assertTrue(report["schema_ready"])
            self.assertFalse(report["status_label_supported"])
            self.assertIsNone(report["issues"][0]["status_label"])
            (root / ".git/releases-app-journal.json").write_text("{}")
            before = (root / "releases.db").read_bytes()
            report = read_work_status(ROOT, root, time.monotonic() + 2, AS_OF)
            self.assertFalse(report["schema_ready"])
            self.assertEqual(before, (root / "releases.db").read_bytes())

    def test_direct_entry_never_calls_main_config_or_writers(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            script = root / "utils/py/releases_app.py"
            script.parent.mkdir(parents=True)
            script.write_text("def main(): raise AssertionError('main/writer called')\n"
                              "def load_work_evidence(path,as_of=None): return {'schema_ready':True,'issues':[{'number':1}]}\n"
                              "if __name__ == '__main__': main()\n")
            (root / "releases.db").write_bytes(b"nonempty sentinel")
            self.assertEqual(read_work_status(root, root, time.monotonic() + 1)["issues"], [{"number": 1}])

    def test_output_and_time_are_enforced_during_execution(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            script = root / "utils/py/releases_app.py"
            script.parent.mkdir(parents=True)
            (root / "releases.db").write_bytes(b"nonempty sentinel")
            script.write_text("def load_work_evidence(path,as_of=None): return {'schema_ready':True,'issues':['x'*3000000]}\n")
            self.assertEqual(read_work_status(root, root, time.monotonic() + 1)["error_code"], "invalid-or-oversized-report")
            script.write_text("import time\ndef load_work_evidence(path,as_of=None): time.sleep(10)\n")
            began = time.monotonic()
            self.assertEqual(read_work_status(root, root, began + 0.15)["error_code"], "reader-timeout")
            self.assertLess(time.monotonic() - began, 0.5)

    def test_native_identity_cannot_borrow_host_owner_type_or_number(self):
        row = {"repo_full_name": "Example/Project", "item_type": "issue", "number": 7,
               "html_url": "https://github.com/Example/Project/issues/7"}
        self.assertTrue(native_item_identity(row))
        for url in ("https://evil.test/Example/Project/issues/7", "https://github.com/Other/Project/issues/7",
                    "https://github.com/Example/Project/pull/7", "https://github.com/Example/Project/issues/8"):
            self.assertFalse(native_item_identity({**row, "html_url": url}))

    def test_native_pre_cap_lookup_keeps_quiet_established_issue_and_bytes(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            config = write_fixtures(root)
            cx = sqlite3.connect(config.rebalance_db)
            for number in range(1000, 3101):
                cx.execute("INSERT INTO github_items VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)", (
                    "Other/Backlog", "issue", number, "New backlog", "open", 0, 0, None, None, None, None,
                    f"https://github.com/Other/Backlog/issues/{number}", instant(0), instant(0)))
            cx.commit(); cx.close()
            before = config.rebalance_db.read_bytes()
            config = replace(config, established_issues=(("github.com/binoidcbd/ltvera-pandas", 440),))
            batch = read_rebalance(config, time.monotonic() + 2)
            self.assertTrue(any(row["number"] == 440 for row in batch["issues"]))
            self.assertEqual(before, config.rebalance_db.read_bytes())
            with self.assertRaises(TimeoutError):
                read_rebalance(config, time.monotonic() - 1)

    def test_additive_merge_is_order_independent_and_keeps_duplicates(self):
        key = "github.com/example/project"
        native = empty_batch("rebalance", (), "ok")
        native["issues"] = [{"repo_id": key, "number": 1, "title": "Native title", "state": "closed",
                             "fetched_at": AS_OF, "source_ref": "rebalance"}]
        reports = []
        for label in (None, "in-progress"):
            batch = empty_batch("xyz_work", (), "ok")
            batch["issues"] = [{"repo_id": key, "number": 1, "source_ref": "xyz_work",
                                "work_evidence": [{"status_label": label}]}]
            reports.append(batch)
        config = ConnectorConfig(None, None, None, None, None, frozenset())
        values = []
        for batches in ([native, *reports], [*reversed(reports), native]):
            with patch("src.flightdeck.aggregate.read_connectors", return_value=batches):
                values.append(FlightdeckAggregator(config).snapshot()["repos"][0]["issues"][0])
        self.assertEqual(values[0], values[1])
        self.assertEqual(values[0]["title"], "Native title")
        self.assertEqual(len(values[0]["work_evidence"]), 2)

    def test_established_first_repository_and_detail_caps(self):
        batch = empty_batch("xyz_work", (), "ok")
        quiet = "github.com/example/quiet"
        batch["issues"] = [{"repo_id": f"github.com/example/backlog{n}", "number": n,
                            "updated_at": AS_OF} for n in range(1, 110)]
        batch["issues"].extend({"repo_id": quiet, "number": n, "updated_at": AS_OF} for n in range(1, 110))
        batch["issues"].append({"repo_id": quiet, "number": 999, "work_evidence": [
            {"status_label": "in-progress", "start": {"at": "2026-09-10T20:00:00Z"}}]})
        config = ConnectorConfig(None, None, None, None, None, frozenset())
        with patch("src.flightdeck.aggregate.read_connectors", return_value=[batch]):
            snapshot = FlightdeckAggregator(config).snapshot()
        self.assertEqual(snapshot["repos"][0]["id"], quiet)
        self.assertEqual(snapshot["repos"][0]["issues"][0]["number"], 999)
        self.assertTrue(snapshot["truncated"])
        self.assertEqual(snapshot["coverage"], "partial")

    def test_native_lock_is_bounded_and_sources_are_immutable(self):
        with tempfile.TemporaryDirectory() as tmp:
            config = write_fixtures(Path(tmp))
            cx = sqlite3.connect(config.rebalance_db)
            cx.execute("BEGIN EXCLUSIVE")
            began = time.monotonic()
            try:
                with self.assertRaises(sqlite3.OperationalError):
                    read_rebalance(config, began + 0.15)
                self.assertLess(time.monotonic() - began, 0.5)
            finally:
                cx.rollback(); cx.close()

    def test_native_expensive_query_is_interrupted_by_shared_deadline(self):
        with tempfile.TemporaryDirectory() as tmp:
            config = write_fixtures(Path(tmp))
            began = time.monotonic()
            def expensive(cx, _sql, _params=()):
                return [dict(row) for row in cx.execute("""
                    WITH RECURSIVE n(x) AS (VALUES(0) UNION ALL SELECT x+1 FROM n WHERE x<100000000)
                    SELECT SUM(x) AS total FROM n
                """)]
            with patch("src.flightdeck.connectors._sqlite_rows", side_effect=expensive):
                with self.assertRaises(sqlite3.OperationalError):
                    read_rebalance(config, began + 0.15)
            self.assertLess(time.monotonic() - began, 0.5)
