---
gh_issue: 1414
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1414
title: "Pilot paraphrase-first plan review and explicit reviewer context from EGM"
status: "Proposed (1-INBOX — not yet active)"
created: 2026-11-10
doc_type: feedback
effort: 2
complexity: 2
risk: 1
phases: 1
---

# Paraphrase-first review pilot

## Quad Concepts

- Hidden assumptions in plans → a fresh document-only reviewer paraphrases the proposal and current system before critique.
- Missing evidence versus inherited framing → explicitly separate comprehension inputs from source-backed technical review.
- Review history drift → preserve original findings and severity alongside dispositions; distinguish accepted risks from unsuccessful fixes.

## Requested work and acceptance

Pilot three narrowly scoped ideas from Google’s Elephant-Goldfish Model in XYZ’s existing review process:

1. **Paraphrase first.** For the next substantial plan review, have a fresh reviewer read only the target plan, without author conversation history or supplementary source files. Before critique, return 2–5 sentences each under “What this proposes” and “How the existing system works, per this document.” Report unclear prerequisites, causal links, or consequential ambiguities. A wrong paraphrase is a signal to investigate, not automatic proof the plan is defective. The author records whether it reveals missing explanation or a reviewer error, with evidence.
2. **Make the context boundary explicit.** Keep the comprehension pass distinct from technical validation. After recording the initial paraphrase, the existing technical reviewer reads the requirements, referenced source paths, and recorded decisions. This can be a staged use of the same existing review turn; do not describe the later technical assessment as document-only. Record what material each assessment received. No author conversation history is supplied.
3. **Preserve findings and dispositions.** Keep original reviewer wording, scope, and severity, then append the author’s disposition and evidence. Accepted risks and rejected findings stay settled absent materially new evidence; a recurrence after an alleged fix reopens the finding. Use the existing relay receipt rather than a new registry.

## Proposed addition: “What it’s not”

Add a third short heading to the comprehension output, after “What this proposes” and “How the existing system works, per this document”: **“What it’s not.”** Use it where a consequential expectation could otherwise be mistaken; do not force filler for trivial work.

The reviewer identifies exclusions actually stated in the target document, cites their sections, and distinguishes excluded work from deferred work, unresolved choices, and actions requiring later authorization. Label inferred boundaries as inference; never invent non-goals, silently remove acceptance criteria, or treat silence as exclusion. If the document does not establish a consequential boundary, report the uncertainty rather than deciding for the author. This remains advisory comprehension evidence, not scope authority or technical approval.

### Where this belongs if adopted

Extend the existing plan-QA instructions in `skills/1-hourly/start-task/SKILL.md` (Step 6), using the existing relay review packet and receipt. Inspect the canonical prompt writer before implementation; keep the detailed rubric in one existing owner and reference it where needed. A separate EGM skill, new runtime, gate, registry, or deployed skill copy is unnecessary for this addition. This issue records the proposed modification; it does not claim those skill instructions have already changed.

### Applying the boundary lens to this modification

It is an optional comprehension aid for consequential plans. It is not an additional approval authority, a replacement for source-backed review, an instruction to manufacture critique or non-goals, or a mandatory extra reviewer turn. It does not authorize implementation, skill deployment, or changes to existing acceptance criteria.

### Applying the lens now to GH-1000 (author assessment)

**What this proposes:** Reconcile existing Storyline, Kanban, dashboard and evidence efforts, choose a small integration slice and an operator interface, and demonstrate that a real task and failure/resume case can be reconstructed from existing evidence.

**How the existing system works, per the issue:** Multiple components and projections exist, including merged building blocks and an unmerged Paperclip spike. Their shipped scope, ownership and deployed behavior still need verification. Existing task and execution records retain authority; interfaces are projections.

**What it’s not — explicit boundaries:**

- A new dashboard, knowledge graph, generic event bus or universal workflow engine built before evaluating existing work (Anti-goals).
- A new task-state database, event writer, or independent status vocabulary (Consolidation checklist and first-slice acceptance).
- Wholesale adoption of ADK/Paperclip control models, or model-derived status substituting for evidence and approval (Anti-goals).
- Authorization for automatic migration, deletion, deployment, merging or broad production changes (Scope now and Anti-goals).
- A documentation-only exercise: the checklist also asks for an actual task lifecycle and failure/resume demonstration (Consolidation checklist, section 4).

**Unresolved boundary:** “Scope now” limits current work to consolidation, evidence review and selecting a small implementation plan, while checklist section 4 requires a working demonstration. Distinguish discovery/selection from the later authorized demonstration and state what closes this umbrella. Do not silently drop the demonstration or interpret it as immediate production-change authority.

This GH-1000 application is the author’s assessment, not a new independent fresh-context reviewer result. It preserves the issue’s existing requirements and does not amend GH-1000 itself.

## Scope and tradeoff

Start with one manual, advisory pilot on this proposal or the next substantial plan. Implementation candidates, after the pilot: existing plan-QA instructions in `skills/1-hourly/start-task/SKILL.md` and the existing relay review packet. Inspect the canonical prompt writer before changing it; avoid duplicating instructions across surfaces. This issue does not authorize a new review driver, mandatory stage, gate, test suite, plugin installation, or broader skill deployment.

Reversibility: **Easy** for the pilot and prompt wording; remove the optional instruction if the additional review cost produces only nits. Extending core relay execution would require a separate blast-radius assessment. The bet is that the paraphrase exposes consequential misunderstandings cheaply; failure mode is manufacturing wording churn from an artificially uninformed reader.

Do not adopt EGM’s full five-stage pipeline, seven-lens brainstorm, mandatory human checkpoints, two-clean-round requirement, or absolute zero-design-decisions rule. Resolve consequential architecture decisions up front while allowing routine implementation judgment.

## Acceptance

- [ ] Run one genuinely fresh-context, read-only comprehension review; preserve the exact input artifact, reviewer brief, paraphrase, findings, and author dispositions in an existing review/evidence location.
- [ ] Include “What it’s not” where consequential; ground exclusions in the document and label inferred or unresolved boundaries.
- [ ] Clearly distinguish the document-only comprehension result from source-backed technical validation and from merge approval.
- [ ] Record whether the pilot caught a consequential misunderstanding, its additional cost, and a retain/revise/abandon recommendation. A no-findings result is valid and is not evidence of proven benefit.
- [ ] If retained, change only the canonical existing review instructions necessary; preserve findings separately from dispositions and keep accepted-risk/reopened-fix semantics explicit.
- [ ] Verify any eventual prompt changes with existing appropriate checks; add no tests or gate machinery. This intake/pilot does not claim implementation or merge readiness.


## Pilot already performed

A separate fresh-context reviewer paraphrased the issue draft and found no consequential ambiguity. The author found both paraphrases faithful. This is an intake demonstration, not the substantial-plan trial needed before adoption; no runtime or prompt changes were made.

Exact input and receipt: `relay-system/2026-11-10/egm-paraphrase-pilot.input.md` and `relay-system/2026-11-10/egm-paraphrase-pilot.codex.md`. Provenance: `relay-system/2026-11-10/egm-paraphrase-pilot.provenance.jsonl`. These intake artifacts are uncommitted; include them together in any later PR that cites the run.

The live issue contains source links and the reviewer paraphrases. No RELEASES row is created for this unstarted implementation capture.

## Merge evidence

- PR #1415 merged 2026-11-11 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
