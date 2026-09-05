# GH-439 start-task implementation QA
NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

## Setup
Artifact: skills/start-task/SKILL.md
Producer: producer
Reviewer: codex
Definition of done: An accurate portable skill satisfying the operator's lifecycle and surgical DRY requirements, with bounded QA and truthful per-issue PR outcomes.

## Log

### Round 1 · Producer · 2026-09-04
**Did:** Authored skills/start-task/SKILL.md and added its Skills Index entry. No runtime code changed.
**Verification:** Skill validator passed; malformed-frontmatter negative control failed correctly. Evidence is TESTS-RESULTS/2026-09-04+GH-439/provenance.jsonl. Plan review textually approved but driver format check failed; retained in gh439-plan-qa.md. Global deployment is pending this review.
**Re-review this:** Read only skills/start-task/SKILL.md, PROJECT/2-WORKING/GH-439-START-TASK-SKILL.md, and the provenance file first. Use referenced governance only to settle concrete discrepancies; avoid a repo-wide scan.

Operator requirements: group related issues and separate independent ones; execute dependency order; adapt to each repo; global symlinks for Codex/Claude/Agy/ZCode to the primary repo skill; fresh full clone, GH issue and PDDA/RELEASES; beyond simple changes write a grounded plan with reasonably traced codepaths and QA it before execution; honor debug-mantra/ponytail tags; surgical DRY changes extending existing subsystems without parallel writers; execute and final Codex relay QA; ready PR, leave merges and teardown separate.

Questions:
1. Does the skill preserve every requirement above? Cite any omission or contradiction.
2. Walk independent issues, dependent unmerged PRs, existing issue/PR resume, unavailable reviewer, and failed tests: does it yield the correct next action and honest per-issue outcome?
3. Can an agent follow it without inventing governance/CLI commands, duplicating a subsystem, skipping plan QA, or silently force-overwriting a global install?
4. Identify only actionable blockers or material improvements. Keep optional enhancements distinct.

Only edit this relay file. Append a Reviewer block with graded findings and file:line citations. Include exactly `VERDICT: PASS` on approval or `VERDICT: FAIL` for changes required, plus a separate nonempty `Basis: textual only` line (the machine validator requires these spellings, Approved alone fails). On PASS set header STATUS: Approved and finish the token. Otherwise leave Open and release to producer. Do not run project test suites or make git commits yourself; the shim owns commits. Keep review concise.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
