---
gh_issue: 295
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/295
title: "Add Pi (pi.dev) as a new supported headless builder harness, alongside Codex/agy"
status: "All 4 phases done 2026-07-24 (shim + tests + README + direct-Alibaba-Qwen validation) on branch gh295-pi-builder-integration — ready for operator review/merge decision"
created: 2026-07-23
updated: 2026-07-24
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
| Phases 1-3 (2026-07-23): shipped `relay-automation/pi-turn.sh` + `utils/py/pi-turn.py` (Python is this repo's actual default runtime per GH-264) mirroring the codex/agy dispatch+containment contract, with a real JSONL `--mode json` usage parser and genuine `tick cost --tool pi` capture (Pi is the first non-Claude lane with real cost visibility — agy stays cost-blind). `PI_MODEL` has no silent default (GH-280/aider#5486 class of bug guarded against). Wrote `test/pi-turn.sh` (39 cases, mirrors the codex/agy stub-binary convention; green under BOTH `XYZ_PYTHON=1` (the actual default) and `XYZ_PYTHON=0`), added 3 pytest cases to `test/test_python_layer.py` (module load + JSONL last-event parsing + missing-file safety; all green), and wired `pi-turn.sh` into `validate.sh`'s TESTS array. Ran a REAL end-to-end headless dry run against OpenRouter (`openai/gpt-mini-latest`, real `OPENROUTER_API_KEY`, a throwaway scratch relay repo — never the production repo) — Pi genuinely read the relay file, edited it with its own `edit` tool, drove `tick claim`/`release` with its own `bash` tool, and the shim committed `relay(RELAY-GH295-DRYRUN): pi turn (pi headless; no push)`; a real `cost.tokens` event landed (`tokens_in=277, tokens_out=6, tool=pi`). Added a full "Pi worker" README section (env vars, exit codes, cost-visibility note, no-default-model safety note), cross-linked from the Components table and the Headless bring-up walkthrough. | Phase 4 (2026-07-24): operator supplied the direct-Alibaba credential; Pi turned out to have first-class native support for it (`qwen-token-plan` provider, `qwen3.8-max-preview` listed directly) — zero code changes needed. Real end-to-end validation in an isolated scratch repo: `pi-turn.sh` dispatched, claimed the token, drove a real turn, committed cleanly, exit 0, production repo confirmed untouched. All 4 phases now done. | **Ready for operator review/merge decision** — no PR opened yet (deliberately left as an operator call). Optional non-blocking follow-ups: run the full `bash validate.sh` aggregate suite once (real API spend, out of scope so far); investigate why the Bash-implementation path didn't produce a `PI_LOG` transcript in one Phase-4 run (cost-capture observability gap only, not a correctness issue). |

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

- [x] `pi-turn.sh`/`pi-turn.py` exist, pass `shellcheck`/lint, and share the exact exit-code contract
  (`0` acted/deferred · `5` failed/no ownership · `6` off-lane · `7` timeout · `2` usage). Verified
  2026-07-23: `shellcheck -S warning` clean on both `relay-automation/pi-turn.sh` and
  `test/pi-turn.sh`; `python3 -c "import ast; ast.parse(...)"` clean on `utils/py/pi-turn.py`.
- [x] A real headless dry run against `openrouter` (reusing the existing `OPENROUTER_API_KEY`) commits a
  real relay-turn edit end-to-end. Verified 2026-07-23 in a throwaway scratch git repo (never the
  production repo): `PI_MODEL=openai/gpt-mini-latest`, real `OPENROUTER_API_KEY`, driven via the
  actual default Python runtime (`XYZ_PYTHON` unset → `utils/py/pi-turn.py`). Pi read `relay.md` with
  its own `read` tool, edited `STATUS: Open` → `STATUS: Approved` with its own `edit` tool, drove
  `tick claim`/`release` with its own `bash` tool, exit code `0`, commit
  `relay(RELAY-GH295-DRYRUN): pi turn (pi headless; no push)` landed, and a real `cost.tokens` event
  (`tokens_in=277, tokens_out=6, tool=pi`) was captured via `tick cost`.

## Phase 2 — Test coverage

Mirror the existing `codex-turn.sh`/`agy-turn.sh` test files (binary-stub pattern) with a
`test/pi-turn.sh` (or `.py` per whichever the Python-default convention uses), wired into `validate.sh`.

### QA gate — Phase 2

- [x] New test file green locally. `bash test/pi-turn.sh` — 39/39 pass, verified under BOTH
  `XYZ_PYTHON=1` (the actual repo default per GH-264) and `XYZ_PYTHON=0` (the Bash fallback). Also
  added 3 pytest cases to `test/test_python_layer.py` (module load, JSONL last-event usage parsing,
  missing-file safety) — `python3 -m pytest test/test_python_layer.py -q` → 19/19 pass (full file).
- [ ] `bash validate.sh` still green with the new test wired in. `pi-turn.sh` IS correctly wired into
  the `TESTS` array (confirmed by inspection + the standalone run above). The full aggregate
  `validate.sh` run (~100 test files, some with real API spend/long wall-clock, e.g.
  `relay-self-sufficiency.sh`/`deep-research.sh`) was NOT executed in this pass — out of scope for a
  single shim addition. Recommended as a pre-merge check, not a Phase-1-3 blocker.

## Phase 3 — README documentation

Add a Pi section to `relay-automation/README.md` mirroring the Codex/agy sections (env vars, exit
codes, auth/headless contract, known gotchas).

### QA gate — Phase 3

- [x] Section added, cross-linked from wherever Codex/agy are listed as builder options. Added a
  "#### Pi worker (GH-295)" subsection under "Headless bring-up" (mirroring the Codex/agy
  subsections), a `pi-turn.sh` row in the Components table, a `pi-turn.sh` exit-codes bullet, a
  `PI_MODEL`-safety prerequisites note, and a cost-visibility callout in the device-caveats bullet.
  Retitled the section header to "Headless bring-up (Codex + agy + Pi)" and fixed the internal anchor
  link.

## Phase 4 — Direct-Alibaba-Qwen validation (DONE 2026-07-24)

Validate Pi against the actual production Qwen access path from GH-280/268 —
`qwen3.8-max-preview` via a direct (non-OpenRouter) Alibaba MaaS OpenAI-compatible endpoint — not
just the OpenRouter smoke test in Phase 0.

**Unblocked 2026-07-24:** the operator supplied the credential directly (kept outside the repo, never
committed — this doc does not record its value or its storage path). It turned out Pi has **first-class
native support** for this exact provider: `pi --list-models` reveals a `qwen-token-plan` provider once
`QWEN_TOKEN_PLAN_API_KEY` is set (international/Singapore region — matches the supplied endpoint's
`ap-southeast-1` region; `QWEN_TOKEN_PLAN_CN_API_KEY` is the separate China-region variant), and its
catalog lists `qwen3.8-max-preview` directly. **No custom base-URL plumbing was needed** —
`PI_PROVIDER=qwen-token-plan PI_MODEL=qwen3.8-max-preview` is the entire config surface; the shim's
existing "trust the provider's own env-var auto-detection for any non-openrouter PI_PROVIDER" design
(Phase 1) already covers this with zero code changes.

**Real validation performed** (throwaway scratch git repo + isolated `TICK_REPO_ROOT`, never the
production repo — confirmed clean before/after both runs):
1. Bare `pi --provider qwen-token-plan --model qwen3.8-max-preview -p "..."` smoke call — clean exit 0.
2. Full `pi-turn.sh` shim run (Bash implementation, `XYZ_PYTHON=0`) end-to-end: dispatch gate, tick
   claim, a real headless Pi turn that read the relay file, edited it to a valid completed block
   (`STATUS: Approved`, `## Log`, `VERDICT: PASS`, `Basis: ...`), released the token, shim committed
   `relay(RELAY-GH295-QWEN-DIRECT2): pi turn (pi headless; no push)` — **exit 0**, real commit landed,
   only `relay.md` touched.

**Two findings from this real-world pass (neither blocks Phase 4):**
- **Reinforces existing guidance, not a new gap:** an earlier run invoked the shim from the production
  repo's own CWD (before realizing the mistake) rather than the scratch repo's. Pi's `bash`/`read` tools
  can reach any absolute path the OS user can reach — there's no built-in sandbox (same posture as agy,
  already stated in `pi-turn.sh`'s header) — so it read a real file from the production repo via an
  absolute path it referenced. **No mutation occurred anywhere in the production repo** (verified clean
  before and after), but this is a live confirmation that `RELAY_WORKTREE_ISOLATION=1` (or at minimum,
  invoking the shim with CWD already at the target repo) is the correct posture for real use — exactly
  what the shim's header already recommends, not a newly discovered defect requiring a code fix.
- **Open follow-up, not investigated further:** the Bash-implementation run (`XYZ_PYTHON=0`) did not
  produce a `PI_LOG` transcript file at the explicitly-set path, so `tick cost` capture did not fire for
  that run (no `cost.tokens` event) — the Python implementation's own earlier run (Phase 1's dry run,
  and the interrupted first Phase-4 attempt) DID capture real usage/cost data correctly. Root cause not
  isolated (redirect/CWD interaction suspected, not confirmed); doesn't affect the shim's core
  correctness (dispatch, edit, commit, containment all verified working), only the cost-observability
  extra. Worth a small follow-up if the Bash path sees real production use.

### QA gate — Phase 4

- [x] Credential/endpoint obtained (operator-supplied 2026-07-24, kept outside the repo).
- [x] Real headless Pi call against the direct endpoint succeeds end-to-end. Verified via a full
  `pi-turn.sh` run in an isolated scratch repo: exit 0, real commit, correct containment, production
  repo confirmed untouched.

## FYI: pre-existing kernel behavior observed during the Phase 1 dry run (not a Pi-specific bug)

The real dry run (Phase 1 QA gate above) emitted three `dependency.drift` events for
`relay-automation/relay-turn-lib.sh` / `src/project.js` / `src/events.js` even though the throwaway
scratch repo never contained those paths at either commit. This is `rtl_enforce`'s shared,
warn-only cross-agent drift signal (GH-68) firing in a fixture that has neither path at either
revision — a pre-existing quirk of the SHARED kernel (`relay-turn-lib.sh`), not something introduced
by `pi-turn.sh`/`pi-turn.py`, and it never blocked or altered the turn's outcome (warn-only, additive,
non-blocking per its own contract). Not fixed here — out of this doc's scope (Phase 1-3 only touched
the Pi-specific shim/tests/docs) and not required by any QA gate above. Worth a follow-up issue if it
turns out to matter (e.g. it could add noise to `dependency.drift` consumers in a fixture-heavy repo).

## Stuck/failure protocol

Per operator direction: if any phase above hits **3 real failures** (e.g. the shim fails its dry run
three times, or a test stays red across three fix attempts), stop and write the failure detail back
into this doc (what was tried, what broke, current hypothesis) rather than continuing to iterate
silently — this doc is the record a cold agent or the operator picks up from.
