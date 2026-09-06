#!/usr/bin/env python3
"""GH-460 adapter preflight — verifies the ACTUAL decoded wrapper adapter before campaigns.

Reads the campaign target from wrapper-target.txt (single source of truth), decodes it the
same way fuzz_engine.build_argv does (shlex.split), asserts the argv mapping, syntax-checks
and exercises the DECODED adapter payload on: a sample mutant, two known hits, an observed
miss, the empty input, absent input, and extra-argument input.

Exit 0 = preflight OK; exit 1 = any failure (with the case named on stderr).
Run from the repo root: python3 TESTS-RESULTS/2026-09-06+GH-460/preflight.py
"""
import ast
import shlex
import subprocess
import sys
from pathlib import Path

TARGET_FILE = Path(__file__).parent / "wrapper-target.txt"
ORACLE = "test/gh460-oracle.sh"
RESOLVER = "relay-automation/resolve-model-alias.sh"
ROOT = sys.argv[1] if len(sys.argv) > 1 else "."

failures = []


def fail(msg):
    failures.append(msg)
    print(f"PREFLIGHT FAIL: {msg}", file=sys.stderr)


target = TARGET_FILE.read_text().strip()
head, _, tail = target.partition("{mutant}")

# 1. decoded argv mapping: engine inserts every mutant token after the fixed prefix
prefix_argv = shlex.split(head)
if prefix_argv[:2] != ["python3", "-c"]:
    fail(f"decoded prefix is {prefix_argv[:2]!r}, want ['python3', '-c']")
payload = prefix_argv[2] if len(prefix_argv) > 2 else ""
if not target.endswith("{mutant}") or target.count("{mutant}") != 1:
    fail(f"target must end with exactly one trailing {{mutant}} (target repr: {target[-60:]!r})")
if "{mutant}" in payload:
    fail("decoded adapter payload must not contain the {mutant} placeholder")

# 2. the DECODED payload must be valid Python
try:
    ast.parse(payload)
except SyntaxError as exc:
    fail(f"decoded adapter payload does not parse: {exc}")
    print("PREFLIGHT: FAILURES —", len(failures), file=sys.stderr)
    sys.exit(1)

# 3. exercise the DECODED adapter exactly as the engine would build it
def adapter(args):
    """Run the decoded payload with the engine's argv shape: payload, then mutant tokens."""
    argv = ["python3", "-c", payload] + list(args)
    return subprocess.run(argv, cwd=ROOT, capture_output=True, text=True)


cases = [
    ("sample mutant", ["sample-mutant"]),
    ("known hit", ["glm-5.2"]),
    ("second known hit", ["deepseek v4 pro"]),
    ("observed miss", ["totally-unknown-model-xyz"]),
    ("empty input", [""]),
    ("absent input", []),
    ("extra arguments", ["glm-5.2", "extra-token"]),
]
for name, args in cases:
    res = adapter(args)
    if res.returncode != 0:
        fail(f"adapter case '{name}': rc={res.returncode} stderr={res.stderr[-200:]!r}")
    else:
        print(f"preflight: adapter case '{name}' OK")

if failures:
    print(f"PREFLIGHT: FAILURES — {len(failures)}", file=sys.stderr)
    sys.exit(1)
print("PREFLIGHT: OK — decoded adapter exercised on all cases")
