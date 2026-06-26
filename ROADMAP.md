---
title: Combined Roadmap — Cost-Observed Marathon Loops + Adversarial Hardening
status: Active
created: 2026-06-16
updated: 2026-06-25
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
| **Part A harness build complete** — cost foundation, headless build→review→chain harness, and worktree-isolation containment all shipped + E2E-validated. **Part B Phase 1 — epoch fencing** shipped 2026-06-18. Recent tooling ships: **GH-21** relay quality gate (`validate.sh` 46/46), **GH-20** agy first-class doc parity, **GH-18** cross-repo relay friction fixes — all 2026-06-24/25. | **Part A Phase 6 (graduation dogfood) re-substrated → WPCC TS-lite, pre-registered, awaiting operator GO to fire** — after two substrate starvations (WPCC backlog + Sleuth both hand-built first), a WPCC discovery pass found a genuinely-unbuilt maintainer-wanted target (WPCC #129 `ts-type-suppression`). Also live: **Part B Phase 2 — chaos suite & auto-recovery**. |

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
- **GH-24 · relay telemetry extractor** 🟢 — **built 2026-06-25** (`7331c87` feat + `4142158` fix): on-demand ETL script `utils/telemetry/extract-relay-telemetry.sh` reads `relay-system/<date>/*.md` for a configurable `--from`/`--to` range and outputs `relay-system/combined/aggregated-FROM-to-TO.json` matching the focus5float stoplight schema `{ health, title, description, updatedAt }` (health from STATUS: + VERDICT:). Fix added no-heading handling + full-range aggregated output; demo feed `focus5float-demo.json` committed (`06baca3`). Remaining: validate against live `relay-system/` + close #24. → [GH-24-RELAY-TELEMETRY-EXTRACTOR.md](PROJECT/1-INBOX/GH-24-RELAY-TELEMETRY-EXTRACTOR.md) · [#24](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/24)
- **GH-22 · agy worktree isolation silent data loss** ⏸️ parked — bug confirmed 2026-06-25: when `RELAY_WORKTREE_ISOLATION=1` (relay-drive.sh default), agy edits the relay file via the absolute `RELAY_FILE` path (ROOT), but `rtl_worktree_end` copies the stale empty worktree copy back over ROOT, silently discarding output (exit 0, task shows done, relay file blank). Workaround: `RELAY_WORKTREE_ISOLATION=0`. Fix direction: rewrite relay file path to CWD-relative in `agy-turn.sh` so agy writes into the worktree. → [GH-22-AGY-WORKTREE-ISOLATION-DATA-LOSS.md](PROJECT/1-INBOX/GH-22-AGY-WORKTREE-ISOLATION-DATA-LOSS.md) · [#22](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/22)
- **GH-19 · relay-xyz skill-skip durability** 🟢 — **built + locally verified 2026-06-24**: closes the recurring failure where a session improvises a relay handoff instead of invoking the relay-xyz skill (a behavioral skip — the skill loads, the agent never opens it). Deterministic `PreToolUse` guard ([relay-automation/hooks/relay-xyz-guard.sh](relay-automation/hooks/relay-xyz-guard.sh)) wired in `.claude/settings.json` blocks executing a `relay-automation/` driver before the skill is loaded; proof-of-load from a `Skill` invocation or `find-harness.sh`; session-scoped, fail-open, high-precision. Plus a ROUTER routing rail + regression test → **`validate.sh` 45/45**; guard confirmed **live in-session** (blocked a real `relay-drive.sh` call). [#19](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/19) filed. Remaining: promote to `2-WORKING` or close after a fresh session confirms an organic catch. → [GH-19-RELAY-XYZ-SKILL-GUARD.md](PROJECT/1-INBOX/GH-19-RELAY-XYZ-SKILL-GUARD.md)
- **Tooling · agy reliability testing** ⏸️ parked — proposal + 3 dogfoods this session: agy **clean as a reviewer** (×2), **scope-sensitive as a builder** (failed a kernel-spanning task → F4/F6/F7 contained; succeeded on a small bounded one). Resume to run the S1–S10 matrix. → [AGY-RELIABILITY-TESTING.md](PROJECT/1-INBOX/AGY-RELIABILITY-TESTING.md)
- **Tooling · front-door onboarding health** 🟡 parked — read-only audit shipped → [FRONTDOOR.md](FRONTDOOR.md) (continuous deterministic dashboard; 10 findings, re-runnable checks) + a phased remediation plan. Verdict ⚠️ Bumpy: clone-to-working works (`validate.sh` 36/36, secrets clean), but stale test counts (3 docs) + 2 dead README links + a phantom-path `CLAUDE.md` + undocumented `--target-root`/`install.sh` remain. Phases 1–3 queued (doc-only). → [FRONT-DOOR/2026-06-22.md](PROJECT/1-INBOX/FRONT-DOOR/2026-06-22.md)
- **PDDA · feedback-synthesis direction** 🟡 parked — **proposal (1-INBOX), agy-reviewed 2026-06-23**: reduces the three June 23 external feedback notes (Perplexity/ChatGPT/Gemini) to one direction — keep PDDA a *thin repo-governance + safety layer*. Near-term scope = Phases 1–2 (constitution/positioning + contract/mode hardening); Phases 3–5 (artifact ergonomics, the Perplexity-only evidence bridge, integrations) deferred. Relay-reviewed by agy: 1 Blocker + 3 Should applied → **Approved**. Awaiting promotion decision to `2-WORKING`. → [PDDA-FEEDBACK-SYNTHESIS-PLAN.md](PROJECT/1-INBOX/PDDA/PDDA-FEEDBACK-SYNTHESIS-PLAN.md) · relay [pdda-feedback-synthesis.md](relay-system/2026-06-23/pdda-feedback-synthesis.md)

### In progress

- **GH-25 · swarm preflight planner** 🟢 — **active (started 2026-06-25)**: `utils/swarm-preflight.sh` implemented on branch `gh-25-swarm-preflight` (Phases 1–6 + regression lock; `validate.sh` 47/47). One durable intake/preflight entrypoint that turns either a `PROJECT/2-WORKING` plan doc or an explicit bundle of GitHub issues into a marathon-ready run packet: deterministic candidate/freshness checks, "fix still required" validation, remediation-readiness gate, and Codex-vs-agy lane assignment; reuses the existing marathon/relay runtime instead of creating a second control plane. Remaining: agy relay review of the final script before merge. → [GH-25-SWARM-PREFLIGHT-PLANNER.md](PROJECT/2-WORKING/GH-25-SWARM-PREFLIGHT-PLANNER.md) · [#25](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/25)
- **Part A · Phase 6 — real-substrate dogfood (graduation test)** 🟢 **re-substrated 2026-06-25 → WPCC TS-lite (pre-registered, awaiting fire)**: after **two substrate starvations** (WPCC's old backlog shipped by 2026-06-24; Sleuth Near-Miss 2-lite hand-shipped in sleuth-app `77a95a7` on **the same day** it was pre-registered — re-verified 2026-06-25), the operator chose a **WPCC discovery pass**. Discovery on the **freshest** WPCC branch (`origin/development` @ 2026-06-18, not stale `main`) found a genuinely-unbuilt, maintainer-wanted target: the first "lite" slice of **WPCC issue #129** — a new grep detector `ts-type-suppression` (flags `@ts-ignore`/`@ts-nocheck`/bare `@ts-expect-error`; advisory, `.ts`/`.tsx`-scoped, additive). Gate designed **narrow** (new fixture only) because WPCC's full `run-fixture-tests.sh` is 7/10 red at baseline for unrelated reasons. **Phase 0 pre-registered; awaiting operator GO to fire** (agy builder + Codex reviewer, `--target-root WP-Code-Check`, worktree isolation). → [MARATHON-DOGFOOD-2026-06-25-WPCC-TS-TYPE-SUPPRESSION.md](PROJECT/2-WORKING/MARATHON-DOGFOOD-2026-06-25-WPCC-TS-TYPE-SUPPRESSION.md) · brief: [wpcc-ts-type-suppression-brief.md](PROJECT/2-WORKING/briefs/wpcc-ts-type-suppression-brief.md) · retired substrates: [Sleuth](PROJECT/2-WORKING/MARATHON-DOGFOOD-2026-06-24-SLEUTH-NEARMISS-2LITE.md) ([brief](PROJECT/2-WORKING/briefs/sleuth-near-miss-2lite-brief.md)) · [WPCC-old](PROJECT/2-WORKING/MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md)
- **Part B — Adversarial hardening** ⚠️ — Phase 1 (epoch fencing) shipped; Phase 2 chaos-suite *detection* partials landed; Phases 2–4 are the active "adversarially proven → commercially viable" frontier. → [ADVERSARIAL-HARDENING.md](PROJECT/2-WORKING/ADVERSARIAL-HARDENING.md)
- **Tooling · relay-to-issue skill** 🟢 — **shipped 2026-06-22**: a post-relay skill that distills a closed `/relay` thread into ONE checklist-style GitHub issue, filed in the repo the relay was *about* (cross-repo aware; dedup-stamped; auto-posts via `gh`). `skills/relay-to-issue/` (SKILL + `relay-to-issue.sh` + `install.sh`); `resolve` smoke-tested green. Remaining: operator `install.sh` + one un-sandboxed live `gh issue create` to confirm posting E2E. → [RELAY-TO-ISSUE-SKILL.md](PROJECT/2-WORKING/RELAY-TO-ISSUE-SKILL.md)
- **Tooling · relay-xyz durability** 🟢 — **shipped 2026-06-21** (regression-tested, pushed): discovery audit via the shakedown lens (locator proven green; symlink-only discovery → `skills/relay-xyz/install.sh`) + drive-layer fixes from a sibling headless run (space-safe `--agent-cmd` dispatch; worktree isolation default-ON for driven runs). Both dangling `consult`/`wpcc` symlinks since repaired (see Completed → *install hygiene* 2026-06-22). Remaining: optional role-vs-model assertion + per-run `RELAY-TURN` id. → [RELAY-XYZ-DISCOVERY-SHAKEDOWN.md](PROJECT/2-WORKING/RELAY-XYZ-DISCOVERY-SHAKEDOWN.md)
- **GH-11 · relay-xyz cross-repo targeting** 🟢 — **Ask 1 complete**: `--target-root` flag + kernel wiring (`relay-turn-lib.sh` routes worktree/allowlist/commit via `RELAY_TARGET_ROOT`; default unchanged) + Codex's `[Nit]` fixed, proven by `test/relay-target-root.sh` in the suite (**`validate.sh` 36/36**). Remaining: Asks 2–5 (surface consult + doc fixes). → [GH-11-CROSS-REPO-TARGETING.md](PROJECT/2-WORKING/GH-11-CROSS-REPO-TARGETING.md)
- **Tooling · relay containment-guard hardening** 🟢 — **active (started 2026-06-23)**: harden `relay-turn-lib.sh` so a headless turn can't destroy work — the commit-bypass guard must not orphan a **concurrent peer commit** ([#13](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/13)) and the turn agent must not **self-commit** mid-turn ([#14](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/14)). Both surfaced 2026-06-23 when a driven agy re-review orphaned a peer's commit (recovered via reflog). → [RELAY-CONTAINMENT-HARDENING.md](PROJECT/2-WORKING/RELAY-CONTAINMENT-HARDENING.md)
- **GH-16 · same-device cross-repo swarm readiness** 🟢 — **active (started 2026-06-24)**: umbrella epic to drive a multi-lane swarm against an external target repo on macOS, same-device, without the harness reverting its own output. Sequences the new Phase-1 macOS case-sensitivity revert ([#17](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/17)) plus existing cross-repo/isolation/concurrency issues (#11, #13, #15, #3, #4, #5; #12 closed). → [GH-16-CROSS-REPO-SWARM.md](PROJECT/2-WORKING/GH-16-CROSS-REPO-SWARM.md)

### Completed

- **GH-20 · agy first-class footing in live relay docs** ✅ 2026-06-25 — doc-only parity pass shipped (`4ff8e4c`): the live relay entry points (root [README.md](README.md), [relay-automation/README.md](relay-automation/README.md), both relay skills, harness-locator labels, front-door dashboard, automated-relay hub) now present **Codex and agy as co-equal Path-A workers** wherever the runtime supports both, while keeping the real auth/sandbox/cost-blindness asymmetries explicit. `test/codex-turn.sh` 27/27, `test/agy-turn.sh` 22/22, `validate.sh` 45/45. Issue [#20](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/20) closed; doc archived. → [GH-20-AGY-FIRST-CLASS-FOOTING.md](PROJECT/3-COMPLETED/GH-20-AGY-FIRST-CLASS-FOOTING.md)
- **GH-18 · cross-repo driven-relay friction** ✅ 2026-06-24, agy-approved — field-validated punch-list from a real cross-repo Codex review (thread/artifact in `rebalance-OS`, harness here via `--target-root`). Phase 0 verification reproduced #1/#2/#5 as real code bugs; #3 (foreign `.tick`) found **largely stale** for driven runs (mitigated by [codex-turn.sh:57](relay-automation/codex-turn.sh#L57)) → doc-only; #4 doc-only. Phase 2 code (`7709abc`): **#2** repo-relative `--relay-file` resolved under `--target-root`, **#1b** token-collision hints in `bin/tick` + `relay-drive.sh` (default unchanged), **#5** `STATUS: Escalated` now terminal-by-design (exit 4, not the stall's exit 3) — 3 new tests, **`validate.sh` 41→44/44**; agy headless review **Approved** (3×[Pass], confirmed #5 doesn't mask a true stall). Child of GH-16; issue #18 closed, doc archived. → [GH-18-CROSS-REPO-RELAY-FRICTION.md](PROJECT/3-COMPLETED/GH-18-CROSS-REPO-RELAY-FRICTION.md) · [#18](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/18)
- **GH-21 · relay quality gate — independent post-generation validator** ✅ 2026-06-25 — three phases shipped: (1) `bin/validate-relay-block` hooked into `bin/tick release`/`done` + `exit 8`; (2) `test/relay-self-sufficiency.sh` self-sufficiency test for the TAKE YOUR TURN block; (3) `--consult-verify` flag on `relay-drive.sh` wiring `consult.sh` (codex + gemini) as an independent post-turn challenger. All 46/46 validate.sh. Process finding: agy cannot complete code-write relay turns in headless mode (see GH-22 backlog candidate). → [GH-21-RELAY-QUALITY-GATE.md](PROJECT/2-WORKING/GH-21-RELAY-QUALITY-GATE.md) · [#21](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/21)
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
