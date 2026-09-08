# GH-421 — reconciliation controls

Local focused checks, 2026-09-08, macOS / Python 3.14.7. These are not a full gate,
hosted delivery evidence, or promotion evidence. The harness owns the final committed-state
gate and its qualifying provenance receipt. The relay turn allows this baseline file but
no additional committed receipt paths.

The executable fixture is `test/gh421-auto-wave-reconcile.sh`. It initializes a real Releases
DB through `releases_app.main`, including a dialed-in manifest member, an active roadmap row,
an active document with Lessons Learned, and offline merged-PR / closed-issue metadata.
It asserts non-empty DB and SQL artifacts before comparing snapshots. Git, network,
dashboard generation, and planner execution are replaced with bounded in-process test doubles;
ledger writes themselves use the real CLI, transactions, dump generation and consistency check.
No Git command is executed by this fixture.

During the contained relay turn the Python heredoc was extracted to `.relay-scratch/gh421/test.py`
and run with `TMPDIR` pinned to `.relay-scratch/gh421`. Logs and mutant source copies stayed
there, as required by the turn's containment contract. The extraction does not change the tests.
Outside a relay, run the named shell test in a disposable full clone per AGENTS.md.

## Witnessed reds

| Control | Observed result |
| --- | --- |
| Original reconciler, before implementation | Six tests ran; eight failures including subtests. Completion marker remained `🆕`; no planned transitions; missing manifest/repoint calls; swallowed CLI error; no-op still invoked downstream tools. |
| Remove `"--status-marker", marker` from the new CLI argv | Lifecycle test failed: `AssertionError: '🆕' != '✅'`. |
| Remove the early `snapshot_ledger_artifacts(repo_root, journal=journal)` from `ledger_write` | Rollback test failed at manifest ship, roadmap repoint and roadmap update boundaries. DB/dump generations differed after rollback. |
| Remove `queue: max` from a scratch workflow copy | Workflow contract failed because the required queue field was absent. |

Mutants were separate scratch copies, selected through `GH421_WAVE` or `GH421_WORKFLOW`.
They were never installed over the candidate files. One initial targeted-control invocation
put the test selector after the root argument and failed fixture loading; it was corrected
before the witnessed mutation results above. That setup failure is not counted as a red control.

## Candidate checks

Final focused run: **13 tests passed**. Both workflow files parsed as YAML; the Python module
parsed successfully. Covered behavior:

- Manifest shipping records the full merge SHA in the real append-only event trail; missing
  merge evidence fails and restores the fixture.
- Doc move, roadmap repoint, Completed section and explicit `✅` marker all agree.
- Second apply leaves the entire fixture artifact set byte-identical and invokes no downstream
  commands. This is stronger than freezing the clock for the second apply: timestamp-producing
  writers and generators are never invoked on the no-op path.
- OPEN issues remain active; a no-reference PR succeeds without requiring a receipt.
- No manifest membership is a successful skip; legacy markdown still receives its transition.
- Dry-run emits the same stable `TRANSITION` records as apply and changes no fixture artifact.
- Failure after doc move, each ledger CLI boundary, downstream sync/check, dashboard generation,
  plan generation and final doc gate restores all non-Git fixture files byte-for-byte.
- Three merged-close events are replayed serially through the reconciler; all three manifest
  items ship and all three roadmap rows complete. Catch-up finds missing work and then none.
- Live catch-up API shape is stubbed with paginated timeline output; foreign-repo references
  and non-closing PR mentions cannot select a PR for lifecycle completion.
- The actual workflow publishing Python is executed with Git stubbed. The exact staging argv
  includes deleted active docs, completed docs, DB/dump, dashboard and dated plan doc. Unexpected
  paths are refused, an empty diff exits cleanly, and a rejected push propagates failure.

## Hosted contract and remaining boundary

The workflow has only `pull_request: closed`, manual dispatch and scheduled catch-up triggers.
It checks out local `development` with full history, requires merged + development for close
events, and invokes `--gate`. Write permission is confined to the reconciliation job; `ci.yml`
remains workflow-wide `contents: read`. The queue uses `cancel-in-progress: false` and
`queue: max`, as specified in [GitHub's concurrency documentation](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency).
The local serial replay is not a claim that hosted queue delivery was witnessed.

Read-only GitHub API checks during implementation returned `protected: false` for
`HiQS-Labs/XYZ-forge`'s `development` branch and `[]` for active branch rules. The job checks
branch protection before mutating. No Actions-token push was attempted. Publication uses one
normal fast-forward push; rejection fails the job. A later catch-up recomputes from fresh
committed state, without rebasing a generated SQLite database or force-pushing. Scheduled
recovery becomes available when the workflow is present on the default branch; restricted
fork-event tokens can require that recovery path. Hosted event delivery, actual token push
permission and scheduling still need deployment verification.

**Known gate blocker:** `validate.sh` has an explicit TESTS registry and
`test/gh306-registry-bidirectional.sh` rejects unregistered top-level shell tests.
The new test is wired into the existing CI macOS and vendored-smoke jobs, but also needs
`"gh421-auto-wave-reconcile.sh"` added to the `validate.sh` TESTS array. `validate.sh` is
outside this relay turn's explicit edit allowlist, so it was not changed. The phase must not
be called gate-ready until the orchestrator authorizes and lands that registration.
