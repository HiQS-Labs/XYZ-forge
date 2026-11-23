# Plan draft: #796 Integration review: sequence and remediate open PRs #794, #795, #765; assess and hold #759

> draft; preflight and independent plan QA outstanding

- Request: `gh-796-7e589e59f89f` (tick `slot_014`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 80/75/50/65
- Capture doc: PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md (sha256 838a1157acdfd8a03f3af0689ae08c96e4c1972944d31cb868670129b8d235e3)
- Issue sha256: 7e589e59f89fff1e17cff6d6fde6aa4e830c1f8a0debc5ee4aeaf093cff84b26 (updated 2026-09-25T08:37:02Z)
- Dependencies: none

## Scope

_Source: issue#796:L31 (Scope and decision)_

Tracking issue: https://github.com/HiQS-Labs/XYZ-forge/issues/796.
Parent adoption arc: #777 (open). Related mechanical wave QA: #784. Existing #791 covers the previous merged batch; #789/#786 cover enhancements to merge-cleanup, not this integration review.

Requested now: source review, conflict/regression flags, an optimal merge/remediation plan in GitHub, and Agy plan QA through relay-xyz. No production fixes, live merges, issue closure, skill deployment, experiment scoring or valued-clone teardown in this planning stage. Later execution uses merge-cleanup, after the conditions below are met. Do not manufacture an all-clear: bounded review and focused diagnostic probes are not a final combined gate.

**Proposed order: #794 → #795 → remediated #765. Hold #759 separately.** Any documentation PR publishing this plan is not part of the runtime sequence; keep it excluded until its ledger intake can be reconciled after the runtime landings. A new or moved head invalidates that PR's snapshot and requires delta review before admission.

| PR | Pinned head | Base | Scope | Current result |
|---|---|---|---|---|
| #794 | `1712a5790ba7c137cd3c2a29f3d490adc5acb3b8` | development | Four previous-batch regressions | First candidate; prior 419/419 local gate at runtime-identical revision, latest hosted smoke success; no new source blocker found |
| #795 | `bdf23e77b55662e34317908bb7c190f66ec63e3a` | development | Spaced Python executable paths, shared test launcher, ratchet | Follows #7

_Source: issue#796:L150 (Plan QA outcome)_

Agy returned PASS in both review rounds. Round1 driver exited4 with the known GH-763 close-mismatch because the reviewer released to an agent named done; that attempt is not counted as successful QA. Bounded round2 retained the token for the existing shim, returned exit0 and recorded attested Approved against reviewed head `095b6c9cd113`. No production change or manual attestation bypass was used. The substantive plan was unchanged between rounds; only protocol recovery and final status/evidence were added. Relay: `relay-system/2026-09-24/gh796-plan-qa.md`. Driver log and portable attestation record are retained with the evidence. This approves the plan, not the still-unremediated PRs. Existing GH-763 remains separate; no runtime repair was attempted here.

_Source: PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:L31 (Scope and decision)_

Tracking issue: https://github.com/HiQS-Labs/XYZ-forge/issues/796.
Parent adoption arc: #777 (open). Related mechanical wave QA: #784. Existing #791 covers the previous merged batch; #789/#786 cover enhancements to merge-cleanup, not this integration review.

Requested now: source review, conflict/regression flags, an optimal merge/remediation plan in GitHub, and Agy plan QA through relay-xyz. No production fixes, live merges, issue closure, skill deployment, experiment scoring or valued-clone teardown in this planning stage. Later execution uses merge-cleanup, after the conditions below are met. Do not manufacture an all-clear: bounded review and focused diagnostic probes are not a final combined gate.

**Proposed order: #794 → #795 → remediated #765. Hold #759 separately.** Any documentation PR publishing this plan is not part of the runtime sequence; keep it excluded until its ledger intake can be reconciled after the runtime landings. A new or moved head invalidates that PR's snapshot and requires delta review before admission.

| PR | Pinned head | Base | Scope | Current result |
|---|---|---|---|---|
| #794 | `1712a5790ba7c137cd3c2a29f3d490adc5acb3b8` | development | Four previous-batch regressions | First candidate; prior 419/419 local gate at runtime-identical revision, latest hosted smoke success; no new source blocker found |
| #795 | `bdf23e77b55662e34317908bb7c190f66ec63e3a` | development | Spaced Python executable paths, shared test launcher, ratchet | Follows #7

_Source: PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:L150 (Plan QA outcome)_

Agy returned PASS in both review rounds. Round1 driver exited4 with the known GH-763 close-mismatch because the reviewer released to an agent named done; that attempt is not counted as successful QA. Bounded round2 retained the token for the existing shim, returned exit0 and recorded attested Approved against reviewed head `095b6c9cd113`. No production change or manual attestation bypass was used. The substantive plan was unchanged between rounds; only protocol recovery and final status/evidence were added. Relay: `relay-system/2026-09-24/gh796-plan-qa.md`. Driver log and portable attestation record are retained with the evidence. This approves the plan, not the still-unremediated PRs. Existing GH-763 remains separate; no runtime repair was attempted here.

_Source: PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:L7 (frontmatter goal)_

Land reviewed compatible PRs in a verified sequence while preserving deferred work and the incomplete GH-777 arc.

_Source: codex-authored (codex-authored)_

Verify the current status and heads of #794, #795, #765, and #759, the GH-807 hold, and the incomplete #777 arc before updating the integration plan.

_Source: codex-authored (codex-authored)_

Reassess the proposed #794 → #795 → remediated #765 sequence, including changed heads, conflicts, regression risks, and cumulative verification; keep #759 separately on hold.

_Source: codex-authored (codex-authored)_

Plan preservation of current ledger schema and history during reconciliation, and retain partial #765 remediation and deferred work.

## Acceptance criteria

_Source: codex-authored (codex-authored)_

Each candidate has a current status, head-specific review, and explicit admission or hold decision.

_Source: codex-authored (codex-authored)_

The plan identifies required #765 remediation, conflict resolution, cumulative verification, and rollback before any landing.

_Source: codex-authored (codex-authored)_

The GH-807 hold and conditions for resuming remote merges are resolved or explicitly retained.

_Source: codex-authored (codex-authored)_

The plan preserves the incomplete #777 arc and keeps #759 outside the landing batch pending its outstanding evaluation.

## Open questions

_Source: codex-authored (codex-authored)_

Has GH-807 been resolved, and does the operator's remote-merge hold still apply?

_Source: codex-authored (codex-authored)_

Which PR heads, remediation findings, and integration results have changed since the captured review?

_Source: codex-authored (codex-authored)_

What remains of the partial #765 remediation, and what conditions must be met to requalify it?

## Write set

- `PROJECT/2-WORKING/recon-gh796-integration.md` (issue#796:L47)
- `releases.sql` (issue#796:L59)
- `CHANGELOG.md` (issue#796:L60)
- `LEADERBOARD.md` (issue#796:L61)
- `utils/pdda/check_marathon_qa.py` (issue#796:L70)
- `utils/pdda/pdda.sh` (issue#796:L72)
- `PROJECT/PDDA-SYNC-POLICY.md` (issue#796:L72)
- `utils/pdda/check_inventory_ratchet.py` (issue#796:L74)
- `utils/pdda/pdda-lib.sh` (issue#796:L76)
- `test/lib/pystub.py` (issue#796:L84)
- `utils/py/releases_app.py` (issue#796:L105)
- `TESTS-RESULTS/2026-09-24+GH-796/merge-tree.json` (issue#796:L142)
- `relay-system/2026-09-24/gh796-plan-qa.md` (issue#796:L152)
- `validate.sh` (issue#796:L177)
- `ci-local.sh` (issue#796:L177)
- `test/gh139-pipe-grep-guard.sh` (PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:L189)
- `PROJECT/2-WORKING/MARATHON-PLAN-2026-09-25.md` (PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:L195)
- `test/gh-gen4-phase1-domain-oracles.sh` (PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:L213)

## Unresolved file names

- `signal-triage.sh` (PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:L209; 2 tracked files share this name)

## Contract probes

- none
