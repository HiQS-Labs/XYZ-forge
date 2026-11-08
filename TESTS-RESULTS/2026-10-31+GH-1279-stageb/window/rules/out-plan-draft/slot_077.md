# Plan draft: #1022 Umbrella: Daily issue intake and weekly auto-* Jog/Marathon planning branches

> draft; preflight and independent plan QA outstanding

- Request: `gh-1022-cfe827e1ed3d` (tick `slot_077`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: cfe827e1ed3dbbbac3e5583f29e746571e7594f3ab81aad67f9953ded8ad0e11 (updated 2026-10-23T05:35:11Z)
- Dependencies: none

## Scope

_Source: issue#1022:L1 (Outcome and scope)_

Build daily GitHub issue intake that accumulates a weekly, branch-backed Jog or Marathon **proposal**, ready for operator-approved execution at the end of the week. The operator requested a branch series named `auto-yyyy-mm-dd` containing intake docs and computed plans, and explicitly requires the branch's **RELEASES ledger DB to be updated with ALL relevant GitHub issues**.

Broad intake/registration and narrow executable selection are different stages. The branch ledger must reconcile new issues, relevant existing/open updated or reopened issues, weekly members, carryovers, dependencies and associated PR state; it must not register only the few tasks selected to run. GitHub remains the issue signal stream, RELEASES remains the canonical planning ledger, and project docs remain the execution-detail surface. Do not introduce a parallel backlog.

This issue records design and future implementation scope only. Its creation does not authorize implementation, branch creation, scheduling, ledger writes, dispatch or paid execution.

_Source: issue#1022:L117 (Anti-goals and related ownership)_

No second backlog, speculative ledger values, direct SQL edits, production-ledger overwrite, competing active Marathon, standalone Jog YAML, unapproved budget, automatic merge, blind re-fire or dispatch from a generated report. Do not absorb #897's hourly-selection design or treat #606 as an intake scheduler. Keep #752's re-fire blocker explicit. This issue does not create branches, write the ledger, schedule runs or execute any task.

Do not auto-close GitHub issues from this protocol, infer completion from issue status/PR existence alone, rewrite equivalent working implementations to match stale plans, replay approved phases blindly, dispatch a materially changed packet under old approval, or treat fire approval as merge/deploy authority. Preserve #752/#1020 recovery constraints and strengthen the existing review/preflight path rather than adding a parallel checker.

Do not treat acceptance scenarios, an existing suite location, emergency recovery, reviewer advice or general issue/plan/phase/Marathon/PR approval as permission to add a CI test. No individual new CI test is added without the operator’s explicit approval identifying it. Running existing tests remains allowed within existing authority.

## Acceptance criteria

_Source: issue#1022:L54 (Proposed architecture and ordered acceptance checklist)_

1. [ ] **Choose and record the weekly branch policy.** Use the required `auto-yyyy-mm-dd` series, with one writer in an isolated full clone. A Monday-dated weekly branch accumulating daily changes and a Friday Pacific-time freeze are **proposed configurable defaults**, not confirmed constraints. Keep source implementation off planning branches. Record the base branch/SHA and branch identity; no force-push that invalidates reviewed revisions.
2. [ ] **Implement complete, restartable GitHub intake in the shared planner path.** Fully paginate new/updated/reopened issues, excluding PR records from the issue inventory, and read associated PRs plus relevant existing members/carryovers/dependencies. Use repository-qualified GitHub identity and stable ledger GIDs, overlap and deduplication. Advance the intake checkpoint only after complete reads and durable canonical doc/ledger/receipt writes. A partial/offline/access failure produces an explicit incomplete/UNKNOWN report and holds promotion; it must not advance the checkpoint or silently drop issues. Define the relevant-issue boundary and account for every included issue.
3. [ ] **Register/reconcile ALL relevant issues in the branch RELEASES ledger.** Accumulate canonical `PROJECT/1-INBOX/GH-<number>-<slug>.md` captures using `hq_render_capture` in [hq-lib.sh](https://github.com/HiQS-Labs/XYZ-forge/blob/development/utils/hq/hq-lib.sh), and register/reconcile through [releases_app.py](https://github.com/HiQS-Labs/XYZ-forge/blob/devel

_Source: issue#1022:L99 (Definition of done)_

The operator can inspect a preserved `auto-yyyy-mm-dd` commit containing intake docs, the CLI-reconciled branch RELEASES ledger for **all relevant issues**, complete intake accounting, a reasoned weekly selection and valid canonical execution artifacts. Every selected item has fresh readiness/acceptance and every exclusion has a reason. Incomplete intake, unknown CI/dependencies or changed approval state holds dispatch. Approved execution is a separate action, bound to the exact reviewed packet. Ownership, approval and limits are visible; no implementation/delivery claim is inferred from plan generation.

Completion additionally requires the shared pre-fire prior-art protocol above: criterion-level current-code coverage, an exact HEAD/plan-bound independent review receipt, fresh drift checks, explicit per-phase delta/hold decisions and a separate latest-target pre-landing regression/redundancy review. All-delivered work produces a no-op. These are required future acceptance conditions, not claims of existing implementation.

Completion also requires the per-test moratorium to remain effective at intake, plan generation, firing, every execution/resume boundary and landing: every individual new CI test in the actual delta has its explicit operator approval, and unapproved proposals remain excluded. Verification gaps are disclosed rather than hidden by a passing or incomplete report.

Completion also requires the new `weekly` skill to use the reviewed shared intake helpers and e

## Open questions

_missing_

## Write set

- `skills/3-weekly/weekly-planner/scripts/planner_core.py` (issue#1022:L11)
- `utils/py/marathon_plan.py` (issue#1022:L13)
- `utils/py/_marathon_plan.py` (issue#1022:L28)
- `utils/hq/hq-lib.sh` (issue#1022:L58)
- `utils/py/releases_app.py` (issue#1022:L58)
- `releases.sql` (issue#1022:L58)
- `utils/py/marathon_yaml_emit.py` (issue#1022:L61)

## Unresolved file names

- `MARATHON.yaml` (issue#1022:L61; 16 tracked files share this name)

## Contract probes

- none
