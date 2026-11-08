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
| Three real workloads produced reviewed PR1371/1372/1373; scheduled final checkpoint661d08ca published, primary clean. Natural sleep continuation and deadline/observer limitations are retained. | Both owned jobs stopped12:12Z before12:30Z cutoff. Parent/user per-PR landing approval is the next external boundary; no-row admission, stale-approval and full qualification remain open. |

## Scope

The live issue owns the bounded qualification of durable decisions and recovery between Jog/Marathon executions. Reuse #1200, #1175 and #1188; this capture creates no competing supervisor design. Execution is authorized by the operator’s subsequent instruction; per-PR merge approval remains required.

## Ratings proposal

pri 75 / sev 35 / appeal 50 / effort 65, stored through `roadmap pickup` in task-branch row `rmi-01M6X64H52SE44FD98KJPZ8BTZ`, followed by `roadmap update --accepted-start`. Initial registration was task-local; the subsequent authorized live rehearsal mutated only primary ledger state through supported CLI/checkpoint publication. Registration occurred during resumed implementation, not before the first source edit.

## Merge evidence

- PR #1324 merged 2026-11-08 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Initial inspection outcome (historical; superseded by implementation below)

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

## Continued isolated rehearsal after parent review

Parent accepted PR1370 head5f98fe6 scope/gates for continued isolated execution,
not merge. Provider-local log shows GH1295 Agy evaluating local regex checks near
the 900s timeout; lock-stall attribution remains unsupported. One of two Marathon
lane attempts is spent; five relay rounds and 900s worker wall/idle caps remain.
Three blocker-repair rounds are a separate task limit, not those lane/QA caps.

Minimal reviewed connection: explicit `jog retry` retains its count, and the next
scheduled `jog run` now routes prior attempts through existing `retry-build` mode,
which uses a fresh token in the same lane family. First dispatch stays unchanged;
cold-start interrupted work still parks. Switch second GH1295 builder to Codex
and reviewer to Agy, preserving the runner's lane attempt file, prior result and
queue identity. No auto-merge, force, cap raise or new full clone to erase budget.


Continuation deployed 2026-11-08T09:54:45Z after the runner-progression full gate
passed409/409 in511s. Frozen manifest/configuration/evidence commit f5c75268a; primary
admission checkpoint4c7f7d3c; prepared runner e9d676e42. Exact command and conservative
12:30Z cutoff are in continuation/manifest.json. GH1295 attempt2 entered Codex,
produced ad7661299 and handed to Agy review; outcome still pending. GH1160 is queued
independently. No parent Git/chat rescue between scheduled wakes.

The existing preadvance command now performs mutation-heavy verification in a
disposable full clone and normal gated candidate push there, then the normal
Marathon docs-tail push/PR. Independent configuration QA required post-test HEAD,
origin fetch/push URL, clean-tree, bare and hook verification before push; applied.
No new runtime gate/supervisor. This preparation is agent-assisted; no merge,
unattended, independent-observer or full-qualification claim.


Deployment-snapshot repair: published intakef3ff5e9d is normally merged into the
retained runner development and1160lane. This is the root setup correction for the
failed coverage check, not a PDDA exception or alternate ledger writer. Old lane
commit93164d4 remains an ancestor; attemptfile hash unchanged. Red1error/green0errors
and frozen repair-window are committed at1a2ec9bb3. New scheduled order1160attempt2
(final allowed), then1216attempt1; source runtime unchanged from5182a77c. No source
full-gate repetition, cap reset, auto-merge or new qualifying claim.

## Additive scope correction and independent observation — 2026-11-08

GH1160 attempt2 created PR1372 and published primary checkpoint da2bc3de. Outer inspection found inherited GH1295 preparation documents; dispatch was halted. Additive624f52c8 removes that scope (normal docs gate166s), preserves all history/receipts and the2/2 counter, and corrects the PR description to AGENTS guidance only. Runner preparation d335e5429 now differs from published development only in GH1216 capture.

A queued wake ran before launchd bootout and refused GH1216 promotion: python3 -c was parsed as missing file -c. Queue attempt1 is retained; no builder started. Shutdown interrupted checkpoint681ab30 publication; a recovery-only scheduled Jog wake published that exact checkpoint. Corrected same behavioral probe uses Python stdin file input under the deployment Python3.13 PATH; validator passes and actual unprefixed export fails the assertion. A bounded second dispatch remains within queue cap2; no third dispatch.

The independent read-only launchd observer (15s interval,120s silence,1800s publication/10800s active ceiling, absolute12:30Z preparation bound) detected the absent supervisor and then active recovery. Initial system-Python deployment could not read Documents (TCC); use of the already-authorized deployment Python repaired observation. This is local process/scheduler observation only, with no host-loss/offhost-delivery claim. Independent QA required journal reread and best-effort supplemental heartbeat; both are applied.

Independent final Codex QA supports a scoped agent-assisted PARTIAL outcome after final receipts settle. Observer samples contain an unexplained469.4s gap10:47:34.880→10:55:24.299; retain UNKNOWN, not host sleep. One135.1s silence detection and recovery is witnessed, but global bounds/slot accounting are unproven. No-row admission and stale-approval coverage remain unfinished; only per-PR approved landing is the present authority boundary.

## Final bounded outcome

GH1216 PR1373 finalheadc50b7616fbe5fabc56705e7894dc9a6cf5b13d6d is independently reviewed, focused56/56 andfull409/409 (one parallelfailure passed existingserialretry). Primarycheckpoint661d08cad249b7815aac21269fb581a18eaaea09 published autonomously, cleanprimary. Bothownedlaunchdjobs disabled/unloaded12:12:33Z, beforefixed12:30Zcutoff; retainedallclones/branches/evidence. Queue1295/1160/1216parkedawaitinglanding,2attemptseach;1344unchanged.

Power-management logs now establish naturalSleep/DarkWake continuation, including465s and979s sleeps corresponding toobservergaps. This supersedes earlierUNKNOWNcause only wherecorrelated; itdoesnotestablishrestart/offhostdetection orcontinuousboundcompliance. Fullgate reports3403s elapsed versusmonotonicguard859s underunchanged1800scap: realelapsedwalltime compliance failed. Existingowner1254deadline and1188observation gaps remainopen. FinalCodexQAapproves meaningfulagent-assistedPARTIAL, notqualification. See continuation/FINAL-RESULTS.md, final-state.json, observer-final-analysis.json andcommittedprovenance.


## Authorized landing continuation and clock repair — 2026-11-08

User authorized PR1370–1373 individually, then remaining transitions; no PhaseB.
One checklist: primary temp/todo-list-2026-11-08-gh1358-landing.md, fixed deadline
19:06:18Z (start17:26:18Z). Existing counters/caps remain unchanged. Merge-cleanup
batch1374 owns serial landing receipts. GH1295 and GH1160 canonical docs must survive
inherited preparation commits; additive upstream merges only. Prior runtime QA reused;
new combined runtime heads go through normal push gates in disposable full clones.

Next bounded implementation under existing GH1254/GH1188 owners: repair the demonstrated
Marathon pre-advance gate elapsed-clock defect. `run_pre_advance_gate` starts/polls/logs
`time.monotonic()`, which excluded Darwin sleep in the retained GH1216 run (3403 real
seconds versus859 reported,1800 cap). A completed child can also escape the deadline
because poll success is accepted before elapsed evaluation. No gate/suite/control-plane
addition. Extend that existing guard to use max(monotonic elapsed, UTC wall elapsed,0),
check wall expiry before accepting completion, retain existing process-group termination
and exit108 attribution. Wall clock jumps forward conservatively expire; backward jumps
cannot subtract awake elapsed. This is a local on-resume bound, not execution during sleep
or an off-host detection guarantee. No silent cap increase.

Easy reversible code change in one function; affects Marathon pre-advance gates only.
An elapsed wall-clock correction is sufficient; a new suspend-aware clock dependency or
second supervisor adds unnecessary platform machinery. Main risk is conservative rejection
when wall time advances or polling is delayed; this is preferable to accepting over-cap work.
Existing observer stays independent/read-only with explicitly awake-host operating envelope;
retain full qualification's off-host/detection gaps, never call awake-only evidence full coverage.

1. Finish authorized serial landings/reconcile and preserve exact receipts.
2. Obtain independent Codex plan QA for the clock seam, then minimally edit existing guard.
3. Record controlled old-code red/new-code green for suspended monotonic time and already-exited
   late child; adjacent normal success, genuine failure and backward wall adjustment. Use the
   actual function under controlled clock/process inputs, not a duplicate implementation.
   Run existing gh390-gate-guard.sh and gh280-jog-marathon-adapter.sh main/adjacent paths in
   a separate disposable full clone; one full gate per host, final QA and normal publication.
4. Continue admission/stale-approval/approved-landing integration within the remaining time;
   no extra GH1160/GH1216/GH1295 attempt (all2/2), no1344retry or fabricated workload.

Review clock plan against this concrete defect/envelope and proportionality. No broad
architecture, new tests, host-power changes, paid access or offhost deployment. Manual controls
are verification, not deployed autonomy. Any new PR remains unmerged pending separate approval.
