"""GH805 admission implementation behind gate_inventory.py; stdlib, git and gh only.

Git objects and candidate JSON are data, never executable input. GitHub native
CODEOWNER review is approval authority; this module cannot grant an approval.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

PACKET = '.github/test-admission.json'
CHECK = 'test admission'
OPERATOR_ID = 56978803
FIELDS = {'outcome', 'behavior', 'existing_coverage', 'reason', 'red_evidence', 'cost', 'issue'}


def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args], text=True)


def unique_object(pairs):
    value = {}
    for key, item in pairs:
        if key in value:
            raise ValueError(f'duplicate JSON key: {key}')
        value[key] = item
    return value


def loads(text):
    return json.loads(text, object_pairs_hook=unique_object)


def gh(path, payload=None, method=None):
    cmd = ['gh', 'api', path]
    if payload is not None:
        cmd += ['--input', '-']
    cmd += ['--method', method or ('POST' if payload is not None else 'GET')]
    result = subprocess.run(cmd, input=json.dumps(payload) if payload is not None else None,
                            capture_output=True, text=True, check=True)
    return loads(result.stdout) if result.stdout.strip() else None


def paged(path):
    pages = loads(subprocess.check_output(['gh', 'api', '--paginate', '--slurp', path], text=True))
    if not isinstance(pages, list) or any(not isinstance(p, list) for p in pages):
        raise ValueError('malformed paginated GitHub response')
    return [row for page in pages for row in page]


def revision(root, ref):
    return git(root, 'rev-parse', '--verify', ref + '^{commit}').strip()


def test_path(path):
    parts = Path(path).parts
    return (any(p in {'test', 'tests', '__tests__'} for p in parts)
            or bool(re.search(r'(^|/)(test_[^/]+|[^/]+(?:[._-]test|[._-]spec)\.[^/]+)$', path)))


def documentation(path):
    # Never exempt tests, workflows, skills, or metadata capable of changing execution.
    return (not test_path(path) and not path.startswith(('.github/', 'skills/', '.claude/'))
            and Path(path).suffix.lower() in {'.md', '.txt', '.rst'})


def manifest(root, base, head):
    parent = revision(root, 'HEAD' if head == 'INDEX' else head)
    base = revision(root, base)
    ancestors = git(root, 'merge-base', '--all', base, parent).splitlines()
    if len(ancestors) != 1:
        raise ValueError('admission needs one unambiguous integration merge-base')
    base = ancestors[0]
    tree = git(root, 'write-tree').strip() if head == 'INDEX' else parent
    raw = git(root, 'diff', '--raw', '--no-abbrev', '--no-renames', '-z', base, tree, '--')
    fields = raw.split('\0')
    rows = []
    for i in range(0, len(fields) - 1, 2):
        meta, path = fields[i:i + 2]
        old_mode, new_mode, old_blob, new_blob, status = meta.lstrip(':').split()
        if path != PACKET:
            rows.append(dict(path=path, status=status, old_mode=old_mode, new_mode=new_mode,
                             old_blob=old_blob, new_blob=new_blob))
    rows.sort(key=lambda row: row['path'])
    if not rows:
        raise ValueError('empty change set; no admission decision to make')
    return base, tree, rows


def rationale(value):
    if not isinstance(value, dict) or set(value) != FIELDS:
        raise ValueError('rationale requires exactly: ' + ', '.join(sorted(FIELDS)))
    if any(not isinstance(v, str) or not v.strip() for v in value.values()):
        raise ValueError('every rationale field must be a nonempty string; explain unknown cost')
    if value['outcome'] not in {'reuse', 'extend', 'add', 'no-add'}:
        raise ValueError('outcome must be reuse, extend, add or no-add')
    if not re.fullmatch(r'https://github\.com/[^/\s]+/[^/\s]+/issues/[1-9][0-9]*', value['issue']):
        raise ValueError('issue must be a full GitHub issue URL')
    return value


def packet(base, rows, decision):
    return dict(schema='test-admission@1', base=base, changes=rows, decision=rationale(decision))


def summary(root, base, head, rows, decision=None):
    tests = [r for r in rows if test_path(r['path'])]
    counts = {kind: sum(r['status'] == kind for r in tests) for kind in ('A', 'M', 'D', 'T')}
    suite_delta = None
    try:
        import gate_inventory
        counts_by_ref = []
        for ref in (base, head):
            if not git(root, 'ls-tree', ref, '--', 'validate.sh').strip():
                raise ValueError('no canonical shell registry')
            source = git(root, 'show', f'{ref}:validate.sh')
            counts_by_ref.append(len(gate_inventory.registered_entries(source)))
        suite_delta = counts_by_ref[1] - counts_by_ref[0]
    except (ValueError, subprocess.CalledProcessError):
        pass  # explicitly unknown; discovery must not be confused with zero.
    return dict(schema='test-admission-catalog@1', state='proposed', approval_trusted=False,
                base=base, reviewed_tree=head, changes=rows, test_files=counts,
                registered_suite_delta=suite_delta, added_case_count='unknown; files are not cases',
                decision=decision, authority='GitHub native operator CODEOWNER review; never this JSON')


def inspect(root, base, head='HEAD'):
    base, tree, rows = manifest(root, base, head)
    needs = any(not documentation(r['path']) or r['old_mode'] not in {'000000', '100644'}
                or r['new_mode'] not in {'000000', '100644'} for r in rows)
    if not needs:
        result = summary(root, base, tree, rows)
        result['state'] = 'documentation-only; operator PR review still required'
        return result
    mode = git(root, 'ls-tree', tree, '--', PACKET).split()
    if not mode or mode[0] != '100644':
        raise ValueError('missing regular admission packet; run gate_inventory.py admission prepare')
    text = git(root, 'show', f'{tree}:{PACKET}')
    if len(text) > 2_000_000:
        raise ValueError('admission packet exceeds 2 MB')
    data = loads(text)
    if not isinstance(data, dict) or set(data) != {'schema', 'base', 'changes', 'decision'}:
        raise ValueError('invalid admission packet; approval flags are not accepted')
    expected = packet(base, rows, data.get('decision'))
    if data != expected:
        raise ValueError('stale/incomplete admission packet: regenerate for the complete staged change set')
    changes = [r for r in rows if test_path(r['path'])]
    outcome = data['decision']['outcome']
    if any(r['status'] == 'A' for r in changes) and outcome != 'add':
        raise ValueError('new test-tree files require an explicit add decision')
    if changes and outcome in {'reuse', 'no-add'}:
        raise ValueError('test changes require an extend or add decision, including weakening/deletion')
    return summary(root, base, tree, rows, data['decision'])


def markdown(result):
    decision = result.get('decision') or {}
    lines = ['## Test coverage decision', '', f"State: **{result['state']}** — not an approval.",
             f"Test-file changes: {json.dumps(result['test_files'], sort_keys=True)} (A/M/D/T).",
             f"Registered shell-suite delta: {result['registered_suite_delta'] if result['registered_suite_delta'] is not None else 'unknown'}.",
             'Case count: unknown; no assertion count is inferred from filenames.', '']
    # Candidate text is quoted as data, not shell or GitHub workflow commands.
    for key, value in decision.items():
        lines += [f'**{key.replace("_", " ")}**', '> ' + value.replace('\n', '\n> '), '']
    lines += ['Changed test paths:'] + ['- `' + r['path'].replace('`', '') + '` (' + r['status'] + ')'
                                      for r in result['changes'] if test_path(r['path'])]
    lines += ['', 'Approve through the GitHub PR review UI after inspecting the complete diff. New commits dismiss approval.']
    return '\n'.join(lines)


def repo_name(value):
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', value):
        raise ValueError('invalid repository name')
    return value


def live_pr(repo, number):
    if number < 1:
        raise ValueError('positive PR number required')
    pr = gh(f'repos/{repo}/pulls/{number}')
    if pr['base']['ref'] != 'development' or pr['state'] != 'open':
        raise ValueError('expected an open PR targeting development')
    return pr


def dispatch_checks(repo, pr):
    gh(f'repos/{repo}/actions/workflows/test-admission.yml/dispatches',
       dict(ref='development', inputs={'pr': str(pr['number'])}))
    gh(f'repos/{repo}/actions/workflows/ci.yml/dispatches', dict(ref=pr['head']['ref'], inputs={'publication_only': 'true'}))


def open_pr(repo, branch, expected, title, body):
    subprocess.run(['git', 'check-ref-format', '--branch', branch], check=True, capture_output=True)
    if branch in {'main', 'development'}:
        raise ValueError('publish a task branch, not an integration branch')
    from urllib.parse import quote
    current = gh(f'repos/{repo}/git/ref/heads/{quote(branch, safe="")}')['object']['sha']
    if current != expected:
        raise ValueError('branch moved before publication; inspect and retry with current SHA')
    existing = gh(f'repos/{repo}/pulls?state=open&base=development&head={quote(repo.split("/")[0]+":"+branch, safe="")}&per_page=100')
    if len(existing) > 1:
        raise ValueError('ambiguous existing PRs')
    pr = existing[0] if existing else gh(f'repos/{repo}/pulls',
                                        dict(base='development', head=branch, title=title, body=body))
    if pr['user']['id'] != 41898282:
        raise ValueError('existing PR is not bot-authored; operator bootstrap/republication required')
    dispatch_checks(repo, pr)
    return pr


def hosted(root, repo, number, output):
    pr = live_pr(repo, number)
    head = pr['head']['sha']
    run = gh(f'repos/{repo}/check-runs', dict(name=CHECK, head_sha=head, status='in_progress'))
    try:
        # Fetch objects only. Do not checkout/import/run anything from the proposed tree.
        git(root, 'fetch', '--no-tags', 'origin', f'refs/pull/{number}/head')
        if revision(root, 'FETCH_HEAD') != head:
            raise ValueError('PR changed during fetch; rerun admission')
        result = inspect(root, pr['base']['sha'], head)
        result.update(pr=number, head=head, verifier=revision(root, 'HEAD'))
        text = markdown(result)
        Path(output).write_text(json.dumps(result, indent=2) + '\n')
        if os.environ.get('GITHUB_STEP_SUMMARY'):
            with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as stream:
                stream.write(text + '\n')
        if live_pr(repo, number)['head']['sha'] != head:
            raise ValueError('PR changed during validation; rerun admission')
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as exc:
        gh(f'repos/{repo}/check-runs/{run["id"]}',
           dict(status='completed', conclusion='failure', output=dict(title=CHECK, summary=str(exc)[:60000])), 'PATCH')
        raise
    gh(f'repos/{repo}/check-runs/{run["id"]}',
       dict(status='completed', conclusion='success', output=dict(title=CHECK, summary=text[:60000])), 'PATCH')
    return result


def catalog(root, repo, number):
    """Project an authenticated review onto the generated catalog; never write approvals."""
    pr = live_pr(repo, number)
    git(root, 'fetch', '--no-tags', 'origin', f'refs/pull/{number}/head')
    head = pr['head']['sha']
    if revision(root, 'FETCH_HEAD') != head:
        raise ValueError('PR changed during catalog fetch')
    result = inspect(root, pr['base']['sha'], head)
    reviews = paged(f'repos/{repo}/pulls/{number}/reviews?per_page=100')
    own = [r for r in reviews if r.get('user', {}).get('id') == OPERATOR_ID
           and r.get('state') in {'APPROVED', 'CHANGES_REQUESTED', 'DISMISSED'}]
    latest = max(own, key=lambda r: r['id']) if own else None
    accepted = (pr['user']['id'] != OPERATOR_ID and latest is not None
                and latest['state'] == 'APPROVED' and latest['commit_id'] == head)
    result.update(pr=number, head=head, state='operator-reviewed' if accepted else 'awaiting-operator',
                  approval_trusted=accepted, review_url=latest.get('html_url') if latest else None,
                  identity_limit='GitHub account authentication; shared operator credentials defeat human-only separation')
    if live_pr(repo, number)['head']['sha'] != head:
        raise ValueError('PR changed during catalog projection')
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['prepare', 'check', 'hosted', 'publish', 'open-pr', 'catalog'])
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument('--base', default='origin/development')
    parser.add_argument('--head', default='HEAD')
    parser.add_argument('--rationale', type=Path)
    parser.add_argument('--repo', default=os.environ.get('GITHUB_REPOSITORY', 'HiQS-Labs/XYZ-forge'))
    parser.add_argument('--pr', type=int)
    parser.add_argument('--output', default='test-admission-catalog.json')
    parser.add_argument('--branch')
    parser.add_argument('--expected-sha')
    parser.add_argument('--title', default='Review proposed coverage and implementation')
    parser.add_argument('--body', default='Review the admission check summary and complete diff before approving.')
    args = parser.parse_args(argv)
    root = args.root.resolve()
    try:
        if args.command == 'prepare':
            if not args.rationale:
                raise ValueError('prepare requires --rationale FILE; stage intended changes first')
            base, tree, rows = manifest(root, args.base, 'INDEX')
            data = packet(base, rows, loads(args.rationale.read_text()))
            target = root / PACKET
            if target.is_symlink() or target.parent.is_symlink():
                raise ValueError('refusing symlink admission output')
            target.parent.mkdir(exist_ok=True)
            target.write_text(json.dumps(data, indent=2, sort_keys=True) + '\n')
            print(f'Wrote proposed decision: {PACKET}; stage it. This does not approve tests.')
            return 0
        if args.command == 'check':
            print(markdown(inspect(root, args.base, args.head)))
            return 0
        repo = repo_name(args.repo)
        if args.command == 'catalog':
            if not args.pr:
                raise ValueError('--pr required')
            print(json.dumps(catalog(root, repo, args.pr), indent=2))
            return 0
        if args.command == 'publish':
            branch = args.branch or git(root, 'branch', '--show-current').strip()
            inspect(root, args.base, 'HEAD')
            gh(f'repos/{repo}/actions/workflows/publish-test-pr.yml/dispatches', dict(ref='development', inputs=dict(
                branch=branch, sha=revision(root, 'HEAD'), title=args.title, body=args.body)))
            print('Bot PR publication dispatched; inspect the resulting PR and exact-head checks.')
            return 0
        if os.environ.get('GITHUB_ACTIONS') != 'true' or os.environ.get('GITHUB_REF') != 'refs/heads/development':
            raise ValueError('hosted publication requires the trusted development workflow')
        if args.command == 'open-pr':
            pr = open_pr(repo, args.branch or '', args.expected_sha or '', args.title, args.body)
            print(pr['html_url'])
        else:
            if not args.pr:
                raise ValueError('--pr required')
            hosted(root, repo, args.pr, args.output)
        return 0
    except (OSError, ValueError, KeyError, TypeError, subprocess.CalledProcessError) as exc:
        print(f'test-admission: REFUSED: {exc}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
