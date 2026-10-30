---
title: Relay separator attestation
status: in-progress
owner: Codex
goal: Accept harmless review separators while protecting history
created: 2026-10-30
updated: 2026-10-30
issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1273
---

# GH-1273 Relay separator attestation

## Status

| What was just completed | What's next |
|---|---|
| Final QA exhausted 3 rounds; B3 reproduced | Correct mixed space/tab literal detection; obtain authorized fresh review cycle |

Plan receipt reconciliation: reviewer consumed seeded plan from 51860e59. Concurrent 6a079035 changed only relay Setup and duplicate Producer text, not the plan or runtime. Both inputs remain in git history. Driver preserved concurrent commit then committed its reviewed snapshot; the approval applies to unchanged source plan, not the unseen duplicate. No production approval inferred.


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

## Execution evidence

Focused suites and manual receipts: TESTS-RESULTS/2026-10-30+GH-1273/. Canonical byte stream and record layout unchanged. Done-state trace: judge_terminal requires done after valid body; startup refuses spent done tokens; no automatic reset/recovery implemented. Wider mechanical verdict repair split from this separator delivery. Conservative HTML contexts may still refuse format drift rather than risk literal loss.

## Resumable blocker — final QA cap

Shipped final relay command: `CODEX_AGENT=codex RELAY_PEER=claude-a ALLOW_PATHS='' bash relay-automation/relay-drive.sh --relay-file relay-system/2026-10-30/gh1273-final.codex.md --relay-task RELAY-gh1273-final --artifact-file PROJECT/2-WORKING/GH-1273-RELAY-SEPARATORS.md --agent-cmd relay-automation/codex-turn.sh --reviewer codex --round-cap 3 --review-once`.

Result exit 4: `relay-drive: relay escalated to human by design (STATUS: Escalated, token open:claude-a)`. Independent review ran and failed; no final approval. Round-three reviewer commit: 5c7d26c6. All three rounds and dispositions retained in the final relay thread.

Unresolved B3 input: `pre=b"STATUS: Open\n\n \talpha\n\n \tbeta\n"`; delete the empty line after alpha and append substantive PASS. Observed fallback boundary 24; required None. Four spaces and initial tab controls already refuse. Fix the neighbor classifier in relay_attest.separator_prefix_end to recognize equivalent space/tab indentation without altering any original nonblank bytes. Record reviewer exact control in existing manual evidence, then obtain an explicitly authorized fresh independent review cycle; do not extend or reset this capped relay implicitly.

Full classified gate not run: workflow requires final Approved first. No push or PR; no merge. Task and verification full clones preserved with local commits/evidence. Primary untouched. Current score remains 85/82/50/65. NO_ENTRY: current controls do not support a general lesson. Retire only after a verified ready PR; this blocked checkpoint is not eligible.

## Authorized resume 2026-10-30

User authorizes fresh independent final QA cycle, maximum five rounds, and evidence-based adjudication. Earlier capped FAIL remains historical evidence, never reused as approval. Parent supplied narrow expandtabs(4) literal-neighbor fix; preserve original bytes and canonical coordinates. Record exact B3 red/candidate controls in disposable full clone, then new review, final classified gate once, gated push and ready PR development; no merge. Existing parent watchdog owns timing; no duplicate scheduler.
