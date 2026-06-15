# ROADMAP — from "mechanically proven" to commercially viable

The `tick` + relay-automation stack is **mechanically proven** (happy-path coordination, 21/21
validate, live Codex + Gemini headless turns behind one safety boundary). Commercial viability
needs a different bar: **adversarial proof under failure**, with reproducible logs a buyer (or an
auditor) can replay. This roadmap tracks that gap.

Maturity ladder:
1. **Mechanically proven** — happy path works. ✅ (done)
2. **Adversarially proven** — survives kill/dup/stale/race, with evidence. ⬅ *this roadmap*
3. **Commercially viable** — adversarial proof + packaging + SLA/observability + a reference deploy.

Each gap below names: the **threat**, what a log must **prove**, the **test to build** (and the
artifact it emits), the existing **mechanism** it leans on, and honest **status**.

---

## Commercial-proof gaps (the deliberate failure logs)

### G1 — Mid-turn termination
- **Threat:** an agent dies *after* `claim` but *before* `release`/`done` — the turn token is held by a corpse; the relay stalls forever.
- **Must prove:** the watchdog **detects** the stalled turn within a bounded time and either **recovers** it (reap → re-offer to a live agent) or **safely halts** with a structured escalation — never silently hangs, never double-assigns.
- **Test to build:** `test/chaos-midturn-kill.sh` — seed RELAY-TURN, claim as agent X, `kill -9` the turn-taker before handoff, run `watchdog.sh`; assert it flags `parked_suspects[X]` and emits the escalation record; then assert a recovery path (reap+reoffer) lands the token on a live agent exactly once. **Artifact:** the watchdog JSON escalation + before/after token state.
- **Leans on:** `watchdog.sh` (Phase 2 liveness, `tick analyze --format json` → `parked_suspects[]`), `relay-drive.sh` no-progress escalation, `tick ping` heartbeats.
- **Status:** ⚠️ *Partial.* Detection exists and is unit-tested; the **recovery** half (auto-reap) is a stub behind `--allow-reap`, pending an authority decision. No deliberate kill-mid-turn chaos log yet.

### G2 — Duplicate / ambiguous turn token
- **Threat:** two `claim`/ownership events for the same token (race, replay, or a malicious/duplicated event file) → ambiguous "whose turn," double-execution.
- **Must prove:** the projection **kernel deterministically resolves to exactly one owner** (or quarantines the token as un-ownable) — same result on every replay, regardless of event arrival order.
- **Test to build:** `test/chaos-dup-token.sh` — inject two claims for one RELAY-TURN with crafted ts/agent orderings (incl. equal ts), project repeatedly; assert a single stable winner via the documented tie-breaker (earliest ts, then lex agent id), and that the loser is rejected with zero side effects. Add a malformed/duplicate event-file variant → assert quarantine, not crash. **Artifact:** projection output across N replays (must be identical).
- **Leans on:** `tick` disjoint-files-per-event log, single-pass projection + deterministic tie-breaker, the **handoff-exclusive** rule (claim of a handed-off token by a non-designee is rejected with zero events).
- **Status:** ⚠️ *Partial.* The tie-breaker and handoff-exclusivity are tested (`concurrent-claim.sh`, `handoff-exclusive.sh`); the **adversarial duplicate-injection + quarantine** path is not a standalone proof yet.

### G3 — Stale-writer fencing  ← **biggest gap**
- **Threat:** agent X is presumed dead and the token is taken over (reap → reclaim by Y); then X **revives** and issues `done`/`release`/edit. Classic stale-writer: a zombie advances or corrupts the relay after it lost ownership.
- **Must prove:** once ownership moves on, the **stale epoch cannot write, commit, or advance** — its events are fenced (rejected) by the kernel, not merely ignored by convention.
- **Test to build:** `test/chaos-stale-writer.sh` — claim as X, reap+reclaim as Y (new epoch), then replay X's `done`/`release`/scope events; assert every one is **rejected as stale-epoch** and the relay state is unchanged. **Artifact:** rejected-event log showing the fence firing.
- **Leans on:** ownership enforcement (only the claiming agent can mutate) — **but that is not epoch fencing.** Today's `tick` has no monotonic **fencing token / epoch number** on claims, so a revived X with the *same* agent id may still satisfy ownership checks after a takeover.
- **Status:** ❌ **Missing mechanism.** Needs a per-claim **epoch** (incrementing fencing token) recorded in the claim event and checked on every mutating verb: a write from an epoch older than the current owner's is rejected. This is the single most important commercial-hardening item — it's the difference between "soft coordination" and "a kernel you can trust unattended." Tracked as **R1** below.

### G4 — Concurrent pollers
- **Threat:** two eligible poller loops (e.g. two windows, or a window + a cron) both see "my turn / parked" and both act → double turn, double escalation, double commit.
- **Must prove:** under a genuine race, **exactly one poller acts**; the others observe the state change and stand down.
- **Test to build:** `test/chaos-concurrent-pollers.sh` — launch two `poll.sh` invocations against the same relay/watchdog state simultaneously (background, same tick); assert exactly one dispatches (runner or watchdog) and the other idles, across many iterations. **Artifact:** per-poller decision log over N trials (must be 1-acts every time).
- **Leans on:** the lock/heartbeat as the real guard (not the timer), `--watchdog-authority` (exactly one authority), the token as the mutex.
- **Status:** ⚠️ *Partial / by-design but unproven.* The design says the lock is the guard and only one authority escalates; there is **no race-hammer test** yet that drives two pollers concurrently and counts winners. (This is the "Phase-4 race hammer-test" already on the backlog.)

### G5 — Cross-repo / cross-model diversity
- **Threat:** the protocol is secretly coupled to *this* repo or to all-Claude/manual flows — it won't generalize, so it has no product surface.
- **Must prove:** the **same protocol runs in a different repository** (zero-setup from the packaged skill) **and** with **heterogeneous agents** taking real turns (not just Claude, not just manual nudge).
- **Test to build:** `test/e2e-fresh-repo.sh` (or a CI job) — install the skill into a throwaway repo from `relay-pkg.tar.gz`, run a full Producer↔Reviewer relay to `Approved` with a headless turn-taker; assert no dependency on the home repo. Pair with a recorded **cross-model** run (Codex turn + Gemini turn in one thread). **Artifact:** transcript + commit graph from a foreign repo.
- **Leans on:** the packaged sibling skill (`relay-pkg.tar.gz`, `QUICKSTART.md`), `codex-turn.sh` + `gemini-turn.sh` over the shared core.
- **Status:** ⚠️ *Partial.* Cross-**model** is live-proven (Codex + Gemini headless turns). Cross-**repo** is documented (`QUICKSTART.md`) but there is **no zero-setup fresh-clone E2E** that proves no home-repo coupling, and `.tick/` is still per-device-local (no cross-machine sync).

---

## Hardening items (mechanisms the gaps imply)

- **R1 — Epoch fencing tokens** (unblocks G3). Add a monotonic epoch to each claim; stamp it on every mutating event; reject events whose epoch < current owner's. The core distributed-systems primitive the stack currently lacks. *Costly; one-way-ish (touches the event schema + projection).*
- **R2 — Auto-reap authority decision** (unblocks the recovery half of G1). Decide who may reap and under what evidence; record it; flip `watchdog.sh --allow-reap` from stub to real.
- **R3 — Cross-machine `.tick/` sync** (unblocks true G5 multi-device). An out-of-band ref or sync daemon so two machines share coordination state.
- **R4 — Observability surface** (commercial table-stakes, not a gap above). Structured, timestamped logs for every claim/handoff/reject/escalation that a buyer can ship to their SIEM.

## Suggested sequence
1. **R1 (epoch fencing) + G3 chaos log** — the credibility keystone; do first.
2. **G1 + G2 + G4 chaos suite** — package the three "deliberate failure" tests with R2.
3. **G5 fresh-repo E2E + R3** — prove generality and decouple from this repo.
4. **R4 observability + reference deploy** — the last mile to "commercially viable."

*Created 2026-06-15. Status legend: ✅ proven · ⚠️ partial/unproven · ❌ missing mechanism.
Gaps map to backlog items in `4X4.md`; mechanisms that change the event schema get a decision
record before they land.*
