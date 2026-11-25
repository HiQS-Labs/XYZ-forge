# GH-1603 manual check

The original CLI ran at `c2e528dd13d504e5650c2c97b987ae17dd157ac6`. The changed CLI ran at the implementation revision recorded in `provenance.jsonl`. The three checked runtime/runbook paths were byte-identical after the integration refresh. No test was added to the suite.

## Fixture and commands

Initialize a development branch and clone it into a bare upstream and two disposable checkouts. Create one local commit with a transcript containing `Repository: https://github.com/example-fixture/unknown-repo`. Add a linked worktree at its exact tip, create one stash and modify one working file. Advance the bare upstream by one distinct commit and fetch into the divergent checkout. Stub only `gh` discovery and visibility answers using `MERGE_CLEANUP_GH_BIN`. For the provenance error control, create a local tag and force only `git ls-remote` to return 1. The working changes, refs, linked index, stash and divergence are real Git objects.

```sh
python3 skills/2-daily/merge-cleanup/scripts/merge_cleanup.py \
  --primary "$CHECKOUT" --root "$FIXTURE" --prefix primary --prs-only
python3 skills/2-daily/merge-cleanup/scripts/scan_clones.py \
  --check-transcript-parking "$CHECKOUT" --parking-tip "$TIP"
```

Capture the full output, then inspect its last 20 lines. Check the normal preview with an empty PR queue, scan-only and PR-only, PR discovery returning a hard error, and a request for a nonexistent PR. To emulate refused caller publication, stop on precheck exit 1 and confirm the temp ref is absent in the bare origin. For the permission-free red control, the old creation-only route pushed the fictional transcript into a temp branch in that same disposable origin. For the positive pin control, move the convenience ref before pushing the scanned OID, then read back the remote ref.

## Results

| Criterion | Original | Changed |
|---|---|---|
| 1. One last-20-lines verdict | PR warning only referred back to Phase 0; no stash or behind count in the verdict. | Footer had `dirty paths: 1; stashes: 1 (advisory); integration commits ahead: 1, behind: 1` with both blockers and the parking refusal. All five preview endings retained it. Discovery and selection errors returned 2. An unfinished cherry-pick also appeared in the footer. |
| 2. Audit agreement | One commit ahead and two unlanded refs at the same tip. The failing tag query displayed zero unpushed. | Primary row showed 1 dirty, 1 stash, 1/1 integration commits and 2 refs with complete proof. Failed merged-PR lookup showed 2 with incomplete proof; failed tag query showed unknown. The audit fetch did not change the primary snapshot in the same run, and a second run reported the newly fetched behind count. Stash and behind alone still produced READY. |
| 3. Foreign private transcript | No visibility assessment. The old caller route created the fixture ref with that transcript. | Phase 0 and footer refused remote parking. The exact-tip precheck exited 1 for verified private, and the caller left no remote ref. A separately authorized fixture-public candidate succeeded. Publishing the scanned OID still used that OID after its convenience ref moved. |
| 4. Same-repo transcript and ordinary docs | No assessment. | A matching origin and `Repository:` field cleared, and a reference in ordinary docs outside the roots cleared. A same-tip linked checkout with its own staged foreign transcript refused while the first checkout still cleared. |
| 5. Lookup and read failures | No assessment. | Failed and mismatched visibility lookups refused. Unidentifiable and non-regular transcript files refused. Separate untracked and staged cases refused, as did a rename out of the transcript root and a deleted intermediate blob. Status, refs, index and FETCH_HEAD matched before and after the precheck. |
| 6. Clean primary | READY. | READY without additional warnings or footer. |

The detector covers structural GitHub repository references and explicit repository fields in recognized roots. A transcript can contain undisclosed material even when its known references are public or same-repository. Workspace names, context without a repository reference, ignored artifacts, and files outside the checked roots require direct review.
