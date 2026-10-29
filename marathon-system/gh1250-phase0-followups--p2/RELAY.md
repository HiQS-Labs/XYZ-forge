# Marathon Phase p2
STATUS: Open
NEXT: agy (Builder)

<!-- marathon-drive: task=MARATHON-P2-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

---
gh_issue: 1235
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1235
title: "merge-cleanup: a Jog-hook jog land refusal still makes the reconcile writes durable"
status: Active
created: 2026-10-27
updated: 2026-10-29
owner: noelsaw1
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 1
goal: "A Jog-hook refusal after a good local reconcile leaves the shared primary clean and level with origin, reports the refusal, and exits non-zero with the Jog row still parked."
non_goals:
  - Changing jog land's verification, the reconcile steps, or which PRs map to Jog rows.
  - Treating a reconcile, releases check or pdda failure as anything but a stop.
related:
  - "Marathon umbrella #1250 (lane L2)"
  - "GH-1175 Phase 0: TESTS-RESULTS/2026-10-25+GH-1175-phase0/step5-*; manual commit 5265cfad"
---

# GH-1235: a Jog-hook `jog land` refusal still makes the reconcile writes durable

## Status

| What was just completed | What's next |
|---|---|
| Promoted for marathon #1250 (lane L2) with plan, acceptance and contract | Codex plan QA, then build |

## Observed (GH-1175 Phase 0, PR #1225, 2026-10-27)

After the merge and a passing local `wave_reconcile --pr 1225`, the Jog hook's `jog land` refused (GH-1208), and merge-cleanup stopped (exit 2) **before** its post-merge commit/push. The primary was left with:
- modified `releases.db` and `releases.sql`;
- a modified `LEADERBOARD.md`;
- the doc move to 3-COMPLETED;
- an untracked generated MARATHON-PLAN file.

A concurrent session (#1217) could not land until these were committed by hand (`5265cfad`). GH-1208 (#1213, merged) removes that trigger, but any other `jog land` refusal reproduces the class.

## Current state (93f41cb8)

`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`:
- `run_post_merge_reconcile` (`:884-951`) runs the local reconcile, `releases check` and pdda, then ends with `return ok and run_jog_post_merge_land(pr_num, repo_path)`.
- `run_jog_post_merge_land` (`:797-881`) returns False when `jog land` refuses (`:877-879`).
- Both callers stop on False before `commit_and_push_phase5_writes` (`:954`): the Phase 5 loop (`:1622-1633`) and `--reconcile-pr` (`:1935-1943`).

Suites mock `run_post_merge_reconcile` as a bool (`test/gh534_phase_a_tests.py:584`, `gh534_phase_b_tests.py:560,574`, `gh436-merge-cleanup.py:360,457`), and `test/gh549-work-events.sh:627-640` pins the call order. So the signature and the callers stay as they are.

## Plan (one phase)
In `run_post_merge_reconcile` only:
1. If `ok` is False (reconcile, check or pdda failed), return False exactly as today, with nothing committed. The early returns at `:900-930` (unknown head, hosted timeout, fetch or fast-forward failure) are untouched.
2. Otherwise run the Jog hook. On True, return True as today.
3. On a False hook result, call the existing `commit_and_push_phase5_writes(pr_num, repo_path, integration_branch)`. That reuses the one durability writer with its clean/level verification.
4. Keep the hook's own specific diagnostic. It already logs the queue, PR, capability or `jog land` error, and its loop can land one row before a later one refuses. Then add one line: `Reconcile writes for PR #<pr> were made durable; Jog completion failed (see the error above) — Jog rows are left exactly as they are; rerun releases jog land after fixing the cause.` If the durable push itself fails, its own error stands instead.
5. Return False. Both callers (`:1622`, `:1935`) then exit 2, skip their own second commit, and stop before the next PR.

The dry-run path is unchanged. Write-set: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` and the evidence bundle `TESTS-RESULTS/2026-10-29+GH-1235/smoke.md` and `provenance.jsonl`. The Status row is updated by the orchestrator. Full route (`utils/ci-route.sh` treats merge-cleanup as a full-gate surface).

## Acceptance

- [ ] When the Jog hook's `jog land` refuses after a successful local reconcile, merge-cleanup still commits and pushes the reconcile writes, leaving the primary clean and level with origin.
- [ ] It then reports the Jog refusal and exits non-zero, and the Jog row stays parked.
- [ ] A failing reconcile, `releases check` or pdda step still stops before the commit, as today.
- [ ] A manual smoke receipt under `TESTS-RESULTS/` shows the fix and a base red control; no new tests (GH-831).

## Verification
- **Existing suites:** gh436, gh534 (phase a/b), gh549 and gh280, in a disposable full clone.
- **Manual smoke** (`TESTS-RESULTS/2026-10-29+GH-1235/`), in a disposable fixture repo with a bare origin. Stub `run_local_wave_reconcile` to write a file and `run_jog_post_merge_land` to return False:
  - **Fix:** the file is committed and pushed; the primary is clean and level with origin; `run_post_merge_reconcile` returns False; the `--reconcile-pr` caller exits 2.
  - **Base red control:** the file is left uncommitted.
  - **Adjacent:** a failing `releases check` stub and a failing pdda stub each return False with nothing committed.

Rollback: revert one commit.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh --auto development",
  "fix_probes": [
    {
      "type": "grep_absent",
      "path": "skills/2-daily/merge-cleanup/scripts/merge_cleanup.py",
      "pattern": "were made durable; Jog completion failed"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-29+GH-1235/smoke.md"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-10-29+GH-1235/provenance.jsonl"
    }
  ],
  "artifacts": [
    "skills/2-daily/merge-cleanup/scripts/merge_cleanup.py",
    "TESTS-RESULTS/2026-10-29+GH-1235/smoke.md",
    "TESTS-RESULTS/2026-10-29+GH-1235/provenance.jsonl"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-10-29+GH-1235/smoke.md",
    "TESTS-RESULTS/2026-10-29+GH-1235/provenance.jsonl"
  ],
  "remediation": {
    "source": "issue#1235",
    "criteria": "A Jog-hook refusal after a good reconcile commits/pushes the writes via commit_and_push_phase5_writes, then reports and returns False."
  },
  "lanes": {
    "agy_safe": [
      "skills/2-daily/merge-cleanup/scripts/merge_cleanup.py",
      "TESTS-RESULTS/2026-10-29+GH-1235/smoke.md",
      "TESTS-RESULTS/2026-10-29+GH-1235/provenance.jsonl"
    ],
    "orchestrator_only": []
  }
}
```


---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): skills/2-daily/merge-cleanup/scripts/merge_cleanup.py, TESTS-RESULTS/2026-10-29+GH-1235/smoke.md, TESTS-RESULTS/2026-10-29+GH-1235/provenance.jsonl
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick
   - /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick claim MARATHON-P2-TURN --agent agy --paths "marathon-system/gh1250-phase0-followups--p2/RELAY.md,skills/2-daily/merge-cleanup/scripts/merge_cleanup.py, TESTS-RESULTS/2026-10-29+GH-1235/smoke.md, TESTS-RESULTS/2026-10-29+GH-1235/provenance.jsonl"
   - /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick ping MARATHON-P2-TURN --agent agy
   - /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick release MARATHON-P2-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh1250-phase0-followups--p2/RELAY.md and skills/2-daily/merge-cleanup/scripts/merge_cleanup.py, TESTS-RESULTS/2026-10-29+GH-1235/smoke.md, TESTS-RESULTS/2026-10-29+GH-1235/provenance.jsonl. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/2-daily/merge-cleanup/scripts/merge_cleanup.py, TESTS-RESULTS/2026-10-29+GH-1235/smoke.md, TESTS-RESULTS/2026-10-29+GH-1235/provenance.jsonl. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick release MARATHON-P2-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick done MARATHON-P2-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/marathon-gh-1250-phase0-followups/bin/tick
   Edit ONLY marathon-system/gh1250-phase0-followups--p2/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
   may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to agy —
   agy, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
