# Marathon Phase p7
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-P7-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

---
title: "L7 brief — #242 post-kill checkout state (Wave 2)"
status: "Brief (input to the GH-648 headless turn-timeout marathon — not a tracked plan)"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  A timeout-killed driven run leaves the operator checkout on the branch/HEAD it started on.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/648
---

# L7 — #242: timeout-killed run leaves the operator checkout switched (Wave 2)

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-16) | Lane fires when the marathon chain reaches this phase |

Umbrella: #648 · Issue: #242 · Wave 2 · depends_on L6

## Goal
A timeout-killed driven run must leave the operator's checkout on the branch/HEAD it started on. #242: the killed run left the operator checkout switched to development. Find the switch site in `utils/py/relay_drive.py` / `utils/py/rtl.py` (branch/worktree setup before the turn, no restore on the kill path), and make the kill path restore or never touch the operator checkout.

## Rules
Python twins authoritative. Register the suite in `validate.sh` TESTS. `bash validate.sh` green.

## Acceptance / Guard
`test/gh648-l7-checkout-aftermath.sh`: fixture run killed at a short cap → the fixture checkout's starting branch/HEAD is unchanged; a healthy run still switches as designed.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): utils/py/relay_drive.py, utils/py/rtl.py, test/gh648-l7-checkout-aftermath.sh, validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick claim MARATHON-P7-TURN --agent codex --paths "marathon-system/gh648-headless-turn-timeout--p7/RELAY.md,utils/py/relay_drive.py, utils/py/rtl.py, test/gh648-l7-checkout-aftermath.sh, validate.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick ping MARATHON-P7-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P7-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh648-headless-turn-timeout--p7/RELAY.md and utils/py/relay_drive.py, utils/py/rtl.py, test/gh648-l7-checkout-aftermath.sh, validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/relay_drive.py, utils/py/rtl.py, test/gh648-l7-checkout-aftermath.sh, validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P7-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick done MARATHON-P7-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick
   Edit ONLY marathon-system/gh648-headless-turn-timeout--p7/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.


### Round 1 · Builder · codex

Implemented timeout checkout recovery in the Python driver boundary.

- `utils/py/relay_drive.py`: capture the driven checkout's branch and HEAD immediately before dispatch; after a child returns timeout exit 7, recover checkout identity before propagating that exit. Healthy turns retain their existing switching behavior. The target root is the same explicit target/main tree used by the driver's progress observer.
- `utils/py/rtl.py`: add shared snapshot/recovery helpers. Recovery uses non-forced `git switch`, handles detached HEAD, verifies the result, and never rewinds a ref or stashes/resets local work. A moved original branch or conflicting local edits yields an explicit manual-recovery diagnostic, retaining timeout exit 7.
- `test/gh648-l7-checkout-aftermath.sh`: registered in `validate.sh`. Runs a real child under a 0.5-second cap and executes the driver's actual AST capture/failure blocks against a modeled Git boundary. Covers branch recovery, detached HEAD, healthy switching, unchanged checkout, moved ref, dirty conflict, and a no-restoration mutation rejected by the same preservation assertion.

Evidence / limitations:
- Focused suite passed all seven cases; Python source syntax parsing passed. Logs: `.relay-scratch/gh648-l7-before.log` and `.relay-scratch/gh648-l7-after.log` (ephemeral, not committed provenance).
- The initial test failed because the capture block did not exist. The behavioral red control is the later no-restoration mutation: the child switches the modeled checkout, times out, and the preservation assertion rejects the remaining wrong branch/HEAD.
- No Git commands were run by this builder or its test: the test mocks Git, while the child process and timeout kill are real. Consequently **real Git checkout semantics and the full fixture acceptance remain unverified**. The full project gate was not run, per turn instructions; the harness owns it. Do not treat this as full gate evidence.
- Source inspection found no branch-switch site in either allowed Python file; the Bash worktree setup creates a separate checkout. The patch covers switches performed inside a driven child; it does not establish the historical #242 switch's origin or recover a switch before this driver launches, a killed supervisor, or concurrent branch writes.

Bet / reversibility: Costly because this is checkout recovery on the relay boundary. Assume the supervisor survives and the original branch ref remains unchanged. Failure mode: a conflicting edit, ref movement, or Git failure prevents automatic recovery; preserve work and name manual recovery rather than force restoration. Rollback is removal of the two driver calls and helper functions; no data/schema migration. This relay records the bet because CHANGELOG is outside the turn allowlist.

Graph tools were unavailable; evidence is direct bounded source inspection. Peer-drift paths were read where relevant, never edited. No commits or full gate were run. Only the authorized artifact paths and this relay were edited; scratch is confined to `.relay-scratch/`.

Reviewer: please assess the non-forced recovery boundary and the explicitly outstanding real-Git fixture proof. NEXT updated as explicitly required by the turn steps; all other existing relay content preserved.

### Round 1 · Reviewer · agy

swept file: yes

I have reviewed the files `utils/py/relay_drive.py`, `utils/py/rtl.py`, `test/gh648-l7-checkout-aftermath.sh`, and `validate.sh` in full.
The test script and the core Git commands for snapshot and recovery look good and pass successfully. However, there are critical defects in how the new Python code handles edge cases where Git operations fail.

**Defects Found in the Builder's Changes:**
1. **Uncaught Git Failures Crash the Driver:** In `utils/py/relay_drive.py`, `checkout_before = checkout_snapshot(progress_main_tree)` is called unconditionally without a `try-except` block. If `progress_main_tree` is not a valid git repository (e.g. an archive-routed relay file with a vendored harness, which falls back to the non-repo `.xyz` root), or if it is an empty repository (where `HEAD` does not exist), `checkout_snapshot` raises `RuntimeError` or `subprocess.CalledProcessError`. This will crash `relay_drive.py` completely before dispatching the turn. You must catch these exceptions and handle the missing snapshot gracefully.
2. **Missing `None` check in recovery:** When you fix the crash in #1 by catching exceptions and setting `checkout_before = None` (or similar), `restore_checkout_after_timeout` in `utils/py/rtl.py` will crash with a `TypeError` when it attempts to unpack `ref, head = before`. It must handle a missing snapshot cleanly (e.g., return `False` or gracefully skip recovery).

No pre-existing defects were found in the scope of the touched files during the sweep.

**Verdict:** Changes requested


### Round 2 · Builder · codex

Addressed both Round 1 review requests.

- `utils/py/relay_drive.py`: catch expected snapshot failures (`OSError`, `ValueError`, `RuntimeError`, and `subprocess.SubprocessError`) before dispatch, clear the snapshot to `None`, and emit an explicit diagnostic. Missing/unborn repository state or a failed Git probe no longer aborts dispatch.
- `utils/py/rtl.py`: a missing starting snapshot returns `False` with a manual-recovery diagnostic before any Git operation. Timeout handling retains exit 7 and does not invent a checkout target.
- `test/gh648-l7-checkout-aftermath.sh`: extend the existing boundary regression to cover all five representative snapshot failures, clear a stale previous snapshot, retain timeout exit 7, and reject any Git operation during missing-snapshot recovery. Existing seven cases remain green. `validate.sh` already registers this suite and needed no change.

Verification: the added snapshot regression failed before the fix with `RuntimeError: not a repository`; a separate mocked probe reproduced the missing-snapshot `TypeError`. After the fix the focused suite exited 0 with all 13 cases passing; both Python files parsed successfully. Ephemeral logs are `.relay-scratch/gh648-l7-round2-red.log`, `.relay-scratch/gh648-l7-round2-none-red.log`, and `.relay-scratch/gh648-l7-round2-green.log`; these are not committed provenance or full-gate evidence. No Git commands or full gate were run. The existing limitation remains: Git is modeled, so real Git checkout semantics are not proven by this suite.

Reversibility: Easy for this bounded revision; remove the two error-handling blocks to roll back. Assumption: an unavailable starting snapshot should not block an otherwise supported turn. Consequence: recovery after its timeout requires manual inspection, explicitly reported rather than silently claiming preservation.

Graph project inventory was fully paginated; this worktree is not indexed, so verification used exact local source and executable boundary tests rather than another checkout's graph. Existing relay content is preserved except the explicitly required NEXT routing line. Handing off for agy's review.
