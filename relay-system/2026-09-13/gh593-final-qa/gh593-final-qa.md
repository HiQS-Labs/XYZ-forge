---
Goal: Final QA — GH-593 implementation (radar re-scores whack-a-mole umbrellas)
Date: 2026-09-13
Producer: claude-a
Reviewer: codex
NEXT: Reviewer
STATUS: Open
---

# Context

Adjudicate the **committed implementation** of GH-593 against its plan and witness. Review turn only — read, adjudicate, write your verdict; do not edit.

Read in full:
- `PROJECT/2-WORKING/GH-593-RADAR-UMBRELLA-RESCORE.md` — the plan (you reviewed it over four rounds in `relay-system/2026-09-13/gh593-plan-qa/gh593-plan-qa.md`; read that thread's last two turns for your own open item)
- `skills/whack-a-mole/SKILL.md` — §6 template now carries `### Cluster signature` + counting rules; §7 report line; Edge cases
- `skills/radar/SKILL.md` — Guardrails, Step 2 signal 8, Step 4 all-clear, Step 5 skip + `## Umbrellas — re-scored`, Boundaries table
- `relay-system/2026-09-13/gh593-plan-qa/WITNESS.md` — the hand-run witness (this becomes the PR body)
- `CHANGELOG.md` top entry

The requirements are in the plan's "Asks" (from issue #593) and its acceptance list.

## Questions

1. **Plan ↔ code.** For each of the plan's implementation steps 1–6, cite the `file:line` in the committed skills that implements it, or name the step as missing/partial. In particular: are all three no-target clauses amended (Guardrails, Step 4, Step 5)? Is signal 8 numbered contiguously after 7? Does the Sink B row's first line match #593's core `#<n> — filed at <score> (<run>), now <score> (<window>), fix merged <date + PR | not yet> → holding | class survived` token for token, with `— recommend reopening` and `| solved` as named extensions?
2. **Contract consistency.** Compare whack-a-mole's counting rules (§6) with radar's signal 8 and Sink B text. Is there any rule stated differently in the two files (interval bound, cutoff source, membership gating, default weights, raw-vs-points arithmetic, streak reset conditions, legacy handling)? Cite both sides of any mismatch.
3. **Witness validity.** Check WITNESS.md's #591 arithmetic against the rules as written: are the five members correctly admitted under the two-signal rule, are the eight excluded `fix:` commits correctly adjacency, is `open_days=9` right for #421 (created 2026-09-04, window end 2026-09-13), is score 6 right, and is `holding` (not `class survived`) the correct state for an open umbrella with no cutoff? Check red controls A, A′, B, C, C-neg, D, E, F derive from their stated inputs under the rules as written — flag any that do not.
4. **Witness-driven fixes.** The witness surfaced two contract gaps that were fixed in text after the plan: (a) discovery restricted to titles beginning `Umbrella:`; (b) membership gates `repeat_fixes`/`reverts`. Are these correctly reflected in **both** skills? Is (a) too narrow — would it exclude a legitimate whack-a-mole umbrella — or too broad?
5. **Guardrails.** Does anything in the new radar text authorize a write beyond the two sinks, or an issue close/reopen/edit? Does anything in the new whack-a-mole text break its non-negotiables (git read-only, one issue per run, never edit existing issues)?
6. **Duplicate subsystem check.** Did a script, DB table, third sink, second scoring formula for non-umbrella targets, or parallel write path slip in?
7. **Rating and state.** Plan says `rated 60/55/50/80`; does the implemented scope still match that (effort = cheapness)? Is the plan's Status row truthful about what is done vs owed (push, PR, gate result)?

Write your verdict as `## Reviewer — codex`: per question `OK` or a concrete finding with `file:line` and the fix. Finish with `VERDICT: Approved` or `VERDICT: Changes requested`; set `STATUS: Approved` on approval, else `NEXT: Producer`.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
