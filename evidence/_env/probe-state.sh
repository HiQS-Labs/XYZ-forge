#!/usr/bin/env bash
cd "$HOME/XYZ-forge" || exit 1
. evidence/_env/prelude.sh
echo "=== DEPS ==="
for b in sqlite3 jq gh node npm python3 codex agy claude git curl tar; do
  p="$(command -v "$b" 2>/dev/null)"
  printf '%-10s %s\n' "$b" "${p:-MISSING}"
done
echo
echo "=== VERSIONS ==="
node --version 2>&1
npm --version 2>&1
codex --version 2>&1
echo
echo "=== PDDA ==="
ls -la utils/pdda/ 2>&1 | head -20
echo "--- pdda.sh status ---"
bash utils/pdda/pdda.sh --help 2>&1 | head -25
