---
title: "GH-1015 observer receipt Recon Map"
status: Reference — bounded recon complete
created: 2026-10-10
updated: 2026-10-10
owner: Codex
goal: Record the existing observer and driver receipt boundary.
roadmap_exempt: true
---

# Recon Map — progress observer receipt attribution

Commit: 9a923f3cc131f432f2682e7a11f57d03597fb5df · Mode: graph+read · Lanes: one bounded lane in the main context.

## Status

| What was just completed | What's next |
|---|---|
| Bounded source and graph recon captured | Follow the parent GH-1015 plan for implementation and QA |

## Subject and change class

Local observer representation correction plus two presentation/comment nits. No authority change.

## Seams and call paths

| Seam | Location | Crosses | Breaks if |
|---|---|---|---|
| Target argument | relay-automation/marathon.sh:565,604 | same TARGET_ROOT to init and driver | one side rewrites logical spelling |
| Receipt producer | utils/py/marathon_drive.py:293,325,1138 | _result_arm from main stores abspath target | observer expects resolve |
| Receipt writer | utils/py/marathon_drive.py:161,253 | target_repo.path serializes stored path | representation differs |
| Attribution reader | relay-automation/marathon.sh:126,139,290 | exact schema/execution/phase/lane/target/token match | attributable logical path is rejected |
| Presentation | relay-automation/marathon.sh:185,238 | sorted emit versus unsorted missed-check | inconsistent presentation |
| Registry comment | validate.sh:144; test/gh609-sdlc-agent-gaps.sh | no runtime change; current existing SWE checks | wording describes obsolete universal contract |

## State and contracts

Init writes atomic context with product_root (line267); phase writes the run's identifiers/result pointer (line280); finish reads matching qualified receipt and increments verified_phases (line289). Context is read by emit/observe/terminal. Current driver target is os.path.abspath(args.target_root), line1394; _result_arm independently stores that same absolute logical form. Qualification still requires approved exit0, green gate exit0, reviewed candidate/head, attestation and no unmet checked acceptance. Observer never dispatches a worker.

## Build, failure and rollback

Launcher has inline Python payload and executes it directly with --progress-observer; this file is not a frozen Tier-A twin. Existing make-pkg.sh and tar listing contain 18 entries and no marathon.sh, so package is outside change scope. Reverting init representation/sort/comment is local. Unknown/malformed/foreign data continues to fail closed. Existing classifier routes launcher and validate.sh through full gate, only in a separate disposable full clone.

## Evidence and coverage

Graph project Users-noelsaw-Documents-GH-Repos-XYZ-forge ready; generation 2026-10-10T08:23:22Z at coverage check. _result_arm main inbound edge read; writer exact snippet read. No relevant trace pagination remained. Coverage reports marathon.sh partial at lines416,416,694; corresponding source ranges plus full embedded payload and launcher target forwarding were read. Driver and validate have no recorded gap (best effort, not proof of completeness). Task base source matches the inspected functions. Literal/config/package checks use direct source fallback.

## Unknowns

| Unknown | Why it matters | What would settle it |
|---|---|---|
| Live Flightdeck and provider consumer reaction to logical product_root spelling | Cannot claim end-to-end live integration | Separately authorized live run on deployed candidate |
| Complete recurrence/reopening history | Cannot infer growing incident velocity | Bounded history audit beyond keyword issue search |

## Current-state radius

Opted-in marathon observer context and stdout/run-log consumers, one driver receipt producer; presentation comment does not affect gate membership.
