---
title: "GH-789 (+ GH-965): merge-cleanup bounded repairs — port of the approved phase-one implementation"
status: In Progress
gh_issue: 789
source: https://github.com/HiQS-Labs/XYZ-forge/issues/789
doc_type: enhancement
created: 2026-09-24
updated: 2026-10-05
owner: operator
goal: "merge-cleanup stops less on mechanical cases: drafts are skipped (not a failed landing), additive CHANGELOG conflicts resolve inside B1, and a stale REBASE_HEAD no longer blocks the primary."
branch: fix/gh789-merge-cleanup-repairs
complexity: 3
risk: 3
effort: 3
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Plan approved (Codex round 2). Port built; Codex final QA round 1 FAIL on evidence only (F1 push-boundary continuation, F2 control attribution) — fixed: matrix 27/27 green, 7 reproducible red controls (`red_controls.py`) each red on its case, gh436 180/180. | Codex final QA round 2, then full-gate push and PR. |

## Why this is a port

The original phase-one implementation was built and Codex-approved on 2026-09-24 in clone `XYZ-forge-gh789`
(branch `fix/gh789-gh786-merge-cleanup`, head `08bb0655`, base `f1321d6d`):
`relay-drive: attest RELAY-GH789-FINAL-R3 approved by codex (reviewed df6a1f126656)`. It was never published:
its full gate failed 416/417 on an upstream inventory ratchet (`github_labels.py`, from #723), not on its own
code, and the clone then sat unpushed. `/merge-cleanup-deep` (2026-10-05) found it PR-WORTHY: `union_changelog`,
`read_changelog_union` and `prepare_primary_landing` have 0 hits on `development`, and #789 is open with no PR.
The clone is backed up at `_backups/XYZ-forge/2026-10-05_085604/zips/XYZ-forge-gh789.zip`; its full original
plan, recon (`recon-gh789.md`) and relay threads are in that commit history.

**Still needed now (recurrence, 2026-10-04):** merge-cleanup handed off PR #930 on
`code/doc conflict outside the ledger set: CHANGELOG.md` (an additive changelog conflict), and stopped a whole
run on draft PR #948 (`GraphQL: Pull Request is still a draft`) — filed as #965, which this port also closes.

## Scope (phase one only)

Port the three approved behaviours from `08bb0655` (diff `f1321d6d..08bb0655 -- skills/2-daily/merge-cleanup/`):

1. **Drafts (GH-789 item 2 + #965).** `toposort_prs.fetch_open_prs` and `merge_cleanup.refresh_pr` request
   `isDraft`. A live draft is `SKIPPED (draft)` before repair or merge, rechecked after UNKNOWN polling, after a
   B1 refresh, before a repaired-head push and before the merge call. At the repaired-head push boundary
   (`merge_cleanup.push_resolved_head`, called at `merge_cleanup.py:1004–1008`), a **positively observed** draft is a
   named skip, not a stop: zero push and zero merge for that PR, B1 evidence kept, recorded as a non-landed hard
   predecessor, independent PRs continue. Every other push failure (unknown state, moved head, refresh error,
   closed PR) keeps today's fail-closed `return 2`. A draft is a non-landed **hard** predecessor (explicit dependents wait; soft/independent PRs
   continue). A run whose only non-landings are drafts is a success; drafts are named in one
   `Skipped draft PR(s): …` summary line. Never marks a PR ready.
   **Added for #965:** the Phase 4 sequence table gets a `Draft` column (`toposort_prs.py` table render).
   The port also carries the source's two supporting ordering transforms (soft collision edges are admitted only
   when they do not create a cycle; a PR with an unvisited hard prerequisite is never merged, including a true
   hard cycle) — they are what keeps a draft prerequisite from being bypassed. They are not GH-786.
2. **CHANGELOG in B1 (GH-789 item 3).** `ledger_merge.union_changelog` / `read_changelog_union` accept only
   newly prepended complete `## YYYY-MM-DD …` blocks on both sides of a unique merge base, with identical preamble
   and unchanged base history; exact duplicate blocks deduplicate; divergent same-heading bodies, fenced/HTML
   additions, conflict markers, empty input or a base edit hand off. Classified before any mutation; staged in the
   existing B1 commit; downstream second-clone validation and gates unchanged.
3. **Stale REBASE_HEAD (GH-789 item 1).** `scan_clones.inspect_primary_landing` distinguishes a lone
   `REBASE_HEAD` from a real `rebase-merge`/`rebase-apply`/sequencer operation (paths via `git rev-parse --git-path`).
   Only in execute landing/reconcile mode, after all other readiness checks pass, `prepare_primary_landing`
   deletes a stale one with compare-and-delete (`git update-ref -d REBASE_HEAD <observed-oid>`) and re-inspects.
   Audit modes never prune.

**Conflict resolution against today's `development`** (from the trial apply):
- `merge_cleanup.py`: keep dev's `PUSH_GATE_TIMEOUT_S` constant; keep dev's GH-851 post-push head wait **and**
  add the port's post-repair draft recheck after it; add the port's pre-repair draft skip next to dev's hold-label skip.
- `SKILL.md`: keep dev's capability rows; add the port's draft and CHANGELOG prose but **not** its two new
  capability rows. GH-831 forbids the tests they would name, and adding the rows anyway would leave them unchecked:
  the parity guard (`test/gh534_phase_c_tests.py:585–596`) checks named tests only for `REQUIRED_CAPABILITIES`
  (`:527–546`), which stays as it is today. The source's `gh534_phase_c_tests.py` hunk (+1 import, +1 required row
  pair) is therefore not ported.
- Port as a delta onto today's files, never by replacing whole historical files: GH-852 MERGED re-query
  (`merge_cleanup.py:165–181`), bounded push (`:356`), retry clone cleanup (`:298–302`), resume and attempt records
  (`:933–998`), hosted reconcile and durability (`:1073–1084`) and the current SKILL prose all stay.

## Non-goals

GH-786 phase two (batch records) — plan-only in the old clone, stays queued on #786. No new tests or capability
rows (GH-831). No changelog support for repos without a ledger. No auto-ready of drafts. GH-785 (hold-label
dependency gap) stays separate. No change to repair budgets, the attempt record or hosted reconcile.

## Verification (no new suites — GH-831)

- **Existing suites, in a disposable full clone** with pre/post identity checks: `test/gh436-merge-cleanup.sh`
  (includes `gh534_phase_b/c` and the parity guard) stays green; the push route runs the full gate (core skill).
- **Manual matrix, reusing the source's cases instead of writing new ones.** The approved source carried 22 cases in
  `test/gh534_phase_b_tests.py` at `08bb0655` (`TestGh789Drafts`, `TestGh789Changelog`, `TestGh789ChangelogMerge`, the
  five REBASE_HEAD primary cases). They move unchanged, except as listed, into one unregistered evidence script
  `TESTS-RESULTS/2026-10-05+GH-789/manual_matrix.py` that imports the existing `LedgerFixture`/helpers from
  `test/gh534_phase_b_tests.py` (same pattern as GH-898's matrix). Nothing is added to `validate.sh` or the registry.
  Coverage this gives, per Codex F3:
  - drafts: initial skip; draft appearing during UNKNOWN polling; after the gate (zero merge-API calls); at the
    repaired-head push (F2: now a named skip — `test_draft_before_repaired_push_is_refused` is adapted to expect skip,
    not stop); after a repaired push; changed head after the gate not merged; soft collisions do not block; a collision
    cycle never bypasses a draft prerequisite; a true hard cycle never merges;
  - exit codes (F1): **f1** draft + independent → exit 0, exactly one merge (the independent), summary names the
    draft; **f2** adds a hard dependent → independent lands, dependent never attempted, exit 3 naming `blocked by #<draft>`;
  - Phase 4: `Draft` cell true/false for a mixed queue (new assertion for #965);
  - changelog: changelog-only and ledger+changelog resolve with exact output bytes, history preserved, same-date
    additions kept, exact duplicates deduplicated; base edit, reorder, ambiguous history, fenced/HTML heading → handoff
    before any write; dry run writes nothing; a repaired changelog reaches the landed outcome;
  - REBASE_HEAD: pruned only in execute landing; scan/prs/teardown-only and dry run never prune; dirty primary or
    active `rebase-merge`/`rebase-apply`/sequencer never prunes; linked-worktree git-path resolution; a changed
    observed OID makes compare-and-delete fail and the block stays.
- **Red controls**, each recorded with command, exit and output: run the matrix against unported `development`
  (draft, changelog and marker cases fail); remove the post-poll / post-gate / push-boundary draft checks one at a time
  (their cases fail); make the changelog classifier accept a base edit (its case fails); drop the compare-and-delete OID
  (its case fails).
- Receipts: `TESTS-RESULTS/2026-10-05+GH-789/provenance.jsonl` with candidate and control runs, committed.
- Live check (operator, optional): `merge_cleanup.py --prs-only` shows the Draft column on today's queue.

## Risk

**Costly** (merge automation writes PR heads; a wrong changelog classification could drop release notes).
Shield: classification before mutation, hand off on anything ambiguous, existing second-clone validation and
guarded push. Rollback: revert the PR commit. Blast radius: merge-cleanup only (`scan_clones`, `toposort_prs`,
`merge_cleanup`, `ledger_merge`). `merge-cleanup-deep` is unaffected by call-path separation: its intake
(`scan_clones --json`, `scan_clones.py:1311–1314`) goes through `scan_directories` → `inspect_checkout`, not the
changed `inspect_primary_landing`.

## Rating (2026-10-05)

GH-789 `rated 75/70/50/50`: severity 70 — work-blocking landing stops (whole run stopped on a draft; CHANGELOG
handoffs), recoverable, no data loss; priority 75 — recurs each batch (2026-10-04: #930 handoff, #948 stop; Sep:
GH-555/623/624/736 same tool); appeal 50 neutral; effort 50 — port of approved code with two conflicts, not new
design (the 2026-09-24 proposal had 65 for a fresh build). GH-965 `rated 60/50/50/85`: the draft stop alone,
fully covered by item 1.
