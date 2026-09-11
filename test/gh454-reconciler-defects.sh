#!/usr/bin/env bash
# GH-454: real timeline export and mode-aware PDDA gate through Reconciler.main.
# Git preflight alone is mocked: no git command, clone, network, or shared fixture setup.
# All generated files (including rollback snapshots) live under TMPDIR when supplied.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHONDONTWRITEBYTECODE=1 python3 - "$HERE/.." <<'PY'
import contextlib
import inspect
import io
import json
from pathlib import Path
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(sys.argv.pop()).resolve()
sys.path.insert(0, str(ROOT / "utils/py"))
import releases_app as ledger
import wave_reconcile as wave


class ReconcilerDefects(unittest.TestCase):
    def setUp(self):
        self.work = tempfile.TemporaryDirectory(prefix="gh454-")
        self.addCleanup(self.work.cleanup)
        self.root = Path(self.work.name)
        for directory in (".git", "utils/py", "utils/timeline", "utils/pdda"):
            (self.root / directory).mkdir(parents=True, exist_ok=True)
        for rel in ("utils/timeline/export_timeline.py", "utils/timeline/RELEASES.html",
                    "utils/py/releases_cycle.py", "utils/pdda/pdda-lib.sh"):
            shutil.copyfile(ROOT / rel, self.root / rel)
        # Unrelated sync/planning are stubs; exporter, validation, and rollback are real.
        (self.root / "utils/py/releases_app.py").write_text("pass\n")
        (self.root / "utils/marathon-plan.sh").write_text("exit 0\n")
        (self.root / "utils/pdda/pdda.sh").write_text('''\
unset PDDA_MODE PDDA_REPO_ROOT
source utils/pdda/pdda-lib.sh
echo 'ERROR [fixture] standing doc finding'
rc="$(pdda_gated_exit 1)"
if [ "$rc" = 0 ]; then
  echo "PDDA run complete: 1 error(s) found, not blocking in $PDDA_MODE mode"
fi
exit "$rc"
''')
        (self.root / ".pdda-mode").write_text("observe\n")
        self.preview = self.root / "RELEASES-PREVIEW.html"
        self.preview.write_text("adopted preview before reconcile\n")
        self.db = self.root / "releases.db"
        with contextlib.closing(sqlite3.connect(self.db)) as cx, cx:
            cx.executescript(ledger.MIGRATION_001 + ledger.MIGRATION_002_DDL)
            cx.execute("INSERT INTO repos VALUES (1, ?, 'fixture')", ("repo-" + "0" * 26,))
            for i, version, codename in ((1, None, None), (2, None, None),
                                         (3, None, "Night Owl"), (4, "1.2.3", None)):
                cx.execute("INSERT INTO issue_refs VALUES (?, ?, ?, NULL, '2026-09-08')",
                           (i, "ref-" + f"{i:026d}", f"https://github.com/example/test/issues/{i}"))
                cx.execute("""INSERT INTO releases
                    (id, global_id, repo_id, version, codename, status, description, tracking_ref_id)
                    VALUES (?, ?, 1, ?, ?, 'draft', 'Fixture release.', ?)""",
                           (i, "rel-" + f"{i:026d}", version, codename, i))
            self.assertEqual(cx.execute(
                "SELECT COUNT(*) FROM releases WHERE codename IS NULL AND version IS NULL"
            ).fetchone()[0], 2)

    def named_only(self):
        with contextlib.closing(sqlite3.connect(self.db)) as cx, cx:
            cx.execute("DELETE FROM releases WHERE id IN (1, 2)")

    def reconcile(self):
        out, err = io.StringIO(), io.StringIO()
        real_run = subprocess.run

        def no_git(cmd, *args, **kwargs):
            if Path(cmd[0]).name == "git":
                raise AssertionError("this regression must never execute git")
            return real_run(cmd, *args, **kwargs)

        argv = ["wave_reconcile.py", "--root", str(self.root), "--marathon", "gh454",
                "--skip-pull", "--skip-branch-check"]
        with mock.patch.object(sys, "argv", argv), \
                mock.patch.object(wave, "check_porcelain_cleanliness", return_value=""), \
                mock.patch.object(wave, "github_slug_from_origin", return_value="example/test"), \
                mock.patch.object(wave, "verify_rollback_completeness"), \
                mock.patch.object(subprocess, "run", side_effect=no_git), \
                contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            try:
                wave.main()
                code = 0
            except SystemExit as exc:
                code = exc.code
        return code, out.getvalue() + err.getvalue()

    def assert_completed(self, result):
        code, output = result
        self.assertEqual(code, 0, output)
        self.assertIn("Wave reconciliation completed successfully!", output)
        self.assertNotIn("Rolling back", output)
        self.assertIn('id="ledger-data"', self.preview.read_text())

    def test_unnamed_releases_export_and_reconcile(self):
        before = self.db.read_bytes()
        command = [sys.executable, str(self.root / "utils/timeline/export_timeline.py"),
                   "--db", str(self.db), "--json"]
        result = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.strip(), "export must be nonempty")
        columns = json.loads(result.stdout)["releases"]
        self.assertEqual(len(columns), 4)
        self.assertEqual({c["slug"] for c in columns},
                         {"unnamed-00000001", "unnamed-00000002", "night owl", "1.2.3"})
        self.assertEqual({c["id"] for c in columns},
                         {"c-unnamed-00000001", "c-unnamed-00000002", "c-night-owl", "c-1-2-3"})
        self.assertTrue(all(c["name"] for c in columns))
        self.assert_completed(self.reconcile())
        self.assertIn("unnamed-00000001", self.preview.read_text())
        self.assertEqual(self.db.read_bytes(), before, "export remains read-only")

    def test_observe_findings_complete(self):
        self.named_only()  # Prove gate behavior independently of the unnamed-release fix.
        gate = subprocess.run(["bash", "utils/pdda/pdda.sh"], cwd=self.root,
                              capture_output=True, text=True)
        self.assertEqual(gate.returncode, 0, gate.stderr)
        self.assertIn("ERROR", gate.stdout)
        self.assertIn("not blocking in observe mode", gate.stdout)
        self.assert_completed(self.reconcile())

    def test_full_findings_roll_back(self):
        self.named_only()
        (self.root / ".pdda-mode").write_text("full\n")
        before = self.preview.read_bytes(), self.db.read_bytes()
        code, output = self.reconcile()
        self.assertEqual(code, 7, output)
        self.assertIn("PDDA validation gate failed", output)
        self.assertIn("Rolling back", output)
        self.assertNotIn("completed successfully", output)
        self.assertEqual((self.preview.read_bytes(), self.db.read_bytes()), before)
        self.assertFalse((self.root / "ROADMAP-DASHBOARD.md").exists())

    def test_old_stdout_gate_fails_completion_assertion(self):
        self.named_only()
        source = inspect.getsource(wave.run_validation_gate)
        self.assertIn("if r.returncode != 0:", source)
        namespace = dict(vars(wave))
        exec(source.replace("if r.returncode != 0:",
                            'if r.returncode != 0 or "ERROR" in r.stdout:', 1), namespace)
        with mock.patch.object(wave, "run_validation_gate", namespace["run_validation_gate"]):
            result = self.reconcile()
        self.assertEqual(result[0], 7, result[1])
        with self.assertRaises(AssertionError):
            self.assert_completed(result)


unittest.main(verbosity=2)
PY
