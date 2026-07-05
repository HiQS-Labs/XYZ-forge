---
gh_issue: 116
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/116
title: "fix(tick): misleading 'break' error on open tasks + marathon retry flag — Bug B remainder (Bug A already landed)"
status: Bug A shipped (bb9138b); this doc scopes the Bug B remainder — a --retry flag on marathon.sh
created: 2026-07-04
updated: 2026-07-04
owner: noel
doc_type: enhancement
goal: >
  Add a --retry <phase-id> flag to marathon.sh so recovering a spent (open, never-claimed) relay
  task doesn't require manually renaming a phase id in MARATHON.yaml, reusing marathon-drive.sh's
  existing --relay-task override rather than adding new task-naming logic.
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: false
non_goals:
  - Not touching src/scope.js or tick's break command — Bug A (the misleading error message) already shipped in bb9138b
  - Not adding retry logic to marathon-drive.sh itself — the fix is entirely in marathon.sh's per-phase task-name derivation, using marathon-drive.sh's existing --relay-task override
related:
  - relay-automation/marathon.sh
  - relay-automation/marathon-drive.sh
  - test/marathon.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Bug A (misleading `tick break` error on an `open` task) already shipped in `bb9138b` — confirmed live in `src/scope.js:26`. This doc scopes only Bug B, the remainder: `marathon.sh` has no way to retry a phase whose relay task is permanently spent (`open`/never-claimed) without manually renaming the phase id in the YAML. | Build: `marathon.sh --retry <phase-id>`. |

## Problem (grounded in the current code)

When a phase fails and its relay task is left `open` (spent — a task token can't be reopened once
claimed-then-abandoned, per this repo's own established constraint), the only recovery path today is
editing `MARATHON.yaml` to rename the phase id (which also renames its `phases/<id>/` dir) so
`marathon.sh` derives a fresh task name. That is manual and easy to get wrong.

`marathon-drive.sh` already supports exactly the primitive needed to fix this without touching its
own logic — `--relay-task` (`marathon-drive.sh:190`):

```bash
--relay-task)      RELAY_TASK="${2:-}"; shift 2 ;;
```

and, absent that override, derives the task name from `--phase-id` (`:214`):

```bash
RELAY_TASK="${RELAY_TASK:-"MARATHON-$(printf '%s' "$PHASE_ID" | tr '[:lower:]' '[:upper:]')-TURN"}"
```

`marathon.sh` (the multi-phase orchestrator) builds `drive_args` per phase (`marathon.sh:91-92`)
without ever setting `--relay-task`, so every attempt at a given phase id gets the same,
once-spent-forever task name.

## Fix

Add `--retry <phase-id>` to `marathon.sh`:

1. Accept the flag alongside the existing `--plan`/`--phases-dir`/`--builder`/`--pre-advance-cmd`
   options.
2. When the phase currently being driven matches `--retry`'s `<phase-id>`, append
   `--relay-task "MARATHON-<ID>-TURN-2"` (or increment further — `-3`, `-4` — if that task name is
   itself already spent; check via `tick info` before choosing the suffix) to that phase's
   `drive_args`, instead of leaving `RELAY_TASK` to `marathon-drive.sh`'s default derivation.
3. Every other phase in the plan is unaffected — this only changes the derived task name for the
   one phase named by `--retry`.

No change needed to `marathon-drive.sh` itself; the existing `--relay-task` override is the whole
mechanism.

## Definition of done

- [ ] `marathon.sh --retry <phase-id>` accepted; usage text updated.
- [ ] The named phase's `marathon-drive.sh` invocation gets `--relay-task
      MARATHON-<ID>-TURN-<N>` where `N` is the first unused suffix (checked against `tick info`, not
      hardcoded to `-2`).
- [ ] Every other phase in the plan derives its task name exactly as before (unaffected by
      `--retry`).
- [ ] `test/marathon.sh` covers: a `--retry`-targeted phase gets the suffixed task name; a plan run
      without `--retry` is byte-for-byte unchanged.
- [ ] `bash validate.sh` green.

## Reversibility & blast radius

**Low.** New optional flag on `marathon.sh`; when unset, behavior is identical to today. Uses
`marathon-drive.sh`'s already-existing `--relay-task` override rather than adding new task-naming
logic — no change to the single-phase driver or the containment core.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/marathon.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/marathon.sh", "pattern": "GH-116" }
  ],
  "artifacts": [
    "relay-automation/marathon.sh",
    "test/marathon.sh"
  ],
  "remediation": "Add a --retry <phase-id> flag to relay-automation/marathon.sh. When the phase currently being driven matches --retry's phase-id, compute the first unused MARATHON-<ID>-TURN-<N> suffix (check via tick info, starting at -2) and pass it as --relay-task to that phase's marathon-drive.sh invocation (drive_args, around marathon.sh:91-92) -- marathon-drive.sh already supports --relay-task natively (marathon-drive.sh:190), no change needed there. Every other phase's task-name derivation stays exactly as today. Add test/marathon.sh coverage for a --retry-targeted phase getting the suffixed name and an unretried run being unaffected. GH-116 marker comment near the fix. Note: this is Bug B only -- Bug A (misleading tick break error) already shipped in bb9138b.",
  "lanes": {
    "agy_safe": ["relay-automation/marathon.sh", "test/marathon.sh"],
    "orchestrator_only": [],
    "note": "Independent -- marathon.sh is not in the kernel or shim zone by this repo's own classifier (not relay-turn-lib.sh/bin/tick/relay-drive.sh, not a *-turn.sh/consult.sh shim). Parallel-safe with every other Plan C lane."
  }
}
```

## Provenance

Found in a live multi-phase MARATHON.yaml run against rebalance-OS: the first attempt failed
(`claude` builder not on PATH — see sibling #117), leaving the phase's relay task permanently open;
recovering required manually renaming the phase id. Bug A (the misleading `tick break` error
surfaced while diagnosing that recovery) already shipped in `bb9138b`.
