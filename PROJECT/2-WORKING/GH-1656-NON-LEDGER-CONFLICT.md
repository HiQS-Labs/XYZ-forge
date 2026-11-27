---
title: "merge-cleanup: a GitHub-CONFLICTING PR whose conflict is not in the ledger fails at gh pr merge"
status: In progress
created: 2026-11-27
updated: 2026-11-27
owner: Noel Saw
gh_issue: 1656
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1656
doc_type: bugfix
reported_from: XYZ-forge
harness_commit: 52813e56f
related:
  - 1657
  - 1654
  - 1226
  - 1475
non_goals:
  - a new tool, rung table, suite or test registry entry
  - `gh pr update-branch` (it rewrites the PR head off its pin and waits on fresh CI; the local merge does not)
  - landing locally under `squash` / `rebase` policy (a local merge commit would change the history shape the policy chose)
  - changing B1's ledger-only scope, the two-repair budget, or the pre-push gate
  - any bypass of the pre-push gate (`--no-verify`, `XYZ_SKIP_PREPUSH`)
goal: "A PR GitHub reports CONFLICTING never reaches `gh pr merge`: a clean local merge lands through a gated local-merge rung recorded in the batch issue, and anything else stops first with a precise reason."
---

# GH-1656 — non-ledger GitHub conflict: local-merge rung or a precise stop

## Status

| What was just completed | What's next |
|---|---|
| Recon and plan written. | Codex plan QA (relay), then implementation. |

## Problem (observed)

Batch #1654, 2026-11-27, PRs #1651 and #1652, twice in a row:

```
merge-cleanup: PR #1651: pre-merge ledger gate green on e14a44bd6e + origin/development
merge-cleanup: Merging PR #1651 via `gh pr merge 1651 --merge --match-head-commit e14a44bd6e…`...
merge-cleanup: ERROR — Failed to merge PR #1651: X Pull request … is not mergeable: the merge commit cannot be cleanly created.
merge-cleanup: ERROR — Phase 5 stopped
```

GitHub read `CONFLICTING`; a local `git merge --no-ff` of the same head onto the same
`origin/development` was clean; neither PR touched the ledger. The operator landed both by hand
(local merge + gated push).

## Recon (base `52813e56f`)

Entry: `_land_prs_loop` in `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`.

1. Live refresh → `_await_mergeable` (GH-736) polls UNKNOWN 6×15 s; still undecided → exit 2
   "GitHub has not decided; stopping rather than guessing". This holds in the dry run too.
2. `prepare_landing_clone` builds a disposable full clone at the PR head and runs
   `git merge --no-ff --no-commit origin/<branch>`; `merge_rc` 0 is clean.
3. `merge_rc != 0` → B1 (`resolve_ledger_conflict`, ledger-only). A conflict outside the ledger
   comes back as `handoff` and stops before any merge. **The dirty case is already stopped before
   `gh pr merge`**, but its message does not say "non-ledger conflict; local merge dirty".
4. `merge_rc == 0` → **no branch looks at GitHub's `mergeable` again.** The flow runs the ledger
   gate, the checks wait, final eligibility and the pin check, then `execute_pr_merge` →
   `gh pr merge --merge --match-head-commit <pin>`, which GitHub refuses. This is the defect.
   In the dry run the same path prints `[DRY RUN] Would merge PR #N`, the misleading preview the
   issue's note describes (the dry run read UNKNOWN in the Phase 4 table, then GitHub decided
   CONFLICTING during the poll, and the clean local merge fell through to "Would merge").
5. After a merge: `_MERGED_THIS_RUN`, `_record_merge_outcome` (batch issue row), primary
   `fetch` + `merge --ff-only`, `run_post_merge_reconcile`, `emit_pr_merged`,
   `commit_and_push_phase5_writes`. All of it keys off `origin/<branch>` and the PR's MERGED state,
   so it works unchanged for a landing that came from a direct push.
6. Existing helpers to reuse: `gate_unwired_reason` (GH-1576 hook check before any push),
   `_net_git(..., timeout=PUSH_GATE_TIMEOUT_S)` (the push runs the pre-push gate),
   `refresh_pr_with_retry`, `_off_pin` (GH-1226 exact-head rule), `MERGEABLE_POLL_*`.
   `commit_and_push_phase5_writes` already pushes straight to `development` through the hook, so a
   gated direct push to the integration branch is an existing, accepted path.
7. Batch issue: `batch_record.set_outcome` stores status / merge_oid / reconcile per PR and
   `script_block` renders the merge-sequence table. No field names the landing rung.
8. Policy: Forge's `.merge-cleanup.json` sets `preserve_commit_history: true` → strategy `merge`.

Tests: `test/gh534_phase_b_tests.py` (`LedgerFixture`: bare origin, gh stub with
`force_mergeable`, `TestPhase5EndToEnd`, `TestGh736AwaitMergeable`), collected by the registered
`test/gh436-merge-cleanup.sh`. The gh stub's `pr merge` squashes whatever merges cleanly; it never
refuses a PR it reports CONFLICTING, so today's suite cannot see the defect.

## Preflight bet check

- **Outcome sought:** a batch never dies inside `gh pr merge` on a PR GitHub already said it
  would refuse; a clean landing completes in the same run, under the same gate and pin.
- **Smallest viable bet:** one branch at the existing merge call (live `mergeable == CONFLICTING`
  and a clean local merge under `merge` strategy → local-merge rung; otherwise a precise stop),
  one dry-run preview line, one message on the existing B1 handoff, one optional `rung` field on
  the batch outcome row.
- **Alternatives rejected:** `gh pr update-branch` (moves the head off the pin, so GH-1226 would
  defer it to a second dry run and a fresh CI wait — a stop with extra steps); stop-only (leaves
  the operator to repeat the manual workaround the run could do itself under the same gate).
- **Rollback:** revert the PR; the rung is a branch in front of the existing merge call, and a
  revert restores today's behaviour exactly.

## Requirements → plan

R1. CONFLICTING + local merge clean + strategy `merge` → **local-merge rung (a).**
R2. CONFLICTING + local merge dirty, or clean but not landable locally → **stop before
    `gh pr merge` (b)** with `non-ledger conflict; local merge clean|dirty: <files>`.
R3. Dry run never prints "Would merge" for a CONFLICTING PR or an UNKNOWN one.
R4. The batch issue names the rung used.

### Implementation (ordered, verification inline)

1. **Red first.** In `test/gh534_phase_b_tests.py` (existing suite; no new file, no registry
   entry): teach the gh stub's `pr merge` to refuse, with GitHub's message, a PR whose
   `force_mergeable` value is `CONFLICTING` (as GitHub does), and teach `view` to report an OPEN
   PR whose head is already on `origin/<base>` as MERGED with the merge commit that brought it in
   (as GitHub does after a direct push). Add `TestGh1656NonLedgerConflict`:
   - `test_clean_local_merge_lands_through_rung`: one PR, non-ledger change, forced
     `CONFLICTING`, policy `merge`. Expect rc 0, PR MERGED at the pinned head, origin/development
     has a merge commit whose second parent is the pin, **no `pr merge` call** in the stub log,
     the log names the rung, and the batch outcome row records `rung: local-merge`.
   - `test_dirty_non_ledger_conflict_stops_before_gh_merge`: a real non-ledger conflict (both
     sides edit `README.md`). Expect rc 2 (handoff path), message
     `non-ledger conflict; local merge dirty: README.md`, no `pr merge` call.
   - `test_clean_conflicting_under_squash_stops_before_gh_merge`: same as the first, default
     (squash) policy. Expect rc 2, message `non-ledger conflict; local merge clean: …`, no
     `pr merge` call, development unchanged.
   - `test_dry_run_conflicting_clean_previews_rung`: dry run, forced CONFLICTING, clean →
     no "Would merge PR #N", a line naming the local-merge rung.
   - `test_dry_run_unknown_never_previews_merge`: dry run, `mergeable` stuck UNKNOWN
     (poll constants patched to 0 s) → no "Would merge", the existing "has not decided" stop.
     (Expected green before the fix; kept as the R3 control for the UNKNOWN half.)
   Run on base: the first four must fail (the first and third reach `pr merge` and are refused;
   the dry-run case prints "Would merge"; the dirty case lacks the message). Record the red
   output under `TESTS-RESULTS/2026-11-27+GH-1656/`.
2. **Rung (a)** in `merge_cleanup.py`: `land_via_local_merge(info, clone, primary_repo, branch,
   pinned)`. In the existing landing clone: `git merge --abort`, `checkout --detach
   origin/<branch>` (the base the ledger gate just ran against), `git merge --no-ff --no-edit -m
   "Merge pull request #N from <headRefName>" <pinned>` with a body line naming GH-1656 and the
   rung. Dirty here → return the conflicted files (R2 dirty). Clean → `gate_unwired_reason` check,
   then `_net_git push origin HEAD:refs/heads/<branch>` with `PUSH_GATE_TIMEOUT_S` (the clone's
   installed pre-push hook runs the gate; a moved base is refused as non-fast-forward, which is
   the exact-base discipline). Never `--force`, never `--no-verify`. After the push, poll
   `refresh_pr_with_retry` (bounded by `MERGEABLE_POLL_*`) until MERGED; `_off_pin` refuses a
   MERGED-at-another-head read. Returns the verified merge oid (GitHub's, else the pushed commit
   with a warning that GitHub has not yet re-read the PR).
3. **Wire it** at the existing merge call (after final eligibility, the pin check and the
   stacked-dependents protection, so every existing guard still runs first): if
   `live["mergeable"] == "CONFLICTING"` → strategy `merge` → rung; else stop with
   `non-ledger conflict; local merge clean: no conflicted files; strategy <s> cannot be landed
   locally — land by hand or re-run with policy merge`, exit 2. Rung success joins the existing
   post-merge path (`_MERGED_THIS_RUN`, `_record_merge_outcome` with `rung="local-merge"`,
   primary fast-forward, reconcile, emit, phase-5 writes). Rung failure → exit 2, clone kept.
   The dry-run branch above the merge call prints
   `[DRY RUN] PR #N: GitHub reports CONFLICTING but the local merge is clean — --execute would
   land it through the local-merge rung (GH-1656)` (or the squash stop) instead of "Would merge".
4. **Dirty message (R2):** on the existing B1 handoff, when GitHub said CONFLICTING and the
   conflict set holds a non-ledger path, also log
   `PR #N: non-ledger conflict; local merge dirty: <files>`. The handoff itself is unchanged.
5. **Batch record (R4):** `batch_record.set_outcome(..., rung=None)` stores `rung`; the
   merge-sequence status cell renders `merged (local-merge rung)`. Status stays `merged`, so
   `landed()` / `row_done()` / downgrade protection are untouched. Carry `rung` through
   `_merge_outcome` like the other touched fields.
6. **SKILL.md:** one bullet in the Phase 5 rules next to B1 describing the rung, its guards and
   the stop, plus the dry-run line. `skills/*/merge-cleanup/SKILL.md` is protected Markdown → the
   classified gate route.
7. Focused green: `bash test/gh436-merge-cleanup.sh` and
   `python3 test/gh534_phase_b_tests.py` (standalone run). Record green output beside the red.
8. Smoke (GH-1088): main path = the rung landing a CONFLICTING-but-clean PR in a disposable
   fixture (bare origin + stub, `--execute`, then a re-run of the dry run on the landed state
   — the adjacent path: the PR now reads MERGED and is recorded as merged outside the run, with no
   second landing). Receipt under `TESTS-RESULTS/2026-11-27+GH-1656/`.

## Acceptance (falsifiable)

- An unfixed candidate reaches `gh pr merge` on a forced-CONFLICTING clean PR → the stub refuses →
  test 1 fails red. After the fix the stub log has no `pr merge` entry and origin carries the
  local merge commit with the pin as second parent.
- Test 3 proves the rung never lands under a non-merge policy.
- Test 2 proves the dirty case stops before `gh pr merge` with the files named.
- Test 4 proves the dry run no longer says "Would merge" for CONFLICTING; test 5 pins UNKNOWN.

## Risks

- **GitHub's CONFLICTING is right and git's merge is wrong** (e.g. a rename git resolves
  differently). The landed tree is exactly what the pre-push gate qualified, and the merge
  commit is ordinary `git merge` output — the same thing the operator did by hand in #1654.
- **Direct push to `development` refused** by branch protection: the push fails, the run stops
  with the push error, nothing landed. Same exposure as `commit_and_push_phase5_writes`.
- **GitHub slow to mark MERGED:** bounded poll; the landing is still witnessed by the push itself.

## Rating (PRS, 2026-11-27)

`rated 75/70/50/60`. Severity 70: a work-blocking stop of the landing loop, recoverable by a
manual local merge (no data loss). Priority 75: one of four fixes the operator scheduled before
live Runs A/B (#1657). Appeal 50 (neutral, no operator value). Effort 60: one branch, one helper,
one record field, tests in an existing suite. Recurrence: 2 incidents on 2026-11-27 (#1651,
#1652, one batch); no earlier same-class report found in the last 28 days (trend unknown).
