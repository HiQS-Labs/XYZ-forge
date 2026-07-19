---
title: Autonomous self-improvement loop (the LOOPS.md endgame) — Part C
slug: autonomous-self-improvement-loop
status: Closed (issue #50 closed) — Active
created: 2026-06-16
updated: 2026-06-29
owner: Noel (operator) · Claude (producer)
gh_issue: 50
branch: feat/self-improvement-loop
complexity: 4
risk: 4
effort: 4
ratings_provisional: true
related:
  - PROJECT/1-INBOX/LOOPS.md                                      # the endgame this realizes
  - PROJECT/3-COMPLETED/MARATHON-HARNESS.md                       # the Part A convergence loop this turns into optimization
  - PROJECT/2-WORKING/ADVERSARIAL-HARDENING.md                    # the Part B safety cage
  - PROJECT/2-WORKING/MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md  # the human-gated precursor (single bounded iteration)
non_goals:
  - Do NOT start before all three pillars (metric, oracle, stop condition) land — this is gated, not next.
goal: >
  Turn the build↔review convergence loop (Part A) into a metric-driven optimization loop — the
  LOOPS.md endgame — an unattended loop that measurably improves an artifact against a scalar, behind
  an un-gameable oracle, until a stop condition fires, without sacrificing the trust properties
  Parts A/B established. Gated vision; this is the canonical Part C detail ROADMAP.md points at.
---

# Autonomous self-improvement loop (Part C)

## Status

| What was just completed | What's next |
|---|---|
| **MERGED (PR #53, 2026-06-30) + real-agent run PROVEN 2026-06-30 (operator GO).** All 6 prerequisites + the composed loop + QA gates + a real-target dogfood shipped (`validate.sh` **69**); then the operator-gated **live-agent dogfood fired** — `improve-loop` drove a live **codex builder + agy reviewer** `marathon-drive` as `--build-cmd`: baseline 4 → live build → `KEEP` oracle held → champion ACCEPTed (metric 3) → halted on the iteration cap (all invariants fired live, provenance logged). | **Follow-ups (not blocking the milestone):** fix harness defects **#58** (`--builder claude` not on PATH headless → use codex/agy) + **#59** (allowlisted artifact in an untracked dir → spurious off-lane exit 6). Optional: find a real *optimization* target worth hill-climbing (this repo has no obvious scalar target yet). |

---

**Status: 🔮 Vision / Not started — gated on the prerequisites below.** Everything to date builds the
*cage*; this is the experiment the cage exists for. The Phase 6 dogfood is its controlled, bounded,
human-gated precursor — a single iteration with a binary gate. Part C removes "single" and
"human-gated": an **unattended loop that measurably improves an artifact against a scalar, behind a
un-gameable oracle, until a stop condition fires.** Do NOT start it before the prerequisites land —
an autonomous optimizer without all three pillars is a budget bonfire or a silently-gamed metric.

**Intent:** turn the build↔review *convergence* loop (Part A) into a metric-driven *optimization*
loop — the LOOPS.md endgame — without sacrificing the trust properties Parts A/B established.

### The three pillars (a loop is illegitimate without all three)

- **Metric — the scalar it optimizes.** A deterministic, machine-readable number emitted after each
  iteration (test-pass count, benchmark score, perf/throughput, finding count, binary size, coverage).
  New surface: a pluggable **`--measure-cmd`** (sibling to `--pre-advance-cmd`) that prints ONE number;
  same input → same number, or the loop chases noise instead of climbing.
- **Oracle — the un-gameable correctness gate.** Stops the loop "winning" by cheating (deleting tests,
  hardcoding outputs, editing the benchmark). Two layers we already have: the **mechanical** oracle
  (`--pre-advance-cmd` test/fixture suite) + the **semantic** oracle (the reviewer turn). The
  load-bearing rule: **the oracle must live OUTSIDE the builder's write surface** — enforce
  `ALLOW_PATHS ∩ oracle-paths = ∅`, or the loop optimizes the oracle instead of the artifact.
- **Stop condition — why it terminates.** Autonomy demands a guaranteed halt. Compose: a **cumulative
  budget** ceiling ($ / tokens / wall-clock across ALL iterations — new; today's caps are per-turn) +
  **plateau detection** (K consecutive no-improvement iterations) + a **target** (metric hits goal) +
  a hard **iteration cap**. Plus a **regression guard**: never accept an iteration whose oracle fails
  or whose metric regressed — keep the champion.

### The loop (champion/challenger hill-climb with a correctness gate)

1. **Baseline:** measure metric₀ on the starting artifact under the oracle (which must already pass).
2. **Each iteration, in an isolated worktree:** builder proposes a change → oracle gate (tests +
   reviewer) → measure metric. **Accept** iff oracle passes AND metric improved; else **reject**
   (discard the worktree, keep the champion). *Reuses worktree isolation (3.6) + per-turn caps (R5) +
   epoch fencing (B·P1) — the safety cage is already built.*
3. **Halt** on: cumulative budget exhausted ∨ plateau(K) ∨ target reached ∨ iteration cap. Emit the
   **champion** + a provenance log (every accepted/rejected step, the metric trace, the spend).

### Prerequisites (this is why it's gated, not "next")

- [ ] **Cumulative budget ceiling** across iterations (`--max-total-budget`), not just per-turn.
- [ ] **`--measure-cmd` metric harness** — deterministic scalar capture; floor-vs-exact honesty.
- [ ] **Oracle-immutability guard** — assert `ALLOW_PATHS` excludes the oracle/test paths; fail loudly otherwise.
- [ ] **Champion/challenger state** — keep best-so-far; accept-on-improve; rollback-on-regress.
- [ ] **Anti-gaming / held-out validation** — a second metric the builder cannot see, to catch overfit/gaming.
- [ ] **Full cost observability** — close the Codex/agy/Claude capture gaps (Phase 1 deferral) so the
      loop's OWN efficiency (improvement-per-dollar) is measurable, not a floor.
- [x] **Autonomy safety cage** — worktree isolation (3.6 ✅), per-turn caps (R5 ✅), epoch fencing (B·P1 ✅).

### QA checklist

- [ ] **Termination proof:** the loop provably halts on every stop path (budget/plateau/target/cap) — no infinite run.
- [ ] **Un-gameable:** an adversarial builder that edits the oracle or hardcodes the benchmark is *contained* (oracle outside write surface) AND *caught* (held-out metric).
- [ ] **No-regress:** the emitted champion's metric ≥ baseline and oracle-passing — always; a losing run ships *nothing*, never a worse artifact.
- [ ] **Provenance:** every accept/reject + metric + spend logged deterministically (feeds R4 observability).
- [ ] **Determinism litmus:** same seed/target → same champion, or the metric noise is explicitly bounded and disclosed.

### Built — 2026-06-29 (autonomous /loop)

All six prerequisites + the composed loop + the QA gates are shipped on `feat/self-improvement-loop`,
each with a test wired into `validate.sh` (**69/69**). The checklists above are satisfied by:

| Prerequisite / gate | Shipped as | Test |
|---|---|---|
| Metric harness (`--measure-cmd`) | `relay-automation/measure.sh` — deterministic scalar, `--check-deterministic`, floor/exact | `test/measure.sh` 12/12 |
| Cumulative stop / guaranteed halt | `relay-automation/loop-stop.sh` — target · iteration-cap · budget · plateau | `test/loop-stop.sh` 13/13 |
| Oracle-immutability | `relay-automation/oracle-guard.sh` — `ALLOW_PATHS ∩ oracle = ∅` (reuses `src/paths.js`) | `test/oracle-guard.sh` 9/9 |
| Champion/challenger + provenance | `relay-automation/champion.sh` — accept-on-improve / rollback-on-regress / `provenance.jsonl` | `test/champion.sh` 13/13 |
| Held-out anti-gaming | `relay-automation/heldout-check.sh` — visible-gain + held-out-loss ⇒ veto | `test/heldout-check.sh` 10/10 |
| Cost observability | `relay-automation/loop-cost.sh` — seconds=exact universal; tokens exact except cost-blind agy | `test/loop-cost.sh` 8/8 |
| **The loop** | `relay-automation/improve-loop.sh` — composes all six | `test/improve-loop.sh` 11/11 |
| QA-checklist gates | termination · un-gameable · no-regress · provenance · **determinism litmus** | `test/improve-loop-qa.sh` 7/7 |

**Dogfood (real bounded target):** `test/improve-loop-dogfood.sh` runs the loop on a real file —
shrink line-count (minimize) under a real oracle that requires both `KEEP:` lines to survive. Result:
the loop drove the file **6 → 2 lines** (4 accepts), **rolled back** the no-op iterations, and **halted
on plateau** once no removable lines remained; the oracle held (both `KEEP:` lines preserved), and the
champion (2 lines) is what shipped — a losing iteration shipped nothing. Provenance recorded every
accept/reject. 7/7.

**RAN 2026-06-30 — operator GO (the capstone payoff).** The loop's `--build-cmd` is pluggable;
plugging `marathon-drive` drives a live builder per iteration (the production path). The proven run:
baseline metric 4 → live build → `KEEP` oracle held → champion ACCEPTed (metric 3) → halted on the
iteration cap, provenance logged — every safety invariant fired against a real agent build.

**Documented live-run lane: `--builder codex --reviewer agy`** — NOT the marathon default
`--builder claude`, which is unusable headless (`exec: claude: not found`, [#58]). Commit the artifact
first: an untracked artifact in a fresh directory trips a spurious off-lane containment failure
([#59]). Canonical invocation (small, watched — each iteration is a full live marathon, ~2 min + real
tokens):

```bash
relay-automation/improve-loop.sh --artifact <committed-file> \
  --measure-cmd '<deterministic scalar, e.g. grep -c ... file>' \
  --oracle-cmd  '<un-gameable gate, e.g. KEEP lines survive>' \
  --build-cmd   'relay-automation/marathon-drive.sh --builder codex --reviewer agy \
                 --artifact <file> --phase-brief <brief> --round-cap 3 --pre-advance-cmd true \
                 --phase-id <fresh-id>' \
  --goal min --max-iterations <small> --state-dir <dir>
```

[#58]: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/58
[#59]: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/59

> **Why this is the capstone, not a side-quest:** Part A proved the loop *runs*; Part B proves it
> *survives failure*; Part C is the only track where the system changes its own artifacts toward a goal
> with no human in the inner loop. That is exactly why it is sequenced last — it is safe to attempt
> *only* once containment (3.6), per-turn limits (R5), and the fencing kernel (B·P1) are trustworthy,
> and once cost is fully observable (the loop must be able to see — and cap — what it spends on itself).
