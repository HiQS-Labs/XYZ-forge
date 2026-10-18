# GH-1088 smoke receipt (documentation-only, self-applied)

The new step 7 rule, applied to this change: documentation-only work reads the changed instruction
once from its consumer's entry point.

## Main path: an agent following start-task in order

1. The recited summary, item 4 (`skills/1-hourly/start-task/SKILL.md:52`), now ends "then smoke-run
   the change on its main path and one adjacent path". The step is visible at recitation.
2. Step 7 (`:252-264`) gives the rule in this order: when (after suites and gates, before final QA),
   what (main path plus one adjacent real-world path), where to record it (`TESTS-RESULTS/` with
   provenance, no suite), isolation (a disposable clone for mutating runs), the docs-only variant,
   what a failure means (fix or record a blocker before QA), and the role boundary (never counts as
   the independent review, step 6).
3. Step 8 (`:267-268`) lists "the step 7 smoke receipt" in the evidence handed to final QA.
4. Step 6's rule "do not silently substitute a self-review or consult" (`:212-213`) is unchanged and
   does not conflict: the smoke runs the change; it does not review or approve it.

**Verdict:** pass. Each step names the next action, and nothing reads as optional except the
docs-only skip, which needs a stated reason.

## Adjacent path: the installed consumer copy

An agent invoking `/start-task` loads `~/.claude/skills/start-task`, which resolves to the
Skills Army deployed copy (`/Users/noelsaw/git-pulse-sync/Deployed Skills/start-task/SKILL.md`). Lines mentioning GH-1088 in that copy: 0. The copy is
also behind the repo on GH-1059.

**Verdict:** expected. The change takes effect for agents only after the post-merge Skills Army
refresh. This is recorded as the PR's hand-off step, not a defect in this change.

## Deterministic checks

- `bash test/gh609-sdlc-agent-gaps.sh`: 33 pass, 0 fail (`gh609.log`). The start-task contract
  text is intact.
- `bash utils/pdda/pdda.sh run`: no errors (`pdda-run.log`). The first run caught missing
  `updated`/`owner` frontmatter and a missing `## Status` table in the plan doc; both were fixed.
- `utils/ci-route.sh pull_request` on the changed paths gives `route=docs tier=1`, so no full gate
  is required.
