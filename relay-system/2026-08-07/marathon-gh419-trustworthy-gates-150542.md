# Marathon Phase gh419-trustworthy-gates
STATUS: Approved
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH419-TRUSTWORTHY-GATES-TURN builder=codex reviewer=agy round-cap=7 -->

## Phase Brief

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


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): GUIDING-PRINCIPLES.md,utils/py/gate_inventory.py,test/gh419-gate-inventory.sh,validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick
   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick claim MARATHON-GH419-TRUSTWORTHY-GATES-TURN --agent codex --paths "phases/litmus-trustworthy-gates-2026-08-06--gh419-trustworthy-gates/RELAY.md,GUIDING-PRINCIPLES.md,utils/py/gate_inventory.py,test/gh419-gate-inventory.sh,validate.sh"
   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick ping MARATHON-GH419-TRUSTWORTHY-GATES-TURN --agent codex
   - /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick release MARATHON-GH419-TRUSTWORTHY-GATES-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/litmus-trustworthy-gates-2026-08-06--gh419-trustworthy-gates/RELAY.md and GUIDING-PRINCIPLES.md,utils/py/gate_inventory.py,test/gh419-gate-inventory.sh,validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: GUIDING-PRINCIPLES.md,utils/py/gate_inventory.py,test/gh419-gate-inventory.sh,validate.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick release MARATHON-GH419-TRUSTWORTHY-GATES-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick done MARATHON-GH419-TRUSTWORTHY-GATES-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-xyz-3-agents-swarm/2569ea28-6a7e-429b-87d2-4a92b81c3694/scratchpad/wt-litmus/bin/tick
   Edit ONLY phases/litmus-trustworthy-gates-2026-08-06--gh419-trustworthy-gates/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

### Round 1 · Builder · codex

Implemented the phase artifacts only: `GUIDING-PRINCIPLES.md` now states the witnessed-negative-control
rule and names #351/#348; `utils/py/gate_inventory.py` discovers every registered executable gate from
`validate.sh` and emits declared evidence or explicit `none`; `test/gh419-gate-inventory.sh` supplies
controlled bad fixtures for the two disqualifying shapes; and `validate.sh` registers that regression.
Evidence is a local `# gate-evidence: {…}` declaration beside a gate, never inferred from its name or a
green run. The deliberate scope boundary is `validate.sh`'s executable gate list, excluding ordinary
Python unit assertions. Verified: `bash test/gh419-gate-inventory.sh` passes.

### Round 1 · Reviewer · agy

swept file: yes

The changes accurately implement the brief requirements.
1. `GUIDING-PRINCIPLES.md` was correctly updated to explicitly state that a green gate without a witnessed red control is not evidence, and names the required disqualifying shapes #351 and #348.
2. `utils/py/gate_inventory.py` accurately discovers registered tests in `validate.sh` and implements the correct negative-control evidence schema correctly distinguishing absence of evidence and filtering out disqualifying shapes appropriately.
3. `test/gh419-gate-inventory.sh` correctly pins the disqualifying shapes and provides controlled bad fixtures.
4. `validate.sh` registers `gh419-gate-inventory.sh` and it passes regression checks successfully.

**Verdict:** Approved
