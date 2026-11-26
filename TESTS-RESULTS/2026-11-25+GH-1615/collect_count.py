# GH-1615 receipt: how many tests does the GATED entry point (test/gh436-merge-cleanup.py) collect, by module?
# Collection only; runs no test. Usage (from a clone's repo root): python3 collect_count.py
import sys, unittest, importlib.util, collections
sys.path.insert(0, "test"); sys.path.insert(0, "skills/2-daily/merge-cleanup/scripts")
spec = importlib.util.spec_from_file_location("gh436_entry", "test/gh436-merge-cleanup.py")
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
def flat(s):
    for t in s:
        if isinstance(t, unittest.TestSuite): yield from flat(t)
        else: yield t
tests = list(flat(unittest.defaultTestLoader.loadTestsFromModule(m)))
by = collections.Counter(t.__class__.__module__ for t in tests)
print("gated entry point collects", len(tests), "tests:", ", ".join(f"{k}={v}" for k, v in sorted(by.items())))
pb = {t._testMethodName for t in tests if t.__class__.__module__ == "gh534_phase_b_tests"}
for n in ("test_same_key_update_on_both_sides_is_handoff_and_nothing_is_overwritten", "test_unknown_mergeable_settles_and_the_pr_lands", "test_unlisted_pr_is_never_sequenced", "test_gate_red_prevents_the_merge"):
    print("pinned test collected through the gate:", n in pb, n)
