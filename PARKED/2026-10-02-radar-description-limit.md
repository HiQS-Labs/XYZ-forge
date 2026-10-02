# Radar skill metadata limit

Observed during GH-927's Markdown skill QA: the existing Radar description is
1336 characters; `skill-creator/scripts/quick_validate.py` permits at most 1024.
`skills/3-weekly/radar/SKILL.md` frontmatter is identical to origin/development;
GH-927 only adds a sibling pointer. Evidence: `TESTS-RESULTS/2026-10-02+GH-927/manual-validation.json`.

Outside GH-927's blocker-assessment and sibling-routing scope. Next decision:
shorten the discovery description while retaining the routing intent, then rerun
the existing metadata validator. This is not a finding about the new pointer.
