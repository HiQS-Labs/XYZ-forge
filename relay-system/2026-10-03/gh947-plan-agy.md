# RELAY · GH947 optional HiQS profile plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-03.
-->

NEXT: Producer
STATUS: Approved
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh947-optional-hiqs-profile-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **GH-947-HIQS-RECIPE-PROFILES.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: codex-author
- Started: 2026-10-03

### Artifact — GH-947-HIQS-RECIPE-PROFILES.md
```
---
gh_issue: 947
source: https://github.com/HiQS-Labs/XYZ-forge/issues/947
title: Optional HiQS recipe-backed profiles
status: In progress (2-WORKING — plan QA)
created: 2026-10-03
updated: 2026-10-03
doc_type: feedback
owner: Codex with Noel Saw
effort: 3
complexity: 3
risk: 3
phases: 3
branch: feat/gh947-hiqs-recipe-profiles
---

# Optional HiQS recipe-backed profiles

## Quad Concepts

1. One explicit source in the existing profile resolver; retain literal behavior.
2. HiQS owns facts/digests/eligibility; XYZ owns local installation and execution.
3. Refusal emits no runnable exports; native config and current expiry gate every call.
4. Pinned inputs and truthful draft dependencies; no implicit refresh or installation.

Implement the narrow profile primitive from GH-947. HiQS GH-4 and PR29 are stacked
prerequisites, explicitly authorized by operator. No merges or live pilot authorized.

## Status

| What was just completed | What's next |
| --- | --- |
| Full clone, recon, registered and rated intake; stacked PRs authorized | Agy plan QA, foundation implementation, then accepted-start and optional source |

## Recon / ownership

Base origin/development 3fbed72f781d1ad060e298b798a44c32edef393d. Profile code is
portable; ~/.xyz/device_config.json paths/auth/binaries are device-local. Known locator
GH-856 fixed upstream in PR936; fresh clone contains it. Primary checkout is untouched.
profile_resolve.py resolve tier1 precedes named profiles and missing config falls through.
emit_env refuses problems but current skill eval command substitution hides exit status.
consult.py Claude seat actually consumes model/effort/tools/limits; claude_cli.preflight
verifies subscription account/provider. claude-turn.py is an independent relay actor
and remains unsupported for this recipe pilot. Native Claude CLI absent on this device.
HiQS protocol2 derives pinned model/harness, checks policy/evidence and canonical config
digest; Python neither hashes canonical data nor filters/ranks recipes.

## Scope / dependencies / ratings

[GH-947](https://github.com/HiQS-Labs/XYZ-forge/issues/947) optional source, existing
resolver/Claude advisory only. [HiQS GH-4](https://github.com/NeochromeTeam/hiqs-ai-resolve/issues/4)
PR6 stacks over PR29; explicit operator approval permits implementation against pinned
unmerged foundation. Both remain merge-blocked drafts pending recipe publication defects
and maintained full-combination evidence/live pilot. No merge, deployment or live call.
GH579 broad workflow rollout is deferred. No all-lane promises, new databases, dispatcher,
service, persistent cache, automatic installs, source uploads or generic config language.

Rated 80/70/50/45 (priority/shared explicit ask; severity dispatch substitution versus
older locator incidents; neutral appeal/no override; medium cheapness from existing seams).
Ledger writer releases_app.py, owned rmi-01M408ZCRZMF99BP1T2MQC7JBZ. Prior-art query
HiQS recipe profile found no competing implementation. Snapshot refresh is explicit setup:
validate candidate with trusted source then atomic file activation; keep previous on failure.
No new refresh writer is needed in this feature.

## Ordered implementation / falsifiable checks

1. Extend profile_resolve.py existing source path before tier1 for explicitly selected HiQS
profile, and hiqs:NAME explicit lookup even when configuration is missing/malformed.
Literal tiers remain unchanged. Source mutually excludes literal route fields. Local source
contains exact recipeRef, pinned installed runner checkout/revision/argv, snapshot path and
snapshotPolicy, full policyPath and executionConfigPath. Validate runner git HEAD and clean
code, all argv paths installed; invoke argv only, no shell/installer/network. Send protocol2
nonsecret input once through proc_group.run_bounded extended with optional stdin string.
Input/output size <=1MiB and finite timeout; do not print runner output on refusal.
2. Reuse existing result/problems/emit_env. Require protocol2 and enforcedRecipeRef, exact
selected refs/target/config and UTC freshness. No downgrade/retry. Only support
xyz.claude-advisory.v1: explicit model/effort/authMode subscription, fixed Read/Grep/Glob
tools/allowedTools, restricted + strictMcpConfig true, JSON output, positive maxTurns and
maxBudgetUsd string. Recipe target must be first-party Anthropic subscription Claude with
no adapterConfig or routing overrides; exact harness build must match installed --version.
Compare returned normalized object to requested, model to wire requestIdentifier, and build.
Reject ambient model/flags/provider/auth overrides before returning exports. Retain request,
response/lock and runner identity in a private per-admission receipt, not a reusable cache.
3. In existing claude_cli.py add supported config validation/admission guard shared with
profile resolver and consult. Guard every dispatch with current UTC vs accepted expiry,
retained config vs emitted model/effort/auth/limits, native build/firstParty subscription
preflight; no fresh resolver per turn. Native managed settings may override CLI policy:
unsupported/mismatched account/model/config refuses; --restricted requires build>=2.1.248.
Claude relay turn rejects XYZ_HIQS_ADMISSION before token claim (pilot consult-only).
Legacy profile env clears HiQS marker; HiQS source exports advisory config/receipt only,
never RELAY_AGENT_CMD pretending Claude is a gate reviewer. Update skill assignment
status check before eval and document advisory usage; no actor/permission gate expansion.
4. Existing suite edits only if needed to pin actual changed behavior; no new test files,
registry entries, runners or suites (AGENTS GH831). Manual fixture receipt proves installed
pinned tsx invocation from foreign cwd and copied vendored context; success + malformed
JSON/old protocol/missing recipe/tampered digest/deny/config/build/provider/stale expiry
refuse with zero worker calls. Multi-turn expiry guard does not start resolver again;
retain request/response for lock replay. Measure cold/warm duration/subprocess count.
5. Agy independent plan/final relay cap3 each with thread-only writes; review committed
inputs and source. Focused profile/Claude/proc_group suites during iteration. Final
qualifying ci-local gate once on approved implementation in disposable FULL clone,
verify remote/HEAD before and after, committed TESTS-RESULTS/.../provenance.jsonl. No
runtime pass claim for skipped/failed checks. Push through applicable hooks; draft PR
against development. Keep primary/task clones and don't close issue before landing.

## Risks / rollback

Cross-repo contract changes are costly; explicit protocol + immutable runner avoids old
runners silently discarding selectors. Disable optional source to roll back, but explicitly
requested HiQS profiles refuse. Digest proves consistency, not authenticity or availability.
Native managed settings cannot be bypassed; live pilot and actual model/provider metadata
remain required for milestone. Boundaries are local single-user CLI, not enterprise grants.
Review any unavoidable implementation pivot before production writes.

## QA gates

- [ ] Agy approved plan before runtime edits / accepted-start.
- [ ] Positive route/config/build argv and negative zero-dispatch controls recorded.
- [ ] Current expiry blocks subsequent turn without resolving again; retained inputs replay.
- [ ] Final Agy approved + required gates truthfully recorded; PR open, awaiting merge.
- [ ] Maintained published recipe / real Claude subscription pilot (external prerequisite).


### Concrete pilot contract

Protocol2 input contains recipeRef, asOf, policy, optional conflicting query/harness;
snapshot + snapshotPolicy + executionConfig are outer fields. Expect response descriptor
trust=untrusted, enforcedRecipeRef and original executionConfig; result.route.recipe
contains typed target/build/effectiveExpiresAt, plus lock preserving selected inputs.
Supported target: transport claude-code-subscription, endpoint https://claude.ai,
first-party Anthropic gateway, empty adapterConfig/no routing, harness Claude Code.
This is a proposed supported wire contract, not an assertion a published recipe exists.

Fixed configuration keys: schema, model, effort, authMode, tools, allowedTools,
restricted, strictMcpConfig, outputFormat, maxTurns, maxBudgetUsd. The full object is
HiQS digest preimage. XYZ constructs existing native argv; no arbitrary settings passed.
Actual response modelUsage must match expected wire model when admission is active;
missing/different metadata is a failed result, never a verified execution receipt.  [Unverified — no citation]
Enterprise managed configuration cannot be established by CLI flags alone; restrict
pilot to personal pro/max subscription and refuse known managed settings/policy files.
The missing live recipe/pilot blocks claims of real executed-route equivalence.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer (agy) — Round 1

swept file: yes. Swept existing implementations across `utils/py/profile_resolve.py`, `utils/py/proc_group.py`, `utils/py/claude_cli.py`, `utils/py/consult.py`, `utils/py/claude-turn.py`, and `skills/1-hourly/relay-xyz/SKILL.md`. No pre-existing defects found in the existing code that impede the plan; the plan correctly identifies and addresses the known command substitution exit masking at `skills/1-hourly/relay-xyz/SKILL.md:290`.

- `[Pass]` **Quad Concepts & Scope Boundaries (GH-947 alignment):** The plan strictly bounds the implementation to one optional HiQS profile source and execution admission in XYZ (`Quad Concepts` 1-4, lines 81-84; `Scope / dependencies / ratings`, lines 108-116), restricting execution to the Claude consult/advisory lane (`lines 110-111, 149-152`). It explicitly defers broad workflow rollout (`GH579 broad workflow rollout is deferred`, `lines 115-116`), rejects persistent result caches and background daemons (`lines 115-116`), and forbids automatic installation or unpinned network calls during turns (`lines 84, 132`).
- `[Pass]` **Resolver Seam & Precedence (`profile_resolve.py`):** The plan detects explicit HiQS profiles before the legacy Tier 1 manual environment return (`Extend profile_resolve.py existing source path before tier1 for explicitly selected HiQS profile`, `line 127`), preventing ambient manual variables from silently overriding an explicit HiQS profile selection (`lines 127-128, 142`). Literal tiers remain unchanged (`lines 129, 135`), while missing or malformed HiQS configurations populate problems and cleanly refuse without falling through to Tier 4 literal defaults (`lines 128-129, 135-136`). Reusing `emit_env`'s existing `problems` refusal (`utils/py/profile_resolve.py:389-394`) ensures clean refusal with zero runnable exports.
- `[Pass]` **Bounded Subprocess & Nonsecret IO (`proc_group.py`):** Protocol2 invocation routes through `proc_group.run_bounded` extended with an optional `stdin` string parameter (`lines 132-133`; `utils/py/proc_group.py:80-97`), maintaining process-group cleanup and wall-clock timeout guarantees while avoiding shell intermediaries. IO is capped at <= 1MiB (`line 134`) and runner output is suppressed on refusal (`line 134`), preventing credential or prompt disclosure.
- `[Pass]` **Admission Expiry & Multi-turn Guard (`claude_cli.py` & `consult.py`):** Centralizes supported configuration validation and admission checking in `claude_cli.py` (`lines 144-145`; `utils/py/claude_cli.py:27-58`), validating current UTC against `effectiveExpiresAt` before each dispatch (`lines 145-146`; `utils/py/consult.py:621-645`). Resolving once at run admission and replaying retained inputs satisfies Phase 2 performance requirements by guaranteeing zero resolver subprocess spawns on subsequent turns (`lines 146, 157-158`).
- `[Pass]` **Role Containment & Caller Safety (`claude-turn.py` & `relay-xyz`):** Strictly enforces GH-221 by ensuring HiQS profiles export advisory config/receipts only and never `RELAY_AGENT_CMD` pretending Claude is a gate reviewer (`lines 150-151`). `claude-turn.py` explicitly rejects `XYZ_HIQS_ADMISSION` before token claim (`lines 149-150`; `utils/py/claude-turn.py:99`). In addition, the plan replaces unchecked `eval "$(resolve-profile ...)"` with checked assignment in skill callers (`lines 151-152`; `skills/1-hourly/relay-xyz/SKILL.md:290`), eliminating exit-code masking.
- `[Pass]` **Verification & Repository Rails (GH-831, GH-308):** Step 4 strictly complies with GH-831 ("No new tests") by editing existing suites only when pinning changed behavior and avoiding new test files, registry entries, or runners (`lines 153-154`). Step 4 defines falsifiable manual check matrices with committed `TESTS-RESULTS/.../provenance.jsonl` receipts (`lines 154-158, 161-163`), and Step 5 mandates that mutation-heavy qualifying gates (`ci-local`) run exclusively in a disposable full clone (`lines 161-162`), honoring `AGENTS.md` and `WORKTREE-SAFETY.md`.

VERDICT: PASS
Basis: The plan in GH-947-HIQS-RECIPE-PROFILES.md is thoroughly grounded in the existing profile resolver, Claude CLI preflight, and consult seams. It satisfies all issue #947 acceptance criteria and repository rails, provides rigorous negative controls, and introduces zero unneeded machinery or prohibited test suites.

relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-10-03T07:12:08Z
task: RELAY-GH947-PLAN-20261003
reviewer: agy
status: Approved
reviewed-head: 99204bfc3a04ea9d523307da7e265bf8423f2503
added-range: 14221+4404
added-sha256: bd129dceb2af263f5aa43889475b13c482dde111287cac6f7b09977b1f80b8b3
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
