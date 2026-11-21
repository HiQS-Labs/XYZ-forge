# GH-1286 acceptance — round 2 (draft 95f82e98)

Same runner, prompt and input snapshots as round 1 (`round1-draft-2bccfb9c.md`); two fresh
subagents (Claude Opus 5.5); skill at commit `95f82e98` (118 lines). Verbatim verdicts:
[`raw/r2-1186.md`](raw/r2-1186.md), [`raw/r2-1279.md`](raw/r2-1279.md); inputs unchanged in [`inputs/`](inputs/).

## Counter-example control — PR #1186: PASS

Cut list: "Nothing to cut. The plan already removed its own ceremony: the local full suite and the
pre-push hook were skipped because the change is one YAML step and hosted CI is the gate for
workflow changes." Kept: the CI step (progress); the local `--check` (proof, gating, about 1 s, already
done); the PR's hosted run (safety and proof); the red branch (proof, the only answer to the open
question). Next step: open the red-control PR "once the operator asks for it", phrased as a question
("Run it now, or wait for the next real breaking PR?"). Parked: 0.

## Worked example — #1279: FAIL (partial, improved)

| Rule part | Round 1 | Round 2 |
|---|---|---|
| Cut timed 8-hour window | met | met (step 6 and sleep prevention) |
| Cut planned crashes and missed slots | met | met (`crash-act` slot 37, misses 85–90, step 7) |
| Cut slot arithmetic | met | met (slot budget, "all 96 slots", 89/1/6) |
| Cut staged handoff / Codex adapter | not met | **partly**: cut the driver derivative, second-arm STOP/backlog layout and parity digests; still kept the Stage A adapter build |
| Keep plan-quality review | met | **partly**: kept the cross-model plan QA (step 9) but cut the seeded-flaw controls as "grades the reviewers, not the planner" |
| Real marathon lane gated on approval | not met | **partly**: proposes dry-running the existing GH-1270 packets now and asks "Is a real build of one dry-run-ready lane the next separate authorization you want to plan for?"; next step is still the agy smoke for the adapter |

Goal line produced: "The GH-1248 outer loop can turn real backlog issues into plans that are correct,
safe and mechanically admissible, and its agent decision layer adds something the rules adapter does
not." The second clause is the plan's own component, which the round-1 rule did not catch because it
only looked at the line as a whole.

Operator questions it raised: dry-run the GH-1270 packets now; one untimed pass over the frozen issues
instead of the 8-hour window; a real one-lane build as the next authorization. Parked: 10.

## Changes made in response (next commit)

1. Step 1: a goal line fails if **any clause** names a component the plan builds; drop the clause.
2. Step 2: a control showing a check catches a known-bad input (planted flaw, red branch) is proof
   when the plan relies on that check, unless the check is already shown to catch that kind of flaw.
3. Trimmed "When to run it" by one line to stay within 120 lines (119).
