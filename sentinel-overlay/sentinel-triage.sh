#!/usr/bin/env bash
# sentinel-triage.sh — §2.2. Read Tier-1 debug.log findings → dedupe against open PDDA docs →
# classify (local Gemma, gated) → draft a PROJECT/1-INBOX capture doc with a Swarm Preflight Contract
# → probe-lint → (gated) file a GitHub issue.
#
# INERT BY DEFAULT: with no runtime.env (SENTINEL_ENABLE!=1) and no classify stub, this is a no-op.
# The doc-drafting is local (no egress); classification (Gemma) and issue-filing are gated wrappers.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$HERE/lib/config.sh"; . "$HERE/lib/classify.sh"; . "$HERE/lib/probe-lint.sh"; . "$HERE/lib/gh.sh"

DEBUG_LOG="${SENTINEL_DEBUG_LOG:-}"
INBOX="${SENTINEL_INBOX:-PROJECT/1-INBOX}"
while [ $# -gt 0 ]; do case "$1" in
  --debug-log) DEBUG_LOG="${2:-}"; shift 2;;
  --inbox)     INBOX="${2:-}"; shift 2;;
  -h|--help)   echo "usage: sentinel-triage.sh [--debug-log FILE] [--inbox DIR]"; exit 0;;
  *) echo "sentinel-triage: unexpected arg: $1" >&2; exit 2;;
esac; done

# Inert gate: proceed only when active OR a deterministic classify stub is present (tests/dry-run).
if ! sentinel_active && [ -z "${SENTINEL_CLASSIFY_STUB:-}" ]; then
  echo "sentinel-triage: inert (no runtime.env / SENTINEL_ENABLE!=1) — no-op (call-home off)" >&2
  exit 0
fi

DEBUG_LOG="${DEBUG_LOG:-debug.log}"
[ -f "$DEBUG_LOG" ] || { echo "sentinel-triage: no debug.log at $DEBUG_LOG — nothing to do" >&2; exit 0; }
mkdir -p "$INBOX"

drafted=0 skipped=0
while IFS= read -r line; do
  [ -n "$line" ] || continue
  # Normalize the finding to TSV: key<TAB>severity<TAB>check<TAB>slug<TAB>message<TAB>file<TAB>probe
  tsv="$(printf '%s' "$line" | python3 -c '
import json,sys,re,hashlib
try: o=json.loads(sys.stdin.read())
except Exception: sys.exit(3)
scope=o.get("scope","harness"); check=o.get("check","unknown"); msg=o.get("message","")
norm=re.sub(r"\s+"," ",msg.strip().lower())
key=hashlib.sha1((scope+"|"+check+"|"+norm).encode()).hexdigest()[:12]
slug=re.sub(r"[^a-z0-9]+","-",(check+"-"+norm)[:40]).strip("-") or "finding"
print("\t".join([key,o.get("severity","warn"),check,slug,msg,o.get("file",""),o.get("probe","")]))
' 2>/dev/null)" || { skipped=$((skipped+1)); continue; }
  [ -n "$tsv" ] || { skipped=$((skipped+1)); continue; }
  IFS=$'\t' read -r key sev check slug msg file probe <<<"$tsv"

  # Dedupe: a doc already carrying this finding-key stays put (recurrence, never refile).
  if grep -rqlF "sentinel-key: $key" "$INBOX" 2>/dev/null; then skipped=$((skipped+1)); continue; fi

  # Classify (Gemma when active; stub in tests). Only real bugs / lessons become docs.
  class="$(sentinel_classify "$line" 2>/dev/null || echo bug)"
  case "$class" in bug|lesson) ;; *) skipped=$((skipped+1)); continue;; esac

  doc="$INBOX/F-$key-$slug.md"
  DATE="$(date +%F 2>/dev/null || echo 2026-07-22)"
  SENTINEL_KEY="$key" SEV="$sev" CHECK="$check" SLUG="$slug" MSG="$msg" FILE="$file" PROBE="$probe" \
  CLASS="$class" DATE="$DATE" python3 - "$doc" <<'PY'
import os,sys,json,re
doc=sys.argv[1]
key=os.environ["SENTINEL_KEY"]; sev=os.environ["SEV"]; check=os.environ["CHECK"]
slug=os.environ["SLUG"]; msg=os.environ["MSG"]; file=os.environ.get("FILE",""); probe=os.environ.get("PROBE","")
cls=os.environ["CLASS"]; date=os.environ.get("DATE","2026-07-22")
doc_type="bugfix" if cls=="bug" else "feedback"
goal_line=re.sub(r"\s+"," ",msg).strip()[:100] or check
# Build a fix_probe with correct polarity when we have concrete evidence.
probes=[]
if probe:
    probes.append({"type":"command","command":probe})
elif file:
    probes.append({"type":"grep_present","path":file,"pattern":check})
contract={"target":{"repo":".","ref":"development"},"gate":"bash validate.sh",
          "fix_probes":probes,"artifacts":[file] if file else [],
          "remediation":{"source":f"sentinel:{check}","criteria":msg}}
fm=f'''---
title: "Sentinel finding: {check} — {msg[:60]}"
sentinel-key: {key}
status: "Proposed (1-INBOX — not yet active)"
created: {date}
updated: {date}
owner: sentinel-triage (auto-draft)
goal: >
  {goal_line}
doc_type: {doc_type}
severity: {sev}
ratings_provisional: true
---

# Sentinel finding · {check}

<!-- sentinel-key: {key} — dedupe marker; do not remove -->

## Status

| What was just completed | What's next |
|---|---|
| Auto-drafted from debug.log by sentinel-triage (classified: {cls}). | Human confirms ratings; probe-lint must pass before this leaves 1-INBOX. |

## Finding

- **check:** {check}
- **severity:** {sev}
- **message:** {msg}
- **file:** {file or "(n/a)"}
- **probe:** `{probe or "(none)"}`

## Swarm Preflight Contract

```json
{json.dumps(contract, indent=2)}
```
'''
open(doc,"w").write(fm)
print(doc)
PY
  drafted=$((drafted+1))

  # (gated) file a GitHub issue for the drafted doc — no-ops when inert.
  sentinel_gh issue create --title "Sentinel: $check" --body-file "$doc" >/dev/null 2>&1 || true
done < "$DEBUG_LOG"

echo "sentinel-triage: drafted=$drafted skipped=$skipped (inbox=$INBOX)"
