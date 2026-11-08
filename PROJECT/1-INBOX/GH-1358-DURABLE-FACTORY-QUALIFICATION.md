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
| Implemented opt-in primary checkpoint publication; manual controls and existing 227-assertion adapter pass; launchd rehearsal entered publication and interruption recovery. | Finish scheduled evidence and final gate/QA; remaining discovery, observer, eligible-work and approved-landing transitions stay open. |

## Scope

The live issue owns the bounded qualification of durable decisions and recovery between Jog/Marathon executions. Reuse #1200, #1175 and #1188; this capture creates no competing supervisor design. Execution is authorized by the operator’s subsequent instruction; per-PR merge approval remains required.

## Ratings proposal

pri 75 / sev 35 / appeal 50 / effort 65, stored through `roadmap pickup` in task-branch row `rmi-01M6X64H52SE44FD98KJPZ8BTZ`, followed by `roadmap update --accepted-start`. Initial registration was task-local; the subsequent authorized live rehearsal mutated only primary ledger state through supported CLI/checkpoint publication. Registration occurred during resumed implementation, not before the first source edit.

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
subscription tools only, 900 seconds per turn, three independent QA rounds. Phase B is not scheduled.
First publication controls consume zero model turns. Scheduled real execution is limited to
three task dispatches before reassessment; no unapproved merge or new spend.

Investment: removes demonstrated manual ledger publication between wakes; real queue changes
and failed-push recovery discriminate it from the assisted baseline. Short transition evidence
can falsify the design immediately; idle soak adds no decision value.

### Rehearsal correction

Local launchd invoked the real Jog/Marathon path at 60-second cadence (no idle soak).
GH1344 was parked before scheduling with its existing attempt counter preserved.
GH1345 parked on missing active contract and published through the installed normal hook.
GH1296 was mistakenly labeled held: its current contract actually passed preflight and
started agy with the existing Marathon default `--round-cap 5` (not the three-round QA cap).
Because its residual acceptance depends on the unavailable original backlog, the owned
attempt was stopped by explicit PID ancestry before accepting it as useful build work.
This is one workload-selection repair, agent-assisted; no held-refusal or throughput claim.
The third scheduled wake completed cold-start park and publication at 26543a0018, without a manual Git/CLI
recovery. The deployment was disabled and booted out after that wake finished. Keep all local-only lane/deployment state. Full issue acceptance remains open.

Ledger integration: after the canonical primary queue checkpoints landed, selected the clean primary ledger snapshot and reapplied this task-only row through `roadmap pickup`/`--accepted-start`, then ran `releases-merge-resolve.sh` (check clean). Original task-row identity remains in 7046047d6 history; live GH1344/GH1345/GH1295 queue states and counters were preserved. No SQL statements were authored. Routine generated view changes were restored from the pre-merge copy and excluded.

Live continuation: GH1295 passed real OPEN preflight, then first Agy turn timed out at 900 seconds without artifact (Marathon exit 7). Scheduled Jog published primary failure state at 632a2a5d8bd21bb08fcb49473c5f931eb72dc4c0 without parent Git rescue. Attempt 1 retained; usage unknown. Empty next wake exposed redundant same-SHA push gate; minimal live-ref check repaired, old-code red and new main/adjacent controls recorded, independent Codex QA approved. See live/README.md. Full qualification remains unmet; no workload PR/merge or Phase B.
