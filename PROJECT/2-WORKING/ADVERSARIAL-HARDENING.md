---
complexity: high
risk: medium
effort: high
ratings_provisional: false
title: Adversarial hardening — commercial-viability track (Part B)
slug: adversarial-hardening
status: Active
created: 2026-06-15
updated: 2026-06-21
owner: Noel (operator) · Claude (producer)
branch: main
related:
  - decisions/2026-06-18-epoch-fencing.md       # Phase 1 canonical decision record
  - 4X4.md                                       # strategic backlog (Part B gaps)
  - PROJECT/3-COMPLETED/MARATHON-HARNESS.md      # the Part A harness this hardens
  - PROJECT/1-INBOX/LOOPS.md
non_goals:
  - Not new features — this track proves the existing tick + relay-automation stack survives failure.
  - Cross-machine .tick/ sync (R3) is scoped to Phase 3; not pulled forward.
goal: >
  Take the mechanically-proven tick + relay-automation stack to "adversarially proven → commercially
  viable": epoch fencing (done), a chaos suite + auto-recovery, cross-repo/multi-device E2E, and a
  SIEM-grade observability + reference-deploy surface. This is the canonical Part B detail ROADMAP.md
  points at.
---

# Adversarial hardening (Part B)

## Status

| What was just completed | What's next |
|---|---|
| **Phase 1 — epoch fencing & stale-writer prevention** ✅ shipped 2026-06-18 (monotonic per-task epoch in the projection kernel; `test/chaos-stale-writer.sh` 13/13; decision record `decisions/2026-06-18-epoch-fencing.md`). Phase 2 landed: G1 mid-turn-kill detection **+ R2 auto-reap recovery (2026-06-30, #52)**, G4 concurrent-pollers (20/20), R5 per-turn wall-clock cap. | **Phase 2 remainder** — G2 dup-token determinism (+ R5 disk / codex-agy spend ceilings); then Phase 3 (cross-repo E2E, R3) and Phase 4 (R4 observability + reference deploy). |

## Context — the maturity ladder

The `tick` + relay-automation stack is **mechanically proven** (happy-path coordination, 22/22
`validate.sh`, live Codex + agy headless turns behind one safety boundary). Commercial viability
needs a different bar: **adversarial proof under failure**, with reproducible logs a buyer (or an
auditor) can replay. This track closes that gap.

Maturity ladder: **1. Mechanically proven** ✅ → **2. Adversarially proven** ⬅ *this track* →
**3. Commercially viable** (adversarial proof + packaging + SLA/observability + reference deploy).

Each item carries a **Threat**, what a log must **Prove**, the **Test/artifact** it emits, the
mechanism it **Leans on**, and an honest **Status** (✅ proven · ⚠️ partial/unproven · ❌ missing
mechanism).

**Model assignment (live kernel items):** the two trust-critical pieces — **G2 dup-token determinism
(Opus)** and the already-shipped **R1 epoch-fencing kernel diff (Opus)** — are correctness proofs, not
scripts. The chaos *test harnesses*, the E2E script, and the observability/deploy work are **Sonnet
High** (mechanical once the mechanism exists). Full build-track table:
[MARATHON-HARNESS.md → Model assignment](../3-COMPLETED/MARATHON-HARNESS.md#model-assignment-build-track-guidance).

---

## Phase 1 — Epoch Fencing & Stale-Writer Prevention (R1 + G3)

**Status: ✅ Shipped 2026-06-18 — mechanism in place.** Monotonic per-task `epoch` added to the
event schema (0.1.0 → 0.2.0); the projection kernel (`src/project.js` `fold`) now fences any mutation
below the current owner's epoch — **including a same-id zombie**, the keystone the threat names.
`test/chaos-stale-writer.sh` 13/13 (keystone same-id reclaim + cross-agent takeover); fenced events
land in a deterministic `.tick/rejected.jsonl` (surfaced by `tick fences`). `validate.sh` **29/29**, no
regressions. Decision record: `decisions/2026-06-18-epoch-fencing.md`. *(Kernel diff written on Opus
per the model-assignment table; remaining Part B work reverts to Sonnet High.)* **Carried forward:**
epoch is assigned under the per-clone `withClaimLock` — cross-machine concurrent claims (R3) are out of
scope and flagged as this record's revisit trigger.

> **G3 — Stale-writer fencing (the keystone).**
> **Threat:** agent X is presumed dead and the token is taken over (reap → reclaim by Y); then X
> *revives* and issues `done`/`release`/edit — a zombie advances or corrupts the relay after losing it.
> **Prove:** once ownership moves on, the stale epoch **cannot write/commit/advance** — its events are
> *fenced (rejected)* by the kernel, not merely ignored by convention.
> **Test/artifact:** `test/chaos-stale-writer.sh` → a rejected-event log showing the fence firing.
> **Leans on:** ownership enforcement (only the claimer can mutate) — **but that is not epoch fencing.**
> Today's `tick` has no monotonic fencing token, so a revived X with the same agent id still passes
> ownership checks after takeover.
> **Status:** ❌ **Missing mechanism** — the difference between "soft coordination" and "a kernel you
> can trust unattended." This is why R1 is sequenced first. *(Resolved by the shipped R1 above.)*

### Checklist

- [x] **R1: Implement monotonic epoch fencing tokens.** ✅ 2026-06-18
  - [x] Add `epoch` field to claim events in the event schema. ✅ (`src/events.js`, schema 0.2.0; absent ⇒ epoch 0)
  - [x] Modify `tick` projection kernel to track the current owner's epoch. ✅ (`fold`: owner = highest live epoch)
  - [x] Reject mutating events (`done`/`release`/scope) whose epoch is older than the current owner's. ✅
        Plus two sub-invariants: a `released` retires a claim only at `epoch >= claim.epoch` (same-id keystone);
        a handoff is honoured only from the latest epoch (no zombie redirect).
- [x] **G3: Build `test/chaos-stale-writer.sh`.** ✅ 2026-06-18 (13/13)
  - [x] Script: claim as agent X → force reap+reclaim (new epoch) → replay X's `done`/`release`/scope events. ✅
        Keystone scenario uses a **same-id** reclaim so ownership passes and only the epoch fences.
  - [x] Assert: every stale event rejected; relay state byte-identical; owner still completes. ✅

### QA checklist

- [x] `test/chaos-stale-writer.sh` emits a rejected-event log showing the fence firing. ✅ (`.tick/rejected.jsonl`, `tick fences`; deterministic across re-projections)
- [x] `validate.sh` green with no regressions from epoch addition. ✅ **29/29** (28 prior + the new chaos test; baseline is no longer 22).
- [x] Schema change documented in a decision record. ✅ `decisions/2026-06-18-epoch-fencing.md`

---

## Phase 2 — Chaos Suite & Auto-Recovery (G1, G2, G4, R2, R5)

**Status: 🔲 Not started — ⚠️ detection partial; recovery and race proofs missing**

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
> **Status:** ⚠️ *Partial — detection PROVEN 2026-06-18* (`test/chaos-midturn-kill.sh`, 8 assertions:
> orphaned claim flagged in `parked_suspects[]` past threshold + false-positive guard; `watchdog.sh`
> exits 0 with exactly one valid-JSON escalation record — never hangs). The recovery half (auto-reap)
> remains a stub behind `--allow-reap`, gated on **R2**.

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

> **R2 — Auto-reap authority.** ✅ **shipped 2026-06-30 (#52).** Unblocked G1's recovery half: authority =
> the explicit `--allow-reap` grant; evidence = `parked_suspects[]` membership; `watchdog.sh --allow-reap`
> now does a real scoped/idempotent/exactly-once `tick reap` re-offer (never a live claim). Decision
> record: `decisions/2026-06-30-auto-reap-authority.md`.
> **R5 — Resource / quota limits** *(Gemini review 2026-06-15).* Cap per-turn wall-clock, disk, and
> API spend in the turn-taker shim so a headless agent can't run away; pairs with the `relay-drive.sh`
> round-cap. **Status:** ❌ not started (per-turn ceilings missing).

### Checklist

- [x] **R2: Auto-reap authority decision.** ✅ shipped 2026-06-30 (#52)
  - [x] Formally define who may reap and on what evidence; recorded in [`decisions/2026-06-30-auto-reap-authority.md`](../../decisions/2026-06-30-auto-reap-authority.md) — authority = the explicit `--allow-reap` grant; evidence = `parked_suspects[]` membership (max gap past threshold), never a live claim.
  - [x] Flip `watchdog.sh --allow-reap` from stub to real — scoped `tick reap <agent> --task <task>`, idempotent, exactly-once, best-effort (escalation stays the guarantee); the release is epoch-stamped (Phase 1).
- [x] **G1: Build `test/chaos-midturn-kill.sh`** (mid-turn termination). *(detection ✅ 2026-06-18; recovery ✅ 2026-06-30 via R2)*
  - [x] Claim as agent X → simulate death (zero heartbeats, time advanced via `TICK_TS`) → assert `parked_suspects[X]` flagged (+ false-positive guard). ✅
  - [x] Assert: structured JSON escalation emitted ✅; **auto-reap re-offers token exactly once** ✅ — `chaos-midturn-kill.sh` 15/15: real reap → release → peer reclaims → idempotent second pass → a live peer claim is never touched.
- [ ] **G2: Build `test/chaos-dup-token.sh`** (duplicate/ambiguous token).
  - [ ] Inject concurrent/duplicate claims → assert projection resolves to exactly one stable winner across N replays.
  - [ ] Inject malformed/duplicate event files → assert safely quarantined without crash.
- [x] **G4: Build `test/chaos-concurrent-pollers.sh`** (concurrent pollers). ✅ (in `validate.sh`, 20/20)
  - [x] Launch two concurrent `poll.sh` instances against the same relay state.
  - [x] Assert exactly one poller acts; the other idles — across N trials (20 trials, exactly one winner each).
- [~] **R5: Resource / quota limits** (per-turn runaway containment; Gemini 2026-06-15). *(wall-clock ✅ 2026-06-18; disk + codex/gemini spend deferred)*
  - [x] Cap per-turn **wall-clock** in the turn-taker shim. ✅ `rtl_run_bounded` (coreutils-free) in `relay-turn-lib.sh`; all 3 shims via `RELAY_TURN_TIMEOUT_S` (default 300); timeout → exit 7. Test `test/relay-turn-timeout.sh` 9/9.
  - [~] **disk** + **per-turn API spend (codex/gemini)** ceilings — deferred (claude already has `--max-budget-usd`; disk belongs in a TMPDIR watchdog). In-code `# NOTE:`s mark the gap.
  - [x] Pairs with `relay-drive.sh` round-cap (turn COUNT); wall-clock adds the per-turn TIME ceiling. ✅

### QA checklist

- [~] `test/chaos-midturn-kill.sh` passes with watchdog JSON escalation (detection ✅ 8/8); "correct recovery state" deferred to R2.
- [ ] `test/chaos-dup-token.sh` passes with identical projection outputs across all replays.
- [ ] `test/chaos-concurrent-pollers.sh` passes: exactly one actor per trial, logged.
- [ ] `watchdog.sh` reaps and re-offers tokens without manual intervention.

---

## Phase 3 — Cross-Repo E2E & Multi-Device Sync (G5, R3)

**Status: 🔲 Not started — ⚠️ cross-model live-proven; zero-setup fresh-clone E2E missing**

Prove the protocol generalizes beyond the home repository and supports true multi-device coordination.

> **G5 — Cross-repo / cross-model diversity.**
> **Threat:** the protocol is secretly coupled to *this* repo or to all-Claude/manual flows — it won't
> generalize, so it has no product surface.
> **Prove:** the same protocol runs in a **different repository** (zero-setup from the packaged skill)
> **and** with **heterogeneous agents** taking real turns (not just Claude, not just manual nudge).
> **Test/artifact:** `test/e2e-fresh-repo.sh` → transcript + commit graph from a foreign repo.
> **Leans on:** the packaged sibling skill (`relay-pkg.tar.gz`, `relay-automation/README.md`), `codex-turn.sh` +
> `agy-turn.sh` over the shared core.
> **Status:** ⚠️ *Partial* — cross-**model** is live-proven (Codex + Gemini headless turns) and the
> MBP16 field report drove a real cross-**repo** run; but there's no zero-setup fresh-clone E2E
> proving no home-repo coupling, and `.tick/` is still per-device-local.
> **R3 — Cross-machine `.tick/` sync:** an out-of-band ref or daemon so machines share coordination state.

### Checklist

- [ ] **G5: Build `test/e2e-fresh-repo.sh`.**
  - [ ] Instantiate a throwaway repository; install the skill via `relay-pkg.tar.gz`.
  - [ ] Run a complete Producer↔Reviewer relay to `Approved` using headless agents.
  - [ ] Assert no hardcoded dependencies on the home repository.
- [ ] **G5: Cross-model demonstration.**
  - [ ] Execute and record a multi-agent run combining Codex + agy headless turns in a single thread.
- [ ] **R3: Cross-machine `.tick/` sync.**
  - [ ] Build or document an out-of-band sync mechanism (git-based or daemon) so multiple machines share `.tick/` securely.

### QA checklist

- [ ] `test/e2e-fresh-repo.sh` succeeds with zero manual setup in the throwaway repo.
- [ ] Transcript + commit graph from the fresh repo verified.
- [ ] Cross-machine sync demonstrated without state conflicts or dropped events.

---

## Phase 4 — Observability & Reference Deploy (R4)

**Status: 🔲 Not started — ❌ structured logs missing**

The final mile to commercial viability: the system is auditable and deployable with SLA-backing.

> **R4 — Observability surface** (commercial table-stakes). Structured, timestamped logs for every
> claim / handoff / reject / escalation that a buyer can ship to their SIEM.
> **Threat:** logs today are human-readable, not structured for ingestion — a buyer cannot ship them
> to a SIEM. This is the final mile to commercial viability.
> **Prove:** every coordination event emits a parseable, timestamped record with agent id + epoch.
> **Status:** ❌ not started (logs today are human-readable, not structured for ingestion).

### Checklist

- [ ] **R4: Build observability surface.**
  - [ ] Instrument `tick` and relay stack to emit structured, timestamped JSON for every claim, handoff, rejection, and escalation — with agent id + epoch.
  - [ ] Format for SIEM ingestion.
- [ ] **Create reference deploy documentation.**
  - [ ] Write a comprehensive guide to deploying the stack with SLA and observability guarantees.

### QA checklist

- [ ] All required events (claim, handoff, reject, escalate) emit structured JSON logs.
- [ ] Log artifacts contain accurate timestamps, epochs, and agent IDs.
- [ ] Reference deploy doc can be followed by an independent auditor to stand up the environment.

---

## Notes

Part B gaps map to the strategic backlog in `4X4.md`; any mechanism that changes the event schema
(e.g. R1 epoch fencing) gets a decision record under `decisions/` before it lands. Part B was merged
2026-06-15 from the flat gap-analysis + the phased/QA structure (the earlier standalone gap-analysis
roadmap is superseded), then folded into `ROADMAP.md` and now extracted here as the canonical Part B
plan.
