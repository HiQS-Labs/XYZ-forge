Review a NEW Claude Code skill being added to this repo. Read both files:

- `skill/consult/SKILL.md` — the skill definition (what it does, when to use it, the workflow).
- `relay-automation/consult.sh` — its implementation (parallel read-only fan-out to Codex + Gemini,
  defensive no-write guard, graceful per-model degrade).

Context: this repo (`tick` + relay-automation: a cross-model coordination/relay stack) may become a
**commercial paid product**. The `consult` skill is meant to be a *one-shot parallel second opinion*
("ask Codex and Gemini the same question, then reconcile"), deliberately distinct from the existing
`relay` skill (iterative 1:1 Producer↔Reviewer build loop).

Assess and give graded findings ([Blocker]/[Should]/[Nit]/[Pass]):

1. **Concept soundness:** Is "consult" a genuinely useful primitive, and is it clearly distinct from
   `relay` — or does it overlap/confuse? Would a paying user understand when to reach for which?
2. **Spec quality:** Is `SKILL.md` well-specified, honest, and complete? Does the trigger/description
   correctly scope when it fires? Anything missing, over-claimed, or ambiguous?
3. **Implementation:** Is `consult.sh` correct and safe? Look hard at: the parallel fan-out + exit-code
   collection, the defensive "advisors must not mutate the tree" revert (does it correctly preserve
   pre-existing operator WIP while reverting only NEW advisor edits?), graceful degrade, and the
   read-only guarantees per model.
4. **Commercial readiness:** What is the single most important thing to fix or add before shipping
   this as a paid feature?

Be specific and cite file:line. End with a one-line recommendation: ship as-is / ship with changes /
needs rework.
