---
title: Flightdeck issue visibility — Recon Map
status: Complete — consumer repair verified; upstream capture gap recorded
created: 2026-09-08
updated: 2026-09-08
owner: Codex
goal: Preserve evidenced work context without inventing activity or a new collector.
doc_type: research
roadmap_exempt: true
gh_issue: 494
source: https://github.com/HiQS-Labs/XYZ-forge/issues/494
---

# Recon Map — issue visibility

## Status

| What was just completed | What's next |
|---|---|
| Consumer attribution/selection repaired; manual harness and browser verified. | Continue the experimental pilot; repair initial-prompt capture in the CLIO producer separately. |

## Scope and evidence

Verify tier; graph project XYZ-forge generation 2026-09-01T15:54:30Z does not cover this task clone's Flightdeck files. Symbol search returned no candidates; coverage reported missing paths for connectors.py, aggregate.py, manual_harness.py and app.js. Exact source reads replace graph evidence. Producer investigation used a bounded read-only recon agent. No source writer, sync, or replay was run.

At approximately 13:03 PDT on September 8, the live LTVera snapshot contained 19 lanes, 100 issues, 3 PRs and 100 events, but the UI selected only issue 255. This falsifies a single-card CSS/layout explanation and an empty-source explanation.

## Fail path and contracts

1. Existing CLIO tailer → prompt-log.jsonl → `read_clio`: full prompts are parsed before display truncation. References persist only until latest prompt minus ORIGINAL reference exceeds two hours. Continuous follow-ups in the same session therefore lose issue 440. Append ordering can also lose earlier context when files interleave.
2. CLIO PR URLs are ignored. A distinct Claude review session points to `/pull/442`; without resolving that PR through the existing cache, its issue lane is invisible.
3. Rebalance SQLite (read-only) → `read_rebalance`: first cached PR link wins, ordered by closes then lowest issue number. PR 442's title explicitly names GH-440 but its primary link becomes 83; PRs 425 and 438 similarly become 202 instead of title references 417 and 434. Arbitrary body mentions are not reliable primary task identity.
4. Git Pulse/Rebalance commits → aggregation deduplicates repo/SHA → events. Issue references in commit subjects are not associated with cards.
5. `issueCards` selects only issue updates or lane prompts less than 60 minutes old. It ignores PR and commit evidence. The same cutoff is appropriate for the timeline, not for preserving a workday's context. Card and drawer filters also disagree on multi-issue lanes.
6. Manual harness → aggregator assertions only. Fresh issue fixtures mask broken lane attribution; no production JavaScript selector is executed. A green snapshot check cannot prove visible cards.

## Independent upstream gap

The original Codex smoke-test prompt exists at source rollout line 10, timestamp 17:19:07.828Z, but is absent from CLIO. Its references mix PR numbers (427, 426, 429, 430, 439) with issues (314, 414, 421, 391, 332, 390); treating all eleven as issues would be wrong. The current installed capture filter accepts it in a read-only check. Installed `clio-codex-tail.sh:185–190` initializes unseen files at EOF; file birthtime precedes the first prompt by 626ms and launchd polls every 60 seconds. First-discovery loss is strongly supported, but initial cursor/time were not logged, so historical causation is not fully proven.

A producer repair should distinguish historical bootstrap from new root rollouts. Blind backfill is unsafe: child rollouts contain inherited, retimestamped prompts and subsequent parent session metadata. This consumer change does not mutate installed hooks, replay private prompts, or invent a replacement collector. Upstream work remains separate.

## Smallest safe repair and rollback

Easy to reverse: existing experimental consumer adapter and selector changes only. Preserve context across consecutive prompts with gaps at most two hours; explicit new references replace the old topic. Resolve PR intent from cached PR title references, falling back to explicit closes, not arbitrary mentions. Scope GitHub URLs to the repository. Select today's evidenced issues and open-PR context; label age/reason, retain a one-hour timeline. Share the production selector with the manual harness using a dependency-free ES module. Exercise real HTTP output and source-isolated negative controls. No CI/CD wiring. Reverting these application files rolls back the behavior; upstream data is read-only throughout.


## Verification outcome

The enhanced manual harness failed on the original continuous-session loss, then
failed separately on PR-lane resolution. With the repair it passes adapter,
HTTP, production-selector, lifecycle/time-boundary, source-preservation and
negative-control checks. The existing 16 focused Python tests pass. Browser QA
rendered fixture issues 332, 390, 421, 440 with two lanes on 440; its handoff drawer
opened and Escape closed it while retaining view C. Live browser QA at 13:13 PDT
rendered eight LTVera cards: 255, 417, 421, 431, 434, 440, 441, 443. Issue 440 has
two observed agent lanes and PR 442. Cached closed issues 314, 414, 391 and 332
are excluded. No replacement collector or CI/CD entry point was added.

Read-only source evidence remains bounded: Rebalance returns at most 2,000 cached
items, and the snapshot caps each repository's issue inventory at 100. An omitted
closed record cannot supply lifecycle certainty. Title links remain inference,
and an uncaptured prompt cannot establish an agent lane. The live UI made no
JavaScript errors; the fixture browser requested an absent favicon (404 only).
