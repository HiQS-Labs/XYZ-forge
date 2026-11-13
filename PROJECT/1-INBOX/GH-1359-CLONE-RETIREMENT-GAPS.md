---
title: Clone retirement lifecycle research and coordination
status: Planning
created: 2026-11-07
updated: 2026-11-07
owner: noelsaw1
gh_issue: 1359
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1359
goal: Clone retirement lifecycle research and coordination
---

# GH-1359 — Clone retirement lifecycle research and coordination

Canonical shared plan: [GH-1247](../2-WORKING/GH-1247-RETIRE-REMOTE-TAGS.md).

This issue's requirements remain in the linked GitHub issue. Research/coordination only; broader implementation, deletion and schedules remain unapproved.

## GH-1359 bounded completion-to-retirement map

Research only, at base `3bf02f73ce0cb11a82f970357209980f808ccb3c`. No inventory below is a safe-delete verdict. No new scheduler or disposal authority.

| Producer / owner | Completion → invocation | Fresh classification → outcome | Witness / refusal control | Failure / next reconciliation |
|---|---|---|---|---|
| start-task / supervising agent | Step 9 invokes `merge_cleanup.py --primary P --retire-published-pr N --checkout C`, preview then execute only eligible paths | `retire_published_checkouts` → `inspect_checkout` → `refresh_for_teardown` → existing teardown | Actual PR #960 run in #1247 comment: published head, clean checkout, explicit invocation, preserved tags; #1362 records installed tick failure first | Retry exact paths after reviewed fixes and deployment; no automatic retry proved |
| Express / supervising caller | `utils/py/express.py:1208` prints guidance after landing | No invocation in this source path; caller must invoke same existing command | Source witness only; no observed missed-retirement execution attributed | Owner must verify landings and invoke retirement; terminal callback unknown |
| Marathon / supervising caller | `utils/py/marathon_drive.py:1812-1841` prints guidance inside cost-summary callback | Early returns can suppress reminder; reminder never calls teardown | Source witness: disabled summary, failed analyze or absent cost block returns first | No automatic retire established; retain caller ownership until real terminal-job trace |
| Jog / supervisor | `utils/py/jog_run.py` finally releases supervisor lock | Lock release is not clone retirement; Marathon owns execution handoff | Source-only boundary; no new omission incident claimed | Correlate real completed queue result with caller closeout before selecting repair |
| Gate / verify helpers / creating agent | start-task Step 9 passes exact helper paths alongside task path | Same fresh classifier, never age-based deletion | This task's helpers remain active during verification | Only after publication and no unique evidence/claims; preserve unknown |
| T3 / platform lifecycle | Supported removal/completion API not established in this scoped trace | UNKNOWN; no implicit safe-root expansion | #1359 reports nested worktrees; no ownership or idle proof | Preserve pending explicit API/session contract |

### Real observed chain and cutoff

The November 7 LTVera-Pandas PR #960 incident reached an actual retirement invocation. It failed first at trusted tool discovery (#1362), then at remote-identical tag provenance (#1247). These are two causes on one completion chain, not proof of a missing invocation. Earlier #1247 evidence identifies a separate October 28 PR #855 run. Dirty/active samples already recorded on #1359 demonstrate correct retention; none are candidates for deletion here.

The two scanner fixes address false preservation only. They do not prove other producers omit cleanup. #748 still owns retained landing clones. Installed drift must be resolved through Skills Army HQ after a reviewed source merge; no deployed payload was edited. Periodic reconciliation remains unjustified until event-driven corrections leave measured residual misses. Unchanged scans are not additional incidents.

Remaining #1359 work: source actual terminal-job receipts for Express/Jog/Marathon, establish T3 ownership/API, inspect safely bounded device inventory with dispositions, and assess residual misses. This PR does not close #1359 or activate its proposed pilot. Workspace-vs-Trash counts: no research-driven retirement or purge performed.

## Merge evidence

- PR #1364 merged 2026-11-08 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Earlier bounded research record

Retained from the Batch 2 research checkpoint; the updated findings above govern where they differ.

## Objective and scope
Determine why completed jobs leave clones, then repair demonstrated lifecycle gaps without weakening preservation. Research/plan only; no deletion or schedule activation. This issue coordinates existing defects #1247 (remote-identical tags) and #748 (retained landing clones); their fixes remain with those owners.

## Medium-depth recon — 2026-11-07
Read-only source/device pass at `3bf02f73ce0cb11a82f970357209980f808ccb3c`. No teardown, gate, fetch, or safe-delete verdict performed. Paths below are relative to this revision.

| Confirmed seam | Source | Consequence |
|---|---|---|
| Published retirement is an agent closeout instruction | skills/1-hourly/start-task/SKILL.md:320-359 | No universal completion callback |
| Marathon prints retirement guidance inside cost-summary output with early-return paths | utils/py/marathon_drive.py:1812-1841 | Reminder may disappear; reminder is not retirement |
| Express prints guidance | utils/py/express.py:1208 | Another handoff rather than automatic disposal |
| Jog exit cleanup releases supervisor lock | utils/py/jog_run.py:2147-2155 | Does not dispose of clones |
| Exact-path published retirement already validates provenance and fresh state | skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:1712-1752 | Reuse this implementation |
| Default roots plus same-origin primary siblings; immediate-child scan | skills/2-daily/merge-cleanup/scripts/scan_clones.py:26-83,1169-1194 | Primary siblings covered; nested T3 roots not covered by default |
| Preserve dirty/ignored/stashed/unpublished/active/dependent/unknown state | scan_clones.py:1085-1155 (same directory) | Retention may be correct |
| Trash full clones; Git-remove worktrees | merge_cleanup.py:1069-1114 (same directory) | Tidiness does not immediately reclaim disk |

Bounded Path.iterdir inventory: 26 immediate Forge Git checkouts in the primary's Documents/GitHub parent (including primary/current runner), two T3 worktrees under ~/.t3/worktrees/XYZ-forge. Zero matching immediate checkouts under Documents/GH Repos or marathon-clones; Documents/GitHub Repos absent. These are NOT device-wide or eligible-for-deletion counts.

Five samples inspected with `git --no-optional-locks`: gh805-test-value has one dirty entry; gh1317 pilot, gh1325 gate and gh1160 sample clean/no stash but remote recovery and live ownership unverified; current gh1356 runner clean but active. Clean does not establish disposable.

Installed script byte comparisons differ despite identical SKILL.md: deployed scanner/teardown lack repository GH-1308 containment/origin rechecks. This is deployment drift, NOT proven cause of accumulation. Deploy through Skills Army HQ only. Bounded LaunchAgents literal search found no merge-cleanup/retire-published references; wrappers/other schedulers remain unknown.

## Triangulate — research
- CELL: irreversible × crossing for eventual retirement; full lenses, medium-depth bounded trace.
- GROUND: creation/completion callers → handoff → discovery → provenance/session checks → fresh teardown.
- FALSIFY: “all leftovers are missed cleanup” disproved by dirty and active examples; “primary sibling root omitted” disproved by default_scan_roots.
- SMALLEST: ownership/disposition census before another cleaner.
- UNKNOWNS: per-folder completed-job attribution, remote recovery, handles, T3 lifecycle API, scheduler wrappers.

## Ranked explanations, not one universal root cause
1. Missing lifecycle invocation: strongest source evidence; correlate actual terminal jobs before attribution.
2. Correct safety preservation: observed dirty/active samples; never weaken checks to improve deletion counts.
3. Producer/discovery mismatch: nested T3 paths outside default discovery and safe roots; ownership contract required before any change.
4. Ref provenance false positive: existing #1247; inspect current classifier at scan_clones.py:549-642 and its fetch at :570.
5. Installed code drift: confirmed, accumulation impact unknown.
Temporary landing leaks remain #748.

## Triangulate — plan
- GROUND: exact-path retire_published_checkouts plus refresh_for_teardown already exist.
- FALSIFY: “hourly deletion fixes the class” fails against correctly preserved and externally owned checkouts.
- SMALLEST: fix demonstrated closeout omissions, then periodic reconciliation for missed eligible cases.
- SKIPPED: T3 removal until ownership/session contract verified; permanent trash purge and automatic disposal of ambiguous state.

## Ordered plan (each phase repeats ground → falsify → shrink)
1. Census roots, registered worktrees and completed jobs by producer; record owner and exact disposition or UNKNOWN. Falsify completeness against git worktree registry and known T3 paths. Produce nonempty sourced inventory, not an age-based deletion list.
2. Trace real completion records to attempted retirement for start-task, Express, Jog/Marathon, gate helpers and T3. Challenge “missing invocation” against actual preservation receipts. Link #1247/#748; select only evidenced repair sites. Root-cause statement must name origin, fix site and why upstream/downstream is inappropriate.
3. Implement minimal verified integration and deploy matching cleanup code through Skills Army HQ. Prefer existing per-job exact-path retirement over new remover. Decide shared completion hook only if traced producers have a common truthful terminal event.
4. Evaluate hourly reconciliation after event-driven fixes. Start report-only; deduplicate unchanged exceptions. Any later action requires explicit owned roots, fresh inspection and established authorization. Do not expand deletion authority through discovery alone.
5. Verify through existing suites in disposable full clone or recorded manual checks; publish findings and retention outcomes. Prove that changing state between scan and teardown is rechecked.

## Acceptance and falsification
- [ ] Every observed checkout gets sourced ownership/disposition or explicit UNKNOWN; empty/failed scan cannot pass.
- [ ] At least one real completed-job chain explains an omission or a correct preservation; folder age is not root-cause evidence.
- [ ] Eligible completed task retires through existing mechanism or produces an actionable preservation reason.
- [ ] Dirty, ignored evidence, stash, unpublished refs, active session, dependent worktree, unknown query and out-of-root controls all preserve.
- [ ] State changed after scan refuses teardown; remote-equivalent/local-only/differing-tag cases handled under #1247.
- [ ] Repeated reconciliation causes no duplicate effects or repeated unchanged alerts.
- [ ] Existing checks/manual red controls and provenance committed under TESTS-RESULTS/<date>+GH-1359/ during implementation. No new suites/gates.
- [ ] Retired/preserved counts and space-in-workspace vs space-in-Trash reported separately.

## Investment rubric (#1358)
Capability: reduce missed cleanup without losing protected state. Test: real completion-to-disposition evidence plus safety controls. Decision value: first determine whether caller repair suffices; only add periodic execution if residual missed cleanup warrants it. No hourly remover approved by this research.

## Unknowns and cutoff
No full safety scan, lsof, remote PR/ancestry attribution, T3 internals or wrapper scheduler trace. These are next targeted lookups, not assumed absent. Main review question: per-producer closeout vs shared hook, resolved by terminal-event ownership.

## PRS proposal
- pri 70: recurring operator effort and workspace accumulation.
- sev 45: cleanup errors can affect unique work; no loss observed in this pass.
- appeal 50: neutral.
- effort 45: bounded lifecycle audit and targeted repairs; T3 integration separately sized.
Unstarted implementation intake; no ledger row. Planning is reversible; actual disposal crosses data-loss boundaries and requires current safety proof.

## Merge evidence

- commit 92b785461279 landed 2026-11-07 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
