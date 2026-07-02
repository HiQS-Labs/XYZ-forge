---
gh_issue: 85
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/85
title: marathon-plan undocumented-partial-completion false-positives on edit-existing-file lanes
status: Queued
created: 2026-07-02
updated: 2026-07-02
owner: noel
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
roadmap_exempt: false
non_goals:
  - Not removing the true-positive case (a genuinely partially-built lane like GH-44 must still be flagged)
  - Not a rewrite of marathon-plan's readiness model — a targeted signal fix only
related:
  - utils/marathon-plan.sh
  - test/marathon-plan.sh
---

# GH-85 — marathon-plan partial-completion false-positive

## Bug

`utils/marathon-plan.sh` (~line 439) flags a rated+contracted lane `state: partial` when ≥2 signals
fire. Two signals misfire for a normal **edit-existing-file** fix: `some-artifacts-exist` (an artifact
path exists merely because the fix *edits* it, not because output is built) and `changelog-mentions-it`
(a queued/contracted CHANGELOG note name-drops `#<n>`). Together they hold genuinely-0%-built lanes.

## Evidence (2026-07-02)

GH-45 (`LANE_MAX_ATTEMPTS` absent) and GH-30 (`XYZ_ARCHIVE_ROOT` absent) — both 0% built — were held
as `partial` because their contracts edit existing kernel scripts and CHANGELOG documents them. GH-44
(one canary already hardened) is a *fair* flag. So the heuristic can't distinguish "edited" from "done."

## Fix direction

Make `some-artifacts-exist` require a **new/created** artifact (e.g. the gate's NEW test path now
exists), and/or drop `changelog-mentions-it` as a partial signal, and/or require a stronger pair
(branch-matches-slug + tests-reference-slug). Keep GH-44-style true positives detectable.

## Definition of done

- An edit-existing-file lane documented in CHANGELOG is NOT flagged `partial`.
- A genuinely partial lane still is.
- `test/marathon-plan.sh` covers both.
