#!/usr/bin/env bash
# gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"self-comparing and self-regenerating fixtures were reported as none"}
# GH-419 — inventory discovery and negative-control evidence must stay separate.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/test/lib/fixture-guard.sh"
require_forge_root validate.sh   # GH-708: forge-root only — witnessed skip in a vendored .xyz/
FIXTURE="$(mktemp -d "${TMPDIR:-/tmp}/gh419-gate-inventory.XXXXXX")"
trap 'rm -rf "$FIXTURE"' EXIT

mkdir -p "$FIXTURE/test"
cat >"$FIXTURE/validate.sh" <<'EOF'
TESTS=(
  "safe.sh"
  "self-comparing.sh"
  "self-regenerating.sh"
  "new-gate.sh"
)
EOF

cat >"$FIXTURE/test/safe.sh" <<'EOF'
# gate-evidence: {"form":"deliberate-mutation","observed":true,"result":"mutation made this fixture fail"}
test "safe" = "safe"
EOF
cat >"$FIXTURE/test/self-comparing.sh" <<'EOF'
# gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"this declaration must not override the shape"}
cmp "$candidate" "$candidate"
EOF
cat >"$FIXTURE/test/self-regenerating.sh" <<'EOF'
# gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"this declaration must not override the shape"}
generate-report > "$EXPECTED_SNAPSHOT"
diff "$EXPECTED_SNAPSHOT" "$actual"
EOF
cat >"$FIXTURE/test/new-gate.sh" <<'EOF'
test "new gate" = "new gate"
EOF

python3 "$HERE/utils/py/gate_inventory.py" --root "$FIXTURE" >"$FIXTURE/inventory.json"
python3 - "$FIXTURE/inventory.json" <<'PY'
import json
import sys

report = json.load(open(sys.argv[1], encoding="utf-8"))
gates = {row["gate"]: row for row in report["gates"]}
assert set(gates) == {
    "test/safe.sh",
    "test/self-comparing.sh",
    "test/self-regenerating.sh",
    "test/new-gate.sh",
}, gates
assert gates["test/safe.sh"]["negative_control"]["form"] == "deliberate-mutation"
assert gates["test/safe.sh"]["negative_control"]["observed"] is True
for gate, shape in (
    ("test/self-comparing.sh", "self-comparing-parity"),
    ("test/self-regenerating.sh", "self-regenerating-drift"),
):
    row = gates[gate]
    assert shape in row["disqualifying_shapes"], row
    assert row["negative_control"]["form"] == "none", row
    assert row["negative_control"]["observed"] is False, row
assert gates["test/new-gate.sh"]["negative_control"]["form"] == "none"
assert gates["test/new-gate.sh"]["negative_control"]["observed"] is False
PY

python3 "$HERE/utils/py/gate_inventory.py" --root "$HERE" >"$FIXTURE/repo-inventory.json"
python3 - "$FIXTURE/repo-inventory.json" <<'PY'
import json
import sys

gates = {row["gate"]: row for row in json.load(open(sys.argv[1], encoding="utf-8"))["gates"]}
row = gates["test/gh419-gate-inventory.sh"]
assert row["negative_control"]["form"] == "controlled-bad-fixture", row
assert row["negative_control"]["observed"] is True, row
PY

# GH-805: parser and advisory decisions must reject bad inputs without inventing authority.
python3 - "$HERE" "$FIXTURE" <<'PY805'
import hashlib, importlib.util, json, pathlib, sys
root, fixture = map(pathlib.Path, sys.argv[1:])
spec = importlib.util.spec_from_file_location('inventory', root/'utils/py/gate_inventory.py')
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
registry = fixture/'validate.sh'; original = registry.read_text()
registry.write_text('TESTS=(\n # "ignored.sh"\n "safe.sh"\n)\n')
assert m.registered_gates(fixture) == ['safe.sh']
for body in ['TESTS=(\n)\n', 'TESTS=(\n "safe.sh" "safe.sh"\n)\n', 'TESTS=(\n "$dynamic.sh"\n)\n']:
    registry.write_text(body)
    try: m.registered_gates(fixture)
    except ValueError: pass
    else: raise AssertionError('invalid registry accepted: '+body)
registry.write_text(original)
file = fixture/'test/safe.sh'
record = {k:'example' for k in ('id','behavior','consequence','issue','overlap','reason','review_source','routing','red_evidence')}
record.update(outcome='extend', proposer='builder', reviewer='independent-advisory', content={'test/safe.sh':hashlib.sha256(file.read_bytes()).hexdigest()})
path = fixture/'decisions.json'
def view(records):
    path.write_text(json.dumps(records)); return m.decision_view(fixture.resolve(), path)['decisions'][0]
valid = view([record]); assert not valid['metadata_errors']
assert valid['approval_trusted'] is False and valid['would_refuse_mandatory'] is True
assert view([{**record, 'approved':True, 'approval_trusted':True}])['approval_trusted'] is False
assert 'self-issued review' in view([{**record,'reviewer':'builder'}])['metadata_errors']
assert view([{**record,'content':{'test/safe.sh':'0'*64}}])['metadata_errors']
assert view([{**record,'content':{'missing.py':'0'*64}}])['metadata_errors']
assert view([{**record,'content':{'../escape.py':'0'*64}}])['metadata_errors']
assert view([{**record,'reason':''}])['metadata_errors']
for records in [[], {}, [None]]:
    try: view(records)
    except ValueError: pass
    else: raise AssertionError('invalid decision input accepted')
print('PASS: parser rejects empty/duplicate/dynamic input; advisory metadata never authenticates approval')
PY805

echo "PASS: GH-419 inventory discovers registered gates and records only declared controls"
