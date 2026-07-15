---
title: HQ MARATHON — 2026-07-06 (cross-repo rollup, orchestrated from xyz-3-agents-swarm)
status: Active
created: 2026-07-06
updated: 2026-07-06
owner: noel@neochro.me
scope: >
  Repos with an OPEN marathon only (operator directive, mid-session 2026-07-06: "only target repos
  with open marathons"). Universe = Git Pulse Sync PDDA registry, filtered to Active marathon status.
roadmap_exempt: true
generated_by: >
  Manual HQ cross-repo pass — first of its kind. No automated tool does this yet; GH-88 explicitly
  deferred "cross-repo launching" to v1.1 (stays `cd repo && marathon.sh`). This file is HQ's first
  attempt at the *aggregation* step; firing each lane still happens inside its own repo.
goal: >
  Manually aggregate every repo with an open marathon into one rollup so the operator can see and
  sequence cross-repo work without opening each repo in turn — the precursor to the automated
  utils/hq/marathon-scan.sh that later replaced this hand-rolled pass.
---

# HQ MARATHON — 2026-07-06

## Status

| What was just completed | What's next |
|---|---|
| Manual cross-repo scan of 4 device-registered PDDA repos via the local Git Pulse Sync registry; 2 repos had an open, actionable marathon (xyz-3-agents-swarm, sleuth-app), rebalance-OS's `-B` file tracked but held by design. | Superseded by the automated `utils/hq/marathon-scan.sh` rollup (see `GLOBAL-HQ-MARATHON.md`) — this doc stays as the historical first pass, no further updates expected. |

## Source registry

The local Git Pulse Sync PDDA registry (path is operator/device-specific; surfaced via
`utils/hq/hq.sh registries`) lists 4 PDDA-compliant repos, device-partitioned:

| Repo | Marathon file | Status | In scope? |
|---|---|---|---|
| rebalance-OS | `PROJECT/2-WORKING/MARATHON-2026-07-06.md` | **Completed** — all 3 lanes shipped + independently re-verified same session | ❌ closed |
| rebalance-OS | `PROJECT/2-WORKING/MARATHON-2026-07-06-B.md` (new, found on re-scan 2026-07-07) | **Held** — un-fired by design | 🟡 tracked, not fired |
| xyz-3-agents-swarm | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md` | **Active** | ✅ |
| sleuth-app | `PROJECT/2-WORKING/MARATHON-PLAN-2026-07-06.md` → regenerated `MARATHON-PLAN-2026-07-07.md` | **Active** | ✅ |
| LTVera-Pandas | none found | no `PROJECT/2-WORKING/*marathon*` doc, no `ROADMAP.md` commit in the last 24h | ❌ none |

Two repos have an open, actionable marathon today; rebalance-OS's new `-B` file is tracked
but intentionally not treated as fireable (see below). Everything below is a `--dry-run`
preflight unless noted otherwise — **fixes applied so far are documentation/promotion
only (see Actions taken), no builds fired.**

## rebalance-OS — MARATHON-2026-07-06-B.md — new since the first pass, HELD by design

Re-scan on 2026-07-07 found a **second** marathon file in rebalance-OS,
`PROJECT/2-WORKING/MARATHON-2026-07-06-B.md`, sitting alongside the already-Completed
`MARATHON-2026-07-06.md`. Its own frontmatter status is **`Held (un-fired — awaiting
operator go + XYZ-side export confirmation)`** — this is not a queued-and-forgotten lane
like the others found so far, it's a *deliberately* gated hold, and the doc says so
explicitly: *"Lane A is a discovery/authoring spike... It should be run deliberately, not
swept into an auto-driven wave."* No `swarm-preflight` was run against it — it isn't a
code-to-spec build lane, it's a doc-only findings write-back.

| Lane | Scope | State |
|---|---|---|
| A — GH-102 Phase 5.0 contract-lock spike | Confirm/deny the XYZ deterministic disposition export, lock the emit schema, write findings back into `GH-102-XYZ-REBALANCE-INTEGRATION.md`. Doc-only, no code. | **Held** — ready to release, but not fired; needs an explicit operator go |
| B — GH-102 Phase 5 Reb collector | `register_collector("xyz_disposition", …)` projection + disagreement detector | **Gated** behind Lane A locking the contract — not evaluated until then |

**HQ recommendation:** leave this HELD. It is explicitly scoped as an operator-judgment
release, not an automation candidate — unlike the ghost lanes above, this isn't drift to
correct, it's a hold to respect.

## sleuth-app — Wave 1 (6 lanes) — RESOLVED (promoted 2026-07-06)

Originally all BLOCKED (exit 6) — *"issue #N has no in-repo GH-N-*.md capture doc under
`PROJECT/2-WORKING/`."* Each doc already carried an embedded Swarm Preflight Contract, so
this was a one-line promotion (`git mv`, HQ's own `promote` pattern), not missing
authorship. **Promoted** (sleuth-app commit `195a889`); post-promotion re-preflight:

| Lane | Doc | Verdict after promotion |
|---|---|---|
| #351 Flaky fixed-port test | `PROJECT/2-WORKING/GH-351-FLAKY-PORT-TEST.md` | ✅ **READY (exit 0)** |
| #352 Trim AGENTS.md redundant inventory | `PROJECT/2-WORKING/GH-352-TRIM-AGENTS-MD.md` | ✅ **READY (exit 0)** |
| #348 Adopt Blend philosophy into GUIDING-PRINCIPLES.md | `PROJECT/2-WORKING/GH-348-ADOPT-BLEND-PHILOSOPHY.md` | ✅ **READY (exit 0)** |
| #349 Hyphen/space command normalization | `PROJECT/2-WORKING/GH-349-HYPHEN-COMMAND-NORMALIZATION.md` | ✅ **READY (exit 0)** |
| #338 show-me reactable output | `PROJECT/2-WORKING/GH-338-SHOWME-COMMAND.md` | ✅ **READY (exit 0)** |
| #355 P3 Phase 2 baseline-import | `PROJECT/3-COMPLETED/GH-355-P3-BASELINE-IMPORT.md` | ⚠️ Was **STALE** — already shipped 1.4.211 (`b3075d7`), prod-validated. **Closed out** (sleuth-app commits `a7e2315`/`f50ae6c`): doc marked Shipped + moved to `3-COMPLETED`, `ROADMAP.md` lane count/cutover-status corrected, `marathon-plan.sh` regenerated (`MARATHON-PLAN-2026-07-07.md`, Wave 1 now `#338‖#348‖#349‖#351‖#352`). Not a fireable lane — nothing left to build. |

## sleuth-app — Wave 2 (1 lane) — READY

| Lane | Doc | Verdict |
|---|---|---|
| first-time-user-remediation | `PROJECT/2-WORKING/FIRST-TIME-USER-REMEDIATION.md` | ✅ **READY (exit 0)** |

Preflight's own suggested fire command (packet not yet materialized — this was `--dry-run`):

```bash
# from inside sleuth-app, after a non-dry-run preflight writes the packet:
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=first-time-user-remediation .xyz/relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact src/reminders-display-utils.js,src/reminders-module.js,data/static/ai/command-catalog.json,tests/catalog-regex-aliases.test.js \
  --pre-advance-cmd 'npm run validate:commands && npx jest catalog-regex-aliases' \
  --require-clean
```

Scope (Phase 1 only, per the doc): Q5 empty-state reminders copy + Q1 command-catalog RegexAlias
for capability-phrasing → `help`. Gate: `npm run validate:commands && npx jest catalog-regex-aliases`.

## xyz-3-agents-swarm — Wave 1 (1 lane) — GHOST, not real work

| Lane | Doc | Verdict |
|---|---|---|
| relay-to-issue-skill | ROADMAP.md still points to `PROJECT/2-WORKING/RELAY-TO-ISSUE-SKILL.md` | ⚠️ **ledger drift — nothing to build** |

The doc actually shipped 2026-07-05 (`c7f8431`, *"verify gh-issue-create end-to-end; project
complete"*) and moved to `PROJECT/3-COMPLETED/RELAY-TO-ISSUE-SKILL.md` (frontmatter `status:
Shipped`). `ROADMAP.md` line 121 was never flipped — it still reads 🟡 with *"Remaining: operator
`install.sh` + one un-sandboxed live `gh issue create`"* and points at the dead 2-WORKING path.
`marathon-plan.sh` read that stale ledger line and queued a lane for work already done. There is no
code left to preflight or fire; the fix is a ROADMAP.md housekeeping edit (mark it ✅/closed, repoint
the link) followed by re-running `utils/marathon-plan.sh` so the ghost drops out of the plan.

## Net result (as of the 2026-07-07 re-scan)

Of 8 originally-nominal lanes across the two open marathons: **6 are now genuinely ready
to fire** (sleuth-app `#351/#352/#348/#349/#338` + `first-time-user-remediation`), **1 was
a ghost, now closed out** (sleuth-app `#355`), **1 is still an open ghost**
(xyz-3-agents-swarm `relay-to-issue-skill`, not yet fixed). Plus rebalance-OS's new `-B`
marathon, tracked but deliberately Held, not counted as queued work.

## Recommended next step (operator decision — nothing below has been executed)

1. Fire any/all of sleuth-app's 6 ready lanes — re-run each preflight without `--dry-run`
   to materialize the packet, then run `marathon-drive.sh` from inside sleuth-app.
2. Housekeeping-fix xyz-3-agents-swarm's `ROADMAP.md` relay-to-issue-skill line, then regenerate
   `utils/marathon-plan.sh` so that ghost lane stops resurfacing — still open, not yet done.
3. Leave rebalance-OS's `MARATHON-2026-07-06-B.md` alone until the operator releases Lane A.

## Automation gap this pass surfaced

Two manual HQ passes (2026-07-06, 2026-07-07) have now each found real drift (BLOCKED-only-
on-location docs, STALE ghost lanes with no code left to build, a brand-new Held marathon
appearing between passes) that a repeatable script would catch for free. **No such script
exists yet** — `utils/hq/` only has `hq.sh`, `hq-lib.sh`, and `rollup.sh` (a ROADMAP-only
Obsidian summarizer, not marathon-aware, not preflight-aware). Filed as
[#158](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/158) —
project plan: [GH-158-HQ-MARATHON-SCAN.md](../1-INBOX/GH-158-HQ-MARATHON-SCAN.md), queued
in `ROADMAP.md`'s Queue/parked intake, not yet built.

## Non-goal (this round)

Actually driving `marathon-drive.sh` inside another repo from an orchestrator sitting in this one.
GH-88 explicitly deferred "cross-repo launching" to v1.1 (`PROJECT/3-COMPLETED/GH-88-CROSS-REPO-MARATHON-MONITOR.md`).
This file only aggregates + preflights across repos; firing still means running the fire command
inside each target repo, by design, until that v1.1 seam gets built.
