# Unstuck reviewed-plan update — GH-854

Base: `b25584c3c4d36ad2d9906b639a4fc4330330b1f0` (`staging/stabilize-2026-10`).
Scope: Markdown only. Existing issue #854 tracks this lower-priority requirement; no ledger or PROJECT writes under the stabilization exception. The user explicitly corrected #855 to #854.

## Decision and recon

Extend the existing Rung 3 blocker check and autonomous triggers in `skills/1-hourly/unstuck/SKILL.md`. Rung 1 already says settled decisions require new evidence; Rung 5 already re-drives the outer engine and returns to workhorse. `skills/2-daily/workhorse/SKILL.md` and `skills/2-daily/review-code/SKILL.md` consume unstuck as an interrupt; their contracts remain unchanged. The skill previously routed unknown failures to debug-mantra but did not route to recon.

Easy reversal: revert the text change. The main risk is suppressing legitimate new failures; the exception for changed user requirements, demonstrated failures and safety gates stays explicit.

This is a simple, local clarification of the existing decision rule, with no new mechanism or design choice: separate plan QA is skipped under start-task Step 6. Final independent Codex relay QA remains required. Skill-creator guidance is applied to keep the entrypoint concise and avoid new supporting machinery.

Task assessment (not a re-rating of umbrella #854): priority 30 (operator says lower priority), severity 35 (execution delay, no observed data loss), appeal 50 (neutral), cheapness 90 (one skill edit). Recurrence: operator reports a recurring pattern; #855 documents reviewer overreach. Trend unknown; no numerical recurrence claim. Ledger writes deferred under #854.

## Acceptance cases for independent review

1. Reviewed plan, repeated preference and no changed facts: identify the settled decision, reject the extra review and execute the next accepted step.
2. Reviewed plan already contains the proposed safeguard: cite it and resume; do not add a duplicate gate.
3. New failing required check: preserve the real blocker, diagnose with debug-mantra, and reopen only the affected decision; bounded recon only if code impact is untraced.
4. Operator changes a requirement: honor the change without requiring a failure first; preserve unaffected decisions.
5. Small blocker cleared in an orchestrated run: re-drive the parent workflow rather than claim the user's whole request complete.

The baseline has no explicit per-topic reviewed-plan check or immediate re-litigation trigger. This is an instruction-gap observation, not proof that every model following the old text would fail. Final QA will assess the cases; deterministic Markdown checks do not prove model behavior.

## Verification

PDDA: rc=0, zero errors and 368 existing-tree warnings. Skill frontmatter validator: rc=0 using the existing test virtualenv (default Python first failed for missing PyYAML). Both added local skill links resolve. Final QA is BLOCKED: round 3 driver rc=4 (`review-body-rewritten`), despite a textual PASS. Draft PR only; no valid harness approval. See CHECKS.md for receipts. No full gate is required for this Markdown-only window PR. Provenance will be embedded in Markdown to preserve the user's `.md`-only scope; this is an explicit departure from the usual separate provenance.jsonl filename.

## Review execution record

Round 1: instruction cases passed; verdict PARKED because the harness forbids Git and the baseline diff was not supplied. Producer supplied the exact diff without changing the skill. Round 2: reviewer approved, but harness rc=6 invalidated that approval when the producer concurrently wrote CHECKS.md outside the reviewer allowlist. The harness saved the file in its orphan backup; it was restored and committed before round 3. No skill change or discarded user work. Round 3 is the final bounded review; no concurrent tree writes.

Final disposition: round 3 reviewer moved an earlier system note; driver rc=4 refused approval. No further review round after the cap. The transcript is retained under `relay-system/2026-09-27/gh854-unstuck.codex.md`. This task is implemented and document-checked, but not merge-ready. A valid independent QA receipt remains required before promotion.

## Superseding QA result — operator-authorized Agy relay

The operator requested a fresh Agy QA run capped at five rounds. Round 1 approved with driver rc=0 and a valid harness attestation. Reviewed head: `f31460cf542c08b7c6a095ea63eb5d35fc2f5cd7`; skill unchanged from the checked revision. Receipt: `relay-system/2026-09-27/gh854-unstuck-agy.md`. This resolves the earlier QA blocker; the historical failed Codex runs remain above. No empirical model-compliance guarantee or full-gate claim is made. Agy's quoted spans support the findings; two ancillary Q3 line references are offset (the quoted passages are at skill lines 102–104 and 118), without changing the verdict.

```jsonl
{"command": "AGY_AGENT=agy RELAY_PEER=codex-author ALLOW_PATHS='' bash relay-automation/relay-drive.sh --relay-file relay-system/2026-09-27/gh854-unstuck-agy.md --relay-task RELAY-gh854-unstuck-agy --agent-cmd relay-automation/agy-turn.sh --reviewer agy --round-cap 5 --review-once", "rc": 0, "result": "Approved in round 1; harness attested", "commit": "f31460cf542c08b7c6a095ea63eb5d35fc2f5cd7", "timestamp": "2026-09-28T00:48:45Z", "host": "Darwin arm64"}
```
