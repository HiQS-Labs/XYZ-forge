#!/usr/bin/env bash
# =============================================================================
# XYZ-forge audit — REPRODUCTION SCRIPT
# One file, re-runs every probe from the audit. Drop-in for the maintainer's
# "negative controls / reproducible evidence" culture. No API keys, no network.
#
# USAGE:
#   bash audit/repro.sh                 # runs all probes, prints a findings summary
#   bash audit/repro.sh --keep          # leave the throwaway probe repo in place
#
# ENV OVERRIDES:
#   XYZ_UNDER_TEST  harness root to probe (default: this script's repo)
#
# The probe repo is a fresh `mktemp -d` every run. This script creates nothing
# outside it, writes nothing into the repo, and deletes only what it made.
#
# WHAT IT PROBES (each maps to a numbered finding in FINDINGS.md):
#   P1   path-overlap on claim (glob vs literal)        -> F1 (lane guard gap)
#   P2   garbage --priority / --epoch                   -> F2 (input coercion)
#   P3   task id containing ../                          -> F3 (id sanitised OK)
#   P4   mutating verb from foreign directory           -> F4 (cwd-independent OK)
#   P5   corrupted events file into the log             -> F5 (kernel poisoning)
#   P6   50 same-ms concurrent appends                  -> BUG-1 regression (fixed)
#   P7   release by non-owner (stale-epoch fence)       -> F6 (fence works)
#
# ENVIRONMENT: portable. Anything handed to node goes through nativep(), because on
#   MSYS/Git-Bash the bundled node is a NATIVE WINDOWS build and cannot resolve
#   /c/... paths. On Linux/macOS nativep() is the identity function.
# =============================================================================
set -uo pipefail

KEEP=0
[[ "${1:-}" == "--keep" ]] && KEEP=1

# --- harness under test ----------------------------------------------------
# Resolved from this script's own location, so the file is checkout-relative and
# carries no machine-specific path. Override to probe a different clone.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XYZ="${XYZ_UNDER_TEST:-$(cd "$HERE/.." && pwd)}"
if [ ! -x "$XYZ/bin/tick" ]; then echo "FATAL: no bin/tick under $XYZ" >&2; exit 2; fi

# --- path form -------------------------------------------------------------
nativep() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi; }
XYZ_W="$(nativep "$XYZ")"

# --- preconditions ---------------------------------------------------------
# This script promises no network. It therefore REFUSES to run npm install; if the
# harness clone is not installed, that is the operator's one-time step, not ours.
if [ ! -d "$XYZ/node_modules/acorn" ]; then
  echo "FATAL: $XYZ/node_modules/acorn is missing - some shims need it." >&2
  echo "       Run 'npm install' in $XYZ once, then re-run this script." >&2
  echo "       (Not done here on purpose: this script does no network I/O.)" >&2
  exit 3
fi

# --- throwaway probe repo --------------------------------------------------
# A fresh mktemp -d every run. Nothing is removed that this script did not create,
# and no fixed path is ever deleted.
DEMO="$(mktemp -d 2>/dev/null || mktemp -d -t xyz-probe)" || { echo "FATAL: mktemp -d failed" >&2; exit 2; }
DEMO_W="$(nativep "$DEMO")"
cleanup() {
  if [ "$KEEP" == "0" ] && [ -n "${DEMO:-}" ] && [ -d "$DEMO" ]; then
    cd / && rm -rf "$DEMO" 2>/dev/null
  fi
}
trap cleanup EXIT

T="$XYZ_W/bin/tick"
cd "$DEMO"
git init -q 2>/dev/null
export TICK_REPO_ROOT="$DEMO_W"
pass=0; info=0; warn=0
line(){ printf '%s\n' "----------------------------------------------------------------------"; }

echo "PROBE REPO: $DEMO"
line

echo "### P1 — path overlap on claim (glob 'src/auth/**' vs literal 'src/auth/login.js')"
node "$T" log task.created P1A --agent dispatcher --priority 5 --paths "src/auth/**" >/dev/null 2>&1
node "$T" log task.created P1B --agent dispatcher --priority 5 --paths "src/auth/login.js" >/dev/null 2>&1
c1=$(node "$T" claim P1A --agent claude-a --paths "src/auth/**" 2>&1 | head -1)
c2=$(node "$T" claim P1B --agent codex --paths "src/auth/login.js" 2>&1 | head -1)
echo "  claim P1A (claude-a): $c1"
echo "  claim P1B (codex, overlapping): $c2"
if [[ "$c2" == *"won"* ]]; then
  echo "  >> FINDING F1 [MEDIUM]: overlapping lane claimed (glob vs literal not intersected on claim)"
  warn=$((warn+1))
else
  echo "  >> OK: overlap rejected"
fi
line

echo "### P2 — garbage --priority and --epoch"
p=$(node "$T" log task.created P2 --agent dispatcher --priority "not-a-number" --paths "x" 2>&1 | head -1)
e=$(node "$T" log task.created P2b --agent dispatcher --epoch "abc" --paths "x" 2>&1 | head -1)
echo "  --priority not-a-number: $p"
echo "  --epoch abc:            $e"
pf=$(node -e 'const fs=require("fs");const d="'"$DEMO_W"'/.tick/events";const f=fs.readdirSync(d).find(x=>x.includes("created-P2.jsonl"));console.log(JSON.parse(fs.readFileSync(d+"/"+f,"utf8")).priority)')
ef=$(node -e 'const fs=require("fs");const d="'"$DEMO_W"'/.tick/events";const f=fs.readdirSync(d).find(x=>x.includes("created-P2b"));console.log(JSON.parse(fs.readFileSync(d+"/"+f,"utf8")).epoch)')
echo "  P2  created event priority field = $pf"
echo "  P2b created event epoch field    = $ef"
if [[ "$pf" != "null" && "$pf" != "0" && "$pf" != "1" ]]; then
  echo "  >> FINDING F2 [LOW]: non-numeric --priority stored verbatim (priority=$pf); downstream sorts/metrics may NaN"
  warn=$((warn+1))
elif [[ "$ef" != "null" && "$ef" != "0" ]]; then
  echo "  >> FINDING F2 [LOW]: non-numeric --epoch coerced to $ef; fence math may misbehave"
  warn=$((warn+1))
else
  echo "  >> OK: bad inputs fell back to null/0 (fence + priority safe)"
fi
line

echo "### P3 — task id containing ../"
p3=$(node "$T" log task.created "../escape" --agent dispatcher --priority 1 --paths "x" 2>&1 | head -1)
echo "  log '../escape': $p3"
ef=$(node -e 'const fs=require("fs");const d="'"$DEMO_W"'/.tick/events";const f=fs.readdirSync(d).find(x=>x.includes("escape"));console.log(f)')
echo "  event file written as: $ef"
if [[ "$ef" == *".."* && "$ef" != *"/"* ]]; then
  echo "  >> OK: '../' normalised to a safe segment (no path traversal in filename)"
  pass=$((pass+1))
else
  echo "  >> FINDING F3 [informational]: id handling = $ef"
  info=$((info+1))
fi
line

echo "### P4 — mutating verb from a foreign directory"
mkdir -p "$DEMO/foreign"; cd "$DEMO/foreign"
p4=$(node "$T" claim P1A --agent rogue --paths "src/auth/**" 2>&1 | head -1)
echo "  claim P1A from ./foreign: $p4"
cd "$DEMO"
if [[ "$p4" == *"lost"* || "$p4" == *"already"* ]]; then
  echo "  >> OK: claim resolved against TICK_REPO_ROOT, not cwd (cwd-independent)"
  pass=$((pass+1))
else
  echo "  >> FINDING F4 [informational]: $p4"
  info=$((info+1))
fi
line

echo "### P5 — corrupted events file poisons the whole log"
node "$T" log task.created P5 --agent dispatcher --priority 1 --paths "x" >/dev/null 2>&1
printf 'this is not valid json {{{' > "$DEMO/.tick/events/2026-08-18T13-25-30.000Z-dispatcher-created-P5.jsonl"
proj_ec=0; node "$T" project >/dev/null 2>&1; proj_ec=$?
claim_ec=0; node "$T" claim P5 --agent x --paths "x" >/dev/null 2>&1; claim_ec=$?
echo "  project exit = $proj_ec ; unrelated claim exit = $claim_ec"
if [[ "$proj_ec" != "0" || "$claim_ec" != "0" ]]; then
  echo "  >> FINDING F5 [HIGH]: one corrupt .jsonl in .tick/events throws on JSON.parse and"
  echo "     takes down project/analyze/claim/release for the ENTIRE repo (no per-file guard,"
  echo "     no 'which file' in the error). Recovery = manually delete the bad file."
  warn=$((warn+1))
else
  echo "  >> OK: corrupt file isolated"
fi
# cleanup the poison so later probes are clean
rm -f "$DEMO/.tick/events/2026-08-18T13-25-30.000Z-dispatcher-created-P5.jsonl"
line

echo "### P6 — 50 same-ms concurrent appends (BUG-1 regression / fixed)"
n=$(node -e '
const ev=require("'"$XYZ_W"'/src/events");
const fs=require("fs"),os=require("os"),path=require("path");
const root="'"$DEMO_W"'";
process.env.TICK_TS="2026-01-01T00:00:00.000Z";
for(let i=0;i<50;i++){ try{ ev.appendEvent(root,{type:"task.heartbeat",task:"P6",agent:"a1"}); }catch(e){} }
delete process.env.TICK_TS;
const dir=root+"/.tick/events";
const p6=fs.readdirSync(dir).filter(f=>f.includes("-a1-heartbeat-P6")).length;
console.log(p6);
')
echo "  P6 heartbeat files written = $n (expected 50 if no clobber)"
if [[ "$n" == "50" ]]; then
  echo "  >> OK: all 50 persisted, no silent clobber (BUG-1 not present in this tree)"
  pass=$((pass+1))
else
  echo "  >> FINDING BUG-1 [HIGH]: only $n/50 survived — events sharing ms+agent+action+task"
  echo "     collide on filename and fs.renameSync silently overwrites the earlier one."
  echo "     Reported against whatever tree XYZ_UNDER_TEST points at; a clone without the"
  echo "     uniqueness-suffix fix WILL show this. Not a regression unless the fix is in."
  warn=$((warn+1))
fi
line

echo "### P7 — release by non-owner (stale-epoch fence)"
node "$T" log task.created P7 --agent dispatcher --priority 1 --paths "y" >/dev/null 2>&1
node "$T" claim P7 --agent owner1 --paths "y" >/dev/null 2>&1
r1=$(node "$T" claim P7 --agent owner2 --paths "y" 2>&1 | head -1)
r2=$(node "$T" release P7 --agent owner1 2>&1 | head -1)
echo "  second claim by owner2: $r1"
echo "  release by owner1 (still the owner): $r2"
if [[ "$r1" == *"lost"* && "$r2" == *"released"* ]]; then
  echo "  >> OK: only the live owner can act; owner2 rejected, owner1 release succeeds (fence intact)"
  pass=$((pass+1))
else
  echo "  >> FINDING F6 [informational]: ownership handoff semantics = r1='$r1' r2='$r2'"
  info=$((info+1))
fi
line

echo "=== SUMMARY ==="
echo "  confirmed-OK / invariant holds : $pass"
echo "  findings (warn/med/high)        : $warn"
echo "  informational                   : $info"
# teardown is the EXIT trap; this only reports what it will do
[[ "$KEEP" == "0" ]] && echo "  (probe repo removed)" || echo "  (probe repo kept at $DEMO)"
echo "Done."
