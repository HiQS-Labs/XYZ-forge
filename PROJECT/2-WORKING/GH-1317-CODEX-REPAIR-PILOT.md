---
gh_issue: 1317
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1317
title: "Codex adapter repair pilot: due probes and frozen prompts"
status: In progress
created: 2026-11-01
updated: 2026-11-01
owner: operator / start-task session
doc_type: bugfix
goal: Repair two real adapter defects through a bounded independently specified actor–verifier loop.
effort: 3
complexity: 3
risk: 2
phases: 3
---

## Status

| What was just completed | What's next |
|---|---|
| Approved all eight cases; independent plan QA approved corrected protocol in round 3; base reproduced both defects. | One actor attempt repaired both defects; seven frozen checks passed; controlled bypass rejected. Final independent review pending. |

## Current state and authorized scope

Operator approved all eight cases and bounded repair execution on 2026-11-01.
Frozen contract and manual checks are under TESTS-RESULTS/2026-11-01+GH-1317/pilot/.
Plan QA precedes implementation; absolute execution stop 22:37:47Z.
Accepted-start is recorded only now, after independent plan approval.

Keep [#1314](https://github.com/HiQS-Labs/XYZ-forge/issues/1314) and
[PR #1316](https://github.com/HiQS-Labs/XYZ-forge/pull/1316) unchanged. Reuse their
identity, raw-output, state-effect, replay and inconclusive-result procedures by
reference; their merge is not a dependency. This draft contains no calibrated
production repair or reliability claim.

## Identities and intake

| Issue | Scope | Dependency | Branch | State |
|---|---|---|---|---|
| [#1317](https://github.com/HiQS-Labs/XYZ-forge/issues/1317) | Due-probe/prompt repairs and bounded repair pilot | Approved cases, frozen specification and plan QA | `fix/XYZ-forge-gh1317-codex-repair-pilot-2026-11-01` | Queued; draft preparation |

Base: `7c06ea30fa6c93b07626c9cc059b29898c2eda64` (`origin/development`).
Fresh full canonical-remote clone basename:
`XYZ-forge-gh1317-codex-repair-pilot-2026-11-01`.
This file is the canonical resumable capture/plan; promote through existing PRS
verbs only when execution is approved. No second plan or scheduler.

## Recon and consequences

`utils/py/harness.py` is the real CLI implementation. `factory_main` dispatches
`init`, `tick`, `status`; `run_tick` persists snapshot, reserves budget, dispatches
`_adapter` → `codex_decide`, settles and emits `agent_called`, validates the decision,
runs the sandboxed tool and records receipt/output state.

- `rules_decide` lines 214–218 uses missing last probe or elapsed time strictly
  greater than 3600 seconds. `codex_decide` lines 243–249 skips only when both inbox
  and configured targets are empty, so non-due targets still invoke the subprocess.
  Reuse a single due predicate rather than adding another timing policy.
- `adapter_config` lines 1016–1028 freezes the selected v2/v3 prompt hash.
  `codex_decide` rereads that prompt without comparing the recorded hash.
  Check the exact loaded content before composing snapshot/request material and
  dispatching; mismatch must explicitly refuse as unbilled/called=false so normal
  `_settle` releases the reservation. Do not throw past settlement leaving a hold.
- `_snapshot` derives last successful probe and budget from persisted state;
  `_reserve` precedes dispatch. A reservation row may exist: require released state,
  zero actual cost and unchanged spent/remaining budget for no-call/refusal cases.
- Existing `CODEX_BIN` is the external subprocess seam; output is read from `-o`
  and validated. A recording fake must implement this external shape and record
  actual argv/prompt, never call a provider. Do not replace internal functions.
- `_run_tool` requires macOS `sandbox-exec` and executes the real tool subprocess.
  Preserve that boundary; inability to use it makes evaluation unavailable, not pass.
- v3 init requires `--codex-authoring --adapter codex --from-prs`. `seed_from_prs`
  reads local ledger and GitHub snapshots; use frozen owned local fixture data and
  an external recording GitHub CLI stand-in if needed. Never read production/live
  backlog to make a fixture. Exact setup is pending independent specification review.
- [#1311](https://github.com/HiQS-Labs/XYZ-forge/pull/1311) already requires positive
  max-call-cost for Codex initialization. Use positive reservation limits with a
  fake provider; do not regress or redo this fix.

Duplicate recon searched all-state issues for periodic probe, prompt_sha256 and
actor/verifier, plus Codex PRs and current plans. Related umbrellas #1248/#1279,
#1298 and calibration #1314 do not own this production repair pilot. Existing
`prior_art_recon.py --query codex_decide` returns merged #1282 as a candidate:
that PR introduced this still-defective seam, not a repair (source/review comments
confirm). It is not an already-solved task requiring duplicate verification.

Recurrence window: 2026-10-18–11-01 versus 2026-10-04–10-18. Targeted issue/PR
searches found these two 2026-10-30 review findings and the distinct #1311 cap fix;
coverage is not an exhaustive incident inventory, so trend is unknown.
Rating rationale (2026-11-01): `rated 70/60/50/45`, written/read back through PRS.
Priority follows the operator's production-repair direction; severity reflects
unnecessary spending and misleading frozen-policy identity, with no observed data
loss. Appeal neutral; cheapness includes separate evaluator/fixture preparation.
No user numeric override.

## Smallest viable bet and boundaries

Outcome: idle configured probes cost no call, frozen policy identity is enforced,
and an actual actor repair is independently accepted on real CLI/state effects.
Bet: existing adapter, bounded execution and receipt seams can carry this narrow
pilot. Reversibility Easy: revert the surgical code/plan change; disposable owned
runs cannot alter other checkouts. A failed pilot retains failure evidence.

A direct hand fix is smaller but cannot demonstrate actor repair against an
independent answer key. More historical calibration does not deliver a current fix.
Use supervised existing execution first; do not construct an autonomous platform.
Blast radius is the Codex adapter, shared due predicate and its settlement/receipts;
rules behavior and positive controls must remain stable.

No new suites, registry entries, guards, runners, lanes or telemetry stages. No
paid model calls, production reads, changes to active checkouts, broad refactors,
merge/deploy, #1295 remediation or #1298 landing handoff. Preserve GH-831/GH-1131.

## Proposed ownership and bounded execution contract

The operator/independent specification owner approves requirements, exact commands,
fixtures, mutation, permissions and budgets before actor changes. Freeze content
hashes for contract, fixtures, fake process, base/candidate and existing runner.
The actor edits only approved implementation paths (initially harness.py and only
an existing helper if recon proves needed); it receives discrepancies, cannot edit
expectations or final corpus, and disputes return to the specification owner.
An independent evaluator reruns frozen CLI cases and grades runner-produced raw
outputs, exits, DB effects, receipts and call records. No self-acceptance.

Use existing `run_bounded`, CLI and `TESTS-RESULTS` provenance. The existing
`self_healer.py` supplies attempt/history and generator seams; `gen4_campaign.py`
currently hands healing to validate.sh/print-mode and matches replay exit codes,
so invoking its default does not verify this semantic contract. Marathon has
bounded attempts and `relay_attest` but no need for a new marathon for one file.
Select the narrowest existing supervised seam in plan QA. If minimum connection
work is required, specify that surgical change before approval, never another
framework. Same-user paths/hashes detect observed drift; do not claim immutability.

Operator-approved ceiling: two actor attempts, 30 minutes total
including setup, 60 seconds per CLI command and zero provider spend; final ten
minutes reserved for independent evaluation, retention and shutdown. Track actual
attempts, elapsed time and every human intervention. Stop on bounds, repeated
non-progress, changed identity, invalid/empty evidence, containment failure,
disputed specification or uncertain owned-process cleanup. Preserve unavailable,
behavioral failure and budget exhaustion as distinct results. No automatic retry
or budget extension. Final actor/reviewer mechanism must satisfy the zero-spend
constraint before dispatch; availability is not yet established.

## Proposed cases — each requires explicit operator approval

| ID | CLI/state case | Required observation | Approval |
|---|---|---|---|
| 1 | Empty inbox, configured target not due | Zero provider calls; agent_called=false; reservation released; no net budget consumption | Approved 2026-11-01 |
| 2 | Same target due | Exactly one call and normal probe action; retain strictly >3600 seconds | Approved 2026-11-01 |
| 3 | Actionable inbox | Normal call/action still succeeds | Approved 2026-11-01 |
| 4 | v2 prompt mutated after init | Explicit refusal before call; called=false; released reservation/no net charge | Approved 2026-11-01 |
| 5 | v3 prompt mutated after init | Same refusal/no-call/settlement | Approved 2026-11-01 |
| 6 | Unchanged v2 | Positive call/action succeeds | Approved 2026-11-01 |
| 7 | Unchanged v3 | Positive call/action succeeds | Approved 2026-11-01 |
| 8 | Independently controlled bypass mutation | Same semantic verifier rejects the deliberately broken candidate | Approved 2026-11-01 |

No new case/assertion/parameterization is added or run by publishing this table.
The evaluator owns fresh final roots and the separately controlled mutation copy.
Freeze expected refusal token, fixture chronology, nonempty output/JSON/schema and
state predicates in the reviewed exact protocol before running. Never accept only
exit code/digest equality or a generated artifact's existence. Actor cannot weaken
the oracle after observing failure. Requirement changes invalidate old evidence.

## Ordered continuation and acceptance gates

1. Obtain per-case approval, freeze exact fixture/protocol identities and zero-spend
   actor/evaluator arrangement, then run independent Codex plan QA through relay-xyz
   (three-round cap). Expect approval or an exact resumable blocker; no code yet.
2. Promote this capture through PRS and accepted-start only after approved plan QA.
   Run the approved real CLI base cases with recording CODEX_BIN; expect real defect
   cases to fail semantically. Give discrepancies to the bounded actor and record
   actual repair attempts. Expect a production implementation diff, not a plan-only
   completion claim. Actor writes cannot touch oracle/evidence.
3. Independently evaluate the exact candidate on fresh roots and mutation control;
   require all approved semantics, existing focused checks and final relay QA.
   Retain commands, sanitized environment, hashes, full nonempty outputs, DB/receipt
   state and before/after inventories with provenance. No improvement claim without
   comparable baseline. Use the classifier-selected publication gate once at the
   final boundary, no repeated full development suite. Update this draft honestly;
   merge/deploy and #1298 landing handoff remain separate.

## Lessons Learned

NO_ENTRY: preparation alone supplies no observed repair outcome. Relevant existing
lesson: LESSONS-LEARNED.md “Ship a gate's producer in the same change you ship the
gate”; do not introduce a new required receipt without its existing producer.

## Execution result (2026-11-01)

Actor attempt 1 produced b3dd3e43, changing only harness.py plus its relay thread.
Separate supervisor ran the frozen v3 checks in a fresh candidate full clone:
7/7 passed. Base: 3 real fault cases failed and 4 controls passed. Evaluator-owned
prompt-check bypass: exactly both mutated-prompt cases failed, 5 other cases passed.
All seven ticks completed with receipts and hash-verified nonempty tool output.
No-call/refusal cases released reservations with aggregate spending unchanged.
Existing codex-turn check: 43 pass/0 fail in disposable full clone.

Process deviations: first coordination dispatch found uninitialized local .tick;
initialized only this task clone. v1 oracle had two real review findings; v2 fixture
setup lacked Git initialization; both corrected/refrozen before actor code changes.
PRS accepted-start initially refused --issue-num; correct --gid admission was
recorded after the actor turn, so required admission ordering was missed. Do not
rewrite that history or count registration as accepted-start. No actor retry,
expectation weakening, human source patch or budget extension occurred.

Source helper preserves strictly >3600 seconds; runtime cases cover recent/absent
history, not an exact-equality timing case. V3 positive control completes idle
after a real external fake call; it does not claim plan-authoring quality.
No generalized autonomy or productivity-improvement claim from this single pilot.
