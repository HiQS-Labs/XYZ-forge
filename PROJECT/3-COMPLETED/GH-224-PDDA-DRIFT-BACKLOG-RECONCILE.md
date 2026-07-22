---
gh_issue: 224
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/224
title: "PDDA drift backlog: 45 stale 3-COMPLETED status words + 15 ROADMAP/issue-state mismatches (surfaced by GH-189's own new checks)"
status: "SHIPPED — closed 2026-07-21, see GitHub issue comment for evidence (commit 19468be)."
created: 2026-07-17
updated: 2026-07-17
owner: noel
doc_type: chore
complexity: 2
risk: 1
effort: 3
phases: 1
ratings_provisional: true
non_goals:
  - Not changing PDDA_TERMINAL_STATUS_WORDS or the check logic itself — GH-189's checks are correct;
    this is about the backlog they found, not the detector
  - Not a blocking gate — pdda.sh run stays warn-only for both checks
related:
  - PROJECT/3-COMPLETED/GH-189-PDDA-COMPLETED-STATE-BLINDSPOT.md
  - ROADMAP.md
  - utils/pdda/pdda.sh
goal: >
  Reconcile the real drift GH-189's two new checks (pdda-check-roadmap-issue-state,
  pdda-check-issue-doc-sync's 3-COMPLETED scan) surfaced against this repo's own docs/ROADMAP: 15
  ROADMAP ledger/issue-state mismatches and 45 stale 3-COMPLETED frontmatter status words.
roadmap_exempt: false
---

# GH-224 · PDDA drift backlog reconciliation

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-07-17, promoted to 2-WORKING with a Swarm Preflight Contract. Findings reproduced live on `marathon/gh174-215-222-189-2026-07-17` (the branch that added the checks) — not false positives. Not yet fixed. | Queue in the next marathon fire; this is a per-item reconciliation pass, not a bulk edit. |
| **2026-07-21:** shipped via commit `19468be`; issue #224 closed on GitHub. | Promoted to `3-COMPLETED`. Nothing further for this doc. |

## Dependency

`pdda-check-roadmap-issue-state` and the 3-COMPLETED scan in `pdda-check-issue-doc-sync` only exist on
`marathon/gh174-215-222-189-2026-07-17` (GH-189's fix), not yet on `development`. This lane can't fire
for real until that branch merges — sequence it after GH-189 lands.

## Findings (reproduced 2026-07-17)

### 15 ROADMAP.md ledger/issue-state mismatches — `bash utils/pdda/pdda.sh roadmap-issue-state`

| Line | Entry reads | Issue | Actual state |
|---|---|---|---|
| 76 | ✅/SHIPPED | #211 | OPEN |
| 83 | ✅/SHIPPED | #173 | OPEN |
| 84 | ✅/SHIPPED | #173 (2nd ref) | OPEN |
| 84 | ✅/SHIPPED | #178 | OPEN |
| 88 | ✅/SHIPPED | #223 | OPEN (expected — self-resolves when #223 ships) |
| 100 | 🆕/non-terminal | #187 | CLOSED |
| 105 | ✅/SHIPPED | #163 | OPEN |
| 109 | ✅/SHIPPED | #147 | OPEN |
| 111 | ✅/SHIPPED | #151 | OPEN |
| 112 | ✅/SHIPPED | #152 | OPEN |
| 113 | ✅/SHIPPED | #155 | OPEN |
| 124 | 🆕/non-terminal | #118 | CLOSED |
| 147 | ✅/SHIPPED | #144 | OPEN |
| 162 | ✅/SHIPPED | #96 | OPEN |
| 162 | ✅/SHIPPED | #141 | OPEN |

Each needs an individual look — "ledger says shipped, issue open" usually means "shipped but the
issue was never closed" (fix: close the issue), but a few may be legitimately open follow-on work
that just needs the ledger's status word corrected instead.

### 45 stale `3-COMPLETED` docs — `bash utils/pdda/pdda.sh issue-doc-sync`

49 total warns; 4 are GH-174/215/222/189 themselves (still in `2-WORKING` pending their own `git mv`
once that branch merges — expected, not backlog). The remaining 45 real items (doc, issue, current
non-terminal status word): GH-106 (captured), GH-108 (captured), GH-112 (captured), GH-116 (bug),
GH-117 (captured), GH-124 (captured), GH-132 (active), GH-133 (proposed), GH-137 (captured), GH-138
(in), GH-150 (active), GH-172 (phase), GH-203/205/206/207/209/212/213 (built), GH-21/25/31/32/40
(active), GH-44/58/70/84 (queued), GH-45/56/59/61/66/78 (proposed), GH-48/68 (built/captured), GH-63/85
(ready), GH-71 (phases), GH-83 (in), GH-88 (queued), MARATHON-PLAN-2026-07-10-LM-STUDIO-AIDER.md/#147
(both), gh-27-roadmap-dashboard-brief.md (active), gh-61-ci-tier1-brief.md (active). Full list
reproducible by re-running the command once this repo is on a branch carrying GH-189's checks.

## Fix direction

Doc-only reconciliation, not a code fix. Per flagged item: confirm real GitHub issue state
(`gh issue view <n> --json state`), then either (a) flip frontmatter `status:` to a terminal word if
truly done, (b) close the GitHub issue if the ledger is right and the issue was just never closed, or
(c) fix the ROADMAP status marker if the issue is legitimately still open. No safe bulk regex — needs
a human/agent eyeball per item.

## Definition of done

- [ ] All 15 ROADMAP/issue-state mismatches reconciled (issue closed, or ledger corrected).
- [ ] All 45 stale 3-COMPLETED status words reconciled (status flipped terminal, or doc moved back to
      2-WORKING if genuinely still open).
- [ ] `bash utils/pdda/pdda.sh issue-doc-sync` and `roadmap-issue-state` re-run clean or only flag
      genuinely-new drift introduced after this pass.
- [ ] No change to `PDDA_TERMINAL_STATUS_WORDS` or check logic.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash utils/pdda/pdda.sh issue-doc-sync && bash utils/pdda/pdda.sh roadmap-issue-state",
  "fix_probes": [
    { "type": "command", "cmd": "bash utils/pdda/pdda.sh issue-doc-sync", "expect_nonzero": false }
  ],
  "artifacts": [ "ROADMAP.md", "PROJECT/3-COMPLETED" ],
  "remediation": {
    "source": "issue#224",
    "criteria": "Every flagged ROADMAP.md ledger entry and every flagged PROJECT/3-COMPLETED/*.md frontmatter status reconciled against actual GitHub issue state; both pdda.sh checks re-run clean or only flag genuinely-new drift; no change to check logic."
  },
  "lanes": { "agy_safe": [ "ROADMAP.md", "PROJECT/3-COMPLETED" ], "orchestrator_only": [] }
}
```
