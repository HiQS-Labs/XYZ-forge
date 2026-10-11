#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_JSON="$(mktemp /tmp/prior_art_test_XXXXXX.json)"
STUB_DIR="$(mktemp -d /tmp/prior_art_stub_XXXXXX)"
trap 'rm -rf "$TMP_JSON" "$STUB_DIR"' EXIT

echo "Testing prior_art_recon.py (query: gate)..."
python3 "$ROOT/utils/py/prior_art_recon.py" --query "gate" --json > "$TMP_JSON"
[ -s "$TMP_JSON" ] || { echo "FAIL: output JSON empty"; exit 1; }

python3 -c "
import json
data = json.load(open('$TMP_JSON'))
assert data['status'] in ('PASS', 'WARN', 'UNKNOWN'), f'Unexpected status: {data[\"status\"]}'
if data['status'] == 'UNKNOWN':
    assert len(data.get('errors', [])) > 0, 'UNKNOWN status must report errors'
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

# GH-1025: merged PRs, issues, sibling repos and the REST fallback, against a stub gh.
cat > "$STUB_DIR/gh" <<'STUB'
#!/usr/bin/env bash
echo "$*" >> "$STUB_DIR/calls.log"
case "$1 $*" in
  "pr "*"--state open"*)   [ "$STUB_MODE" = rest ] && exit 1; echo '[{"number":5,"title":"wip widget","url":"u5","state":"OPEN","headRefName":"feat/w"}]' ;;
  "pr "*"--state merged"*) [ "$STUB_MODE" = rest ] && exit 1; echo '[{"number":7,"title":"fix widget","url":"u7","state":"MERGED","headRefName":"fix/w","mergedAt":"2099-01-01T00:00:00Z"}]' ;;
  "issue "*)               [ "$STUB_MODE" = rest ] && exit 1; echo '[{"number":8,"title":"widget broken","url":"u8","state":"CLOSED","stateReason":"COMPLETED"},{"number":9,"title":"widget idea","url":"u9","state":"OPEN","stateReason":null}]' ;;
  "api "*"/issues?"*) echo '[{"number":8,"title":"widget broken","body":"","html_url":"u8","state":"closed","state_reason":"completed"},{"number":10,"title":"widget PR","pull_request":{},"html_url":"u10","state":"open"},{"number":11,"title":"unrelated","html_url":"u11","state":"open"}]' ;;
  "api "*"pulls?state=closed"*) echo '[{"number":7,"title":"Fixes the thing","body":"Fixes #8 widget","html_url":"u7","state":"closed","merged_at":"2099-01-01T00:00:00Z","head":{"ref":"fix/w"}},{"number":6,"title":"widget old","html_url":"u6","state":"closed","merged_at":"2000-01-01T00:00:00Z","head":{"ref":"x"}}]' ;;
  "api "*"pulls?state=open"*) echo '[]' ;;
  *) exit 1 ;;
esac
STUB
chmod +x "$STUB_DIR/gh"

for MODE in list rest; do
  echo "Testing prior_art_recon.py merged PRs + issues via stub gh ($MODE)..."
  : > "$STUB_DIR/calls.log"
  STUB_MODE="$MODE" STUB_DIR="$STUB_DIR" PATH="$STUB_DIR:$PATH" \
    python3 "$ROOT/utils/py/prior_art_recon.py" --query "widget" --repo acme/sibling --json > "$TMP_JSON"
  python3 -c "
import json
d = json.load(open('$TMP_JSON'))
assert not any('GitHub' in e for e in d['errors']), d['errors']
assert [p['number'] for p in d['merged_prs']] == [7, 7], d['merged_prs']
assert {p['repo'] for p in d['merged_prs']} == {'current', 'acme/sibling'}, d['merged_prs']
assert sorted(c['number'] for c in d['existing_fix_candidates']) == [7, 7, 8, 8], d['existing_fix_candidates']
assert 10 not in [i['number'] for i in d['issues']], 'PRs must not be reported as issues'
"
  grep -q -e "--repo acme/sibling" -e "repos/acme/sibling/" "$STUB_DIR/calls.log" \
    || { echo "FAIL: sibling repo not scanned"; exit 1; }
done
echo "  stub gh: list and REST fallback paths verified"

echo "PASS: prior_art_recon.py verified"
