---
gh_issue: 1583
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1583
title: "marathon planner and frozen twins read a gone path_present probe as blocked, not landed (parity with swarm_preflight, GH-1580)"
status: Proposed (1-INBOX — not yet active)
created: 2026-11-24
updated: 2026-11-24
owner: Kickstart run 3 child (GH-1592)
doc_type: bugfix
effort: 1
complexity: 1
risk: 2
phases: 1
goal: "The Python marathon planner classifies a removed path_present path as landed, exactly as swarm_preflight does."
---

# GH-1583 — planner path_present parity

## Observed problem

`path_present` detects an UNWANTED path (`relay-automation/CONTRACT.example.md:22`): present means the bug is still
there, so a gone path means the fix landed. PR #1593 (GH-1580) made `swarm_preflight.eval_probes` read a gone path as
`landed`, using `os.path.lexists` so a dangling link and a directory entry count as present (`utils/py/swarm_preflight.py:267-270`).
The planner's port still reads it the old way:

- `utils/py/_marathon_plan.py:497-498`: `return "blocked" if not os.path.exists(at(p.get("path"))) else "unfixed"`.

Effect on base `305ebc303`: with `{"type":"path_present","path":"ROADMAP.md"}` and the path absent, the planner reports
`blocked` and never reaches `already-landed` (`_marathon_plan.py:1211-1216`), so it holds an item whose removal already
landed and disagrees with preflight on the same contract.

## Recon map

- Authoritative Python: `utils/py/_marathon_plan.py` (`_eval_probe`), the native engine behind `marathon_plan.py`. Not frozen.
- `utils/marathon-plan.sh:414` and `utils/swarm-preflight.sh:262` are FROZEN Bash twins (GH-308; banner lines 2-3, AGENTS.md).
  The default runtime is Python (`XYZ_PYTHON` unset), and this is a parity fix, not a fallback safety defect, so
  the `Frozen-twin-exception:` trailer does not apply. The twins stay untouched.
- Existing coverage: `test/marathon-plan.sh` (Python lane and `XYZ_PYTHON=0` lane). It has no `path_present` fixture, so no suite pins the old
  `blocked` result and nothing needs a truthful update.
- Prior art: GH-1580 (`TESTS-RESULTS/2026-11-23+GH-1580/`).

## Plan

1. In `_marathon_plan.py:497-498` return `"landed"` when `not os.path.lexists(at(p.get("path")))`, else `"unfixed"`. One expression, mirroring preflight.
2. Run `bash test/marathon-plan.sh` unchanged; record a manual red/green under `TESTS-RESULTS/2026-11-24+GH-1583/` with
   `provenance.jsonl`: absent path (red `blocked`, green `landed`/`already-landed`), existing file, directory and dangling symlink (all `unfixed`).

## Non-goals

The frozen twins, the `grep_*` probes, new tests (GH-831), changing preflight.

## Rating rationale (2026-11-24)

pri 40 / sev 25 / appeal 50 / effort 90. Severity: the planner holds an already-landed item instead of retiring it;
no data loss and the hold is visible. Priority: parity follow-up of #1580, no stated urgency. Appeal: neutral 50.
Effort: a single expression. Recurrence: one report (#1580 final QA F4); trend unknown.

## Acceptance

- [ ] A `path_present` probe whose path is absent evaluates to `landed` in `_marathon_plan.py`, and the row becomes `already-landed` when every probe has landed.
- [ ] An existing file, an existing directory and a dangling symlink at that path still evaluate to `unfixed` (same as preflight).
- [ ] `bash test/marathon-plan.sh` still passes in both lanes, and `utils/marathon-plan.sh` and `utils/swarm-preflight.sh` are unchanged.
- [ ] Manual red and green controls are retained under `TESTS-RESULTS/2026-11-24+GH-1583/` with provenance, and no test file or suite is added.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash test/marathon-plan.sh",
  "fix_probes": [
    {
      "type": "grep_present",
      "path": "utils/py/_marathon_plan.py",
      "pattern": "\"blocked\" if not os\\.path\\.exists"
    },
    { "type": "path_absent", "path": "TESTS-RESULTS/2026-11-24+GH-1583/manual-check.md" },
    { "type": "path_absent", "path": "TESTS-RESULTS/2026-11-24+GH-1583/provenance.jsonl" }
  ],
  "artifacts": [
    "utils/py/_marathon_plan.py",
    "TESTS-RESULTS/2026-11-24+GH-1583/manual-check.md",
    "TESTS-RESULTS/2026-11-24+GH-1583/provenance.jsonl"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-11-24+GH-1583/manual-check.md",
    "TESTS-RESULTS/2026-11-24+GH-1583/provenance.jsonl"
  ],
  "remediation": {
    "source": "issue#1583",
    "criteria": "utils/py/_marathon_plan.py evaluates an absent path_present path as landed using os.path.lexists, leaves existing files, directories and dangling links unfixed, the frozen Bash twins are unchanged, test/marathon-plan.sh passes, and manual red/green controls are retained under TESTS-RESULTS/2026-11-24+GH-1583/ with provenance and no test is added."
  }
}
```
