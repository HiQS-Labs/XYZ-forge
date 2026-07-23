---
gh_issue: 295
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/295
title: "Add Pi (pi.dev) as a new supported headless builder harness, alongside Codex/agy"
status: "Phase 0 (smoke test) done 2026-07-23; Phase 1 (shim build) starting on branch gh295-pi-builder-integration"
created: 2026-07-23
updated: 2026-07-23
owner: noel
branch: gh295-pi-builder-integration
doc_type: project
effort: 3
complexity: 3
risk: 2
phases: 4
related:
  - "#280 — Aider+Qwen investigation this effort grew out of (Pi surfaced as a candidate cost-visible alternative)"
goal: >
  Ship relay-automation/pi-turn.sh + utils/py/pi-turn.py as a new headless turn-taker shim for the
  Pi coding agent (pi.dev), following the exact safety/dispatch contract codex-turn.sh and agy-turn.sh
  already establish, so Pi becomes a third selectable builder/reviewer lane — not a replacement for
  the codex+agy default pairing.
---

# GH-295 · Add Pi as a new supported builder harness

## Status
| What was just completed | What's next |
|---|---|
| Phase 0 smoke test (2026-07-23): installed `@earendil-works/pi-coding-agent` v0.81.1 globally, confirmed legit (MIT, matches pi.dev + github.com/earendil-works/pi). Headless text-mode (`-p`) and JSON-mode (`--mode json`) calls both verified against `openrouter/openai/gpt-mini-latest` using the harness's existing `OPENROUTER_API_KEY` — JSON mode confirmed to carry per-call cost/usage data inline, a real gap-closer vs. agy's cost-blind lane. Issue #295 filed, this doc promoted straight to 2-WORKING, branch `gh295-pi-builder-integration` cut off `development`. | Phase 1: build `relay-automation/pi-turn.sh` + `utils/py/pi-turn.py` mirroring the `codex-turn.sh`/`agy-turn.sh` shim contract. |

## Table of contents

- [Phase 0 — Discovery: smoke test](#phase-0--discovery-smoke-test) (done)
- [Phase 1 — Shim implementation](#phase-1--shim-implementation)
- [Phase 2 — Test coverage](#phase-2--test-coverage)
- [Phase 3 — README documentation](#phase-3--readme-documentation)
- [Phase 4 — Direct-Alibaba-Qwen validation](#phase-4--direct-alibaba-qwen-validation-blocked)

## Phase 0 — Discovery: smoke test

**What was investigated:** whether Pi (pi.dev) is viable as a new headless builder/reviewer, in the
same shape as Codex CLI / agy CLI, surfaced as a candidate while closing out GH-280 (Aider+Qwen).

**What was found:**
- Legit MIT-licensed package: `npm view @earendil-works/pi-coding-agent` confirms repo
  `github.com/earendil-works/pi`, matches the pi.dev site's install instructions.
- Headless contract confirmed live: `pi --provider openrouter --model <id> --no-session -p "<prompt>"`
  returns cleanly (exit 0) in text mode; `--mode json` streams structured events and — critically —
  includes `usage`/`cost` fields per call, which neither Aider nor agy's print mode expose today.
- Already auto-detects `OPENROUTER_API_KEY` from the environment with zero extra config — `--provider
  openrouter` alone was enough to get a full model catalog and make real calls.
- A real file-edit task (append a line via Pi's own `edit` tool, `--mode json`) succeeded and produced
  the expected file content — confirmed Pi's tool-use loop actually mutates files correctly, not just
  chats.

**What it changes:** confirms Phase 1 (shim build) is worth doing — Pi's CLI surface
(`-p`/`--mode json`/`--provider`/`--model`/`--api-key`/`--no-session`) maps cleanly onto the same shape
`codex-turn.sh` and `agy-turn.sh` already wrap, so no new integration paradigm is needed, just a new shim
following the existing contract.

## Phase 1 — Shim implementation

Build `relay-automation/pi-turn.sh` + `utils/py/pi-turn.py`, mirroring `codex-turn.sh`/`agy-turn.sh`'s
contract exactly:

- Dispatch gate: `PI_AGENT` env var; no-ops (exit 0) unless `RELAY_AGENT == PI_AGENT`.
- Shared safety core: `rtl_init`, `rtl_turn_prompt`, `rtl_drift_brief`, `rtl_before`,
  `rtl_run_bounded`, `rtl_worktree_begin`/`rtl_worktree_end`, `rtl_enforce` — same as every other shim,
  no reimplementation.
- Tick claim-before-launch (same idempotent `tick claim`/`info`/`ping` pattern as codex/agy).
- `RELAY_WORKTREE_ISOLATION=1` support (throwaway worktree of `ROOT@HEAD`).
- `RELAY_TURN_TIMEOUT_S` wall-clock cap via `rtl_run_bounded`, default 900s.
- Persistent transcript via `rtl_default_log` (`PI_LOG`, overridable), exported as `RTL_LOG`.
- Config surface: `PI_BIN` (default `pi`), `PI_PROVIDER` (default `openrouter`, reusing this harness's
  existing OpenRouter seam), `PI_MODEL` (operator-set; no silent default that could hit an
  unlisted-model-style footgun), `PI_FLAGS` (passthrough).
- **This repo's `XYZ_PYTHON` default is `1` (Python-default, GH-264) — the Python port is the actual
  default runtime, not a lagging alternative.** Both files ship together, same as `aider-turn.sh` /
  `utils/py/aider-turn.py`, not Bash-first-Python-later.
- Cost capture: parse `--mode json`'s per-call `usage`/`cost` fields into the same `cost.tokens` shape
  Codex aspires to — this is the one place Pi can do strictly better than the existing lanes, not just
  match them.

### QA gate — Phase 1

- [ ] `pi-turn.sh`/`pi-turn.py` exist, pass `shellcheck`/lint, and share the exact exit-code contract
  (`0` acted/deferred · `5` failed/no ownership · `6` off-lane · `7` timeout · `2` usage).
- [ ] A real headless dry run against `openrouter` (reusing the existing `OPENROUTER_API_KEY`) commits a
  real relay-turn edit end-to-end.

## Phase 2 — Test coverage

Mirror the existing `codex-turn.sh`/`agy-turn.sh` test files (binary-stub pattern) with a
`test/pi-turn.sh` (or `.py` per whichever the Python-default convention uses), wired into `validate.sh`.

### QA gate — Phase 2

- [ ] New test file green locally.
- [ ] `bash validate.sh` still green with the new test wired in.

## Phase 3 — README documentation

Add a Pi section to `relay-automation/README.md` mirroring the Codex/agy sections (env vars, exit
codes, auth/headless contract, known gotchas).

### QA gate — Phase 3

- [ ] Section added, cross-linked from wherever Codex/agy are listed as builder options.

## Phase 4 — Direct-Alibaba-Qwen validation (BLOCKED)

Validate Pi against the actual production Qwen access path from GH-280/268 —
`qwen3.8-max-preview` via Aider's direct (non-OpenRouter) Alibaba MaaS OpenAI-compatible endpoint — not
just the OpenRouter smoke test in Phase 0.

**Blocked:** this environment has no `DASHSCOPE_API_KEY`/equivalent or the direct endpoint URL. The
GH-280 investigation's direct-Alibaba access was set up ad hoc in that session's shell and was never
persisted or documented in-repo (checked: no `.env`, no README mention, no committed config). Needs the
operator to supply the endpoint + credential (or point at wherever it's actually stored) before this
phase can run.

### QA gate — Phase 4

- [ ] Credential/endpoint obtained.
- [ ] Real headless Pi call against the direct endpoint succeeds end-to-end.

## Stuck/failure protocol

Per operator direction: if any phase above hits **3 real failures** (e.g. the shim fails its dry run
three times, or a test stays red across three fix attempts), stop and write the failure detail back
into this doc (what was tried, what broke, current hypothesis) rather than continuing to iterate
silently — this doc is the record a cold agent or the operator picks up from.
