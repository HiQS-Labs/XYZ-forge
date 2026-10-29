---
gh_issue: 1248
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1248
title: "Outer-loop primitive: tracked agent-agnostic control-plane spike"
status: Active
created: 2026-10-28
updated: 2026-10-28
owner: noelsaw1
goal: "Build and measure a deterministic outer loop whose decision adapters are replaceable without changing scheduling, validation, containment, recovery, or receipt semantics, while keeping all production Jog and repository execution disabled."
doc_type: plan
effort: 3
complexity: 3
risk: 2
phases: 5
branch: feat/gh1248-outer-loop-primitive
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1175
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1188
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1224
non_goals:
  - Jog, repository, GitHub, merge, deployment, or multi-repo execution.
  - New test suites, gate registrations, production schedulers, or a competing queue.
  - Treating a synthetic soak as XYZ factory or marathon readiness evidence.
---

# GH-1248 — Outer-loop primitive

## Status

| What was just completed | What's next |
|---|---|
| Phase 1 control plane implemented; 17/17 manual controls passed with retained logs; shared scenario now has 27 inputs including 24 deterministic adversarial canaries | Run the outstanding one-hour rules-only gate; watchdog, report generator, agent adapters, multi-arm runs, and 24-hour soak remain unimplemented |

The full experiment contract and acceptance criteria live in issue #1248. This document is the execution surface and build record.

## Tracked source and runtime boundary

Source is versioned on `feat/gh1248-outer-loop-primitive`; the branch is not merged when incomplete and may be retained for later revisit. The implementation uses Python only and does not alter existing production entry points.

```text
utils/py/factory-primitive.py          # CLI entry point
utils/py/factory_primitive/            # loop, state, adapters, tools, sandbox
  prompts/evaluator.v1.md
  schemas/*.json
  scenarios/soak-v1.jsonl
  scenarios/soak-v1.manifest.json

temp/factory-primitive/                # gitignored mutable runtime root
  instances/<A|B|C>/
    out/<tool>/
    state.db
    telemetry/
    heartbeat.json
    lock
    PAUSE
```

The source tree contains no live database, output, transcript, heartbeat, lock, or pause state. Existing `proc_group.run_bounded` owns process-group timeout behavior. The experiment is separate from GH-1098's production Jog work and creates no scheduler or queue integration.

## Bet, reversibility, and blast radius

**Bet:** a small deterministic executive can enforce the issue's four-action contract across adapters without forking Jog or making model output an execution authority. **Reversibility: Easy** — retain or abandon the unmerged branch. **Blast radius:** new experiment files, this plan and its ledger pointer, and manual evidence; existing relay/Jog/gate behavior is untouched. The primary failure mode is a clean synthetic result being overread as production readiness, so integration remains separately gated.

## Phases and QA gates

### Phase 1 — Rules-only control plane

Implement the CLI, slot-indexed scenarios, SQLite snapshots/decisions/intents/receipts, rules adapter, four logical tools, heartbeat, lock, pause, budget reservations, macOS filesystem sandbox, reconciliation, and `status`. Exercise the issue's manual negative controls without adding a test suite or gate registration.

**QA gate:** recorded controls under `TESTS-RESULTS/2026-10-28+GH-1248/` show unsafe decisions are rejected, new/existing-file escapes are blocked, crashes leave classified recoverable state, ambiguous attempts never repeat, and unknown billing is not converted to zero. A one-hour rules-only run remains required before this phase is complete.

### Phase 2 — Scenario synchronization and observability

Add the independent watchdog, immutable per-slot manifest checks, seeded scenario generator, and report. Use artificial latency skew in a compressed slot run.

**QA gate:** available-item digests match the manifest across arms, pause/liveness semantics are correct, and every report rate has a complete denominator. Write findings back here and to #1248.

### Phase 3 — Two agent adapters

Add Claude Code and Codex behind the unchanged adapter contract, with pinned run manifests and raw-output retention.

**QA gate:** no adapter-specific loop change, every outcome is classified, and a two-hour three-arm run records raw decision quality separately from safe fallback.

### Phase 4 — Full soak

Run the 24-hour slot-indexed fault schedule in issue #1248.

**QA gate:** all 16 issue criteria pass with committed `provenance.jsonl`; failures remain visible. No production integration follows merely from elapsed time.

### Phase 5 — Review and next-step decision

Review control-plane and decision-quality evidence independently.

**QA gate:** approve only rejection, a narrower follow-up, or a separately planned read-only Jog observation spike. Real dispatch, scheduling, merge, and deployment need new explicit authorization.

## Verification policy

No new tests under GH-831. Use applicable existing checks plus recorded manual controls with committed `provenance.jsonl`. Before branch publication, run the frozen-twin staged check, PDDA checks, `releases check`, and the gate selected by `utils/ci-route.sh`; do not claim the one-hour or 24-hour runs until they actually occur.
