---
gh_issue: 161
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/161
title: "Audit and add more observability into the harness and individual files"
status: Queued (1-INBOX) — awaiting explore-marathon lane
created: 2026-07-07
updated: 2026-07-07
owner: noel
doc_type: feature
complexity: 3
risk: 1
effort: 3
phases: 1
ratings_provisional: true
non_goals:
  - Not changing containment, allowlist, or commit behavior — logging only, no control-flow changes
  - Not a new external telemetry service — scope is in-repo, inspectable output
related:
  - relay-automation/relay-turn-lib.sh
  - relay-automation/codex-turn.sh
  - relay-automation/agy-turn.sh
  - relay-automation/marathon-drive.sh
  - utils/swarm-preflight.sh
goal: >
  Audit the harness for observability gaps and add structured instrumentation at key decision
  points, so root-causing a future containment/allowlist/worktree bug doesn't require manually
  sourcing relay-turn-lib.sh and hand-constructing an empirical repro from scratch.
roadmap_exempt: false
---

## Key concepts

- Root-causing GH-160 required manually sourcing `relay-turn-lib.sh` and hand-building a repro to
  see what `RTL_ROOT` actually resolved to — there was no direct way to observe that state live.
- Scope: `relay-automation/` shims (`codex-turn.sh`, `agy-turn.sh`, `relay-turn-lib.sh`,
  `marathon-drive.sh`) and `utils/swarm-preflight.sh`.
- Candidate instrumentation points: root resolution, allowlist matching, worktree seed/copy-back,
  containment verdicts.
- Open question: log format/destination and opt-in-vs-always-on, still undecided.

# GH-161 · Audit and add more observability into the harness and individual files

## Status

| What was just completed | What's next |
|---|---|
| Captured as an issue (2026-07-07) with the motivating incident (GH-160) on record. No exploration done yet. | Fire the explore-marathon lane: survey the listed files for existing logging, decide what to instrument, and produce a concrete instrumentation proposal (what, where, format, destination, default-on/off). |

## Idea

Audit the harness (`relay-automation/`, `utils/`, and individual shim scripts like `codex-turn.sh`,
`agy-turn.sh`, `relay-turn-lib.sh`, `marathon-drive.sh`, `swarm-preflight.sh`) for observability
gaps, and add more structured instrumentation.

## Why

Root-causing GH-160 required manually sourcing `relay-turn-lib.sh` and hand-constructing empirical
repros to see what `RTL_ROOT` actually resolved to — there was no direct way to observe that state
from a live run. A harness this size, driving multiple headless agents across many repos, would
benefit from built-in tracing/logging at key decision points (root resolution, allowlist matching,
worktree seed/copy-back, containment verdicts) rather than requiring source-level reconstruction
every time something goes wrong.

## Phase 0 — Explore & scope

Purpose: this is a review/spike, not yet a build — decide what "more observability" concretely means
before writing any instrumentation.

### Checklist

- [ ] Survey the listed files for existing logging (grep for `echo`/`printf` to stderr, `CODEX_LOG`/
      `AGY_LOG` conventions already in place) so new instrumentation doesn't duplicate what's there.
- [ ] List the specific decision points worth instrumenting (root resolution, allowlist match/reject,
      worktree seed/copy-back, containment verdict, tick token transitions) and what each needs to
      emit to have mattered for GH-160/GH-165-style investigations.
- [ ] Decide log format and destination: structured (JSON lines) vs. plain text; per-PID temp file
      (like `CODEX_LOG` today) vs. a persistent, append-only location.
- [ ] Decide default posture: opt-in via an env var (e.g. `RTL_TRACE=1`) vs. always-on at a low
      verbosity level.
- [ ] Propose the concrete change set (files touched, new env vars, output shape) as this doc's next
      phase — do not implement in this phase.

### QA checklist — Phase 0

- [ ] The proposal names concrete decision points, not just "more logging."
- [ ] The proposal states whether it's opt-in or always-on, with a stated reason.
- [ ] The proposal doesn't touch containment/allowlist/commit control flow — logging only.
