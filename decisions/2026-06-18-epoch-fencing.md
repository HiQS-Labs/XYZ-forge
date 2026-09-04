---
status: Decided
date: 2026-06-18
reversibility: Costly
revisit: "first chaos-suite run (G1 midturn-kill / R2 auto-reap) that exercises reap → reclaim under real liveness, or any cross-machine .tick/ sync (R3) that can reorder claim arrival"
related: ["2026-06-15-relay-turns-tick-native.md"]
decider: "@noelsaw1"
---

# Monotonic epoch fencing for stale-writer prevention (Part B Phase 1, R1 + G3)

**Decision:** Add a monotonic, per-task `epoch` to the `tick` event schema (bump `schema_version` 0.1.0 → 0.2.0) and make the projection kernel (`src/project.js` `fold`) **fence** any mutating event whose epoch is below the current owner's. A displaced writer — even one that revives with the **same agent id** — can no longer advance (`done`/`circuit_break`), corrupt (`scope_changed`), retire (`released`), or redirect the handoff of a task it no longer owns. Rejected events are recorded in a deterministic audit log (`.tick/rejected.jsonl`, surfaced by `tick fences`).

**The bet:** A single integer fencing token, assigned under the existing claim lock and baked into each event at write time, is sufficient to turn "soft coordination" (ownership-by-convention) into a kernel you can trust unattended. Specifically: replay determinism holds because the fence verdict is a pure function of the recorded event set (no wall-clock, no arrival-order dependence), so the same events project to the same state and the same rejections on every machine and every replay.

**Mechanism (the invariants):**
- **Assignment.** A fresh `task.claimed` carries `epoch = max(prior epochs for this task) + 1` (first claim ⇒ 1). Computed under `withClaimLock`, so concurrent claims serialize and can't collide on an epoch. Mutations (`done`/`break`/`scope`/`release`) are stamped with the current owner's epoch by the verb layer; `reap` stamps the reaped claim's epoch on the release that retires it.
- **Ownership = highest live epoch.** The current owner is the live claim with the highest epoch (ties → earliest ts → lex agent id, the legacy tie-breaker, reached only when all epochs are equal — e.g. pre-0.2.0 logs that are all epoch 0).
- **Release is epoch-gated (load-bearing).** A `task.released` retires a claim only if `release.epoch >= claim.epoch`. Without this, a revived writer's replayed *lower-epoch* release would retire the current *higher-epoch* claim it shares an id with — the same-id keystone failure.
- **The fence.** A mutation is honoured only when it is from the current owner at `epoch >= owner.epoch`; otherwise it is rejected and never applied. Reason is `non-owner-agent` (different id) or `stale-epoch` (same id, lower epoch — the keystone).
- **Audit, not noise.** Only post-takeover violations (`ts > owner.claim.ts`) are logged. Legitimate prior-epoch history (the reap/handoff release, the old owner's scope) is silently superseded, not flagged.

**Backward compatibility:** Events without `epoch` read as epoch 0. With every claim at epoch 0 the new selection degenerates exactly to the old earliest-ts/lex-agent tie-breaker, so pre-0.2.0 logs project identically. `validate.sh` 29/29 (28 prior + `chaos-stale-writer.sh`), zero regressions. Non-epoch events stay byte-stable (`epoch` is stamped only when present).

**Rejected alternatives:**
- *Emit-time ownership check only (status quo).* `assertOwnership` already blocks a stale write **through the CLI**, but cannot stop an event that lands in `.tick/events/` by another path (duplicate file, R3 cross-machine sync, a buffered write from a corpse process). The threat is replay/injection, so the fence must live in the projection kernel, not the verb.
- *Wall-clock / lease timestamps.* Not replay-deterministic and not monotonic across machines; a clock skew or a reordered sync would mis-rank owners. An integer epoch is order-free and exact.
- *Quarantine the whole task on conflict.* Heavier and operator-hostile; the displaced writer is unambiguously the loser (lower epoch), so reject-the-event is the minimal correct response and keeps the live owner working.

**Expected signal:** When the chaos suite (Part B Phase 2: G1 mid-turn kill, R2 auto-reap, G2 dup-token) drives real reap → reclaim cycles, no stale writer advances or corrupts state, and `.tick/rejected.jsonl` shows the fence firing with matching epochs. `tick fences` output is identical across replays of the same event set.

**Reversibility:** Costly, not a one-way door. The schema field is additive and the kernel change is localized to `fold`, but once 0.2.0 logs with real epochs exist in the wild, reverting the kernel would re-expose the stale-writer hole and the epoch fields would become dead weight. Reverting before any real epoch logs accumulate is cheap.

**Revisit trigger:** A chaos-suite run where a stale writer still mutates state despite the fence (re-open the kernel invariant), **or** a cross-machine sync (R3) that can deliver claims out of order in a way the per-task epoch assignment doesn't cover (epochs are assigned under a *local* lock — multi-writer concurrent claim across machines may need a coordination point above the per-clone lock). Either fires a `Revisited`.

## Caveats carried forward
- **Epoch assignment assumes a single serialization point** (`withClaimLock`, per clone). Cross-machine concurrent claims (R3) are out of scope for this change — flagged as the revisit trigger.
- **Releases are agent-scoped**, so a stale release is already inert against another agent's claim; the epoch gate matters specifically for the *same-id* reclaim case and is logged as `stale-epoch-inert` when it post-dates takeover.
- **`.tick/rejected.jsonl` is the seed for R4** (SIEM-ready observability), but is not yet a committed artifact or wired into `tick analyze` — that is Part B Phase 4.
