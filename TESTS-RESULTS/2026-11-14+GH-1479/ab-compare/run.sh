#!/bin/bash
# usage: run.sh <label> ; executor = verify clone at its current checkout
V="$1"; T="$2"; OUTROOT="$3"; L="$4"
export SWARM_PREFLIGHT_NOW=2026-11-14T00:00:00Z SWARM_PREFLIGHT_TODAY=2026-11-14
mkdir -p "$OUTROOT/$L"; cd "$T"
r(){ n="$1"; shift; rm -rf "$T/temp/gh1479/packet"; "$@" >"$OUTROOT/$L/$n.out" 2>"$OUTROOT/$L/$n.err"; echo $? >"$OUTROOT/$L/$n.rc"; if [ -d "$T/temp/gh1479/packet" ]; then cp -R "$T/temp/gh1479/packet" "$OUTROOT/$L/$n.packet"; fi; }
P="$V/utils/swarm-preflight.sh"
r json   "$P" --project-doc "$T"/temp/gh1479/preflight-main.md --target-root "$T" --out "$T/temp/gh1479/packet" --format json --dry-run
r text   "$P" --project-doc "$T"/temp/gh1479/preflight-main.md --target-root "$T" --out "$T/temp/gh1479/packet"
r unknown "$P" --definitely-unknown
r noargs "$P"
r both   "$P" --project-doc "$T"/temp/gh1479/preflight-main.md --gh-issue 1479
r checklist "$P" --project-doc "$T"/temp/gh1479/variant-checklist.md --target-root "$T" --out "$T/temp/gh1479/packet"
r missing "$P" --project-doc "$T"/temp/gh1479/variant-missing.md --target-root "$T" --out "$T/temp/gh1479/packet"
r missingjson "$P" --project-doc "$T"/temp/gh1479/variant-missing.md --target-root "$T" --out "$T/temp/gh1479/packet" --format json
r landed "$P" --project-doc "$T"/temp/gh1479/variant-landed.md --target-root "$T" --out "$T/temp/gh1479/packet" --format json
r ghissue "$P" --gh-issue 1479 --target-root "$T" --out "$T/temp/gh1479/packet" --format json --dry-run
