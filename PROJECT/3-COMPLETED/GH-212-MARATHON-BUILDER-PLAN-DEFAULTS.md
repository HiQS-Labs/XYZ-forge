---
gh_issue: 212
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/212
title: "Make marathon builder-default (no billed CLI) and plan-location (PROJECT/2-WORKING) explicit, enforced defaults in the vendored harness"
status: built 2026-07-15 — validate.sh green (only pre-existing #208 red)
created: 2026-07-15
updated: 2026-07-15
owner: noel
doc_type: feedback
complexity: 3
risk: 2
effort: 4
phases: 1
ratings_provisional: true
non_goals:
  - Not building a --builder self/orchestrator mode that hands the builder turn back to the
    invoking interactive agent (considered, operator chose the simpler default-swap approach —
    see Decision below). That remains a real future option if the cost profile of the chosen
    approach ever stops holding.
  - Not touching reviewer defaults (agy) or reviewer routing — only the builder default.
  - Not adding a `brief:` path location check (only the `--plan` YAML's own location is enforced).
related:
  - relay-automation/marathon.sh
  - relay-automation/marathon-drive.sh
  - relay-automation/MARATHON.example.yaml
  - utils/swarm-preflight.sh
  - utils/py/marathon_drive.py
  - GUIDING-PRINCIPLES.md
  - test/marathon.sh
  - test/marathon-drive.sh
goal: >
  Encode two currently-implicit vendored-harness conventions as explicit, enforced defaults so an
  agent given only the vendored `.xyz/` bundle picks the right behavior without pattern-matching a
  downstream repo's prior drift: (1) the marathon builder defaults to a non-per-call-API-billed
  agent, with the billed `claude` CLI builder as a documented opt-in; (2) a marathon plan's YAML +
  phase briefs live under `PROJECT/2-WORKING/`, enforced by `marathon.sh --plan` rather than only
  documented.
---

## Status

| What was just completed | What's next |
|---|---|
| Both parts built same session: `BUILDER` default swapped to `codex` in `marathon.sh`/`marathon-drive.sh`/`utils/py/marathon_drive.py` with `--builder claude` documented as a cost-acknowledged opt-in; `marathon.sh --plan` now refuses a plan outside `PROJECT/2-WORKING/` (exempt: `MARATHON_HOME`-owned paths, or `MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1`), fixing two macOS tmp-dir symlink canonicalization gaps found while testing (same class of issue `swarm-preflight.sh` already works around). `GUIDING-PRINCIPLES.md` documents both defaults + overrides. `test/marathon.sh` (33/33, 3 new guard cases), `test/marathon-drive.sh` (85/85, 1 new default-builder case), `test/xyz-harness-hooks.sh` (47/47, fixed a builder==reviewer collision the default swap exposed) all green. Full `validate.sh`: only the pre-existing, tracked #208 environment red remained. CHANGELOG updated. | Merge / PR at operator's discretion. Noted but out of scope: a real pre-existing instance of the anti-pattern this issue fixes already lives at `marathon-plans/2026-07-15-gh205-207/` (tracked in git, from yesterday's GH-205/206/207 work) — left as historical, not migrated. |

## Problem (as reported)

Two conventions that matter for cost and repo hygiene are implicit — living only in a downstream
repo's prior examples, not in the vendored docs/schema/scripts:

1. **Builder default is a billed CLI.** `relay-automation/marathon.sh` and
   `relay-automation/marathon-drive.sh` both hardcode `BUILDER="claude"`, which routes to the
   headless Claude Code CLI (`CLAUDE_BIN`) — a separate, per-call API-billed subprocess, distinct
   from the interactive session driving the marathon. `utils/swarm-preflight.sh` already suggests
   `--builder codex --reviewer agy` in its generated invocation, so the two entry points disagree
   on the default builder.
2. **No stated home for a marathon plan's artifacts.** `marathon-plans` appears 0 times in any
   vendored doc/schema; `PROJECT/2-WORKING` is referenced ~280 times as the general active-doc home
   but nothing says a `MARATHON.yaml` + its phase briefs must live there. Agents pattern-match a
   downstream repo's prior top-level `marathon-plans/<slug>/` folder instead.

## Decision — Part 1 (builder default)

Two designs were on the table:

- **A. Default `BUILDER` to `codex`** — matches what `swarm-preflight.sh` already suggests, no
  architecture change. Codex bills via the ChatGPT subscription and agy is cost-blind — neither is
  a per-call API charge like the headless `claude` CLI. `--builder claude` stays available as a
  documented, cost-acknowledged opt-in.
- **B. A new `--builder self`/`--builder orchestrator` mode** — `marathon-drive.sh` hands control
  back to the invoking interactive agent for the builder's turn instead of spawning a subprocess,
  then resumes the automated reviewer loop on re-invocation. Literal reading of "the orchestrator
  performs the build turns inline," but a real change to the relay loop's control flow (the loop is
  built around subprocess dispatch via `marathon-agent.sh` → `*-turn.sh` shims; nothing today
  represents "pause and wait for the calling session").

**Operator chose A** (2026-07-15): satisfies "zero builder API charges by default" immediately,
reconciles `marathon.sh`/`marathon-drive.sh` with what `swarm-preflight.sh` already recommends, and
stays inside the existing headless-subprocess architecture. Option B is left as a documented
non-goal, revisitable later if Option A's cost profile stops holding.

## Acceptance criteria

- [x] `relay-automation/marathon.sh` and `relay-automation/marathon-drive.sh` default `BUILDER` to
      `codex`, not `claude`.
- [x] `utils/py/marathon_drive.py` (the opt-in `XYZ_PYTHON=1` port) matches — same CLI contract.
- [x] `--builder claude` remains fully supported, documented in both scripts' `--help`/usage output
      as an explicit, cost-acknowledged opt-in (one-line note: spawns a billed headless Claude Code
      CLI turn-taker, a separate per-call API cost).
- [x] `relay-automation/MARATHON.example.yaml`'s header states the builder default and the cost
      note for `--builder claude`.
- [x] `GUIDING-PRINCIPLES.md` → Conventions documents both the builder default and the plan-location
      convention as first-class, with override instructions.
- [x] `marathon.sh --plan PATH` refuses (exit 2) a plan that resolves outside
      `PROJECT/2-WORKING/` relative to the target repo root, UNLESS: (a) the plan lives under the
      harness's own home (`MARATHON_HOME` — covers shipped examples like
      `relay-automation/MARATHON.example.yaml`, which are reference material, not an
      agent-authored plan for a target repo), or (b) `MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1` is set
      (the documented override knob).
- [x] `test/marathon.sh` fixtures are updated to place their plan YAMLs under
      `PROJECT/2-WORKING/` (dogfooding the new convention) rather than relying on the override; new
      test cases cover refuse-by-default, the override, and the harness-home exemption.
- [x] `test/marathon-drive.sh` is updated so its existing `claude`-identity assertions keep testing
      what they always tested (pin `--builder claude` in the shared `run_driver` helper), with a new
      dedicated case proving the *unset* default now resolves to `codex`.
- [x] `validate.sh` green.

## Scope lock

Edit only: `relay-automation/marathon.sh`, `relay-automation/marathon-drive.sh`,
`relay-automation/MARATHON.example.yaml`, `utils/py/marathon_drive.py`, `GUIDING-PRINCIPLES.md`,
`test/marathon.sh`, `test/marathon-drive.sh`, `test/xyz-harness-hooks.sh` (fixture fixed after the
default swap exposed a builder==reviewer collision), `CHANGELOG.md`, `ROADMAP.md`, plus this doc.
