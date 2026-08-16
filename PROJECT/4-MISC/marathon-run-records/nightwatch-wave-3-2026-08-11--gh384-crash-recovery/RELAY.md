# Marathon Phase gh384-crash-recovery
STATUS: Approved
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-GH384-CRASH-RECOVERY-TURN builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

---
title: "Phase brief: GH-384 gh384-crash-recovery (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-08-11
updated: 2026-08-11
owner: noel
goal: >
  Phase-brief input consumed by the marathon driver for the gh384-crash-recovery phase of
  MARATHON-2026-08-11-NIGHTWATCH-WAVE-3 — not itself an active-doc capture; the canonical capture doc
  is GH-384-MARATHON-CRASH-RECOVERY.md two levels up.
roadmap_exempt: true
---

# Brief — GH-384: report the ungated commits a crashed marathon leaves behind

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-10 in the Nightwatch batch-2 doc fan-out. Issue had **no acceptance criteria**; criteria were authored in a separately labelled block. Two of the issue's own claims were corrected against source before this brief existed — see "What was corrected". Preflight 2026-08-11: **ready (exit 0)**, issue **OPEN**. | Fire as phase 1 of 3, first, because its write-set is a NEW file plus README and nothing downstream reads either. |

**Parent capture doc:** `PROJECT/2-WORKING/GH-384-MARATHON-CRASH-RECOVERY.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/384

## Acceptance

**Read the acceptance criteria from the parent capture doc's `## Acceptance — authored` block.** The
issue itself carries none, which is why they are authored and labelled as such. Do not treat this
brief's prose as the definition of done.

## The defect

A marathon that is interrupted — crash, kill, host reset — leaves a **clean working tree containing
commits that were never gated**, and nothing reports it. The mechanism, which the issue asserts but
never explains:

| step | where |
|---|---|
| the turn's commit lands | `relay-automation/relay-turn-lib.sh:1144` |
| the pre-advance gate runs *later* | `utils/py/marathon_drive.py:1557` |
| `phase.approved` is logged only after the gate passes | `:1580` |

An interruption inside that window is therefore **structurally** an ungated commit. The tree looks
clean because the work *was* committed; what is missing is any record that it was ever verified.  [Unverified — no citation]

## What was corrected before you start — do not re-introduce these

**1. The `phases/<plan>--p*/` residue claim is STALE.** GH-484 flipped the default phase-output
directory to `marathon-system/` on 2026-08-10 (`utils/py/marathon_drive.py:697-700`,
`relay-automation/marathon.sh:174-178`). The old `phases/` path survives only as a *fallback* in the
two existing monitors. A new interruption today lands in `marathon-system/`. Write the tool against
the current default and treat `phases/` as legacy-only.

**2. "No tooling reports phase state" is an OVERSTATEMENT.** `relay-automation/marathon-ls.sh` and
`relay-automation/marathon-detail.sh` already exist and already report driver-lock LIVE/STALE/IDLE
plus `STATUS:` / `NEXT:` lines. Read both in full before writing anything — duplicating them is the
most likely way to waste this lane.

**The genuinely missing thing is narrower than the issue implies**, and it is the whole job:

> **no tool cross-references "this phase is Open **AND** a commit for it exists **AND** no
> `phase.approved` event ever landed."**

That conjunction is the recovery signal. Everything else in the neighbourhood already exists.

## The trap this lane is most likely to fall into

**Editing `relay-automation/marathon.sh`.** The issue's own suggestion 1 proposes
`marathon --status` / `--recover`, which edits **the running driver** — and a marathon lane cannot
build that, because the driver is what would be gating the change mid-run. That is why acceptance is
scoped to a **NEW STANDALONE SCRIPT**. If you find yourself opening `marathon.sh` or
`marathon_drive.py`, stop: the lane is mis-scoped and should halt rather than proceed.

**Second trap: inventing a state file.** Do not add new persistent state to make detection easier.
The three facts above are already observable from the relay file, the commit log, and the tick event
log. A recovery tool that requires the crashed run to have cooperated is not a recovery tool.

## Write-set

- `relay-automation/marathon-recover.sh` — **NEW**
- `README.md` — document the tool where the other monitors are documented

**Nothing else.** Specifically **not** `marathon.sh`, **not** `marathon_drive.py`, **not**
`relay-turn-lib.sh`, **not** `rtl.py`.

## Dependency worth stating

The capture doc records that a full recovery story depends on **#388** (durable run log) — you cannot
recover from a record that was never written. This lane is deliberately scoped to what is detectable
*today*, from what already survives a crash. Do not build against #388's not-yet-existing log.


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/marathon-recover.sh,README.md
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): ~/Documents/GH Repos/xyz-marathon-wave3/bin/tick
   - ~/Documents/GH Repos/xyz-marathon-wave3/bin/tick claim MARATHON-GH384-CRASH-RECOVERY-TURN --agent codex --paths "marathon-system/nightwatch-wave-3-2026-08-11--gh384-crash-recovery/RELAY.md,relay-automation/marathon-recover.sh,README.md"
   - ~/Documents/GH Repos/xyz-marathon-wave3/bin/tick ping MARATHON-GH384-CRASH-RECOVERY-TURN --agent codex
   - ~/Documents/GH Repos/xyz-marathon-wave3/bin/tick release MARATHON-GH384-CRASH-RECOVERY-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/nightwatch-wave-3-2026-08-11--gh384-crash-recovery/RELAY.md and relay-automation/marathon-recover.sh,README.md. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/marathon-recover.sh,README.md. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: ~/Documents/GH Repos/xyz-marathon-wave3/bin/tick release MARATHON-GH384-CRASH-RECOVERY-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: ~/Documents/GH Repos/xyz-marathon-wave3/bin/tick done MARATHON-GH384-CRASH-RECOVERY-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: ~/Documents/GH Repos/xyz-marathon-wave3/bin/tick
   Edit ONLY marathon-system/nightwatch-wave-3-2026-08-11--gh384-crash-recovery/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

Implemented `relay-automation/marathon-recover.sh` and documented its recovery procedure in
`README.md`. The report is read-only: it scans current `marathon-system/` plus legacy `phases/`,
uses the shared driver-lock resolver, finds each relay task, and labels an `UNGATED COMMIT` only
when a non-terminal phase lacks `marathon.phase.approved` and has a matching commit reachable from
the current tip. It does not create state or alter the monitored repository.

Verified with `bash -n` and an isolated temporary two-phase fixture: the Approved phase with an
approval event reported `APPROVAL: recorded`; the Open phase with a reachable relay commit and no
event reported `UNGATED COMMIT` and `RECOVERY: UNVERIFIED`; fixture file hashes were unchanged.

### Round 1 · Reviewer · agy
swept file: yes
The implementation exactly matches the brief. The `marathon-recover.sh` script correctly detects ungated commits using the intersection of the tick event log, relay file status, and the reachable git commits, without persisting any extra state to the target repository. The bash logic safely handles empty or non-existent log structures. The README update concisely documents the tool and its output.

Verified the failure modes with a probe in `$TMPDIR`.
**Verdict:** Approved
