#!/usr/bin/env python3
"""GH-414 comment-reference extractor — one Python process per scanned tree.

Contract (mirrors utils/py/pdda_gov_scan.py, GH-365): the shell side invokes this ONCE per
tree and consumes `file<TAB>line<TAB>ref` rows from a regular file. Byte-compatibility with
the legacy per-line bash pipelines matters more than elegance: the awk comment-state machine
and the reference regex below are deliberate mirrors of the originals in pdda.sh
(_pdda_comment_scannable_lines / _pdda_comment_extract_refs), so findings do not change shape
when the scanner is present vs. the fallback.

Only `root/src` is walked (same as the legacy find), only the same extensions, `.git` skipped,
output sorted for deterministic findings order. Runtime cost is one process per tree instead
of per-line pipeline fan-out — the bash streaming version of this scan died intermittently by
signal under macOS /bin/bash 3.2 (process-substitution feeds), which is why this helper exists.
"""

import os
import re
import sys

C_LIKE = {".js", ".mjs", ".cjs", ".ts", ".tsx", ".jsx", ".c", ".cc", ".cpp",
          ".h", ".hpp", ".java", ".go", ".rs"}
SCRIPT_LIKE = {".sh", ".bash", ".zsh", ".py", ".rb", ".pl"}

REF_RE = re.compile(r"[A-Za-z0-9_.\-]+(?:/[A-Za-z0-9_.\-]+)+\.(?:md|sh)(?:#[A-Za-z0-9_\-]+)?")
ANCHOR_RE = re.compile(r"#[A-Za-z0-9_\-]+$")


def c_like_comment_lines(text):
    """Mirror of the legacy awk state machine: yield (line_no, comment_text)."""
    in_block = False
    for no, raw in enumerate(text.splitlines(), 1):
        line = raw
        if "//" in line:
            yield no, line[line.index("//") + 2:]
            continue
        if "/*" in line:
            body = line[line.index("/*") + 2:]
            end = body.find("*/")
            if end >= 0:
                yield no, body[:end]
                in_block = False
            else:
                yield no, body
                in_block = True
            continue
        if in_block:
            end = line.find("*/")
            if end >= 0:
                yield no, line[:end]
                in_block = False
            else:
                yield no, line


def script_like_comment_lines(text):
    """Mirror of the legacy awk: leading-whitespace `#` comment lines."""
    for no, raw in enumerate(text.splitlines(), 1):
        stripped = raw.lstrip()
        if stripped.startswith("#"):
            body = stripped[1:]
            if body.startswith(" "):
                body = body[1:]
            yield no, body


def main():
    if len(sys.argv) != 2:
        sys.stderr.write("usage: pdda_comment_refs.py <root>\n")
        return 2
    root = os.path.abspath(sys.argv[1])
    src = os.path.join(root, "src")
    if not os.path.isdir(src):
        return 0
    rows = set()
    for dirpath, dirnames, filenames in os.walk(src):
        dirnames[:] = sorted(d for d in dirnames if d != ".git")
        for name in sorted(filenames):
            path = os.path.join(dirpath, name)
            ext = os.path.splitext(name)[1]
            if ext in C_LIKE:
                extractor = c_like_comment_lines
            elif ext in SCRIPT_LIKE:
                extractor = script_like_comment_lines
            else:
                continue
            try:
                with open(path, encoding="utf-8", errors="replace") as fh:
                    text = fh.read()
            except OSError:
                continue
            for no, line_text in extractor(text):
                for match in REF_RE.findall(line_text):
                    ref = ANCHOR_RE.sub("", match)
                    rows.add((path, str(no), ref))
    for path, no, ref in sorted(rows):
        sys.stdout.write("%s\t%s\t%s\n" % (path, no, ref))
    return 0


if __name__ == "__main__":
    sys.exit(main())
