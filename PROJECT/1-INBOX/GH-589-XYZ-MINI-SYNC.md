---
title: "GH-589: XYZ mini — manifest-driven publisher into HiQS-Labs/XYZ-mini (MVP)"
status: Proposed (1-INBOX — not yet active)
created: 2026-09-13
updated: 2026-09-13
owner: unassigned
goal: one small script in XYZ-forge that copies an embedded manifest of skills into the local XYZ-mini checkout, commits with the source SHA and pushes; plus the minimal source edits that let those skills run without forge governance
gh_issue: 589
source: https://github.com/HiQS-Labs/XYZ-forge/issues/589
doc_type: feedback
context_tags: [xyz-mini, sync, skills, consult]
non_goals:
  - GitHub Action / automatic pipeline (manual `/push-to-xyz-mini` for now)
  - vendoring bin/tick into mini
  - any hardening beyond one ownership guard and one secret scan (operator decision 2026-09-13: MVP, no tech debt)
effort: 4
complexity: 2
risk: 1
---

# GH-589 — XYZ mini publisher (MVP)

## What ships

- `utils/py/xyz_mini_sync.py` — embedded manifest; preview by default; `--apply` copies tracked files, mirrors removals (via `MANIFEST.txt` written on the last run), seeds `TODO.md` once, writes `.xyz-forge-revision`, commits; `--push` pushes and reads `origin/main` back. Guards: every manifest source must be tracked; a destination file the last run did not write is never overwritten; shipped files are regex-scanned for secrets before any write.
- `mini/` — README, TODO seed, gitignore, `skills/skill-viewer` (lists `skills/*/SKILL.md` from frontmatter; resolves its repo from its own location).
- `skills/push-to-xyz-mini/SKILL.md` — operator flow.
- consult: `utils/py/consult.py` tolerates an absent `tick` (explicit broken `TICK_BIN` stays fatal) and counts an exit-0 empty answer as failed. debug-mantra: two forge-only `#419` links genericised. consult/agent-chorus/relay SKILL.md: wording that named forge-only paths.

## Acceptance (issue criteria → test)

| # | Criterion | Test |
|---|---|---|
| 1 | idempotent | `test/gh589-xyz-mini-sync.sh` |
| 2 | loud failure, no partial push | same |
| 3 | inclusion-only | same |
| 4 | consult runs without PROJECT/releases.db/bin/tick | `test/gh589-consult-no-tick.sh` (Python + Bash lanes, exported package) |
| 5 | debug-mantra clean | sync test |
| 6 | viewer count == disk | `test/gh589-skill-viewer.sh` + sync test |
| QA | licences, secret scan, front-door, shakedown | sync test; front-door and shakedown ran once on the candidate (viewer repo-root bug found and fixed) |

## Rating (2026-09-13)

`rated 55/25/50/40` — feature, no defect; operator-requested; appeal neutral; small surface after the MVP cut.

## Log

- 2026-09-13 first publication to `HiQS-Labs/XYZ-mini` `main` = `9bee3be7`; fresh-clone smoke: viewer prints 7 skills, consult with stub CLIs → `2 answered, 0 failed`, no tick.
- 2026-09-13 branch rebuilt from `origin/development` as one commit after the operator rejected review-driven hardening as tech debt.
