---
gh_issue: 1461
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1461
title: "Simplify idea skill: direct GitHub issue creation with EGM alignment, strip HQ, ledger, and preflight contract"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-11-13
doc_type: enhancement
effort: 2
complexity: 2
risk: 1
phases: 1
---

# Simplify idea skill

## Quad Concepts
- Excessive machinery in idea capture → Strip HQ, ledger writing, local 1-INBOX captures, and preflight contracts so filing ideas leaves zero on-disk footprint.
- Preserving alignment → Retain the Elephant-Goldfish Model (EGM) paraphrase-first comprehension lens (What this proposes, How it works, What it's not) and multi-model consult pass (Codex/Agy).
- Direct remote publishing → Use \`gh issue create\` directly to create GitHub issues and post consult dispositions as an issue comment.

## Scope and Plan
1. Update \`skills/1-hourly/idea/SKILL.md\`:
   - Replace complex intake/HQ/ledger steps with a streamlined 4-part issue format:
     1. Context & Operator Alignment
     2. Recon & Code Seams
     3. Proposed Sketch & Approach
     4. Acceptance & Non-Goals
   - Retain the automated multi-model consult step (Codex/Agy) with EGM comprehension lens.
   - Publish directly via \`gh issue create\` and comment consult dispositions.
   - Zero files created on disk during filing.
2. Update \`ARCHITECTURE.md\` to reflect the simplified skill description.
3. Verify with PDDA local checks and docs gate.
4. Open PR, await green CI, merge, and redeploy via Skills Army HQ to Git Pulse Sync.

## Acceptance Criteria
- [ ] \`skills/1-hourly/idea/SKILL.md\` writes zero files to disk when filing ideas.
- [ ] All HQ, ledger, 1-INBOX on-disk capture, and preflight contract references are removed from \`idea\`.
- [ ] EGM paraphrase-first comprehension lens (What this proposes, How it works, What it's not) is preserved in consult and issue sections.
- [ ] \`ARCHITECTURE.md\` reflects the streamlined description.
- [ ] Documentation and PDDA gates pass.
- [ ] PR created, merged once CI is green, and deployed to Git Pulse Sync via Skills Army HQ.
