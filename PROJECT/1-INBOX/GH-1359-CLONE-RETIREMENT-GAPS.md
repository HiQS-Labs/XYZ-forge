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
