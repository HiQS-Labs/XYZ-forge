# RELAY · GH-949 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-03.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-949-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **GH-949-ATE-REMEDIATION.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-03

### Artifact — GH-949-ATE-REMEDIATION.md
```
---
title: "GH-949 — ATE lifecycle, oracle and environment remediation"
status: Planning
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
| Fresh clone, issue-first intake, exact-source recon and per-issue ratings | Codex relay plan QA; no production edits before approval |

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
| #949 | F1–F9 | shared cleanup before oracle/ATE use | this plan; fix/gh949-ate-remediation | matrix below + final QA/gate | rated90/85/50/55 | Planning; none |
| #912 | K1 ambient selector leak | existing runner envelope | same plan/branch, separate ledger row | inherited selector red → clean wrapped suites; intentional overrides still win | rated82/80/50/85 | Planning; none |

Ratings dated2026-10-03, read back from RELEASES: #949 priority90/severity85/neutral appeal50/cheapness55; #91282/80/50/85. Unsupervised continuing writes and false containment are high-impact potential consequences, not claimed production loss. #912 caused a documented3373s false-red gate on Oct1; the Oct3 campaign reproduces the same defect, not a second production incident. History windows Sep19–Oct3 versus Sep5–19: #478 documents a Sep3–6 runaway incident in the earlier window, but its generator cause differs; #918 Oct1 pooled oracle failure has unknown attribution and is not counted as the same root cause. Trend is unknown from this bounded sample, not increasing by assertion. No user override exists; appeal stays neutral. Cheapness reflects a focused multi-file repair versus simple envelope correction.

## Phase 1 — Plan QA

- [x] Record exact-source recon, existing consumers and graph limitations.
- [x] Register and rate #949 and #912 independently; do not admit accepted-start before approved QA.
- [ ] Commit plan and run shipped Codex relay, review-only, with three-round cap; record every disposition.

### Phase 1 — QA checklist

- [ ] Approved relay status plus successful driver exit, nonempty receipt and grounded findings.
- [ ] Scope covers all ten checklist entries; no new test/gate machinery.

## Phase 2 — Implement and prove

Execute this one ordered list after plan approval. Shared changes are Costly; shield is fresh full verification clone with identity snapshots, tripwire is any changed caller result shape, surviving owned process or unintended Git mutation. Stop on tripwire, preserve evidence, revert only owned changes/commits if necessary. No production data migration or one-way operation.

1. Admit the exact two owned roadmap rows with --accepted-start after issue/row identity read-back. Extend `proc_group.run_bounded` to clean/reap its group on BaseException and re-raise, preserving timeout result and spawn-error propagation. Keep signal handlers out of threaded library calls. At CLI entry boundaries translate SIGTERM into catchable cancellation, restore previous handlers, and guard repeated interruption during bounded cleanup. Move command-mode timeout validation before spawn/publication/ack; keep --kill-pgid timeout-optional. → F1/F7 controls: SIGINT/SIGTERM no surviving same-group child; missing timeout no PID/sentinel; existing timeout/ack/publication codes unchanged; normal successful background policy unchanged.
2. Reuse run_bounded in domain `_run` and existing metamorphic idempotence repetitions. Preserve ordinary nonzero diagnostic semantics, but mark timed-out/unlaunched observation incomplete and never pass it; reject timeout in zero-state, containment and idempotence, including later repeats. Keep intentional crash-holder SIGKILL separate. → F8: nonempty no-op passes, timed-out same-group late writer fails and cannot mutate after return; sequential/threaded idempotence remains callable and timeout fails; genuine command exit124 distinguishable from witnessed timeout.
3. Extend existing tree digest to include directory symlink entries without traversing targets. Resolve shared Git config with Git's common-dir/path commands and include worktree config presence/hash; metadata resolution/read errors must not silently compare as an empty success. → F2/F3: no-op passes; file/link add/remove/retarget detected; target contents untouched; standalone config, linked shared config, linked config.worktree and linked HEAD changes detected.
4. Reject empty grids before control/baseline/reset writes. Track records produced by this invocation and return explicit nonzero no-work when a budget runs out before any attempt. Convert launch exceptions into one structured fail/spawn_error row, then stop nonzero (deliberate fail-fast, no repeated global launch failure); record a cancelled active run as one fail/interrupted row, then exit130/143 with no next attempt. Reuse the existing append/classification path and schema1.0; preserve prior rows and filing exit semantics for normally completed runs. Generate UTC timestamps and run IDs with UTC clocks. → F1/F4/F5/F9: nonempty positive, no-write empty-grid refusal, missing executable one row/nonzero, cancellation prior-row preservation, timezone-invariant epoch; checkin/compile readers accept records.
5. Guard optional HOME config/search/AGY paths without root-relative fallbacks; preserve XDG and explicit override precedence. Scrub inherited XYZ_HARNESS and XYZ_REPO_ROOT once at `runner_envelope_begin`, shared by both gate runners; keep XYZ_HARNESS_DB and explicit per-case assignments. → F6/K1: valid override works with HOME unset with/without XDG; missing fallback truthfully refuses; baseline ambient-override suite red becomes wrapped green; explicit fixture overrides still resolve correctly.
6. Record manual red/base and repaired controls with provenance and minimized scripts under TESTS-RESULTS/2026-10-03+GH-949. Run the existing focused suites named in recon once relevant changes stabilize; alter an existing suite only if changed behavior makes its assertion untruthful. No new suite or registry entry, and no re-enabling #918's retired universal check. Update CHANGELOG for this consequential shared-behavior bet. → every F1–F9/K1 has a result and failure-witness reference; no empty extracted evidence.

### Phase 2 — QA checklist

- [ ] All ten requirements mapped to observed base/repaired outcomes; expected refusals separated from product failures.
- [ ] Process/fixture cleanup and clone identity before/after verified; no production writes.  [Unverified — no citation]
- [ ] Focused suite results and manual controls committed with provenance, including failures and dispositions.
- [ ] Runtime scope stays in existing helpers; no new dependencies, schemas, suites or gate stages.

## Phase 3 — Final QA and PR

- [ ] Commit implementation/evidence; run final Codex relay against full changed files, acceptance matrix and latest ratings (three rounds maximum). Resolve grounded findings, reject speculative scope expansion with written disposition, and obtain Approved on final implementation.
- [ ] Run full qualifying local gate exactly once on the final approved implementation in a separate disposable full clone; verify clone identity and retain output/provenance. A failed gate remains failed; diagnose required failures rather than bypassing.
- [ ] Fetch/reconcile current development conflicts via supported RELEASES merge resolver if needed; any implementation change after approval gets fresh focused verification/review.
- [ ] Push through the required hook from the disposable verification/push clone, open ready PR to development, verify emitted base/head/scope and hosted checks. Do not merge or prematurely close issues; retain task clone for merge handoff.

### Phase 3 — QA checklist

- [ ] Final relay Approved plus successful nonempty receipt; required local and hosted results linked for exact tested SHA.
- [ ] #949/#912 requirements all satisfied or explicitly unresolved; ready status only when all blocking checks pass.
- [ ] Plan/ledger say PR ready awaiting merge, not shipped; retained clone and cleanup handoff reported.
```
- Definition of Done: Canonical plan Phase 2 steps 1–6 cover F1–F9/K1 with falsifiable controls, bounded existing helpers, compatibility and rollback; Phase 3 requires independent final QA and qualifying evidence.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Review packet — operational envelope

Review the committed canonical plan and recon against GH-949 F1–F9 and GH-912. Inspect named source, not only embedded prose. Check cleanup/cancellation shapes, all delegated idempotence runs, no-work admission before mutation, append/filing semantics, Git config error paths, optional HOME fallbacks and the existing shared envelope. Ratings are stored in RELEASES for each issue with no overrides. Grade against this single-user developer-tool envelope and commensurate complexity; no enterprise multi-tenant threat model, new frameworks, gates or suites. Review-only: edit only this relay transcript. Do not run mutation-heavy suites from this task clone or linked review worktree. Do not install anything or create issues/PRs. Report concrete blockers with observed input, affected scope and falsifier. This is pre-implementation QA; runtime changes are intentionally absent. A successful review must set STATUS: Approved, record VERDICT: PASS, and hand the token back per the embedded protocol. Three rounds maximum; do not manufacture scope expansion.

## Log

### Reviewer · Round 1

swept file: yes

VERDICT: PASS

Basis: Approved as a pre-implementation plan, not as proof that the runtime is repaired. Read the entire embedded and canonical plan plus recon, and inspected the named source seams. The six ordered implementation steps cover F1–F9/K1 with bounded scope, existing shared helpers, explicit compatibility constraints, reversible commits and independent final QA. No blocking pre-existing defect in the plan was found.

- [Pass] Process lifecycle sequencing is grounded: `utils/py/proc_group.py:95` spawns before its communicate-only exception boundary, and command-mode timeout admission is currently after publication/ack at `utils/py/proc_group.py:185`. Phase 2 step 1 explicitly moves admission before spawn, covers BaseException cleanup and CLI SIGTERM, protects cleanup from repeated interruption, and keeps signal registration out of threaded library calls. Preserve the stated success/background policy and 124/125/127 distinctions during implementation.
- [Pass] Oracle repair reaches delegated repeats: `utils/py/domain_oracles.py:348` calls `check_idempotence`, whose `_run_single` uses raw subprocess execution at `utils/py/metamorphic_oracle.py:182`. Phase 2 step 2 names both paths and requires genuine exit124 to remain distinguishable from timeout. Steps 2–3 also address the digest's filenames-only iteration (`domain_oracles.py:98`) and literal `.git/config` identity (`domain_oracles.py:239`), with linked common/worktree config and error-path controls. These are concrete existing seams, not a proposed second oracle engine.
- [Pass] ATE admission and records have measurable consumer-facing criteria: `utils/ate/scripts/run_variations.py:449` writes control before the empty loop can skip work, `:483` invokes the harness before classification/append, and `:534` labels local time as UTC. Phase 2 step 4 specifies pre-write empty-grid rejection, invocation-local no-work accounting, one append for spawn/cancellation failures, 130/143 cancellation, and UTC clocks. The existing readers accept category/cause strings and top-level fail (`utils/ate/scripts/checkin.py:67`, `utils/ate/scripts/compile_issue.py:49`); retain the full existing record shape as planned.
- [Pass] Environment scope is appropriately narrow: optional HOME expansions precede override selection at `skills/1-hourly/relay-xyz/find-harness.sh:121` and recur in AGY discovery at `:348`. The single envelope entry at `test/lib/runner-envelope.sh:59` is used by `validate.sh:1238` and `ci-local.sh:399`. Step 5 preserves XDG, explicit fixture assignments and XYZ_HARNESS_DB while removing only the two named inherited selectors.
- [Unverified — no citation] Proof and rollback are explicit: the plan says “shield is fresh full verification clone with identity snapshots” and requires “every F1–F9/K1 has a result and failure-witness reference.” The recon names existing focused suites; Phase 3 requires final independent QA, qualifying evidence and exact-SHA checks before ready publication. No new suite, gate, schema or dependency is proposed.
- [Nit] The relay Setup still has the placeholder Definition of Done and the plan table says “matrix below” although the criteria are in the numbered steps. On future packet preparation, point these directly at Phase 2 steps 1–6 and Phase 3 QA. The operational envelope and explicit controls make this review's criteria unambiguous, so this is not a blocker.
- [Unverified — needs clone run] No runtime suites, executable fixtures, model calls or Git commands were run in this review worktree. Cancellation, late-writer teardown, exact result compatibility, reader acceptance and gate behavior remain implementation acceptance work, not witnessed passes in this turn. Historical incident counts and live PR/ledger state were treated as supplied context rather than independently re-attested.

Evidence boundary: Verify-tier discovery attempted against nearest indexed project `XYZ-forge` (different checkout), generation `2026-09-01T15:54:30Z`; project listing exhausted both pages. Symbol search returned only unrelated `rtl_run_bounded` (no further pages). Coverage reported proc_group/domain_oracles/locator/envelope not tracked and ATE scripts excluded; metamorphic metadata matched only that other checkout. Used local source reads for material claims, without treating graph silence as absence or reindexing outside this turn's allowed write scope.

Relay closed (Approved), no further review turn needed. Producer may proceed with the approved implementation plan; runtime approval remains subject to the planned evidence and final QA.

### Producer · Round 2

Disposition: Implemented the review packet nit. Definition of Done now points to the explicit phase criteria. The canonical plan table now points to numbered acceptance steps.

Protocol recovery: round 1 driver exited 4 with review-body-rewritten because the producer placed the operational packet after the final marker. Its PASS is retained as advisory, not accepted approval. Moved that packet into Setup above Log; prior reviewer block is unchanged. Re-review the canonical plan and corrected protocol; this is round 2 of the original three-round budget. No production edits have begun.

Handing off to Reviewer for corrected plan approval.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
