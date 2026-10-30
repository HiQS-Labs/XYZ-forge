"""GH-1261 manual controls (plan QA R1-R3 and acceptance). Run from the -verify clone root after the
pilot: PYTHONDONTWRITEBYTECODE=1 python3 TESTS-RESULTS/2026-10-30+GH-1261/gh1261-controls.py"""
import copy
import json
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, "utils/py")
import harness as h  # noqa: E402

PILOT = Path("temp/factory-primitive/pilot-3/instances/C")


def show(name, value):
    print(f"CONTROL {name} | {value}")


# R1: a bare name resolves only with exactly one tracked match.
one = h._file_index("utils/marathon-plan.sh\n")
two = h._file_index("utils/marathon-plan.sh\ntest/marathon-plan.sh\n")
for label, idx in (("one-match", one), ("two-match", two)):
    u = []
    show(f"bare-{label}", (h._cited_paths("Fix marathon-plan.sh now.", "t", index=idx, unresolved=u), u))

# `.xyz/` strip only when the stripped path is in the frozen listing.
for label, listing in (("in-listing", "utils/py/harness.py\n"), ("not-in-listing", "utils/py/other.py\n")):
    show(f"xyz-{label}", h._cited_paths("See .xyz/utils/py/harness.py", "t", index=h._file_index(listing)))

# Red control for resolution: without the index, #216's issue body sources nothing.
issues = json.loads((PILOT / "backlog/issues.json").read_text())
show("red-no-index-216", h._cited_paths(issues["216"]["body"], "issue#216"))

# R3: 25+ resolved citations keep the capture-doc path, and it still collides with a competing lane.
idx = h._file_index((PILOT / "backlog/base-files.txt").read_text())
names = sorted(n for n, ps in idx["names"].items() if len(ps) == 1 and ps[0].startswith("utils/py/")
               and n.endswith(".py"))[:25]
paths = h._cited_paths(" ".join(names), "issue", index=idx) + h._cited_paths("Touches PROJECT/PDDA.md", "doc", index=idx)
dedup = list(dict.fromkeys(p["path"] for p in paths))
show("cap-removed", f"{len(dedup)} paths; PDDA kept={'PROJECT/PDDA.md' in dedup}")
engine = h._planner(PILOT / "backlog", "stub")
computed = engine.compute()
manifest = json.loads((PILOT / "backlog/manifest.json").read_text())
ready = [json.loads(p.read_text()) for p in sorted((PILOT / "out/plan-draft").glob("slot_*.json"))]
ledger_draft = next(b for b in ready if b["draft_status"] == "draft" and b["planner_state"] != "unregistered")
big, rival = copy.deepcopy(ledger_draft), copy.deepcopy(ledger_draft)
big["write_set"] = [{"path": p, "source": "x"} for p in dedup]
rival_rec = next(r for r in computed["deduped"] if r["gh"] not in {big["issue"]} and r["state"] == "needs-contract"
                 and r["gh"] not in {b["issue"] for b in ready})
rival.update(issue=rival_rec["gh"], request_id="rival", write_set=[{"path": "PROJECT/PDDA.md", "source": "x"}])
p = h._build_proposal(engine, computed, [big, rival], manifest, "control", "control")
wave_of = {x["issue"]: i for i, w in enumerate(p["provisional"]["waves"], 1) for x in w}
show("cap-collision", f"#{big['issue']} wave {wave_of.get(big['issue'])} vs rival #{rival['issue']} "
     f"wave {wave_of.get(rival['issue'])} (must differ)")

# R2: a dependency on a held/pending seeded issue holds the dependent; an admitted prerequisite packs first.
unreg = [b for b in ready if b["planner_state"] == "unregistered" and b["draft_status"] == "draft"]
dep, pre = copy.deepcopy(unreg[0]), copy.deepcopy(unreg[1])
dep["deps"] = [pre["issue"]]
others = [b for b in ready if b["issue"] not in {dep["issue"], pre["issue"]}]
pre_held = dict(pre, draft_status="missing-scope", held_reason="no sourced scope")
for label, briefs in (("prereq-held", others + [dep, pre_held]), ("prereq-pending", others + [dep]),
                      ("prereq-admitted", others + [dep, pre])):
    p = h._build_proposal(engine, computed, briefs, manifest, "control", "control")
    wave_of = {x["issue"]: i for i, w in enumerate(p["provisional"]["waves"], 1) for x in w}
    held = [x["reason"] for x in p["held"] if x["issue"] == dep["issue"]]
    show(f"dep-{label}", f"dependent #{dep['issue']} wave={wave_of.get(dep['issue'])} held={held}; "
         f"prereq #{pre['issue']} wave={wave_of.get(pre['issue'])}")
# Red control: lookup limited to admitted lanes (no seeded unregistered requests in the manifest view).
narrow = copy.deepcopy(manifest)
for q in narrow["requests"].values():
    if q.get("source") == "unregistered":
        q["source"] = "ledger"
p = h._build_proposal(engine, computed, others + [dep], narrow, "control", "control")
wave_of = {x["issue"]: i for i, w in enumerate(p["provisional"]["waves"], 1) for x in w}
show("red-dep-admitted-only-lookup", f"dependent #{dep['issue']} wave={wave_of.get(dep['issue'])} (packed = bug shown)")

# Verifier covers the new key: a brief without unresolved_names is refused.
with tempfile.TemporaryDirectory() as tmp:
    inst = Path(tmp) / "C"
    shutil.copytree(PILOT / "backlog", inst / "backlog")
    out = inst / "out" / "plan-draft"
    shutil.copytree(PILOT / "out/plan-draft", out)
    last = sorted(out.glob("slot_*.json"))[-1]
    tick_id = last.stem
    brief = json.loads(last.read_text())
    args = {"inbox_id": brief["request_id"]}
    try:
        h._verify_plan_draft(inst, tick_id, args)
        show("verify-intact", "accepted")
    except ValueError as exc:
        show("verify-intact", f"refused: {exc}")
    del brief["unresolved_names"]
    last.write_text(h.canonical(brief))
    try:
        h._verify_plan_draft(inst, tick_id, args)
        show("verify-drop-unresolved", "accepted (BUG)")
    except (ValueError, KeyError) as exc:
        show("verify-drop-unresolved", f"refused: {exc}")
