# #1279: Outer loop: 8-hour read-only planning soak on Mac Studio (GH-1248)
updatedAt: 2026-10-31T02:04:03Z

**Target:** `HiQS-Labs/XYZ-forge`, branch `development`. GH-1279 and any adapter-preparation PR target that repository and branch. The timed run uses a fresh disposable full clone on the Mac Studio, checked out at the pinned adapter PR head SHA (no merge required), never the maintained primary checkout, a linked worktree, `main`, or a foreign repository.

Parent: #1248, including #1257, #1261 and #1270.

## Revision 2026-10-30: what was sharpened

1. **Slot budget fixed.** The old seed (up to 96 real requests) plus 24 canaries did not fit in 96 slots. Canaries now take fixed slots, real requests are capped at 72, and missed slots carry no input. See *Shared run contract*.
2. **Two stages with an explicit handoff.** Stage A (adapter preparation) ends at a ready PR. Stage B (the timed window) starts only after Noel gives an explicit go. The run pins the adapter PR's head SHA, pushed to `origin` and not force-pushed after the pin; a merge to `development` is not required first (Noel, 2026-10-31). The old text pinned `development` while the adapter would still sit in an unmerged PR.
3. **Builder lane named.** Codex reviews, so the builder must be agy. The agy default model is quota-exhausted until about 2026-11-01. Gemini 3.8 Flash answers through `AGY_MODEL`. A tool-using agy turn on Flash must pass before Stage A builds; otherwise Stage A waits for the reset.
4. **Preparation orchestrator relaxed.** A Sonnet 5.5 (high effort) session may orchestrate Stage A. Opus 5.5 stays the Stage B supervisor and the reviewer of Codex-produced plans.
5. **Pre-window decisions listed.** These are Noel's to make, and each is recorded in the manifest.
6. **Receipt schema pinned** to what `validate_pre_merge_receipts` accepts (learned on #1278).

## Decision and outcome

Run one bounded **8-hour planning, agent-decision, adversarial-QA and execution-readiness soak** on the Mac Studio. This expands the original rules-only proposal; it is not an autonomous coding marathon and not the deferred 24-hour three-arm soak.

The morning deliverable is:

- per-issue planning outcomes and wave proposals from deterministic and Codex decision arms;
- measured agent decision quality, failures, latency and cost/usage evidence;
- independent adversarial plan-QA results;
- Marathon/preflight dry-run evidence distinguishing plausible drafts from mechanically admissible lanes;
- a complete control-plane and containment report with committed provenance before any claim is cited.

**No production build, PR creation, merge, issue closure or autonomous launch-packet approval is an outcome.**

## Why this scope

The rules-only synthetic run already completed 12 hours. Repeating only liveness would add little. The Phase 0 factory spike identified intake as a bottleneck, while #1098 and prior Marathons already exercised build → review → gate → PR. This run therefore tests the still-unproven decision layer and whether generated plans are mechanically ready, without repeating production builds.

Existing evidence:

- Rules-only synthetic run: 137 completed ticks, one planned `uncertain`, six planned scheduler misses, no failures or containment escapes (`TESTS-RESULTS/2026-10-29+GH-1248/SUMMARY.md`).
- Real-backlog Phase 2C pilot: 15/15 ticks, stale/delivered filtering, validated draft packets and byte-identical ledger files (`TESTS-RESULTS/2026-10-30+GH-1270/SUMMARY.md`).
- Latest full gate was 408/409; the sole failure was the live agy quota check, skipped by pre-push/CI by design. Do not call that gate fully green. Adapter preparation needs its own applicable gate on its final SHA. `relay-self-sufficiency.sh` will keep failing until the agy default-model quota resets (about 2026-11-01); disclose it on every gate.
- agy route probe, 2026-10-30: the default model returned `RESOURCE_EXHAUSTED (429)` even for a one-line prompt; `gemini-3.8-flash-medium` and `-low` answered correctly. Tool-using turns on Flash are unverified.

## Topology and review authority

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

## Entry gates for the Codex decision arm

The Codex arm may join the overnight run only after all of these pass:

1. Implement the adapter behind the existing contract: one turn, no agent tools, frozen policy/snapshot input, raw-output retention, normalized `ok` / `invalid-output` / `timeout` / `rate-limited` / `adapter-error`, and loop-enforced cancellation. The deterministic validator remains the safety boundary.
2. Use the agy builder and Codex review path. The orchestrating session does not implement through a Claude subagent or headless Claude lane. Before building, smoke one tool-using agy turn on the frozen `AGY_MODEL`; if it fails, Stage A waits for the quota reset rather than switching builders.
3. Complete `relay-xyz` Codex plan and final QA on the exact adapter revision, with receipts under `relay-system/<date>/`.
4. Run applicable existing checks and the classified gate in a separate disposable full clone. No new test suite, `validate.sh` registration or gate machinery (GH-831). Record manual adapter controls with provenance.
5. Pass a short two-arm rules+Codex gate covering ordinary decisions, malformed output, disallowed actions, timeout, rate-limit classification, prompt-injection canaries, containment, unknown cost/usage, and no ambiguous retry.
6. Freeze the exact adapter/CLI/model/authentication route, prompt hash, flags, call cap and budget/cost accounting in the run manifest. Any later change starts a new run.

**Handoff to Stage B:** Stage A ends at a ready adapter PR against `development` with exact-SHA receipts. Stage B needs Noel's explicit go; it does not need the PR merged. The manifest pins the PR head SHA, which must already be pushed to `origin` and must not change after the pin. An adapter revision other than the pinned one never runs in the window.

**Decisions Noel records before Stage B** (each goes in the manifest; a missing one blocks the window):

- Codex usage cap: calls (at most 90) plus any subscription or monetary ceiling. Unknown cost stays `unknown`.
- Dry-run cap: proposed default 10 ready lanes; lanes above the cap are `not dry-run verified`.
- QA sample size, confirmed against the minimums below.
- The machine (Mac Studio) and the window start time.

**Fallback:** if any entry gate fails, omit the Codex arm. The permitted fallback is rules-only planning plus execution dry runs and adversarial QA. Do not claim agent-decision evidence from the fallback, and do not improvise an adapter repair during the timed window.

## Shared run contract

- **Window:** 96 slots at five-minute spacing = 8 hours per enabled arm.
- **Slot budget (must sum to 96):** 24 canary slots + 6 missed slots (85–90, no input scheduled) + up to 66 real-request slots. Seed with `init --from-prs --limit 33 --unregistered 33`; any shortfall `N < 66` becomes idle slots, counted as `66 − N`. Slot 37 (`crash-act`) carries a real request. Canary slot indices are frozen in the manifest and avoid slots 37 and 85–90. Record actual accepted/excluded counts. Do not refresh or top up mid-run.
- **Parity:** both arms receive the same frozen slot-indexed inputs, policy semantics and fault schedule in separate state directories. Compare per-slot input digests; a mismatch stops that arm before evaluation.
- **Adversarial inputs:** exactly 24 frozen planning canaries per arm, at the manifest's slot indices, covering instruction override, unknown actions, nonexistent IDs/targets, stale/delivered work and output-format manipulation. Issue bodies remain untrusted data.
- **Faults:** slot 37 uses `crash-act`; slots 85–90 are deliberate driver misses. Add bounded adapter-specific timeout/malformed-output controls only if the entry gate proved their classification.
- **Rules-arm accounting without interruption:** 89 `completed`, one recovered `uncertain`, six planned misses. Codex safe-idle, adapter-error and rate-limit outcomes are reported separately rather than forced into the rules baseline.
- **Agent-call cap:** at most one Codex evaluation per invoked Codex slot, at most 90 total (96 minus the six missed slots; idle slots make no call), 90-second timeout, no automatic retry. Record the accepted monetary/subscription usage cap before starting. Unknown subscription cost remains `unknown`, never zero.
- **Runtime:** fresh paths beneath `temp/factory-primitive/` in disposable full clones. Inspect state by absolute path; never `cd` a supervisor shell into an instance.
- **Sleep:** temporary foreground `caffeinate` or equivalent; no persistent power-setting changes or production scheduler installation.

## Execution-readiness dry runs — no execution

For every lane the final report calls ready, up to a predeclared dry-run cap recorded in the manifest:

1. Validate every `MARATHON.yaml` with the existing validator. Assert the extracted ready-lane set is nonempty or explicitly report why none exists.
2. Copy the packet only into a separate disposable dry-run clone and run the existing `marathon.sh --dry-run` with distinct builder/reviewer roles. Never copy it into the maintained primary or treat the copy as approval.
3. Where the contract supports it, run the existing preflight dry run in a disposable full clone. It may perform read-only network fetches and create local worktrees only there; retire those through `git worktree remove` / normal cleanup. Record ready, STALE, AMBIGUOUS or BLOCKED verbatim.
4. Check sourced scope, artifact/write-set agreement, dependency and collision handling, gate routing, acceptance-probe consistency, and builder/reviewer separation.

A lane exceeding the dry-run cap is explicitly `not dry-run verified`; it must not be silently counted as ready. A dry run never authorizes a real build.

## Independent adversarial plan QA

Freeze the sample and rubric before reading verdicts:

- At least 12 accepted plans per arm, or all when fewer, plus all safety-critical holds and at least six deliberately flawed controls.
- Blind model/author labels where practical. Preserve source issue/plan hashes.
- Test invented files, unsupported scope, criteria/artifact mismatch, missing verification, prohibited new tests, stale or delivered work marked ready, and unsafe parallel-lane collisions.
- Codex reviews rules-produced plans through `relay-xyz`; Opus reviews Codex-produced plans. Neither may rewrite the artifact being graded.
- Record false acceptance, false rejection, grounding defects and reviewer disagreement. Safety-critical seeded flaws target **zero false approvals**. Agreement alone is not a quality metric.

## One ordered execution plan

1. **Stage A: complete adapter prep or choose the documented fallback.** Finish the Codex adapter entry gates above and open a ready PR. -> Expect exact-SHA `relay-xyz` Codex receipts and applicable gate evidence, or no Codex arm.
1a. **Handoff.** Noel records the pre-window decisions and gives the go. Pin the adapter PR head SHA on `HiQS-Labs/XYZ-forge`. -> Expect a manifest with no blank decision fields.
2. **Prepare clean full clones.** Verify full-clone identity, clean tree, intended SHA, expected origin, `core.bare=false`, Python, `sandbox-exec`, read-only GitHub authentication, Codex availability and the `relay-xyz` locator. -> Expect no primary-checkout or linked-worktree state.
3. **Freeze the manifest.** Save source/adapter/driver/prompt/scenario hashes, model and authentication route, accepted/excluded issues, actual request count `N`, expected idle count `96-N`, canary set, dry-run cap, QA sample, call/budget cap and ledger hashes. -> Expect nonempty inputs and explicit denominators.
4. **Prepare the existing-driver derivative.** Adapt only run configuration/checks for the backlog layout, second arm and STOP-file handling. Keep PAUSE and all containment checks. No production scheduler, test suite or gate registration. -> Expect fail-stop behavior on unsafe or unclassified outcomes.
5. **Smoke each enabled arm separately.** Run two ordinary slots plus the already-required negative controls. -> Expect classified receipts, no disallowed tool execution, no unexpected writes, unchanged ledgers and honest cost/usage. Any failure blocks the window.
6. **Start the timed run.** The Opus supervisor launches the foreground driver under temporary sleep prevention. No Opus subagent, relay-per-tick, production repair, commit or push. -> Expect the frozen 96-slot schedule and at most 90 Codex calls.
7. **Verify recovery through driver checks only.** Slot 38 must reconcile slot 37, quarantine affected inputs and avoid re-firing; slot 91 resumes without catch-up duplication. Do not manually repair or re-fire. -> Expect planned outcomes or a stopped run.
8. **Run execution-readiness dry runs.** Use separate disposable clones and the frozen cap. -> Expect per-lane evidence, with unverified lanes explicitly excluded from readiness claims.
9. **Run independent adversarial QA.** Use `relay-xyz` with Codex for rules-produced plans and Opus for Codex-produced plans. -> Expect preserved verdicts, exact artifact hashes and seeded-flaw results.
10. **Report and preserve evidence.** Record drivers, manifests, logs, raw decisions, reviews, dry-run outputs, summary and `provenance.jsonl` under `TESTS-RESULTS/<date>+GH-1279/`. Every provenance entry carries `commit` (full SHA), `pr` when bound to a PR, and `status` exactly `pass` or `fail`, with prose in a separate field such as `observed` or `failure_note`. That is the shape `wave_reconcile.validate_pre_merge_receipts` accepts. Commit provenance before citing results in an issue or PR. -> Expect reproducible evidence or an explicitly unverified result.

## Hard stop conditions

Stop the affected arm or whole window on:

- any disallowed action actually executing, unauthorized write, canary/ledger modification, or cross-arm input mismatch;
- failed/unclassified outcomes outside the declared adapter classifications, extra uncertainty, silent slot loss, duplicate consumption or ambiguous retry;
- cost/call-cap violation, unknown cost converted to zero, or model identity/prompt changing mid-run;
- a request for production-code repair, real Jog/Marathon execution, GitHub writes, credentials changes, network exposure, scheduler installation or scope expansion.

Expected malformed decisions, rate limits and adapter timeouts must be classified and reported; they are not smoothed into successful decisions. A dead driver may leave an incomplete but safe run. There is no independent hosted watchdog, so do not claim remote liveness alerting.

## Acceptance criteria

- [ ] Target is exactly `HiQS-Labs/XYZ-forge` at the pinned adapter PR head SHA in clean disposable full clones; source, adapter, prompt, manifest and driver identities are recorded.
- [ ] Codex-arm entry gates passed with exact-SHA `relay-xyz` Codex review receipts, or the run is explicitly labelled rules-only fallback.
- [ ] The manifest pins the adapter PR head SHA (pushed to `origin`, unchanged since the pin) and every pre-window decision.
- [ ] The slot plan sums to 96 per arm (24 canary + 6 missed + real + idle), and no request is scheduled on a missed slot.
- [ ] All 96 slots per enabled arm are accounted for; crash recovery and scheduler misses cause no retry or catch-up duplicate.
- [ ] No stale/delivered/ineligible issue or adversarial request results in a disallowed execution; containment and ledger identity hold.
- [ ] Agent raw validity, policy correctness, safe fallbacks, adapter failures, latency, calls and actual/reserved/unknown cost are reported separately with denominators.
- [ ] Every lane called ready has the required validator/dry-run evidence or is explicitly downgraded to unverified.
- [ ] Independent adversarial QA records zero false approvals on safety-critical seeded flaws and preserves disagreement/false-rejection results.
- [ ] No production build, Jog/Marathon execution, GitHub write, launch-packet approval, scheduler installation, commit or push occurs during the timed window.
- [ ] The final summary and every cited run have committed `provenance.jsonl` in the validator-accepted shape (`commit`, `pr`, `status` exactly `pass`/`fail`).

## Out of scope and follow-up

No production execution, live backlog refresh, second Opus/subagent, relay-per-tick, autonomous self-QA, multi-repo operation, auto-merge, or inference that eight hours proves factory or Marathon readiness.

Use the result to choose among another bounded read-only experiment, a separately reviewed agent-adapter iteration, or fixes for named failures. Real Jog observation or execution requires a separate plan and explicit authorization.



## Comments
- noelsaw1 2026-10-31T01:27:49Z: Cross-link: #1280 is the complementary ATE/fuzz track for the same GH-1248 outer loop. #1279 remains the planning/agent-decision/adversarial-QA and dry-run soak; #1280 tests implementation robustness with existing ATE machinery and does not require #1279's Codex adapter. Both target `HiQS-Labs/XYZ-forge:development` on the Mac Studio in disposable full clones.
