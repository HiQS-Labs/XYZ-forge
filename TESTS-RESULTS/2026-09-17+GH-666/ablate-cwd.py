import importlib.util
from pathlib import Path
import unittest
from unittest import mock

repo = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("probe_tests", repo / "test/gh666_agy_model_probe.py")
tests = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tests)
original_run = tests.agy.subprocess.run

def remove_model_cwd(command, *args, **kwargs):
    if len(command) == 2 and command[1] == "models":
        kwargs.pop("cwd", None)
    return original_run(command, *args, **kwargs)

with mock.patch.object(tests.agy.subprocess, "run", side_effect=remove_model_cwd):
    result = unittest.TextTestRunner(verbosity=2).run(
        unittest.defaultTestLoader.loadTestsFromTestCase(tests.ModelProbeTests))
raise SystemExit(0 if result.wasSuccessful() else 1)
