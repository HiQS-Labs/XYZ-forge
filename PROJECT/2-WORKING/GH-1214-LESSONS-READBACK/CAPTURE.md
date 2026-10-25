---
title: "GH-1214 lessons read-back + Harness² borrows — marathon capture (one chain, five lanes)"
status: "Delivered — five phases Approved and gated; PR #1223 open against development"
created: 2026-10-25
updated: 2026-10-25
owner: marathon-gh-1214
goal: >
  Land the five implementable phases of #1214 (plan revision 4, Kimi K3.1 QA applied, Phase 0 decided)
  through one strictly sequential marathon chain: #1222 manifest count, #1221 improve-loop write check,
  #1219 consult blind A/B, #1218 lessons read-back (+6a), #1220 config-fingerprinted resume.
doc_type: project
gh_issue: 1214
roadmap_exempt: true
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1214
reversibility: "Easy — one delivery PR into development from feat/gh1214-lessons-readback; the chain halts on a failed phase and the marathon merges nothing"
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1218
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1219
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1220
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1221
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1222
---

# GH-1214 — lessons read-back + Harness² borrows (marathon capture)

## Status

| What was just completed | What's next |
|---|---|
| 2026-10-25: chain complete (run `marathon-MARATHON_-010448-63424`). Every phase was Approved by codex with a full gate exit 0: p1 #1222, p2 #1221 (retry after a GH-505 refusal; orchestrator re-baselined two re-indented trusted evals in `262b6ffe`), p3 #1219, p4 #1218, p5 #1220. Closeout opened PR #1223 (head `dc415bbc`, MERGEABLE). | Land #1223 through the merge lane: CodeRabbit/peer review adjudication (checklist item 3 per wave), CHANGELOG reconciled at landing, then the hosted reconcile promotes the member docs. #1214 stays open for Phase 6b. |

Tracking issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1214. It holds the full plan, the Phase 0 decisions and the QA dispositions.

## Chain (strict `depends_on`, one lane at a time)

| Phase | Issue | Plan + contract (also the phase brief) | Write-set |
|---|---|---|---|
| p1 | #1222 manifest count | `PROJECT/2-WORKING/GH-1222-RELEASES-LIVE-MANIFEST-COUNT.md` | `utils/py/releases_app.py` + `TESTS-RESULTS/2026-10-25+GH-1222/` |
| p2 | #1221 improve-loop write check | `PROJECT/2-WORKING/GH-1221-IMPROVE-LOOP-BUILD-CAN.md` | `relay-automation/improve-loop.sh` + `TESTS-RESULTS/2026-10-25+GH-1221/` |
| p3 | #1219 consult blind A/B | `PROJECT/2-WORKING/GH-1219-CONSULT-BLIND-B-RECONCILE.md` | `utils/py/consult.py`, `skills/1-hourly/consult/SKILL.md` (`consult.sh` frozen, untouched) + `TESTS-RESULTS/2026-10-25+GH-1219/` |
| p4 | #1218 lessons read-back + 6a | `PROJECT/2-WORKING/GH-1218-LESSONS-READ-BACK-EVIDENCE.md` | `relay-automation/relay-turn-lib.sh`, `skills/1-hourly/relay-automation/relay-pkg.tar.gz`, `LESSONS-LEARNED.md`, `skills/{1-hourly/start-task,3-weekly/marathon-cleanup,4-occasional/defect-campaign}/SKILL.md` + `TESTS-RESULTS/2026-10-25+GH-1218/` |
| p5 | #1220 config-fingerprinted resume | `PROJECT/2-WORKING/GH-1220-MARATHON-RESUME-REUSES-PHASE.md` | `utils/py/{marathon_drive,relay_drive,relay_attest}.py` + `TESTS-RESULTS/2026-10-25+GH-1220/` |

**Collision map.** The declared write-sets are pairwise disjoint. Two things are shared by every lane: `CHANGELOG.md` and the ledger (`releases.db`/`releases.sql`). No lane writes either; the orchestrator reconciles them at landing. The chain is sequential anyway.

**Order rationale.** The two lanes that edit harness code the driver itself runs go last: p4 changes `rtl_turn_prompt`, which every later turn renders, and p5 changes the attestation and resume code. A regression in them can only halt their own phase. p1 and p2 are the smallest and least coupled, so they go first.

**Ratings and selection.** #1220 is rated risk 3, so the planner would hold it from *automatic* selection. The operator selected it explicitly (#1214, 2026-10-25), and the risk is mitigated by the optional field, no schema bump and legacy records accepted.

**Held, not in this chain.**
- **#1214 Phase 6b** (the ATE-metric champion experiment) is a live multi-hour campaign. It needs separate operator approval under the ATE skill, plus p2 landed first.
- Dialing the members into a release is a manifest-scope decision left to the operator.

## Firing recipe

```bash
CLONE="$HOME/marathon-clones/marathon-gh-1214-lessons-readback"   # full clone, branch feat/gh1214-lessons-readback
cd "$CLONE"
export PATH="$HOME/.cache/xyz-forge-test-venv/bin:/opt/homebrew/bin:$PATH"
relay-automation/marathon.sh --plan PROJECT/2-WORKING/GH-1214-LESSONS-READBACK/MARATHON.yaml --builder agy --dry-run
relay-automation/marathon.sh --plan PROJECT/2-WORKING/GH-1214-LESSONS-READBACK/MARATHON.yaml --builder agy --closeout-pr
```

## Acceptance & Quality Checklist

### Wave 1
- [x] Wave 1 Proof of Done Test Suite Green (runnable command + test exit 0): `bash validate.sh` exit 0 after 748s in the pre-advance gate (run log `relay-system/run-logs/2026-10-25/marathon-MARATHON_-010448-63424.log`)
- [x] Wave 1 Post-Build Codex QA Relay executed: receipt [`relay-system/2026-10-25/marathon-p1-081718.md`](../../../relay-system/2026-10-25/marathon-p1-081718.md) (STATUS: Approved, relay-drive attested)
- [ ] Wave 1 CodeRabbit / Peer Review findings adjudicated

### Wave 2
- [x] Wave 2 Proof of Done Test Suite Green (runnable command + test exit 0): `bash validate.sh` exit 0 after 778s in the pre-advance gate (run log `relay-system/run-logs/2026-10-25/marathon-MARATHON_-010448-63424.log`)
- [x] Wave 2 Post-Build Codex QA Relay executed: receipt [`relay-system/2026-10-25/marathon-p2-083239.md`](../../../relay-system/2026-10-25/marathon-p2-083239.md) (STATUS: Approved, relay-drive attested)
- [ ] Wave 2 CodeRabbit / Peer Review findings adjudicated

### Wave 3
- [x] Wave 3 Proof of Done Test Suite Green (runnable command + test exit 0): `bash validate.sh` exit 0 after 734s in the pre-advance gate (run log `relay-system/run-logs/2026-10-25/marathon-MARATHON_-010448-63424.log`)
- [x] Wave 3 Post-Build Codex QA Relay executed: receipt [`relay-system/2026-10-25/marathon-p3-085323.md`](../../../relay-system/2026-10-25/marathon-p3-085323.md) (STATUS: Approved, relay-drive attested)
- [ ] Wave 3 CodeRabbit / Peer Review findings adjudicated

### Wave 4
- [x] Wave 4 Proof of Done Test Suite Green (runnable command + test exit 0): `bash validate.sh` exit 0 after 729s in the pre-advance gate (run log `relay-system/run-logs/2026-10-25/marathon-MARATHON_-010448-63424.log`)
- [x] Wave 4 Post-Build Codex QA Relay executed: receipt [`relay-system/2026-10-25/marathon-p4-092537.md`](../../../relay-system/2026-10-25/marathon-p4-092537.md) (STATUS: Approved, relay-drive attested)
- [ ] Wave 4 CodeRabbit / Peer Review findings adjudicated

### Wave 5
- [x] Wave 5 Proof of Done Test Suite Green (runnable command + test exit 0): `bash validate.sh` exit 0 after 749s in the pre-advance gate (run log `relay-system/run-logs/2026-10-25/marathon-MARATHON_-010448-63424.log`)
- [x] Wave 5 Post-Build Codex QA Relay executed: receipt [`relay-system/2026-10-25/marathon-p5-095420.md`](../../../relay-system/2026-10-25/marathon-p5-095420.md) (STATUS: Approved, relay-drive attested)
- [ ] Wave 5 CodeRabbit / Peer Review findings adjudicated

## Plan QA (pre-fire)

- **Codex, 3 rounds, `STATUS: Approved`** in `relay-system/2026-10-25/gh1214-plan-qa.md`, with a relay-drive attestation (reviewed-head `25591066`).
  - Round 1 found 1 Blocker (p5 trailer binding) and 2 Shoulds (p2 ignored-file bytes, p3 JSON projection).
  - Round 2 found 2 Shoulds (p2 content manifest, p5 acceptance case e).
  - All were accepted and folded in; round 3 approved.
- Earlier independent QA of the whole plan: Kimi K3.1 Pro on #1214 (13 findings, all accepted; disposition table in #1214's comments).
