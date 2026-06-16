title: "ROADMAP — from mechanically proven to commercially viable"
date: "2026-06-15"
status: "Active"
description: "Tracks the transition from a mechanically proven happy-path relay stack to an adversarially proven, commercially viable system."
---

| Most recently completed phase | What's next |
| :--- | :--- |
| **Mechanically Proven:** Happy path works, 21/21 validate, Phase 2 liveness, live Codex + Gemini headless turns behind one safety boundary. | **Adversarially Proven:** Survives kill/dup/stale/race with repeatable evidence. Implementation of epoch fencing and the chaos test suite. |

## Table of Contents
- [Phase 1: Epoch Fencing & Stale-Writer Prevention (R1 + G3)](#phase-1-epoch-fencing--stale-writer-prevention-r1--g3)
- [Phase 2: Chaos Suite & Auto-Recovery (G1, G2, G4, R2)](#phase-2-chaos-suite--auto-recovery-g1-g2-g4-r2)
- [Phase 3: Cross-Repo E2E & Multi-Device Sync (G5, R3)](#phase-3-cross-repo-e2e--multi-device-sync-g5-r3)
- [Phase 4: Observability & Reference Deploy (R4)](#phase-4-observability--reference-deploy-r4)

---

## Phase 1: Epoch Fencing & Stale-Writer Prevention (R1 + G3)

This phase addresses the most critical commercial-hardening gap: ensuring that once ownership of a token moves on, the previous owner cannot write, commit, or advance the relay.

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

## Phase 2: Chaos Suite & Auto-Recovery (G1, G2, G4, R2)

This phase packages the deliberate failure scenarios and operationalizes the auto-recovery mechanisms for the watchdog.

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

This phase proves the protocol generalizes beyond the home repository and supports true multi-device coordination.

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

The final mile to commercial viability involves ensuring the system is auditable and deployable with SLA-backing.

- [ ] **R4: Build Observability surface.**
  - [ ] Instrument `tick` and the relay stack to emit structured, timestamped logs (JSON) for every claim, handoff, rejection, and escalation.
  - [ ] Ensure logs are formatted for easy ingestion by a SIEM.
- [ ] **Create Reference Deploy documentation.**
  - [ ] Write a comprehensive guide on deploying the stack with SLA and observability guarantees in a commercial context.

### QA Checklist
- [ ] All required events (claim, handoff, reject, escalate) reliably emit structured JSON logs.
- [ ] Log artifacts contain accurate timestamps, epochs, and agent IDs.
- [ ] The Reference Deploy documentation can be followed by an independent auditor to successfully stand up the environment.