---
gh_issue: 1421
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1421
title: "board_sync repos_source: opt-in read of Rebalance agent_session_activity (T3 work signal)"
status: Active (2-WORKING — PR ready; awaiting merge)
created: 2026-11-11
updated: 2026-11-11
owner: claude (start-task)
doc_type: feedback
complexity: 2
risk: 2
effort: 2
phases: 1
non_goals:
  - no Rebalance DB writes
  - no github_activity semantics change
  - no new board columns
related:
  - HiQS-Labs/rebalanceOS#375
  - "#1000"
  - "#899"
  - "#898"
goal: >
  With an opt-in `include_agent_sessions: true` in the board selection policy's `repos_source`,
  repos that have T3 agent activity in Rebalance's `agent_session_activity` (and no GitHub activity)
  join the board's resolved repo list, ranked after the GitHub-active repos. With the key off the
  output is unchanged. The live read-only open failure on this Mac is root-caused and named in the warning.
---

## Status

| What was just completed | What's next |
|---|---|
| Plan QA Approved (Codex, round 3; `relay-system/2026-11-11/gh1421-plan.codex.md`), `--accepted-start` recorded, implemented in `utils/py/board_sync.py`, verified (`TESTS-RESULTS/2026-11-11+GH-1421/SUMMARY.md`). | Codex final QA Approved (round 2, `relay-system/2026-11-11/gh1421-final.codex.md`; round 1 caught a `HAVING` alias bug, fixed in 2565f073b). Routed gate at push; ready PR; awaiting merge. Then the follow-up decision on reading the no-sidecar WAL DB (step 5). |

## Key concepts

- `board_sync`'s Rebalance `repos_source` (GH-898) adds the top active repos from Rebalance's
  `github_activity` to the pinned policy repos. Repos worked only through T3 agents never qualify.
- rebalanceOS#375 (merged as 88a8972, migration `0010_agent_session_activity.sql`) stores per-device
  T3 agent activity per (source, device, repo, UTC day, provider) with `runs` and other counts.
- The operator chose opt-in reads of the new table (2026-11-11), never writes into `github_activity`.
- The reader has never worked on this Mac: the DB is in persistent WAL mode with no sidecars, so
  `?mode=ro` cannot open it. This task documents the cause and names it in the warning; making it open
  safely is a follow-up decision (step 5).

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

## Idea

Follow-on to HiQS-Labs/rebalanceOS#375. That issue adds per-device T3 Code agent activity to Rebalance in a new table, `agent_session_activity`. The operator decided on 2026-11-11 that existing readers get the data through **opt-in reads of the new table**, not by writing into `github_activity`. This issue is the XYZ-forge reader: `board_sync`'s Rebalance `repos_source`.

## Observed (recon, 2026-11-11, base 046b41538)

- `utils/py/board_sync.py:133-161` `_rebalance_active_repos(source, limit)` opens the DB with one
  `sqlite3.connect(<uri>?mode=ro, uri=True, timeout=2)` annotated `SQLITE-GATEWAY-OK`. The GH-777
  ratchet (`utils/pdda/check_inventory_ratchet.py:65-83`) counts *unannotated* connect occurrences, so the
  annotation is what keeps it green (GH-898 marker round); keeping one annotated site is reuse, and a green
  ratchet alone does not prove there is one site. It runs one `github_activity` score query, warns and returns `[]` on any `sqlite3.Error`/`OSError`
  ("has no github_activity table" vs "is unreadable"), and warns when no rows are in window.
- Its only caller is `_resolve_policy_and_label` (`board_sync.py:169-232`), which validates `repos_source`
  (`type == "rebalance_active"`, positive-int `top_n`/`since_days`), merges results after the pinned repos
  with case-insensitive dedupe, an `owner/name` regex and a `top_n` cap, and sets the label
  `explicit+rebalance_active` / `explicit (rebalance_active fell back)`. `repos_source` is popped out of
  the policy dict, so apply/restore identity is the resolved `repos` list only. Consumers:
  `resolve_selection_policy` → `build_policy_preview` / apply / restore, and the offline `config` subcommand
  (prints `selection_policy_repos`).
- Settings come from `device_config.resolve_device_block("github_board_selection_policy", …,
  "XYZ_GITHUB_BOARD_POLICY")`; `repos_source` is a nested object in the device config (an env string is
  rejected as "must be an object"). The new key rides inside that object; no new env var.
- Upstream schema (rebalanceOS `src/rebalance/ingest/db/migrations/0010_agent_session_activity.sql`):
  `agent_session_activity(source, device_id, repo_full_name, day TEXT 'YYYY-MM-DD' UTC, provider, threads,
  runs, runs_completed, user_prompts, agent_threads, branches_json, pr_urls_json, first_at, last_at,
  scanned_at)`, PK (source, device_id, repo_full_name, day, provider), index on `day`. rebalanceOS's own
  reader (`queries.py`, "since `since_days` ago") filters `day >= <utc date N days ago>`, and returns `[]`
  on `OperationalError` before migration 0010.
- **`mode=ro` failure, cause confirmed.** On this Mac, `?mode=ro` fails with "unable to open database file"
  (SQLITE_CANTOPEN), reproduced in Python and with `/usr/bin/sqlite3 -readonly`, inside and outside the
  agent sandbox. **The connect succeeds; the first SELECT fails** (measured on the live DB and on a fixture). The DB header bytes 18–19 are `02 02` (persistent WAL mode; rebalanceOS's
  `connection.py` sets `PRAGMA journal_mode=WAL`), and the directory holds only `rebalance.db` — no `-wal`
  or `-shm`. On this Mac's SQLite (3.54.0, Apple build, Python 3.9) a `mode=ro` connection to a WAL database
  with no sidecars fails on first read and creates no sidecar, even in a writable directory. That is narrower
  than SQLite's general WAL docs, which allow a read-only connection to create sidecars when the directory is
  writable; the measured behaviour on this build is what the reader must handle. Fixture reproduction: write
  a WAL DB, `wal_checkpoint(TRUNCATE)`, close, delete the empty `-wal`/`-shm`; `mode=ro` then fails on the first
  SELECT and leaves the directory as it was. `?mode=ro&immutable=1` opens and reads
  (it reports `journal_mode=delete` only because immutable disables WAL). The issue's suspicion is
  confirmed. Consequence: GH-898's `repos_source` has silently fallen back to the pinned repos on this
  device, which raises severity above "missing signal" alone.
- Live data (read-only, immutable): 25 `agent_session_activity` rows, 3 repos, days 2026-10-13..2026-11-11;
  in the last 7 days all 3 agent repos also appear in `github_activity`'s top list. So turning the key on
  live adds no new repo today; the agent-only path is witnessed on a fixture.

## Plan

Extend the existing reader and resolver in `utils/py/board_sync.py`. No new module, no new writer, no
new subcommand.

1. **Policy key.** In `_resolve_policy_and_label`, default `include_agent_sessions` to `False` alongside
   `top_n`/`since_days`, and refuse a non-bool value with `ValueError("repos_source.include_agent_sessions
   must be true or false")`. It stays inside `repos_source`, which is already popped from the policy
   dict, so apply/restore identity is unchanged.
2. **Agent read, same connection.** In `_rebalance_active_repos`, after the existing `github_activity` query
   succeeds and only when the key is on, run on the same connection:
   `SELECT repo_full_name, SUM(runs) AS total_runs FROM agent_session_activity WHERE day >= date('now', ?)
   GROUP BY repo_full_name HAVING total_runs > 0 ORDER BY total_runs DESC, repo_full_name LIMIT ?`
   (final QA round 1: an alias named `runs` makes `HAVING runs` bind to the stored column, so a repo whose
   first row has 0 runs vanished; the alias must not collide with a column name) with the same
   `-N days` and `limit`. `date('now', …)` is UTC, matching the `day` column and the existing
   `scan_date` filter.
3. **Merge rule (documented).** The return value is the GitHub-ranked list exactly as today, followed by
   agent repos not already in it (case-insensitive), in `runs DESC, name` order. GitHub-active repos keep
   their GitHub order; agent-only repos rank after all of them. This is the issue's "agent-only ranked
   after GitHub-active" rule without re-scoring GitHub repos by `runs`: adding `runs` to a GitHub repo's
   score would reorder today's list for no stated gain. The caller's existing dedupe, regex and `top_n` cap
   apply unchanged. The empty-window warning fires only when the merged list is empty.
4. **Missing table / other agent errors.** The agent query runs in its own inner `try`, after the GitHub rows
   are in hand. If it raises `sqlite3.Error` containing "no such table", warn once
   ("repos_source: rebalanceOS DB has no agent_session_activity table (older Rebalance); using
   github_activity only") and return the GitHub list. Any other agent-query error warns and also returns
   the GitHub list: the agent signal is additive and must never remove GitHub repos.
5. **Open mode (revised after plan QA rounds 1-2).** Keep today's single `?mode=ro` open and its
   warn-and-fall-back path. No `immutable` read, no `mode=rw`. When the read fails with "unable to open database
   file" and neither `<db>-wal` nor `<db>-shm` exists, the warning says this *may be* that cause (CANTOPEN plus absent
   sidecars does not by itself prove WAL mode): "…is unreadable (unable to open database file); this may be the
   WAL DB with no -shm sidecar that SQLite cannot open read-only until Rebalance holds it open (GH-1421)". Other failures keep today's wording.
   *Why not `immutable=1`.* It opens this DB, but it disables locking and change detection. Checking for
   sidecars before and after the read only detects a race; it cannot prove the file stayed still, and the
   resolved list feeds board-mutation eligibility (GH-898), where the preview/apply/restore equality checks
   catch a changed list but not a wrong list that repeats. Using it needs a stable-read contract or an explicit
   operator decision, neither of which this task has. Recorded as the follow-up below.
   *Measured behaviour is build-specific.* On this Mac's build `mode=ro` creates no sidecar; SQLite's general
   docs allow a read-only WAL connection to create sidecars on supported builds. This reader therefore makes
   no "never touches the directory" claim beyond SQLite's own read-only semantics.
   *Follow-up (outside this task).* Make the live reader work on this device: either rebalanceOS keeps its WAL
   sidecars between connections (e.g. `SQLITE_FCNTL_PERSIST_WAL`), or the operator explicitly accepts a
   best-effort immutable read. Either is a separate decision and issue.
6. **Docs.** Record the key, merge rule and open-mode behaviour in this doc and a `CHANGELOG.md` entry
   (the only other mention of `repos_source` outside completed docs is the policy-defaults comment, which
   gains the key).

### Non-goals

No writes to the Rebalance DB (no `mode=rw`, which would create sidecars). No change to `github_activity`
semantics or the score. No new board columns, subcommands, env vars, modules or tests. No per-device or
per-source filter (all sources and devices count, like `github_activity` has no login filter). No alias
map: names are deduped case-insensitively as today.

### Preflight bet check

- *Outcome sought:* agent-only repos can reach the board when the operator opts in, and the
  WAL-mode open failure is root-caused and named.
- *Smallest viable bet:* one optional key, one extra query on the existing connection, one more
  specific warning. Not built: immutable reads, re-scoring, aliasing, source/device filters, rw opens.
- *Alternatives rejected:* writing agent rows into `github_activity` (operator rejected 2026-11-11);
  importing rebalanceOS's `agent_session_repos` (board_sync deliberately has no rebalance import, GH-898);
  opening `mode=rw` to get sidecars (writes to the Rebalance dir, violates the non-goal); a second
  connect for the agent table (a second annotated GH-777 exception that adds nothing).
- *Rollback / containment:* key defaults off; reverting the single-file change restores today's
  behaviour. The open mode is unchanged.

### Risks

- On this Mac the feature is inert until the step 5 follow-up lands (the live DB still falls back).
- `day >= date('now','-N days')` includes N+1 calendar days, same as the existing `scan_date` filter.

## Acceptance (with verification)

Acceptance 4 of the issue ("succeeds on this Mac, **or** the failure cause is documented with a working open
mode") is met by the second branch: the cause is confirmed in Observed and `?mode=ro&immutable=1` is the
recorded working mode, deliberately not used by the reader (step 5).


Verification is a manual matrix under `TESTS-RESULTS/2026-11-11+GH-1421/` (no new tests, GH-831),
modelled on `TESTS-RESULTS/2026-09-30+GH-898/manual_matrix.py`, run in a disposable full clone, plus the
existing suites `test/gh402-board-sync.sh`, `test/gh405-mock-board-harness.sh`, `test/gh549-work-events.sh`,
`test/test_gh605_board_policy.py`, `test/gh777-inventory-ratchet.sh`. The repo-list surface is the resolver
behind `policy-preview` (`_resolve_policy_and_label`) and the offline `config` subcommand; a live
`policy-preview` needs GitHub and is run once as the smoke.

- [x] **Key off is unchanged.** Resolved policy and `config` stdout are identical to base for every DB; the
  only key-off difference is the stderr wording of the no-sidecar WAL warning (step 5). On a fixture DB holding both tables, the key absent and `false` yield a
  resolved policy and `config` output byte-identical to the base commit's `board_sync.py` (loaded from
  `git show 046b41538:utils/py/board_sync.py`). Red control: the key on, same fixture, changes the list.
- [x] **Agent-only repo joins when on.** Fixture with a repo only in `agent_session_activity` (runs > 0):
  key on → it appears after every GitHub-active repo; a zero-runs and an out-of-window agent repo do not;
  a GitHub repo that also has agent runs keeps its GitHub position. Red control: key off omits it.
- [x] **Missing table falls back.** A DB with `github_activity` only, key on: no exception, one warning naming
  `agent_session_activity`, the GitHub-derived list. Red control: the same DB plus the table yields the
  agent repo.
- [x] **Other agent-query error keeps GitHub rows.** An `agent_session_activity` table without `runs`, key on:
  one warning, the unchanged non-empty GitHub list. Red control: a disposable-clone mutation that lets that
  error reach the outer fallback fails this check.
- [x] **No-sidecar WAL fixture.** First-SELECT failure reproduced on the base reader (red: generic "is
  unreadable" warning). The new reader, key off and on: the pinned-list fallback, one warning naming the
  WAL/no-sidecar cause, no exception. Control: the same DB while a writer connection holds it open (sidecars
  present) reads normally, and with the key on merges the agent repo.
- [x] **Validation.** `include_agent_sessions: "yes"` / `1` raise `ValueError`.
- [x] **Live open: cause documented.** On the live DB, the base reader's generic warning (red) vs the new
  reader's named-cause warning, key off and on; `?mode=ro&immutable=1` reads it (the recorded working mode).
- [x] **Ratchet unchanged.** `test/gh777-inventory-ratchet.sh` passes; one annotated connect site, by inspection.

## Rating rationale (2026-11-11)

`rated 50/45/50/75` (pri/sev/appeal/effort), via `releases roadmap pickup`. Severity 45: no data loss;
the board misses repos worked only through agents, and the live `mode=ro` failure means GH-898's
`repos_source` silently falls back on this Mac (recoverable, degraded projection). Recurrence: same reader
class as #899 (stale default DB path); no other incidents in the last 14 days; trend unknown. Priority 50
tracks severity; the operator asked for this follow-on today. Appeal 50 neutral (no operator score).
Effort 75: one file, one extra query, verification by manual matrix.

## Dependencies

HiQS-Labs/rebalanceOS#375 — merged (PR #376, 88a8972). Related: #1000 (project 9 board), #899, #898.
The 1-INBOX copy of this doc also rides PR #1424 (byte-identical capture commit 6a55a7e); this branch
carries that commit and promotes the file, so land #1424 first or drop the GH-1421 file from it.

## Phase 1 — Implement and verify

### QA checklist — Phase 1

- [x] Codex plan QA approved.
- [x] `--accepted-start` recorded.
- [x] Acceptance matrix green with red controls witnessed.
- [x] Existing suites green (gh402, gh405, gh549, gh605-board-policy, gh777). Routed gate on the final commit: pending.
- [x] Live smoke (main path + adjacent path) recorded.
- [x] Codex final QA approved (round 2).

## Lessons Learned

- An aggregate alias that reuses a column name (`SUM(runs) AS runs`) makes SQLite resolve `HAVING runs`
  to the stored column, so the filter depends on which row SQLite picks. Single-row fixtures hide it; the
  red control is a multi-row fixture with a zero row first (`redcontrol-having-alias.log`).
- On this Mac's SQLite build, a `mode=ro` reader of a WAL DB with no sidecars connects and then fails on
  the first SELECT; it does not create the sidecars SQLite's docs describe.
- LESSONS-LEARNED.md: `NO_ENTRY`. Both are code-local facts recorded here; neither fits the ledger's
  areas (relay, marathon, pdda, gate, skills, releases).

## Merge evidence

- PR #1429 merged 2026-11-12 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
