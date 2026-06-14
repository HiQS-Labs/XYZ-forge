---
status: Decided
date: 2026-06-14
reversibility: Costly
revisit: "next real balanced multi-agent run < 50% work-bounded concurrency"
related: []
decider: "@noelsaw1"
---

# Graduate the relay-automation coordination spike to Phase 2

**Decision:** Graduate the `tick`-based coordination layer from spike to Phase 2 — start building the relay-automation product on top of it (flesh out `runner.sh` / `watchdog.sh` beyond skeletons), rather than running more validation rounds first.

**The bet:** Run 4's result generalizes — a *balanced* task fixture reliably clears the ≥50% work-bounded concurrency bar, and the 40% → 72.2% jump was the fixture fix Run 3 prescribed working as intended, not a fluke of one tiny 4-task run. Equivalently: the coordination protocol (atomic claim, lane isolation, heartbeats, launch-sync) is sound, and the only thing that ever held back the metric was load imbalance, now resolved by construction.

**Rejected:** *Iterate — run more balanced rounds before graduating.* Lost because Run 3 already isolated load imbalance as the sole cause of the 40% miss and prescribed the balanced fixture; Run 4 applied exactly that and cleared the bar on a flawless run (both acceptances green, real passing deliverables, zero collisions/parked claims). Additional rounds buy marginal confidence at the cost of delaying Phase 2 — and Phase 2 work will itself produce more balanced-run datapoints to watch.

**Expected signal:** The next real balanced multi-agent run (Phase-2 build work, or a deliberate follow-up run) holds **≥ 50%** work-bounded concurrency — observed on the next such run, not a calendar date.

**Reversibility:** Costly — the protocol itself is unchanged, so reverting the *decision* is cheap (resume iterating), but any Phase-2 product work built on the graduation assumption would be partially sunk if the bet breaks. Not a one-way door.

**Revisit trigger:** A real balanced run drops below the 50% work-bounded-concurrency bar (re-open the load-balance question), **or** Phase-2 build surfaces a coordination failure the spike didn't catch (collision, drift, parked-claim deadlock). Either fires a `Revisited`.

## Caveats carried forward
- **Single-trial datapoint.** 72.2% is one short (~3 min) 4-task run. Strong, but n=1 — the first real balanced Phase-2 run is the confirmation.
- **Open polish items** (not blockers, tracked from agent feedback): build-prompt "initiative bound"; test-harness `TICK_REPO_ROOT`/`$A` standardization; possible lighter launch-sync.

## Updates
<!-- append-only, newest last -->
