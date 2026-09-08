---
Goal: Final QA of the GH-505 / GH-509 / GH-510 implementation — driver-attested approval
Date: 2026-09-08
NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3
---

# Context

Review the **committed implementation** of the design the operator chose after plan QA reached
its 3-round cap (`relay-system/2026-09-08/gh509-design-v2-plan-qa.md`, escalated; operator
chose option (b): implement on the producer-adjudicated revision with THIS review as the check).

Read in full:

- `PROJECT/2-WORKING/GH-505-RELAY-REVIEWER-INTEGRITY.md` — the adjudicated plan, with an
  **Implementation dispositions** table listing every place the code departs from it and why
- `test/baselines/GH-505-negative-control.md` — red controls as observed, and the same deviations
- `PROJECT/1-INBOX/GH-505-RELAY-REVIEWER-INTEGRITY.md`, `PROJECT/1-INBOX/GH-510-JOG-MERGE-FALSE-SUCCESS.md`

The implementation (all on this branch, base `a6441b9b`):

- `utils/py/relay_attest.py` — the one writer / resolver / validating reader of `relay-drive/attest@1`:
  `canonical()`, `write()`, `load(task, *, expected_reviewer, relay_file, target_repo, path=None)`,
  `candidate_ok(record, candidate_sha, target_repo)`
- `utils/py/relay_drive.py` — `--reviewer` / `--builder`; per-turn `RELAY_ROLE`, `RELAY_REVIEWED_HEAD`,
  `RELAY_ARTIFACT_SHA256`; `judge_terminal()` (forged-terminal revert + checked commit; empty-approval;
  review-body-rewritten; close-mismatch before publication; attest = trailer + checked commit + atomic
  record); `unattested-terminal` at all three terminal exits; the nonzero-shim path judges for revert only
- `relay-automation/relay-turn-lib.sh` — `rtl_is_reviewer_turn` first tier (`RELAY_ROLE` under
  `RELAY_DRIVER_LOCKED=1`); `rtl_worktree_begin` cuts at `RELAY_REVIEWED_HEAD` and verifies the seeded
  artifact digest; the approval instruction moved into the reviewer `role_note`
- `utils/py/marathon_drive.py` — `attested_terminal()` shared probe; `satisfied_lane_terminal()`, the
  exit-3 and exit-7 probes require it; `complete_phase_success()` binds the candidate before the approved
  event and again after the post-approve command; receipt gains `reviewed_candidate`, `reviewed_head`,
  `added_sha256`, `attest_path` (`MACHINE-CONTRACTS.md` Contract B updated; goldens re-recorded)
- `utils/py/jog_run.py` — override deleted; `run_single_phase_drive` requires a reviewer and dispatches
  via `marathon-agent.sh`; `_merge_reviewed_pr()` serves all three landing branches with
  `candidate_ok` + `--match-head-commit`; parks on refusal / failure / no PR (#510); simulate lands as
  a simulated completion
- `utils/py/gate_env.py` + the marathon literal — the three new exports classified SCRUB
- `test/gh505-relay-attest.sh` (50 cases, real `codex-turn.sh` with a stub binary, base-driver red
  controls); `test/lib/attest-stub.sh`; 30 shipped suites re-pointed at the attestation;
  `test/fixtures/contracts/result-at1-*.json`
- Migration: `skills/relay-xyz/SKILL.md` recipes, `relay-automation/README.md`, `relay-drive.sh` header

Gate: `validate.sh` 355/356 in a disposable clone at `2ca56630` (the one failure, `gh280` N1, was a
fixture without an attestation — fixed in the next commit); the full re-run at the reviewed HEAD is
recorded under `TESTS-RESULTS/2026-09-08+GH-505/` once it completes.

## Questions

Answer each with a verdict and cite `file:line` where you disagree.

1. **Is the trust boundary the code enforces the one the plan states?** The driver's exit depends
   only on `attested` (in-process memory). Find any path where a terminal exit 0 is reachable
   without `judge_terminal` having attested in this process.
2. **B1 (round 2 of plan QA): can a turn's permissions still be decided by bytes a builder can
   write?** `relay-turn-lib.sh` `rtl_is_reviewer_turn`, `rtl_worktree_begin`, and the `rtl.py` bridge.
3. **Is the reviewed revision really pinned?** `RELAY_REVIEWED_HEAD` → `git worktree add --detach … "$_cut"`.
   Non-isolated turns → `isolated:false` → `candidate_ok` refuses. Seeded artifact → digest verified
   at seed, record merge-ineligible. Any gap?
4. **Reader obligations (B3):** does `load()` check everything the plan required — task, file,
   repo, expected reviewer, status (record = file), range + digest, trailer by offset — and does
   every consumer pass a trusted expected reviewer and require the token `done`?
5. **Candidate binding (B2):** `candidate_ok` = ancestor + endpoint diff outside `relay-system/`,
   the relay file, and its directory (`:(top,literal,exclude)`). Marathon binds before publication
   and after post-approve; jog binds to the PR head and merges with `--match-head-commit`. Is the
   transcript-path allowance too wide (the relay file's *directory*)? Is the marathon-executor
   landing's `expected_candidate == receipt.reviewed_candidate` check sufficient?
6. **Each implementation disposition** in the plan's table: accept, or name the cheapest
   correction. In particular `--reviewer` warn-not-refuse and the uncited-claim downgrade port in
   `canonical()` (is the port byte-faithful to the awk in `relay-turn-lib.sh:1195-1230`?).
7. **Falsifiability:** are the red controls real? Cases A and C invoke the base driver from a
   `git archive a6441b9b` copy without the new flags. Is anything in the 50 cases passing for a
   reason unrelated to the fix? Is `test/lib/attest-stub.sh` an honest stand-in for the driver, or
   does it let a suite pass that should not?
8. **Scope:** any second subsystem or parallel writer? Anything changed that the issues do not
   require? Ratings #505 `85/85/50/55`, #509 `75/85/50/25`, #510 `70/70/50/90` — still grounded?

Reviewer writes ONLY to this relay file. Set `STATUS: Approved` only if the implementation is sound
as committed; otherwise list findings ranked, each with the cheapest correction.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
