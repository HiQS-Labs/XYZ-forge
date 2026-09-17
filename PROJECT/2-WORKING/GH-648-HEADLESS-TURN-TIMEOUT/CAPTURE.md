---
title: "GH-648 headless turn-timeout umbrella — marathon capture (two waves, nine lanes)"
status: "Planned — plan dry-run validated (9 phases in order); awaiting fire"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  Eliminate the idle/timeout whack-a-mole family: de-claim the progress oracle, unify kill
  aftermath contracts, and retire the per-symptom patches. Tracking lives in GitHub issue 648.
doc_type: project
gh_issue: 648
roadmap_exempt: true
source: https://github.com/HiQS-Labs/XYZ-forge/issues/648
reversibility: "Easy — each lane is an independent PR into development; the chain halts on a failed phase"
---

# GH-648 — headless turn-timeout umbrella (marathon capture)

## Status

| What was just completed | What's next |
|---|---|
| Umbrella #648 filed; radar class CLAIMED; plan + 9 briefs authored; consult agreement (codex + agy recheck) | Fire the marathon when no other marathon is in flight; lanes PR into development in chain order |

Tracking issue: https://github.com/HiQS-Labs/XYZ-forge/issues/648 (umbrella: root cause, lane list, wave structure, evidence grades).
Radar: #293 `RADAR-class-headless-turn-timeout` — CLAIMED by this plan (membership widened 2026-09-16, churn scan `20260916T190147Z`, score 25).

Two waves, nine sequential lanes (`MARATHON.yaml`, phases p1..p9, strict `depends_on` chain):
- **Wave 1 (p1–p6):** L1 oracle instrumentation + honest labels → L2 #241 token aftermath → L3 #276/#480 consult cap policy → L4 #285 revalidate → L5 #237 repro → L6 #521 muse attribution.
- **Wave 2 (p7–p9):** L7 #242 checkout aftermath → L8 #397 zero-output handback → L9 #369 regression baseline.

Consult provenance: codex AGREE-with-corrections (file:line citations spot-checked at HEAD `4ba9d504`); agy AGREE ×4 + FILE-UMBRELLA on the inline-evidence recheck (first pass void — foreign-tree grounding). Transcripts: `relay-system/2026-09-16/gh237-umbrella-confirm-124200/`, `gh237-agy-recheck-125141/`.
