import importlib.util
from pathlib import Path
import unittest
from unittest import mock

repo = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("probe_tests", repo / "test/gh666_agy_model_probe.py")
tests = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tests)
original_cleanup = tests.tempfile.TemporaryDirectory.cleanup

def omit_probe_cleanup(directory):
    if Path(directory.name).name.startswith("agy-model-probe."):
        directory._finalizer.detach()
        return
    return original_cleanup(directory)

with mock.patch.object(tests.tempfile.TemporaryDirectory, "cleanup", omit_probe_cleanup):
    result = unittest.TextTestRunner(verbosity=2).run(
        tests.ModelProbeTests("test_post_allocation_launch_error"))
raise SystemExit(0 if result.wasSuccessful() else 1)
