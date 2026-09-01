#!/usr/bin/env python3
r"""pdda_gov_scan.py — GH-365 step 4: ONE in-process governance reference scan per doc.

WHY THIS FILE EXISTS
--------------------
`utils/pdda/pdda.sh`'s check_governance used to extract file references from its governance docs
one LINE at a time: `_pdda_gov_extract_refs` spawned four `printf | grep -oE | sed` pipelines per
line, and check_governance scanned every doc TWICE (pass 1 collects bare names for the batch
find-cache, pass 2 validates refs). ~2,775 scannable lines x 2 passes x ~8 short-lived processes
is tens of thousands of process spawns per run — measured at ~78% of an 87s `pdda.sh run` on
macOS (GH-365 step 4). This file replaces that fan-out with ONE in-process scan per doc that
reproduces the legacy extraction byte-exactly, so check_governance can cache the whole
"<lineno>TAB<ref>" list once per doc and read it from both passes.

It lives in `utils/py/` — NOT `utils/pdda/` — because `utils/pdda/**` is sync-managed (see
PROJECT/PDDA-SYNC-POLICY.md: "New local behaviour belongs outside utils/pdda/** so a later sync
cannot silently remove it"). A sync that reverts pdda.sh's hook simply falls back to the legacy
per-line path pdda.sh still carries; this scanner then goes unused, never wrong.

CONTRACT (byte-exact with the legacy path it replaces)
------------------------------------------------------
CLI:  python3 pdda_gov_scan.py <abs-doc-path>
out:  one "<lineno>TAB<ref>" pair per extracted reference, in the legacy iteration order —
      scannable-line order, and LC_ALL=C sort -u order of refs within a line. Refs never
      contain tabs or newlines (the extraction patterns exclude both), so the pair is
      unambiguous.
exit: 0 with the pairs (an empty set prints nothing and exits 0); 2 if the doc cannot be read.

What "byte-exact" means here, concretely — every stage of the legacy pipeline is reproduced:

  1. `_pdda_gov_scannable_lines` (awk): lines outside an exempt ```console/```text/```transcript
     fence and outside blockquotes, emitted as "<NR>TAB<line>". Fence delimiter lines and
     blockquote lines are never emitted; lines inside a NON-exempt fence (e.g. ```bash) ARE.
  2. `_pdda_gov_extract_refs` (4x grep -oE + sed) applied to each line, unioned, then
     GH-<n>-*.md names filtered and the result LC_ALL=C sort -u'd:
       (a) markdown-link targets   ](x.md) / ](x.sh#anchor)
       (b) whole-span code refs    `x.md` / `x.sh`
       (c) command-position paths  a *.sh at line start or opening a code span, ending at a
           terminator (space class, backtick, `,;:)"'`) or end of line; leading ./ stripped
       (d) interpreter-wrapped     bash/sudo/env/source/... x.sh — wrapper words (and VAR=val
           assignments for env) stripped; leading ./ stripped
  3. The GH filter '(^|/)GH-[0-9]+-[^/]*\.md(#.*)?$' drops illustrative issue-doc names.

POSIX-vs-Python notes (why this is not a naive regex transliteration):
  * The file is read as BYTES and decoded latin-1, so one char == one byte and every character
    class below has exactly the ASCII membership its POSIX [[:space:]] / [A-Za-z0-9_] counterpart
    has. Sorting latin-1 strings by codepoint is LC_ALL=C byte order, so the final per-line sort
    matches `LC_ALL=C sort -u` exactly. Python's \s is NOT used anywhere: it is Unicode-aware and
    would admit non-ASCII whitespace grep never matches.
  * POSIX ERE is leftmost-longest; Python `re` is leftmost-first. Where the two could print a
    different FULL match, the legacy sed post-strip normalizes the difference away (an anchor
    chosen as ^ instead of consuming the backtick still yields the same ref after the leading
    backtick/whitespace strips), and the terminator alternation is unambiguous (a terminator
    char is consumed whenever one follows; $ only at end of line). The alternation order below
    (backtick before ^, terminator class before $) mirrors the longest-match preference anyway.
"""

import re
import sys

# POSIX [[:space:]] membership: space, tab, newline, CR, FF, VT. Built with chr() so the class
# carries the real control characters, not a spelling of them.
_SP, _TAB, _NL, _CR, _FF, _VT = " ", chr(9), chr(10), chr(13), chr(12), chr(11)
_WS_CHARS = _SP + _TAB + _NL + _CR + _FF + _VT
_WS = "[" + _WS_CHARS + "]"

# The (c)/(d) terminator class, POSIX [[:space:]`,;:)"'] — space class plus backtick, comma,
# semicolon, colon, close-paren, double quote, single quote. Built by concatenation so neither
# quote needs an escape that a raw string would mangle.
_TERM_C = "[" + _WS_CHARS + "`" + ",;:)" + '"' + "']"

FENCE_DELIM_RE = re.compile("^[" + _WS_CHARS + "]*```")   # /^[[:space:]]*```/
LEADING_TICKS_RE = re.compile("^[" + _WS_CHARS + "]*`+")  # sub(/^[[:space:]]*`+/,"",info)
ANY_WS_RE = re.compile("[" + _WS_CHARS + "]+")            # gsub(/[[:space:]]/,"",info)
BLOCKQUOTE_RE = re.compile("^[" + _WS_CHARS + "]*>")      # /^[[:space:]]*>/
EXEMPT_INFO_STRINGS = ("console", "text", "transcript")

# (a) markdown-link targets — '\]\([^)[:space:]]+\.(md|sh)(#[A-Za-z0-9_-]*)?\)'
# The negated class is built from _WS_CHARS (the bare members), not _WS (a full class), because
# this class is already open — embedding a bracketed class inside it would close it early.
PAT_LINK = re.compile(r"\]\([^)" + _WS_CHARS + r"]+\.(md|sh)(#[A-Za-z0-9_-]*)?\)")

# (b) whole-span code refs — '`[A-Za-z0-9_./-]+\.(md|sh)(#[A-Za-z0-9_-]*)?`'
PAT_CODESPAN = re.compile(r"`[A-Za-z0-9_./-]+\.(md|sh)(#[A-Za-z0-9_-]*)?`")

# (c) command-position paths. A *.sh token opening a code span or the scanned line, ending at
# one of the terminators or end of line. A trailing '.' is deliberately NOT a terminator —
# deploy.sh.bak must not yield deploy.sh (see the legacy comment in pdda.sh).
_SUFFIX = r"\.sh(" + _TERM_C + r"|$)"
PAT_COMMAND = re.compile(
    r"(`|^)" + _WS + r"*(\.{1,2}/)?[A-Za-z0-9_.][A-Za-z0-9_./-]*" + _SUFFIX
)

# (d) interpreter-wrapped invocations — one or more wrapper words (sudo|source|bash|zsh|env|sh|.,
# i.e. a literal '.' for POSIX sourcing), each optionally followed by VAR=val assignments (env),
# then the path in argument position. The path's leading char class rejects '-' (so `bash -c`
# is not a path) and '"'/'$' (a quoted or variable-expanded argument is not a path claim).
_WRAPPER = (
    r"((sudo|source|bash|zsh|env|sh|\.)("
    + _WS
    + r"+[A-Za-z_][A-Za-z0-9_]*=[^"
    + _WS_CHARS
    + r"]*)*"
    + _WS
    + r"+)+"
)
PAT_WRAPPED = re.compile(
    r"(`|^)" + _WS + r"*" + _WRAPPER + r"(\.{1,2}/)?[A-Za-z0-9_.][A-Za-z0-9_./-]*" + _SUFFIX
)

# sed post-strips, translated. Each operates on one grep -o match string.
LEADING_WS_STRIP = re.compile("^" + _WS + "+")
TRAILING_TERM_STRIP = re.compile(_TERM_C + "+$")  # s/[[:space:]`,;:)"']+$//
WRAPPER_STRIP = re.compile(_WRAPPER)              # s/^((sudo|...)+// — used anchored at start

# The final GH-<n>-*.md filter — grep -Ev '(^|/)GH-[0-9]+-[^/]*\.md(#.*)?$'
GH_NAME_FILTER = re.compile(r"(^|/)GH-[0-9]+-[^/]*\.md(#.*)?$")


def scannable_lines(text):
    """Yield (lineno, line) pairs outside exempt fences/blockquotes — the awk filter."""
    lines = text.split(_NL)
    # awk's last record has no terminator: "a\n" is ONE record, but split yields a trailing "".
    if text.endswith(_NL):
        lines.pop()
    in_fence = False
    fence_exempt = False
    for lineno, line in enumerate(lines, 1):
        if FENCE_DELIM_RE.match(line):
            if in_fence:
                in_fence = False
                fence_exempt = False
            else:
                info = LEADING_TICKS_RE.sub("", line)
                info = ANY_WS_RE.sub("", info)
                info = info.lower()
                in_fence = True
                fence_exempt = info in EXEMPT_INFO_STRINGS
            continue
        if in_fence and fence_exempt:
            continue
        if BLOCKQUOTE_RE.match(line):
            continue
        yield lineno, line


def _strip_span(match_text, drop_wrapper):
    """The sed chain every (c)/(d) match goes through, in the legacy order."""
    s = match_text
    if s.startswith("`"):                 # s/^`//
        s = s[1:]
    s = LEADING_WS_STRIP.sub("", s)       # s/^[[:space:]]+//
    if drop_wrapper:                      # s/^((sudo|source|...)+//   ((d) only)
        m = WRAPPER_STRIP.match(s)
        if m:
            s = s[m.end():]
    s = TRAILING_TERM_STRIP.sub("", s)    # s/[[:space:]`,;:)"']+$//
    if s.startswith("./"):                # s|^\./||
        s = s[2:]
    return s


def extract_refs(line):
    """Refs for ONE line — the union of patterns (a)-(d), GH-filtered, LC_ALL=C sorted unique.

    Reproduces `_pdda_gov_extract_refs "$line"` including its final `sort -u`: the four pattern
    outputs are unioned and deduplicated per line, in byte order.
    """
    refs = []
    for m in PAT_LINK.finditer(line):
        refs.append(m.group(0)[2:-1])  # strip leading "](" and trailing ")"
    for m in PAT_CODESPAN.finditer(line):
        refs.append(m.group(0)[1:-1])  # strip the surrounding backticks
    for m in PAT_COMMAND.finditer(line):
        refs.append(_strip_span(m.group(0), drop_wrapper=False))
    for m in PAT_WRAPPED.finditer(line):
        refs.append(_strip_span(m.group(0), drop_wrapper=True))
    return sorted(set(r for r in refs if not GH_NAME_FILTER.search(r)))


def scan(path):
    """The whole-doc scan: every scannable line's refs, as "lineno TAB ref" lines."""
    with open(path, "rb") as fh:
        text = fh.read().decode("latin-1")
    out = []
    for lineno, line in scannable_lines(text):
        for ref in extract_refs(line):
            out.append("%d" % lineno + _TAB + ref)
    return out


def main(argv):
    if len(argv) != 2:
        sys.stderr.write("usage: pdda_gov_scan.py <abs-doc-path>" + _NL)
        return 2
    try:
        lines = scan(argv[1])
    except OSError as exc:
        sys.stderr.write("pdda_gov_scan: cannot read %s: %s" % (argv[1], exc) + _NL)
        return 2
    payload = _NL.join(lines) + (_NL if lines else "")
    sys.stdout.buffer.write(payload.encode("latin-1"))
    sys.stdout.buffer.flush()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
