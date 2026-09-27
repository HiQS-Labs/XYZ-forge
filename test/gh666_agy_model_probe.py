"""Actual-validator regression; no live Agy/model calls or valued checkout writes."""
import importlib.util
import json
import os
import shutil
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "utils/py"))
sys.path.insert(0, str(Path(__file__).resolve().parent / "lib"))
import pystub  # GH-788: stub header that survives a spaced interpreter path
spec = importlib.util.spec_from_file_location(
    "agy_turn", Path(__file__).resolve().parents[1] / "utils/py/agy-turn.py")
agy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(agy)


class ModelProbeTests(unittest.TestCase):
    def setUp(self):
        self.sandbox = tempfile.TemporaryDirectory(prefix="gh666.", dir=os.environ.get("WORK"))
        self.addCleanup(self.sandbox.cleanup)
        self.root = Path(self.sandbox.name).resolve()
        self.caller = self.root / "caller"
        self.caller.mkdir()
        self.probes = self.root / "probes"
        self.probes.mkdir()
        self.record = self.root / "invocations.jsonl"
        self.stub = self.caller / "tools" / "agy"
        self.stub.parent.mkdir()
        self.stub.write_text(pystub.launcher() + '''
import json, os, sys, time
from pathlib import Path
assert sys.argv[1:] == ["models"]
marker = Path("probe-write.txt")
marker.write_text("relative probe write")
with open(os.environ["PROBE_RECORD"], "a") as out:
    out.write(json.dumps({"cwd": str(Path.cwd()), "wrote": marker.read_text()}) + "\\n")
print("model-id\\tDisplay Model", flush=True)
mode = os.environ.get("PROBE_MODE", "ok")
if mode == "nonzero": sys.exit(9)
if mode == "timeout": time.sleep(10)
''')
        self.stub.chmod(0o700)
        (self.caller / "sentinel.txt").write_bytes(b"caller work must survive\n")
        self.git("init", "-q")
        self.git("config", "user.name", "GH666 fixture")
        self.git("config", "user.email", "fixture@example.test")
        self.git("add", ".")
        self.git("commit", "-q", "-m", "controlled caller seed")
        self.cwd_before = os.getcwd()
        os.chdir(self.caller)
        self.addCleanup(os.chdir, self.cwd_before)
        self.env = mock.patch.dict(os.environ, {
            "AGY_MODEL": "model-id", "AGY_AUTH_TIMEOUT_S": "1",
            "PROBE_RECORD": str(self.record), "PROBE_MODE": "ok"})
        self.env.start()
        self.addCleanup(self.env.stop)
        temp_root = mock.patch.object(tempfile, "tempdir", str(self.probes))
        temp_root.start()
        self.addCleanup(temp_root.stop)

    def git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.caller), *args], stderr=subprocess.DEVNULL)

    def snapshot(self):
        return (self.git("rev-parse", "HEAD", "--absolute-git-dir", "--is-bare-repository"),
                self.git("status", "--porcelain", "--untracked-files=all"),
                (self.caller / "sentinel.txt").read_bytes())

    def check_probe(self, expected, binary=None, invoked=True):
        before = self.snapshot()
        result = agy.agy_validate_model(binary or str(self.stub))
        self.assertEqual(result, expected)
        self.assertEqual(self.snapshot(), before, "caller identity/HEAD/tree/sentinel changed")
        self.assertFalse((self.caller / "probe-write.txt").exists(), "probe wrote into caller")
        if invoked:
            self.assertTrue(self.record.is_file() and self.record.stat().st_size > 0)
            rows = [json.loads(row) for row in self.record.read_text().splitlines()]
            self.assertTrue(rows)
            for row in rows:
                cwd = Path(row["cwd"])
                self.assertEqual(row["wrote"], "relative probe write")
                self.assertNotEqual(cwd, self.caller)
                self.assertEqual(cwd.parent, self.probes)
                self.assertFalse(cwd.exists(), "completed probe cwd not cleaned")
        else:
            self.assertFalse(self.record.exists(), "failed creation/launch invoked stub")
        self.assertEqual(list(self.probes.iterdir()), [], "probe cwd/log residue")

    def test_listed_forms(self):
        for model in ("model-id", "Display Model", "model-id\tDisplay Model"):
            with self.subTest(model=model):
                os.environ["AGY_MODEL"] = model
                self.check_probe(True)

    def test_ignored_marker_still_detected(self):
        (self.caller / ".gitignore").write_text("probe-write.txt\n")
        self.check_probe(True)

    def test_unavailable(self):
        os.environ["AGY_MODEL"] = "not-listed"
        self.check_probe(False)

    def test_nonzero(self):
        os.environ["PROBE_MODE"] = "nonzero"
        self.check_probe(False)

    def test_timeout(self):
        os.environ["PROBE_MODE"] = "timeout"
        self.check_probe(False)

    def test_launch_failure(self):
        self.check_probe(False, str(self.root / "missing-agy"), invoked=False)

    def test_post_allocation_launch_error(self):
        broken = self.caller / "tools" / "broken-agy"
        broken.write_text("#!" + str(self.root / "missing-interpreter") + "\n")
        broken.chmod(0o700)
        factory = tempfile.TemporaryDirectory
        with mock.patch.object(agy.tempfile, "TemporaryDirectory", wraps=factory) as allocation:
            self.check_probe(False, str(broken), invoked=False)
            allocation.assert_called_once_with(prefix="agy-model-probe.")

    def test_relative_executable(self):
        self.check_probe(True, "./tools/agy")

    def test_relative_path_entry(self):
        os.environ["PATH"] = "tools" + os.pathsep + os.environ["PATH"]
        self.check_probe(True, "agy")

    def test_absolute_path_entry(self):
        os.environ["PATH"] = str(self.stub.parent) + os.pathsep + os.environ["PATH"]
        self.check_probe(True, "agy")

    def test_missing_path_does_not_use_caller_binary(self):
        # A bare command absent from PATH must not fall back to a caller file.
        local_binary = self.caller / "agy"
        shutil.copy2(self.stub, local_binary)
        empty_bin = self.root / "empty-bin"
        empty_bin.mkdir()
        real_git = shutil.which("git")
        self.assertIsNotNone(real_git)
        (empty_bin / "git").symlink_to(real_git)
        os.environ["PATH"] = str(empty_bin)
        self.check_probe(False, "agy", invoked=False)

    def test_unset_model_skips_probe(self):
        os.environ.pop("AGY_MODEL")
        with mock.patch.object(agy.subprocess, "run") as run:
            self.assertTrue(agy.agy_validate_model(str(self.stub)))
            run.assert_not_called()
        self.assertFalse(self.record.exists())
        self.assertEqual(list(self.probes.iterdir()), [])

    def test_directory_creation_failure_refuses(self):
        # Raising at the existing stdlib allocation seam must prevent invocation.
        with mock.patch.object(agy.tempfile, "mkdtemp", side_effect=OSError("injected allocation failure")):
            self.check_probe(False, invoked=False)

    def test_cleanup_failure_is_reported_and_refuses(self):
        original_exit = tempfile.TemporaryDirectory.__exit__

        def failed_exit(directory, *args):
            original_exit(directory, *args)
            raise OSError("injected cleanup failure after removal")

        with mock.patch.object(tempfile.TemporaryDirectory, "__exit__", failed_exit):
            with mock.patch("builtins.print") as report:
                self.check_probe(False)
                self.assertTrue(any("probe failed" in str(call) for call in report.call_args_list))


if __name__ == "__main__":
    unittest.main(verbosity=2)
