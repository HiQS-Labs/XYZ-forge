"""Run the actual fixture suite with one controlled, in-memory defect.

This is evidence tooling, not a replacement implementation or gate. All mutations
remain in _setup.sh's owned sandbox. The tracked suite is never rewritten.
"""
import hashlib
from pathlib import Path
import subprocess
import sys

mode = sys.argv[1]
suite = Path(__file__).resolve().parents[2] / "test/gh642-consumer-fruit.sh"
source = suite.read_text()
print(f"mode={mode} suite_sha256={hashlib.sha256(source.encode()).hexdigest()}", flush=True)
if mode == "guard-disabled":
    needle = 'caller_before="$(git -C "$A" rev-parse HEAD)"'
    replacement = 'require_fixture() { :; }\n' + needle
elif mode == "caller-damaged":
    needle = '  [ "$(git -C "$A" rev-parse HEAD)" = "$caller_before" ]'
    replacement = ('  git -C "$A" -c user.name=fixture -c user.email=fixture@test.invalid '
                   'commit -q --allow-empty -m controlled-caller-damage\n' + needle)
else:
    raise SystemExit("choose guard-disabled or caller-damaged")
if source.count(needle) != 1:
    raise SystemExit("control anchor absent/ambiguous; refusing to report an empty test")
result = subprocess.run(["bash", "-c", source.replace(needle, replacement, 1), str(suite)])
raise SystemExit(result.returncode)
