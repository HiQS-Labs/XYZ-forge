## Problem

XYZ Forge already has independent plan and final QA reviews, recorded dispositions, and bounded review rounds. These reviews can still miss a plan whose individual terms are defined but whose overall explanation requires the author’s conversation history. The proposed improvement is to discover consequential misunderstandings before implementation, without adding another review subsystem.

## Proposal

Pilot three narrowly scoped ideas from Google’s Elephant-Goldfish Model in XYZ’s existing review process:

1. **Paraphrase first.** For the next substantial plan review, have a fresh reviewer read only the target plan, without author conversation history or supplementary source files. Before critique, return 2–5 sentences each under “What this proposes” and “How the existing system works, per this document.” Report unclear prerequisites, causal links, or consequential ambiguities. A wrong paraphrase is a signal to investigate, not automatic proof the plan is defective. The author records whether it reveals missing explanation or a reviewer error, with evidence.
2. **Make the context boundary explicit.** Keep the comprehension pass distinct from technical validation. After recording the initial paraphrase, the existing technical reviewer reads the requirements, referenced source paths, and recorded decisions. This can be a staged use of the same existing review turn; do not describe the later technical assessment as document-only. Record what material each assessment received. No author conversation history is supplied.
3. **Preserve findings and dispositions.** Keep original reviewer wording, scope, and severity, then append the author’s disposition and evidence. Accepted risks and rejected findings stay settled absent materially new evidence; a recurrence after an alleged fix reopens the finding. Use the existing relay receipt rather than a new registry.

## Scope and tradeoff

Start with one manual, advisory pilot on this proposal or the next substantial plan. Implementation candidates, after the pilot: existing plan-QA instructions in `skills/1-hourly/start-task/SKILL.md` and the existing relay review packet. Inspect the canonical prompt writer before changing it; avoid duplicating instructions across surfaces. This issue does not authorize a new review driver, mandatory stage, gate, test suite, plugin installation, or broader skill deployment.

Reversibility: **Easy** for the pilot and prompt wording; remove the optional instruction if the additional review cost produces only nits. Extending core relay execution would require a separate blast-radius assessment. The bet is that the paraphrase exposes consequential misunderstandings cheaply; failure mode is manufacturing wording churn from an artificially uninformed reader.

Do not adopt EGM’s full five-stage pipeline, seven-lens brainstorm, mandatory human checkpoints, two-clean-round requirement, or absolute zero-design-decisions rule. Resolve consequential architecture decisions up front while allowing routine implementation judgment.

## Acceptance

- [ ] Run one genuinely fresh-context, read-only comprehension review; preserve the exact input artifact, reviewer brief, paraphrase, findings, and author dispositions in an existing review/evidence location.
- [ ] Clearly distinguish the document-only comprehension result from source-backed technical validation and from merge approval.
- [ ] Record whether the pilot caught a consequential misunderstanding, its additional cost, and a retain/revise/abandon recommendation. A no-findings result is valid and is not evidence of proven benefit.
- [ ] If retained, change only the canonical existing review instructions necessary; preserve findings separately from dispositions and keep accepted-risk/reopened-fix semantics explicit.
- [ ] Verify any eventual prompt changes with existing appropriate checks; add no tests or gate machinery. This intake/pilot does not claim implementation or merge readiness.

## Sources

- https://github.com/google/elephant-goldfish-model/blob/main/agents/comprehension.md
- https://github.com/google/elephant-goldfish-model/blob/main/skills/egm-review-loop/SKILL.md
- https://github.com/google/elephant-goldfish-model/blob/main/skills/egm-resolve/SKILL.md
- XYZ existing plan QA: `skills/1-hourly/start-task/SKILL.md`, Step 6.

The requested local EGM path was unavailable in this session; source assessment used the public Google repository, assumed to be the intended project.
