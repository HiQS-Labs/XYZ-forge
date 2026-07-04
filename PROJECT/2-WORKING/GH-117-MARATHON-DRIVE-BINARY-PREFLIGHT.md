---
gh_issue: 117
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/117
title: "fix(marathon-drive): --dry-run must probe builder/reviewer binary before mutating tick state"
status: captured 2026-07-03, rated, ready to build
created: 2026-07-04
updated: 2026-07-04
owner: noel
doc_type: bugfix
goal: >
  Probe the builder/reviewer binary's existence on PATH before marathon-drive.sh mutates any tick
  state, so a missing binary fails clean (before task.created) instead of leaving a permanently
  spent relay task that needs manual recovery.
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: false
non_goals:
  - Not changing which binaries are valid (claude/codex/agy/aider) — only adding an existence check before tick state is touched
  - Not adding retry/recovery logic here — that's #116 Bug B's --retry flag, a separate lane
related:
  - relay-automation/marathon-drive.sh
  - test/marathon-drive.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-07-03/04 from a live 3-phase marathon run where a missing `claude` binary left a spent relay task requiring manual cleanup. Rated, ready to build. | Build: a builder/reviewer binary probe right after agent routing, before any tick mutation. |

## Problem (grounded in the current code)

`marathon-drive.sh` maps `--builder`/`--reviewer` to their `*_AGENT` env var via `route_agent()`
(`:213-230`), then — whether `--dry-run` or a live run — proceeds to seed tick state starting at
`:386` (`"$TICK_BIN" log task.created "$RELAY_TASK" --agent marathon`). `DRY_RUN` (checked at
`:330`) only decides whether to print-and-exit *before* the real run's turn-taker dispatch; it does
**not** skip the tick-seeding block itself for a genuinely missing binary — nor does the live path
check the builder/reviewer binary is even on `PATH` before that seeding happens.

Reproduced live: a `claude` builder not on `PATH` fails downstream (inside the turn-taker dispatch),
by which point `task.created`/`claim`/`release` have already run and the relay task is
`open`/never-claimed — permanently spent (per this repo's tick-token model, a task in that state
can't be reopened; recovering it today needs `#116`'s `--retry` flag or a manual phase-id rename).

## Fix

Add a binary-existence probe immediately after `route_agent "$BUILDER"` / `route_agent "$REVIEWER"`
(`:232-233`) and before the clean-workspace check (`:256`) — i.e. before *any* tick mutation, on
both `--dry-run` and live paths:

```bash
_probe_bin() {  # <bin> <label> — die if not found on PATH
  command -v "$1" >/dev/null 2>&1 || die "builder/reviewer binary '$1' not found on PATH (--$2 agent)"
}
[[ -n "${CLAUDE_AGENT:-}" ]] && _probe_bin "${CLAUDE_BIN:-claude}" builder
[[ -n "${CODEX_AGENT:-}"  ]] && _probe_bin "${CODEX_BIN:-codex}"  builder
[[ -n "${AGY_AGENT:-}"    ]] && _probe_bin "${AGY_BIN:-agy}"      builder
[[ -n "${AIDER_AGENT:-}"  ]] && _probe_bin "${AIDER_BIN:-aider}"  builder
# (repeat the same four checks for the REVIEWER's routed *_AGENT, since a builder and reviewer can't
# share an agent id — route_agent already enforces that — but both still need probing independently)
```

Following the same `*_BIN` override pattern the turn scripts already use (`CODEX_BIN`, `AGY_BIN`,
etc.), so a non-default binary path is still respected. This makes a missing binary fail with `die`
(exit 2, usage-class error) **before** `task.created` ever logs — clean, no spent token, no manual
cleanup needed.

## Definition of done

- [ ] A missing builder or reviewer binary is caught before any `tick log`/`claim`/`release` call,
      on both `--dry-run` and live invocations.
- [ ] The probe respects `*_BIN` overrides (`CLAUDE_BIN`, `CODEX_BIN`, `AGY_BIN`, `AIDER_BIN`), not
      just the default binary name.
- [ ] A run with all binaries present is completely unaffected (no new output, no behavior change).
- [ ] `test/marathon-drive.sh` covers: missing builder binary → clean exit 2, no tick state
      mutated; missing reviewer binary → same; both present → unaffected.
- [ ] `bash validate.sh` green.

## Reversibility & blast radius

**Low.** A pure pre-check inserted before existing logic; the only behavior change is failing
earlier (and more clearly) for a case that already failed anyway, just messily. No containment or
kernel change.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/marathon-drive.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/marathon-drive.sh", "pattern": "GH-117" }
  ],
  "artifacts": [
    "relay-automation/marathon-drive.sh",
    "test/marathon-drive.sh"
  ],
  "remediation": "In relay-automation/marathon-drive.sh, add a binary-existence probe (_probe_bin helper: command -v \"$1\" || die) immediately after the route_agent \"$BUILDER\" / route_agent \"$REVIEWER\" calls (around line 232-233) and before the clean-workspace check (line 256) -- i.e. before any tick task.created/claim/release call, on both --dry-run and live paths. Probe whichever of CLAUDE_AGENT/CODEX_AGENT/AGY_AGENT/AIDER_AGENT got set for BOTH the builder and reviewer, respecting the existing *_BIN override env vars (CLAUDE_BIN/CODEX_BIN/AGY_BIN/AIDER_BIN) the turn scripts already use. A missing binary must die() with a clear message before any tick state is touched. Add test/marathon-drive.sh coverage for missing-builder, missing-reviewer, and both-present-unaffected cases. GH-117 marker comment near the fix.",
  "lanes": {
    "agy_safe": ["relay-automation/marathon-drive.sh", "test/marathon-drive.sh"],
    "orchestrator_only": [],
    "note": "Independent -- marathon-drive.sh is not in the kernel or shim zone by this repo's classifier. Touches the same file GH-116's --retry flag conceptually pairs with, but no write-set overlap (GH-116 only touches marathon.sh) -- parallel-safe with every other Plan C lane."
  }
}
```

## Provenance

Found in a live 3-phase `marathon.sh` run against rebalance-OS: the first phase attempt failed
because the `claude` builder binary wasn't on `PATH`; the relay task was already seeded and left
`open` by the time the failure surfaced, requiring manual recovery. See sibling `#116` (the misleading
`tick break` error encountered while diagnosing that recovery, and the `--retry` flag that would make
recovery itself less manual).
