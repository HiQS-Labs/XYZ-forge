---
title: GH-796 — Open PR integration review and merge-remediation plan
status: Plan approved — awaiting remediation
created: 2026-09-24
updated: 2026-09-24
owner: noel
goal: Land reviewed compatible PRs in a verified sequence while preserving deferred work and the incomplete GH-777 arc.
gh_issue: 796
branch: feat/gh796-integration-review
effort: 3
complexity: 3
risk: 4
phases: 3
---

## Status

| What was just completed | What's next |
|---|---|
| Four pinned PRs reviewed; Agy plan QA PASS with successful harness attestation | Remediate and requalify candidates, then run the reviewed merge-cleanup sequence |

## Table of contents

- [Scope and decision](#scope-and-decision)
- [Phase 1 — Reviewed findings](#phase-1--reviewed-findings)
- [Phase 2 — Ordered remediation and landing](#phase-2--ordered-remediation-and-landing)
- [Phase 3 — Reconciliation and cleanup](#phase-3--reconciliation-and-cleanup)
- [Risk, alternatives and rollback](#risk-alternatives-and-rollback)
- [Evidence and QA](#evidence-and-qa)

## Scope and decision

Tracking issue: https://github.com/HiQS-Labs/XYZ-forge/issues/796.
Parent adoption arc: #777 (open). Related mechanical wave QA: #784. Existing #791 covers the previous merged batch; #789/#786 cover enhancements to merge-cleanup, not this integration review.

Requested now: source review, conflict/regression flags, an optimal merge/remediation plan in GitHub, and Agy plan QA through relay-xyz. No production fixes, live merges, issue closure, skill deployment, experiment scoring or valued-clone teardown in this planning stage. Later execution uses merge-cleanup, after the conditions below are met. Do not manufacture an all-clear: bounded review and focused diagnostic probes are not a final combined gate.

**Proposed order: #794 → #795 → remediated #765. Hold #759 separately.** Any documentation PR publishing this plan is not part of the runtime sequence; keep it excluded until its ledger intake can be reconciled after the runtime landings. A new or moved head invalidates that PR's snapshot and requires delta review before admission.

| PR | Pinned head | Base | Scope | Current result |
|---|---|---|---|---|
| #794 | `1712a5790ba7c137cd3c2a29f3d490adc5acb3b8` | development | Four previous-batch regressions | First candidate; prior 419/419 local gate at runtime-identical revision, latest hosted smoke success; no new source blocker found |
| #795 | `bdf23e77b55662e34317908bb7c190f66ec63e3a` | development | Spaced Python executable paths, shared test launcher, ratchet | Follows #794; author's full run 417/420 reports three baseline failures fixed by #794; not a combined pass |
| #765 | `be28ff1fcd6db7ec149992da0f8060f36cc4e6b7` | development | start-marathon, PARKED, standup, wave QA gate | Blocked on code/contract remediation, doc migration and conflict resolution |
| #759 | `4df190c6eca54dff33189b07a493e3079753f8d9` | development | Phase 0 next-action research probe | Draft; hold outside batch; human answers and frozen evaluation outstanding |

Development snapshot: `337813e042e50bf4c09a6c7daa0247355bba5b58`. Full clone and branch were cut from the canonical GitHub remote. Review map: `recon-gh796-integration.md` beside this document.

## Phase 1 — Reviewed findings

### Confirmed textual conflicts

`git merge-tree --write-tree` at the pinned heads, with nonempty captured results, reports:

| Combination | Conflicted paths |
|---|---|
| development + #794 | none |
| development + #795 | none |
| #794 + #795 | `releases.db`, `releases.sql` |
| development or #794 or #795 + #765 | `CHANGELOG.md`, `releases.db`, `releases.sql` |
| development or #794 or #795 + #759 | `LEADERBOARD.md`, `releases.db`, `releases.sql` |
| #765 + #759 | `CHANGELOG.md`, `releases.db`, `releases.sql` |

These are pairwise Git results, not a remediated cumulative integration result. There are no textual source-code conflicts in this bounded matrix; the semantic failures below still prevent #765 landing.

Read-only database comparison against each PR's own merge base finds distinct added roadmap issues: #794 adds 791/793; #795 adds 788; #765 adds 762/763/764; #759 adds 757. Stable roadmap/event/receipt keys do not overlap, but all writers advance `settings.generation`. Development schema is 9/generation 1119; #765 and #759 carry schema 8. A binary or SQL "take theirs" can rewind schema/state despite disjoint task rows. Preserve current schema and ledger history through the existing resolver/replay writer; fresh three-way classification at each actual landing remains mandatory. #764 already closed upstream must not return as active merely because an old branch added its row.

### PR #765 — remediation required

**F1 / P1 — Per-wave execution deadlock.** `start-marathon/SKILL.md:267–269,292–296` requires pre-PR QA per wave, but `utils/pdda/check_marathon_qa.py:102,289–298` makes `--pre-pr` require all waves complete. The existing #777 plan line 72 says Wave 1 must merge before Wave 2 begins. Diagnostic: complete Wave 1 + pending Wave 2 returns 1 with three errors; changing only Wave 2 to complete returns 0. Root cause: whole-plan completion reused at a per-wave boundary. Fix the existing checker/skill contract to select the wave being admitted (for example `--wave N`), while retaining all-wave final closeout. No parallel gate implementation. Invalid/missing selected wave must fail, unfinished future waves must remain honestly pending.

**F2 / P1 — New aggregate gate rejects current project docs.** `utils/pdda/pdda.sh:1568` adds the checker to the aggregate; Forge is in full mode. Pinned checker against current development documents returns **1, six errors/five warnings**. Six errors are missing proof/Codex/peer entries in #777's two waves. Migrate the active plan's checklist structure in the same change, without checking unfinished work or inventing receipts. Repoint the old `skills/2-daily/marathon-triage/SKILL.md` write-set references at #777 plan lines 28/40 to `start-marathon`. Review affected consumer distribution under `PROJECT/PDDA-SYNC-POLICY.md`; the recursive manifest distributes the new checker.

**F3 / P1 — Inventory contract collision.** New `utils/pdda/check_marathon_qa.py` is absent from #777's frozen script inventory. `check_inventory_ratchet.py:55–66,122–143` scans that directory and rejects additions; `--update-baseline` explicitly refuses growth. Deliberately review this checker as an addition to the existing PDDA subsystem and approve only its exact baseline path/count, preserving #794's GitHub-label connector baseline repair. Do not disable the ratchet, silently rebaseline the whole tree, or invoke shrink-only update as if it approved growth. Verify another unapproved production script still fails.

**F4 / P2 — Consumer root mismatch.** Skill lines 292–294 call `$HARNESS` tools without target-root binding. Checker `:25–29` defaults to the harness checkout; `pdda-lib.sh:6` does likewise. Consumer receipts are therefore resolved in Forge. Pass the canonical consumer root via checker `--root`, and `PDDA_REPO_ROOT` to the dispatcher. Prove with distinct harness/consumer roots that only the consumer receipt satisfies the check and no consumer operation writes the harness activity log.

**F5 / P2 — Ordinary Markdown receipt links fail.** Checker `:201` includes trailing `)` in a receipt path parsed from `[receipt](relay-system/qa.md)`. Existing backticked receipt passes; Markdown link fails. Parse supported link/path forms with the smallest existing-compatible change; test both existing and missing receipts in both forms. No general Markdown framework needed.

**F6 / proof limitation — Empty receipts pass.** With all boxes checked and the receipt replaced by an empty file, the current checker returns 0. It only checks `isfile` at `:278`. This is a witnessed weakness, not evidence anyone falsified a real receipt. Before calling this mechanical proof of QA, reject empty/non-approved receipts using the existing relay verdict/terminal contract where suitable; keep independent review and exact-head verification separate. Tests: missing, empty, changes-requested and approved receipt controls. No new signature/attestation service. If #784 deliberately limits itself to existence, narrow its guarantee explicitly and retain this gap as an open acceptance item rather than calling it verified QA.

### PRs #794 and #795

Bounded source review found no additional blocker. #795's `test/lib/pystub.py:22–24` preserves the exact interpreter and argv for supported paths; it intentionally refuses quote/backslash/newline/CR. Its production callers already import shlex. The new test helper is under `test/`, outside the production script inventory, and the three production quote edits introduce no new scripts or SQLite connects. #794 cleanup changes and canonical test import are unaffected. Must still run their combined tree: disjoint code and individual green evidence do not prove integration.

Spaced TMPDIR fuzz paths remain an explicitly documented pre-existing non-goal; sandbox deletion risk is already #792. Parallel idle-control flake is #793. Do not expand this batch to fix these without separate tasking.

### PR #759 — hold and return findings to its existing work

The Phase 0 script fetches dataset-server `/rows` without binding fetched data to the revision it writes as `m.REVISION` (`phase0-development-probe.py:7–9,41`); it does not verify the imported serializer against the advertised digest. This is a reproducibility gap, not proof historical results are wrong. The committed JSON matches its documented hash. Before this draft becomes eligible, #757 must bind acquisition to an immutable revision or verify/archive exact source bytes, verify the serializer, and retain committed provenance. It also needs an explicit temp/output path (script line 42 writes CWD; summary says run at repo root), removal of routine generated LEADERBOARD churn, and the outstanding human pilot/frozen contracts/independent evaluation. No fresh ranking or human-answer inference here. These observations belong to existing #757/#759, not a duplicate experiment implementation.

Phase 1 acceptance:
- [x] Pin all four heads and development; distinguish Git conflicts from semantic risks.
- [x] Review code and ledger seams; record explicit source/coverage limitations.
- [x] Retain diagnostic failures and passing comparison controls.
- [x] Agy approves the resulting plan through a successful relay turn.

## Phase 2 — Ordered remediation and landing

One ordered execution list; this is a future execution contract, not a claim these steps ran:

1. Refresh open PRs, exact heads, base, draft/hold state, checks and current development. Freeze this batch to #794/#795/#765; explicitly exclude #759 and every other discovered PR, including the plan-publication PR and any future #789/#786 PR. Preserve other agents' active clones. -> Any changed head gets delta review and updated evidence; wrong base, unreadable state or new unreviewed work stops admission.
2. Bootstrap landing with the **reviewed #794 implementation** of merge-cleanup, invoked from its retained full clone with the operator's maintained checkout as explicit `--primary`. Run the deployed skill's locator/readiness and the pinned script's dry run first, excluding all PRs except #794. Do not run an older deployed script that still contains the polling/SHA defects being repaired. -> Confirm exact executing file/revision, primary landing-ready, fresh ledger check/reconcile-state dry-run, and current PR readiness before any remote merge. If the bootstrap cannot safely run, stop for a reviewed narrow bootstrap decision; do not improvise force merges.
3. Land #794 through merge-cleanup once admitted. Wait for its actual MERGED state and merge SHA, then exact-SHA hosted reconciliation or guarded local fallback per skill. Fast-forward primary, verify ledger/doc state and clean equality to origin before continuing. -> Existing six-poll, exact-hosted-SHA, fresh-clone import and inventory controls remain green; no unrelated workflow can attest this merge. A failure stops the batch.
4. Integrate current reconciled development into #795 using an isolated full clone. Its overlap with #794 is ledger-only: classify/replay with the existing B1/resolver and canonical `releases_app.py` writer, preserving schema9, all task rows, ratings and audit history. Remove routine generated view churn from its task diff where applicable. Recheck source diff and publish without force only if the remote head still matches the observed head. -> `releases check`, `roadmap reconcile-state --dry-run`, no unresolved paths; spaced-interpreter launcher/fuzz suites, GH-788 ratchet including red controls, GH-777 inventory, GH-436 cleanup and GH-674 lookup pass on the combined code.
5. Run the final approved #795 candidate's full macOS gate once in a separate disposable full clone, checking HEAD/origin/core.bare/local identity before and after. Retain logs/provenance; confirm hosted run for that exact pushed head. -> Full gate green; 417/420 and GitHub CLEAN alone do not qualify. Land #795 and complete the same reconciliation sequence before #765.
6. Remediate F1–F6 in #765's existing checker, skill and tests; migrate #777's active checklist and renamed paths. Resolve CHANGELOG semantically, preserving every unique dated entry and unchanged history; resolve ledger through current writer/schema, never binary replacement or SQL union. Reconcile stale #764 records against live issue state. Update #765 body and acceptance mapping to include #784; do not close #777. -> Focused GH-784, hook routing, installer links, standup153-case suite, inventory and full-mode PDDA aggregate pass; witnessed negative controls enforce selected-wave readiness, final closeout, both roots and receipt forms/content. Keep unfinished wave acceptance unchecked.
7. Independently QA the repaired #765 diff and exact test evidence, review PDDA distribution per policy, then run its final full macOS gate once in a separate disposable clone. -> No stale review reuse after changes; no new source conflict, meaningful hosted run appears for final head, explicit head-bound admission. Only then land #765 and reconcile before any cleanup.
8. Leave #759 draft and explicitly excluded throughout. Record its provenance/eligibility findings under #757/#759 when that task resumes; don't merge it just to empty the queue. Reconcile the plan-publication PR last via canonical ledger writer if one exists. -> No evaluation artifacts are scored/published by this batch, no human answers inferred, and no intake row disappears.

Use debug-mantra for any failed check: reproduce, trace, falsify, retain breadcrumbs. Failure under parallel load requires pre/post identity proof and matched-base controls, not retry-until-green. Focused tests during remediation; full gate only after final approved implementation. Existing merge-cleanup repair cap is two repairs per PR at the pinned primary coordinator; do not reset it by recloning. Plan QA cap is three Agy rounds; exhausted or failed harness runs remain blocked, never self-approved.

Phase 2 acceptance:
- [ ] All admitted PRs pass their final current-base gates; no bypass represents readiness.
- [ ] Every remediation has failing and passing controls retained with provenance.
- [ ] Merge SHA, reconciliation and primary equality verified after each landing.
- [ ] #759 and unrelated PRs remain outside the landing set.

## Phase 3 — Reconciliation and cleanup

After the last admitted landing, compare the final tree to the pinned/reviewed intended changes, inspect hosted reconciliation for every merge, run ledger consistency and issue-doc sync, and reconcile #777's delivery map without closing its remaining work. #796 remains open until this execution is complete; publishing an approved plan does not close it.

Then use merge-cleanup's fresh per-clone inspection for only completed batch work. Preserve dirty files, unique refs, stashes, dependent worktrees, active sessions and failed inspection state. Move proven-safe full clones to Trash using the skill; remove linked worktrees only through Git. The review clone, #759 evaluation clone and any active #789/#786 work remain until their own state proves retirement safe. No broad recursive deletion, no discarded evidence, no skill deployment from temporary clones.

Phase 3 acceptance:
- [ ] Primary clean at origin/development; every landing reconciled and no lost ledger row.
- [ ] #777 truthful and open for remaining commitments; #784 status reflects actual delivered QA behavior.
- [ ] Only verified-complete clones retired; preserved clones and reasons reported.

## Risk, alternatives and rollback

Current planning writes are **Easy** to undo: issue/doc edits and isolated task ledger intake. Eventual merging and governance enforcement are **Costly**: they affect local gates, consumer PDDA, planning workflows and shared ledger history. Shield: pinned heads, per-wave selection, same-change honest doc migration, current-base disposable-clone probes, existing bounded B1 writer and exact-head gates. Tripwires: schema/generation rewind, missing row/history, whole-plan deadlock, false-green receipt, wrong root, failed gate, stale head or incomplete reconciliation. Stop before the next remote merge.

Rollback after a landing is an ordinary reviewed revert on a new branch plus ledger reconciliation through canonical writers; never reset development, overwrite newer DB state, or force-push. Retain the pre-landing SHAs and receipts. Cleanup happens last because it reduces recovery options.

Alternatives: #795 first retains known cleanup/inventory failures; #765 first adds contract breaks and more collisions; batching all PRs into one synthetic branch masks attribution and unnecessarily includes draft research. Chosen order repairs the landing path first, then test hygiene, then broader governance. Open reviewer question: can the existing checker support narrow wave admission while preserving final completeness without introducing a second gate? Preferred answer is one selector in the existing checker, not a parallel subsystem.

No new executor, merge framework, general parser, fuzz campaign or attestation service is in scope. Test footprint is limited to the changed gates/callers and existing final repository gate.

## Evidence and QA

Evidence directory: `TESTS-RESULTS/2026-09-24+GH-796/`. `merge-tree.json` captures ten pairwise merge probes. PR snapshots preserve reported author evidence and current check state; they are not newly executed full tests. Diagnostic checker runs record six current-doc errors, the sequential-wave failure/passing comparison, the empty-receipt false green and Markdown-link false failure. Source review found the consumer-root mismatch; dedicated cross-root fixture is required during remediation. No full gate or remediated cumulative merge has run in this planning stage.

Graph Verify attempted: XYZ-forge generation `2026-09-01T15:54:30Z`, ready but stale. New/moved paths were missing/not tracked and pdda.sh metadata changed; direct pinned-source reads supersede graph leads. Three bounded read-only lanes covered governance, cleanup/test hygiene, and evaluation/ledger; no claim of exhaustive whole-repo correctness.

2026-09-24 RELEASES rating: **80/75/50/65** (priority/severity/neutral appeal/cheapness), read back from the canonical writer. Gate-blocking and false-green readiness consequences justify priority/severity; no observed data loss is claimed. Bounded review/remediation is moderately cheap. Recurrence: recent Sep10–24 examples include #791 merge collisions, #788/#651 repeated interpreter-path failures, and #784 missing independent-QA enforcement; prior Aug27–Sep9 window was not exhaustively audited, so trend is unknown. No user numeric override. Existing PR issue scores are not changed by this integration coordinator.

Agy reviewer must grade this plan and its evidence, not approve unremediated PRs. Reviewer writes only the relay thread. Every finding gets a disposition; nonzero driver exit/missing verdict/containment failure is not approval. Final planned handoff includes exact executing merge-cleanup revision, admitted/excluded PR list, remediation status and outstanding gates.

## Plan QA outcome

Agy returned PASS in both review rounds. Round1 driver exited4 with the known GH-763 close-mismatch because the reviewer released to an agent named done; that attempt is not counted as successful QA. Bounded round2 retained the token for the existing shim, returned exit0 and recorded attested Approved against reviewed head `095b6c9cd113`. No production change or manual attestation bypass was used. The substantive plan was unchanged between rounds; only protocol recovery and final status/evidence were added. Relay: `relay-system/2026-09-24/gh796-plan-qa.md`. Driver log and portable attestation record are retained with the evidence. This approves the plan, not the still-unremediated PRs. Existing GH-763 remains separate; no runtime repair was attempted here.
