Here is the independent advisory read based strictly on the current rules in `skills/workhorse/SKILL.md`.

### Scenario 1: Fast-tracking a "trivial" clone deletion
**Answer:** Refuse the fast-track request. The deletion of a clone is a destructive action, requiring the full Rung 5 preservation proof.
**Finding:** [Blocker] `skills/workhorse/SKILL.md:L198-199` — "Destructive, externally published, Costly, or One-way-door actions never fast-track, however simple the command or small the diff."
**Recommendation:** Execute the full Rung 5 preservation gate to inventory state carriers and prove preservation before proceeding.

### Scenario 2: Clean branch, but incomplete state evidence
**Answer:** Block the mutation and reject the incomplete report.
**Finding:** [Blocker] `skills/workhorse/SKILL.md:L138-139` — "Record each carrier as `checked`, `not applicable`, or `unknown`; any `unknown` blocks mutation." Furthermore, `skills/workhorse/SKILL.md:L163-164` commands: "Reject an incomplete report and run `/recon` per preservation-unproven clone before disposition."
**Recommendation:** Run a bounded `/recon` on the clone to definitively inventory the missing carriers (secondary refs, stashes, reflogs, ignored files, nested repos, sessions).

### Scenario 3: Patch equivalence vs. line-level origin requirement
**Answer:** Block the mutation. The provided evidence (patch equivalence) does not answer the specific preservation claim (origin attribution).
**Finding:** [Blocker] `skills/workhorse/SKILL.md:L149-150` — "None substitutes for another unless it answers the invariant. In particular... a clean diff is not provenance."
**Recommendation:** Require explicit provenance evidence (e.g., ancestry) to prove that the line-level origin attribution survives, as patch equivalence only proves change-set similarity (`L145-147`).

### Scenario 4: New local ref appears after preservation proof
**Answer:** Halt the move to Trash. The new ref invalidates the existing proof.
**Finding:** [Blocker] `skills/workhorse/SKILL.md:L155-157` — "Re-run the inventory and preservation checks immediately before mutation; a changed path, ref, worktree, process/session, or evidence artifact invalidates the prior proof."
**Recommendation:** Re-run the inventory and preservation checks to generate and bind a fresh proof to the current state before executing the deletion.

---

### Verdict
**Does the current skill authorize mutation in any scenario?**
**Answer:** **No.** The current `workhorse` skill explicitly forbids mutation in all four scenarios. Scenario 1 fails the Fast-Track destructive gate (`L198-199`); Scenario 2 fails the unknown carrier and repository retirement minimums (`L138-139`, `L159-164`); Scenario 3 fails the evidence-to-invariant matching requirement (`L149-150`); and Scenario 4 is blocked by proof invalidation due to changed state (`L155-157`).
