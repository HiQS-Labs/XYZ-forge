---
title: Combined Roadmap — Cost-Observed Marathon Loops + Adversarial Hardening
status: Active
created: 2026-06-16
updated: 2026-06-24
branch: main
supersedes: PROJECT/2-WORKING/ROADMAP-COMBINED.md (promoted to canonical 2026-06-17); folds in the former standalone ROADMAP.md (adversarial-hardening track, now Part B)
synthesizes:
  - PROJECT/1-INBOX/LOOPS.md
  - PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md
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
     Enforced by utils/pdda-check-roadmap.sh + utils/pdda-check-roadmap-coverage.sh (deterministic) + utils/pdda-doc-ready.sh ROADMAP rubric (LLM). -->

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

### Queue / parked intake

- **Tooling · agy reliability testing** ⏸️ parked — proposal + 3 dogfoods this session: agy **clean as a reviewer** (×2), **scope-sensitive as a builder** (failed a kernel-spanning task → F4/F6/F7 contained; succeeded on a small bounded one). Resume to run the S1–S10 matrix. → [AGY-RELIABILITY-TESTING.md](PROJECT/1-INBOX/AGY-RELIABILITY-TESTING.md)
- **Tooling · front-door onboarding health** 🟡 parked — read-only audit shipped → [FRONTDOOR.md](FRONTDOOR.md) (continuous deterministic dashboard; 10 findings, re-runnable checks) + a phased remediation plan. Verdict ⚠️ Bumpy: clone-to-working works (`validate.sh` 36/36, secrets clean), but stale test counts (3 docs) + 2 dead README links + a phantom-path `CLAUDE.md` + undocumented `--target-root`/`install.sh` remain. Phases 1–3 queued (doc-only). → [FRONT-DOOR/2026-06-22.md](PROJECT/1-INBOX/FRONT-DOOR/2026-06-22.md)
- **PDDA · feedback-synthesis direction** 🟡 parked — **proposal (1-INBOX), agy-reviewed 2026-06-23**: reduces the three June 23 external feedback notes (Perplexity/ChatGPT/Gemini) to one direction — keep PDDA a *thin repo-governance + safety layer*. Near-term scope = Phases 1–2 (constitution/positioning + contract/mode hardening); Phases 3–5 (artifact ergonomics, the Perplexity-only evidence bridge, integrations) deferred. Relay-reviewed by agy: 1 Blocker + 3 Should applied → **Approved**. Awaiting promotion decision to `2-WORKING`. → [PDDA-FEEDBACK-SYNTHESIS-PLAN.md](PROJECT/1-INBOX/PDDA/PDDA-FEEDBACK-SYNTHESIS-PLAN.md) · relay [pdda-feedback-synthesis.md](relay-system/2026-06-23/pdda-feedback-synthesis.md)

### In progress

- **Part A · Phase 6 — real-substrate dogfood (graduation test)** 🟢 — **re-substrated 2026-06-24**: WPCC retired (its documented backlog was already shipped — preflight found all target rules built/fixed). New substrate = `sleuth-app` **Near-Miss 2-lite** (confirmed unbuilt, additive + flag-gated + default-OFF). Phase 0 pre-registered: branch cut, gate baseline captured (validate ✓ / jest 134/0), workers green (Codex + agy). Build now, default-OFF (operator). → [MARATHON-DOGFOOD-2026-06-24-SLEUTH-NEARMISS-2LITE.md](PROJECT/2-WORKING/MARATHON-DOGFOOD-2026-06-24-SLEUTH-NEARMISS-2LITE.md) · build spec: [sleuth-near-miss-2lite-brief.md](PROJECT/2-WORKING/briefs/sleuth-near-miss-2lite-brief.md) · WPCC retired-substrate record: [MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md](PROJECT/2-WORKING/MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md)
- **Part B — Adversarial hardening** ⚠️ — Phase 1 (epoch fencing) shipped; Phase 2 chaos-suite *detection* partials landed; Phases 2–4 are the active "adversarially proven → commercially viable" frontier. → [ADVERSARIAL-HARDENING.md](PROJECT/2-WORKING/ADVERSARIAL-HARDENING.md)
- **Tooling · relay-to-issue skill** 🟢 — **shipped 2026-06-22**: a post-relay skill that distills a closed `/relay` thread into ONE checklist-style GitHub issue, filed in the repo the relay was *about* (cross-repo aware; dedup-stamped; auto-posts via `gh`). `skills/relay-to-issue/` (SKILL + `relay-to-issue.sh` + `install.sh`); `resolve` smoke-tested green. Remaining: operator `install.sh` + one un-sandboxed live `gh issue create` to confirm posting E2E. → [RELAY-TO-ISSUE-SKILL.md](PROJECT/2-WORKING/RELAY-TO-ISSUE-SKILL.md)
- **Tooling · relay-xyz durability** 🟢 — **shipped 2026-06-21** (regression-tested, pushed): discovery audit via the shakedown lens (locator proven green; symlink-only discovery → `skills/relay-xyz/install.sh`) + drive-layer fixes from a sibling headless run (space-safe `--agent-cmd` dispatch; worktree isolation default-ON for driven runs). Remaining: operator sign-off on the two dangling `consult`/`wpcc` symlinks; optional role-vs-model assertion + per-run `RELAY-TURN` id. → [RELAY-XYZ-DISCOVERY-SHAKEDOWN.md](PROJECT/2-WORKING/RELAY-XYZ-DISCOVERY-SHAKEDOWN.md)
- **GH-11 · relay-xyz cross-repo targeting** 🟢 — **Ask 1 complete**: `--target-root` flag + kernel wiring (`relay-turn-lib.sh` routes worktree/allowlist/commit via `RELAY_TARGET_ROOT`; default unchanged) + Codex's `[Nit]` fixed, proven by `test/relay-target-root.sh` in the suite (**`validate.sh` 36/36**). Remaining: Asks 2–5 (surface consult + doc fixes). → [GH-11-CROSS-REPO-TARGETING.md](PROJECT/2-WORKING/GH-11-CROSS-REPO-TARGETING.md)
- **Tooling · relay containment-guard hardening** 🟢 — **active (started 2026-06-23)**: harden `relay-turn-lib.sh` so a headless turn can't destroy work — the commit-bypass guard must not orphan a **concurrent peer commit** ([#13](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/13)) and the turn agent must not **self-commit** mid-turn ([#14](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/14)). Both surfaced 2026-06-23 when a driven agy re-review orphaned a peer's commit (recovered via reflog). → [RELAY-CONTAINMENT-HARDENING.md](PROJECT/2-WORKING/RELAY-CONTAINMENT-HARDENING.md)
- **GH-18 · cross-repo driven-relay friction** ✅ — **shipped 2026-06-24, agy-approved**: field-validated punch-list from a real cross-repo Codex review (thread/artifact in `rebalance-OS`, harness here via `--target-root`). Phase 0 verification reproduced #1/#2/#5 as real code bugs; #3 (foreign `.tick`) found **largely stale** for driven runs (mitigated by [codex-turn.sh:57](relay-automation/codex-turn.sh#L57)) → doc-only; #4 doc-only. Phase 1 docs (QUICKSTART: per-relay token id + cross-repo recipe). Phase 2 code (`7709abc`): **#2** repo-relative `--relay-file` resolved under `--target-root`, **#1b** token-collision hints in `bin/tick` + `relay-drive.sh` (default unchanged), **#5** `STATUS: Escalated` now terminal-by-design (exit 4, not the stall's exit 3) — 3 new tests, **`validate.sh` 41→44/44**; agy headless review **Approved** (3×[Pass], confirmed #5 doesn't mask a true stall). Child of GH-16. → [GH-18-CROSS-REPO-RELAY-FRICTION.md](PROJECT/2-WORKING/GH-18-CROSS-REPO-RELAY-FRICTION.md) · [#18](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/18)
- **GH-16 · same-device cross-repo swarm readiness** 🟢 — **active (started 2026-06-24)**: umbrella epic to drive a multi-lane swarm against an external target repo on macOS, same-device, without the harness reverting its own output. Sequences the new Phase-1 macOS case-sensitivity revert ([#17](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/17)) plus existing cross-repo/isolation/concurrency issues (#11, #13, #15, #3, #4, #5; #12 closed). → [GH-16-CROSS-REPO-SWARM.md](PROJECT/2-WORKING/GH-16-CROSS-REPO-SWARM.md)

### Completed

- **Part A · Phase 1 — Cost observability foundation** ✅ 2026-06-16 — deterministic token / wall-clock / human-minute capture in `tick analyze`. → [COST-OBSERVABILITY-PLAN.md](PROJECT/2-WORKING/COST-OBSERVABILITY-PLAN.md)
- **Part A · Phases 2–4 — Marathon harness build** ✅ 2026-06-17/18 — dispatcher + headless single-phase loop + autonomous-builder containment + multi-phase `MARATHON.yaml` chaining (M6/M7 deferred). → [MARATHON-HARNESS.md](PROJECT/3-COMPLETED/MARATHON-HARNESS.md)
- **Part A · Phase 5 — Cross-system cost comparison** ✅ 2026-06-16 — xyz vs relay, every cell from `tick analyze --format json`. → [COST-COMPARISON.md](PROJECT/2-WORKING/COST-COMPARISON.md)
- **Part B · Phase 1 — Epoch fencing & stale-writer prevention** ✅ 2026-06-18 — monotonic per-task epoch fences zombie writers in the projection kernel. → [ADVERSARIAL-HARDENING.md](PROJECT/2-WORKING/ADVERSARIAL-HARDENING.md#phase-1--epoch-fencing--stale-writer-prevention-r1--g3) · [decision record](decisions/2026-06-18-epoch-fencing.md)
- **Tooling · Automated /relay loop** ✅ 2026-06-15 — Producer↔Reviewer relay that runs hands-free (all-Claude) or one-line-nudge (cross-model), self-heals on stalls (watchdog), and terminates on `Approved`; shipped + packaged as a sibling skill (Phases 1–5, `validate.sh` 20/20). Kept in `2-WORKING` as a completion hub. → [AUTOMATED-RELAY.md](PROJECT/2-WORKING/AUTOMATED-RELAY.md)
- **Tooling · relay-xyz install hygiene** ✅ 2026-06-22 — both dangling user-skill symlinks repaired (operator-signed-off): `consult` → `skills/consult` (was the singular-`skill/` typo) and `wpcc` → `…/wp-code-check/skills/wpcc` (the clone is now present at that path; symlink target was already correct). Both resolve to their `SKILL.md` ✓. → [RELAY-XYZ-DISCOVERY-SHAKEDOWN.md](PROJECT/2-WORKING/RELAY-XYZ-DISCOVERY-SHAKEDOWN.md)

### Deferred · vision

- **Part C — Autonomous self-improvement loop** 🔮 gated — the LOOPS.md endgame; gated on the metric / oracle / stop-condition prerequisites (safety cage already shipped). → [AUTONOMOUS-SELF-IMPROVEMENT-LOOP.md](PROJECT/1-INBOX/AUTONOMOUS-SELF-IMPROVEMENT-LOOP.md)
- **Part A · Phase 4 — M6 / M7** 🔲 deferred — cross-phase context injection + state projection, until a phase genuinely needs them. → [MARATHON-HARNESS.md → Deferred](PROJECT/3-COMPLETED/MARATHON-HARNESS.md#deferred--m6--m7)

---

*Detail for every entry lives in its linked `PROJECT/**` doc. Part B gaps also map to `4X4.md`; any
event-schema change gets a decision record under `decisions/` before it lands.*
