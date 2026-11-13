---
title: Jog checkpoint starts from local state and reconciles once when development has moved
status: In progress
created: 2026-11-13
updated: 2026-11-13
owner: Noel Saw
branch: fix/XYZ-forge-gh1453-jog-local-reconcile-2026-11-13
gh_issue: 1453
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1453
doc_type: bugfix
complexity: 3
risk: 3
effort: 3
phases: 1
reported_from: LTVera-Pandas
harness_commit: 6c0c76bb5
non_goals:
  - Publishing each queue transition as it happens (GH-1108 delivery 2, stopped)
  - Changing the per-task preflight fetch in the execution clone
  - Changing merge-cleanup's landing flow or ledger_merge.py (B1)
  - Moving the ledger out of the repository (GH-1224)
goal: >
  A `jog run --checkpoint-root` wake depends only on local state while it runs, and publishes
  once at the end. When `development` has moved in the meantime, the wake reconciles its own
  queue writes onto the moved ledger through the canonical writer and publishes, as a normal
  outcome. The only stop is a real overlap, and the skill lists every legal stop by its message.
---

# GH-1453 — Jog checkpoint: local state during the run, one reconcile at the end

## Status

| What was just completed | What's next |
|---|---|
| Issue filed, task clone provisioned, recon and plan written (2026-11-13). | Codex plan QA, then implementation in `utils/py/jog_run.py` and `skills/2-daily/jog/SKILL.md`. |

## Rating rationale (2026-11-13)

`rated 75/70/50/40` (pri/sev/appeal/effort).

- **sev 70:** work-blocking for unattended multi-hour runs on a shared branch. When `development`
  moves during a wake, the run ends in a Python traceback and a hand repair of the ledger. No data is
  lost: the checkpoint commit and journal are kept.
- **pri 75:** it held a real five-task downstream run for a day (LTVera-Pandas issue 1014,
  2026-11-13), and the operator asked for it to be fixed now. Kept close to severity.
- **appeal 50:** neutral; the operator gave no preference.
- **effort 40:** one core file behind the full gate, with a real merge-and-replay path that has no
  suite and needs manual fixture verification.
- **Recurrence** (Jog publication against a moving `development`): this incident (2026-11-13);
  GH-1207 (2026-10-22, dirty primary after a Jog verb); GH-1108 delivery 2 (2026-10-17, per-transition
  publication, stopped unmerged as PR 1117). Same seam, three reports in four weeks. Coverage is a
  title and body search of open issues, not an incident count.

## Recon (base `6c0c76bb5`)

- **Entry:** `releases_app.py jog run` → `jog_run.jog_run_main`. With `--checkpoint-root`,
  `JogCheckpoint(root, checkpoint_root)` wraps the loop: `begin()` before the first lease
  (`utils/py/jog_run.py:2357-2361`), `finish()` after the loop (`:2541-2542`).
- **Start gate** (`jog_run.py:2140-2160`): requires the primary pin, refuses foreign dirt, refuses
  pre-existing ledger changes, then `fetch origin development` and
  `ContractError("checkpoint requires primary HEAD at published origin/development")` unless the two
  are equal.
- **Mid-run writes are local.** Every lease and status goes through `perform_write`
  (`utils/py/releases_app.py:1662`), which rewrites `releases.db` and `releases.sql` in the primary and
  appends one `op_receipts` row per write. Nothing is committed or pushed. With a separate execution
  clone, contract promotion returns before touching the primary's roadmap rows
  (`jog_run.py:1764-1767`), so the only writes a wake makes to the primary ledger are `jog-lease`,
  `jog-<status>` and `jog-reconcile`. Per-execution state lives in `.tick/jog/<gid>/state.json`, which
  is local and not in the ledger.
- **End** (`jog_run.py:2162-2199`): commit the two ledger files in the primary, fast-forward the
  publication clone to that commit, read the live ref with `ls-remote`, then one plain
  `git push origin <commit>:refs/heads/development`.
- **What happens when `development` moved:** the push is non-fast-forward, `_git` raises
  `ContractError` (`jog_run.py:1116-1121`), and nothing in `jog_run_main` catches it, so the run ends
  in a traceback. The journal stays at `phase: "committed"`. The next wake sees the unpublished
  journal and calls `finish()` again (`:2143-2150`), which fails the same way until someone repairs the
  ledger by hand.
- **Why the existing ledger merge does not help:** `ledger_merge.classify` reports any `jog_queue`
  change on the replayed side as "the writer path cannot express this table"
  (`skills/2-daily/merge-cleanup/scripts/ledger_merge.py:228-234`), and it only runs in a disposable
  clone, where `jog-*` writes are refused (`releases_app.py:1675-1676`).
- **What can be reused as is:** `jog_acquire_lease` and `jog_set_status` (the canonical writers, already
  imported by `jog_run.py`); `releases_app.py check --rebuild`; `utils/releases-merge-resolve.sh`,
  which rebuilds the DB from the merged dump, regenerates the views, stages them, and refuses a dump
  whose generation is below either parent.
- **Skill text** (`skills/2-daily/jog/SKILL.md:158-162`): "Unrelated changes, divergence or rejected
  push stop and preserve state for reconciliation." It does not say what is not a stop. The phrases
  "quiet window", "competing writer" and "one coordinator" appear nowhere in the Jog skill or code.
- **Coverage:** no suite references `--checkpoint-root` or `JogCheckpoint`
  (`git grep -l -E "checkpoint-root|JogCheckpoint" -- test` is empty). GH-1358 verified the checkpoint
  with manual rehearsals under `TESTS-RESULTS/2026-11-08+GH-1358-rehearsal/checkpoint/`.
- **Not traced:** downstream vendored copies (`.xyz/`) and the publisher; the factory reconciler
  (GH-1175/GH-1207) that may call the same checkpoint.

## Preflight bet

- **Outcome sought:** a wake that started finishes and publishes without a human, whether or not
  other sessions wrote to `development` meanwhile, and an agent reading the skill cannot conclude
  that it must wait for a quiet branch.
- **Smallest viable bet:** changes inside `JogCheckpoint` only. Replay the wake's own queue writes,
  which the ledger already records as receipts, onto the remote ledger. Not built: a general ledger
  merge, per-transition publication, any change to B1 or merge-cleanup.
- **Alternatives rejected:**
  - *Skill text only.* It would tell agents to proceed into an end-of-run failure that is likely on a
    busy branch.
  - *Extend B1 (`ledger_merge.py`) to carry Jog rows.* B1 runs in a disposable clone where Jog writes
    are refused, and it keeps the higher-generation side, which is often the wake's side; replaying
    the remote's changes then needs verbs that do not exist.
  - *Publish every transition immediately (GH-1108 delivery 2).* Stopped by the operator at 4,960
    added lines; it also couples every task to the remote, the opposite of this request.
- **Rollback / containment:** the behaviour is behind the opt-in `--checkpoint-root` flag. Every
  failure path aborts the merge and leaves the checkpoint commit and journal exactly as today.
  Rollback is one revert.

## Plan

Reversibility: **Easy**. One file of code behind an opt-in flag; a revert restores today's behaviour.
Existing subsystem and writer extended: `JogCheckpoint` in `utils/py/jog_run.py`; ledger writes only
through `jog_acquire_lease` / `jog_set_status` / `jog_reconcile_orphan_leases` in `releases_app.py`.

1. **`begin()` uses local state only.** Remove the fetch and the equality check. Keep the primary
   pin, the foreign-dirt refusal and the pre-existing-ledger-change refusal. Add one local check: no
   commit on `HEAD` that is absent from the local `origin/development` ref, else
   `checkpoint refuses unpublished local commits`. Record in the journal, next to `base`: the
   `txn_id` of the newest `op_receipts` row, and `status`, `attempt_count` and `failure_reason` for
   every `jog_queue` row. -> expect a primary that is behind the remote to start; a primary with a
   local unpublished commit to refuse.
2. **`finish()` publishes as today when the live ref is the wake's base** (or already the checkpoint
   commit). No behaviour change on this path. -> expect identical output to base.
3. **`finish()` reconciles when the live ref is anything else.** In the primary, up to three attempts:
   1. `fetch origin development`; `git merge --no-commit --no-ff origin/development`.
   2. If any unmerged path is outside `releases.db`, `releases.sql` and the three ledger views, abort
      the merge and stop (step 5).
   3. If the remote did not change `releases.sql` since the base, commit the merge and go to 3.7.
   4. Take the remote side of `releases.sql` and `releases.db` (the merge-conflict form,
      `git checkout --theirs`, on the two conflicted ledger files only; the wake's version is safe in
      the checkpoint commit), stage the dump, and run `check --rebuild`.
   5. **Overlap check.** The wake's writes are the `op_receipts` rows after the recorded `txn_id`,
      read from the checkpoint commit's database before the merge. Every one must be a `jog-` op. For
      every queue row the wake changed, the remote's row must equal the recorded start values.
      Otherwise abort and stop, naming the rows.
   6. **Replay** the wake's receipts in order through the canonical writers: `jog-lease` →
      `jog_acquire_lease`; `jog-<status>` → `jog_set_status`, passing the wake's final
      `failure_reason` on the last status write for that row; `jog-reconcile` →
      `jog_reconcile_orphan_leases`. Any other op aborts and stops. Then verify that every row the
      wake changed now has the wake's final `status`, `attempt_count` and `failure_reason`; a mismatch
      aborts and stops. One replayed write per original write keeps the generation at or above both
      parents, which the resolver enforces.
   7. Run `utils/releases-merge-resolve.sh --root <primary>`, then `check`; remove the
      `releases.db.bak` that the rebuild leaves; commit the merge as
      `jog: reconcile wake checkpoint <base> onto <remote>`; record it as the journal's `commit`.
   8. Publish through the existing publication-clone path. If the push is rejected because the
      remote moved again, repeat from 3.1. The replay source is still the original checkpoint commit
      and the recorded start values, so a repeat is the same procedure on a newer remote.
   -> expect the wake's transitions and the remote's rows both on `origin/development`, `check` clean,
   primary clean and equal to the remote, journal `published`.
4. **A checkpoint stop is a message, not a traceback.** `jog_run_main` catches `ContractError` from
   `begin()` and `finish()`, prints `jog: checkpoint held: <reason>` and exits 2. -> expect no
   traceback on any checkpoint stop.
5. **The stop.** On overlap, an unexpected op, a non-ledger conflict, a refused replay, a red check,
   or three moved-again attempts: `git merge --abort`, remove `releases.db.bak`, leave the journal at
   `committed` with the original checkpoint commit. The next wake retries the reconcile before any
   dispatch, as it retries the push today. A journal written before this change has no recorded start
   values; it gets the plain push and, if that is rejected, the stop.
6. **Skill text.** Replace the "Interim publication checkpoint" paragraph's open-ended stop sentence
   with a short section: Jog contacts `origin/development` only at publication; ledger writes by other
   sessions are never a stop and a quiet window is never requested; a moved `development` is
   reconciled automatically; the legal checkpoint stops, each by its exact message; what to do at a
   stop (rerun the same command; never force-push, reset, or hand-edit the ledger). -> expect each
   listed message to be found verbatim in `jog_run.py`.
7. **Records.** `CHANGELOG.md` entry; manual-check receipts and `provenance.jsonl` under
   `TESTS-RESULTS/2026-11-13+GH-1453/`.

## Acceptance

Each item is a manual check against a local fixture: a bare origin, a primary clone carrying the
primary pin, a publication clone, and a third clone that plays the other session.
The red control is the same check on base `6c0c76bb5`.

- [ ] **A1 moved, disjoint.** The other session pushes a roadmap write during the wake. The wake ends
  `published`; `origin/development` holds the remote's row and the wake's queue transitions;
  `check` is clean; the primary is clean and equal to the remote. Red control on base: rejected push,
  traceback, journal `committed`.
- [ ] **A2 behind at start.** The primary is one commit behind the remote at start. The wake starts.
  Red control on base: `checkpoint requires primary HEAD at published origin/development`.
- [ ] **A3 overlap.** The other session changes the same `jog_queue` row. The wake prints
  `jog: checkpoint held:` naming the row, exits 2 with no traceback, the primary is at the checkpoint
  commit with no merge in progress and no `releases.db.bak`, and the remote is unchanged. Control:
  remove the overlapping write and the same fixture reconciles.
- [ ] **A4 unmoved.** With no remote movement, the published commit's tree and the console output
  match base.
- [ ] **A5 rerun after a stop.** After A3, resolve the overlap on the remote side and rerun the same
  command: it reconciles and publishes without dispatching a task.
- [ ] **A6 skill text.** Every stop message listed in `skills/2-daily/jog/SKILL.md` is found verbatim
  in `utils/py/jog_run.py`, and the section states that remote ledger activity is not a stop. Red
  control: the check fails on base, where the section does not exist.

## Verification

- Existing suites, run in a disposable `-gate` clone: `test/gh280-jog-marathon-adapter.sh`,
  `test/jog-queue.sh`. Final gate by `utils/ci-route.sh` classification of the changed paths
  (`jog_run.py` is core, so the full qualifying run, once, on the approved commit).
- A1–A6 as manual checks with commands, output and verdicts under
  `TESTS-RESULTS/2026-11-13+GH-1453/`. Smoke: A1 is the main path; A5 is the adjacent path.
- No new suite, registry entry or test file (GH-831).

## Risks

- **A real merge runs in the primary.** It also brings the remote's non-ledger commits into the
  primary, which is what a fast-forward would do after publication anyway. Every failure aborts the
  merge; the tree was clean before it, so the abort restores the checkpoint commit exactly.
- **`git checkout --theirs` on two files in the primary.** This is conflict resolution inside a merge,
  on files whose other version is committed, not the tree-restoring form `AGENTS.md` forbids.
- **Replayed writes get new timestamps and receipts.** The wake's original receipts remain in git
  history on the checkpoint commit, which is a parent of the merge.
- **A wake that includes an orphan-lease reconcile** replays only if the remote's row is still in the
  same state; otherwise the final-state verification stops it. Accepted: this is crash recovery, and
  the stop is safe.
