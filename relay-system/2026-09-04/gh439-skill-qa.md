# GH-439 start-task implementation QA
NEXT: Reviewer
STATUS: Approved
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

### Round 1 · Reviewer · codex · 2026-09-04
VERDICT: PASS
Basis: textual only

**Grade:** Approved; no blocking findings.

**Findings:** None requiring producer changes.

**Requirement coverage:** The skill preserves the requested lifecycle: request/repo resolution and existing-issue resume before duplicate intake (skills/start-task/SKILL.md:28-36, 57-64), issue grouping with dependency order and per-issue tracking (skills/start-task/SKILL.md:38-50), fresh full clone and XYZ branch/hook expectations (skills/start-task/SKILL.md:52-56), recon-grounded planning with graph-tool preference and uncertainty disclosure (skills/start-task/SKILL.md:67-76), debug-mantra/ponytail handling (skills/start-task/SKILL.md:77-80), surgical DRY extension of existing subsystems without parallel writers (skills/start-task/SKILL.md:88-98), mandatory bounded Codex plan QA for non-simple work (skills/start-task/SKILL.md:101-115), execution plus deterministic verification in safe clones (skills/start-task/SKILL.md:117-130), final Codex relay QA before ready PR claims (skills/start-task/SKILL.md:132-143), and ready-PR handoff without premature merge/closure/teardown (skills/start-task/SKILL.md:145-158). Global installation is portable and non-overwriting, and separates filesystem deployment from app refresh (skills/start-task/SKILL.md:160-179).

**Scenario checks:** Independent issues continue as separate unblocked groups while every issue remains tracked (skills/start-task/SKILL.md:38-45, 50, 143). Dependent unmerged PRs correctly block dependents until the prerequisite lands, unless the user explicitly authorizes stacked PRs (skills/start-task/SKILL.md:47-50, 130). Existing issue/PR resume uses the existing issue, canonical plan, clone, branch, PR, and HEAD instead of duplicating or overwriting (skills/start-task/SKILL.md:31-33, 57-58, 147-148). Unavailable reviewers, containment failures, exhausted caps, nonzero relay exits, empty output, or missing verdicts stop the group rather than producing a self-approved claim (skills/start-task/SKILL.md:101-115, 141-143). Failed tests remain failed or blocked, and failing prerequisites do not pass dependents (skills/start-task/SKILL.md:124-130, 152-157).

**Verification reviewed:** Producer evidence shows the skill validator passed and the malformed-frontmatter negative control failed as intended (TESTS-RESULTS/2026-09-04+GH-439/provenance.jsonl:1-2), with targeted PDDA/release checks and diff whitespace checks clean (TESTS-RESULTS/2026-09-04+GH-439/provenance.jsonl:3-7). I did not run project suites or edit any artifact/source file.
