---
title: merge-cleanup B1 CHANGELOG repair reorders existing same-date sections
status: Active (2-WORKING)
created: 2026-10-30
owner: noelsaw1
gh_issue: 1269
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1269
doc_type: bugfix
complexity: 2
risk: 3
effort: 2
phases: 1
reported_from: LTVera-Pandas
harness_commit: e305cbf3
non_goals:
  - Changing the GH-789 two-repair budget or the history-preservation refusal itself
  - Resolving genuinely divergent same-heading additions (those still hand off)
related:
  - GH-789 (bounded repairs and the additive changelog boundary)
goal: >
  A B1 additive CHANGELOG resolution prepends the PR's new dated sections and keeps the
  integration branch's existing history byte-for-byte, including the order of same-date
  sections, so a repair recorded `resolved` passes B1's own history check on the next attempt.
---

# GH-1269 — merge-cleanup B1 CHANGELOG repair reorders existing same-date sections

## Status

| What was just completed | What's next |
|---|---|
| Promoted; root cause reproduced in the intake repo (`TESTS-RESULTS/2026-10-30+GH-1269/red-control-prefix.log`); plan written | Codex plan QA, then the one-function fix |

## Symptom

The B1 additive CHANGELOG resolution reorders the integration branch's existing same-date
sections and records the repair `resolved`. The next B1 attempt refuses that output ("changelog
preamble or existing history changed") and hands off, which uses up the PR's two-repair budget.

## Environment
- **Observed from:** `LTVera-Pandas` (vendored `.xyz/` at `017b1425`; `merge_cleanup.py` from the deployed Skills Army copy)
- **Harness commit:** `e305cbf3` (intake repo at report time)
- **Worker/CLI:** merge-cleanup (`merge_cleanup.py --execute`, B1 rung)
- **Runtime:** Python — matches the `runtime:python` issue label
- **Sandbox:** off

## Reproduction
1. LTVera PR #874 (one new 2026-10-30 section) conflicts with `development` `3c936bea`, whose `CHANGELOG.md` holds six 2026-10-29 sections added by three parallel PRs.
2. `merge_cleanup.py --primary <landing clone> --prs 870,874 --execute`: B1 attempt 1 on head `f57f2540` resolves and pushes merge commit `497ca1e8`, recorded `resolved`.
3. On the next run, B1 attempt 2 on head `497ca1e8` hands off.

**Expected:** `497ca1e8`'s CHANGELOG = the GH-818 section + development's history unchanged.
**Observed:** the six 2026-10-29 sections are reordered (development order 867-QA, 867, 866-typing, 866, 866-resumed, 776 → output order 776, 866, 867, 866-typing, 866-resumed, 867-QA); bodies intact. Attempt 2: `outcome: handoff`, `reason: CHANGELOG handoff: changelog preamble or existing history changed`.
**Frequency:** once so far; expected to be deterministic for multi-section same-date history.

```text
attempts[0]: rung=B1 head=f57f2540 outcome=resolved commit=497ca1e8
attempts[1]: rung=B1 head=497ca1e8 outcome=handoff reason="CHANGELOG handoff: changelog preamble or existing history changed"
conflict_files: CHANGELOG.md, RELEASES-PREVIEW.html, releases.db, releases.sql
```

## Impact
LTVera PR #874 needs an operator-approved third, CHANGELOG-only repair. Any batch landing with
several same-date CHANGELOG sections from parallel PRs is exposed. No data loss: bodies are kept
and the handoff stopped the reordered history from landing.

## Phase 0 — Diagnose & scope
> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [x] Reproduce it in the intake repo (not just in the reporting repo)
- [x] Locate the responsible script/path — name the concrete write-set (likely the additive-section merge under `skills/2-daily/merge-cleanup/scripts/`)
- [x] Decide fix vs. guard-and-document; reuse an existing code path before adding one (`/ponytail`)
- [x] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [x] The repro is confirmed from the report, not assumed
- [x] An existing suite, or a recorded manual check, covers the failure path before the fix lands (no new test suites: `AGENTS.md` *No new tests*, GH-831)
- [x] The fix composes with the existing harness rather than adding a parallel path

## Rating (2026-10-30)

`rated 65/60/50/85`. Severity 60: a resolved B1 repair produces history its own next attempt refuses,
burning the GH-789 two-repair budget and forcing an operator-approved manual repair; recoverable, no
data loss (the refusal stops the reordered history from landing). Priority 65: severity-led;
deterministic whenever parallel PRs add several same-date sections, which batch landings do routinely.
Appeal 50 (neutral, no operator preference). Effort 85: one function's assembly line plus a manual
smoke. Recurrence: 1 incident (LTVera #874, 2026-10-30) in the last 14 days, 0 in the prior 14;
no other open or closed issue reports it (search "changelog B1"). Trend: unknown beyond one incident.

## Plan (GH-1269)

### Recon (base: origin/development, see Status)

- Landing merge runs inside the PR clone: `merge_cleanup.py:553` `git merge --no-ff --no-commit origin/<integration>`.
  So in B1, `HEAD` = PR head (ours) and `MERGE_HEAD` = integration tip (theirs).
- `ledger_merge.py::read_changelog_union` reads `CHANGELOG.md` at (merge-base, HEAD, MERGE_HEAD) and calls
  `union_changelog(base, ours, theirs)`; its only caller is `resolve_ledger_conflict` (B1).
- `union_changelog` validates that both sides are `preamble + additions + history`, collects every
  addition block from **both** sides into one dict, and emits
  `preamble + sorted(blocks, reverse=True) + history`. Sorting by heading text reorders the integration
  side's own additions whenever they are not already in descending heading order (LTVera #874: six
  2026-10-29 sections 867-QA, 867, 866-typing, 866, 866-resumed, 776 → 776, 866, 867, ...).
- On the next attempt the merge base is the integration tip, so its whole post-preamble text becomes
  `history`; the reordered output fails `text.endswith(history)` → "changelog preamble or existing
  history changed" → handoff, second repair slot burned.
- Coverage: no registered suite exercises `union_changelog`; GH-789's unregistered
  `TESTS-RESULTS/2026-10-05+GH-789/manual_matrix.py` (ChangelogUnitCases, ChangelogMergeCases) does.

### Fix (one function, one file)

`skills/2-daily/merge-cleanup/scripts/ledger_merge.py::union_changelog`: keep every existing validation;
change only the assembly. Output = `preamble + <PR-side (ours) addition blocks, in their own order,
skipping any block byte-identical to an integration-side addition> + theirs[len(preamble):]`.
The integration side's text after the preamble is copied verbatim, so the next B1 attempt's history
check passes by construction. Docstring names the ours=PR / theirs=integration contract.

Non-goals: no change to the two-repair budget, the refusal rules, fenced/HTML refusal, or
same-heading-different-body handoff; no date re-sorting of PR blocks against integration blocks
(the PR's sections are prepended, as the capture's goal states); no new suite (GH-831).

Risk / rollback: single-function revert. A PR whose new section is dated older than an integration
addition now lands above it (prepend) instead of being date-sorted; acceptable per goal, and B1 history
stays byte-for-byte.

### Verification

1. Smoke (GH-1088), `TESTS-RESULTS/2026-10-30+GH-1269/`: main path = LTVera-shaped fixture (base; theirs
   adds six same-date sections in non-sorted order; ours adds one newer section) → output equals
   `preamble + ours block + theirs-after-preamble`; red control on the pre-fix function shows the
   reorder. Adjacent path = feed the output back as the next attempt's (base=theirs, ours=output,
   theirs=theirs + nothing new / plus one more section) → no "history changed" refusal.
2. Re-run `TESTS-RESULTS/2026-10-05+GH-789/manual_matrix.py` in a disposable full clone (all cases green).
3. Full gate via the pre-push hook (merge-cleanup scripts route to the full tier), run once on the
   final commit.
