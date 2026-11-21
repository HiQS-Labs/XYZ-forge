# GH-1286 acceptance — round 3, final (skill at f09f8105, 119 lines)

Same runner, prompt and input snapshots as rounds 1 and 2; two fresh subagents (Claude Opus 5.5).
Verbatim verdicts: [`raw/r3-1186.md`](raw/r3-1186.md), [`raw/r3-1279.md`](raw/r3-1279.md); inputs
unchanged in [`inputs/`](inputs/). Round 3 is the last round run (see the stop decision below).

## Counter-example control — PR #1186: PASS

"Nothing to cut. The plan already left out the ceremony: it did not re-run the local full suite for a
one-step YAML change, and it added no new suite or gate machinery (GH-831)." It kept the CI step
(progress), the 1-second local check (proof, gates the push), the hosted run (proof) and the red branch
(proof; real run unavailable on demand). Next step: push the red branch, "waits on the operator's
approval", phrased as a question. Parked: 1.

## Worked example — #1279: PARTIAL (4 of 6 rule parts met)

| Rule part | R1 | R2 | R3 |
|---|---|---|---|
| Cut timed 8-hour window | met | met | met |
| Cut planned crashes and missed slots | met | met | met |
| Cut slot arithmetic | met | met | met ("96-slot budget arithmetic, idle-slot accounting, 89/1/6 target") |
| Cut staged handoff / Codex adapter | not met | partly | **partly**: cut the driver derivative, in-window canaries and per-slot digests as "machinery so the window can test itself"; kept the adapter build as progress because #1279 line 158 names "agent-adapter iteration" as a follow-up, i.e. the issue says it outlives the test |
| Keep plan-quality review with planted flaws | met | partly | **met** ("at least six seeded-flaw controls … no record shows the reviewers catch these kinds of flaws") |
| Real marathon lane, gated on approval | not met | partly | **partly**: proposes an untimed run of one decision per issue and asks whether to dry-run one GH-1270 packet now; keeps `--dry-run` as the end point because a real build "is not authorized now and needs a separate plan" |

Next step it gave: build the adapter after one agy Flash turn passes; then one Codex decision on one
real issue, then the rest back to back. Questions to Noel: dry-run one GH-1270 packet now; drop the
8-hour window for an untimed run. Parked: 11.

## Rejection witness (hand-applied)

A deliberately wrong verdict for #1279 that keeps every proxy (timed window, crashes, missed slots,
slot accounting, driver derivative, adapter) and cuts nothing meets none of rows 1–4 and is rejected.
Rounds 1–3 show the rule also separates partial verdicts from full ones.

## Assessment

Blind, from #1279's own text, the skill reaches the core finding: the soak re-proves liveness that a
recorded 12-hour run already showed, and it should be cut for an untimed pass plus dry runs and a
planted-flaw plan review. Two parts of the operator's expected answer are not reached:

1. **Cutting the Codex adapter.** #1279 states the adapter's purpose and lists its iteration as a
   follow-up, so an auditor reading only #1279 treats it as goal-bearing. Reaching the expected cut
   needs the parent goal (#1248: drafted plans a marathon can execute), which is not in the input.
2. **One real marathon lane as the next step.** The skill's rule ("a real run that needs approval is
   still the next step, gated on that approval") was applied to the red branch in #1186 but not to the
   marathon lane in #1279, where the plan calls a real build out of scope and separately authorized.

Further rounds were not run. The approved plan sets no cap on acceptance rounds; stopping after
three is the producer's judgment (Claude), made because each further round tunes the text toward one
known answer and so weakens what a pass would show. The two unmet parts stay recorded as unmet. Both gaps are disclosed in the PR for the operator to judge.
