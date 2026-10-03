---
title: "GH-949 — ATE lifecycle, oracle and environment remediation"
status: In Progress
created: 2026-10-03
updated: 2026-10-03
owner: Codex
goal: Repair nine campaign findings and GH-912 with existing shared implementations and witnessed before/after controls.
gh_issue: https://github.com/HiQS-Labs/XYZ-forge/issues/949
related: [949, 912, 435, 948]
effort: 3
complexity: 3
risk: 3
phases: 3
reversibility: Costly — shared process and gate environment consumers require compatibility verification; revert focused commits on regression.
---

# GH-949 — ATE remediation plan

## Status

| What was just completed | What's next |
|---|---|
| Plan QA attested Approved; runtime repair committed at 76ad7e4e; original manual controls green | Focused suites, independent final QA and qualifying gate |

## Table of contents

- [Scope and evidence](#scope-and-evidence)
- [Phase 1 — Plan QA](#phase-1--plan-qa)
- [Phase 2 — Implement and prove](#phase-2--implement-and-prove)
- [Phase 3 — Final QA and PR](#phase-3--final-qa-and-pr)

## Scope and evidence

Canonical tracking: https://github.com/HiQS-Labs/XYZ-forge/issues/949; existing related task https://github.com/HiQS-Labs/XYZ-forge/issues/912. Campaign evidence PR948 is a reference, not an implementation dependency: repairs start at current development `3fbed72f781d1ad060e298b798a44c32edef393d`. [Recon map](recon-gh949-ate-remediation.md) traces the callers and mutable state. No overlapping implementation PR was found; PR930 is held canary work and is not changed.

Bet: existing process-group and runner boundaries can carry all fixes without a new engine, gate or dependency. If a control requires another executor or persistent authority, stop and re-review the plan. Debug-mantra is the execution protocol. No schema migration, Bash twin edit, new test suite, registry entry, timeout-success policy expansion, installer behavior change or broad #918 diagnosis. Manual scripts are retained execution artifacts under TESTS-RESULTS, not a new runner or registered gate. This is a bounded repair batch, not a large refactor/new marathon; review, dogfood and conformance are budgeted inside these phases.

| Issue | Requirements | Dependencies | Plan / branch | Acceptance | Ledger rating | State / PR |
|---|---|---|---|---|---|---|
| #949 | F1–F9 | shared cleanup before oracle/ATE use | this plan; fix/gh949-ate-remediation | Phase 2 steps 1–6 + final QA/gate | rated90/85/50/55 | Implementation; none |
| #912 | K1 ambient selector leak | existing runner envelope | same plan/branch, separate ledger row | inherited selector red → clean wrapped suites; intentional overrides still win | rated82/80/50/85 | Implementation; none |

Ratings dated2026-10-03, read back from RELEASES: #949 priority90/severity85/neutral appeal50/cheapness55; #91282/80/50/85. Unsupervised continuing writes and false containment are high-impact potential consequences, not claimed production loss. #912 caused a documented3373s false-red gate on Oct1; the Oct3 campaign reproduces the same defect, not a second production incident. History windows Sep19–Oct3 versus Sep5–19: #478 documents a Sep3–6 runaway incident in the earlier window, but its generator cause differs; #918 Oct1 pooled oracle failure has unknown attribution and is not counted as the same root cause. Trend is unknown from this bounded sample, not increasing by assertion. No user override exists; appeal stays neutral. Cheapness reflects a focused multi-file repair versus simple envelope correction.

## Phase 1 — Plan QA

- [x] Record exact-source recon, existing consumers and graph limitations.
- [x] Register and rate #949 and #912 independently; do not admit accepted-start before approved QA.
- [x] Commit plan and run shipped Codex relay, review-only, with three-round cap; record every disposition. Round 1 protocol refusal preserved; corrected round 2 attested Approved, exit 0. Receipt: `relay-system/2026-10-03/gh949-plan.codex.md`; driver logs under TESTS-RESULTS.

### Phase 1 — QA checklist

- [x] Approved relay status plus successful driver exit, nonempty receipt and grounded findings.
- [x] Scope covers all ten checklist entries; no new test/gate machinery.

## Phase 2 — Implement and prove

Execute this one ordered list after plan approval. Shared changes are Costly; shield is fresh full verification clone with identity snapshots, tripwire is any changed caller result shape, surviving owned process or unintended Git mutation. Stop on tripwire, preserve evidence, revert only owned changes/commits if necessary. No production data migration or one-way operation.

1. Admit the exact two owned roadmap rows with --accepted-start after issue/row identity read-back. Extend `proc_group.run_bounded` to clean/reap its group on BaseException and re-raise, preserving timeout result and spawn-error propagation. Keep signal handlers out of threaded library calls. At CLI entry boundaries translate SIGTERM into catchable cancellation, restore previous handlers, and guard repeated interruption during bounded cleanup. Move command-mode timeout validation before spawn/publication/ack; keep --kill-pgid timeout-optional. → F1/F7 controls: SIGINT/SIGTERM no surviving same-group child; missing timeout no PID/sentinel; existing timeout/ack/publication codes unchanged; normal successful background policy unchanged.
2. Reuse run_bounded in domain `_run` and existing metamorphic idempotence repetitions. Preserve ordinary nonzero diagnostic semantics, but mark timed-out/unlaunched observation incomplete and never pass it; reject timeout in zero-state, containment and idempotence, including later repeats. Keep intentional crash-holder SIGKILL separate. → F8: nonempty no-op passes, timed-out same-group late writer fails and cannot mutate after return; sequential/threaded idempotence remains callable and timeout fails; genuine command exit124 distinguishable from witnessed timeout.
3. Extend existing tree digest to include directory symlink entries without traversing targets. Resolve shared Git config with Git's common-dir/path commands and include worktree config presence/hash; metadata resolution/read errors must not silently compare as an empty success. → F2/F3: no-op passes; file/link add/remove/retarget detected; target contents untouched; standalone config, linked shared config, linked config.worktree and linked HEAD changes detected.
4. Reject empty grids before control/baseline/reset writes. Track records produced by this invocation and return explicit nonzero no-work when a budget runs out before any attempt. Convert launch exceptions into one structured fail/spawn_error row, then stop nonzero (deliberate fail-fast, no repeated global launch failure); record a cancelled active run as one fail/interrupted row, then exit130/143 with no next attempt. Reuse the existing append/classification path and schema1.0; preserve prior rows and filing exit semantics for normally completed runs. Generate UTC timestamps and run IDs with UTC clocks. → F1/F4/F5/F9: nonempty positive, no-write empty-grid refusal, missing executable one row/nonzero, cancellation prior-row preservation, timezone-invariant epoch; checkin/compile readers accept records.
5. Guard optional HOME config/search/AGY paths without root-relative fallbacks; preserve XDG and explicit override precedence. Scrub inherited XYZ_HARNESS and XYZ_REPO_ROOT once at `runner_envelope_begin`, shared by both gate runners; keep XYZ_HARNESS_DB and explicit per-case assignments. → F6/K1: valid override works with HOME unset with/without XDG; missing fallback truthfully refuses; baseline ambient-override suite red becomes wrapped green; explicit fixture overrides still resolve correctly.
6. Record manual red/base and repaired controls with provenance and minimized scripts under TESTS-RESULTS/2026-10-03+GH-949. Run the existing focused suites named in recon once relevant changes stabilize; alter an existing suite only if changed behavior makes its assertion untruthful. No new suite or registry entry, and no re-enabling #918's retired universal check. Update CHANGELOG for this consequential shared-behavior bet. → every F1–F9/K1 has a result and failure-witness reference; no empty extracted evidence.

### Phase 2 — QA checklist

- [x] All ten requirements mapped to observed base/repaired outcomes; expected refusals separated from product failures.
- [x] Process/fixture cleanup and clone identity before/after verified; no production writes.
- [x] Focused suite results and manual controls committed with provenance, including failures and dispositions.
- [x] Runtime scope stays in existing helpers; no new dependencies, schemas, suites or gate stages.

## Phase 3 — Final QA and PR

- [ ] Commit implementation/evidence; run final Codex relay against full changed files, acceptance matrix and latest ratings (three rounds maximum). Resolve grounded findings, reject speculative scope expansion with written disposition, and obtain Approved on final implementation.
- [ ] Run full qualifying local gate exactly once on the final approved implementation in a separate disposable full clone; verify clone identity and retain output/provenance. A failed gate remains failed; diagnose required failures rather than bypassing.
- [ ] Fetch/reconcile current development conflicts via supported RELEASES merge resolver if needed; any implementation change after approval gets fresh focused verification/review.
- [ ] Push through the required hook from the disposable verification/push clone, open ready PR to development, verify emitted base/head/scope and hosted checks. Do not merge or prematurely close issues; retain task clone for merge handoff.

### Phase 3 — QA checklist

- [ ] Final relay Approved plus successful nonempty receipt; required local and hosted results linked for exact tested SHA.
- [ ] #949/#912 requirements all satisfied or explicitly unresolved; ready status only when all blocking checks pass.
- [ ] Plan/ledger say PR ready awaiting merge, not shipped; retained clone and cleanup handoff reported.

Evidence: `TESTS-RESULTS/2026-10-03+GH-949/SUMMARY.md` maps all findings to retained before/after controls. The process helper API remains signal-handler-free; only the two CLI entry boundaries own handlers. Zero-minute admission remains nonzero without new rows but retains existing baseline/control initialization. All nine focused suites passed on runtime candidate76ad7e4e; final review/gate outstanding.

Final QA R1 disposition: Implemented. The whole-file sweep exposed a pre-existing first-versus-later rc/stdout blind spot. `984b7f64` compares the first observation against existing metamorphic result fields. Actual-process red/green controls are retained under manual-idempotence; affected existing suites are rerun. This extends the already approved idempotence comparison, not the process architecture or risk scope.
