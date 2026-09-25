#!/usr/bin/env bash
# gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"self-comparing and self-regenerating fixtures were reported as none"}
# GH-419 — inventory discovery and negative-control evidence must stay separate.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
. "$HERE/test/lib/fixture-guard.sh"
require_forge_root validate.sh   # GH-708: forge-root only — witnessed skip in a vendored .xyz/
FIXTURE="$(mktemp -d "${TMPDIR:-/tmp}/gh419-gate-inventory.XXXXXX")"
trap 'rm -rf "$FIXTURE"' EXIT

mkdir -p "$FIXTURE/test"
cat >"$FIXTURE/validate.sh" <<'EOF'
TESTS=(
  "safe.sh"
  "self-comparing.sh"
  "self-regenerating.sh"
  "new-gate.sh"
)
EOF

cat >"$FIXTURE/test/safe.sh" <<'EOF'
# gate-evidence: {"form":"deliberate-mutation","observed":true,"result":"mutation made this fixture fail"}
test "safe" = "safe"
EOF
cat >"$FIXTURE/test/self-comparing.sh" <<'EOF'
# gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"this declaration must not override the shape"}
cmp "$candidate" "$candidate"
EOF
cat >"$FIXTURE/test/self-regenerating.sh" <<'EOF'
# gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"this declaration must not override the shape"}
generate-report > "$EXPECTED_SNAPSHOT"
diff "$EXPECTED_SNAPSHOT" "$actual"
EOF
cat >"$FIXTURE/test/new-gate.sh" <<'EOF'
test "new gate" = "new gate"
EOF

python3 "$HERE/utils/py/gate_inventory.py" --root "$FIXTURE" >"$FIXTURE/inventory.json"
python3 - "$FIXTURE/inventory.json" <<'PY'
import json
import sys

report = json.load(open(sys.argv[1], encoding="utf-8"))
gates = {row["gate"]: row for row in report["gates"]}
assert set(gates) == {
    "test/safe.sh",
    "test/self-comparing.sh",
    "test/self-regenerating.sh",
    "test/new-gate.sh",
}, gates
assert gates["test/safe.sh"]["negative_control"]["form"] == "deliberate-mutation"
assert gates["test/safe.sh"]["negative_control"]["observed"] is True
for gate, shape in (
    ("test/self-comparing.sh", "self-comparing-parity"),
    ("test/self-regenerating.sh", "self-regenerating-drift"),
):
    row = gates[gate]
    assert shape in row["disqualifying_shapes"], row
    assert row["negative_control"]["form"] == "none", row
    assert row["negative_control"]["observed"] is False, row
assert gates["test/new-gate.sh"]["negative_control"]["form"] == "none"
assert gates["test/new-gate.sh"]["negative_control"]["observed"] is False
PY

python3 "$HERE/utils/py/gate_inventory.py" --root "$HERE" >"$FIXTURE/repo-inventory.json"
python3 - "$FIXTURE/repo-inventory.json" <<'PY'
import json
import sys

gates = {row["gate"]: row for row in json.load(open(sys.argv[1], encoding="utf-8"))["gates"]}
row = gates["test/gh419-gate-inventory.sh"]
assert row["negative_control"]["form"] == "controlled-bad-fixture", row
assert row["negative_control"]["observed"] is True, row
PY

# GH-805: parser and advisory decisions must reject bad inputs without inventing authority.
python3 - "$HERE" "$FIXTURE" <<'PY805'
import hashlib, importlib.util, json, pathlib, sys
root, fixture = map(pathlib.Path, sys.argv[1:])
spec = importlib.util.spec_from_file_location('inventory', root/'utils/py/gate_inventory.py')
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
registry = fixture/'validate.sh'; original = registry.read_text()
registry.write_text('TESTS=(\n # "ignored.sh"\n "safe.sh"\n)\n')
assert m.registered_gates(fixture) == ['safe.sh']
for body in ['TESTS=(\n)\n', 'TESTS=(\n "safe.sh" "safe.sh"\n)\n', 'TESTS=(\n "$dynamic.sh"\n)\n']:
    registry.write_text(body)
    try: m.registered_gates(fixture)
    except ValueError: pass
    else: raise AssertionError('invalid registry accepted: '+body)
registry.write_text(original)
file = fixture/'test/safe.sh'
record = {k:'example' for k in ('id','behavior','consequence','issue','overlap','reason','review_source','routing','red_evidence')}
record.update(outcome='extend', proposer='builder', reviewer='independent-advisory', content={'test/safe.sh':hashlib.sha256(file.read_bytes()).hexdigest()})
path = fixture/'decisions.json'
def view(records):
    path.write_text(json.dumps(records)); return m.decision_view(fixture.resolve(), path)['decisions'][0]
valid = view([record]); assert not valid['metadata_errors']
assert valid['approval_trusted'] is False and valid['would_refuse_mandatory'] is True
assert view([{**record, 'approved':True, 'approval_trusted':True}])['approval_trusted'] is False
assert 'self-issued review' in view([{**record,'reviewer':'builder'}])['metadata_errors']
assert view([{**record,'content':{'test/safe.sh':'0'*64}}])['metadata_errors']
assert view([{**record,'content':{'missing.py':'0'*64}}])['metadata_errors']
assert view([{**record,'content':{'../escape.py':'0'*64}}])['metadata_errors']
assert view([{**record,'reason':''}])['metadata_errors']
for records in [[], {}, [None]]:
    try: view(records)
    except ValueError: pass
    else: raise AssertionError('invalid decision input accepted')
print('PASS: parser rejects empty/duplicate/dynamic input; advisory metadata never authenticates approval')
PY805

# GH805 gateway controls extend this existing suite; no additional runner registration.
python3 - "$HERE" "$FIXTURE" <<'PY_GATEWAY'
import copy, json, pathlib, subprocess, sys
from unittest.mock import patch
root, fixture = map(pathlib.Path, sys.argv[1:])
sys.path.insert(0, str(root/'utils/py'))
import test_admission as a
r = fixture/'admission-repo'; r.mkdir(); (r/'test').mkdir()
def g(*args): return subprocess.check_output(['git','-C',str(r),*args], text=True).strip()
g('init','-q','--initial-branch=development'); g('config','user.name','Fixture'); g('config','user.email','fixture@example.invalid')
(r/'product.py').write_text('value=1\n'); (r/'test/existing.py').write_text('assert value == 1\n')
g('add','.'); g('commit','-qm','base'); base=g('rev-parse','HEAD')
(r/'test/existing.py').write_text('assert value == 2\n'); (r/'product.py').write_text('value=2\n'); g('add','.')
why={k:'bounded fixture evidence' for k in a.FIELDS}; why.update(outcome='extend',issue='https://github.com/HiQS-Labs/XYZ-forge/issues/805')
b,tree,rows=a.manifest(r,base,'INDEX'); valid=a.packet(b,rows,why)
packet=r/a.PACKET; packet.parent.mkdir()
def write(data):
    packet.write_text(json.dumps(data)); g('add',a.PACKET)
def refused(fn):
    try: fn()
    except ValueError: return
    raise AssertionError('bad proposal was accepted')
refused(lambda:a.inspect(r,base,'INDEX'))
write(valid); out=a.inspect(r,base,'INDEX'); assert out['test_files']['M']==1 and not out['approval_trusted']
for bad in [{**valid,'approved':True}, {**valid,'changes':rows[:-1]}, {**valid,'base':'0'*40}, {**valid,'decision':{**why,'reason':''}}]:
    write(bad); refused(lambda:a.inspect(r,base,'INDEX'))
write(valid); (r/'product.py').write_text('value=3\n'); g('add','product.py'); refused(lambda:a.inspect(r,base,'INDEX'))
(r/'product.py').write_text('value=2\n'); g('add','product.py')
(r/'test/new.py').write_text('assert True\n'); g('add','test/new.py')
b,t,rs=a.manifest(r,base,'INDEX'); write(a.packet(b,rs,why)); refused(lambda:a.inspect(r,base,'INDEX'))
write(a.packet(b,rs,{**why,'outcome':'add'})); assert a.inspect(r,base,'INDEX')['test_files']['A']==1
(r/'test/new.py').unlink(); g('add','-u'); (r/'test/existing.py').rename(r/'test/renamed.py'); g('add','.')
refused(lambda:a.inspect(r,base,'INDEX')); b,t,rs=a.manifest(r,base,'INDEX'); write(a.packet(b,rs,{**why,'outcome':'add'}))
assert a.inspect(r,base,'INDEX')['test_files']['D']==1
write(a.packet(b,rs,{**why,'outcome':'no-add'})); refused(lambda:a.inspect(r,base,'INDEX'))
refused(lambda:a.loads('{"outcome":"add","outcome":"reuse"}'))
# The hosted path publishes failure, never success, when candidate verification rejects.
pr={'number':1,'base':{'ref':'development','sha':base},'head':{'sha':'f'*40},'state':'open','user':{'id':41898282}}
calls=[]
def api(path,payload=None,method=None):
    calls.append((path,payload,method))
    return {'id':7} if path.endswith('/check-runs') else pr
with patch.object(a,'gh',side_effect=api), patch.object(a,'git',return_value=''), patch.object(a,'revision',return_value='f'*40), patch.object(a,'inspect',side_effect=ValueError('seeded stale proposal')):
    refused(lambda:a.hosted(r,'owner/repo',1,str(fixture/'never.json')))
assert calls[-1][1]['conclusion']=='failure'
assert not any(c[1] and c[1].get('conclusion')=='success' for c in calls)
# A same-account reviewer, stale review, or dismissed review is never authenticated admission.
with patch.object(a,'gh',return_value=pr), patch.object(a,'git',return_value=''), patch.object(a,'revision',return_value='f'*40), patch.object(a,'inspect',return_value={'state':'proposed'}):
    review={'id':3,'user':{'id':a.OPERATOR_ID},'state':'APPROVED','commit_id':'f'*40,'html_url':'review'}
    with patch.object(a,'paged',return_value=[review]): assert a.catalog(r,'owner/repo',1)['approval_trusted']
    for bad in [{**review,'commit_id':'0'*40},{**review,'state':'DISMISSED'},{**review,'user':{'id':9}}]:
        with patch.object(a,'paged',return_value=[bad]): assert not a.catalog(r,'owner/repo',1)['approval_trusted']
    pr['user']['id']=a.OPERATOR_ID
    with patch.object(a,'paged',return_value=[review]): assert not a.catalog(r,'owner/repo',1)['approval_trusted']
# Exercise the real push hook: a missing/stale packet stops before its expensive runner.
import os, shutil
(r/'utils/py').mkdir(parents=True); (r/'.github/workflows').mkdir()
for name in ['gate_inventory.py','test_admission.py']:
    shutil.copyfile(root/'utils/py'/name,r/'utils/py'/name)
(r/'.github/workflows/test-admission.yml').write_text('trusted checker exists\n')
(r/'validate.sh').write_text('#!/bin/sh\necho expensive > expensive-ran\nexit 99\n'); (r/'validate.sh').chmod(0o755)
g('add','.'); g('commit','-qm','unadmitted proposal')
g('update-ref','refs/remotes/origin/development',base)
head=g('rev-parse','HEAD')
result=subprocess.run(['bash',str(root/'githooks/pre-push'),'origin'],cwd=r,text=True,capture_output=True,
                      input=f'refs/heads/task {head} refs/heads/task {base}\n',env={**os.environ,'XYZ_SKIP_PREPUSH':'0'})
assert result.returncode==1 and 'refused before expensive validation' in result.stderr, result.stderr
assert not (r/'expensive-ran').exists()
print('PASS: real push hook refuses unadmitted changes before executing validate.sh')
print('PASS: complete binding, stale/missing/forged/renamed/deleted controls and native review identity')
PY_GATEWAY

echo "PASS: GH-419 inventory discovers registered gates and records only declared controls"
