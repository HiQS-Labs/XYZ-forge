---
Goal: Final QA — GH-593 implementation (radar re-scores whack-a-mole umbrellas)
Date: 2026-09-13
Producer: claude-a
Reviewer: codex
NEXT: Producer
STATUS: Approved
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

## Reviewer — codex

**Changes requested: two P2 contract gaps, plus one P3 witness correction.** The window, membership and arithmetic corrections from plan QA are implemented. The remaining fixes fit the existing two skills and witness; no new subsystem is needed.

Evidence boundary: static review of the supplied working-tree copies of the complete plan, both skills, WITNESS.md, CHANGELOG's top entry, and the last two plan-QA turns. No graph tools are exposed; these are direct, line-numbered Markdown reads. No git command, project script, artifact, test suite, remote query or scoring run was executed. Thus historical GitHub events and commit classifications below are adjudicated from the witness's stated inputs, not independently fetched; committed-state identity and the complete branch diff are not independently attested. Reversibility of the requested prose fixes: Easy.

Citation keys: **P** = `PROJECT/2-WORKING/GH-593-RADAR-UMBRELLA-RESCORE.md`; **W** = `skills/whack-a-mole/SKILL.md`; **R** = `skills/radar/SKILL.md`; **V** = `relay-system/2026-09-13/gh593-plan-qa/WITNESS.md`. All line numbers refer to this review's input.

1. **Plan ↔ implementation — partial (P2 F1).** The six steps map as follows:

   | Plan step | Implementation evidence | Result |
   |---|---|---|
   | 1. Signature, semantics, refusal, report, edge case | W:160–185,211–213,239,247 | Present, but the rendered-body fence is missing; F1 below |
   | 2. Three no-target clauses | R:37–40,319,387–389 | OK; all three explicitly admit umbrella-only runs |
   | 3. Signal 8 | R:176–210 | OK; signals 1–8 start at R:123,136,145,146,154,156,163,176, contiguously |
   | 4. Sink B section and states | R:461–485 | Row present; state coverage needs F2 below |
   | 5. Boundaries row | R:515 | OK |
   | 6. CHANGELOG entry | CHANGELOG.md:5–7 | OK; entry under 2026-09-13 |

   R:467 matches P:204 verbatim, including the issue, filed/run, now/window, merged-date/PR-or-not-yet fields and state alternatives. The reopening recommendation and solved extension are named in the state bullets at R:476–481; metadata stays on the continuation line.

   **F1 — P2: the template does not actually contain the required fenced signature in the issue body (W:127–170 versus W:172–173,211–213; V:105).** The only opening fence is the outer `markdown` fence at W:127, and its only closing fence is W:170. Copying its contents as the issue body produces a heading and unfenced key lines. Keeping that outer fence instead makes the entire issue a code block, defeating the rendered remediation checklist required at W:125. Neither is the promised body with a fenced signature. Fix: use a four-backtick outer presentation fence and an inner triple-backtick fence around the signature keys, with its heading outside the inner fence. Show the resulting body in the witness and then remove the inner block/key for the negative controls. The current witness merely says a fenced block was rendered without supplying a rendering that resolves this contradiction.

2. **Contract consistency — counting OK; state coverage needs P2 F2.** W:190–208 and R:197–206 agree on inclusive window bounds intersected with strictly-after-cutoff, two-signal membership gating every count, raw fields, and the default formula. W:177–179 and R:201–204 agree that custom filing weights affect baseline comparability only. Radar owns the cutoff source and invalidation at R:192–196, legacy handling at R:186–191,471–473, and streak/reset conditions at R:479–485; W:213,239 references that retirement contract without a competing rule. The original producer scoring table W:85–90 and the explicitly later-measurement rules W:187–208 have different scopes; this review does not treat that as a new cross-skill mismatch.

   **F2 — P2: an open umbrella with a merged fix and post-cutoff score ≥5 has no legal state (R:474–481; V:77).** It fails `holding`'s stated alternatives (below 5 or no fix merged), fails `class survived`'s closed-umbrella condition, and cannot be solved. V's D case explicitly chooses `holding` when the umbrella is open, but that result does not follow from R. An unavailable score with an existing cutoff similarly needs an explicit unresolved state (V:87). Cheapest fix preserving the plan's closed-only reopening recommendation: define holding as the unresolved fallback whenever neither survived nor solved applies, explicitly including an open umbrella with active post-fix churn and unavailable evidence. Remove the claim that holding means the class is not proven alive; the displayed score may establish otherwise. Keep quiet credit at 0 for active/unavailable observations and keep the operational-evidence veto. Pin D's open/closed umbrella alternatives against that definition.

3. **Witness validity — arithmetic OK on the stated evidence; F1/F2 and P3 F3 need correction.** V:45–49 supplies two signals per admitted member: link plus path/error for the four issues, path plus error for `e30ceb86`. If V:53's eight other commits have only path overlap as stated, they are adjacency under W:75,194–202. One admitted fix contributes no repeat fix; four issues plus that commit give size 5. Sep 4 01:23Z to Sep 13 23:59Z is 9 complete days (plus 22h36m), so the integer-day reading gives `open_days=9`; score is `5 + floor(2/5) + floor(9/7) = 6`. Even fractional elapsed days would leave the score unchanged. V:63's `holding`, legacy baseline and zero quiet credit are correct with no cutoff.

   A derives 5; A′ derives 4 after removing #584's only countable event; B derives 0 after moving the cutoff; C derives 0 and C-neg derives the intentionally wrong 4 under the old interval. D's independent Aug 30–Sep 13 fixture now derives 14 raw days and score 9, closing the prior plan-QA age-input objection; its open-umbrella rendering is F2. E correctly keeps default score 5 despite custom filing weights. Quiet credit in A′/B and the observation table presumes a real signature in the synthetic umbrella, the stated valid cutoff, and no operational veto, rather than #591's reconstructed legacy baseline. The two previous plan-QA fixture corrections are present at P:238–248 and V:75–77.

   **F3 — P3: correct F's rejection rationale (V:79).** Rejecting the mutated solved row is right, but “A has neither” is false: A supplies the Sep 1 fix cutoff and therefore assumes a merged fix. It lacks `quiet 2/2` and scores 5. Replace the rationale with that precise failing prerequisite; do not remove A's cutoff.

4. **Witness-driven fixes — OK for the supported title convention.** R:180–185's case-insensitive prefix matches W:235's actual create title (and W:128's title template), including lowercase #591. Both skills now gate repeat fixes and reverts through membership (W:194–202; R:197–200). A title-conforming umbrella is not excluded. The prefix is a convention, not proof of provenance: renamed/imported umbrellas could be missed, and another tool could reuse that prefix. No supplied example establishes either collision; broadening reconstruction to every title containing “umbrella” would reintroduce the demonstrated false matches. This is a disclosed scope limit, not an additional blocking request.

5. **Guardrails — OK.** R:29–32 retains the two-sink boundary; R:473,478 explicitly forbids editing/reopening the umbrella; R:490 keeps one confirmation. W:14–15 retains git read-only and the single approved issue write; W:223,247 allows proposed text without posting to an existing issue. No new authorization to close, reopen or edit an umbrella appears. Sink B's existing live radar-issue edit/comment remains an authorized sink action.

6. **Duplicate subsystem — OK within the inspected implementation; complete-diff limitation above applies.** W:172–208 supplies the counting contract; R:197 cites it and R:207–210 keeps umbrella rows out of the ordinary target formula at R:234–240. Persistence remains R:405 and R:424. No new executable, table, third sink or parallel write path is introduced by these skill instructions. V:110 explicitly discloses the existing intake `releases.sql` change; that is not a claimed new scoring table. Without git inspection, this is not an exhaustive attestation of all changed branch paths.

7. **Rating and state — OK as a scope estimate, not merge readiness.** The bounded prose implementation and hand witness still fit P:292–304's `60/55/50/80`, with effort 80 meaning cheapness. P:31 accurately leaves final QA, gate-backed push and a PR against development outstanding; it does not claim landing. V:109 and CHANGELOG.md:7 report the producer's docs gate result, not a reviewer rerun; V:110 defers the pre-push result. The rendering/state corrections above remain owed before approval, and the harness/operator still owns gate and publication evidence.

Disposition: apply F1 and F2, correct F3, and update the witness accordingly. No source or artifact changes were made in this review. Returning the token to claude-a; this verdict does not authorize another automated review round or any publication.

VERDICT: Changes requested

## Producer — claude-a (round 1 adjudication)

Questions 2 (counting), 4, 5, 6, 7: OK per reviewer. F1, F2, F3 accepted and applied:

- **F1** — `skills/whack-a-mole/SKILL.md` §6: outer presentation fence is now four backticks; the Cluster signature keys sit in their own triple-backtick fence with the `### Cluster signature` heading outside it; the semantics paragraph says so. WITNESS.md "Template violation check" now shows the rendered tail of the body with the inner fence, then the two negative controls (block deleted; `signals:` line deleted).
- **F2** — `skills/radar/SKILL.md` Sink B: `holding` is now the explicit fallback — every observation that is neither `class survived` (closed + ≥ 5) nor `solved`, including an open umbrella whose fix merged but still scores ≥ 5, and unavailable evidence; active/unavailable observations earn 0 quiet credit and reset the streak. The "not proven alive" phrase is gone. WITNESS.md case D now pins both renderings against that definition.
- **F3** — WITNESS.md case F rationale corrected: A has the 2026-09-01 cutoff (a merged fix) but scores 5 → `quiet 0/2`; it lacks `2/2`, not the cutoff.

Round 2: confirm F1–F3 closed or cite the remaining line. Then `VERDICT:`.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Reviewer — codex

**Round 2 — Approved. F1, F2 and F3 are closed in the actual artifact text.** No remaining blocking finding in this requested correction review.

**Basis: textual only; non-executable skill instructions.** Re-read the revised template, counting contract, radar state definitions and witness directly, and checked the plan and prior dispositions. No graph tools are exposed; these Markdown checks use line-numbered source reads. No git command, project script, artifact execution, gate or remote query was run. Historical evidence and gate results remain producer-reported; this approval does not independently attest the commit identity, complete branch diff, or merge readiness. Only this relay file was edited.

Citation keys retain their definitions from round 1: W = whack-a-mole skill; R = radar skill; V = WITNESS.md; P = implementation plan.

1. **Plan ↔ implementation — OK; [Pass] F1 closed.** W:125–127 now separates the outer four-backtick presentation fence from the issue body. W:160–172 puts all nine signature keys in an inner triple-backtick block with the heading outside it; W:174–175 explicitly defines that layout. The remediation checklist at W:140–145 remains outside the inner fence. V:105–127 supplies the matching body tail and both deleted-block/deleted-key controls. The step 1 mapping is now complete (W:160–215,241,249). Steps 2–6 remain at R:37–40,319,387–389; R:176–210; R:461–490; R:519; CHANGELOG.md:5–7 respectively. R:467 still matches P:204 exactly, including the named reopening and solved extensions.

2. **Contract consistency — OK; [Pass] F2 closed.** R:474–479 now defines `holding` as the fallback when neither survived nor solved applies. It explicitly covers an open umbrella with a merged fix and score ≥5, and unavailable observations; both active and unavailable observations reset quiet credit. R:480–489 preserves the closed-only reopening recommendation and the merged-fix plus two-distinct-date quiet requirement. R:195–196 retains the operational-evidence veto, and R:471–473 retains the legacy restriction. W:192–210 and R:197–206 still agree on interval, membership, raw counts and default arithmetic. No new contradiction introduced by the correction.

3. **Witness validity — OK on stated inputs; [Pass] F3 closed.** V:77 now gives both legal states for D: closed → survived; open → holding; score 9 → quiet 0/2. V:87's unavailable observation now has an explicit fallback in R:474–479. V:79 correctly says A has a merged-fix cutoff but score 5 and quiet 0/2, so it lacks the required 2/2. The #591 calculation remains `size=5, comments=2, open_days=9` → `5+0+1=6`, holding without a cutoff (V:45–66); A/A′/B/C/C-neg/D/E remain 5/4/0/0/4/9/5 under the stated fixtures. Membership and excluded-commit classifications remain conditional on the witness's supplied evidence, as in round 1.

4. **Witness-driven fixes — OK.** W:237 and R:180–185 agree on the supported `Umbrella:` title convention; W:196–204 and R:197–200 retain membership gating for every count. Round 1's disclosed renamed/imported-title limitation remains; no additional scope change is needed for F1–F3.

5. **Guardrails — OK.** The correction adds no write authority. R:29–32,473,480–482 retains the two sinks and no umbrella edit/reopen; the template correction changes formatting, not whack-a-mole's filing permissions.

6. **Duplicate subsystem — OK within the inspected prose scope.** These corrections remain in the existing template, state bullets and witness. No new scoring formula, persistence destination or executable is called for; the complete-diff evidence limit above still applies.

7. **Rating and state — OK.** P:292–304's `60/55/50/80` remains appropriate for the bounded prose scope. P:31 correctly left this final QA, gate-backed push and PR outstanding at review entry. This turn completes final textual QA; push, PR and final gate evidence remain the producer/harness's work (V:129–132), not outcomes claimed here.

Disposition: F1 and F2 textually fixed; F3 witness rationale corrected. Marking the relay Approved and completing its token with `done`; the harness owns the file-scoped commit and subsequent gate.

VERDICT: Approved

### Attestation · relay-drive — 2026-09-13T05:30:04Z
task: RELAY-gh593-final-qa
reviewer: codex
status: Approved
reviewed-head: 27e036dba8c925cd21c5ffb7d2835239537cf104
added-range: 14434+4290
added-sha256: 3af01c86c330345500dc71e622e829d733f9a9fe9441ba54349fe9ccef83da18
