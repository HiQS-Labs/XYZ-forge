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
| Plan revised after Codex plan QA rounds 1–3 (8 blockers + 1 should accepted, 2 parts declined). | Codex plan QA round 4 (cap). |

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
   entry). Stub changes, each mirroring GitHub: `pr merge` refuses, with GitHub's message, a PR
   whose `force_mergeable` value is `CONFLICTING`; `view` infers MERGED for an OPEN PR **only from
   real origin ancestry** (its head is reachable from `origin/<base>`), enabled only by a
   per-test `infer_merged` flag so existing false-success controls keep their meaning, with the merge commit that
   introduced it; a `confirm_lag` / `confirm_withheld` knob delays or withholds that inference so
   the confirmation paths are exercised. Tests run with `--strategy merge` (no capability probe).
   Add `TestGh1656NonLedgerConflict`:
   - `test_clean_conflicting_lands_through_rung` — two PRs (so a batch issue exists): PR A
     non-ledger, forced `CONFLICTING`, clean, cut from the current base (so the simulation is
     already up to date — no `MERGE_HEAD`); PR B ordinary. Expect the existing landed/QA-pending
     exit 4, both MERGED at their pins, origin/development has a merge commit with first parent =
     the gated base and second parent = A's pin, **no `pr merge` call for A**, the rendered batch
     issue body shows `merged (local-merge rung)` for A.
   - `test_rejecting_hook_leaves_origin_unchanged` — a real `pre-push` hook dropped into the
     landing clone (by wrapping `prepare_landing_clone`) that honours `XYZ_SKIP_PREPUSH` like the
     real one and otherwise rejects; `XYZ_SKIP_PREPUSH=1` in the caller env. Stripped override →
     push refused, origin unchanged, rc 2 (an unstripped override would let it through: red).
   - `test_moved_base_refused` — origin/development advances (from another clone) between the
     final refresh and the push: the push is refused, origin keeps the intruder commit, rc 2.
   - `test_pr_closed_or_retargeted_before_push_stops` — final live read shows CLOSED (and, a
     second case, a different base): no push, origin unchanged.
   - `test_confirmation_lag_then_tail_once` — MERGED appears after N polls: the common tail runs
     once (one reconcile).
   - `test_confirmation_withheld_stops_without_reconcile` — MERGED never appears: rc 2, origin
     carries the pushed commit, the batch row is `stopped: local-merge rung published <oid>…`
     with no merge OID, no reconcile, no next landing. A second case returns MERGED with a
     different merge commit: `mismatch` stop, same assertions.
   - `test_push_acknowledgement_lost` — the one push call runs the real push, then returns rc
     124: the run treats the candidate as published (reads origin), never pushes twice, and
     lands through confirmation. Subcase: after the real push a child D is pushed from another
     clone before rc 124 returns: origin is D, C is its ancestor, still one push, published.
   - `test_confirmed_rung_reconciles_candidate` — `MERGE_CLEANUP_USE_HOSTED=1` with
     `wait_for_hosted_reconcile` intercepted: it receives the candidate as `merged_head` once.
   - `test_rung_label_survives_recovery` — renderer control on a batch record: rung + matching
     merge OID → `merged (local-merge rung)`; rung + different merge OID → plain `merged`.
   - `test_clean_conflicting_under_squash_stops` — default squash policy: rc 2, `non-ledger
     conflict; local merge clean: …` message, no `pr merge` call, development unchanged, stacked
     dependents untouched.
   - `test_dirty_non_ledger_conflict_message` — both sides edit `README.md`, forced CONFLICTING:
     the existing handoff exit (3), plus `non-ledger conflict; local merge dirty: README.md`, no
     `pr merge` call.
   - `test_dry_run_conflicting_clean_previews_rung` — dry run: no `Would merge PR #N`, a line
     naming the local-merge rung.
   - `test_dry_run_unknown_never_previews_merge` — UNKNOWN stuck (poll constants patched to 0):
     no `Would merge`, the existing "has not decided" stop. Green on base by design; the R3
     control for UNKNOWN.
   On base: the clean, squash, dirty-message and dry-run-preview cases fail red (the clean and
   squash cases reach the refusing `pr merge`). Record red output under
   `TESTS-RESULTS/2026-11-27+GH-1656/`.
2. **Rung (a)** in `merge_cleanup.py`: `land_via_local_merge(info, clone, primary_repo, branch,
   pinned)`, operating on the landing clone the ledger gate just passed:
   - Capture the **gated tree** (`git write-tree` of the clean `--no-commit` index) and the
     **gated base** (`rev-parse origin/<branch>` in that clone) before touching it.
   - Abort only an active merge (`MERGE_HEAD` present — a pin that already contains the base
     simulates as up to date with none); a failed capture, abort or checkout stops, nothing pushed.
     Then `checkout --detach <gated base>`; `git merge --no-ff --no-edit -m
     "Merge pull request #N from <headRefName>" <pin>` (body names GH-1656 and the rung).
     Dirty → return its conflicted files (stop (b), "local merge dirty").
   - Verify before publishing: `HEAD^1 == gated base`, `HEAD^2 == pin`, `HEAD^{tree} == gated
     tree`. Any mismatch → stop with that reason, nothing pushed (the commit must be exactly what
     was gated). Capture the candidate OID.
   - `gate_unwired_reason(clone)`; env with `XYZ_SKIP_PREPUSH` removed; then
     `git push --force-with-lease=refs/heads/<branch>:<gated base> origin HEAD:refs/heads/<branch>`
     via `_net_git(..., timeout=PUSH_GATE_TIMEOUT_S)`. The lease is the atomic compare-and-swap
     for "the base is still exactly the gated base"; because HEAD descends from that base, the
     update is always a fast-forward when the lease holds, so it never rewrites history. Never
     `--force` without a lease, never `--no-verify`. The clone's installed hook runs the gate.
   - Push nonzero (rejection, or rc 124 timeout with a possibly lost acknowledgement): fetch the
     destination into the clone. Its tip equals or descends from the candidate
     (`merge-base --is-ancestor`) → published, go to confirmation; a fetched tip that does not
     contain the candidate → rejected, nothing landed (an integration branch is never rewound);
     fetch fails → stop as `publication unknown` naming the candidate OID. Never a second push.
   - After a publication: poll `refresh_pr_with_retry` (bounded by `MERGEABLE_POLL_*`) until
     MERGED. Confirmed only when MERGED, `headRefOid == pin`, `baseRefName == branch` and
     `mergeCommit.oid == candidate` → `("merged", candidate)`. MERGED with any other head, base
     or merge commit → `("mismatch", …)`; no MERGED → `("unconfirmed", candidate)`.
3. **Wire it** at the existing merge call. On the final live refresh (which already checks
   draft/hold/head/pin), add: `state == OPEN` and `baseRefName == branch`, else stop. Route on
   the live `mergeable`: `MERGEABLE` → unchanged `execute_pr_merge`; `CONFLICTING` → the rung
   under strategy `merge`, else stop (b) `non-ledger conflict; local merge clean: no conflicted
   files; strategy <s> cannot be landed locally` — this check runs **before**
   `_protect_stacked_dependents`, so a stop never edits dependent PRs; anything else → stop
   "GitHub has not decided". Rung `merged` → the existing tail (`_MERGED_THIS_RUN`,
   `_record_merge_outcome(..., rung="local-merge")`, fast-forward, reconcile with
   `merged_head=<confirmed oid>` (rung landings only, so hosted lookup matches the candidate even
   if the tip moved), emit, writes).
   Rung `unconfirmed` / `mismatch` / `publication unknown` → nothing in `merge_oid`, no
   reconcile, no next PR, exit 2; the stop line (which the Phase 5 finalizer copies into the
   batch row as `stopped: …`) names the rung, the candidate OID, the pin and the target, e.g.
   `local-merge rung published <oid> to origin/<branch> (pin <sha>); GitHub has not confirmed
   PR #N MERGED — once it reads MERGED with that merge commit and head, run --reconcile-pr N;
   do not re-land`. Mismatch says `investigate before reconciling`. Validating these fields
   inside `--reconcile-pr` is out of scope (the operator verifies against the named OIDs). Rung
   failure before the push → exit 2, clone kept. The dry-run branch prints
   `[DRY RUN] PR #N: GitHub reports CONFLICTING but the local merge is clean — --execute would
   land it through the local-merge rung (GH-1656)` (or the squash stop) instead of "Would
   merge", only when the existing checks-pending preview did not already report that it would
   not merge yet.
4. **Dirty message (R2):** on the existing B1 handoff, when GitHub said CONFLICTING and the
   conflict set holds a non-ledger path, also log
   `PR #N: non-ledger conflict; local merge dirty: <files>`. The handoff itself is unchanged.
5. **Batch record (R4):** `batch_record.set_outcome(..., rung=None, rung_oid=None)` stores the
   rung and the candidate OID it published, both on confirmation and on every post-push stop
   (`unconfirmed` / `mismatch` / `publication unknown`), never in `merge_oid`. The merge-sequence
   status cell renders `merged (local-merge rung)` only when `status == merged` and
   `merge_oid == rung_oid`, so a later `--reconcile-pr N` recovery that records the same merge
   OID keeps the label, and a different merge OID never gets it. Status stays `merged`, so
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

- R1: `test_clean_conflicting_lands_through_rung` fails on base (the stub refuses `pr merge`); on
  the candidate origin carries a merge commit with parents (gated base, pin) and the gated tree,
  with no `pr merge` call for that PR. Publication-safety controls: rejecting hook, moved base,
  closed/retargeted PR, lost acknowledgement, confirmation lag/withheld/mismatch.
- R2: `test_clean_conflicting_under_squash_stops` (red on base) and
  `test_dirty_non_ledger_conflict_message` (red on base: message missing).
- R3: `test_dry_run_conflicting_clean_previews_rung` (red on base: prints `Would merge`);
  `test_dry_run_unknown_never_previews_merge` (green control).
- R4: the rendered batch issue body in the R1 test shows `merged (local-merge rung)`.

## Risks

- **GitHub's CONFLICTING is right and git's merge is wrong** (e.g. a rename git resolves
  differently). The landed tree is exactly what the pre-push gate qualified, and the merge
  commit is ordinary `git merge` output — the same thing the operator did by hand in #1654.
- **Direct push to `development` refused** by branch protection: the push fails, origin is read
  back to confirm nothing landed, the run stops with the push error. Same exposure as `commit_and_push_phase5_writes`.
- **GitHub slow to mark MERGED:** bounded poll; the landing is still witnessed by the push itself.

## Rating (PRS, 2026-11-27)

`rated 75/70/50/60`. Severity 70: a work-blocking stop of the landing loop, recoverable by a
manual local merge (no data loss). Priority 75: one of four fixes the operator scheduled before
live Runs A/B (#1657). Appeal 50 (neutral, no operator value). Effort 60: one branch, one helper,
one record field, tests in an existing suite. Recurrence: 2 incidents on 2026-11-27 (#1651,
#1652, one batch); no earlier same-class report found in the last 28 days (trend unknown).
