---
title: "daily-planner: read-only Stalled & stale section, one dated comment per device on the weekly issue"
status: "Active (2-WORKING)"
created: 2026-10-22
updated: 2026-10-22
owner: agent-b
gh_issue: 1184
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1184
doc_type: feature
complexity: 2
risk: 1
effort: 2
phases: 1
rating: "pri/sev/appeal/effort 50/30/50/45 · calc 175"
non_goals:
  - An `arc` skill, 3-day cycles, tracking-issue creation/closing, or cross-device writes to a shared body (#1183, retired)
  - Dispatch, merging, re-rating, ledger writes, or closing member issues/PRs
  - The launchd scheduler itself (#1168 owns it; enabling any job is a separate approval) or a new collection daemon
  - A new script under utils/, scripts/ or bin/, or any new `sqlite3.connect` (GH-777 ratchet, #1182)
  - New test suites or validate.sh registry entries (GH-831); porting to XYZ-mini (adapted skill, forge-only change)
related:
  - GH-1183
  - GH-1168
  - GH-1182
goal: >
  `/daily-planner` gains a read-only "Stalled & stale" section (GitHub items idle N days
  plus this device's unpushed/uncommitted/orphaned branches and open session notes),
  with Held items listed separately, written into the existing daily pivot files and,
  with --team-issue, posted as one dated comment per device per day on the weekly issue
  (a same-day re-run edits its own comment). A headless `--mode stalled` runs only that
  scan and comment so the shared scheduler (#1168) can call it later.
---

# GH-1184 - daily-planner: read-only Stalled & stale section (slim successor to #1183)

## Status

| What was just completed | What's next |
|---|---|
| Intake parked (`rmi-01M5KMYBGA9R5BE619TX3MY0N3`), rated 50/30/50/45, promoted; recon of `planner_core.py`, comment-edit pattern, device identity, local-scan helpers, tests/CI/ratchet done; plan written. | Codex relay plan QA (`relay-system/2026-10-22/gh1184-plan-qa.md`, cap 3) → implement in this clone → full gate in a disposable `-gate` clone → smoke receipt → final relay QA → PR against `development`. |

## Observed Problem & Recon

Base: `origin/development` @ `eb0623ce` (task clone `XYZ-forge-gh1184-stalled-stale-section-2026-10-22`).
**P** = `skills/3-weekly/weekly-planner/scripts/planner_core.py` (1352 lines, the only planner script).

- **Entry point.** `main` (P:1271-1348): flags `--repo-root`, `--gh-repo`, `--mode {weekly,daily,audit,sequence,intake}`,
  `--plan-file`, `--decisions-issue`, `--team-issue/--issue` (int), `--hours` (36), `--fallback`. Every mode first runs
  `get_open_prs` + `detect_merge_sequence` (P:1289-1290). `daily` = `pivot_daily` + `audit_adversarial`, writes
  `temp/planner/daily-pivot-<date>.json` and `DAILY-PIVOT-<date>.md` (P:1304-1320); `date_str` is UTC (P:1301).
  `/daily-planner` (SKILL.md:14,30) runs it by subprocess with `--mode daily`; `pivot_daily` raises without a weekly
  baseline (P:732-736).
- **Data already pulled.** `get_open_prs(limit=300)` (P:326-341): `number,title,author,headRefName,baseRefName,
  mergeable,reviewDecision,reviews,updatedAt,statusCheckRollup,files,body,isDraft`; at the limit it only WARNs.
  `get_open_issues(limit=500)` (P:259-275): `number,title,url,labels,assignees,body,updatedAt`; at the limit it raises.
  `fetch_recent_merges` / `fetch_recent_closed_issues` (P:607-670): `--search merged:>=/closed:>=`, limit 200, no
  truncation warning. `run_cmd` (P:25-36) raises `RuntimeError` on non-zero exit, no timeout.
- **Holds already classified.** `detect_merge_sequence` (P:344-486): hold predicates P:399-415 (title `HOLD`/`[HOLD]`,
  `leave unmerged`, `not an authorized merge`, `prerequisites required|live-pilot`, `review authority limit`),
  evidence carriers P:418-427; phase `evidence_carriers_or_held` (rendered as "Phase 5" in the weekly MD, P:1120).
  Labels are never consulted. Classification order P:436-447; prerequisites demotion P:451-467.
- **Daily rendering.** `format_daily_markdown` (P:1188-1268) emits sections 1–4 (`Accomplished Yesterday`, `P0 Blocker`,
  `Active PR Merge Sequence`, `Adversarial Audit Findings`). daily-planner SKILL.md:42-43,59 claim phases/queues the
  daily MD does not render (pre-existing drift, noted).
- **`--team-issue` today** (P:911-925, weekly only): `gh issue view <n> --json body,assignees,title`, parses
  `Name -> domain` teammates, WARNs on failure, never writes. **No code in P posts or edits comments.**
- **Comment find/edit pattern exists elsewhere:** `utils/py/marathon_drive.py` `runlog_find_comment_id` (:332-362) +
  use site (:1696-1722): marker `<!-- … -->` in the body, `gh api --paginate --slurp repos/{r}/issues/{n}/comments
  ?per_page=100`, `PATCH repos/{r}/issues/comments/{id}` when found else `POST`. Importing marathon_drive is heavy
  (top-level `harness_paths`, `rtl`, `relay_attest`), so the ~15-line pattern is copied with a citation.
- **Device identity.** `utils/py/device_config.py` `resolve_device_setting("device_id","XYZ_DEVICE_ID")` (:120-140),
  default `platform.node()` (:19); stdlib-only, importable via `sys.path` insert of `utils/py`. On this machine the
  three ids differ (`noels-Mac-Studio.local` / git-pulse `noels-mac-studio` / `hostname -s` `noels-Mac-Studio`) →
  normalize (lowercase, strip `.local`).
- **Local roots.** `~/marathon-clones` has 122 entries, 32 git checkouts, 16 XYZ-forge clones by origin URL, 2 linked
  worktrees, 6 clones-of-clones with a local-path origin, 4 foreign repos; `~/Documents/GH Repos/XYZ-forge-*` holds 19
  start-task clones. `skills/2-daily/merge-cleanup/scripts/scan_clones.py` enumerates and classifies checkouts but
  `classify_local_refs` (:525) and `published_pr_head` (:494) **fetch**, `inspect_open_handles` runs lsof (120 s) —
  not read-only or fast enough for a daily scan. No `for-each-ref … %(upstream:track)` helper exists (gap);
  single-branch versions at `standup/collect.sh:343,361`, `swarm_preflight.py:1302`.
- **Notes.** PARKED lens 8 (`standup/collect.sh:1046-1169`) is inline Python in bash (not importable; `— check:` lines
  only). `utils/py/poll.py` `relay_field(file, key)` / `relay_next_agent` (:74-90) parse `NEXT:`/`STATUS:` headers of
  relay threads — small, importable.
- **Tests / gate / ratchet.** No test exercises P or either planner SKILL (`gh418`/`gh698` cover `marathon_plan.py`).
  `utils/ci-route.sh pull_request` on `P` + `daily-planner/SKILL.md` → `route=docs tier=1` (`is_docs_surface` :63-70;
  no planner subsystem). Ratchet baseline has zero planner_core entries; `scan_scripts` scans only `utils/`, `scripts/`,
  `bin/` (:50-61); P's existing `sqlite3.connect` at P:814 carries `SQLITE-GATEWAY-OK`. Adding code to P adds no
  ratchet debt; a new file under `utils/**` or an unmarked connect would.
- **Mini sync.** `utils/py/xyz_mini_sync.py:71-72` marks both planner skills `adapted` (seeded once, never replaced);
  `test/gh589-xyz-mini-sync.sh:95-126` asserts forge drift is NOT shipped. This change is forge-only by construction.
- **Name/claim checks.** A session hook asserted "start-marathon already does this"; `start-marathon/SKILL.md` uses
  "stale" only for `STALE-CLOSED`/`CONTRACT-STALE` capture states of marathon candidates (:177,:179) — not a stalled-
  work report. Not a duplicate.

## Preflight Bet Check (Solution-Fit)

- **Outcome sought:** each morning, on whichever Mac the operator runs `/daily-planner`, one list of what they
  started and left hanging (PRs, issues, local branches, open session notes), with holds separated and a next action
  per row; visible to the other Mac via one comment per device on the weekly issue.
- **Smallest viable bet:** ~300 lines added to P (one collector, one formatter, one comment poster, one new `--mode`,
  four flags) + daily-planner SKILL.md text. NOT built: a new script or skill, a scheduler, a shared body, a
  daemon, label management, a test suite, a mini port.
- **Alternatives rejected:** (a) a separate `stalled_core.py` — a second planner script and (under `utils/`) ratchet
  debt; (b) reusing `scan_clones.inspect_checkout` for the local scan — it fetches and runs lsof, violating "read-only"
  and the daily time budget; (c) comments-only without the local section in the pivot files — the operator asked for
  the section in `/daily-planner` output.
- **Rollback / containment:** revert the P hunk and SKILL.md lines; delete that day's comments by hand. No ledger,
  schema, label, or shared-contract change; `--mode daily` without `--team-issue` writes only local files.

## Design decisions

1. **One collector, pure over inputs:** `collect_stalled_stale(prs, issues, sequence, merges, closed_issues, now,
   stale_days, draft_stale_days, device, local_rows, coverage) -> dict` with keys `stalled`, `held`, `local`,
   `coverage`, `generated_at`, `device`, `thresholds`. Rows: `{kind, ref, url_or_path, device, last_activity,
   reason, next_action}`.
   - GitHub stalled: open non-draft PR not in `evidence_carriers_or_held` with `updatedAt` older than `stale_days`
     → `next_action: rebase|resume|close`; open draft idle `draft_stale_days` → `resume|close`; open issue assigned
     to the operator (login from `gh api user`, cached per run; override `--operator`) or labelled `in progress`/
     `🚧`, idle `stale_days` → `resume|route to weekly`. `updatedAt` is GitHub's own last-activity (commits, review,
     comment all bump it), which is the issue's "no commits, review or comment in N days".
   - Held (never stalled): every PR in `evidence_carriers_or_held` with its `hold_reason`; any PR/issue with label
     `hold` or `parked`; owner decisions already encoded by the engine (`leave unmerged`, `not an authorized merge`).
   - Local (this device only, read-only): for each root in `--local-roots` (default: `--repo-root` + every
     `~/marathon-clones/*` whose `origin` is the target repo, following one hop of local-path origins), run
     `git for-each-ref refs/heads --format='%(refname:short)%00%(upstream:short)%00%(upstream:track)%00%(committerdate:iso8601)'`
     and `git status --porcelain` (count only); no `fetch`, `prune`, `worktree prune`, or any write. Rows: branch with
     `ahead N` or no upstream and a commit in the window → `push or open PR`; dirty tree → `commit or stash`
     (count only); branch whose head ref name matches a merged/closed PR (`gh pr list --state all --limit 300 --json
     headRefName,state,number` keyed by name) → `retire clone/branch`. Notes: `PARKED/*.md` and
     `relay-system/**/*.md` under the target checkout with mtime in the window; a relay thread counts only when
     `STATUS:` (via `poll.relay_field`) is not `Approved|Closed`; published as path + mtime + `STATUS`, never contents.
   - Coverage: every external read is wrapped; failure → `{source, status: failed, error}`; a list at its limit →
     `status: truncated`; a missing root → `status: absent`. The section header prints coverage before rows, and an
     empty Stalled list with any gap renders `no stalled items observed — coverage incomplete`, never "nothing stalled".
2. **Daily integration:** in `--mode daily` the collector runs after the sequence with the already-fetched `prs`,
   `issues` (fetched once for this), merges/closures from `pivot_daily`'s window; result stored at
   `result["stalled_stale"]` and rendered as `## 5. Stalled & stale` by `format_stalled_markdown(section)` which
   `format_daily_markdown` calls. With `--team-issue` the same rendering is posted (decision 4).
3. **Headless `--mode stalled`:** does NOT call `pivot_daily` (no baseline needed), runs the collector and writes
   `temp/planner/stalled-<date>.{json,md}`; with `--team-issue` posts the comment; prints one summary line; exit 0,
   or 2 on usage, 3 when the weekly-issue comment could not be read/written (coverage gaps alone never fail the run).
   Non-interactive by construction (no prompts anywhere in P).
4. **Comment contract:** header `Stalled & stale — <device> — <YYYY-MM-DD>` and hidden marker
   `<!-- planner-stalled:<device>:<YYYY-MM-DD> -->` as the first line. Find via
   `gh api --paginate --slurp repos/{slug}/issues/{n}/comments?per_page=100`; if a comment with this device+date
   marker exists → `PATCH repos/{slug}/issues/comments/{id}`, else `POST`. Two devices → two markers → two comments.
   `{slug}` = `--gh-repo` or `gh repo view --json nameWithOwner`. Device = `--device-id` or
   `resolve_device_setting("device_id","XYZ_DEVICE_ID")` normalized (lowercase, `.local` stripped). The same comment
   listing yields every `planner-stalled:<dev>:<date>` marker, so the section's coverage block lists each known device
   with its latest date and `no report from <device> since <date>` when it is not today.
5. **Dates:** `<date>` is the device's local date (the comment is a morning report), while the pivot filename keeps
   P's UTC `date_str` unchanged; both are printed in the header.
6. **Writes, exhaustively:** `temp/planner/*` (gitignored), and — only with `--team-issue` — one comment create or
   edit on that issue. No label changes, no body edits, no ledger, no git mutation.

## Rating Rationale (2026-10-22)

`rated 50/30/50/45`. Consequence: forgotten in-flight work and stale PRs cost re-discovery time and occasional
duplicate effort; no data loss, no crash — low-mid severity (30). Priority 50: asked for now, compounds with the
daily/weekly planners in use, slim scope. Appeal 50 (no preference given). Effort 45 (cheapness): ~300 lines in one
existing script plus doc text; the local scan and the comment edit are the only new mechanics. Recurrence:
operator-reported recurring problem; the retired #1183 is the same ask — unknown count, not zero.

## Ordered Implementation & Verification Plan

Operational envelope: a local, operator-attended (or later scheduler-invoked, non-interactive) CLI run from one
checkout on macOS; python3 stdlib; `gh` on PATH. Not a service. No new tests (GH-831). Reversibility: Easy.

1. **P:** add `--mode stalled`, flags `--stale-days 3`, `--draft-stale-days 7`, `--local-roots` (repeatable),
   `--device-id`, `--operator`; functions `collect_stalled_stale`, `scan_local_roots`, `format_stalled_markdown`,
   `post_stalled_comment` (with the copied `find_comment_id` pattern, cited to `marathon_drive.py:332-362`); wire the
   daily branch (`result["stalled_stale"]`, section 5, optional comment) and the stalled branch. Keep P's existing
   `sqlite3.connect` untouched; the collector never opens the ledger (it does not need it).
   Verify: `python3 -c "import ast; ast.parse(...)"`; `--mode stalled --repo-root . --gh-repo HiQS-Labs/XYZ-forge`
   without `--team-issue` writes the two files and posts nothing.
2. **daily-planner SKILL.md:** add the "Stalled & stale" step (what is collected, Held vs Stalled, coverage line,
   `--team-issue` comment contract, flags, the headless `--mode stalled` command for #1168 and that scheduling is not
   enabled here); fix the drift sentence about daily phases. weekly-planner SKILL.md:50 "imports and calls" → "runs
   by subprocess" (one-line truth fix in the file this change already touches).
   Verify: `bash utils/pdda/pdda.sh run` (docs gate) in the task clone.
3. **Full gate (lesson of #1182):** in a disposable `<folder>-gate` clone at the final commit run
   `python3 utils/pdda/check_inventory_ratchet.py --check` and `bash validate.sh --parallel 4`; both must be green
   even though `ci-route` classifies the change docs/tier 1.
4. **Smoke (GH-1088)** recorded under `TESTS-RESULTS/2026-10-22+GH-1184/` with `provenance.jsonl`, using a stub `gh`
   on PATH for the negative controls (stub is a temp file, not a fixture):
   - main: `--mode stalled --team-issue <weekly issue>` on the live repo → one comment with today's marker for this
     device; the section lists coverage first; the live weekly issue is the real target (comment is reversible).
   - adjacent: immediate re-run → the same comment is edited (comment count unchanged, body updated); second device
     simulated with `--device-id other-mac` → a second comment; `--mode daily` without `--team-issue` → section 5 in
     `DAILY-PIVOT-<date>.md`, no comment; `--mode daily` without a baseline → still fails exactly as today (unchanged).
   - held vs stalled: a `HOLD` PR and an `evidence carrier` PR in the stub data appear under Held, not Stalled; an idle
     non-draft PR appears under Stalled with `rebase|resume`.
   - gaps: stub `gh pr list` exits 1 → coverage `failed`, Stalled header says `coverage incomplete`; stub returns 300
     PRs → `truncated`.
   - local read-only: run against a throwaway clone with an unpushed branch, a dirty file and a branch whose PR
     merged → three rows; `git reflog`/`git status` before and after identical; `git fetch` never invoked (stub `git`
     wrapper logs argv; red control: any `fetch|prune|push|checkout` in the log fails the check).
   - secrets: the comment body contains no file contents (grep the posted body for a sentinel string placed in a
     PARKED note → absent).
5. Final Codex relay QA on the diff + smoke receipt; PR against `development` referencing #1184, noting: forge-only
   (mini `adapted`), scheduler not enabled, and the acceptance line "covered by an extension to the existing
   daily-planner/planner_core tests" is satisfied by the recorded manual smoke because **no such test exists** and
   GH-831 forbids adding one — flagged for the operator in the PR.

### Test non-scope

No new `test/` suite, no `validate.sh` registry entry, no committed fixture or stub. The stub `gh`/`git` used in the
smoke live under `$TMPDIR` for the run and are quoted in the receipt.
