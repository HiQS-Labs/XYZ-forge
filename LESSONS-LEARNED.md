---
title: Lessons Learned
created: 2026-09-13
source: umbrella #591 (chain #421 → #425 → #546 → #584)
tags: [ci, gates, reconciliation, provenance]
---

# Ship a gate's producer in the same change you ship the gate

## What happened

GH-421 wired the post-merge reconciler to run automatically. GH-425 made its
provenance check honest — it started *requiring* a `provenance.jsonl` receipt
naming the merged PR, instead of just checking the directory was non-empty.
Nothing was ever wired to actually write that receipt: the local pre-push hook
runs the full test suite and then discards the result. Every merge started
failing (GH-546), and the scheduled catch-up sweep had its own version of the
same gap (GH-584) — one unattributable legacy row aborted the entire run
instead of being logged and skipped.

Two "fixes" (#421, #425) each made the next failure appear instead of closing
the class of failure. Manual fallback PRs and hand-written receipts papered
over it for days before the pattern was named and given its own umbrella.

## The lesson

**A verification gate is only as good as the thing that produces the evidence
it checks.** Tightening a gate/contract and landing its producer are one
change, not two. Shipping the stricter check first and "wiring the producer
later" turns every caller in between into an incident — the gate is broken by
construction the moment it merges, and it will not announce that; it will just
start failing on real work.

**Corollary:** any step that computes a pass/fail result and then discards it
is a latent gap. If a gate might ever check for that result, the step that
first knows the answer is the one responsible for persisting it — not a
separate, later-added system.

## How to apply

Before merging a change that makes an existing gate stricter (requires new
evidence, tightens a match condition, removes a fallback), trace every caller
that will hit the tightened path and confirm each one already produces what
will now be demanded. If any caller doesn't, the producer change ships in the
*same* PR as the gate change — not as a follow-up issue.
