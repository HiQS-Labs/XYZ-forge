---
title: "Phase brief: GH-419 gh419-trustworthy-gates (marathon builder input, not a capture doc)"
status: not yet fired
created: 2026-08-06
updated: 2026-08-06
owner: noel
goal: >
  Phase-brief input consumed by relay-automation/marathon-drive.sh for the gh419-trustworthy-gates
  phase of MARATHON-2026-08-06-LITMUS — not itself an active-doc capture; the canonical capture doc
  is GH-419-TRUSTWORTHY-GATES.md two levels up.
roadmap_exempt: true
---

# Brief — GH-419 Phases 1–2: the principle, and the decision-gate inventory

## Status

| What was just completed | What's next |
|---|---|
| Contract authored and verified READY. Scope, sequencing and acceptance were revised on the issue 2026-08-04 after a Codex review caught three defects in the original framing. | Fire as marathon phase 1 of 4. |

**Parent doc:** `PROJECT/2-WORKING/GH-419-TRUSTWORTHY-GATES.md`
**Issue:** https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419
**Runs FIRST in this marathon — it builds the instrument the other three lanes record into.**

## Acceptance

**Read the acceptance criteria from the parent capture doc's `## Acceptance` block.** They are
copied verbatim from the issue there and carry `Deviations: None`. Do not work from a paraphrase of
them in this brief — GH-400 exists because restating acceptance instead of copying it corrupts it,
and this lane is a member of the class that defect belongs to.

## The gap

One recurring, expensive defect class, stated precisely:

> A gate reported green while being **structurally incapable** of reporting anything else.

Eight documented instances. Every one passed review; every one was found by a human reading the
check and the thing it checked side by side, usually weeks later. None was caught by the gate suite,
because the gate suite's own passing is the thing that cannot be trusted.

| # | The check | Why it could not fail |
|---|---|---|
| #348 | `marathon-plan` Bash↔Python parity assertion | Compared Python to Python |
| #351 | `roadmap-dashboard` drift test | Regenerated the artifact it validated |
| #342 | GH-281 Tier-1 debug capture | Never ran on the default lane at all |
| #362 | GH-308 freeze guard | Rejected a trailer permanently in history |
| #369 | `find-doc.sh --root` | Spun forever; blamed a flag the user never passed |
| #400 | `/10days` capture-doc acceptance | Nothing compared the doc to its source issue |
| #417 | turn-ROOT resolution | No test can distinguish the two candidate behaviours |
| #418 | `swarm-preflight` readiness | Never checks issue state or the FROZEN banner |

**A ninth instance surfaced while this marathon was being authored.** #368 was selected as a lane,
its capture doc reading "not yet fired", when it had already been fixed and merged (PR #433,
`3a6ddfc`) and closed the same day. Preflight would have passed it READY. That is #418's defect,
observed live — and it is exactly the evidence phase 3 of this marathon is required to produce.

## What to build

**Phase 1 — the principle.** `GUIDING-PRINCIPLES.md` gains a numbered entry stating that a gate
which has never been observed failing is not evidence, and that every new check ships with a
demonstration it fails for the right reason. It must name both disqualifying shapes with their
instances: a check that validates an artifact it generates (#351), and a check that compares a lane
to itself (#348). Docs only.

**Phase 2 — the inventory.** `utils/py/gate_inventory.py` plus `test/gh419-gate-inventory.sh`,
registered in `validate.sh`'s `TESTS` array.

Three distinctions the acceptance turns on, and which a naive implementation will collapse:

- **Discovery is generated; evidence is declared.** A newly added gate must appear in the inventory
  without anyone remembering to register it — but whether its test actually falsifies its claim is
  never inferred from a filename or a green run. Only from recorded evidence.
- **Absence of evidence is recorded as absence.** An explicit `none`, never a pass.
- **Three accepted forms of negative control**, whichever is cheapest and honest: a pre-fix replay,
  a deliberate mutation, or a controlled bad fixture. A pre-fix count is *not always available* —
  net-new behavior has no "before" — so do not write the check such that it cannot be met.

Scope is **decision gates** — a check whose result changes what the system does (starts a run, emits
a packet, advances a phase, reverts an edit). Ordinary unit assertions are explicitly out of scope;
the parent doc's non-goals say so, and generating noise there devalues the signal where it matters.

## Litmus test for this lane itself

The inventory's own regression test is a decision gate, so it is subject to its own contract: it
must be **observed failing** before it is believed. Pin the two disqualifying shapes — a
self-comparing parity assertion and a self-regenerating drift check must both be detected as having
no negative control.

## Out of scope for this phase

Phase 3 of the issue (#418 as the first child) is **phase 3 of this marathon**, on its own issue.
The parent doc is explicit: its write-set collides with #418's by construction and the two must
never run as concurrent lanes. Do not touch `utils/py/swarm_preflight.py` in this phase.

Frozen Bash twins are out of scope entirely (GH-308) — work lands in Python.
