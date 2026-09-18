#!/usr/bin/env bash
# gh645-merge-cleanup-xyz-tools.sh — /merge-cleanup must find PRS tools that a consumer repo vendors
# under gitignored `.xyz/utils/py/` (GH-645). A landing clone is a plain `git clone`, so it never
# carries `.xyz/`; the gate went RED with "No such file", and the reconciler was then passed
# `--force-local-reconcile`, which the vendored wave_reconcile.py rejects. Pins resolver order,
# the primary-checkout fallback, and the advertised-flag-only rule.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export XYZ_TEST_SCRIPTS="$HERE/../skills/merge-cleanup/scripts"

exec python3 - <<'PY'
import os, stat, sys, tempfile, unittest, subprocess
import unittest.mock as mock
from pathlib import Path

sys.path.insert(0, os.environ["XYZ_TEST_SCRIPTS"])
import ledger_merge  # noqa: E402
import merge_cleanup  # noqa: E402
from ledger_merge import tool_path  # noqa: E402


def _touch(p: Path) -> Path:
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text("# stub\n")
    return p


class ToolPathResolution(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.clone = Path(self.tmp.name) / "clone"
        self.primary = Path(self.tmp.name) / "primary"
        self.clone.mkdir(); self.primary.mkdir()
        self._saved = ledger_merge.TOOL_FALLBACK_ROOT
        ledger_merge.TOOL_FALLBACK_ROOT = None

    def tearDown(self):
        ledger_merge.TOOL_FALLBACK_ROOT = self._saved
        self.tmp.cleanup()

    def test_canonical_utils_py_wins_over_vendored(self):
        canon = _touch(self.clone / "utils" / "py" / "releases_app.py")
        _touch(self.clone / ".xyz" / "utils" / "py" / "releases_app.py")
        self.assertEqual(tool_path(self.clone, "releases_app.py"), canon)

    def test_vendored_xyz_in_clone_is_found(self):
        vend = _touch(self.clone / ".xyz" / "utils" / "py" / "releases_app.py")
        self.assertEqual(tool_path(self.clone, "releases_app.py"), vend)

    def test_gitignored_xyz_falls_back_to_the_primary(self):
        prim = _touch(self.primary / ".xyz" / "utils" / "py" / "releases_app.py")
        ledger_merge.TOOL_FALLBACK_ROOT = self.primary
        self.assertEqual(tool_path(self.clone, "releases_app.py"), prim)

    def test_vendored_shell_resolver_runs_against_the_landing_clone(self):
        resolver = self.primary / ".xyz" / "utils" / "releases-merge-resolve.sh"
        _touch(resolver)
        resolver.write_text('test "$1" = "--root" && test "$(cd "$2" && pwd -P)" = "$(pwd -P)"\n')
        _touch(self.primary / ".xyz" / "utils" / "py" / "releases_app.py")
        ledger_merge.TOOL_FALLBACK_ROOT = self.primary
        commands = []

        def run(cmd, cwd):
            commands.append(cmd)
            if cmd[0] == "bash":
                return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
            return subprocess.CompletedProcess(cmd, 0, "", "")

        sem = {"ok": True, "classification": None}
        with mock.patch.object(ledger_merge, "extract_conflict_set", return_value=(True, {"LEADERBOARD.md"}, "")), \
             mock.patch.object(ledger_merge, "ledger_semantic_check", return_value=sem), \
             mock.patch.object(ledger_merge, "run_git", return_value=subprocess.CompletedProcess([], 0, "", "")), \
             mock.patch.object(ledger_merge, "_run", side_effect=run):
            result = ledger_merge.resolve_ledger_conflict(self.clone, execute=True)
        self.assertTrue(result["resolved"], result)
        self.assertIn(["bash", str(resolver), "--root", str(self.clone)], commands)

    def test_missing_everywhere_reports_the_canonical_path(self):
        ledger_merge.TOOL_FALLBACK_ROOT = self.primary
        self.assertEqual(tool_path(self.clone, "wave_reconcile.py"),
                         self.clone / "utils" / "py" / "wave_reconcile.py")

    def test_app_command_uses_the_resolver_with_root(self):
        prim = _touch(self.primary / ".xyz" / "utils" / "py" / "releases_app.py")
        ledger_merge.TOOL_FALLBACK_ROOT = self.primary
        cmd = ledger_merge._app(self.clone)
        self.assertEqual(cmd[1], str(prim))
        self.assertEqual(cmd[2:4], ["--root", str(self.clone)])


class ReconcileFlagIsAdvertisedOnly(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name)
        self._saved = ledger_merge.TOOL_FALLBACK_ROOT
        ledger_merge.TOOL_FALLBACK_ROOT = None

    def tearDown(self):
        ledger_merge.TOOL_FALLBACK_ROOT = self._saved
        self.tmp.cleanup()

    def _write_reconciler(self, advertises: bool):
        # --help lists the flag or not; unknown arguments are refused like the real argparse tool.
        flag_line = '    print("  --force-local-reconcile")' if advertises else "    pass"
        body = (
            "import sys\n"
            "if '--help' in sys.argv:\n"
            "    print('usage: wave_reconcile.py [--root ROOT] [--pr PR]')\n"
            f"{flag_line}\n"
            "    sys.exit(0)\n"
            "known = {'--root', '--pr'}\n"
            "bad = [a for a in sys.argv[1:] if a.startswith('--') and a not in known"
            + (" | {'--force-local-reconcile'}" if advertises else "") + "]\n"
            "if bad:\n"
            "    print('error: unrecognized arguments: ' + ' '.join(bad), file=sys.stderr); sys.exit(2)\n"
            "open('argv.txt', 'w').write(' '.join(sys.argv[1:]))\n"
        )
        return _touch(self.repo / ".xyz" / "utils" / "py" / "wave_reconcile.py").write_text(body)

    def test_flag_omitted_when_the_tool_does_not_advertise_it(self):
        self._write_reconciler(advertises=False)
        with mock.patch.object(merge_cleanup, "log"), mock.patch.object(merge_cleanup, "log_err") as err:
            self.assertTrue(merge_cleanup.run_local_wave_reconcile(7, self.repo))
            err.assert_not_called()
        argv = (self.repo / "argv.txt").read_text()
        self.assertNotIn("--force-local-reconcile", argv)
        self.assertIn(f"--root {self.repo}", argv)
        self.assertIn("--pr 7", argv)

    def test_flag_passed_when_the_tool_advertises_it(self):
        self._write_reconciler(advertises=True)
        with mock.patch.object(merge_cleanup, "log"), mock.patch.object(merge_cleanup, "log_err"):
            self.assertTrue(merge_cleanup.run_local_wave_reconcile(7, self.repo))
        self.assertIn("--force-local-reconcile", (self.repo / "argv.txt").read_text())


if __name__ == "__main__":
    unittest.main(verbosity=1)
PY
