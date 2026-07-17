---
title: HQ MARATHON — 2026-07-17 (cross-repo rollup, orchestrated from xyz-3-agents-swarm)
status: Active
created: 2026-07-17
updated: 2026-07-17
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

# HQ MARATHON — 2026-07-17

## Source registry

`hq_known_repos` + `hq_repo_resolve` from `utils/hq/hq-lib.sh`.

| Repo | Marathon file | Status | In scope? |
|---|---|---|---|
| LTVera-Pandas | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md` | "Active — reopened 2026-07-10 to add a new disjoint lane (#47)" | ❌ closed |
| pdda | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07.md` | Ready to fire (2-WORKING) — docs authored, briefed, not yet fired | ❌ closed |
| rebalance-OS | `PROJECT/2-WORKING/MARATHON-2026-07-07.md` | "MOSTLY STALE (2026-07-16) — Lane A superseded by #125, Lane B shipped via MARATHON-2026-07-16-B, Lane D shipped separately. Only Lane C (resolution resilience) remains un-fired." | ❌ closed |
| rebalance-OS | `PROJECT/2-WORKING/MARATHON-2026-07-16-B.md` | "All 5 lanes fired, shipped, and merged to development 2026-07-16 via PR #134. GH-120/GH-121/GH-129's follow-up are fully closed; GH-123 (Phase 0+1 of 4) and GH-127 (2 of 8 sources) have real remaining scope tracked against this file, since neither has its own project doc yet." | ❌ closed |
| xyz-3-agents-swarm | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07-E-BUILD.md` | All 5 lanes complete — #159/#168/#169/#175 merged (PR #179); #186 built + Approved on local branch `marathon/gh-186-aider-vendor-version-drift-2026-07-09`, not yet pushed/PR'd | ❌ closed |
| xyz-3-agents-swarm | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-07-F-VALIDATE-FIXES.md` | Lanes 12-13 SHIPPED 2026-07-17 (GH208-154-149-198 marathon, both Approved). Lanes 1-9 | ❌ closed |
| xyz-3-agents-swarm | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-10-LM-STUDIO-AIDER.md` | Lane 1 (#195 ATE LM Studio driver) shipped — merged to `main` via PR #195 (2026-07-10). Lane 2 (GH-147 Phase 2, production Aider relay shim) OPEN and fireable next. | ❌ closed |
| xyz-3-agents-swarm | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-17-G-DRIVER-HARDENING.md` | Both lanes SHIPPED 2026-07-17 via the GH208-154-149-198 marathon (codex builder, agy | ❌ closed |

## Status

| What was just completed | What's next |
|---|---|
| Scanned 4 repo(s), found 8 marathon doc(s), preflighted 0 active lane(s): 0 ready, 0 blocked-not-promoted, 0 blocked-other, 0 stale-already-landed, 0 ambiguous; 0 held marathon(s) surfaced but not counted. | Re-run `utils/hq/marathon-scan.sh` to refresh; fire any ready lane via that repo's own `swarm-preflight.sh` → `marathon-drive.sh`. |

## Net result

- Repos scanned: 4
- Marathon docs found: 8
- Active lanes scanned: 0
- Ready: 0
- Blocked-not-promoted: 0
- Blocked-other: 0
- Stale-already-landed: 0
- Ambiguous: 0
- Held marathons surfaced, not counted: 0

## Notes

- The scanner is read-only over target repos. It writes only this aggregate doc.
- Each active lane is preflighted with that repo's own `utils/swarm-preflight.sh --dry-run`.
- Held marathons are surfaced for operator awareness but excluded from the fireable count by design.
