---
gh_issue: 1254
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1254
title: "Outer loop (#1248): borrow declared supervision and cache-warmth dispatch from clodex"
status: Partial implementation merged — acceptance gaps remain
created: 2026-10-29
updated: 2026-11-08
owner: Codex
doc_type: feature
complexity: 2
risk: 2
effort: 3
phases: 1
ratings_provisional: true
non_goals:
  - no Clodex dependency
  - no intent parsing
  - no agent-to-agent messaging
  - no change to jog/marathon dispatch
  - no new test files (GH-831)
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1248
goal: >
  Borrow declared supervision (FACTORY_SUPERVISED=1) and cache-warmth dispatch into the #1248 outer loop primitive.
---

## Key concepts

- Declared-not-detected supervision: explicit `FACTORY_SUPERVISED=1`, refusing restart if undeclared.
- Cache-warmth-aware dispatch: record cache tokens, evaluate cold TTL, defer non-urgent items for cold arms.

## Status

| What was just completed | What's next |
|---|---|
| PR1369 merged with user approval; independent QA Approved, integrated full gate 409/409, reconciliation published. | GH1254 remains OPEN: restart verification, overloaded deadlines and observed live savings require follow-up. |

## Idea

Borrow two high-value operational patterns from Clodex into the #1248 outer-loop primitive:
1. Declared-not-detected supervision: check `FACTORY_SUPERVISED=1` instead of inferring from PID/launchd.
2. Cache-warmth-aware dispatch: track prompt cache token states and defer low-priority calls when cache is cold.

## Why

Improves reliability and token efficiency of long-running autonomous software factory sessions without adding heavy orchestration dependencies.

## Phase 0 — Explore & scope

### Checklist

- [ ] Add `FACTORY_SUPERVISED` check to tick/watchdog in `utils/py/harness.py`.
- [ ] Enforce restart refusal when supervision is undeclared.
- [ ] Instrument cache-read vs cache-creation tokens in `#1248` telemetry.
- [ ] Add `urgent` flag and cold-context deferral logic.

### QA checklist — Phase 0

- [ ] Undeclared supervision causes self-restart to refuse with recorded receipt reason.
- [ ] Non-urgent items aimed at cold context defer up to configured slot limit; urgent items run immediately.
- [ ] No new test files (GH-831); verified against existing python layer test suite.

## Ratings rationale

pri 60 / sev 40 / appeal 50 / effort 50 (extends factory-primitive resilience and cost efficiency).

## Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "python3 -m pytest test/test_python_layer.py",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/py/harness.py", "pattern": "FACTORY_SUPERVISED",
      "note": "pre-fix: harness.py does not check FACTORY_SUPERVISED declaration" }
  ],
  "artifacts": [ "utils/py/harness.py" ],
  "remediation": {
    "source": "issue#1254",
    "criteria": "Check FACTORY_SUPERVISED in tick/watchdog and implement cache-warmth dispatch telemetry; no new tests (GH-831)."
  }
}
```

## Implementation plan — 2026-11-07

Agent-assisted GH-1356 lane. Owner: implementation agent; parent is outer reviewer.
Base 938a96e60542e6bff1234d1e5fddfadec646c706. Selection row
`rmi-01M6WTMK376C3R6EGNG4BG4HTH`, rated 60/40/50/50: moderate reliability/cost impact,
user-selected batch priority; appeal neutral. Recurrence trend unknown; no new incident count inferred.

Recon: harness.py owns init_instance, _snapshot, run_tick, AdapterResult and codex_decide.
Existing inbox status and events provide durable dispatch state without a schema change.
Each instance is one adapter arm. Codex calls are ephemeral; time-based warmth is a heuristic,
not proof of cache reuse. Billing stays unknown absent reported accounting.
GH-1248 plan and TESTS-RESULTS/2026-10-29+GH-1248/SUMMARY.md defer watchdog;
the historical scheduler is a gitignored external driver. No restart command or launchd generator
exists in the factory CLI. Parent explicitly chose truthful declaration receipts, no new scheduler.
Restart acceptance remains OPEN, owned by GH-1248 scheduling follow-up and parent GH-1358 planning.

Bet: bounded waiting may batch low-urgency work, but does not guarantee cache savings.
Easy to revert: local additions to existing factory primitives; no schema migration or dispatch changes.
Blast radius: factory scenario validation, snapshots, adapter telemetry, tick receipts; no make_packet changes.

1. Report explicit FACTORY_SUPERVISED truth values in tick receipts, with restart_performed false and a reason; never infer supervisor existence or permission from process ancestry.
2. Add nullable cache-read/create usage to AdapterResult and per-call telemetry; extract only reported Codex usage values, including failed calls where present.
3. Configure positive cache TTL seconds and nonnegative maximum deferral slots at initialization, retaining values in config/run metadata. Read urgent booleans from the immutable scenario. Compare last actual call timestamp from events; no prior call is cold. Filter cold nonurgent items until arrival slot plus limit; urgent/deadline items remain eligible. Log deferred-cold IDs/deadlines, preserve pending inbox rows. Avoid an adapter call when all work is deferred. Warmth never implies known billing. Default zero deferral preserves existing runs.
4. Record manual red/green controls and main/rerun smoke in a disposable full clone, with provenance. Compare identical scenario with deferral disabled/enabled using stub-reported accounting, clearly label modeled evidence; unknown live accounting means no observed savings claim. No new suites.
5. Independent final QA, applicable existing gate, then PR to development leaving #1254 open for restart acceptance. No merge/watch or generated packet dispatch.

Plan/final review cap: three rounds each; blocker repair rounds: zero at plan creation.
No #1344/#1345 attempts, no #1358 run.

### Plan QA round 1 disposition

Accepted: cache eligibility is not execution. N bounds cache-imposed withholding, not arbitrary
backlog execution. Two simultaneous notes and one action per tick falsify unconditional deadline
execution; Codex can also select idle. Keep stronger acceptance OPEN, never call eligibility execution.
Within existing dispatch, order deadline-expired deferred items first and use existing rules_decide
for their selection, so a feasible single due item runs now rather than being skipped by the model.
Do not add a scheduler: a saturated two-note deadline is explicitly reported as unmet; tool failure,
pause and budget exhaustion also prevent execution and remain visible. Test single due item,
same-deadline contention, urgent work, rerun, and skipped-call warmth. This is a deterministic
selection fallback using the existing evaluator, not a new queue or dispatch mechanism.

## Historical implementation checkpoints

The checkpoints below record the sequence and are superseded by the merge evidence at the end.

### Implementation checkpoint

Runtime implemented; focused manual 21/21 and Python 21/21 pass. Evidence: TESTS-RESULTS/2026-11-08+GH-1254/. Independent final QA and applicable gate pending. Initializer defect repaired in one round; no other blocker budget consumed. Plan QA Approved round 2. Restart and overloaded execution-deadline acceptance remain OPEN. NO_ENTRY for lessons: modeled-only observation is insufficient for a durable generalization.

## Durable gate handoff

Parent owns the full-gate host reservation for #1324. Do not run this gate concurrently.
Task candidate includes development through 035802c19, not the pending #1324 repair.
After parent releases the host, inspect origin/development and safely merge any landed
#1324 changes; no reset/stash/force. Recheck actual combined diff and focused evidence
if integration changes runtime behavior. Then in the existing disposable full gate clone,
fetch the task branch and fast-forward it. Verify core.bare=false, origin, user identity,
HEAD and clean status before/after. Use Python 3.13 venv already verified to import
requests, yaml and pytest. Run `PATH=<verified-venv>/bin:$PATH bash validate.sh --parallel 4`
with full output captured under temp/gh1254/full-gate.log. Keep exact-SHA receipt;
normal pre-push can reuse it for this commit. Publish the gated runtime commit first,
then commit raw gate log/provenance and push that evidence-only delta through the docs gate.
No PR exists yet. No full gate has started. No #1358 run or #1344 retry.

Final QA Approved round 1, receipt relay-system/2026-11-08/gh1254-final.codex.md.
Primary ownership released after accepted-start 035802c19aea8724f96193edae611389376839ad.

### Gate and integration progress

Original full gate passed 409/409 at 522155356. PR1324 and reconciliation through 248ecec4d
are now included. Combined focused manual21/Python21/packet9 checks pass. Code QA remains
applicable to unchanged GH1254 runtime; upstream packet changes carry their independent receipts.
Combined-SHA publication gate pending; peer PR1316 currently occupies the host. No bypass.

### Published scoped implementation

PR: https://github.com/HiQS-Labs/XYZ-forge/pull/1369. Code-gate SHA
79c735156907e98be2572bf70f6585af5e33e8e1; full409/409. Final evidence-only
commits do not change runtime. Independent QA approved GH1254 runtime; merged GH1296
packet changes carry their separate review and gate evidence. One width-environment
publication failure repaired without code changes; controls and failed log retained.
No merge/watch; parent retains outer-review and user per-PR approval boundary.

## Merge evidence

- PR #1369 merged 2026-11-08 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

### Authorized landing and active lifecycle

PR1369 merged at e6fcbbc3616b26e63560e7c6df4e967882a4c7fe; normal reconciliation
published at 95deeea37b721f007736ebcf52bf047bf9afde31. The issue stays OPEN.
This document is promoted to 2-WORKING and existing row
`rmi-01M6WTMK376C3R6EGNG4BG4HTH` repointed through the supported CLI.
No new runtime changes or full gate: code gate remains 79c735156907e98be2572bf70f6585af5e33e8e1 (409/409);
final reviewed PR head 91214d29fd7802a9608f305fdfc95dd0e12bcc8d adds docs/evidence only, hosted smoke SUCCESS.

Open acceptance owners: GH1248/parent GH1358 planning for an actual supervised restart;
GH1254 for overloaded deadline behavior and live accounting/cost evidence. No restart or live
savings is claimed. Parent owns the GH1356 partial/not-qualified terminal outcome; no GH1358
execution or GH1344 retry occurred. Repair counters: initializer 1, publication environment 1,
landing clone-preservation recovery 1, lifecycle staging repair 1; plan QA 2, final QA 1. Cleanup interpreted an exclusion
as a literal substring rather than a glob and moved two clones to Trash; both full clones were
restored intact to their original paths. No data was discarded and no peer process stopped.

The initial lifecycle commit recorded only the rename after a stale old-path staging argument
failed. Remaining owned status/ledger/evidence changes were preserved and published in a
follow-up commit; no reset or history rewrite. Final publication re-runs the normal docs gate.

## Merge evidence

- PR #1377 merged 2026-11-08 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
