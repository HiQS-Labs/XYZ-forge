#!/usr/bin/env bash
echo "=== agy anywhere on Linux ==="
for p in "$HOME/.local/bin/agy" "$HOME/.antigravity/bin/agy" /usr/local/bin/agy; do
  [ -e "$p" ] && echo "FOUND $p" || echo "absent $p"
done
echo
echo "=== Antigravity on Windows side ==="
ls -d /mnt/c/Users/Askyla/AppData/Local/Programs/*ntigravity* 2>/dev/null || echo "no Programs/*Antigravity*"
ls -d /mnt/c/Users/Askyla/.antigravity 2>/dev/null || echo "no ~/.antigravity (win)"
find /mnt/c/Users/Askyla/AppData/Local/Programs -maxdepth 1 -iname '*antigrav*' 2>/dev/null | head
find /mnt/c/Users/Askyla -maxdepth 3 -iname 'agy*' 2>/dev/null | head
echo
echo "=== npm registry: is there an agy/antigravity package? ==="
npm view @google/antigravity-cli version 2>&1 | head -3
npm view antigravity-cli version 2>&1 | head -3
echo
echo "=== curl the CLI install page ==="
curl -sL --max-time 20 https://antigravity.google/product/antigravity-cli -o /tmp/agy-page.html -w 'http=%{http_code} bytes=%{size_download}\n' 2>&1
grep -oiE '(curl|npm|brew|wget)[^<"]{0,120}' /tmp/agy-page.html 2>/dev/null | head -20
