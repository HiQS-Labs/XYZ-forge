---
title: "GH-728: /merge-cleanup-deep — read-only sub-agent triage of the checkouts /merge-cleanup preserves"
status: Complete
created: 2026-09-21
updated: 2026-09-21
owner: Claude Code (merge-cleanup → workhorse)
gh_issue: 728
source: https://github.com/HiQS-Labs/XYZ-forge/issues/728
doc_type: project
complexity: 2
risk: 1
effort: 2
goal: >
  Give the PRESERVE_* rows that /merge-cleanup leaves behind a verdict, a backup, and one next step,
  without adding judgment or cost to the landing skill itself.
---

# GH-728 — `/merge-cleanup-deep`

Issue: [GH-728](https://github.com/HiQS-Labs/XYZ-forge/issues/728). Decided during the
2026-09-21 `/merge-cleanup` run, after a hand-driven deep pass over 14 preserved sibling clones.

## Status

| What was just completed | What's next |
|---|---|
| Skill written (`skills/merge-cleanup-deep/SKILL.md`, `agents/scan-prompt.md`, `agents/openai.yaml`) from the 2026-09-21 run: scanner-JSON intake, zip-first backup + manifest, ≤3 read-only agents by branch family, evidence checklist a–g, re-verification, handoff table. Skills Index rows for `merge-cleanup` and `merge-cleanup-deep`; merge-cleanup's Deep Scan Escalation now points here. | Land via `/merge-cleanup`; first real use is the next preserved-clone pile (the 12 disposable clones from 2026-09-21 are already zipped under `~/Documents/Backups/XYZ-forge-clones-2026-09-21/`). Publish to the Pulse collection per the skill-edit pipeline. |

## Decision: separate skill, not a merge-cleanup phase

- `/merge-cleanup` is script-owned and parity-guarded (`gh534_phase_c_tests.py::TestParityGuard`);
  its own rule is *the script owns the evidence and the cap, the caller owns the analysis*. The
  triage is caller-owned judgment.
- Cost: three sub-agents (~380k tokens on 14 clones) must be opt-in, never part of every landing.
- DRY holds: Phase 0 consumes `scan_clones.py --json`; Phase 4 returns disposable checkouts to
  merge-cleanup's Phase 6. No second discovery, no second deletion path.

## Smallest affected surface

- New: `skills/merge-cleanup-deep/{SKILL.md,agents/scan-prompt.md,agents/openai.yaml}`.
- `ARCHITECTURE.md` Skills Index: two rows (`merge-cleanup` was missing too). Six other skills are
  still unindexed (`browserbase`, `ci-optimize`, `converge`, `dry`, `timbre`, `unstuck`,
  `workhorse`) — out of scope here.
- `skills/merge-cleanup/SKILL.md` Phase 3: the escalation line names this skill. No script, test,
  or CLI change; the parity guard's capability table and option list are untouched.

## Acceptance checks

- [x] `test/gh589-skill-viewer.sh` contract: the skill has parsable `name`/`description`
  frontmatter and the folder set equals the viewer's set (the viewer derives from `skills/*/`).
- [x] Skills Index links resolve (`skills/merge-cleanup-deep/SKILL.md` exists).
- [ ] First real run on a preserved-clone pile produces the disposition table and zips (recorded
  on #728 at closeout).

## Merge evidence

- Gate: pre-push gate on the task clone (route classified by the hook); receipt in the PR.

## Lessons Learned (For Future Agents)

- Group sub-agents by **branch family**, not by count: five clones of one branch name were five
  independent re-executions of one plan, and only an agent holding all five could establish that
  none was an ancestor of another.
- A sub-agent's "unique defect" is intake only after the caller re-checks `development` and open
  issues — both QA-surfaced blockers on 2026-09-21 were already #656/#657, and their fix sat in a
  different clone family.
- Zip **before** analysis and include `.git`; the unpushed refs are the point, and the zip makes a
  later Trash teardown doubly recoverable.
