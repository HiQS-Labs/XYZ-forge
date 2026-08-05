#!/usr/bin/env python3
"""Backfill `source:` issue URLs into capture-doc frontmatter (GH-422).

GH-400 criterion 2 made `swarm-preflight` refuse to emit a packet for a capture doc that declares a
`gh_issue` but does not cite that issue's URL. The gate is right and stays; the cost of satisfying it
was the problem. That posture was chosen from a blast radius measured on the harness repo alone —
1 of 48 docs — while the repos vendoring the harness carried 18 between them. Hand-editing a dozen
frontmatter blocks per repo is not a remediation, it is a tax.

This tool derives the issue URL from the TARGET repo's own `origin` remote, never the harness's, so a
vendored `.xyz/` install fixes its own docs against its own GitHub project.

Deliberately conservative, in three ways that matter:

  * **Dry-run by default.** It edits tracked files, so writing requires `--apply`.
  * **A mismatch is never rewritten.** When `source:` cites a different issue than `gh_issue`, the
    wrong field may be `gh_issue`. A machine cannot tell which, so it reports and leaves the file
    alone. Guessing here would silently launder bad provenance into good-looking provenance, which
    is the exact failure GH-400 exists to prevent.
  * **Frontmatter only.** The body is never touched; the tool reassembles the document from the
    original text and asserts the body is byte-identical before writing.

Never run automatically — not from a hook, not from preflight, not from `xyz-sync update`.
"""

import argparse
import glob
import os
import re
import subprocess
import sys

FRONTMATTER_RE = re.compile(r'\A---\n(.*?)\n---\n', re.DOTALL)
GH_ISSUE_RE = re.compile(r'^gh_issue:\s*"?(\d+)"?\s*$', re.MULTILINE)
SOURCE_RE = re.compile(r'^source:\s*(.+?)\s*$', re.MULTILINE)
ISSUE_URL_RE = re.compile(r'https?://github\.com/([^/\s]+/[^/\s]+?)/issues/(\d+)')


def repo_slug(root):
    """`owner/name` from the target repo's origin remote, or None."""
    try:
        url = subprocess.check_output(["git", "-C", root, "remote", "get-url", "origin"],
                                      stderr=subprocess.DEVNULL).decode("utf-8").strip()
    except Exception:
        return None
    m = re.search(r'(?:github\.com[:/])([^/]+/[^/]+?)(?:\.git)?$', url)
    return m.group(1) if m else None


def effective_issue(path, fm):
    """(issue, basis) using the SAME rule the gate applies, or (None, None).

    `swarm_preflight.check_source_url` is called with the doc's frontmatter `gh_issue` when there is
    one, and otherwise with the issue from `--gh-issue N`, whose doc was resolved by globbing
    `GH-N-*.md`. So a doc named `GH-9-foo.md` with no `gh_issue:` key IS blocked by the gate in
    bundle mode. A backfill that only reads frontmatter silently skips exactly those docs and leaves
    the operator still blocked — the two-extractors-disagree failure agy found in #400's checker
    (see #413). Found here by dry-running against `cactus`, whose docs use `issue:` not `gh_issue:`.
    """
    m = GH_ISSUE_RE.search(fm)
    if m:
        return m.group(1), "frontmatter"
    m = re.match(r'^GH-(\d+)-', os.path.basename(path))
    if m:
        return m.group(1), "filename"
    return None, None


def classify(text, slug, path):
    """(action, detail, new_text) for one document.

    action is one of: 'add' (a source: line is missing or unusable), 'ok' (already cites the right
    issue), 'conflict' (cites a DIFFERENT issue — reported, never rewritten), 'skip' (no frontmatter,
    or no issue identifiable by either rule, so nothing is claimed and nothing is owed).
    """
    fm_match = FRONTMATTER_RE.match(text)
    if not fm_match:
        return "skip", "no YAML frontmatter", None
    fm = fm_match.group(1)

    issue, basis = effective_issue(path, fm)
    if not issue:
        return "skip", "no gh_issue and no GH-<n>- filename — nothing to cite", None
    issue_match = GH_ISSUE_RE.search(fm)

    want = f"https://github.com/{slug}/issues/{issue}"
    src_match = SOURCE_RE.search(fm)
    if src_match:
        raw = src_match.group(1).strip().strip('"\'')
        url = ISSUE_URL_RE.search(raw)
        if url and url.group(2) == issue:
            return "ok", f"already cites issue #{issue}", None
        if url:
            return ("conflict",
                    f"source: cites issue #{url.group(2)} but gh_issue is {issue} — "
                    "not rewritten; the incorrect field may be gh_issue", None)
        # A non-URL value such as `source: issue#154` is replaced in place.
        new_fm = fm[:src_match.start()] + f"source: {want}" + fm[src_match.end():]
        detail = f'replace unusable source: "{raw[:48]}" with the issue URL (issue from {basis})'
    else:
        # Insert after gh_issue where there is one, so provenance sits next to the number it belongs
        # to; otherwise append to the end of the frontmatter block.
        if issue_match:
            anchor = fm.index("\n", issue_match.start()) if "\n" in fm[issue_match.start():] else len(fm)
        else:
            anchor = len(fm)
        new_fm = fm[:anchor] + f"\nsource: {want}" + fm[anchor:]
        detail = f"add source: for issue #{issue} (issue from {basis})"

    new_text = text[:fm_match.start(1)] + new_fm + text[fm_match.end(1):]

    # Frontmatter-only guarantee, asserted rather than assumed. Re-match the frontmatter on the NEW
    # text: inserting a line shifts every offset after it, so reusing `fm_match`'s indices against
    # `new_text` compares misaligned slices and reports a body change that never happened.
    new_fm_match = FRONTMATTER_RE.match(new_text)
    if not new_fm_match or new_text[new_fm_match.end():] != text[fm_match.end():]:
        return "skip", "INTERNAL: body would change — refusing", None
    return "add", detail, new_text


def main():
    ap = argparse.ArgumentParser(description="Backfill capture-doc source: issue URLs (GH-422)")
    ap.add_argument("--root", default=".", help="repo root to scan (default: cwd)")
    ap.add_argument("--apply", action="store_true",
                    help="write the changes; without this the tool only reports")
    ap.add_argument("--dirs", default="1-INBOX,2-WORKING",
                    help="comma-separated PROJECT/ subdirectories to scan")
    args = ap.parse_args()

    root = os.path.abspath(args.root)
    slug = repo_slug(root)
    if not slug:
        print(f"BLOCKED: no GitHub origin remote resolves in {root} — cannot derive issue URLs.",
              file=sys.stderr)
        print("  This tool derives the URL from the TARGET repo's own origin by design, so that a "
              "vendored install cites its own project rather than the harness's.", file=sys.stderr)
        return 6

    docs = []
    for d in args.dirs.split(","):
        docs += sorted(glob.glob(os.path.join(root, "PROJECT", d.strip(), "**", "*.md"),
                                 recursive=True))

    counts = {"add": 0, "ok": 0, "conflict": 0, "skip": 0}
    changed, conflicts = [], []
    for path in docs:
        try:
            with open(path, "r", encoding="utf-8") as f:
                text = f.read()
        except OSError as e:
            print(f"  UNREADABLE {path}: {e}", file=sys.stderr)
            continue
        action, detail, new_text = classify(text, slug, path)
        counts[action] += 1
        rel = os.path.relpath(path, root)
        if action == "add":
            changed.append((rel, detail))
            if args.apply:
                with open(path, "w", encoding="utf-8") as f:
                    f.write(new_text)
        elif action == "conflict":
            conflicts.append((rel, detail))

    verb = "Updated" if args.apply else "Would update"
    print(f"backfill-source-url · {root}")
    print(f"  origin slug : {slug}")
    print(f"  scanned     : {len(docs)} doc(s) under PROJECT/{{{args.dirs}}}")
    for rel, detail in changed:
        print(f"  {verb}: {rel} — {detail}")
    for rel, detail in conflicts:
        print(f"  CONFLICT (untouched): {rel} — {detail}")
    print(f"  summary     : {counts['add']} to change, {counts['ok']} already correct, "
          f"{counts['conflict']} conflict(s), {counts['skip']} not applicable")
    if not args.apply and counts["add"]:
        print("  DRY-RUN: nothing written. Re-run with --apply to write these changes.")
    # Conflicts need a human; exit non-zero so a script cannot mistake this for a clean sweep.
    return 1 if counts["conflict"] else 0


if __name__ == "__main__":
    sys.exit(main())
