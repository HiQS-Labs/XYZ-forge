---
name: weekly-planner
description: >-
  Dual-horizon weekly planning and team orchestration skill built around XYZ Forge PRS (releases.db)
  and PDDA, with zero-dependency markdown fallback. Ingests team weekly GitHub issues, maps member
  focus domains, prioritizes high-value blockers, enforces the Provisional Decisions Protocol (zero
  stalls on external decisions), performs a rigorous 2nd-pass adversarial conflict and contradiction
  audit, and outputs a lightweight weekly outline. Shares core engine functions with daily-planner
  to ensure zero drift and complete coherence across planning cadences.
---

# Weekly Planner (with Shared Daily Adaptive Engine)

Orchestrate weekly sprint alignment and daily task execution across team members without stalling on external decisions or accumulating contradictory plans.

**The Golden Anti-Conflict Rule:** A plan containing contradictions, file collisions, or circular dependencies undermines team trust and stalls execution. Every weekly outline and daily pivot must pass an explicit **2nd-Pass Adversarial Audit** before being published or executed.

---

## Core Northstars

1. **Release Milestone & Build Manifest Anchoring:**
   - Every weekly plan must anchor itself to the active target release (`releases_app.py next` and `releases.db`), reporting target release version, release window, days overdue/remaining, the **release exit criterion**, and the **manifest build burndown** (shipped count, dialed-in count, burndown percentage, and exact dialed-in build issue numbers), along with active marathons and the jog build queue.
2. **Live Issue Grounding & Grounded Assignments:**
   - Ingested roadmap and backlog tasks MUST be validated against live GitHub open issue state (`gh issue list --state open`). Closed, retired, superseded, or foreign issues must be dropped immediately. A failed or truncated live lookup stops intake; a successful empty native result stays empty and does not reopen the general backlog.
   - Task assignments must be grounded in explicit GitHub assignees mapped to known teammates; the team issue supplies domain descriptions—never dump unassigned tasks onto a single operator. Unassigned roadmap items belong in `Unassigned / Triage Queue`, and parked vision items belong in `Deferred / Parked Intake`.
3. **Adversarial Audit on Both Horizons (Weekly & Daily):**
   - Every weekly plan and every daily pivot must undergo a 2nd-pass adversarial review (spawned subagent, or `/relay-xyz` / `/consult` fallback in environments without subagents).
   - Catches:
     - **Task Duplication:** Multiple PRs or issues solving the same root bug under different names (exempting non-implementation evidence carriers / receipts).
     - **Contradictions & Merge Collisions:** Parallel branches editing shared files (`CHANGELOG.md`, database migrations, core configuration) without topological ordering.
     - **Concurrency / Data Races:** E.g., scheduling a database historical backfill while live rolling reconciliation is unpartitioned.
     - **Stale Assumptions:** Features scheduled against unmerged base branches.
4. **The Provisional Decision Protocol (Zero External Stalls):**
   - **Never write "Waiting for [Stakeholder] to decide" as a plan item or blocker.**
   - Capture unresolved business/product decisions as **Deferred Provisional Decision Points** on the canonical tracking issue. Check later comments and linked follow-up decisions before applying an older assumption or exclusion; follow the latest explicit owner decision and show unresolved conflicts.
   - If no decisions tracker exists, the skill requests permission to create a canonical GitHub issue to track and record all decisions.
   - For reversible business configuration, record an explicit provisional value, owner, and correction path. Add a UI control or re-compute action only when that configuration actually needs one; never turn correctness invariants, safety guardrails, or migrations into blanket settings.
5. **High-Value Blocker Prioritization & PRS Ranking:**
   - Before publishing, the operator/adversarial pass identifies any task that **currently blocks another team member or gates the active release milestone** and promotes it explicitly; the engine does not infer teammate blockers.
   - Tasks are prioritized by `(is_release_build, prs_score)` descending:
     - **Dialed-in release builds** rank first to advance the active release.
     - Scored items rank by composite PRS score (`rating_ovr` or sum of `pri/sev/appeal/effort`).
     - `risk >= 4` acts as an explicit human gate (`*[GATE: risk {risk}]*`), never summed into the score.
6. **Dual Ingestion (PRS/PDDA Native with Fallback):**
   - **Mode A (Native XYZ):** Ingests PRS 4-axis ratings (`pri/sev/appeal/effort`, `calc` sum, `ovr` overrides, `risk` gate) and build manifest items directly from `releases.db` (read-only SQLite) and active docs from `PROJECT/`.
   - **Mode B (Zero-Dependency Fallback):** Ingests open issues via `gh issue list`, executing a 2–3 pass scratch markdown process in `temp/planner/` to triage and sharpen tasks.
7. **Shared Core Engine Architecture (Zero Skill Drift):**
   - The weekly planner owns the primary data models, merge-sequencer, and adversarial checks in `scripts/planner_core.py`.
   - The `daily-planner` skill imports and calls these shared routines to calculate its 24-hour pivot, ensuring that the daily and weekly cadence never contradict each other.

---

## Architectural Layout

```
skills/3-weekly/weekly-planner/
├── SKILL.md                  # This specification and prompt guide
└── scripts/
    └── planner_core.py       # Shared engine for intake, sequencing, audit, and daily pivot
```

---

## Step-by-Step Execution Workflow

### Step 0: Preflight & Isolated Scratch Verification
1. Verify repo root and ensure `<repo_root>/temp/` exists and is gitignored (`.gitignore`).
   - If `temp/` does not exist, ask user permission to create it.
2. Scratch artifacts and triage files MUST be written into `temp/planner/`, never the repo root.

### Step 1: Ingest Signals & Team Weekly Plan
1. Identify the **Team Weekly Plan GitHub Issue** (via `--issue <N>` or search):
   - Ingest team member domain assignments (e.g. Jose -> Data/Pipeline, Matthew -> NexMail/Calendar, Noel -> Orchestration/Gate).
2. Signal Ingestion & Live Grounding:
   - **Release Milestones & Builds:** Query `releases.db` and run `python3 utils/py/releases_app.py next` to anchor the weekly plan to the active milestone, compute days overdue or remaining, extract the release exit criterion, compute the manifest build burndown (`shipped` vs `dialed_in`), and inspect active marathons and the jog queue.
   - **Live Open Issues:** Fetch live open issues via `gh issue list --state open` to ground all candidate tasks. Filter out any closed, retired, or superseded issues.
   - **If `releases.db` exists:** Query PRS 4-axis ratings and overrides directly from `roadmap_items`. Tag dialed-in release build tasks with `*[Release Build: {version}]*`, format PRS badges `*[PRS: {score} ({p}/{s}/{a}/{e})]*` or `*[PRS: {score} (ovr)]*`, and flag `*[GATE: risk {risk}]*`.
   - **If Fallback Mode:** Ingest active GH issues and generate `temp/planner/pass1-intake.md` and `temp/planner/pass2-sharpened.md`.
3. Reconcile the latest issue/PR state, owner decisions, plan documents, and rollout evidence before labeling work open or done. Record the source and as-of date; distinguish merged, deployed, backfilled, and production-verified states.
4. Ground assignments in explicit GitHub assignees mapped to known teammates (the team issue supplies domain descriptions); route unassigned items to `Unassigned / Triage Queue` and parked items to `Deferred / Parked Intake`, sorted by release build status and PRS score.

### Step 2: Establish the Topological Merge Sequence
Run the shared sequencing engine:
```bash
python3 skills/3-weekly/weekly-planner/scripts/planner_core.py --repo-root . --mode sequence
```
The sequence classifies all open PRs into 5 distinct phases with CI validation and dependency ordering:
1. **Phase 1: Ready to Land** — Approved, `mergeable: MERGEABLE`, passing/neutral CI (`statusCheckRollup`), non-draft, and unblocked by prerequisite PRs.
2. **Phase 2: Ready Pending Undraft** — Passing CI, mergeable, but held as GitHub Draft awaiting operator readiness check to undraft.
3. **Phase 3: Needs Rebase** — `mergeable: CONFLICTING` against base.
4. **Phase 4: In Review / WIP** — Awaiting reviews, pending CI, or active implementation WIP.
5. **Phase 5: Held Drafts & Evidence Carriers (Do Not Merge Directly)** — Held PRs or test qualification / post-merge receipts (e.g. #1039, #1033, #930, #954, #1024), annotated with explicit hold reason (e.g. "Evidence retention", "Prerequisites required", "Explicit HOLD in title"). These are exempted from false-positive duplicate implementation audits.
Confirm any claimed stack with merge-base and diff evidence; nearby PR numbers or shared labels do not establish a dependency.

### Step 3: Apply the Provisional Decisions Protocol
1. Scan for any requirement waiting on external input (e.g. Elan, Sam, Legal, Marketing).
2. Check if a canonical Provisional Decisions register exists:
   - If an existing issue is known (e.g. `#202`), append the decision item with:
     - Item ID & description
     - Current provisional default value in code
     - Owner
     - Cost of correction
   - If NO tracker issue exists, **prompt the user for permission to create one**:
     ```
     "No canonical provisional decisions tracking issue found.
      May I create one titled 'DECISIONS - Current applied provisional decisions register'?"
     ```
3. Schedule a settings control or re-compute action only for business configuration that requires operator adjustment; keep invariants and migration work as explicit engineering tasks.

### Step 4: 2nd-Pass Adversarial Audit
Run the adversarial engine:
```bash
python3 skills/3-weekly/weekly-planner/scripts/planner_core.py --repo-root . --mode audit
```
If subagents are enabled, invoke an independent subagent (`invoke_subagent` with role `Plan Auditor`).
In environments where subagents cannot be spawned, invoke `/relay-xyz` or `/consult --models codex,agy` to challenge the plan:
- *Check 1: Duplication.* Are two PRs fixing the same issue or touching the same reset logic? (Distinguish implementation PRs from evidence receipts).
- *Check 2: Contradictions.* Will landing PR A break PR B's tests or assumptions?
- *Check 3: Concurrency Hazards.* Will running a backfill script collide with active rolling reconcilers?
- *Check 4: Merge Friction.* Are multiple PRs modifying `CHANGELOG.md` or shared migrations simultaneously? (Mitigate by enforcing sequential landing order or single-file rebase at merge time).

### Step 5: Deliver Output & Calibrate
1. Generate both machine-readable (`temp/planner/weekly-plan-<date>.json`) and human-readable (`temp/planner/WEEKLY-PLAN-<date>.md`) outlines.
2. Present the plan with standard sections:
   - **Header:** Planning Window (7-day range and timezone e.g. `Oct 13 – Oct 19, 2026 (America/Los_Angeles)`), Generation Timestamp, Intake Mode, Provisional Decisions Register.
   - **Section 0: Release Milestone Context & Active Targets:** Target release from `releases.db` / `releases_app.py next`, overdue/remaining days, release exit criterion, manifest build burndown, dialed-in build tasks, subsequent milestones, active marathons, and jog build queue.
   - **Section 1: Immediate P0 Blockers** at the top.
   - **Section 2: PR Merge Sequence:** Topologically sorted 5 phases (Ready to Land, Ready Pending Undraft, Needs Rebase, In Review, Held Drafts & Evidence Carriers).
   - **Section 3: Teammate Focus & Action Outlines:** Member tasks with release build tags, PRS badges, risk gates, and assignment citations, plus `Unassigned / Triage Queue` and `Deferred / Parked Intake` sorted by priority.
   - **Section 4: Adversarial Audit Receipt:** Zero contradictions or explicit friction warnings.
3. Treat engine output as a draft until these checks are applied:
   - Define acceptance per owner and each applicable tenant or cohort, with dated evidence and explicit, approved exclusions. Do not generalize one owner's pass to everyone.
   - Stamp counts and denominators with source and as-of time; recheck them before using an old snapshot as a success target.
   - Trace audit claims to the exact source and commit. Identify the observed guardrail or threshold; do not invent constants or treat distinct guardrails as interchangeable.
   - Estimate remaining scoped work against combined team capacity, including review, deployment, and verification. Mark deadlines as targets unless an owner has justified a commitment.
   - After optional additions are resolved, record the exact release SHA and hold acceptance to that revision; a version label or adjacent PR number cannot expand the agreed scope.

---

## Daily Adaptive Pivot (Linkage to Daily Planner)

The companion `daily-planner` skill relies on `planner_core.py` to pivot the active weekly plan:
```bash
python3 skills/3-weekly/weekly-planner/scripts/planner_core.py --repo-root . --mode daily
```
1. Queries PRs merged and issues closed in the last 24–36 hours (filtered by `mergedAt` and `closedAt`).
2. Compares against the baseline weekly plan (`temp/planner/weekly-plan-*.json` or `WEEKLY-PLAN-*.md`) and marks completed items `[DONE]`.
3. Re-sequences the remaining open PRs with statusCheckRollup CI verification.
4. Promotes newly unblocked tasks to the top of today's operator queue.
5. Runs the Adversarial Northstars check on the pivoted day plan before presenting to the user.
6. Emits both `temp/planner/daily-pivot-<date>.json` and `temp/planner/DAILY-PIVOT-<date>.md`.
