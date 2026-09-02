---
title: "p1 brief — same-lane agent routing (#368) + reviewer-validation alignment (#373)"
status: "Brief (input to the 2026-09-01 xyz-harness-quickwins marathon — not a tracked plan)"
created: 2026-09-01
updated: 2026-09-01
owner: Noel Saw
goal: >
  Make a builder and a reviewer on the SAME model lane routable (agy + agy-qa), and make
  the accepted reviewer set agree with what can actually dispatch.
roadmap_exempt: true
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/368
  - https://github.com/HiQS-Labs/XYZ-forge/issues/373
---

# p1 — routing + validation

## Status

| What was just completed | What's next |
|---|---|
| Phase brief authored. | Marathon phase execution. |

Read the two capture docs first: `PROJECT/2-WORKING/GH-368-SAME-LANE-BUILDER-REVIEWER-ROUTING.md`
and `PROJECT/2-WORKING/GH-373-PHANTOM-GEMINI-REVIEWER-LANE.md`.

## #368 — same-lane routing

- `utils/py/marathon_drive.py` `route_agent`: one env slot per lane (`AGY_AGENT`) is
  overwritten when builder and reviewer share the agy prefix.
- `relay-automation/marathon-agent.sh`: dispatch matches one exact id per slot.
- `utils/py/agy-turn.py` (+ frozen `agy-turn.sh` twin): no-ops unless
  `RELAY_AGENT == AGY_AGENT` verbatim.

Fix so builder `agy` + reviewer `agy-qa` both dispatch: e.g. the dispatcher routes by
lane membership, and the shim trusts the dispatcher for actor identity while KEEPING the
tick ownership guard. **FROZEN TWINS**: behavior changes in the `.py` lanes only
(`agy-turn.sh`, `marathon-drive.sh` are frozen); `marathon-agent.sh` is not frozen and
may be edited directly.

**Repro evidence** (2026-09-01 LTVera run): `marathon-agent: unknown agent 'agy'` after
route_agent overwrote the slot; then `agy-turn: actor agy is not the agy agent (agy-qa)
— deferring (window-driven)` once dispatch was worked around.

Test: `test/gh368-same-lane-routing.sh` — assert a same-lane builder+reviewer pair
routes through marathon-agent.sh and the shim does not defer (fixture/stub-based, in the
style of `test/gh520-default-reviewer-stub.sh`).

## #373 — phantom gemini lane (MOSTLY ALREADY FIXED — read this before touching anything)

**Two of the three surfaces were fixed on `development` by XYZ-forge PR #367 (GH-346 Phase 2),
after this brief was written.** Verified on `development @ b56e32d3`:

- `utils/py/marathon_drive.py` `route_agent` — no gemini branch. **Already correct.**
- `bin/marathon-yaml:99` — reviewer regex is `/^(codex|agy)/`. **Already correct.**
- `relay-automation/marathon-drive.sh` — **still wrong**: accepts `gemini*` at `:795`, advertises
  it at `:33`, `:593`, `:772`, `:794`.

So the remaining work is *only* the frozen Bash twin, and that is a GH-308 frozen-twin edit
requiring a `Frozen-twin-exception:` trailer. Decide explicitly: spend the exception, or close
#373 as "fixed everywhere it can dispatch" and let the twin retire with GH-308. **Do not edit
`marathon_drive.py` or `bin/marathon-yaml` for this issue** — they are already correct, and
changing them to satisfy a stale preflight probe is a change made to please a checkbox.

The GH-373 capture doc's contract has been corrected accordingly: it previously named the two
already-fixed files as artifacts and omitted the only file still carrying the defect.

## #368 also touches the GH-346 profile resolver — same change, or it breaks

`utils/py/profile_resolve.py` (XYZ-forge PR #375, merged after this brief was written) derives the
lane set by parsing `route_agent`'s source instead of keeping a copy — deliberately, because
GH-346 Phase 2 found that lane set in ten hand-maintained allowlists. Both routing fixes #368
proposes rewrite the shape it matches, after which the resolver yields no lanes and every profile
degrades to its floor: no crash, no blocked turn, just a feature that quietly stops working.

Update the derivation alongside `route_agent`. `test/gh346-profile-resolve.sh` already asserts the
derived lane set equals `route_agent`'s, so this fails in the gate rather than drifting. Do not
hardcode the lane list in the resolver — that makes it the eleventh allowlist.

## Constraints

- Leave a `GH-368` marker comment at the marathon-agent.sh change site and `GH-373` at
  the marathon_drive.py validation change — the capture-doc preflight probes key on them.
- Do not weaken the builder≠reviewer rule or the tick ownership guard.
- Gate: `bash validate.sh` (the repo default). In-turn, run only the two new tests plus
  any test file you edit — not the whole suite.
