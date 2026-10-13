---
gh_issue: 854
source: https://github.com/HiQS-Labs/XYZ-forge/issues/854
title: "GH-854: execute approved gate dispositions"
status: Working
created: 2026-10-01
updated: 2026-10-01
owner: "XYZ Forge maintainers"
goal: "Apply the operator-approved check dispositions without changing runtime behavior."
doc_type: bugfix
---
# GH-854 — execute approved gate dispositions

## Status
| What was just completed | What's next |
|---|---|
| Full push gate at0b4c82e6 passed410/410, zero retries, clean envelope and identity; branch published. | Publish proof, open PR and verify exact-head hosted CI; merge requires operator authority. |

The [canonical ordered stabilization list](https://github.com/HiQS-Labs/XYZ-forge/issues/854#issuecomment-5915099783) owns overall progress. This bounded execution document owns only the approved registry change; it does not duplicate the full stabilization plan or October 8 audit.

## Decision and evidence
Operator requested each unresolved item be tracked and deferred until a true blocker, then authorized executing the triangulated dispositions. #916 tracks unexplained live relay exit6, #917 the installation registry15/16 diagnostic, and #918 the Gen4 shared-root oracle16/1 failure. #909 stays closed: #910 repaired witnessed completion-record loss, and its existing regression coverage stays. Deferral accepts reduced automatic coverage for unrelated changes; it is not proof of harmlessness or root-cause resolution. See each issue for exact resume triggers.

Base development: `1b40d57c36c70eb045341ec95403de93ba056b92`. The [bounded source recon](../../TESTS-RESULTS/2026-10-01+GH-854/dispositions/recon.md) records consumers, preserved runtime contracts, observed failures and unknowns. Registry410 before change. Every affected suite is outside Small; domain-oracle additionally appears in the ATE selection list. Ubuntu names the registry suite in --skip; unregistered skips are rejected, requiring a companion workflow edit. No gate runs in this valuable task clone.

## Preservation, reversibility and scope
Easy to reverse: restore the two TESTS entries, remove their EXEMPT entries, restore the ATE member and corresponding Ubuntu skip together. Keep both suite files and all runtime modules byte-for-byte. Keep Small, containment, token ownership, commit-bound attestation, resume, escalation and completion regression coverage. Do not add tests, guards, runners, lanes, telemetry stages or runtime fixes. No module deletion, data migration, fixture repair, automatic audit, merge, deploy or clone cleanup is part of this change. Existing #836 D2 RELAY_SELF_SUFFICIENCY_SKIP=1 applies to subsequent local qualification; direct validate defaults stay unchanged.

## Ordered execution and acceptance
1. Cross-model consult and independent Codex plan QA -> disposition scope and companion selections reviewed; three-round QA cap.
2. Admit the exact roadmap row; remove registry-lock-concurrency.sh and gh-gen4-phase1-domain-oracles.sh from TESTS; add explicit gh306 exemptions; remove oracle from ATE subset and registry from Ubuntu skip; correct obsolete ci-local/ci-workflow assertions/comments and AGENTS.md local-registry example -> registry408, no runtime change.
3. In a separate disposable full clone, run existing gh306, gh35 tier coverage, gh379 and ci-workflow checks; witness gh306 red by omitting exemptions, then restore saved bytes -> red names missing entries, green with explicit exemptions; record provenance and identity.
4. Independent final Codex QA of final diff and focused evidence -> Approved within three rounds; then one full task-branch push gate under caffeinate, serial on host, intact identity, zero retry activity in telemetry and transcript, not merely exit0 -> committed full evidence and exact-head hosted result.
5. Ready PR to development and #854 update -> operator landing decision remains required by #854. After approved landing, two clean development4-wide runs in fresh clones; stop on failure/drift. Task-branch gate never increments development count.

## Deferred follow-ups and unchanged counters
[#916](../1-INBOX/GH-916-LIVE-RELAY-DEFERRED.md), [#917](../1-INBOX/GH-917-INSTALL-REGISTRY-DEFERRED.md), [#918](../1-INBOX/GH-918-GEN4-ORACLE-DEFERRED.md) remain deferred/open. Live compatibility can be run deliberately with existing opt-in; retained installer/oracle suites can be run directly when their actual contracts change. No independent expected October8 registry count is invented. #854 local1/3, hostedPR-closed3/3; #853 quiet interval remains unmet. Automation stays paused.

## Rating
70/50/50/85: current operator-selected CI unblock, bounded coverage tradeoff, neutral appeal, small selection change. No override. This row covers disposition implementation, not closing all umbrella acceptance criteria.

## Consult reconciliation
Codex and agy both answered; source-only advice, no runtime verification claimed. Codex found no blocker and requested existing gh35 coverage, explicit zero-retry acceptance, and truthful adjacent workflow prose; all accepted. Agy found the stale AGENTS.md local-registry example in addition to workflow prose; accepted as a narrow documentation correction, with no policy expansion. No disagreement on the approved retirement or preserved runtime scope. Raw receipts: relay-system/2026-10-01/gh854-dispositions-plan-221120/.

## Plan QA and unstuck receipt
Independent plan QA attested Approved against ffe982b5739a in relay-system/2026-10-01/gh854-dispositions-plan-qa2.md. Initial attempts failed the harness protocol (producer concurrent plan edit; premature token release), not substantive plan review. Frozen inputs and terminal token closure corrected the failures in the final allowed plan turn. No production edits preceded valid approval; no review-cap extension or harness change.

## Verified push blocker and existing repair
The first full push gate at3c7ce17f stopped before publication on gh251. Its nested Python suite failed test_a2_archives_round_trip_and_same_day_collisions on UTC2026-10-02: both sample-2026-10-02.zip and sample-2026-10-02-02.zip satisfy endswith("-02.zip"), so next(noncollision) raises StopIteration. Clone identity intact; no qualification count. Existing #914 and PR915 already own this deterministic calendar defect. Reuse only the isolated test correction698cb14342286473b774679cd24dc91a12059249 with cherry-pick attribution; no unrelated PR915 changes or runtime changes. Existing archive assertion now distinguishes the suffix after the full date. Keep #914 active because it is a witnessed current gate blocker; the three previously approved deferred issues stay deferred. Verify the existing affected test/outer suite, then finalQA round2 before restarting the failed gate. Failed receipt: blocked-push/.

GH914 focused check: existing gh251 outer suite passed6/0 at c3072782, including the actual nested Python behavioral coverage that previously failed; identity unchanged. FinalQA first round Approved at f32061aa; optional pre-existing comment nit deferred. FinalQA round2 reviews the reused six-line test diff and historical evidence publication.

## Invocation-only correction
The second full push stopped at011c3f41 after274s on gh544-parallel-default22/7, with intact identity. Producer exported XYZ_VALIDATE_MAX_JOBS=4, which correctly outranks the suite’s XYZ_VALIDATE_PARALLEL probes. Existing gh544 gives22/7 with that export and29/0 without it; normal --print-mode selects four workers on this host. Remove the producer-injected override from the invocation; no suite, selector, runtime, or approved implementation change. Failed attempt excluded. Evidence: blocked-width-override/. FinalQA round2 was attested Approved at e10d2d97; the invocation correction has fresh focused verification and does not reopen technical scope.

## Standing-policy fixture disposition (GH-920)
Third push at dc0d533b stopped on gh4-ungated-clone-warning fixture-copy failure, 0 product assertions; identity intact. Focused existing suite passed6/0 with retained cp stderr empty, then original source restored. Exact historical errno unknown. Apply the existing AGENTS/#853 non-Small flake policy: unregister/exempt gh4, keep its file and all hook/warning runtime unchanged. Candidate registry is now407 (410 minus the original two and gh4); Small unchanged. Reversal adds the single entry and removes exemption. #920 is deferred with concrete user-facing warning/hook failure triggers; no repair campaign. This narrow disposition supplements the original two-entry scope above. Review in final permitted QA round3, then verify full gate. Receipt: blocked-gh4-copy/.

## Current stop — final review budget exhausted
Final round3 at02713f3a produced reviewer PASS in c8a66009, but driver exited4: review-body-rewritten at byte44320. Producer placed its packet below the transcript append marker; reviewer inserted above it. This is our packaging error, not a code finding, and is not valid Approved evidence. All3 final rounds consumed; start-task binding cap prevents another automatic review or ready publication. Exact receipts: dispositions/final-review-blocked/. No gates active, no remote branch/PR, no new local qualification. Candidate407 and focused evidence retained; operator may authorize one additional protocol-correct review. Do not restart the entire ladder or fabricate attestation.

## Authorized continuation
Operator explicitly authorized one additional final review attempt to correct the transcript-placement error. Round4 of4 is the only exception; prior rejected review is preserved, marker moved to the actual end, implementation unchanged. Resume verification/publication only if the driver attests this review successfully. No merge authority is inferred.

## Corrective review completed
The one operator-authorized extra turn completed successfully: relay-drive exit0, attested Approved by codex at reviewed d04b5aa4cadb; review commit f76b860e. The marker placement correction resolved the protocol rejection. No code findings or implementation changes. Prior failed review remains recorded. Full gate and hosted verification remain outstanding.

## Ballast companion dependency — active GH854 scope
The fourth full push at741ed95e stopped after250s on ballast-release:4pass1fail because closed GH4 requires registration of the deliberately retired suite. Identity intact; no retries, remote publication or count. This is a producer/recon omission caused by our selection change, not another unexplained runtime failure. Ballast is Small and remains registered. Correct its existing manifest audit in place: explicit gh306 exemption with retained suite and negative control reports informational/remains incomplete; missing file/control or undeclared unregistration still fails. No release-completion credit; --release-gate still requires zero remaining and fresh executed stranger-path checks. Ten-line companion plus truthful comment; no new suite, runner or runtime behavior. Existing ballast4/0+1info and mutation8/0; manual missing exemption/file/control each red and restored green. Evidence dispositions/ballast-companion/. The one authorized extra QA turn succeeded before this new change; it cannot attest this delta. Further targeted final QA requires explicit budget authority. Do not rerun a full gate merely hoping or silently self-review this new change.

## Ballast targeted review accepted
Operator authorized the targeted companion review and publication. Round5 completed with driver exit0 and attested Approved at1a05d3dcaa33. Integrated development75b75181 through merge6e08f4d5; official ledger resolution preserved both receipt histories and checked clean. Archive-test conflict uses development bytes (no archive-test PR diff). Runtime/Small membership unchanged. Full push gate on final integrated branch follows; no merge authorization inferred.

## Completed full push gate
2026-10-02: source0b4c82e668b64851d63a2c18bbb55480cf9110b9 passed mandatory normal4-wide macOS push gate in separate full clone gate-dispositions-publish5-oct2 under caffeinate. Gate862s (whole push866.47s),410/410,407registered,zero retry events,clean envelope,intact identity. Branch published through hook with no bypass. Full proof in dispositions/full-gate/ binds raw logs/telemetry/identity and accepted review attestations. Live relay intentionally default-skipped per836D2. This task-branch gate earns no development-run credit; local1/3 remains. Exact-head hosted CI follows PR creation.

## Merge evidence

- PR #925 merged 2026-10-02 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
