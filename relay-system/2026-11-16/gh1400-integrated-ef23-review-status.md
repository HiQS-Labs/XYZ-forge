# GH-1400 integrated candidate verification and review status

Reviewed candidate: `ef23e77b24e51add4be9476191257bcbc7d7c432`.
Integration parent: `dc3035c18707b8205e65a87f5740d478d1492d61`.
Published comparison: `0d1dc0fe8395b4f0fc58280fc32b86d4957d47d9`.
Development comparison: `f346d8908a42cd6e7e92f80657f9e7a21208e0ae`.

VERDICT: PARKED
Basis: focused verification is available, but current-candidate Claude relay approval and the qualifying final gate remain outstanding. This is the verification agent's bounded source assessment, not an independent Claude review or a relay attestation.
swept file: no
gate run: no — full gate explicitly reserved for the parent after final approval.

## Independent review routing

Independent review did not run. The installed relay-xyz skill was read and its bundled locator was run with `--check`; it resolved this task clone successfully. The shipped supported route is `CLAUDE_AUTH_MODE=subscription`, `claude-turn.sh`, and `relay-drive.sh --reviewer <reviewer-id> --review-once` (round cap at most 3). Subscription mode refuses API fallback. No auth or model call was made.

The session's higher-priority T3 orchestration instruction requires `delegate_task` for another provider's model. `orchestrator_capabilities` exposes Claude via `claudeAgent`, but the `delegate_task` interface has no shipped relay-driver/turn-adapter hook, no relay reviewer flag, and no attestation transport. Direct native Claude CLI dispatch from this Codex session would bypass that required route. A generic T3 review would not satisfy the requested shipped-harness attestation, so it was not substituted. Driver exit: not run. Validator exit: not run. Attestation: absent. Review rounds consumed: 0. Earlier Agy and Claude attempts were not modified or restarted.

## Bounded source assessment

No new integration regression was identified in the inspected Jog execution/recovery paths. This is not an exhaustive repository or whole-file sweep.

- `utils/py/jog_run.py:2495-2525`: task-local continuation requires the newly appended projected-failed execution, matching issue/execution identity and target, escalated/pre-advance-failed/exit 5, red gate with a nonzero integer exit excluding resource-guard 108, and no preserved approval. `jog_run_main:2919-2931` applies it only to supervised failed execution. Other failures retain the stop path.
- `jog_run_main:2809-2854`: task/deadline checks and target alignment precede the next dispatch. `JogSupervisorLock:1547-1564` refuses unknown or live/stopped ownership on the supervised path. `_jog_align_target:2543-2577` holds tracked dirt, detached HEAD and dependent worktrees and retains ahead development on a named branch.
- `_jog_supervise_recover:2582-2632` takes the target lock, checks lease ownership and latest execution/retry identity, target and approved outcome before calling `jog_resume`. `jog_resume:793-829` will not fall back from an invalid latest gate retry. `publish_jog_receipt:1148-1209` validates a green gate at the receipt SHA, its existing lane branch, original receipt bytes and candidate tail before publication. These are source checks; the fresh restart controls supply narrower observed evidence.
- Both Jog runtime blobs are identical to published `0d1dc0fe`: jog_run `70c085faa955aa200b67a9346c1aecb1f7ba6396`; releases_app `a8908d6c9f5d88edb2d14989ba56f15664167945`. The upstream integration does change `swarm_preflight.py`; inspected consumer seams retain `--gh-issue`/`--out`, readiness exit handling (`report_candidate:1896-1968`), and structured `marathon-invocation.json` publication (`write_packet:2008-2014`). No full preflight refactor audit is claimed.
- `ef23e77b2` adds only the plan's current outer-loop alignment. Its requirement for combined-head qualification is appropriate. Historical plan/review outcomes are not current-head approval. The SQL diff against development adds merge-rebuild bookkeeping with an unchanged before/after semantic digest; no runtime schema change is introduced by the task delta.

Known limits remain explicit: a shared environment fault producing the same pre-advance-failed receipt cannot be distinguished from a task-local red gate; later tasks can each consume one bounded attempt. Mid-wake checkpoint contradiction is detected by finish, not between tasks. Synthetic controls do not prove production provider behavior, arbitrary process-tree containment, power-loss recovery, PID reuse, external exactly-once effects, or unattended delivery.

## Evidence and clone safety

Fresh evidence is under `TESTS-RESULTS/2026-11-16+GH-1400/integration-ef23-review/`, including command provenance and identity brackets.

The task clone began clean at the reviewed candidate and source was not edited. The sibling `-gate` was left untouched: it contains untracked GH-1506 and prior pinned-Agy review files. The sibling `-verify` was a clean full clone at `7f946cd1d79fbd405b6c67ead1c638fd2fed709d`, without stashes, dependent worktrees, .tick claims/locks or detected open files. Its branch history is retained and is ancestral to the candidate. It fetched the candidate only from the local task clone and switched to detached candidate HEAD; no reset, ref deletion, new task checkout or cleanup occurred. Tests create their own synthetic fixture repositories under their established fixture boundaries.

Graph evidence is Tier Verify for the PRIMARY project, generation `2026-11-16T19:03:06Z`, not candidate proof. Coverage reported no recorded gaps for the main runtime/plan/skill paths, missing followup.py, and partial test coverage at lines 725-726. Exact candidate source was read, including those test lines. Negative/exhaustive graph claims are not made.

## Parent action

Obtain a supported Claude subscription relay review with valid VERDICT/Basis and actual driver attestation, preserve all attempts, then run the qualifying full gate on the final approved commit in a verified disposable full clone. Parent owns evidence commit/publication and landing; this report authorizes neither and establishes no promotion/unattended milestone.

## Final observed verification

Fresh focused controls: exit 0, 23/23 complete. Existing Jog–Marathon suite: exit 0, 227 pass, 0 fail. Identity unchanged after both. No new blocking code finding in the bounded inspected scope. Evidence remains uncommitted for the parent; task HEAD is still the reviewed candidate. Independent approval and final qualifying gate remain outstanding.
