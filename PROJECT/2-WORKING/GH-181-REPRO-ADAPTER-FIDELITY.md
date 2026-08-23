---
title: "GH-181: repro_builder emits non-reproducing reproducers from real telemetry (mis-tokenized unquoted command)"
status: active
created: 2026-08-23
updated: 2026-08-23
owner: orchestrator (Claude Code)
goal: a finding's telemetry record builds a reproducer that actually reproduces that finding — the Gen 3.5 end-to-end criterion
gh_issue: 181
source: https://github.com/HiQS-Labs/XYZ-forge/issues/181
branch: gh-181/repro-adapter-fidelity
doc_type: bugfix
effort: 3
complexity: 3
risk: 3
related:
  - "#180 — same ingest seam in utils/py/repro_builder.py; serialize with it (write-set overlap)"
  - "#174 — Gen 3.5 umbrella (Part F task 1+4, Part G probe B2); #177 — soak results §3.2"
---

# GH-181 — telemetry → reproducer fidelity (schema 1.1)

## Status

| What was just completed | What's next |
|---|---|
| capture doc + preflight contract written; auto-filed per SOP §1 (2026-08-23); queued as Bulkhead wave candidate (release 0.7.3, #179) | Operator fires the marathon lane per MARATHON-PLAN; builder executes ## Plan, reviewer verifies ## Acceptance |

Release 0.7.3 "Bulkhead" manifest member. Gen 3.5 soak (#177 §3.2, probe B2): a real GH-141
failure record built a reproducer whose command is mis-tokenized AND unquoted — executing it
returns rc 127 against the expected rc 2. Two compounding defects: (1) `command` recorded as a
joined string (`" ".join(cmd)`) cannot round-trip tokens containing spaces; (2) records carry no
error signature, so matching is rc-only and wrong-cause failures pass.

## Bug

See #181 for the deterministic reproduction against
`TESTS-RESULTS/2026-08-22+GH-141/error_log.jsonl` (record 1). The builder manufactured a
non-reproducing reproducer from real telemetry.

## Plan

1. `utils/ate/scripts/run_variations.py`: telemetry schema 1.1 — record `argv` as a list, the
   realized `env`, and a normalized failure signature (stderr substring) per iteration.
2. `utils/py/repro_builder.py`: ingest `argv` lists directly (no shlex round-trip); quote every
   emitted token unconditionally; require signature match (rc + substring) in `test_reproduction`.
3. `test/gh181-repro-adapter-fidelity.sh`: the GH-141 record (committed fixture) builds a
   reproducer that executes the intended command and reproduces the exit-2 failure; wrong-cause
   rc coincidence no longer passes (negative control). Register in `validate.sh` TESTS.

## Acceptance

The GH-141 record builds a reproducer that reproduces the actual agy `--help` exit-2 failure
(that record becomes the permanent regression fixture per #174 Part F task 4); gh181 suite green;
gh155-phase3 suite stays green.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "test/gh181-repro-adapter-fidelity.sh" } ],
  "artifacts":     [ "utils/ate/scripts/run_variations.py", "utils/py/repro_builder.py", "test/gh181-repro-adapter-fidelity.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh181-repro-adapter-fidelity.sh" ],
  "remediation":   { "source": "self#plan", "criteria": "the committed GH-141 record builds a reproducer that reproduces the exit-2 failure; signature matching rejects wrong-cause rc coincidence" },
  "lanes":         { "agy_safe": [ "utils/ate/scripts/run_variations.py", "utils/py/repro_builder.py", "test/gh181-repro-adapter-fidelity.sh" ], "orchestrator_only": [ "validate.sh" ] }
}
```
