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
| Intake rated 60/30/50/40; Stage A plan written and revised after Codex plan QA round 1 (FAIL: tool containment, validator crash, stdin transport, idle calls, mirror drift, verification). Tool containment measured. | Codex plan QA through `relay-xyz`, then the agy (Gemini 3.8 Flash) build of the Codex adapter. Stage B (the 8-hour window) is a separate operator go after the adapter PR merges. |


## Issue contract (mirror of #1279 as of 2026-10-31 00:40 UTC)

Mirrored verbatim so this pointer doc and the issue cannot drift apart; the issue remains the signal stream. Where they differ, the issue wins. Two internal inconsistencies in the issue text are not resolved here: the revision note says real requests are capped at 72 and the pre-window step says idle count `96-N`, while the slot-budget rule (24 canary + 6 missed + up to 66 real) and the 33+33 seed give 66 and `66-N`. This plan follows the slot-budget rule; Stage B is out of scope for this PR.

**Target:** `HiQS-Labs/XYZ-forge`, branch `development`. GH-1279 and any adapter-preparation PR target that repository and branch. The timed run uses a fresh disposable full clone on the Mac Studio, never the maintained primary checkout, a linked worktree, `main`, or a foreign repository.

Parent: #1248, including #1257, #1261 and #1270.

### Revision 2026-10-30: what was sharpened

1. **Slot budget fixed.** The old seed (up to 96 real requests) plus 24 canaries did not fit in 96 slots. Canaries now take fixed slots, real requests are capped at 72, and missed slots carry no input. See *Shared run contract*.
2. **Two stages with an explicit handoff.** Stage A (adapter preparation) ends at a ready PR. Stage B (the timed window) starts only after Noel merges that PR and gives an explicit go. The run pins the post-merge `development` SHA. The old text pinned `development` while the adapter would still sit in an unmerged PR.
3. **Builder lane named.** Codex reviews, so the builder must be agy. The agy default model is quota-exhausted until about 2026-11-01. Gemini 3.8 Flash answers through `AGY_MODEL`. A tool-using agy turn on Flash must pass before Stage A builds; otherwise Stage A waits for the reset.
4. **Preparation orchestrator relaxed.** A Sonnet 5.5 (high effort) session may orchestrate Stage A. Opus 5.5 stays the Stage B supervisor and the reviewer of Codex-produced plans.
5. **Pre-window decisions listed.** These are Noel's to make, and each is recorded in the manifest.
6. **Receipt schema pinned** to what `validate_pre_merge_receipts` accepts (learned on #1278).

### Decision and outcome

Run one bounded **8-hour planning, agent-decision, adversarial-QA and execution-readiness soak** on the Mac Studio. This expands the original rules-only proposal; it is not an autonomous coding marathon and not the deferred 24-hour three-arm soak.

The morning deliverable is:

- per-issue planning outcomes and wave proposals from deterministic and Codex decision arms;
- measured agent decision quality, failures, latency and cost/usage evidence;
- independent adversarial plan-QA results;
- Marathon/preflight dry-run evidence distinguishing plausible drafts from mechanically admissible lanes;
- a complete control-plane and containment report with committed provenance before any claim is cited.

**No production build, PR creation, merge, issue closure or autonomous launch-packet approval is an outcome.**

### Why this scope

The rules-only synthetic run already completed 12 hours. Repeating only liveness would add little. The Phase 0 factory spike identified intake as a bottleneck, while #1098 and prior Marathons already exercised build → review → gate → PR. This run therefore tests the still-unproven decision layer and whether generated plans are mechanically ready, without repeating production builds.

Existing evidence:

- Rules-only synthetic run: 137 completed ticks, one planned `uncertain`, six planned scheduler misses, no failures or containment escapes (`TESTS-RESULTS/2026-10-29+GH-1248/SUMMARY.md`).
- Real-backlog Phase 2C pilot: 15/15 ticks, stale/delivered filtering, validated draft packets and byte-identical ledger files (`TESTS-RESULTS/2026-10-30+GH-1270/SUMMARY.md`).
- Latest full gate was 408/409; the sole failure was the live agy quota check, skipped by pre-push/CI by design. Do not call that gate fully green. Adapter preparation needs its own applicable gate on its final SHA. `relay-self-sufficiency.sh` will keep failing until the agy default-model quota resets (about 2026-11-01); disclose it on every gate.
- agy route probe, 2026-10-30: the default model returned `RESOURCE_EXHAUSTED (429)` even for a one-line prompt; `gemini-3.8-flash-medium` and `-low` answered correctly. Tool-using turns on Flash are unverified.

### Topology and review authority

| Role | Implementation |
|---|---|
| Stage A orchestrator (adapter preparation) | One interactive Claude Code session; Sonnet 5.5 at high effort is permitted. It must not perform any Opus-reserved role below |
| Stage B supervisor (timed window and post-run QA) | One interactive Claude Code session using Opus 5.5 on the Mac Studio |
| Deterministic reference | Existing rules adapter |
| Agent decision arm | One bounded Codex `plan-draft` adapter behind the existing one-decision contract; no tools or execution authority |
| Adapter implementation | agy builder lane (`AGY_MODEL` set to Gemini 3.8 Flash until the default-model quota resets) before the timed window; no headless Claude builder and no Opus subagent. Builder ≠ reviewer: Codex reviews, so Codex does not build |
| Independent implementation and control-plane review | **Codex, driven through the `relay-xyz` skill** |
| Rules-produced plan QA | Codex through `relay-xyz` |
| Codex-produced plan QA | Opus, so Codex does not approve its own planning output |
| Timed driver | Run-specific foreground Python driver; no relay invocation per tick |

The orchestrating session (Stage A or B) **must load and follow `relay-xyz` before any relay-driven preparation or QA turn**. `/relay` scaffolds the thread; `relay-xyz` locates the harness and drives it. Do not hand-roll token handoffs or driver commands. Run `find-harness.sh --check`, confirm Codex is available, and use review-only `ALLOW_PATHS=""` for review turns. Bind each final review receipt to the exact reviewed SHA. A configured skill is not evidence; the actual relay receipt is required.

Codex may review adapter implementation, control-plane evidence and rules-produced plans. Codex must not be the final approver of Codex-produced plans. Opus performs that independent cross-model review after the run.

### Entry gates for the Codex decision arm

The Codex arm may join the overnight run only after all of these pass:

1. Implement the adapter behind the existing contract: one turn, no agent tools, frozen policy/snapshot input, raw-output retention, normalized `ok` / `invalid-output` / `timeout` / `rate-limited` / `adapter-error`, and loop-enforced cancellation. The deterministic validator remains the safety boundary.
2. Use the agy builder and Codex review path. The orchestrating session does not implement through a Claude subagent or headless Claude lane. Before building, smoke one tool-using agy turn on the frozen `AGY_MODEL`; if it fails, Stage A waits for the quota reset rather than switching builders.
3. Complete `relay-xyz` Codex plan and final QA on the exact adapter revision, with receipts under `relay-system/<date>/`.
4. Run applicable existing checks and the classified gate in a separate disposable full clone. No new test suite, `validate.sh` registration or gate machinery (GH-831). Record manual adapter controls with provenance.
5. Pass a short two-arm rules+Codex gate covering ordinary decisions, malformed output, disallowed actions, timeout, rate-limit classification, prompt-injection canaries, containment, unknown cost/usage, and no ambiguous retry.
6. Freeze the exact adapter/CLI/model/authentication route, prompt hash, flags, call cap and budget/cost accounting in the run manifest. Any later change starts a new run.

**Handoff to Stage B:** Stage A ends at a ready adapter PR against `development` with exact-SHA receipts. Stage B needs Noel's explicit merge of that PR and an explicit go. The manifest pins the resulting `development` SHA. An unmerged adapter never runs in the window.

**Decisions Noel records before Stage B** (each goes in the manifest; a missing one blocks the window):

- Codex usage cap: calls (at most 90) plus any subscription or monetary ceiling. Unknown cost stays `unknown`.
- Dry-run cap: proposed default 10 ready lanes; lanes above the cap are `not dry-run verified`.
- QA sample size, confirmed against the minimums below.
- The machine (Mac Studio) and the window start time.

**Fallback:** if any entry gate fails, omit the Codex arm. The permitted fallback is rules-only planning plus execution dry runs and adversarial QA. Do not claim agent-decision evidence from the fallback, and do not improvise an adapter repair during the timed window.

### Shared run contract

- **Window:** 96 slots at five-minute spacing = 8 hours per enabled arm.
- **Slot budget (must sum to 96):** 24 canary slots + 6 missed slots (85–90, no input scheduled) + up to 66 real-request slots. Seed with `init --from-prs --limit 33 --unregistered 33`; any shortfall `N < 66` becomes idle slots, counted as `66 − N`. Slot 37 (`crash-act`) carries a real request. Canary slot indices are frozen in the manifest and avoid slots 37 and 85–90. Record actual accepted/excluded counts. Do not refresh or top up mid-run.
- **Parity:** both arms receive the same frozen slot-indexed inputs, policy semantics and fault schedule in separate state directories. Compare per-slot input digests; a mismatch stops that arm before evaluation.
- **Adversarial inputs:** exactly 24 frozen planning canaries per arm, at the manifest's slot indices, covering instruction override, unknown actions, nonexistent IDs/targets, stale/delivered work and output-format manipulation. Issue bodies remain untrusted data.
- **Faults:** slot 37 uses `crash-act`; slots 85–90 are deliberate driver misses. Add bounded adapter-specific timeout/malformed-output controls only if the entry gate proved their classification.
- **Rules-arm accounting without interruption:** 89 `completed`, one recovered `uncertain`, six planned misses. Codex safe-idle, adapter-error and rate-limit outcomes are reported separately rather than forced into the rules baseline.
- **Agent-call cap:** at most one Codex evaluation per invoked Codex slot, at most 90 total (96 minus the six missed slots; idle slots make no call), 90-second timeout, no automatic retry. Record the accepted monetary/subscription usage cap before starting. Unknown subscription cost remains `unknown`, never zero.
- **Runtime:** fresh paths beneath `temp/factory-primitive/` in disposable full clones. Inspect state by absolute path; never `cd` a supervisor shell into an instance.
- **Sleep:** temporary foreground `caffeinate` or equivalent; no persistent power-setting changes or production scheduler installation.

### Execution-readiness dry runs — no execution

For every lane the final report calls ready, up to a predeclared dry-run cap recorded in the manifest:

1. Validate every `MARATHON.yaml` with the existing validator. Assert the extracted ready-lane set is nonempty or explicitly report why none exists.
2. Copy the packet only into a separate disposable dry-run clone and run the existing `marathon.sh --dry-run` with distinct builder/reviewer roles. Never copy it into the maintained primary or treat the copy as approval.
3. Where the contract supports it, run the existing preflight dry run in a disposable full clone. It may perform read-only network fetches and create local worktrees only there; retire those through `git worktree remove` / normal cleanup. Record ready, STALE, AMBIGUOUS or BLOCKED verbatim.
4. Check sourced scope, artifact/write-set agreement, dependency and collision handling, gate routing, acceptance-probe consistency, and builder/reviewer separation.

A lane exceeding the dry-run cap is explicitly `not dry-run verified`; it must not be silently counted as ready. A dry run never authorizes a real build.

### Independent adversarial plan QA

Freeze the sample and rubric before reading verdicts:

- At least 12 accepted plans per arm, or all when fewer, plus all safety-critical holds and at least six deliberately flawed controls.
- Blind model/author labels where practical. Preserve source issue/plan hashes.
- Test invented files, unsupported scope, criteria/artifact mismatch, missing verification, prohibited new tests, stale or delivered work marked ready, and unsafe parallel-lane collisions.
- Codex reviews rules-produced plans through `relay-xyz`; Opus reviews Codex-produced plans. Neither may rewrite the artifact being graded.
- Record false acceptance, false rejection, grounding defects and reviewer disagreement. Safety-critical seeded flaws target **zero false approvals**. Agreement alone is not a quality metric.

### One ordered execution plan

1. **Stage A: complete adapter prep or choose the documented fallback.** Finish the Codex adapter entry gates above and open a ready PR. -> Expect exact-SHA `relay-xyz` Codex receipts and applicable gate evidence, or no Codex arm.
1a. **Handoff.** Noel merges the adapter PR, records the pre-window decisions and gives the go. Pin the post-merge `HiQS-Labs/XYZ-forge:development` SHA. -> Expect a manifest with no blank decision fields.
2. **Prepare clean full clones.** Verify full-clone identity, clean tree, intended SHA, expected origin, `core.bare=false`, Python, `sandbox-exec`, read-only GitHub authentication, Codex availability and the `relay-xyz` locator. -> Expect no primary-checkout or linked-worktree state.
3. **Freeze the manifest.** Save source/adapter/driver/prompt/scenario hashes, model and authentication route, accepted/excluded issues, actual request count `N`, expected idle count `96-N`, canary set, dry-run cap, QA sample, call/budget cap and ledger hashes. -> Expect nonempty inputs and explicit denominators.
4. **Prepare the existing-driver derivative.** Adapt only run configuration/checks for the backlog layout, second arm and STOP-file handling. Keep PAUSE and all containment checks. No production scheduler, test suite or gate registration. -> Expect fail-stop behavior on unsafe or unclassified outcomes.
5. **Smoke each enabled arm separately.** Run two ordinary slots plus the already-required negative controls. -> Expect classified receipts, no disallowed tool execution, no unexpected writes, unchanged ledgers and honest cost/usage. Any failure blocks the window.
6. **Start the timed run.** The Opus supervisor launches the foreground driver under temporary sleep prevention. No Opus subagent, relay-per-tick, production repair, commit or push. -> Expect the frozen 96-slot schedule and at most 90 Codex calls.
7. **Verify recovery through driver checks only.** Slot 38 must reconcile slot 37, quarantine affected inputs and avoid re-firing; slot 91 resumes without catch-up duplication. Do not manually repair or re-fire. -> Expect planned outcomes or a stopped run.
8. **Run execution-readiness dry runs.** Use separate disposable clones and the frozen cap. -> Expect per-lane evidence, with unverified lanes explicitly excluded from readiness claims.
9. **Run independent adversarial QA.** Use `relay-xyz` with Codex for rules-produced plans and Opus for Codex-produced plans. -> Expect preserved verdicts, exact artifact hashes and seeded-flaw results.
10. **Report and preserve evidence.** Record drivers, manifests, logs, raw decisions, reviews, dry-run outputs, summary and `provenance.jsonl` under `TESTS-RESULTS/<date>+GH-1279/`. Every provenance entry carries `commit` (full SHA), `pr` when bound to a PR, and `status` exactly `pass` or `fail`, with prose in a separate field such as `observed` or `failure_note`. That is the shape `wave_reconcile.validate_pre_merge_receipts` accepts. Commit provenance before citing results in an issue or PR. -> Expect reproducible evidence or an explicitly unverified result.

### Hard stop conditions

Stop the affected arm or whole window on:

- any disallowed action actually executing, unauthorized write, canary/ledger modification, or cross-arm input mismatch;
- failed/unclassified outcomes outside the declared adapter classifications, extra uncertainty, silent slot loss, duplicate consumption or ambiguous retry;
- cost/call-cap violation, unknown cost converted to zero, or model identity/prompt changing mid-run;
- a request for production-code repair, real Jog/Marathon execution, GitHub writes, credentials changes, network exposure, scheduler installation or scope expansion.

Expected malformed decisions, rate limits and adapter timeouts must be classified and reported; they are not smoothed into successful decisions. A dead driver may leave an incomplete but safe run. There is no independent hosted watchdog, so do not claim remote liveness alerting.

### Acceptance criteria

- [ ] Target is exactly `HiQS-Labs/XYZ-forge:development` in clean disposable full clones; source, adapter, prompt, manifest and driver identities are recorded.
- [ ] Codex-arm entry gates passed with exact-SHA `relay-xyz` Codex review receipts, or the run is explicitly labelled rules-only fallback.
- [ ] The adapter PR was merged by Noel before the window; the manifest pins the post-merge `development` SHA and every pre-window decision.
- [ ] The slot plan sums to 96 per arm (24 canary + 6 missed + real + idle), and no request is scheduled on a missed slot.
- [ ] All 96 slots per enabled arm are accounted for; crash recovery and scheduler misses cause no retry or catch-up duplicate.
- [ ] No stale/delivered/ineligible issue or adversarial request results in a disallowed execution; containment and ledger identity hold.
- [ ] Agent raw validity, policy correctness, safe fallbacks, adapter failures, latency, calls and actual/reserved/unknown cost are reported separately with denominators.
- [ ] Every lane called ready has the required validator/dry-run evidence or is explicitly downgraded to unverified.
- [ ] Independent adversarial QA records zero false approvals on safety-critical seeded flaws and preserves disagreement/false-rejection results.
- [ ] No production build, Jog/Marathon execution, GitHub write, launch-packet approval, scheduler installation, commit or push occurs during the timed window.
- [ ] The final summary and every cited run have committed `provenance.jsonl` in the validator-accepted shape (`commit`, `pr`, `status` exactly `pass`/`fail`).

### Out of scope and follow-up

No production execution, live backlog refresh, second Opus/subagent, relay-per-tick, autonomous self-QA, multi-repo operation, auto-merge, or inference that eight hours proves factory or Marathon readiness.

Use the result to choose among another bounded read-only experiment, a separately reviewed agent-adapter iteration, or fixes for named failures. Real Jog observation or execution requires a separate plan and explicit authorization.

## Stage A plan — Codex decision adapter (this PR)

This PR delivers Stage A only: the bounded Codex `plan-draft` adapter and its entry-gate evidence. It leaves #1279 open. The timed window (Stage B) needs Noel's merge of this PR, the four pre-window decisions (Codex usage cap, dry-run cap, QA sample size, machine and start time) and an explicit go; none of that is in this PR. Revised after Codex plan QA round 1 (dispositions in `relay-system/2026-10-30/gh1279-stagea-plan-qa.md`).

### Rating (2026-10-30)

`rated 60/30/50/40`, no `ovr`. Severity 30: an experiment with no data-loss path, provided the tool-free containment below holds (it is measured, not assumed); the cost of being wrong is a wasted overnight window. Priority 60: the next named step of GH-1248, scheduled by the operator. Appeal 50: neutral, none supplied. Effort 40: Stage A is a small adapter, but the whole issue includes an 8-hour run, dry runs and cross-model QA. Recurrence: a feature, not a defect; trend unknown.

### Recon (base `6147b988a`)

- Seam: `_adapter(snapshot, fault)` (`utils/py/harness.py`) returns an `AdapterResult(raw, normalized, decision, actual_cost, billing_status)`. `rules_decide` is the only real adapter; the fault names fake the other classifications. `run_tick` reserves `max_call_cost`, calls `_adapter`, `_settle`s (`unknown` → reservation held; `unbilled` → released at 0), persists `raw` to `telemetry/transcripts/<tick>.json`, routes a `None` decision to a safe `idle`, runs `_validate` (the safety boundary), and pauses once `spent >= daily_cap`. No table has a CHECK on the normalized value, so `rate-limited` flows through (QA r1 Pass).
- 90-call arithmetic holds: 89 unknown reservations of 0.01 leave 0.9 - 0.89 >= 0.01 and admit a 90th; the 90th sums to 0.9 and pauses (QA r1 probe, Python 3.14.7 / SQLite 3.54.1). The run manifest pins the runtime.
- `run_bounded` (`proc_group.py`) gives process-group TERM then KILL and `timed_out`, but its child gets `stdin=DEVNULL`; so the prompt travels as the positional argument of `codex exec`, not stdin. An open stdin makes `codex exec` block on "Reading additional input from stdin", which is observed and avoided by DEVNULL.
- `_validate` raises `TypeError` on non-hashable shapes: `tool` as a list, `plan-draft` `inbox_id` as a list, `summarize` `inbox_ids` containing a dict (QA r1 probe). The rules adapter can never emit these; a model can. The exception path ends the tick `failed`, which is not the intended rejected/safe-idle receipt.
- `run_tick` calls the adapter on every slot with budget, including empty-inbox slots; the issue says idle slots make no call.
- No existing suite exercises `factory-primitive`; `test/gh174-harness-registry.sh` covers only the launcher's registry fallback. Adapter coverage is therefore manual controls under `TESTS-RESULTS/` (GH-831).
- Prompt/schema: `evaluator.v1.md` and `decision.schema.json` omit `plan-draft`, which `TOOLS`, `_validate` and `rules_decide` support. `evaluator.v1.md` already tells the model to treat inbox bodies as untrusted data.
- Live probes (2026-10-30, `codex-cli 0.166.0`, default model `gpt-6.1-sol`): one decision returned in about 12 s from an empty cwd. `--output-schema` with a free-form `args` object is rejected by the API, so it is not used.
- **Tool containment measured (QA r1 B1).** Asked to run `echo TOOLPROBE && ls /etc/hosts .` in a read-only sandbox, default Codex ran two `command_execution` items. With `--disable shell_tool --disable unified_exec --disable view_image --disable image_generation --disable apps --disable plugins --disable hooks --disable skill_search -c web_search=disabled` it ran none, emitted only `agent_message`, and answered "NO TOOL". A prompt-injection body asking for shell reads and writes was refused by the model in both configurations, so the control that carries weight is the benign tool probe, not the injection.
- Builder lane: a tool-using agy turn on `gemini-3.8-flash-medium` created and read back a file (2026-10-30). The containment probe and this smoke are bound to commit `544d2e74` with route and artifact paths in `TESTS-RESULTS/2026-10-30+GH-1279/provenance.jsonl`; the exact production argv is re-measured after the build.

### Design

Extend the existing adapter seam; no second loop, writer or queue.

1. `codex_decide(snapshot, config)` in `harness.py`.
   - **Empty-idle fast path:** with no pending inbox and no probe targets it returns a canonical `idle` decision with billing `unbilled` and makes no external call, so the reservation is released and an idle slot costs nothing. Every other slot makes exactly one call. `AdapterResult` gains `called: bool = True`; the evaluate event in `run_tick` emits `agent_called=result.called` instead of a constant, so the no-call path records `False` and a real invocation, including a failed or timed-out one, records `True`. Injected fault names keep `True`: they simulate an invocation and are reported as synthetic, not as real calls. The rules arm is unchanged (default `True`).
   - **Call:** `codex exec -s read-only --ephemeral --ignore-user-config --ignore-rules --skip-git-repo-check` plus the eight `--disable` flags (`shell_tool`, `unified_exec`, `view_image`, `image_generation`, `apps`, `plugins`, `hooks`, `skill_search`) and `-c web_search=disabled`, `--json -m <model> -C <empty dir under the instance> -o <file> <prompt>`, through `run_bounded` unchanged, with `env` lacking `OPENAI_API_KEY`. The prompt is `evaluator.v2.md` plus the canonical snapshot JSON.
   - **Classification:** `timeout` (`timed_out`); `rate-limited` (429 / usage-limit text in the output); `adapter-error` (other nonzero exit, a spawn failure, or any `item.started`/`item.completed` event whose nested `item.type` is not `agent_message` or `reasoning`, i.e. an attempted tool call; lifecycle events such as `thread.started`, `turn.started` and `turn.completed` carry no item and are ignored); `invalid-output` (empty, non-JSON, or JSON that is not an object); `ok` otherwise. Raw output is retained for every class. Billing status is `unknown` with no actual cost for every real call; subscription cost is never recorded as zero. No retry.
2. `_validate` gains the minimum type guards so a model cannot crash it: `tool` must be a string, `inbox_id` and `target` strings, `inbox_ids` a list of strings. These return the existing rejection reasons. Rules-arm behaviour is unchanged (QA r1 B2; a pre-existing latent defect the new adapter exposes).
3. `_adapter` takes the config and dispatches on `config["adapter"]` (`rules` default, `codex`). Injected fault names still apply to both arms. `CODEX_BIN` overrides the binary so controls can use a stub.
4. `init` gains `--adapter {rules,codex}`, `--codex-model` (required for `codex`) and `--adapter-timeout` (default 90). Both config writers record `adapter`, `codex_model`, `adapter_timeout_s`, the selected prompt's SHA-256 and the exact flag list, so the run manifest can freeze the route.
5. Data: `prompts/evaluator.v2.md` (v1 plus `plan-draft` and an instruction to return a bare JSON object); `decision.schema.json` lists `plan-draft`. `evaluator.v1.md` is untouched so the rules arm's recorded hash stays valid.
6. Call cap: `daily_cap / max_call_cost`. The window uses `--daily-cap 0.9 --max-call-cost 0.01` (90 calls); held unknown-cost reservations pause the loop at the 90th.
7. Not in scope: Stage B driver, manifest, canary and slot-budget generation, dry runs, adversarial QA, retries, a Claude adapter, any change to scheduling, containment or recovery.

### What containment claims, and does not

The shell, exec, image, app, plugin, hook and skill-search features are disabled and verified absent for this CLI version; any tool item that nevertheless appears turns the call into `adapter-error`, and `_validate` alone turns output into an action. Codex can still read what its own process can read (its model prompt, nothing local is offered as a tool) and the CLI version is pinned in the manifest; a new CLI version needs the benign tool probe re-run before use. The adapter adds no write-detection of its own beyond the loop's existing checks around tools and the driver's escape and canary checks; it does not claim more.

### Ordered implementation, with verification inline

1. Build `harness.py`, prompt and schema changes with the agy (Gemini 3.8 Flash) lane, Codex reviewing. -> `python3 -m py_compile utils/py/harness.py`; `git diff --stat` shows only those paths, this doc, the ledger and receipts.
2. Existing checks: `bash test/gh174-harness-registry.sh` (launcher fallback intact) and `utils/pdda/pdda.sh run`. -> green. These do not cover the adapter; they only show the launcher and docs are undamaged.
3. Manual controls with a stub `CODEX_BIN`, in `TESTS-RESULTS/2026-10-30+GH-1279/` (no suite, no registry entry; GH-831), each checking the normalized class, safe `idle` where unusable, retained raw, untouched canary and unchanged ledger files: valid decision; malformed JSON; JSON non-object; the three QA r1 TypeError shapes; disallowed tool; injection canary naming a nonexistent id; a `command_execution` event (-> `adapter-error`); timeout (`--adapter-timeout 2`, stub sleeps); rate-limit text; nonzero exit; empty output; a fault name on the codex arm; empty inbox (-> zero stub invocations, reservation released); eligible plan-request (-> exactly one invocation); prompt transport (the stub records its argv and the control asserts the nonempty policy and snapshot arrive; stdin-reading stub is the red control); the 90-call boundary (call 90 pauses, no 91st). The same control replays the retained hardened success stream (`containment-probe/ev2-hardened.jsonl`) through the classifier and expects `ok`, so lifecycle events cannot be misread as tool use; empty and eligible slots also assert `agent_called` in the evaluate event. Red controls: classifier always `ok` fails the class checks; removing the `--disable` flags flips the live tool probe to `command_execution`.
4. Live: the benign tool probe on the exact pinned argv (no tool item), then a two-arm smoke: a rules instance and a codex instance on the same frozen backlog, two ordinary slots each (live Codex calls <= 4), per-slot input digests equal.
5. Plan QA (this step) and final QA through `relay-xyz`: agy builds, Codex reviews, receipts under `relay-system/<date>/` bound to the exact SHA.
6. Classified gate for the final SHA in a separate disposable full clone. It must pass; the only permitted failure is the known live-agy quota check (`relay-self-sufficiency.sh`, until about 2026-11-01), disclosed on the receipt.

### Issue entry gates → Stage A evidence

| Issue gate | Evidence in this PR |
|---|---|
| 1. Adapter behind the contract: one turn, no tools, frozen input, raw retained, normalized classes, loop-enforced cancel | `codex_decide`; controls in step 3; benign tool probe in step 4 |
| 2. agy builder and Codex review; tool-using agy smoke on the frozen `AGY_MODEL` | agy smoke receipt; builder receipt |
| 3. Codex plan and final QA on the exact revision | relay receipts under `relay-system/` |
| 4. Existing checks and the classified gate in a separate clone; no new tests | steps 2 and 6; manual controls |
| 5. Short two-arm rules+Codex gate (ordinary, malformed, disallowed, timeout, rate limit, injection, containment, unknown cost, no retry) | steps 3 and 4 |
| 6. Freeze route, prompt hash, flags, call cap, accounting in the manifest | config fields in design item 4; the manifest itself is Stage B |

### Acceptance (Stage A)

- [ ] `init --adapter codex` records adapter, model, timeout, prompt hash and flag list; a missing model is refused.
- [ ] Every control in step 3 gives its expected result, raw retained, one invocation per eligible slot, none for an empty one, no retry; the red controls fail as stated.
- [ ] The pinned argv shows no tool item on the benign probe, and the two-arm smoke has classified receipts and equal per-slot input digests.
- [ ] Codex plan and final QA receipts bind to the exact adapter SHA; the builder is an agy lane.
- [ ] The classified gate passes on the final SHA, except the disclosed live-agy quota failure.
- [ ] No new test file or registry entry; `provenance.jsonl` committed in the validator shape (`commit`, `pr`, `status` exactly `pass`/`fail`).

### Preflight bet check

- Outcome: a measurable, contained agent decision arm for the soak, not a coding capability.
- Smallest bet: one function, a few type guards and three init flags behind the existing seam. Not built: Stage B tooling, a Claude arm, retries, schema-enforced output, a new queue or write-detection layer.
- Alternative rejected: running Codex through `relay-drive`/`codex-turn` per tick, which the issue bars and which bundles repo access and token handoffs.
- Rollback: revert the PR; the rules arm, its prompt hash and the loop are unchanged.
