---
gh_issue: 238
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/238
title: "marathon-drive: pre-advance gate defaults to `bash validate.sh` — halts AFTER approval in any consuming repo without it"
status: "SHIPPED — closed 2026-07-21, see GitHub issue comment for evidence (commit d999c36,
  merged PR #243; Python port commit b180ace)."
created: 2026-07-18
updated: 2026-07-18
owner: noel
doc_type: bug
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not fixing validate.sh's own failing tests — that is GH-170 / GH-232, a different problem
  - Not silently skipping the gate when its target is missing — that weakens a safety gate to buy
    convenience; fail fast instead
  - Not making the default mode-dependent (different default under a vendored `.xyz/` layout) —
    an invisible context-dependent default is the same failure class being fixed
related:
  - relay-automation/marathon-drive.sh
  - relay-automation/MARATHON.example.yaml
  - PROJECT/2-WORKING/MARATHON-PLAN-2026-07-18-J-VENDORED-CONSUMER-DX.md
goal: >
  Resolve and probe the pre-advance gate command before the first builder turn, so a consuming repo
  without `validate.sh` fails immediately with an actionable message instead of after a full paid
  build + review cycle — and document the gate default in MARATHON.example.yaml, where a new
  consumer authoring their first plan actually looks.
roadmap_exempt: false
---

# GH-238 · pre-advance gate default fails late in consuming repos

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-07-18 from an external field report filed against a vendored `.xyz/` consumer (`Hypercart-Dev-Tools/rebalance-OS`). Promoted to `2-WORKING` with a Swarm Preflight Contract. All load-bearing claims verified against source. Not yet fixed. | Fire as lane J1 of [MARATHON-PLAN-2026-07-18-J](MARATHON-PLAN-2026-07-18-J-VENDORED-CONSUMER-DX.md), in parallel with GH-239 (disjoint write-sets). |
| **2026-07-21:** shipped via commit `d999c36`, merged PR [#243](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/243); Python port shipped commit `b180ace`; issue #238 closed on GitHub. | Promoted to `3-COMPLETED`. Nothing further for this doc. |

## The bug (verified, not hypothetical)

`marathon-drive.sh` defaults its pre-advance gate to `bash <ROOT>/validate.sh` and never checks that
the file exists. In a vendored `.xyz/` install the consuming repo usually has no `validate.sh`, so
the gate fails — but only *after* the relay has already built and approved the phase.

Verified in source:

| Claim | Evidence |
|---|---|
| Default is `bash <ROOT>/validate.sh` | `relay-automation/marathon-drive.sh:376` — `PRE_ADVANCE_CMD="${PRE_ADVANCE_CMD:-"bash $ROOT/validate.sh"}"` |
| Resolved late, never existence-checked | `:334` initialises it empty (`# resolved to default after ROOT is set`); `:376` fills it; nothing probes the path before turn 1 |
| Gate runs after relay approval | `:751` — `log "relay approved — running pre-advance gate: $PRE_ADVANCE_CMD"`, before `marathon.phase.approved` is emitted |
| Example plan never mentions the gate | `relay-automation/MARATHON.example.yaml` is 46 lines documenting per-phase fields only — no mention of `--pre-advance-cmd`, `validate.sh`, or gating at all |

Observed sequence on a repo without `validate.sh`:

1. builder turn runs (full cost)
2. reviewer turn runs (full cost)
3. relay approves
4. gate runs `bash validate.sh` → `No such file or directory`
5. chain halts at exit 5; phase never marked approved

## Wider than reported

The reporter only described the happy path. The gate is **also** probed on two recovery paths:

- `:662` — relay timed out (exit 7) with declared artifacts present
- `:779` — relay stalled (exit 3) with declared artifacts present

A missing gate target degrades both rescue paths too, not just the normal advance. The fix must
cover all three call sites, or an early-resolve check that runs once at startup must guarantee it.

## Why the default is awkward

`validate.sh` is this repo's own gate script. As a default it assumes the consumer looks like this
repo — but the vendored `.xyz/` path exists precisely to serve repos that don't. The default is
right for a self-hosted run and wrong for every vendored one, with no signal about which mode
you're in until two paid turns have already been spent.

## Fix direction

1. **Fail fast at plan load.** After `ROOT` is resolved and `PRE_ADVANCE_CMD` is defaulted
   (`:376`), verify the gate command is actually runnable *before* the first builder turn. If it
   isn't, exit immediately with a message naming the resolved command, the reason, and the
   `--pre-advance-cmd` flag as the remedy.
2. **Document the default** in `MARATHON.example.yaml` — a short block covering the gate, its
   default, and when a consuming repo must override it.
3. Confirm the early check also protects the `:662` and `:779` recovery probes (either by running
   once at startup, or by covering each site).

## Definition of done

- [ ] `marathon-drive.sh` refuses to start when the resolved pre-advance gate is not runnable,
      before any builder turn is dispatched, with a message naming the command and `--pre-advance-cmd`.
- [ ] `MARATHON.example.yaml` documents the gate default and when to override it.
- [ ] A regression test asserts the failure happens *before* turn 1 (not merely that it fails).
- [ ] `bash validate.sh` no worse than baseline.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/marathon-drive.sh", "pattern": "pre-advance gate not runnable" },
    { "type": "grep_absent", "path": "relay-automation/MARATHON.example.yaml", "pattern": "pre-advance-cmd" }
  ],
  "artifacts": [ "relay-automation/marathon-drive.sh", "relay-automation/MARATHON.example.yaml", "test/marathon-drive.sh" ],
  "remediation": {
    "source": "issue#238",
    "criteria": "marathon-drive.sh resolves and probes PRE_ADVANCE_CMD before dispatching the first builder turn, exiting with an actionable message (containing the phrase 'pre-advance gate not runnable', the resolved command, and the --pre-advance-cmd remedy) when the gate cannot run; the same guarantee covers the exit-7 and exit-3 recovery probes at lines ~662 and ~779. MARATHON.example.yaml documents the --pre-advance-cmd default and when a consuming repo must override it. A regression test asserts the refusal occurs before turn 1. bash validate.sh green, no worse than pre-existing environmental reds."
  },
  "lanes": {
    "agy_safe": [ "relay-automation/MARATHON.example.yaml" ],
    "orchestrator_only": [ "relay-automation/marathon-drive.sh", "test/marathon-drive.sh" ]
  }
}
```
