#!/usr/bin/env bash
# GH-1257 manual controls, run in the disposable -verify clone. Prints one line per control.
set -u
cd "$1"
H="python3 utils/py/harness.py factory-primitive"
J() { python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)$1))"; }
seed() { $H --run-root "temp/factory-primitive/$1" init --from-prs --limit "$2" >/dev/null; }

for fault in fail-after-output corrupt-issue-hash drop-key md-mismatch drop-file; do
  R="ctl-$fault"; seed "$R" 2
  t1=$($H --run-root temp/factory-primitive/$R tick --slot 1 --fault "$fault" 2>&1)
  t2=$($H --run-root temp/factory-primitive/$R tick --slot 2 2>&1)
  t3=$($H --run-root temp/factory-primitive/$R tick --slot 3 2>&1)
  st=$($H --run-root temp/factory-primitive/$R status)
  echo "CONTROL $fault | slot1=$t1 | slot2=$t2 | slot3=$t3 | quarantined=$(echo "$st" | J "['quarantined_ids']") | last_error=$(sqlite3 "temp/factory-primitive/$R/instances/C/state.db" "select error from ticks where slot=1")"
done

R="ctl-missing-receipt"; seed "$R" 2
t1=$($H --run-root temp/factory-primitive/$R tick --slot 1 --fault missing-receipt 2>&1; echo "rc=$?")
t2=$($H --run-root temp/factory-primitive/$R tick --slot 2 2>&1)
st=$($H --run-root temp/factory-primitive/$R status)
na=$(python3 -c "import json; print(json.load(open('temp/factory-primitive/$R/instances/C/out/plan-draft/wave-proposal.json'))['not_accepted'])")
echo "CONTROL crash-after-output | slot1=$(echo $t1 | tr '\n' ' ') | slot2=$t2 | ticks=$(echo "$st" | J "['ticks']") | quarantined=$(echo "$st" | J "['quarantined_ids']") | proposal.not_accepted=$na"

R="ctl-pause"; seed "$R" 1; touch "temp/factory-primitive/$R/instances/C/PAUSE"
t1=$($H --run-root temp/factory-primitive/$R tick --slot 1 2>&1)
echo "CONTROL pause | slot1=$t1 | drafts=$(ls temp/factory-primitive/$R/instances/C/out/plan-draft 2>/dev/null | wc -l | tr -d ' ')"

R="ctl-doc-changed"; seed "$R" 1
doc=$(python3 -c "import json; m=json.load(open('temp/factory-primitive/$R/instances/C/backlog/manifest.json')); print(next(iter(m['requests'].values()))['doc_path'])")
cp "$doc" "$TMPDIR/gh1257-doc.bak"; printf '\nedited after init\n' >> "$doc"
t1=$($H --run-root temp/factory-primitive/$R tick --slot 1 2>&1); cp "$TMPDIR/gh1257-doc.bak" "$doc"
echo "CONTROL doc-changed-after-init ($doc) | slot1=$t1 | error=$(sqlite3 "temp/factory-primitive/$R/instances/C/state.db" "select error from ticks where slot=1" | cut -c1-120) | quarantined=$($H --run-root temp/factory-primitive/$R status | J "['quarantined_ids']")"

R=pilot-1
before=$(ls temp/factory-primitive/$R/instances/C/out/plan-draft | wc -l | tr -d ' ')
t3=$($H --run-root temp/factory-primitive/$R tick --slot 3 2>&1)
after=$(ls temp/factory-primitive/$R/instances/C/out/plan-draft | wc -l | tr -d ' ')
echo "CONTROL replay-completed-slot | rerun slot3=$t3 | files before=$before after=$after"
