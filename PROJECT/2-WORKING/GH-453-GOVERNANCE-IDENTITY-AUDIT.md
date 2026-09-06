---
gh_issue: 453
source: https://github.com/HiQS-Labs/XYZ-forge/issues/453
title: Governance document identity audit
status: Stage 1 planning — Stage 2 awaiting maintainer approval
updated: 2026-09-05
owner: Codex
goal: Establish document ownership and propose corrections without changing governance authority.
created: 2026-09-05
doc_type: feedback
effort: 3
complexity: 3
risk: 2
phases: 2
---

# GH-453 — Governance document identity audit

## Status

| What was just completed | What's next |
|---|---|
| Revised prompt and issue intake; traced upstream manifest and XYZ launch retention. | Independent plan review, then Stage 1 report; Stage 2 remains unapproved. |

## Quad Concepts

- Mixed document authority → separate subject, maintenance and XYZ applicability.
- Stale factual claims → check each principle against bounded evidence.
- Sync overwrites → trace provenance before proposing a durable disposition.
- Policy changes → stop after the report for maintainer approval.

## Scope

Execute Stage 1 of [the revised audit prompt](../1-INBOX/CODEX-GOVERNANCE-DOC-AUDIT-PROMPT.md).
Produce one report with the ownership/applicability inventory, exact proposed corrections,
strategy trade-offs, confirmed/refuted nearby drift, evidence limits and non-goals.
Stage 2 governance edits require explicit approval of that report.

## Table of contents

- [Stage 1 — report](#stage-1--report)
- [Stage 2 — approved corrections only](#stage-2--approved-corrections-only)

## Initial recon and rating

Base: `9a8eb8a59ea2ce9617a77149e198505bb2263f04`, fresh clone from canonical remote,
branch `fix/gh453-governance-audit`, origin/development base. Git hooks installed and checked.
The original issue body remains unchanged; the revised prompt incorporates its review comment.

Instruction path: ROUTER → AGENTS → PROJECT/PDDA; ROUTER calls the constitution policy of record.
Import path: upstream pdda-sync manifest → runtime tree plus PROJECT/PDDA.md; startup docs are
separate opt-in installer copies. XYZ's build-launch-artifact PROJECT_SCAFFOLD retains all five
PROJECT governance files. Local sync policy protects registered local behavior even in imports.
No file removal or rename is proposed; deletion inventory is empty for this report-only phase.

Rating rationale (2026-09-05): RELEASES read-back `70/65/50/55` (priority/severity/appeal/cheapness),
rank 240, no operator override. Misread policy can misdirect agents and sync review, but no new
loss-of-work incident is established. Medium research effort: small document set, mixed history.
Appeal is neutral. Related evidence: issue #406's review and #414's comment-reference audit concern
misstated contracts; they do not prove another instance of this ownership confusion. Searched issue
metadata for governance/PDDA over 2026-08-23..2026-09-05 versus 2026-08-09..2026-08-22 (the query
included 2026-08-08 as a boundary buffer). Results mix features, duplicates and defects; distinct
incident counts and trend are unknown, with no recurrence multiplier. The supplied reviewer
misreading is one reported example, not a measured rising rate.

## Stage 1 — report

1. Record audit/base and upstream SHAs, graph freshness and coverage limits; enumerate the required
   eight documents from disk → expect non-empty inventory with one row per path.
2. Inspect registration, callers/test references, introduction history, upstream manifest and
   provenance for each row → expect subject, maintenance, local authority and protected behavior
   separated; unknown classifications remain ambiguous.
3. Inspect every numbered principle and relevant conventions against bounded source evidence →
   expect confirmed/contradicted/unresolved rows and exact proposed text for falsified claims.
4. Refresh nearby findings, compare at least the path-preserving, banner, relocation and charter
   options, and write disposition/non-goals/approval questions here → expect complete report with
   no governance policy edits and no assertions of sync persistence without evidence.
5. Run relevant report/intake checks and independent Codex report QA → expect attributable results
   or explicit failures; submit the concrete report and stop for maintainer approval.

### QA checklist

- [ ] Every requested file and numbered principle has a row; evidence boundaries are explicit.
- [ ] Missing upstream provenance or local-authority ambiguity is not silently resolved.
- [ ] Revised prompt retains the original requirements, except expressly corrected statements.
- [ ] Only prompt, intake/report, ledger projections and review evidence changed.
- [ ] Review and hygiene results are recorded honestly; no Stage 2 completion claim.

The final reviewer gets an omission-diff question comparing the issue-body requirements, revised
prompt and report. A report can fail on a missing row, unsupported authority decision or absent
required replacement text. There is no new runtime gate in Stage 1, so mutation testing a new
implementation is inapplicable. Stage 2's link checker must reject empty input, missing file and
missing heading; eventual evidence goes under test/baselines/gh453-governance/ with provenance.

## Stage 2 — approved corrections only

Not authorized. Its exact scope and executable sequence will be set from the maintainer-approved
report, then reviewed before edits. It must preserve the user's upstream-policy, checker-behavior,
frozen-twin, package-name and historical-CHANGELOG exclusions. No deployment or merge authorized.

## Risks and rollback

Stage 1 is Easy: a separate branch contains report-only work; no governance behavior changes.
The later authority decision is Costly until the maintainer settles adoption and sync ownership.
Rollback for approved future edits is a scoped revert of this task's commits, followed by sync
and link verification; do not overwrite shared working files from Git or clean up valued clones.
No competing writer or system is introduced: existing RELEASES CLI owns all ledger changes.

## Evidence and execution log

- Initial source checks: upstream manifest names runtime + PDDA.md; launch scaffold names all five.
- Preflight full suite is running in a separate disposable full clone; no passing claim yet.
- Upstream PDDA reference: `2a762f28432da074794e5adfa845108cfe037601`; its manifest
  (`utils/pdda/pdda-sync-manifest.conf:16–23`) distributes only runtime + PROJECT/PDDA.md.
- Predecessor reference: `67dd324487c1fc470b2c539f1cebe2a9c3fb3651`; all four non-PDDA.md
  PROJECT governance docs are byte-identical to that predecessor. Constitution/anti-scope were
  introduced at `1019503`, mode guide at `2ad905e` for predecessor #144, sync policy via #416.
  The four missing provenance sources exist in the predecessor: synthesis moved to PROJECT/4-MISC;
  three feedback docs remain in PROJECT/1-INBOX/PDDA. They are not in the current PDDA repo.
- The current README's “all ... sync inputs / not XYZ Forge policy” paragraph contradicts that
  narrower manifest and the locally owned sync policy; include this refreshed drift in the report.
- Independent plan review pending. Report contents below will be filled only after plan approval.

## Non-goals

No policy adoption/rejection, governance moves/deletions, upstream publications, code changes,
package rename, new sync mechanism, historical-log repairs, merge or clone teardown.
