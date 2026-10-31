# Plan draft: #1248 Outer loop primitive

> draft; preflight and independent plan QA outstanding

- Request: `gh-1248-d8dad71fa38a` (tick `slot_024`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 65/50/60/55
- Capture doc: PROJECT/2-WORKING/GH-1248-OUTER-LOOP-PRIMITIVE.md (sha256 560c23df263855e368c60fc654c0fbb2392c25523280eac029c8bac51e0779c2)
- Issue sha256: d8dad71fa38a270dc78e430f4c9289da6a56f1b79e517405b77f3036df5143f9 (updated 2026-10-31T01:27:47Z)
- Dependencies: none

## Scope

_Source: issue#1248:L11 (1. Hypothesis, scope, and non-claims)_

**Hypothesis:** given the same seeded inputs and fault timeline, one unchanged loop can safely drive at least two agent CLIs and one deterministic rules adapter through the same four-action contract for 24 hours.

On each scheduled tick, the loop must:

1. wake or leave an explicit missed-tick record;
2. maintain an honest heartbeat while work is in flight;
3. obtain one decision or classify the adapter failure;
4. validate the decision and execute at most one allowlisted tool;
5. leave either a complete receipt or an explicit `uncertain` outcome.

**Out of scope:** XYZ Forge and Jog state, repository writes, GitHub writes, remote hosting, multi-repo support, autonomous retries after ambiguous outcomes, and changes to XYZ Forge's test or gate registry.

**Agent agnostic** means that replacing an adapter requires no change to the loop, tools, schemas, or evaluator policy. It does **not** mean that agents behave identically, have equal availability, or produce equally good decisions.

A successful soak supports only these conclusions:

- the tested adapters satisfy this narrow decision contract;
- the loop handles the exercised faults without unsafe execution or silent state loss;
- the design is suitable for a subsequent read-only Jog observation spike.

It does **not** establish XYZ Forge factory reliability, general model interchangeability, exactly-once execution, queue/lease correctness, worktree safety, or marathon readiness. A clean 24-hour run is evidence, not proof of 

_Source: PROJECT/2-WORKING/GH-1248-OUTER-LOOP-PRIMITIVE.md:L9 (frontmatter goal)_

Build and measure a deterministic outer loop whose decision adapters are replaceable without changing scheduling, validation, containment, recovery, or receipt semantics, while keeping all production Jog and repository execution disabled.

_Source: codex-authored (codex-authored)_

Verify the current state of issue #1248, its branch, and the #1257 follow-ups before identifying remaining work.

_Source: codex-authored (codex-authored)_

Plan agent adapters over real snapshots while preserving deterministic scheduling, validation, containment, recovery, and receipt semantics.

_Source: codex-authored (codex-authored)_

Keep the synthetic 24-hour soak, watchdog, and soak-v2 deferred until their prerequisites are resolved.

## Acceptance criteria

_Source: issue#1248:L221 (8. Acceptance criteria)_

Planned scheduler-stop slots are excluded from the enabled-tick denominator but remain visible as injected misses. With slots 85–90 stopped, the denominator is 282 enabled slots, not 288. Paused slots remain enabled and must produce paused receipts.

| # | Criterion | Target |
|---|---|---|
| 1 | Scheduler invocation coverage | ≥ 99% of enabled slots per instance; paused invocations counted separately |
| 2 | Scenario synchronization | Every arm's per-slot available-item digest matches the immutable manifest; a mismatch stops that arm before an agent call; final cross-arm digests are identical |
| 3 | Concurrent execution | 0 overlapping ticks and 0 unexpected `skipped-busy` outcomes |
| 4 | Tool containment | 0 successful unauthorized writes; outside-directory creation, existing-file modification, and instance-external attempts are blocked and recorded |
| 5 | Decision safety | 100% of malformed, unknown, ineligible, or disallowed requests rejected without executing the requested action |
| 6 | Decision measurement | Raw validity, policy correctness, adapter errors, and safe fallbacks reported separately for every arm |
| 7 | Receipt completeness | 100% of invoked ticks have a terminal receipt, `uncertain`, or classified `unpersisted-intent-abort`; 0 silent losses |
| 8 | Kill during `act` | Persisted intent recovered; tick marked `uncertain`; old attempt not re-fired; affected input quarantined |
| 9 | Crash during intent persistence | `unpersisted-intent-abort` recorded; b

_Source: codex-authored (codex-authored)_

The loop executes at most one allowlisted tool per tick and records a complete receipt or an explicit uncertain outcome.

_Source: codex-authored (codex-authored)_

Adapters use the same policy and snapshot semantics, preserve raw output, and report unavailable telemetry explicitly.

_Source: codex-authored (codex-authored)_

Runtime execution remains isolated from production Jog state, repository execution, GitHub writes, deployment, and multi-repo execution.

_Source: codex-authored (codex-authored)_

Verification accounts for the recorded quarantine, status, missed-tick, and post-execution verification gaps without treating the incomplete full gate as passed.

## Open questions

_Source: codex-authored (codex-authored)_

Has #1257 landed on the experiment branch, and which follow-ups remain?

_Source: codex-authored (codex-authored)_

What are the full issue acceptance criteria and current evidence beyond the excerpts provided?

_Source: codex-authored (codex-authored)_

What prerequisites must be met before the deferred soak, watchdog, and soak-v2 work resumes?

## Write set

- `utils/py/harness.py` (issue#1248:L75)
- `PROJECT/2-WORKING/GH-1248-OUTER-LOOP-PRIMITIVE.md` (issue#1248:L96)
- `utils/ci-route.sh` (PROJECT/2-WORKING/GH-1248-OUTER-LOOP-PRIMITIVE.md:L100)

## Unresolved file names

- none

## Contract probes

- none
