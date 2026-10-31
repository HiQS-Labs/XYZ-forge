# GH-1286 acceptance — round 1 (draft 2bccfb9c): both checks FAILED

- **Skill under test:** `skills/1-hourly/ceremony-audit/SKILL.md` at commit `2bccfb9c` (108 lines).
- **Runner:** two fresh Claude Code general-purpose subagents (Claude Opus 5.5), started 2026-10-31.
  Each was told to read exactly two files (the skill and one input snapshot), use no git, gh, web or
  repo browsing, and return the skill's verdict. Neither was told the expected answer.
- **Inputs:** `gh issue view 1279` snapshot (body + its one comment, a cross-link to #1280),
  `updatedAt 2026-10-31T02:04:03Z`; `gh pr view 1186` snapshot (title, body, files, mergedAt).

## Prompt (identical apart from the input path and description)

> You are testing a skill. Read exactly two files and nothing else (no other files, no git, no gh,
> no web, no repo browsing): 1. `<scratch>/SKILL.md` — the skill instructions. 2. `<scratch>/input-…md`
> — a GitHub issue containing a plan / a merged pull request describing its change and verification
> plan. Apply the skill to the plan in file 2, following its steps exactly, and return only the
> skill's verdict in the format the skill specifies (Goal / open question, Cut, Kept, Next step,
> Parked). Base every judgement on the text of file 2. Do not edit or create any files.

## Worked example — #1279: FAIL (partial)

Acceptance rule (plan step 3): cut the timed window / planned crashes / slot arithmetic / staged
handoff as re-proving proven uptime or not load-bearing; keep plan-quality review and one real
marathon lane as proof/progress; name the operator approval as the gate.

| Rule part | Result |
|---|---|
| Cut timed 8-hour window | met ("repeats the 12-hour rules-only liveness result") |
| Cut planned crashes and missed slots | met (slot 37 `crash-act`, slots 85–90) |
| Cut slot arithmetic | met (89/1/6 accounting, "all 96 slots accounted") |
| Cut staged handoff / Codex adapter | **not met**: kept the adapter build and driver derivative as *progress* |
| Keep plan-quality review | met (step 9 adversarial QA kept as proof) |
| Keep one real marathon lane, gated on approval | **not met**: kept the dry runs as the end point because "a real build is unauthorized here" |

Diagnosis: the run took the plan's own mechanism as the goal ("whether an agent decision arm (Codex
`plan-draft`) can produce … plans"), so the adapter looked necessary; and the skill let a proxy stand
when the real run needed approval instead of proposing the real run gated on that approval.

Raw verdict: verbatim in [`raw/r1-1279.md`](raw/r1-1279.md); the exact input is [`inputs/input-1279.md`](inputs/input-1279.md) (one snapshot, used unchanged in all three rounds). Summary:

- Goal: find out whether an agent decision arm (Codex `plan-draft`) can produce safe, well-grounded
  plans that are mechanically ready to run, on the real XYZ-forge backlog.
- Open question: does a Codex adapter behind the one-decision contract produce valid, contained and
  admissible plans on real issues? Cited as already shown: the rules-only run (137 ticks, planned
  misses and crash, no escapes), the Phase 2C pilot (15/15), #1098 and earlier Marathons.
- Cut: crash and scheduler-miss faults and their check; the rules arm as a timed 8-hour window with
  its 89/1/6 accounting; 8 hours at 5-minute spacing as a requirement; step 5 smoke of each arm
  (repeats entry gate 5); entry gate 2's separate agy smoke turn.
- Kept: adapter build (progress); driver derivative (progress); Codex arm over frozen requests and 24
  canaries (proof); entry gate 5 two-arm gate (proof/safety); step 8 dry runs (proof, proxy kept
  because a real build is unauthorized); step 9 adversarial plan QA (proof); entry gates 3–4, frozen
  manifest, step 1a handoff, disposable clones, call caps, provenance (safety).
- Next step: start the adapter build on agy with Flash; then one Codex decision on one real issue.
  Questions: untimed vs 5-minute spacing; full pass after gate 5 or after Noel's go.
- Parked: 6.

## Counter-example control — PR #1186: FAIL

Acceptance rule (plan step 4): cut list empty.

Raw verdict: [`raw/r1-1186.md`](raw/r1-1186.md); input [`inputs/input-1186.md`](inputs/input-1186.md).

Result: cut one step, the local `check_inventory_ratchet.py --check` on the head, as a repeat of the
hosted run. That check ran before pushing and gated the push, so deleting it would change the next
decision; it also cost about one second. The run also turned the "on request" red branch into the
next step. Over-cut: the skill did not say that a check gating the next action is not ceremony, or
that a step costing seconds is not worth a cut.

## Rejection witness (hand-applied, plan step 3)

A deliberately wrong verdict for #1279 that keeps every proxy (timed window, crashes, missed slots,
slot accounting, adapter, two-stage handoff) and cuts nothing fails rows 1–4 of the table above, so
the rule rejects it. Round 1's real output also failed rows 4 and 6, which shows the rule is not
satisfied by a merely plausible verdict.

## Changes made in response (next commit)

1. Step 1: the goal is the outcome the plan serves, not a component the plan builds; rewrite a goal
   line that names one.
2. Step 2: a check that gates the next action is not ceremony; do not cut steps that cost seconds or
   steps already done.
3. Step 2: machinery built only so the plan can test itself (adapters, harnesses, handoffs) is
   ceremony unless the goal still needs it afterwards.
4. Step 3: when the real run needs approval, it is still the next step, gated on that approval; a
   pending approval does not promote the proxy to the end point.
