# RELAY · PR 878 unstuck Agy QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-27.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 5

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(pr-878-unstuck-agy-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **SKILL.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: codex-author
- Started: 2026-09-27

### Artifact — SKILL.md
````
---
name: unstuck
description: >-
  Interrupt a stalled AI work session and restore movement toward the original
  outcome. Use proactively when the agent is passive, trapped in narration,
  halting on tool exits, or reporting activity without milestone change, as well as
  when overengineering, inventing machinery around work, or reopening settled decisions.
  Fires autonomously on self-trigger tripwires (two turns without milestone change,
  tool exit code inertia, passive waiting narration, false completion, or re-litigating a reviewed plan), and on
  operator triggers /unstuck, "we're stuck", "rabbit hole", "stop overengineering",
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

---

## Recite this — verbatim, as the first thing in your first response

> **Unstuck Discipline:**
> 1. **Freeze the cogs (Rung 1).** Immediately stop inventing machinery, abstractions, helpers, review loops, or new plans; preserve working state, and record the true requested outcome, nearest milestone, last real movement, and current time sink.
> 2. **Re-anchor the finish line (Rung 2).** State the nearest observable task milestone in one sentence (e.g. "failing test passes", "PR exists", "operator chose A vs B"); strip all self-created prerequisites from the critical path.
> 3. **Test the claimed blocker (Rung 3).** Ask *"If this item were fixed now, could the next milestone proceed?"*; strictly classify items as Goal Blocker, Required Correctness/Safety, External Dependency, Polish, or Cog; park cogs/polish and queue genuine blockers into durable intake.
> 4. **Execute foundational resolution — no bandages (Rung 4).** Select the single smallest action that resolves the true root blocker gating the milestone; strictly forbid painkillers, silencing hacks, bypassed invariants, or symptom patches that kick the can down the road (hand off to `/workhorse` if a structural fix is required).
> 5. **Act once, verify movement & exit (Rung 5).** Execute the single move, check whether the milestone itself changed, emit the structured UNSTUCK receipt, and immediately resume execution (or return to parent `/workhorse` ladder).
>
> **Overall Goal:** Stalled session interrupted and durable goal movement restored immediately via the simplest foundational action that advances the milestone, with zero added machinery, zero symptom bandages, and zero bypassed safety invariants.

Then begin work.

---
## Autonomous Trigger Tripwires

Models must self-invoke `/unstuck` as an immediate blocking interrupt when any of these tripwires fire — **do NOT wait for the operator to intervene**:

1. **Two-Turn No-Milestone Tripwire:** The agent has communicated with the operator across two consecutive turns without advancing the observable milestone (e.g. outputting progress updates, narrating next steps without executing them, asking redundant permission for an already-authorized goal).
2. **Tool Exit Code Inertia:** A CLI tool, test, or runner script exited non-zero (e.g., rc=2, rc=3), and the agent stops, narrates waiting, or asks what to do rather than diagnosing the error and executing an unblocking action.
3. **Passive Narration Detection:** The agent catches itself typing passive waiting phrases ("Waiting for the run to finish...", "Now I will wait for...", "Let me know how to proceed", "Should I continue?") on an active in-flight task.
4. **False Completion Detection:** The agent is about to report "Done" or "Complete", but the original prompt's core deliverables (e.g., merging PRs, running test suites) were bypassed or unattempted.
5. **Reviewed-Plan Re-litigation:** The agent is about to reopen a settled decision in a sound plan reviewed at least once, without identifying new contradictory evidence or an explicit changed user requirement. Interrupt immediately, before adding another review round or prerequisite; apply the reviewed-plan check in Rung 3.

## The five-rung recovery ladder

```text
1. Freeze the cogs       ──► Stop adding machinery, reviews, and scope; preserve current work
2. Re-anchor the goal    ──► Original outcome, current milestone, last verified movement  [Unverified — no citation]
3. Test the blocker      ──► Required to advance, required for safety, polish, or machinery?
4. Choose one next move  ──► Smallest bounded action that changes task state (foundational, no bandages)
5. Act, verify, re-drive ──► One action, one movement check, re-launch primary engine, explicit next state
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

**Reviewed-plan check.** Treat a sound plan reviewed at least once as the execution baseline.
Before spending more work on each reopened topic, the agent must identify, in the existing thread:

- the settled decision and its review or acceptance reference (use the existing context; do not demand a new sign-off artifact);
- what evidence or explicit user requirement changed since that decision, and which acceptance criterion, safety invariant, required gate or next milestone it affects;
- whether the plan already covers the concern, and whether the proposed response resolves the evidenced gap or merely adds ceremony.

No qualifying change, or an already-covered concern: stop re-litigating it and execute the next
accepted step. A different preference, speculative edge case or repeated reviewer objection is not
new evidence. Do not create a checklist file, new gate, recon pass or review round to prove that
nothing changed. Record the disposition briefly in the existing thread or UNSTUCK receipt.

New contradictory evidence or an explicit changed user requirement: reopen only the affected
decision and retain the rest of the plan. Diagnose a genuinely unknown failure with
[`/debug-mantra`](../debug-mantra/SKILL.md); if resolving it requires changing existing code whose
impact is not yet traced, use a bounded [`/recon`](../recon/SKILL.md) on that seam before revising the
step. These are conditional routes, not mandatory reviews of an unchanged plan. Never use prior
approval to dismiss a demonstrated failure, changed requirement or required safety check.

A fan of simultaneous genuine blockers is itself a stall signal — working them in parallel is
activity without movement. Rank them by critical path to the re-anchored milestone, act only on
the first, and file or record the rest into the work's existing durable intake (issue tracker,
queue, or ledger — never a new artifact). They are **queued**, not parked: queued items are real
outstanding work with a recorded home; parked items are cogs or polish that may never be done.
This queue rule covers blockers to the current goal. An incidental finding outside that goal goes
to root `PARKED/` under `PARKED/README.md` and may be promoted during later triage.

### Rung 4 — Choose one goal-moving action

Choose the first safe option that applies:

1. execute the already accepted plan or next committed step;
2. fix one narrow, evidenced foundational blocker, then resume the plan;
3. use an existing seam, supported command, or bounded manual bridge instead of building machinery;
4. ask the operator one crisp decision that genuinely cannot be inferred.

**No Bandages / No Painkillers Law.** Never apply temporary hacks that kick the can down the road:
- Do NOT disable tests, silence type/lint errors (`@ts-ignore`, `# noqa`, suppressed asserts), or weaken contracts to simulate progress.
- Do NOT patch call-site symptoms when the root cause is a broken invariant.
- If the blocker requires a multi-file structural or architectural remedy, do NOT apply an inline hack—transition cleanly to `/workhorse` to execute the governed 7-rung solution.

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

### Rung 5 — Act once, verify movement, re-drive the engine, exit

Take the selected action. Then check the milestone itself, not the machinery around it.

**Re-drive the primary execution engine:** For batch runners or orchestrators (`merge-cleanup`, `jog`, `marathon`), taking a micro-action (resolving a single conflict, granting a permission, deleting a stale lock) is only the first beat of the recovery. The action MUST include re-launching the primary command (e.g. re-running the orchestrator with `--resume`). The recovery is not complete and this interrupt must not exit until the autonomous execution loop is actively moving again.

Return this receipt:

```text
UNSTUCK
Goal: <original outcome>
Stall: <what was consuming motion>
Move: <single action taken or exact decision requested>
Evidence: <observable milestone change or named blocker>
Queued: <genuine blockers filed to durable intake, or none>
Parked: <non-blocking cogs/polish, or none>
Next: <one next task state>
```

If the action did not move the goal, do not invent another mechanism. Name the falsified assumption,
reclassify the blocker once, and either take the now-obvious existing path or stop on the exact
external dependency. The skill ends when movement resumes or the real blocker is legible.

If `/workhorse` invoked this skill, return to that parent ladder once movement resumes. Resume at the
appropriate rung for the action; its governance, preservation, verification, and ledger closeout
still apply. `/unstuck` is a blocking interrupt, not an escape from the parent workflow.

**Bi-directional watchdog handshake:** If the stall stemmed from a recurring defect class, architectural flaw, or broad dependency conflict, hand off to `/workhorse` for the durable root-cause fix; `/workhorse` must return by re-entering the outer driver loop rather than terminating.

## Routing boundary

- Start a complex problem from scratch with `/workhorse`.
- Minimize an implementation that is otherwise moving with `/ponytail`.
- Diagnose an unknown failure with `/debug-mantra`.
- Park scope creep and close a chapter with `/finish-line`.
- Interrupt a live process whose activity no longer advances its goal with `/unstuck`.

The shortest path back to the plan is the product.
````
- Definition of Done: Independently QA PR #878, Markdown-only unstuck change. Read the complete skill embedded above and `TESTS-RESULTS/2026-09-27+GH-854-unstuck/CHECKS.md`. Existing Codex receipt failed protocol, so this is a newly operator-authorized Agy run capped at 5 rounds. Grade instruction correctness and existing focused evidence; no full gate or empirical model-compliance claim is required. Do not request code, new tests, new process layers, ledger edits or deployment.
- Questions: (1) Does a reopened topic require identifying the reviewed decision, changed evidence/requirement and actual gap? (2) Does an already-covered concern resume the accepted step without new ceremony? (3) Can real failures and explicit changed user requirements still reopen only affected decisions? (4) Are debug-mantra and recon conditional? (5) Is the outer-workflow resumption preserved? (6) Is any statement inconsistent or unnecessary?
- Protocol: Edit only this relay. Append ONE Reviewer block immediately BEFORE the final marker, preserving all existing text and ordering except header NEXT/STATUS. No Git commands, commits, tests, file creation or GitHub writes. The harness commits. Cite file:line or quoted spans. On approval set STATUS: Approved and finish the tick task as directed by your turn prompt. Do not touch historical relay files.

### Exact skill diff from staging baseline b25584c3

````diff
diff --git a/skills/1-hourly/unstuck/SKILL.md b/skills/1-hourly/unstuck/SKILL.md
index 2c358be1..847bcc87 100644
--- a/skills/1-hourly/unstuck/SKILL.md
+++ b/skills/1-hourly/unstuck/SKILL.md
@@ -5,8 +5,8 @@ description: >-
   outcome. Use proactively when the agent is passive, trapped in narration,
   halting on tool exits, or reporting activity without milestone change, as well as
   when overengineering, inventing machinery around work, or reopening settled decisions.
-  Fires autonomously on 4 self-trigger tripwires (two turns without milestone change,
-  tool exit code inertia, passive waiting narration, or false completion), and on
+  Fires autonomously on self-trigger tripwires (two turns without milestone change,
+  tool exit code inertia, passive waiting narration, false completion, or re-litigating a reviewed plan), and on
   operator triggers /unstuck, "we're stuck", "rabbit hole", "stop overengineering",
   "the cogs are moving but the goal isn't", or "get back to the plan". Do not use
   for a new ambiguous problem that needs the full /workhorse ladder, a still-unknown
@@ -47,12 +47,14 @@ Then begin work.
 ---
 ## Autonomous Trigger Tripwires
 
-Models must self-invoke `/unstuck` as an immediate blocking interrupt when any of these 4 tripwires fire — **do NOT wait for the operator to intervene**:
+Models must self-invoke `/unstuck` as an immediate blocking interrupt when any of these tripwires fire — **do NOT wait for the operator to intervene**:
 
 1. **Two-Turn No-Milestone Tripwire:** The agent has communicated with the operator across two consecutive turns without advancing the observable milestone (e.g. outputting progress updates, narrating next steps without executing them, asking redundant permission for an already-authorized goal).
 2. **Tool Exit Code Inertia:** A CLI tool, test, or runner script exited non-zero (e.g., rc=2, rc=3), and the agent stops, narrates waiting, or asks what to do rather than diagnosing the error and executing an unblocking action.
 3. **Passive Narration Detection:** The agent catches itself typing passive waiting phrases ("Waiting for the run to finish...", "Now I will wait for...", "Let me know how to proceed", "Should I continue?") on an active in-flight task.
 4. **False Completion Detection:** The agent is about to report "Done" or "Complete", but the original prompt's core deliverables (e.g., merging PRs, running test suites) were bypassed or unattempted.
+5. **Reviewed-Plan Re-litigation:** The agent is about to reopen a settled decision in a sound plan reviewed at least once, without identifying new contradictory evidence or an explicit changed user requirement. Interrupt immediately, before adding another review round or prerequisite; apply the reviewed-plan check in Rung 3.
+
 ## The five-rung recovery ladder
 
 ```text
@@ -115,6 +117,25 @@ A review finding is not automatically blocking because a reviewer found it. Tie
 criterion, observable failure, safety invariant, or required gate. Conversely, do not relabel a real
 failure as polish merely to create motion.
 
+**Reviewed-plan check.** Treat a sound plan reviewed at least once as the execution baseline.
+Before spending more work on each reopened topic, the agent must identify, in the existing thread:
+
+- the settled decision and its review or acceptance reference (use the existing context; do not demand a new sign-off artifact);
+- what evidence or explicit user requirement changed since that decision, and which acceptance criterion, safety invariant, required gate or next milestone it affects;
+- whether the plan already covers the concern, and whether the proposed response resolves the evidenced gap or merely adds ceremony.
+
+No qualifying change, or an already-covered concern: stop re-litigating it and execute the next
+accepted step. A different preference, speculative edge case or repeated reviewer objection is not
+new evidence. Do not create a checklist file, new gate, recon pass or review round to prove that
+nothing changed. Record the disposition briefly in the existing thread or UNSTUCK receipt.
+
+New contradictory evidence or an explicit changed user requirement: reopen only the affected
+decision and retain the rest of the plan. Diagnose a genuinely unknown failure with
+[`/debug-mantra`](../debug-mantra/SKILL.md); if resolving it requires changing existing code whose
+impact is not yet traced, use a bounded [`/recon`](../recon/SKILL.md) on that seam before revising the
+step. These are conditional routes, not mandatory reviews of an unchanged plan. Never use prior
+approval to dismiss a demonstrated failure, changed requirement or required safety check.
+
 A fan of simultaneous genuine blockers is itself a stall signal — working them in parallel is
 activity without movement. Rank them by critical path to the re-anchored milestone, act only on
 the first, and file or record the rest into the work's existing durable intake (issue tracker,
````


## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Round 1 · Reviewer · agy

swept file: yes

VERDICT: PASS
Basis: The reviewed-plan check additions to /unstuck (Tripwire 5, Rung 3 "Reviewed-plan check", and description updates) correctly prevent circular re-litigation of already-reviewed plans without suppressing genuine failures or changing outer-workflow resumption contracts. Pre-existing file content was swept with no defects found, and focused evidence confirms all doc and schema checks pass with zero errors.

#### Findings vs Definition of Done & Questions
* **[Pass] Q1 — Identification requirements for reopened topic:** Under `skills/1-hourly/unstuck/SKILL.md:120-126` (`**Reviewed-plan check.** Treat a sound plan reviewed at least once as the execution baseline. Before spending more work on each reopened topic, the agent must identify, in the existing thread:`), the three necessary criteria are explicitly enforced:
  1. `- the settled decision and its review or acceptance reference (use the existing context; do not demand a new sign-off artifact);`
  2. `- what evidence or explicit user requirement changed since that decision, and which acceptance criterion, safety invariant, required gate or next milestone it affects;`
  3. `- whether the plan already covers the concern, and whether the proposed response resolves the evidenced gap or merely adds ceremony.`
  This is matched by Tripwire 5 at `skills/1-hourly/unstuck/SKILL.md:56` (`"5. **Reviewed-Plan Re-litigation:** The agent is about to reopen a settled decision in a sound plan reviewed at least once, without identifying new contradictory evidence or an explicit changed user requirement. Interrupt immediately, before adding another review round or prerequisite; apply the reviewed-plan check in Rung 3."`).
* **[Pass] Q2 — Resume accepted step without new ceremony for covered concerns:** Confirmed in `skills/1-hourly/unstuck/SKILL.md:127-130`:
  `"No qualifying change, or an already-covered concern: stop re-litigating it and execute the next accepted step. A different preference, speculative edge case or repeated reviewer objection is not new evidence. Do not create a checklist file, new gate, recon pass or review round to prove that nothing changed. Record the disposition briefly in the existing thread or UNSTUCK receipt."`
* **[Pass] Q3 — Real failures and explicit changed requirements reopen only affected decisions:** Confirmed in `skills/1-hourly/unstuck/SKILL.md:132-137`:
  `"New contradictory evidence or an explicit changed user requirement: reopen only the affected decision and retain the rest of the plan."`
  Guarded by:
  `"Never use prior approval to dismiss a demonstrated failure, changed requirement or required safety check."`
  and bounded by existing Rung 3 rules at `skills/1-hourly/unstuck/SKILL.md:162-164` (`"A newly discovered issue still blocks when it demonstrates an acceptance failure, safety invariant, or required gate; otherwise classify the new work as polish or a cog."`) and `skills/1-hourly/unstuck/SKILL.md:177-178` (`"Conversely, do not relabel a real failure as polish merely to create motion."`).
* **[Pass] Q4 — Debug-mantra and recon are conditional:** Confirmed in `skills/1-hourly/unstuck/SKILL.md:133-137`:
  `"Diagnose a genuinely unknown failure with [`/debug-mantra`](../debug-mantra/SKILL.md); if resolving it requires changing existing code whose impact is not yet traced, use a bounded [`/recon`](../recon/SKILL.md) on that seam before revising the step. These are conditional routes, not mandatory reviews of an unchanged plan."`
* **[Pass] Q5 — Outer-workflow resumption preserved:** Preserved in `skills/1-hourly/unstuck/SKILL.md:184` (`"**Re-drive the primary execution engine:** For batch runners or orchestrators (`merge-cleanup`, `jog`, `marathon`), taking a micro-action (resolving a single conflict, granting a permission, deleting a stale lock) is only the first beat of the recovery. The action MUST include re-launching the primary command (e.g. re-running the orchestrator with `--resume`). The recovery is not complete and this interrupt must not exit until the autonomous execution loop is actively moving again."`), `skills/1-hourly/unstuck/SKILL.md:203-205` (`"If `/workhorse` invoked this skill, return to that parent ladder once movement resumes. Resume at the appropriate rung for the action; its governance, preservation, verification, and ledger closeout still apply. `/unstuck` is a blocking interrupt, not an escape from the parent workflow."`), and `skills/1-hourly/unstuck/SKILL.md:207` (`"**Bi-directional watchdog handshake:** If the stall stemmed from a recurring defect class, architectural flaw, or broad dependency conflict, hand off to `/workhorse` for the durable root-cause fix; `/workhorse` must return by re-entering the outer driver loop rather than terminating."`).
* **[Pass] Q6 — Consistency and minimal necessity:** In `skills/1-hourly/unstuck/SKILL.md:8-10`, the description cleanly includes `"false completion, or re-litigating a reviewed plan"` in the list of self-trigger tripwires, exactly mirroring Tripwire 5 at line 56 and the Rung 3 guidance at lines 120-137. No conflicting, redundant, or unnecessary statements were introduced.
* **[Pass] Pre-existing file sweep (GH-268):** `swept file: yes`. Full text of `skills/1-hourly/unstuck/SKILL.md` (lines 1–218) audited. Preamble 5-rung recitation block, 5 autonomous tripwires, 5 operational rungs, receipt template, and routing boundaries are consistent with zero pre-existing defects found. Relative links `../debug-mantra/SKILL.md` and `../recon/SKILL.md` resolve to existing files.
* **[Pass] Focused evidence verification:** Verified against `TESTS-RESULTS/2026-09-27+GH-854-unstuck/CHECKS.md:6-20`, which reports `PDDA run complete: no errors` (`SUMMARY [pdda-check-frontmatter] errors=0`, `SUMMARY [pdda-check-status-table] errors=0`, `SUMMARY [pdda-check-hardcoded-paths] errors=0`, `SUMMARY [pdda-check-changelog] errors=0`, `SUMMARY [pdda-doc-ready] errors=0`) and valid skill syntax at line 27 (`"Skill is valid!"`). Markdown-only doc change confirmed classified as `route=docs`, `tier=1`.

relay closed (Approved), no further turn needed


### Attestation · relay-drive — 2026-09-28T00:48:45Z
task: RELAY-gh854-unstuck-agy
reviewer: agy
status: Approved
reviewed-head: f31460cf542c08b7c6a095ea63eb5d35fc2f5cd7
added-range: 26307+6169
added-sha256: c17cb4af2250505d565351fbd9c3c0579c2770f44ad0717865df7bb55eda18e0
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
