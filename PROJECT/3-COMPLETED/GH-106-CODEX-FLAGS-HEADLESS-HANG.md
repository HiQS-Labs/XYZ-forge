---
gh_issue: 106
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/106
title: "codex-turn: default CODEX_FLAGS hangs on approvals in headless runs → silent 300s timeout + wasted lane attempt"
status: Closed — captured 2026-07-04, rated, ready to build
created: 2026-07-04
updated: 2026-07-04
owner: noel
doc_type: bugfix
goal: >
  Change codex-turn.sh's default CODEX_FLAGS so a headless run no longer hangs on an interactive
  approval prompt, without changing the fully-overridable env-var contract.
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: false
non_goals:
  - Not changing codex-turn.sh's dispatch gate, worktree lifecycle, or containment enforcement — only the default autonomy flags
  - Not making CODEX_FLAGS mandatory to set explicitly; the new default must work out of the box headless
related:
  - relay-automation/codex-turn.sh
  - test/codex-turn.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-07-04 from a real vendored-install marathon dogfood field report (1 of 3 friction points in that run, alongside #107/#108). Rated, ready to build. | Build: change `codex-turn.sh`'s default `CODEX_FLAGS` to an autonomy level that doesn't block on an approval prompt in a headless run. |

## Problem (grounded in the current code)

`relay-automation/codex-turn.sh:69`:

```bash
read -ra _cflags <<<"${CODEX_FLAGS:--s workspace-write}"
```

The default sandbox mode is `-s workspace-write`, which still requires interactive approval for
certain operations (the codex CLI's `workspace-write` sandbox permits filesystem writes but still
gates some actions behind an approval prompt depending on `approval_policy`). In a headless marathon
run with no human at the terminal, that prompt is never answered — `codex exec` blocks until
`RELAY_TURN_TIMEOUT_S` (default 300s) kills it, producing exit 7 (hung turn) and burning a full lane
attempt for a turn that never got a chance to do real work.

The header comment (`codex-turn.sh:20`) already documents the escape hatch:

```
#                     CODEX_FLAGS='--dangerously-bypass-approvals-and-sandbox' o...
```

— but it is opt-in, not the default, so a fresh headless run hits the hang before anyone knows to
set it.

## Fix

Change the default in `codex-turn.sh:69` from `-s workspace-write` to a non-interactive-safe
default. Two candidate directions (pick the one that preserves the most containment):

1. `-c approval_policy=never` combined with `-s workspace-write` — keeps the sandbox restriction
   (still can't touch outside the workspace) but removes the interactive approval gate. Preferred
   if it doesn't also block on other prompt types codex may emit.
2. `--dangerously-bypass-approvals-and-sandbox` as the new default — matches the header comment's
   own escape hatch, but is a bigger autonomy jump (removes codex's own sandbox entirely; this
   repo's containment then relies solely on `relay-turn-lib.sh`'s worktree isolation, which already
   holds for every other headless worker).

Whichever is chosen, keep `CODEX_FLAGS` fully overridable (unchanged) so an operator running codex
interactively can still tighten it back down.

## Definition of done

- [ ] `codex-turn.sh`'s default `CODEX_FLAGS` no longer blocks on an approval prompt in a headless
      run (verified against a real `codex exec` invocation, not just a stub).
- [ ] The header comment's documented escape hatch is updated to match whatever the new default is
      (no longer describing an opt-in workaround for the default failure mode).
- [ ] `test/codex-turn.sh` covers the new default (assert the flags string, not a live codex call).
- [ ] `bash validate.sh` green.

## Reversibility & blast radius

**Low.** One default-value change in one file; fully overridable via the existing `CODEX_FLAGS` env
var. No containment-kernel change — `relay-turn-lib.sh`'s worktree isolation is what actually
enforces the write boundary regardless of codex's own sandbox setting.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/codex-turn.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/codex-turn.sh", "pattern": "GH-106" }
  ],
  "artifacts": [
    "relay-automation/codex-turn.sh",
    "test/codex-turn.sh"
  ],
  "remediation": "In relay-automation/codex-turn.sh, change the default CODEX_FLAGS (line ~69, currently '-s workspace-write') to a non-interactive-safe default that does not block on an approval prompt in a headless run -- either '-s workspace-write -c approval_policy=never' or '--dangerously-bypass-approvals-and-sandbox' (match whichever the header comment's documented escape hatch already recommends, and update that comment to describe the new default rather than a workaround). Add a test/codex-turn.sh assertion on the new default flags string. GH-106 marker comment near the fix.",
  "lanes": {
    "agy_safe": ["relay-automation/codex-turn.sh", "test/codex-turn.sh"],
    "orchestrator_only": [],
    "note": "Independent -- shim zone (relay-automation/*-turn.sh), parallel-safe with any lane that doesn't touch codex-turn.sh."
  }
}
```

## Provenance

Field report from a real vendored-install marathon dogfood run (2026-07-04), one of three
independent friction points that each individually blocked a correct, complete build from advancing
cleanly (siblings: #107 containment tool-cache, #108 gate scoping).
