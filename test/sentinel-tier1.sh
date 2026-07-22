#!/usr/bin/env bash
# test/sentinel-tier1.sh — acceptance tests for Tier-1 JSONL finding capture.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARVEST="$HERE/../relay-automation/harvest-findings.sh"
FINDING_NEW="$HERE/../relay-automation/finding-new.sh"

[[ -x "$HARVEST" ]] || { echo "FAIL: not executable: $HARVEST" >&2; exit 1; }
[[ -x "$FINDING_NEW" ]] || { echo "FAIL: not executable: $FINDING_NEW" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/sentinel-tier1.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

RELAY_FIXTURE="$WORK/RELAY.md"
HARVEST_LOG="$WORK/harvest.jsonl"
MANUAL_LOG="$WORK/manual.jsonl"

cat > "$RELAY_FIXTURE" <<'EOF'
# Relay fixture

### Side Finding
- path: relay-automation/alpha.sh
- symptom: first symptom
- suspected_cause: first cause
- probe: printf alpha

### Side Finding
- path: relay-automation/beta.sh
- symptom: second symptom
- suspected_cause: second cause
- probe: printf beta

## Next section
EOF

"$HARVEST" --relay "$RELAY_FIXTURE" --scope "tier1-fixture" --repo "fixture/repo" --out "$HARVEST_LOG"

[[ "$(wc -l < "$HARVEST_LOG" | tr -d ' ')" -eq 2 ]] || {
  echo "FAIL: harvest should emit exactly 2 JSONL lines" >&2
  exit 1
}
python3 -c 'import json,sys;[json.loads(l) for l in sys.stdin]' < "$HARVEST_LOG"
python3 - "$HARVEST_LOG" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as stream:
    rows = [json.loads(line) for line in stream]
assert [row["check"] for row in rows] == ["marathon.side-finding"] * 2
assert [row["scope"] for row in rows] == ["tier1-fixture"] * 2
assert [row["probe"] for row in rows] == ["printf alpha", "printf beta"]
PY

DEBUG_LOG_FILE="$MANUAL_LOG" "$FINDING_NEW" --scope "manual-fixture" --severity info 'one "quoted" finding' >/dev/null
[[ "$(wc -l < "$MANUAL_LOG" | tr -d ' ')" -eq 1 ]] || {
  echo "FAIL: finding-new should emit exactly 1 JSONL line" >&2
  exit 1
}
python3 -c 'import json,sys;[json.loads(l) for l in sys.stdin]' < "$MANUAL_LOG"
python3 - "$MANUAL_LOG" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as stream:
    row = json.loads(stream.readline())
assert row["check"] == "manual"
assert row["scope"] == "manual-fixture"
assert row["severity"] == "info"
assert row["message"] == 'one "quoted" finding'
PY

echo "PASS: sentinel Tier-1 JSONL capture"
