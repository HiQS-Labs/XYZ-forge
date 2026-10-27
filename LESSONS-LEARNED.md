---
title: Lessons Learned
created: 2026-09-13
updated: 2026-10-25
source: umbrella #591 (chain #421 → #425 → #546 → #584); structured format #1218 (#1214 P1+6a)
tags: [ci, gates, reconciliation, provenance, lessons]
---

# Lessons Learned

Canonical repository lessons read back into relay and marathon turn prompts via `rtl_turn_prompt` (newest 5 non-superseded entries, warn-only). Append new entries at the bottom of this file through the evidence-gated writer steps in `/start-task`, `/marathon-cleanup`, and `defect-campaign`.

### Entry format

Each entry is a `## <short title>` heading followed by these field lines (and an optional narrative body below the fields using `###` subheadings):

```markdown
## <short title>
- **cue**: the kind of situation, not this task's facts
- **lesson**: an operation that can be checked, naming the component
- **evidence**: public links only
- **confidence**: high/medium/low, with the reason
- **area**: relay | marathon | pdda | gate | skills | releases
- **source**: the issue/PR
- **date**: YYYY-MM-DD
- **superseded-by**: optional (<issue/PR or replacement lesson title> when superseded)
```

### Writer & admission rules (prompt-enforced; no lint/guard/gate)

- **Admission:** refuse an entry whose `cue`, `lesson` or `evidence` is empty. Adoption or a merge alone is not evidence. Writing `NO_ENTRY` is a valid outcome.
- **Edit verdicts:** before drafting, write one row per changed component: `helped` / `hurt` / `no observed effect` / `confounded`. Use `confounded` when several things changed at once or a single run is the only support. A lesson resting only on `confounded` rows is refused.
- **Public evidence:** use repo-relative paths to committed `TESTS-RESULTS/` receipts, stable IDs, or public issue/PR/commit links. Never paste DB narratives, transcripts, credentials, hostnames or absolute paths.
- **ATE/fuzz evidence (Phase 6a):** it counts only after semantic replay, and the cited record must show the predicate and the clean/failing controls. A raw cluster, or a replay matched only by digest or exit code, is `confounded`.

---

## Ship a gate's producer in the same change you ship the gate

- **cue**: Tightening an existing verification gate, post-merge reconciler, or contract so it demands new evidence, a stricter match condition, or removes a fallback.
- **lesson**: Trace every caller of the tightened gate (`ci.yml`, `wave-reconcile.yml`, `githooks/pre-push`, `ci-local.sh`) and ship the producer change that writes and persists the required receipt in the same PR as the gate change.
- **evidence**: https://github.com/HiQS-Labs/XYZ-forge/issues/591, https://github.com/HiQS-Labs/XYZ-forge/issues/421, https://github.com/HiQS-Labs/XYZ-forge/issues/425, https://github.com/HiQS-Labs/XYZ-forge/issues/546, https://github.com/HiQS-Labs/XYZ-forge/issues/584
- **confidence**: high — observed across four linked incidents (#421 → #425 → #546 → #584) where requiring a `provenance.jsonl` receipt without wiring the producer broke every merge and catch-up sweep until the producer shipped.
- **area**: gate
- **source**: https://github.com/HiQS-Labs/XYZ-forge/issues/591
- **date**: 2026-09-13

### What happened

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

### The lesson

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

### How to apply

Before merging a change that makes an existing gate stricter (requires new
evidence, tightens a match condition, removes a fallback), trace every caller
that will hit the tightened path and confirm each one already produces what
will now be demanded. If any caller doesn't, the producer change ships in the
*same* PR as the gate change — not as a follow-up issue.
