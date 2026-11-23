"""GH-1257 final-QA round-1 controls (F1 goal decoding, F2 ready-brief admission). Run from the -verify clone root."""
import copy
import json
import sys
from pathlib import Path

sys.path.insert(0, "utils/py")
import harness as h  # noqa: E402

# F1: frontmatter goal decoding.
cases = {"folded (#478 doc)": Path("PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md").read_text(),
         "inline": "---\ntitle: x\ngoal: Ship the thing.\n---\nbody\n",
         "literal": "---\ngoal: |\n  line one\n  line two\nowner: x\n---\n",
         "empty marker": "---\ngoal: >\nowner: x\n---\n",
         "no goal": "---\ntitle: x\n---\n## Goal\nnot frontmatter\n"}
for name, text in cases.items():
    print(f"CONTROL goal-{name} |", h._frontmatter_goal(text))

# F2: a planner-ready brief is admitted to provisional waves only with sourced scope.
pilot = Path("temp/factory-primitive/pilot-2/instances/C")
manifest = json.loads((pilot / "backlog/manifest.json").read_text())
engine = h._planner(pilot / "backlog", "stub")
computed = engine.compute()
ready = next(json.loads(p.read_text()) for p in sorted((pilot / "out/plan-draft").glob("slot_*.json"))
             if json.loads(p.read_text())["draft_status"] == "ready")
for label, scope in (("with-scope", ready["scope"]), ("no-scope", [])):
    brief = copy.deepcopy(ready)
    brief["scope"] = scope
    if not scope:
        brief["draft_status"], brief["held_reason"] = "missing-scope", "no sourced scope"
    p = h._build_proposal(engine, computed, [brief], manifest, "control", brief["request_id"])
    prov = any(x["issue"] == brief["issue"] for w in p["provisional"]["waves"] for x in w)
    actual = any(x["issue"] == brief["issue"] for w in p["actual"]["waves"] for x in w)
    held = [x["reason"] for x in p["held"] if x["issue"] == brief["issue"]]
    print(f"CONTROL ready-brief-{label} | #{brief['issue']} in_actual={actual} in_provisional={prov} held={held}")

# AC3: a dependency cycle is held, never forced into one wave; the CLI path still forces it.
a, b = (copy.deepcopy(r) for r in computed["active"][:2])
a["deps"], b["deps"] = [b["gh"]], [a["gh"]]
for force in (False, True):
    waves, unplaced = engine._pack_waves([a, b], [a, b], force_tail=force)
    print(f"CONTROL dependency-cycle force_tail={force} | waves={[[r['gh'] for r in w] for w in waves]} "
          f"unplaced={[r['gh'] for r in unplaced]}")
