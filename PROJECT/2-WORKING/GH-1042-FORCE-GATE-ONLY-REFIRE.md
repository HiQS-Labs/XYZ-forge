---
title: "GH-1042 + GH-1045: trusted phase completion recovery"
status: PR ready — awaiting merge
created: 2026-10-13
updated: 2026-10-15
owner: Codex
goal: Restore gate-only and cross-phase recovery without approving unreviewed branch changes.
gh_issue: 1042
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1042
related: [GH-1045, GH-1048]
doc_type: bugfix
risk: 3
complexity: 3
effort: 3
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Fresh clone, live issue intake, graph/source trace and reproduced recovery defects. | Await PR #1054 merge and hosted reconciliation; then safe clone cleanup. |

## Scope and per-issue acceptance

One repair PR, based on development b9f07ea5b8d95bac62a3ed9f886770fee883030f, covering the shared completion/recovery seam.

| Issue | Requirement | Acceptance | State |
|---|---|---|---|
| [#1042](https://github.com/HiQS-Labs/XYZ-forge/issues/1042) | `--force` on an attested terminal lane reruns the gate, with no fresh token/turn. | Base, numeric and force-token completions select their recorded same-family token; no dispatch; explicit retry still rebuilds. | Verified — PR #1054 |
| [#1045](https://github.com/HiQS-Labs/XYZ-forge/issues/1045) | Later legitimate phase/operator commits must not make a completed phase unsatisfiable. | Complete phase p1, commit p2 changing shared source, replay p1 and reach p2 retry; retain historical reviewed candidate. | Verified — PR #1054 |
| Shared safety | Terminal words, unrelated tokens, missing/corrupt evidence and unreviewed edits before completion cannot satisfy a phase. | Refusal controls, strict legacy/current-candidate checks and unchanged merge eligibility. | Verified — PR #1054 |

Canonical plan is this file; GH1045 capture points here. Branch is `fix/XYZ-forge-gh1042-force-gate-only-refire-2026-10-13`; clone naming follows the lowest issue's capture slug. PR: #1054.

## Measured ground truth and root cause

Live GitHub issues are open; no matching repair PR was found. Prior-art search returned #505 (the existing strict approval safeguard) and #1014 (progress/repair observer), neither changes these failing paths. Graph generation 2026-10-13T06:40:42Z provides outer symbols, but misses nested helpers; exact source supplies the traced closure paths. See [recon map](recon-phase-recovery.md).

Root cause: historical completion uses current-HEAD merge eligibility, and force-token allocation happens before resolving completion; fix site: existing marathon completion/attestation owner; why not upstream/downstream: shell traversal correctly visits prior phases, while globally relaxing candidate_ok would weaken Jog merge qualification.

Manual replay drives shipped marathon_drive with real tick and the existing attestation stub in disposable repositories. Baseline force dispatches a stub (exit7); later source commit causes unattested-terminal (exit4); force-family record is rejected; unreviewed pre-completion edit refuses. Stub turns intentionally fail, proving dispatch occurred rather than performing a provider build. Raw observations and provenance live under TESTS-RESULTS/2026-10-13+GH-1042/. Full provider replay is outside this deterministic recovery check.

## Smallest viable bet and authority

Outcome: preserve already approved/completed work while retrying a later phase or its gate.
Extend the existing protected git-common-dir relay-attest record with optional driver-owned completion metadata (phase, lane, validated completion candidate, reviewed-head and review digest binding). This is a derived historical-completion projection of the existing approval, not a parallel store or writer for review authority. Marathon stamps only after the existing success checks; relay-drive remains the approval writer. Atomic existing record publication is reused.

A regex-only change fixes the token instance but not historical candidate rejection. Checking any approved ancestor cannot distinguish a phase that really completed from an unreviewed post-approval mutation. Workspace result JSON and .xyz gate receipts are writable by builders; they cannot authorize historical recovery. Tracking unchanged write-set paths rejects legitimate later shared-file changes. The chosen additive field retains the current trust boundary and the existing candidate_ok contract.

## Blast radius and rollback

Costly: this changes phase-satisfaction semantics in the core harness and adds persisted metadata. Read/write surfaces are marathon_drive, relay_attest, terminal result consumers, and Jog's existing strict merge check. No event/verb/schema changes, frozen Bash edits, new subsystem, new suites or registry entries. No ownership, cap, lock, containment or merge-policy changes.

New readers use historical recovery only when completion metadata matches the loaded attestation, configured phase/lane and an ancestor of current HEAD. They validate the historical candidate with unchanged candidate_ok. Missing metadata falls back to the existing strict current-HEAD rule; malformed metadata refuses. New writes retain schema attest@1 plus an optional field; old readers ignore it and keep strict recovery. Rollback is reverting the Python change; extra metadata remains inert. Fresh relay approval replaces the whole record and removes old completion metadata. Crashes before atomic completion publication retain strict fallback; corrupt publication cannot confer success. Same-user unsandboxed host writes remain outside the existing GH505 containment threat model.

Legacy limitation: a phase completed by an older driver, followed already by unrelated commits, has no trusted completion stamp. Do not infer it from terminal status or builder-writable artifacts. Such runs retain strict refusal; an intentional explicit retry or unsatisfied force rebuilds/reviews the phase under the repaired driver. No automatic backfill or operator escape flag is included.

## Ordered implementation and verification

1. Resolve the original computed token's satisfaction before force allocation; accept only its base/numeric/`-R<n>` family. Explicit relay-task still means deliberate rebuild. -> Force approved replay dispatches no turn; actual unsatisfied force still allocates a free token.
2. Extend relay_attest with narrow completion read/write helpers, using its existing atomic writer. Validate configured phase/lane, review binding, candidate_ok at completion SHA, and ancestry to current HEAD. -> Missing/malformed/wrong-identity/unreachable completion refuses or strict-falls back as documented.
3. Stamp completion only after all acceptance, gate, required-test and post-approve candidate checks pass. Publish no green completion if stamp fails. -> Red gate/post-approval source edit cannot mint completion.
4. For an already completed historical lane, rerun current acceptance probes and pre-advance gate; retain its pinned reviewed candidate, do not re-execute completed post-approve side effects or demand a fresh requires-test delta. Check that recovery's gate/transcript processing adds no unreviewed non-transcript change after recovery began. Never refresh the stamp to a later HEAD. -> Shared-file successor/operator commit recovers; gate-induced source drift refuses.
5. Keep current HEAD observational and historical reviewed_candidate distinct in result JSON. Do not create a fresh review/gate/phase-QA receipt falsely binding the recovery gate to the historical or current revision; initial successful completion keeps normal receipts. -> Jog's unchanged candidate_ok refuses merging current unreviewed successor HEAD against historical approval.
6. Run existing focused suites in a disposable full clone, manual pre-fix/fixed replay and red controls, retain provenance, then independent final Codex QA. Select the final gate from ci-route; push from a separate full gate clone through the installed hook. -> Required route passes exact source revision, hosted run appears for PR head, PR targets development.

## Evidence and QA gates

No new test files or gate machinery. Existing suites: gh491-gate-only-refire, gh505-relay-attest, gh642-consumer-fruit, marathon-drive, and Python layer if applicable. Manual replay under TESTS-RESULTS is an evidence artifact, not a registered suite. Controls must include empty/missing attestation, unrelated family, force generation, numeric generation, explicit retry, legacy later drift, tampered review binding, divergent HEAD, red gate and post-approve mutation, historical gate-induced mutation, result identity, and a two-phase shell traversal. Compare disposable clone HEAD/config/origin/local identity before and after suite runs; drift invalidates evidence.

Plan QA: Approved, third round, relay driver exit0; earlier two scaffold-invalid turns do not qualify. Final QA: round2 Approved. Original full publication gate: 409/409 at d37140db. The current base refresh and evidence corrections require remaining final QA round3 and a fresh publication gate. Reviewer budget is three rounds; no enterprise machinery or speculative approval redesign.

## Ratings and recurrence (2026-10-13)

Read-back RELEASES scores: GH1042 80/80/50/65 (sum275), GH1045 85/85/50/40 (sum260), no operator override. Severity reflects repeated unnecessary rebuilds and a recoverable work-blocking halt, not irreversible data loss. Priority respects user's explicit selection. Appeal neutral50; combined design makes GH1045 harder than token-only GH1042. Last14days (Sep30–Oct13) evidence is the same GH750 marathon, two force incidents and a broader base-token retry incident in its issue update; these are concrete examples, not independent user prevalence. Prior14days (Sep16–29) trend is unknown; no growth claim is made. GitHub search is bounded and duplicate reports are not counted as independent incidents.

## Implementation checkpoint

Source at 7128b496 implements the approved plan. Existing post-approve hooks revealed an event-timing regression at 0275a7a0; corrected by preserving the approval event before the hook while stamping completion only after final validation. Existing marathon-drive suite then passed. Manual recovery/refusal controls and two-phase shell traversal all passed, with exact raw records and provenance under TESTS-RESULTS/2026-10-13+GH-1042/.

Plan QA completed with driver exit0 on round3. Round1 and round2 were structurally rejected due to the producer's scaffold/skill-runtime verdict mismatch; retained in the relay, not counted as approvals. Historical checkpoint: final QA and the full route3 publication gate were pending then. The verified handoff below records their later results; this task is not shipped.

Final QA round1 approved source7128b496 with driver exit0. A subsequent producer compatibility check found --force on a legacy divergent approval had lost GH642's rebuild escape (exit4/no dispatch). Restored explicit force fallthrough to fresh-token rebuild, never satisfaction; plain recovery still refuses. This narrow preservation is covered by plan step1 (unsatisfied force allocates a fresh token). Final QA round2 will review the changed source and new control; round1 approval is stale for that source.

At source9b392b35, all34 manual expected outcomes and the existing Marathon suite pass; identity before/after remains unchanged. New receipts in TESTS-RESULTS/2026-10-13+GH-1042/after-legacy-force/.

## Verified handoff

Final Codex QA round2 Approved with driver exit0 (relay-system/2026-10-13/gh1042-final.codex.md). Full macOS pre-push gate409/409, zero retries at d37140db; clone identity unchanged. Runtime source remains9b392b35's exact blobs; subsequent changes are retained receipts and handoff metadata. PR publication follows the final documentation gate. Awaiting merge is not shipped; both issues stay open until landing. Jog was not dispatched.

PR: [https://github.com/HiQS-Labs/XYZ-forge/pull/1054](https://github.com/HiQS-Labs/XYZ-forge/pull/1054). Base development; live mergeability and exact-head gates must be rechecked after the current review corrections; issues remain open pending landing.

## Review corrections and base refresh — 2026-10-14

The ledger conflict against development7bc727cb is mechanically disjoint. The installed classifier kept generation1628 and replayed GH1042/GH1045 through the existing writer, preserving ratings and issue/document identity. Current review corrections leave production recovery/attestation code unchanged. Acceptance remains verified by the original retained replay; corrected two-phase evidence now removes the seed result before the shell traversal, so a failed p2 retry cannot carry an earlier p1 approval object. Earlier raw receipts remain immutable and are explicitly superseded for that result association.

The durable bet is recorded in [the recovery decision](../../decisions/2026-10-14-gh1042-historical-completion.md). Final QA round3 and the fresh normal publication gate remain required for the updated head. The three-round review cap is unchanged. No live Marathon/Jog was activated.

## Updated verified handoff — 2026-10-15

All five original CodeRabbit findings were adjudicated by independent final Codex QA round3/3, Approved, attested review6edaeacd. The corrected existing34-outcome replay passed, and the normal installed full macOS push gate passed409/409 at2fe59019 in1402seconds, with two built-in sequential retries and unchanged clone identity. That exact branch head was published.

Completed hosted reconciliation qualified the preceding GH1044 landing with409/409 at7bc727cb and advanced development69666c47. Repair2/2 preserved every reviewed GH1042/GH1045 row and all three core runtime blobs while replaying only incoming GH1043 metadata. Hosted LEADERBOARD.md is retained byte-for-byte; no task-owned routine view delta. Review3/3 and repair2/2 are not reset. The administrative follow-up uses the normal documentation gate and fresh exact-head remote checks/reviews before any landing. This is still awaiting merge, not shipped or main-qualified.
