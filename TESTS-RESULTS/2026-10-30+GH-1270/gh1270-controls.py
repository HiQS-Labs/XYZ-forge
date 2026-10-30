"""GH-1270 manual controls. Run from the -verify clone root after the pilot:
PYTHONDONTWRITEBYTECODE=1 python3 TESTS-RESULTS/2026-10-30+GH-1270/gh1270-controls.py"""
import copy
import json
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, "utils/py")
import harness as h  # noqa: E402
import wave_reconcile  # noqa: E402

PILOT = Path("temp/factory-primitive/pilot-2c/instances/C")


def show(name, value):
    print(f"CONTROL {name} | {value}")


backlog = PILOT / "backlog"
manifest = json.loads((backlog / "manifest.json").read_text())
engine = h._planner(backlog, "stub")
computed = engine.compute()
active = [r["gh"] for r in computed["active"]]
show("frozen-state-1075", f"in planner active={1075 in active}; closed list has 1075="
     f"{1075 in [r['gh'] for r in computed['deduped'] if r['state'] == 'already-closed']}")

# Red: the Phase 2B state file (seeded issues only, all OPEN) puts #1075 back in an active lane.
with tempfile.TemporaryDirectory() as tmp:
    b2 = Path(tmp) / "backlog"
    shutil.copytree(backlog, b2)
    seeded = json.loads((b2 / "issues.json").read_text())
    (b2 / "gh-state.json").write_text(h.canonical({n: "OPEN" for n in seeded}) + "\n")
    show("red-seeded-only-state-1075", f"in planner active={1075 in [r['gh'] for r in h._planner(b2, 'stub').compute()['active']]}")

# Delivered-but-open signal: closers count, mentions do not.
show("closer-vs-mention", (wave_reconcile.extract_linked_issues({"title": "t", "body": "Closes #722"})[0],
                           wave_reconcile.extract_linked_issues({"title": "t", "body": "see #722"})[0]))
lane = computed["active"][0]["gh"]
m2 = dict(manifest, delivered={str(lane): [99999]})
p = h._build_proposal(engine, computed, [], m2, "control", "control")
in_prov = any(x["issue"] == lane for w in p["provisional"]["waves"] for x in w)
show("delivered-planner-lane", f"#{lane} provisional={in_prov} held={[x['reason'] for x in p['held'] if x['issue'] == lane]}")

# Stale contract on an unseeded planner lane (no brief): mixed probes held, all-unfixed eligible.
base = copy.deepcopy(computed["active"][0])
mixed = [{"type": "path_absent", "path": "utils/py/harness.py"},
         {"type": "grep_absent", "path": "utils/py/harness.py", "pattern": "GH1270_NEVER_PRESENT_CONTROL"}]
unfixed = [{"type": "path_absent", "path": "utils/py/GH1270_NEVER_PRESENT.py"},
           {"type": "grep_absent", "path": "utils/py/harness.py", "pattern": "GH1270_NEVER_PRESENT_CONTROL"}]
for label, probes in (("mixed", mixed), ("all-unfixed", unfixed)):
    rec = dict(copy.deepcopy(base), gh=99999, contract={"artifacts": base["writeset"], "fix_probes": probes})
    c2 = dict(computed, active=[rec] + [r for r in computed["active"] if r["gh"] != base["gh"]])
    p = h._build_proposal(engine, c2, [], manifest, "control", "control")
    show(f"stale-unbriefed-{label}", f"provisional={any(x['issue'] == 99999 for w in p['provisional']['waves'] for x in w)} "
         f"held={[x['reason'] for x in p['held'] if x['issue'] == 99999]}")

# A command probe is never executed.
marker = Path(tempfile.gettempdir()) / "gh1270-command-probe-must-not-run"
marker.unlink(missing_ok=True)
results, landed = h._probe_landing(engine, {"contract": {"fix_probes": [
    {"type": "command", "command": f"touch {marker}", "expect_rc": 0}]}})
show("command-probe", f"results={results} landed={landed} marker_created={marker.exists()}")

# Verifier covers probe_results: a brief without it is refused.
with tempfile.TemporaryDirectory() as tmp:
    inst = Path(tmp) / "C"
    shutil.copytree(backlog, inst / "backlog")
    out = inst / "out" / "plan-draft"
    shutil.copytree(PILOT / "out/plan-draft", out)
    last = sorted(out.glob("slot_*.json"))[-1]
    brief = json.loads(last.read_text())
    del brief["probe_results"]
    last.write_text(h.canonical(brief))
    try:
        h._verify_plan_draft(inst, last.stem, {"inbox_id": brief["request_id"]})
        show("verify-drop-probe-results", "accepted (BUG)")
    except (ValueError, KeyError) as exc:
        show("verify-drop-probe-results", f"refused: {exc}")
