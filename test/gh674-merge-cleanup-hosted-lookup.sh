#!/usr/bin/env bash
# GH-674 — hosted reconciliation lookup sees PR-keyed runs; automatic fallback never forces.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export XYZ_TEST_SCRIPTS="$HERE/../skills/merge-cleanup/scripts"

exec python3 - <<'PY'
import json
import os
import subprocess
import sys
import tempfile
import unittest
import unittest.mock as mock
from pathlib import Path

sys.path.insert(0, os.environ["XYZ_TEST_SCRIPTS"])
import merge_cleanup  # noqa: E402


class HostedLookup(unittest.TestCase):
    def test_unfiltered_lookup_adopts_pr_keyed_active_run(self):
        calls = []
        responses = [
            [{"databaseId": 67401, "status": "in_progress", "conclusion": "",
              "headSha": "p" * 40, "event": "push"}],
            [{"databaseId": 67401, "status": "completed", "conclusion": "success",
              "headSha": "p" * 40, "event": "push"}],
        ]

        def fake_gh(args, cwd, timeout=60):
            calls.append(args)
            # Red control: the pre-fix filtered lookup misses this PR-keyed run.
            payload = [] if "--branch" in args or "--commit" in args else responses.pop(0)
            return subprocess.CompletedProcess(args, 0, json.dumps(payload), "")

        legacy = fake_gh([
            "run", "list", "--workflow", "wave-reconcile.yml",
            "--branch", "development", "--commit", "m" * 40,
        ], Path("."))
        self.assertEqual(json.loads(legacy.stdout), [], "red control must miss the PR-keyed run")

        env = {
            merge_cleanup.HOSTED_GRACE_ENV: "60",
            merge_cleanup.HOSTED_WAIT_ENV: "10",
            merge_cleanup.HOSTED_POLL_ENV: "0",
        }
        with tempfile.TemporaryDirectory() as td, \
                mock.patch.object(merge_cleanup, "_gh", side_effect=fake_gh), \
                mock.patch.object(merge_cleanup.time, "sleep", return_value=None), \
                mock.patch.dict(os.environ, env):
            result = merge_cleanup.wait_for_hosted_reconcile(
                "m" * 40, Path(td), "development", pr_head="p" * 40)

        self.assertEqual(result, "success")
        lookup_calls = calls[1:]
        self.assertEqual(len(lookup_calls), 2)
        self.assertTrue(all("--branch" not in call and "--commit" not in call for call in lookup_calls))
        self.assertTrue(all("headSha" in call[call.index("--json") + 1] for call in lookup_calls))

    def test_automatic_fallback_never_adds_force_flag(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            script = root / "utils" / "py" / "wave_reconcile.py"
            script.parent.mkdir(parents=True)
            script.write_text(
                "import pathlib, sys\n"
                "pathlib.Path('argv.txt').write_text(' '.join(sys.argv[1:]))\n"
            )
            with mock.patch.object(merge_cleanup, "log"), \
                    mock.patch.object(merge_cleanup, "log_err"):
                self.assertTrue(merge_cleanup.run_local_wave_reconcile(674, root))
            argv = (root / "argv.txt").read_text()
            self.assertNotIn("--force-local-reconcile", argv)
            self.assertIn("--pr 674", argv)


if __name__ == "__main__":
    unittest.main(verbosity=1)
PY
