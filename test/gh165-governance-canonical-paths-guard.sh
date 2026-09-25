#!/usr/bin/env bash
# gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"quoted mover, ledger writes, wrapper and missing input fixtures rejected"}
source "$(dirname "$0")/_setup.sh" gh165-governance-canonical-paths-guard || exit 1
XYZ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# A bounded static canary, not proof that arbitrary computed writes are impossible.
python3 - "$XYZ_ROOT" "$WORK" <<'PY'
import pathlib, re, sys
root, work = map(pathlib.Path, sys.argv[1:])

def audit(target):
    failures = []
    required = ['utils/pdda/pdda.sh', 'utils/pdda/pdda-lib.sh', 'skills/1-hourly/standup/triage.py']
    for name in required:
        if not (target / name).is_file() or not (target / name).stat().st_size:
            failures.append('missing-input:' + name)
    for directory in ['utils', 'relay-automation', 'skills']:
        if not (target / directory).is_dir():
            failures.append('missing-input:' + directory)
            continue
        for file in (target / directory).rglob('*'):
            if not file.is_file() or file.suffix not in {'.sh', '.py'} or file.name == 'wave_reconcile.py':
                continue
            for number, line in enumerate(file.read_text().splitlines(), 1):
                if line.lstrip().startswith('#'):
                    continue
                # Literal same-line moves; computed destinations remain outside this canary.
                if '3-COMPLETED' in line and re.search(r'(^\s*(?:git\s+)?mv\s|\b(?:os\.(?:rename|replace)|shutil\.move)\s*\()', line):
                    failures.append(f'mover:{file.relative_to(target)}:{number}')
    for name in required[:2]:
        file = target / name
        if file.is_file():
            for number, line in enumerate(file.read_text().splitlines(), 1):
                if re.search(r'^\s*(?:git mv|mv|rm|cp)\s+.*(?:ROADMAP\.md|releases\.(?:db|sql))', line):
                    failures.append(f'pdda-write:{name}:{number}')
    file = target / required[2]
    if file.is_file():
        for number, line in enumerate(file.read_text().splitlines(), 1):
            if not line.lstrip().startswith('#') and re.search(r'open\(.*(?:ROADMAP\.md|releases\.(?:db|sql)|PROJECT/3-COMPLETED)', line):
                failures.append(f'triage-open:{number}')
    if (target / 'utils/wave-reconcile.sh').exists():
        failures.append('retired-wrapper')
    return failures

errors = audit(root)
fixture = work / 'canonical-path-controls'
for directory in ['utils/pdda', 'relay-automation', 'skills/1-hourly/standup']:
    (fixture / directory).mkdir(parents=True, exist_ok=True)
for name in ['utils/pdda/pdda.sh', 'utils/pdda/pdda-lib.sh', 'skills/1-hourly/standup/triage.py']:
    (fixture / name).write_text('# clean\n')
assert not audit(fixture), audit(fixture)
controls = [
 ('utils/mover.py', 'shutil.move("active.md", "PROJECT/3-COMPLETED/active.md")\n', 'mover:'),
 ('utils/mover.sh', 'mv active.md PROJECT/3-COMPLETED/active.md\n', 'mover:'),
 ('utils/pdda/pdda.sh', 'mv old releases.db\n', 'pdda-write:'),
 ('skills/1-hourly/standup/triage.py', 'open("releases.db", "w")\n', 'triage-open:'),
 ('utils/wave-reconcile.sh', '# wrapper\n', 'retired-wrapper'),
 ('utils/pdda/pdda-lib.sh', '', 'missing-input:')]
for name, content, expected in controls:
    file = fixture / name
    original = file.read_bytes() if file.exists() else None
    file.write_text(content)
    found = audit(fixture)
    assert any(item.startswith(expected) for item in found), (name, found)
    print('PASS red control:', expected, name)
    if original is None:
        file.unlink()
    else:
        file.write_bytes(original)
assert not audit(fixture), audit(fixture)
if errors:
    print('\n'.join(errors), file=sys.stderr)
    raise SystemExit(1)
print('PASS: canonical-path static canaries and six rejecting controls')
PY
