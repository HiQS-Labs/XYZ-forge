---
gh_issue: 1459
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1459
title: "daily-planner: shared Daily Work Ledger GH issue, carryover, checkout calibration, and vendored repo support"
status: "Working — Phase 1 (Plan QA)"
updated: 2026-11-13
created: 2026-11-13
owner: agent-agy
doc_type: feature
branch: feat/XYZ-forge-gh1459-daily-planner-shared-daily-2026-11-13
complexity: 2
risk: 1
effort: 2
phases: 1
rating: "pri/sev/appeal/effort 70/45/50/55 · calc 220"
non_goals:
  - Replacing Rebalance /daily
  - New standalone skill or script under utils/scripts/bin
  - New sqlite3.connect call (GH-777)
  - New test files under test/ (GH-831)
  - Automatic dispatch or issue closure
related:
  - #1184
  - #1022
  - #1043
  - #1340
goal: >
  Extend planner_core.py with --mode ledger and --repo-mode {auto,forge,vendored,gh-only} and update daily-planner/SKILL.md so operators coordinate daily work on one shared Daily Work Ledger GitHub issue per day, carry forward unfinished work from yesterday's ledger issue, surface assigned issues and PR review/comment remediations, calibrate against earlier starters' checkouts, and chain /recon and /debug-mantra.
---

## Key concepts

- daily-work-ledger
- earliest-starter-calibration
- planner-core-ledger-mode
- vendored-repo-mode
- recon-and-debug-mantra-chaining

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# daily-planner: shared Daily Work Ledger GH issue, carryover, checkout calibration, and vendored repo support

## Status

| What was just completed | What's next |
|---|---|
| Intake filed (#1459), promoted to `2-WORKING`, rated `70/45/50/55` in `releases.db`, and grounded via `/recon`, `/debug-mantra`, and `/consult` (`daily-work-ledger-idea-170103`). | Run Step 6 independent Codex relay plan QA before implementation. |

## Idea

## Observed

| Claim | Command / source | Observed |
|---|---|---|
| `planner_core.py` has no `ledger` mode or daily-issue find/create helper | `grep -n "ledger" skills/3-weekly/weekly-planner/scripts/planner_core.py` | Matches `ledger_repo_id` (`:88,134,819`), `releases.db` inspection (`:816`), and comments (`:89,165,962,1165,1198`); `--mode` choices at `:1839` are `weekly, daily, audit, sequence, intake, stalled`. |
| `--mode daily` requires an existing weekly plan baseline (defaulting to `temp/planner/`, or `--plan-file`) | `skills/3-weekly/weekly-planner/scripts/planner_core.py:730-738,1840,1906-1907` | `pivot_daily` raises `FileNotFoundError("No active weekly plan baseline found in temp/planner/...")` when no weekly baseline exists. |
| `--mode stalled` posts per-device comments (`<!-- planner-stalled:<device>:<date> -->`) only when `--team-issue <n>` is passed explicitly | `skills/3-weekly/weekly-planner/scripts/planner_core.py:1200,1655-1684,1889-1903` | `sync_stalled_comment` patches or creates a marker-tagged comment on `--team-issue`, but cannot look up or create a daily GitHub issue for today's date or inspect yesterday's ledger issue. |
| `daily-planner` does not chain `/recon` or `/debug-mantra` or calibrate against earlier operators' checkouts on today's ledger issue | `skills/2-daily/daily-planner/SKILL.md:18-120` | `SKILL.md` runs `planner_core.py --mode daily` and `stalled`; it never discovers/files a daily ledger GH issue, never parses prior workday ledger carryovers, and never cross-references teammate checkout claims on today's issue. |
| Rebalance `/daily` is a separate 15-minute local prompt/telemetry synthesizer | Deployed `daily/SKILL.md` + `utils/hq/hq.sh` | Rebalance `/daily` synthesizes `0. Claude Prompts.md` and `rebalance.db` into `temp/daily-log/YYYY-MM-DD.log`; it is distinct from the GitHub repo-level `/daily-planner` skill. |

## Diagnosis / existing gap

Operators starting their workday across XYZ Forge (dogfood maintenance) or repos where XYZ Forge is vendored (`.xyz/`) lack a shared, per-day GitHub coordination ledger issue that bridges yesterday's unfinished work, newly assigned issues, PR reviews/comment remediations, and multi-operator checkout calibration. Currently:
1. `skills/2-daily/daily-planner/SKILL.md` and `skills/3-weekly/weekly-planner/scripts/planner_core.py` require an existing weekly plan baseline (`pivot_daily` at `:734`, defaulting to `temp/planner/` unless `--plan-file` is passed) and an explicit `--team-issue <n>` integer (`:1842`) to publish a device comment.
2. There is no `--mode ledger` (or daily ledger issue resolver) in `planner_core.py` to search for today's `"Daily Work Ledger — YYYY-MM-DD"` GitHub issue, file it if absent (when authorized via `--publish-ledger`), locate the most recent previous workday's `"Daily Work Ledger — *"` issue and its comments to carry forward unfinished operator items, or aggregate what work is already checked out by whichever operator started earliest today.
3. `daily-planner/SKILL.md` does not chain `/recon` (to trace active seams and N+1 downstream state for assigned issues/PRs) and `/debug-mantra` (to verify live ground truth of PR review comments, failing CI checks, and claimed checkouts before recommending action), nor does it document auto-detection across Native Forge mode (`releases.db` + `utils/hq/`), Vendored `.xyz/` mode, and zero-dependency GitHub fallback mode.

Root cause: `planner_core.py` was built around a local file baseline (`weekly-plan-*.json`) plus an optional manual `--team-issue` comment sink (`GH-1184`), leaving daily GitHub-native continuity and multi-operator checkout visibility unimplemented. Fixing this in `planner_core.py` and `skills/2-daily/daily-planner/SKILL.md` (with `skills/3-weekly/weekly-planner/SKILL.md` architecture notes) extends the single shared planner engine without creating a new skill or script.

## Plan

1. **Extend `skills/3-weekly/weekly-planner/scripts/planner_core.py` with Daily Work Ledger mode (`--mode ledger`) and repo-mode auto-detection (`--repo-mode {auto,forge,vendored,gh-only}`):**
   - Update `main()`'s pre-dispatch `get_open_prs` guard (`planner_core.py:1871`) from `if args.mode not in {"stalled", "daily"}:` to `if args.mode not in {"stalled", "daily", "ledger"}:` so a missing/broken repo slug or offline `gh` records a `failed` coverage gap (and exits 3 when `--publish-ledger` is set) instead of raising an uncaught `RuntimeError`. Also ensure `open_prs` coverage in `--mode ledger` is explicitly marked `"truncated"` (not `"ok"`) whenever `len(prs) >= 300` (the actual `get_open_prs` `limit: int = 300` cap at `:326-345`).
   - Add `resolve_repo_mode(repo_root, explicit_mode)` with precedence `--repo-mode` CLI > `XYZ_DAILY_LEDGER_MODE` env > `device_config.json` `daily_ledger_mode` > `auto` detection (`forge` when `releases.db` and `utils/hq/hq.sh` exist at `repo_root`, `vendored` when `.xyz/` exists at `repo_root`, and `gh-only` otherwise). Preserve installed-engine vs target-repo separation (`--repo-root` points to the target checkout). In `forge` mode, reuse `get_release_milestones` / `ingest_weekly_intake` (zero new `sqlite3.connect` calls, honoring `GH-777`) to enrich tasks with release milestone burndown, PRS scores, and active marathon/jog queues; in `vendored` mode, resolve `.xyz/` device identity and scan `.tick/` active claims plus local worktrees without requiring `releases.db` or a weekly baseline; in `gh-only` mode, operate purely from GitHub issues/PRs and local git refs without requiring `.xyz/` or `releases.db`.
   - **Extend `scan_local_checkout(repo_root)` (`planner_core.py:1352-1406`) to enumerate linked git worktrees and active `.tick` claims read-only:**
     - Run `git -C <repo_root> worktree list --porcelain` (read-only) to enumerate all linked worktrees and their checked-out branch names (`branch refs/heads/...`), emitting `kind: "worktree_branch"` rows with extracted issue numbers (`(?:#|GH-|gh)(\d+)`) even when a linked worktree is clean, tracked, and 0 commits ahead of upstream.
     - Read active `.tick` claims without mutating state using the canonical `tick claims --json` reader only (no parallel Python event-state interpreter): if `<repo_root>/.tick/events` exists, resolve `<tick_bin>` from `<repo_root>/bin/tick`, `<repo_root>/.xyz/bin/tick`, or the harness's installed `bin/tick` relative to `planner_core.py`, and run `TICK_REPO_ROOT=<repo_root> <tick_bin> claims --json` (which calls `fold(readAllEvents(root, { strict: true }))` read-only and writes no `STATE.md`), extracting issue numbers from task IDs and claimed paths and emitting `kind: "tick_claim"` rows (`local-device-only` provenance). If `<repo_root>/.tick/events` exists and `<tick_bin>` is unavailable or `tick claims --json` exits non-zero (e.g. exit 3 on corrupt/unreadable events), record `coverage["tick_claims"] = {"status": "failed" | "unavailable", ...}` and surface a coverage warning rather than reimplementing `.tick` event folding in Python or treating local claims as empty/verified. Never invoke `claim`, `ping`, or any mutating `tick` verb during collection.
   - Add `find_or_create_daily_ledger_issue(repo_root, slug, date_local, ledger_issue_arg, create_if_missing, coverage)` (resilient past 100 historical ledger issues):
     - Use a shared day timezone (defaulting to `America/Los_Angeles` or `XYZ_LEDGER_TZ`, overridable via `--ledger-tz`) so all operators share one calendar date `YYYY-MM-DD`.
     - If `--ledger-issue <n>` is passed, resolve issue `#<n>` directly via `gh issue view`.
     - **Complete discovery contract (resilient to >100 historical ledgers, mixed-page duplicate spikes, and backfilled dates):**
       1. **Today's ledger lookup:** Query exact-date `gh issue list -R <slug> --search '"Daily Work Ledger — <date_local>" in:title sort:created-asc' --state all --limit 100 --json number,title,state,url,body,createdAt,author`, filtering strictly by regex `^Daily Work Ledger — (\d{4}-\d{2}-\d{2})$` where `parsed_date == date_local`. If `len == 100` on this exact-date query, mark `coverage["ledger_discovery"] = "truncated"`.
       2. **Prior-workday lookup with unconditional pagination on full pages:** Query `gh issue list -R <slug> --search '"Daily Work Ledger — " in:title sort:created-desc' --state all --limit 100 --json number,title,state,url,body,createdAt,author`. Whenever that initial 100-row page is full (`len == 100`), **unconditionally paginate to completeness** via `gh api --paginate --slurp 'repos/<slug>/issues?state=all&per_page=100'` (filtering exact regex `^Daily Work Ledger — (\d{4}-\d{2}-\d{2})$` across all pages) so that neither backfilled older ledger creation timestamps nor mixed-page duplicate spikes (e.g., 1 issue for today + 100 duplicates for yesterday) can hide the true maximum `parsed_date < date_local` or omit the oldest `min(number)` canonical issue and its comments for that prior workday. If pagination fails (`rc != 0` or invalid JSON), mark `coverage["ledger_discovery"] = "failed"`.
     - If either discovery query fails (`rc != 0`, invalid JSON) or remains truncated (`status != "ok"` in `coverage["ledger_discovery"]`), refuse to create a new issue (exit 3 on `--publish-ledger`) so a failed/incomplete lookup never files a blind duplicate.
     - **Canonical tie-break & concurrent-create reconciliation:** If multiple issues exist for `date_local` (e.g. two operators raced on creation), the **lowest issue number (`min(number)`)** is canonical; the engine still reads comments across all duplicate same-day issues so no operator comment is lost, and surfaces a warning pointing duplicates to the canonical issue. When today's issue is absent and `--publish-ledger` is set, create `"Daily Work Ledger — <date_local>"` and immediately re-run today's discovery query to reconcile against any concurrent creation (selecting `min(number)`). Without `--publish-ledger`, run strictly read-only on GitHub and write `temp/planner/daily-ledger-<date>.{json,md}`.
     - Resolve `previous_ledger` as the most recent ledger issue whose parsed title date `< date_local` (ordered by parsed title date descending, tie-broken by `min(number)` while reading comments across all same-date duplicates for that prior workday), and fetch both `today_ledger_comments` and `previous_ledger_comments` via paginated `gh api --paginate --slurp repos/{slug}/issues/{num}/comments?per_page=100` (`read_stalled_comments` pattern at `:1635-1652`).
   - Add `collect_operator_continuation_and_queue(repo_root, slug, operator, auth_login, prs, sequence, open_issues, previous_ledger, previous_ledger_comments, today_ledger_comments, local_rows, repo_mode, coverage)`:
     - **First-line marker rule & ingestion authorship verification (`[P1]` guard):**
       - Only comments whose **first non-empty line** (`body.lstrip().splitlines()[0].strip()`) matches `^<!-- daily-ledger:([a-zA-Z0-9._-]+):([a-zA-Z0-9._-]+):(\d{4}-\d{2}-\d{2})(?:\s+started:(\S+))? -->$` AND whose marker date equals the target ledger's date (`prev_date` for `previous_ledger_comments`, `date_local` for `today_ledger_comments`) are parsed as ledger claim blocks (`LESSONS-LEARNED.md:154` — never match markers quoted on line 2+ or inside prose, and never parse the shared issue `body` as an operator claim block).
       - **Verify comment authorship on ingestion:** A comment marker for `<marker_op>` is only trusted (`verified-ledger-claim` on today's ledger, or eligible for `<operator>`'s prior-workday carryover) when `comment["user"]["login"].lower() == marker_op.lower()` (or when `--allow-delegate-comment` is explicitly set AND `comment["user"]["login"].lower()` is in the configured trusted delegate bot allowlist `XYZ_DAILY_LEDGER_TRUSTED_BOTS` / `device_config.json` `daily_ledger_trusted_bots`, default empty). Any comment where `comment["user"]["login"]` does not match `marker_op` (and is not an authorized delegate bot) is rejected as `unverified-forged-marker`, surfaced in `warnings`, and excluded from carryover and from suppressing any operator's candidate queue.
     - **Prior-workday continuation:** Match verified comments for `operator` in `previous_ledger_comments` across *any* device (so an operator switching Macs retains continuity). Cross-verify every cited `#N` / `GH-N` against live `open_issues` and `prs`: only confirm an item closed/merged when `open_issues` and `prs` coverage are `ok` (if either lookup failed or truncated, mark unverified rather than silently dropping carryovers).
     - **Newly assigned issues, PR reviews & comment remediations:**
       - Assigned issues: open issues where `operator` is in `assignees` not already in prior-day continuation.
       - PRs awaiting review: open non-draft PRs where `operator` is in `reviewRequests` (adding `reviewRequests` to `get_open_prs` at `:334`; requested team slugs are surfaced with a `team:<slug>` note since team membership is not expanded offline).
       - PR comment & CI remediations: for open PRs authored by `operator`, flag `reviewDecision == "CHANGES_REQUESTED"`, `ci_status == "FAILURE"`, and unresolved inline review threads fetched via a bounded GraphQL query (`gh api graphql` querying `repository.pullRequest.reviewThreads(first:100){pageInfo{hasNextPage} nodes{isResolved isOutdated}}` for the operator's open PRs; if `hasNextPage` is true or the query fails, record a `truncated`/`failed` coverage entry).
     - **Earliest-Starter / Already Checked Out Calibration:** From verified comments on today's ledger issue(s), order starters by their preserved `started:<ISO-8601>` timestamp (or comment `createdAt` fallback, preserved across same-day `PATCH` edits). Combine with live GitHub signals (`in progress`/`🚧` labels, issue assignees, open PR `headRefName` + authors) and this device's extended `scan_local_checkout` rows (local branches, linked worktrees from `git worktree list --porcelain`, and read-only `.tick` claims), explicitly labeling provenance (`verified-ledger-claim`, `github-label-or-pr`, `local-device-only`) and flagging collisions with `operator`'s candidate queue.
   - **Authenticated ownership check on both `POST` and `PATCH` (`sync_daily_ledger_comment`):** Query authenticated GitHub user (`auth_login` via `gh api user -q .login`). Before creating an issue, `POST`ing a new comment, or `PATCH`ing an existing comment on `--publish-ledger`:
     - Require `auth_login` to resolve non-empty and require `operator.lower() == auth_login.lower()` (with the sole exception of first-time `POST` or issue creation when `--allow-delegate-comment` is explicitly set AND `auth_login.lower()` is in `trusted_bots`). Otherwise, if `--operator` does not match `auth_login`, refuse with exit 3 on both first publication (`POST`) and update (`PATCH`).
     - Before `PATCH`ing an existing comment whose first line matches `<!-- daily-ledger:<operator>:<device>:<date_local> ... -->`, unconditionally verify `comment["user"]["login"].lower() == auth_login.lower()` (even when delegation is enabled); if another GitHub user authored the comment, refuse to `PATCH` (exit 3) so a forged marker can never cause one user's comment to be overwritten or hijacked.
2. **Update `skills/2-daily/daily-planner/SKILL.md` (and `skills/3-weekly/weekly-planner/SKILL.md` linkage notes) to chain `/recon` and `/debug-mantra` into the Daily Work Ledger workflow:**
   - Keep Rebalance's `/daily` untouched as the 15-minute local prompt/telemetry synthesizer; document in `daily-planner/SKILL.md` that `/daily-planner` (also triggered on `"daily work ledger"`, `"start my day"`, `"calibrate my day"`, `"what is already checked out today"`) owns the GitHub Daily Work Ledger issue workflow alongside its weekly-plan pivot.
   - Codify the mandatory **Recon + Debug-Mantra Grounding Ladder** in `daily-planner/SKILL.md`:
     - **Step 1 (Mantra Recital & Live Ledger Discovery):** Recite `/debug-mantra` verbatim; run `planner_core.py --mode ledger` to inspect today's and yesterday's Daily Work Ledger GH issues, open PRs, assigned issues, and earlier operators' checkouts.
     - **Step 2 (Multi-Operator Checkout Calibration):** Inspect the earliest starter's comment and live GitHub/local claims to de-conflict today's queue before selecting tasks.
     - **Step 3 (Bounded `/recon` & `/debug-mantra` on Top Candidates):** For the operator's top carry-over task, newly assigned issue, or PR needing comment remediation, run bounded `/recon` (entry points, state writers, Step N+1 consumer progress) and `/debug-mantra` (verify raw PR review comments, failing check logs, and live file:line state; falsify stale assumptions) before posting the operator's calibrated daily plan comment.
     - **Step 4 (Publish / Sync Comment on Today's Ledger Issue):** With operator confirmation (`--publish-ledger`), create today's `"Daily Work Ledger — YYYY-MM-DD"` issue if none exists and post/update the operator's marker-tagged comment (`<!-- daily-ledger:<operator>:<device>:<YYYY-MM-DD> started:<ISO-8601> -->`).
3. **Verify in a disposable full clone and record receipts under `TESTS-RESULTS/`:**
   - Run offline stubbed negative/positive controls for `--mode ledger` (discovery completeness/truncation refusal, concurrent-create `min(number)` reconciliation, prior-day comment carryover across devices and closed-item filtering, PR review-request and GraphQL unresolved-thread remediation detection, earliest-starter timestamp ordering and collision flagging, authenticated comment-author ownership enforcement on `PATCH`, and `--repo-mode` execution in `forge`, `vendored`, and `gh-only` targets without a weekly baseline) plus `bash utils/pdda/pdda.sh run`, `python3 utils/pdda/check_inventory_ratchet.py --check`, and `bash validate.sh --parallel 4` in a disposable gate clone.

## Blast radius

| Seam | Current owner (`file:line`) | Change & N+1 downstream consumer impact |
|---|---|---|
| Shared planner CLI & modes | `skills/3-weekly/weekly-planner/scripts/planner_core.py:1835-1955` | Add `--mode ledger`, `--repo-mode {auto,forge,vendored,gh-only}`, `--publish-ledger`, `--ledger-issue <n>`, `--ledger-tz`. Include `"ledger"` in the `:1871` `get_open_prs` coverage-gap guard. Existing modes keep their exact CLI signatures and JSON/MD outputs. |
| PR & issue metadata intake | `skills/3-weekly/weekly-planner/scripts/planner_core.py:259-275,326-343` | Add `reviewRequests` to `get_open_prs` JSON fields at `:334` and a bounded GraphQL `reviewThreads` helper for the operator's open PRs in `--mode ledger`; additive keys are ignored by `detect_merge_sequence`, `audit_adversarial`, `site_build.py`, and `rollup.sh`. |
| Comment marker sync & auth | `skills/3-weekly/weekly-planner/scripts/planner_core.py:1635-1684` | Add `sync_daily_ledger_comment` supporting `<!-- daily-ledger:<operator>:<device>:<date> started:<ts> -->` with `comment.user.login == auth_login` ownership verification before `PATCH`. |
| Daily planner skill contract | `skills/2-daily/daily-planner/SKILL.md:1-120` | Document the Daily Work Ledger GH issue workflow, `/recon` + `/debug-mantra` grounding steps, earliest-starter checkout calibration, and `forge`/`vendored`/`gh-only` mode auto-detection. |
| Weekly planner linkage doc | `skills/3-weekly/weekly-planner/SKILL.md:48-51,142-153` | Document `--mode ledger` in the shared engine overview so both skills stay drift-free. |

Recon: `7acaa2450` · integration base: `development@6f4dbaf9c`. Truthful write-set: `skills/3-weekly/weekly-planner/scripts/planner_core.py`, `skills/2-daily/daily-planner/SKILL.md`, `skills/3-weekly/weekly-planner/SKILL.md`, and manual verification receipts under `TESTS-RESULTS/` when executed. Builder/reviewer route: Codex builder + Agy or Codex relay reviewer (`ci-route` classifies `skills/**` as `docs` / tier 1; declared gate + full `validate.sh --parallel 4` run in a disposable gate clone per GH-1184 precedent).

## Dependencies

- None blocking. Reuses `skills/3-weekly/weekly-planner/scripts/planner_core.py` (including GH-1184's comment sync and local root scanner) and composes with `/recon` (`skills/1-hourly/recon/SKILL.md`) and `/debug-mantra` (`skills/1-hourly/debug-mantra/SKILL.md`). Compatible with GH-1022 (`weekly` intake) and GH-1340/GH-1345 (`releases.db` read-only inspection).

## Acceptance

- [x] `planner_core.py --mode ledger` resolves today's `"Daily Work Ledger — YYYY-MM-DD"` issue (by exact title regex or `--ledger-issue <n>`) and the most recent prior workday's ledger (`date < today`) even when >100 historical ledger issues exist in the repo, reconciles concurrent same-day issues by selecting `min(number)` as canonical while reading comments across all same-day matches, creates today's issue only when `--publish-ledger` is set and discovery coverage is `ok`, and ingests verified prior-workday comments across any device for the operator; red control: (a) a stubbed repo with >100 historical ledger issues — including the mixed-page duplicate case (1 today issue + 100 yesterday duplicate issues where the oldest canonical `min(number)` yesterday issue is on page 2) and a backfilled older ledger created more recently than yesterday's ledger — paginates to completeness and resolves both today's canonical `min(number)` issue (`#200` over `#201`, merging comments from `#201`) and the true maximum prior title date's canonical `min(number)` issue and all of its comments, (b) a stubbed verified prior ledger comment from `laptop-a` referencing a closed issue and a merged PR drops both when live lookups are `ok` while retaining open items when running on `studio-b` (cross-device positive control), and (c) an unresolvable/failed discovery lookup or missing `--gh-repo` slug with failed `gh repo view` records a coverage gap and exits 3 on `--publish-ledger` without creating an issue (evidence in `TESTS-RESULTS/<date>+GH-<n>/`).
- [x] `planner_core.py --mode ledger` authenticates ledger claim markers on **ingestion** (requiring a first-line marker matching the target ledger date AND `comment.user.login.lower() == marker_operator.lower()`, rejecting quoted line-2+ markers, shared issue body text, and forged comments where `comment.user.login != marker_operator`), computes an "Already Checked Out / Earliest Starter Calibration" section ordered by preserved `started:<ISO-8601>` timestamp, extends `scan_local_checkout` to enumerate linked git worktrees (`git worktree list --porcelain`) and active `.tick` claims read-only via the canonical `tick claims --json` command only (with target root pinned and no parallel Python event-folding fallback), labels each claim with provenance (`verified-ledger-claim`, `github-label-or-pr`, `local-device-only`), and flags collisions; red control: (a) injecting a verified earlier operator comment claiming `GH-999` surfaces `GH-999` as `verified-ledger-claim` and flags a collision, (b) injecting a forged first-line comment (`comment.user.login="mallory"` with marker operator `"alice"` claiming `GH-998`) and a line-2 quoted marker (`GH-997`) rejects both from carryover and from `verified-ledger-claim` collision suppression, (c) a clean tracked git worktree (0 dirty, 0 ahead) on branch `feat/gh-996-clean` and a live `.tick` claim on `gh-995` with 0 dirty/ahead git state both surface as `local-device-only` checked-out items and flag collisions, and (d) when `.tick/events` contains corrupt JSONL causing `tick claims --json` to exit 3, `coverage.tick_claims.status` records `"failed"` with a visible warning rather than falling back to a Python replay or reporting an `ok` empty claim set (evidence in `TESTS-RESULTS/<date>+GH-<n>/`).
- [x] `planner_core.py --mode ledger` surfaces the operator's newly assigned open issues, PRs requesting their review (`reviewRequests`), and their open PRs needing remediation (`CHANGES_REQUESTED`, failing `statusCheckRollup`, or unresolved review threads via `reviewThreads` where `isResolved == false`), marks `coverage.open_prs.status = "truncated"` when `len(prs) >= 300` (the `get_open_prs` cap), and enforces `operator.lower() == auth_login.lower()` on **both `POST` and `PATCH`** while unconditionally verifying `comment.user.login.lower() == auth_login.lower()` before `PATCH`; red control: (a) a PR with `isResolved == true` threads only is excluded from comment-remediation while `isResolved == false` is included, (b) a second same-day run by the authenticated author `PATCH`es the existing comment (`created_count == 0, patched_count == 1` with original `started:` timestamp preserved), and (c) both a first-time `POST` with mismatched `--operator != auth_login` and a `PATCH` when an existing comment has `comment.user.login != auth_login` (forged marker) are refused with exit 3 (evidence in `TESTS-RESULTS/<date>+GH-<n>/`).
- [x] `planner_core.py` supports `--repo-mode {auto,forge,vendored,gh-only}` (precedence: `--repo-mode` > `XYZ_DAILY_LEDGER_MODE` > `device_config.json` `daily_ledger_mode` > `auto`), running end-to-end without requiring a weekly plan baseline in all three modes; red control: running `--mode ledger --repo-mode auto` against (a) a temp git checkout containing `.xyz/` and no `releases.db` or weekly baseline selects `vendored` and completes the ledger report (exit 0), and (b) a plain git checkout with neither `releases.db` nor `.xyz/` selects `gh-only` and completes the ledger report (exit 0), while failing if the mode classifier is broken (evidence in `TESTS-RESULTS/<date>+GH-<n>/`).
- [x] `skills/2-daily/daily-planner/SKILL.md` (and `skills/3-weekly/weekly-planner/SKILL.md`) documents the Daily Work Ledger workflow, explicitly preserving Rebalance's `/daily` skill as separate and chaining `/recon` and `/debug-mantra` to ground candidate issues and PR remediations before publishing; red control: `bash utils/pdda/pdda.sh run` and `python3 utils/pdda/check_inventory_ratchet.py --check` exit 0, and removing the `## Daily Work Ledger` heading or `planner_core.py --mode ledger` reference causes the verification probe to fail (evidence in `TESTS-RESULTS/<date>+GH-<n>/`).

## Verification

- Existing suites and gates: `bash utils/pdda/pdda.sh run`, `python3 utils/pdda/check_inventory_ratchet.py --check`, `python3 -m pytest test/test_python_layer.py`, and full `bash validate.sh --parallel 4` in a disposable gate clone (no new permanent test files under `test/`, honoring `AGENTS.md:162` *No new tests* / GH-831).
- Manual verification harness and negative controls recorded under `TESTS-RESULTS/<date>+GH-<n>/` with `provenance.jsonl` (using temporary `$TMPDIR` stubs during the run, never committed under `test/`), exercising: (1) today/yesterday ledger discovery, truncation/failure refusal, and concurrent-create `min(number)` tie-break; (2) cross-device prior-day comment carryover and live open/closed filtering; (3) `reviewRequests` and GraphQL `reviewThreads` (`isResolved == false` vs `true`) remediation classification; (4) earliest-starter timestamp preservation and checkout collision detection; (5) authenticated comment-author ownership enforcement (refusing forged markers); and (6) end-to-end `--mode ledger` runs across `forge`, `vendored`, and `gh-only` targets without a weekly baseline.

## Non-goals

- Replacing or modifying Rebalance's `/daily` skill (the 15-minute local prompt/telemetry synthesizer in `rebalance-OS`).
- Creating a standalone new skill folder, a new script under `utils/`, `scripts/`, or `bin/`, or a new `sqlite3.connect` call (GH-777 ratchet).
- Adding new test files under `test/` or modifying `validate.sh` (GH-831).
- Mutating `releases.db`, auto-dispatching Jog/Marathon lanes, or closing/merging GitHub issues/PRs from the ledger scan.

## Risk and rollback

- **Risk:** Low (`risk: 1`). All changes are additive (`--mode ledger` and `--repo-mode` in `planner_core.py` plus documentation in `daily-planner/SKILL.md` and `weekly-planner/SKILL.md`). Default execution without `--publish-ledger` writes only to gitignored `temp/planner/*`; GitHub writes are gated behind `--publish-ledger`, refuse on discovery coverage gaps, reconcile concurrent same-day issues via `min(number)`, and verify `comment.user.login == auth_login` before `PATCH`ing any comment.
- **Rollback:** Revert the commit touching `planner_core.py`, `daily-planner/SKILL.md`, and `weekly-planner/SKILL.md`. For any already-published GitHub state, close duplicate test ledger issues (referencing the canonical `min(number)` issue) or delete/revert test comments via `gh api --method DELETE/PATCH repos/{slug}/issues/comments/{id}`. No database schema or local git state migration is involved.

## PRS proposal

- pri 70: Operator-requested daily coordination workflow across XYZ Forge dogfooding and vendored repos so multiple operators can continue yesterday's work, triage new assignments/PR reviews, and see what earlier starters already checked out.
- sev 45: Without a shared daily ledger issue and checkout calibration, operators risk duplicate task pickup, missed PR comment remediations, and manual context reconstruction each morning, though no data corruption occurs.
- appeal 50: Neutral appeal default per `/idea` rubric; operator requested the workflow directly without specifying a custom numeric appeal override.
- effort 55: Moderate cheapness — extends `planner_core.py` (reusing GH-1184's comment sync and local checkout scanner) plus skill docs, while accounting for paginated comment/thread lookups, canonical `min(number)` issue reconciliation, and comment-author ownership checks.

## Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash utils/pdda/pdda.sh run && python3 utils/pdda/check_inventory_ratchet.py --check && python3 -m pytest test/test_python_layer.py",
  "round_cap": 2,
  "fix_probes": [
    {
      "type": "grep_absent",
      "path": "skills/3-weekly/weekly-planner/scripts/planner_core.py",
      "pattern": "<!-- daily-ledger:"
    },
    {
      "type": "grep_absent",
      "path": "skills/2-daily/daily-planner/SKILL.md",
      "pattern": "Daily Work Ledger"
    }
  ],
  "artifacts": [
    "skills/3-weekly/weekly-planner/scripts/planner_core.py",
    "skills/2-daily/daily-planner/SKILL.md",
    "skills/3-weekly/weekly-planner/SKILL.md"
  ],
  "remediation": {
    "source": "issue#1459",
    "criteria": "Extend planner_core.py with --mode ledger and --repo-mode {auto,forge,vendored,gh-only} to find/create today's Daily Work Ledger GH issue, carry forward yesterday's unfinished items, surface assigned issues and PR reviews/comment remediations, calibrate against earlier operators' checkouts, and document the /recon + /debug-mantra workflow in skills/2-daily/daily-planner/SKILL.md."
  }
}
```

Recon: 7acaa2450 · base: development@6f4dbaf9c · tier: standard · review: consult daily-work-ledger-idea-170103 models=codex,agy hash 4664386b83a0e321a7a2ea7fcf942e3e043998a2f14f2cfff433ff30c0cb807e

## Why

Give operators across XYZ Forge dogfooding and vendored (.xyz/) repos a shared per-day GitHub Daily Work Ledger issue that carries forward yesterday's unfinished work, surfaces newly assigned issues and PR review/comment remediations, calibrates what work earlier starters already checked out, and chains /recon and /debug-mantra without inventing a parallel skill or replacing Rebalance /daily.

## Phase 0 — Explore & scope

### Checklist

- [x] Recon-lite and debug-mantra grounding on `planner_core.py` and `daily-planner/SKILL.md`.
- [x] Cross-model `/consult` review (`daily-work-ledger-idea-170103`) and disposition of findings.
- [ ] Step 6 independent Codex relay plan QA approval.

### QA checklist — Phase 0

- [x] Preflight contract dry-run exits 0 (`ready`).
- [ ] Codex relay plan QA reaches `Approved`.
