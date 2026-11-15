# GH-1484 connect-the-dots: manual checks

Manual evidence for [GH-1484](https://github.com/HiQS-Labs/XYZ-forge/issues/1484). No suite or script was added (AGENTS.md *No new tests*, GH-831). Every run used a fresh Claude subagent with no conversation history, reading a disposable clone at base `5967bde25191fc23712ed5e33d9f6ea6aa7a540f`. That clone holds no GH-1484 file. Run 0 is the exception and is discarded below.

## Result: the headline acceptance check is NOT met

The plan required that, with the skill, a fresh agent names `tick` and ATE as candidates for the motivating problem. On clean evidence it does not.

| Run | Condition | What happened | File |
|---|---|---|---|
| 2 | Operator's wording, no skill | Names neither `tick` nor ATE. Recommends changes inside Jog, from the flywheel documents. | `run-2-red-baseline-operator-wording.md` |
| 3 | Operator's wording, skill as first written | Cites both with correct lines. **Answer-seeded:** that skill text named `tick` and ATE in its opening example. | `run-3-green-skill-operator-wording.md` |
| 5 | Operator's wording, skill copy with the example and module names removed | Produces a cited reuse table (Jog, checkpoint, conveyor, launchd installer). Names neither `tick` nor ATE. | `run-5-skill-answer-free-copy.md` |
| 6 | Same as 5, after a reverse sweep of the maps was added to the skill | `tick` is surfaced and set aside with a reason ("inner turn loop"). ATE is not listed. | `run-6-skill-answer-free-copy-with-map-sweep.md` |
| 1 | Capability wording, no skill | Names both `tick` and ATE unaided. | `run-1-baseline-capability-wording-clean.md` |
| 4 | No-match problem, skill | Partial. See below. | `run-4-adjacent-no-match.md` |

Other checks:

| Check | Verdict | File |
|---|---|---|
| Existing suite `test/gh589-skill-viewer.sh` on the branch | 8 passed, 0 failed (disposable clone, commit `e571fab02`; not rerun after the later skill-text edits). | `existing-suite-summary.txt` |
| Keyword scanner on the same problem | 0 matching helpers for both phrasings. | `prior-art-keyword-baseline.txt` |
| Rubric control | Two deliberately bad outputs rejected by the rubric. | below |

## What the runs do and do not show

- **Shown, one run each:** asked in capability verbs that mention claiming and parameter variations, an agent finds `tick` and ATE without any skill (run 1). Asked in the operator's wording, it does not (run 2).
- **Not shown:** that the skill closes that gap. With the answers removed from the skill text, the agent's own capability breakdown for "outer loop" did not include exclusive claiming across agents or variation testing, so nothing led it to `tick` or ATE (run 5). The reverse map sweep made `tick` visible, and the agent judged it the wrong layer (run 6).
- **Open question, not settled here:** whether `tick` and ATE are the right pieces for the outer loop. Runs 2, 5 and 6 independently chose Jog's lease and supervisor lock as the claim owner. The expectation that the skill should name `tick` and ATE comes from the issue, not from these runs.
- Run 3's pass shows only that an agent told the answer can retrieve and cite it correctly.

## Deviation from the approved plan: the prompt was replaced

The plan fixed a capability-worded prompt. Run on the clean clone without the skill, it already produced both modules (run 1), so under the plan's own rule it was replaced with the operator's original wording: *"I've been struggling to get the outer loop for the software flywheel going. What should we build to get it running?"*

## Rubric (fixed before grading)

An output passes only if all hold:

1. It names `tick` as a candidate, with a `file:line` inside the tick source, the capability it covers, and one material limitation.
2. It names ATE the same way.
3. Every cited file appears in the run's own "Files I actually opened" list.
4. The cited lines say what the row claims. Checked by hand against the base commit.

## Grading

**Run 2.** Fails 1 and 2.

**Run 3.** Meets all four, answer-seeded. `tick`: `src/claim.js:28-93`, limit at `src/lock.js:17-18` (reads "a hard process kill mid-claim leaves a stale lock"). ATE: `utils/ate/scripts/run_variations.py:5-27`, `skills/4-occasional/ate/SKILL.md:48,63-69` (reads "there is no implicit check-in loop"; "Every variation hard-resets and cleans `--repo`"). Lines checked by hand.

**Run 5.** Fails 1 and 2. Its table is cited and its candidates were opened; the citations were not checked by hand.

**Run 6.** Fails 1 and 2. `tick` appears in the sweep as "set aside", not as a candidate. The sweep grouped "the remaining skills" in one line instead of listing each subsystem, which the skill text asks for.

**Rubric control.** Two samples derived from run 3: with the ATE row deleted (fails 2); with the tick citation changed to `src/scope.js:167`, a file not in the run's opened list (fails 3).

**Run 4 (adjacent), partial.** No capability is given a fit and the table rows say "not found in these searches" with the searches listed. But the answer opens with "this repo has nothing that produces PDFs or embeds fonts", an unbounded absence claim that the skill forbids. `adjacent-prerun-searches.txt` holds the scope-fixing searches. After this run the skill text was tightened to forbid that opening; the tightened text was not rerun on this case.

## Run 0, discarded

Ran in the task clone and opened the GH-1484 plan, which names the expected answer.

## Limits

- One run per condition, one model family (Claude subagents in the authoring session). Output varies between runs; none of this is a rate.
- The grader is the author of the skill, in the same session.
- Runs 5 and 6 used an uncommitted answer-free copy of the skill, with a different worked example. The committed skill still carries the motivating example, so it cannot be tested on that example.
- The code graph was not exercised: the installed index does not cover the disposable clone. Every skill run reported "maps, then grep".
