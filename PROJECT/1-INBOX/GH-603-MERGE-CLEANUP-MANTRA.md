---
gh_issue: 603
source: https://github.com/HiQS-Labs/XYZ-forge/issues/603
title: "feat(skills): add 5-point discipline mantra and overall goal to merge-cleanup, start-task, workhorse, and sop skills"
status: Proposed (1-INBOX — active)
created: 2026-09-13
updated: 2026-09-13
owner: noelsaw1
doc_type: feedback
goal: >
  Add verbatim 5-point discipline mantra recital blocks, Rung 0 Intake Triage, and Overall Goal
  anchors at the top of skills/merge-cleanup/SKILL.md, skills/start-task/SKILL.md,
  skills/workhorse/SKILL.md, and skills/sop/SKILL.md (matching debug-mantra) to enforce re-anchoring across multi-turn agent conversations.
roadmap_exempt: true
---

# GH-603 — workflow discipline mantras for merge-cleanup, start-task, workhorse, and sop

Add verbatim 5-point discipline mantra recital blocks and Overall Goal anchors to `skills/merge-cleanup/SKILL.md`, `skills/start-task/SKILL.md`, `skills/workhorse/SKILL.md`, and `skills/sop/SKILL.md` to ensure agents reciting the skill at the start of execution re-anchor context across multi-turn sessions.

## 1. Merge-Cleanup Discipline Mantra
1. **Verify primary landing readiness (Phase 0).** Confirm the primary on-disk checkout is clean, on the integration branch (`development`), and ready to fast-forward before any remote action.
2. **Inventory checkouts & protect active sessions (Phases 1–3).** Scan worktrees and task clones across safe roots; preserve any checkout with active file handles, driver locks, `.tick` claims, or recent edits (10m/60m recency ladder).
3. **Sequence PRs & pre-gate conflicts (Phases 4–5).** Fetch open PRs into a topological DAG to prevent file collisions; pre-simulate landings and resolve disjoint ledger/doc conflicts.
4. **Merge & reconcile governance (Phase 5).** Remote squash-merge in dependency order, fast-forward primary checkout (`git merge --ff-only`), and execute post-merge reconciliation (`wave_reconcile`, `releases_app check`, `pdda.sh`).
5. **Safe teardown & status confirmation (Phase 6).** Deregister worktrees via canonical git protocol, move clean disposable clones to Trash, prune dangling skill symlinks, and confirm all PRs are landed.
**Overall Goal:** All ready-to-merge PRs processed and local disk clones and git worktree folders safely torn down when appropriate.

## 2. Start-Task Discipline Mantra
1. **Resolve intake & isolate in a fresh clone (Steps 1–3).** Verify the canonical remote/issue, provision a fresh full clone with a task branch off `origin/development`, register the PDDA capture doc in `1-INBOX`, and record 4-axis RELEASES task ratings.
2. **Ground in recon & draft a surgical plan (Steps 4–5).** Trace live entry points, state writes, and blast radius before proposing changes; design the leanest DRY plan that extends existing subsystems with falsifiable acceptance checks.
3. **Pre-implementation plan QA (Step 6).** Run a Codex relay review on the plan, adjudicate findings against ground-truth evidence, and iterate until approved before writing production code.
4. **Execute & deterministically verify (Step 7).** Build the reviewed scope, commit structured checkpoints, and execute all required test suites and repo gates in safe isolation.
5. **Final relay QA & open ready PR (Steps 8–9).** Run final Codex relay QA on the completed diff and test evidence; upon approval, push through the pre-push gate, open the PR against `development`, and retain the task clone for merge handoff.
**Overall Goal:** Issue implemented to spec, validated through double-relay QA (plan + final), and submitted as a verified, conflict-free PR ready for merge.

## 3. Workhorse Discipline Mantra
1. **Triage & rank intake (Rung 0).** Deconstruct walls of text, multi-symptom dumps, or LLM transcripts into an atomic priority list (P0 → P1 → P2). Hold the active queue in the session plan; for deferred/out-of-scope items, prefer the repository's canonical intake path (e.g. `PROJECT/1-INBOX/`) when available, otherwise park them in `<repo-root>/PARKED/`.
2. **Establish ground truth on current item (Rung 1).** For the top priority item, inspect raw artifacts and live state directly, capture a deterministic repro, trace fail paths end-to-end, and run disproofs first before theorizing.
3. **Design least-mechanism & check governance (Rungs 2–3).** Apply `/ponytail` (YAGNI, standard library first, shortest diff); strictly extend existing subsystems with zero code sprawl or duplicate write paths, complying with `AGENTS.md`/`SOP.md`.
4. **Stress-test via cross-model consensus (Rung 4).** Fan out the plan to independent advisors (Codex + Agy via `/consult`), surface technical disagreements without averaging, and resolve all blocking feedback.
5. **Prove preservation, execute & advance queue (Rungs 5–6).** Classify reversibility (`Easy`/`Costly`/`One-way door`), prove preservation invariants, apply minimal diff, verify against runnable checks, and loop back to the next item until the queue is clear.
**Overall Goal:** Complete triage queue resolved serially — each item root-cause proven, simplest architecture validated across independent models, and solution executed with zero code sprawl and verified preservation.

## 4. SOP Discipline Mantra
1. **Locate operational docs & discover conventions (Step 1a–1b).** Find existing SOP and lessons-learned documentation (`SOP.md`, `LESSONS.md`, runbooks, postmortems) across the repository, learn local doc conventions, or offer to scaffold minimal additive structure if none exist.
2. **Mine recent events & grade evidence (Step 1c).** Collect recent changes across commits, PRs, issues, incident logs, changelogs, and transcripts within the lookback window (Express 7d vs. Deep); strictly grade every finding by evidence strength (**`FACT`** · **`PATTERN`** · **`HYPOTHESIS`**).
3. **Draft surgical, additive proposal diffs (Step 2).** Group candidates by target document (SOP first, then LESSONS), show exact proposed additive lines with evidence citations, isolate low-confidence hypotheses, and disclose anything unverified.
4. **Solicit operator confirmation before mutation (Step 3).** Present candidate diffs to the human operator, prompt for any missing incidents or context, and wait for explicit approval (all / by ID / edit / drop) before modifying any files.
5. **Apply additively & record audit trail (Step 3 / Governance).** Apply approved diffs additively (newest first, never deleting without explicit request), persist the run audit log to `.sop/<timestamp>/`, re-verify disk writes, and provide a suggested commit message (strictly read-only git).
**Overall Goal:** Operational procedures and lessons-learned documentation continuously synchronized with verified empirical events, with zero unconfirmed assertions, zero destructive overwrites, and strict evidence-graded operator approval.


