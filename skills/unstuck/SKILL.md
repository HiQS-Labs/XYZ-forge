---
name: unstuck
description: >-
  Interrupt a stalled AI work session and restore movement toward the original
  outcome. Use when the agent is overengineering, inventing machinery around the
  work, reopening settled decisions, exhausting review rounds without qualifying
  progress, polishing controls after the plan is ready, or reporting lots of
  activity with no milestone change.
  Also fires on /unstuck, "we're stuck", "rabbit hole", "stop overengineering",
  "the cogs are moving but the goal isn't", or "get back to the plan". Do not use
  for a new ambiguous problem that needs the full /workhorse ladder, a still-unknown
  failure that needs /debug-mantra, or ordinary implementation minimization that
  /ponytail already covers.
metadata:
  argument-hint: "[original goal or current stalled session]"
---

# /unstuck — Goal-Movement Interrupt

`unstuck` is a mid-flight interrupt, not another planning framework. It stops a session that is
optimizing its own machinery instead of changing the state of the user's task.

The governing question is:

> **What is the smallest action that changes the original goal's observable state?**

Activity is not movement. More findings, helpers, review rounds, scaffolding, or stronger controls
do not count unless they enable the next milestone or prevent a demonstrated correctness or safety
failure.

## The five-rung recovery ladder

```text
1. Freeze the cogs       ──► Stop adding machinery, reviews, and scope; preserve current work
2. Re-anchor the goal    ──► Original outcome, current milestone, last verified movement
3. Test the blocker      ──► Required to advance, required for safety, polish, or machinery?
4. Choose one next move  ──► Smallest bounded action that changes task state
5. Act, verify, exit     ──► One action, one movement check, one explicit next state
```

### Rung 1 — Freeze the cogs

Pause invention before diagnosing the stall. Do not add a helper, abstraction, cache, wrapper,
review round, orchestration layer, new plan, or new acceptance gate during this rung. Do not discard
working changes either.

Record four lines:

- latest authoritative requested outcome, including subsequent user changes;
- current milestone;
- last action that measurably advanced it;
- activity consuming time now.

A cap exhausted **without qualifying movement** is a boundary, not an invitation to raise the cap.
Cap exhaustion alone is not proof of a stall: if the governing workflow grants bounded extensions
while evidenced correctness findings are still being resolved, honor that policy. A settled
decision stays settled unless new evidence contradicts it.

### Rung 2 — Re-anchor the finish line

State the nearest observable milestone in one sentence. It must describe changed task state, such
as “the accepted plan is launched,” “the failing test passes,” “the PR exists,” or “the operator has
chosen between A and B.” “Improve the helper,” “make the review cleaner,” and “investigate further”
are activities, not milestones.

List only what must be true for that milestone. Preserve explicit user requirements and repository
gates; delete self-created prerequisites from the critical path.

### Rung 3 — Test the claimed blocker

For every claimed blocker, ask:

> **If this item were fixed now, could the next milestone proceed?**

Then ask whether required evidence exposed the blocker or optional activity begun after the stall
manufactured it. A newly discovered issue still blocks when it demonstrates an acceptance failure,
safety invariant, or required gate; otherwise classify the new work as polish or a cog.

Classify it from evidence, not discomfort:

| Class | Meaning | Disposition |
|---|---|---|
| Goal blocker | Its absence directly prevents the next milestone | Fix the narrow blocker |
| Required correctness or safety | A failing check, violated contract, data-loss/security risk, or explicit gate | Satisfy it or name the exact external dependency; never dismiss it as a cog |
| External decision or dependency | Progress genuinely requires authority, input, credentials, or outside state | Ask one exact question or name the dependency |
| Polish | Improves confidence or elegance but does not gate the milestone | Park it |
| Cog | New machinery, process, or review about doing the work | Stop it and use the existing path |

A review finding is not automatically blocking because a reviewer found it. Tie it to an acceptance
criterion, observable failure, safety invariant, or required gate. Conversely, do not relabel a real
failure as polish merely to create motion.

A fan of simultaneous genuine blockers is itself a stall signal — working them in parallel is
activity without movement. Rank them by critical path to the re-anchored milestone, act only on
the first, and route the rest to the work's existing durable intake (issue tracker, queue, or
ledger — never a new artifact). They are **queued**, not parked: queued items are real outstanding
work with a recorded home; parked items are cogs or polish that may never be done.

### Rung 4 — Choose one goal-moving action

Choose the first safe option that applies:

1. execute the already accepted plan or next committed step;
2. fix one narrow, evidenced blocker, then resume the plan;
3. use an existing seam, supported command, or bounded manual bridge instead of building machinery;
4. ask the operator one crisp decision that genuinely cannot be inferred.

**Recurrence tripwire.** A narrow fix stops being the smallest move the second time the same
*class* of blocker appears: a repeated narrow fix is symptom relief with a demonstrated failure
rate. If the ledger, changelog, or issue history shows this blocker's class was narrowly fixed
before, hand the thread to `/workhorse` for the durable root-cause fix — or file the gap and take
the bounded bridge once, explicitly labeled a bridge, not a fix.

Do not produce a new multi-step plan unless the old one is invalidated by evidence. Park optional
ideas in the current thread or existing project document; do not create a new artifact merely to
park them.

If two plausible paths remain and the choice materially affects the outcome, run **one** `/consult`
with a binary question: “Which option advances the stated milestone with fewer new assumptions?”
The coordinator breaks the tie. Do not retry if consult failed or is part of the stall; choose the
simpler safe path or ask the operator directly. No review of the review and no cap extension.

Before acting, retain normal authorization and safety boundaries. `/unstuck` removes self-created
process debt; it never grants permission to push, publish, delete, spend money, bypass a gate, or
perform an irreversible operation.

### Rung 5 — Act once, verify movement, exit

Take the selected action. Then check the milestone itself, not the machinery around it.

Return this receipt:

```text
UNSTUCK
Goal: <original outcome>
Stall: <what was consuming motion>
Move: <single action taken or exact decision requested>
Evidence: <observable milestone change or named blocker>
Queued: <genuine blockers routed to durable intake, or none>
Parked: <non-blocking cogs/polish, or none>
Next: <one next task state>
```

If the action did not move the goal, do not invent another mechanism. Name the falsified assumption,
reclassify the blocker once, and either take the now-obvious existing path or stop on the exact
external dependency. The skill ends when movement resumes or the real blocker is legible.

If `/workhorse` invoked this skill, return to that parent ladder once movement resumes. Resume at the
appropriate rung for the action; its governance, preservation, verification, and ledger closeout
still apply. `/unstuck` is a blocking interrupt, not an escape from the parent workflow.

## Routing boundary

- Start a complex problem from scratch with `/workhorse`.
- Minimize an implementation that is otherwise moving with `/ponytail`.
- Diagnose an unknown failure with `/debug-mantra`.
- Park scope creep and close a chapter with `/finish-line`.
- Interrupt a live process whose activity no longer advances its goal with `/unstuck`.

The shortest path back to the plan is the product.
