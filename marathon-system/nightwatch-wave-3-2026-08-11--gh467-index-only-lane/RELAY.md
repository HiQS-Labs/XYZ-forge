# Marathon Phase gh467-index-only-lane
STATUS: Open
NEXT: codex (Builder)

<!-- marathon-drive: task=MARATHON-GH467-INDEX-ONLY-LANE-TURN builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

---
title: "Phase brief: GH-467 gh467-index-only-lane (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-08-11
updated: 2026-08-11
owner: noel
goal: >
  Phase-brief input consumed by the marathon driver for the gh467-index-only-lane phase of
  MARATHON-2026-08-11-NIGHTWATCH-WAVE-3 — not itself an active-doc capture; the canonical capture doc
  is GH-467-INDEX-ONLY-LANE-GIT-BAN.md two levels up.
roadmap_exempt: true
---

# Brief — GH-467: refuse an index-only lane at preflight instead of dispatching it to fail

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10 in the Nightwatch batch-2 doc fan-out. The issue deliberately declines to pick a shape ("Not choosing here"), so criteria were authored for **option 3 only** and the reasoning recorded. The contract was **rejected by preflight on 2026-08-11** and fixed — see "The contract was wrong". Preflight after the fix: **ready (exit 0)**, issue **OPEN**. | Fire as phase 3 of 3, LAST, because it modifies the preflight tool that gates future waves. |

**Parent capture doc:** `PROJECT/2-WORKING/GH-467-INDEX-ONLY-LANE-GIT-BAN.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/467

## Acceptance

**Read the acceptance criteria from the parent capture doc's authored acceptance block**, which is
scoped to **option 3 only**. The issue lists three options and picks none.

## The defect

Every builder packet says **"Do NOT run git"**, verbatim at `relay-automation/marathon-drive.sh:1017,1023`
and `utils/py/marathon_drive.py:1757,1772`. So a lane whose *deliverable is an index change* — untrack
a file, change what is staged — is dispatched to a builder that is forbidden from performing its own
work. It cannot succeed, and nothing says so until it fails.

## The ban is PROTECTIVE. Do not remove it.

This is the single most important line in this brief. The rationale is real and documented
(`relay-automation/relay-turn-lib.sh:1026-1053`,
`PROJECT/3-COMPLETED/RELAY-CONTAINMENT-HARDENING.md:31`): the harness performs the commit itself, and
a builder that commits mid-turn has previously **reset HEAD and orphaned a peer agent's commit**.

Any change that lifts, weakens, or conditionally bypasses the ban is out of scope and should be
treated as a mis-scoped lane. The fix is to **refuse the lane early**, not to let the builder do git.

## Why option 3, and not 1 or 2

| option | write-set | why not |
|---|---|---|
| 1 — driver grants a narrow git verb | `marathon_drive.py` | **the running driver** — can never be a marathon lane |
| 2 — allowlist verb in `rtl_enforce` | `relay-turn-lib.sh` / `rtl.py` | **the turn kernel** — the most protected file in the repo; "a narrow allowlist verb" understates it badly |
| **3 — declare intent, preflight refuses** | `utils/py/swarm_preflight.py` | ✅ no driver, no kernel — the only one that is fireable |

## The fact the issue omits, and it changes the size of the job

`lanes.orchestrator_only` **already exists** in `utils/py/swarm_preflight.py:199-234` (`lane_plan()`).
But it is **advisory only — nothing outside that file reads `orchestrator_owned`**. Verified.

So "preflight refuses to dispatch" is **new behaviour**, not wiring up something that already works.
Do not assume the plumbing exists because the field does.

## The contract was wrong, and preflight caught it

On 2026-08-11 this lane's own contract was **rejected outright**:

```
CONTRACT ERROR: artifacts_new entry 'test/gh467-index-only-lane-blocked.sh'
has no matching fix_probes entry of type path_absent on the same path
```

A `path_absent` probe was added and the lane went ready. Worth knowing as a builder: the new test
file you are expected to create is itself a probe target, so **the lane is only satisfied once that
file exists**. Not creating it leaves the bug reported as still-present.

## Also missing, and part of the job

**No test asserts the "Do NOT run git" string is present.** So the ban could be silently weakened by a
future change with nothing going red. Add a regression guard for it alongside the new refusal test —
a protective instruction with no test is one edit away from disappearing.

## Write-set

- `utils/py/swarm_preflight.py`
- `test/gh467-index-only-lane-blocked.sh` — **NEW**
- `validate.sh` — register the new test

`utils/py/swarm_preflight.py` is the **authoritative (Python)** half of a frozen twin pair; the Bash
twin `utils/swarm-preflight.sh` is **out of scope** and must not be touched — doing so would need a
`Frozen-twin-exception:` trailer.

## Containment note — read before you start

This lane modifies **the preflight tool itself**, which is what verdicts future marathon waves. It is
sequenced LAST for that reason: a defect lands on its own gate with no phase after it to damage.
Preflight for *this* wave already ran and is recorded, so nothing in this run depends on the tool you
are changing.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/swarm_preflight.py,test/gh467-index-only-lane-blocked.sh,validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-marathon-wave3/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-marathon-wave3/bin/tick claim MARATHON-GH467-INDEX-ONLY-LANE-TURN --agent codex --paths "marathon-system/nightwatch-wave-3-2026-08-11--gh467-index-only-lane/RELAY.md,utils/py/swarm_preflight.py,test/gh467-index-only-lane-blocked.sh,validate.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-marathon-wave3/bin/tick ping MARATHON-GH467-INDEX-ONLY-LANE-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-marathon-wave3/bin/tick release MARATHON-GH467-INDEX-ONLY-LANE-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/nightwatch-wave-3-2026-08-11--gh467-index-only-lane/RELAY.md and utils/py/swarm_preflight.py,test/gh467-index-only-lane-blocked.sh,validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/swarm_preflight.py,test/gh467-index-only-lane-blocked.sh,validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GH Repos/xyz-marathon-wave3/bin/tick release MARATHON-GH467-INDEX-ONLY-LANE-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-marathon-wave3/bin/tick done MARATHON-GH467-INDEX-ONLY-LANE-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-marathon-wave3/bin/tick
   Edit ONLY marathon-system/nightwatch-wave-3-2026-08-11--gh467-index-only-lane/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
