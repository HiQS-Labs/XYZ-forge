---
gh_issue: 603
source: https://github.com/HiQS-Labs/XYZ-forge/issues/603
title: "feat(skills): add 5-point discipline mantra and overall goal to merge-cleanup, start-task, workhorse, sop, whack-a-mole, unstuck, express, radar, and daily skills"
status: Proposed (1-INBOX — active)
created: 2026-09-13
updated: 2026-09-13
owner: noelsaw1
doc_type: feedback
goal: >
  Add verbatim 5-point discipline mantra recital blocks, Rung 0 Intake Triage, and Overall Goal
  anchors at the top of skills/merge-cleanup/SKILL.md, skills/start-task/SKILL.md,
  skills/workhorse/SKILL.md, skills/sop/SKILL.md, skills/whack-a-mole/SKILL.md,
  skills/unstuck/SKILL.md, skills/express/SKILL.md, skills/radar/SKILL.md, and
  skills/daily/SKILL.md (matching debug-mantra) to enforce re-anchoring across multi-turn agent conversations.
roadmap_exempt: true
---

# GH-603 — workflow discipline mantras for merge-cleanup, start-task, workhorse, sop, whack-a-mole, unstuck, express, radar, and daily

Add verbatim 5-point discipline mantra recital blocks and Overall Goal anchors to `skills/merge-cleanup/SKILL.md`, `skills/start-task/SKILL.md`, `skills/workhorse/SKILL.md`, `skills/sop/SKILL.md`, `skills/whack-a-mole/SKILL.md`, `skills/unstuck/SKILL.md`, `skills/express/SKILL.md`, `skills/radar/SKILL.md`, and `skills/daily/SKILL.md` to ensure agents reciting the skill at the start of execution re-anchor context across multi-turn sessions.

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

## 5. Whack-a-Mole Discipline Mantra
1. **Scan activity & detect repo ranking systems (§1–§2).** Perform a read-only sweep of the last 14 days of issues, merged PRs, fix/revert commits, and comment threads; identify the repo's ranking scheme (PDDA, P0 labels, project fields) to anchor priority.
2. **Cluster by multi-signal correlation (§3).** Group defects sharing $\ge 2$ independent signals (same hot file/module, matching error signatures, explicit issue links, or common component labels), separating single-signal adjacent noise.
3. **Score churn & audit recurrence (§4).** Quantify developer friction using weighted composite churn scoring (reopens, repeat fixes on the same files, reverts, cluster size, comment volume, age open); stop if no cluster scores $> 5$.
4. **Isolate root-cause invariant via recon (§5).** Apply `/debug-mantra` and `/recon` to trace failure paths end-to-end, uncover the violated architectural invariant (state, ordering, concurrency, boundary), and falsify coincidental file co-location.
5. **Draft graded umbrella & file on operator approval (§6–§7).** Structure a concrete umbrella remediation plan with evidence-graded findings (**`FACT`** · **`PATTERN`** · **`HYPOTHESIS`**), ordered tasks (repro $\rightarrow$ guard $\rightarrow$ fix $\rightarrow$ sweep $\rightarrow$ verify), and top-tier priority; file the single issue only after explicit operator approval.
**Overall Goal:** Recurring bug churn eliminated by identifying the single foundational defect behind symptom clusters and obtaining operator approval to file a top-priority, actionable umbrella remediation plan.

## 6. Unstuck Discipline Mantra
1. **Freeze the cogs (Rung 1).** Immediately stop inventing machinery, abstractions, helpers, review loops, or new plans; preserve working state, and record the true requested outcome, nearest milestone, last real movement, and current time sink.
2. **Re-anchor the finish line (Rung 2).** State the nearest observable task milestone in one sentence (e.g. "failing test passes", "PR exists", "operator chose A vs B"); strip all self-created prerequisites from the critical path.
3. **Test the claimed blocker (Rung 3).** Ask *"If this item were fixed now, could the next milestone proceed?"*; strictly classify items as Goal Blocker, Required Correctness/Safety, External Dependency, Polish, or Cog; park cogs/polish and queue genuine blockers into durable intake.
4. **Execute foundational resolution — no bandages (Rung 4).** Select the single smallest action that resolves the true root blocker gating the milestone; strictly forbid painkillers, silencing hacks, bypassed invariants, or symptom patches that kick the can down the road (hand off to `/workhorse` if a structural fix is required).
5. **Act once, verify movement & exit (Rung 5).** Execute the single move, check whether the milestone itself changed, emit the structured UNSTUCK receipt, and immediately resume execution (or return to parent `/workhorse` ladder).
**Overall Goal:** Stalled session interrupted and durable goal movement restored immediately via the simplest foundational action that advances the milestone, with zero added machinery, zero symptom bandages, and zero bypassed safety invariants.

## 7. Express Discipline Mantra
1. **Verify clone & pre-flight bounds (Phases 0–2).** Require a task clone off `origin/development` ($\le 2$ local commits, canonical pre-push gate installed via `githooks/install.sh --check`); enforce strict subsystem bounds ($\le 4$ files / $\le 150$ insertions) and hard refusals on kernel, coordination, or shared Bash surfaces.
2. **Validate issue & registered regression suite (Phases 3–4).** Confirm the tracking issue is OPEN; verify that a dedicated regression suite exists (`test/gh<N>-<slug>.sh`) and is registered in `validate.sh TESTS` (hotfix without a registered suite is refused).
3. **Generate born-complete docs & append changelog (Phase 5).** Scaffold capture doc in `PROJECT/2-WORKING/` with Status, Acceptance, Merge evidence, and Lessons Learned present from birth; append the entry to `CHANGELOG.md` in the same motion.
4. **Execute qualified gate & dial-in releases ledger (Phases 6–7).** Register roadmap issue in `releases.db` and dial into active release (`releases next`); execute regression suite green, prove tree identity, and re-snapshot tree to prevent drift.
5. **Direct fast-forward landing & 3-push reconciliation (Phases 8–11).** Commit qualified paths (`Closes #N`), direct push fast-forward to `origin/development` (`XYZ_SKIP_PREPUSH=1`), verify remote issue closure, ship release evidence, and execute clean-tree `wave_reconcile --commit`.
**Overall Goal:** Critical, risk-bounded hotfix implemented, tested, ledger-tracked, landed directly to development, and reconciled with a complete paper trail in one single, unpaused motion with zero bypassed safety invariants.

## 8. Radar Discipline Mantra
1. **Frame window & discover historical arc (Step 0).** Default to 21 days on trunk (`main`/`development`); discover prior reports in `RADAR/`, `docs/radar/`, or `PROJECT/1-INBOX/` to extract historical baseline RGT metrics and multi-week trajectory.
2. **Prove flow distribution & RGT mix (Step 1 — Lens 1).** Pipe trunk commit subjects to a verified tally file, prove counts sum to `wc -l`, isolate Harness machinery from the denominator, classify Run/Grow/Transform (Transform strictly declared via `rgt: transform`), and report Unclassified drift.
3. **Cluster defects, detect regressions & check PR collisions (Steps 2–2b — Lens 2).** Mine 7 evidence signals to isolate chronic debt and short-cycle regressions (applying $\ge 2$ days / $\ge 2$ PRs recurrence discriminator); score targets, and cross-check open PRs to prevent duplicate scheduling.
4. **Audit release alignment & orphan backlog (Step 3 — Lens 3).** Read `releases.db` and open milestones read-only; measure orphan issue share and surface roadmap plan-vs-execution drift without modifying database state.
5. **Deliver coaching memo & persist dual sinks on confirmation (Steps 4–5).** Present the SDLC Process Coach narrative (celebrate wins, coach process friction, highlight regressions, offer multi-week arc); upon single operator confirmation, write immutable Sink A (`RADAR-REPORT-*.md`) and sync live Sink B (`radar` issue checklist).
**Overall Goal:** SDLC process momentum evaluated across 3-lens empirical evidence (RGT flow, defect/regression clusters, release alignment), synthesized into an actionable coaching memo, and persisted to dual historical/live sinks on operator approval with zero unconfirmed mutations.

## 9. Daily Discipline Mantra
1. **Extract multi-agent intent signal (Step 1).** Read recent operator prompts from `0. Claude Prompts.md` / `clio_prompts` over the rolling 2-hour window across Claude, Agy, Codex, and ZCode to anchor active human directives.
2. **Collect live operational work signals (Step 2).** Query `get_next_actions()`, `calendar_events`, `sleuth_reminders`, and read-only Apple Reminders snapshots from the local database without external side effects.
3. **Scan device-wide git state & CPU health (Step 3).** Run unclosed loop and runaway CPU scanners read-only; synchronize `temp/close-the-loop.md` with in-flight worktrees, unmerged branches, open PRs, and process health.
4. **Evaluate 2-hour trajectory & trigger-grounded coaching (Step 4).** Assess velocity, momentum, and time-gated horizons (exactly-once Morning Retro / Monday Horizon); emit falsifiable coaching nudges strictly citing their telemetry triggers (`[Trigger: ...]`).
5. **Format deterministic schema & append log (Steps 5–6).** Render the standard Markdown synthesis block (Focus, Trajectory, Velocity, Horizon, Unclosed Loops, CPU Health, Coaching Nudge) and append atomically to `temp/daily-log/YYYY-MM-DD.log`.
**Overall Goal:** 15-minute multi-agent work synthesis delivered with zero external mutations — fusing prompt intent, operational state, device git activity, and temporal trajectory into deterministic daily logs and trigger-cited adaptive coaching.








