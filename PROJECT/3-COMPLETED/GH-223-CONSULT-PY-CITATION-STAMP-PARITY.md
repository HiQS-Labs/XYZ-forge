---
gh_issue: 223
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/223
title: "utils/py/consult.py missing GH-178 A4 'no firsthand citation' stamping (Python parity gap, unmasked by GH-215)"
status: "SHIPPED — closed 2026-07-21, see GitHub issue comment for evidence (commit 54972e9, merged PR #228)."
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
  - Not touching the SINGLE-MODEL stamping GH-215 just added — leave that code as-is
  - Not a broader Bash/Python consult.py audit — this is the one specific named gap
related:
  - relay-automation/consult.sh
  - utils/py/consult.py
  - test/consult.sh
  - PROJECT/3-COMPLETED/GH-215-CONSULT-PY-DEGRADED-PANEL-PARITY.md
goal: >
  Port relay-automation/consult.sh's GH-178 A4 "NO FIRSTHAND VERIFICATION CITED" stamping
  (consult.sh:310-336) into utils/py/consult.py, so XYZ_PYTHON=1 consult runs get the same
  uncited-claim caveat Bash consult already stamps.
roadmap_exempt: false
---

# GH-223 · utils/py/consult.py citation-stamp parity gap

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-07-17, promoted to 2-WORKING with a Swarm Preflight Contract. Found while fixing GH-215 (`consult.py` SINGLE-MODEL stamping) — that fix unmasked this as the next thing `XYZ_PYTHON=1 bash test/consult.sh` fails on (test 12: `stdout missing NO FIRSTHAND VERIFICATION CITED warning`). Not yet fixed. | Queue in the next marathon fire; direct port, no design work needed. |
| **2026-07-21:** shipped via commit `54972e9`, merged PR [#228](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/228); issue #223 closed on GitHub. | Promoted to `3-COMPLETED`. Nothing further for this doc. |

## The gap

`relay-automation/consult.sh:310-336` mechanically stamps any answered advisor whose transcript trips
`rtl_has_uncited_claim()` (shared with B3's per-line downgrade, `relay-turn-lib.sh`) with:

```
**NO FIRSTHAND VERIFICATION CITED** — treat conclusions as conditional (...)
```

— prepended into the transcript file (skipped for `*.json` outputs) plus a sidecar
`$RUN_DIR/${LABEL}.${model}.NO-CITATION.txt`, and a matching `warn` on stdout listing which models
were flagged. `utils/py/consult.py` has zero equivalent logic (no matches for `CITATION`/`uncited`
anywhere in `utils/py/consult.py` or `utils/py/rtl.py`).

This was invisible until GH-215 landed: `test/consult.sh`'s `test/_setup.sh` `fail()` exits
immediately on the first failure, and test (3) (the SINGLE-MODEL case, GH-215's bug) always failed
first — so test (12) (this citation-warning case) never got a chance to run. Fixing GH-215 unmasked
it: `XYZ_PYTHON=1 bash test/consult.sh` now gets past test (3) and fails at test (12).

## Fix direction

Same discipline as GH-215: a direct port, not a redesign. Mirror `consult.sh:310-336`'s detection +
stamping into `utils/py/consult.py`'s synthesis/output path, reusing the same "claim"/"citation"
definition `rtl_has_uncited_claim()` encodes (a Python equivalent likely already exists in
`utils/py/rtl.py` given GH-172's parity work — check there first before writing new detection logic).
Existing test (12) in `test/consult.sh` (forced `XYZ_PYTHON=1`) already exercises this — it should
flip to green once the port lands; no new test needed unless coverage is found lacking.

## Definition of done

- [ ] `utils/py/consult.py` stamps the same `NO FIRSTHAND VERIFICATION CITED` warning (transcript
      prepend + sidecar file + stdout warn) under the same trigger condition as `consult.sh`.
- [ ] `XYZ_PYTHON=1 bash test/consult.sh` green (test 12 passes).
- [ ] No regression in Bash-mode `test/consult.sh` or the SINGLE-MODEL stamping GH-215 just landed.
- [ ] `python3 -m py_compile utils/py/consult.py` clean.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash test/consult.sh",
  "fix_probes": [
    { "type": "command", "cmd": "env XYZ_PYTHON=1 bash test/consult.sh", "expect_nonzero": true }
  ],
  "artifacts": [ "utils/py/consult.py" ],
  "remediation": {
    "source": "issue#223",
    "criteria": "utils/py/consult.py stamps the same NO FIRSTHAND VERIFICATION CITED warning (transcript prepend + sidecar file + stdout warn) as relay-automation/consult.sh:310-336 under the same rtl_has_uncited_claim-equivalent trigger; XYZ_PYTHON=1 bash test/consult.sh passes test (12) and stays green overall; no regression in Bash-mode consult.sh or GH-215's SINGLE-MODEL stamping; python3 -m py_compile utils/py/consult.py clean."
  },
  "lanes": { "agy_safe": [ "utils/py/consult.py" ], "orchestrator_only": [] }
}
```
