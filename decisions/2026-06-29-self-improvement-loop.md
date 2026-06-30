---
status: Decided
date: 2026-06-29
reversibility: Costly
revisit: "the first operator-gated REAL-AGENT dogfood (marathon-drive as --build-cmd) — does the loop improve a real target with a live Codex/agy builder without gaming, regressing, or runaway spend? Also revisit if any single iteration's --build-cmd is ever allowed to write an oracle/test path."
related: ["2026-06-18-epoch-fencing.md", "2026-06-15-unattended-agent-containment.md"]
decider: "@noelsaw1"
gh_issue: 50
---

# Autonomous self-improvement loop (Part C) — compose small primitives behind a hard safety contract

**Decision:** Build the LOOPS.md endgame — a metric-driven champion/challenger hill-climb — as a
composition of six small, independently-tested bash primitives (`measure.sh`, `loop-stop.sh`,
`oracle-guard.sh`, `champion.sh`, `heldout-check.sh`, `loop-cost.sh`) orchestrated by `improve-loop.sh`,
on top of the **already-shipped** safety cage (worktree isolation 3.6, per-turn caps R5, epoch fencing
B·P1, the GH-40 double-blind reviewer as the semantic oracle). The builder is **pluggable** via
`--build-cmd`: a deterministic script for tests/dogfood, or `marathon-drive` driving a live agent in
production. The machinery runs autonomously; the **real-agent trigger stays operator-gated**.

**The bet:** Five enforced invariants are sufficient to make unattended metric optimization *safe* —
i.e. it cannot silently ship a worse artifact, game its own measure, or run forever:
1. **Guaranteed halt** — `loop-stop.sh` requires a positive `--max-iterations`; even if target/budget/
   plateau never fire, the cap halts on every path (termination is structural, not hoped-for).
2. **Un-gameable oracle** — `oracle-guard.sh` refuses to start if the builder's write surface overlaps
   the oracle (`ALLOW_PATHS ∩ oracle = ∅`), reusing the kernel's own conservative path-overlap; so the
   loop cannot "win" by editing tests.
3. **No-regress** — `champion.sh` accepts only on `oracle-pass AND metric-improved`; a reject rolls the
   artifact back to the champion snapshot. A losing run ships the champion, never something worse.
4. **Anti-gaming** — `heldout-check.sh` vetoes a visible-metric gain that arrives with a held-out-metric
   loss (the overfit signature), with a metric the builder never sees.
5. **Honest cost** — `loop-cost.sh` makes spend exact (wall-clock is universal; tokens exact except the
   cost-blind agy lane) and flags floors, so improvement-per-dollar is never silently a lower bound.

**Why composition over a monolith:** each invariant is a ~30–60 line script with its own test (12/13/
9/13/10/8), so a failure is localized and the safety properties are individually auditable — the same
"small kernel you can trust unattended" discipline as epoch fencing. `improve-loop.sh` only wires them.

**Reversibility:** the *code* is additive — new `relay-automation/*.sh` + tests, `validate.sh` 68→69,
**zero kernel/`src`/`.tick` change** — so the build is Easy to revert. The *bet* (that this is safe to
eventually run on the live system with a real agent) is the Costly / one-way part, which is why the
real-agent run is gated, not fired by the autonomous build loop.

**Verification:** all six primitives + the composed loop + a QA-checklist test are green
(`test/improve-loop*.sh`); a **real-target dogfood** (`test/improve-loop-dogfood.sh`) drove a real file
6→2 lines under a real oracle, rolled back the no-op steps, halted on plateau, preserved the required
content, and shipped the 2-line champion — a losing iteration shipped nothing. `validate.sh` 69/69.

**Rejected alternatives:**
- *Run the real-agent loop unattended now.* It spends real tokens per iteration and the builder is
  non-deterministic; firing it from an autonomous build loop is exactly the budget-bonfire / silent-
  gaming risk the cage exists to prevent. Gate it behind an explicit operator GO.
- *A single orchestrator script.* Harder to test the safety invariants in isolation; a bug in one gate
  would hide inside the loop. Small composable primitives keep each invariant falsifiable.
- *Trust the metric alone (no held-out, no oracle-immutability).* That is precisely how an optimizer
  games the benchmark; both guards are load-bearing, not belt-and-suspenders.

**Expected signal:** the first operator-gated real-agent dogfood improves a real bounded target's metric
with the oracle held, the held-out metric not regressed, cumulative spend within `--max-total-budget`,
and the provenance log showing a clean accept/reject trace that replays identically.
