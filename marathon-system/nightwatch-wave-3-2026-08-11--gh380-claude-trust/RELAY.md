# Marathon Phase gh380-claude-trust
STATUS: Open
NEXT: codex (Builder)

<!-- marathon-drive: task=MARATHON-GH380-CLAUDE-TRUST-TURN builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

---
title: "Phase brief: GH-380 gh380-claude-trust (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-08-11
updated: 2026-08-11
owner: noel
goal: >
  Phase-brief input consumed by the marathon driver for the gh380-claude-trust phase of
  MARATHON-2026-08-11-NIGHTWATCH-WAVE-3 — not itself an active-doc capture; the canonical capture doc
  is GH-380-CLAUDE-BUILDER-TRUST-SILENT-DEGRADE.md two levels up.
roadmap_exempt: true
---

# Brief — GH-380: surface the trust warning a claude builder currently swallows

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10 in the Nightwatch batch-2 doc fan-out. Issue had **no acceptance criteria**; five were authored in a separately labelled block. One of the issue's two evidence claims was found stale against source — see "What was corrected". Preflight 2026-08-11: **ready (exit 0)**, issue **OPEN**. | Fire as phase 2 of 3. |

**Parent capture doc:** `PROJECT/2-WORKING/GH-380-CLAUDE-BUILDER-TRUST-SILENT-DEGRADE.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/380

## Acceptance

**Read the acceptance criteria from the parent capture doc's authored acceptance block.** The issue
carries none. This brief's prose is context, not the contract.

## The defect

A claude builder pointed at a target repo that was never pre-trusted **silently degrades to default
permissions**. The CLI does emit a warning about it — and nothing surfaces that line anywhere an
operator will see. The turn proceeds, produces weaker work than intended, and reports success.

## What was corrected before you start — this is the important part

**The issue describes the DEAD half of a frozen twin pair.** Its evidence table says the warning
lands in `$TMPDIR/claude-turn-<pid>.json` and is "never copied into the phase directory."

- That is **true** of `relay-automation/claude-turn.sh:159` — the **FROZEN Bash** shim.
- It is **false** of the path that actually runs. `utils/py/claude-turn.py:72` calls
  `rtl_default_log()` (`utils/py/rtl.py:307-324`), which already writes a persistent in-repo
  `relay-system/logs/<date>/…` transcript, as of commit `7812710` — confirmed an ancestor of HEAD.

`XYZ_PYTHON` defaults to Python, so the Python shim is what runs.

**Therefore the issue's suggested fix #4 — "preserve the turn log" — is ALREADY SHIPPED and is out of
scope.** Do not re-implement it. If you find yourself adding transcript persistence, you are building
something that exists.

**What is untouched and IS the job:** nothing surfaces the trust *warning line itself* in a place an
operator reads. The log now survives; the signal is still buried in it.

## The trap this lane is most likely to fall into

**Silently auto-trusting the directory.** The issue's own suggested fix says *"print … and
continue"* — not "set `hasTrustDialogAccepted`". A builder that makes the warning go away by granting
trust has inverted the fix: it removes the *signal* instead of surfacing it, and it does so by
widening permissions without an operator ever deciding to. That is strictly worse than the bug.

**Second trap: changing the exit contract.** `claude-turn`'s existing exit codes (0/3/5/6/7) must
stay exactly as they are. This is an observability change. A trust warning is **not** grounds to fail
a turn — the turn still works, it just works with fewer permissions than the operator expected.

## Write-set

- `utils/py/claude-turn.py` — the Python (authoritative) half **only**

**Do NOT touch `relay-automation/claude-turn.sh`.** It is the frozen half of twin pair
`claude-turn.sh : claude-turn.py` (`test/gh308-frozen-twin-guard.sh`). Editing it requires a
`Frozen-twin-exception:` trailer and is explicitly out of scope for this lane — the Python-only
write-set is what keeps this lane fireable at all.

## Containment note

`validate.sh` runs `test/claude-turn.sh`, so this file **is executed inside every phase's
pre-advance gate**. That makes the lane *contained*, not inert: a defect here turns this phase's own
gate red rather than wedging a later turn. Do not assume a broken change will be caught downstream —
it will be caught by your own gate, which is the intended behaviour.

## Adjacent, and NOT this lane

`marathon_drive.py:238-260`'s binary probe (GH-117) fail-fasts on a missing claude binary before any
tick mutation. It is **PATH-only and never trust-aware**, so it neither blocks nor interacts with
this fix. Verified. Leave it alone.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/claude-turn.py
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-marathon-wave3/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-marathon-wave3/bin/tick claim MARATHON-GH380-CLAUDE-TRUST-TURN --agent codex --paths "marathon-system/nightwatch-wave-3-2026-08-11--gh380-claude-trust/RELAY.md,utils/py/claude-turn.py"
   - /Users/noelsaw/Documents/GH Repos/xyz-marathon-wave3/bin/tick ping MARATHON-GH380-CLAUDE-TRUST-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-marathon-wave3/bin/tick release MARATHON-GH380-CLAUDE-TRUST-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/nightwatch-wave-3-2026-08-11--gh380-claude-trust/RELAY.md and utils/py/claude-turn.py. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/claude-turn.py. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GH Repos/xyz-marathon-wave3/bin/tick release MARATHON-GH380-CLAUDE-TRUST-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-marathon-wave3/bin/tick done MARATHON-GH380-CLAUDE-TRUST-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-marathon-wave3/bin/tick
   Edit ONLY marathon-system/nightwatch-wave-3-2026-08-11--gh380-claude-trust/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
