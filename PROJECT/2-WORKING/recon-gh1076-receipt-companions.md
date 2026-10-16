---
title: GH1076 receipt companion trust and eligibility recon
status: Research complete — strict carrier contract and producer boundary need disposition
created: 2026-10-15
updated: 2026-10-15
owner: Codex
goal: Admit only independently verified evidence companions without weakening functional scope or proof authority.
doc_type: research
roadmap_exempt: true
gh_issue: 1076
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1076
---

# Recon Map — receipt companions

Commit:7c5d5aa5; grep/read-only, one local lane across the existing reader/writer/publisher. No graph used. This extends the earlier GH1076 map for one new contract seam; no parallel implementation writer exists.

## Status

| What was just completed | What is next |
|---|---|
| Canonical reader/producer/carrier boundaries traced; current ledger reconciled without runtime changes. | Parent judgment on strict premerge producer trust/schema and review allowance; no activation or expensive full run. |

## Subject and change class

Receipt-aware functional-scope selection. Contract/authority change if a receipt authorizes excluding a changed file. It cannot be treated as a path-only correction.

## Call paths and seams

| Seam | Current owner and location | Consequence |
|---|---|---|
| Complete raw scope | wave_reconcile.py:497-513 content_landing_base | Only modified regular top-level package text. Any evidence companion selects full. |
| Actual merged identity | wave_reconcile.py:516-527 content_source_identity | Requires one real merged development PR, exact landing, source ancestry. Keep this check. |
| Generic premerge admission | wave_reconcile.py:1044-1169 validate_pre_merge_receipts; run_pre_merge:2275 | Committed outcome/attribution, stale-source check. Returns an error/None, not a validated companion set. |
| Canonical telemetry reader | wave_reconcile.py:568-627 qualification_summary | Sequential producer/schema/run/coverage/envelope validation, strict Small/area controls. Reuse, do not copy. |
| Canonical wave replay | wave_reconcile.py:630-752 | Typed wave receipts, exact tested/landing ancestry, telemetry digest; @2 adds policy/config/environment. |
| Canonical wave producer | wave_reconcile.py:798-946 qualify_landings | Refuses unmerged PRs. Actual bounded gate, identity checks, canonical two filenames. Not a premerge producer. |
| Publication/recovery | hosted_lane_publish.py:52-91 and module contract | Only canonical wave provenance/validation files carried; receipts retained before recompute. No arbitrary artifact exemption. |
| Local receipt owner | gate_receipt.py:35-92; utils/gate-record.sh:74-86 | Self-reported records; explicit tamper-evident, not independently attested. No source-tree/complete-companion-set contract. |
| Evidence carrier classification | weekly-planner/scripts/planner_core.py:394-427 | Hold/unmerged planning semantics. No runtime trust or scope exemption. |

## State and downstream checks

Current wave receipts are terminal audit records and replay inputs, not a new queue. committed_qualifications selects supported canonical paths/schema; qualification_receipt_matches decides whether replay is suppressed. Hosted FF recovery persists those same files and recomputes once. Thus a new companion authority must not silently broaden historical @1 admission, generic premerge PASS or publisher allowlists.

The new strict companion result would be a constraint on exactly which raw changed files may be excluded, never a generator of new files/receipts or a generic PASS. Unsupported/missing/invalid evidence must select full. Real test failure or identity drift must remain fatal; it cannot become a fallback exception.

## Existing evidence and trust boundary

The retained admission fixture proves the eligibility mismatch. The prior controlled @2 demo proves that the real writer/reader accepts well-formed SIMULATED fixture telemetry; that is deliberate fixture behavior, not authenticated producer evidence. utils/gate-record.sh explicitly explains why locally hashing self-produced output cannot establish independent provenance. A runner/producer string or Git author is also a claim, not authentication.

No existing independently authenticated committed premerge carrier was found in the reader, producer, local gate or workflow. Do not describe this bounded search as proof that no external attestation exists anywhere.

## Smallest proposed correction and unresolved decision

Extend the existing premerge reader with an opt-in strict companion-set result, using canonical telemetry validation and immutable Git blobs. Require a versioned exact pre-carrier source commit/tree, producer identity/revision, and an exhaustive regular-file digest/blob manifest. Prove source-to-carrier is exactly that verified set; apply the original complete raw predicate to functional changes. Extra files, altered evidence, stale source/tree, unknown schema/producer, symlinks/modes or functional mixtures stay full. No global TESTS-RESULTS exemption and no legacy PASS upgrade.

The missing producer contract is material: the current canonical strict writer requires a merged landing. Parent must judge a bounded premerge producer/reader contract and its review allowance, or explicitly retain the existing local tamper-evident trust boundary. No additional review/cap reset is implied. A requirement to reject fully resealed forged producer evidence needs a trusted producer witness, not more JSON assertions. No security/access changes or new CI cases are authorized by this map.

## Unknowns

| Unknown | Why it changes implementation | Resolution |
|---|---|---|
| Required producer trust: existing self-report/tamper evidence vs independently authenticated witness | Determines whether a strict local resolver is sufficient or a premerge CI producer is necessary | Parent's operator-delegated procedural judgment on this concrete boundary |
| Existing external premerge attestation beyond the searched owners | Could avoid introducing a producer contract | Identify and read the actual producer/reader, immutable source binding and trust evidence |
| Review allowance for the new proof-authority contract | Supplemental final remains FAIL1/1, no rounds remain in that grant | Parent judgment; never reset or call new design evidence-only QA |

Radius: one wave source/scope/receipt owner, its canonical publisher, local self-check receipts and the retained qualification schemas. No runtime implementation change made at this checkpoint.
