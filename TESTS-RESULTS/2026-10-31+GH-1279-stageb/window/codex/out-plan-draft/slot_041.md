# Plan draft: #579 HiQS integration: resolve explicit model requests for consult, relay, builder and reviewer

> draft; preflight and independent plan QA outstanding

- Request: `gh-579-81658ada9d5e` (tick `slot_041`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 70/55/50/25
- Capture doc: PROJECT/1-INBOX/GH-579-HIQS-CONSUMER.md (sha256 1810756dbd8aea87eb0ad2d809f345de8470bc31ef5904195d03f01280c659e5)
- Issue sha256: 81658ada9d5e24b6e380bf13c5bf920618c7ca880dd57feeb273fdfb0d669540 (updated 2026-09-25T01:18:58Z)
- Dependencies: none

## Scope

_Source: issue#579:L1 (Outcome)_

When an operator requests a model by natural language—e.g. “Deepseek 4.1 Flash”—XYZ Forge resolves an evidenced HiQS route, preserves the requested workflow role, and invokes the existing supported worker with the exact wire model and endpoint. Unknown/ambiguous/unavailable requests ask for clarification; NEVER silently select a nearby model or shim default. The example name is unverified, not an assertion that a model or route exists.

Implement one consult pilot first, then expand the same adapter to relay, builder and reviewer. This is a medium discovery sketch, not a mandate to replace existing routing.

_Source: PROJECT/1-INBOX/GH-579-HIQS-CONSUMER.md:L25 (Scope and dependency)_

Consult pilot first, then relay/builder/reviewer boundary checks (explicit unsupported
where current gates forbid a combination). Ask on unknown/ambiguous/unavailable models;
never retry with another model. Source issue owns full acceptance requirements.

Foundation: https://github.com/NeochromeTeam/hiqs-ai-resolve/issues/4 ; daily sibling:
https://github.com/NeochromeTeam/hiqs-ai-resolve/issues/3 . Track foundation-ready separately
from tracking-issue closure. Implementation waits for foundation landing; no implicit merge
or unmerged dependency pin. PR targets development, confirmed by operator 2026-09-12.

_Source: codex-authored (codex-authored)_

Verify the current issue, shared HiQS consumer contract, and foundation readiness before identifying remaining implementation work.

_Source: codex-authored (codex-authored)_

Plan a shared explicit model resolution adapter and a consult pilot using an existing supported advisor, then extend it to relay, builder, and reviewer after tracing their dispatch paths.

_Source: codex-authored (codex-authored)_

Preserve local execution authority, reviewer eligibility, credential handling, and existing behavior for requests outside the explicit HiQS path.

## Acceptance criteria

_Source: issue#579:L27 (Acceptance checks — run, don't merely author)_

- [ ] Exact identity and declared aliases select the expected endpoint AND wire model, verified at mocked child-process/transport arguments.
- [ ] Unknown “Deepseek 4.1 Flash”, ambiguity, conflicting overrides, missing binding, stale/invalid snapshot and missing credentials produce zero worker invocations.
- [ ] Explicit-model unavailability is tested separately: missing binding/known unsupported runtime causes zero worker invocations; provider outage after dispatch causes exactly one failed worker invocation and zero fallback-profile, substitute-model or retry dispatches.
- [ ] Literal-model requests never fall through to default profiles or a different model; unset-model legacy behavior remains compatible.
- [ ] Role/model/provider/harness remain distinct: selecting a model cannot grant reviewer eligibility or collapse producer/reviewer actors.
- [ ] Dry-run makes zero external calls; cache/offline behavior and one-refresh cap are tested.
- [ ] Consult, relay, builder and reviewer each have a boundary test, including explicit unsupported outcomes where current gates prevent execution.
- [ ] One operator-approved live consult demonstrates answer + trace; later surfaces have approved smoke checks before enablement.
- [ ] Negative-control receipts and passing output are attached to the implementation PR; use existing focused suites before repository-required final gates.

_Source: codex-authored (codex-authored)_

Explicit model requests resolve to an evidenced exact route or produce an actionable refusal without falling back to a profile default or another model.

_Source: codex-authored (codex-authored)_

Route, policy, endpoint, role, credentials, and runtime checks occur before dispatch; known invalid or unavailable routes spawn no worker.

_Source: codex-authored (codex-authored)_

The consult dry run makes no external calls and reports the route decision; an approved pilot produces a real advisory result using the exact model and endpoint.

_Source: codex-authored (codex-authored)_

A provider failure discovered by the worker is returned without an automatic retry or alternate dispatch.

_Source: codex-authored (codex-authored)_

Telemetry records the requested and actual route and decision provenance without exposing credentials.

## Open questions

_Source: PROJECT/1-INBOX/GH-579-HIQS-CONSUMER.md:L52 (Execution gates and unknowns)_

- [ ] Confirm real pilot model/provider/credential reference and published snapshot policy.
- [ ] Land shared consumer contract; promote this capture and plan concrete call-site changes.
- [ ] Instrument Aider/LiteLLM exact wire model/endpoint; suppress conflicting local model,
      weak/editor-model and provider configs without changing legacy non-HiQS behavior.
- [ ] Mock child dispatch asserts exact route; misses/ambiguity/policy/trust/runtime/credentials
      failures spawn zero workers. Provider outage produces one failure, no fallback/retry.
- [ ] Dry-run has zero external calls; preserve actor/path/no-push gates on every role.
- [ ] Agy plan and final QA, scoped red controls, full local gate in disposable clone,
      then operator-approved live consult receipt. Never claim fixture coverage as live.

_Source: codex-authored (codex-authored)_

Has the shared consumer foundation landed, and are its versioned contract and policy materialization rules ready for use?

_Source: codex-authored (codex-authored)_

Which pilot model, provider, credential reference, and published snapshot policy have been confirmed?

_Source: codex-authored (codex-authored)_

Can the candidate advisor enforce the exact wire model and endpoint while suppressing conflicting configuration and keeping credentials out of process arguments?

_Source: codex-authored (codex-authored)_

What has changed in the relevant dispatch and reviewer gates since the supplied recon?

## Write set

- `utils/py/consult.py` (PROJECT/1-INBOX/GH-579-HIQS-CONSUMER.md:L39)
- `utils/py/aider-turn.py` (PROJECT/1-INBOX/GH-579-HIQS-CONSUMER.md:L42)
- `utils/py/profile_resolve.py` (PROJECT/1-INBOX/GH-579-HIQS-CONSUMER.md:L44)
- `utils/py/pi-turn.py` (PROJECT/1-INBOX/GH-579-HIQS-CONSUMER.md:L46)
- `utils/py/deepseek-turn.py` (PROJECT/1-INBOX/GH-579-HIQS-CONSUMER.md:L48)
- `utils/py/marathon_drive.py` (PROJECT/1-INBOX/GH-579-HIQS-CONSUMER.md:L49)
- `utils/py/relay_drive.py` (PROJECT/1-INBOX/GH-579-HIQS-CONSUMER.md:L50)

## Unresolved file names

- none

## Contract probes

- none
