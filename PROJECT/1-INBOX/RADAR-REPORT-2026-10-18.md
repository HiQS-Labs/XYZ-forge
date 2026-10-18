---
title: "Radar report 2026-10-18 — flow distribution, recurring targets, release recalibration (run 6)"
status: active
created: 2026-10-18
updated: 2026-10-18
owner: radar
goal: "Run-6 read of the last 21 days on development: RGT mix, recurring/regressing defect classes, release alignment; reconcile the live board #293"
doc_type: report
---

# Radar report — 2026-10-18 (run 6)

Window: **2026-09-27 00:00 → 2026-10-18 00:00 PDT** ([start, end), start 00:00 / exclusive end 00:00).
Trunk: `origin/development`. **`<trunk-sha>` = `f9e5b243`** (boundary at window end, resolved via `git rev-list -1 origin/development --before=2026-10-18T00:00:00-07:00`; commit 2026-10-17T23:11:57-07:00 "Merge pull request #1132"; ancestry verified against trunk). **`<current-trunk-sha>` = `4fd5dca8`** (2026-10-18T08:02:42Z, observation time ~08:30 PDT).
Prior window: 2026-09-06 → 2026-09-27 (513 non-merge commits). Prior reports: runs 1–4 on GitHub (`RADAR-REPORT-2026-08-28/09-01/09-02/09-21.md`); **run 5's Sink A (`RADAR-REPORT-2026-09-26.md`) was never committed — 404 on GitHub, absent locally; its content survives only in board #293's body.**
Live board: #293. Run record: #1138. Tracking issue for the skill itself: GH-442.
SOP: `docs/CI-CHURN-RECOVERY-SOP.md` (landed; #857 closed 2026-09-28; no open `CI churn recovery:` issue — not in a recovery window).
**Commit state: committed locally on `development` 2026-10-18, NOT pushed** (operator instruction — active merge sequence on `development`; the local branch is 2 ahead / 587 behind origin). Land with the next push or run 7 cannot see this file.

**Clone-state fact:** the analysis clone's local `development` was **2 ahead / 587 behind** `origin/development` at run start (tip `f7e501f5`, 2026-10-16T23:57-07:00). Measuring the window on the local ref would have tallied **359 of 872** commits (−59%). All measurements below were re-pinned to the fetched trunk (`git fetch origin development`; remote-tracking ref was already current — the local *branch* is stale, the remote ref was not).

## Degradation applied this run

| Row | Cost to the verdict |
|---|---|
| Run-5 Sink A never committed | Run 5's figures (Run 83.1%/Grow 9.4%, umbrella states) come from board #293's body — a live copy, labelled as such. E8's "two consecutive runs" comparison rests on it. |
| Tally comparability across the Sep squash boundary | Run 5's warning carried: squash-style `(#N)` subjects and merge commits shifted shape; both windows here are post-shift, and the same method was used both sides, but cross-boundary trends remain soft. |
| E2 ready→merged unavailable | Only `createdAt`→`mergedAt` (median 0.22d) is measurable from the PR list; review-ready state was not fetched. |
| Umbrella comment counts are lifetime totals | `gh issue list --json comments` gives per-issue lifetime counts, not interval-filtered; they enter the score as `floor(total/5)` upper-bound flavour. Both re-scored umbrellas clear their thresholds without any comment contribution (#591 = 13 without comments; #853 = 22 without). |
| `#648/#591/#949/#784` have no Cluster signature | Legacy — reconstructed baselines only; they can never earn quiet credit until an operator adds a real signature (radar never edits an umbrella). |
| Signal 9 branch-filter blind spot (caught) | `gh run list --branch development` misses PR-close-triggered Wave-reconciliation runs (they report the PR head as branch). Three lane failures were invisible to the filter (#994's run 37723297290, #1125's 39085003007, #1128's 39085005180 — each verified individually). The lane's auto-filed monitor issues are the authoritative lane-failure record. |
| Milestone join impossible | DB `milestoneRef` values (Front-Door, Sundown, Plumbline, `milestones`) do not exist on GitHub (only Bulkhead/Ballast, both shipped). Orphan share 256/256 = 100% — **missing binding, sixth consecutive run**, not backlog drift. |
| Issue-fetch coverage | 705 issues fetched at `--limit 1000` (255 open / 450 closed); run-6 window reads are complete within this fetch; older pagination not independently verified. |

`gh`, `PROJECT/**`, and the releases ledger were available and healthy. The operational corpus is **back**: 107 files under `relay-system/2026-10-*/` and daily `TESTS-RESULTS/` (runs 2–3 had zero).

## Executive summary (SDLC process coach)

This is the greenest radar window in the repo's history, and it is the payoff for the stabilization run 4 and run 5 asked for. Of 290 hosted runs on `development` in the window, exactly **two failed — both Wave-reconciliation scheduled runs on Oct 2, both recovered same-day** — and the reconcile lane sits on a **52-consecutive-green streak** (7/40 at run 4). The two worst defect classes verifiably drained: 6 of 8 open #853 members closed in one campaign on Sep 27 (the #854 gate dispositions, PRs #810/#818/#863/#866/#867/#869), the headless turn-timeout wave-1 ledger finally emptied (5 of 6 issues closed Oct 11–13), and umbrella #853's churn score fell **65 → 28**. The *No new tests* freeze held under load: registry 414 → 409, zero new suite files in-window **and** post-window through today's tip. The deliberate CI-audit program delivered measured wins — `marathon-root-audit` 79.8s → 8.8s single-pass (#1123, merged in-window), bounded backfill fixtures (#1132), and the parallel qualifying-receipt lane landed the morning after the window closed (#1134). Delivery mechanics scaled to a new level: 83 PRs merged at a **5.3-hour median** created→merged.

But look at what all that health cost: **Run is 82.0% of non-harness commits and Grow collapsed to 3.4%** (4.0% adjusted) — the lowest of six runs, down from 9.4% at run 5, the sixth consecutive run with Transform at 0% declared (0 of 83 window PR bodies; all five `rgt:` strings in issues are classifier discussions, not declarations). This is a repo deep in a deliberate maintenance campaign — and it shows two cracks. First, the reconcile-lane class **outlived its umbrella**: #591 closed Oct 11, and the lane's own monitor filed "needs attention" twice in the window's final hours (#1125 *"Qualification failed; no receipt produced"*, #1128), on top of the Oct-2 transferred-issue incidents (#921/#926, root still open) and an Oct-8 hosted qualification red (#994) — a post-cutoff score of 18, which per the counting contract reads **class survived — recommend reopening**. Second, a new unclaimed cluster grew quietly in the merge lane: **merge-batch machinery acting on stale captured state** (#444, #944, #1072, #1073, #1075, #1084), touched by fixes across Sep 27 → Oct 17 from ≥4 PRs, with a same-day Jog bounceback (#1099 feat → #1116 fix). Meanwhile the ledger conflict magnet kept pulling (`releases.db` fix-touched **12 of 21 days**), 8 migration refs are now **61 days stale** against a 7-day threshold, two roadmap rows claim closed issues as In-progress (GH-591, GH-807), Front-Door is **22 days past target** as a draft, and Sundown passed its target yesterday with the exit criterion this board has tracked since run 1 still reading NOT WRITTEN.

**Recommended next step (proposal — you decide):** Per `docs/CI-CHURN-RECOVERY-SOP.md`, triggers **E6** (2 clean-trunk reds on Oct 8: #991 local full-gate red at clean `development@33a03acc` + hosted run 37723297290 qualification failure) and **E8** (Run share 83.1% run 5 → 82.0% run 6, ≥ 80% two consecutive radar runs) fired. That meets its declaration rule. I recommend declaring a CI churn recovery and starting its Day 0 checklist (§2.3). Nothing changes until you declare.
**Second:** reopen #591 (or fold its residue into the ledger's already-In-progress GH-591 "Reconciler provenance lifecycle" row) and fix the one open root — #926, transferred-issue catch-up exit 6, which caused the Oct 2 reds. Completion: 10 consecutive green lane runs *and* #926 closed by a commit naming transferred-issue handling.
**Third:** one durable fix for the merge-batch cluster — re-derive batch state (file lists, verdict, QA-pending) at read time instead of trusting the captured copy — verified through the **existing** `test/gh436-merge-cleanup.py` and `gh534_phase_b_tests.py` suites (no new suites, GH-831). Retires six open issues including three operator-deferred Mediums.

## Lens 1 — flow distribution

**Tally proven before bucketing.** Subjects written with `/usr/bin/git log --no-merges --since='2026-09-27T00:00:00-07:00' --until='2026-10-18T00:00:00-07:00' --pretty='%s' f9e5b243` → `wc -l` = **872**; `git rev-list --no-merges --count` (same bounds, same SHA) = **872**; bucket counts sum to 872. Prior window (pinned `85a60f2c`): 513 = 513 = 513.

### Mechanical read

| Bucket | Count | Share of RGT denominator | Prior window | Run 5 |
|---|---|---|---|---|
| **Harness** (prefix families `relay*` `marathon*` `plan:` `capture:` `triage:` `wip:` `reconcile*:` + reconcile/version-record chore+docs families) | 377 | *excluded* | 138 | 177 |
| **Run** (`fix` `chore` `docs` `refactor` `test` `ci` `hotfix` `cleanup`) | 406 | **82.0%** | 79.2% | 83.1% (adj 86.3%) |
| **Grow** (`feat`) | 17 | **3.4%** | 11.7% | 9.4% (adj 13.7%) |
| **Transform** (explicit `rgt:` only) | 0 | **0%** — adoption 0 of 83 window merged-PR bodies, 0 of 705 issue bodies (the only `rgt:` strings anywhere are classifier discussions: #26 #27 #294 #295 #1083) | 0% | 0% |
| **Unclassified** | 72 | 14.5% | 9.1% | 7.5% |

RGT denominator = **495**. PR-title view (83 window merges): feat 13 · fix 25 · docs 16 · chore 3 · other 26 (marathon/staging/integration squashes) — Grow ≈ 15.7% of PRs; commit-share and PR-share diverge because relay sub-commits inflate the denominator.

### Adjusted read

41 of the 72 Unclassified are machine families the harness table does not name — `jog-state:` ×8, `intake(` ×7, 24 QA-turn prose commits from the relay/batch machinery ("Retain/Seed/Freeze/Normalize/Record/Keep/Hold …", the GH-1121 batch-QA era), `scope-c(` ×2, `pdda(` ×1, `receipts(` ×2 — moved to **Harness**; `perf(GH-836)`, `pages:`, scope-as-type work commits moved to **Run**; "Forge is upstream again …" (#956) counted **Grow**.

**Adjusted: Harness 418 · Run 436 (96.0%) · Grow 18 (4.0%) · Unclassified 0 · denominator 454.**

**Measurement defect, source-fixable (grown since run 5):** the harness prefix table has drifted behind the repo's machine vocabulary — `jog-state:`, `scope-c(`, `pdda(`, `intake(`, `receipts(` leak into Unclassified mechanically. The run-5 commit-type registration item stands, now with more families to register.

### Unclassified subjects, verbatim (72)

```
perf(GH-836): bound backfill and interleave fixture data
Retain final target-tree attestation as transcript-only evidence
Name the unseeded target tree explicitly in final review setup
Freeze final unseeded target-tree QA4of4; preserve prior review limits
Normalize accepted review driver-log trailing blank line
Record accepted independent batch QA3of4 and evidence reuse
Keep frozen review diff as whitespace-clean text evidence
Record explicit four-attempt QA cap and repair reviewer protocol setup
intake(GH-1112, GH-1114): CI quick wins capture doc, parked + rated, promoted to 2-WORKING
Normalize remote progress whitespace in publication receipt
Retain full publication proof and current-base draft hold (GH-1121)
Normalize retained driver-log trailing whitespace
Hold batch at QA cap; retain both rejected review attestations (GH-1121)
Seed second and final cumulative batch QA without changing production
Retain failed first QA and manual checks; correct GH960 closeout facts (GH-1121)
Seed bounded independent Gemini batch strategy and implementation review
Record pinned non-CI batch strategy and integration resolutions (GH-1121)
Keep development changelog history and defer routine views to hosted reconciliation
merge-cleanup(GH-1108): Jog hook rejects an unusable PR object as a named failure
merge-cleanup(GH-1108): Jog hook skips mapped rows that have no committed receipt bundle
receipts(GH-1105): correct live read-only exit codes; record final QA approval
receipts(GH-1105): provenance for probes, live read-only check, gate and reviews
intake(GH-1105): capture and park task-sync Claude Code adapter
jog-state: intake + lease for GH-1087 (execution gh1087-exec1) — supervisor-owned ledger, doc, and view writes committed before dispatch (GH-292 F1)
scope-c(gh1098): reset GH-1075 after the #1100 cold-start park; invocation 3
jog-state: intake + lease for GH-942 (execution gh942-exec1) — supervisor-owned ledger, doc, and view writes committed before dispatch (GH-292 F1)
jog-state: intake + lease for GH-1075 (execution gh1075-exec1) — supervisor-owned ledger, doc, and view writes committed before dispatch (GH-292 F1)
scope-c(gh1098): morning checklist — queue reset to GH-1075, GH-942, GH-1087 with contracts; GH-1087 intake parked and rated 20/10/20/95
pdda(gh1098): promote plan to 2-WORKING after Approved plan QA; admit task (accepted-start)
intake(GH-1098): capture doc, plan, preflight contract; park + rate 75/55/50/55
jog-state: intake + lease for GH-960 (execution gh960-exec1) — supervisor-owned ledger, doc, and view writes committed before dispatch (GH-292 F1)
jog-state: intake + lease for GH-942 (execution gh942-exec1) — supervisor-owned ledger, doc, and view writes committed before dispatch (GH-292 F1)
radar(GH-1090): verify before naming a fix, read tracker state, deterministic window, Sink B on a closed board
GH-1088: doc status — final QA approved, PR ready
GH-1088: start-task step 7 ends with an orchestrator smoke check before final QA
GH-1088: intake, rating and plan for the start-task orchestrator smoke check
GH-1074: resume never loses a recorded merge or skips pending QA; park GH-1075
GH-1064: manual-check evidence for the dropped TestBatchIssue; doc + changelog amended
GH-1064: drop TestBatchIssue; verify the batch record with manual checks (GH-831)
test-results(GH-1064): retain the green gh436 log the provenance row cites
intake(GH-1064): plan QA approved; promote to 2-WORKING and admit start
intake(GH-1064): capture + roadmap park for script-owned merge-batch issue and post-merge QA
skills(GH-1060): add review-pr-xyz; rename review-code to review-code-xyz
intake(GH-1052): capture recon vendor-contracts spike + roadmap park
test-evidence(GH-1051): retain existing workflow and manual routing checks
test-results(GH-1046): tier-2 gate and final QA provenance
test-results(GH-1046): manual byte check, existing suite and red-control provenance
Sharpen SWE governance and justify recurring test cost (#1009)
Fix ATE process cleanup, oracle false passes, and gate environment leaks (#953)
GH-1001/GH-1002: intake, ratings and shared plan for vendored marathon fixes
evidence(GH-796): land the integration-review landing receipts for #794, #795, #765 (#969)
radar(GH-945): recommend the repo's own verification assets (harness/fuzzer) for recurring clusters (#946)
Forge is upstream again: one central publisher for all standalone repos (GH-955, reverses #882) (#956)
mini-sync(GH-589): adapted mode for mini-owned bytes + review-code verdict (carry-forward of unlanded 09-29 work) (#950)
intake(GH-937): land the CLIO fleet completion umbrella capture (#952)
skills(GH-942+GH-944): loader-limit description trims (radar/10days/express) + merge-cleanup batch-issue protocol (#943)
Record PR902 verified merge readiness
Retain passing full gate and merge readiness summary
Retain PR902 failed and clean Small gate receipts
Retain PR900 failed, focused, and clean Small gate receipts
Seed independent archive fixture QA
Seed independent PR902 merge QA
Seed independent PR900 merge QA
review: scaffold independent PR 902 readiness QA
pages: TL;DR executive summary at the top of Apple Silicon Testing
pages: add Apple Silicon Testing overview (benchmark results so far + links to HiQS-AI-Resolve-Catalog#5)
evidence(GH-862): measured validation replaces the name-keyed sample (#854 landing QA B1)
Revert "skills(GH-862): ci-suite-audit skill (#854 window)"
Revert "evidence(GH-862): validation plan measured from receipts, hosted logs and suite source"
evidence(GH-862): validation plan measured from receipts, hosted logs and suite source
skills(GH-862): ci-suite-audit skill (#854 window)
skills(GH-860): radar and whack-a-mole check CI churn against the repo's SOP
```

## Lens 2 — recurring defects & regression detection

**Signal yields (never collapsed):**
1. **Kinship** — available, low yield: 187 docs carry `related:`, 136 references extracted (50 array-form with `#refs`, 6 scalar filename-form); top citations (#174 ×7, #177 ×6, #224 ×5, #908 ×4, #113 ×4) are infrastructure context, not defect kinship. #591 cited ×3.
2. **Shared seam** — available: 94 `fix:` commits over 43 distinct governing issues; `releases.db`/`releases.sql` fix-touched over **12 distinct days**; `skills/2-daily/merge-cleanup` over 7 days from ≥4 PRs. The Sep-27 gate-fix burst (5 members, one campaign, one branch family #880/#895/#854) is **concentrated authoring, excluded from recurrence** by the ≥2-day/≥2-PR discriminator — and is why #853's `repeat_fixes` (counted from the second, per §6) is 4, not 5+.
3. **Issue-text similarity** — available: the "Hosted wave-reconcile lane needs attention" auto-filed title recurs ×3 in-window (#921 Oct 2, #994 Oct 8, #1125+#1128 Oct 18 01:51/03:07Z — the last two in-window by 5h09m and 3h53m); merge-batch record issues (#1003 #1012 #1063 #1086 #1094 #1103 #1121 #1124) are auto-generated templates — downweighted as report-template similarity, per the guard.
4. **False closes/reopens** — available and genuinely empty for qualifying recurrences: all three REOPENED-state issues (#5, #444, #879) reopened **31s / 33s / 12min** after close — accidental-close corrections, none >24h. Nothing has qualifying reopen history this window.
5. **Cross-repo `reported_from:`** — 18 docs (unchanged relevance; no new consumer-repo re-report observed this window).
6. **Operational evidence** — available (corpus back): relay-system Oct corpus (107 files), TESTS-RESULTS daily, hosted run history (500 runs read), and the lane monitor's auto-files as a live instrument.
7. **Bounceback** — one qualifying instance: Jog-integration feat (#1099, merged 2026-10-17T04:21Z... 06:29Z #1109 adjacent; #1099 merged 2026-10-17) → `fix: make primary Jog own committed landing receipts and merge…` (#1116, merged 2026-10-17T23:05Z) on `merge_cleanup.py`/`batch_record.py` — different PR, same day → **potential regression** (folded into the merge-batch target). Task-sync (#900/#902 → GH-1105) and recon (#1044) fixes are same-PR in-branch authoring — excluded.
8. **Umbrella re-score** — yield: 27 title hits, **13 whack-a-mole-form, 1 with a `### Cluster signature` (#853)**; 12 without (8 open hand-filed groupings — #937 #1022 #1021 #1000 #845 #967 #775 #777 — plus legacy #591 #648 #949 #784). Rows below.
9. **Trunk CI health** — green: 290 window runs on `development`; failures = 2 (Wave reconciliation, 2026-10-02T05:53Z run 36970981161 @1b40d57c and 12:51Z run 37009287827 @75b75181). CI workflow: 0 failures in its last 212 fetched runs (back to 2026-09-18). **Consecutive red days at window end: 0.** No Potential Regression from signal 9. Plus the branch-filter correction (degradation table): 3 additional PR-close-triggered lane qualification failures (#994's run 37723297290 on `fix/workhorse-claude-optimization-v2` @67e2df8c Oct 8; #1125's 39085003007 failure + #1128's 39085005180 cancelled, Oct 18, on `chore/non-ci-integration-20261017` @4a042b9f and `marathon/gh-960-…` @eb349646).

### Targets

**T1 · RADAR-class-gate-red-on-clean-trunk — 24 members · first-seen 2026-09-21 · runs 3 · Recent Regression (draining) · CLAIMED by #853 · score ≈ 24 × 2 ÷ 2 × 1.3 ≈ 31 (down from ≈29-at-22-members with 8 open; open members 8 → 3).**
Closed since run 5: #745 #793 #807 #813 #814 #830 (all 2026-09-27, #854 campaign: PRs #867 #869 #810 #818 #866) and #912 (2026-10-09). New open member: **#991** (2026-10-08: 13 harness/vendoring suites red in a fresh disposable full clone of clean `development@33a03acc` on this Mac — "env leak"; the same morning hosted run 37723297290's full-suite qualification failed — E6's second red). Still open: #715 #760 #991. Umbrella #853 re-score: **65 → 28** (reopens 0 · repeat_fixes 4 · reverts 0 · size 7 · comments 31 lifetime → 6 · open_days 21 → 3; no umbrella-level cutoff exists — the Fix task is per-member and incomplete). Why it recurs: ~409 registered suites still assume a quiet, clean, single-tenant host; the freeze stopped the inflow (414 → 409; 0 new suite files in-window and post-window through `4fd5dca8`) but not the stock. Durable fix remains #853's own per-member classification (suite assumption / product defect / legitimate regression), now down to 3 open members.

**T2 · RADAR-class-hosted-reconcile-lane — first-seen 2026-09-21 · runs 3 · Regressed after declared fixed · post-cutoff score 18 → class survived.**
#591 closed 2026-10-11 (umbrella), with #421 #454 (10-11), #842 #851 #852 (09-28) — but in-window post-cutoff member events: #921 + #926 (Oct 2: `gh issue view #506 failed` — issue #506 was transferred to #958 on 2026-10-01, and `wave_reconcile.py --catch-up` still exits 6 on it; #926 **open**, the root), #994 (Oct 8 hosted qualification failure), #1125 + #1128 (Oct 18 01:51Z/03:07Z — 7 days after the close; #1125: *"Qualification failed; no receipt produced: `bash validate.sh --sequential` returned non-zero exit status 1"*, auto-closed on the next green). Score = 3·0 + 3·1 + 4·0 + 8 + floor(29/5) + 2 = **18** (robust: 13 with comments zeroed) ≥ 5 on a closed umbrella → **class survived — recommend reopening #591** (radar recommends; it never reopens). Counterweight, stated plainly: dev-branch scheduled/push runs are on a **52-green streak**, and the surviving residue is one open root (#926) plus a monitor that files-then-closes within hours. The ledger already carries an In-progress row — GH-591 "Reconciler provenance lifecycle" — which is simultaneously the natural home for the residue and **drift** (closed issue, live row). Post-window: PR #1134 (merged 2026-10-18T08:02Z tip) makes hosted qualification run `validate.sh --parallel 4` with receipts recording first-attempt failures — possibly the exact guard this class lacked; verify at run 7.

**T3 · RADAR-class-merge-batch-stale-state — NEW · first-seen 2026-10-18 · runs 1 · Chronic with recent-regression flavor · UNCLAIMED · score ≈ 7 × 2 ÷ 2 × 1.3 ≈ 9.**
Class: merge-batch machinery trusts state captured once (per-PR file lists at `batch_record.new()`, verdict snapshots, QA-pending flags, do-not-merge title flags) across resumes and reruns where the world has moved. Members: **#444** (open, 2026-09-05: Phase 5 merges a "do not merge" PR), **#944** (open, 10-03: batch-issue protocol), **#1072 #1073 #1075** (open, 10-15, operator-deferred Mediums: stale verdict snapshot erasing a newer landing; resume retaining stale repaired-PR files; stale per-PR file lists), **#1084** (open, 10-15: QA gate bypassed on a non-resume rerun) + closed #1005 (10-09), #1066 (10-15). Seam: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, `batch_record.py`, `ledger_merge.py`; fix commits 2026-09-27 → 2026-10-17 across ≥4 PRs (#863-era staging, #1069 GH-1064 10-14, #1116 GH-1108 10-17). Bounceback: #1099 (feat, Jog landing receipts) → #1116 (fix) same day, different PR. Blast radius: every multi-PR landing — the repo merged 83 PRs this window mostly through this machinery. **Verify with:** the existing `test/gh436-merge-cleanup.py` and `test/gh534_phase_b_tests.py` suites (extend toward resume/rerun/verdict-staleness signatures — no new suites, GH-831).

**T4 · RADAR-class-roadmap-ledger-drift — runs 6 · Chronic.** `releases.db`+`releases.sql` fix-touched over 12 of 21 window days; `releases check` clean (0 failures / 10 warnings, generation 1611, receipt chain intact, 1793 receipts); **8 migration refs 61 days stale** (7-day threshold; 39 at run 5); 24 `grandfather_entries` pending, unchanged. New drift: roadmap rows GH-591 and GH-807 read In-progress against **closed** issues (GH-854's row likely post-execution too). `releases-merge-resolve.sh` absorbed the conflicts — the transport decision (#496 Phase 3) is still open.

**Carried targets (delta only):** vendored-skill-drift (superseded posture unchanged; #959 open), vendored-root-resolution (**flat a second consecutive window** — no fifteenth member filed; #715 still open, shared with T1), dark-telemetry (**new member candidate #1032**: the Oct-8 one-time full-suite audit routine died before any work, no partial log — the exact class shape; run-log corpus partially restored), guard-blind-matcher (no single helper cited; registry pressure stays capped), marathon_drive.py (#290/#291: **0 window commits name them** — unactioned 6th interval), headless-turn-timeout (**5 of 6 wave-1 members closed 2026-10-11/13** (#241 #276 #285 #480 #521); #237 remains open with no closing citation; #1126 (10-18T02:54Z, in-window) is a candidate member — timeout-diagnosis determinism), frozen-twin-dead-fix (**0.8.0 Sundown is now 1 day past its 2026-10-17 target and the exit criterion still reads NOT WRITTEN** — `releases check` warning, 2026-10-18), agy-auth-preflight (**quiet ×5, unexplained** — one command settles it: verify #245's cross-call-site invariant covers #227).

### Regressed after declared fixed

| Class | Declared fixed | Came back | Rule | Mechanical guard |
|---|---|---|---|---|
| Hosted lane qualification | #591 closed 2026-10-11 (stayed closed 7 days) | #1125 + #1128 (2026-10-18T01:51Z/03:07Z, in-window) — plus pre-close incidents #921/#926 (10-02) and #994 (10-08) | A landing's qualification must produce a receipt or a named failure before the next landing proceeds | `hosted_lane_report.py` auto-file (#684) caught every return; nothing yet pins the class itself — post-window #1134's receipt-recorded first-attempt failures is the candidate guard, verify at run 7 |

(#912 closed 2026-10-09 vs #991 created 2026-10-08: overlapping reports, not a post-fix return — excluded from this table; #991 is counted as a T1 member instead.)

## Step 2b — Open-PR collision check

Exactly one open PR: **#1024** — `feat(weekly): held intake and preserved rollover…` (GH-1022), **draft**, base `development`, `CONFLICTING`/DIRTY, `mergeable: UNKNOWN`→CONFLICTING, no review, stale since 2026-10-13T07:23Z, files = GH-1022 docs + `TESTS-RESULTS/2026-10-11+GH-1022/**` + `CHANGELOG.md`/`LEADERBOARD.md`/`ARCHITECTURE.md` (collides with hosted reconcile output). It does **not** touch `releases.db`. Classification: **blocked/stale** — ask the owner to rebase/update/split; it overlaps no radar target ("No work underway" for every target above). New-guard re-run: the window's added guards (#1123's CI ordering/audit work, the gh648 guard) are hosted-workflow-side and **cannot be run locally** — reported unavailable, never as a pass; with zero file overlap against the sole open PR, no collision was found.

## Step 2c — CI churn check (SOP-aware)

SOP detection: `docs/CI-CHURN-RECOVERY-SOP.md` on trunk, referenced from `SOP.md:202`, governing issue #857 **closed 2026-09-28T16:39Z** → `SOP: docs/CI-CHURN-RECOVERY-SOP.md (landed)`. Its E1–E8 table (§2.1) matches the skill defaults with repo-specific sources. No open `CI churn recovery:` issue → not in a recovery window.

| Trigger | Value | Threshold | Source | Fired |
|---|---|---|---|---|
| E1 | Wave-recon last 20 (unfiltered): 15 success · 1 failure · 3 cancelled · 1 skipped = 5% | ≥30% of last 20, or ≥5 consecutive | `gh run list --workflow wave-reconcile.yml` | no |
| E2 | median created→merged **0.22 d** (83 PRs); 1 open PR (ready-state unavailable — proxy labelled) | >2 d median, or ≥5 ready PRs waiting | PR list | no |
| E3 | 0 of 1 open PRs touch `releases.db` | ≥50% of open PRs on one shared file | Step 2b file lists | no |
| E4 | `TESTS` 414 → 409 (net −5); 0 new `test/` files in-window and post-window | any net growth under the #831 freeze | `validate.sh` at `85a60f2c` vs `f9e5b243` vs `4fd5dca8` | no |
| E5 | #853 now-score 28; its `repeat_fixes` = 4 (from the second, §6) | churn score ≥40, or ≥5 repeat fixes in 14 d | signal 8 | no |
| E6 | **2 clean-trunk reds on 2026-10-08**: #991 (local full gate red at clean `development@33a03acc`) + run 37723297290 (hosted qualification `validate.sh --sequential` exit 1) | ≥2 red runs on a clean trunk in 7 days | issues, gate records | **yes** |
| E7 | job caps 120 min (ci.yml:160, wave-reconcile.yml:28) vs longest observed 33.6 min (duration proxy includes queue time) | cap < 1.25 × longest of last 20 | workflow config vs run durations | no |
| E8 | Run share **83.1%** (run 5) → **82.0%** (run 6); Front-Door 22 d past target as a draft | ≥80% two consecutive radar runs, or active release slips on CI work | Lens 1, `releases.sql` | **yes** |

Declaration rule (any two, or any one for 7 consecutive days): **met — E6 + E8.**

> **Recommended next step (proposal — you decide):** Per `docs/CI-CHURN-RECOVERY-SOP.md`, triggers E6 (2 clean-trunk reds on 2026-10-08: #991 local + hosted run 37723297290) and E8 (Run share ≥80% in runs 5 and 6) fired. That meets its declaration rule. I recommend declaring a CI churn recovery and starting its Day 0 checklist (§2.3). Nothing changes until you declare.

Context the SOP does not encode: E1/E2/E3/E4/E5/E7 are all no — the pipelines are the healthiest of any radar run — and the recovery the SOP would prescribe is already self-organizing through the #1118 board's CI program (#1110 audit → #1112 spike → #1114 experiment → #1123 quick wins → #1134 parallel receipts, landed post-window). Declaring would put governance and exit gates around work already in flight.

## Lens 3 — release recalibration

`releases check` (run against a scratch git-repo copy of `releases.db`+`releases.sql`, per the lock rule): **clean — 0 failures / 10 warnings; generation trio consistent at 1611** (968 → 1221 → 1611); receipt chain intact (1793 receipts, 180 merge forks tolerated). Warnings: 8 migration refs **61 days stale** (>7-day threshold; 39 days at run 5 — aged, not moved), 24 `grandfather_entries` pending (unchanged), **0.6.0 Front-Door draft 22 days past target (2026-09-26)**, **0.8.0 Sundown draft 1 day past target (2026-10-17)**.

Unshipped: Front-Door 0.6.0 (draft, 19 items, overdue), Sundown 0.8.0 (draft, 0 items, overdue — the frozen-twin target's "write the exit criterion" item is now dated urgency), Plumbline 0.4.0 (2026-11-14), Lantern 0.5.0 (2026-12-12). 0.9.0 Cargo shipped 2026-09-25 (6 days late).

Ledger→GitHub join: `milestoneRef` Front-Door/Sundown/Plumbline/`milestones` have no GitHub milestones (only Bulkhead/Ballast exist, both shipped) → join impossible, membership/status labelled unavailable; **orphan share 256/256 open issues = 100%, sixth consecutive run = missing binding** ("bind a milestone so the next run can join" — the actionable finding, not backlog drift).

Plan-vs-execution: the window's actual effort (CI qualification, gate hotspots, Jog supervisor, merge-batch machinery) maps to the GH-836 "CI refactor: trim the measured gate hotspots" row (In progress; PR #1132 landed in-window) and the #854/#853 stabilization arc — but the release bands' own targets (Front-Door's 19 items) saw little motion. **T3 merge-batch cluster is UNCLAIMED by any band.** Drift rows (closed issue, live In-progress row): **GH-591, GH-807** (GH-854 likely post-execution). Advisory only.

## Umbrellas — re-scored (signal 8)

Yield: 27 title hits · 13 whack-a-mole-form · 1 with a signature present (#853) · 12 without (8 open hand-filed groupings excluded from re-score — no churn claim; 4 legacy).

- [ ] **#853** — filed at **65** (`20260927T144000Z`), now **28** (window 2026-09-27 → 2026-10-18), fix merged **not yet** (per-member only: #818 #866 #867 #869 #810, all 2026-09-27) → **holding**
      cluster gate-suite-isolation · baseline observed (default weights) · quiet 0/2 · class RADAR-class-gate-red-on-clean-trunk
- [ ] **#591** — legacy — no signature (reconstructed; run 4 ≈13), closed 2026-10-11, fix merged 2026-09-13 PR #600; now **18** post-cutoff (interval = full window) → **class survived — recommend reopening**
      cluster hosted-reconcile-lane · legacy — no signature (reconstructed) · quiet 0/2 · class RADAR-class-hosted-reconcile-lane
- [x] ~~**#648**~~ — closed 2026-09-22 after #687; struck at run 4. **Run 6 caveat update:** 5 of 6 wave-1 members closed 2026-10-11/13 (#241 #276 #285 #480 #521); **#237 still open** with no closing citation — close it against its lane or reopen on the umbrella
      cluster headless-turn-timeout · legacy — no signature (reconstructed) · class RADAR-class-headless-turn-timeout
- [ ] **#802** — superseded by operator decision (comment 5841529958) → #831 (closed 2026-09-26); residual = #853 → **superseded**
      cluster containment-gate-decoupling · signature present · class RADAR-class-gate-red-on-clean-trunk
- [ ] **#949** — legacy — no signature (reconstructed), closed; fix merged 2026-10-09 PR #953; post-cutoff interval 10-09→10-18 shows one unconfirmed member candidate (#1032) → **holding** (legacy earns no quiet credit)
      cluster ate-campaign-lifecycle · legacy — no signature (reconstructed) · class none (candidate: RADAR-class-dark-telemetry)

## Measurement hygiene — sixth consecutive run

- `rgt:` adoption **0** (0 of 83 window merged-PR bodies; 0 of 705 issue bodies — the only hits are the classifier's own contract discussions #26 #27 #294 #295 #1083). Transform cannot be measured until a governing record declares.
- Commit-type registration: Unclassified 14.5% mechanical (7.5% at run 5); new unregistered machine families this window: `jog-state:` ×8, `intake(` ×7, `scope-c(` ×2, `pdda(` ×1, `receipts(` ×2, plus 24 unprefixed QA-turn prose commits. Register the families in the commit SOP (or in radar's harness table) — acceptance: Unclassified < 5% with no parser change.
- Milestones: sixth consecutive 100% orphan (256/256). The Lens 3 join stays impossible until Front-Door/Sundown/Plumbline milestones exist on GitHub.
- **Sink A durability:** run 5's report was never committed anywhere; this run found it only because board #293 carried the content. This run's Sink A is committed **locally** (operator instruction — active merge sequence, no push); if it does not ride the next push, run 7 inherits the same gap.
- Doc-corpus drift guard: 1-INBOX 73 · 2-WORKING 111 · 3-COMPLETED 269 · 4-MISC 5 (458 total; run 5 counted 321 — the corpus grew ~43%, citation deltas are **not** comparable run-over-run).

## Checklist snapshot (as written to board #293 at generation time)

See #293 for the live copy. Targets carried/updated: gate-red-on-clean-trunk (3 open members: #715 #760 #991), hosted-reconcile-lane (class survived — recommend reopening #591; root #926), vendored-skill-drift, vendored-root-resolution (flat ×2), dark-telemetry (+ #1032 candidate), guard-blind-matcher, roadmap-ledger-drift (MIG 61d · grandfather 24 · drift rows), marathon_drive.py (unactioned ×6), headless-turn-timeout (#237 close-or-reopen), frozen-twin-dead-fix (Sundown overdue, exit criterion unwritten), agy-auth-preflight (quiet ×5). New: **RADAR-class-merge-batch-stale-state** (3 items). CI churn section added (declaration rule met; operator decision pending).

### Standing observation for the next run (run 7)

Run 6 confirmed both of run 5's asks: the freeze held for a full window (414 → 409, 0 new suites, 0 post-window through `4fd5dca8`) and #853's open-member count fell (8 → 3). The stock is draining; the mix is not. Run 7's four checks: (1) #1134's parallel qualifying receipts actually record first-attempt failures — the guard that would pin the #591 class; (2) #591 reopened or its ledger row reconciled, #926 closed with a naming commit; (3) Grow share — a seventh consecutive decline re-fires E8, and the recovery decision proposed here will have been made or declined; (4) this report visible on GitHub and the local branch reconciled (2 ahead / 587 behind at run 6).
