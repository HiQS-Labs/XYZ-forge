---
title: Nothing deterministic checks whether an inline code comment is still true — extend the dead-reference resolver past the doc boundary
status: Proposed (1-INBOX — not yet active)
created: 2026-09-03
owner: noelsaw1
gh_issue: 414
source: https://github.com/HiQS-Labs/XYZ-forge/issues/414
doc_type: feature
complexity: 2
risk: 1
effort: 2
phases: 2
ratings_provisional: true
non_goals:
  - Detecting semantic comment-vs-code drift. This verifies that references RESOLVE, nothing more.
  - Building a new checker; the dead-reference resolver already exists and is scoped to markdown.
related:
  - GH-406 (umbrella — external review by Russ K.)
  - GH-413 (adds the two dropped ADRs to KEEP_FILES; this catches the class permanently)
goal: >
  Extend pdda-check-governance's dead-reference resolver to source comments and run it against
  the built artifact as well as the source tree, so a kernel comment citing an absent ADR fails a
  gate instead of staying green forever.
---

# GH-414: comment references are unchecked

> **1-INBOX capture**, not an active-work doc. On promotion, create the status table.

## Why this is worth more than the nit that produced it

Russ K. asked whether anything catches comment rot. It does not — it is culture and review. His
finding 1.5 (`src/events.js:8`, `:36`, `src/project.js:59` cite two ADRs the build drops) is not
one broken link; it is proof that the repo's best documentation has **zero** deterministic
protection. Fix 1.5 by hand and it silently regrows.

## The check already half exists

A live PDDA run at HEAD emits three markdown dead-reference warnings from `README.md`. So the
resolver works — it stops at the document boundary. Pointing it at source comments is closer to a
configuration change than a new check, which makes the highest-leverage umbrella item one of the
cheapest.

Second-order finding: those markdown warnings have been in the stream long enough to appear in an
external review. **A warning nobody acts on is functionally not a check** — so triaging the
existing stream is in scope, not just adding to it.

## Phases

1. Extend the resolver to path-shaped references in source comments; run against both trees. The
   public-tree run is the one that catches 1.5, since the defect is created by the build's
   `decisions` drop rather than by the source.
2. Triage the existing markdown warning stream to zero or explicit acceptances.

Red control: the two ADR citations in `src/events.js` fail pre-fix.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "utils/pdda/pdda.sh", "pattern": "comment_reference" } ],
  "artifacts":   [
    "utils/pdda/pdda.sh",
    "test/gh414-comment-reference-check.sh",
    "test/baselines/GH-414-negative-control.md"
  ],
  "remediation": { "source": "issue#414", "criteria": "a source comment citing a non-existent path fails the check, and the check runs against the built artifact as well as the source tree" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
