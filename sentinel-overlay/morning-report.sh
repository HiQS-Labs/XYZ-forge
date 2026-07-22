#!/usr/bin/env bash
# morning-report.sh — §2.7. One local markdown summary of the pipeline: findings captured (by scope
# + severity), drafted in 1-INBOX, eligible vs route-to-human in 2-WORKING, and blocked/parked lanes.
# Purely local: reads files and prints. NO egress — safe to run whether or not the overlay is active.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEBUG_LOG="${SENTINEL_DEBUG_LOG:-debug.log}"
INBOX="${SENTINEL_INBOX:-PROJECT/1-INBOX}"
WORKING="${SENTINEL_WORKING:-PROJECT/2-WORKING}"

echo "# Sentinel morning report"
echo

if [ -f "$DEBUG_LOG" ]; then
  echo "## debug.log — captured findings"
  python3 - "$DEBUG_LOG" <<'PY' || echo "(could not parse debug.log)"
import json,sys,collections
c=collections.Counter()
for ln in open(sys.argv[1],encoding="utf-8"):
    ln=ln.strip()
    if not ln: continue
    try: o=json.loads(ln)
    except Exception: continue
    c[(o.get("scope","?"),o.get("severity","?"))]+=1
if not c: print("(none)")
for (scope,sev),n in sorted(c.items()):
    print(f"- {scope} · {sev}: {n}")
PY
else
  echo "## debug.log — not present (Tier-1 capture off or no findings yet)"
fi
echo

echo "## 1-INBOX — drafted captures"
n=$(find "$INBOX" -maxdepth 1 -name 'F-*.md' 2>/dev/null | wc -l | tr -d ' ')
echo "- sentinel-drafted docs: ${n:-0}"
echo

echo "## 2-WORKING — eligible vs route-to-human"
if [ -d "$WORKING" ]; then
  for d in "$WORKING"/*.md; do [ -f "$d" ] || continue
    python3 - "$d" <<'PY'
import sys,re
p=sys.argv[1]; t=open(p,encoding="utf-8").read()
m=re.search(r"^---\n(.*?)\n---",t,re.S)
if not m: sys.exit(0)
fm=m.group(1)
def g(k,dv=None):
    mm=re.search(rf"^{k}:\s*(.+)$",fm,re.M); return mm.group(1).strip() if mm else dv
def i(k,dv=99):
    try: return int(g(k))
    except: return dv
risk=i("risk"); prov=(g("ratings_provisional","true")=="true")
label="route-to-human" if (risk>=4 or prov) else ("needs-ack" if risk==3 else "eligible")
print(f"- {label}: {p.split('/')[-1]} (risk={risk}, provisional={prov})")
PY
  done
else
  echo "- (no 2-WORKING dir)"
fi
