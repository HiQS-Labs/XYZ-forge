---
title: "GH-1059: Retire fully published task checkouts before merge"
gh_issue: 1059
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1059
status: "In progress (2-WORKING — planning)"
created: 2026-10-14
updated: 2026-10-14
owner: Codex
goal: "Automatically retire fully published task checkouts without losing active or local-only work"
doc_type: feature
effort: 2
complexity: 2
risk: 3
---

# GH-1059: Published task checkout retirement

## Status

| What was just completed | What's next |
|---|---|
| Final QA round2 Approved; existing cleanup180 tests, three start-task suites and41 manual cases retained | Fresh classified gate, ready PR and targeted retirement |

## Requirements and bet

The operator explicitly requests: after the branch and PR are fully pushed to origin, delete the worktree or full clone; modify the policy. Full clones go to recoverable Trash; linked worktrees use native Git removal. This does not authorize merging this repair PR or sweeping unrelated existing clones.

Smallest bet: add a targeted published-PR retirement mode to the existing merge-cleanup driver and reuse its inspection/removal paths. Default post-merge cleanup is unchanged. No daemon, scheduler, separate deletion utility, new test suite or new CI gate. The earlier GH-690/PR692 fix was a reminder-only policy and explicitly excluded automatic retirement, so this is the operator-authorized next behavior rather than a duplicate fix. #722 (inventory roots) and #748 (temporary landing clones) are separate scopes.

Reversibility: **Costly** because eligibility for shared cleanup changes. Containment is an explicit PR number plus exact task-owned checkout paths; no remote merges, primary writes, branch deletion or broad scan. Rollback: omit the new mode (existing landed-only behavior), revert this commit, and restore accidentally retired full clones from Trash. No schema or persisted-format migration. Linked worktrees are removable only when their content/refs are recoverable from the canonical remote.

## Rating rationale

2026-10-14: **65/35/50/65**, read back from the canonical roadmap writer. Priority reflects explicit operator demand and recurring housekeeping. Severity reflects retained disk folders and manual handoff, with no observed data loss; appeal50 is neutral; effort65 reflects reuse with meaningful safety verification. Historical GH-690 is a concrete reminder-only predecessor. Recent14-day vs preceding14-day distinct incident counts are unknown; no growth-rate claim is made. No operator numeric override was supplied.

## Recon Map

Base: `7bc727cbaecf8106250e18c2c7645e92abb1512d`. Mode: graph leads plus exact source; one bounded lane in the parent. Graph project `Users-noelsaw-Documents-GH-Repos-XYZ-forge`, generation2026-10-13T06:40:42Z; start-task metadata changed and was read in full. Other candidate paths have matching metadata/no recorded gap; this is not proof of completeness. Graph teardown callers include driver main and existing GH534 tests; heuristic edges to unrelated `get`/`move` symbols were rejected after source reads.

| Seam | Current source | Consequence |
|---|---|---|
| Authorization and end-of-task handoff | `skills/1-hourly/start-task/SKILL.md` opening, recital5, Step9 | Explicitly retains clone until requested merge-cleanup; no automatic disposal |
| Ref provenance | `skills/2-daily/merge-cleanup/scripts/scan_clones.py` `classify_local_refs` | All non-remote refs and detached HEAD must already be landed; an open PR currently cannot qualify |
| Session/local-state checks | same file `inspect_checkout` | Preserves dirt, stashes, dependent worktrees, live driver/tick/open handles and unknown queries |
| Freshness and removal | `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` `refresh_for_teardown`, `teardown_checkout` | Requires fresh inspection; only safe dispositions; full clones move to Trash, linked worktrees use Git |
| Driver routing | same file `main` | Existing cleanup also sequences merges and gates primary landing readiness, unsuitable for a narrowly published-only disposal |
| Safety policy | `WORKTREE-SAFETY.md` section7; `SOP.md` section4; merge-cleanup skill | Requires proof of no unique/dependent state; policy needs an explicit pre-merge exception backed by remote publication |

State: GitHub PR head/state and canonical origin branch are publication authority, not a local tracking ref or cached scan. Existing local Git/tick/lsof checks remain the only safety inspection path. Removal remains in `teardown_checkout`, not a new writer.

N+1 consumer: the new mode must pass proven published refs through `classify_local_refs` into `inspect_checkout` eligibility, then into the existing fresh-inspection/removal consumer. Changing only start-task prose would leave every open-PR ref rejected. Retry: rerunning revalidates current remote/PR/session state; unavailable API/fetch means preserve, never retry with force. Parameter role: the mode's PR/path arguments constrain eligible existing checkouts; they must not discover or create additional work. Rollout: a caller needs a driver revision exposing the new mode; an older maintained install must not trigger fallback manual deletion. No persisted contract changes.

Unknowns: current old-clone inventories and individual ownership have not been audited, and are outside this repair. Actual IDE skill refresh is also outside start-task publication. Fork-PR retirement is not required by the same-repository maintainer workflow; preserve cross-repository PRs instead of guessing.

## Ordered implementation and verification

1. Extend ref classification with an opt-in published PR number: bind live `gh pr view` to the candidate's canonical GitHub origin; require matching base, non-draft OPEN/MERGED same-repo PR and well-formed exact head; fetch the actual origin head branch and compare SHA. Admit only refs/HEAD reachable from that verified head, retaining existing landed proof for other refs -> a merely pushed arbitrary branch, fork, stale head, closed-unmerged PR or unavailable query remains preserved. Keep default signature behavior unchanged when no published PR is supplied.
2. Add `--retire-published-pr N --checkout PATH` (repeatable exact paths) to existing driver. Dispatch before broad merge/primary-write paths; reject mixed merge/scan/override modes, invalid/primary/ancestor paths and origins differing from the protected primary. Run outside candidate directories. Preview by default; `--execute` reuses fresh inspection and `teardown_checkout` for only supplied paths -> primary may have unrelated work because this mode neither lands into it nor writes governance. A refusal is reported with exact reason and nonzero status, no force/permission churn.
3. Update start-task authorization/recital/Step9 and merge-cleanup/SOP/section7 policy so successful PR publication invokes this targeted mode automatically from outside task paths. Retain required evidence in the PR first; release only the current workflow's completed claims/processes; preserve peer activity and remaining local-only evidence. Keep merging/deployment separate. Use a current driver, never an unsupported-flag fallback manual remover -> no unconditional retain-until-merge clause remains, and no blanket deletion is authorized.
4. Verify in a separate disposable full clone using existing GH436/GH534 coverage and targeted existing start-task suites, plus retained manual cases for the new policy. Cover published-but-unmerged success, branch/head/repo/draft failures, unavailable queries, extra local refs/detached work, dirt/stash/dependent worktrees/live session, protected primary, linked worktree and missing Trash. Witness a red control by removing the published-ref admission (success fails) and by removing a publication guard (unsafe case becomes eligible). No new suite/registry/gate. Preserve commands, inputs, outputs and provenance under `TESTS-RESULTS/2026-10-14+GH-1059/`.
5. Run final independent Codex QA on the committed change and evidence, adjudicate concrete findings within three rounds, then run the actual classified final gate once in the disposable full clone. Push through the normal hook, open one ready PR into development with `Closes #1059`, verify exact remote head/base/hosted checks, and exercise the task's own published-closeout policy where all safety predicates permit -> report retired path(s) or exact preservation reason. Do not merge or deploy this policy PR without authorization.

## Acceptance

- [x] Publication before merge is sufficient only through live canonical PR/head/ref proof.
- [x] Existing safety checks and normal merged-only behavior remain intact.
- [x] Only explicitly supplied task-owned paths retire; no primary writes, broad merges or new remover.
- [x] Start-task automatically invokes published closeout; local-only/active/unknown state is preserved.
- [x] Existing/manual verification, red controls, plan/final QA and appropriate final gate have retained receipts.

## Implementation notes

Plan QA attested Approved at `04b787c2`, reviewed head `3bb6231f`. Qualified schema009 accepted-start was recorded for owned row `rmi-01M4YBF6YKJ8MJP63B15FB6PZS` before implementation. The publication validator fetches the exact named origin head, not a cached tracking ref; failure preserves even a merged PR whose head branch is no longer fetchable (normal post-merge cleanup remains available). Native linked-worktree removal updates parent Git metadata, as clarified by plan QA; no primary landing/working-tree/governance writer runs. Existing merged-only invocation paths omit the new optional argument.

## Verification and ownership

This workflow owns only the sibling task clone slug `XYZ-forge-gh1059-published-clone-retirement-2026-10-14` and its `-gate` and `-verify` helpers, on branch `fix/XYZ-forge-gh1059-published-clone-retirement-2026-10-14`. The operator-designated primary and all other folders remain outside retirement scope.

Existing cleanup suite:180/180 at c391afec. Three existing start-task suites and39 manual cases passed at60c1ad18. The manual API/URL surface is a fixture, not live GitHub proof; Git fetch/ancestry, Trash moves and linked-worktree removal are real isolated operations. Final publication will supply the live same-origin PR evidence. Red controls: removing admission breaks successful open-PR classification; removing draft validation admits draft refs; a zero-PR routing witness reached the broad path at c391 and is rejected after60c. Fresh inspection catches changed PR metadata and preserves. Initial probe authoring errors (empty fixture commit, nonempty fixture Trash) were corrected before the retained completed run; neither was a product failure. No new test file/suite/registry/gate was added.

### Post-approval input correction

Final round1 approved at8eb6f70c (reviewed e86e1371). Before publication, a nonmutating sentinel probe observed that `--primary ""` resolved to the caller's current directory and entered targeted retirement instead of rejecting missing explicit identity. No removal occurred. The published-mode argument check now requires an absolute primary path; ordinary modes are unchanged. The in-flight first full gate at8eb was intentionally interrupted and is not passing evidence. This concrete scope correction receives cumulative final review round2/3 and a fresh final gate; no speculative re-review or cap reset.

Final round2 attested Approved at26574f1c, reviewed e013552e. The remaining edits update only this progress/ownership record; runtime and policy match that reviewed head. Both task-owned helper suffixes are explicit scope: the interrupted `-gate` and fresh `-verify`. Required evidence is committed before their closeout.

Development reconciliation69666c47 landed while the final gate ran on669d136f. Supported disjoint ledger replay committed dbe1e3bc: keep this branch's higher-generation ledger and replay GH1043's completed doc/section/marker/text via writer verbs. No reviewed runtime/policy byte changed; the refreshed ledger checks clean (nine existing warnings). The subsequent publication push rechecks these governance-only changes.

Final publication gate at669d136f:409/409 pass in1574s, separate full clone identity intact; ordinary push published the branch. Retained log, telemetry and provenance are under publication/. This is parallel publication evidence, not main promotion qualification. Runtime/policy still match final QA e013552e; remaining ready-PR/own-clone closeout is performed against live GitHub state. Routine LEADERBOARD output from the ledger refresh is omitted from the task branch; hosted reconciliation owns views.


## Merge review correction — 2026-10-15 UTC

A clean synthetic linked worktree with ignored operator notes is admitted by the prior
ordinary inspection and its native Git remover deletes the notes. The first scoped guard
passed existing cleanup180 and manual45, but a further retained input demonstrated that
the same known loss remains in ordinary native cleanup. Complete the guard in the existing
shared linked-worktree inspection owner: preserve ignored files and failed enumeration
for both flows. Keep ordinary merged-only history admission and whole-clone Trash.
No CI test/case is added. Original final QA remains2/3; use only the remaining third round
after the integration refresh and fresh verification. No publication or merge is claimed
for this correction until its normal gate and exact-head checks complete.
