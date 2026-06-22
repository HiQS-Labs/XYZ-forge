---
title: Combined Roadmap — Cost-Observed Marathon Loops + Adversarial Hardening
status: Active
created: 2026-06-16
updated: 2026-06-21
branch: main
supersedes: PROJECT/2-WORKING/ROADMAP-COMBINED.md (promoted to canonical 2026-06-17); folds in the former standalone ROADMAP.md (adversarial-hardening track, now Part B)
synthesizes:
  - PROJECT/1-INBOX/LOOPS.md
  - PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md
  - PROJECT/1-INBOX/MARATHON.md
goal: >
  Canonical pointer/ledger index for the repo's work — projects in progress, completed, attempted,
  and deferred — linking to the canonical PROJECT/** docs that own the execution detail. This is an
  index, not a plan body.
---

<!-- PDDA ROADMAP CONTRACT — this file is a POINTER/LEDGER, not a plan body.
     Allowed: projects in progress / completed / attempted / deferred + links to PROJECT/** docs.
     NOT allowed: phase checklists, build steps, deep execution notes — put those in the project doc.
     Carve-out: a SHORT exception note is OK only when omitting it would hide an operationally critical fact.
     Enforced by utils/pdda-check-roadmap.sh (deterministic) + utils/pdda-doc-ready.sh ROADMAP rubric (LLM). -->

# Combined Roadmap: Cost-Observed Marathon Loops + Adversarial Hardening

> **Pointer/ledger only — not a plan body.** Execution detail (phase checklists, build steps, QA
> gates, deep notes) lives in the linked `PROJECT/**` docs; keep it there. See the contract banner above.

Three tracks, sequenced independently:

- **Part A — Marathon:** cost observability (done) → headless multi-phase chaining (done) → real-monolith dogfood (active)
- **Part B — Adversarial Hardening:** epoch fencing (done) → chaos suite → cross-repo E2E → reference deploy
- **Part C — Autonomous Self-Improvement:** the gated LOOPS.md endgame

## Status

| What was just completed | What's next |
|---|---|
| **Part A harness build complete** — cost foundation, headless build→review→chain harness, and worktree-isolation containment all shipped + E2E-validated (`validate.sh` 33/33). **Part B Phase 1 — epoch fencing** shipped 2026-06-18. | Two active frontiers: **Part A Phase 6 — WPCC real-monolith dogfood** (the graduation test, run with `RELAY_WORKTREE_ISOLATION=1`) and **Part B Phase 2 — chaos suite & auto-recovery**. |

## Model assignment (heuristic)

Mechanical / pattern-following work → **Sonnet High**; trust-critical kernel-correctness reasoning
(epoch-fencing kernel, dup-token determinism) → **Opus**. Full build-track table:
[MARATHON-HARNESS.md → Model assignment](PROJECT/3-COMPLETED/MARATHON-HARNESS.md#model-assignment-build-track-guidance).

> **Operational note (carve-out — operationally critical):** Gemini CLI retired 2026-06-19; **agy**
> (Antigravity CLI) is the permanent cross-model lane. **Run agy turns sandbox-OFF** (it exits 0 with
> empty output when its backend is blocked) and an agy lane is **cost-blind** (no token output).
> Detail: [MARATHON-HARNESS.md → Operational note](PROJECT/3-COMPLETED/MARATHON-HARNESS.md#operational-note--cross-model-lane).

## Ledger

### In progress

- **Part A · Phase 6 — WPCC real-monolith dogfood** 🟢 — the graduation test: first run of the whole harness against a 6,988-line production monolith (Codex + agy workers). Unblocked 2026-06-18; run on a dedicated branch with `RELAY_WORKTREE_ISOLATION=1`. → [MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md](PROJECT/2-WORKING/MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md)
- **Part B — Adversarial hardening** ⚠️ — Phase 1 (epoch fencing) shipped; Phase 2 chaos-suite *detection* partials landed; Phases 2–4 are the active "adversarially proven → commercially viable" frontier. → [ADVERSARIAL-HARDENING.md](PROJECT/2-WORKING/ADVERSARIAL-HARDENING.md)
- **Tooling · relay-xyz durability** 🟢 — shakedown-lens discovery audit (locator green, root-caused symlink-only discovery → shipped `skills/relay-xyz/install.sh`) + drive-layer hardening from a sibling headless run (space-safe `--agent-cmd` dispatch; worktree isolation default-ON for driven runs); dangling-symlink + `GH Repos`/`GitHub-Repos` clone-split flagged for sign-off. → [RELAY-XYZ-DISCOVERY-SHAKEDOWN.md](PROJECT/2-WORKING/RELAY-XYZ-DISCOVERY-SHAKEDOWN.md)

### Completed

- **Part A · Phase 1 — Cost observability foundation** ✅ 2026-06-16 — deterministic token / wall-clock / human-minute capture in `tick analyze`. → [COST-OBSERVABILITY-PLAN.md](PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md)
- **Part A · Phases 2–4 — Marathon harness build** ✅ 2026-06-17/18 — dispatcher + headless single-phase loop + autonomous-builder containment + multi-phase `MARATHON.yaml` chaining (M6/M7 deferred). → [MARATHON-HARNESS.md](PROJECT/3-COMPLETED/MARATHON-HARNESS.md)
- **Part A · Phase 5 — Cross-system cost comparison** ✅ 2026-06-16 — xyz vs relay, every cell from `tick analyze --format json`. → [COST-COMPARISON.md](PROJECT/2-WORKING/COST-COMPARISON.md)
- **Part B · Phase 1 — Epoch fencing & stale-writer prevention** ✅ 2026-06-18 — monotonic per-task epoch fences zombie writers in the projection kernel. → [ADVERSARIAL-HARDENING.md](PROJECT/2-WORKING/ADVERSARIAL-HARDENING.md#phase-1--epoch-fencing--stale-writer-prevention-r1--g3) · [decision record](decisions/2026-06-18-epoch-fencing.md)

### Deferred · vision

- **Part C — Autonomous self-improvement loop** 🔮 gated — the LOOPS.md endgame; gated on the metric / oracle / stop-condition prerequisites (safety cage already shipped). → [AUTONOMOUS-SELF-IMPROVEMENT-LOOP.md](PROJECT/1-INBOX/AUTONOMOUS-SELF-IMPROVEMENT-LOOP.md)
- **Part A · Phase 4 — M6 / M7** 🔲 deferred — cross-phase context injection + state projection, until a phase genuinely needs them. → [MARATHON-HARNESS.md → Deferred](PROJECT/3-COMPLETED/MARATHON-HARNESS.md#deferred--m6--m7)

---

*Detail for every entry lives in its linked `PROJECT/**` doc. Part B gaps also map to `4X4.md`; any
event-schema change gets a decision record under `decisions/` before it lands.*
