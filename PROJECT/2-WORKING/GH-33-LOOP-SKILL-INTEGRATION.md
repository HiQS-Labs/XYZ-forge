---
title: Leverage the built-in /loop skill to drive relays (adaptive cadence + unify Path A/B)
status: Active (2-WORKING)
created: 2026-06-27
updated: 2026-06-28
owner: noel
goal: >
  Use the built-in Claude Code /loop skill (recurring + self-paced "dynamic" mode,
  backed by ScheduleWakeup) as a first-class cadence and lifecycle engine for the
  relay harness — replacing the fixed-interval /loop 60s of Path B and complementing
  (not replacing) the blocking model-free supervisor relay-drive.sh of Path A.
  Net target: one relay mode that is BOTH hands-free AND cross-model.
doc_type: project
complexity: high
risk: high
effort: high
ratings_provisional: true
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
| **Phase 3 shipped** (2026-06-28, inline Opus). `relay-automation/relay-loop.sh --background`: dispatches the turn DETACHED on `run-runner` and returns at once (session freed; scheduler re-invokes next tick), a pidfile is the single-turn lock (`BG-RUNNING` → no double-dispatch; stale pidfile cleared on completion → fresh decision acted on). **Containment inherited** — the backgrounded process is the same runner, so the `relay-turn-lib.sh` boundary is byte-identical (proven by an fg/bg parity test). `poll.sh` stays a pure oracle (reused its `--dry-run`). +6 cases in `test/relay-loop.sh` (**11/11**); README Components row added; **`validate.sh` green**. Phases 0–2 already merged (#35). | **Phase 4 contract authored** (below) → **firing the marathon dogfood** (`swarm-preflight → marathon-drive`, codex builder + agy reviewer): on `nudge-cross-model` launch the cross-model shim as background Bash (reusing Phase 3's `bg_launch` + pidfile lock) instead of a human nudge, with CLI-absent → degrade-to-nudge. Scope-locked to relay-loop.sh/poll.sh/test/README; `relay-turn-lib.sh` is OUT of scope (containment byte-identical). |

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
- [FAQ](#faq)
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

## FAQ

### Does this lock us into Anthropic / Claude models?

**No — not entirely, and the part that does couple is the smallest, most replaceable layer.** Three layers:

- **Workers (who takes the turns):** already multi-vendor. The harness drives **Codex (OpenAI)** and **agy (Antigravity/Gemini)** as first-class turn-takers, plus Claude. GH-33 changes nothing here — zero model lock-in on the content work.
- **Decision oracle (`poll.sh`, incl. Phase 1's `--emit-delay`):** pure bash, no Anthropic dependency. The `DELAY:` line is plain text any scheduler can read — cron, a systemd timer, a `while sleep` loop, or another agent. Fully portable.
- **Cadence driver:** *only here* is there Claude-specific coupling, and only if you use `/loop` **dynamic mode** (the `ScheduleWakeup`-backed self-pacing), which lives in Claude Code. It is opt-in and additive — `relay-drive.sh` (model-free, harness-free) and fixed-interval cron stay fully working.

The Phase 0 decision *reduces* lock-in: the thin `relay-loop.sh` wrapper consumes the generic `DELAY:` output, so the reschedule step can be `/loop` **or** cron **or** anything. Phase 2 keeps that reschedule pluggable rather than hardcoding `ScheduleWakeup`, so "drop Claude Code" = "swap the sleeper," not a rewrite.

### What is the next safe-but-usable phase?

**Phase 2.** Phase 1 is safe but is only an enabling primitive (it emits a number nothing consumes yet). Phase 2 (the `/loop` dynamic-mode recipe + the `relay-loop.sh` wrapper that consumes `--emit-delay`) is the next phase that is *both* low-risk **and** independently useful: additive, **no containment touch**, and it delivers a real benefit on its own (idle relays back off → token savings; active loops respond faster). The Costly line starts at **Phase 3**.

### Do we have to go all the way to Phase 6?

**No — each phase is independently shippable; stop at any plateau.**

- **Stop after Phase 2** → adaptive cadence for all-Claude / Path-B relays. Cheap, safe, done. Does *not* include cross-model hands-free.
- **Phases 3–4** → the marquee feature (cross-model relays advancing **unattended**) — a separate, bigger bet and the Costly/containment part. Opt in only if wanted.
- **Phase 5** = lifecycle cleanup (optional polish); **Phase 6** = docs + promote to `2-WORKING` (only when graduating it for real).

Honest tension: the cheapest safe phase (2) is **not** the headline benefit — the headline (cross-model hands-free) lives in the **Costly phases (3–4)**. Stopping at 2 buys the token/latency win but not the "walk away from a Codex review" win.

## Phase 0 — Intake & decision gate

- [x] Open a GitHub issue describing the `/loop` integration (issue-first SOP). → [#33](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/33)
- [x] Name this doc `PROJECT/1-INBOX/GH-33-LOOP-SKILL-INTEGRATION.md` and set `gh_issue` in frontmatter.
- [x] Park a one-line queue pointer in `ROADMAP.md` linking this inbox doc.
- [x] Decide the shipping shape: **chose (A)** — a new thin wrapper `relay-automation/relay-loop.sh` that maps `poll.sh` decisions to act / background-dispatch / reschedule, over (B) a `--driver loop` mode inside `relay-drive.sh`. Rationale: keeps the deterministic supervisor untouched (smaller blast radius), composes with the existing `--dry-run`/`--emit-delay` oracle, and is fully removable. (CHANGELOG entry lands when Phase 2 promotes to `2-WORKING`.)
- [x] Confirm scope ordering: **Phase 2 (adaptive cadence) first**, then Phases 3–4 (the unification) behind an explicit operator GO — they touch containment (Costly).

### QA checklist — Phase 0

- [x] GH issue exists and is linked from both the doc frontmatter and `ROADMAP.md`.
- [x] `utils/pdda-check-roadmap-coverage.sh` passes (inbox doc is parked).
- [x] Shipping-shape decision (A or B) is written down, not implicit.
- [x] No code changed in this phase. (Code begins in Phase 1, below.)

## Phase 1 — poll.sh emits a suggested next-delay ✅ (shipped)

- [x] Added `--emit-delay` so each `poll.sh` run prints a `DELAY: <seconds> (<reason>)` line alongside its `DECISION`, derived from the same state it already computes: `run-runner`/`run-watchdog`/`stop`→0, idle-dirty→`POLL_DELAY_DIRTY` (30), waiting-for-peer-commit→`POLL_DELAY_WAIT_COMMIT` (90), `nudge-cross-model`→`POLL_DELAY_NUDGE` (120), idle-backoff→`POLL_DELAY_IDLE` (300), then **clamped** so the next wake never overshoots `--deadline`.
- [x] Purely additive: the existing `DECISION:` line is unchanged; callers that ignore the new line behave exactly as today (flag is opt-in, default off).
- [x] Unit-covered the delay mapping for each decision + the env override + the near-deadline clamp (8 new assertions in `test/poll-driver.sh`).

### QA checklist — Phase 1

- [x] Existing `poll.sh` callers (incl. the current `/loop 60s` recipe) are unaffected when they ignore the new output.
- [x] Delay suggestion is a pure function of state (only wall-clock read is the deadline clamp, matching the existing `--deadline` behaviour).
- [x] New tests pass under `./validate.sh` — **50/50**, skill tarball repackaged so `skill-extract.sh` parity holds.

## Phase 2 — Adaptive cadence via /loop dynamic mode ✅ (shipped)

- [x] Built `relay-automation/relay-loop.sh` (the Phase-0 thin wrapper): default = one tick that prints `NEXT-POLL: <seconds>` and exits `poll.sh`'s code, for a `/loop` dynamic-mode tick to read and `ScheduleWakeup` from. Documented the dynamic-mode `/loop` recipe in the `relay-xyz` SKILL.
- [x] Respected the prompt-cache window economics: idle backoff is 300s (crosses the 5-min TTL by design — the win is tokens), active states (dirty 30 / wait-commit 90 / nudge 120) stay sub-cache-window. Encoded in the Phase 1 delay defaults.
- [x] Added the `relay-xyz` SKILL note ("Path B cadence — fixed interval (today) vs adaptive") describing the tradeoff + the dynamic-mode recipe; **kept the reschedule pluggable** — `relay-loop.sh --sleep-loop` self-paces in pure bash and the `NEXT-POLL`/`DELAY` output is consumable by cron/systemd, so `/loop` is one option, not a dependency (addresses the lock-in FAQ).

### QA checklist — Phase 2

- [x] Idle relays back off (NEXT-POLL 300) while a live turn still advances promptly (NEXT-POLL 0) — asserted in `test/relay-loop.sh`.
- [x] The fixed-`60s` recipe still works unchanged (dynamic mode is opt-in; `--emit-delay` is additive, `DECISION:` line untouched).
- [x] `tick` claim/heartbeat cadence is unchanged — only the *poll* cadence adapts (wrapper touches no token logic).
- [x] `validate.sh` green with the new `relay-loop.sh` test registered + the script packaged (`skill-extract.sh` 15 files).

## Swarm Preflight Contract

> **Active target: Phase 4** (unify Path A/B — cross-model turns advance unattended).
> Phase 3 (background dispatch) **shipped 2026-06-28** — its contract probes now read
> `already-landed`. This contract supersedes it for the next fire (the marathon dogfood).

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/relay-loop.sh", "pattern": "cross-model-cmd", "note": "Phase 4 adds a --cross-model-cmd flag so --background launches the cross-model shim on nudge-cross-model; the flag is absent today → fix still required" },
    { "type": "grep_absent", "path": "test/relay-loop.sh", "pattern": "cross-model-cmd", "note": "Phase 4 adds a --cross-model-cmd background-dispatch test case; absent today → fix still required" }
  ],
  "artifacts": [
    "relay-automation/relay-loop.sh",
    "relay-automation/poll.sh",
    "test/relay-loop.sh",
    "relay-automation/README.md"
  ],
  "remediation": "Unify Path A/B in relay-loop.sh --background: on DECISION: nudge-cross-model, launch the cross-model turn shim (codex-turn.sh / agy-turn.sh) as a DETACHED background process — reuse the Phase 3 bg_launch + pidfile single-turn lock — instead of printing a human nudge, so a Codex/agy turn advances unattended. Add a --cross-model-cmd flag (mirror --runner-cmd) for the command to run for a cross-model turn; if it is unset OR the agent's CLI is not on PATH, DEGRADE to the existing human-nudge (never a silent stall) — preserve --claude-agents semantics. Containment + token correctness MUST be identical to Path A: do NOT modify relay-turn-lib.sh, do NOT widen any allowlist (the backgrounded shim already enforces the boundary). Keep poll.sh a pure oracle. Extend test/relay-loop.sh with: (a) nudge-cross-model + --background + --cross-model-cmd -> BG-DISPATCH of the shim, single-dispatch lock holds; (b) cross-model CLI absent -> degrades to nudge, no dispatch. Update the relay-loop.sh README row. SCOPE LOCK: edit ONLY the four artifacts; verify with `bash test/relay-loop.sh` ONLY — do NOT run the full validate.sh yourself (it can create files that trip containment and discard your whole turn); the harness runs the gate after your turn.",
  "lanes": {
    "orchestrator_only": ["relay-automation/relay-loop.sh", "relay-automation/poll.sh"],
    "note": "supervisor zone — serialize; one kernel lane per wave. relay-turn-lib.sh / bin/tick are OUT of scope (containment must stay byte-identical)."
  }
}
```

## Phase 3 — Background-Bash turn dispatch ✅ (shipped 2026-06-28)

- [x] Document/support running a turn shim (`codex-turn.sh` / `agy-turn.sh` / the Claude turn) as a **background** process so the session is freed during the turn and the harness re-invokes on completion (no polling for harness-tracked work). → `relay-loop.sh --background` (nohup-detached launch; `poll.sh` left a pure oracle via `--dry-run`).
- [x] Verify the turn shim's safety boundary (path-allowlist, commit-bypass guard, no-push, worktree isolation) holds identically when launched in the background. → **inherited by construction** (backgrounding via `&` changes only when the parent returns, not the child's code path); asserted by the fg/bg execution-parity test + the kernel's own containment tests (`test/relay-target-root-newfile.sh`).
- [x] On completion, the resuming session reads `STATUS:` / token state and decides hand-off vs stop. → stale pidfile cleared on the next tick, which then acts on the fresh `poll.sh` decision (stop/idle/handoff).

### QA checklist — Phase 3

- [x] A backgrounded turn enforces the same containment as a foreground turn (off-allowlist edit reverted, no push). → same runner path; parity test green.
- [x] Session is not blocked for the turn's duration; completion re-invokes the model. → `--background` returns immediately after launch (test: returns before the runner's `sleep` finishes); the scheduler re-invokes on the next tick.
- [x] No double-dispatch: the token/lock prevents a second turn firing while one runs. → pidfile lock → `BG-RUNNING` (test: runner ran exactly once across two ticks).
- [x] `validate.sh` green; `test/relay-loop.sh` 11/11.

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
