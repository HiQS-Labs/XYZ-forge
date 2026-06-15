---
status: Validated
date: 2026-06-15
reversibility: Costly
revisit: "if the RELAY-TURN-task rework proves heavier than ~one 4a/4b-sized increment, reassess vs baton"
related:
  - decisions/2026-06-14-graduate-relay-automation-phase-2.md
decider: "@noelsaw1"
---

# Relay turns go tick-native (resolve baton-vs-tick fork → Option a)

**Decision:** Convert the relay driver's turn-token from the baton file's `NEXT`/`STATUS` to a real **`RELAY-TURN` tick task** (claim / `release --to` / `ping`), so the relay path uses the Phase-1 handoff-exclusive rule and is visible to the Phase-2 watchdog. Content + verdict stay in the relay markdown; tick owns *whose-turn + liveness*. (Option **(a)** over Option **(b)** baton-as-built.)

**The bet:** Tick-native is where we end up regardless — both **unattended/long relays** (watchdog self-healing) and the deferred **Option A headless CLI** only pay off in the tick-native world. Doing it now avoids a later baton→tick migration and a stranded Phase-1 rule.

**Rejected:** (b) keep the baton-file model + rewrite spec items 191/201. Lost because it leaves relay turns un-enforced (honor-system exclusivity), invisible to the watchdog (no self-healing — contradicting the "self-healing review loop" goal), and maintained as a second coordination model alongside tick. Cheaper today, but a known future migration. Operator's call: "that's where we'll end up ultimately."

**Expected signal:** (a) ships with the watchdog **detecting a stalled `RELAY-TURN`** (a test proving self-healing covers relays), `validate.sh` green, and proposal items 191 + 201 honestly re-checked `[x]`.

**Reversibility:** Costly — reworks poll.sh relay mode + relay-drive.sh + their tests; reversible back to baton but at the cost of the work. Not a one-way door.

**Revisit trigger:** if the rework balloons past ~one 4a/4b-sized increment (e.g. the token/verdict split or test-harness tick ops prove gnarly), reassess whether baton-now + tick-later is the better sequence after all.

## Updates
<!-- append-only, newest last -->
- 2026-06-15 — **Scope reality-checked by Codex (single-round-trip relay, `relay-system/2026-06-15/phase4a-scope-check.md`).** My ~2.5-pass estimate was rosy; accepted Codex's **~3.5 passes / ~4–5 hours**. It's conversion work (no new core — the `tick` primitive + handoff-exclusive rule verified sufficient, incl. repeated handoff via projection); the cost is the relay poll/supervisor/**test** rewrite off `NEXT`/`sed` onto a real `RELAY-TURN`. Scope corrected (added role↔agent plumbing + re-priced tests as a full slice + a multi-turn integration test). **Operator deciding whether to commit the 4–5h now or sequence later** — does not change the (a) direction, only its timing/cost.
- 2026-06-15 — **SHIPPED + Validated.** (a) built in the estimated ~3.5 passes (test-harness rewrite was the cost, as Codex predicted). **Expected signal met:** `test/watchdog-relay.sh` proves the watchdog detects a stalled `RELAY-TURN` (self-healing now covers relays), `validate.sh` 18/18, proposal items 191/201 re-checked `[x]`. **Codex code-review: Approved** (`relay-system/2026-06-15/phase4a-code-review.md`) — it caught + reproduced a close-mismatch Blocker (Approved-without-`done` leaked a live token), fixed via close-agreement + regression. Status → Validated.
