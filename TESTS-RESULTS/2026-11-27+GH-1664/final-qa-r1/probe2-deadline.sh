PYTHONDONTWRITEBYTECODE=1 python3 -B - <<'PY'
import inspect, io, json, os, sys, tempfile, time
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, "utils/py")
import jog_run, swarm_preflight

doc = Path("PROJECT/2-WORKING/GH-1664-STALE-EVIDENCE-ADMISSION.md").resolve()
packet = swarm_preflight.extract_contract(str(doc))
packet["prepared_commit"] = "52813e56f0abd76cd3ba277602cc3e7fdf1e6f90"
markdown = "## Swarm Preflight Contract\n```json\n" + json.dumps(packet) + "\n```\n"
with tempfile.TemporaryDirectory(dir=Path.cwd()) as tmp:
    child = Path(tmp, "git")
    child.write_text(f"#!{sys.executable}\nimport sys, time\n"
                     "assert sys.argv[3:] == ['fetch', '--prune', '--quiet']\n"
                     "time.sleep(4)\nsys.exit(1)\n")
    child.chmod(0o700)
    check = jog_run.stale_evidence_refusal
    with patch.dict(os.environ, {"PATH": tmp + os.pathsep + os.environ["PATH"]}), \
         patch.object(jog_run, "_admission_captures", return_value=[str(doc)]), \
         patch.object(swarm_preflight, "open", lambda *a, **k: io.StringIO(markdown), create=True):
        started = time.monotonic()
        kwargs = {"deadline": started + 1} if "deadline" in inspect.signature(check).parameters else {}
        try:
            reason = check(str(Path.cwd()), 1664, **kwargs)
        except jog_run.ContractError as exc:
            reason = str(exc)
        elapsed = time.monotonic() - started
        print(f"elapsed={elapsed:.2f}s reason={reason!r}")
        assert elapsed < 3 and reason and ("deadline" in reason or "timed out" in reason), reason
PY
