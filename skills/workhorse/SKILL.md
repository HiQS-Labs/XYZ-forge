---
name: workhorse
description: >
  End-to-end disciplined problem resolution ladder: establishes ground truth via
  /debug-mantra, engineers the leanest safe solution via /ponytail (reusing and
  extending existing subsystems with zero code sprawl), enforces AGENTS.md, SOP.md,
  and GUIDING PRINCIPLES governance, checks cross-repo CHANGELOG cohesion, stress-tests
  the plan via /consult with Codex and Agy, and executes with verified runnable checks.
  Trigger on /workhorse, "workhorse", "tackle this", "work through this problem",
  "methodical progress", or when an ambiguous or complex task requires structured,
  governed execution across the full ladder.
argument-hint: "[task, PR, issue, or problem description]"
---

# /workhorse — Governed End-to-End Problem Resolution Ladder

`workhorse` is a 5-rung execution ladder that transforms ambiguous symptoms, complex bugs, PR reviews, or feature requests into clean, minimal, cross-model-verified, durable solutions.

It coordinates existing specialized skills (`debug-mantra`, `ponytail`, `consult`) and repository governance rules rather than creating duplicate procedural abstractions.

---

## The 5-Rung Ladder

```text
1. Ground Truth & Diagnostics  (/debug-mantra)  ──► Reproduce raw artifact, trace paths, falsify hypotheses
2. Least-Mechanism Design      (/ponytail)      ──► YAGNI, stdlib first, ZERO duplicate subsystems, minimal diff
3. Governance & Cohesion Gate                   ──► AGENTS.md, SOP.md, GUIDING-PRINCIPLES.md, CHANGELOG parity
4. Cross-Model Consensus       (/consult)       ──► Parallel fan-out (Codex + Agy), reconcile disagreements
5. Governed Execution & Verification            ──► Apply minimal diff, execute runnable checks, verify done
```

---

## Rung 1: Ground Truth & Diagnostics (`/debug-mantra`)

Establish primitive ground truth before theorizing or proposing any changes.

1. **First is reproducibility / raw artifact inspection:**
   - For a failure/bug: capture a fast, deterministic runnable repro (failing test, curl, CLI run).
   - For an attribution or architecture question: inspect the raw object (database row, message payload, exact file lines) before assuming. Screenshots, rendered views, and memory are **hypothesis-zero**, not axioms.
2. **Know the fail path:**
   - Trace the execution path end-to-end. Enumerate all controlling knobs (configs, env vars, branch conditions, concurrency).
   - Flip one axis at a time in the differential.
3. **Question your hypothesis (Disproof First):**
   - Generate 2–3 ranked hypotheses. Identify the cleanest **disproof** for each.
   - Run the disproof first: if it fails, discard immediately to avoid chasing phantoms.
4. **Every run is a breadcrumb:**
   - Maintain a running session ledger of observations, probes, and ruled-out paths.

*When the target is a plan, PR, or architecture (Plan Pivot):*
- Measure ground truth at plan time (re-run live counts and file:lines; do not cite remembered state).
- Trace the exact path being modified across all callers before proposing modifications.
- Falsify acceptance criteria (specify how each criterion fails and where red-control evidence lands).
- Maintain a recon ledger against what has already shipped.

---

## Rung 2: Least-Mechanism Architecture (`/ponytail`)

Channel a pragmatic senior engineer: build the simplest, shortest, most durable mechanism that satisfies the requirement.

1. **The Ponytail Rungs:**
   - *Rung 1:* Does this added code/machinery need to exist at all? (YAGNI).
   - *Rung 2:* Standard library does it? Use it.
   - *Rung 3:* Native platform/framework feature covers it? Use it.
   - *Rung 4:* Already-installed dependency solves it? Use it. Never add dependencies for what a few lines can do.
   - *Rung 5:* Can it be a small focused diff? Shortest working diff wins.
2. **The Subsystem Reuse Law:**
   - **Do not invent new modules, helper utilities, or parallel execution paths.**
   - Audit existing modules in `src/rebalance/lib/`, `XYZ-forge/utils/`, etc., and extend them logically.
   - Extending an existing abstraction beats standing up a parallel, siloed system that will silently drift.
3. **Deliberate Shortcuts & Runnable Checks:**
   - Mark deliberate minimal simplifications with an explanatory comment (e.g. `// ponytail: sqlite single-thread, revisit if throughput exceeds threshold`).
   - Every non-trivial change leaves behind **one runnable check** (an assert-based check, unit test, or integration probe).

---

## Rung 3: Governance & Cross-Repo Cohesion

Validate that the proposed minimal solution complies with the repository's foundational rules and history.

1. **`AGENTS.md` Alignment:**
   - Respect single entry points (e.g. orchestrator dispatch chains in `index_ops.py` or `releases_app.py`).
   - Honor disabled or paused subsystems (never silently revive paused components).
   - Adhere to containment and worktree safety rules.
2. **`SOP.md` Alignment:**
   - Any performance or efficacy claim must be backed by measurable, reproducible test evidence.
   - Follow the issue-first and capture-doc protocols where required.
3. **`GUIDING-PRINCIPLES.md` Alignment:**
   - Check the North Star: Durable, Reversible, DRY.
   - Single-writer per contract/table.
   - Introduce an FSM if state transitions exceed 4 states or multiple conditional branches.
4. **`CHANGELOG.md` Check:**
   - Review recent entries in `CHANGELOG.md` across relevant repos (`XYZ-forge`, `rebalanceOS`, etc.).
   - Ensure terms, patterns, and architectural conventions match the active codebase state rather than legacy/superseded patterns.
5. **PDDA & Releases Ledger Intake:**
   - *Tracking Doc:* For non-trivial tasks, confirm a capture doc exists in `PROJECT/1-INBOX/` or `PROJECT/2-WORKING/` with frontmatter `status: active`.
   - *Releases DB / Roadmap:* Verify the issue is registered in `releases.db` (`releases roadmap add <GH-NUM>` / `releases jog add`) in releases-mode repos.

---

## Rung 4: Cross-Model Consensus (`/consult`)

Stress-test the finalized plan or architecture across independent AI models before touching production code.

1. **Fan-Out (`consult.sh`):**
   - Formulate a crisp prompt referencing the real file paths and problem context.
   - Run `consult.sh --prompt "..." --label ...` to query **Codex** and **Agy** in parallel in isolated throwaway worktrees.
2. **Reconcile Without Averaging (Surface the Seams):**
   - **TLDR:** 1–2 sentence summary of the reconciled call and confidence level.
   - **Disagreements:** Explicitly list every point where advisors differed, with your adjudication and technical rationale.
   - **Agreements:** Highlight points where both models independently concurred.
   - **Sorted Categories:**
     - **Blocking:** Legitimate risks or defects caught by an advisor; must be addressed before proceeding.
     - **Worth Doing / Optional:** Valid improvements or cleanups to consider.
     - **Skip / Out of Scope:** Ideas noted and explicitly dismissed with rationale.
3. **Finalize the Plan:** Incorporate blocking feedback directly into the execution steps.

---

## Rung 5: Governed Execution & Verification

1. **Execute:** Apply the approved minimal diff to the working branch.
2. **Verify:**
   - Run the runnable check left behind in Rung 2.
   - Execute the repository validation suite (e.g., `validate.sh` in XYZ-forge or `pytest` in rebalanceOS).
   - Ensure working tree and tests are green.
3. **Ledger Closeout & PDDA Reconciliation:**
   - *Doc Promotion:* If a working doc was created, update frontmatter to `status: completed` and move to `PROJECT/3-COMPLETED/` (or let `wave_reconcile` handle it).
   - *Ledger Integrity:* Run local PDDA/releases checks (e.g. `pdda-local-checks.sh` or `releases roadmap list`) to ensure zero orphaned or unanchored states remain.
4. **Report & Close:**
   - Present a concise completion summary:
     - Root cause & ground truth established (Rung 1).
     - Minimal diff & reused modules (Rung 2).
     - Governance checks passed (Rung 3).
     - Consult reconciliation takeaways (Rung 4).
     - Test execution and verification results (Rung 5).

---

## Proportional Rigor & Escape Hatches

- **Fast-Track (Trivial / 1-Step Changes):**
  For obvious, mechanical, or trivial edits (typos, single config values, version bumps):
  - Execute Rungs 1, 2, and 5 directly (observe ground truth → shortest diff → verify).
  - Explicitly skip Rung 4 (consult) in one line: `[workhorse fast-track: trivial edit, skipped consult]`.

- **Handoff to Specialized Skills:**
  - **Iterative 1:1 Co-Authoring:** If Rung 4 reveals that an artifact requires multiple iterative drafting rounds, hand off to `/relay-xyz`.
  - **Open-Ended Research / Ideation:** If the task is purely investigatory without code modifications, hand off to `/recon` or `/feynman`.
  - **Immediate Landing / Fleet Cleanup:** When the task is purely about consolidating branches and merging PRs, route to `/merge-cleanup`.

- **Pushback & Routing Authority:**
  If an operator invokes `/workhorse` on an emergency fire drill (incident rollback) or pure open-ended Q&A, the agent is explicitly authorized to state: *"Fast-tracking to immediate remedy / routing to research mode."*

---

## Operating Rules

- Apply all 5 rungs in order. Never skip Rung 1 (ground truth) to jump to Rung 5 (execution).
- Keep communication concise and results-driven.
- If a consult or verification surfaces unexpected failure, loop back to Rung 1 (falsify hypothesis & trace fail path) rather than guessing a patch.

