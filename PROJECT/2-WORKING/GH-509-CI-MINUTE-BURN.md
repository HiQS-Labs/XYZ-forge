---
gh_issue: 509
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/509
title: "GH-509 — tier CI to stop per-push Actions minute burn"
status: active — PR #511 under revision
created: 2026-08-11
updated: 2026-08-11
owner: noel
branch: feat/gh509-optimize-ci
doc_type: infrastructure
effort: 3
complexity: 3
risk: 3
phases: 1
ratings_provisional: false
roadmap_exempt: false
goal: >
  Keep the complete regression inventory while routing fast, documentation, and full integration
  gates so private-repository Actions minutes are spent at the boundary that needs them.
---

# GH-509 — tier CI to stop per-push Actions minute burn

## Status

| What was just completed | What's next |
|---|---|
| PR #511 was rebuilt on current `development`; its accidental GH-485 stack was removed. CI now classifies docs, fast, and full routes through a tested helper, with the complete local gate green. | Update PR #511 and observe its GitHub-hosted full route; after merge, sample 30 runs before graduating the routing table. |

## Problem

The prior workflow ran the complete acceptance manifest on every PR update and again on every push to
`development` or `main`. A 2026-08-11 audit measured roughly 976 rounded runner minutes across 100
runs in 66 hours. The complete suite is valuable; treating it as the default feedback loop is not.

## Decision

PDDA remains a CI gate because project documents are resumable runtime state, but it is path-routed:

- documentation and PDDA changes run PDDA before merge
- every full integration and manual route runs PDDA
- code-only fast PRs omit PDDA, avoiding the roughly 2.5-minute scan when no owned document changed

Pull requests touching the Tick kernel, relay containment, Python-authoritative twins, worktree
safety, or CI itself fail closed into the full suite before merge. Lower-risk code changes run a
fixed safety smoke set plus a directly matching changed-area test when one exists. Docs-only changes
keep the required job present, avoiding a path-skipped check that can remain pending indefinitely.

**Bet:** the path classifier is narrower than “all code,” so an incorrectly omitted critical path
could receive only the fast gate. The classifier and its fail-closed cases are deterministic and
tested; any new coordination or containment surface must join its critical-path table. Reversibility
is **Easy**: route a path back to `full` or make PDDA unconditional without changing runtime code.
Revisit after 30 CI runs; graduate if critical PRs select `full`, code-only fast runs stay below three
minutes, and no post-merge-only defect appears. Otherwise widen the full-path table.

## Acceptance

- [x] Superseded PR runs use branch-scoped concurrency cancellation.
- [x] Docs-only changes skip the runtime regression suite without skipping the required job.
- [x] Tick/event, relay-containment, frozen-twin, worktree-safety, and CI changes select a pre-merge full gate.
- [x] The code-only fast-route whole-job budget is documented as less than three minutes.
- [x] Full coverage remains available on critical PRs, integration pushes, and manual dispatch; no daily full-suite burn is added.
- [x] Only exact duplicate checks are skipped; fixture and negative-control PDDA tests remain.
- [ ] Record the updated hosted Actions latency and a 30-run before/after minute sample.
- [ ] Verify the live PR route and required-check behavior on PR #511.

## Validation

| Check | Result |
|---|---|
| `bash test/ci-route.sh` | PASS — 15/15 route and fail-closed cases |
| `bash test/ci-workflow.sh` | PASS — 22/22 workflow contract checks |
| `bash test/pdda-roadmap-coverage.sh` | PASS — 11/11 fixture and negative-control cases |
| `bash test/pdda-local-checks.sh` | PASS — 9/9 fixture and repository cases |
| `utils/pdda/pdda.sh run` | PASS — 0 errors; existing advisory warnings only |
| `RELAY_SELF_SUFFICIENCY_SKIP=1 ./validate.sh` | PASS on `13b17be` — 185/185 shell suites plus 20/20 Python tests; current-base run reached 186/187, with its sole path-integrity fixture-literal finding fixed and rerun directly |
