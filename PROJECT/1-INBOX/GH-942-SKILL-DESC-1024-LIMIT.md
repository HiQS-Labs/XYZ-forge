---
gh_issue: 942
source: https://github.com/HiQS-Labs/XYZ-forge/issues/942
title: "9 skills exceed the 1024-char frontmatter description limit"
status: Proposed
created: 2026-10-02
updated: 2026-10-02
owner: operator
goal: "Every committed SKILL.md folds its frontmatter description to ≤1024 chars so skill loaders stop silently dropping skills."
complexity: 1
risk: 1
effort: 2
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Issue #942 filed; all three deployed skills (radar, 10days, express) trimmed on PR #943 and re-vendored from its commits; independent relay QA Approved (`relay-system/2026-10-02/gh943-qa.md`). | Trim the remaining 6 (five, feynman, front-door, readme-audit, spike-360, timbre); re-vendor any that becomes deployed. |

## Problem

ZCode (and any spec-compliant Agent Skills consumer) silently drops a skill at load time when its
frontmatter `description` folds to more than 1024 characters. 9 committed skills are over the limit;
the 3 deployed to the operator's device (`radar`, `10days`, `express`) are therefore invisible to
ZCode sessions despite a healthy skills-army-hq deployment (payload + symlinks verified).

## Affected (canonical `skills/<tier>/<name>/SKILL.md`, folded desc chars)

- ~~1570~~ → 1015 — 3-weekly/10days (deployed; **fixed on PR #943**)
- ~~1336~~ → 1001 — 3-weekly/radar (deployed; **fixed on PR #943**)
- 1241 — 4-occasional/feynman
- 1193 — 4-occasional/front-door
- 1183 — 4-occasional/readme-audit
- 1151 — 4-occasional/spike-360
- 1136 — 4-occasional/timbre
- ~~1131~~ → 1015 — 2-daily/express (deployed; **fixed on PR #943**)
- 1061 — 1-hourly/five

## Fix recipe

1. Trim `description` to ≤1024 folded chars, front-loading trigger wording in the first ~250 chars;
   move cut detail into the body if absent there. Body pins (e.g. `test/gh779-radar-ci-health.sh`)
   are unaffected by frontmatter-only edits.
2. Deployed skills: re-vendor with `intake.py --apply update <name> --source <forge>/skills/<tier>/<name>`;
   symlinks read through, no re-link needed. Restart the consumer session to re-discover.
3. Optional guard rides an existing suite (GH-831 no-new-tests rail) — fail when a committed
   SKILL.md description folds over 1024.

## Merge evidence

- PR #943 merged 2026-10-03 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
