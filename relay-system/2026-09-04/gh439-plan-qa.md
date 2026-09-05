# GH-439 start-task plan QA
NEXT: Reviewer
STATUS: Approved
ROUND: 1 / 3

## Setup
Artifact: PROJECT/2-WORKING/GH-439-START-TASK-SKILL.md
Producer: producer
Reviewer: codex
Definition of done: A grounded, minimal plan that fully captures the operator requirements without duplicating runtime systems.

## Log

### Round 1 · Producer · 2026-09-04
**Did:** Recorded the plan.
**Verification:** Textual recon only.
**Re-review this:** Questions below.
**Commit:** 619e8d30
Review the artifact and the referenced existing skills and governance. This is plan QA only: do not implement the skill or run mutation-heavy test suites. Verification: direct source/document inspection; implementation not started.

Questions:
1. List any user requirement in the Scope/Plan that the acceptance criteria fail to cover, especially multi-issue grouping/dependencies, both QA stages, DRY and global deployment.
2. Is the plan grounded in existing workflow paths and does it avoid duplicating governance or prematurely merging/closing issues?
3. Are verification and reversible deployment sufficient for a documentation-only skill? Identify concrete blockers with file:line citations. Distinguish scope requirements from optional improvements.

Write graded findings and verdict with Basis: textual only. Only edit this relay file. Set STATUS: Approved if no blockers, otherwise leave Open and hand back to producer. Do not commit manually; shim owns commits. Use tick release for handoff or tick done on approval as instructed by runtime.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

### Round 1 · Reviewer · codex · 2026-09-04
**Verdict:** Approved.
**Basis:** Textual only; direct inspection of `PROJECT/2-WORKING/GH-439-START-TASK-SKILL.md`, `ROUTER.md`, `PROJECT/PDDA.md`, `GUIDING-PRINCIPLES.md`, `skills/workhorse/SKILL.md`, `skills/relay-xyz/SKILL.md`, `skills/merge-cleanup/SKILL.md`, `ARCHITECTURE.md`, and targeted `rg`/`nl` checks. No source/artifact edits or project test gates run.

**Findings:**
- **[Pass] Scope requirements are covered by acceptance.** The requested multi-issue/dependency shape is in the plan as "per-issue dependency/status mapping" and scenario inspection for independent/dependent issues, unresolved dependencies, and duplicate intake (`PROJECT/2-WORKING/GH-439-START-TASK-SKILL.md:39-42`). Acceptance requires preserving per-issue outcomes, using repo governance, both plan QA and final QA, no merge/closure claim at PR creation, malformed-frontmatter red control, and symlink wrong-target rejection (`PROJECT/2-WORKING/GH-439-START-TASK-SKILL.md:44-46`).
- **[Pass] The plan is grounded in existing workflow owners and avoids duplicating runtime systems.** The scope forbids runtime changes, new executors, parallel ledgers, automatic merges, and cleanup (`PROJECT/2-WORKING/GH-439-START-TASK-SKILL.md:23-25`). The recon/design path correctly delegates diagnosis/design/consult to `workhorse`, relay containment/driver behavior to `relay-xyz`, and merge/teardown to `merge-cleanup` (`PROJECT/2-WORKING/GH-439-START-TASK-SKILL.md:27-35`). This aligns with `workhorse` being a coordination ladder over existing skills rather than a duplicate abstraction (`skills/workhorse/SKILL.md:17-20`), `relay-xyz` requiring the shipped relay harness instead of hand-rolled handoff (`skills/relay-xyz/SKILL.md:43-49`), and `merge-cleanup` owning merge sequencing, reconciliation, and teardown (`skills/merge-cleanup/SKILL.md:60-78`).
- **[Pass] Verification and reversibility are sufficient for a documentation-only skill.** The plan marks the change Easy to reverse because it is additive and symlink-based (`PROJECT/2-WORKING/GH-439-START-TASK-SKILL.md:33-35`), which matches the no-runtime-codepath claim (`PROJECT/2-WORKING/GH-439-START-TASK-SKILL.md:31`). Verification is proportionate: frontmatter/doc governance plus disposable malformed fixture, scenario inspection, implementation relay QA, and exact symlink-resolution checks (`PROJECT/2-WORKING/GH-439-START-TASK-SKILL.md:39-46`). This is consistent with PDDA's deterministic-doc plus LLM-review model (`PROJECT/PDDA.md:7-19`) and active-doc contract (`PROJECT/PDDA.md:44-66`).
- **[Pass] PR boundary is correctly bounded.** The plan opens a PR against `development` and preserves the task clone while unmerged, but does not merge or close issues (`PROJECT/2-WORKING/GH-439-START-TASK-SKILL.md:42-46`). That matches the maintainer SOP that fresh task work lands by branch + PR into `development`, not direct `development` commits (`SOP.md:197-220`), while merge duty remains a separate orchestrator/cleanup concern (`SOP.md:249-254`; `skills/merge-cleanup/SKILL.md:66-78`).

**Non-blocking notes for implementation:**
- Spell out the exact global install targets in the skill from the verified set rather than relying on prose memory. Current evidence supports `~/.claude/skills`, `~/.codex/skills`, `~/.agents/skills`, and the locally observed ZCode paths; `relay-xyz` already uses non-overwriting symlink installer patterns for Claude/Codex-style roots (`skills/relay-xyz/SKILL.md:66-80`, `skills/relay-xyz/SKILL.md:95-112`).
- Keep "ready PR" as the terminal claim for this skill. Any merge, issue closeout, clone pruning, or post-merge reconciliation should route to `merge-cleanup` or existing governance instead of being reimplemented here.

## Producer receipt

The reviewer approved the plan textually, but the driver exited 8 because its verdict spelling did not satisfy the machine validator. This is not a successful driver run. The author independently accepted the no-blocker review and proceeded with the approved plan; final QA must use the required PASS/FAIL marker and complete successfully.
