---
title: Auto-reap authority — who may reap a parked claim, and on what evidence (Part B Phase 2, R2)
date: 2026-06-30
status: Decided
gh_issue: 52
supersedes: the `--allow-reap` reap stub (watchdog.sh)
related:
  - decisions/2026-06-18-epoch-fencing.md   # the release a reap emits is epoch-stamped (Phase 1)
  - relay-automation/watchdog.sh
  - PROJECT/2-WORKING/ADVERSARIAL-HARDENING.md  # G1 detection (shipped) + R2 (this)
---

# Auto-reap authority (Part B Phase 2, R2)

**Decision:** Flip `relay-automation/watchdog.sh --allow-reap` from a print-only stub to a **real,
scoped, idempotent** reap. For each confirmed parked suspect the watchdog already escalates, it then
runs `tick reap <agent> --by watchdog --task <task_id>` to **re-offer the orphaned token exactly once**.
Reaping is gated behind the explicit `--allow-reap` authority grant; the evidence is membership in the
structured `parked_suspects[]` from `tick analyze` (a max-heartbeat-gap past the parked threshold),
which by construction excludes any live / heartbeating claim. This closes the recovery half of G1
(mid-turn-kill): detection shipped 2026-06-18; recovery was deferred pending this authority decision.

**The bet:** The existing **detection** verdict (`parked_suspects[]`) is a trustworthy enough liveness
signal to also drive **recovery** — *no new liveness logic is needed* — provided recovery is (a) gated
behind an explicit authority flag, (b) **scoped** to one `(agent, task)` so it never blanket-reaps an
agent's other (possibly live) work, (c) **idempotent** so repeated watchdog ticks never double-reap,
and (d) **epoch-safe** (Phase 1 already stamps the release a reap emits with the reaped claim's epoch,
so a revived same-id writer's lower-epoch events stay fenced). Recovery reuses detection; it adds an
authority gate and a re-offer, nothing more.

**Mechanism (the invariants):**
- **Authority = the `--allow-reap` grant.** Only a watchdog invoked with `--allow-reap` may reap.
  Without it, behaviour is byte-identical to today: escalate (one JSON record per suspect) and stop.
  Pairs with the single `--watchdog-authority` poller rule so at most one actor reaps.
- **Evidence = `parked_suspects[]` membership, nothing else.** The ONLY input to the reap is the
  structured suspect list (`max_gap_ms` past the parked threshold — the text-grep false-positive was
  removed earlier, relay r1 Blocker). A claim heartbeating within the threshold never appears, so it is
  never reaped. The watchdog reaps nothing it did not first escalate.
- **Scoped, never blanket.** `tick reap <agent> --task <task_id>` retires exactly that one stalled
  claim — not the agent's other claims. (`tick reap <agent>` without `--task` reaps all of an agent's
  claims; the watchdog never does that.)
- **Exactly-once + idempotent (two independent guarantees).** (1) Reaping releases the dead claim, so
  the task becomes OPEN/unclaimed → it is no longer a parked suspect → a later watchdog tick will not
  re-reap it. (2) `tick reap` itself is a no-op if `<agent>` no longer holds `<task_id>` (already
  re-offered / a peer reclaimed). Either alone prevents double-reap; together they are belt-and-braces.
- **Epoch-safe by inheritance.** The `task.released` a reap emits is stamped with the reaped claim's
  epoch ([epoch fencing](2026-06-18-epoch-fencing.md)), so a revived same-id writer cannot re-advance
  the token it lost — the reap re-offer and the fence compose.
- **Escalate-then-reap order preserved.** The human-facing escalation record is still written FIRST,
  then the reap — recovery never hides the incident; a reap is always accompanied by its escalation.

**Backward compatibility:** Default (no `--allow-reap`) is byte-identical to today (escalate-only). The
only change under the flag is that the stub's two print lines become a real `tick reap` + a one-line
outcome. No schema change, no kernel change — `tick reap` and epoch fencing already shipped.

**Rejected alternatives:**
- **Reap ALL of the agent's claims** (`tick reap <agent>` unscoped) — too broad; it would kill the
  agent's *live* concurrent work on other tasks. Scope to the one stalled `(agent, task)`.
- **Force-take / re-assign the token to a named peer** — the token/lock is the mutex; recovery should
  *re-offer* (release → any eligible peer claims via the normal path), not force an assignment.
- **A `heartbeats == 0` guard in the reap path** — WRONG. A claim that heartbeated a few times then
  died has `heartbeats > 0` but is genuinely parked. The liveness signal is the **gap** (`max_gap_ms`
  past threshold), not the total count; the detector already encodes it, and a count guard would refuse
  legitimate reaps. The "never reap a live claim" invariant is delegated to the detector + tested
  directly (a healthy/heartbeating claim is never escalated, hence never reaped).

**Expected signal:** `test/chaos-midturn-kill.sh` + `test/watchdog-liveness.sh` drive a real reap: the
orphaned token is released exactly once, a peer can then reclaim it, a healthy run reaps nothing, and a
second watchdog pass over the same state is a no-op.

**Reversibility:** **Easy.** The change is localized to `watchdog.sh`'s reap function; revert it to the
stub or drop `--allow-reap` to fully disable. No schema/kernel/projection change to unwind.

**Revisit trigger:** a reap that releases a claim still heartbeating within the threshold (a detector
false-positive — re-open detection, not this decision), **or** a cross-machine watchdog (R3) where two
authorities could reap the same token concurrently (needs a coordination point above the single-clone
`--watchdog-authority` holder). Either fires a `Revisited`.

## Caveats carried forward
- **Single-authority assumption.** Exactly one watchdog runs with `--allow-reap` (the
  `--watchdog-authority` holder). Concurrent reapers across machines (R3) are out of scope.
- **Re-offer ≠ reclaim.** The reap makes the token claimable again; whether a peer actually picks it up
  is the next claim cycle's concern, not the watchdog's.
- **Reap audit** today is the watchdog's stderr line + the `task.released` event; a first-class reap
  audit feed is Part B Phase 4 (R4 observability), not wired here.
