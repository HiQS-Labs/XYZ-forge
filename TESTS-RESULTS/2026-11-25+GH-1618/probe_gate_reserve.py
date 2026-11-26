"""GH-1618 manual check (not a suite, registered nowhere). Read-only probe: does a phase B test, collected through the gated gh436 module, reach the B1
reserve call? Usage: python3 probe_gate_reserve.py <clone>. Imports gh436 (as the gate does), wraps
attempt_record.reserve and gate_toolchain_fault_reason with counters, runs ONE phase B test."""
import importlib.util, sys, unittest, os
clone = sys.argv[1]
test_dir = os.path.join(clone, "test")
sys.path.insert(0, test_dir)
spec = importlib.util.spec_from_file_location("gh436_mod", os.path.join(test_dir, "gh436-merge-cleanup.py"))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
import merge_cleanup, attempt_record
print("gh436 stub installed:", merge_cleanup.gate_unwired_reason.__name__ == "<lambda>")
calls = {"reserve": 0, "toolchain": 0}
orig_reserve = attempt_record.reserve
orig_tc = merge_cleanup.gate_toolchain_fault_reason
def reserve(*a, **k):
    calls["reserve"] += 1
    return orig_reserve(*a, **k)
def tc(*a, **k):
    calls["toolchain"] += 1
    return orig_tc(*a, **k)
attempt_record.reserve = reserve
merge_cleanup.gate_toolchain_fault_reason = tc
# the class is reachable as an attribute of the gh436 module (import *), which is how unittest collects it
cls = getattr(mod, "TestPhase5EndToEnd")
suite = unittest.TestSuite([cls("test_two_prs_second_conflicts_after_first_lands_and_b1_resolves_it")])
res = unittest.TextTestRunner(verbosity=2).run(suite)
print("RESULT run=%d fail=%d err=%d" % (res.testsRun, len(res.failures), len(res.errors)))
print("CALLS", calls)
