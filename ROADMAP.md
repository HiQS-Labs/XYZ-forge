---
title: "ROADMAP — from mechanically proven to commercially viable"
date: "2026-06-15"
status: "Active"
description: "Tracks the transition from a mechanically proven happy-path relay stack to an adversarially proven, commercially viable system."
---

The `tick` + relay-automation stack is **mechanically proven** (happy-path coordination, 21/21
validate, live Codex + Gemini headless turns behind one safety boundary). Commercial viability needs
a different bar: **adversarial proof under failure**, with reproducible logs a buyer (or an auditor)
can replay. This roadmap tracks that gap.

Maturity ladder: **1. Mechanically proven** ✅ → **2. Adversarially proven** ⬅ *this roadmap* →
**3. Commercially viable** (adversarial proof + packaging + SLA/observability + reference deploy).

Each phase item carries a `>` rationale block — the **Threat**, what a log must **Prove**, the
**Test/artifact** it emits, the mechanism it **Leans on**, and honest **Status**
(✅ proven · ⚠️ partial/unproven · ❌ missing mechanism).

| Most recently completed phase | What's next |
| :--- | :--- |
| **Mechanically Proven:** Happy path works, 21/21 validate, Phase 2 liveness, live Codex + Gemini headless turns behind one safety boundary. | **Adversarially Proven:** Survives kill/dup/stale/race with repeatable evidence. Implementation of epoch fencing and the chaos test suite. |

## Table of Contents
- [Phase 1: Epoch Fencing & Stale-Writer Prevention (R1 + G3)](#phase-1-epoch-fencing--stale-writer-prevention-r1--g3)
- [Phase 2: Chaos Suite & Auto-Recovery (G1, G2, G4, R2, R5)](#phase-2-chaos-suite--auto-recovery-g1-g2-g4-r2-r5)
- [Phase 3: Cross-Repo E2E & Multi-Device Sync (G5, R3)](#phase-3-cross-repo-e2e--multi-device-sync-g5-r3)
- [Phase 4: Observability & Reference Deploy (R4)](#phase-4-observability--reference-deploy-r4)

---

## Phase 1: Epoch Fencing & Stale-Writer Prevention (R1 + G3)

The most critical commercial-hardening gap: once ownership of a token moves on, the previous owner
must not be able to write, commit, or advance the relay.

> **G3 — Stale-writer fencing (the keystone).**
> **Threat:** agent X is presumed dead and the token is taken over (reap → reclaim by Y); then X
> *revives* and issues `done`/`release`/edit — a zombie advances or corrupts the relay after losing it.
> **Prove:** once ownership moves on, the stale epoch **cannot write/commit/advance** — its events are
> *fenced (rejected)* by the kernel, not merely ignored by convention.
> **Test/artifact:** `test/chaos-stale-writer.sh` → rejected-event log showing the fence firing.
> **Leans on:** ownership enforcement (only the claimer can mutate) — **but that is not epoch fencing.**
> Today's `tick` has no monotonic fencing token, so a revived X with the same agent id still passes
> ownership checks after takeover.
> **Status:** ❌ **Missing mechanism** — the difference between "soft coordination" and "a kernel you
> can trust unattended." This is why R1 is sequenced first.

- [ ] **R1: Implement monotonic epoch fencing tokens.**
  - [ ] Update event schema to include an `epoch` field on claim events.
  - [ ] Modify `tick` projection kernel to track the current owner's epoch.
  - [ ] Add validation logic to reject mutating events (done/release/edit) if the event's epoch is older than the current owner's epoch.
- [ ] **G3: Build `test/chaos-stale-writer.sh`.**
  - [ ] Script claim as agent X, then force reap+reclaim as Y (new epoch).
  - [ ] Script replay of X's `done`/`release`/scope events.
  - [ ] Assert that every stale event is rejected and the relay state remains unchanged.

### QA Checklist
- [ ] `test/chaos-stale-writer.sh` executes successfully and emits a rejected-event log showing the fence firing.
- [ ] Run `tick validate` and ensure all 21 core tests still pass (no regressions from epoch addition).
- [ ] Document the schema change in a decision record.

---

## Phase 2: Chaos Suite & Auto-Recovery (G1, G2, G4, R2, R5)

Package the deliberate failure scenarios and operationalize the watchdog's auto-recovery.

> **G1 — Mid-turn termination.**
> **Threat:** an agent dies *after* `claim` but *before* `release`/`done` — the token is held by a
> corpse and the relay stalls forever.
> **Prove:** the watchdog **detects** the stall within a bounded time and either **recovers** (reap →
> re-offer to a live agent, exactly once) or **safely halts** with a structured escalation — never
> silently hangs, never double-assigns.
> **Test/artifact:** `test/chaos-midturn-kill.sh` → watchdog JSON escalation + before/after token state.
> **Leans on:** `watchdog.sh` (`tick analyze --format json` → `parked_suspects[]`), `relay-drive.sh`
> no-progress escalation, `tick ping` heartbeats.
> **Status:** ⚠️ *Partial* — detection is unit-tested; the recovery half (auto-reap) is a stub behind
> `--allow-reap` (see R2). No deliberate kill-mid-turn chaos log yet.

> **G2 — Duplicate / ambiguous turn token.**
> **Threat:** two claims/ownership events for one token (race, replay, or a duplicated event file) →
> ambiguous "whose turn," double-execution.
> **Prove:** the projection kernel **deterministically resolves to exactly one owner** (or quarantines
> the token) — identical result on every replay, regardless of arrival order.
> **Test/artifact:** `test/chaos-dup-token.sh` → projection output across N replays (must be identical).
> **Leans on:** disjoint-files-per-event log, single-pass projection + deterministic tie-breaker
> (earliest ts, then lex agent id), the handoff-exclusive rule.
> **Status:** ⚠️ *Partial* — tie-breaker + handoff-exclusivity are tested; adversarial
> duplicate-injection + quarantine is not a standalone proof yet.

> **G4 — Concurrent pollers.**
> **Threat:** two eligible poller loops (two windows, or window + cron) both see "my turn / parked"
> and both act → double turn, double escalation, double commit.
> **Prove:** under a genuine race, **exactly one poller acts**; the others observe the state change
> and stand down.
> **Test/artifact:** `test/chaos-concurrent-pollers.sh` → per-poller decision log over N trials
> (must be 1-acts every time).
> **Leans on:** the lock/heartbeat as the real guard (not the timer), `--watchdog-authority` (exactly
> one authority), the token as the mutex.
> **Status:** ⚠️ *Partial / by-design but unproven* — no race-hammer test drives two pollers
> concurrently and counts winners yet.

> **R2 — Auto-reap authority.** Unblocks G1's recovery half: decide who may reap and on what evidence,
> record it, and flip `watchdog.sh --allow-reap` from stub to real.
> **R5 — Resource / quota limits** *(Gemini review 2026-06-15).* Cap per-turn wall-clock, disk, and
> API spend in the turn-taker shim so a headless agent can't run away; pairs with the `relay-drive.sh`
> round-cap. **Status:** ❌ not started (per-turn ceilings missing).

- [ ] **R2: Implement Auto-reap authority decision.**
  - [ ] Formally define who may reap and under what evidence. Record this in a decision markdown.
  - [ ] Flip `watchdog.sh --allow-reap` from a stub to real functionality.
- [ ] **G1: Build `test/chaos-midturn-kill.sh`.**
  - [ ] Script token claim as agent X, then `kill -9` the agent.
  - [ ] Run `watchdog.sh` and assert it flags `parked_suspects[X]`.
  - [ ] Assert the script emits the structured JSON escalation record.
  - [ ] Assert the auto-reap recovery path re-offers the token to a live agent exactly once.
- [ ] **G2: Build `test/chaos-dup-token.sh`.**
  - [ ] Inject concurrent/duplicate claims for the same token.
  - [ ] Assert the projection kernel resolves to exactly one stable winner via the deterministic tie-breaker across N replays.
  - [ ] Inject malformed/duplicate event files and assert they are safely quarantined without crashing the projection.
- [ ] **G4: Build `test/chaos-concurrent-pollers.sh`.**
  - [ ] Launch two concurrent `poll.sh` invocations against the same relay state.
  - [ ] Assert exactly one poller dispatches (acts) while the other safely idles across N trials.
- [ ] **R5: Resource / quota limits** (runaway-agent containment; *Gemini review 2026-06-15*).
  - [ ] Cap per-turn wall-clock, disk usage, and API spend in the turn-taker shim.
  - [ ] Pairs with the existing `relay-drive.sh` round-cap; the missing piece is per-turn time/spend ceilings.

### QA Checklist
- [ ] `test/chaos-midturn-kill.sh` passes and artifacts show correct watchdog JSON and token recovery state.
- [ ] `test/chaos-dup-token.sh` passes and artifacts show identical projection outputs across all replays.
- [ ] `test/chaos-concurrent-pollers.sh` passes and logs prove exactly one actor per trial.
- [ ] `watchdog.sh` successfully reaps and re-offers tokens without manual intervention.

---

## Phase 3: Cross-Repo E2E & Multi-Device Sync (G5, R3)

Prove the protocol generalizes beyond the home repository and supports true multi-device coordination.

> **G5 — Cross-repo / cross-model diversity.**
> **Threat:** the protocol is secretly coupled to *this* repo or to all-Claude/manual flows — it won't
> generalize, so it has no product surface.
> **Prove:** the same protocol runs in a **different repository** (zero-setup from the packaged skill)
> **and** with **heterogeneous agents** taking real turns (not just Claude, not just manual nudge).
> **Test/artifact:** `test/e2e-fresh-repo.sh` → transcript + commit graph from a foreign repo.
> **Leans on:** the packaged sibling skill (`relay-pkg.tar.gz`, `QUICKSTART.md`), `codex-turn.sh` +
> `gemini-turn.sh` over the shared core.
> **Status:** ⚠️ *Partial* — cross-**model** is live-proven (Codex + Gemini headless turns) and the
> MBP16 field report drove a real cross-**repo** run; but there's no zero-setup fresh-clone E2E
> proving no home-repo coupling, and `.tick/` is still per-device-local.
> **R3 — Cross-machine `.tick/` sync:** an out-of-band ref or daemon so machines share coordination state.

- [ ] **R3: Implement cross-machine `.tick/` sync.**
  - [ ] Build or document an out-of-band sync mechanism (e.g., git-based or daemon) so multiple machines share the `.tick/` directory securely.
- [ ] **G5: Build `test/e2e-fresh-repo.sh`.**
  - [ ] Create an automated test or CI job that instantiates a throwaway repository.
  - [ ] Install the skill via `relay-pkg.tar.gz`.
  - [ ] Run a complete Producer↔Reviewer relay to `Approved` using headless agents.
  - [ ] Assert there are no hardcoded dependencies on the home repository.
- [ ] **G5: Cross-model demonstration.**
  - [ ] Execute and record a multi-agent run combining Codex and Gemini headless turns in a single thread.

### QA Checklist
- [ ] `test/e2e-fresh-repo.sh` succeeds with zero manual setup in the throwaway repository.
- [ ] The generated transcript and commit graph from the fresh repo are verified.
- [ ] Cross-machine sync is successfully demonstrated without state conflicts or dropped events.

---

## Phase 4: Observability & Reference Deploy (R4)

The final mile to commercial viability: the system is auditable and deployable with SLA-backing.

> **R4 — Observability surface** (commercial table-stakes). Structured, timestamped logs for every
> claim / handoff / reject / escalation that a buyer can ship to their SIEM.
> **Prove:** every coordination event emits a parseable, timestamped record with agent id + epoch.
> **Status:** ❌ not started (logs today are human-readable, not structured for ingestion).

- [ ] **R4: Build Observability surface.**
  - [ ] Instrument `tick` and the relay stack to emit structured, timestamped logs (JSON) for every claim, handoff, rejection, and escalation.
  - [ ] Ensure logs are formatted for easy ingestion by a SIEM.
- [ ] **Create Reference Deploy documentation.**
  - [ ] Write a comprehensive guide on deploying the stack with SLA and observability guarantees in a commercial context.

### QA Checklist
- [ ] All required events (claim, handoff, reject, escalate) reliably emit structured JSON logs.
- [ ] Log artifacts contain accurate timestamps, epochs, and agent IDs.
- [ ] The Reference Deploy documentation can be followed by an independent auditor to successfully stand up the environment.

---

*Created 2026-06-15 (merged from the flat gap-analysis + the phased/QA structure after a concurrent
edit). Gaps map to the backlog in `4X4.md`; mechanisms that change the event schema get a decision
record before they land.*
