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
- path: src/alpha.js
- symptom: first symptom
- suspected_cause: first cause
- probe: printf alpha

### Side Finding
- path: src/beta.js
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

# Adversarial: quote + backslash + control bytes (form-feed, escape) in BOTH scope and message —
# every dynamic field must escape/normalize so the line stays valid JSON with the full 10-key shape.
ADV_SCOPE="$(printf 'sc\fo"pe')"
ADV_MSG="$(printf 'm\033sg "q" \\b')"
DEBUG_LOG_FILE="$MANUAL_LOG" "$FINDING_NEW" --scope "$ADV_SCOPE" --severity warn "$ADV_MSG" >/dev/null
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
# exact 10-key PDDA contract, in order
assert list(row.keys()) == ["timestamp","severity","check","scope","repo","file","line","message","action","probe"], list(row.keys())
assert row["check"] == "manual" and row["severity"] == "warn" and row["action"] == "triage"
assert row["file"] == "" and row["line"] == "" and row["probe"] == ""
# controls normalized to space; quote/backslash survive JSON round-trip
assert row["scope"] == 'sc o"pe', repr(row["scope"])
assert row["message"] == 'm sg "q" \\b', repr(row["message"])
PY

# --- adversarial escaping + boundary coverage (harvester, Should #3) ----------
ADV_FIXTURE="$WORK/adv.md"; ADV_LOG="$WORK/adv.jsonl"
printf '%s\n' \
  '# Heading before any block' \
  '### Side Finding' \
  '- path: src/gamma.js' \
  '- symptom: has "quotes" and \back' \
  '- suspected_cause: edge' \
  $'- probe: tab\there' \
  '---' \
  'prose after a thematic break (must not join the block)' \
  '### Side Finding' \
  '- path: src/delta.js' \
  '- symptom: second' \
  '- suspected_cause: cause2' \
  '- probe: printf second' \
  '# trailing heading' > "$ADV_FIXTURE"

"$HARVEST" --relay "$ADV_FIXTURE" --scope "adv" --repo "fx" --out "$ADV_LOG"
[[ "$(wc -l < "$ADV_LOG" | tr -d ' ')" -eq 2 ]] || {
  echo "FAIL: adversarial harvest should emit 2 lines (--- and # are flush boundaries)" >&2
  exit 1
}
python3 -c 'import json,sys;[json.loads(l) for l in sys.stdin]' < "$ADV_LOG"
python3 - "$ADV_LOG" <<'PY'
import json, sys
r = [json.loads(line) for line in open(sys.argv[1], encoding="utf-8")]
assert len(r) == 2, r
assert r[0]["probe"] == "tab here", repr(r[0]["probe"])   # literal tab escaped to a space
assert '"quotes"' in r[0]["message"], r[0]["message"]     # quote survives JSON round-trip
assert "\\back" in r[0]["message"], r[0]["message"]       # backslash survives JSON round-trip
assert r[1]["probe"] == "printf second", r[1]["probe"]
PY

# CRLF + non-tab control byte (form-feed) must normalize to space (awk [[:cntrl:]]), not leak raw.
CRLF_FIXTURE="$WORK/crlf.md"; CRLF_LOG="$WORK/crlf.jsonl"
printf '### Side Finding\r\n- path: src/e.js\r\n- symptom: crlf\r\n- suspected_cause: c\r\n- probe: a\fb\r\n# end\r\n' > "$CRLF_FIXTURE"
"$HARVEST" --relay "$CRLF_FIXTURE" --scope "cr" --repo "fx" --out "$CRLF_LOG"
python3 -c 'import json,sys;[json.loads(l) for l in sys.stdin]' < "$CRLF_LOG"
python3 - "$CRLF_LOG" <<'PY'
import json, sys, re
r = [json.loads(line) for line in open(sys.argv[1], encoding="utf-8")]
assert len(r) == 1, r
# no raw C0 control byte survived in any value
for v in r[0].values():
    assert not re.search(r"[\x00-\x1f\x7f]", v), repr(v)
assert r[0]["probe"].strip() == "a b", repr(r[0]["probe"])   # form-feed + trailing CR both normalized
PY

echo "PASS: sentinel Tier-1 JSONL capture"
