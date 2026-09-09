---
title: Flightdeck — session context and status mitigation
status: Planned — awaiting independent plan QA
created: 2026-09-08
updated: 2026-09-08
owner: Codex
goal: Preserve session intent and show existing Claude session status through passive incoming connectors.
doc_type: project
gh_issue: 494
roadmap_exempt: true
source: https://github.com/HiQS-Labs/XYZ-forge/issues/494
reversibility: Costly — cross-repository read contract; optional additive rollout and disable rollback
---

# Flightdeck — session context and status mitigation

## Status

| What was just completed | What's next |
|---|---|
| Existing reader verified against all three screenshot sessions; consumer context loss reproduced. | DeepSeek V4 Pro plan QA, then implement this Phase 4 mitigation through the existing owners. Runtime implementation has not started. |

## Table of contents

- [Phase 1 — Preserve and publish](#phase-1--preserve-and-publish)
- [Phase 2 — Consume and prove](#phase-2--consume-and-prove)

This is the bounded Phase 4 follow-up to [the parent plan](GH-494-FLIGHT-DASHBOARD.md), not a replacement roadmap. Grounding and observed values: [Recon Map](recon-flightdeck-session-context.md). RB denotes canonical RebalanceOS; FD denotes this repository. Re-anchor both HEADs before implementation. Predictions below are acceptance targets, not delivered behavior.

The bet: the existing authenticated Claude session reader remains usable for these Remote Control sessions. Its endpoint is not a guaranteed public contract. A compatibility failure must degrade this optional plugin, not the rest of Flightdeck. No new collector, transcript crawler, hook, database, model summarizer, independent scheduler, or GitHub fetcher. No Swift work, mockup changes, CI/CD integration, or automatic merging in this phase. Production styling continues to use existing tokens.

## Phase 1 — Preserve and publish

**Goal:** Existing producers publish bounded session facts without losing intent or confusing failed collection with zero sessions.

1. Extend RB `src/rebalance/ingest/claude_cloud.py` using its existing `_fetch_raw`/authentication path, leaving existing daily grade/ranking behavior compatible. Add a snapshot-specific read path that includes sessions still active regardless of creation day, plus sessions with events within the last two hours. Preserve `connection_status` alongside title, remote ID, repo, origin, status bucket, worker state and UTC event time. Bound requests to three pages/300 records, five seconds per request, no immediate retries; expose partial coverage when capped or pagination fails. Unsupported enums remain raw facts with normalized state unknown. Do not call the current error-to-empty `sessions_for_day` wrapper for export. -> Old active fixtures remain present; auth failures are distinguishable from a successful empty result.
2. Add one producer-owned export function alongside that reader: a version-1 JSON envelope with `source`, `device_id` when known, `attempted_at`, `last_success_at`, `coverage` (complete/partial), `error_code`, and `sessions`. Rows carry `observed_at`, remote ID, optional explicit local ID mappings with provenance, title, repo, connection and worker fields. Credentials, transcript bodies and raw API payloads are excluded. Publish through a temporary sibling plus atomic replace, restrictive user-only file permissions; serialize concurrent runs with the existing producer locking mechanism if available, otherwise a single standard-library file lock. A failed attempt retains previous successful rows and timestamps while publishing failure metadata. A failed write leaves the previous whole file; age reveals the failure. -> Interrupted/concurrent writes never expose partial JSON or regress the success timestamp.
3. Reuse the existing producer scheduling facility after inspecting its actual configured invocation and locking contract; record that exact integration in this doc before enabling. Configure a 120-second target for this opt-in export, independently of ranking enablement. Export filename/location is producer-configured; Flightdeck receives it through connector configuration, never a machine-hardcoded path. If no existing scheduler can meet this, leave manual export supported and explicitly report freshness unavailable rather than install another scheduler. -> One owner invokes the existing reader; dashboard requests never invoke it.
4. Preserve CLIO context in FD `read_clio` as additive fields: earliest available intent and timestamp, latest prompt and timestamp, optional authoritative session title, and explicit history coverage. Keep legacy `task` for compatibility but stop using it as the sole display label. Earliest available is not called original when the bounded read may omit history. Keep existing issue-context replacement semantics; label initial intent separately so a later topic change is not hidden. -> An acknowledgment updates latest prompt without erasing initial intent, while a new issue remains the current issue.
5. Exact joins are optional enrichment, not a prerequisite for showing remote sessions. Reuse existing producer metadata parsing only after locating and reading its title/bridge handling. If that seam exists, extend it to emit explicit local UUID/remote bridge ID, device, and source record provenance; if absent, defer that enrichment and show unmatched remote sessions separately with count coverage marked partial. Do not add a scanner just to recover two known mappings. Never join by title, repo alone or guessed time proximity. Conflicting/resumed bridge mappings remain ambiguous until uniquely attributable. -> Two explicit matching fixtures coalesce; Needle-style unmapped and ambiguous fixtures remain visible without claiming exact distinct-session totals.

### Phase 1 — QA checklist

<!-- phase-qa -->
- [ ] DRY/SOLID: existing reader/auth/export ownership retained; small functions, additive optional fields, no vendor dependency in Flightdeck core or speculative inheritance.
- [ ] Observability: sanitized source/error code, attempted/success/observation timestamps and coverage appear in the envelope; no token, prompt body or raw payload logging.
- [ ] Producer fixtures run for old active, fresh idle, disconnected, unknown enum, complete empty, cap, failed later page, auth failure, interrupted/concurrent publish and existing daily-grade compatibility.
- [ ] Consumer context fixture runs for acknowledgment, topic switch, bounded-history truncation and separate same-repo sessions. Mutating back to latest-only context must fail the acknowledgment test.
- [ ] Exact scheduler and optional metadata reuse seams are read and recorded before their integration; unsupported capability stays explicit. This gate does not permit a new collector.

## Phase 2 — Consume and prove

**Goal:** Cards and handoffs expose session context and current status independently of last-hour activity.

6. Register a passive incoming adapter in FD `connectors.py` using existing config/contract conventions. Read only the configured versioned snapshot with byte/row bounds; validate structure, UTC timestamps and version. Core aggregation in `aggregate.py` coalesces only explicit unique source-qualified mappings, retains both IDs and provenance, and reports omitted rows at existing lane caps. Invalid/missing/unsupported data leaves other plugins operating. -> A fixture-compatible file works without Rebalance installed, and network-disabled dashboard reads still work.
7. Extend production `web/flightdeck/app.js` projections and handoff text: authoritative title when available, otherwise earliest available intent with a coverage label; latest instruction separately. Repo and issue views show connected/disconnected and working/idle/unknown as separate facts. Active remote sessions remain visible even with no prompt during the last hour. Do not invent issue associations for sessions lacking explicit references; show an unassigned session lane in repo details. Count last-hour activity separately from observed sessions; unmatched records are labeled observed records/partial distinct-session coverage. Worker running is not a completed milestone and never resets the meaningful-progress clock. Preserve navigation, breadcrumbs, Esc, focus and token styling. -> Named sessions appear without collapsing same-repo lanes or falsely assigning progress/issues.
8. Set passive client reads to 30 seconds when this feature is enabled; producer target 120 seconds plus bounded fetch budget 15 seconds gives a predicted <=165-second healthy observation-to-display delay. Staleness is computed at display time from each row's observation time: after 180 seconds, all live assertions become unknown/stale, including browser last-good cache and failed/offline fetch paths. Keep the last observed value labeled historical. Successful absence only removes a prior row when coverage is complete; partial/error results cannot assert session closure. -> Fake-clock and browser tests cross the freshness boundary even if no new successful response arrives.
9. Run the existing manually invoked experimental harness with added fixtures; do not wire it to CI/CD. Retain nonempty sanitized receipts and provenance in `TESTS-RESULTS/2026-09-08+GH-494/`, recording commands, SHAs and outcomes. Use disposable full clones for repository mutation-heavy gates. Include negative controls: restore latest-only overwrite, drop an old active session, merge by repo, and freeze a stale running badge; each relevant assertion must go red. Then run a bounded local pilot for three producer cycles, comparing source snapshot with cards/handoff, including an observed or simulated disconnect/reconnect. -> Actual measured healthy refresh <=180 seconds and honest stale/partial states; otherwise keep plugin disabled and record the failed target.

### Phase 2 — QA checklist

<!-- phase-qa -->
- [ ] DRY/SOLID: optional plugin remains replaceable, central join/presentation rules have one owner, existing connector implementations require no dummy methods.
- [ ] Observability: freshness/coverage and exact source IDs explain each badge and join; unavailable is not zero, idle is not disconnected, working is not progress.
- [ ] Manual harness executed with nonempty input, success cases and failing negative controls; evidence and provenance retained together.
- [ ] UI verified in Layouts A/B/C, narrow and monitor sizes; initial intent, latest prompt, unmatched sessions, issue context, handoff, breadcrumbs and Esc remain usable.
- [ ] End-to-end pilot verifies measured refresh and offline expiry; no request-side collection, no new scheduler/hooks, no CI/CD changes, frozen mockups unchanged.
- [ ] Update status and issue with measured outcome before calling the phase done; independent code QA remains required after plan approval.

## Blast radius, rollback and stop rules

Cross-repo export/identity semantics are Costly: consumers of RB daily grading/ranking must remain compatible; Flightdeck lane counts, cards and handoffs can change. Shield: producer export opt-in and adapter independently disableable; no source ownership migration. Tripwire: any false join, credential/payload leak, stale live claim, existing grading regression or refresh target failure disables the plugin before broader rollout. Rollback: disable export invocation and adapter, retain original CLIO fields and immutable source logs; remove optional cache only after confirming it is regenerable. Context display changes are Easy to revert independently. No destructive migrations or remote deployments are required.

Use debug-mantra during execution: reproduce, trace the failing path, falsify the hypothesis, cross-reference evidence. Each fetch cycle has three requests maximum, no nested retry loop. Pilot ends after three cycles; failures are reported, not retried indefinitely. Plan review is capped at three reviewer rounds with a documented disposition per finding. New producer work outside the grounded seams requires bounded recon before implementation, not speculative scaffolding.
