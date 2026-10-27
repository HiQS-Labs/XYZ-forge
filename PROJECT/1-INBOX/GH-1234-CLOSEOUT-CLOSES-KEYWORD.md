---
title: "Marathon lane PR body carries Closes #<issue>"
status: "Proposed (1-INBOX - not yet active)"
created: 2026-10-27
owner: noelsaw1
gh_issue: 1234
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1234
doc_type: project
phases: 1
---

# GH-1234: marathon lane PR body carries `Closes #<issue>`

## Problem (observed)

GH-1175 Phase 0, PR #1225 (2026-10-26). Marathon's lane PR for issue #416 had the body "Automated
marathon closeout for phase `gh-416-doc-trues-up-batch` (GH-561)." and `closingIssuesReferences: []`.
wave_reconcile treats a PR with no closing keyword as mention-only (GH-202), so merging it would have
left #416 OPEN and its doc in 2-WORKING. Fixed by hand by appending `Closes #416` before the merge.

Traced at base `5cab70c8`:

- `utils/py/marathon_drive.py:2667` `open_lane_pr()` calls `relay-automation/marathon-closeout.sh`
  with `--notes "Automated marathon closeout for phase \`<phase>\` (GH-561)."`. That is the only
  automated caller.
- The issue number is already derived in the same scope: `lane_issue_number()` (`:1579`), and in the
  receipt's `issue` field via `_derive_issue_number` (`:128`).
- A multi-phase issue must not close on its first lane PR. The repo's existing declaration is capture
  frontmatter `umbrella|multiphase|multi_phase: true`, which `utils/py/wave_reconcile.py` checks
  inline twice (`:2383-2387`, `:2466-2470`).

## Requirements

1. A lane PR for a single-phase issue carries `Closes #<issue>` in its body.
2. A lane whose issue doc declares umbrella/multiphase carries `Refs #<issue>` (no closing keyword).
3. A lane with no derivable issue keeps today's body.
4. No change to `marathon-closeout.sh` or its other options (manual use unchanged).

## Preflight bet check

- **Outcome sought:** merging a Jog/Marathon lane PR closes its issue, so reconcile moves the doc and
  ledger row without a hand edit.
- **Smallest viable bet:** append one line to the `--notes` value in `open_lane_pr()`. Decide which
  line with the existing frontmatter declaration, read through one small shared predicate in
  wave_reconcile so the three call sites cannot drift.
- **Alternatives rejected:**
  - Teach `marathon-closeout.sh` an `--issue` flag. That is a second place to carry the rule; the
    driver already has everything it needs.
  - Always write `Closes`. That closes multi-phase umbrellas early.
- **Rollback:** revert one commit. The bodies of PRs already opened are unaffected.

## Plan

1. `utils/py/wave_reconcile.py`: add `doc_declares_multiphase(fm)`, which returns True when `umbrella`,
   `multiphase` or `multi_phase` is `true|1|yes`. Replace the two inline expressions (`:2383`, `:2466`)
   with it. No behaviour change.
2. `utils/py/marathon_drive.py` `open_lane_pr()`:
   - `issue = lane_issue_number()`.
   - If an issue was derived, import `find_active_doc_for_issue, parse_doc_frontmatter,
     doc_declares_multiphase` from wave_reconcile inside `try`, following the existing lazy-import
     idiom (`:2631-2635`), and check the doc in the lane's `repo`.
   - Append `\n\nCloses #<issue>`, or `\n\nRefs #<issue> (multi-phase; this lane does not close it)`.
   - If the import or lookup fails, fall back to `Refs`. A failure must never close an issue, and
     must never fail the phase: `open_lane_pr` is best-effort by design.

## Non-goals

- Closing keywords for lanes that bundle several issues (the first derived issue only, which is the
  same rule as `lane_issue_number`).
- Changing marathon-closeout.sh, wave_reconcile semantics, or Jog landing.
- New tests (AGENTS.md *No new tests*, GH-831).

## Verification

- Existing suites:
  - `test/gh232-wave-reconcile-multiphase.sh` and `test/gh202-wave-reconcile-issue-state.sh`, which
    pin the refactored predicate;
  - the suites covering the GH-561 lane PR in `marathon_drive`, found by grep on `open_lane_pr` / GH-561;
  - the routed final gate.
- Manual smoke under `TESTS-RESULTS/2026-10-27+GH-1234/`, run in a disposable clone, with a stub `gh`
  on PATH that records `gh pr create` argv:
  - **Main:** a single-phase issue doc gets a body ending `Closes #N`. **Red control:** at base it
    does not.
  - **Adjacent:** a doc with `multiphase: true` gets `Refs #N`, and no derivable issue leaves the body
    unchanged.

## Rating (2026-10-27)

`rated 65/55/50/85`.

- **sev 55:** a merged lane silently leaves its issue open and its doc and ledger row stale. It is
  recoverable by hand, and nothing is lost.
- **pri 65:** every Jog/Marathon lane hits it, and it blocks unattended landing (#1175). One observed
  incident; trend unknown.
- **appeal 50:** neutral.
- **effort 85:** a few lines plus a no-op refactor.

## Status

| What was just completed | What's next |
|---|---|
| Capture + plan written from recon at 5cab70c8 | Codex plan QA |
