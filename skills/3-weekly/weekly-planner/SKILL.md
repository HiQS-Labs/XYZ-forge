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

1. **Adversarial Audit on Both Horizons (Weekly & Daily):**
   - Every weekly plan and every daily pivot must undergo a 2nd-pass adversarial review (spawned subagent, or `/relay-xyz` / `/consult` fallback in environments without subagents).
   - Catches:
     - **Task Duplication:** Multiple PRs or issues solving the same root bug under different names.
     - **Contradictions & Merge Collisions:** Parallel branches editing shared files (`CHANGELOG.md`, database migrations, core configuration) without topological ordering.
     - **Concurrency / Data Races:** E.g., scheduling a database historical backfill while live rolling reconciliation is unpartitioned.
     - **Stale Assumptions:** Features scheduled against unmerged base branches.
2. **The Provisional Decision Protocol (Zero External Stalls):**
   - **Never write "Waiting for [Stakeholder] to decide" as a plan item or blocker.**
   - All unresolved business/product decisions are captured as **Deferred Provisional Decision Points** on the canonical tracking issue (e.g. [#202](https://github.com/BinoidCBD/LTVera-Pandas/issues/202)).
   - If no decisions tracker exists, the skill requests permission to create a canonical GitHub issue to track and record all decisions.
   - Code against an explicit, recorded provisional default value, and deliver a UI setting control + backend "Re-compute" trigger button so stakeholders can adjust values post-merge.
3. **High-Value Blocker Prioritization:**
   - The top item in an operator's queue is strictly whatever **currently blocks another team member or gates the weekly milestone**.
4. **Dual Ingestion (PRS/PDDA Native with Fallback):**
   - **Mode A (Native XYZ):** Ingests PRS 4-axis ratings (`pri/sev/appeal/effort`, `calc` sum, `ovr` overrides) directly from `releases.db` and active docs from `PROJECT/`.
   - **Mode B (Zero-Dependency Fallback):** Ingests open issues via `gh issue list`, executing a 2–3 pass scratch markdown process in `temp/planner/` to triage and sharpen tasks.
5. **Shared Core Engine Architecture (Zero Skill Drift):**
   - The weekly planner owns the primary data models, merge-sequencer, and adversarial checks in `scripts/planner_core.py`.
   - The `daily-planner` skill imports and calls these shared routines to calculate its 24-hour pivot, ensuring that the daily and weekly cadence never contradict each other.

---

## Architectural Layout

```
skills/3-weekly/weekly-planner/
├── SKILL.md                  # This specification and prompt guide
├── install.sh                # Skills Army HQ symlink installer
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
2. Signal Ingestion:
   - **If `releases.db` exists:** Query calculated scores via `python3 utils/py/releases_app.py roadmap list --json`.
   - **If Fallback Mode:** Ingest active GH issues and generate `temp/planner/pass1-intake.md` and `temp/planner/pass2-sharpened.md`.

### Step 2: Establish the Topological Merge Sequence
Run the shared sequencing engine:
```bash
python3 skills/3-weekly/weekly-planner/scripts/planner_core.py --repo-root . --mode sequence
```
The sequence classifies all open PRs into 4 distinct phases:
1. **Phase 1: Ready to Land** — Approved and `mergeable: MERGEABLE`.
2. **Phase 2: Blockers to Fix** — `reviewDecision: CHANGES_REQUESTED` or red CI.
3. **Phase 3: Needs Rebase** — Approved but `mergeable: CONFLICTING` (conflicts on `development`).
4. **Phase 4: In Review / WIP** — Awaiting reviews or local browser verification.

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
3. Ensure the weekly plan schedules UI settings controls and re-compute buttons for those values.

### Step 4: 2nd-Pass Adversarial Audit
Run the adversarial engine:
```bash
python3 skills/3-weekly/weekly-planner/scripts/planner_core.py --repo-root . --mode audit
```
If subagents are enabled, invoke an independent subagent (`invoke_subagent` with role `Plan Auditor`).
In environments where subagents cannot be spawned, invoke `/relay-xyz` or `/consult --models codex,agy` to challenge the plan:
- *Check 1: Duplication.* Are two PRs fixing the same issue or touching the same reset logic?
- *Check 2: Contradictions.* Will landing PR A break PR B's tests or assumptions?
- *Check 3: Concurrency Hazards.* Will running a backfill script collide with active rolling reconcilers?
- *Check 4: Merge Friction.* Are multiple PRs modifying `CHANGELOG.md` simultaneously? (Mitigate by enforcing single-file rebase at merge time).

### Step 5: Deliver Output & Calibrate
1. Generate the light weekly outline and save to `temp/planner/WEEKLY-PLAN-<date>.md`.
2. Present the plan grouped by teammate, highlighting:
   - **Immediate P0 Blockers** at the top.
   - **Merge sequence roadmap**.
   - **Per-member light task outlines**.
   - **Adversarial audit receipt**.

---

## Daily Adaptive Pivot (Linkage to Daily Planner)

The companion `daily-planner` skill relies on `planner_core.py` to pivot the active weekly plan:
```bash
python3 skills/3-weekly/weekly-planner/scripts/planner_core.py --repo-root . --mode daily --plan-file temp/planner/WEEKLY-PLAN-<date>.json
```
1. Queries what merged and closed in the last 24 hours.
2. Marks completed items `[DONE]`.
3. Re-sequences the remaining open PRs.
4. Promotes newly unblocked tasks to the top of today's operator queue.
5. Runs the Adversarial Northstars check on the pivoted day plan before presenting to the user.
