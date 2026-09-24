#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Testing prior_art_recon.py..."
python3 "$ROOT/utils/py/prior_art_recon.py" --query "lock" --json > /tmp/prior_art_test.json
[ -s /tmp/prior_art_test.json ] || { echo "FAIL: output JSON empty"; exit 1; }

python3 -c "
import json
data = json.load(open('/tmp/prior_art_test.json'))
assert data['status'] == 'PASS', 'Status must be PASS'
assert 'open_prs' in data, 'Missing open_prs'
assert 'existing_helpers' in data, 'Missing existing_helpers'
"
echo "PASS: prior_art_recon.py verified"
