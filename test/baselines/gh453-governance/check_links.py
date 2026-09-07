#!/usr/bin/env python3
"""GH-453 retained one-off evidence tool; not registered as a production gate.

Checks ordinary inline/reference Markdown links and GitHub-style Markdown headings.
Excludes external URLs, historical logs/transcripts and unrelated document scopes.
Plain-text section names are checked manually, not parsed as Markdown links.
"""
import argparse
import html
import json
import posixpath
import re
import subprocess
from pathlib import Path
from urllib.parse import unquote, urlsplit

SEEDS = {
    'GUIDING-PRINCIPLES.md', 'ROUTER.md', 'README.md', 'AGENTS.md', 'ARCHITECTURE.md',
    'PROJECT/CONSTITUTION.md', 'PROJECT/DO-NOT-BUILD.md',
    'PROJECT/PDDA-MODE-GUIDE.md', 'PROJECT/PDDA-SYNC-POLICY.md', 'PROJECT/PDDA.md',
}


def prose(text):
    lines, fence = [], None
    for line in text.splitlines():
        marker = re.match(r'^\s*(`{3,}|~{3,})', line)
        if marker:
            token = marker[1]
            if fence is None:
                fence = token
            elif token[0] == fence[0] and len(token) >= len(fence):
                fence = None
            continue
        if fence is None:
            lines.append(line)
    return '\n'.join(lines)


def anchors(text):
    clean = prose(text)
    result = set(re.findall(r'<a\s+(?:name|id)=["\']([^"\']+)', clean))
    counts = {}
    for title in re.findall(r'^ {0,3}#{1,6}\s+(.+?)\s*#*\s*$', clean, re.M):
        title = re.sub(r'!?\[([^]]+)\]\([^)]*\)', r'\1', title)
        title = html.unescape(re.sub(r'<[^>]+>', '', title)).lower()
        slug = re.sub(r'[^\w\- ]', '', title).replace(' ', '-')
        count = counts.get(slug, 0)
        counts[slug] = count + 1
        result.add(slug + (f'-{count}' if count else ''))
    return result


def links(text):
    clean = prose(text)
    definitions = dict(re.findall(r'^\s*\[([^]]+)\]:\s*<?([^\s>]+)>?', clean, re.M))
    result = [a or b for a, b in re.findall(r'\]\(\s*(?:<([^>]+)>|([^\s)]+))(?:\s+["\'][^\n]*?["\'])?\s*\)', clean)]
    for label, key in re.findall(r'\[([^]]+)\]\[([^]]*)\]', clean):
        result.append(definitions.get(key or label, 'missing-reference:' + (key or label)))
    # Definition targets are checked as well (including shortcut references).
    result.extend(definitions.values())
    return result


def scan(texts, existing, scope):
    if not scope:
        raise ValueError('empty scanned set')
    errors, count = set(), 0
    for source in scope:
        for target in links(texts[source]):
            if target.startswith('missing-reference:'):
                errors.add((source, target, 'undefined-reference'))
                continue
            url = urlsplit(target)
            if url.scheme or url.netloc:
                continue
            count += 1
            path = unquote(url.path)
            dest = posixpath.normpath(posixpath.join(posixpath.dirname(source), path)) if path else source
            if path.startswith('/'):
                dest = posixpath.normpath(path.lstrip('/'))
            if dest not in existing:
                errors.add((source, dest, 'missing-file'))
            elif url.fragment and dest.endswith('.md') and unquote(url.fragment) not in anchors(texts.get(dest, '')):
                errors.add((source, dest + '#' + unquote(url.fragment), 'missing-heading'))
    return errors, count


def eligible(path):
    return path.endswith('.md') and path != 'CHANGELOG.md' and not path.startswith((
        'PROJECT/3-COMPLETED/', 'PROJECT/4-MISC/', 'relay-system/', 'TESTS-RESULTS/', 'test/',
    ))


def snapshot(root, ref=None):
    args = ['git', '-C', str(root)]
    names = subprocess.check_output(args + (['ls-tree', '-rz', '--name-only', ref] if ref else ['ls-files', '-z'])).decode().split('\0')
    names = {p for p in names if p}
    existing = set(names)
    for name in names:
        parent = posixpath.dirname(name)
        while parent:
            existing.add(parent)
            parent = posixpath.dirname(parent)
    texts = {}
    for name in names:
        if name.endswith('.md'):
            texts[name] = (subprocess.check_output(args + ['show', f'{ref}:{name}']).decode(errors='replace')
                           if ref else (root / name).read_text(errors='replace'))
    scope = {p for p, text in texts.items() if eligible(p) and (p in SEEDS or any(Path(s).name in text for s in SEEDS))}
    return texts, existing, scope


def controls():
    texts = {'a.md': '[valid](b.md#real-heading)', 'b.md': '# Real heading\n'}
    good, count = scan(texts, set(texts), {'a.md'})
    assert count == 1 and not good
    texts['a.md'] = '[bad](missing.md)'
    assert any(e[2] == 'missing-file' for e in scan(texts, set(texts), {'a.md'})[0])
    texts['a.md'] = '[bad](b.md#missing-heading)'
    assert any(e[2] == 'missing-heading' for e in scan(texts, set(texts), {'a.md'})[0])
    try:
        scan(texts, set(texts), set())
    except ValueError:
        pass
    else:
        raise AssertionError('empty input passed')
    return ['valid link accepted', 'missing file rejected', 'missing heading rejected', 'empty scope rejected']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base', required=True)
    parser.add_argument('--root', type=Path, default=Path.cwd())
    args = parser.parse_args()
    proof = controls()
    before = snapshot(args.root, args.base)
    after = snapshot(args.root)
    old, old_count = scan(*before)
    new, new_count = scan(*after)
    assert old_count > 0 and new_count > 0, 'empty link extraction'
    findings = new - old
    print(json.dumps({'base': args.base, 'controls': proof, 'scanned_documents': sorted(after[2]),
                      'link_count': new_count, 'new_defects': sorted(findings),
                      'existing_defects': sorted(new & old), 'resolved_defects': sorted(old - new),
                      'limits': __doc__}, indent=2))
    return bool(findings)


if __name__ == '__main__':
    raise SystemExit(main())
