---
title: Leverage the built-in /loop skill to drive relays (adaptive cadence + unify Path A/B)
status: Proposed (1-INBOX — not yet active)
created: 2026-06-27
updated: 2026-06-27
owner: noel
goal: >
  Use the built-in Claude Code /loop skill (recurring + self-paced "dynamic" mode,
  backed by ScheduleWakeup) as a first-class cadence and lifecycle engine for the
  relay harness — replacing the fixed-interval /loop 60s of Path B and complementing
  (not replacing) the blocking model-free supervisor relay-drive.sh of Path A.
  Net target: one relay mode that is BOTH hands-free AND cross-model.
doc_type: project
non_goals:
  - Not replacing relay-drive.sh — its blocking, model-free determinism stays the unattended/CI mode
  - Not weakening the tick token as the correctness guard (/loop is cadence only, never the lock)
  - Not adding cross-machine coordination (/loop and cron are per-session; tick stays the cross-machine path)
  - Not changing default behavior when the new mode is unused (additive, opt-in)
related:
  - relay-automation/poll.sh
  - relay-automation/relay-drive.sh
  - relay-automation/relay-turn-lib.sh
  - skills/relay-xyz/SKILL.md
  - PROJECT/PDDA.md
gh_issue: 33
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/33
roadmap_exempt: false
---

## Status

| What was just completed | What's next |
|---|---|
| Phase 0 intake done: issue [#33](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/33) opened, doc named `GH-33-…`, parked in ROADMAP queue. Design captured from a live external-consumer session (the one that also produced #31/#32). Confirmed `poll.sh` is already a stateless one-shot decision oracle (no internal sleep/loop), so the `/loop`=scheduler ÷ `poll.sh`=decision seam already exists. | Decide the open Phase 0 gate — whether the integration ships as a new thin wrapper (`relay-loop.sh`) or as a `--driver loop` mode inside `relay-drive.sh` — then promote to `2-WORKING` before any code. Queued, not in progress. |

## Effort & Risk (the question asked)

- **Effort: Moderate→Large, but cleanly phased.** The cadence work (Phases 1–2) is small and additive because `poll.sh` already exposes a single `DECISION`. The cost concentrates in Phase 4 (background-Bash turn dispatch + the Path A/B unification), which touches the turn shims and the containment boundary.
- **Risk: mixed — Easy for cadence, Costly for dispatch.** Phases 1–3 are reversible and default-off (cadence/lifecycle only). Phase 4 touches `relay-turn-lib.sh` containment + commit semantics; `AGENTS.md` flags containment changes as "broader than they look."
- **Blast radius:** `poll.sh` (decision output), `relay-drive.sh` (Path A supervisor), the turn shims (`codex-turn.sh` / `agy-turn.sh`), `relay-turn-lib.sh` (containment core), and the `relay-xyz` SKILL's Path A/B recipes. Cadence phases touch only the first; dispatch phases touch the rest.
- **Reversibility read:** Easy to roll back cadence (the new mode is opt-in; unused → today's behavior is byte-for-byte unchanged). Costly to roll back if a background-dispatch mode is adopted operationally and then removed. Mitigation: keep `relay-drive.sh` as the always-available deterministic mode; the `/loop` mode is strictly additive.

## Table of Contents

- [Status](#status)
- [Effort & Risk (the question asked)](#effort--risk-the-question-asked)
- [Problem](#problem)
- [Why this is cheap (the existing seam)](#why-this-is-cheap-the-existing-seam)
- [Phase 0 — Intake & decision gate](#phase-0--intake--decision-gate)
- [Phase 1 — poll.sh emits a suggested next-delay](#phase-1--pollsh-emits-a-suggested-next-delay)
- [Phase 2 — Adaptive cadence via /loop dynamic mode](#phase-2--adaptive-cadence-via-loop-dynamic-mode)
- [Phase 3 — Background-Bash turn dispatch](#phase-3--background-bash-turn-dispatch)
- [Phase 4 — Unify Path A and Path B (hands-free + cross-model)](#phase-4--unify-path-a-and-path-b-hands-free--cross-model)
- [Phase 5 — Let /loop own lifecycle](#phase-5--let-loop-own-lifecycle)
- [Phase 6 — Docs, defaults, and validation](#phase-6--docs-defaults-and-validation)

## Problem

The relay harness has two automated paths, and each is half a solution:

- **Path A — `relay-drive.sh`** (headless single-session): can drive Codex/agy turns, but it **blocks the session** for the whole run, does **not** use `/loop`, and is **opaque between turns** (a one-shot review ends in `exit 3` "no progress after handback" — looks like a stall; you must read the relay file to learn the verdict).
- **Path B — `/loop` + `poll.sh`** (hands-free, two live Claude windows): hands-free, but the loop ticks at a fixed `60s` regardless of state, and it **cannot act on a cross-model turn** — when the token belongs to a non-Claude agent it emits `DECISION: nudge-cross-model`, a manual nudge for a human.

So today you choose between *hands-free but all-Claude* (Path B) or *cross-model but blocking and opaque* (Path A). The built-in `/loop` skill — recurring **and** self-paced "dynamic" mode, with `ScheduleWakeup` deciding the next wake, plus background-Bash completion re-invoking the model automatically — is the missing cadence/lifecycle engine that can give us *both* properties at once.

## Why this is cheap (the existing seam)

`poll.sh` is already a **stateless, one-shot decision oracle**: it parses args, computes exactly one `DECISION` (`run-runner | idle | nudge-cross-model | run-watchdog | stop`) from coordination state, and exits — it does **no** sleeping or looping itself (`--deadline EPOCH` self-expiry aside). All cadence already comes from the `/loop` wrapper. That clean split — **`/loop` = scheduler/lifecycle, `poll.sh` = pure decision function** — is exactly the factoring this project needs, so most of the work is connecting two existing capabilities rather than building new control flow.

## Phase 0 — Intake & decision gate

- [x] Open a GitHub issue describing the `/loop` integration (issue-first SOP). → [#33](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/33)
- [x] Name this doc `PROJECT/1-INBOX/GH-33-LOOP-SKILL-INTEGRATION.md` and set `gh_issue` in frontmatter.
- [x] Park a one-line queue pointer in `ROADMAP.md` linking this inbox doc.
- [ ] Decide the shipping shape: **(A)** a new thin wrapper `relay-automation/relay-loop.sh` that maps `poll.sh` decisions to act / background-dispatch / reschedule, vs **(B)** a `--driver loop` mode inside `relay-drive.sh`. Record the call + reversibility in `CHANGELOG.md`.
- [ ] Confirm scope ordering with the operator: ship Phase 2 (adaptive cadence, cheap) first, or go straight for Phase 4 (the unification, the capability win).

### QA checklist — Phase 0

- [ ] GH issue exists and is linked from both the doc frontmatter and `ROADMAP.md`.
- [ ] `utils/pdda-check-roadmap-coverage.sh` passes (inbox doc is parked).
- [ ] Shipping-shape decision (A or B) is written down, not implicit.
- [ ] No code changed in this phase.

## Phase 1 — poll.sh emits a suggested next-delay

- [ ] Add an optional `--emit-delay` (or always-on extra stdout line) so each `poll.sh` run prints a suggested next-poll delay alongside its `DECISION` (derived from the same state it already computes: `run-runner`→0, `idle`→long, `nudge-cross-model`→medium, near-`--deadline`→tighten).
- [ ] Keep it purely additive: the existing `DECISION:` line is unchanged; consumers that ignore the new line behave exactly as today.
- [ ] Unit-cover the delay mapping for each `DECISION` and the near-deadline tightening.

### QA checklist — Phase 1

- [ ] Existing `poll.sh` callers (incl. the current `/loop 60s` recipe) are unaffected when they ignore the new output.
- [ ] Delay suggestion is a pure function of state (no wall-clock nondeterminism beyond the deadline read).
- [ ] New tests pass under `./validate.sh`.

## Phase 2 — Adaptive cadence via /loop dynamic mode

- [ ] Document a `/loop` **dynamic-mode** recipe (no fixed interval) where the model calls `poll.sh`, then schedules the next wake from the suggested delay (Phase 1) via `ScheduleWakeup`.
- [ ] Respect the prompt-cache window economics: idle backoff may cross the 5-min cache TTL (acceptable — the win is tokens, not cache), but active turns stay sub-cache-window.
- [ ] Add a `relay-xyz` SKILL note describing fixed-interval (today) vs dynamic (new) Path B, with the tradeoff.

### QA checklist — Phase 2

- [ ] Idle relays back off (fewer ticks/tokens) while a live turn still advances promptly.
- [ ] The fixed-`60s` recipe still works unchanged (dynamic mode is opt-in).
- [ ] `tick` claim/heartbeat cadence is unchanged — only the *poll* cadence adapts.

## Phase 3 — Background-Bash turn dispatch

- [ ] Document/support running a turn shim (`codex-turn.sh` / `agy-turn.sh` / the Claude turn) as a **background** process so the session is freed during the turn and the harness re-invokes on completion (no polling for harness-tracked work).
- [ ] Verify the turn shim's safety boundary (path-allowlist, commit-bypass guard, no-push, worktree isolation) holds identically when launched in the background.
- [ ] On completion, the resuming session reads `STATUS:` / token state and decides hand-off vs stop.

### QA checklist — Phase 3

- [ ] A backgrounded turn enforces the same containment as a foreground turn (off-allowlist edit reverted, no push).
- [ ] Session is not blocked for the turn's duration; completion re-invokes the model.
- [ ] No double-dispatch: the token/lock prevents a second turn firing while one runs.

## Phase 4 — Unify Path A and Path B (hands-free + cross-model)

- [ ] In the `/loop`-driven supervisor (shape from Phase 0), on `DECISION: run-runner` take the turn; on `DECISION: nudge-cross-model` **launch the cross-model shim (`codex-turn.sh` / `agy-turn.sh`) as background Bash** instead of surfacing a human nudge.
- [ ] Preserve the `--claude-agents` semantics: an agent genuinely unreachable headless (no CLI on PATH) still degrades to a manual nudge rather than a silent stall.
- [ ] Terminal `STATUS: Approved|Closed` (and `--deadline`) stop the loop cleanly — a "Changes requested, handed back" turn is *continue*, not a confusing `exit 3`.

### QA checklist — Phase 4

- [ ] A relay whose next turn is Codex/agy advances **without** a human nudge when the CLI is on PATH.
- [ ] Containment + token correctness identical to Path A (no widened allowlist, no orphaned cross-repo commit — see the `rtl_enforce` hazard and GH-29).
- [ ] `relay-drive.sh` (deterministic mode) remains fully functional and unchanged.
- [ ] `./validate.sh` green.

## Phase 5 — Let /loop own lifecycle

- [ ] Reduce `poll.sh` `--deadline` self-expiry to a pure oracle output (it already emits `DECISION: stop` past the deadline); let the `/loop` mode own start/stop so lifecycle isn't reimplemented in bash.
- [ ] Keep the bash `--deadline` for the standalone (`/loop`-less) poll usage — do not regress the existing self-close guarantee.

### QA checklist — Phase 5

- [ ] Standalone `poll.sh --deadline …` still self-closes (no regression for non-`/loop` callers).
- [ ] The `/loop` mode stops on terminal STATUS and on its own deadline without bash duplicating the timer.

## Phase 6 — Docs, defaults, and validation

- [ ] Document the new mode in `relay-automation/README.md` and the `relay-xyz` SKILL (Path A = deterministic/CI, Path B-fixed = today, Path B-dynamic = adaptive, Unified = hands-free + cross-model).
- [ ] State the default-unchanged guarantee and the "keep `relay-drive.sh`" rationale.
- [ ] Add a `CHANGELOG.md` entry recording the bet (Costly: containment/dispatch touch in Phase 4) with the reversibility read and a revisit trigger.
- [ ] Promote this doc to `PROJECT/2-WORKING/` with the full active-doc contract intact.

### QA checklist — Phase 6

- [ ] `./validate.sh` green.
- [ ] `utils/pdda-run.sh` clean (frontmatter, status table, hardcoded paths, roadmap coverage).
- [ ] Docs describe every mode; no hardcoded absolute paths in the docs.
- [ ] `CHANGELOG.md` entry present with the bet recorded.
