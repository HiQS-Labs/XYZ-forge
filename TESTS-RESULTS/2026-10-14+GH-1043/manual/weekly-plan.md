# Weekly Plan Outline — 2026-10-14

- **Planning Window:** Oct 14 – Oct 20, 2026 (America/Los_Angeles)
- **Generated:** 2026-10-14T20:18:30.399674+00:00
- **Intake Mode:** native_prs
- **Provisional Decisions Register:** None configured

## 0. Release Milestone Context & Active Targets

- **Target Release:** `0.6.0 Front-Door (draft; target=2026-09-26)` (18 days overdue)
- **Release Exit Criterion:** bash test/meter-release.sh --release-gate exits 0. NOT BUILT — written first, before any sanitization (the Litmus/Nightwatch ordering). Half A AUDITS the launch artifact: single-commit sanitized cl...
- **Release Build Burndown:** 12 shipped, 8 dialed-in (60.0% complete)
- **Dialed-in Build Tasks:** #416, #418, #419, #342, #255, #256, #275, #345
- **Subsequent Milestones:**
  - `0.8.0 Sundown (draft; target=2026-10-17)`
  - `0.4.0 Plumbline (draft; target=2026-11-14)`
  - `0.5.0 Lantern (draft; target=2026-12-12)`
- **Active Marathons:**
  - Marathon #1 (`planned`): https://github.com/HiQS-Labs/XYZ-forge/issues/77
  - Marathon #2 (`planned`): https://github.com/HiQS-Labs/XYZ-forge/issues/417
  - Marathon #3 (`planned`): https://github.com/HiQS-Labs/XYZ-forge/issues/462
  - Marathon #4 (`planned`): https://github.com/HiQS-Labs/XYZ-forge/issues/497
  - Marathon #5 (`planned`): https://github.com/HiQS-Labs/XYZ-forge/issues/490
  - Marathon #6 (`planned`): https://github.com/HiQS-Labs/XYZ-forge/issues/749
- **Active Jog Build Queue:**
  - Pos 1: GH-904 (status: `pending`)
  - Pos 2: GH-907 (status: `pending`)
  - Pos 3: GH-906 (status: `pending`)
  - Pos 4: GH-905 (status: `pending`)
  - Pos 5: GH-554 (status: `pending`)
  - Pos 5: GH-555 (status: `pending`)
  - Pos 6: GH-307 (status: `pending`)
  - Pos 7: GH-313 (status: `pending`)

## 1. Immediate P0 Blockers

- *No open PR blockers detected.*

## 2. PR Merge Sequence (Topologically Ordered)

### Phase 1: Ready to Land
- *No PRs currently ready to land.*

### Phase 3: Needs Rebase
- **PR #1054**: fix(marathon): preserve attested phase recovery (#1042, #1045) — `CONFLICTING` against base
- **PR #1053**: fix: publish Pages only from development — `CONFLICTING` against base
- **PR #1044**: feat(recon, review-code): Step N+1 bounded downstream verification (#1043) — `CONFLICTING` against base
- **PR #954**: feat: admit exact HiQS recipes through Claude advisory profiles — `CONFLICTING` against base

### Phase 5: Held Drafts & Evidence Carriers (Do Not Merge Directly)
- **PR #1024**: feat(weekly): held intake and preserved rollover with tracked review limits (GH-1022) — Status: `Review authority limit / unresolved escalation`
- **PR #930**: [HOLD] canary: clean-room sub-minute smoke tier over tick, relay, consult, marathon, and jog (GH-928) — Status: `Explicit HOLD in title`

## 3. Teammate Focus & Action Outlines

### Noel (Orchestration/Gate)
- [ ] **GH-854**: Execute approved gate dispositions *[PRS: 255 (70/50/50/85)]* *[GitHub assignee (@noelsaw1)]*

### Jose (Data/Pipeline)
- *No scheduled tasks assigned.*

### Matthew (NexMail/Calendar)
- *No scheduled tasks assigned.*

### Unassigned / Triage Queue
- [ ] **GH-418**: Marathon planner still reads the frozen ROADMAP.md *[Release Build: 0.6.0]* *[PRS: 321 (88/78/80/75)]*
- [ ] **GH-275**: Medium-level write-ops logging of agent disk-write commands *[Release Build: 0.6.0]* *[PRS: 265 (70/60/60/75)]*
- [ ] **GH-416**: four documentation trues-ups *[Release Build: 0.6.0]* *[PRS: 235 (50/30/60/95)]*
- [ ] **GH-345**: Sleep-vs-readiness audit: one confirmed race in the agent-chorus doorbell assertion, and the case against the paid Test Reliability tier *[Release Build: 0.6.0]* *[PRS: 200 (50/50/50/50)]*
- [ ] **GH-256**: No preflight checks the builder can reach a phase artifact paths *[Release Build: 0.6.0]* *[PRS: 8 (3/2/2/1)]*
- [ ] **GH-255**: marathon-drive blocked-before-dispatch refusal omits XYZ_ARCHIVE_ROOT *[Release Build: 0.6.0]* *[PRS: 4 (1/1/1/1)]*
- [ ] **GH-67**: GH-67 · Commandcode builder default widened to `--yolo` — closer evaluation → possible build *[PRS: 340 (ovr)]*
- [ ] **GH-1043**: feat(recon, review-code): Step N+1 bounded downstream verification in default and exhaustive simulation in deep mode *[PRS: 340 (85/80/90/85)]*
- [ ] **GH-423**: releases roadmap render: emit the DB as ledger markdown — the missing verb #418 actually depends on *[PRS: 313 (80/60/85/88)]*
- [ ] **GH-141**: GH-141 · make Fuzzing and ATE actually useful — Phases 1, 2, 4, 5 (+ #142 prerequisite); Phase 3 deferred pending #143's incidence comparison *[PRS: 285 (80/65/85/55)]*
- *... and 70 more unassigned items in roadmap ledger.*

### Deferred / Parked Intake
- [ ] **GH-916**: Deferred: attribute live relay-self-sufficiency failure only when the live skill path is blocked *[PRS: 185 (30/55/50/50)]*
- [ ] **GH-917**: Deferred: registry-lock-concurrency missing install row — retain installer scope, retire universal gate blocker *[PRS: 170 (20/40/50/60)]*
- [ ] **GH-918**: Deferred: Gen4 domain-oracle shared-root zero-state failure — retire universal gate blocker *[PRS: 170 (15/30/50/75)]*

## 4. Adversarial Northstars Audit

- **[MEDIUM] MERGE_FRICTION**: Detected 4 overlapping file(s) across active PRs: CHANGELOG.md (PRs: [1054, 1053, 1024, 930]); releases.db (PRs: [1053, 1044, 954, 930]); releases.sql (PRs: [1053, 1044, 954, 930]); LEADERBOARD.md (PRs: [1044, 1024, 954, 930]). Enforce sequential landing order to prevent merge conflicts.
