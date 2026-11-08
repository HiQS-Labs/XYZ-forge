---
gh_issue: 1358
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1358
title: "Durable factory qualification after Batch 2"
status: Active (checkpoint integration)
created: 2026-11-07
owner: unassigned
doc_type: experiment
---

## Status

| What was just completed | What's next |
|---|---|
| Bounded readiness inspection completed: Phase A NOT READY; seven composition transitions NOT EXERCISED. | Identify deployed composition, observer, meaningful workload and numeric dispatch budgets under existing owners; no Phase B. |

## Scope

The live issue owns the bounded qualification of durable decisions and recovery between Jog/Marathon executions. Reuse #1200, #1175 and #1188; this capture creates no competing supervisor design. Execution is authorized by the operator’s subsequent instruction; per-PR merge approval remains required.

## Ratings proposal

pri 75 / sev 35 / appeal 50 / effort 65, as proposed in the issue; not stored in PRS until committed selection.

## Merge evidence

- PR #1324 merged 2026-11-08 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Short attempt outcome

Phase A NOT READY: bounded manual controls only; all seven deployed composition transitions NOT EXERCISED. See `TESTS-RESULTS/2026-11-08+GH-1358-rehearsal/SUMMARY.md`. No Phase B start. Next: identify deployment, observer, workload and numeric dispatch budgets through existing owners.

## Checkpoint integration implementation (2026-11-08)

Resume in the provisioned linked worktree, baseline bc2d79398. Existing issue plan and
seven transitions remain authoritative. No full-issue qualification is claimed by this delivery.

The next capability is two scheduled `releases jog run --max-tasks 1` invocations which
publish their owned primary ledger effects without parent Git rescue. Existing queue
selection already ignores parked rows; existing Marathon and cold-start projection remain
execution authority. `publish_jog_receipt` publishes lane evidence, not primary checkpoints.

Extend `jog_run_main` with opt-in `--checkpoint-root`: dedicated disposable full publication
clone, same origin, development branch. Hold existing supervisor lock through publication.
Journal `.tick/jog/checkpoint.json` binds the clean published starting SHA to the owned
ledger commit. Recover an interrupted wake before new dispatch; only existing orphan and
Marathon cold-start reconciliation may reproject it. No automatic build retry. Publish an
exact checkpoint SHA with a normal non-forced push from the disposable clone; refuse
foreign dirt, divergent histories or extra publication-clone commits. Install/check the
existing hooks in deployment. Default invocation remains unchanged.

Reversibility: Easy for opt-in code and local deployment; disable scheduling and preserve
journal/clones to roll back. Publishing real primary checkpoints is Costly: preserve commits,
never reset or rewrite shared refs. This rehearsal initially targets a local bare transport,
not remote development. No primary ownership is taken by this implementation.

1. Add checkpoint publication inside the existing supervisor; independently review concrete
   paths and failure cases, including exact-SHA publication and interrupted wake recovery.
2. Verify main two-wake publication, retry after rejected push, and unrelated-dirt refusal
   with manual provenance; run existing gh280 adapter suite in a separate disposable full clone.
3. Deploy the supported invocation to local launchd with a bounded window and retained logs;
   exercise actual queue transitions, preserving GH1344 exhausted counters. Distinguish
   fixture controls from real-work composition evidence. No primitive-only autonomy claim.
4. Run final independent QA and classified gate, publish reviewed delivery to development
   via PR, then continue the remaining transition table within original authorization.

Budgets: preparation maximum six hours across this attempt, maximum three repair rounds per
blocker across sessions, one task per wake, no automatic retries, builder agy/reviewer codex
subscription tools only, 900 seconds per turn, three review rounds. Phase B is not scheduled.
First publication controls consume zero model turns. Scheduled real execution is limited to
three task dispatches before reassessment; no unapproved merge or new spend.

Investment: removes demonstrated manual ledger publication between wakes; real queue changes
and failed-push recovery discriminate it from the assisted baseline. Short transition evidence
can falsify the design immediately; idle soak adds no decision value.
