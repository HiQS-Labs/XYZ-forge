---
gh_issue: 63
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/63
title: Self-healing harness — triage stage for inbound signals before GH-*.md capture
status: Proposed (1-INBOX — not yet active)
created: 2026-06-30
updated: 2026-06-30
owner: noel
doc_type: feature
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
non_goals:
  - Not rebuilding CI/lint/doc-hygiene scheduling — GH-61 already owns that
  - Not adding a new coordination primitive or changing relay containment
related:
  - relay-automation/README.md
  - ROUTER.md
  - PROJECT/PDDA.md
roadmap_exempt: false
---

# GH-63 · Triage stage for inbound signals before GH-*.md capture

**Why:** A review of an external "self-healing agent harness" doc against this repo's actual
architecture found most of its principles already implemented (deterministic proof-of-work gates,
separated grading, oracle-immutability, chaos/failure-state testing, adaptive-cadence scheduling).
One concrete gap: nothing classifies an inbound signal before a `GH-*.md` capture doc exists. Today
the issue-first SOP starts at "open a GitHub issue" — there's no triage step that decides an inbound
signal's severity/category before that.

## Status

| What was just completed | What's next |
|---|---|
| Issue [#63](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/63) opened, doc captured, parked in ROADMAP. | Confirm scope, promote to `2-WORKING`, then define the triage classification step. |

## Table of contents

- [Status](#status)
- [Checklist](#checklist)
- [QA gate](#qa-gate)

## Checklist

- [ ] Define a triage classification step that runs **before** a `PROJECT/1-INBOX/GH-*.md` capture
      doc is created — input: any inbound signal (a failing `validate.sh` test, a relay escalation
      record, a manually reported bug); output: a severity/category tag (bug / drift / enhancement /
      noise).
- [ ] Wire the triage step to reuse existing signal sources instead of inventing new ones: relay
      escalation records (`watchdog.sh` `parked_suspects[]`), `validate.sh` failures, and manually
      filed GitHub issues.
- [ ] Ensure triage output is a deterministic artifact (a tagged note or doc field), not just an
      agent's verbal claim — consistent with GUIDING-PRINCIPLES.md's proof-of-work bar.
- [ ] Document the triage step in `ROUTER.md` routing hints so a cold agent finds it before
      hand-rolling issue capture.

## QA gate

- [ ] A synthetic bad signal (e.g., an injected `validate.sh` failure) is correctly classified and
      produces a deterministic, inspectable triage artifact.
- [ ] No triage path bypasses the issue-first SOP (still opens a `GH-*` issue before `2-WORKING`
      promotion) or writes outside its allowlisted scope.
