I am searching for the files you mentioned to review their contents. I will let you know my findings shortly once the search is complete.
### (1) ANSWER
Keep `/unstuck` as a separate skill.

### (2) FINDINGS
- **[Blocker] Governance Drop (State Machine Defect):** The integration between the two skills is currently a one-way `GOTO`. `workhorse` instructs the agent to "*hand off to `/unstuck`*" (`skills/workhorse/SKILL.md:204`), and `/unstuck` concludes with "*The skill ends when movement resumes*" (`skills/unstuck/SKILL.md:125`). Because it ends and exits without returning to the parent context, the agent drops the `/workhorse` governance envelope. Any goal-moving mutation executed by `/unstuck` bypasses the Preservation Gate (`workhorse` Rung 5), and when the task finishes, the agent will skip Ledger Closeout and PDDA Reconciliation (`workhorse` Rung 6 at `skills/workhorse/SKILL.md:178`), leaving orphaned state.
- **[Should] Tie-Breaker Hang Risk:** Rung 4 of `/unstuck` permits running exactly *one* `/consult` to break a tie (`skills/unstuck/SKILL.md:99`). If the original session stalled *because* the `/consult` script is broken, hanging, or timing out, invoking it again will trap the recovery skill in the exact same loop. There should be a circuit breaker to pick the simpler path or escalate to the operator if the consult machinery itself is the failing cog.
- **[Pass] Boundary Decision:** The architectural reasoning is sound. As noted in the decision doc (`PROJECT/2-WORKING/GH-473-UNSTUCK-SKILL.md:31`), folding a meta-cognitive loop-breaker into the primary forward-execution path would bloat `/workhorse`'s healthy path. An agent needs a sharp context reset to break a stall, which a distinct skill provides.

### (3) RECOMMENDATION
Keep `/unstuck` separate, but rewrite the `workhorse` handoff to invoke it as a blocking interrupt (subroutine) rather than a one-way exit, explicitly requiring the agent to resume the parent `/workhorse` ladder (especially the Rung 6 closeout) once movement is restored.
