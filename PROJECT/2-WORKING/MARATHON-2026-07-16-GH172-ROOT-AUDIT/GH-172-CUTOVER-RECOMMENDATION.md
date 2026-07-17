---
title: "GH-172 cutover recommendation"
status: completed
created: 2026-07-17
updated: 2026-07-17
owner: codex
goal: >
  Record the final GH-172 cutover recommendation from the completed Phase 0, Bash, and Python audit
  findings: enumerate any remaining known parity gaps and state explicitly whether a stable Bash
  branch and Python-default mainline cutover are safe.
roadmap_exempt: true
---

# GH-172 cutover recommendation

## Status

| What was just completed | What's next |
|---|---|
| Phase 4 synthesis drafted from the recorded Phase 0, Bash, and Python findings on 2026-07-17, including explicit cutover calls for the Bash branch and Python-default `main`. | Reviewer confirms the recommendation matches the findings docs and either approves or sends it back for correction. |

## Evidence base

This recommendation is intentionally limited to the recorded artifacts for GH-172:

- [GH-172-VENDORED-ROOT-AUDIT.md](../GH-172-VENDORED-ROOT-AUDIT.md) for the Phase 0 root-contract
  findings and fixes already landed before the marathon phases.
- [GH-172-BASH-AUDIT-FINDINGS.md](GH-172-BASH-AUDIT-FINDINGS.md) for the scoped Bash audit results.
- [GH-172-PYTHON-AUDIT-FINDINGS.md](GH-172-PYTHON-AUDIT-FINDINGS.md) for the scoped Python audit
  results.

No new audit was run in this phase.

## Remaining known parity gaps

One known Bash/Python parity gap remains in the recorded findings:

1. `utils/py/consult.py`
   Finding: the Phase 2 Python audit recorded that `XYZ_PYTHON=1 bash test/consult.sh` is still red
   because the Python port lacks the Bash degraded-panel `SINGLE-MODEL — NOT RECONCILED` stamping
   path. The tick-root/cost-routing fix in that file was verified separately, but the broader consult
   output parity gap remains open.

The Bash findings doc does not record any remaining unfixed Bash root-contract gap after the
`relay-automation/consult.sh` fix and its targeted verification.

## Cutover calls

### Safe to cut a stable Bash branch?

**Yes.**

Reasoning:

- The Bash audit recorded one real GH-172 gap in `relay-automation/consult.sh`, and that gap was
  fixed and verified on 2026-07-17.
- Every other scoped Bash entry point in `GH-172-BASH-AUDIT-FINDINGS.md` was recorded as clean
  against the vendored three-root contract.
- The only remaining known parity gap in the recorded artifacts is Python-side consult-panel output
  parity, not a Bash branch blocker.

Conclusion: the current Bash path is documented as root-contract-safe enough to branch as the stable
baseline.

### Safe to switch `main` to Python-default mode (`XYZ_PYTHON=1`)?

**No.**

Reasoning:

- The Phase 2 Python findings explicitly record a still-red `XYZ_PYTHON=1 bash test/consult.sh`.
- The stated cause is an unresolved parity gap in `utils/py/consult.py`: the Python port still lacks
  the Bash degraded-panel `SINGLE-MODEL — NOT RECONCILED` stamping path.
- Switching `main` to Python-default while that gap remains would make the default lane diverge from
  the hardened Bash behavior the cutover is supposed to preserve.

## Blocking gaps for Python-default cutover

Because the Python-default answer is "No", the blocker must stay explicit:

1. `utils/py/consult.py` — `GH-172 Python audit findings` / `## utils/py/consult.py`
   Blocker: the Python consult path still does not match the Bash degraded-panel
   `SINGLE-MODEL — NOT RECONCILED` stamping behavior, and that mismatch keeps
   `XYZ_PYTHON=1 bash test/consult.sh` red in the recorded findings.

## Final recommendation

Cut the stable Bash branch from the current Bash path once the normal release process is ready.
Do not switch `main` to Python-default mode until the remaining `utils/py/consult.py` parity gap is
closed and `XYZ_PYTHON=1 bash test/consult.sh` is green.
