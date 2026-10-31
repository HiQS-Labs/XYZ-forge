---
gh_issue: 1280
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1280
title: "ATE/fuzz the GH-1248 outer loop: smoke-first Mac Studio campaign"
status: Proposed (1-INBOX — not yet active)
created: 2026-10-30
owner: claude
doc_type: feedback
complexity: 3
risk: 2
effort: 3
phases: 3
ratings_provisional: true
non_goals:
  - no production-code repair during the campaign
  - no new state adapter, suite, CI case or registry entry (GH-831)
  - no synthesis, healing, model-per-mutant or automatic issue filing
related:
  - "#1248"
  - "#1279"
  - "#299"
  - "#298"
goal: >
  A bounded smoke proves the existing ATE/Gen 4 tools actually invoke the GH-1248
  `factory-primitive` outer loop with working oracles, reset and cleanup; only then a
  frozen, Codex-reviewed campaign of at most eight hours runs, and every candidate gets a
  semantic replay and an accountable disposition, with evidence under
  `TESTS-RESULTS/2026-10-30+GH-1280/`.
---

## Key concepts

- **Target:** `python3 utils/py/harness.py factory-primitive …` (merged via PR #1249 and
  stacked PRs #1260, #1262, #1274), pinned at `development` SHA
  `6147b988ac902f0f54d990256c876c474f68f760`.
- **Smoke gate first.** At most 20 min discovery + 10 min replay/cleanup, 200 mutations,
  25 per batch, 30 s per command, corpus cap 100; stop after 50 consecutive cases that
  only produce already-classified expected refusals.
- **Track A** — stateless CLI fuzzing through `fuzz_engine.py` / `gen4_campaign.py` with a
  custom target list (`--help`, `generate-manifest --output temp/factory-primitive/…`).
- **Track B** — constrained safe grid plus existing stateful oracles; held if per-case
  reset, semantic oracle, exact replay or descendant cleanup cannot be shown.
- **Long window** — at most 6 h discovery + 2 h postprocessing under an external 8 h hard
  cap; 10,000 mutations, 50 per batch, corpus 500; requires the smoke and a Codex
  `relay-xyz` review of the frozen contract.

## Acceptance criteria (from the issue)

- Exact source, target, fixture, seed/corpus, environment and driver identities recorded;
  telemetry proves relevant outer-loop invocations.
- Smoke controls, including a witnessed negative control and cleanup, passed before the
  long window; the `relay-xyz` Codex contract review is recorded.
- Discovery stayed within all bounds and stopped at the no-new-signal limit or earlier.
- Host/git/ledger identity and canaries unchanged; no unauthorized write or surviving
  descendant process.
- Expected refusals separated from candidate defects; every candidate has a semantic
  replay and an accountable disposition with clean/failing controls.
- Stateful coverage claimed only where reset, operation sequence and semantic predicate
  were actually exercised.
- No synthesis, healing, model-per-mutant, automatic filing, production execution, commit
  or push during the campaign.
- Report includes exercised/excluded coverage and actual budgets; every cited result has
  committed `provenance.jsonl`.

## Rating rationale (2026-10-30)

`rated 55/40/50/35`. Severity 40: no defect has been observed; the campaign looks for
latent robustness defects in a new, not-yet-production outer loop, so the consequence is
bounded. Priority 55: the operator asked for it now and it gates trust in #1248 before
wider use. Appeal 50: neutral, no operator score given. Effort 35: a multi-hour
supervised campaign with two Codex reviews and an evidence package, but no new code.
Recurrence: not applicable (an experiment, not an incident report); trend unknown.
