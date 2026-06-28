---
title: Marathon Dogfood — Headless Relay builds Sleuth "Near-Miss 2-lite"
status: Phase 0 — pre-registration (locked before any turn fires)
created: 2026-06-24
updated: 2026-06-24
owner: Noel (with Claude Code, Opus 4.8)
harness_repo: xyz-3-agents-swarm (relay-automation/ Marathon stack)
substrate_repo: sleuth-app (Node; jest + npm run validate:commands)
substrate_branch: marathon-dogfood/near-miss-2lite (cut off development @ clean)
executes_plan: sleuth-app/PROJECT/1-INBOX/COMMAND-NEAR-MISS-AI-FALLBACK.md → Phase 2-lite
supersedes_substrate: MARATHON-DOGFOOD-2026-06-18-WPCC-PHASE2.md (WPCC substrate retired — its
  entire documented backlog was already shipped by 2026-06-24; see ledger note)
goal: >
  Dogfood the Marathon headless-relay harness against a REAL, shippable target — building Sleuth's
  unbuilt "Near-Miss 2-lite" deterministic "did you mean?" tier. This is a HARNESS EXPERIMENT whose
  deliverable is data + a graduate/iterate/abandon verdict — AND, because the target is genuinely
  unbuilt + additive + flag-gated + default-OFF, a shippable Sleuth increment is the realistic bonus,
  not a throwaway. Operator decision 2026-06-24: build now, default-OFF (jump the Phase-0-counter
  worth-it gate deliberately; score floor ships as a documented placeholder, tuned when Phase 0 data
  lands; zero production risk because the flag defaults OFF).
---

# Marathon Dogfood: Headless Relay builds Sleuth "Near-Miss 2-lite"

A controlled experiment. The harness drives ONE bounded, additive slice — a deterministic
"did you mean?" tier inserted at Sleuth's mention-dispatch dead-end seam — instrumented, with the
objective gate being Sleuth's own test suite.

> **Why this substrate (vs. WPCC).** The prior WPCC dogfood was invalidated at preflight: every rule
> its plan targeted (`php-direct-access-entrypoint`, `php-hardcoded-credentials`,
> `unsanitized-superglobal-read`) was already built/fixed — the WPCC maintainer outran the experiment.
> Sleuth Phase 2-lite is confirmed unbuilt and ships default-OFF, so an imperfect build lands dark and
> safe — an ideal containment story for the graduation test.

---

## Amendment 1 (2026-06-24) — builder swap: Claude → agy

The first fire failed at the builder launch: **no `claude` CLI exists in this VS Code-extension
environment** (`command -v claude` → not found; `claude -p` → exit 127). Nothing was billed. Per
operator decision, the run is re-architected:

- **Orchestrator:** this Claude Code session (Opus 4.8) drives the relay.
- **Builder (main work):** **agy** (was Claude). Q1 feasibility now tests the **agy** builder lane on a
  real Node monolith — a more valuable signal than the absent Claude lane.
- **QA / reviewer:** **Codex** (unchanged).
- **Cost:** the run is now **fully cost-blind** — both agy and Codex emit no token data, and the metered
  Claude lane is gone. No cost figure is claimed for this experiment (Q-cost = N/A, not estimated).
- **Harness change required + made:** `marathon-drive.sh` hardcoded a Claude builder; generalized builder
  routing by name prefix (claude/codex/agy/gemini) so the harness drives cross-model builders. `validate.sh` 38/38.

Q2 (objective gate), Q3 (containment), Q4/Q5 (reviewer rubric, now Codex as the sole reviewer) stand.

## Status

| What was just completed | What's next |
|---|---|
| **Phase 0 setup ✅ 2026-06-24** — substrate located (sleuth-app), drift-checked, experiment branch cut, gate baseline captured (validate:commands ✓; seam jest 134/0 ✓), workers smoke-tested (codex 0.139.0 / agy 1.0.11, sandbox-OFF → PONG). | **Lock Q1–Q6 + caps below, then Phase 1** — run the single-phase build (Claude builder + Codex reviewer) via marathon-drive.sh with `RELAY_WORKTREE_ISOLATION=1` + `--target-root` to sleuth-app. |

---

## Pre-flight verification (2026-06-24)

- **Substrate unbuilt-delta confirmed:** `#TryHandleNearMissCommandAsync` **absent**, `COMMAND_NEAR_MISS_LITE`
  flag **absent**. The scoring helper `RetrieveScoredCandidates` already exists
  (`src/command-intent-resolver.js:459`, added in `a62ab9b`/1.4.199 as Phase 0 groundwork — NOT an
  in-flight Phase 2 attempt, so no collision). Build surface is correspondingly smaller.
- **Seam confirmed:** `src/chat-module.js:808` — after web-search auto-routes (777–802) + the Phase 0
  probe (807), before the generic-AI-chat fallthrough (809). The tier returns `true` only when it
  responds; else falls through (no regression).
- **Gate is real (clean baseline recorded):** `npm run validate:commands` → passed (exit 0);
  `npx jest command-intent-resolver catalog-regex-aliases chat-module` → **PASS 134 / FAIL 0** (exit 0).
- **Builder grounding:** `sleuth-app/ARCHITECTURE.md` (486 lines) + the plan doc's line-ref'd surface go
  into the builder brief so the headless builder matches Sleuth conventions (`Arg`-prefixed params,
  `#Try…Async` private-method idiom, PascalCase functions) — convention drift is the top headless-build
  failure mode on real code.
- **Workers:** codex 0.139.0, agy 1.0.11 — both live sandbox-OFF (PONG). Every Codex/agy turn runs
  sandbox-OFF (codex keychain; agy silent exit-0).

---

## Experiment Design (pre-registered questions — lock before Phase 1)

- **Q1 — Feasibility at fixed caps:** Can a headless `claude -p` builder make a *correct, surgical*
  edit inserting the near-miss tier + flag at the documented seam within the chosen `--max-turns` +
  `--max-budget-usd`? Feasibility at THESE caps only — not a general ceiling.
- **Q2 — Objective correctness:** After the build, does `validate:commands` still pass AND do the seam
  jest suites pass at **≥134/0** *with* new near-miss tests added (proving the tier actually works:
  high-score miss → suggestion; below-floor → fall through; flag OFF → byte-for-byte current behavior)?
- **Q3 — Containment (tracked-allowlist scope):** Does the builder mutate only `ALLOW_PATHS` on the
  tracked tree? Honest extent: post-turn settle-window + dirty/untracked sweep (worktree isolation ON
  via `RELAY_WORKTREE_ISOLATION=1`; async/ignored-file effects beyond the sweep acknowledged out of reach).
- **Q4 — Reviewer value (Codex):** scored by the rubric below — falsifiable.
- **Q5 — New worker (agy):** agy as reviewer on the SAME frozen post-build artifact; same rubric;
  Codex-vs-agy head-to-head. First live agy relay turn on this substrate.
- **Q6 — Chain cleanliness:** N/A for this single-phase run — declared inconclusive, does not weaken Q1–Q5.

### Reviewer scoring rubric (Q4/Q5)
True positives / false positives · effect on outcome (did a requested change alter the final diff or
gate?) · seeded-defect catch (binary — plant an inverted score-floor comparison or a missing
flag-OFF guard; did the reviewer catch it?) · false approval (hard fail — `Approved` while the gate or
a seeded defect remained).

> **Honest blind spot:** Q-cost is answerable only from the Claude builder lane (`total_cost_usd`);
> codex + agy are cost-blind. Any "cost of an AI build" figure is a floor from the Claude lane only.

---

## Run parameters (lock these)

- **ALLOW_PATHS (minimal):**
  - `src/chat-module.js` — insert `#TryHandleNearMissCommandAsync` at the :808 seam + flag read.
  - `src/command-intent-resolver.js` — only if a one-line export of `RetrieveScoredCandidates` is
    needed (it already exists; expect zero or trivial change).
  - `tests/command-near-miss-lite.test.js` — NEW test file (the proof + the gate's new assertions).
- **Objective gate (`--pre-advance-cmd`):** `npm run validate:commands && npx jest command-intent-resolver catalog-regex-aliases chat-module --silent`
  (clean baseline: validate ✓, jest 134/0).
- **Flag contract:** `COMMAND_NEAR_MISS_LITE`, default OFF. OFF ⇒ byte-for-byte current behavior
  (the containment backstop). Score floor = documented placeholder constant (tuned post-Phase-0).
- **Caps (pre-registered):** `--max-turns 12` · `--max-budget-usd 3.00` (Claude builder) ·
  `RELAY_TURN_TIMEOUT_S 900` · `--round-cap 5` (= 2×2 review rounds + 1) · `--require-clean` ON ·
  `RELAY_WORKTREE_ISOLATION=1` · `--target-root <sleuth-app>`.
- **Invalidation rule:** if brief, caps, harness scripts, or substrate baseline change between the
  Phase-1 build and the Phase-2 (agy) reviewer comparison, the comparison is INVALID — restart both
  reviewers from the frozen baseline + patch. No mid-experiment goalpost moves.

---

## Builder brief

→ [briefs/sleuth-near-miss-2lite-brief.md](briefs/sleuth-near-miss-2lite-brief.md) (the single-phase
`--phase-brief` the harness feeds the headless builder).

## Out of scope / deferred
Phase 2-full (LLM), Phase 3 (model-name repair), Phase 4 (confirm button / ask-self help) — all gated
and larger. Flipping the flag ON in production — separate human call, after Phase 0 data sets the floor.
Merging to `development` — a separate human review, not this experiment.
