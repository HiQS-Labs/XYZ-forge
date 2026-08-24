---
title: "GH-180: repro_builder crashes on timeout telemetry records (exit_code: null -> TypeError)"
status: active
created: 2026-08-23
updated: 2026-08-23
owner: orchestrator (Claude Code)
goal: make the reproducer builder ingest the fuzzer's most common record class instead of crashing on it
gh_issue: 180
source: https://github.com/HiQS-Labs/XYZ-forge/issues/180
branch: gh-180/repro-timeout-crash
doc_type: bugfix
effort: 1
complexity: 1
risk: 1
related:
  - "#181 — same file (utils/py/repro_builder.py), same telemetry-ingest seam; serialize or same-wave lane"
  - "#174 — Gen 3.5 umbrella (Part G probe A10); #177 — soak results §3.1"
---

# GH-180 — repro_builder crashes on timeout telemetry records

## Status

| What was just completed | What's next |
|---|---|
| capture doc + preflight contract written; auto-filed per SOP §1 (2026-08-23); queued as Bulkhead wave candidate (release 0.7.3, #179) | Operator fires the marathon lane per MARATHON-PLAN; builder executes ## Plan, reviewer verifies ## Acceptance |

Release 0.7.3 "Bulkhead" manifest member. Gen 3.5 soak (#177 §3.1, probe A10):
`parse_failure_telemetry` calls `int(exit_code)` unconditionally (`utils/py/repro_builder.py:68`);
timeout records carry `exit_code: null` (`run_harness` on TimeoutExpired), so real timeout
telemetry — the record class a fuzzer produces most — crashes the builder.

## Bug

Deterministic repro in #180: any record with `exit_code: null` → `TypeError: int() argument …
not 'NoneType'` at `repro_builder.py:68`. The builder cannot ingest the soak's own output.

## Plan

1. `utils/py/repro_builder.py`: map `exit_code: null` (and the `timed_out: true` key) to a
   first-class timeout signature — target rc sentinel 124 + `timed_out: true` — never `int(None)`.
2. `generate_repro_script`: timeout-signature repros assert a bounded wall-clock failure instead
   of a numeric rc equality.
3. `test/gh180-repro-timeout-crash.sh`: null-exit record builds without crashing; emitted timeout
   repro asserts the timeout shape; pre-fix negative control (crash) recorded. Register in
   `validate.sh` TESTS.

## Acceptance

A telemetry record with `exit_code: null` produces a runnable reproducer (no TypeError);
gh180 suite green and registered; gh155-phase3 suite stays green.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "test/gh180-repro-timeout-crash.sh" } ],
  "artifacts":     [ "utils/py/repro_builder.py", "test/gh180-repro-timeout-crash.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh180-repro-timeout-crash.sh" ],
  "remediation":   { "source": "self#plan", "criteria": "null-exit telemetry builds a timeout-signature reproducer without crashing; gh180 suite green" },
  "lanes":         { "agy_safe": [ "utils/py/repro_builder.py", "test/gh180-repro-timeout-crash.sh" ], "orchestrator_only": [ "validate.sh" ] }
}
```

## Lessons Learned (For Future Agents)

The crash class was a schema assumption: telemetry records from timed-out runs carry
`exit_code: null`, and `repro_builder.py` arithmetic on that field threw before any reproducer was
built. The fix that shipped in PR #185 pairs the null-tolerant ingest with a negative-control
baseline (`test/baselines/GH-180-negative-control.md`) proving the pre-fix code actually crashed
on the same input — without that control, a green test cannot distinguish "fixed" from "never
exercised the crash path." When ingesting external/telemetry data, treat every field as optional
until a record proves otherwise, and encode the timeout case as a first-class signature rather
than a fabricated exit code.
