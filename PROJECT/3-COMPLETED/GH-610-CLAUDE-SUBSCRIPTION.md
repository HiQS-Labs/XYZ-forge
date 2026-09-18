---
title: "GH-610: feat(claude): subscription-validated native consult and relay support"
status: Complete
created: 2026-09-13
updated: 2026-09-14
owner: operator (via /express)
gh_issue: 610
source: https://github.com/HiQS-Labs/XYZ-forge/issues/610
doc_type: feature
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Extend native Claude consult and relay with explicit subscription validation and public instructions.
---

# GH-610 — feat(claude): subscription-validated native consult and relay support

## Status

| What was just completed | What's next |
|---|---|
| Implementation, public docs, live Max validation, and 376/376 full gate complete | Merge the reviewed PR after blocking hosted checks |

## Acceptance Criteria

- [x] Registered regression and existing consult/Claude suites pass.
- [x] Live subscription consult, reviewer and builder evidence retained with account details redacted.
- [x] Public docs explain configuration and role/usage limits.
- [x] Full gate and independent review pass before landing.

## Merge evidence

- Source branch `codex/claude-subscription`; full pre-push gate green on `04e21ace` (376/376, 883 seconds, no pooled failures). PR and merge evidence follow below.

## Recon and scope

Base: `561123d0`. Graph generation 2026-09-01 was stale; exact source reads verified
`claude-turn.py` (claim, worktree, cleanup, enforcement), `consult.py` (isolated advisory
worktree, per-model failure aggregation), and `proc_group.py` (bounded auth probes).
Existing dispatch in `marathon-agent.sh` handles Claude; standalone relay sets reviewer
role and attests approvals. Marathon's Codex/Agy reviewer allowlist is unchanged.
One shared native CLI helper owns auth/result interpretation. There is no new credential
store, proxy, or coordination authority. Runtime default remains Python; Bash is frozen. Native Claude requires the full checkout or
Tier 1/2 vendor; the legacy partial relay tarball is explicitly excluded in its installation guide.

## Validation

Phase 0: the installed CLI reports Claude.ai / firstParty / Max. A controlled apiKeyHelper
configuration changes its auth status to api_key_helper, confirming the probe distinguishes
that route. No account identifiers or credentials are retained.

- Final focused run: 8 Python tests and 3 real shim fixtures, including post-claim auth failure,
  CLI error JSON, stderr warnings, strict success fields and operator handoff.
- Existing adapter suites: Claude 36 assertions and consult 62 assertions pass.
- Witnessed red: helper absent; a no-op authentication mutation is also rejected by the suite.
- Live CLI 2.1.270 / Max: consult read README with a citation; standalone review returned Approved
  with a driver attestation and a completed token; builder changed only its requested text file
  and relay log, with a scoped harness commit and explicit handoff to operator.
- Independent source review found a missing stderr diagnostic pointer; fixed before the final run.
- Deterministic documentation checks: frontmatter, status table and changelog all clean.
- Evidence: `TESTS-RESULTS/2026-09-13+GH-610/`. Account identifiers and machine paths are redacted.
  Live fixture commits are separate from the source branch; the reviewer receipt includes the
  reviewed helper's SHA-256. This is route/role smoke evidence, not a general model-quality grade.
- The initial sequential gate at d5b02118 was stopped as superseded; it is not passing evidence.
  The 8edd90ca pre-push run caught a new test pipe into grep -q (GH-139). The assertions
  were corrected to here-strings; GH610 and GH139 pass on the corrected test. Final
  qualification must include that correction. A pooled GH53 failure matched pre-existing
  #541 (timestamp-sensitive fixture union); the unchanged base passes alone, and the
  full gate owns its standard isolated retry. No releases runtime code changed.

## Delivery

Express check refused generated ledger output from the earlier driver ledger step. The
complete implementation plus public documentation surfaces also exceeds 4 core files.
Use the normal fresh-clone PR lane; no express bound overrides. Ledger writes were made
only by express's official verbs. The generated leaderboard is omitted from the task PR.

## Lessons Learned (For Future Agents)

- Native CLI auth status distinguishes subscription login from apiKeyHelper; never infer
  billing from a CLI name, token counts, or total_cost_usd.
- Reviewers need protocol-file writes and tick handoff; read-only consult tool flags cannot
  be applied wholesale to relay review.

Final source validation: `04e21ace`, normal full pre-push gate 376/376. Subsequent changes are documentation/evidence only.
