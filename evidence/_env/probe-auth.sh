#!/usr/bin/env bash
cd "$HOME/XYZ-forge" || exit 1
. evidence/_env/prelude.sh
echo "=== codex auth ==="
ls -la "$HOME/.codex" 2>&1 | head -20
echo "--- auth.json present? ---"
if [ -f "$HOME/.codex/auth.json" ]; then
  python3 -c "import json,sys;d=json.load(open('$HOME/.codex/auth.json'));print('keys:',sorted(d.keys()));print('has OPENAI_API_KEY:', bool(d.get('OPENAI_API_KEY')));print('has tokens:', bool(d.get('tokens')))" 2>&1
else
  echo "NO auth.json"
fi
echo "--- env ---"
echo "OPENAI_API_KEY set: ${OPENAI_API_KEY:+yes}${OPENAI_API_KEY:-no}"
echo
echo "=== network ==="
curl -s -o /dev/null -w 'github.com %{http_code}\n' --max-time 15 https://github.com 2>&1
curl -s -o /dev/null -w 'sqlite.org %{http_code}\n' --max-time 15 https://sqlite.org 2>&1
echo
echo "=== PATH ==="
echo "$PATH" | tr ':' '\n' | head -20
echo
echo "=== ~/.local/bin ==="
ls -la "$HOME/.local/bin" 2>&1 | head
