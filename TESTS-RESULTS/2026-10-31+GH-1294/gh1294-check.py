"""GH-1294 manual check: _build_proposal with a draft brief for an issue a merged PR delivered. Not a test suite (GH-831)."""
import importlib.util, json, sys
spec = importlib.util.spec_from_file_location("harness", sys.argv[1] + "/utils/py/harness.py")
h = importlib.util.module_from_spec(spec); sys.modules["harness"] = h; sys.path.insert(0, sys.argv[1] + "/utils/py"); spec.loader.exec_module(h)

class Engine:
    def _zone_of(self, a, lane): return {"zone": "z", "zoneRule": "r"}
    def _pack_waves(self, lanes, view, force_tail=False): return ([lanes] if lanes else []), []
    def _contract_seams(self, waves): return []
    def _eval_probe(self, p): return "unlanded"

def brief(n, status="draft", ws=("utils/py/x.py",)):
    return {"issue": n, "title": f"t{n}", "draft_status": status, "held_reason": None, "deps": [],
            "write_set": [{"path": p, "source": "issue"} for p in ws], "request_id": f"r{n}"}
manifest = {"delivered": {"384": [386]}, "requests": {"r384": {}, "r777": {}}, "excluded": []}
computed = {"active": [], "deduped": [], "waves": [], "contract_seams": []}
p = h._build_proposal(Engine(), computed, [brief(384), brief(777)], manifest, "t", "r")
print(json.dumps({"scheduled": [l["issue"] for w in p["provisional"]["waves"] for l in w], "held": p["held"]}))
