#!/usr/bin/env bash
# sentinel-nightly.sh — §2.4. Select eligible PROJECT/2-WORKING docs by PDDA's selection rule and
# (gated) fire marathon-drive.sh serially, capped at SENTINEL_NIGHTLY_MAX, with --require-clean and
# --requires-test. Selection is deterministic/read-only (runs even when inert, as a preview); FIRING
# is gated — inert by default means it only prints what it *would* fire.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$HERE/lib/config.sh"
WORKING="${SENTINEL_WORKING:-PROJECT/2-WORKING}"
MAX="${SENTINEL_NIGHTLY_MAX:-2}"
[ -d "$WORKING" ] || { echo "sentinel-nightly: no $WORKING — nothing to select" >&2; exit 0; }

# Rank eligible docs: eligible = risk<=2 AND ratings_provisional=false; order by effort+complexity,
# then phases. PDDA's rule verbatim. Pure frontmatter parse — no egress.
eligible=()   # portable fill (macOS bash 3.2 has no mapfile)
while IFS= read -r _row; do [ -n "$_row" ] && eligible+=("$_row"); done < <(
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
    v=g(k);
    try: return int(v)
    except: return dv
risk=i("risk"); prov=(g("ratings_provisional","true")=="true")
if risk<=2 and not prov:
    print(f"{i('effort')+i('complexity')}\t{i('phases')}\t{p}")
PY
  done | sort -n
)

if [ "${#eligible[@]}" -eq 0 ]; then echo "sentinel-nightly: 0 eligible (risk<=2, ratings confirmed)"; exit 0; fi

fired=0
for row in "${eligible[@]}"; do
  [ "$fired" -lt "$MAX" ] || { echo "sentinel-nightly: hit nightly cap ($MAX)"; break; }
  doc="${row##*$'\t'}"
  if sentinel_active; then
    echo "sentinel-nightly: firing lane for $doc"
    # gated real fire — serial, clean, test-gated
    "$HERE/../relay-automation/marathon-drive.sh" --phase-brief "$doc" \
      --builder codex --reviewer agy --require-clean --requires-test "bash validate.sh" \
      || echo "sentinel-nightly: lane returned nonzero for $doc (parked/escalated — surfaced in report)"
  else
    echo "sentinel-nightly: WOULD fire (inert) → $doc"
  fi
  fired=$((fired+1))
done
