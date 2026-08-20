#!/usr/bin/env bash
echo "=== Antigravity tools/ + resources bin ==="
find /mnt/c/Users/Askyla/AppData/Local/Programs/Antigravity/tools -maxdepth 2 2>/dev/null | head -20
echo
echo "=== fetch CLI page (gzip-aware) ==="
curl -sL --compressed --max-time 25 https://antigravity.google/product/antigravity-cli -o /tmp/agy2.html -w 'http=%{http_code} bytes=%{size_download}\n'
python3 - <<'PY'
import re,html
s=open('/tmp/agy2.html',encoding='utf-8',errors='replace').read()
t=re.sub(r'<script.*?</script>','',s,flags=re.S|re.I)
t=re.sub(r'<style.*?</style>','',t,flags=re.S|re.I)
t=html.unescape(re.sub(r'<[^>]+>',' ',t))
t=re.sub(r'[ \t]+',' ',t)
t=re.sub(r'\n\s*\n+','\n',t)
print(t[:2500])
print("\n=== install-ish strings in raw ===")
for m in set(re.findall(r'(?:curl|npm i|npm install|brew install|wget|iwr|irm)[^"\'<>\]{0,140}', s)):
    print(" *", m.strip()[:160])
PY
