---
gh_issue: 64
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/64
title: Self-healing harness — security-scanning guardrail in the review chain
status: Shipped (tool + active blocking gate)
created: 2026-06-30
updated: 2026-07-01
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
| **SHIPPED 2026-07-01.** Scanner + test shipped `a0cc84e` (marathon Wave 2 Lane A); active-gate wiring completed this session: `relay-automation/hooks/security-scan-baseline.txt` (hand-maintained, 45 reviewed findings, content-keyed not line-keyed), `--no-baseline`/`--tsv` flags, `test/security-scan.sh` 28/28 including a real-repo-against-baseline assertion that IS the blocking gate (already in `validate.sh`). | Nothing — fully shipped. Optional future pairing with GH-61 CI (Tier 1 job) once that lands. |

## Table of contents

- [Status](#status)
- [Checklist](#checklist)
- [QA gate](#qa-gate)

## Checklist

- [x] Identify a lightweight, no-network-dependency security scanner appropriate for a Node-stdlib
      / bash repo — a minimal custom grep-based scanner for unsafe patterns: `eval`, `curl | sh`,
      AWS keys, PEM headers, GitHub PATs, Slack tokens, literal credential assignments.
- [x] Add the scanner as a distinct step in the review chain, alongside (not replacing) the existing
      containment guard (`relay-xyz-guard.sh`) and structural validator (`bin/validate-relay-block`).
- [x] On a finding, the scanner raises a flag for human review — it does not silently block or
      silently auto-fix, per GUIDING-PRINCIPLES.md #8 (no masked failure).
- [x] Wire the scanner into `validate.sh` so it runs on every relevant change, not ad hoc — a
      hand-maintained baseline (`security-scan-baseline.txt`) makes it a real BLOCKING gate: every
      known-legitimate finding is baselined (still printed, never hidden) so only a genuinely NEW
      finding fails the suite.

## QA gate

- [x] A known-bad fixture (e.g., a script containing `eval "$UNSANITIZED_INPUT"` or a committed
      fake secret) trips the scanner and produces a visible flag.
- [x] A clean fixture passes with no false positive.
- [x] Scanner failure mode is fail-loud, never fail-silent.
- [x] A baselined finding is still printed (not hidden); a non-baselined finding in the same file
      still fails the scan; `--no-baseline` bypasses the baseline entirely for a raw audit.
- [x] The real repo tree, scanned against the checked-in baseline, is clean (0 non-baselined
      findings) — proven by `test/security-scan.sh`'s "GH-64 active gate" assertion in `validate.sh`.
