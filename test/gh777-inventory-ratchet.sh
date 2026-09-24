#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Testing inventory ratchet on live tree..."
python3 "$ROOT/utils/pdda/check_inventory_ratchet.py" --check

echo "Testing ratchet rejection of growth..."
TMP_TEST_DIR="$(mktemp -d /tmp/ratchet_test_XXXXXX)"
trap 'rm -rf "$TMP_TEST_DIR"' EXIT

# Copy baseline and script to mock environment
mkdir -p "$TMP_TEST_DIR/utils/pdda"
cp "$ROOT/utils/pdda/check_inventory_ratchet.py" "$TMP_TEST_DIR/utils/pdda/"
cp "$ROOT/utils/pdda/inventory_ratchet_baseline.json" "$TMP_TEST_DIR/utils/pdda/"

# Add a rogue script in mock repo
mkdir -p "$TMP_TEST_DIR/scripts"
echo "#!/usr/bin/env bash" > "$TMP_TEST_DIR/scripts/rogue_script.sh"

set +e
OUT=$(python3 "$TMP_TEST_DIR/utils/pdda/check_inventory_ratchet.py" --check 2>&1)
RC=$?
set -e

if [ $RC -eq 0 ]; then
  echo "FAIL: ratchet failed to block rogue script addition"
  exit 1
fi

if [[ "$OUT" != *"NEW script added"* ]]; then
  echo "FAIL: unexpected output: $OUT"
  exit 1
fi

echo "PASS: inventory ratchet enforcement and negative controls verified"
