---
title: "GH-610: feat(claude): subscription-validated native consult and relay support"
status: Active
created: 2026-09-13
updated: 2026-09-13
owner: operator (via /express)
gh_issue: 610
source: https://github.com/HiQS-Labs/XYZ-forge/issues/610
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
goal: >
  Express hotfix (GH-267 lane): feat(claude): subscription-validated native consult and relay support
---

# GH-610 — feat(claude): subscription-validated native consult and relay support

## Status

| What was just completed | What's next |
|---|---|
| Account route confirmed; implementation and public docs drafted | Finish integration/account validation and PR delivery |

## Acceptance Criteria

- [ ] Registered regression and existing consult/Claude suites pass.
- [ ] Live subscription consult, reviewer and builder evidence retained with account details redacted.
- [ ] Public docs explain configuration and role/usage limits.
- [ ] Full gate and independent review pass before landing.

## Merge evidence

- (recorded at landing by the /express driver)

## Recon and scope

Base: `561123d0`. Graph generation 2026-09-01 was stale; exact source reads verified
`claude-turn.py` (claim, worktree, cleanup, enforcement), `consult.py` (isolated advisory
worktree, per-model failure aggregation), and `proc_group.py` (bounded auth probes).
Existing dispatch in `marathon-agent.sh` handles Claude; standalone relay sets reviewer
role and attests approvals. Marathon's Codex/Agy reviewer allowlist is unchanged.
One shared native CLI helper owns auth/result interpretation. There is no new credential
store, proxy, or coordination authority. Runtime default remains Python; Bash is frozen.

## Validation

Phase 0: the installed CLI reports Claude.ai / firstParty / Max. A controlled apiKeyHelper
configuration changes its auth status to api_key_helper, confirming the probe distinguishes
that route. No account identifiers or credentials are retained. Live requests pending.
Regression first failed with the helper absent; initial six deterministic tests pass.

## Delivery

Express check refused generated ledger output from the earlier driver ledger step. The
complete implementation plus six public documentation surfaces also exceeds 4 core files.
Use the normal fresh-clone PR lane; no express bound overrides. Ledger writes were made
only by express's official verbs. The generated leaderboard is omitted from the task PR.

## Lessons Learned (For Future Agents)

- Native CLI auth status distinguishes subscription login from apiKeyHelper; never infer
  billing from a CLI name, token counts, or total_cost_usd.
- Reviewers need protocol-file writes and tick handoff; read-only consult tool flags cannot
  be applied wholesale to relay review.
