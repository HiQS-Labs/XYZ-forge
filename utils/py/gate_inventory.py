#!/usr/bin/env python3
"""Report declared negative-control evidence for validate.sh decision gates.

Discovery deliberately comes from validate.sh's TESTS array: adding a registered
executable gate therefore adds an inventory row without a second registry edit.
Evidence is deliberately separate from discovery and lives beside the gate as a
single JSON comment, for example::

    # gate-evidence: {"form":"controlled-bad-fixture","observed":true,"result":"rejected fixture"}

An absent declaration is reported as explicit ``none``.  This tool never treats a
filename, a successful invocation, or a prose mention as negative-control evidence.
"""

from __future__ import annotations

import argparse
import os
import uuid
import json
import hashlib
import shlex
import subprocess
import re
import sys
from pathlib import Path
from typing import Any


ACCEPTED_FORMS = {
    "pre-fix-replay",
    "deliberate-mutation",
    "controlled-bad-fixture",
}
EVIDENCE_RE = re.compile(r"^\s*#\s*gate-evidence:\s*(\{.*\})\s*$", re.MULTILINE)
TESTS_RE = re.compile(r"^TESTS=\((.*?)^\)", re.MULTILINE | re.DOTALL)
QUOTED_ENTRY_RE = re.compile(r'"([^"\n]+)"')
SELF_COMPARISON_RE = re.compile(
    r"\b(?:cmp|diff)\s+(?P<left>[^\s;|]+)\s+(?P=left)(?:\s|$)"
)
COMPARISON_RE = re.compile(r"\b(?:cmp|diff)\s+([^\s;|]+)")
REDIRECT_RE = re.compile(r">\s*([^\s;|]+)")
GENERATE_RE = re.compile(r"\b(?:gen(?:erate)?|render|build|make|write|update|regen(?:erate)?)\w*\b", re.I)
SNAPSHOT_NAME_RE = re.compile(r"(?:expected|golden|snapshot|baseline|artifact)", re.I)
HEREDOC_RE = re.compile(r"<<-?\s*['\"]?([A-Za-z_][A-Za-z0-9_]*)")


def registered_gates(root: Path) -> list[str]:
    """Return the registered shell gates, in validate.sh order."""
    validate = root / "validate.sh"
    return registered_entries(validate.read_text(encoding="utf-8"))


def registered_entries(source: str) -> list[str]:
    """Parse registry text without evaluating a candidate runner."""
    match = TESTS_RE.search(source)
    if not match:
        raise ValueError("could not find TESTS array")
    entries = shlex.split(match.group(1), comments=True)
    if not entries or len(entries) != len(set(entries)):
        raise ValueError("TESTS must contain nonempty, unique literal entries")
    if any(not re.fullmatch(r"[A-Za-z0-9_./-]+\.sh", entry) for entry in entries):
        raise ValueError("TESTS contains unsupported nonliteral entries")
    return entries


def source_outside_heredocs(source: str) -> str:
    """Ignore fixture payloads: comments and commands in them are not this gate's code."""
    executable_lines: list[str] = []
    heredoc_end: str | None = None
    for line in source.splitlines():
        if heredoc_end is not None:
            if line.strip() == heredoc_end:
                heredoc_end = None
            continue
        executable_lines.append(line)
        heredoc = HEREDOC_RE.search(line)
        if heredoc:
            heredoc_end = heredoc.group(1)
    return "\n".join(executable_lines)


def declared_evidence(source: str) -> tuple[dict[str, Any] | None, str | None]:
    """Read the one machine-readable declaration; reject ambiguity or bad shape."""
    declarations = EVIDENCE_RE.findall(source_outside_heredocs(source))
    if not declarations:
        return None, None
    if len(declarations) != 1:
        return None, "multiple gate-evidence declarations"
    try:
        evidence = json.loads(declarations[0])
    except json.JSONDecodeError as error:
        return None, f"invalid gate-evidence JSON: {error.msg}"
    if not isinstance(evidence, dict):
        return None, "gate-evidence must be a JSON object"
    if evidence.get("form") not in ACCEPTED_FORMS:
        return None, "gate-evidence form must be an accepted negative-control form"
    if evidence.get("observed") is not True:
        return None, "gate-evidence must record observed: true"
    if not isinstance(evidence.get("result"), str) or not evidence["result"].strip():
        return None, "gate-evidence must record a non-empty result"
    return evidence, None


def disqualifying_shapes(source: str) -> list[str]:
    """Find the two known structures that cannot falsify a drift/parity claim."""
    executable = "\n".join(
        line for line in source_outside_heredocs(source).splitlines()
        if not line.lstrip().startswith("#")
    )
    shapes: list[str] = []
    if SELF_COMPARISON_RE.search(executable):
        shapes.append("self-comparing-parity")

    redirected = {
        target
        for line in executable.splitlines()
        if GENERATE_RE.search(line)
        for target in REDIRECT_RE.findall(line)
        if SNAPSHOT_NAME_RE.search(target)
    }
    compared = {operand for operand in COMPARISON_RE.findall(executable)}
    if redirected & compared:
        shapes.append("self-regenerating-drift")
    return shapes


def no_evidence(reason: str) -> dict[str, Any]:
    return {"observed": False, "form": "none", "result": "none", "reason": reason}


def inventory(root: Path) -> dict[str, Any]:
    """Build the machine-readable inventory without executing any gate."""
    rows: list[dict[str, Any]] = []
    for entry in registered_gates(root):
        path = root / "test" / entry
        source = path.read_text(encoding="utf-8") if path.is_file() else ""
        shapes = disqualifying_shapes(source)
        evidence, error = declared_evidence(source)
        if not path.is_file():
            negative_control = no_evidence("registered gate file is missing")
        elif shapes:
            negative_control = no_evidence(
                "structurally incapable of falsifying its claim: " + ", ".join(shapes)
            )
        elif error:
            negative_control = no_evidence(error)
        elif evidence is None:
            negative_control = no_evidence("no declared negative-control evidence")
        else:
            negative_control = evidence
        rows.append(
            {
                "gate": f"test/{entry}",
                "discovered_from": "validate.sh:TESTS",
                "disqualifying_shapes": shapes,
                "negative_control": negative_control,
            }
        )
    return {
        "schema_version": 1,
        "scope": "registered executable decision gates",
        "discovery": "validate.sh:TESTS",
        "gates": rows,
    }



def audit(root: Path) -> dict[str, Any]:
    """Read canonical discovery/selection; source references are not execution proof."""
    gates = registered_gates(root)
    tracked = subprocess.check_output(
        ["git", "-C", str(root), "ls-files", "test"], text=True
    ).splitlines()
    if not tracked:
        raise ValueError("empty tracked test discovery")
    routes = subprocess.check_output(
        ["bash", str(root / "utils/ci-route.sh"), "subsystems"], text=True
    ).splitlines()
    if not routes:
        raise ValueError("empty subsystem discovery")
    ownership: dict[str, list[str]] = {}
    for line in routes:
        subsystem, entries = line.split("\t", 1)
        for entry in entries.split():
            ownership.setdefault(entry, []).append(subsystem)
    runners = {name: (root / name).read_text() for name in ("validate.sh", "ci-local.sh")}
    sources = {name: (root / name).read_text(encoding="utf-8") for name in tracked if name.endswith((".sh", ".py", ".js", ".mjs"))}
    rows = []
    for name in tracked:
        if not name.endswith((".sh", ".py", ".js", ".mjs")):
            continue
        path = root / name
        entry = name.removeprefix("test/")
        selected = []
        references = []
        if entry in gates:
            selected = list(runners)
            references = ["validate.sh:TESTS", "ci-local.sh:read_tests"]
            state = "registered-shell"
        elif name.startswith("test/lib/") or Path(name).name in {"_setup.sh", "_scratch-repo.sh"}:
            state = "helper"
        else:
            # Literal direct callers/imports only; dynamic dispatch remains explicitly unknown.
            tokens = {name, Path(name).name}
            if name.endswith(".py"):
                tokens.add(Path(name).stem)
            for caller in tracked:
                if caller == name or not caller.endswith((".sh", ".py", ".js")):
                    continue
                caller_source = sources[caller]
                if any(token in caller_source for token in tokens):
                    references.append(caller)
            selected = [runner for runner, text in runners.items() if name in text]
            if name.startswith("test/flightdeck/") and name.endswith(".py"):
                selected = [runner for runner, text in runners.items() if '"$HERE/test/flightdeck/"' in text]
            if name.startswith("test/unit/") and name.endswith(".test.js"):
                selected = [runner for runner, text in runners.items() if "npm run test:unit" in text]
            state = "explicit-non-shell-lane" if selected else "reference-only-or-uncollected"
        rows.append({"path": name, "classification": state, "selected_by": selected,
                     "subsystems": ownership.get(entry, []), "source_references": sorted(set(references)),
                     "coverage_review": "unreviewed"})
    return {"schema_version": 1, "mode": "observe", "registered_shell_suites": len(gates),
            "tracked_shell_files": sum(name.endswith(".sh") for name in tracked),
            "rows": rows, "limitations": [
                "Literal source references may be comments, fixtures or imports; they are not execution proof.",
                "Dynamic collectors and case/assertion/invariant counts require focused runtime evidence.",
                "Negative-control declarations and advisory review metadata are not authenticated approvals."]}


def decision_view(root: Path, path: Path) -> dict[str, Any]:
    """Validate bounded advisory metadata; NEVER infer authentication from candidate files."""
    records = json.loads(path.read_text())
    if not isinstance(records, list) or not records:
        raise ValueError("decision input must be a nonempty list")
    ids: set[str] = set()
    result = []
    for record in records:
        if not isinstance(record, dict):
            raise ValueError("decision must be an object")
        errors = []
        for field in ("id", "behavior", "consequence", "issue", "overlap", "reason", "reviewer", "review_source", "routing", "red_evidence"):
            if not isinstance(record.get(field), str) or not record[field].strip():
                errors.append(f"missing {field}")
        ident = record.get("id")
        if isinstance(ident, str):
            if ident in ids:
                errors.append("duplicate id")
            ids.add(ident)
        if record.get("outcome") not in {"reuse", "extend", "add", "no-add"}:
            errors.append("invalid outcome")
        bindings = record.get("content")
        if not isinstance(bindings, dict) or not bindings:
            errors.append("missing content bindings")
        else:
            for name, expected in bindings.items():
                file = (root / name).resolve()
                if not file.is_relative_to(root) or not file.is_file():
                    errors.append(f"missing/outside content: {name}")
                elif not isinstance(expected, str) or hashlib.sha256(file.read_bytes()).hexdigest() != expected:
                    errors.append(f"stale content: {name}")
        if record.get("reviewer") == record.get("proposer"):
            errors.append("self-issued review")
        result.append({**record, "state": "unreviewed" if errors else "advisory-reviewed",
                       "metadata_errors": errors, "approval_trusted": False,
                       "would_refuse_mandatory": True,
                       "authority_reason": "No authenticated reviewer/check authority is configured"})
    return {"schema_version": 1, "mode": "observe", "enforcement": "disabled", "decisions": result}

def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    if argv and argv[0] == "admission":
        return admission_main(argv[1:])
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--json", action="store_true", help="emit JSON (the default output format)")
    parser.add_argument("--audit", action="store_true", help="read-only discovery and routing view (not collection proof)")
    parser.add_argument("--decisions", type=Path, help="validate advisory decision JSON; does not approve admission")
    args = parser.parse_args(argv)
    try:
        root = args.root.resolve()
        report = audit(root) if args.audit else inventory(root)
        if args.decisions:
            report["admission"] = decision_view(root, args.decisions)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(f"gate-inventory: {error}", file=sys.stderr)
        return 2
    json.dump(report, sys.stdout, indent=2, sort_keys=True)
    print()
    return 0


# Admission proposals and native-review catalog share this canonical gateway.
PACKET_DIR = '.github/test-admission'
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


def is_packet_path(path):
    return bool(re.fullmatch(re.escape(PACKET_DIR) + r'/[0-9a-f]{32}\.json', path))


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
        rows.append(dict(path=path, status=status, old_mode=old_mode, new_mode=new_mode,
                         old_blob=old_blob, new_blob=new_blob))
    records = [r for r in rows if r['path'].startswith(PACKET_DIR + '/')]
    if len(records) > 1 or any(not is_packet_path(r['path']) or r['status'] != 'A'
                               or r['new_mode'] != '100644' for r in records):
        raise ValueError('one new regular admission record per change; historical records are immutable')
    record_path = records[0]['path'] if records else None
    rows = [r for r in rows if r['path'] != record_path]
    rows.sort(key=lambda row: row['path'])
    if not rows:
        raise ValueError('empty change set; no admission decision to make')
    return base, tree, rows, record_path


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
        counts_by_ref = []
        for ref in (base, head):
            if not git(root, 'ls-tree', ref, '--', 'validate.sh').strip():
                raise ValueError('no canonical shell registry')
            source = git(root, 'show', f'{ref}:validate.sh')
            counts_by_ref.append(len(registered_entries(source)))
        suite_delta = counts_by_ref[1] - counts_by_ref[0]
    except (ValueError, subprocess.CalledProcessError):
        pass  # explicitly unknown; discovery must not be confused with zero.
    return dict(schema='test-admission-catalog@1', state='proposed', approval_trusted=False,
                base=base, reviewed_tree=head, changes=rows, test_files=counts,
                registered_suite_delta=suite_delta, added_case_count='unknown; files are not cases',
                decision=decision, authority='GitHub native operator CODEOWNER review; never this JSON')


def inspect(root, base, head='HEAD'):
    base, tree, rows, record_path = manifest(root, base, head)
    needs = any(not documentation(r['path']) or r['old_mode'] not in {'000000', '100644'}
                or r['new_mode'] not in {'000000', '100644'} for r in rows)
    if not needs and record_path is None:
        result = summary(root, base, tree, rows)
        result['state'] = 'documentation-only; operator PR review still required'
        return result
    if record_path is None:
        raise ValueError('missing regular admission packet; run gate_inventory.py admission prepare')
    text = git(root, 'show', f'{tree}:{record_path}')
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
    result = summary(root, base, tree, rows, data['decision'])
    result['record_path'] = record_path
    return result


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


def admission_main(argv=None):
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
            base, tree, rows, record_path = manifest(root, args.base, 'INDEX')
            data = packet(base, rows, loads(args.rationale.read_text()))
            record_path = record_path or f'{PACKET_DIR}/{uuid.uuid4().hex}.json'
            target = root / record_path
            if target.is_symlink() or target.parent.is_symlink():
                raise ValueError('refusing symlink admission output')
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(json.dumps(data, indent=2, sort_keys=True) + '\n')
            print(f'Wrote proposed decision: {record_path}; stage it. This does not approve tests.')
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


if __name__ == "__main__":
    raise SystemExit(main())
