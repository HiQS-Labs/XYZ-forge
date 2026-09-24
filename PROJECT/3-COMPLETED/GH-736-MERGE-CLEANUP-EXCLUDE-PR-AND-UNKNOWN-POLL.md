---
title: "GH-736: merge-cleanup — --exclude drops a PR, UNKNOWN mergeability is polled before stopping"
status: Complete
created: 2026-09-24
updated: 2026-09-24
owner: operator
gh_issue: 736
source: https://github.com/HiQS-Labs/XYZ-forge/issues/736
doc_type: bugfix
complexity: 1
risk: 2
effort: 1
ratings_provisional: true
goal: >
  Land #736 items 1 and 2 in merge-cleanup's script: a bare PR number passed to --exclude leaves
  that PR out of the queue, and a PR that reads mergeable=UNKNOWN right after a landing is polled
  (bounded) before the run stops. Item 3 (stacked PRs auto-closed by --delete-branch) is a design
  question and stays open on #736.
---

# GH-736 — merge-cleanup: `--exclude <PR#>` and post-landing `UNKNOWN` mergeability

## Status

| What was just completed | What's next |
|---|---|
| Items 1–2 implemented in `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` with regression tests in `test/gh534_phase_b_tests.py`; SKILL.md and its capability table updated; full `gh436-merge-cleanup.sh` suite green (168 tests). | Agy relay QA, then PR. #736 stays open for item 3 (stacked-PR retarget before `--delete-branch`) and the two "also seen" notes. |

## Problem

Both gaps were hit independently in live `/merge-cleanup` runs:

1. **`--exclude <PR#>` only filtered checkouts.** SKILL.md example 6 documents `--exclude 427` as
   "exclude active in-flight work (e.g. PR 427)", but the script passed `args.exclude` only to the
   checkout scan and teardown. The PR was still sequenced and merged. Reported on LTVera-Pandas
   (2026-09-21, #587 stacked on #586); a local patch carried the fix in the deployed copy since.
2. **`mergeable == UNKNOWN` after every landing stopped the run.** GitHub recomputes mergeability
   for every open PR after a push to the base; for roughly 5–30 s the next PR reads `UNKNOWN`, and
   Phase 5 exited 2 ("GitHub has not decided; stopping rather than guessing"). Seen on
   LTVera-Pandas and again on HiQS-Labs/rebalanceOS 2026-09-22 (#235 read `UNKNOWN` right after
   #231 landed).

## Change

- `--exclude` values that are bare integers drop those PRs before topological sorting, each logged
  as `PR #N: excluded by --exclude; not sequenced this run`. Non-numeric patterns keep their
  checkout-only meaning.
- Before the existing `UNKNOWN` stop, Phase 5 polls up to `MERGEABLE_POLL_ATTEMPTS` (6) ×
  `MERGEABLE_POLL_S` (15 s), re-reading through `refresh_pr_with_retry`. A PR still undecided
  after 90 s stops the run exactly as before, so no PR of unknown state is ever merged.
- The same bounded poll (and the retry wrapper instead of a single `refresh_pr`) runs after a B1
  ledger resolution re-fetches the PR. Both sites share one helper, `_await_mergeable`.
- A refresh error inside the poll ends it at once and is handled by the existing GH-623 rules — a
  transient error defers the PR, any other stops the run naming the real error (Agy QA round 1).
  A re-fetch that already failed is never polled.

## Acceptance Criteria

- [x] `test_exclude_pr_number_drops_it_from_the_queue` — PR 1 stays OPEN, PR 2 merges, exclusion logged.
- [x] `test_unknown_mergeable_settles_and_the_pr_lands` — UNKNOWN for the first reads, then the PR lands.
- [x] `test_unknown_mergeable_stops_before_any_merge` — a PR that never settles is polled exactly 6 times, then the run stops with nothing merged.
- [x] Negative control: all three fail against `development`'s unmodified script.
- [x] Capability table rows `mergeable-unknown-poll` and `exclude-drops-pr` pinned; `TestParityGuard` green.
- [x] Full registered suite `test/gh436-merge-cleanup.sh` green (168 tests).
- [x] Agy relay QA round 1 (`relay-system/2026-09-24/gh736-merge-cleanup-qa.md`): two blockers — an error mid-poll was masked as "GitHub has not decided", and a failed post-B1 re-fetch was polled six times. Both fixed via `_await_mergeable`; pinned by `TestGh736AwaitMergeable` (4 unit tests) and two end-to-end tests, both red on the reviewed commit `09003de9`. The round-1 `[Should]` (a held predecessor does not block its hard dependents) is pre-existing and filed as #785.
- [ ] Agy relay QA approved.
- [ ] PR merged to `development`.

## Merge evidence

- Agy relay QA: round 1 FAIL (2 blockers, fixed in `1d3d3c3b`; `[Should]` filed as #785), round 2
  PASS — `relay-system/2026-09-24/gh736-merge-cleanup-qa.md`.
- Pre-push gate (2026-09-24, local, 1177 s): `gh436-merge-cleanup.sh` green (174 tests). Push
  refused on 10 suites unrelated to this change (`agy-turn`, `gh610-claude-subscription`,
  `gh648-l2/l4/l5/l6`, `gh492-roadmap-state-sweep`, `gh-gen4-phase3/4/5`). The 4 re-run on a
  pristine `origin/development` checkout (`39c2ae6a`) on the same machine fail identically
  ("Exec format error" executing test stubs), so the baseline is known-red on this device.
  Pushed with `--no-verify` on operator approval; the environment fault is tracked separately.

- (recorded at landing)

## Lessons Learned (For Future Agents)

- **A fix that lives only in a deployed copy is invisible.** Both changes ran for three days as a
  hand-edit in `~/git-pulse-sync/Deployed Skills/merge-cleanup/scripts/merge_cleanup.py`. The next
  skills-army-hq refresh from canonical overwrote it; it survived only because the refresh was
  preceded by a diff against canonical and the edit was saved as a patch first. Always diff a
  deployed payload against its source before re-vendoring, and send local improvements upstream.
- **Documented behavior is a contract the code owes.** SKILL.md promised `--exclude 427` for a
  PR; nothing tested it, so the doc and code diverged silently. The new capability-table rows make
  the parity guard enforce both promises.
- **"Unknown" right after a write is often timing, not state.** GitHub's mergeability is
  eventually consistent. A bounded poll with the existing fail-closed stop at the end keeps the
  safety property (never merge an undecided PR) while removing a guaranteed false stop after every
  landing.
- **A poll is a second read, so it needs the first read's error handling.** The first version
  polled correctly but treated a failed refresh as "still undecided", so a DNS blip mid-poll
  stopped the whole run with a misleading message. Agy's review caught it; routing the poll's
  error back through the same defer/stop rules as the first read fixed both sites at once.
- **Shared test fixtures are shared contracts.** Stubbing `_sleep` inside the shared `run_main`
  helper silently replaced the stub the GH-623 resilience tests install themselves; the parity
  guard caught it. Scope a stub to the test that needs it.
