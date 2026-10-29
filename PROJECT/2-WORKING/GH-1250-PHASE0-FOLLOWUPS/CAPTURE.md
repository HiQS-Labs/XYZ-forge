---
title: "GH-1250: marathon — GH-1175 Phase 0 follow-ups"
status: Active
created: 2026-10-29
updated: 2026-10-29
owner: noelsaw1
gh_issue: 1250
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1250
doc_type: project
umbrella: true
roadmap_exempt: true
goal: "Land the four reviewed Phase 0 follow-up lanes (#1233, #1235, #1251, #1236) one at a time, each with post-build Codex QA and a merge-cleanup landing."
---

# GH-1250: marathon — GH-1175 Phase 0 follow-ups

## Status

| What was just completed | What's next |
|---|---|
| Plans approved (codex plan QA r3, attested); all four preflight ready (exit 0); marathon.sh --dry-run exit 0 | Operator confirms the exact plan and order, then fire via /pre-marathon |

## Members

| Phase | Issue | Doc | Write-set |
|---|---|---|---|
| p1 | #1233 | `PROJECT/2-WORKING/GH-1233-JOG-RECOVERY-AFTER-DRIVER.md` | `skills/2-daily/jog/SKILL.md` |
| p2 | #1235 | `PROJECT/2-WORKING/GH-1235-MERGE-CLEANUP-JOG-LAND.md` | `merge_cleanup.py` + evidence |
| p3 | #1251 (Refs #522) | `PROJECT/2-WORKING/GH-1251-GH-522-SLICE-1.md` | `utils/py/_marathon_plan.py` + evidence |
| p4 | #1236 | `PROJECT/2-WORKING/GH-1236-JOG-MARATHON-LANE-RUNS.md` | `validate.sh`, `githooks/pre-push`, `gate_receipt.py`, `marathon_drive.py` + evidence |

Plan QA: `relay-system/2026-10-29/gh1250-plan-qa.md` (r1 FAIL → r2 FAIL on write allowances → r3 PASS, attested).

## Acceptance & Quality Checklist

### Wave 1
- [ ] Wave 1 Proof of Done Test Suite Green (runnable command + test exit 0)
- [ ] Wave 1 Post-Build Codex QA Relay executed (receipt recorded under `relay-system/<YYYY-MM-DD>/<label>.codex.md`)
- [ ] Wave 1 CodeRabbit / Peer Review findings adjudicated
