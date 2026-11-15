# GH-1484 connect-the-dots: manual checks

Manual evidence for [GH-1484](https://github.com/HiQS-Labs/XYZ-forge/issues/1484). No suite or script was added (AGENTS.md *No new tests*, GH-831). Every run used a fresh Claude subagent with no conversation history, reading a disposable clone at base `5967bde25191fc23712ed5e33d9f6ea6aa7a540f`. That clone holds no GH-1484 file. Run 0 is the exception and is discarded below.

## Result

| Check | Verdict | File |
|---|---|---|
| Red: operator's own wording, no skill | **Missed as required.** Names neither `tick` nor ATE. | `run-2-red-baseline-operator-wording.md` |
| Green: same wording, skill text supplied | **Pass.** Cites both, each with capability and a material limit. | `run-3-green-skill-operator-wording.md` |
| Rubric control: two deliberately bad outputs | **Both rejected** by the same rubric. | this file, below |
| Adjacent: a problem with no match | **Pass.** "Not found in these searches", searches listed, no invented fit. | `run-4-adjacent-no-match.md`, `adjacent-prerun-searches.txt` |
| Keyword scanner on the same problem | 0 matching helpers for both phrasings. | `prior-art-keyword-baseline.txt` |

## Deviation from the approved plan: the prompt was replaced

The plan fixed a prompt written in capability verbs with no repo nouns ("an unattended overnight loop that claims tasks so two agents never collide, runs parameter variations…"). Run on the clean clone **without** the skill, that prompt already produced `tick` and ATE with citations (`run-1-baseline-capability-wording-clean.md`). Under the plan's own rule ("if the baseline already finds both, the prompt is too easy: replace it"), it was replaced.

The replacement is the operator's original wording: *"I've been struggling to get the outer loop for the software flywheel going. What should we build to get it running?"* Plan review had advised against the word "flywheel" as a likely leak. The runs show the opposite: the word anchors the agent on the flywheel documents and it never reaches `tick` or ATE.

What this pair of baselines shows: the capability-worded question finds the modules unaided, and the noun-worded question does not. The skill's first step is the conversion between the two. This was observed, not designed for, and rests on one run of each.

## Rubric (fixed before grading)

An output passes only if all hold:

1. It names `tick` as a candidate, with a `file:line` inside the tick source, the capability it covers, and one material limitation.
2. It names ATE the same way.
3. Every cited file appears in the run's own "Files I actually opened" list.
4. The cited lines say what the row claims. Checked by hand against the base commit.

## Grading

**Run 2 (red).** Fails 1 and 2: no mention of `tick` or ATE anywhere in the answer. It recommends changes inside Jog and the landing flow, from the flywheel plan documents.

**Run 3 (green).** Passes all four.

- `tick`: `src/claim.js:28-93`, `src/take.js:23-68`; capability "claim work so no second agent takes it"; limit "per-clone and a hard kill leaves a stale lock (`src/lock.js:17-18`)". Checked: `claim()` begins at `src/claim.js:30`; `src/lock.js:17-18` reads "a hard process kill mid-claim leaves a stale lock. Recovery is `rm <repo>/.tick/locks/claim.lock`".
- ATE: `utils/ate/scripts/run_variations.py:5-27`, `skills/4-occasional/ate/SKILL.md:48,63-69`; capability "run variations unattended"; limit "hard-resets its target repo; has no check-in loop of its own". Checked: SKILL.md:48 reads "there is no implicit check-in loop"; :63 reads "Every variation hard-resets and cleans `--repo`".
- All cited files are in its opened list. It graded ATE `pattern only` and `tick` as secondary to Jog's lease for a serial loop: the fit judgement is the agent's and is not graded here.

**Rubric control.** Two bad samples derived from run 3, graded with the same rubric:

- *Sample A: run 3 with the ATE row deleted.* Fails 2.
- *Sample B: run 3 with the tick row's citation changed to `src/scope.js:167`.* Fails 3: `src/scope.js` is not in run 3's opened list.

**Run 4 (adjacent).** No capability is given a fit. One row is `pattern only` (an HTML export function, read at the cited lines); the rest are "not found in these searches", with the searches listed. `adjacent-prerun-searches.txt` holds the scope-fixing searches run before the case was frozen: `pdf`, `embedded font`, `reportlab`, `weasyprint` return nothing in the corpus; `invoice` returns CI config, a test fixture and gate baselines.

Observation, not a failure: two "not found" rows in run 4 still name a module in the module column to show what was ruled out. The skill text does not say whether that column should be empty on such rows.

## Run 0, discarded

`run-0-baseline-capability-wording-contaminated.md` ran in the task clone and opened the GH-1484 plan, which names the expected answer. It is kept only to show why the later runs used a clean clone.

## Limits

- One run per condition, one model family (Claude subagents in the authoring session). Model output varies between runs; this is not a rate.
- The grader is the author of the skill, in the same session. The independent check is the Codex review recorded in `relay-system/2026-11-14/`.
- The code graph was not exercised: the installed index does not cover the disposable clone, so both skill runs reported "maps, then grep". The graph rung of the skill is untested.
- Shows the skill text works on the motivating case. Does not show it generalises.
