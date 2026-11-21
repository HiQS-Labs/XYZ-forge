"""GH-1296 manual check: _preflight_blockers against the live-preflight verdicts recorded for the same contracts. Not a test suite (GH-831)."""
import importlib.util, json, sys
root = sys.argv[1]
spec = importlib.util.spec_from_file_location("harness", root + "/utils/py/harness.py")
h = importlib.util.module_from_spec(spec); sys.modules["harness"] = h; sys.path.insert(0, root + "/utils/py"); spec.loader.exec_module(h)
files = set(open(sys.argv[2]).read().split())
for label, pf in (("1265 (ready)", sys.argv[3]), ("1265 moved artifact path", sys.argv[4]), ("670 (artifacts_new)", sys.argv[5])):
    contract = json.load(open(pf))["contract"]
    print(label, "->", json.dumps(h._preflight_blockers({"contract": contract}, files)))
print("no contract ->", json.dumps(h._preflight_blockers({"contract": None}, files)))
