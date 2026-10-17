---
gh_issue: 1100
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1100
title: "Jog dispatch must keep the task root explicit"
status: "Planning — awaiting independent QA"
updated: 2026-10-16
owner: codex
goal: "Keep Jog-dispatched Marathon writes in the selected clone"
created: 2026-10-16
doc_type: bugfix
---

# GH-1100 — Jog target root

Jog must dispatch Marathon against the preflight target even when preflight and target roots match. A shell-global XYZ_HARNESS must not redirect phase files, commits or coordination into the primary clone. Preserve explicit cross-repo targets and existing retry semantics.

## Status

| What was just completed | What's next |
|---|---|
| Root leak reproduced with intercepted dispatch; recon complete | Codex plan QA, then accepted-start and implementation |

## Grounding and bet

See [Recon Map](recon-gh1100-jog-target-root.md). Base: ccb900746c5c2d011522299246f111ce0a49db0f.
Outcome: a Jog lane must execute against the packet target and keep harness coordination/phase writes in the preflight-selected clone despite an ambient primary XYZ_HARNESS.
Smallest viable bet: extend the existing shared argv policy to supply target-root when absent; share the existing two env construction sites through a small invocation-env helper that pins XYZ_HARNESS to the selected drive script's harness directory and MARATHON_ROOT to packet harness_root. Keep packet-supplied explicit target flags unchanged. No global resolver/preflight changes, schemas, new suites, runners or gate machinery.
Alternatives: cwd alone demonstrably fails; target-root alone leaves phase output under the ambient harness; changing global resolver precedence would affect unrelated standalone callers. The helper centralizes identical policy for run/retry-build and gate-retry, including old stored packets without harness_home.
Reversibility: Costly containment seam; rollback is a code revert. Stop on any primary-root dispatch or fixture identity drift before allowing a live run. No migration is involved.

## Rating (2026-10-16)

PRS read-back: **80/85/50/90**, no override. Priority retains issue value (blocks GH-1098 Scope C); severity raised from issue's 75 to 85 because the observed branch/commit leak risks operator work, even though caught before builder dispatch. Appeal neutral; cheapness retained for a local adapter correction. Recent window 2026-10-03–16: concrete #1098/#1093/#1099/#1100 reports describe a root-containment sequence, not four independent incidents. Preceding window 2026-09-19–10-02: #770 reports a related root-selection class but shared cause is unproven. Trend unknown; no inferred incident multiplier or user override.

## Ordered implementation and acceptance

1. Obtain Codex plan approval; admit the exact issue URL's owned PRS row with accepted-start → read-back succeeds before runtime edits.
2. Extend existing argv/env adapters in jog_run.py → missing target supplied from packet target_root, existing explicit target preserved, packet argv/env unmodified. Pin harness tool root from executable directory and coordination root from packet harness_root in both dispatch sites; preserve lock/idle policies.
3. Replay intercepted dispatch with ambient primary, existing explicit target, vendored harness and retry paths → selected code/harness/phase roots stay in their packet boundaries; retain command and red/green evidence with provenance under TESTS-RESULTS/2026-10-16+GH-1100. No live builders needed for this probe.
4. Run the existing gh280 adapter suite in a disposable full clone; compare identity before/after → existing root, vendored and retry behavior stays green. No new test files or registry entries; change an existing assertion only if its pinned behavior changes. Run PDDA hygiene and frozen-twin checks; route final changed paths through ci-route and run its required final gate once after final Codex QA.
5. Resolve final Codex findings within three rounds, push through the hook from disposable isolation, open/inspect a development PR → exact head, bounded diff and actual hosted-check status recorded. Keep issue open pending merge; follow current retirement policy if fully published evidence permits.

## Acceptance falsifiers and review questions

The pre-fix intercepted dispatch must fail the missing-target/root assertions (nonempty captured dispatch required). A target-only mutation must still fail the harness-root assertion; this prevents a cosmetic fix. Verify explicit packet target is preserved, and vendored .xyz harness and consumer coordination roots remain distinct. No standalone resolver policy change is in scope.
Review whether the adapter's executable-parent assumption matches all supported preflight packets, whether explicit same-root target causes a relay containment conflict, and whether root/phase/coordination pinning addresses the incident without widening the contract. Operational envelope: a local operator-controlled harness, not an unrequested multi-tenant security model. Grade commensurate complexity and actual requirements.
