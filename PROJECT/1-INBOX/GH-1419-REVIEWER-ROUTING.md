---
title: "Provider-agnostic Jog reviewer routing"
gh_issue: 1419
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1419
status: "Proposed"
created: 2026-11-11
updated: 2026-11-11
owner: Codex
goal: "Run explicit supported independent reviewers including Claude-only actor pairs without divergent admission rules"
doc_type: task
effort: 3
complexity: 3
risk: 3
phases: 1
---

# Provider-agnostic reviewer routing

## Status

| What was just completed | What's next |
|---|---|
| Grounded conflicting Jog/Marathon/manifest restrictions; fresh canonical clone provisioned | Independent plan QA before production changes |

## Outcome and recon

Jose explicitly authorizes Claude builder plus independent Claude reviewer for #1418. Current Jog validator hardcodes codex/gemini/agy and manual binary selection; Marathon accepts router prefixes but separately restricts reviewers to codex/agy; bin/marathon-yaml repeats the latter restriction. Gemini is phantom (no dispatcher). Existing marathon-agent.sh supports Claude but single CLAUDE_AGENT slot is overwritten by second same-provider actor. Agy alone has comma-member routing. Equal actor IDs are correctly rejected. Existing `profile_resolve.lanes()` derives supported routes from `marathon_drive.route_agent` source, so moving/changing that function carelessly breaks discovery. Existing `_probe_agent_bin` already resolves each route's executable. No need for a second provider registry.

Prior-art query matched broad #1223/#1279/#646/#862 but none implements reviewer routing; actual current validators still refuse Claude. Related source: utils/py/jog_run.py:validate_marathon_executor; utils/py/marathon_drive.py:route_agent/_probe_agent_bin; bin/marathon-yaml:validate; relay-automation/marathon-agent.sh; profile_resolve.py:lanes. Preflight generates roles and Jog substitutes actual invocation roles: trace both to preserve exact binding.

## Bet, alternatives, risk

Costly coordination surface: misrouting can dispatch a builder instead of reviewer and misattribute attestation. Revert scoped PR as rollback; no DB schema or default-role change. Smallest bet: reuse existing route discovery/probes and dispatcher, remove provider-quality hardcoding from execution admission, and accept operator-explicit supported routes. Availability and review quality remain separate; no new quality grade claims. Unsupported/phantom routes still refuse. External T3 review recovers one candidate but cannot satisfy automatic Jog continuation; simply adding claude to three allowlists leaves duplication and same-provider overwrite.

## Ordered implementation and verification

1. Establish one callable supported-route validation/resolution using existing Marathon route owner/discovery and executable probes; preserve profile_resolve source-derived lane discovery. Jog validates selected builder/reviewer before lease using that owner, no ad hoc binary table. Keep same-exact-actor refusal, explicit reviewer requirement and defaults. Existing general route availability is the admission criterion, not a hardcoded provider quality ranking.
2. Remove narrower Marathon reviewer restriction; make manifest validation consume the same route owner rather than another prefix list (use existing Python CLI/helper seam if practical; avoid a new executable). Trace preflight invocation substitution and retry paths for identical validation.
3. Fix existing marathon-agent dispatcher routing for two distinct same-provider actors, including claude-builder/claude-reviewer and codex pairs, without shell evaluation of arbitrary commands. Preserve unknown actor rejection and reviewer-only write containment/attestation. Existing Bash dispatcher is not one of the frozen twins; authoritative frozen Python twins remain unchanged on Bash side.
4. Witness baseline refusals then fixed paths through actual validators/dispatcher with controlled existing/manual fixtures: Claude reviewer; explicit Claude pair; Codex/Agy regression; same actor refusal; phantom/unknown route refusal; missing binary; review-only role binding; manifest and Jog parity. No new suites/registry/guards. Adjust existing suites only for changed pinned behavior (gh280/gh346 and dispatcher coverage discovered during recon).
5. Smoke main and adjacent real entry paths in disposable full clone (Claude pair configured dry-run/controlled dispatch and resumed/review-only path). One bounded live Claude review can prove actual reviewer route, without claiming other providers' quality. Independent final Codex QA on committed source/evidence; normal classified push gate once final code approved, ready PR development. No merge/deployment/trial qualification claim.

## Acceptance

- [ ] Explicit supported reviewers consistently accepted by Jog/Marathon/manifest; original Claude refusal reproduced red.
- [ ] Claude-only distinct actor roles route to correct isolated turns; equal IDs/unknown routes/missing binaries refuse before lease.
- [ ] Existing Codex/Agy behavior, reviewer-only containment, approval attestation, retry caps and explicit builder default policy remain intact.
- [ ] Main+adjacent smoke, independent plan/final QA and normal gate evidence committed; no new suite or runner.

## Non-goals

No arbitrary command reviewer, automatic provider fallback, account/credential changes, quality grade upgrades, new model catalog/queue/scheduler, legacy frozen twin parity, PR merge/global install. #1171 qualification and #1315 build remain separate, with their prior histories preserved. This PR does not itself prove overnight progression.

## Rating rationale

2026-11-11 proposed75/70/50/55: blocks explicitly requested Claude-only workflow and recovery from repeated Agy resource failures; recoverable configuration refusal rather than data loss. Neutral appeal. Moderate multi-entrypoint coordination change. Recurrence trend unknown; prior failures are credit incidents, not independent proof of routing-defect growth. No operator override.

## Lessons Learned

Pending verified results; NO_ENTRY until evidence distinguishes changed components.
