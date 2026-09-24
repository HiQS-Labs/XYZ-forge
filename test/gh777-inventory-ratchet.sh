#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Testing inventory ratchet..."
python3 "$ROOT/utils/pdda/check_inventory_ratchet.py" --check
echo "PASS: inventory ratchet clean"
