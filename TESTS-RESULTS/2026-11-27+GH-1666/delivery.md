# GH-1666 acceptance line model delivery

Issue and capture criteria, declared deviations, and packet checklists now split on CRLF, CR, and LF. Issue-side fence detection examines those same lines. The existing fidelity suite checks that a shortened U+2028 copy diverges and that all eight additional Python line separators stay inside the criterion, raw checklist line, and declaration.

## Verification

Ran the [prepared read-only probe](../2026-11-27+GH-1658-runA-prep/probe-gh1666.py) with Python 3.14.7 and `PYTHONDONTWRITEBYTECODE=1` against the relay worktree before and after the edit.

| Revision | Exit | Observed result |
|---|---|---|
| Before | 1 | `AssertionError: ('0xb', ['Alpha', 'Gamma'], ['Alpha', 'Gamma'])`. Both readers lost `beta`. |
| After | 0 | All eight separators passed the issue, capture, checklist, deviations, and fence checks. The mixed CRLF/CR/LF control also passed. |

A separate direct fidelity probe returned `match` for the U+2028 fence-closer input and the verbatim `Alpha\u2028beta` copy. The shortened copy returned `diverged`, with `Alpha beta` dropped and `Alpha` added. Rendering the packet checklist preserved the literal U+2028. Shell and Python syntax checks passed.

The relay harness owns execution of `bash test/gh400-acceptance-fidelity.sh`. Its result was pending at handoff.
