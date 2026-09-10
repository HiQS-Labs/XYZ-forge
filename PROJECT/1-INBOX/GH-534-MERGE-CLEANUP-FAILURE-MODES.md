---
title: "GH-534: merge-cleanup promises merge + conflict-resolution + teardown, implements one and a half"
status: Parked
created: 2026-09-09
updated: 2026-09-09
owner: unassigned
goal: make /merge-cleanup's scripts do what SKILL.md says, or make SKILL.md say what the scripts do — and give PRESERVE_* dispositions a way to become eligible
gh_issue: 534
source: https://github.com/HiQS-Labs/XYZ-forge/issues/534
doc_type: defect
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/444
  - https://github.com/HiQS-Labs/XYZ-forge/issues/523
  - https://github.com/HiQS-Labs/XYZ-forge/pull/526
  - https://github.com/HiQS-Labs/XYZ-forge/issues/510
  - https://github.com/HiQS-Labs/XYZ-forge/issues/446
context_tags: [merge-cleanup, skill, teardown, squash-merge, safety-guard, doc-code-drift]
non_goals:
  - Re-deciding the repo's squash-merge landing strategy
  - The #523 primary-checkout-first fix (PR #526 owns it; this doc only avoids colliding with it)
  - The #444 "do not merge" label guard (separate, small, already tracked)
  - Building a general-purpose automatic code-conflict resolver — code conflicts are escalated by name, not auto-merged
effort: 5
complexity: 3
risk: 3
---

# GH-534 — merge-cleanup audits, declines, and leaves

## Status

| What was just completed | What's next |
|---|---|
| Issue #534 filed with six verified failure modes at `6e304820`; fresh task clone `~/marathon-clones/gh-merge-cleanup-fm` on `fix/merge-cleanup-failure-modes`; parked + rated | Operator decides Phase B scope (see Fix), then Codex plan QA via relay-xyz, then Phase A implementation |

## Why

The skill advertises three jobs. Two invocations on 2026-09-09 — one by this session, one by a
second agent — produced the same output: a complete audit, every checkout `PRESERVE_*`, every
conflicting PR skipped, and the actual work handed back to the caller. The operator called the
result "mostly useless", and that is the correct reading. This is the third same-class report in
five days (#444 on 09-05, #523 on 09-09, this).

The reason is not one bug. The scripts were built as an *audit + safe-delete* tool (`10918e9e`)
and SKILL.md was later widened (`b9d156c0`) to promise conflict resolution that was never
implemented. On top of that, the safety model is terminal — `PRESERVE_*` has no transition — and
its "unpushed" test is defeated permanently by the repo's own squash-merge landing strategy.

## Verified findings (at `6e304820`)

Full evidence with line references is in #534. Compressed:

| # | Failure mode | Where | Verified how |
|---|---|---|---|
| A | `~/marathon-clones` outside `DEFAULT_SAFE_ROOTS`: never scanned by default; `PRESERVE_UNSAFE_ROOT` when scanned | `scan_clones.py:18-22`, `:47-67` | Bare scan: 8 hits, all in `GH Repos`. `--root ~/marathon-clones`: clean `pr495-repair` → `PRESERVE_UNSAFE_ROOT` |
| B | Unpushed = `[ahead N]` or `branch -r --contains` empty. Squash+`--delete-branch` means local commits are never contained in a remote ref → permanent `PRESERVE_UNPUSHED`. No `git cherry` / patch-id | `scan_clones.py:236-254` | Primary `[ahead 4]` — `git cherry` proved all four upstream-equivalent. gh490 dev `[ahead 6]`. gh271: 29, gh462: 83 unclassified |
| C | Dirty = any porcelain line. Telemetry (`harnesses.db`), #446 plan artifact, `.playwright-mcp/` all count as work | `scan_clones.py:303-306` | Every `PRESERVE_DIRTY` today was regenerable |
| D | `inspect_tick_claims()` defined, never called. `ACTIVE_TICK_CLAIM` cannot fire. SKILL.md Phase 2 claims the check | `scan_clones.py:136`, `:296` | `grep -n inspect_tick_claims` → one hit, the definition |
| E | Phase 5: no `mergeable` pre-check; PR list fetched once, never refetched; `MERGED` never re-queried; `ff-only` result discarded; reconcile always returns `True` | `merge_cleanup.py:57-62`, `:272`, `:306`, `:65-102` | Read; `ff-only` silently failed on today's diverged primary |
| F | Conflict resolution exists only as SKILL.md Phase 5 prose delegating to the calling agent | `SKILL.md` Phase 5; `git log -- skills/merge-cleanup` | `b9d156c0` touched only docs |

Traced (recon, `6e304820`): the root set is not the skill's invention. `WORKTREE-SAFETY.md:783`
defines `SAFE_ROOTS = [~/agent-workspaces, ~/Documents/GH Repos]` and the skill mirrors it —
while `skills/10days/SKILL.md:144` and `skills/marathon-triage/SKILL.md:109` create clones under
`~/marathon-clones`. The governance doc and the clone-creating skills disagree, and merge-cleanup
inherited the governance side. **A.1 is therefore a `WORKTREE-SAFETY.md` change first**, with the
skill following it; changing only the skill would leave the safety doc forbidding what the skill
does. No other script consumer of the list was found (`git grep` over `utils/`, `skills/`,
`relay-automation/`).

## Fix

Two phases. Phase A is surgical and has no design question. Phase B has one, and it is the
operator's call.

### Phase A — make the scanner tell the truth, and make Phase 5 check its own work

Extend the existing scripts. No new module, no second scanner.

1. **Roots.** Add `~/marathon-clones` to `DEFAULT_SAFE_ROOTS` in `scan_clones.py`, or read the
   root set from wherever the repo's clone-creating flows define it (recon item above decides).
   Both the scan and `is_safe_deletable_path()` consume the same list already — one edit.
2. **Unpushed → unlanded.** In `inspect_checkout()`, for every branch currently flagged, run
   `git cherry origin/development <branch>` and count only `+` lines. Report `unlanded_commits`
   per branch; a branch with zero `+` is landed even if `[ahead N]`. Keep the existing ref check
   as the first pass so an actually-unpushed branch is still caught cheaply.
3. **Dirt classification.** A small list of known-regenerable patterns (`harnesses.db`,
   `harnesses.sql`, `MARATHON-PLAN-*.md`, `.playwright-mcp/`, `*.db.bak`). `PRESERVE_DIRTY` only
   when a non-matching file exists; the reason names the real files. Regenerable-only dirt gets
   a new disposition `DIRTY_REGENERABLE` that Phase 6 treats as eligible after a warning.
4. **Call `inspect_tick_claims()`** in `inspect_checkout()` next to `inspect_driver_lock()`.
5. **Phase 5 feedback loop** in `merge_cleanup.py`: before each merge, refetch that PR's
   `mergeable`; skip `CONFLICTING` with a named reason instead of attempting; after `gh pr merge`,
   re-query `state` and treat anything but `MERGED` as failure; check `ff-only`'s return code and
   stop the run on failure; propagate reconcile failures instead of warning.
6. **Doc/code parity.** SKILL.md Phase 2, 3, 5 and 6 text rewritten to describe exactly what the
   scripts do after this change, including that code conflicts are escalated by name.

### Phase B — the decision: implement conflict resolution, or stop promising it

The Phase 5 prose describes a real, repeatable flow for the *ledger* conflict set
(`releases.db`/`.sql`, `ROADMAP-DASHBOARD.md`, `LEADERBOARD.md`): disposable clone, merge
`origin/development`, `utils/releases-merge-resolve.sh`, CLI re-apply, regen, gate. #519 was
landed exactly this way and it worked. Code conflicts are a different animal — #495's
`wave_reconcile.py` needs a human.

Options the operator chooses between:

- **B1 — implement the ledger half.** Phase 5 handles ledger-only conflicts automatically in a
  disposable clone using the existing resolver; anything with a code conflict is escalated with
  the file list. This is what SKILL.md already claims. Cost: a new function in
  `merge_cleanup.py` (~100 lines), a fixture test, and a real gate run per resolved PR.
- **B2 — stop promising it.** Delete the Phase 5 resolution prose; replace with a precise
  handoff: "conflicting PRs are listed with their conflict file set; resolve with `/start-task`
  or by hand in a disposable clone using `releases-merge-resolve.sh`." Phase A still ships.

Recommendation: **B1**, because the repo already has the resolver and the proven procedure, and
B2 leaves the skill unable to do the job it is named for. But B1 is a day of work and a design
review; B2 is an hour. Not the implementer's call.

### Risks and rollback

- Phase A.2 makes teardown *more* permissive. The red control below is mandatory before it ships.
- Phase A.3's regenerable list is a judgment; a wrong entry makes real work look like dirt. Keep
  the list short, name every file in the disposition, and never delete on `DIRTY_REGENERABLE`
  without the `--execute` flag the skill already requires.
- Rollback is `git revert` of the PR; the skill has no persistent state.

## Acceptance check

- A clean fixture clone under `~/marathon-clones` is reported `SAFE_REMOVE_CLONE`.
- **Red control (B):** a fixture whose only "ahead" commit is a squash-merged twin of a commit on
  `origin/development` is reported eligible; the same fixture with one genuinely unlanded commit
  is reported `PRESERVE_UNPUSHED` naming that commit. Both must be asserted; the second must
  fail if step A.2 is reverted.
- A fixture with `.tick/locks/x` is reported `ACTIVE_TICK_CLAIM`; must fail if A.4 is reverted.
- A fixture dirty only with `harnesses.db` is `DIRTY_REGENERABLE`; dirty with `foo.py` is
  `PRESERVE_DIRTY` naming `foo.py`.
- Phase 5 dry-run against a `CONFLICTING` PR prints a skip-with-reason, never a merge attempt.
- `test/mktemp-trap-guard.sh` and `test/gh1-adoption-guard.sh` pass with the new test registered.
- SKILL.md and `merge_cleanup.py --help` describe the same behaviour.

## Rating rationale — 2026-09-09

`rated 75/70/50/40` → calc 235.

- **sev 70** — work-blocking: two of three advertised jobs do not run, and teardown is impossible
  for the main clone population by construction. Plus one latent safety gap (D): a guard SKILL.md
  promises never executes. No data loss observed, so not the 80+ band; the dead guard keeps it
  from going lower.
- **pri 75** — the operator is blocked on it today, and it is the third same-class report in five
  days: #444 (09-05), #523 (09-09), #534 (09-09). Windows: last 14 days = 3 distinct incidents;
  preceding 14 days = 0 (the skill landed 09-04 under #436). Rising, and each is a different
  defect in the same tool, not a cross-post.
- **appeal 50** — neutral; operator gave no preference.
- **effort 40** — Phase A is a day of surgical edits with clear tests. Phase B1 is another day
  plus design review. Not a quick win, not an architectural rewrite.
- Uncertainty: the count of *other* consumers of `DEFAULT_SAFE_ROOTS` (untraced) could widen
  A.1. No operator `ovr`.
