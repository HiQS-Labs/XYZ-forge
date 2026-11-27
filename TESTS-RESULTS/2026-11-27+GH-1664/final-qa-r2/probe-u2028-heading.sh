#!/usr/bin/env bash
export PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.relay-scratch/tmp"
mkdir -p "$TMPDIR"
python3 -B - <<'PY'
import io, json, subprocess, sys
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0, "utils/py")
import jog_run, swarm_preflight

doc = Path("PROJECT/2-WORKING/GH-1664-STALE-EVIDENCE-ADMISSION.md")
packet = swarm_preflight.extract_contract(str(doc))
a, b = "a" * 40, "b" * 40
packet["prepared_commit"] = a
packet["artifacts"] = ["utils/py/jog_run.py"]
body = "## Swarm Preflight Contract\n```json\n" + json.dumps(packet) + "\n```\n"
def fake_process(argv, **kwargs):
    args = argv[3:]
    if args[0] == "fetch":
        out, rc = "", 0
    elif args[0] == "rev-parse":
        out, rc = (a if args[-1].startswith(a) else b) + "\n", 0
    elif args[0] == "config":
        out, rc = "", 1
    else:
        assert args[0] == "diff" and ":(literal)utils/py/jog_run.py" in args, args
        out, rc = "utils/py/jog_run.py\n", 0
    return subprocess.CompletedProcess(argv, rc, out, "")

for sep in ("\n", "\u2028"):
    markdown = "Preparation notes" + sep + body
    with patch.object(jog_run, "_admission_captures", return_value=[str(doc)]), \
         patch.object(Path, "read_text", return_value=markdown), \
         patch.object(swarm_preflight, "open", lambda *a, **k: io.StringIO(markdown), create=True), \
         patch.object(jog_run, "_jog_process", side_effect=fake_process) as process:
        parsed = swarm_preflight.extract_contract(str(doc))["prepared_commit"]
        reason = jog_run.stale_evidence_refusal(".", 1664)
        print(f"separator={ord(sep):#06x} stamp={parsed[:12]} calls={process.call_count} reason={reason!r}")
        assert reason and reason.startswith("stale-evidence:"), reason
PY
