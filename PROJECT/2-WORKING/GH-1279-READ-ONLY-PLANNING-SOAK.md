---
gh_issue: 1279
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1279
title: "Outer loop: 8-hour read-only planning soak on Mac Studio (GH-1248)"
status: Active
created: 2026-10-30
updated: 2026-10-30
owner: noelsaw1
doc_type: research
effort: 3
complexity: 3
risk: 2
phases: 2
branch: feat/XYZ-forge-gh1279-read-only-planning-soak-2026-10-30
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1248
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1257
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1261
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1270
non_goals:
  - Production builds, Jog or Marathon execution, PR creation, merges or issue closure
  - A second Opus session or subagent, relay-per-tick, or Codex approving its own plans
  - Production repairs, new test suites or gates, scheduler installation, commits or pushes during the timed window
goal: >
  Compare deterministic and Codex planning over frozen real backlog inputs, independently red-team
  the resulting plans, and verify ready lanes through existing dry runs while preserving containment,
  recovery and ledger identity for 96 five-minute slots per enabled arm.
---

## Quad Concepts

- Another rules-only soak would mostly repeat prior liveness evidence → compare Codex and rules decisions over the same real backlog inputs.
- Plausible plans can still be unsafe or inadmissible → require independent adversarial QA and existing Marathon/preflight dry runs without executing builds.

# GH-1279 — 8-hour read-only planning soak

## Status

| What was just completed | What's next |
|---|---|
| Intake registered and rated 60/30/50/40; recon of the adapter seam done; Stage A plan written below (plan QA not yet run). | Codex plan QA through `relay-xyz`, then the agy (Gemini 3.8 Flash) build of the Codex adapter. Stage B (the 8-hour window) is a separate operator go after the adapter PR merges. |


## Target and decision

Target `HiQS-Labs/XYZ-forge:development` only. The issue and any adapter-preparation PR use that repository and branch; the timed run uses fresh disposable full clones on the Mac Studio, never the maintained primary, a linked worktree, `main` or a foreign repository.

Run 96 five-minute slots per enabled arm. The rules adapter is the deterministic reference; a bounded Codex `plan-draft` adapter is the agent decision arm. One interactive Opus 5.5 session orchestrates preflight, launch and post-run review. It does not spawn an Opus subagent or implement through a headless Claude lane.

The morning result is planning/wave outputs, agent decision-quality measurements, independent adversarial QA, execution-readiness dry-run evidence and a containment/recovery report. No production build, PR, merge, issue closure or launch-packet approval is an outcome.

## Relay and independence contract

The Opus supervisor must load and follow `relay-xyz` before any relay-driven preparation or QA. `/relay` scaffolds; `relay-xyz` locates and drives the harness. Run `find-harness.sh --check`, confirm Codex availability, use review-only `ALLOW_PATHS=""`, and bind final receipts to exact reviewed SHAs. Do not hand-roll token handoffs or driver commands.

- Adapter implementation uses a normal non-Claude builder before the window, with Codex plan/final QA through `relay-xyz`.
- Codex reviews adapter implementation, control-plane evidence and rules-produced plans.
- Opus reviews Codex-produced plans so Codex never approves its own output.
- The timed loop uses the bounded adapter API, not a relay invocation per tick.

## Codex-arm entry gates

The Codex arm runs only after:

1. Its one-turn, tool-free adapter preserves raw output and normalizes `ok`, `invalid-output`, `timeout`, `rate-limited` and `adapter-error`; the deterministic validator remains the safety boundary.
2. Exact-SHA Codex plan/final QA receipts exist through `relay-xyz`.
3. Applicable existing checks and the classified gate pass in a separate disposable full clone, without new tests or gate machinery.
4. A short rules+Codex gate passes ordinary/malformed/disallowed decisions, timeout, rate limiting, prompt injection, containment, honest cost/usage and no-retry controls.
5. The run manifest freezes adapter/CLI/model/authentication route, prompt hash, flags, call cap and budget accounting.

If any gate fails, omit the Codex arm. The fallback is rules-only planning plus dry runs and adversarial QA, explicitly not agent-decision evidence. No adapter repair is allowed during the timed window.

## Shared run contract

- Seed with `init --from-prs --limit 48 --unregistered 48`; record actual accepted/excluded counts and expected idle slots. Do not refresh or top up.
- Both arms receive identical frozen slot-indexed inputs, policy semantics and faults in separate state directories. A per-slot digest mismatch stops that arm before evaluation.
- Include at least 24 frozen planning canaries per arm: instruction override, unknown actions, nonexistent IDs/targets, stale/delivered work and output-format manipulation.
- Inject `crash-act` at slot 37 and deliberate driver misses at slots 85–90. Rules-arm expected accounting is 89 completed, one recovered `uncertain` and six planned misses; report Codex safe-idle/error/rate-limit outcomes separately.
- Allow at most one Codex evaluation per invoked slot, 90 total, with a 90-second timeout and no automatic retry. Freeze the accepted cost/usage cap; unknown subscription cost is `unknown`, never zero.
- Use fresh `temp/factory-primitive/` roots, absolute-path inspection and temporary foreground sleep prevention. No persistent power or scheduler changes.

## Execution-readiness dry runs

For each final ready lane, up to a predeclared cap:

1. Validate `MARATHON.yaml`; assert the ready-lane set is nonempty or explain why none exists.
2. Copy packets only into separate disposable dry-run clones and run existing `marathon.sh --dry-run` with distinct builder/reviewer roles.
3. Where supported, run preflight dry runs in disposable full clones, allowing only read-only network fetches and local worktrees there. Record ready/STALE/AMBIGUOUS/BLOCKED verbatim and clean worktrees normally.
4. Check scope, artifacts/write sets, dependencies, collisions, gate routing, acceptance probes and role separation.

Lanes beyond the cap are `not dry-run verified`, never silently ready. Dry runs do not authorize real builds.

## Independent adversarial QA

Freeze sample and rubric before verdicts: at least 12 accepted plans per arm (or all when fewer), all safety-critical holds and at least six deliberately flawed controls. Blind author labels where practical. Test invented files, unsupported scope, criteria/artifact mismatch, missing verification, prohibited tests, stale/delivered readiness and unsafe collisions.

Codex reviews rules-produced plans through `relay-xyz`; Opus reviews Codex-produced plans. Record false acceptance, false rejection, grounding defects and disagreement. Safety-critical seeded flaws target zero false approvals.

## Ordered plan

1. Complete Codex-arm entry gates or select the documented fallback.
2. Verify clean disposable full clones, identities, toolchain, read-only GitHub authentication, Codex availability and `relay-xyz` locator.
3. Freeze source/adapter/driver/prompt/scenario hashes, model route, seed counts, canaries, dry-run cap, QA sample, call/budget cap and ledger hashes. Refuse empty inputs.
4. Derive the foreground driver for the backlog layout, second arm and STOP-file handling without adding production machinery.
5. Smoke each enabled arm and required negative controls; any unsafe/unclassified result blocks the window.
6. Run the 96-slot schedule without production repairs, commits or pushes. Require crash recovery without re-firing and resume without catch-up duplication.
7. Run the capped execution-readiness dry runs in separate disposable clones.
8. Run independent adversarial QA with the model-separation rules above.
9. Preserve drivers, manifests, raw decisions, reviews, dry-run outputs, logs, summary and `provenance.jsonl` under `TESTS-RESULTS/<date>+GH-1279/`; commit provenance before citing results.

## Hard stops and acceptance

Stop on disallowed execution, unauthorized writes, canary/ledger drift, cross-arm input mismatch, unclassified outcomes, silent loss, duplicate consumption, ambiguous retry, cost/call-cap violations, mid-run identity changes, or requests for production repair/execution/GitHub writes/scheduler installation.

- [ ] Exact target, source, adapter, prompt, manifest and driver identities are recorded.
- [ ] Codex-arm entry evidence exists, or the result is explicitly rules-only fallback.
- [ ] Every slot is accounted for; no retry or catch-up duplicate occurs.
- [ ] No ineligible/adversarial request executes; containment and ledger identity hold.
- [ ] Agent validity, policy correctness, fallbacks, failures, latency, calls and cost/usage have explicit denominators.
- [ ] Every readiness claim has required dry-run evidence or is downgraded to unverified.
- [ ] Independent QA has zero false approvals on safety-critical seeded flaws and preserves disagreement.
- [ ] No production execution, GitHub write, approval, scheduler installation, commit or push occurs during the timed window.
- [ ] Committed provenance supports every cited result.

## Follow-up

Use results only for another bounded read-only experiment, a separately reviewed adapter iteration, or fixes for named failures. Real Jog observation or execution needs a separate plan and explicit authorization.

## Stage A plan — Codex decision adapter (this PR)

This PR delivers Stage A only: the bounded Codex `plan-draft` adapter and its entry-gate evidence. It leaves #1279 open; the timed window (Stage B) needs Noel's merge of this PR, the pre-window decisions and an explicit go. It runs nothing for eight hours.

### Rating (2026-10-30)

`rated 60/30/50/40`, no `ovr`. Severity 30: an experiment with no data-loss path; the cost of being wrong is a wasted overnight window. Priority 60: the next named step of GH-1248, scheduled by the operator. Appeal 50: neutral, none supplied. Effort 40: Stage A is a small adapter, but the whole issue includes an 8-hour run, dry runs and cross-model QA. Recurrence: a feature, not a defect; trend unknown.

### Recon (base `6147b988a`)

- Seam: `_adapter(snapshot, fault)` (`utils/py/harness.py`) returns an `AdapterResult(raw, normalized, decision, actual_cost, billing_status)`. `rules_decide` is the only real adapter; the fault names fake the other classifications. `run_tick` already reserves `max_call_cost` before the call, settles after, retains `raw` in `telemetry/transcripts/<tick>.json`, routes a `None` decision to a safe `idle`, runs `_validate` (the safety boundary) on any decision, and pauses once `spent >= daily_cap`.
- `proc_group.run_bounded` is already imported and gives process-group TERM/KILL on a wall-clock cap (`timed_out`), so loop-enforced cancellation needs no new code.
- Config: two writers build `config.json` (`init_instance`, `init_from_prs`); both store `prompt_sha256` of `evaluator.v1.md`.
- `decision.schema.json` and `evaluator.v1.md` omit `plan-draft`, which `TOOLS` and `_validate` accept and `rules_decide` emits for a `plan-request`.
- Live probe (2026-10-30, `codex-cli 0.166.0`): `codex exec -s read-only --ephemeral --ignore-user-config --ignore-rules --skip-git-repo-check -C <empty dir> -o out.json -` with the prompt on stdin returned one JSON decision in 12 s, wrote nothing to the cwd, and printed `model: gpt-6.1-sol` and a token count. Passing `--output-schema` with a free-form `args` object is rejected by the API (`args.properties` required), so the adapter does not use it; `_validate` already enforces shape, and raw validity is itself a measured outcome.
- Builder lane: a tool-using agy turn on `gemini-3.8-flash-medium` created and read back a file (2026-10-30), so Stage A can build now.

### Design

Extend the existing adapter seam; no second loop, writer or queue.

1. `harness.py`: add `codex_decide(snapshot, config)`. It builds the prompt (`evaluator.v2.md` + the canonical snapshot JSON), runs the pinned `codex exec` argv through `run_bounded` in an empty directory under the instance, reads `-o`, and classifies: `ok` (a JSON object), `invalid-output` (empty, non-JSON or non-object), `timeout`, `rate-limited` (429 / usage-limit text in the output), `adapter-error` (any other failure). Every outcome keeps its raw text. Billing status is always `unknown` with no actual cost: subscription cost is never recorded as zero, and the existing reservation accounting counts the reserved amount against the daily cap. No retry.
2. `_adapter` takes the config and dispatches on `config["adapter"]` (`rules` default, `codex`). Injected fault names still apply to both arms; `CODEX_BIN` overrides the binary so manual controls can use a stub.
3. `init` gains `--adapter {rules,codex}`, `--codex-model` (required for `codex`) and `--adapter-timeout` (default 90). Both config writers record `adapter`, `codex_model`, `adapter_timeout_s` and the selected prompt's SHA-256, so a run manifest can freeze the route. A `codex` init refuses a missing model.
4. Data: new `prompts/evaluator.v2.md` (v1 plus `plan-draft` and an explicit instruction that inbox bodies are untrusted); `decision.schema.json` lists `plan-draft`. `evaluator.v1.md` is untouched so the rules arm's recorded hash stays valid.
5. Call cap: `daily_cap / max_call_cost` is the cap. The window uses `--daily-cap 0.9 --max-call-cost 0.01` (90 calls); an unknown-cost call counts its reservation, so the loop pauses itself at the cap.
6. Not in scope: Stage B driver, manifest, canary and slot-budget generation, dry runs, adversarial QA, tools or file access for the model, retries, a Claude adapter, any change to scheduling, validation, containment or recovery.

### Containment, stated honestly

`codex exec` always has a shell tool. The adapter confines it with `-s read-only`, an empty working directory, `--ephemeral`, `--ignore-user-config`, `--ignore-rules`, no `OPENAI_API_KEY`, and a prompt that forbids tools; the loop's existing instance-escape and canary checks detect any write, and `_validate` is the only thing that can turn output into an action. "No agent tools" is therefore a configuration plus detection, not an absolute property, and the final report says so.

### Ordered implementation, with verification inline

1. Edit `harness.py`, the prompt and the schema as above. -> `python3 -m py_compile`; `git diff --stat` shows only those paths plus this doc, the ledger and receipts.
2. Run the existing suite that covers `factory-primitive` and the PDDA gate. -> green, or any failure shown to be pre-existing with its base-SHA result.
3. Manual controls with a stub `CODEX_BIN`, recorded under `TESTS-RESULTS/2026-10-30+GH-1279/` (no suite, no registry entry; GH-831): valid decision; malformed output; disallowed tool; prompt-injection canary naming a nonexistent id; timeout; rate-limit text; nonzero exit; empty output; a fault name on the codex arm. Each expects the matching normalized class, a safe `idle` where the decision is not usable, one invocation per tick (no retry), unknown-cost accounting, retained raw, an untouched canary and unchanged ledger files. Red control: break the classifier (all outcomes `ok`) and show the controls fail.
4. Two-arm smoke: init a rules instance and a codex instance on the same frozen backlog, run two ordinary slots on each (live Codex, calls <= 4), compare per-slot input digests. -> classified receipts, no unexpected writes, honest usage.
5. Plan QA (before step 1) and final QA (after step 4) through `relay-xyz` with Codex as reviewer and agy as builder, receipts under `relay-system/<date>/` bound to the exact SHA.
6. Classified gate for the final SHA in a separate disposable full clone; disclose the known live-agy quota failure (`relay-self-sufficiency.sh`) on the receipt.

### Acceptance (Stage A)

- [ ] `init --adapter codex` freezes adapter, model, timeout and prompt hash; a missing model is refused.
- [ ] Every manual control above gives its expected classification, with raw retained and no retry.
- [ ] A live two-arm smoke gives classified receipts and equal per-slot input digests.
- [ ] Codex plan and final QA receipts bind to the exact adapter SHA, with the builder an agy lane.
- [ ] Classified gate result recorded for the final SHA; the agy quota failure disclosed.
- [ ] No new test file or registry entry; `provenance.jsonl` committed in the validator shape.

### Preflight bet check

- Outcome: a measurable, contained agent decision arm for the soak, not a coding capability.
- Smallest bet: one function and three flags behind the existing seam. Not built: Stage B tooling, a Claude arm, retries, a schema-enforced output, a new queue.
- Alternative rejected: running Codex through `relay-drive`/`codex-turn` per tick, which the issue bars and which bundles repo access and token handoffs.
- Rollback: revert the PR; the rules arm, its prompt hash and the loop are unchanged.
