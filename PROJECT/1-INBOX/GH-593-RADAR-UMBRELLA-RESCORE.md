---
title: radar re-scores whack-a-mole umbrellas — "solved" is a quiet score, not a closed issue
status: Proposed (1-INBOX — not yet active)
created: 2026-09-13
owner: noelsaw1
gh_issue: 593
source: https://github.com/HiQS-Labs/XYZ-forge/issues/593
doc_type: feature
complexity: 1
risk: 1
effort: 2
phases: 1
related:
  - "#591 — the umbrella whose chain (#421 → #425 → #546 → #584) showed 'closed' ≠ 'solved'"
  - "#293 — radar live checklist, the sink this extends"
  - "#442 — radar tracking issue"
non_goals:
  - No script, DB table, or third sink; radar's two existing sinks carry the state
  - No change to whack-a-mole's non-negotiables (read-only, one issue per run, never edit existing issues)
  - No change to radar's target-score formula for non-umbrella clusters
---

# GH-593 — radar re-scores whack-a-mole umbrellas

## Why

`whack-a-mole` files an umbrella for a recurring-defect cluster and says "re-run after the
sweep to confirm the score drops", but it is stateless: nothing records the score at filing
and nothing re-measures after the fix merges. "Umbrella closed" is the only completion
signal. #591's chain (#421 → #425 → #546 → #584) shows that is not "class solved" — two
closed fixes each exposed the next break. Radar's board has the same shape:
`RADAR-class-vendored-root-resolution` run 1 said "no consumer repo files an eighth"; runs
2 and 3 produced the eighth through twelfth (#293).

`radar` already owns persistence (immutable dated report + live checklist #293) and already
refuses to strike through on symptom disappearance alone. It does not know which clusters
have an umbrella and has no numeric quiet-threshold for calling a class retired.

## Asks (from the issue)

1. `skills/whack-a-mole/SKILL.md` — umbrella template's "Evidence and confidence" gains a
   fixed-key **Cluster signature** block: paths, error strings, member issues/commits, raw
   churn signals at filing (`reopens repeat_fixes reverts size comments open_days score`),
   run ID. whack-a-mole stays read-only.
2. `skills/radar/SKILL.md` — Lens 2 gains a signal: read open+closed `Umbrella:` issues,
   parse the signature, re-score against the current radar window with whack-a-mole's
   weights, counting only signals dated after the fix-merge date when one exists. Sink B
   gains `## Umbrellas — re-scored` with one line per umbrella:
   `#<n> — filed at <score> (<run>), now <score> (<window>), fix merged <date + PR | not yet> → holding | class survived`.
3. **Solved** = signature scores below 5 on two consecutive radar runs after the fix merged.
   A closed umbrella still ≥ 5 is marked `class survived — recommend reopening`; radar never
   closes or reopens anything.

## Acceptance (each must be able to fail)

- whack-a-mole's template renders a Cluster signature block; a body without one is a
  template violation.
- radar, run against this repo, produces a re-score line for #591 in the exact format —
  witnessed in the PR body with the actual line and the signals counted. Finding
  `Umbrella:` issues and emitting no line is a failure.
- Red control: a synthetic closed umbrella whose signature still matches ≥ 5 points of
  window activity is emitted as `class survived`, not struck through — shown in the PR body.
- radar's Guardrails hold: no writes beyond the two sinks, no issue closes/reopens.
- `utils/pdda/pdda.sh run` clean; docs-only route green.

## Rating rationale (2026-09-13)

`rated 60/55/50/80`. **sev 55**: consequence is a false "solved" on a recurring class — #591's
chain cost two fallback PRs (#543, #545) and four hand-written receipts before the pattern
was named; not a crash or data loss. **pri 60**: severity-led, plus the operator asked for
it now as follow-through on a live umbrella. **appeal 50**: neutral, no user preference
given. **effort 80**: two prose SKILL.md edits, no code, cheap. Recurrence window
2026-08-30 → 2026-09-13: 4 distinct issues in the #591 chain, 2 closed-then-superseded;
prior 14 days: the radar board's vendored-root target shows the same acceptance-never-
re-measured shape across 3 runs. Uncertainty: whether two consecutive radar runs is the
right quiet horizon (radar cadence is irregular — Aug 28, Sep 1, Sep 2).
