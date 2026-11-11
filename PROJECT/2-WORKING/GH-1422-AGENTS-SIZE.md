---
title: Trim AGENTS.md below 32 KiB
status: In progress
created: 2026-11-11
updated: 2026-11-11
owner: Codex
goal: Keep all operative repository instructions available within Codex's default loading budget.
gh_issue: 1422
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1422
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
phases: 1
---

# GH-1422 — AGENTS size

## Status

| What was just completed | What's next |
|---|---|
| Plan QA Approved; accepted-start recorded; draft 27,756 bytes and manual controls pass | PR publication through final push gate |

## Requirements and observed baseline

Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1422.
Base: `966290ddd8b69fcfd49a9df5e123b118befcd6e1` (`origin/development`).
`AGENTS.md` is 42,768 UTF-8 bytes. Codex automatically includes project instructions
under a combined default 32,768-byte budget, not a separate budget per nested file.
Source: https://learn.chatgpt.com/docs/agent-configuration/agents-md.
Consumer path: Codex project discovery → root AGENTS → ROUTER startup → canonical
SOP / PDDA / safety / relay documents. No runtime code change is required.

`AGENTS.md` already says it must not restate routing or roadmap contracts. Its
largest repetition is incident narrative and procedural details whose owners are
ROUTER, SOP and WORKTREE-SAFETY. Retain operative requirements in concise form;
use existing canonical links for the explanations already owned there. Preserve
existing headings where external references may depend on them. No new instruction
subsystem, script, nested AGENTS file, or configuration override is needed.

Prior-art recon for `AGENTS.md 32 KiB` found #1422, unrelated #32, no open or recently
merged matching PR, and no existing fix candidate. No prior #1422 capture or row.
Primary checkout preserved; task clone/branch slug is `agents-size`.

## Preflight bet and scope

Outcome: the root behavioral contract is completely available at default discovery.
Smallest bet: compress AGENTS in place to at most 28,000 bytes, retaining all operative
rules, exceptions, authority boundaries and exact commands necessary to apply them.
Keep critical safety and explicit required-read routing near the top. Retain existing
links to incident records; do not move unique requirements into unconditionally unread
prose. Prefer links to existing owners over copying long procedures.
Simpler alternative rejected: raising project_doc_max_bytes only fixes configured users
and fails the requested artifact-size target. Splitting into nested AGENTS still shares
the same cumulative budget. Wholesale deletion risks silently weakening the contract.
Reversibility: Easy — revert the documentation commit; no runtime/state migration.
Blast radius: agent interpretation of root instructions; canonical destinations stay intact.
Non-goals: policy changes, harness/runtime edits, new tests/gates, config changes, merge or deploy.

## Ordered implementation and verification

1. After plan approval and accepted-start, compress AGENTS section by section. Keep a
   mapping from every original section/rail to its retained text or existing canonical
   owner in the verification receipt. Preserve discoverability and meaningful anchors.
2. Verify byte count `0 < size <= 28000 < 32768`; witness red on the 42,768-byte base
   and on empty input. Record UTF-8 byte counts, content hashes and commands in
   `TESTS-RESULTS/2026-11-11+GH-1422/` with provenance.jsonl.
3. Read from ROUTER → AGENTS as the main smoke path; inventory applicable nested
   AGENTS/override/fallback instructions as the adjacent path. Calculate applicable
   root-to-directory totals and report any remaining overflow honestly. Validate
   changed Markdown link targets and anchors. Do not claim links auto-load their targets.
4. Run the existing classifier and applicable gate on the actual changed paths.
   No new tests, suites, registry entries, scanners or gate machinery. Manual byte/link
   probes are task evidence only; mutation-heavy suites, if required, run in a separate
   disposable full clone with identity checks. Retain evidence and final QA in the PR.
5. Independent final Codex review must perform an omission-diff: identify every original
   operative requirement without an equivalent retained requirement or reachable mandatory
   canonical instruction. Resolve material losses before publication. Publish to development,
   close out #1422 with truthful QA/gate state, and safely retire fully published checkouts.

## Acceptance

- [x] Root file is nonempty and below 32,768 bytes, with target <=28,000 for headroom.
- [x] Before/after counts and a section/requirement destination mapping are retained.
- [x] Critical safety, authority, routing and existing operative semantics are preserved.
- [x] Links resolve; applicable instruction-chain totals are measured and limitations stated.
- [x] Existing docs gate and independent plan/final QA pass; no new tests or gate machinery.

## PRS rationale (2026-11-11)

Persisted/read back: rated 75/65/50/80; no operator override.
Priority 75: requested now; default loading omits repository rules across Codex sessions.
Severity 65: credible loss of workflow/safety guidance, but no attributed data-loss incident.
Appeal 50: neutral; operator supplied no numeric preference.
Cheapness 80: bounded documentation rewrite and semantic review, no runtime migration.
Recurrence windows: 2026-10-29–11-11 versus 2026-10-15–28. Narrow prior-art search
found no separate matching incident; coverage does not establish incident counts or trend.
Trend unknown; this is one demonstrated oversized artifact, not proven increasing incidents.

## Review and verification

Plan QA Approved at `5b6db4820`; receipt: `relay-system/2026-11-11/gh1422-plan.codex.md`.
Candidate 27,756 bytes; manual controls/link/chain smoke passed. Evidence:
`TESTS-RESULTS/2026-11-11+GH-1422/SUMMARY.md`. Docs gate passed (exit 0, zero errors, 99 backlog warnings); final QA Approved at `d53a88d60` (round 2), receipt `relay-system/2026-11-11/gh1422-final.codex.md`.
Publication gate reruns on the final pushed commit; issue remains open until merge.

## Lessons Learned (For Future Agents)

Byte count alone cannot establish preservation of policy. Retain the requirement map and independent omission review. NO_ENTRY for the global lessons ledger.
