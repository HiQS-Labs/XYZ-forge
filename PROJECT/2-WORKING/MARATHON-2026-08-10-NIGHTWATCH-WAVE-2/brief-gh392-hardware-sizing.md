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
Python 3.8+ — and **states no hardware requirement at all**. Verified against the tree 2026-08-10.

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
