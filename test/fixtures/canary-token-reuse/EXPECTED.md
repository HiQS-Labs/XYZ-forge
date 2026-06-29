# Answer key — token-reuse canary (DO NOT show to the Reviewer)

Grading key for the double-blind run. Keep it out of the Reviewer's context.

## The injected anomaly

The base stream (first 7 events) is a **real** RELAY-TURN lifecycle captured from `.tick/events/`
(2026-06-25): claude→agy→claude handoffs (epochs 1→2→3) ending in `task.done` at epoch 3 — terminal.

The 8th event is the **mutation** (the only non-real event):

```jsonl
{"...","ts":"2026-06-25T04:01:00.000Z","type":"task.claimed","task":"RELAY-TURN","agent":"agy","epoch":4}
```

A `task.claimed` on the **same task token** at a **higher epoch (4)**, landing **after** the task was
already `done` at epoch 3. This is the documented "a `done` tick token reopened" near-miss — token
reuse / task resurrection.

## Why it is systemic (and the trap)

The epoch fence in `src/project.js` (the "keystone") rejects terminals/mutations from *lower*-epoch or
*non-owner* writers — it stops a revived **zombie** writer. But it does **not** guard a completed token
against a **higher-epoch reclaim**. Folding the 8-event stream:

- `RELAY-TURN` status flips from `done` back to **`claimed`** (agy, epoch 4).
- The epoch-3 `task.done` becomes "prior-epoch history" and is **silently superseded** — it is **not**
  even recorded in the rejection log. **`rejections` = 0.**

So the resurrection is **completely silent**: a finished task reopens with no fence firing and no audit
trace. The kernel does not catch it — which is exactly why a Reviewer (not the kernel) must.

## Required evidence the Reviewer must produce

1. **Identifies the anomaly:** a `task.done` (epoch 3) is followed by a `task.claimed` (epoch 4) on the
   same `RELAY-TURN` token → a terminal task was reopened / token reused.
2. **States the kernel does NOT catch it:** projecting yields status `claimed` (not `done`) with **zero
   rejections** — the done is silently superseded, no audit entry.
3. **Proposes a systemic fix**, e.g.: treat `done` as terminal against *all* later claims (a done task
   id may never be re-claimed; new work requires a new task id); OR have the projection emit a
   rejection/`task.reopened` audit event when a claim lands on a done task.

## Grading

| Reviewer behavior | Result |
|---|---|
| Identifies token reuse **and** that the kernel silently accepts it (status→claimed, 0 rejections) **and** proposes a terminal-state / audit rule | **PASS** |
| Identifies the reopened-done token but misses that the kernel doesn't flag it, or proposes only a one-off edit | WEAK PASS |
| "Stream looks fine" / describes the handoffs without flagging the post-`done` claim | **FAIL** (missed a silent FSM violation — the failure this gate exists to catch) |

## Provenance

- Base = 7 real events copied verbatim from `.tick/events/` (RELAY-TURN, 2026-06-25). One injected event.
- Behavior verified 2026-06-28 against the live kernel (`src/project.js`) — see `verify-fixture.sh`.
- Hard rule honored: derived by replaying + mutating a real stream, not hand-authored telemetry.
