import hashlib, json, pathlib, re, subprocess, time
from measure import BASE, CANDIDATE, OUT, identity, run

def function(text, name):
    return re.search(r'^' + re.escape(name) + r'\(\) \{.*?^\}', text, re.M | re.S)[0]

old = (BASE / 'test/gh365-tier-fail-closed.sh').read_text()
path = CANDIDATE / 'test/gh365-tier-fail-closed.sh'
new = path.read_text()
router = CANDIDATE / 'utils/ci-route.sh'
records = []
paths = ['README.md', 'utils/hq/hq.sh', 'src/project.js', 'utils/py/releases_app.py',
         'utils/py/wave_reconcile.py', 'test/gh549-work-events.sh', 'validate.sh',
         '.github/workflows/ci.yml', 'releases.sql', 'test/deleted-suite.sh',
         'unknown.file', 'a path with spaces.py', 'path=with=equals.py', '',
         'skills/1-hourly/relay-xyz/SKILL.md', 'utils/ate/anything.py']
for item in paths:
    values = []
    for text in (old, new):
        code = 'ROUTER="$1"\n' + function(text, 'classify') + '\nclassify "$2"\nprintf "%s\\0%s\\0%s\\0" "$CL_tier" "$CL_reason" "$CL_sub"'
        result = subprocess.run(['/bin/bash', '-c', code, '_', str(router), item],
                                cwd=CANDIDATE, capture_output=True)
        assert result.returncode == 0
        values.append(result.stdout.decode())
    assert values[0] == values[1], (item, values)
    records.append({'control': 'real-classifier-parser-equivalence', 'input': item,
                    'old': values[0], 'new': values[1], 'equal': True})

registry = subprocess.check_output(['/bin/bash', str(router), 'subsystems'], cwd=CANDIDATE, text=True)
assert registry.strip()
results = []
for text in (old, new):
    code = ('ROUTER="$1"\nSUBSYSTEM_REGISTRY="$2"\n' + function(text, 'registered_anywhere') +
            '\nfor f in test/*.sh; do b="${f##*/}"; if registered_anywhere "$b"; then printf "%s yes\\n" "$b"; else printf "%s no\\n" "$b"; fi; done')
    result = subprocess.run(['/bin/bash', '-c', code, '_', str(router), registry], cwd=CANDIDATE, capture_output=True, text=True)
    assert result.returncode == 0
    results.append(result.stdout)
assert results[0] == results[1] and results[0].strip()
records.append({'control': 'registry-membership-equivalence', 'count': len(results[0].splitlines()),
                'old_sha256': hashlib.sha256(results[0].encode()).hexdigest(),
                'new_sha256': hashlib.sha256(results[1].encode()).hexdigest(), 'equal': True})

block = new[new.index('SUBSYSTEM_REGISTRY='):new.index('registered_anywhere()')]
for name, body in [('failed-registry', 'exit 7'), ('empty-registry', 'exit 0'),
                   ('valid-registry', "printf 'hq\\thq.sh\\n'")]:
    fake = OUT / (name + '.sh')
    fake.write_text(body + '\n')
    code = 'ROUTER="$1"\nfail() { echo "FAIL: $*"; exit 1; }\n' + block
    result = subprocess.run(['/bin/bash', '-c', code, '_', str(fake)], capture_output=True, text=True)
    expected = 0 if name == 'valid-registry' else 1
    assert result.returncode == expected, result
    records.append({'control': name, 'rc': result.returncode, 'expected_rc': expected, 'output': result.stdout})

before = identity(CANDIDATE)
original = path.read_bytes()
try:
    needle = b'tier) CL_tier="$value"'
    assert original.count(needle) == 1
    mutated = original.replace(needle, b'tier) CL_tier="BROKEN"')
    path.write_bytes(mutated)
    row = run('mutated-tier-red', CANDIDATE, ['/bin/bash', 'test/gh365-tier-fail-closed.sh'])
    assert row['rc'] != 0 and row['identity_equal']
    records.append({'control': 'existing-suite-detects-broken-tier-parser', 'rc': row['rc'],
                    'original_blob_sha256': hashlib.sha256(original).hexdigest(),
                    'mutated_blob_sha256': hashlib.sha256(mutated).hexdigest(),
                    'mutation': 'tier output assignment changed to BROKEN',
                    'output_first_1200': (OUT / 'mutated-tier-red.log').read_text()[:1200]})
finally:
    path.write_bytes(original)
assert identity(CANDIDATE) == before
records.append({'control': 'red-control-restoration', 'identity_equal': True,
                'restored_blob_sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
(OUT / 'controls.json').write_text(json.dumps(records, indent=2))
print(json.dumps({'controls': len(records), 'parser_inputs': len(paths), 'registry_equal': True,
                  'red_rc': row['rc'], 'restored': True}), flush=True)
