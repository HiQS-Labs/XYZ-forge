---
title: "GH-183: active_explorer env-family fuzzing unsound — base_env={} hardcoded, one always-deferring vector, ambient-env leakage"
status: active
created: 2026-08-23
updated: 2026-08-23
owner: orchestrator (Claude Code)
goal: the explorer's env family actually generates and executes missing/empty/corrupted env vectors from a clean base
gh_issue: 183
source: https://github.com/HiQS-Labs/XYZ-forge/issues/183
branch: gh-183/explorer-env-soundness
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
related:
  - "#174 — Gen 3.5 umbrella (Part D D5, Part G); #177 — soak results §3.4"
---

# GH-183 — explorer env-family soundness (clean base env)

## Status

| What was just completed | What's next |
|---|---|
| capture doc + preflight contract written; auto-filed per SOP §1 (2026-08-23); queued as Bulkhead wave candidate (release 0.7.3, #179) | Operator fires the marathon lane per MARATHON-PLAN; builder executes ## Plan, reviewer verifies ## Acceptance |

Release 0.7.3 "Bulkhead" manifest member. Gen 3.5 soak (#177 §3.4, probe D5): CLI explore mode
hardcodes `base_env={}`, so the env family generates exactly ONE vector (the
conflicting-identity variant) which every shim cleanly defers at exit 0 — missing-env testing is
impossible by construction; and `execute_with_process_limits` builds on `os.environ.copy()`, so
ambient `RELAY_*` silently satisfies "missing key" mutations (machine-dependent results).

## Bug

See #183 for the deterministic reproduction (1 probe / 0 anomalies, with and without ambient env).

## Plan

1. `utils/py/active_explorer.py`: add `--base-env KEY=VAL` (repeatable); execute from a CLEAN
   env (inherit `differential_oracle.py`'s discipline: PATH/HOME/TMPDIR/XYZ_ROOT only) + declared
   base, never `os.environ.copy()`.
2. Env-family generation runs from the declared base: missing/empty/corrupted/long/buffer
   variants per key, plus the conflicting-identity vector.
3. `test/gh183-explorer-env-soundness.sh`: with `--base-env RELAY_AGENT=x RELAY_FILE=y` against a
   turn shim, the missing-key vectors are present in the JSON record set and execute from a clean
   env (ambient RELAY_AGENT set high cannot satisfy them — negative control); anomalies=0 by
   construction stays 0 (rc-2 deferrals are not crashes — #174 D6 is a separate lane).
   Register in `validate.sh` TESTS.

## Acceptance

Env-family explore with a declared base generates and executes the missing/empty/corrupted
families; ambient runner env provably cannot affect results; gh183 suite green; gh155-phase5
suite stays green.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "test/gh183-explorer-env-soundness.sh" } ],
  "artifacts":     [ "utils/py/active_explorer.py", "test/gh183-explorer-env-soundness.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh183-explorer-env-soundness.sh" ],
  "remediation":   { "source": "self#plan", "criteria": "declared base env drives the full missing/empty/corrupted vector set from a clean environment; ambient env cannot satisfy mutations" },
  "lanes":         { "agy_safe": [ "utils/py/active_explorer.py", "test/gh183-explorer-env-soundness.sh" ], "orchestrator_only": [ "validate.sh" ] }
}
```

## Lessons Learned (For Future Agents)

Env-family fuzzing with `base_env={}` hardcoded meant mutations were applied to nothing: vectors
"deleted" variables that were never set, and ambient runner variables leaked in to satisfy
mutations the explorer believed it had made. The fix (PR #185) drives all missing/empty/corrupted
vectors from a declared base env over a clean environment, with a test asserting ambient env
cannot satisfy a mutation. Lesson: a fuzzer's negative space must be constructed, not inherited —
any mutation framework that starts from the process's own environment is testing the runner, not
the target, and will pass everywhere while covering nothing.
