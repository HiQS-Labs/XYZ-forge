---
gh_issue: 836
source: https://github.com/HiQS-Labs/XYZ-forge/issues/836
title: "CI refactor: trim the measured gate hotspots (gh549 race leg and board-reconcile legs, gh436 parity double-run, gh649 /tmp bug); take the tier decisions on hosted Small numbers"
status: Proposed (1-INBOX — not yet active)
created: 2026-09-26
updated: 2026-09-26
owner: operator (via /start-task)
doc_type: fix
non_goals:
  - New suites, registry entries or gate machinery (AGENTS.md, No new tests).
  - Moving gh549 or gh436 out of Small; D1 is the operator's decision, taken on hosted numbers.
  - Rewriting gh549 in-process or gh436 on fixture templates (deferred in #836).
related:
  - "#835 — the gate-timing snapshot and its three profiling reviews (closed as completed)"
  - "#831 — the three-tier gate; its Phase 3 hosted Small evidence is still owed"
goal: >
  The hosted Small run and the full gate get cheaper where the profiling measured the cost, with every
  trimmed suite's red controls still firing and the same coverage on the same landings.
---

# GH-836 — trim the measured gate hotspots

## Status

| What was just completed | What's next |
|---|---|
| Captured from #835's profiling, and parked and rated in the roadmap ledger. | Recon: trace `gh549` legs 21e and `rr`, `gh436`'s parity guard, and `gh649`'s resolver check. Then promote to `2-WORKING` with the plan. |

## Idea

The canonical statement is [#836](https://github.com/HiQS-Labs/XYZ-forge/issues/836): its findings table, plan
steps 1–3, decisions D1–D3, non-goals and acceptance. This capture points there and does not restate them.

## Rating — 2026-09-26: `70/45/50/70` (pri/sev/appeal/effort)

- **Severity 45.** No crash or data loss. The cost is time: `gh549` and `gh436` are about 12 of the hosted Small
  run's ~18 minutes, and every docs, ledger and skill landing pays it.
  - One real defect: `gh649` goes red on any clone under the `/tmp` symlink, a false failure in the gate
    (GLM's red log, `TESTS-RESULTS/2026-09-26+GH-835/full-gate-b2c307b4-tmp-red.log`).
- **Priority 70.** Gate cost is the operator's current focus. The 14-day window (2026-09-12 to 09-26) shows the
  same class repeatedly:
  - #802, #828's 79-minute reconcile failure, #831 and #835;
  - the operator asked for this work directly.

  The window before it (08-29 to 09-11) was not searched, so the trend is **unknown**, not rising.
- **Appeal 50.** Neutral; the operator gave no score.
- **Effort 70.** Cheap: edits to three existing suites, with no routing or runner change. The cost is witnessing
  red controls and taking same-device before/after timings.
