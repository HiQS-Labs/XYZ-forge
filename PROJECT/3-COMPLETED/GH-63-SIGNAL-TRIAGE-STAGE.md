---
gh_issue: 63
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/63
title: Self-healing harness — triage stage for inbound signals before GH-*.md capture
status: Closed — Ready (rubric CONFIRMED + contracted — fully-ready lane)
created: 2026-06-30
updated: 2026-07-02
owner: noel
doc_type: feature
complexity: 2
risk: 2
effort: 2
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

## Classification rubric — CONFIRMED 2026-07-02 (decided by GUIDING-PRINCIPLES)

A deterministic decision function keyed on the signal's **source + structured markers** (never
free-text sentiment), so identical input → identical tag. **First match wins**, in this order:

1. **`noise`** — the signal **duplicates an already-open GH issue** (dedupe by issue number / title
   slug), OR is an informational-only record with no failure and no parked/drift marker. Already
   tracked or nothing to act on → drop before capture. *(Dedupe-first is load-bearing per GP #2 — a
   duplicate signal must never spawn a second issue.)*
2. **`bug`** — a deterministic failure of existing behavior: a `validate.sh` test **FAIL**, a
   canary/fixture rejection, a relay **containment revert (exit 6)**, **or a security-scan failure**
   (GH-64). Source is a failing active gate. A security finding is NOT a separate bucket (GP #7): it
   is a `bug` with `source: "security-scan"` recorded so it stays queryable + Attested.
3. **`drift`** — reality diverges from declared state without a hard failure: a `watchdog.sh`
   `parked_suspects[]` record (stalled/parked turn), a `pdda issue-doc-sync` / roadmap-coverage
   mismatch, or a `dependency.drift` signal (GH-68).
4. **`enhancement`** — a manually filed request/idea with **no** failing gate and **no** drift marker
   (net-new capability).

`severity` is derived from category: `bug`→high, `drift`→medium, `enhancement`→low, `noise`→drop.
Because the rules are deterministic, confidence is trivially 1.0 — no confidence field (GP #7).

**Output artifact (CONFIRMED):** an inspectable JSON note printed to stdout **and** written to the
**canonical** path `relay-system/triage/<signal-id>.json`:
`{signal_id, source, category, severity, evidence, dedupe_of?}`, where **`evidence` carries the
matched-rule id** (e.g. `"rule-2-bug / validate-fail: test/foo.sh"`) so every tag carries its receipt
and is independently auditable (GP Attested + #12).

- The standalone note is **canonical** — it is the *only* home that covers `noise`/dropped signals
  (which never become a `GH-*.md`), so a GH-doc field cannot hold them (the decisive constraint).
- When a signal **is** promoted to a `GH-*.md`, that capture carries a one-time **`triage_ref:`**
  pointer to the note — a reference, **NOT** a re-stored copy (GP #2: nothing canonical in two places).
- **Never** a `.tick/` record — `.tick/` is the coordination event log; a triage note claims/mutates
  no task, so writing it there would pollute the canonical projection (GP #2).

> **Decision basis:** both open choices (taxonomy+precedence, artifact path) resolved to this rubric by
> GUIDING-PRINCIPLES — #7 (fewest buckets; security folds into `bug`), #2 (dedupe-first; one canonical
> home; `.tick/` excluded), Relevant/Attested pillars (severity ranking; matched-rule receipt). Locked.

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
  "remediation": { "source": "GH-63#classification-rubric-CONFIRMED", "criteria": "New utils/signal-triage.sh: a deterministic, side-effect-free classifier implementing the CONFIRMED rubric (first-match, source+markers keyed): (1) noise = duplicates an already-open GH issue OR informational-only w/ no failure/parked/drift marker; (2) bug = a failing active gate — validate.sh test FAIL, canary/fixture rejection, relay containment revert (exit 6), OR a security-scan failure (source:'security-scan' recorded — NOT a separate bucket); (3) drift = watchdog parked_suspects[] / pdda issue-doc-sync|roadmap-coverage mismatch / dependency.drift (GH-68); (4) enhancement = manual, no failing gate + no drift. severity derived bug=high/drift=medium/enhancement=low/noise=drop; no confidence field (deterministic). It ingests ONE signal from an existing source (validate.sh failure record, a watchdog parked_suspects[] entry read STRUCTURALLY not text-grepped, or a manual issue stub) and emits the JSON note {signal_id,source,category,severity,evidence,dedupe_of?} to stdout AND the CANONICAL path relay-system/triage/<id>.json, where evidence carries the matched-rule id (e.g. 'rule-2-bug / validate-fail: test/foo.sh'); never a verbal claim; identical input -> identical tag; NEVER writes a .tick/ record. Runs BEFORE any GH-*.md capture and MUST NOT bypass the issue-first SOP; a promoted signal's GH-*.md carries a triage_ref: pointer to the note (a reference, not a duplicate). Write outside utils/ ONLY the triage note path + ROUTER.md hint. NEW test/signal-triage.sh feeds a synthetic validate.sh failure + a watchdog parked_suspect + a duplicate-of-open-issue + a manual stub, asserting the four deterministic tags, the matched-rule id in evidence, a canonical note written (no .tick/ write), and no GH-*/2-WORKING side effects; wired into validate.sh. GH-63 marker comment. SCOPE LOCK: do NOT touch relay-turn-lib.sh/bin/tick/relay-drive.sh/watchdog.sh or GH-61 scheduling." },
  "lanes":       { "agy_safe": [ "utils/signal-triage.sh", "test/signal-triage.sh", "ROUTER.md" ], "orchestrator_only": [] }
}
```
