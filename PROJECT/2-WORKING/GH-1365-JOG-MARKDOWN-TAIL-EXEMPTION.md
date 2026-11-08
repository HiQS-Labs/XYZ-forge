---
title: Jog queue completion with honest version attribution
status: Planning
created: 2026-11-07
updated: 2026-11-07
owner: codex
goal: Record delivered work without requiring exact approval ancestry at queue closeout.
gh_issue: 1365
effort: 3
complexity: 3
risk: 3
phases: 1
---

# GH-1365 — Jog queue completion

## Status

| What was just completed | What's next |
|---|---|
| Operator selected simpler policy; source recon and rated pickup complete | Independent plan QA, implement, focused verification and final QA |

## Decision and requirements

Tracking: https://github.com/HiQS-Labs/XYZ-forge/issues/1365.
The operator explicitly requests: “stop making exact approval ancestry a requirement for queue completion, while recording which versions were reviewed and tested.” This supersedes the supplemental-attestation spike. The same PR must explain proportionate rigor in GUIDING-PRINCIPLES.md and AGENTS.md.

Outcome: a merged, reconciled lane can leave the queue even when its final PR head differs from its historical review/gate revisions. Queue completion records delivery, not approval of subsequent changes. Bet: existing publication review, CI and post-merge QA carry quality assurance; blocking bookkeeping on ancestry costs more than it adds here. Costly policy change (shared closeout semantics); rollback is a normal revert, retaining historical records and explicitly identifying records created under the new policy.

No blanket Markdown exception, supplemental approval framework, new writer, CLI override, gate, runner or test suite. Publication and retry-gate admission retain their current checks. No live queue changes or issue closure during development.

## Recon and prior art

Base: cff1d0a16c2c9a6eb073b99ef259d3658aea1430. Entry releases_app.py jog land/reconcile -> jog_run.jog_land -> _committed_jog_receipt -> GitHub merge verification -> reconciliation -> _close_delivered_issue -> jog_set_status -> landing.json. The existing status writer remains sole queue writer. Whole-issue closure has separate coverage checks and stays unchanged.

_committed_jog_receipt validates committed bundle hashes, repository/issue/execution identity and green gate at receipt.head_sha. _landing_tail_proof enforces exact ancestry and permitted tail paths both in jog_land and publish_jog_receipt. Remove its use ONLY in post-merge jog_land. Keep the helper and its publication caller. Retry-gate uses _is_relay_receipt_tail and is outside this change.

Retain checks for merged PR, expected base/head branch, original receipt identity, merge reachability on origin and primary HEAD, clean releases ledger and reconciliation. Fetch the actual PR head and verify it equals GitHub headRefOid when it differs from the receipt; this checks PR identity, NOT ancestry to approval. Missing/mismatched heads still refuse. No comparison of reviewed/approved ancestry to landed head.

landing.json currently stores approved_head_sha, landed_head_sha and tail_proof. Replace tail_proof with completion_policy=merged-pr and explicit reviewed_head_sha / reviewed_candidate_sha (from original receipt, null if absent), tested_head_sha (head_sha bound by the validated gate), preserving approved_head_sha, landed_head_sha and merged_sha. Do not infer review when old fixtures/receipts lack it. No consumers of landing.tail_proof found outside this writer; publication tail proof remains internal. MACHINE-CONTRACTS.md needs distinguish merge admission from post-merge bookkeeping.

Existing suite: test/gh280-jog-marathon-adapter.sh covers committed evidence, wrong PR base/head, unmerged/unreachable merge, reconciliation and idempotent landing. Update its existing landing scenario to carry a real nonledger tail and assert distinct attribution. Manual historical PR #1361 replay and adjacent rerun use actual jog_land with local GitHub transport fixtures; never send issue writes. Also demonstrate a non-ancestor approved revision can complete under this policy. Missing/tampered bundle and wrong identity still refuse before mutations.

Prior-art scan matched #1122 review skills and #1054 Marathon recovery, neither removes this jog_land call at this base. No existing implementation solves the requested change. Historical supplemental spike passed in isolated local commit 0ee72589f31e8ef33b76e17352d4ead66090e83e; it is an alternative feasibility result, not this implementation or public acceptance evidence. Issue retains the historical alternatives.

Ratings readback: 75/35/50/70 (pri/sev/appeal/effort). Priority follows explicit user ordering; severity reflects delayed bookkeeping, not lost code; appeal neutral; effort reflects a small shared-path change plus verification. One demonstrated incident (#1361/#1356), repeatedly discussed; no evidenced increasing recurrence. Window Nov 7 versus preceding 14/28-day history: prior-art results do not establish other incidents; trend unknown.

## Ordered implementation and acceptance

1. Independent Codex plan QA -> expect Approved before production writes; record accepted-start through RELEASES CLI.
2. Edit jog_land only at the approval-tail boundary and landing metadata; update existing landing scenario, MACHINE-CONTRACTS and skills/2-daily/jog/SKILL.md landing guidance -> expect nonledger changes and rebased approved history can complete, while invalid receipt/PR/merge checks remain effective.
3. Add canonical proportionality paragraph to GUIDING-PRINCIPLES North Star and concise AGENTS application: justify controls by concrete risk and operational cost, honor explicit operator tradeoffs and retain honest evidence -> expect no blanket permission to bypass unrelated safety/verification rules.
4. In disposable full clone run existing gh280 suite and main/adjacent manual land/rerun. Record baseline refusal as red control, successful completion, exact version attribution, negative controls and idempotence under TESTS-RESULTS with committed provenance. Bracket clone identity. No new suites/registry or speculative framework.
5. Final independent QA -> applicable classified final gate -> ready PR against development. Update issue and retain evidence; no merge claimed.

## Alternatives and rollback

Leave parked: no implementation, but fails the requested queue outcome. Bounded allowlist: still couples delivery to file types and misses broader final edits. Supplemental attestation: proven feasible, but adds machinery the operator rejects. Selected solution removes only post-merge ancestry enforcement, retaining factual provenance. Revert production/docs changes if delivery semantics prove insufficient; do not rewrite old receipts as newly approved.

## Lessons Learned

Pending observed implementation results; no lesson claimed from policy adoption alone.
