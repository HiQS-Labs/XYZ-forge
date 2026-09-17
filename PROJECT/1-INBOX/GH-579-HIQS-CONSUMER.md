---
gh_issue: 579
source: https://github.com/HiQS-Labs/XYZ-forge/issues/579
title: HiQS explicit model consumer
status: Proposed (1-INBOX — foundation blocked)
created: 2026-09-12
updated: 2026-09-12
owner: Codex with Noel Saw
doc_type: feedback
effort: 4
complexity: 4
risk: 4
phases: 3
branch: feat/hiqs-consumer-579
---

# GH-579 — HiQS consumer

## Quad Concepts

- Exact named model → shared HiQS route-or-refusal boundary, no profile fallback.
- Existing advisor → reuse isolated consult, not another executor.
- Workflow authority → preserve reviewer eligibility independently of catalog compatibility.

## Scope and dependency

Consult pilot first, then relay/builder/reviewer boundary checks (explicit unsupported
where current gates forbid a combination). Ask on unknown/ambiguous/unavailable models;
never retry with another model. Source issue owns full acceptance requirements.

Foundation: https://github.com/NeochromeTeam/hiqs-ai-resolve/issues/4 ; daily sibling:
https://github.com/NeochromeTeam/hiqs-ai-resolve/issues/3 . Track foundation-ready separately
from tracking-issue closure. Implementation waits for foundation landing; no implicit merge
or unmerged dependency pin. PR targets development, confirmed by operator 2026-09-12.

## Recon at e4236f854c9e01930bdddc43400431b976458ee2

Direct source reads; graph generation 2026-09-01 belongs to another checkout and is stale.
`utils/py/consult.py:415,432,541` accepts advisor names, not arbitrary model IDs.
Its Aider explicit-base path (`:572–591`) is the smallest candidate adapter. It currently
places the key in process arguments (`:581`); before live use, reuse environment-only
credential transport from `utils/py/aider-turn.py:88–94`. No secret was read or sent.

`utils/py/profile_resolve.py:317–360` intentionally permits env precedence/default fallback;
do not route explicit HiQS misses through it. `:379–424` exports telemetry gateway/model,
not an endpoint/auth contract. Pi uses PI_PROVIDER (`utils/py/pi-turn.py:55,111`) rather
than its gateway telemetry. DeepSeek uses fixed provider routes and alias rewriting
(`utils/py/deepseek-turn.py:35–52,226–238`); neither proves arbitrary wire-exact routing.
`utils/py/marathon_drive.py:1930–1966` allows multiple builders but codex/agy reviewers only.
`utils/py/relay_drive.py:643–711` approval requires a witnessed reviewer turn/attestation.

## Execution gates and unknowns

- [ ] Confirm real pilot model/provider/credential reference and published snapshot policy.
- [ ] Land shared consumer contract; promote this capture and plan concrete call-site changes.
- [ ] Instrument Aider/LiteLLM exact wire model/endpoint; suppress conflicting local model,
      weak/editor-model and provider configs without changing legacy non-HiQS behavior.
- [ ] Mock child dispatch asserts exact route; misses/ambiguity/policy/trust/runtime/credentials
      failures spawn zero workers. Provider outage produces one failure, no fallback/retry.
- [ ] Dry-run has zero external calls; preserve actor/path/no-push gates on every role.
- [ ] Agy plan and final QA, scoped red controls, full local gate in disposable clone,
      then operator-approved live consult receipt. Never claim fixture coverage as live.

## Rating rationale

2026-09-12 assessment: rated 70/55/50/25 (pri/sev/appeal/cheapness). Requested integration
is valuable but blocked on foundation; disclosure/spend and precedence risks make it costly.
Appeal neutral, no operator numeric overrides. Relevant prior issues GH-346/GH-399 document
routing work, not distinct new incidents. Recurrence trend over last 14 vs preceding 14 days
is unknown from bounded evidence; do not count cross-posted proposals as incidents.
Queries for routing/profile issues over 2026-08-15 through 2026-09-12 found relevant
GH-368 (same-lane env collision), GH-373 (unsupported reviewer alias), GH-399 (route
configuration), GH-448 (configured model differs from runtime); these are distinct
reported mechanisms, not proof of recurrence of one cause. Dates concentrate in the
recent window (2026-08-29 through 2026-09-12); the prior window is not an exhaustive
incident inventory. Preserve uncertainty instead of a numeric trend claim.

Rollback disables opt-in adapter; no legacy defaults changed. Live external disclosure/spend
is a one-way door: explicit preview/approval and endpoint-key pairing before first send.
Debug-mantra governs failures; Agy relay cap three rounds, stop on unresolved blocker.
