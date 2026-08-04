---
gh_issue: 419
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419
title: "GH-419 — trustworthy gates: a check that has never been observed failing is not evidence"
status: "Intake (2-WORKING) — captured 2026-08-04, not yet fired. Policy + evidence inventory only; changes no execution behavior. #418 is the designated first child."
created: 2026-08-04
updated: 2026-08-04
owner: noel
doc_type: project
complexity: 3
risk: 2
effort: 3
phases: 3
ratings_provisional: true
related:
  - "#418 — the designated FIRST CHILD. swarm-preflight never checks issue state or the GH-308 FROZEN banner. Fixing it under this policy proves the contract on a real gate."
  - "#417 — also a member of the class: the tree asserts both that `rev-parse --show-toplevel` is the correct turn-ROOT default and that it is the bug 'caught live', with no test able to distinguish them."
  - "#400 — established the `unknown`-reported-loudly posture this generalizes, and supplied the worked example of a negative control (1 pass / 19 fail against pre-fix code)."
  - "#348 / #351 / #342 / #362 / #369 — the five closed instances. Read these before designing the inventory; they are the failure shapes it must detect."
  - "#308 — Python is the authoritative lane. Frozen Bash twins are out of scope."
non_goals:
  - "A big-bang audit of all 147 validate.sh suites. That is how this becomes a project nobody finishes. The inventory is the deliverable; retrofitting is opportunistic and permanently open."
  - "Applying any of this to ordinary unit tests. The scope is DECISION GATES. A test asserting a pure function's return value needs no negative-control record and no `unknown` reporting; demanding one would generate noise and devalue the signal where it matters."
  - "Deleting or weakening any existing check to make the inventory look complete. A check with no negative control is recorded as such, not removed."
  - "Mandating a mutation-testing framework or adding a dependency. The bar is evidence the check can fail, by whatever means is cheapest."
  - "Changing execution behavior as part of THIS issue. Policy and inventory only; each demonstrated gap is fixed on its own issue, starting with #418."
  - "Reopening the eight instances. They are closed or separately tracked; this is the pattern, not a re-litigation."
  - "Editing the frozen Bash twins (GH-308). Work lands in utils/py/**."
goal: >
  Turn an ad-hoc act of diligence into a standing contract: every decision gate must ship with
  evidence that it can fail for the right reason, and must say what it could not check. Eight
  documented instances of a gate that reported green while structurally incapable of reporting
  anything else — three of them found in a single afternoon — is the argument that finding these
  by hand does not scale.
---

# GH-419 · a gate that has never been observed failing is not evidence

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-08-04 from the triage that retired four marathon plans and filed #417/#418. Scope, sequencing and acceptance revised after a Codex review that caught three defects in the original framing. Preflight contract authored and verified. | Operator go. Then Phase 1 (the principle), Phase 2 (the inventory), Phase 3 (#418 as the first child, closed under the policy). |

## The problem

This repo has one recurring, expensive defect class, and it is not "a gate was wrong." It is:

> **A gate reported green while being structurally incapable of reporting anything else.**

Every instance passed review. Every one was found by a human reading the check and the thing it
checked side by side, usually weeks later. None was caught by the gate suite, because the gate
suite's own passing is the thing that cannot be trusted.

| # | The check | Why it could not fail |
|---|---|---|
| #348 | `marathon-plan` Bash↔Python parity assertion | Compared Python to Python |
| #351 | `roadmap-dashboard` drift test | Regenerated the artifact it validated |
| #342 | GH-281 Tier-1 debug capture | Never ran on the default lane at all |
| #362 | GH-308 freeze guard | Rejected a trailer permanently in history |
| #369 | `find-doc.sh --root` | Spun forever; blamed a flag the user never passed |
| #400 | `/10days` capture-doc acceptance | Nothing ever compared the doc to its source issue |
| #417 | turn-ROOT resolution | No test can distinguish the two candidate behaviours |
| #418 | `swarm-preflight` readiness | Never checks issue state or the GH-308 FROZEN banner |

Five were closed before 2026-08-03. **#400, #417 and #418 came out of a single read-only triage on
one afternoon.** A class producing three findings in an afternoon of *looking* is not exhausted, and
looking by hand does not scale.

## The principle, and why it is actionable

**A gate that has never been observed failing is not evidence. It is decoration.**

The corollary is the enforceable half: *every decision gate must ship with a demonstration that it
fails for the right reason.* The repo already knows this technique and applies it ad hoc — #400's
suite was observed at **1 pass / 19 fail** against pre-fix code; GH-400 criterion 2's at **2 pass /
11 fail**; #348's fix added an in-run mutation self-check that fails if the comparison ever stops
being cross-lane. What is missing is that these are individual acts of diligence rather than a
contract every gate is held to.

The second half matters as much: **a gate must say what it could not check.** #400 established the
posture — `unknown` reported loudly and never masked as a pass, and the packet stating whether its
acceptance list was verified or merely inlined. Silence reading as success is how all eight survived.

## Scope — decision gates, not every assertion

The unit is a **decision gate**: a check whose result changes what the system does — starts a run,
emits a packet, advances a phase, reverts an edit. In scope, all on the Python lane:

- **Lane readiness / packet emission** — `utils/py/swarm_preflight.py`
- **`fix_probes`** — whose polarity trap (probes detect the **bug**, not the fix) has already produced
  false "already done" STALE verdicts: a green that means the opposite of what it reads
- **Planner and pre-advance gates** — `utils/py/marathon_drive.py`, `marathon_plan.py`, `_marathon_plan.py`
- **Containment** — `utils/py/relay_drive.py`, `relay_loop.py`, `poll.py`, `rtl.py`
- **The tests that certify the above** — in scope precisely because #348 and #351 were failures *of
  the certifying test*, not of the gate

## Sequencing and reversibility

Policy and evidence first. **Nothing new blocks and nothing new fails until an individual gap has
been demonstrated and fixed on its own issue.** Rollback is deleting a doc section and a generated
file — which is what makes it safe to adopt before every gap is known.

**#418 is the first concrete child**, mirroring GH-308 Phase 1, which closed #278 as "the first fix
under the new policy and proof it works."

## Acceptance

*Copied verbatim from [issue #419](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/419)
(`## Acceptance`), fetched 2026-08-04. Deviations, if any, are recorded below this block.*

- [ ] `GUIDING-PRINCIPLES.md` gains a numbered principle stating that a gate which has never been observed failing is not evidence, and that every new check ships with a demonstration it fails for the right reason.
- [ ] The principle names the two disqualifying shapes explicitly, each with its instance: a check that validates an artifact it generates (#351), and a check that compares a lane to itself (#348).
- [ ] A machine-readable inventory of **decision gates** records, per gate, whether a negative control has been **observed**, in which of the accepted forms, and with what result — and an explicit `none` where there is no evidence. Absence of evidence is recorded as absence, never as a pass.
- [ ] **Discovery is generated from the tree; evidence is declared alongside each gate.** A newly added gate appears in the inventory without anyone remembering to register it, but whether its test actually falsifies its claim is never inferred from a filename or a green run — only from recorded evidence.
- [ ] Every new or **materially changed** decision gate ships a negative control in one of three accepted forms, chosen by whichever is cheapest and honest: a **pre-fix replay** (run the new suite against the old code), a **deliberate mutation** (break the gate's own logic and observe the suite go red), or a **controlled bad fixture** (an input the gate must reject). A pre-fix count is not always available — net-new behavior has no "before" — and the criterion must not be written so that it cannot be met.
- [ ] Gates that make an **operational readiness claim** — READY/NOT-READY, safe-to-advance, contained — report what they could **not** verify, distinguishing "checked and passed" from "could not check", in their output and in `run-candidate.json`, per #400's `unknown` posture. This applies to readiness claims only and must not become boilerplate on ordinary assertions.
- [ ] A regression test pins the two disqualifying shapes: a self-comparing parity assertion and a self-regenerating drift check are both detected as having no negative control.
- [ ] #418 is closed under this policy as its first child, with its negative control recorded in the inventory — demonstrating the contract on a real gate before anything is asked of the rest of the tree.

## Acceptance — deviations from the issue

None. Every criterion is carried verbatim.

The issue's scope, sequencing and acceptance were revised on 2026-08-04 — *before this capture doc
existed* — after a Codex review caught three defects in the original framing: a demanded "pre-fix
count" that cannot exist for net-new behavior; "the inventory is generated from the tree" conflating
automatic **discovery** with evidence that must be **declared**; and an `unknown`-reporting
requirement scoped loosely enough to land on ordinary unit tests. Those changes belong to the issue,
not to this doc, so there is no deviation to declare.

## Phases

| Phase | Deliverable | Artifacts | cx/risk/eff |
|---|---|---|---|
| 1 | The principle. `GUIDING-PRINCIPLES.md` gains a numbered entry stating the rule and naming both disqualifying shapes with their instances (#351 self-regenerating, #348 self-comparing). Docs only. | `GUIDING-PRINCIPLES.md` | 1/1/1 |
| 2 | The inventory. Discovery generated from the tree; evidence declared per gate with its form (pre-fix replay / deliberate mutation / controlled bad fixture) and result, `none` where absent. Plus the regression test that detects the two disqualifying shapes. | `utils/py/gate_inventory.py`, `test/gh419-gate-inventory.sh`, `validate.sh` | 3/2/3 |
| 3 | The first child. Close **#418** under the policy — issue-state and FROZEN-banner checks in `swarm_preflight.py` — with its negative control recorded in the inventory. **Fires on its own issue**, not this one. | (tracked on #418) | 2/2/2 |

Phase 3's write-set collides with #418's by construction. **Never run them as concurrent lanes.**

## Litmus tests

- **Phase 2 must fail on itself first.** The inventory's own regression test is a decision gate. If
  it cannot be observed failing — via a fixture that is a self-comparing assertion — it is the ninth
  instance, filed by the issue that exists to prevent it.
- **A `none` must be common at first.** An inventory whose first run reports every gate as having a
  negative control is evidence the detector is broken, not that the repo is healthy.

## Swarm Preflight Contract

Scoped to **Phases 1–2 only**. Phase 3 is #418's write-set and must not appear here, or the two
lanes would collide by construction.

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [
    { "type": "grep_absent", "path": "GUIDING-PRINCIPLES.md", "pattern": "never been observed failing" },
    { "type": "path_absent", "path": "utils/py/gate_inventory.py" },
    { "type": "path_absent", "path": "test/gh419-gate-inventory.sh" }
  ],
  "artifacts":     [ "GUIDING-PRINCIPLES.md", "utils/py/gate_inventory.py", "test/gh419-gate-inventory.sh", "validate.sh" ],
  "artifacts_new": [ "utils/py/gate_inventory.py", "test/gh419-gate-inventory.sh" ],
  "remediation":   { "source": "issue#419", "criteria": "policy + evidence inventory for decision gates — ranking summary only, NOT the definition of done (that is the verbatim ## Acceptance block above)" },
  "lanes":         { "agy_safe": [], "orchestrator_only": [] }
}
```

**Probe polarity** (the field most often got wrong — probes detect the **bug**, not the fix):
`grep_absent` reports `landed` when the pattern *is found*, and `path_absent` reports `landed` when
the path *exists*. So all three probes assert the pre-fix state, and each flips to `landed` exactly
when its phase ships.

## Method note

The eight instances were confirmed against live issue state on 2026-08-04 (`gh issue view` per
number, all CLOSED except #417/#418 which are open and tracked). The three from 2026-08-03 were
found by read-only triage during the marathon-plan retirement, not by any automated check — which
is the point.
