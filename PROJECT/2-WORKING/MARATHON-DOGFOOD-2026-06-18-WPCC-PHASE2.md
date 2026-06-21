---
title: Marathon Dogfood — Headless Relay vs. the WPCC Scanner Monolith
status: Planned
created: 2026-06-18
author: Noel (with Claude Code, Opus 4.8)
updated: 2026-06-20
owner: Noel
harness_repo: xyz-3-agents-swarm (relay-automation/ Marathon stack)
substrate_repo: wp-code-check (dist/bin/check-performance.sh — 6,988 lines / 275 KB)
executes_plan: wp-code-check/PROJECT/2-WORKING/P1-2026-06-18-WPCC-PUBLIC-ENTRYPOINT-SECRET-DETECTION.md (Codex-approved r3, b7838ba)
relates_to:
  - ROADMAP.md Part A · Phase 4 (multi-phase chaining) — first real-monolith chain
  - ROADMAP.md Part A · Phase 3.6 (autonomous-builder hardening) — containment on a real repo
  - REAL-AGENT-OBSERVATIONS.md (where the harvested data lands)
reviewed: "Codex relay — r1 Changes requested (3 blockers/4 improvements/1 nit) → applied → r2 APPROVED (all resolved, no new issues, 2 rounds). Thread: relay-system/2026-06-18/marathon-dogfood-plan-review.md"
goal: >
  Dogfood the Marathon headless-relay harness against a hard, real-world target — the
  6,988-line WPCC scanner monolith — to answer a small set of pre-registered questions
  the synthetic greet.js phases could not. This is a HARNESS EXPERIMENT with WPCC as the
  substrate, NOT an attempt to autonomously rebuild the scanner. Any shipped WPCC detector
  is a bonus; the deliverable is data + a graduate/iterate/abandon verdict on the harness.
verification_2026-06-18: >
  Scanner code re-scanned and confirmed byte-identical to the earlier read (6,988 lines /
  275,615 bytes; last code change 2026-04-16). The remote "pull" was the other agent's
  relay loop on the PLAN DOC (Producer↔Codex r1→r3 APPROVED), touching zero scanner code.
---

# Marathon Dogfood: Headless Relay vs. the WPCC Scanner Monolith

A controlled experiment. We run ONE bounded slice of the Codex-approved WPCC detection plan
through the Marathon harness, instrument it, and harvest data on whether a headless builder +
automated reviewer can do useful work on a 275 KB monolith — bounding new variables to one per
run so a failure is attributable.

> **Scope discipline (read first).** This plan deliberately does NOT run the full 6-phase WPCC
> chain, does NOT chain unattended on first contact, and does NOT treat "the scanner improved" as
> success. Success = *clean, attributable data* + a defensible verdict. A run that fails honestly
> is a passing experiment; a run retried-until-green is a failed one.

---

## Status At A Glance

| What was just completed | What's next |
|---|---|
| **Pre-flight verification** ✅ 2026-06-18 — WPCC scanner confirmed byte-identical to earlier scan; WPCC plan confirmed Codex-approved (r3). No code drift. | **Phase 0 — Pre-flight & Experiment Setup** (pre-register questions, branch, scope ALLOW_PATHS, wire the gate) |

---

## Table of Contents

- [Background](#background)
- [Experiment Design (pre-registered questions)](#experiment-design)
- [Phase 0 — Pre-flight & Experiment Setup](#phase-0)
- [Phase 1 — Baseline Single-Phase Run (Claude builder + Codex reviewer)](#phase-1)
- [Phase 2 — Worker Swap (introduce `agy` as the one new variable)](#phase-2)
- [Phase 3 — Analysis & Synthesis (feed the ROADMAP)](#phase-3)
- [Phase 4 — Conditional: Two-Phase Chain on Real Code](#phase-4)
- [Constraints & Guardrails](#constraints)
- [Out of Scope / Deferred](#out-of-scope)

---

<a name="background"></a>
## Background

The Marathon harness (`relay-automation/marathon-drive.sh`, `marathon.sh`, `marathon-agent.sh`) is
proven on synthetic single- and two-phase chains (`greet.js`). It has never driven a real,
gnarly target. The WPCC scanner is the ideal stress substrate: a single ~6,988-line bash file,
checks largely inline, with a real fixture suite as an objective gate. The WPCC detection plan is
Codex-approved and decomposed into 6 dependency-ordered phases — but it is **not** an `/xyz` fit
(monolith + hard deps), which is exactly why it belongs on the sequential Marathon rail.

**Chosen slice:** WPCC **Phase 2 — `php-direct-access-entrypoint`**. It is the best first target
because it is *additive* (insert one new inline rule + fixtures, not a surgical leak-trace),
*independent* (no Phase-1 prerequisite), and *auto-gradable* (litmus: all 8 KISS root scripts
flagged; the plugin's `includes/` class files clean).

---

<a name="experiment-design"></a>
## Experiment Design (pre-registered questions)

Lock these BEFORE running. Do not add or move goalposts mid-experiment (that is the cardinal QA
rule below). Each question maps to an observable captured in `REAL-AGENT-OBSERVATIONS.md`.

- **Q1 — Feasibility at fixed caps:** Can a headless `claude -p` turn make a *correct, surgical*
  edit to a 6,988-line / 275 KB file within the *chosen* `--max-turns` + `--max-budget-usd`? This
  answers feasibility at THESE caps — **not** a general file-size ceiling (a stepped-cap sweep to
  find the ceiling is deferred → Out of Scope). One run cannot claim a ceiling.
- **Q2 — Objective correctness:** Does the WPCC fixture-validation gate pass after the AI build?
- **Q3 — Containment on a real repo (tracked-allowlist scope):** Does the builder stay in-lane
  (only `ALLOW_PATHS` mutated on the *tracked* tree)? **Measurement honesty:** tracked-path
  inspection canNOT prove absence of *async* or *ignored-file* side effects (worktree isolation is
  still open, ROADMAP 3.6). Phase 1 adds a post-turn **settle-window + dirty/untracked sweep** as
  the honest extent of this answer; anything beyond that is out of measurable reach here.
- **Q4 — Reviewer value (Codex):** scored by the rubric below — falsifiable, not vibes.
- **Q5 — New worker (`agy`):** does `agy` work as a *live* relay worker, and how does its review
  quality compare to Codex **on the identical frozen artifact** (Q4's rubric applied to agy)? First
  live agy relay turn.
- **Q6 — Chain cleanliness (conditional):** Across a real dependency edge, does the next phase
  start from a clean tree with no prior-phase residue?

### Reviewer scoring rubric (makes Q4/Q5 falsifiable)

Pre-register these so reviewer quality is *measured*, not judged after the fact. For each reviewer
run, record:
- **True positives / false positives** — real issues raised vs. spurious ones.
- **Effect on outcome** — did a requested change actually alter the final diff or the gate result?
  (A review that changes nothing is a rubber-stamp signal.)
- **Seeded-defect catch (binary)** — in a controlled sub-run, a KNOWN defect is planted in the
  builder's output (a fixture the rule must flag but doesn't, or an inverted guard). Did the
  reviewer catch it?
- **False approval (hard fail)** — did the reviewer set `Approved` while a known defect or a failing
  gate remained?

Q4 = these metrics for Codex; Q5 = the SAME metrics for agy on the SAME frozen artifact, then a
head-to-head.

> **Honest blind spot, pre-declared:** Q-cost is *not* answerable from the agy/Codex lanes — both
> are cost-blind (no token capture). Only the **Claude builder** lane yields real `total_cost_usd`.
> Any "cost of an AI build" figure in this experiment is a floor from the Claude lane only.

---

<a name="phase-0"></a>
## Phase 0 — Pre-flight & Experiment Setup

**Intent:** make the run reproducible, attributable, and safe before a single turn fires.

- [ ] Pre-register Q1–Q6 (above) in `REAL-AGENT-OBSERVATIONS.md` as the experiment's success contract.
- [ ] Create a **dedicated experiment branch in `wp-code-check`** (e.g. `marathon-dogfood/wpcc-p2`)
      off the approved plan branch — NOT `main`, NOT the doc branch. (Doc prep needs no branch; the
      *run* mutates `check-performance.sh`, so it does.)
- [ ] Scope `ALLOW_PATHS` to the minimum: `dist/bin/check-performance.sh` + the new rule's fixture
      file(s) under `dist/bin/fixtures/` (and/or `dist/tests/fixtures/`). Nothing else.
- [ ] Identify and capture the **exact WPCC fixture-validation command** to use as
      `--pre-advance-cmd` (the objective gate). Record the literal command + its clean-baseline exit.
- [ ] Write the single-phase **Phase-2 builder brief** (`phases/p1/` or a dedicated `--phase-brief`
      file): name the rule id `php-direct-access-entrypoint`, the guard-detection requirement, the
      4 fixtures (+/− pairs), and the litmus — point at the REAL `check-performance.sh` insertion area.
- [ ] Confirm worker auth + the **sandbox-OFF** requirement for every Codex/agy turn (silent-exit
      trap for agy; keychain block for Codex). Smoke: `agy -p "Reply PONG"` and a Codex `exec` echo.
- [ ] Size the caps: `--max-turns`, `--max-budget-usd` (Claude builder), `RELAY_TURN_TIMEOUT_S`,
      and `--round-cap = 2 × max_review_rounds + 1`. Record the chosen numbers.

### QA Checklist — Phase 0
- [ ] **Pre-registration locked:** Q1–Q6 + success contract written down *before* Phase 1; no later edits to the questions.
- [ ] **Reproducibility:** the full invocation (env + flags) is captured verbatim so the run can be replayed.
- [ ] **Blast radius bounded:** experiment is on a throwaway branch; `ALLOW_PATHS` is the minimal set; `--require-clean` will be set for the run.
- [ ] **Gate is real:** the `--pre-advance-cmd` command was run once on the clean tree and its baseline result recorded (so a post-build pass/fail is meaningful).
- [ ] **One-variable rule stated:** Phase 1 changes only "harness vs. monolith"; the worker pairing is held at the proven Claude+Codex.

---

<a name="phase-1"></a>
## Phase 1 — Baseline Single-Phase Run (Claude builder + Codex reviewer)

**Intent:** isolate "*can the harness build into a monolith?*" with the **already-proven** worker
pair, so any failure is attributable to the target, not a new worker.

- [ ] Run one phase via `marathon-drive.sh --phase-brief <brief> --reviewer codex --builder claude
      --artifact dist/bin/check-performance.sh,<fixture paths> --pre-advance-cmd <gate>
      --require-clean --round-cap <N>` (sandbox-OFF).
- [ ] Observe the build turn: builder edits ONLY `ALLOW_PATHS`; the new rule + fixtures appear.
- [ ] Observe the review turn(s): Codex critiques; producer applies fixes; loop to `STATUS: Approved`
      or halts at the round-cap with `ESCALATION.md`.
- [ ] On approval, the `--pre-advance-cmd` fixture gate runs automatically *before* `phase.approved`.
- [ ] Capture: turns used, wall-clock, Claude-lane `total_cost_usd`, the final diff to
      `check-performance.sh`, and the relay transcript (committed under `relay-system/<date>/`).
- [ ] Record Q1–Q4 outcomes in `REAL-AGENT-OBSERVATIONS.md` with evidence (diff + gate result).

### QA Checklist — Phase 1
- [ ] **Containment proven (Q3), tracked scope:** `git show` of the build commit touches ONLY `ALLOW_PATHS`. A violation → exit 6 recorded, not papered over.
- [ ] **Side-effect sweep (Q3 honest extent):** after a settle-window, `git status` shows no unexpected dirty/untracked files; the turn transcript shows no spawned external-model call (tool-shadow held). Async/ignored-file effects beyond this are acknowledged out of measurable reach (worktree isolation open) — NOT claimed as "no side effects."
- [ ] **Objective gate honored (Q2):** the documented fixture command actually ran post-build and its pass/fail is recorded — not assumed from `STATUS: Approved`.
- [ ] **No silent truncation:** if the builder hit `--max-turns`/budget and stopped mid-edit, that is logged as the Q1 answer ("feasible / not feasible at caps X"), not retried until green.
- [ ] **Evidence sources are real:** cost from the `claude --output-format json` transcript (`.usage`, `.total_cost_usd`); turn count from the tick event chain. `tick analyze` only *sums what the lanes captured* (it defers per-commit drift/collision) — no invented metrics.
- [ ] **Honest negative:** a failed or partial build is written up as a result, with the failure mode, not deleted.

---

<a name="phase-2"></a>
## Phase 2 — Worker Swap (introduce `agy` as the one new variable)

**Intent:** change exactly ONE thing — the reviewer identity — to compare `agy` against Codex (Q5).
The ONLY way to truly isolate the reviewer is to hold the builder output **FIXED**: do NOT re-run
the builder (a re-run changes builder stochasticity and the starting tree, confounding the result).
Capture Phase 1's post-build / pre-review patch, reset the tree to the Phase-1 baseline commit,
replay that exact patch, and run BOTH reviewers against that frozen artifact. This is also agy's
first live relay turn.

- [ ] **Freeze the artifact:** from Phase 1, capture the builder's post-build, pre-review patch and
      the baseline commit it applied to. Both reviewers review THIS byte-identical patch.
- [ ] **Codex reviewer (control):** run Codex against the frozen artifact; score with the rubric.
- [ ] **agy reviewer (the one variable):** reset to the same baseline + replay the frozen patch, then
      run agy as reviewer, sandbox-OFF. Routing: a `gemini-`prefixed alias mapped to `AGY_AGENT` (so
      `marathon-drive`'s `codex|gemini` reviewer check passes), OR drive
      `relay-drive.sh --agent-cmd relay-automation/marathon-agent.sh` directly with `AGY_AGENT` set.
- [ ] **Empty-output guard live-check:** confirm a deliberately-sandboxed agy turn exits 5 (not a
      phantom success) — the shim's central safety claim, proven live.
- [ ] **Seeded-defect sub-run:** prepare a SECOND frozen artifact with one known planted defect
      (a fixture the rule must flag but doesn't, or an inverted guard); run both reviewers on it;
      record whether each catches it (the rubric's binary).
- [ ] Score agy with the SAME rubric; record exit code, wall-clock, whether containment held,
      transcript path. Then the Codex-vs-agy head-to-head (Q5).

### QA Checklist — Phase 2
- [ ] **One-variable integrity:** the builder output is FROZEN (same patch replayed onto the same baseline commit); only the reviewer identity differs. No builder re-run.
- [ ] **Comparison is fair:** Codex and agy review the byte-identical frozen patch and are scored with the same rubric (incl. the seeded-defect binary).
- [ ] **Empty-output guard verified:** a deliberately-sandboxed agy turn exits 5 — proven live.
- [ ] **Cost-blind acknowledged:** the write-up states agy produced no token/cost data; no fabricated cost figure for this lane.
- [ ] **Containment re-checked:** agy reviewer mutated only the relay file (read-only on code); off-lane → exit 6 recorded.

---

<a name="phase-3"></a>
## Phase 3 — Analysis & Synthesis (feed the ROADMAP)

**Intent:** convert the runs into durable data and a decision.

- [ ] Fill the objective sections of `REAL-AGENT-OBSERVATIONS.md` — per-worker claimed-before-edit /
      drift / verbs and cross-cutting collisions via **manual git inspection** (the analyzer defers
      per-commit drift/collision; do NOT claim `tick analyze` produced them).
- [ ] Answer Q1–Q6 explicitly, each with its evidence pointer (commit/diff/gate/transcript).
- [ ] State upfront in the synthesis: if Phase 4 was not run, **Q6 is inconclusive** — and that does
      NOT weaken the verdict on the single-phase dogfood (Q1–Q5 stand on their own).
- [ ] Write a 3–5 sentence **verdict** for the *harness on real code*: graduate (Marathon is ready
      for real-repo dogfooding) / iterate (named harness fixes) / abandon-this-approach.
- [ ] Feed back: if Q1 shows a hard file-size ceiling, note it against ROADMAP Part A Phase 4; if Q3
      shows drift, that is the adversarial test ROADMAP Phase 3.6 is still missing — link it.
- [ ] File any harness bugs found as ROADMAP/BACKLOG items (NOT WPCC bugs — those go to the WPCC plan).

### QA Checklist — Phase 3
- [ ] **Every question answered:** no Q1–Q6 left blank; "inconclusive" is a valid, stated answer with the reason.
- [ ] **Evidence-linked:** each claim cites a commit/diff/transcript, not memory.
- [ ] **Separation of concerns:** harness findings → ROADMAP/BACKLOG; scanner findings → the WPCC plan. No cross-contamination.
- [ ] **Verdict is defensible:** the graduate/iterate/abandon call follows from the recorded data, and names what would change it.

---

<a name="phase-4"></a>
## Phase 4 — Conditional: Two-Phase Chain on Real Code

**Run ONLY if Phase 1 was clean.** Tests multi-phase chaining (Q6) on real code across a genuine
dependency edge — the first time the M5 chain meets a monolith.

- [ ] Author a 2-phase `MARATHON.yaml`: WPCC **Phase 1 (hygiene)** → WPCC **Phase 3 or 4** (which
      `depends_on` Phase 1's JS file path) — the real dependency the WPCC plan documents.
- [ ] Run via `relay-automation/marathon.sh`; confirm `depends_on` ordering, halt-on-first-failure,
      and `marathon.complete` only on full success.
- [ ] Verify the second phase's `rtl_before` snapshot is clean (no residue from phase 1) — by diffing
      the phase-2 build commit's touched files.

### QA Checklist — Phase 4
- [ ] **State cleanliness (Q6):** phase-2 build commit touches only its own lane; no phase-1 file leaks in.
- [ ] **Ordering enforced:** the dependent phase never starts before its prerequisite approves; proven from the tick event chain.
- [ ] **Halt semantics:** a deliberately failed phase-1 stops the chain; phase-2 never starts; escalation written.
- [ ] **Cross-phase context honesty:** since M6 (context injection) is deferred, note whether the phase-2 builder needed prior-phase rationale and lacked it.

---

<a name="constraints"></a>
## Constraints & Guardrails

- **Sandbox OFF** for every Codex and agy turn (Codex keychain/chatgpt.com block; agy silent exit-0).
- **Dedicated branch** in `wp-code-check` for the run; **`--require-clean`** on; review every diff.
- **Worktree isolation is still OPEN** (ROADMAP 3.6) — the airtight async-side-effect close is not
  built, so this run leans on tool-shadow + clean-workspace + commit-scoped containment. Treat the
  branch as the blast-radius backstop.
- **Caps mandatory:** `--max-turns` AND `--max-budget-usd` on the Claude builder; `RELAY_TURN_TIMEOUT_S`
  on every lane; `--round-cap = 2N+1`.
- **Cost-blind lanes:** agy + Codex emit no token data; only the Claude builder lane is metered.
- **Invalidation rule (one-variable integrity):** if the brief, caps, harness scripts, or repo
  baseline change between the Phase-1 build and the Phase-2 reviewer comparison, the comparison is
  INVALID — restart both reviewers from the frozen baseline + patch. No mid-experiment goalpost moves.

---

<a name="out-of-scope"></a>
## Out of Scope / Deferred

- Running the full 6-phase WPCC chain unattended (premature; gated on Phase 1 being clean).
- Shipping WPCC detectors to `main` (this is an experiment branch; merges are a separate human call).
- Cost/concurrency benchmarking via agy/Codex (cost-blind; use the Claude lane or defer).
- Fixing the worktree-isolation gap (ROADMAP 3.6 work item, not this experiment).
- Any `/xyz` concurrent-lane attempt on the monolith (established non-viable in the prior assessment).
- **`AGY_MODEL` multi-model variants** — would break the one-variable rule (reviewer identity must be
  the only change); a separate experiment if agy proves viable at all.
- **Stepped-cap sweep** to find the true file-size ceiling — Q1 here is feasibility at *fixed* caps only.
