# Marathon Phase gh392-hardware-sizing
STATUS: Approved
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-GH392-HARDWARE-SIZING-TURN-3 builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

---
title: "Phase brief: GH-392 gh392-hardware-sizing (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-08-10
updated: 2026-08-10
owner: noel
goal: >
  Phase-brief input consumed by the marathon driver for the gh392-hardware-sizing phase of
  MARATHON-2026-08-10-NIGHTWATCH-WAVE-2 — not itself an active-doc capture; the canonical capture doc
  is GH-392-HARDWARE-SIZING-GUIDANCE.md two levels up.
roadmap_exempt: true
---

# Brief — GH-392 part (a): publish the hardware sizing guidance that does not exist

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10. Acceptance criteria **authored onto the issue** (it had none), then **revised after an adversarial codex + agy consult** that found two of them defective — see "What the review changed". Preflight 2026-08-10: **ready (exit 0)**, acceptance **8/8 verbatim**, issue **OPEN**. | Fire as phase 1 of 2, first, because documentation cannot affect the phase after it. |

**Parent capture doc:** `PROJECT/2-WORKING/GH-392-HARDWARE-SIZING-GUIDANCE.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/392

## Acceptance

**Read the acceptance criteria from the parent capture doc's `## Acceptance` block** — all eight,
carried verbatim from the issue. Work from those, not from this brief's prose.

## The defect

`README.md:129`'s Prerequisites section is four rows — Codex CLI, agy CLI, Node 18+ and git,
Python 3.8+ — and **states no hardware requirement at all**. Verified against the tree 2026-08-10.  [Unverified — no citation]

That matters because the harness's memory cost is not uniform:

| Route | Shape | Measured |
|---|---|---|
| serial `marathon.sh --plan` | serial by construction (GH-241): one builder + one gate | **~2.2 GB steady**, 2.26 GB peak, 138 samples |
| `/10days` per-lane dispatch | one agent per lane per wave | **7-14 GB** for a real 7-lane wave, uncapped |

A new operator on a 16 GB Mac gets no signal before dispatching the second one.

## What the review changed — read this before writing a word

Two criteria in the first draft were wrong, and the corrections are the substance of this lane:

**1. Do not write "Path A" / "Path B" as if they are defined.** They are the *issue's* private
vocabulary and appear nowhere in the README. Name the routes by their command — the serial
`marathon.sh --plan` route, and the `/10days` per-lane parallel dispatch — before using any shorthand.

**2. Do not write that the harness has no memory protection.** That is false. The GH-390 gate guard
enforces an RSS cap on a gate and kills it; it was observed live on 2026-08-10 reporting
`peak group RSS 1042MB … caps: RSS 8192MB`. What is missing is **host-aware wave sizing** — nothing
reads host RAM, nothing clamps wave width, nothing refuses. Per-gate containment exists; host sizing
does not. Say exactly that.

A third correction, smaller: `kernel ≤ 1 per wave` is a **coordination/zone cap, not a memory cap**
(`utils/marathon-plan-zones.default.json`, `maxPerWave`). It is enforced independently of write-set
collision, so calling it a "write-conflict rule" is imprecise in the direction that misleads.

## The trap this lane is most likely to fall into

**Writing about the capability probe in the present tense.** Part (b) of the issue proposes
`xyz doctor`, a wave clamp, and a refusal below a memory floor. **None of it exists.** Prose that
describes any of it as shipped is both a false statement about the harness and a way to make part (b)
look done — the false-completion shape that already cost this repo #461 and #425.

Part (b) is out of scope. Do not build it, do not stub it, do not describe it as present.

## Write-set

| File | Note |
|---|---|
| `README.md` | the Prerequisites section, plus wherever the sizing guidance best lives |

**Nothing else.** This is a documentation-only diff. A code change made "to support the prose" is out
of scope by definition — if the prose seems to need code, the prose is wrong.

## Why a reviewer is the gate here

`validate.sh` does not read README prose, so a green suite says nothing about whether this lane
succeeded. The gate protects against collateral damage only. Criteria 2, 5, 7 and 8 are phrased as
things a reviewer can check by reading the artifact — that is deliberate, and it is why the reviewer
pass matters more on this lane than on a code lane.


## Debug mantra (auto-triggered — 2 prior attempt(s) on this phase did not reach Approved)

Before trying again, read `relay-automation/DEBUG-MANTRA.md` (relative to the harness root) and follow its four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.
Last recorded reason (`marathon-system/nightwatch-wave-2-2026-08-10--gh392-hardware-sizing/ESCALATION.md`): `timeout-no-artifact`. Read it before re-guessing.

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): README.md
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH392-HARDWARE-SIZING-TURN-3 --agent codex --paths "marathon-system/nightwatch-wave-2-2026-08-10--gh392-hardware-sizing/RELAY.md,README.md"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH392-HARDWARE-SIZING-TURN-3 --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH392-HARDWARE-SIZING-TURN-3 --agent codex --to agy
4. Edit ONLY these paths: marathon-system/nightwatch-wave-2-2026-08-10--gh392-hardware-sizing/RELAY.md and README.md. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: README.md. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH392-HARDWARE-SIZING-TURN-3 --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH392-HARDWARE-SIZING-TURN-3 --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY marathon-system/nightwatch-wave-2-2026-08-10--gh392-hardware-sizing/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

- Touched: `marathon-system/nightwatch-wave-2-2026-08-10--gh392-hardware-sizing/RELAY.md`; reviewed the scoped `README.md` artifact, which already contains the complete sizing guidance required by this phase.
- Kept the existing README wording because it meets all eight acceptance criteria without claiming the deferred capability probe: it defines the serial `marathon.sh --plan` and `/10days` routes, gives the 16/24/32/64 GB table and per-lane arithmetic, records full measurement provenance, distinguishes the zone cap and the GH-390 RSS guard from host-aware sizing, and defines “Supported.”
- Verification: targeted `rg` checks found all required README markers and confirmed `STATUS: Open`, `NEXT: agy (Reviewer)`, and this builder block. No README-prose test or `bin/validate-relay` validator exists in this worktree; no full gate was run.
- Debug breadcrumb: the prior `timeout-no-artifact` cannot be reproduced from the current tree because `README.md` now has the artifact; reviewer should independently assess the complete file against the acceptance block.

### Round 1 · Reviewer · agy

swept file: yes

The builder correctly implemented all 8 acceptance criteria from `PROJECT/2-WORKING/GH-392-HARDWARE-SIZING-GUIDANCE.md` into the `README.md` file.

1. **Hardware requirement & recommended minimum**: `16 GB RAM for the serial marathon.sh --plan route` is explicitly stated and covers the context (one builder and gate serially, normal host reserve).
2. **Execution paths defined by command**: Uses `marathon.sh --plan` and `/10days` parallel dispatch, avoiding "Path A / B".
3. **Table coverage**: Covers 16 / 24 / 32 / 64 GB, explicitly noting that 16 GB is for the serial path only.
4. **Budgeting rule**: States `1.5-2 GB per concurrent lane` + target-suite memory + host reserve.
5. **Measurement provenance**: Explicitly included (32 GB M1 Max, 138 samples, 10-second intervals, etc).
6. **Coordination/zone cap**: Defines `kernel ≤ 1 per wave` correctly without implying it limits memory.
7. **No false claims of capability vs memory protection**: Correctly distinguishes the GH-390 RSS cap guard (which exists) from host-aware wave sizing (which does not exist yet).
8. **Definition of 'Supported'**: "Supported" is explicitly defined as a recommended planning envelope without expected swapping.

I reviewed the entirety of the `README.md` file and found no pre-existing defects or out-of-scope issues that needed correction. The prose additions are well-placed under the "Hardware sizing for Marathon" heading within the Prerequisites section.

**Verdict:** Approved
