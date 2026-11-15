# GH-1475 Phase 2A — verification receipts

Tested commit: `323b3d0e3` (implementation). The merge of `origin/development` into the branch
(`3eb65e64f`) brought only unrelated files, so `skills/2-daily/merge-cleanup/` and the two edited test
files are identical at both. Red control: base `a9ece7fcf` (`origin/development` at branch cut),
extracted with `git archive` into a scratch dir. No new tests or suites (GH-831). The driver is a
manual-check script, kept as `.txt`, and runs every scenario against both trees.

`python3 -I manual-p2a.py.txt <scripts-dir> base|new all`, with each scenario in its own scratch `TMPDIR`.
It drives the real `_land_prs_loop` against a scratch primary (a bare origin and a clone). Only the
GitHub-facing calls (`_gh`, PR refresh) and the landing/B1 machinery are stubbed. Where a merge is
attempted, the stub returns failure on purpose so nothing reaches post-merge writes. That is why those
scenarios end with rc 2: the evidence is the merge attempt and the head it targets.

| Item | Scenario | New | Red control (base) |
|---|---|---|---|
| P2.8 | dry run, two PRs that both need a B1 repair | both previewed (`[DRY RUN] PR #n: B1 would repair …`), rc 0, workdir removed | `B1 stopped` at #1, #2 never previewed, workdir kept |
| P2.2 policy | `wait_for_checks` as `["ci"]`, `[]`, `[""]`, `"ci"` | list accepted; the other three refused | all four refused (unknown key) |
| P2.2 wait | no required checks; declared `ci` pending then pass | waits, then merge attempted | base refuses the policy (rc 2); without the key, base and new both merge at once (control row) |
| P2.2 timeout | declared `ci` pending past `MERGE_CLEANUP_CHECKS_WAIT_S=2` | `DEFERRED — required checks pending (ci)`, rc 3, no merge | — |
| P2.2 absent | declared `ci` never reported (only `lint`) | `ci (not reported)` waited for, then deferred, no merge | — |
| P2.1 (a) | own B1 repair; old head `pass(ci)`; new head `pending(ci)` then `pass(ci)` | waits, re-pins to the repaired head (in memory and in the selection file), merge attempted at it | `DEFERRED — head … is not the dry-run pin` (rc 3), no merge |
| P2.1 (b) | as (a), but the new head goes from `pending(ci)` to "no required checks" | every such read counts as not registered; deferred at the wait limit, no re-pin, no merge | deferred (rc 3) |
| P2.1 (c) | external push lands while the run reads green | `DEFERRED — head … moved after this run's B1 repair`, no re-pin | deferred |
| P2.1 (d) | head moved off the pin before the run | unchanged: `moved off the dry-run pin`, deferred | same |
| P2.1 (e) | `pin_selection` fails | `DEFERRED — re-pin not published`, in-memory pin unchanged | deferred |
| P2.1 (f) | repo with no required checks at all | re-pinned with no wait, merge attempted | deferred |
| P2.3 handles | `inspect_open_handles` on a folder with a `sleep` whose cwd is that folder | `active=True (PID … (sleep))` | `active=False ("no open handles")`: the pre-existing defect found by the prune check below |
| P2.3 prune | real loop end; 5 old `merge-cleanup-*` + 5 old `merge-check-*`, an older one held open, a young `merge-check-*`, a symlink, a foreign prefix | removed 5 (`merge-cleanup-old3/4`, `merge-check-old2/3/4`); kept the newest 3 of each prefix (the young one counts), the held-open one, the symlink and the foreign prefix | everything kept |
| P2.3 controls | pgrep exit 2; pgrep finds a foreign PID; lsof incomplete; foreign owner; and a positive case | the first four keep the candidate; clean probe + verified idle prunes it | no pruning exists |
| P2.3 exit 3 | PR 1 B1-repaired, re-pinned and landed; PR 2 deferred on pending checks | `Released landed PRs' clones: pr-1-aaaaaaaa-…, pr-1-cccccccc-…, verify-cccccccc`; workdir holds only `pr-2` | PR 1 not landed (deferred); workdir holds everything |

Before the open-handle fix, the first P2.3 prune run removed the held-open folder. `inspect_open_handles`
used the strictly-inside `_within`, so a process whose cwd is the folder root was not a holder. Fixed in
`scan_clones.py` (`323b3d0e3`); the "P2.3 handles" row is its red control.

Output: `manual-check-run.log` (scratch paths shown as `<scratch>`). Existing suites:
`existing-suite-summary.txt`. Smoke: `smoke.log`.

Smoke: a real dry run of three open PRs (#1413, #1467, #1471) from the task clone against a disposable
full clone of this repo. P2.8: #1413 hands off (code conflict, as before), and #1467 and #1471 each log the
B1 preview, so the whole batch is previewed. P2.3: the five seeded folders were reduced by the policy
through the real CLI; the run's own workdir was excluded. The adjacent path is a rerun: the earlier run's
folder is under an hour old and is kept. A second adjacent path: `--show-merge-policy` accepts
`wait_for_checks: ["validate"]` and refuses `[]`.

## Kimi K3.1 Pro QA fixes (`c544c3884`, `345d60532`)

Third-seat QA (`relay-system/2026-11-15/gh1475-p2a-qa-kimi.md`) failed the PR on three blockers; all
three were confirmed in the code and fixed:

| Finding | Fix | Evidence |
|---|---|---|
| P2.1: `development` can move during the repaired-head check wait, and the ledger gate never saw the new base | after the wait, compare the clone's `origin/<branch>` with `ls-remote`; defer (exit 3) on change or unreadable | source change only; the base-unchanged re-pin paths stay green in the existing suite. Not exercised in a loop fixture |
| P2.3: a name prefix was the only proof of ownership; unique content could be deleted | pruning takes only `mkdtemp`-shaped folders whose entries are all tool-made; every removal keeps a clone with untracked files, a stash, a linked worktree, or tracked changes outside an in-progress merge (round 2) | `manual-kimi-fixes.log` checks 1-3 and 6-8; PR head red on 1, 2, 6, 7 |
| P2.3: the exit-3 release skipped the open-handle probe | the probe moved into `_remove_own_scratch`, so the clean-run removal, the exit-3 release and pruning all use it | checks 4-5; PR head removed the live-cwd folder |

Existing suite on `345d60532`: 227 tests OK. Not adopted: keeping clones whose HEAD is "unpushed". The tool pushes B1 merge commits by URL, so they have no remote-tracking ref; on the real temp root about 20 tool-made merge commits read as unpushed, and the rule would stop pruning. Those commits are reproducible by re-running B1.
