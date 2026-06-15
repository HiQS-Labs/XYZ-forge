---
title: Automated Relay — tick-backed, self-healing review loop
status: ✅ Phases 1–5 SHIPPED (2026-06-15) — relay-automation packaged as a sibling skill (`skill/relay-automation/`), validate 20/20. Tick-native relay turns (a), self-healing watchdog, hands-free poll, self-expiring loops, and cross-model (Claude↔Codex) + Option-A headless turns all live-proven. Phase-4 QA 10/12 (open: race hammer-test; two-window E2E proven via the dogfood). Project DoD met. See CHANGELOG.md + relay-automation/{README,CROSSMODEL-OPTIONA-PLAN}.md.
owner: Noel / Neochrome
created: 2026-06-14
repo: Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm
type: project-plan
depends_on:
  - tick runtime (bin/tick, src/*.js — claim/lock/ping/analyze/reap/release)
related:
  - /relay skill (the portable, dependency-free protocol — stays standalone)
  - docs/relay-history/ (Run 3 plan, results, and skill-review relays)
  - skill/xyz/SKILL.md (§4/§4b self-extract pattern; sibling reference only)
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

**In scope:** a **sibling** `relay-automation` module + runner + skill in this
repo (a separate artifact *powered by* `tick` — **not** a use-case of the
parallel-swarm `xyz` skill, whose charter is partitionable lanes and explicitly
*excludes* tightly-coupled back-and-forth handoff; see `skill/xyz/SKILL.md` §2a).
It runs a two-role (Producer/Reviewer) relay with **enforced** turn-taking and
**automatic** stall recovery.

> **Current vs target — read this first.** Today `tick` only *prioritizes*
> `handoff_to` (it does **not** exclude other claimers: `src/take.js` falls
> through to `candidates[0]`, and `src/claim.js` has no handoff check) and only
> *reports* parked claims (`src/analyze.js`); `reap` is a **manual** coordinator
> lever (`src/scope.js`). So "enforced turn-taking" and "auto-recovery" are
> **target behaviors this project adds** (a small `tick` core change in Phase 1 +
> a watchdog policy in Phase 2) — not capabilities to be claimed as already
> present. The body below marks every mapping row as **today** or **adds**.

**Non-goals (explicit anti-scope):**
- Do **not** add a `tick` dependency to the portable `/relay` skill — it must keep working with zero install and any tool (Codex/Gemini/Claude).
- Do **not** silently broaden the `xyz` parallel-swarm charter — this ships as a sibling, not a smuggled-in use-case.
- Do **not** invent cross-process *push* wakeup — `tick` is poll-based; we harden the existing `/loop` poll, we do not replace it.
- Do **not** have `tick` judge the verdict — "Approved" is the LLM's call, read from the turn text by the runner.
- Do **not** generalize beyond 2 roles / same-session / shared working tree (carry the `xyz` limits forward).

---

## Core idea: the turn-as-token

Model the relay's `NEXT:` pointer as **one claimable `tick` task, `RELAY-TURN`**.
Each row is tagged **[today]** (works on current `tick`) or **[adds]** (this
project must build it):

| Relay concept | tick mechanism | Status |
|---|---|---|
| It's role X's turn | `RELAY-TURN` claimed by X; the per-clone lock makes the *claim cycle* atomic | **[today]** — but it does **not** stop a wrong role from claiming an open/handed-off token |
| Out-of-turn action refused | reject `claim`/`take` when `handoff_to` is set and ≠ agent | **[adds]** Phase 1 — small `tick` core change; today only mutating verbs are owner-guarded, the initial claim is not |
| Hand off to the other role | `tick release RELAY-TURN --to <other>` re-opens + sets `handoff_to`; `take`/`next` *prioritize* it | **[today]** routing only — exclusivity comes from the Phase 1 change |
| Turn in progress / alive | `tick ping RELAY-TURN` heartbeats | **[today]** |
| Turn-holder stalled | `tick analyze` flags a parked claim | **[today]** detection/reporting only |
| Recover a stalled turn | `tick reap` releases it → reassign or escalate | **[today]** `reap` is **manual**; **[adds]** Phase 2 — the *auto*-reap policy/authority |
| Approved → end | `tick done RELAY-TURN` | **[today]** verb; **[adds]** the runner deciding *when* (verdict grep) |
| Escalated → end | `tick break RELAY-TURN` | **[today]** verb; **[adds]** the runner's round-cap trigger |

`tick` supplies the mutex primitive, handoff *routing*, liveness *detection*, and
audit **today**; this project **adds** handoff *exclusivity* (Phase 1) and
*auto*-recovery (Phase 2). A thin **runner** supplies the parts `tick` will never
cover: poll-wakeup, the clean-tree gate, the verdict grep, and the round cap.
Honest split *after* the planned additions: `tick` ≈ the coordination substrate;
the runner + the LLM cover wakeup and the verdict.

---

## Phase 0 — Design spike & seam map

**Goal:** lock the design before code; prove the model needs minimal `tick`-core
change and name every added contract explicitly.

- [ ] Document the `RELAY-TURN` token model (claim = act, `release --to` = handoff, `done`/`break` = terminal) in a `SEAM-MAP.md`, tagging every row **[today]** vs **[adds]**
- [ ] Produce the full relay-rule → tick-primitive-or-runner mapping table (every `/relay` ground rule placed in exactly one layer)
- [ ] Classify each behavior: **pure reuse** vs **runner-only** vs **needs tick-core change**. (Confirmed: exactly **one** core change is in scope — handoff-exclusive claims, Phase 1. Flag if the spike finds others.)
- [ ] **Enforcement-contract decision (resolved):** Phase 1 adds a `tick` rule that **rejects `claim`/`take` of a task whose `handoff_to` is set and ≠ agent**. Phase 0 writes its exact acceptance criteria + the events it must (not) emit.
- [ ] **Auto-reap authority decision:** define WHO may auto-reap, the threshold, and the default action — reassign vs human-escalate (today `reap` is manual; this names the policy that makes it automatic). Detection ≠ permission to act.
- [ ] **Charter decision (resolved):** ship as a **sibling** `relay/` module + its own skill, **not** Use-case C of `xyz` (whose §2a excludes tightly-coupled handoff). Portable `/relay` skill stays untouched.
- [ ] **Clean-tree gate scope decision:** is the gate repo-global or artifact-scoped? (Resolved target: **artifact-scoped** — name the exact command in Phase 3, e.g. `git status --porcelain -- <artifact> <relay-log>`, so unrelated repo dirt can't block a handoff.)
- [ ] **Runtime-generation preflight note:** state that this plan targets the **shared-tree, local-event `.tick/events/` runtime** (post-git-transport) — readers must not import stale README/`CLAUDE.md` transport assumptions.
- [ ] Define the runner's responsibilities explicitly: poll-wakeup, the (artifact-scoped) clean-tree gate, verdict grep, round-counter/cap
- [ ] Write the rollback rule: the manual relay must run **unchanged** if the automation is removed

### QA checklist — Phase 0
- [ ] **DRY:** no behavior assigned to two layers in the mapping table
- [ ] **Honesty (current vs target):** every mapping row is tagged **[today]** or **[adds]**, cross-checked against `src/` — no current-vs-target conflation survives
- [ ] **Observability:** seam map names, for every failure mode, which layer detects it
- [ ] **Anti-goals stated:** doc explicitly lists what the automation will NOT do (push-wakeup, verdict-judging, >2 roles)
- [ ] **Litmus:** a reader can point at any `/relay` ground rule and say "tick" or "runner" with no ambiguity
- [ ] **Reversibility:** the rollback-to-manual path is written and credible
- [ ] **Remote deploy needed?** No — design artifact only

---

## Phase 1 — Turn-token core (alternation + mutual exclusion)

**Goal:** *add* the one `tick` change that makes acting out of turn impossible (not honor-system), then prove strict alternation on it.

- [ ] **`tick` core change:** `claim`/`take` **reject** a task whose `handoff_to` is set and ≠ the calling agent, writing **zero** events on rejection (today `src/claim.js` has no handoff check and `src/take.js` falls through to `candidates[0]`). Ships with new tests; `validate.sh` stays green (≥ 12/12, expect +N for the new rule)
- [ ] `relay-init <slug>` scaffolds the relay `.md` AND seeds `RELAY-TURN` (handoff_to = producer)
- [ ] Manual two-window dry run: Producer → `release --to reviewer` → Reviewer claims → `release --to producer`, ≥ 2 round-trips
- [ ] **Observable enforcement (post-change):** a wrong-role window's `claim`/`take` of `RELAY-TURN` is rejected and writes no event — verified from `.tick/events/` (turn-taking is now lock+rule-enforced, not honor-system)
- [ ] Confirm no second core change crept in — the rejection rule is the only addition to `tick`

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

Acceptance is split into three distinct gates — detection, false-positive bound, and *authority to act* (the reviewer's point: "parked is detectable" ≠ "safe to auto-reap"; today `reap` is manual):

- [ ] **(detection)** Agent emits `tick ping RELAY-TURN` while a turn is in progress (cadence in the prompt); watchdog runs `tick analyze` and flags a turn with no heartbeat > threshold as parked — reuses today's analyzer, no second detector
- [ ] **(false-positive bound)** A slow-but-pinging turn is provably **never** flagged; the threshold is justified against real turn durations, not guessed
- [ ] **(authority)** Auto-reap acts **only** per the Phase-0 authority decision (who/threshold/action); absent that approval it **escalates to a human** rather than reaping. Detection alone never triggers a release.
- [ ] Watchdog, when authorized, `reap`s a stalled turn and either reassigns (handoff back) or escalates — every action logged with the gap that triggered it
- [ ] Demo: kill a mid-turn window → watchdog detects + (recovers or escalates) within the threshold (captured in a log)
- [ ] New tests cover: detection, the "healthy/pinging turn is never reaped" false-positive case, and reap-and-reassign vs escalate

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
- [ ] **Artifact-scoped** clean-tree gate: handoff refused only if `git status --porcelain -- <artifact-path> <relay-log-path>` is non-empty — so unrelated repo dirt (e.g. an edited `README.md` elsewhere in the shared checkout) does **not** block the handoff. (Repo-global was rejected in Phase 0.)
- [ ] Observable: a P→R→…→Approved run terminates cleanly; an over-cap run escalates; an *artifact*-dirty handoff is blocked while unrelated dirt is allowed

### QA checklist — Phase 3
- [ ] **DRY:** one verdict-parsing function, one termination path (Approved/Escalated converge on a single "stop")
- [ ] **Observability:** the terminal event records WHY it ended (approved vs cap vs error)
- [ ] **Litmus:** an uncommitted change *to the artifact or relay log* provably blocks the handoff, while unrelated repo dirt does not (rule 9 enforced by code, artifact-scoped, not honor)
- [ ] **Anti-goal guard:** runner never marks `done` on its own opinion — only on an LLM-written `Approved`
- [ ] **Edge cases:** max-round-exactly, Approved-on-first-round, and dirty-tree-at-cap all handled
- [ ] **Remote deploy needed?** No

---

## Phase 4 — Hands-free poll integration

**Goal:** two windows complete a relay with zero human nudges, degrading gracefully for non-Claude tools.

- [x] Per-window `/loop` guard keyed on **claimability-for-me**, not current ownership (a handed-off turn is an *open* task routed via `handoff_to`, which the next actor does **not** yet hold — guarding on "I hold it" would deadlock). Exact guard: from `tick info RELAY-TURN`, with the artifact-scoped tree clean —
  - `status: open` **and** `handoff-to: <me>` → **claim it, then take the turn**
  - `status: claimed` **and** `claimer: <me>` → **resume/take the turn** (re-entrant)
  - otherwise → **do nothing, keep polling**
  - *DONE via (a) 2026-06-15: relay poll guard is now `tick info RELAY-TURN` claimability (`poll.sh` `tick_my_turn`, shared with xyz mode); the file's `STATUS` is read only as the terminal signal. Tested in `test/poll-driver.sh` (wake-on-handoff + claimed-by-me).*
- [ ] End-to-end: two Claude windows finish a full automated relay with no human "your turn" — including the wake-on-handoff step (the waiting side claims the open, routed token rather than waiting to already own it) — *PENDING: mechanism built + unit-tested (relay-drive.sh, poll-relay.sh 8/8) but not yet run live with two real Claude windows*
- [x] Graceful degradation: a non-Claude window (e.g. Codex) can still take turns via the file + manual nudge (automation is additive, not required) — *embedded `▶ TAKE YOUR TURN` block + poll.sh cross-model nudge; exercised live with Codex this week*
- [x] **Operating-model note (documented limit):** hands-free poll is an **all-Claude convenience** — it relies on Claude Code's in-session `/loop` guarded polling. It is **not** a generic "any editor agent self-wakes" capability and **not** a durable scheduler. Non-Claude participants (Codex/Gemini) stay on **manual nudge**. For reliable, unattended recurring checks, polling must move into a **real runner/watchdog process/service**, not the agent session.
- [x] Poll interval documented with the cache-warmth tradeoff (≈ 60s default; the lock/heartbeat is the real correctness guard, not the timer) — *DONE: `relay-automation/README.md` "Poll interval — cache-warmth tradeoff" (60s warm-cache, lock-is-the-guard, longer = latency-only).*

### QA checklist — Phase 4
- [x] **DRY:** the guard reuses `tick info`/`analyze` state — no parallel "whose turn" bookkeeping — *DONE via (a): whose-turn now comes from the `RELAY-TURN` tick task for both modes; the relay markdown holds content + the terminal `STATUS` only, not a duplicate turn-token.*
- [x] **SOLID:** poll guard, turn-runner, and watchdog remain separable — *poll.sh / runner.sh / watchdog.sh / relay-drive.sh are distinct files & concerns*
- [x] **Observability:** each poll tick logs its decision (acted / not-my-turn / tree-dirty / stop) — *poll.sh prints `DECISION: <x> (<reason>)` every tick*
- [ ] **Litmus (race):** two windows polling simultaneously never both act — the lock serializes (verify by hammering) — *now serialized by the real tick claim-lock (relay turns are tick claims after (a)); still not hammer-tested with two concurrent pollers*
- [x] **Litmus (no deadlock):** after `release --to <other>`, the routed-to window wakes and **claims the open token** — the relay never stalls with both sides waiting to "already hold" it — *DONE via (a): proven by `poll-driver.sh` (open+handoff-to-me → run-runner = wake) + `poll-relay.sh` 3-turn re-handoff; full two-live-window run still tracked by the E2E item.*
- [x] **Anti-goal guard:** the manual relay path still works with automation disabled; no hard tick dependency added to the protocol — *the portable `/relay` skill stays dependency-free; automation lives in relay-automation/*
- [x] **Remote deploy needed?** No — same-session, shared tree (a remote/async variant is explicitly out of scope)

---

## Phase 5 — Package, validate, meta-exercise

**Goal:** ship it inside the skill, prove the extract still works, and (optionally) build it WITH the swarm.

- [ ] Ship the **sibling `relay-automation` skill** (its own self-extracting `SKILL.md` under `skill/relay-automation/`) with the runner + watchdog + the Phase-1 `tick` change embedded — **not** added as a use-case of `skill/xyz/SKILL.md`
- [ ] `validate.sh` green including new relay-automation tests; full two-block self-extract re-verified (runtime + tests → all pass)
- [ ] Run a real automated relay on a live artifact; capture metrics (rounds, time/turn, auto-recovered stalls)
- [ ] _(Optional)_ **Run 4 meta-exercise:** use `xyz` to build/extend this layer concurrently (recon → lane-split → build); record results in `REAL-AGENT-OBSERVATIONS.md`
- [ ] Update `RECAP.md` + docs with honest limits (wakeup still poll-based and **all-Claude `/loop`-only** — non-Claude stays manual, durable polling needs a runner/service; verdict = LLM judgment; ≤ 2 roles)

### QA checklist — Phase 5
- [ ] **DRY:** the sibling skill reuses the §4/§4b self-extract pattern; no third bespoke install mechanism
- [ ] **Observability:** a single `tick analyze` (or runner status) shows the live relay state at a glance
- [ ] **Litmus:** a fresh clone extracts the SKILL.md and runs an automated relay end-to-end with no extra setup
- [ ] **Anti-goals re-checked:** no push-wakeup invented, no verdict-judging, protocol still dependency-free
- [ ] **Honesty:** the limits section states what is NOT solved, in the style of the Run 1–3 caveats
- [ ] **Remote deploy needed?** No — but document the remote/async variant as future work, not done

---

## Project definition of done

Two Claude windows complete a Producer/Reviewer relay **with zero human nudges**;
a turn that stalls is **auto-detected and recovered or escalated** (never a silent
hang); the loop **ends cleanly on Approved or escalates at the cap with an
artifact-scoped clean tree**; it ships as a **sibling self-extracting skill**
(`skill/relay-automation/`, powered by `tick`, **not** folded into `xyz`) that
still passes `validate.sh`; and the **portable `/relay` protocol remains
untouched and dependency-free**.
