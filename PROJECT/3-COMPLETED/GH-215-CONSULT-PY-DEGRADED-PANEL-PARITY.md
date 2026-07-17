---
gh_issue: 215
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/215
title: "GH-172 follow-up: utils/py/consult.py missing Bash degraded-panel SINGLE-MODEL stamping (keeps XYZ_PYTHON=1 bash test/consult.sh red)"
status: Fixed and verified 2026-07-17 via a marathon lane, merged to `development`. Unmasked a
  separate pre-existing gap, filed as #223 (not fixed here).
created: 2026-07-17
updated: 2026-07-17
owner: noel
doc_type: bug
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not a broader Bash/Python parity audit — GH-172 already completed that; this is the one
    specific named gap it left open
  - Not touching the tick-root/cost-routing fix already landed in utils/py/consult.py via GH-172
related:
  - relay-automation/consult.sh
  - utils/py/consult.py
  - PROJECT/3-COMPLETED/GH-172-VENDORED-ROOT-AUDIT.md
  - PROJECT/3-COMPLETED/GH-172-CUTOVER-RECOMMENDATION.md
  - PROJECT/3-COMPLETED/GH-172-PYTHON-AUDIT-FINDINGS.md
goal: >
  Port relay-automation/consult.sh's degraded-panel SINGLE-MODEL — NOT RECONCILED stamping into
  utils/py/consult.py, so XYZ_PYTHON=1 consult runs match the Bash contract. This is the one
  residual parity gap GH-172's cutover recommendation named as the blocker to switching main to
  Python-default mode.
roadmap_exempt: false
---

# GH-215 · utils/py/consult.py degraded-panel parity gap

## Status

| What was just completed | What's next |
|---|---|
| **Fixed and verified 2026-07-17** via a marathon lane (worktree-isolated Sonnet subagent). Ported the `SINGLE-MODEL — NOT RECONCILED` stamping from `relay-automation/consult.sh:338-356` into `utils/py/consult.py` verbatim (condition, stamp text, sidecar file), plus a matching stdout warn. 2 new `test/consult.sh` cases (single-survivor stamps; full panel doesn't). Independently re-verified: gate `bash test/consult.sh` 50/50 green. **Found in the process (not fixed here, out of this lane's scope):** `XYZ_PYTHON=1 bash test/consult.sh` is still red — GH-215's own bug was previously masking a separate, pre-existing gap (GH-178 A4, the "no firsthand citation" stamp was never ported to `consult.py` either) by failing first. Filed as #223. | Closed out for this lane's own scope. Follow-up: file + fix the GH-178 A4 Python-port gap separately. |

## The gap

GH-172's cutover recommendation named this as the sole blocker to switching `main` to Python-default
(`XYZ_PYTHON=1`) mode. From
[GH-172-PYTHON-AUDIT-FINDINGS.md](../3-COMPLETED/GH-172-PYTHON-AUDIT-FINDINGS.md#utilspyconsultpy):

> `XYZ_PYTHON=1 bash test/consult.sh` is still red, but for a broader pre-existing parity gap that I
> did not touch here: the Python port still lacks the Bash degraded-panel `SINGLE-MODEL — NOT
> RECONCILED` stamping path.

When only one advisor model actually answers in a multi-model consult, `relay-automation/consult.sh`
marks the synthesis `SINGLE-MODEL — NOT RECONCILED` rather than presenting it as a reconciled
multi-model verdict. `utils/py/consult.py` has no equivalent stamping, so a Python-mode consult run
under the same single-advisor-answered condition silently reports as if it were reconciled.

## Fix direction

Find the exact stamping site in `relay-automation/consult.sh` (the degraded-panel / single-model
detection logic), then port the equivalent check into `utils/py/consult.py`'s synthesis path. This
is a direct port of an already-verified Bash pattern, not new design — same discipline as GH-172's
own Lane fixes (mirror first, don't redesign).

## Phase 0 — Port and regression-test

### Checklist

- [ ] Locate the exact `SINGLE-MODEL — NOT RECONCILED` stamping logic in `relay-automation/consult.sh`.
- [ ] Port the equivalent stamping into `utils/py/consult.py`'s synthesis/output path.
- [ ] Add a regression case in `test/consult.sh` proving `XYZ_PYTHON=1` consult stamps the same way
      Bash does under a single-advisor-answered condition.
- [ ] Confirm `XYZ_PYTHON=1 bash test/consult.sh` green.

### QA checklist — Phase 0

- [ ] The fix is a direct port of the already-verified Bash pattern, not a redesign.
- [ ] No regression in `bash test/consult.sh` (Bash mode) or the tick-root/cost-routing fix GH-172
      already landed in this same file.
- [ ] `python3 -m py_compile utils/py/consult.py` clean.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/consult.sh",
  "fix_probes": [ { "type": "command", "cmd": "env XYZ_PYTHON=1 bash test/consult.sh", "expect_nonzero": true } ],
  "artifacts": [ "utils/py/consult.py", "test/consult.sh" ],
  "remediation": { "source": "self#phases", "criteria": "Phase 0 checklist in this doc" },
  "lanes": { "agy_safe": [ "utils/py/consult.py", "test/consult.sh" ], "orchestrator_only": [] }
}
```
