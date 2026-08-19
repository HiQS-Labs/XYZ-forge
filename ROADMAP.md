---
title: Combined Roadmap — Cost-Observed Marathon Loops + Adversarial Hardening
status: Active
created: 2026-06-16
updated: 2026-08-19
branch: main
supersedes: PROJECT/2-WORKING/ROADMAP-COMBINED.md (promoted to canonical 2026-06-17); folds in the former standalone ROADMAP.md (adversarial-hardening track, now Part B)
synthesizes:
  - PROJECT/1-INBOX/LOOPS.md
  - PROJECT/4-MISC/COST-OBSERVABILITY-PLAN.md
  - PROJECT/1-INBOX/MARATHON.md
goal: >
  Canonical pointer/ledger index for the repo's work — queued intake, projects in progress,
  completed, attempted, and deferred — linking to the canonical PROJECT/** docs that own the
  execution detail. This is an index, not a plan body.
---

<!-- PDDA ROADMAP CONTRACT — this file is a POINTER/LEDGER, not a plan body.
     Allowed: queued intake / projects in progress / completed / attempted / deferred + links to PROJECT/** docs.
     NOT allowed: phase checklists, build steps, deep execution notes — put those in the project doc.
     Carve-out: a SHORT exception note is OK only when omitting it would hide an operationally critical fact.
     Coverage rule: every PROJECT/2-WORKING doc must be reflected here by a pointer (or opt out with roadmap_exempt: true).
     Enforced by `utils/pdda/pdda.sh roadmap` + `utils/pdda/pdda.sh roadmap-coverage` (deterministic) + `utils/pdda/pdda.sh doc-ready` ROADMAP rubric (LLM). -->

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
| **2026-08-19:** release **0.7.1 “Bulwark”** cut end-to-end through the RELEASES CLI and merged (PR #66) — the first release never hand-edited. **PR #55** (GH-35 tiered test selection + CPU governance; GH-45 worktree-gate refusal) and **PR #60** (GH-57 SQLite ledger fuzzing, 42/0) merged. **PR #70** closed GH-57’s live-merge gap: `test/gh57-live-merge-resolve.sh` (30/0) drives a REAL `git merge` and found four resolver defects, all fixed (failed-resolve half-closed the merge; rewound generation header accepted; `releases.db.bak` committable; `--root ""` retargeting). This ledger was purged of 256 upstream-numbered entries the same day (see below). | **[#67](https://github.com/HiQS-Suite/XYZ-forge/issues/67) (P1)** — decide the Commandcode `--yolo` default landed silently by PR #60. **[#59](https://github.com/HiQS-Suite/XYZ-forge/issues/59)** — re-arm hosted CI: the repo is public and Actions is enabled, yet pushes produce no runs. **[#58](https://github.com/HiQS-Suite/XYZ-forge/issues/58)** — GH-35 Phase 3 follow-ups (tier-2 hygiene gap P2 + two P3s), recommended to ride with Phase 3. **[#69](https://github.com/HiQS-Suite/XYZ-forge/issues/69)** — ROADMAP-as-ledger design (staged plan on the issue). Held: PR #29 (do not merge), PR #51 unreviewed. |

### Immediate next-up (ordered)

1. **[#67](https://github.com/HiQS-Suite/XYZ-forge/issues/67) — P1: ratify or revert the Commandcode `--yolo` default.** A permission-posture change to a builder default, landed inside a fuzzing PR, undecided.
2. **[#59](https://github.com/HiQS-Suite/XYZ-forge/issues/59) — find out why hosted CI fires on nothing**, then narrow triggers to push/merge on `development` + `main` and wire the required check behind `main`'s new branch protection.
3. **[#58](https://github.com/HiQS-Suite/XYZ-forge/issues/58) — GH-35 Phase 3**, folding in the tier-2 hygiene gap (P2) and the two P3 defects from the PR #55 review.

> **Provenance note (2026-08-19):** this repo succeeds
> [`xyz-3-agents-swarm`](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm); the migration kept the old GH numbering in
> inherited ledger entries. 256 upstream-numbered entries were removed from this ledger on the
> operator's call and preserved verbatim in
> [docs/ROADMAP-UPSTREAM-ARCHIVE.md](docs/ROADMAP-UPSTREAM-ARCHIVE.md) ([#69](https://github.com/HiQS-Suite/XYZ-forge/issues/69)).
> Every `GH-nnn` below refers to THIS repo's issues.

## Model assignment (heuristic)

Mechanical / pattern-following work → **Sonnet High**; trust-critical kernel-correctness reasoning
(epoch-fencing kernel, dup-token determinism) → **Opus**. Full build-track table:
[MARATHON-HARNESS.md → Model assignment](PROJECT/3-COMPLETED/MARATHON-HARNESS.md#model-assignment-build-track-guidance).

> **Operational note (carve-out — operationally critical):** Gemini CLI retired 2026-06-19; **agy**
> (Antigravity CLI) is the permanent cross-model lane. **Run agy turns sandbox-OFF** (it exits 0 with
> empty output when its backend is blocked) and an agy lane is **cost-blind** (no token output).
> Detail: [MARATHON-HARNESS.md → Operational note](PROJECT/3-COMPLETED/MARATHON-HARNESS.md#operational-note--cross-model-lane).

## Ledger

### Ad-hoc detours
- **GH-23 · Kernel invariant: enforce path-overlap rejection on direct tick claim and tick scope** 🆕 **2026-08-17, active on `fix/gh-23-kernel-overlap-enforcement`** — enforce collision-free path claims at the kernel boundary by rejecting direct `tick claim` and `tick scope` when requested paths overlap active claims held by other agents; wire `--force` bypass; add regression test coverage. → [GH-23-KERNEL-OVERLAP-ENFORCEMENT.md](PROJECT/2-WORKING/GH-23-KERNEL-OVERLAP-ENFORCEMENT.md) · [#23](https://github.com/HiQS-Suite/XYZ-forge/issues/23)
### Queue / parked intake
- **GH-57 · test(releases): SQLite ledger fuzzing recipes & multi-scenario resilience suite** 🚧 **built 2026-08-19** — synthetic fuzzing recipes and edge-case scenario coverage in `test/gh57-releases-fuzz.sh` (42/42 assertions) for concurrent branch divergence, multi-generation merge headers, duplicate settings/GID collisions, crash injection & journal recovery at 5 boundaries, common-dir lock contention, torn dump protection, and Markdown drift; evaluated non-interactive model routing across Muse Spark, Qwen 3.8-Max, GLM-5.2, and Codex. → [GH-57-RELEASES-SQLITE-FUZZING.md](PROJECT/2-WORKING/GH-57-RELEASES-SQLITE-FUZZING.md) · [#57](https://github.com/HiQS-Suite/XYZ-forge/issues/57)
- **GH-45 · validate.sh must refuse to run from a linked worktree — an observed run corrupted the parent clone** ✅ **BUILT 2026-08-18 on `development` (clone `XYZ-forge-gh35`)** — `validate.sh` AND `ci-local.sh` now refuse (exit 2, before anything runs, every tier) when invoked from a linked git worktree, using the issue's verified `--absolute-git-dir` vs `--git-common-dir` comparison anchored on both HERE and the CWD. The refusal names the observed 2026-08-19 damage (core.bare=true, origin repointed, remote refs deleted, development overwritten with fixture commits); `XYZ_ALLOW_WORKTREE_GATE=1` overrides and announces itself. Pinned in `test/gh35-test-tiers.sh` §9 incl. the required control (normal checkout of the same repo still runs, silently). → [GH-45-WORKTREE-GATE-REFUSAL.md](PROJECT/2-WORKING/GH-45-WORKTREE-GATE-REFUSAL.md) · [#45](https://github.com/HiQS-Suite/XYZ-forge/issues/45) · [#564](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/564)
- **GH-35 · 3-tier test suite selection (docs / utility subsystems / core) + CPU governance** 🚧 **Phases 1+2 BUILT 2026-08-18 on `development` (standalone clone `XYZ-forge-gh35`)** — one fail-closed subsystem registry in `utils/ci-route.sh` (hq, releases, telemetry, ate, swe-diagram, pdda, agent2agent) consumed by `githooks/pre-push` and `validate.sh`; `--tier/--subsystem/--auto/--paths-file`; the parallel default rebalanced from `cores-2` (up to 8) to `cores/2` (cap 4) with every worker under `nice -n 10`, plus `--throttle`/`--burst`/`XYZ_VALIDATE_THROTTLE`/`XYZ_VALIDATE_MAX_JOBS`. Utility pushes drop from the full ~4-min pool to their focused suites (~20-45s target, measurement owed). New suite `test/gh35-test-tiers.sh` 56/0; pre-push suite extended to 85/0. Phase 3 (CI alignment + every-file-classified sweep) pending. → [GH-35-TEST-TIER-ROUTING.md](PROJECT/2-WORKING/GH-35-TEST-TIER-ROUTING.md) · [#35](https://github.com/HiQS-Suite/XYZ-forge/issues/35)
- **GH-39 · RELEASES app: one-way GitHub Project release-card projection** 🚧 **built 2026-08-18, awaiting review** — explicit `project sync` dry-run/apply writer maps every ledger release by immutable Release ID, refuses mismatched Project schema, and keeps GitHub cards read-only from the ledger’s perspective. → [GH-39-RELEASES-PROJECT-SYNC.md](PROJECT/2-WORKING/GH-39-RELEASES-PROJECT-SYNC.md) · [#39](https://github.com/HiQS-Suite/XYZ-forge/issues/39)
- **GH-42 · relay automation: supported Commandcode turn-taker** 🚧 **active 2026-08-18** — add a Python-authoritative, containment-preserving Commandcode adapter with mocked regression coverage; Muse Spark Contributor is the initial builder and Codex performs independent QA. → [GH-42-COMMANDCODE-TURN.md](PROJECT/2-WORKING/GH-42-COMMANDCODE-TURN.md) · [#42](https://github.com/HiQS-Suite/XYZ-forge/issues/42)
- **GH-32 · RELEASES app: SQLite-backed release ledger, CLI-only writes, generated RELEASES.md, cross-repo UI** 🚧 **Phase 0+1 BUILT and merged 2026-08-19 (PR #34, builder GLM 5.3 per the #33 evaluation)** — schema/CLI/writer-protocol/canonical-dump/import landed (`utils/py/releases_app.py`, suite 81/0, full gate green, independently verified); the PRD survived a 4-round Codex sol-high relay review first. Still ahead: the `/releases` route migration (Phase 0 entry gate for the measured dogfood window), the Phase 2 strict flip, and the Phase 3 cockpit card. → [GH-32-RELEASES-APP-SQLITE.md](PROJECT/1-INBOX/GH-32-RELEASES-APP-SQLITE.md) · [#32](https://github.com/HiQS-Suite/XYZ-forge/issues/32) · [#33](https://github.com/HiQS-Suite/XYZ-forge/issues/33)
- **GH-28 · RELEASES.md ledger discipline: deterministic bloat checks + per-release tracking issue** 🆕 **queued 2026-08-18, sharpened via /consult (single-model, agy quota-failed) 2026-08-18, post-Ballast 0.7.0 follow-up** — root cause is two gaps: the discipline rubric only fires on manual `/releases clean`, and release-level notes have no home of their own. Consult caught that the original plan would've reversed documented "never blocks" policy and that the parser can't see continuation-paragraph bloat at all — both fixed: checks are now permanently advisory, scoped to active/unshipped blocks, with a required parser-folding step. → [GH-28-RELEASES-LEDGER-DISCIPLINE.md](PROJECT/1-INBOX/GH-28-RELEASES-LEDGER-DISCIPLINE.md) · [#28](https://github.com/HiQS-Suite/XYZ-forge/issues/28)
- **GH-17 · SOP for evaluating new agent harnesses and frontier models** 🆕 **queued 2026-08-16** — establish a standardized operating procedure, checklist, and per-harness tracking issue workflow for new harness discovery, isolation, non-interactive execution, and cross-model matrix evaluation. → [GH-17-SOP-HARNESS-MODEL-EVAL.md](PROJECT/1-INBOX/GH-17-SOP-HARNESS-MODEL-EVAL.md) · [#17](https://github.com/HiQS-Suite/XYZ-forge/issues/17)
- **GH-18 · Harness evaluation: Command Code (cmd) and model matrix** 🆕 **queued 2026-08-16** — evaluate Command Code CLI (v1.26.0), PATH resolution, auth, non-interactive `-p` execution, and model review benchmarks with `qwen/qwen3.7-flash` and `qwen/qwen3.8-max`. → [GH-18-COMMANDCODE-EVAL.md](PROJECT/1-INBOX/GH-18-COMMANDCODE-EVAL.md) · [#18](https://github.com/HiQS-Suite/XYZ-forge/issues/18)
### In progress

- **GH-10 · prevent-half of containment: adopt require_fixture across the ~31 (found: 73) unaudited suites + adoption guard + ci-local identity bracket** ⏸️ **CUT from Ballast 0.7.0, 2026-08-17 — a driven marathon escalated after 5 rounds, scope grew from ~31 to 73 suites with zero adopted; invokes the manifest's pre-declared scope-slip contingency (RELEASES.md). Issue stays open; #1's clone-identity bracket is the interim detect-half protection.** — → [GH-10-REQUIRE-FIXTURE-ADOPTION.md](PROJECT/2-WORKING/GH-10-REQUIRE-FIXTURE-ADOPTION.md) · [#10](https://github.com/HiQS-Suite/XYZ-forge/issues/10)
- **GH-1 · suite-wide fixture containment + clone-identity invariant gate** 🆕 **active 2026-08-15 on `gh-1/suite-containment-gate` (public-repo tracker)** — the GH-564 follow-through: the one guarded suite's `require_fixture` moved to a shared `test/lib/fixture-guard.sh` and gained the **resolved-containment** check the GH-567 residual named (the lexical `"$WORK"/*` prefix test accepts `$WORK/../../<real repo>`; `cd`+`pwd -P` collapses traversal and follows symlinks), plus a file variant and an init-missing refusal. The detect-half: `test/lib/clone-identity.sh` snapshots `core.bare`/remotes/local user identity/`HEAD` before the run and asserts it after, wired into `validate.sh` so the ~31 unaudited suites are covered by one bracket even before they adopt the guard — a sandbox escape now fails the run instead of leaving an unattributable clone. New suite `test/gh1-fixture-guard.sh` pins both halves, including the traversal and symlink-escape cases the old check passed. cx/risk/eff 2/2/2. → [GH-1-SUITE-CONTAINMENT-GATE.md](PROJECT/2-WORKING/GH-1-SUITE-CONTAINMENT-GATE.md) · [#1](https://github.com/HiQS-Suite/XYZ-forge/issues/1)
- **GH-5 · kernel robustness: node:test unit runner** 🆕 **active 2026-08-15 on `gh-5/events-quarantine-unit-tests` (public-repo tracker)** — 11 direct unit tests on the built-in `node:test` runner (was 13; the 2 quarantine-dependent tests deferred to #14), zero new dependencies, `npm run test:unit`, `npm test` → `validate.sh` unchanged. The quarantine-in-reader approach was rejected on orchestrator review per the correction on #5 (silent event loss on the concurrent path while writes are non-atomic) and re-routed to #14. **#5 stays open until this PR's tests and #14's atomic write have both landed.** cx/risk/eff 1/2/1. → [GH-5-EVENTS-QUARANTINE-UNIT-TESTS.md](PROJECT/2-WORKING/GH-5-EVENTS-QUARANTINE-UNIT-TESTS.md) · [#5](https://github.com/HiQS-Suite/XYZ-forge/issues/5)
### Completed
- **GH-4 · the pre-push gate does not travel with clones: fresh clones push unverified** ✅ **SHIPPED 2026-08-17, orchestrator-authored directly** — `validate.sh` warns non-fatally when the clone is ungated (verified both directions: fires when ungated, silent when gated); README documents the install step as a correctness requirement. A prior driven-marathon attempt escalated after 5 rounds without landing this (see `test/baselines/GH-4-negative-control.md`'s design note). → [GH-4-GATE-TRAVELS-WITH-CLONES.md](PROJECT/3-COMPLETED/GH-4-GATE-TRAVELS-WITH-CLONES.md) · [#4](https://github.com/HiQS-Suite/XYZ-forge/issues/4)
- **GH-14 · appendEvent writes non-atomically, so concurrent readers can observe torn event files** ✅ **SHIPPED 2026-08-17 (PR #21)** — `appendEvent` writes to a `.tmp` name then `renameSync`s into place; a `.jsonl` file that exists is always complete. `test/gh14-atomic-append.sh` 6/0; negative control `test/baselines/GH-14-negative-control.md` (5/1 pre-fix). Gap: the two `test/unit/events.test.js` cases deferred from PR #7 (quarantine, empty-file skip) were not re-authored; #5 stays open on that gap. → [GH-14-ATOMIC-EVENT-APPEND.md](PROJECT/3-COMPLETED/GH-14-ATOMIC-EVENT-APPEND.md) · [#14](https://github.com/HiQS-Suite/XYZ-forge/issues/14)
- **GH-15 · parallel runs are unreliable in a fresh clone; the GH-528 contention retry is not honoring its contract** ✅ **SHIPPED 2026-08-17 (PR #20 + orchestrator reconciliation)** — `validate.sh`'s parallel retry gives every suite `stdin=/dev/null`, adds a completeness catch-up for suites with no result line, and a tally-integrity guard. `test/gh528-parallel-contention-retry.sh` 9/0; negative control `test/baselines/GH-15-parallel-contention-negative-control.md` (5/4 pre-fix). Ten consecutive parallel fresh-clone runs: 10/10 exit 0, zero failures, zero contention. → [GH-15-PARALLEL-FRESH-CLONE-RELIABILITY.md](PROJECT/3-COMPLETED/GH-15-PARALLEL-FRESH-CLONE-RELIABILITY.md) · [#15](https://github.com/HiQS-Suite/XYZ-forge/issues/15)
- **GH-3 · improve-loop.sh --state-dir durability — provenance evidence must not evaporate** ✅ **SHIPPED 2026-08-17 (closed as landed)** — durable default and path-printing were already landed pre-Ballast (GH-430); the sole remaining gap, a recorded negative control, closed 2026-08-17 (`test/baselines/GH-3-state-dir-negative-control.md`, 6/2 pre-fix → 8/0 post-fix). → [GH-3-IMPROVE-LOOP-STATE-DIR.md](PROJECT/3-COMPLETED/GH-3-IMPROVE-LOOP-STATE-DIR.md) · [#3](https://github.com/HiQS-Suite/XYZ-forge/issues/3)
### Deferred · vision

*(empty since the 2026-08-19 purge — its one entry was upstream-numbered; see
[docs/ROADMAP-UPSTREAM-ARCHIVE.md](docs/ROADMAP-UPSTREAM-ARCHIVE.md). The heading stays because the
planner's `SECTIONS` list names it.)*

## Entry format

**This section documents the contract the marathon planner already enforces. It does not introduce
one.** It exists because all three sibling repos (`rebalanceOS`, `sleuth-app`,
`aegis-sleuth-slack-bot`) carry an `## Entry format` section and this repo — which *owns* the
planner — did not, so the rule lived only in downstream copies. See
[#69](https://github.com/HiQS-Suite/XYZ-forge/issues/69).

One flat bullet per item, name in **bold**:

```
- **Project / track name** — one-line status summary. → [linked doc](PROJECT/...)
```

The bold name is required, not cosmetic. The planner (`utils/py/_marathon_plan.py`, and its frozen
Bash twin `utils/marathon-plan.sh`) recognises a ledger entry only when it matches `^- \*\*`, and
only under one of these four `###` headings, spelled exactly:

| Recognised `###` heading |
|---|
| `Queue / parked intake` |
| `In progress` |
| `Completed` |
| `Deferred · vision` |

Source of truth for that list: `utils/py/_marathon_plan.py:31` (`SECTIONS`) and
`utils/marathon-plan.sh:232`.

**Entries anywhere else are skipped silently** — the planner reports `no ledger items parsed` and
writes no plan, with nothing naming what it passed over.

### What that currently means here

`### Ad-hoc detours` is **not** in the recognised list, so its one remaining entry (GH-23; the
other three were upstream-numbered and left with the 2026-08-19 purge) is invisible to the
planner. Whether that is intended — a detour arguably should not be marathon-plannable — has never
been written down either way. It is recorded here as an observation, not changed: renaming the
heading would silently make those items plannable, which is a decision for the owner and not a
formatting fix. Tracked on [#69](https://github.com/HiQS-Suite/XYZ-forge/issues/69).

Bullets above `## Ledger` (the Part A/B/C lines under `## Status`) are narrative, sit outside the
ledger, and are correctly not parsed.
