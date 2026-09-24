#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_JSON="$(mktemp /tmp/prior_art_test_XXXXXX.json)"
trap 'rm -f "$TMP_JSON"' EXIT

echo "Testing prior_art_recon.py (query: gate)..."
python3 "$ROOT/utils/py/prior_art_recon.py" --query "gate" --json > "$TMP_JSON"
[ -s "$TMP_JSON" ] || { echo "FAIL: output JSON empty"; exit 1; }

python3 -c "
import json
data = json.load(open('$TMP_JSON'))
assert data['status'] in ('PASS', 'WARN'), f'Unexpected status: {data[\"status\"]}'
assert 'open_prs' in data, 'Missing open_prs'
assert 'roadmap_items' in data, 'Missing roadmap_items'
assert 'existing_helpers' in data, 'Missing existing_helpers'
assert isinstance(data['roadmap_items'], list), 'roadmap_items must be a list'
print(f'Verified: {data[\"open_prs_count\"]} PRs, {data[\"roadmap_items_count\"]} roadmap items, {data[\"existing_helpers_count\"]} helpers')
"

echo "Testing prior_art_recon.py empty query..."
python3 "$ROOT/utils/py/prior_art_recon.py" --json > "$TMP_JSON"
python3 -c "
import json
data = json.load(open('$TMP_JSON'))
assert data['status'] in ('PASS', 'WARN')
assert isinstance(data['roadmap_items'], list)
"

echo "PASS: prior_art_recon.py verified"
