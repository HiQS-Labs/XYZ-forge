---
gh_issue: 844
source: https://github.com/HiQS-Labs/XYZ-forge/issues/844
title: "GH-833 evidence: V1b must scope the PRS entry to the glossary, the witness recipe must return an aggregate status, and the plan's non-goal wording (CodeRabbit on #840)"
status: Active — PR ready; awaiting merge (2-WORKING)
created: 2026-09-26
updated: 2026-09-26
owner: operator (via umbrella #845)
branch: fix/gh844-small-run-record
doc_type: fix
non_goals:
  - Any change to the PRS wording or links.
  - Turning the manual checks into a suite or gate (AGENTS.md, No new tests).
related:
  - "#845 — umbrella for #840's CodeRabbit follow-ups"
  - "#833 / #840 — the change whose evidence this fixes"
goal: >
  GH-833's manual checks can fail on what they claim to check: V1b confines the PRS entry to the glossary, and
  the witness recipe exits non-zero on any unexpected result.
---

# GH-844 — GH-833 evidence hygiene

## Status

| What was just completed | What's next |
|---|---|
| Fixed, witnessed and recorded; see Results. The same PR records the first hosted Small run in the GH-831, GH-833 and GH-836 plans. | Operator merge. Then #843, the other child of #845. |

## Idea

The canonical statement is [#844](https://github.com/HiQS-Labs/XYZ-forge/issues/844). This capture points there.

## Rating — 2026-09-26: `20/10/50/90` (pri/sev/appeal/effort)

Severity 10: evidence tooling and plan wording only; nothing shipped is wrong. Priority 20: a check that cannot
fail on a moved entry, or a recipe that hides a failure, weakens a future re-run. Appeal 50: neutral. Effort 90:
small edits and one re-run. Recurrence: none; these are review findings, not incidents.

## Plan (simple change: local, obvious, reversible; no design decision)

The existing writer is GH-833's own evidence folder. The originals stay as history, and the revisions go next to
them.

1. **Wording.** Fix the non-goal in `PROJECT/2-WORKING/GH-833-PRS-DEFINITION.md:13` to "No new automated suite
   or registry entry".
2. **`prs-definition-check-v2.py.txt`.** Search for the PRS entry only between the `## Glossary…` heading and
   the next `## ` heading. Fail if any `- **PRS**` entry sits elsewhere in `HOW-TO-USE.md`.
3. **`witness-script-v2.sh.txt`.**
   - Each green check and control declares the exit code it wants.
   - A mismatch, or a mutation that does not apply, sets an aggregate status, and the recipe exits with it.
   - New control: move the entry under `## FAQ`. v2 must fail on it, and v1 is run on the same move to show the
     gap.
   - `WITNESS_SELFTEST=1` adds a control built to break the aggregate.

## Results — 2026-09-26

Evidence is in `TESTS-RESULTS/2026-09-26+GH-833/`, recorded in `provenance.jsonl`.

| Check | Result | Evidence |
|---|---|---|
| Green: V1 and V1b-v2 on the tree | both rc 0 | `witnesses-v2.log` |
| Red controls, v2 | all six rc 1 as wanted: the ROUTER line removed, the entry deleted, the ROUTER anchor broken, the entry restated in the FAQ, a skill anchor broken, and the entry moved under `## FAQ` (new) | `witnesses-v2.log` |
| The gap, shown | v1 on the same move: rc 0 (passes) | `witnesses-v2.log` |
| The recipe's aggregate | `AGGREGATE: PASS`, exit 0 | `witnesses-v2.log` |
| The recipe's own red control | `WITNESS_SELFTEST=1`: the no-op control reports `UNEXPECTED`, `AGGREGATE: FAIL`, exit 1 | `witnesses-v2-selftest.log` |
