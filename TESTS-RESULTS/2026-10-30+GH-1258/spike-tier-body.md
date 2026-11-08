## Observed (2026-10-30, `development@e305cbf3`)

| Claim | Command | Observed |
|---|---|---|
| Three contracted issues are STALE and one open issue's fix has landed | `TESTS-RESULTS/2026-10-25+GH-1175-phase0/D4-stale-contracts-intake.md:4`; `test/agent-chorus.sh:617-624` | #423/#141/#275 `swarm-preflight --dry-run` exit 4 (probes already satisfied); #345's fix is in the suite with a `GH-345` comment and the issue is still OPEN |

## Diagnosis / existing gap

Nobody has determined, per issue, whether STALE means delivered-but-open (close with evidence) or a wrong probe (refresh the contract). The answer is an investigation, not a change.

## Plan

1. For each of #423, #141, #275, #345: list the probes, show which landed and in which commit (`git log -S`), and state delivered or wrong-probe.
2. Post the four findings as one comment on #1175 (the umbrella) with the close/refresh recommendation per issue; closing or editing contracts is a separate, operator-approved change.

## Blast radius

Read-only: `PROJECT/2-WORKING/GH-{423,141,275}-*.md`, `test/agent-chorus.sh`, git history. Recon `e305cbf3`; base `development@e305cbf3`. Write-set: one #1175 comment. Route: none (no repo change).

## Dependencies

None. Related: #1175 (D4), #522 (delivered-but-open detector).

## Acceptance

- [ ] One comment on #1175 names each of the four issues with the landed commit for each satisfied probe and a one-word recommendation (close / refresh). Red control: a recommendation with no commit cited is incomplete.

## Verification

Manual: the comment's commits resolve (`git cat-file -e`), recorded under `TESTS-RESULTS/<date>+GH-<this>/`.

## Non-goals

No issue is closed and no contract is edited by this spike.

## Risk and rollback

None; a comment.

## PRS proposal

- pri 40: it feeds #522's delivered-but-open rule with four concrete cases.
- sev 30: four issues misreport their state; nothing breaks.
- appeal 50: operator did not set a preference.
- effort 85: four lookups and one comment.

Recon: e305cbf3 · base: development@e305cbf3 · tier: spike · review: pending
