# GH-796 review evidence

Pinned refs and results are in the sibling JSON snapshots and merge-tree.json. No final integration or full gate was executed in this review. Author-reported gate results remain attributed to each PR, not re-certified here.

QA diagnostics use the exact checker from PR765 be28ff1f via `git show <sha>:utils/pdda/check_marathon_qa.py`, saved under temp/. Run its `--root <development clone> --mode full` to reproduce the current-doc migration failure.

The two-wave fixture below is run with `--root <fixture> --pre-pr --mode full --doc <fixture>/MARATHON-PLAN-probe.md`. Create `relay-system/approved.md` containing `VERDICT: PASS` and `STATUS: Approved`. Wave1 checked/Wave2 unchecked fails; checking both waves passes. Empty the receipt: still passes. Replace backticked receipt paths with ordinary Markdown links: fails because trailing parentheses are captured. These are diagnostic fixtures, not new registered tests or a claim of approved production receipts.

```markdown
---
status: Active
---
## Wave 1
Work one.
## Wave 2
Work two after Wave 1 merges.
## Acceptance & Quality Checklist
### Wave 1
- [x] Wave 1 Proof of Done Test Suite Green
- [x] Wave 1 Post-Build Codex QA Relay executed (`relay-system/approved.md`)
- [x] Wave 1 CodeRabbit / Peer Review findings adjudicated
### Wave 2
- [ ] Wave 2 Proof of Done Test Suite Green
- [ ] Wave 2 Post-Build Codex QA Relay executed (`relay-system/approved.md`)
- [ ] Wave 2 CodeRabbit / Peer Review findings adjudicated
```

Graph generation2026-09-01 was stale; direct source at pinned refs was reviewed. Ledger comparisons deserialize git blobs in memory; no PR ledger was mutated. Review scope and unknowns are in the GH-796 plan/recon map.
