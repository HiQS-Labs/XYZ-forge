# GH-1484 connect-the-dots: manual checks

Manual evidence for [GH-1484](https://github.com/HiQS-Labs/XYZ-forge/issues/1484). No suite or script was added (AGENTS.md *No new tests*, GH-831). Every run used a fresh Claude subagent with no conversation history, reading a disposable clone at base `5967bde25191fc23712ed5e33d9f6ea6aa7a540f`. That clone holds no GH-1484 file. Run 0 is the exception and is discarded below.

## Update 2026-11-15: operator decision, rewritten check, runs 7 and 8

The operator accepted the skill "as a reuse map that shows its dismissals" and asked for the Elephant-Goldfish paraphrase-first lens (GH-1414) in the vetting. The plan's rewritten check no longer requires `tick` or ATE. Its five-point rubric was committed (`436e06a88`) before run 7.

**The rewritten check is partly met. Each run fully meets 3 of 5 points (1, 4 and 5).**

| Point | Run 7 (`run-7-skill-answer-free-paraphrase-first.md`) | Run 8 (`run-8-skill-answer-free-opened-files-and-count.md`) |
|---|---|---|
| 1. Three paraphrase headings before the capability list | Met | Met |
| 2. Every row cites `file:line`; every cited file was opened | **Not met.** `MARATHON-PLAN-2026-11-15.md:250` is cited in the owner column and is not in the opened list. | **Not met.** `utils/py/releases_app.py:951,4725` is cited and is not in the opened list. |
| 3. Sweep gives a verdict per subsystem; each `set aside` has a source line or `inferred` | **Not met.** The listed subsystems each have a verdict, but the sweep is incomplete: ATE is on the map (`ROUTER.md:222`) and absent. | **Not met.** The count is given (79 skills, about 10 routed subsystems); about 69 are dismissed as one group. |
| 4. No unbounded absence claim | Met | Met |
| 5. New remainder and one next action | Met | Met |

Between the runs the skill text was tightened (`5eb32e299`): every cited file must be opened, and the sweep closes with a count. Run 8 broke the citation rule again, so the tightening did not fix it. After run 8 the skill gained a closing **Files opened** list and a sentence telling the reader to check citations; that last change was not rerun.

Hand-checked against base `5967bde25`: the two unopened citations do say what the rows claim (`MARATHON-PLAN-2026-11-15.md:250` is the #1168 scheduler line; `releases_app.py:951` creates `jog_queue`, `:4725` defines `cmd_jog_add`). Also checked in run 7: `jog_run.py:2424-2432`, `harness.py:133-139`, `ARCHITECTURE.md:31-38`. Other citations were not checked.

What the paraphrase step did: both runs wrote `not stated` for "how it is handled today" and "what it's not", and carried "outer loop is not defined" into Unknowns. Runs 5 and 6 had guessed silently. One run each; not a rate.

`tick` and ATE, recorded and not graded: run 7 sets `tick` aside with a map line and omits ATE; run 8 lists `ate` as an unopened lead and does not name `tick`. Both runs again chose Jog's queue and supervisor lock.

Extra limits for these two runs: run 7's answer refers to "your notes", so the subagent saw the session's memory index, which run 8's prompt told it to ignore. The skill is run by one agent, so the paraphrase is a self-paraphrase; the fresh-reader form of the lens is the optional `consult` hand-off, which was not exercised.

## Result under the original criterion: NOT met (2026-11-14)

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
| Existing suite `test/gh589-skill-viewer.sh` on the branch | 8 passed, 0 failed at `e571fab02`, and again at `3285126df` after the later skill-text edits (disposable clone both times). | `existing-suite-summary.txt`, `existing-suite-rerun.txt` |
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
