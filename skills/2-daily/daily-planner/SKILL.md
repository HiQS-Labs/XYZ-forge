---
name: daily-planner
description: >-
  Adaptive daily planning and GitHub Daily Work Ledger skill. Pivots the active weekly plan
  (--mode daily) AND runs the shared Daily Work Ledger GitHub issue workflow (--mode ledger)
  across XYZ Forge dogfooding, vendored .xyz/ repos, and plain GitHub repos without requiring
  a weekly baseline. Discovers or creates today's "Daily Work Ledger — YYYY-MM-DD" issue,
  carries forward the operator's unfinished items from the most recent prior workday across
  devices, surfaces newly assigned issues and PR reviews/comment remediations, calibrates
  against earlier starters' checkouts, and chains /recon and /debug-mantra to ground the plan.
  Distinct from Rebalance's 15-minute /daily prompt-log synthesizer.
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
- **This device only, read-only:** for every checkout under `--local-roots` (repeatable, globs allowed; the default
  is `--repo-root` plus `~/marathon-clones/*`, and passing the flag **replaces** that default) whose `origin` is this
  repo (one hop through a local-path origin; an unresolved origin is a visible gap): branches with no upstream or
  `ahead N` (regardless of age — forgotten work is the point; `ahead` is *as of last fetch*, this scan never fetches),
  uncommitted changes (count only, via `git --no-optional-locks status --porcelain`), and branches whose name matches
  a merged/closed PR head — reported as **`retire? name match — verify with /merge-cleanup`**, never "safe to retire"
  (names get reused, forks share names, local commits may exist). Integration branches (`development`, `main`,
  `master`) never get a retirement or no-upstream hint; an `ahead N` on them is still reported.
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

runs only the scan and the comment (no weekly baseline needed), writes `temp/planner/stalled-<UTC date>.json` and
`temp/planner/STALLED-<UTC date>.md` (file names use the engine's UTC date like every other planner file; the comment
header and marker use the device's local date), and is non-interactive. If the open-PR lookup itself fails, the
report is still produced with `open PRs` as a `failed` coverage entry (daily mode does the same; the other modes keep
failing closed as before). Enabling a scheduled job is a separate operator approval under #1168. The scan writes nothing
but `temp/planner/*` and that one comment; it never fetches, prunes, deletes, or touches `releases.db`.

This change is forge-only: XYZ-mini's copies of both planner skills are `adapted` (`utils/py/xyz_mini_sync.py`)
and are not refreshed from here.

---

## Daily Work Ledger (`--mode ledger` · GH-1459)

Use `--mode ledger` when starting or calibrating a workday (`"daily work ledger"`, `"start my day"`, `"calibrate my day"`, `"what is already checked out today"`), or in repositories where no weekly plan baseline file exists.

**Boundary with Rebalance `/daily`:** Rebalance's `/daily` skill (`rebalance-OS`) is the 15-minute local prompt/telemetry synthesizer (`temp/daily-log/YYYY-MM-DD.log`). Do **not** replace or invoke `/daily` for GitHub issue coordination; `/daily-planner` (`--mode ledger`) owns the repository-level GitHub Daily Work Ledger issue workflow.

### Repository Operating Modes (`--repo-mode {auto,forge,vendored,gh-only}`)

Precedence: `--repo-mode` CLI flag > `XYZ_DAILY_LEDGER_MODE` env var > `device_config.json` `daily_ledger_mode` > `auto` detection on `--repo-root`:
- **`forge`:** Auto-selected when `releases.db` and `utils/hq/hq.sh` exist at `--repo-root`. Enriches the ledger with read-only `releases.db` milestone context (`get_release_milestones`), local worktrees, and `.tick` claims.
- **`vendored`:** Auto-selected when `.xyz/` exists at `--repo-root`. Uses `.xyz/` device config and read-only `tick claims --json` + git worktree scanning without requiring `releases.db` or a weekly baseline.
- **`gh-only`:** Zero-dependency fallback for any GitHub repository without `releases.db` or `.xyz/`.

### Mandatory 4-Step `/recon` + `/debug-mantra` Grounding Ladder

#### Step 1: Recite `/debug-mantra` & Run Live Ledger Discovery (Read-Only Default)

Recite the four-mantra debugging discipline block verbatim, then run `planner_core.py --mode ledger` in read-only mode first:

```bash
python3 "$PLANNER_ENGINE" --repo-root "$PLANNER_REPO" --mode ledger --repo-mode auto
```

What the engine collects and verifies:
- **Today's & Prior Workday's Ledger Issues:** Queries exact title regex `^Daily Work Ledger — (\d{4}-\d{2}-\d{2})$` in the shared ledger timezone (`--ledger-tz`, default `America/Los_Angeles`). When either 100-row search page is full, it **unconditionally paginates** `repos/<slug>/issues?state=all&per_page=100` so >100 historical ledgers, mixed-page duplicate spikes (`1 today + 100 yesterday`), and backfilled dates never lose completeness. If concurrent earliest starters created duplicate issues for the same date, `min(number)` is selected as canonical while comments across all same-date duplicates are merged.
- **Ingestion Authorship Verification (`[P1]` guard):** Only comments whose **first non-empty line** matches `<!-- daily-ledger:<operator>:<device>:<YYYY-MM-DD> started:<ISO-8601> -->` with a date matching the target ledger issue AND `comment.user.login.lower() == marker_operator.lower()` (or an explicit `--allow-delegate-comment` bot in `XYZ_DAILY_LEDGER_TRUSTED_BOTS` / `daily_ledger_trusted_bots`) are trusted. Quoted markers on line 2+, shared issue body text, and forged comments where `comment.user.login != marker_operator` are rejected (`unverified-forged-marker`).
- **Cross-Device Prior-Workday Carryover:** Aggregates the operator's verified comments from the most recent prior workday (`date < today`) across **any** device (so switching from laptop to Mac Studio preserves continuity), filtering out issues closed or PRs merged since that ledger when live GitHub lookups are `ok`.
- **Assigned Issues, PR Reviews & Comment Remediations:** Surfaces newly assigned open issues (`assignees`), non-draft PRs requesting the operator's review (`reviewRequests`), and the operator's open PRs needing remediation (`CHANGES_REQUESTED`, failing `statusCheckRollup`, or unresolved review threads via bounded GraphQL `reviewThreads(first:100)` where `isResolved == false`).

#### Step 2: Multi-Operator Checkout Calibration ("Already Checked Out")

Inspect Section 2 of `temp/planner/DAILY-LEDGER-<date>.md` (`already_checked_out` and `collisions` in `temp/planner/daily-ledger-<date>.json`):
- Starters on today's ledger issue are ordered by their preserved `started:<ISO-8601>` timestamp ascending (`earliest_starter`).
- Every active claim carries an explicit provenance badge:
  - `verified-ledger-claim` — verified first-line marker comment on today's ledger issue.
  - `github-label-or-pr` — live GitHub `in progress`/`🚧` label, assignee, or open PR branch reference.
  - `local-device-only` — local git branches, clean/dirty linked git worktrees (`git worktree list --porcelain`), and active `.tick` claims read via canonical `TICK_REPO_ROOT=<root> tick claims --json` (read-only; if `.tick/events` is corrupt or `tick` fails, `coverage` reports `tick claims` as `failed`/`unavailable` rather than guessing in Python).
- De-conflict any item flagged under `### ⚠️ Checkout Collisions Detected` before selecting today's active queue.

#### Step 3: Bounded `/recon` & `/debug-mantra` on Top Candidate Items

Before publishing your daily claim comment or starting implementation:
1. Run bounded `/recon` on the top carryover/assigned issue or PR remediation target to trace entry points, state writers, and N+1 downstream consumers.
2. Apply `/debug-mantra` to verify raw PR review thread comments, failing check logs, and live `file:line` ground truth — falsifying stale assumptions from yesterday's notes before committing to today's plan.

#### Step 4: Publish / Update Your Idempotent Comment on Today's Ledger Issue (`--publish-ledger`)

When ready to publish (or update) today's claim block on GitHub:

```bash
python3 "$PLANNER_ENGINE" --repo-root "$PLANNER_REPO" --mode ledger --repo-mode auto --publish-ledger
```

- **Fail-Closed Coverage & Authorship Gate:** Refuses to create an issue or post/patch a comment (exits `3`) if ledger discovery or comment listing failed/truncated, if `auth_login` (`gh api user -q .login`) is unresolved, or if `--operator` does not match `auth_login` on `POST` or `PATCH` (with the sole `POST`/create exception of `--allow-delegate-comment` when `auth_login` is in `trusted_bots`).
- **Unconditional `PATCH` Author Guard & Preserved Timestamp:** When updating an existing comment for `(operator, device, date)`, unconditionally verifies `comment.user.login.lower() == auth_login.lower()` and preserves the original `started:<ISO-8601>` timestamp so earliest-starter ordering never shifts on mid-day updates.

