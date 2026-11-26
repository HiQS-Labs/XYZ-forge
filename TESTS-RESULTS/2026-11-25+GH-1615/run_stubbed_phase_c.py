# Experiment 1c (outside the repo): the same one-line stub gh436:43 applies, phase C standalone, nothing else.
import sys, unittest
sys.path.insert(0, "test"); sys.path.insert(0, "skills/2-daily/merge-cleanup/scripts")
import gh534_phase_c_tests as T
T.merge_cleanup.gate_unwired_reason = lambda clone, install=False: ""
r = unittest.TextTestRunner(verbosity=1).run(unittest.defaultTestLoader.loadTestsFromModule(T))
print("RESULT run=%d failures=%d errors=%d ok=%s" % (r.testsRun, len(r.failures), len(r.errors), r.wasSuccessful()))
for kind, items in (("FAIL", r.failures), ("ERROR", r.errors)):
    for t, _tb in items: print(kind, t.id())
