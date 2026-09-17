# Marathon Phase p5
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-P5-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

---
title: "L5 brief — #237 consult agy lane repro after the oracle fix"
status: "Brief (input to the GH-648 headless turn-timeout marathon — not a tracked plan)"
created: 2026-09-16
updated: 2026-09-16
owner: Noel Saw
goal: >
  Re-run the consult agy scenario: completes, or fails with a specific truthful attribution — never a silent idle-kill.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/648
---

# L5 — #237: consult agy lane repro after the oracle fix

## Status

| What was just completed | What's next |
|---|---|
| Brief authored at marathon plan time (2026-09-16) | Lane fires when the marathon chain reaches this phase |

Umbrella: #648 · Issue: #237 · Wave 1 · depends_on L4

## Goal
Re-run #237's scenario shape against the post-L1/L3 consult: an agy advisor given a substantial prompt inside consult's throwaway worktree. Expected after the umbrella's foundation lanes: the lane **completes**, or fails with a **specific, truthful attribution** — `idle-unknown`/in-flight, or the actual startup blocker named (what fd/prompt it waits on) — never a silent idle-kill labeled "no progress".

#237's operator note is the spec for "truthful": 0 CPU + no transcript growth is NORMAL for an LLM CLI awaiting a first token from a slow/queued backend; the old label conflated that with locally stuck.

If the repro exposes a real startup blocker (e.g. an interactive prompt the worktree path raises that `-p` + skip-permissions doesn't suppress), surface it in consult's failure output — that surfacing is the deliverable, not a workaround.

## Rules
Write-set: `utils/py/consult.py` (failure-attribution surfacing only — cap policy landed in L3). The SUITE must stub the advisor (no real agy tokens in `test/`); run the real-advisor probe once by hand and record the receipt in the PR description instead. Register the suite in `validate.sh` TESTS. `bash validate.sh` green.

## Acceptance / Guard
`test/gh648-l5-gh237-repro.sh`: a stubbed slow-backend advisor (0 CPU, no output growth, open socket) is NOT idle-killed with the old label; either completes or fails with the truthful attribution string. Hand-run receipt of the real agy repro attached to the PR.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/consult.py, test/gh648-l5-gh237-repro.sh, validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick claim MARATHON-P5-TURN --agent codex --paths "marathon-system/gh648-headless-turn-timeout--p5/RELAY.md,utils/py/consult.py, test/gh648-l5-gh237-repro.sh, validate.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick ping MARATHON-P5-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P5-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh648-headless-turn-timeout--p5/RELAY.md and utils/py/consult.py, test/gh648-l5-gh237-repro.sh, validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/consult.py, test/gh648-l5-gh237-repro.sh, validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick release MARATHON-P5-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick done MARATHON-P5-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh237-idle-hang/bin/tick
   Edit ONLY marathon-system/gh648-headless-turn-timeout--p5/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

- Added `test/gh648-l5-gh237-repro.sh` and registered it in `validate.sh` TESTS. `utils/py/consult.py` is unchanged: L1/L3 already provide the required honest idle labels and partial-failure output. No cap-policy changes.
- The hermetic suite runs consult's actual main/launch/wait/classification/result path with a substantial agy prompt and a real silent child holding a socketpair. Repository operations and auth preflight are stubbed; CPU/time/network observations are deterministic inputs to the real shared classifier. This proves consult's attribution plumbing, not OS socket discovery or live backend connectivity. No Git commands, real advisor tokens, network listeners, or writes outside `.relay-scratch/` occur in the suite.
- Focused verification: `bash test/gh648-l5-gh237-repro.sh` exited 0. Cases: slow completion; idle in-flight; idle unknown; deliberate old `timeout-idle` / `no progress` mutation rejected by the same transcript/stdout attribution assertion. Each failure asserts exit 5, nonempty output, and a reaped child. Log: `.relay-scratch/gh648-l5-test.log` (ephemeral, not durable release evidence).
- One manual real-agy probe used consult's actual launcher and wait loop from this existing relay worktree, with a substantial source-review prompt, idle=5s and wall=20s. Observed exit 1 after 0.416s, zero transcript bytes, no idle kill. This provides no evidence of a backend hang or specific startup blocker; the cause remains unknown. Receipt: `.relay-scratch/gh648-l5-live-receipt.txt`; raw empty transcript: `.relay-scratch/gh648-l5-live-agy.md` (ephemeral).
- **Outstanding acceptance:** the exact real-advisor repro through consult's worktree creation and auth preflight, plus a durable PR receipt, remains required. Running that path invokes Git, prohibited in this turn; the partial live probe is not a substitute and must not be cited as full scenario success. The outer operator/harness must run it under appropriate authorization and attach the receipt before phase closure. Full gate intentionally not run; it belongs to the harness.
- Graph tools were unavailable; source fallback covered consult's main, launch, idle-bound, partial surfacing, and shared diagnostic classifier. Reversibility: Easy — a test and one registration line. Existing kill policy is preserved.

Handing off to agy for review, with the live repro limitation explicit.
