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
clean because the work *was* committed; what is missing is any record that it was ever verified.

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
