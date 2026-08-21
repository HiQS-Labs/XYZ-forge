#!/usr/bin/env bash
cd "$HOME/XYZ-forge" || exit 1
. evidence/_env/prelude.sh
echo "=== WSL-side claude creds ==="
ls -la "$HOME/.claude/" 2>&1 | grep -iE 'cred|json|settings' || echo "(none matched)"
[ -f "$HOME/.claude/.credentials.json" ] && echo "WSL .credentials.json PRESENT" || echo "WSL .credentials.json ABSENT"
echo
echo "=== Windows-side claude creds ==="
[ -f /mnt/c/Users/Askyla/.claude/.credentials.json ] && echo "WIN .credentials.json PRESENT" || echo "WIN .credentials.json ABSENT"
echo "ANTHROPIC_API_KEY set: ${ANTHROPIC_API_KEY:+yes}"; echo "${ANTHROPIC_API_KEY:-  (unset)}" | sed 's/./x/g' | head -1
echo
echo "=== what marathon.sh accepts for --builder ==="
grep -n -- '--builder' relay-automation/marathon.sh | head -20
echo "--- builder validation ---"
grep -n -iE 'builder.*(codex|claude|agy)|BUILDER=' relay-automation/marathon-drive.sh | head -30
