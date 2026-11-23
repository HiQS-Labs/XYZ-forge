"""GH-1232 manual smoke (GH-1088): drive promote_contract_to_working(interactive=False) in a
disposable full clone. Usage: python3 smoke.py <clone-root> [<jog_run.py to load>]

The primary pin and the clone-side commit are stubbed: they guard the operator's ledger, not the
probe decision under test. Each case writes a fresh 1-INBOX doc, promotes it, and prints the result.
"""
import importlib.util
import os
import subprocess
import sys

root = os.path.abspath(sys.argv[1])
jog_path = sys.argv[2] if len(sys.argv) > 2 else os.path.join(root, "utils", "py", "jog_run.py")
sys.path.insert(0, os.path.join(root, "utils", "py"))
spec = importlib.util.spec_from_file_location("jog_run_under_test", jog_path)
jog = importlib.util.module_from_spec(spec)
spec.loader.exec_module(jog)
jog._require_jog_primary = lambda *a, **k: None
jog.jog_commit_execution_contract = lambda *a, **k: None

FM = "---\ntitle: smoke\nstatus: Proposed\ncreated: 2026-10-27\n---\n\n# smoke\n"


def contract(probes):
    import json
    body = {"target": {"repo": ".", "ref": "development"}, "gate": "bash validate.sh",
            "fix_probes": probes, "artifacts": ["README.md"]}
    return f"\n## Swarm Preflight Contract\n\n```json\n{json.dumps(body, indent=1)}\n```\n"


CASES = [
    ("main: well-formed contract, no frontmatter probes",
     FM + contract([{"type": "grep_present", "path": "README.md", "pattern": "XYZ"},
                    {"type": "path_absent", "path": "no/such/file.md"}])),
    ("adjacent: no probes anywhere", FM),
    ("adjacent: command probe 'true' (lint)", FM + contract([{"type": "command", "cmd": "true"}])),
    ("adjacent: non-object probe", FM + contract(["x"])),
    ("adjacent: no execution (command would touch a marker)",
     FM + contract([{"type": "command", "cmd": "touch .promotion-ran && false"}])),
    ("adjacent: non-object contract (top-level [] JSON, final QA r1)",
     FM + "\n## Swarm Preflight Contract\n\n```json\n[]\n```\n"),
]

for n, (label, text) in enumerate(CASES, 9001):
    doc = os.path.join(root, "PROJECT", "1-INBOX", f"GH-{n}-SMOKE.md")
    with open(doc, "w", encoding="utf-8") as f:
        f.write(text)
    path, reason = jog.promote_contract_to_working(root, str(n), doc, interactive=False,
                                                    primary="/nonexistent-other-primary")
    verdict = "PROMOTED" if path else "PARKED"
    print(f"[{n}] {label}\n      -> {verdict}: {os.path.relpath(path, root) if path else reason}")
    for p in (doc, os.path.join(root, "PROJECT", "2-WORKING", f"GH-{n}-SMOKE.md")):
        if os.path.exists(p):
            os.remove(p)
    subprocess.run(["git", "reset", "-q"], cwd=root)

marker = os.path.join(root, ".promotion-ran")
print(f"marker .promotion-ran exists after all cases: {os.path.exists(marker)}")
