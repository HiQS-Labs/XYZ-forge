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
- **Adopted views (pre-existing gap).** Every canonical write calls `refresh_preview`
  (`releases_app.py:1763`), which rewrites `RELEASES-PREVIEW.html` and `LEADERBOARD.html` when the repo
  has them at its root (`:1364-1393`). The checkpoint owns only the two ledger files
  (`jog_run.py:2113`) and refuses every other dirty path (`:2135-2138`), so in a repo that adopts
  either view a wake with one queue write is refused at `finish()`. This repo adopts neither file, so
  the GH-1358 rehearsal did not meet it; a downstream repo vendored with the releases overlay can.
- **Writer refusals are `SystemExit`, not `ContractError`** (`releases_app.py:209-211`), and the
  `JogCheckpoint` constructor raises outside any handler (`jog_run.py:2119-2122,2358`).
- **Rebuild and generation.** `check --rebuild` sets the generation to
  `max(dump generation, existing DB generation) + 1` (`releases_app.py:6568-6570`), copies the
  displaced DB to `releases.db.bak` and rewrites the dump (`:6654-6660`). The dump serializes every
  `lease_pid` as NULL (`:1273-1278`).
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
through `jog_acquire_lease` and `jog_set_status` in `releases_app.py`.

**Journal.** `.tick/jog/checkpoint.json` keeps `base` and `phase` and gains: `source` (the wake's
own checkpoint commit, the replay source, never rewritten), `anchor` (the `txn_id` of the newest
`op_receipts` row at start, or null for an empty log) and `queue` (`status`, `attempt_count`,
`failure_reason` per `jog_queue` row at start). `commit` stays the current publication head: the
checkpoint commit first, then the latest reconcile merge.

1. **`begin()` uses local state only.** Remove the fetch and the equality check. Keep the primary
   pin, the foreign-dirt refusal and the pre-existing-ledger-change refusal. Add two local checks:
   the local `origin/development` ref exists, else `checkpoint requires a local origin/development
   ref`; and `HEAD` has no commit absent from it, else `checkpoint refuses unpublished local commits`.
   Record `anchor` and `queue`. -> expect a primary behind the remote to start; a primary with a local
   unpublished commit to refuse.
2. **Own the views a write refreshes.** The owned set becomes the two ledger files plus
   `RELEASES-PREVIEW.html` and `LEADERBOARD.html` when they exist at the root. They are committed
   with the checkpoint. Any other dirty path is still refused. -> expect a wake in a repo with an
   adopted view to finish; an unrelated dirty file to be refused as today.
3. **`finish()` publishes as today when the live ref is the wake's base** (or already the
   publication head). No behaviour change on this path.
4. **`finish()` reconciles when the live ref is anything else.** In the primary, at most three
   attempts, each:
   1. `fetch origin development`. If it is already an ancestor of `HEAD`, skip to 4.9.
   2. `git merge --no-commit --no-ff origin/development`. If any unmerged path is outside the two
      ledger files and the three ledger views, stop (step 6).
   3. If the remote did not change `releases.sql` since the merge base, there is no ledger work:
      go to 4.8.
   4. Put the remote's dump in place whether or not the textual merge conflicted: write the bytes of
      `origin/development:releases.sql` to the working file and stage it, then `check --rebuild`. No
      `git checkout` is used.
   5. **The wake's writes** are read from the `source` commit's `releases.db`, extracted to a
      temporary file and opened read-only: the `op_receipts` rows whose `id` is greater than the
      anchor row's `id` (resolved by `txn_id` in that same file), in `id` order. Each must be
      `jog-lease` or `jog-<status>`. Anything else, including `jog-reconcile` (a global orphan scan
      that cannot be replayed safely against another ledger), is a stop.
   6. **Overlap check.** For every queue row those writes target, the remote's row must equal the
      recorded start values. Otherwise stop, naming the rows.
   7. **Replay** in order through the canonical writers: `jog-lease` → `jog_acquire_lease`;
      `jog-<status>` → `jog_set_status`, passing the wake's final `failure_reason` on the last status
      write for that row. A writer refusal (`SystemExit`) is converted to a stop. **Verify:** every
      targeted row now has the wake's final `status`, `attempt_count` and `failure_reason`, and every
      other queue row has the same three values it had on the remote before the replay. A mismatch is a
      stop.
   8. Run `utils/releases-merge-resolve.sh --root <primary>` when step 4.4 ran (it rebuilds, regenerates
      the adopted views and stages them), then `check`; remove `releases.db.bak`; commit the merge
      **once** as `jog: reconcile wake checkpoint <base> onto <remote sha>`; set the journal's `commit`
      to it.
   9. Publish through the existing publication-clone path. If the push is rejected and the live ref has
      moved again, start the next attempt at 4.1 from the new `HEAD`. The replay source and start
      values are unchanged, so a later attempt replays the same writes onto a newer remote ledger.
   -> expect the wake's transitions and the remote's rows both on `origin/development`, both the
   remote's commit and the checkpoint commit as ancestors of the published head, `check` clean,
   primary clean and equal to the remote, journal `published`.

   *Generation.* The resolver refuses a dump whose generation is below either merge parent. Step 4.4's
   rebuild already sets the generation above both the remote's and the primary's current one, before
   any replay, and each replayed write raises it further. A refusal here is a stop, not something to
   pad around.
5. **Resume recognition.** `finish()` accepts `HEAD` when it equals the journal's `commit`, or when
   its first parent equals the journal's `commit` (or `base`, before any commit is recorded) and its
   subject is the checkpoint message or starts with `jog: reconcile wake checkpoint <base> onto `. The
   second form covers a crash between a commit and the journal save. Anything else is the existing
   `checkpoint primary HEAD changed outside this wake`.
6. **The stop.** What is kept depends on where it happens:
   - *While a merge is open* (4.2–4.8): stage the owned paths, `git merge --abort`, remove
     `releases.db.bak`. `HEAD` stays at the journal's `commit`. The tree was clean before the merge,
     and staging first leaves the abort nothing unstaged to trip on; the fixture asserts the restored
     tree.
   - *After a merge commit* (4.9, or three attempts used): nothing is undone. The latest merge commit
     is the journal's `commit` and the publication clone is already fast-forwarded to it.
   In both cases the journal stays at `committed`, and rerunning the same command retries the
   reconcile before any dispatch, as it retries the push today. A journal written before this change
   has no `source`, `anchor` or `queue`; it gets the plain push and, if that is rejected, a stop.
7. **A checkpoint stop is a message, not a traceback.** `jog_run_main` catches `ContractError` from
   the `JogCheckpoint` constructor, `begin()` and `finish()`, prints `jog: checkpoint held: <reason>`
   and exits 2.
8. **Skill text**, scoped to checkpoint publication. Replace the open-ended stop sentence in
   `skills/2-daily/jog/SKILL.md` with a short section: the checkpoint contacts `origin/development`
   only at publication (per-task preflight in the execution clone still fetches); ledger writes by
   other sessions are never a stop and a quiet window is never requested; a moved `development` is
   reconciled automatically; the legal checkpoint stops, each by its exact message; what to do at a
   stop (rerun the same command; never force-push, reset or hand-edit the ledger). -> expect each
   listed message to be found verbatim in `jog_run.py`.
9. **Records.** `CHANGELOG.md` entry; manual-check receipts and `provenance.jsonl` under
   `TESTS-RESULTS/2026-11-13+GH-1453/`.

## Acceptance

Each item is a manual check against a local fixture: a bare origin, a primary clone carrying the
primary pin, a publication clone, and a third clone that plays the other session. As in the GH-1358
controls, the checks drive `JogCheckpoint` and the supported ledger CLI directly; A3 also runs the
`jog run` command line for the message and exit code. A1–A3, A5–A9 are change checks and must fail on
base `6c0c76bb5` for the stated reason. A4 is a preservation check and must pass on base.

- [ ] **A1 moved, disjoint.** The other session pushes a roadmap write during the wake. The wake ends
  `published`. On `origin/development`: the remote's roadmap row is present with its values; each
  queue row the wake wrote has the wake's `status`, `attempt_count` and `failure_reason`; the remote's
  commit and the checkpoint commit are both ancestors of the head; `check` is clean; the primary is
  clean and equal to the remote. Red control on base: rejected push, `ContractError`, journal
  `committed`.
- [ ] **A2 behind at start.** The primary is one commit behind the remote and its tracking ref is
  stale. The wake starts and, after a queue write, publishes with the result of A1. Red control on
  base: `checkpoint requires primary HEAD at published origin/development`.
- [ ] **A3 overlap and restore.** The other session changes the same `jog_queue` row. Through the
  `jog run` command line: `jog: checkpoint held:` naming the row, exit 2, no traceback. The primary is
  at the checkpoint commit with no merge in progress, a clean tree whose `releases.db` matches that
  commit, and no `releases.db.bak`; the remote is unchanged. Control: without the overlapping write
  the same fixture reconciles.
- [ ] **A4 unmoved (preservation).** With no remote movement the wake publishes one checkpoint commit
  whose parent is the base and whose message is unchanged, with the same console line. Passes on base
  and on the candidate; timestamps and receipt ids are not compared.
- [ ] **A5 rerun after a stop.** After A3, the other session restores the row and the same command is
  rerun: it reconciles and publishes without dispatching a task.
- [ ] **A6 skill text.** Every stop message listed in `skills/2-daily/jog/SKILL.md` is found verbatim
  in `utils/py/jog_run.py`, and the section states that remote ledger activity is not a stop. Red
  control: the check fails on base, where the section does not exist.
- [ ] **A7 moved again during publication.** A hook in the publication clone lets the other session
  push once more during the first push. The wake still ends `published` after a second attempt; the
  head has both remote commits and the checkpoint commit as ancestors; the queue rows carry the wake's
  values exactly once (`attempt_count` not doubled).
- [ ] **A8 code-only movement.** The other session pushes a commit that does not touch the ledger. The
  wake publishes exactly one merge commit and the ledger files equal the checkpoint commit's.
- [ ] **A9 adopted view.** With `RELEASES-PREVIEW.html` present at the root, a wake with one queue
  write finishes and the view is committed with it; an unrelated dirty file is still refused. Red
  control on base: `checkpoint refuses unrelated changes` naming the view.
- [ ] **A10 crash after the merge commit.** After A1's merge commit, the journal's `commit` is put
  back to the checkpoint commit and the command is rerun: it recognises the merge and publishes it
  rather than refusing.

Not covered by a fixture: a writer refusal during replay (step 4.7). The overlap check runs first and
catches every input found that would make a writer refuse, so this path is defence in depth; it is
checked by reading and recorded as unverified by fixture.

## Verification

- Existing suites, run in a disposable `-gate` clone: `test/gh280-jog-marathon-adapter.sh`,
  `test/jog-queue.sh`. Final gate by `utils/ci-route.sh` classification of the changed paths
  (`jog_run.py` is core, so the full qualifying run, once, on the approved commit).
- A1–A10 as manual checks with commands, output and verdicts under
  `TESTS-RESULTS/2026-11-13+GH-1453/`. Smoke: A1 is the main path; A5 is the adjacent path.
- No new suite, registry entry or test file (GH-831).

## Risks

- **A real merge runs in the primary.** It also brings the remote's non-ledger commits into the
  primary, which is what a fast-forward would do after publication anyway.
- **Restore after a failed open merge** rests on `git merge --abort` from a tree that was clean before
  the merge and fully staged before the abort. A3 asserts the result rather than assuming it.
- **Replayed writes get new timestamps and receipts.** The wake's original receipts remain in git
  history on the checkpoint commit, which is a parent of the merge.
- **A wake that includes an orphan-lease reconcile is not reconciled automatically** when
  `development` has moved. It stops with a named message. Accepted: this is crash recovery combined
  with a moved remote, and replaying a global orphan scan against another ledger can change rows the
  wake never touched.
- **Queue positions** of rows the wake did not touch are whatever the canonical writer computes on
  the remote queue; they are not compared with the wake's local positions.
