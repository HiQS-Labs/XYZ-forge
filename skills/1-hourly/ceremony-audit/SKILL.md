---
name: ceremony-audit
description: >-
  Audit a plan or task for meaningful progress versus ceremony. Name the goal and the one question
  the evidence has not answered yet, then label every planned step progress, proof, safety or
  ceremony, cut the ceremony, and return the smallest next step that changes goal state. Prefers one
  real run over any proxy (soak, dry run, validator) that only stands in for it. Trigger on "no
  ceremony", "is this meaningful progress", "are we just building machinery", "audit this plan for
  ceremony", "ceremony audit". Also self-trigger when a plan's verification or test sections outgrow
  its delivery sections. Not for one blocker (sanity-check), shrinking one mechanism (ponytail), or
  whether to continue the whole effort (worth-it).
---

# Ceremony audit

A plan can be busy and still not move. Steps that re-prove a known result, or build machinery that no
decision reads, feel like diligence and cost hours. This skill asks one question of every step:
**does it change goal state, or only produce activity?**

## When to run it

- The operator asks for it, or says "no ceremony".
- A plan's verification, soak, harness or controls sections are longer than the part that delivers.
- A plan re-runs something whose result is already recorded.

Skip it for a plan of one or two obvious steps. Auditing those is itself ceremony.

## Step 1 — Goal and the open question

Write two lines before judging any step:

- **Goal:** the end-user or operator outcome, in one line. If your goal line names a component the
  plan itself builds (an adapter, an arm, a harness), you have copied the plan's framing: rewrite it
  as the outcome that component is for, usually the parent issue's goal.
- **Open question:** the one load-bearing thing nobody has shown yet. Cite the evidence that the
  rest is already shown: a run, a receipt, a merged PR, a line in the plan itself.

If you cannot cite evidence that something is proven, treat it as open. "Probably works" is not
evidence. If there are two open questions, name both and say which one the next decision hangs on.

## Step 2 — Label every step

Give each planned step exactly one label:

| Label | Meaning |
|---|---|
| **progress** | It changes goal state: something now exists, runs or ships that did not. |
| **proof** | It answers the open question from Step 1. |
| **safety** | A control that protects data, security, reversibility or a required gate. Never cut. |
| **ceremony** | It re-proves something already shown, or adds machinery no decision depends on. |

The test for ceremony: **if this step were deleted, would the outcome or the next decision change?**
If neither changes, it is ceremony. Apply it to the step, not to its topic: a crash test is safety
when crash recovery is unproven and the plan depends on it, and ceremony when recovery is already
shown and nothing downstream reads the new result.

- Machinery built only so the plan can test itself (an adapter, harness, staged handoff, fault
  injector) is ceremony unless the goal still needs it after the test.
- A check that gates the next action (run before pushing, merging or launching) changes the next
  decision, so it is not ceremony even if a later run repeats it.
- Cut only what costs real time or attention. A step that takes seconds, or is already done, is not
  worth a line in the cut list.

Group small sub-steps that stand or fall together. Do not invent steps the plan does not contain.

## Step 3 — Real run over proxy

One real execution on the main path answers more than any number of stand-ins for it. For each
proof step, ask whether it is the real thing or a proxy: a timed soak, a dry run, a simulated
failure, a validator, a synthetic dataset, an adapter built only to feed a test.

When it is a proxy, name it and name the real run it stands in for. Keep the proxy only if the real
run is unsafe, irreversible or unavailable right now, and say which. Otherwise propose the real run,
smallest first: one item, one lane, one tenant. A real run that needs the operator's approval is
still the next step, gated on that approval; a pending approval never makes the proxy the end point.

## Step 4 — Verdict

Plain English, no scores. Exactly these parts:

1. **Goal / open question:** the two lines from Step 1.
2. **Cut:** each ceremony step, with the one-line reason (what it re-proves, or that nothing reads it).
3. **Kept:** each progress, proof and safety step, with the one-line reason.
4. **Next step:** the smallest step that changes goal state, with its gating condition in the same
   line ("after the operator approves", "once the dry run is clean").
5. **Parked:** a count of out-of-scope ideas, not a list.

Scheduling, stop and approval calls belong to the operator. Write them as questions ("Run the real
lane now, or after the review?"), never as decisions the skill has made.

An empty cut list is a valid result. Say "nothing to cut" and give the next step.

## Composition

Link, do not restate:

- Is one blocker real, or is one guard needed? [`sanity-check`](../sanity-check/SKILL.md).
- A kept step is right but over-built? Shrink it with [`ponytail`](../ponytail/SKILL.md).
- Is the whole effort still worth continuing? [`worth-it`](../../3-weekly/worth-it/SKILL.md) continuation mode.

This skill decides which steps stay. Those decide how big a kept step is, whether one blocker is
real, and whether the effort continues at all.

## Counter-example — nothing to cut

Plan: rename a misleading config key in its one reader and its one default file; run the existing
suite that loads that config; note the rename in the changelog.

Verdict: goal is the clearer key with nothing broken; open question is whether anything else reads
the old name, which the plan's search for the key answers. Both edits are progress, the suite run
and the search are proof, the changelog line is safety for anyone holding the old name. Cut:
nothing. Next step: open the PR. Adding a migration shim or a new test for one rename would be the
ceremony here; the plan was right not to.

## What success looks like

The verdict is shorter than the plan it audits, every cut names what it re-proved, and the next step
is something a person could start today.
