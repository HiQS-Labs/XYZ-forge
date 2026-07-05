---
gh_issue: 124
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/124
title: "deep-research.mjs shipped un-run against real agy — add a real-agy smoke test + runaway-grounding guard"
status: captured 2026-07-04, rated, ready to build
created: 2026-07-04
updated: 2026-07-04
owner: noel
doc_type: enhancement
goal: >
  Add an opt-in, self-skipping real-agy smoke test for deep-research.mjs (mirroring
  relay-self-sufficiency.sh's convention) so a stub can't again hide a real-backend break, plus
  document the runaway-grounding risk at high search-context-size and the timeout override.
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: false
non_goals:
  - Not re-litigating the two hangs already fixed (91f17f2, 74cd553) — those are done; this is the hardening follow-up the issue itself proposes
  - Not making the real-agy smoke test part of the default validate.sh gate — it must self-skip like relay-self-sufficiency.sh so keyless/offline environments stay green
related:
  - relay-automation/deep-research.mjs
  - test/deep-research.sh
  - test/relay-self-sufficiency.sh
---

## Status

| What was just completed | What's next |
|---|---|
| Captured 2026-07-04 after dogfooding GH-87's adapter for real (researching #111) surfaced two hangs, both already fixed (`91f17f2`, `74cd553`) with stub regression coverage added. This doc scopes the issue's own proposed hardening follow-up: a real-`agy` smoke test (so a stub can't hide the next real-backend break) + a runaway-grounding guard + a timeout revisit. | Build all three items in one lane. |

## Problem (grounded in the current code)

Both hangs that shipped past review were invisible to `test/deep-research.sh` because its stub never
gates on tool permissions or reads stdin — the exact two behaviors that broke against real `agy`.
Stub coverage was added for both specific bugs after the fact (regression-proofing what already
broke), but nothing in the test suite proves the adapter still works against the **real** backend
going forward — the next real-`agy` behavior change would sail through the same way these two did.

Separately, `deep-research.mjs`'s `--search-context-size high` hint plus its citation-heavy system
prompt can drive `agy` to search unboundedly on a multi-claim query, pushing close to
`DEEP_RESEARCH_TIMEOUT_MS`'s default 120000ms (`deep-research.mjs:116`) — fine for the ~30s focused
queries seen so far, tight for a thorough one.

## Fix

1. **Opt-in real-`agy` smoke test**, mirroring `test/relay-self-sufficiency.sh`'s established
   self-skip convention (`RELAY_SELF_SUFFICIENCY_SKIP`/no-live-agent detection): add a
   `DEEP_RESEARCH_LIVE=1`-gated test (default: skipped, printing why) that runs one real, small
   `deep-research.mjs` query against actual `agy` and asserts a real answer + citation come back
   within the configured timeout. Never part of the default `validate.sh` gate's required-green set —
   same opt-in posture as the self-sufficiency test.
2. **Runaway-grounding guard**: document (in `deep-research.mjs`'s header comment and
   `relay-automation/README.md`) that `--search-context-size high` can approach the timeout on
   multi-claim queries, and add a lighter guard — either a lower default `search-context-size`, or a
   note steering callers toward `medium` for anything but a single, focused claim. Prefer
   documentation + a sane default over new runtime complexity, per this repo's "least code that
   clears the bar" convention.
3. **Revisit `DEEP_RESEARCH_TIMEOUT_MS`'s default**: keep 120000ms as the default (it covers the
   focused-query case observed so far) but document the env override clearly for thorough/multi-claim
   queries, rather than silently raising the default for everyone.

## Definition of done

- [ ] A `DEEP_RESEARCH_LIVE=1`-gated real-`agy` smoke test exists in `test/deep-research.sh` (or a
      sibling file), skipped by default with a clear reason line, matching
      `relay-self-sufficiency.sh`'s convention.
- [ ] `deep-research.mjs`'s header comment and `relay-automation/README.md` document the
      runaway-grounding risk at `high` context size and the `DEEP_RESEARCH_TIMEOUT_MS` override.
- [ ] No change to the default (non-live) test behavior — `test/deep-research.sh`'s existing 23
      assertions stay green and unaffected.
- [ ] `bash validate.sh` green (the new live test self-skips in this environment).

## Reversibility & blast radius

**Low.** Additive test + documentation; no change to `deep-research.mjs`'s actual request/response
logic beyond what the issue explicitly asks for (no new runtime guard code unless a genuinely cheap
one is found — documentation is the default fallback per the fix's own framing).

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash test/deep-research.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "test/deep-research.sh", "pattern": "DEEP_RESEARCH_LIVE" }
  ],
  "artifacts": [
    "test/deep-research.sh",
    "relay-automation/deep-research.mjs",
    "relay-automation/README.md"
  ],
  "remediation": "Add a DEEP_RESEARCH_LIVE=1-gated real-agy smoke test to test/deep-research.sh (or a sibling file), self-skipping by default (no network/agy, or DEEP_RESEARCH_LIVE unset) exactly like test/relay-self-sufficiency.sh's convention -- runs one real, small deep-research.mjs query against actual agy and asserts a real answer + citation within DEEP_RESEARCH_TIMEOUT_MS. Document in deep-research.mjs's header comment and relay-automation/README.md: (a) --search-context-size high can approach the timeout on multi-claim queries -- recommend medium for anything but a single focused claim; (b) DEEP_RESEARCH_TIMEOUT_MS's default (120000ms) and how to override it for thorough queries. No change to the existing 23 non-live assertions. GH-124 marker comment near the new test.",
  "lanes": {
    "agy_safe": ["test/deep-research.sh", "relay-automation/deep-research.mjs", "relay-automation/README.md"],
    "orchestrator_only": [],
    "note": "Independent -- deep-research.mjs/test/deep-research.sh/README.md, no overlap with any other Plan C lane's write-set."
  }
}
```

## Provenance

Surfaced 2026-07-04 dogfooding the merged GH-87 adapter to run grounded research for #111 (Python
cutover lessons) — the adapter hung on every real call, both root causes already fixed (`91f17f2`,
`74cd553`) with stub regression coverage; this issue is the testing-gap + hardening follow-up the
fix commits themselves flagged as remaining.
