---
name: daily-planner
description: >-
  Adaptive daily planning skill that pivots the active weekly plan based on what closed
  yesterday. Directly reuses the core engine and adversarial Northstars from weekly-planner
  (skills/3-weekly/weekly-planner/) to eliminate logic drift and prevent planning contradictions.
  Re-sequences the daily merge queue and highlights the immediate blocker for the operator.
---

# Daily Planner (Adaptive Daily Pivot)

Adapts the active weekly plan based on yesterday's progress, landed PRs, and newly emerged blockers.

**Drift Prevention Contract:** This skill reuses the installed `weekly-planner` bundle's `scripts/planner_core.py`. Resolve that skill's physical folder through the local skill catalog and set `PLANNER_ENGINE` to its absolute engine path; set `PLANNER_REPO` to the absolute target checkout. Do not assume a particular IDE's skill root. When using repository source directly, resolve `skills/3-weekly/weekly-planner/scripts/planner_core.py` from the Forge checkout. Weekly planner must be installed alongside this skill; follow its runtime and native CLI compatibility requirements.

---

## Daily Workflow

### Step 1: Preflight & Weekly Plan Lookup

1. Locate the latest weekly plan in `temp/planner/` (`weekly-plan-*.json` or `WEEKLY-PLAN-*.md`).
2. If no weekly baseline exists, the daily runner halts with an actionable error prompting the operator to run `/weekly-planner` first to establish the baseline trajectory.

### Step 2: Ingest Yesterday's Closures

Run the shared engine in daily mode:

```bash
python3 "$PLANNER_ENGINE" --repo-root "$PLANNER_REPO" --mode daily
```

The engine automatically:
- Scans PRs merged in the last 24–36 hours (`gh pr list --state merged` bounded by `mergedAt`).
- Scans issues closed in the last 24–36 hours (`gh issue list --state closed` bounded by `closedAt`).
- Reconciles baseline items from the weekly plan against these closures and marks completed items `[DONE]`.

Before presenting a status change, recheck current sources and the latest explicit owner decisions; a merged PR alone does not prove deployment, backfill, or production acceptance.

### Step 3: Re-Sequence & Promote Unblocked Work

- Open PRs are classified by the shared engine into the phases Ready to Land, Ready Pending Undraft, Blockers to Fix, Needs Rebase, In Review/WIP, and Held Drafts & Evidence Carriers, with CI status check validation (`statusCheckRollup`). The daily Markdown renders the ready sequence and the top blocker; the full phase lists are in the JSON (`merge_sequence.status_phases`).
- Held drafts and evidence carriers (e.g. test qualification receipts, held spikes) are isolated in `evidence_carriers_or_held` with reason annotations so the daily runner does not mistake them for actionable blockers or merges — and so the Stalled & stale step (Step 6) never calls them stalled.
- Newly unblocked dependent tasks are promoted to the top of today's operator queue.
- If a task is waiting on a business decision, the **Provisional Decision Protocol** is applied (fallback default + record on canonical tracking issue).

### Step 4: Adversarial Audit on the Daily Pivot

Before presenting the pivoted day plan, the engine executes the 2nd-Pass Adversarial Audit:
- **Duplication:** Checks if today's actions duplicate work in review.
- **Contradiction:** Checks if two developers are scheduled to touch colliding files today.
- **Race Condition:** Ensures long-running migrations/backfills aren't scheduled over concurrent sync jobs.

### Step 5: Output Daily Action Queue

Emits both machine-readable `temp/planner/daily-pivot-<date>.json` and human-readable `temp/planner/DAILY-PIVOT-<date>.md`:
1. **Accomplished Yesterday:** Include only updates evidenced within the stated calendar day and cite their dates/sources; keep older context separate, even when the ingestion window spans 24–36 hours.
2. **Today's Immediate P0 Blocker:** The single item the operator should clear first.
3. **Active Merge Sequence:** Live status of the PR queue with passing CI requirements.
4. **Adversarial Audit Findings.**
5. **Stalled & stale** (Step 6 below).

Teammate action queues come from the weekly plan's assignments (`teammate_assignments` in the weekly JSON); the daily
engine does not re-derive them.

Apply the weekly planner's Step 5 calibration checks to the daily queue, using fresh per-owner and per-applicable-tenant evidence rather than carrying forward an old success count.

### Step 6: Stalled & stale (read-only; GH-1184)

The daily run ends with a **Stalled & stale** section so the operator sees what they started and left hanging,
across GitHub and the Mac the run is on. It is a log, not a planning surface: actionable follow-ups still go to
their owning issue or the weekly issue body.

What it collects (every source is wrapped; a failed or capped lookup is a **coverage gap**, printed first, and an
empty Stalled list under a gap renders *coverage incomplete*, never "nothing stalled"):

- **GitHub** (the data the engine already pulled plus one `gh issue list` and one `gh pr list --state all`):
  open non-draft PRs idle ≥ `--stale-days` (default 3); drafts idle ≥ `--draft-stale-days` (default 7); open issues
  assigned to the operator (`gh api user`, override `--operator`) or labelled `in progress`/`🚧`, idle ≥ `--stale-days`.
  "Idle" is GitHub's `updatedAt` age — a proxy: label churn and bot comments count as activity, so a human stall after
  such activity can be missed; the section says so.
- **Held, never Stalled:** the engine's held/evidence-carrier PRs (title `HOLD`, `leave unmerged`, `not an authorized
  merge`, `prerequisites required`/`live-pilot`, `review authority limit`, evidence-carrier phrasing), anything
  labelled `hold`/`parked`, and a body line `Owner decision: hold`. Comment-only holds are **not** read; the coverage
  block states the recognised set.
- **This device only, read-only:** for `--repo-root` and every checkout under `--local-roots` (default
  `~/marathon-clones/*`; globs allowed, repeatable) whose `origin` is this repo (one hop through a local-path origin;
  an unresolved origin is a visible gap): branches with no upstream or `ahead N` (regardless of age — forgotten work is
  the point; `ahead` is *as of last fetch*, this scan never fetches), uncommitted changes (count only, via
  `git --no-optional-locks status --porcelain`), and branches whose name matches a merged/closed PR head —
  reported as **`retire? name match — verify with /merge-cleanup`**, never "safe to retire" (names get reused,
  forks share names, local commits may exist). Integration branches (`development`, `main`, `master`) are skipped.
  Open session notes: dated `PARKED/YYYY-MM-DD-*.md` not marked `Resolved:`/`Promoted:`/`Closed:` and relay threads
  whose `STATUS:` is not Approved/Closed, when their last **commit** (or an uncommitted edit) is inside the window —
  path, date and status only, never contents; a note's `check`/`close` fields are never executed.
- Rendering caps local rows at 10 per checkout (newest first; the JSON keeps all).

**Comment on the weekly issue (`--team-issue <n>`):** the section is posted as one comment per device per day,
headed `Stalled & stale — <device> — <date>` with a hidden marker `<!-- planner-stalled:<device>:<date> -->`.
A same-day re-run **edits that device's own comment**; another Mac posts its own; the coverage block lists every
device seen in prior markers with `no report from <device> since <date>` when it has none today. The device id is
`--device-id` or `device_config.json`'s `device_id`, lowercased with `.local` stripped. Without `--team-issue`
nothing is posted. If the comment listing fails the run does not post blind; a failed listing or write exits 3.

**Headless entry point (for the #1168 scheduler — not enabled here):**

```bash
python3 "$PLANNER_ENGINE" --repo-root "$PLANNER_REPO" --mode stalled --team-issue <weekly issue>
```

runs only the scan and the comment (no weekly baseline needed), writes `temp/planner/stalled-<date>.{json,md}`, and
is non-interactive. Enabling a scheduled job is a separate operator approval under #1168. The scan writes nothing
but `temp/planner/*` and that one comment; it never fetches, prunes, deletes, or touches `releases.db`.

This change is forge-only: XYZ-mini's copies of both planner skills are `adapted` (`utils/py/xyz_mini_sync.py`)
and are not refreshed from here.
