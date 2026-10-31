# Plan draft: #1203 Audit B: evaluate and stage a pure-Python production runtime

> draft; preflight and independent plan QA outstanding

- Request: `gh-1203-20132f144ba7` (tick `slot_027`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 60/60/85/20
- Capture doc: PROJECT/1-INBOX/GH-1203-PURE-PYTHON.md (sha256 00dac82bf128d38ec66336d1797de2312b44956bcf58ebcf071959538eb55c67)
- Issue sha256: 20132f144ba73dfc9985ee8de05be894679404cf0e2d37decb7a9f08c186965f (updated 2026-10-24T21:37:37Z)
- Dependencies: none

## Scope

_Source: PROJECT/1-INBOX/GH-1203-PURE-PYTHON.md:L18 (frontmatter goal)_

Determine and execute a compatibility-preserving path to Python-only production coordination, containment, automation, ledger, and tick runtime.

## Acceptance criteria

_Source: issue#1203:L28 (Acceptance criteria)_

- A production dependency scan finds no Bash or Node execution on supported runtime paths.
- Existing event logs and machine contracts retain their documented behavior.
- Current containment, concurrency, stale-writer, timeout, and wrong-root negative controls still fail for the intended reasons.
- Vendored and source-tree installs pass the same existing coverage.
- Rollback is possible at each stage without rewriting event history or the SQLite ledger.

_Source: PROJECT/1-INBOX/GH-1203-PURE-PYTHON.md:L42 (Acceptance)_

- Supported production paths execute no Bash or Node.
- Existing logs, machine contracts, CLI behavior, and exit codes remain compatible.
- Containment, concurrency, stale-writer, timeout, and wrong-root negative controls still fire correctly.
- Source and vendored installs pass existing coverage, with rollback possible without rewriting history.

## Open questions

_missing_

## Write set

- `utils/py/rtl.py` (issue#1203:L8)
- `relay-automation/relay-turn-lib.sh` (issue#1203:L8)
- `bin/tick` (issue#1203:L10)

## Unresolved file names

- `package.json` (issue#1203:L26; 3 tracked files share this name)

## Contract probes

- none
