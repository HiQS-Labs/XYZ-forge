---
title: skills-army-hq intake.py update cannot adopt a skill whose payload already matches its source
status: Working
created: 2026-10-31
updated: 2026-10-31
owner: noelsaw1
gh_issue: 1306
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1306
doc_type: bugfix
complexity: 1
risk: 2
effort: 1
phases: 1
non_goals:
  - Moving Skills Army HQ authorship to XYZ-skills-army-mini (#882, mini#2)
  - A RECEIPT-STALE status report or post-pull reconciliation command (#1157 item 4)
  - Any change to payload copy, backup, link or drift semantics
related:
  - GH-1157 (stale receipts; item 2 asks for a no-recopy receipt refresh)
  - HiQS-Labs/XYZ-skills-army-mini#9 (same defect, upstream reference)
goal: >
  `intake.py update NAME --source PATH` records the source receipt for a deployed skill whose bytes
  already equal the source, without recopying, so an unadopted identical skill can be adopted
  through the supported CLI.
---

# GH-1306 — intake.py update cannot adopt an identical skill

## Status

| What was just completed | What's next |
|---|---|
| Plan QA Approved (`relay-system/2026-10-31/gh1306-plan-qa.md`); fix 6426356f; smoke 19/19, red control 4 FAIL; existing suite 33 passed (`TESTS-RESULTS/2026-10-31+GH-1306/smoke.md`) | Final Codex QA, full gate, PR |

## Symptom

`intake.py update NAME --source PATH` prints `Unchanged: NAME` and exits whenever the source digest
equals the deployed digest, without checking the receipt. A `manual/unadopted` skill that is already
byte-identical to its owning repo can never be adopted; hand-editing `.deploy-skills.json` is forbidden.
Seen 2026-10-30 on the MBP 14" collection: 10days, dry, file-xyz-bug, review-code-xyz, review-pr-xyz,
sanity-check, triangulate and xyz.

## Rating

`rated 40/35/50/85` (2026-10-31). Severity 35: provenance and drift visibility are lost for the
affected skills; no data loss, no blocked work, and payloads stay correct. Priority 40: eight skills on
one device are invisible to drift checks today, and a fresh device hits the same wall. Appeal 50
(neutral, no operator preference stated). Effort 85: one branch in one function, existing transaction
path. Recurrence (2026-10-17..10-31 vs prior 14 days): one incident in the window; the related
stale-receipt class appears once in #1157 (2026-10-18). No incidents before that; trend unknown.

## Recon (base 5a93dcfb, origin/development)

- Entry: `skills/3-weekly/skills-army-hq/scripts/intake.py` `main()`, `add`/`update` branch. `source_record()` builds the
  receipt (source, repository, commit, dirty, digest, updated, prerequisites). `found` comes from `inventory()`
  (deployed digests). The early return `if before == record["digest"]: print("Unchanged: …"); return 0` runs before
  any receipt comparison, so state is never written.
- State writer: `transact()` -> `finish()` writes `.deploy-skills.json`, `targets.json`, `catalog.md`, README and
  history. An empty `actions` list is already valid (`catalog`, `adopt-existing` use it).
- Post-apply: `commit_skill()` commits the skill folder in the Pulse repo. State, catalog and history are untracked
  machine state, so a receipt-only update has nothing to commit and would print the misleading
  "WARN not committed … the hourly pulse stays blocked".
- Receipts without `source` come from `catalog` (`state["skills"].setdefault(name, {**info, …})`); `copy_line()` shows
  them as `manual/unadopted`.
- `add` never reaches the equal-digest branch with a deployed skill (`name not in found` is required), so only
  `update` changes behaviour.
- Covering suite: `test/skills-army-hq.sh` (wraps `test/test_deploy_skills.py`, registered in `validate.sh:549`).

## Fix (one function, one file)

In the `add`/`update` branch, when `before == record["digest"]`:
- If the held receipt already names this `source` and its `digest` equals the deployed digest, keep
  `Unchanged: NAME` and exit 0 (today's behaviour for adopted skills).
- Otherwise continue as a **receipt-only** update: no `archive()`, no `stage_payload()`, empty `actions`;
  `details` carries `"receipt_only": true`; the preview prints `skills-army-hq: will RECORD source <src> @ <commit>
  for NAME (payload already identical; nothing copied)`. Prerequisites are preserved by the existing line.
- After apply, skip `commit_skill()` for a receipt-only update (nothing tracked changed) instead of printing the
  blocked-pulse WARN.

Non-goals as in frontmatter. No new suites (GH-831). Rollback: revert the one hunk.

## Verification

1. Existing suite `bash test/skills-army-hq.sh` green (no regression in update/add/self-update paths).
2. Smoke (GH-1088), in a disposable copy of a collection under `TESTS-RESULTS/2026-10-31+GH-1306/`:
   - red control on the pre-fix file: unadopted identical skill -> `Unchanged`, receipt has no source;
   - main path: same command with `--apply` -> receipt records source/commit, payload digest and files unchanged,
     no backup ZIP, no commit attempt WARN;
   - adjacent path: rerun the same command -> `Unchanged` (idempotent);
   - adjacent path: a changed payload still copies (normal update unaffected).
3. Full gate via pre-push (skills-army-hq scripts route to the full tier), once on the final commit.

## After merge

Refresh the deployed manager (`intake.py --apply update skills-army-hq`), then adopt the eight skills with
`intake.py --apply update NAME --source <forge path>`; done when `sync.py --status` shows 0 drift and each copy line
names its source.
