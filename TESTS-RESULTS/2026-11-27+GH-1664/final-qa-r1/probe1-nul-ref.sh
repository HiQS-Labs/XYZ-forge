python3 -B - <<'PY'
import io, json, subprocess, sys
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0, "utils/py")
import jog_run, swarm_preflight
doc = Path("PROJECT/2-WORKING/GH-1664-STALE-EVIDENCE-ADMISSION.md")
packet = swarm_preflight.extract_contract(str(doc))
packet.update(prepared_commit="52813e56f0abd76cd3ba277602cc3e7fdf1e6f90")
packet["target"]["ref"] = "development\0"
markdown = "## Swarm Preflight Contract\n```json\n" + json.dumps(packet) + "\n```\n"
run = subprocess.run
def local_run(argv, **kwargs):
    if argv[3:] == ["fetch", "--prune", "--quiet"]:
        return subprocess.CompletedProcess(argv, 0, "", "")
    assert argv[3:6] == ["rev-parse", "--verify", "--quiet"], argv
    return run([sys.executable, "-c", "pass", argv[-1]], **kwargs)
with patch.object(jog_run, "_admission_captures", return_value=[str(doc)]), \
     patch.object(swarm_preflight, "open", side_effect=lambda *a, **k: io.StringIO(markdown), create=True), \
     patch.object(jog_run.subprocess, "run", side_effect=local_run):
    assert swarm_preflight.extract_contract(str(doc))["target"]["ref"] == "development\0"
    reason = jog_run.stale_evidence_refusal(".", 1664)
    assert reason and reason.startswith("stale-check-unavailable:"), reason
PY
