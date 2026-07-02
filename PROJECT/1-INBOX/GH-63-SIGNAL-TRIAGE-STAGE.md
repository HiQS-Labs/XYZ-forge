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

## Classification rubric — DRAFT (operator to confirm before the lane fires)

A deterministic decision function keyed on the signal's **source + structured markers** (never
free-text sentiment), so identical input → identical tag. **First match wins**, in this order:

1. **`noise`** — the signal **duplicates an already-open GH issue** (dedupe by issue number / title
   slug), OR is an informational-only record with no failure and no parked/drift marker. Already
   tracked or nothing to act on → drop before capture.
2. **`bug`** — a deterministic failure of existing behavior: a `validate.sh` test **FAIL**, a
   canary/fixture rejection, or a relay **containment revert (exit 6)**. Source is a failing gate.
3. **`drift`** — reality diverges from declared state without a hard failure: a `watchdog.sh`
   `parked_suspects[]` record (stalled/parked turn), a `pdda issue-doc-sync` / roadmap-coverage
   mismatch, or a `dependency.drift` signal (GH-68).
4. **`enhancement`** — a manually filed request/idea with **no** failing gate and **no** drift marker
   (net-new capability).

**Output artifact (default):** an inspectable JSON note printed to stdout **and** written to a
non-coordination path (e.g. `relay-system/triage/<signal-id>.json`) — `{signal_id, source, category,
severity, evidence, dedupe_of?}`. NOT a `.tick/` record (keeps the coordination log clean, GP #2), NOT
a bare verbal claim (GP proof-of-work bar). `severity` is derived: `bug`→high, `drift`→medium,
`enhancement`→low, `noise`→drop.

> **Operator confirm:** the four buckets + this precedence + the artifact path. Adjust here, then the
> lane implements exactly this.

## Swarm Preflight Contract

Consumed by `utils/swarm-preflight.sh`. Same-repo build (`target.ref: main`). **Independent leaf-util
zone** (agy-safe) — new `utils/signal-triage.sh` + test + a `ROUTER.md` hint; touches no kernel file.
Gate is a new test.

```json
{
  "target":      { "repo": ".", "ref": "main" },
  "gate":        "bash test/signal-triage.sh",
  "fix_probes":  [ { "type": "path_absent", "path": "utils/signal-triage.sh" }, { "type": "grep_absent", "path": "ROUTER.md", "pattern": "signal-triage" } ],
  "artifacts":   [ "utils/signal-triage.sh", "test/signal-triage.sh", "ROUTER.md" ],
  "remediation": { "source": "GH-63#classification-rubric", "criteria": "New utils/signal-triage.sh: a deterministic, side-effect-free classifier implementing the rubric above (first-match noise/bug/drift/enhancement keyed on source+markers) that ingests ONE inbound signal from an existing source (a validate.sh failure record, a watchdog parked_suspects[] entry read structurally, or a manual issue stub) and emits the JSON triage note (stdout + relay-system/triage/<id>.json), never a verbal claim; identical input -> identical tag. It runs BEFORE any GH-*.md capture and MUST NOT bypass the issue-first SOP or write outside utils/ + the triage note path. Add a ROUTER.md routing-hint line. NEW test/signal-triage.sh feeds a synthetic failure + a parked_suspect and asserts deterministic tags + no GH-*/2-WORKING side effects; wired into validate.sh. GH-63 marker comment. SCOPE LOCK: do NOT touch relay-turn-lib.sh/bin/tick/relay-drive.sh/watchdog.sh or GH-61 scheduling." },
  "lanes":       { "agy_safe": [ "utils/signal-triage.sh", "test/signal-triage.sh", "ROUTER.md" ], "orchestrator_only": [] }
}
```
