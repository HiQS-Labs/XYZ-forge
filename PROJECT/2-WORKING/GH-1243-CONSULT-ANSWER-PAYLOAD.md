---
gh_issue: 1243
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1243
title: "Consult answer payload and citation accuracy"
status: Active
created: 2026-11-10
updated: 2026-11-10
owner: B trial
goal: "Extract final answer for neutral payload and citation screening; preserve full transcript separately and missing-final-answer safety. Verify cited and uncited answers plus transcript exclusion using existing consult suite/manual evidence; no new suite."
---
## Status

| What was just completed | What's next |
|---|---|
| Reviewed final-answer fix qualified and merged as PR1406; missing/empty and citation controls passed | Live Codex + agy comparison remains unverified; issue1243 stays open under its owner |

# GH-1243 — Consult answer payload

## Acceptance

- [ ] Re-running a small Codex + agy consult gives neutral payloads of comparable shape and size: answer text only, with no exec logs, prompt echo or token footer.
- [x] A Codex answer that cites file:line next to its `[Pass]` lines is not stamped. An answer with an uncited `[Pass]` still is.
- [x] Verified per GH-831 with existing suites (`test/consult.sh`) plus a manual TESTS-RESULTS receipt. No new suites.
- [x] Preserve baseline failure and final passing evidence in the declared manual/provenance artifacts; use existing checks only.
- [ ] Do not install or publish anything, change versions or release tags, add dependencies, create new test suites, or modify unrelated paths.

## Acceptance — deviations from the issue

- [added] Preserve baseline failure and final passing evidence in the declared manual/provenance artifacts; use existing checks only. — reason: operator-authorized bounded trial constraints.
- [added] Do not install or publish anything, change versions or release tags, add dependencies, create new test suites, or modify unrelated paths. — reason: operator-authorized bounded trial constraints.

## Trial execution scope

Extract final answer for neutral payload and citation screening; preserve full transcript separately and missing-final-answer safety. Verify cited and uncited answers plus transcript exclusion using existing consult suite/manual evidence; no new suite. Preserve unrelated files. Two builder attempts maximum. Capture baseline/final controls, no new test suite.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh --auto development",
  "fix_probes": [
    {
      "type": "command",
      "cmd": "python3 TESTS-RESULTS/2026-11-10+GH-1386/consult-admission.py",
      "expect_nonzero": true
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-11-10+GH-1243/manual.md"
    },
    {
      "type": "path_absent",
      "path": "TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl"
    }
  ],
  "artifacts": [
    "utils/py/consult.py",
    "TESTS-RESULTS/2026-11-10+GH-1243/manual.md",
    "TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl"
  ],
  "artifacts_new": [
    "TESTS-RESULTS/2026-11-10+GH-1243/manual.md",
    "TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl"
  ],
  "remediation": {
    "source": "issue#1243",
    "criteria": "Extract final answer for neutral payload and citation screening; preserve full transcript separately and missing-final-answer safety. Verify cited and uncited answers plus transcript exclusion using existing consult suite/manual evidence; no new suite."
  },
  "lanes": {
    "agy_safe": [
      "utils/py/consult.py",
      "TESTS-RESULTS/2026-11-10+GH-1243/manual.md",
      "TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl"
    ],
    "orchestrator_only": []
  },
  "round_cap": 2
}
```

## Merge evidence

- PR #1402 merged 2026-11-10 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Source delivery and remaining qualification

PR1406 merged as6a0766b97f after independent Opus source approval, exact-source controls, fresh normal full qualification on d291ac29 (556.038s), normal documentation publication on011d215f (75.442s), and exact-head hosted smoke. Source/qualification receipts are retained under TESTS-RESULTS/2026-11-10+GH-1243 and relay-system/2026-11-10/pr1406-outer-opus.md. The live two-provider comparison was not run and stays unchecked.

The original no-publication constraint belonged to the closed engine window. The operator subsequently authorized PR review, minor corrections and merging. No package/service publishing, dependency/version change, new test suite, engine restart or cap reset occurred. Original failed automatic trial and manual interventions remain historical; delivery is agent-assisted.

GitHub closed issue1243 through PR1406's closing reference at08:42:52Z. The parent removed closing wording and reopened it because live acceptance remains unverified. Active document and nonterminal ledger state are restored through the existing PRS writer; the original rating65/60/70/75 is retained. This corrects source-delivery bookkeeping, not the live engine.

## Merge evidence

- PR #1406 merged 2026-11-10 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
