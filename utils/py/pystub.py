"""Header for an executable Python stub that runs under an exact interpreter (GH-788).

A `#!` line cannot contain a space, so a shebang built from the bare interpreter path fails with
ENOEXEC ("Exec format error") whenever the interpreter lives under a spaced path such as a virtualenv
in `…/GH Repos/…`.
`launcher()` returns a two-line sh/Python polyglot instead: `/bin/sh` runs line 2 as an `exec` of the
quoted interpreter, and Python reads line 1 as a comment and line 2 as a string-literal expression,
then runs the rest of the same file. Same mechanism as gh610's launcher (PR #753), in one file.
"""

import sys


def launcher(python=None):
    """Return the stub header; prepend it to the stub's Python body.

    The interpreter is always single-quoted: that is a string literal in both languages, which
    `shlex.quote` is not for an ordinary path (it leaves `/usr/bin/python3` bare). A path the
    header cannot carry is refused rather than emitted as a broken stub.
    """
    python = sys.executable if python is None else python
    if not python or any(c in python for c in "'\\\n"):
        raise ValueError(f"pystub: interpreter path cannot be embedded in a launcher: {python!r}")
    return "#!/bin/sh\n\"exec\" '" + python + "' \"$0\" \"$@\"\n"
