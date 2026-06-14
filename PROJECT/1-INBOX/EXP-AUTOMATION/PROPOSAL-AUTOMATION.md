---
title: Automated Relay — tick-backed, self-healing review loop
status: Proposal — not started
owner: Noel / Neochrome
created: 2026-06-14
repo: Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm
type: project-plan
depends_on:
  - tick runtime (bin/tick, src/*.js — claim/lock/ping/analyze/reap/release)
  - skill/xyz/SKILL.md (use-cases A build, B recon)
related:
  - /relay skill (the portable, dependency-free protocol — stays standalone)
  - docs/relay-history/ (Run 3 plan, results, and skill-review relays)
layering_principle: >-
  The portable relay PROTOCOL stays a zero-dependency, tool-agnostic skill.
  This project builds the OPTIONAL automation ENGINE that depends on tick, and
  it lives in THIS repo. The dependency arrow points one way: automation → tick.
---

# Automated Relay (tick-backed)

Turn the manual, human-nudged relay into a **self-healing, hands-free** review
loop by reusing the `tick` coordination primitives — without breaking the plain
relay protocol, which stays dependency-free.

| Most recently completed phase | What's next |
|---|---|
| — _(none — proposal drafted, not started)_ | **Phase 0 — Design spike & seam map** |

---

## Table of Contents
- [Scope & non-goals](#scope--non-goals)
- [Core idea: the turn-as-token](#core-idea-the-turn-as-token)
- [Phase 0 — Design spike & seam map](#phase-0--design-spike--seam-map)
- [Phase 1 — Turn-token core (alternation + mutual exclusion)](#phase-1--turn-token-core-alternation--mutual-exclusion)
- [Phase 2 — Liveness & self-healing](#phase-2--liveness--self-healing)
- [Phase 3 — Termination & verdict gating](#phase-3--termination--verdict-gating)
- [Phase 4 — Hands-free poll integration](#phase-4--hands-free-poll-integration)
- [Phase 5 — Package, validate, meta-exercise](#phase-5--package-validate-meta-exercise)
- [Project definition of done](#project-definition-of-done)

---

## Scope & non-goals

**In scope:** a `relay-automation` module + runner in this repo, exposed as
**Use-case C** in `skill/xyz/SKILL.md`, that uses `tick`'s lock, `release --to`,
`ping`, `analyze`, and `reap` to run a two-role (Producer/Reviewer) relay with
enforced turn-taking and automatic stall recovery.

**Non-goals (explicit anti-scope):**
- Do **not** add a `tick` dependency to the portable `/relay` skill — it must keep working with zero install and any tool (Codex/Gemini/Claude).
- Do **not** invent cross-process *push* wakeup — `tick` is poll-based; we harden the existing `/loop` poll, we do not replace it.
- Do **not** have `tick` judge the verdict — "Approved" is the LLM's call, read from the turn text by the runner.
- Do **not** generalize beyond 2 roles / same-session / shared working tree (carry the `xyz` limits forward).

---

## Core idea: the turn-as-token

Model the relay's `NEXT:` pointer as **one claimable `tick` task, `RELAY-TURN`**:

| Relay concept | tick mechanism |
|---|---|
| It's role X's turn | `RELAY-TURN` claimed by X (lock-enforced; out-of-turn action refused) |
| Hand off to the other role | `tick release RELAY-TURN --to <other>` (re-opens, routes via handoff) |
| Turn in progress / alive | `tick ping RELAY-TURN` heartbeats |
| Turn-holder stalled/dead | `tick analyze` parked-claim flag → `tick reap` |
| Approved → end | `tick done RELAY-TURN` |
| Escalated → end | `tick break RELAY-TURN` |

`tick` supplies the mutex, alternation, liveness, and audit. A thin **runner**
supplies the parts `tick` cannot: poll-wakeup, the clean-tree gate, the verdict
grep, and the round cap. Honest split: `tick` covers ~60–70% of the mechanical
glue; the runner + the LLM cover wakeup and the verdict.

---

## Phase 0 — Design spike & seam map

**Goal:** lock the design before code; prove the model needs minimal/zero `tick`-core change.

- [ ] Document the `RELAY-TURN` token model (claim = act, `release --to` = handoff, `done`/`break` = terminal) in a `SEAM-MAP.md`
- [ ] Produce the full relay-rule → tick-primitive-or-runner mapping table (every `/relay` ground rule placed in exactly one layer)
- [ ] Classify each behavior: **pure reuse** vs **runner-only** vs **needs tick-core change** (target: zero core change)
- [ ] Define the runner's responsibilities explicitly: poll-wakeup, `git status --porcelain` clean-tree gate, verdict grep, round-counter/cap
- [ ] Confirm placement: module at `relay/` + Use-case C in `skill/xyz/SKILL.md`; portable `/relay` skill stays untouched
- [ ] Write the rollback rule: the manual relay must run **unchanged** if the automation is removed

### QA checklist — Phase 0
- [ ] **DRY:** no behavior assigned to two layers in the mapping table
- [ ] **Observability:** seam map names, for every failure mode, which layer detects it
- [ ] **Anti-goals stated:** doc explicitly lists what the automation will NOT do (push-wakeup, verdict-judging, >2 roles)
- [ ] **Litmus:** a reader can point at any `/relay` ground rule and say "tick" or "runner" with no ambiguity
- [ ] **Reversibility:** the rollback-to-manual path is written and credible
- [ ] **Remote deploy needed?** No — design artifact only

---

## Phase 1 — Turn-token core (alternation + mutual exclusion)

**Goal:** two roles strictly alternate, and acting out of turn is *impossible*, not honor-system.

- [ ] `relay-init <slug>` scaffolds the relay `.md` AND seeds `RELAY-TURN` (handoff_to = producer)
- [ ] Manual two-window dry run: Producer → `release --to reviewer` → Reviewer claims → `release --to producer`, ≥2 round-trips
- [ ] Out-of-turn action is refused by `tick`'s lock/ownership (observable: non-holder window gets a rejection and writes no event)
- [ ] Alternation enforced by targeted handoff (a wrong-role window cannot claim `RELAY-TURN`)
- [ ] If any `tick`-core change was required, it ships with tests and `validate.sh` stays green (≥ 12/12)

### QA checklist — Phase 1
- [ ] **DRY:** runner wraps `tick` verbs; no reimplementation of claim/lock logic
- [ ] **SOLID:** runner depends on the `tick` CLI interface, not its internals
- [ ] **Observability:** every turn transition emits a `tick` event (claim/release) — fully reconstructable from `.tick/events/`
- [ ] **Litmus:** a deliberately misbehaving window cannot take a turn it does not hold (honor-system assumption killed)
- [ ] **Anti-goal guard:** no `tick` dependency leaked into the portable `/relay` skill
- [ ] **Remote deploy needed?** No — local shared tree

---

## Phase 2 — Liveness & self-healing

**Goal:** the highest-value slice — a dead or stalled turn is detected and recovered, not silently hung.

- [ ] Agent emits `tick ping RELAY-TURN` while a turn is in progress (cadence documented in the agent prompt)
- [ ] Watchdog loop runs `tick analyze` and flags a turn with no heartbeat > threshold as parked
- [ ] Watchdog auto-`reap`s a stalled turn and either reassigns (handoff back) or escalates to the human
- [ ] Demo: kill a mid-turn window → watchdog detects + recovers within the threshold (captured in a log)
- [ ] New tests cover parked-turn detection, reap-and-reassign, and the "healthy turn is never reaped" case

### QA checklist — Phase 2
- [ ] **DRY:** reuses `analyze`'s existing parked-claim detector — no second liveness implementation
- [ ] **SOLID:** watchdog is a separate concern from the turn-runner (single responsibility)
- [ ] **Observability:** every reap/escalation logs the reason and the gap that triggered it
- [ ] **Litmus (false-positive guard):** a slow-but-pinging turn is NOT reaped; only a heartbeat-silent one is
- [ ] **Anti-goal guard:** watchdog escalates to a human rather than fabricating progress (honors "operational contract, not inference")
- [ ] **Remote deploy needed?** No

---

## Phase 3 — Termination & verdict gating

**Goal:** the loop ends correctly — clean on Approved, escalated at the cap, never with a dirty tree.

- [ ] Runner greps the latest turn block for the verdict; `Approved` → `tick done RELAY-TURN` → loop stops
- [ ] Round cap reached without Approved → `tick break RELAY-TURN` + `STATUS: Escalated`, hand back to human
- [ ] Clean-tree gate: handoff refused if `git status --porcelain` is non-empty (commit-before-handoff enforced)
- [ ] Observable: a P→R→…→Approved run terminates cleanly; an over-cap run escalates; a dirty-tree handoff is blocked

### QA checklist — Phase 3
- [ ] **DRY:** one verdict-parsing function, one termination path (Approved/Escalated converge on a single "stop")
- [ ] **Observability:** the terminal event records WHY it ended (approved vs cap vs error)
- [ ] **Litmus:** an uncommitted change provably blocks the handoff (rule 9 enforced by code, not honor)
- [ ] **Anti-goal guard:** runner never marks `done` on its own opinion — only on an LLM-written `Approved`
- [ ] **Edge cases:** max-round-exactly, Approved-on-first-round, and dirty-tree-at-cap all handled
- [ ] **Remote deploy needed?** No

---

## Phase 4 — Hands-free poll integration

**Goal:** two windows complete a relay with zero human nudges, degrading gracefully for non-Claude tools.

- [ ] Per-window `/loop` guard rewritten to "I hold `RELAY-TURN` (per `tick info`) AND tree clean" — replaces honor-system `NEXT` + manual tree check
- [ ] End-to-end: two Claude windows finish a full automated relay with no human "your turn"
- [ ] Graceful degradation: a non-Claude window (e.g. Codex) can still take turns via the file + manual nudge (automation is additive, not required)
- [ ] Poll interval documented with the cache-warmth tradeoff (≈ 60s default; the lock/heartbeat is the real correctness guard, not the timer)

### QA checklist — Phase 4
- [ ] **DRY:** the guard reuses `tick info`/`analyze` state — no parallel "whose turn" bookkeeping
- [ ] **SOLID:** poll guard, turn-runner, and watchdog remain separable
- [ ] **Observability:** each poll tick logs its decision (acted / not-my-turn / tree-dirty / stop)
- [ ] **Litmus (race):** two windows polling simultaneously never both act — the lock serializes (verify by hammering)
- [ ] **Anti-goal guard:** the manual relay path still works with automation disabled; no hard tick dependency added to the protocol
- [ ] **Remote deploy needed?** No — same-session, shared tree (a remote/async variant is explicitly out of scope)

---

## Phase 5 — Package, validate, meta-exercise

**Goal:** ship it inside the skill, prove the extract still works, and (optionally) build it WITH the swarm.

- [ ] Add **Use-case C — automated relay** to `skill/xyz/SKILL.md` with the runner + watchdog embedded in the self-extracting block
- [ ] `validate.sh` green including new relay-automation tests; full two-block self-extract re-verified (runtime + tests → all pass)
- [ ] Run a real automated relay on a live artifact; capture metrics (rounds, time/turn, auto-recovered stalls)
- [ ] _(Optional)_ **Run 4 meta-exercise:** use `xyz` to build/extend this layer concurrently (recon → lane-split → build); record results in `REAL-AGENT-OBSERVATIONS.md`
- [ ] Update `RECAP.md` + docs with honest limits (wakeup still poll-based; verdict = LLM judgment; ≤ 2 roles)

### QA checklist — Phase 5
- [ ] **DRY:** Use-case C reuses the §4/§4b extract pattern; no third bespoke install mechanism
- [ ] **Observability:** a single `tick analyze` (or runner status) shows the live relay state at a glance
- [ ] **Litmus:** a fresh clone extracts the SKILL.md and runs an automated relay end-to-end with no extra setup
- [ ] **Anti-goals re-checked:** no push-wakeup invented, no verdict-judging, protocol still dependency-free
- [ ] **Honesty:** the limits section states what is NOT solved, in the style of the Run 1–3 caveats
- [ ] **Remote deploy needed?** No — but document the remote/async variant as future work, not done

---

## Project definition of done

Two Claude windows complete a Producer/Reviewer relay **with zero human nudges**;
a turn that stalls is **auto-detected and recovered or escalated** (never a silent
hang); the loop **ends cleanly on Approved or escalates at the cap with a clean
tree**; it ships as **Use-case C** in a self-extracting `SKILL.md` that still
passes `validate.sh`; and the **portable `/relay` protocol remains untouched and
dependency-free**.
