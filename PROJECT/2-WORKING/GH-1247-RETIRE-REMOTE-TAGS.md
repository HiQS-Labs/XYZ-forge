---
title: merge-cleanup treats a local tag that origin already holds as unpushed, so published task clones are never retired
status: Active
created: 2026-10-28
updated: 2026-11-07
owner: noelsaw1
gh_issue: 1247
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1247
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: false
reported_from: LTVera-Pandas
harness_commit: 93f41cb8
non_goals:
  - Changing how branches, detached HEAD, stashes or dirty files are judged.
  - Treating a local-only tag, or one whose object differs from origin's, as safe.
  - Refreshing the Skills Army deployed copy of merge-cleanup (a separate operator step).
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1193
  - https://github.com/HiQS-Labs/XYZ-forge/pull/1198
  - https://github.com/HiQS-Labs/XYZ-forge/issues/722
goal: >
  A start-task clone whose only non-integration refs are tags that origin holds at the same
  object id is retired by --retire-published-pr (and reads SAFE_REMOVE in the audit), while a
  local-only or diverged tag still preserves the checkout and a failed lookup still fails closed.
---

# GH-1247 — merge-cleanup treats origin-held tags as unpushed

> Original incident capture below; the shared plan and current Status table follow it.

## Symptom

`merge_cleanup.py --retire-published-pr` preserves a fully published task clone as `PRESERVE_UNPUSHED`
whenever the repository has a tag not reachable from the integration branch, even when `origin` holds that
exact tag at the same object id.

## Environment

- **Observed from:** `LTVera-Pandas` (vendored `.xyz/`; driver run from the XYZ-forge checkout)
- **Harness commit:** `93f41cb8` (includes the #1198 safe-root fix)
- **Worker/CLI:** n/a (`merge_cleanup.py`)
- **Runtime:** Python
- **Sandbox:** off

## Reproduction

1. Clone a repository that has tags off its integration branch (here `archive/merge-group-1-2026-10-09` and
   `archive/merge-group-2-2026-10-09`, both present on `origin`).
2. Publish a PR from that clone so the branch head equals the PR head and `origin`; leave it clean, no stashes.
3. `python3 skills/2-daily/merge-cleanup/scripts/merge_cleanup.py --primary <primary> --retire-published-pr <n> --checkout <clone>`

**Expected:** the tags are recognised as recoverable from `origin` and the clone is retired.
**Observed:** `PRESERVE_UNPUSHED`, naming both tags; the clone is skipped.
**Frequency:** every time, for any repo with tags off the integration branch.

```text
PRESERVE_UNPUSHED | Unlanded local refs:
refs/tags/archive/merge-group-1-2026-10-09 @ dc965a88c5: not reachable from origin/development; no merged PR has this head
refs/tags/archive/merge-group-2-2026-10-09 @ e87ed4fe37: not reachable from origin/development; no merged PR has this head
```

`git ls-remote --tags origin 'archive/*'` returns both tags at the identical object ids.

## Original cause hypothesis (confirmed by shared-plan reproduction)

`classify_local_refs` in `skills/2-daily/merge-cleanup/scripts/scan_clones.py` (around lines 540-555)
collects every ref except `refs/remotes/*` and `refs/stash`, so cloned tags count as local refs. Each must then
be an ancestor of `origin/<integration>`, inside the published PR head, or a merged PR's head. Nothing checks
whether `origin` holds the same ref.

## Impact

Every start-task clone of an affected repo is unretirable, so clones accumulate on disk. Not blocking:
the checkout is preserved and can be removed by hand.

## Phase 0 — Diagnose & scope

> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [ ] Reproduce it in the intake repo (not just in the reporting repo)
- [ ] Locate the responsible script/path — name the concrete write-set
- [ ] Decide fix vs. guard-and-document; reuse an existing code path before adding one (`/ponytail`)
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The repro is confirmed from the report, not assumed
- [ ] An existing suite, or a recorded manual check, covers the failure path before the fix lands (no new test suites: `AGENTS.md` *No new tests*, GH-831)
- [ ] The fix composes with the existing harness rather than adding a parallel path

## Merge evidence

- commit 0628da70e550 landed 2026-10-29 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Status

| What was just completed | What's next |
|---|---|
| Codex plan QA Approved; both fixes implemented | Disposable-clone verification and final QA |

## Shared plan — #1247, #1362, coordinating #1359

Base `3bf02f73ce0cb11a82f970357209980f808ccb3c`. Clone `XYZ-forge-gh1247-retire-remote-tags-2026-11-07`, branch `fix/XYZ-forge-gh1247-retire-remote-tags-2026-11-07`. One implementation PR, not yet created. This is the canonical shared plan; other captures point here.

| Issue | Scope / acceptance | Dependencies | Rating and rationale | State |
|---|---|---|---|---|
| [#1247](https://github.com/HiQS-Labs/XYZ-forge/issues/1247) | Exact origin tag-object equality permits classification; local-only/different/query-failure preserve | None | 75/60/50/80: recurring retention, recoverable operator burden, neutral appeal, narrow fix | Plan QA |
| [#1362](https://github.com/HiQS-Labs/XYZ-forge/issues/1362) | Deployed scanner resolves trusted configured tick, unknown claims preserve | Same scanner | 75/60/50/85: deployed closeout blocked, workaround exists, neutral appeal, small extension | Plan QA |
| [#1359](https://github.com/HiQS-Labs/XYZ-forge/issues/1359) | Research/coordination only, bounded transition map and remaining gaps | Findings from both fixes | 70/45/50/45: retain issue proposal, recurring burden, no loss observed, neutral appeal, bounded audit | Broader work remains open |

### Recon, solution-fit and blast radius

`scan_clones.py::inspect_checkout` consumes `classify_local_refs` and `inspect_tick_claims`; failed queries become PRESERVE_UNVERIFIED_QUERY, unknown claims become PRESERVE_UNVERIFIED_SESSION. `merge_cleanup.py::retire_published_checkouts` reuses inspection and fresh teardown. No removal code changes. The graph excludes these scripts, so direct source reads were necessary.

Base reproduction in separate full clone: origin-identical lightweight and annotated tags off development are unlanded. A deployed-path scanner with empty PATH resolves neither XYZ_HARNESS nor device config. A differing tag aimed at development is accepted by ancestry: tag object/name equality must precede ancestry. Existing gh436 suite includes gh534_phase_a_tests.py with provenance and claim coverage.

Outcome: remove false preservation while preserving unique work. Smallest viable bet: two function extensions, existing run_git and disposition propagation. The full relay locator discovers the caller's vendored harness, inappropriate for an auditor; reuse its explicit configuration contract instead, not its cwd discovery. No parallel resolver framework, dependency or new CLI.

Costly: a false safe verdict can permit downstream retirement. Source rollback is one commit; stop on any false-safe control before deployment. No user-checkout disposal during verification. Deployment remains a separate post-merge Skills Army step.

### Ordered implementation

1. For tags, query `git ls-remote --refs --tags origin` once and compare exact full ref names and unpeeled object IDs before ancestry. Missing/different tags remain unlanded, even if commit targets are reachable. Failed/malformed query uses existing failed_query. Branch/detached rules unchanged. -> identical lightweight/annotated pass; local-only/differing target or annotation preserve; failed query preserves.
2. Extend `_tick_binary` retaining explicit MERGE_CLEANUP_TICK_BIN and own-harness/PATH behavior. Add XYZ_HARNESS and the existing XDG_CONFIG_HOME/HOME xyz/harness config; configured root must identify canonical Forge origin and executable tick. Never discover from audited cwd or its vendored tree. -> deployed-path env/config resolution; absent/broken candidates and active claims preserve; override precedence stays deterministic.
3. Record #1359's real LTVera PR #960 completion→retirement invocation→two preservation causes from issue evidence. Map start-task, Express, Jog/Marathon, helper and T3 boundaries with owner, supported command/API, witness/refusal, failure disposition and next reconciliation. Unknown ownership stays UNKNOWN. No schedules, broad cleanup, #748 implementation or installed deployment.
4. Existing `test/gh436-merge-cleanup.sh` plus manual red/green probes in a disposable full clone. Main-path and adjacent retry/negative smoke exercises actual classifier and claims entry points. Record commands, logs, provenance under TESTS-RESULTS/2026-11-07+GH-1247. No new suites, registry entries, gate machinery or fuzzers.
5. Final independent QA, one final classified gate, ready PR to development; #1359 stays open. Retire only workflow-owned published clones if normal fresh checks permit.

### Acceptance and QA
- [x] Plan independent Codex QA approved before production edits (relay-system/2026-11-07/gh1247-plan.codex.md).
- [x] Both issues reproduced on base; fixed main path and adjacent/negative controls verified.
- [x] Local-only/different tags, query failures, unknown/active claims remain preserved.
- [ ] Existing suite, final independent QA and classified gate pass; receipts retained.

### Recurrence and rating evidence

2026-10-25–11-07 versus 2026-10-11–24: #1247 names Oct 28 PR #855 and Nov 7 PR #960 as two distinct incidents; #1362 is another failure on the same Nov 7 run, not a third tag incident. Previous-window trend unknown. No observed loss. Existing #1247 rating/ovr were null; other rows absent. Persist each score through PRS and read back before QA.

### Review questions

Compare requirements of all three issues against this plan. Are tag object identity, failure propagation and trusted tick lookup sufficient? Are any requirements missing? Are rollback and falsifiable controls adequate without extra machinery? Local developer cleanup tool, no speculative enterprise threat model. Reviewer writes only relay receipt and runs no tests in relay worktree.
