---
gh_issue: 85
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/85
title: marathon-plan undocumented-partial-completion false-positives on edit-existing-file lanes
status: Ready (rated + contracted — marathon lane)
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

## Swarm Preflight Contract

Consumed by `utils/swarm-preflight.sh`. Same-repo build (`target.ref: main`). **Independent zone** —
`marathon-plan.sh` is a planner (pre-pre-flight advisory), NOT a kernel-serialization file — so this
lane can run in the same wave as the other independent/shim lanes and never contends for the kernel
slot. Both artifacts already exist (a fix that extends them), and `test/marathon-plan.sh` is in the
`validate.sh` roster. agy-safe.

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash test/marathon-plan.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "utils/marathon-plan.sh", "pattern": "GH-85" } ],
  "artifacts":   [ "utils/marathon-plan.sh", "test/marathon-plan.sh" ],
  "remediation": { "source": "GH-85#fix-direction", "criteria": "In utils/marathon-plan.sh's undocumented-partial-completion detector (~line 439), stop the two false-positive signals from firing on an edit-existing-file lane: the `some-artifacts-exist` signal must require a NEW/created artifact to be present (e.g. the contract's gate test path, or an artifact the contract marks net-new) rather than ANY listed (existing, being-edited) path; and drop `changelog-mentions-it` as a partial-completion signal (a queued/contracted CHANGELOG mention is not evidence of completion). A genuinely partial lane (GH-44 style: real prior work on disk — e.g. a branch matching the slug AND tests referencing it) is STILL flagged. test/marathon-plan.sh adds two regression cases: (a) a rated+contracted edit-existing-file lane whose artifacts all pre-exist and whose #n is in CHANGELOG is classified READY (not partial); (b) a lane with genuine partial signals is still `partial`. Carries a GH-85 marker comment. Verify with `bash test/marathon-plan.sh`." },
  "lanes":       { "agy_safe": [ "utils/marathon-plan.sh", "test/marathon-plan.sh" ], "orchestrator_only": [] }
}
```
