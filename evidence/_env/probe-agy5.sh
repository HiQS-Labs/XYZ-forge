#!/usr/bin/env bash
D=/mnt/c/Users/Askyla/AppData/Local/Programs/Antigravity
echo "=== top level ==="
ls -1 "$D" 2>&1 | head -30
echo
echo "=== anything named agy ==="
find "$D" -iname '*agy*' -maxdepth 4 2>/dev/null | head -20
echo
echo "=== bin dir ==="
ls -1 "$D/bin" 2>&1 | head -20
echo
echo "=== gemini/antigravity state (auth?) ==="
ls -la /mnt/c/Users/Askyla/.gemini/ 2>&1 | head -20
ls -la /mnt/c/Users/Askyla/.antigravity 2>&1 | head -10
echo
echo "=== install page hints ==="
python3 - <<'PY'
import re,html
try:
    s=open('/tmp/agy-page.html',encoding='utf-8',errors='replace').read()
except Exception as e:
    print("no page:",e); raise SystemExit
t=re.sub(r'<script.*?</script>','',s,flags=re.S|re.I)
t=re.sub(r'<style.*?</style>','',t,flags=re.S|re.I)
t=html.unescape(re.sub(r'<[^>]+>',' ',t))
t=re.sub(r'\s+',' ',t)
print(t[:1800])
PY
