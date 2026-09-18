# Marathon Phase p4
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-P4-TURN-R3 builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

---
title: "L4 brief — #285 revalidate whether the cap kills the child at HEAD"
status: "Brief (input to the GH-648 headless turn-timeout marathon — not a tracked plan)"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  Fixture-prove agy-turn's cap behavior at HEAD; close #285 as already-fixed or fix what still reproduces.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/648
---

# L4 — #285 revalidate: does the cap kill the child at HEAD?

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-16) | Lane fires when the marathon chain reaches this phase |

Umbrella: #648 · Issue: #285 · Wave 1 · depends_on L3

## Goal
#285 claimed `agy-turn` returns exit 7 at the cap but never kills the child (fixture: `RELAY_TURN_TIMEOUT_S=1` vs 5s stub; codex-turn killed, agy didn't). At HEAD, `utils/py/agy-turn.py` ~`:500` calls `_kill_turn_group(proc)` at the wall cap, so the issue may already be fixed in the Python twin.

First build `test/gh648-l4-285-revalidate.sh` (same fixture shape: short cap vs sleeping stub, both agy and codex twins). Then:
- If agy's cap fires fast (child group dead well before the stub's natural end): close #285 citing the commit that fixed it — put the sha in the suite receipt and the issue close. NO production change.
- If it still reproduces: fix in `utils/py/agy-turn.py` (Python twin only) and keep the suite red→green.

## Rules
`utils/py/agy-turn.py` is in your write-set ONLY for the still-reproduces branch. Register the suite in `validate.sh` TESTS. `bash validate.sh` green.

## Acceptance / Guard
The suite asserts the cap fires fast for BOTH twins (agy, codex) and records which case happened (already-fixed close vs fix landed).


## Debug mantra (auto-triggered — 1 prior attempt(s) on this phase did not reach Approved)

Before trying again, read `relay-automation/DEBUG-MANTRA.md` (relative to the harness root) and follow its four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.
Last recorded reason (`marathon-system/gh648-headless-turn-timeout--p4/ESCALATION.md`): `pre-advance-failed`. Read it before re-guessing.

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): utils/py/agy-turn.py, test/gh648-l4-285-revalidate.sh, validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick claim MARATHON-P4-TURN-R3 --agent codex --paths "marathon-system/gh648-headless-turn-timeout--p4/RELAY.md,utils/py/agy-turn.py, test/gh648-l4-285-revalidate.sh, validate.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick ping MARATHON-P4-TURN-R3 --agent codex
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P4-TURN-R3 --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh648-headless-turn-timeout--p4/RELAY.md and utils/py/agy-turn.py, test/gh648-l4-285-revalidate.sh, validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/agy-turn.py, test/gh648-l4-285-revalidate.sh, validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P4-TURN-R3 --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick done MARATHON-P4-TURN-R3 --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick
   Edit ONLY marathon-system/gh648-headless-turn-timeout--p4/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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


### Round 3 · Builder · codex

**Result:** The existing focused fixture passes at the supplied source; #285's
five-second sleeper / one-second cap failure did not reproduce. No production
change is justified by this result. Only this relay file was edited this turn
(the required NEXT header transition plus this appended block).

- Read the prior escalation: `pre-advance-failed`, `gate: red`, with no failing
  command output or turn log. That is insufficient to attribute the gate failure
  to L4, and I did not rerun the prohibited full gate or guess a fix.
- Ran `bash test/gh648-l4-285-revalidate.sh`: exit 0. Codex returned 7 in
  1.004s; agy pipe returned 7 in 2.008s; agy PTY returned 7 in 2.006s.
  Each child was dead before cleanup, its transcript was nonempty, and its
  natural-completion marker was absent. The agy process-group absence checks
  passed. The fixture only launches a single sleeper, so this does not establish
  containment of independently signal-resistant descendants.
- The built-in no-kill mutation returned 7 in 2.003s with its child still alive;
  the containment assertion rejected it before cleanup. This is the witnessed
  negative control, not an inference from a green run.
- Receipt: `.relay-scratch/gh648-l4-receipt.json` (ephemeral, not committed
  provenance). Tested agy source SHA-256:
  `7ba49c671f963cc420fade4ed98bec78f2ed51b076d02488a33b253205878c38`;
  codex source SHA-256:
  `f5c7dfc0f4332a0adc9917cc26cc3300c4168761b0b1aade0050b4bdc2cabb84`.
- Inspected the production wall-cap path: it calls `_kill_turn_group(proc)`;
  the suite is already registered in `validate.sh` TESTS. Both files and the
  existing suite were retained unchanged.
- **Outstanding acceptance:** the historical fixing commit is unresolved in the
  receipt. Git execution is explicitly prohibited in this turn; source comments
  and the searched project/changelog references do not establish a fixing SHA.
  I did not invent one or close #285 without it. The outer orchestrator must
  establish that provenance and close the issue under its authorized workflow.
  Full-gate readiness is also unverified here; the harness owns that run.

Agy: review the existing artifacts and these bounded results. Do not interpret
this focused pass as resolution of the prior unspecified gate failure or as
completion of the historical-provenance/issue-closure acceptance.


### Round 3 · Reviewer · agy

swept file: yes

**Review Findings:**
I have swept `utils/py/agy-turn.py` in its entirety, as well as the test script `test/gh648-l4-285-revalidate.sh` and `validate.sh`.
There IS a pre-existing defect in the code you are touching. The implementation of `_kill_turn_group(proc)` in `utils/py/agy-turn.py` is flawed. It currently does this:

```python
    for sig, wait_s in ((signal.SIGTERM, 5), (signal.SIGKILL, 2)):
        try:
            os.killpg(os.getpgid(proc.pid), sig)
        except (ProcessLookupError, PermissionError, OSError):
            return
        try:
            proc.wait(timeout=wait_s)
            return
        except subprocess.TimeoutExpired:
            continue
```

Because it calls `proc.wait(timeout=wait_s)`, it only waits for the process group *leader* (`proc`). If the leader terminates on `SIGTERM` but leaves behind child processes in the same process group that ignore or take longer to handle `SIGTERM`, `proc.wait()` returns immediately. The function then executes `return`, entirely skipping the `SIGKILL` step for the rest of the process group!

This perfectly matches your observation that "The fixture only launches a single sleeper, so this does not establish containment of independently signal-resistant descendants." #285 asks if the cap kills the child at HEAD. The answer is **NO**: it kills the leader but orphans signal-resistant descendants.

**Action Required:**
You must fix `_kill_turn_group` in `utils/py/agy-turn.py` so that it doesn't skip `SIGKILL` for surviving descendants just because the leader died. Also, please update `test/gh648-l4-285-revalidate.sh` to include a test case that spawns a signal-resistant descendant, demonstrating that the fix successfully prevents it from outliving the timeout.

**Verdict:** Changes requested

### Round 4 · Builder · codex

**Result:** Reproduced and fixed the reviewer's resistant-descendant leak.
Files changed: `utils/py/agy-turn.py`, `test/gh648-l4-285-revalidate.sh`,
and this relay (required NEXT transition plus appended block).
`validate.sh` already registers the focused suite and was left unchanged.

- Reproduction: added a forked descendant that installs SIGTERM and SIGHUP
  ignore handlers, publishes readiness, and sleeps five seconds. Its leader
  waits for readiness before sleeping. The unchanged production helper passed
  the three original cases, then failed with
  `('process group remains', 'agy-pty0-descendant')`.
  Captured output: `.relay-scratch/l4-r4-red.log`.
- Fail path: both agy launch modes use `start_new_session=True`; wall and idle
  caps call the same helper. Waiting for the leader returned early and skipped
  SIGKILL. Looking up its group after reaping would also lose the group ID.
- Fix: retain `proc.pid` as the known session group ID and continue to SIGKILL
  after the leader wait. Preserve the existing five-second leader grace and
  two-second final wait. A promptly exiting leader no longer exempts surviving
  descendants from escalation.
- Costly containment change: affects agy wall/idle termination only; the bet is
  that these two session-creating launch sites own the target group. Source
  confirms that assumption. Rollback is the helper change, but restores the
  demonstrated leak. No event/token shape or Bash twin changed.
- Verification: `bash test/gh648-l4-285-revalidate.sh` exited 0.
  Codex single child: 1.005s; agy pipe/PTY single child: 2.008s/2.010s;
  resistant descendant pipe/PTY: 2.008s/2.013s. All positive cases returned 7
  before natural completion. Both descendant groups were absent before test
  cleanup (bounded one-second observation allowance for asynchronous reaping).
  The no-kill mutation returned 7 with its child alive and was rejected.
- Logs and JSON are ephemeral under `.relay-scratch/`, not committed
  provenance. The fixture now records the fix-required branch and leaves the
  fixing commit pending the harness commit, instead of claiming already-fixed.
  Tested agy SHA-256:
  `6aac5b234e7d858fcde62560244ea230ef0462932d9de4b7aa33085515255127`.
- The graph project list contains no index for this worktree; exact source
  fallback was used. No git commands or full gates were run. The earlier
  unspecified pre-advance failure remains unattributed; the harness owns the
  final gate, commit attribution, and any subsequent issue closure.
- Scope of proof: same-process-group resistant descendants on the wall cap,
  in both pipe and PTY modes. Descendants that create their own sessions and
  a separate idle-cap integration run are not covered by this fixture.

Agy: review the production fix and expanded regression; full gate readiness
remains pending the harness.
