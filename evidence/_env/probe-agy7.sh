#!/usr/bin/env bash
echo "=== npm search antigravity ==="
npm search antigravity --json 2>/dev/null | python3 -c "
import json,sys
try: d=json.load(sys.stdin)
except Exception as e: print('parse fail',e); raise SystemExit
for p in d[:15]: print(' *',p.get('name'),p.get('version'),'-',(p.get('description') or '')[:80])
" 2>&1 | head -20
echo
echo "=== direct package probes ==="
for pkg in "@google/antigravity" "antigravity" "@antigravity/cli" "agy" "@google/agy"; do
  v=$(npm view "$pkg" version 2>/dev/null)
  printf '%-24s %s\n' "$pkg" "${v:-<none>}"
done
echo
echo "=== antigravity docs page ==="
curl -sL --compressed --max-time 25 -o /tmp/agydocs.html -w 'http=%{http_code} bytes=%{size_download}\n' https://antigravity.google/docs/cli
python3 - <<'PY'
import re,html
try: s=open('/tmp/agydocs.html',encoding='utf-8',errors='replace').read()
except Exception as e: print('no page',e); raise SystemExit
t=re.sub(r'<(script|style).*?</\1>','',s,flags=re.S|re.I)
t=html.unescape(re.sub(r'<[^>]+>',' ',t))
t=re.sub(r'\s+',' ',t)
print(t[:1200])
PY
