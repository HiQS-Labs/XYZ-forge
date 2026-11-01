#!/usr/bin/env bash
# GH-1308 manual checks (not a suite; GH-831). Run from the root of a DISPOSABLE full clone:
#   bash TESTS-RESULTS/2026-11-01+GH-1308/gh1308-checks.sh <red-clone-root-at-cb1bf933> <fakehome>
# Prints each command, its exit code and decisive output. Needs gh auth (read-only calls).
set -u
RED="$1"; FAKEHOME="$2"
H="python3 utils/py/harness.py factory-primitive"
# Each run uses fresh run roots (unique suffix), so nothing is ever removed (AGENTS.md: no recursive
# cleanup through relative paths).
RUN="$(date +%s)-$$"
run() { echo "\$ $*"; out=$(eval "$@" 2>&1); rc=$?; printf '%s\n' "$out" | tail -n "${TAIL:-3}"; echo "rc=$rc"; echo; }
echo "# GH-1308 checks"; echo "head=$(git rev-parse HEAD) origin=$(git remote get-url origin) clean_files=$(git status --porcelain | wc -l | tr -d ' ')"
echo "red=$(git -C "$RED" rev-parse HEAD) date=$(date -u +%FT%TZ) python=$(python3 -V 2>&1)"; echo

echo "## 1. Stage B canary init: red control on cb1bf933, then this revision"
INIT="init --from-prs --limit 33 --unregistered 33 --canaries utils/py/factory_primitive/scenarios/gh1279-canaries.jsonl --miss 85-90"
run "cd '$RED' && $H --run-root temp/factory-primitive/r1-$RUN $INIT"
run "$H --run-root temp/factory-primitive/g1-$RUN $INIT"
M=temp/factory-primitive/g1-$RUN/instances/C/backlog/manifest.json
TAIL=20 run "python3 -c \"import json;m=json.load(open('$M'));print('requests',len(m['requests']),'excluded',len(m['excluded']));print('delivered',json.dumps(m['delivered'],sort_keys=True))\""
echo "## 1b. independent all-PR recomputation of the delivered map (not via harness.py)"
TAIL=20 run "python3 - '$M' <<'PY'
import json,subprocess,sys
sys.path.insert(0,'utils/py'); import wave_reconcile as w
slug=w.github_slug_from_origin('.')
prs=json.loads(subprocess.run(['gh','pr','list','--state','merged','--limit','5000','--json','number,title,body'],capture_output=True,text=True,check=True).stdout)
iss=json.loads(subprocess.run(['gh','issue','list','--state','all','--limit','5000','--json','number,state'],capture_output=True,text=True,check=True).stdout)
st={str(i['number']):i['state'] for i in iss}; d={}
for pr in prs:
    for n in w.extract_linked_issues(pr,slug)[0]:
        if st.get(str(n))=='OPEN': d.setdefault(str(n),set()).add(pr['number'])
d={k:sorted(v) for k,v in d.items()}
m=json.load(open(sys.argv[1]))['delivered']
print('merged_prs',len(prs),'issues',len(iss))
print('independent',json.dumps(d,sort_keys=True))
print('EQUAL' if d==m else 'DIFFERENT')
sys.exit(0 if d==m else 1)
PY"

echo "## 2. Codex call cap"
run "$H --run-root temp/factory-primitive/c0-$RUN init --adapter codex --codex-model m"
run "$H --run-root temp/factory-primitive/c1-$RUN init --adapter codex --codex-model m --max-call-cost 0.01"
run "$H --run-root temp/factory-primitive/c2-$RUN init"

echo "## 3. re-tick after crash-act: red then this revision"
for side in "$RED" "$PWD"; do
  run "cd '$side' && $H --run-root temp/factory-primitive/tk-$RUN init >/dev/null && { $H --run-root temp/factory-primitive/tk-$RUN tick --slot 1 --fault crash-act >/dev/null 2>&1; echo crash-rc=\$?; } && $H --run-root temp/factory-primitive/tk-$RUN tick --slot 1"
done

echo "## 4. idea skill tool paths from a foreign repo, and the empty-TARGET guard"
F=$(mktemp -d); git -C "$F" init -q
eval "$(bash skills/2-daily/hq/find-hq.sh --env)"
run "cd '$F' && python3 utils/py/releases_app.py --help"
run "cd '$F' && python3 '$HQ_ROOT/utils/py/releases_app.py' --root '$PWD' roadmap list --json >/dev/null"
run "cd '$F' && python3 '$HQ_ROOT/utils/py/prior_art_recon.py' --help >/dev/null && bash '$HQ_ROOT/utils/swarm-preflight.sh' --help >/dev/null"
run "TARGET=\$(bash '$HQ_SH' resolve no-such-project-zz | sed -n 's/^REPO_PATH=//p'); [ -n \"\$TARGET\" ] || { echo 'idea: project did not resolve'; exit 1; }"

echo "## 5. sibling_root"
TAIL=10 run "cd skills/2-daily/merge-cleanup/scripts && python3 -c \"
from pathlib import Path; import scan_clones as s; h=Path.home()
for p in ['/Users/XYZ-forge', h/'Documents/GH Repos/XYZ-forge', h/'Documents/XYZ-forge', h/'XYZ-forge', '/XYZ-forge', '/opt/work/XYZ-forge']: print(p,'->',s.sibling_root(Path(p)))
print(s.is_safe_deletable_path(Path('/Users/someone/Desktop/old/XYZ-forge-task'), s.primary_safe_roots(Path('/Users/XYZ-forge'))))\""
TAIL=10 run "cd '$RED/skills/2-daily/merge-cleanup/scripts' && python3 -c \"
from pathlib import Path; import scan_clones as s
print('red /Users/XYZ-forge ->', s.sibling_root(Path('/Users/XYZ-forge')))\""

echo "## 6/suites. existing merge-cleanup suites (fake HOME)"
run "HOME='$FAKEHOME' python3 test/gh534_phase_a_tests.py 2>&1 | grep -E '^(Ran|OK|FAILED)'"
run "HOME='$FAKEHOME' python3 test/gh436-merge-cleanup.py 2>&1 | grep -E '^(Ran|OK|FAILED)'"

echo "## 7. governance"
run "python3 utils/py/releases_app.py check"
TAIL=8 run "python3 utils/py/releases_app.py roadmap list --json | python3 -c \"import json,sys;[print(r['gh_number'],r['section'],r['status_marker'],r['doc_path']) for r in json.load(sys.stdin) if r.get('gh_number') in (1273,1280,1308)]\""
TAIL=8 run "bash utils/pdda/pdda.sh run 2>&1 | grep -E 'issue-doc-sync.*(1250|1273|1280)|SUMMARY \\[pdda-check-issue-doc-sync\\]'"
