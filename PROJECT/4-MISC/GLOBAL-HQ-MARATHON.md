---
title: HQ MARATHON — 2026-07-08 (cross-repo rollup, orchestrated from xyz-3-agents-swarm)
status: Active
created: 2026-07-08
updated: 2026-07-08
owner: noel@neochro.me
scope: >
  Repos with marathon docs under PROJECT/2-WORKING/, enumerated from the HQ PDDA registry and
  resolved via hq-lib.sh. Active docs are preflighted lane-by-lane with each repo's own
  utils/swarm-preflight.sh --dry-run; Held docs are surfaced but never counted as fireable.
goal: >
  Give the operator one at-a-glance cross-repo rollup of every marathon doc's status and
  preflight verdict on this device, regenerated fresh each run rather than hand-maintained.
roadmap_exempt: true
generated_by: utils/hq/marathon-scan.sh
---

# HQ MARATHON — 2026-07-08

## Source registry

`hq_known_repos` + `hq_repo_resolve` from `utils/hq/hq-lib.sh`.

| Repo | Marathon file | Status | In scope? |
|---|---|---|---|
| LTVera-Pandas | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md` | Partially landed (2-WORKING) — #40 fixed & verified; #41 ready to fire | ❌ closed |
| pdda | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md` | Ready to fire (2-WORKING) — docs authored, briefed, not yet fired | ❌ closed |
| rebalance-OS | `PROJECT/2-WORKING/MARATHON-2026-07-06-B.md` | Held (un-fired — awaiting operator go + XYZ-side export confirmation) | 🟡 held, not counted |
| rebalance-OS | `PROJECT/2-WORKING/MARATHON-2026-07-06.md` | Completed | ❌ closed |
| rebalance-OS | `PROJECT/2-WORKING/MARATHON-2026-07-07.md` | Queued (not yet fired) | ❌ closed |
| sleuth-app | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md` | Active (2-WORKING) | ✅ active |
| xyz-3-agents-swarm | `PROJECT/2-WORKING/GLOBAL-HQ-MARATHON.md` | Active | ✅ active |
| xyz-3-agents-swarm | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07-D-EXPLORE-IDEAS.md` | Ready to fire (2-WORKING) — skeleton docs authored, not yet fired | ❌ closed |
| xyz-3-agents-swarm | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07-E-BUILD.md` | Ready to fire (2-WORKING) — docs authored + rated, not yet fired | ❌ closed |
| xyz-3-agents-swarm | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07-F-VALIDATE-FIXES.md` | Ready to fire (2-WORKING) — doc authored + rated, not yet fired | ❌ closed |
| xyz-3-agents-swarm | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md` | Active (2-WORKING) | ✅ active |
## sleuth-app

| Lane | Source marathon | Resolution | Verdict |
|---|---|---|---|
| #338 | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md` | `gh-issue #338` | ⛔ blocked-other (exit 6) |
| #348 | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md` | `gh-issue #348` | ⛔ blocked-other (exit 6) |
| #349 | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md` | `gh-issue #349` | ⛔ blocked-other (exit 6) |
| #351 | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md` | `gh-issue #351` | ⛔ blocked-other (exit 6) |
| #352 | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md` | `gh-issue #352` | ⛔ blocked-other (exit 6) |
| first-time-user-remediation | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md` | `PROJECT/2-WORKING/FIRST-TIME-USER-REMEDIATION.md` | ⛔ blocked-other (exit 6) |

## xyz-3-agents-swarm

| Lane | Source marathon | Resolution | Verdict |
|---|---|---|---|
| relay-to-issue-skill | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md` | `PROJECT/3-COMPLETED/RELAY-TO-ISSUE-SKILL.md` | ⛔ blocked-other (exit 3) |

## Status

| What was just completed | What's next |
|---|---|
| Scanned 5 repo(s), found 11 marathon doc(s), preflighted 7 active lane(s): 0 ready, 0 blocked-not-promoted, 7 blocked-other, 0 stale-already-landed, 0 ambiguous; 1 held marathon(s) surfaced but not counted. | Re-run `utils/hq/marathon-scan.sh` to refresh; fire any ready lane via that repo's own `swarm-preflight.sh` → `marathon-drive.sh`. |

## Net result

- Repos scanned: 5
- Marathon docs found: 11
- Active lanes scanned: 7
- Ready: 0
- Blocked-not-promoted: 0
- Blocked-other: 7
- Stale-already-landed: 0
- Ambiguous: 0
- Held marathons surfaced, not counted: 1

## Notes

- The scanner is read-only over target repos. It writes only this aggregate doc.
- Each active lane is preflighted with that repo's own `utils/swarm-preflight.sh --dry-run`.
- Held marathons are surfaced for operator awareness but excluded from the fireable count by design.
