---
gh_issue: 64
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/64
title: Self-healing harness — security-scanning guardrail in the review chain
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
  - Not rebuilding CI/lint/doc-hygiene scheduling — GH-61 already owns that; this can plug into
    whichever CI job lands first
  - Not replacing the containment guard or structural validator — this adds a distinct layer
related:
  - relay-automation/hooks/relay-xyz-guard.sh
  - bin/validate-relay-block
  - PROJECT/1-INBOX/GH-61-CI-GITHUB-ACTIONS.md
roadmap_exempt: false
---

# GH-64 · Security-scanning guardrail in the review chain

**Why:** A review of an external "self-healing agent harness" doc against this repo's actual
architecture found most of its principles already implemented. One concrete gap: the review chain
has containment guarding (`relay-xyz-guard.sh`) and structural validation (`bin/validate-relay-block`)
but no security-specific scanner alongside them.

## Status

| What was just completed | What's next |
|---|---|
| Issue [#64](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/64) opened, doc captured, parked in ROADMAP. | Confirm scope, promote to `2-WORKING`, then evaluate scanner options. |

## Table of contents

- [Status](#status)
- [Checklist](#checklist)
- [QA gate](#qa-gate)

## Checklist

- [ ] Identify a lightweight, no-network-dependency security scanner appropriate for a Node-stdlib
      / bash repo (e.g., `npm audit`-equivalent is N/A since there's no root manifest — evaluate
      `shellcheck`'s security-relevant checks, a secret-scan pass, or a minimal custom check for
      unsafe patterns: `eval`, unquoted expansions, `curl | sh`).
- [ ] Add the scanner as a distinct step in the review chain, alongside (not replacing) the existing
      containment guard (`relay-xyz-guard.sh`) and structural validator (`bin/validate-relay-block`).
- [ ] On a finding, the scanner raises a flag for human review — it does not silently block or
      silently auto-fix, per GUIDING-PRINCIPLES.md #8 (no masked failure).
- [ ] Wire the scanner into `validate.sh` or the GH-61 Tier 1 CI job (whichever lands first) so it
      runs on every relevant change, not ad hoc.

## QA gate

- [ ] A known-bad fixture (e.g., a script containing `eval "$UNSANITIZED_INPUT"` or a committed
      fake secret) trips the scanner and produces a visible flag.
- [ ] A clean fixture passes with no false positive.
- [ ] Scanner failure mode is fail-loud, never fail-silent.
