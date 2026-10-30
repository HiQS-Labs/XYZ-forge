---
title: Relay separator attestation
status: planning
created: 2026-10-30
updated: 2026-10-30
issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1273
---

# GH-1273 Relay separator attestation

## Status

| Field | Value |
|---|---|
| Current State | Plan QA pending |
| Last Completed | Fresh canonical full clone; source recon |
| Next Action | Independent Codex plan QA |

## Recon and bet

Base is origin/development at provisioning. relay_drive.py judge_terminal compares canonical_prefix(pre,post) to canonical_bytes(post), then requires nonempty appended bytes and a done token before writing attestation. relay_attest.py owns canonicalization and load validates the canonical added range. Existing normalization removes the exact marker, normalizes first control headers and applies citation downgrade with positional look-ahead. Changing blank counts before that look-ahead can change its meaning; normalize after citation handling with aligned context. Raw transcript must remain untouched.

Outcome: a substantive valid PASS survives deletion of an ordinary blank separator. Costly: shared approval contract; rollback is revert of narrow helper/driver changes. Preserve all nonblank bytes, fenced blocks, indented literal blocks and ambiguous Markdown literal contexts conservatively. Do not normalize general whitespace. Existing exact comparison remains the first choice; narrowly normalized comparison is fallback only and emits a warning. Keep canonical_bytes and persisted range semantics unchanged. A fallback helper returns the boundary in the original post canonical stream after comparing separator-normalized history. Store added_start at that original-stream boundary, so existing load and raw trailer positioning remain unchanged. Explicitly replay both a legacy record and a new fallback approval through real load, including the trailer. No alternative writer/controller.

Smallest bet: separator-only tolerance in existing helper, warning in driver, exact instruction examples. Reject wholesale whitespace stripping because it hides substantive literal changes. Defer bounded mechanical verdict repair if done-token recovery needs broader state changes; first trace token state and refuse paths, document the split. No force approval or review inference.

## Ratings

2026-10-30 proposed rated 85/82/50/65: observed work-blocking recoverable halt, neutral appeal, bounded shared-contract change. Related #1145 is another formatting stop, not proven same root cause. Recurrence windows Oct 16–30 and Oct 2–16: distinct-incident counts not yet established; trend unknown, no user override.

## Ordered implementation and acceptance

1. Trace canonicalization consumers, citation context, raw evidence and done-token recovery; reproduce separator deletion before changing code -> current prefix comparison rejects it.
2. Extend existing canonicalization narrowly, preserving fenced/indented literals and substantive history; emit warning only when separator tolerance needed -> valid approval accepted, raw evidence retained.
3. Update existing review instructions with accepted/rejected examples -> no blanket whitespace permission.
4. Run existing attestation/relay suites in separate sibling disposable full clone; record manual replay and provenance in TESTS-RESULTS/2026-10-30+GH-1273 -> nonempty receipts, positive separator control, negative historical FAIL→PASS, sentence deletion, fenced literal, reviewer mismatch and empty approval. Smoke main and adjacent invocation. No new suites, registry entries, gates, runners or speculative fuzzers.
5. Final independent Codex relay QA, classified final gate, gated push and ready PR development -> exact SHA and review receipts retained. No merge. Retire only proven fully published owned clones.

## QA packet

Operational envelope: existing local relay harness. Commensurate complexity only. Review issue #1273, utils/py/relay_attest.py and utils/py/relay_drive.py. Are requirements complete, context and literal protections adequate, writer shared, rollback safe, checks falsifiable, and ratings honest? Reviewer writes only relay thread. No production edits before approved plan and accepted-start.

## Lessons Learned

Pending verification; NO_ENTRY until observed controls support a lesson.
