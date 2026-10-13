"""Manual replay of the existing GH1012 promotion recovery plan; no CI registration."""
import json
import pathlib
import subprocess

SOURCE = pathlib.Path('/Users/noelsaw/Documents/Codex/2026-10-12/task-2/promotion-review-20261012')
OUT = pathlib.Path('/Users/noelsaw/Documents/Codex/2026-10-12/task-2/task-results/release-review')
B = 'a076b1b117a68252dc3d9d1c4901b0c31fcb4db3'
D = '2f8969a292e8dd230ab69ab9fe4ddc96a898ab55'
records = []

def run(root, *args, check=True, stdin=None):
    cmd = ['git', '-C', str(root), *args]
    p = subprocess.run(cmd, input=stdin, text=True, errors='replace', capture_output=True)
    records.append({'cmd': cmd, 'rc': p.returncode, 'stdout': p.stdout, 'stderr': p.stderr})
    if check and p.returncode:
        raise RuntimeError(records[-1])
    return p

results = []
for mainline in (1, 2):
    root = pathlib.Path('/tmp') / ('xyz1012-recovery-20261012-r2-mainline-' + str(mainline))
    if root.exists() or root.parent.resolve() != pathlib.Path('/tmp').resolve():
        raise RuntimeError('Recovery clone target must be new and strictly under /tmp')
    p = subprocess.run(['git', 'clone', '--no-local', '--quiet', str(SOURCE), str(root)], capture_output=True, text=True)
    records.append({'clone': str(root), 'rc': p.returncode, 'stdout': p.stdout, 'stderr': p.stderr})
    if p.returncode:
        raise RuntimeError('clone failed')
    run(root, 'remote', 'set-url', 'origin', 'https://github.com/HiQS-Labs/XYZ-forge.git')
    expected = run(root, 'rev-parse', B + '^{tree}').stdout.strip()
    tree = run(root, 'rev-parse', D + '^{tree}').stdout.strip()
    merge = run(root, '-c', 'user.name=Recovery Fixture', '-c', 'user.email=recovery@example.invalid',
                'commit-tree', tree, '-p', B, '-p', D, stdin='GH1012 isolated promotion rehearsal\n').stdout.strip()
    parents = run(root, 'rev-list', '--parents', '-n', '1', merge).stdout.split()
    if parents != [merge, B, D]:
        raise RuntimeError('Synthetic promotion parent identity mismatch')
    run(root, 'switch', '--detach', merge)
    before = {key: run(root, *args).stdout.strip() for key, args in {
        'head': ('rev-parse', 'HEAD'), 'origin': ('remote', 'get-url', 'origin'),
        'bare': ('config', '--get', 'core.bare'), 'config': ('config', '--local', '--list')}.items()}
    run(root, 'revert', '--no-commit', '-m', str(mainline), merge)
    restored = run(root, 'write-tree').stdout.strip()
    diff = run(root, 'diff', '--exit-code', '--raw', B, check=False)
    after = {key: run(root, *args).stdout.strip() for key, args in {
        'head': ('rev-parse', 'HEAD'), 'origin': ('remote', 'get-url', 'origin'),
        'bare': ('config', '--get', 'core.bare'), 'config': ('config', '--local', '--list')}.items()}
    if before != after:
        raise RuntimeError('Recovery identity changed')
    matched = restored == expected and diff.returncode == 0
    if matched != (mainline == 1):
        raise RuntimeError('Recovery positive/negative expectation failed')
    results.append({'mainline': mainline, 'synthetic_merge': merge, 'parents': parents[1:],
                    'expected_tree': expected, 'result_tree': restored, 'matches_base': matched,
                    'diff_exit': diff.returncode, 'identity_unchanged': before == after,
                    'root': str(root), 'intentional_worktree_effect': 'uncommitted recovery rehearsal only'})

report = {'candidate': D, 'base': B, 'live_merge': False, 'checks': results, 'commands': records}
(OUT / 'recovery-rehearsal.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(results, indent=2))
