#!/usr/bin/env python3
"""GH-460 adapter preflight — verifies the ACTUAL decoded wrapper adapter before campaigns.

Decodes the campaign target exactly as fuzz_engine.build_argv does (shlex.split), then:
  1. syntax-checks the bash oracle and the decoded Python payload (ast.parse)
  2. exercises the decoded adapter on seven cases, comparing its printed output against an
     INDEPENDENT direct resolver invocation (a hard-coded-input adapter fails this — the
     constant-input falsification below proves it)
  3. constant-input falsification: a mutated payload that hard-codes the input must FAIL at
     least one case (proves the observation can catch the round-3 failure class)

Exit 0 = preflight OK; exit 1 = any failure. Run from the repo root.
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

def resolver_stdout(inp):
    r = subprocess.run(["bash", RESOLVER, inp], cwd=ROOT, capture_output=True, text=True)
    return r.returncode, r.stdout

target = TARGET_FILE.read_text().strip()
head, _, tail = target.partition("{mutant}")
if not target.endswith("{mutant}") or target.count("{mutant}") != 1:
    fail(f"target must end with exactly one trailing {{mutant}} (got ...{target[-40:]!r})")

prefix_argv = shlex.split(head)
if prefix_argv[:2] != ["python3", "-c"]:
    fail(f"decoded prefix is {prefix_argv[:2]!r}, want ['python3', '-c']")
payload = prefix_argv[2] if len(prefix_argv) > 2 else ""
if "{mutant}" in payload:
    fail("decoded adapter payload contains the placeholder")

try:
    ast.parse(payload)
except SyntaxError as exc:
    fail(f"decoded adapter payload does not parse: {exc}")

oracle_target_prefix = shlex.split("bash " + ORACLE + " ")
if oracle_target_prefix[0] != "bash" or not oracle_target_prefix[1].endswith("gh460-oracle.sh"):
    fail(f"oracle target decode wrong: {oracle_target_prefix[:2]!r}")
if subprocess.run(["bash", "-n", ORACLE], cwd=ROOT).returncode != 0:
    fail("oracle script fails bash -n")

def adapter(args, payload_text=None):
    body = payload_text if payload_text is not None else payload
    argv = ["python3", "-c", body] + list(args)
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
    inp = args[0] if args else ""
    rc_expected, expected = resolver_stdout(inp)
    expected = expected.strip()
    res = adapter(args)
    if res.returncode != 0:
        fail(f"adapter case '{name}': rc={res.returncode} stderr={res.stderr[-200:]!r}")
        continue
    observed = res.stdout.strip()
    # independent observation: the adapter's printed output must equal what the resolver
    # actually produces for that input (or the literal on an expected miss)
    want = expected if rc_expected == 0 else inp
    if observed != want:
        fail(f"adapter case '{name}': observed output {observed!r} != independent resolver expectation {want!r}")
    elif not isinstance(observed, str):
        fail(f"adapter case '{name}': non-string output")

# constant-input falsification: hard-coding the input must be CAUGHT by the independent check
mutated = payload.replace('a[0] if a else ""', '"glm-5.2"')
caught = False
for name, args in cases[1:5]:  # second hit, miss, empty, absent: hard-coded input diverges
    inp = args[0] if args else ""
    rc_expected, expected = resolver_stdout(inp)
    expected = expected.strip()
    want = expected if rc_expected == 0 else inp
    res = adapter(args, payload_text=mutated)
    observed = res.stdout.strip()
    if observed != want:
        caught = True
        print(f"falsification: constant-input mutation caught at case '{name}' ({observed!r} != {want!r})")
        break
if not caught:
    fail("constant-input falsification FAILED: the mutated (hard-coded) adapter passed every case — the independent observation cannot catch the round-3 failure class")

if failures:
    print(f"PREFLIGHT: FAILURES — {len(failures)}", file=sys.stderr)
    sys.exit(1)
print("PREFLIGHT: OK — decoded adapter exercised on all cases; constant-input control falsified correctly")
