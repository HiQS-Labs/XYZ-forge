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

## Engine refactors must survive suites that build objects with __new__

- **cue**: Adding a constructor-set attribute to `utils/py/_marathon_plan.py` `Engine` (or any class a suite instantiates with `Class.__new__` to reach one method).
- **lesson**: Before relying on a new `__init__` attribute inside an existing method, grep `test/` for `Engine.__new__` and read the new attribute with `getattr(self, NAME, default)`, then run `test/gh423-roadmap-render.sh` with the planner suites.
- **evidence**: TESTS-RESULTS/2026-10-29+GH-1257/gate.txt (gh423 failed on 030db02d with `AttributeError: 'Engine' object has no attribute 'RELEASES_DB'`; 409/409 after the getattr fix on 761389dd), https://github.com/HiQS-Labs/XYZ-forge/issues/1257
- **confidence**: medium — one observed failure; the three planner suites and a byte-for-byte parity check all passed and missed it, only the full gate caught it.
- **area**: gate
- **source**: https://github.com/HiQS-Labs/XYZ-forge/issues/1257
- **date**: 2026-10-29

## Wave packing treats a missing dependency record as satisfied

- **cue**: Adding lanes to `_marathon_plan.Engine._pack_waves` from a source the planner's own records do not cover (synthesized, seeded or provisional items).
- **lesson**: Give every known item a lookup record in the dependency view, admitted or not, with a state outside `DEP_RESOLVED`; an absent record reads as a satisfied dependency and packs the dependent early. Check with a held-prerequisite control and a red control that limits lookup to admitted lanes.
- **evidence**: TESTS-RESULTS/2026-10-30+GH-1261/controls.txt (`dep-prereq-held` and `dep-prereq-pending`: dependent unplaced; `red-dep-admitted-only-lookup`: dependent packed in wave 7), relay-system/2026-10-30/gh1261-plan-qa.md (R2, found at plan QA by probe before any code), https://github.com/HiQS-Labs/XYZ-forge/issues/1261
- **confidence**: medium — one design, caught at plan review and confirmed by a red control; no production run yet.
- **area**: marathon
- **source**: https://github.com/HiQS-Labs/XYZ-forge/issues/1261
- **date**: 2026-10-30

## A planner fed partial GitHub state treats closed rows as ready

- **cue**: Running `_marathon_plan.Engine` with `gh_force="off"` or a `gh_state_file` that covers only some issues (pilots, stubs, frozen inputs).
- **lesson**: A missing state reads as "unverified", not "closed", so a CLOSED ledger row stays a ready lane. Freeze state for every issue (one `gh issue list --state all`) before the planner computes; check with a red control that restricts the state file and watches the closed row return.
- **evidence**: TESTS-RESULTS/2026-10-30+GH-1270/controls.txt (`frozen-state-1075`: not active with full state; `red-seeded-only-state-1075`: active again), TESTS-RESULTS/2026-10-30+GH-1270/pilot-2c/wave-proposal.md (Closed section lists #1075), https://github.com/HiQS-Labs/XYZ-forge/issues/1270
- **confidence**: medium — one observed closed row in two pilots, confirmed by a red control.
- **area**: marathon
- **source**: https://github.com/HiQS-Labs/XYZ-forge/issues/1270
- **date**: 2026-10-30

## A replay reset in a gen4 clone deletes the campaign corpus

- **cue**: Replaying or re-checking cases inside the disposable clone that `gen4_campaign.py` fuzzed, after the run ends and before its outputs are copied out.
- **lesson**: gen4 keeps its corpus as untracked `.fuzz_corpus/` inside that clone and spares it only with `git clean -e .fuzz_corpus`; any plain `git clean -fd`/`-fdx` reset deletes it. Copy `.fuzz_corpus/` out first, or replay in a separate clone. Reset with gen4's own exclusion, and remove ignored dirs such as `temp/` too, or a replay starts from a different state than the campaign did.
- **evidence**: TESTS-RESULTS/2026-10-30+GH-1280/SUMMARY.md (Deviations 1 and D4), TESTS-RESULTS/2026-10-30+GH-1280/ev/12-phase3b.json, https://github.com/HiQS-Labs/XYZ-forge/issues/1280
- **confidence**: high — observed once, and the mechanism is in `utils/py/gen4_campaign.py:103`.
- **area**: ate
- **source**: https://github.com/HiQS-Labs/XYZ-forge/issues/1280
- **date**: 2026-10-30
