---
gh_issue: 1006
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1006
title: "Marathon: bounded progress and safe repair handoff"
status: "Working — PR ready; awaiting review/merge"
created: 2026-10-09
updated: 2026-10-09
owner: Codex
goal: "Bound unattended observation and leave a verified milestone or actionable repair handoff"
branch: feat/XYZ-forge-gh1006-bounded-recovery-2026-10-09
doc_type: feature
effort: 3
complexity: 3
risk: 3
phases: 3
---

## Status

| What was just completed | What's next |
|---|---|
| Plan/final code QA Approved round 3; current-development macOS full gate 409/409, intact clone identity; tested revision published. | PR review/merge; retain #1006 open for held conditional continuation. |

## Table of contents

- [Observed problem and bet](#observed-problem-and-bet)
- [Recon and dependencies](#recon-and-dependencies)
- [Consult synthesis](#consult-synthesis)
- [Phase 1 — Plan QA](#phase-1--plan-qa)
- [Phase 2 — Bounded observation and repair handoff](#phase-2--bounded-observation-and-repair-handoff)
- [Phase 3 — Verification and PR](#phase-3--verification-and-pr)
- [Implementation evidence](#implementation-evidence)
- [Conditional continuation](#conditional-continuation)
- [Acceptance map](#acceptance-map)

## Observed problem and bet

The operator wants evidence of useful work after several unattended hours: opt-in scheduled
progress reports, a bounded path for genuinely minor machinery repairs, and a reviewed repair PR
that can support an explicitly authorized continuation. Completion is not guaranteed. A live
heartbeat and repeated attempts are not accepted progress. Keep one executor, existing locks,
containment, gates and attempt/review caps; reuse consult/start-task/relay rather than a new daemon.

Original observation default: 600 seconds × 6 checks; report terminal outcomes immediately and
end the monitoring window explicitly without killing an authorized run. Recovery must be
separately opted into and budgeted. A three-seat consult is advisory, never proof or authority to
bypass deterministic constraints. Preserve all prior failure receipts and attempts.

2026-10-09 rating rationale: priority 80 (explicit operator scheduling, blocks unattended usefulness),
severity 65 (observed recoverable stalls and wasted operator time; no data loss claimed), appeal 80
(interpretation of the user's explicit desirability, retaining the issue's provisional value),
cheapness 45 (observation is modest; safe continuation is constrained by existing contracts).
No operator rank override. The 2026-09-25–2026-10-09 versus 2026-09-11–2026-09-25 search found
relevant examples #1001/#1002 (one consumer episode), #976 (receipt churn), and #752 (multi-phase
resume refusal). This is examples-based recurrence evidence; distinct incident counts and trend
are unknown, because issue updates/reconciliation are not incident timestamps.

Outcome sought: when the operator returns, the run shows a newly accepted deliverable with
verification, a reviewed repair PR, or an actionable blocker handoff. The latter two are preparation
progress, not shipped product work. We cannot guarantee a milestone or recovery when external
services, ownership or the product contract prevent it. A refusal with evidence is preferable to
spending hours repeating the same failed attempt.

Smallest viable bet: add chain-owned finite observation, and teach the existing supervising agent
an explicitly authorized, bounded repair-to-PR procedure. A runtime autonomous repair controller,
new daemon, scheduler service, eligibility gate, schema, parallel executor and lock changes are
out of scope. The existing heartbeat/fleet views were considered: they cannot deliver scheduled,
run-attributed reports, and liveness cannot prove accepted work. Observation alone cannot repair a
stall, so the procedure retains the repair option without pretending it is automatic runtime code.

Observation is Easy to undo by omitting its flags; the default invocation remains unchanged. PR-based
harness replacement remains Costly: incorrect ownership or revision attribution can consume attempts
or invalidate product review. Containment: no hot edit of an active installed harness, no automatic
merge, no `--force`, no raised caps, no new gates. Rollback of continuation means stop and preserve
the run for handoff; selecting an older harness does not roll back product commits.

## Recon and dependencies

Base: `7435a38cbcccbb7e3cb6fe11db809a7f6562a8c2` from canonical origin/development.
Graph project `XYZ-forge`, generation `2026-09-01T15:54:30Z`, Verify tier, task-directed scope.
The graph found `utils/py/marathon_drive.py::main` and its outgoing calls (32 rows, untruncated),
but coverage reports changed metadata for marathon_drive, consult and rtl. Current source was read
instead. `marathon.sh` has a partial range at line 351, also directly read. This is not a full audit.

| Existing surface | Grounded finding | Implication |
|---|---|---|
| `relay-automation/marathon.sh:266-336` | Launcher owns order, blocks on each driver, halts the chain on any nonzero phase exit. | Observation belongs to this chain lifecycle, not six new checks per phase. Preserve child status. |
| `relay-automation/marathon.sh:241-257` | Existing tee-backed durable run log captures stdout/stderr. | Emit structured progress lines through this supported stream; no second reporting store or notification service. |
| `utils/py/marathon_drive.py:232-278` | Existing opt-in `marathon-drive/result@1` binds execution, phase/lane, product candidate, review and gate. | Request a unique terminal receipt per launched phase; use its identity, not newest-file mtime. |
| `utils/py/marathon_drive.py:1473-1550` | Atomic per-phase driver heartbeat, refreshed by one daemon thread and cleared at exit. | Read it for activity; it is not accepted progress. |
| `utils/py/marathon_drive.py:2660-2749` | Success binds acceptance, gate and independent reviewer attestation; already-satisfied has an explicit reason. | Count accepted receipts separately from re-verification; never infer approval from relay prose alone. |
| `utils/py/jog_run.py:651-854` | Resume reconciles receipts; retry-gate and retry-build are explicit, ownership-checked verbs. | Reuse semantics in procedure; do not route the multi-phase chain into a new Jog executor. |
| `utils/py/consult.py:621-675` | Codex/Agy/Claude advisory seats exist; success may mean only one seat answered. | Read each seat; process exit zero is not a quorum. |
| `relay-automation/xyz-vendor.sh:430-449` | Existing vendor mirrors utils plus relay-automation. | Python reader travels through normal adoption; no new manifest or install workflow. |

Blast radius: opt-in launcher reports, its stdout consumers, phase result emission and vendored
launchers. Existing phase order/dispatch, coordination writers, driver locks and product verdicts
remain authoritative. Reporting failures must degrade visibly without changing the marathon exit.
SIGKILL/host failure cannot guarantee a final report; normal exit and catchable signals must cancel
the observer, which also exits if its owning launcher disappears.

External dependencies: [PR #1004](https://github.com/HiQS-Labs/XYZ-forge/pull/1004) is OPEN at
`51ec2ba59b13a10ac3d8c370b19aae2fa51225f0` (2026-10-09 read): it repairs consumer root selection
and scratch/cap behavior. [#752](https://github.com/HiQS-Labs/XYZ-forge/issues/752) documents
whole-tree attestation refusing a multi-phase re-fire after later phases land. Neither repair is
duplicated here. Observation can ship independently. Consumer adoption/recovery must account for
both and cannot claim that setting a harness path proves safe resume. Surviving descendants after
driver exit are another handoff uncertainty requiring a demonstrated stop boundary.

## Consult synthesis

TLDR: all three seats recommend finite observation plus a bounded skill procedure before a runtime
repair controller. Their source reviews are advisory; none ran verification. The consult harness
stamped Codex/Claude with missing-firsthand-verification warnings; citations remain conditional.
Raw receipts: `relay-system/2026-10-09/gh1006-design-082143/`.

Disagree: Codex favors two affirmative seats for diagnosis with a concrete safety objection veto;
Agy and Claude require unanimity. Choose three explicit affirmative recommendations for unattended
repair, and park on a missing/abstaining seat. This is a conservative decision rule, not a safety
proof; independent post-change QA and deterministic constraints still decide readiness.
Codex places observation at marathon.sh; Agy proposes Jog; Claude proposes a detached observer.
Choose a finite read-only child owned by marathon.sh, retaining serial phase execution. This
extends the current chain supervisor and avoids a second executor or a second runtime state machine.

Agree: no guaranteed completion; heartbeat is activity; genuine cap exhaustion is not inherently a
harness bug; repairs need full-clone isolation and independent QA; PR publication is not merge or
safe resume. Budgets persist across successor tokens/invocations.

Blocking for continuation: exact replacement harness revision attribution, stopped descendants,
preserved state/attempt identity, #1004 dependency composition, and demonstrated #752-safe re-entry.
Worth doing: the observation and repair-to-PR procedure now; optional longer windows through explicit
check-count selection. Skip / out of scope: pausing/extending deadlines during repair, new Bash
observer or eligibility gates, a Jog chain executor, bypass flags, auto-merging, deleting repair
clones with unfinished evidence, and unsupported conversational-delivery guarantees. These were
advisor suggestions, not adopted requirements.

## Phase 1 — Plan QA

Commit this plan and review inputs; invoke Codex through the shipped relay-xyz workflow with a
three-round cap. Require a grounded approval on the implementation boundary and acceptance map
before production edits. Record dispositions for every finding. Then admit the exact GH-1006
roadmap row via `--accepted-start` (registration/rating/QA are not execution starts).

QA gate:

- [x] Plan relay Approved round 3; current independent receipt: `relay-system/2026-10-09/gh1006-plan-qa.codex.md`.
- [x] Owned roadmap row reads back 80/65/80/45 and the active doc pointer; accepted-start after plan approval.
- [x] Observations, disagreements, dependencies and unknowns captured above.

## Phase 2 — Bounded observation and repair handoff

Signal-design probe (macOS, disposable clone): foreground sleep deferred launcher TERM for 0.954s;
background child + Bash wait delivered it in 0.001s (same exit 143). This proves the wait choice, not
the full observer lifecycle. Receipt: `TESTS-RESULTS/2026-10-09+GH-1006/baseline/signal-design-probe.json`.

One ordered implementation list, verification inline:

1. Extend `marathon.sh` with opt-in `--progress-interval-s` and `--progress-check-count`. Supplying
   either enables 600/6 defaults for the other; positive integers are bounded (interval <=86400,
   count <=144, total window <=86400 seconds). Validate before dispatch, show effective dry-run
   settings, and refuse the feature with `XYZ_PYTHON=0` because that frozen driver lacks result
   receipts. Existing Bash fallback invocations without these flags remain supported -> bad/zero/
   overflow flags fail before a phase; ordinary dry-run stays compatible.
2. Expose a stdlib-only read/report helper (~300 lines ceiling) through the existing
   `marathon.sh --progress-observer` internal subcommand; GH-777 forbids a new loose script. It
   never dispatches, signals workers, mutates coordination state, changes caps, or grades a run.
   `marathon.sh` is the sole writer of a run-log-adjacent observation context, atomically through
   this helper. The context is an ephemeral projection, not operational state; the run log is the
   durable report. Bind run ID, owner, plan, harness/product roots, initial SHA/origin, phase index/
   lane, and unique execution/result path at launch -> stale/foreign receipts cannot count.
3. Start one finite reader child after validated plan parsing and before the phase loop; use N
   absolute monotonic deadlines (N = effective count), carried across phases. Only when observation
   is enabled, launch each phase as one background child and synchronously `wait` for it before
   starting any successor; Bash's interruptible wait lets launcher-only INT/TERM reach cleanup
   promptly. Normal/catchable exit notifies/reaps the observer within one second on a responsive
   host; parent loss self-terminates it within one second. Forward INT/TERM to the directly owned
   phase process, retain interruption status (130/143), and report descendant ownership as unknown;
   no descendant-stop or safe-refire guarantee is implied. Without observation, foreground calls
   stay unchanged. Each snapshot read is bounded. After suspension, emit missed-slot records for
   earlier due slots and one current snapshot for the latest due slot; all consume N. If the whole
   window elapsed, mark 1..N-1 missed, snapshot N now, end observation immediately without extending
   it -> phase changes do not reset N; no N+1 report appears. Default N=6 has no check 7; explicit
   N=18 allows 7 and ends at 18. Window expiry prints next action and stops only observation.
4. Before each serial phase call, publish exact phase context and forward a unique
   `--execution-id`/`--result-file` to the existing Python driver. After exit, record status and
   consume only a matching approved receipt with green gate and bound reviewer candidate. Mark
   `already-satisfied` as verification activity, not a new milestone. Read exact relay/heartbeat
   paths for role/review/liveness; missing/malformed data stays unknown. At each due check emit
   run/clone identity, phase/role, heartbeat age, last qualifying milestone, completed/total,
   gate/review, and receipt/log pointers -> heartbeat-only or stale data cannot report acceptance.
5. Document the stdout/run-log caller contract in existing `relay-automation/README.md`; add the
   bounded repair procedure to existing `skills/1-hourly/relay-xyz/SKILL.md`. No conversational
   update is guaranteed when the caller is not actively consuming output. A longer away window
   requires explicit settings, e.g. 600×18 for three hours; the default still ends after one hour
   -> docs distinguish liveness, product progress, preparation progress, window end and halt.

The supervising agent procedure requires explicit launch-time repair authorization, one repair
episode, at most one continuation dispatch, and an absolute UTC recovery deadline supplied by the
operator. Diagnosis, consult, implementation, both QAs, gates and publication consume that shared
allowance; no nested repair and no new token resets it. The caller must remain active; skills are
not durable background services. On genuine halt, preserve/report it immediately; recovery is a
separate successor action. Do not rewrite the halt or extend observation.

Eligibility: reproduce a local machinery defect, trace its cause with debug-mantra, state a narrow
allowlist and falsifier, inspect existing PRs, obtain three affirmative advisory seats, then use
start-task's isolated repair clone and independent plan/final relay QA. Small line count is not
eligibility. Exclude lock/ownership, containment, gate/review semantics, schemas, auth/network
bridges, dependency expansion, deletion, product-scope changes and unknown causes. Publish a PR to
development and default to park with the original receipt, repair SHA, review/gate pointers and
single next action. No runtime code in this phase automatically diagnoses, edits or re-fires work.

QA gate:

- [ ] Flags/defaults and finite schedule meet the acceptance map.
- [ ] Reader cannot dispatch or mutate operational state; context has one launcher writer.
- [ ] Procedure retains original failures/attempts, mandatory QA, hard exclusions and deadline.

## Phase 3 — Verification and PR

Use existing `test/marathon.sh`, `test/marathon-monitor.sh`, `test/gh280-jog-marathon-adapter.sh`
receipt coverage and applicable package/frozen-twin checks. Do not add new suites, registry entries,
gates, runners or telemetry stages. Record manual clock-controlled checks under
`TESTS-RESULTS/2026-10-09+GH-1006/` with committed provenance and nonempty outputs. Show red controls
for reset-per-phase, N+1 check, stale/foreign/empty receipt, heartbeat-only acceptance, duplicate
re-verification, terminal cancellation, parent loss, bad bounds and missing data. Check default N=6
versus explicit N=18, and clock jumps over several slots and beyond the whole window, proving missed
slots consume N without historical snapshots or deadline extension. On macOS measure child exit,
launcher-only TERM/INT, process-group TERM, and actual owner disappearance separately; the
one-second observer-cancellation claim needs a full launcher probe, not just a shell-semantics read. Narrow deterministic
manual probes are evidence artifacts, not a new registered test suite.

Run mutation-heavy checks only in a separate disposable full clone, bracketed by identity checks.
Run focused checks during iteration; run the final classified full gate once on the final approved
runtime commit. Regenerate the existing relay package after README changes. Independent final
Codex QA must return Approved with receipts before a ready PR into development. Keep the task clone
for merge handoff; no automatic merge or teardown with unique work.

QA gate:

- [ ] Existing suites and manual red/green controls have retained provenance.
- [ ] Classified final gate and PDDA report truthful results; identity is intact.
- [ ] Final relay is Approved; emitted PR base/head/diff match the reviewed artifact.

## Implementation evidence

Plan QA is independently attested Approved at producer head `3b5a9a12c3a8201e453967632e27692a029937e6`.
The launcher remains the only executor and context writer. Terminal cancellation sets a context
stop marker and waits for the reader, avoiding a stale observer-PID signal after window expiry.
A process-group TERM probe exposed a dead run-log reader and exit -13; the opt-in tee now ignores
INT/TERM until the stream closes. Red/green minimal probes isolate the logger as the origin.
Root cause: group TERM killed tee before the terminal write; fix site: opt-in logger signal
inheritance; downstream broken-pipe handling would lose the durable terminal record.

Focused proof: existing launcher 35/35, monitor 17/17, receipt adapter 223/223, and bounded manual
schedule/receipt/signal/read-only controls. Retained evidence and exact source hashes live under
`TESTS-RESULTS/2026-10-09+GH-1006/`; final QA and classified gate remain separate obligations.

Final QA round 1 found no material observer-runtime defect; its two Should findings concern
pre-existing reviewer expansion and maintained-clone test recipes. Literal reviewer IDs and
disposable-full-clone verification now resolve those findings; 16 clean/conflicting environment
argv probes, the old-command red control and package freshness are retained in `recipe-fix/`.
Integration merged `ecec5561` through the repository RELEASES conflict resolver: both GH-1005
and GH-1006 histories, original admission timestamp and rating survived; no observer code changed.
Round 2 independently approved the resulting artifact at `bd6c7f55`. Receipt: `relay-system/2026-10-09/gh1006-final-qa.codex.md`. Branch renamed to the SOP folder-based naming formula before publication; runtime/package hashes are unchanged. The first full gate exposed GH-777
inventory rejection of the new loose helper. The helper payload now routes through an existing
launcher subcommand; no guard/baseline is weakened, and reader roles remain unchanged. The
remaining third final QA round covers this placement correction and retained fresh probes.
The unchanged GH-492 suite also failed 2 parallel timing assertions (14/2) and passed focused
16/0 on identical diagnostics bytes. It is outside Small. The standing AGENTS #802/#853 rule
requires removing its full-gate registration and adding the gh306 exemption; manual use remains.
No idle-diagnostics runtime repair or claim of harmlessness is made here. The
failed full run is retained in `gate-correction/`; clone identity stayed intact. Its serial retry passed GH-492 and final red was GH-777 alone. Current embedded reader has fresh 38+13 passing controls and launcher 35/35; inventory and registry existing controls pass. Evidence is in `embedded/` and `gate-correction/`; the earlier `manual/` module-layout hashes are historical. A passing classified gate remains owed.
No accepted product milestone is claimed from these fixtures. Conditional continuation is held.

## Conditional continuation

Held work, explicitly not a shipped capability of this first delivery: a budget-preserving handoff
to a verified unmerged repair PR. Publication alone cannot enable it. Before enabling this path,
prove exclusive ownership and stopped descendants; verify exact PR head/base and independent QA/
gate receipts; bind original authorization/plan/state roots plus repair SHA; preserve prior failure
receipts/attempt counts; prove #752-safe re-entry and #1004 adoption; run normal preflight/dry-run.
Use a separate immutable per-run harness checkout, never hot-patch an installed harness. Require
explicit authorization for the unmerged dependency. No merge/promotion occurs. If any predicate is
unknown or deadline/cap is exhausted, keep the reviewed repair PR and park with a specific action.

Future verification must falsify wrong SHA, live descendants, altered state root, exhausted budget,
missing QA, and a fresh-token reset. This is a prerequisite-bound stage, not permission to waive
those checks or silently add a controller. Completing observation/procedure does not close #1006
as guaranteed unattended recovery; the PR must describe this delivery boundary.

## Acceptance map

| Requirement | Delivery / proof |
|---|---|
| Validated opt-in 600×6 and effective dry-run | Launcher; bad bounds and default output probes |
| Run-bound rich reports, no heartbeat-as-progress | Context reader; matching receipt and heartbeat-only red controls |
| Supported caller delivery | stdout + durable chain log; README states chat limitations |
| Immediate terminal + cancellation | Interruptible wait + EXIT lifecycle; four signal/exit probes with measured latency |
| Explicit window end without killing work | Finite reader; N=6/18, missed slots and end observed while executor survives |
| Read-only observer, unchanged caps/locks | Diff review + manual state before/after |
| Bash/Python compatibility honest | Default unchanged; opt-in legacy refusal tested; no frozen twin edit |
| Three-seat repair decision, PR and handoff | Existing skill procedure; separate QA/gates; automatic continuation held |
| Several-hour operation | Explicit longer window; separate absolute recovery deadline; no outcome guarantee |

Final code QA round 3 independently Approved the current artifact at `c0abced3`; the shipped relay exited 0 and attested the review. Receipt: `relay-system/2026-10-09/gh1006-final-qa-r3.codex.md`. The three-round budget is exhausted. Required classified full gate and PR checks remain separate obligations.

Publication integration update: development advanced to `3c829e0d`, including merged PR #1004 (`53e40d6c`). Merge `5129704d` resolved only CHANGELOG, ledger dump/derived DB and the generated relay package. The repository resolver retained the original GH-1006 admission/rating/history and all five selected issue rows; GH-1005 uses upstream’s latest existing row. The composed 18-file package matches source. All five authored production files are byte-identical to round-3-approved source; upstream driver receipt/heartbeat shapes are unchanged. Imported GH-1001/1002 seams have their own independent Approved receipt at `relay-system/2026-10-08/gh1001-1002-final-qa.md`. No fourth review round or fresh recovery budget is opened. Fresh composed launcher35, receipt-adapter223, package3 and PDDA checks pass; clone identity stayed intact. Receipts are in `TESTS-RESULTS/2026-10-09+GH-1006/integration/`. The required publication gate remains pending. #1004 adoption is now observed on this branch; #752-safe re-entry, stopped descendants, ownership and budget attribution still hold automatic continuation.

Publication qualification: exact composed revision `85a03218` passed the configured full macOS push gate 409/409 in 970 seconds; Python layer21 also passed and identity stayed intact. The initial network update raced the earlier gated publisher and was rejected after GREEN. Fresh remote readback plus ancestry/unchanged-head proof justified the documented already-gated `XYZ_SKIP_PREPUSH=1` retry, which pushed normally without force. Both the rejected update and successful retry are retained in `publication/`; the first successful older-base 409/409 run is historical `first-green/`. The final evidence/status-only follow-up uses the normal deterministic documentation gate. These push gates are PR checks, not promotion evidence or permission to merge.

Retirement: preserve this task clone and its disposable verification/gate clones until the PR lands and required origin verification finishes. Raw local receipts and probe fixtures remain under their `temp/` directories; no teardown is performed here. After verified landing, use `/merge-cleanup` with the repository safety checks.
