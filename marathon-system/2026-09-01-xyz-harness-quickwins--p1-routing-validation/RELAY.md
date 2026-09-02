# Marathon Phase p1-routing-validation
STATUS: Open
NEXT: codex (Builder)

<!-- marathon-drive: task=MARATHON-P1-ROUTING-VALIDATION-TURN builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

---
title: "p1 brief — same-lane agent routing (#368) + reviewer-validation alignment (#373)"
status: "Brief (input to the 2026-09-01 xyz-harness-quickwins marathon — not a tracked plan)"
created: 2026-09-01
updated: 2026-09-01 (rescoped after XYZ-forge #367 and #375)
owner: Noel Saw
goal: >
  Make a builder and a reviewer on the SAME model lane routable (agy + agy-qa), and make
  the accepted reviewer set agree with what can actually dispatch.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/368
  - https://github.com/HiQS-Labs/XYZ-forge/issues/373
---

# p1 — routing + validation

Read the two capture docs first: `PROJECT/2-WORKING/GH-368-SAME-LANE-BUILDER-REVIEWER-ROUTING.md`
and `PROJECT/2-WORKING/GH-373-PHANTOM-GEMINI-REVIEWER-LANE.md`.

## #368 — same-lane routing

- `utils/py/marathon_drive.py` `route_agent`: one env slot per lane (`AGY_AGENT`) is
  overwritten when builder and reviewer share the agy prefix.
- `relay-automation/marathon-agent.sh`: dispatch matches one exact id per slot.
- `utils/py/agy-turn.py` (+ frozen `agy-turn.sh` twin): no-ops unless
  `RELAY_AGENT == AGY_AGENT` verbatim.

Fix so builder `agy` + reviewer `agy-qa` both dispatch: e.g. the dispatcher routes by
lane membership, and the shim trusts the dispatcher for actor identity while KEEPING the
tick ownership guard. **FROZEN TWINS**: behavior changes in the `.py` lanes only
(`agy-turn.sh`, `marathon-drive.sh` are frozen); `marathon-agent.sh` is not frozen and
may be edited directly.

**Repro evidence** (2026-09-01 LTVera run): `marathon-agent: unknown agent 'agy'` after
route_agent overwrote the slot; then `agy-turn: actor agy is not the agy agent (agy-qa)
— deferring (window-driven)` once dispatch was worked around.

Test: `test/gh368-same-lane-routing.sh` — assert a same-lane builder+reviewer pair
routes through marathon-agent.sh and the shim does not defer (fixture/stub-based, in the
style of `test/gh520-default-reviewer-stub.sh`).

## #373 — phantom gemini lane (MOSTLY ALREADY FIXED — read this before touching anything)

**Two of the three surfaces were fixed on `development` by XYZ-forge PR #367 (GH-346 Phase 2),
after this brief was written.** Verified on `development @ b56e32d3`:

- `utils/py/marathon_drive.py` `route_agent` — no gemini branch. **Already correct.**
- `bin/marathon-yaml:99` — reviewer regex is `/^(codex|agy)/`. **Already correct.**
- `relay-automation/marathon-drive.sh` — **still wrong**: accepts `gemini*` at `:795`, advertises
  it at `:33`, `:593`, `:772`, `:794`.

So the remaining work is *only* the frozen Bash twin, and that is a GH-308 frozen-twin edit
requiring a `Frozen-twin-exception:` trailer. Decide explicitly: spend the exception, or close
#373 as "fixed everywhere it can dispatch" and let the twin retire with GH-308. **Do not edit
`marathon_drive.py` or `bin/marathon-yaml` for this issue** — they are already correct, and
changing them to satisfy a stale preflight probe is a change made to please a checkbox.

The GH-373 capture doc's contract has been corrected accordingly: it previously named the two
already-fixed files as artifacts and omitted the only file still carrying the defect.

## #368 also touches the GH-346 profile resolver — same change, or it breaks

`utils/py/profile_resolve.py` (XYZ-forge PR #375, merged after this brief was written) derives the
lane set by parsing `route_agent`'s source instead of keeping a copy — deliberately, because
GH-346 Phase 2 found that lane set in ten hand-maintained allowlists. Both routing fixes #368
proposes rewrite the shape it matches, after which the resolver yields no lanes and every profile
degrades to its floor: no crash, no blocked turn, just a feature that quietly stops working.

Update the derivation alongside `route_agent`. `test/gh346-profile-resolve.sh` already asserts the
derived lane set equals `route_agent`'s, so this fails in the gate rather than drifting. Do not
hardcode the lane list in the resolver — that makes it the eleventh allowlist.

## Constraints

- Leave a `GH-368` marker comment at the marathon-agent.sh change site and `GH-373` at
  the marathon_drive.py validation change — the capture-doc preflight probes key on them.
- Do not weaken the builder≠reviewer rule or the tick ownership guard.
- Gate: `bash validate.sh` (the repo default). In-turn, run only the two new tests plus
  any test file you edit — not the whole suite.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/marathon_drive.py,utils/py/agy-turn.py,relay-automation/marathon-agent.sh,relay-automation/marathon-drive.sh,utils/py/profile_resolve.py,test/gh346-profile-resolve.sh,test/gh368-same-lane-routing.sh,test/gh373-reviewer-validation.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick
   - /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick claim MARATHON-P1-ROUTING-VALIDATION-TURN --agent codex --paths "marathon-system/2026-09-01-xyz-harness-quickwins--p1-routing-validation/RELAY.md,utils/py/marathon_drive.py,utils/py/agy-turn.py,relay-automation/marathon-agent.sh,relay-automation/marathon-drive.sh,utils/py/profile_resolve.py,test/gh346-profile-resolve.sh,test/gh368-same-lane-routing.sh,test/gh373-reviewer-validation.sh"
   - /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick ping MARATHON-P1-ROUTING-VALIDATION-TURN --agent codex
   - /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick release MARATHON-P1-ROUTING-VALIDATION-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/2026-09-01-xyz-harness-quickwins--p1-routing-validation/RELAY.md and utils/py/marathon_drive.py,utils/py/agy-turn.py,relay-automation/marathon-agent.sh,relay-automation/marathon-drive.sh,utils/py/profile_resolve.py,test/gh346-profile-resolve.sh,test/gh368-same-lane-routing.sh,test/gh373-reviewer-validation.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/marathon_drive.py,utils/py/agy-turn.py,relay-automation/marathon-agent.sh,relay-automation/marathon-drive.sh,utils/py/profile_resolve.py,test/gh346-profile-resolve.sh,test/gh368-same-lane-routing.sh,test/gh373-reviewer-validation.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick release MARATHON-P1-ROUTING-VALIDATION-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick done MARATHON-P1-ROUTING-VALIDATION-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GitHub-Repos/XYZ-forge-marathon-2026-09-02/bin/tick
   Edit ONLY marathon-system/2026-09-01-xyz-harness-quickwins--p1-routing-validation/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
