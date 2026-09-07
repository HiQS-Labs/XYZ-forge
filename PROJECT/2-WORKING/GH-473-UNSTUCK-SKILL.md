---
gh_issue: 473
source: https://github.com/HiQS-Labs/XYZ-forge/issues/473
title: "feat(skill): add /unstuck goal-movement interrupt"
status: Active
created: 2026-09-06
updated: 2026-09-06
owner: Codex
goal: give stalled AI sessions a bounded recovery ladder that restores movement toward the original outcome
doc_type: feedback
effort: 1
complexity: 2
risk: 1
phases: 1
---

# GH-473: Unstuck Skill

## Status

| What was just completed | What's next |
|---|---|
| Five-rung recovery ladder and blocking `/workhorse` interrupt implemented; consult corrections applied; skill, PDDA, RELEASES, and the 351-suite gate are green | Await operator direction on pushing the branch and opening a PR to `development` |

## Decision

Keep `/unstuck` separate from `/workhorse`.

`/workhorse` begins with an ambiguous problem and supplies a governed end-to-end method. `/unstuck`
begins later, when a method is already in flight but the session is looping, inventing machinery,
reopening settled decisions, or treating review activity as progress. Folding both into one ladder
would make workhorse heavier at its healthy path and make the interrupt harder to invoke when the
agent needs a sharp context reset.

The only workhorse change is a handoff: when successive passes produce no observable goal movement,
route to `/unstuck` instead of automatically adding another diagnostic, design, or review cycle.

## Recovery contract

The skill must:

1. restate the original outcome, current milestone, last verified movement, and exact blocker;
2. classify current activity as goal-blocking work, required safety/correctness, optional polish, or
   machinery about the work;
3. test every claimed blocker with: “If this is fixed, can the next milestone proceed?”;
4. freeze settled decisions and park non-blocking ideas without implementing them;
5. select one smallest bounded action that changes externally observable task state;
6. use at most one `/consult` for a genuine tie, ask a binary decision, and have the coordinator
   break disagreement rather than start another review loop;
7. report whether the action moved the goal and stop if a real external decision or dependency is
   still required.

Safety, preservation, explicit user scope, and real correctness failures are never dismissed as
“cogs.” The skill removes self-created process debt; it does not waive gates that protect people,
data, security, or irreversible state.

## Consult reconciliation

**TLDR:** Both advisors independently chose a separate `/unstuck` skill with a narrow workhorse
handoff. The boundary is sound after making the interrupt progress-aware and explicitly returning
to the parent governance ladder.

**Disagreements:** The advisors found different blockers rather than conflicting with each other.
Codex caught that cap exhaustion alone could interrupt a review still resolving real correctness
findings. Agy caught that a one-way handoff could drop workhorse's preservation and closeout rungs.
Both findings were adopted. Agy also flagged retrying `/consult` when consult itself is the failed
cog; the skill now falls back to the simpler safe path or asks the operator directly.

**Agreements:** Both favored separation because recovery begins from a different state than healthy
end-to-end problem solving. Both found the correctness/safety boundary necessary.

## Forward-test walkthroughs

| Scenario | Classification | Required move | Result |
|---|---|---|---|
| Four review rounds and fourteen findings resolved; the last narrow correctness fix is complete, and only launch authorization remains | Further review is a cog; operator authority is the real dependency | Ask the one launch decision; do not open round five | Pass |
| Agent proposes a new helper subsystem to automate a one-time bridge already supported by an existing command | Cog | Use the supported command and resume the accepted plan | Pass |
| A required gate still fails because the cache fingerprint can vouch for an untested path | Required correctness | Fix the narrow fingerprint defect and rerun the gate; do not wave it through as polish | Pass |

The first scenario mirrors the supplied session. The third prevents `/unstuck` from becoming a
permission slip for motion at the expense of correctness.

## Verification

- Skill validator: valid.
- PDDA full run: zero errors; 22 pre-existing warnings.
- RELEASES consistency and receipt chain: clean.
- Frozen Bash/new-Bash guard: clean.
- Full disposable-clone gate: 351/351. Three suites failed under parallel lock contention and passed
  on the runner's required isolated retry; clone identity remained unchanged.
- Consult: two advisors answered and agreed on separation. This was advisory design review, not
  runtime proof; the Codex transcript carries the harness's no-firsthand-verification marker.

## Acceptance criteria

1. Add a concise, self-contained `skills/unstuck/SKILL.md` with discriminating triggers.
2. Keep the boundary with `/workhorse`, `/ponytail`, and `/debug-mantra` explicit.
3. Add only one narrow handoff to `skills/workhorse/SKILL.md`.
4. Forward-test a review-cap loop, a proposed new helper subsystem, and a genuine unresolved blocker.
5. Pass the skill validator and relevant PDDA checks.

## Lessons Learned (For Future Agents)

1. A round cap is not a progress signal. Trigger recovery on missing qualifying movement, not the
   number alone.
2. A recovery interrupt invoked inside a governed workflow must return to that workflow; otherwise
   “getting unstuck” silently becomes a governance bypass.
3. The tie-breaker needs its own circuit breaker. Never retry the mechanism that caused the stall.
