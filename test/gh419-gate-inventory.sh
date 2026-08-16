#!/usr/bin/env bash
# gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"self-comparing and self-regenerating fixtures were reported as none"}
# GH-419 — inventory discovery and negative-control evidence must stay separate.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
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

echo "PASS: GH-419 inventory discovers registered gates and records only declared controls"
