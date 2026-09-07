---
name: workhorse
description: >
  End-to-end disciplined problem resolution ladder: establishes ground truth via
  /debug-mantra, engineers the leanest safe solution via /ponytail (reusing and
  extending existing subsystems with zero code sprawl), enforces AGENTS.md, SOP.md,
  and GUIDING PRINCIPLES governance, checks cross-repo CHANGELOG cohesion, stress-tests
  the plan via /consult with Codex and Agy, runs bounded /recon on ambiguous stateful
  targets, proves preservation before irreversible operations, and executes with verified
  runnable checks.
  Trigger on /workhorse, "workhorse", "tackle this", "work through this problem",
  "methodical progress", or when an ambiguous or complex task requires structured,
  governed execution across the full ladder.
metadata:
  argument-hint: "[task, PR, issue, or problem description]"
---

# /workhorse — Governed End-to-End Problem Resolution Ladder

`workhorse` is a 6-rung execution ladder that transforms ambiguous symptoms, complex bugs, PR reviews, or feature requests into clean, minimal, cross-model-verified, durable solutions.

It coordinates existing specialized skills (`debug-mantra`, `recon`, `ponytail`, `consult`) and repository governance rules rather than creating duplicate procedural abstractions.

---

## The 6-Rung Ladder

```text
1. Ground Truth & Diagnostics  (/debug-mantra)  ──► Reproduce raw artifact, trace paths, falsify hypotheses
2. Least-Mechanism Design      (/ponytail)      ──► YAGNI, stdlib first, ZERO duplicate subsystems, minimal diff
3. Governance & Cohesion Gate                   ──► AGENTS.md, SOP.md, GUIDING-PRINCIPLES.md, CHANGELOG parity
4. Cross-Model Consensus       (/consult)       ──► Parallel fan-out (Codex + Agy), reconcile disagreements
5. Preservation & Irreversibility Gate          ──► Inventory state, prove preservation, establish rollback or confirm loss
6. Governed Execution & Verification            ──► Apply minimal diff, execute runnable checks, verify done
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
   - If an action is not plainly Easy to reverse, include its provisional resolved target,
     reversibility classification, preservation invariant, evidence, and rollback in the consult.
     Rung 5 revalidates them immediately before execution.

---

## Rung 5: Preservation & Irreversibility Gate

Run this rung before **every** mutation. Easy work records the classification in one line. Costly
and One-way-door operations must produce the full preservation proof below; implementation
complexity never lowers this requirement.

1. **Resolve and classify the exact target:** Name the concrete path, ref, record, service, or
   published artifact and classify the action `Easy`, `Costly`, or `One-way door`. If the target is
   unresolved, stop.
2. **Inventory the relevant state carriers:** Record each carrier as `checked`, `not applicable`, or
   `unknown`; any `unknown` blocks mutation. For multiple stale clones or folders, evaluate each
   candidate separately. If its origin, purpose, or relationship to the canonical destination is
   ambiguous, run a bounded `/recon` **for that candidate** and retain the Recon Map as evidence.
3. **State the preservation invariant:** Say exactly what must remain true after the operation and
   what pre-mutation evidence would prove nothing is lost. Match the evidence to the claim:
   - ancestry proves graph reachability;
   - patch equivalence proves change-set similarity;
   - content or semantic evidence proves bytes or behavior;
   - provenance evidence proves origin and attribution.

   None substitutes for another unless it answers the invariant. In particular, a commit not being
   an ancestor is **not** evidence that its content is missing, and a clean diff is not provenance.
4. **Make recovery or permanent loss explicit:** A Costly operation needs a tested rollback. A true
   One-way door has none: state the exact permanent loss, residual uncertainty, and resolved target,
   then obtain fresh, operation-specific operator confirmation. General permission to work
   unattended is not confirmation of a particular permanent loss.
5. **Bind and refresh the proof:** Bind evidence to the resolved target and current state. Re-run the
   inventory and preservation checks immediately before mutation; a changed path, ref, worktree,
   process/session, or evidence artifact invalidates the prior proof.

**Repository retirement minimum.** Follow `WORKTREE-SAFETY.md` and `/merge-cleanup`, and require its
report to cover dirty, untracked, and relevant ignored files; all ref namespaces, reflogs,
unreachable objects, and stashes; registered worktrees; nested repositories/submodules and
local-only object stores where applicable; remotes and PR state; hooks/config; and active processes
or sessions. A specialized handoff supplies domain mechanics; it does not waive this rung. Reject
an incomplete report and run `/recon` per preservation-unproven clone before disposition.

---

## Rung 6: Governed Execution & Verification

1. **Execute:** Apply the approved minimal diff to the working branch.
2. **Verify:**
   - Run the runnable check left behind in Rung 2.
   - Execute the repository validation suite (e.g., `validate.sh` in XYZ-forge or `pytest` in rebalanceOS).
   - Ensure working tree and tests are green.
   - For destructive work, verify the preservation invariant against the destination or recovery
     artifact. Post-deletion absence alone cannot prove that nothing was lost; the proof must already
     exist from Rung 5.
3. **Ledger Closeout & PDDA Reconciliation:**
   - *Doc Promotion:* If a working doc was created, update frontmatter to `status: completed` and move to `PROJECT/3-COMPLETED/` (or let `wave_reconcile` handle it).
   - *Ledger Integrity:* Run local PDDA/releases checks (e.g. `pdda-local-checks.sh` or `releases roadmap list`) to ensure zero orphaned or unanchored states remain.
4. **Report & Close:**
   - Present a concise completion summary:
     - Root cause & ground truth established (Rung 1).
     - Minimal diff & reused modules (Rung 2).
     - Governance checks passed (Rung 3).
     - Consult reconciliation takeaways (Rung 4).
     - Preservation proof, reversibility classification, and confirmation result (Rung 5).
     - Test execution and verification results (Rung 6).

---

## Proportional Rigor & Escape Hatches

- **Fast-Track (Trivial + Easy to Reverse):**
  Only when an action is both obvious/mechanical/trivial **and** classified Easy to reverse:
  - Execute Rungs 1, 2, 5, and 6 directly (observe ground truth → shortest diff → classify → verify).
  - Explicitly skip Rung 4 in one line: `[workhorse fast-track: trivial and Easy to reverse; skipped consult]`.
  - Destructive, externally published, Costly, or One-way-door actions never fast-track, however
    simple the command or small the diff.

- **Handoff to Specialized Skills:**
  - **Iterative 1:1 Co-Authoring:** If Rung 4 reveals that an artifact requires multiple iterative drafting rounds, hand off to `/relay-xyz`.
  - **Open-Ended Research / Ideation:** If the task is purely investigatory without code modifications, hand off to `/recon` or `/feynman`.
  - **Ambiguous Stale State:** For each stale clone or folder whose disposition is not already
    proven, run a bounded `/recon` before deciding whether to preserve, merge, archive, or remove it.
  - **Immediate Landing / Fleet Cleanup:** When the task is purely about consolidating branches and
    merging PRs, route to `/merge-cleanup` within Rung 5's preservation contract; reject execution
    when its report leaves a relevant carrier unchecked or unknown.

- **Pushback & Routing Authority:**
  If an operator invokes `/workhorse` on an emergency fire drill (incident rollback) or pure open-ended Q&A, the agent is explicitly authorized to state: *"Fast-tracking to immediate remedy / routing to research mode."*

---

## Operating Rules

- Apply all 6 rungs in order. Never skip Rung 1 (ground truth) or Rung 5 (preservation) to jump to
  Rung 6 (execution).
- Keep communication concise and results-driven.
- If a consult or verification surfaces unexpected failure, loop back to Rung 1 (falsify hypothesis & trace fail path) rather than guessing a patch.
