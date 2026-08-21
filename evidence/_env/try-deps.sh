#!/usr/bin/env bash
cd "$HOME/XYZ-forge" || exit 1
. evidence/_env/prelude.sh
echo "=== sudo cached? ==="
if sudo -n true 2>/dev/null; then
  echo "SUDO: cached OK"
  echo "=== apt-get install sqlite3 jq ==="
  sudo -n apt-get install -y sqlite3 jq
  echo "APT_RC=$?"
else
  echo "SUDO: NOT cached (password still required)"
fi
echo
echo "=== verify ==="
for b in sqlite3 jq; do
  p="$(command -v "$b" 2>/dev/null)"
  printf '%-10s %s' "$b" "${p:-MISSING}"
  [ -n "$p" ] && printf '  (%s)' "$("$b" --version 2>&1 | head -1)"
  echo
done
echo
echo "=== codex auth now? ==="
[ -f "$HOME/.codex/auth.json" ] && echo "auth.json PRESENT ($(stat -c%s "$HOME/.codex/auth.json") bytes)" || echo "auth.json ABSENT"
