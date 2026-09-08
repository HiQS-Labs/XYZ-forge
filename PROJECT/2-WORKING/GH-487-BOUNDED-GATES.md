---
title: "GH-487 — bounded gates for new-branch skill/test pushes"
status: In progress (2-WORKING)
created: 2026-09-07
updated: 2026-09-07
owner: noelsaw
goal: First pushes of registered skill/test changes use bounded local gates instead of the full suite; draft-review bypass is documented as distinct from merge readiness; the gh365 telemetry flake is fixed and the pool-flake surface is characterised before any serialization.
gh_issue: 487
source: https://github.com/HiQS-Labs/XYZ-forge/issues/487
branch: fix/gh487-bounded-gates
doc_type: bugfix
related: [GH-484, GH-486, GH-35, GH-509, GH-544]
context_tags: [ci, pre-push, routing, tier2, contention]
effort: 3
complexity: 3
risk: 2
phases: 4
---

## Status

| What was just completed | What's next |
|---|---|
| Recon + plan (comment #3 Rev. 2) reviewed by Claude Opus; item 4 re-aimed, D3 tightened, D1 edge cases folded in; intake parked and rated 55/30/50/60 | Phase 1: classifier contract tests (red) then `utils/ci-route.sh` changes |

## Table of contents

- [Phase 1 — classifier + registry](#phase-1--classifier--registry)
- [Phase 2 — hook merge-base classification](#phase-2--hook-merge-base-classification)
- [Phase 3 — contention fix, characterisation, docs, measurements](#phase-3--contention-fix-characterisation-docs-measurements)
- [Phase 4 — gate, PR, final QA](#phase-4--gate-pr-final-qa)

**Canonical plan:** [issue #487 comment #3, Rev. 2](https://github.com/HiQS-Labs/XYZ-forge/issues/487#issuecomment-5575660146) — the full recon-grounded plan with seams, design decisions D1–D6, the ordered implementation list with inline verification, and the falsifier mapping. This doc is the in-repo status surface; the GH comment is the plan of record. Recon ledger: `temp/recon-gh487-ci-route.md` on the primary checkout (scratch; not committed).

**Rating** (RELEASES DB): `rated 55/30/50/60` — sev 30: workflow latency (one observed 698 s draft-publish wait; no data loss); pri 55: operator-driven, plan already reviewed; appeal 50 neutral; effort 60: surgical registry/hook changes but a guarded contract with six pinning test files.

## The asks (from the issue, as amended by review)

1. First pushes classify against a verified merge-base with the integration branch; missing/ambiguous/stale base evidence fails closed to the full gate.
2. Register isolated skill code + dedicated tests as bounded subsystems (skills-army-hq here); shared test infra, gate/routing files, kernel paths, and unknown paths stay on the full gate; no global `skills/**` or `test/**` exemption. Dedicated tests exempt from the tier-3 rule **only with co-touch** (the same push also touches the subsystem's code).
3. Draft-review publication documented as distinct from merge readiness, using the existing loud bypasses.
4. Contention: gh365 fix applied (red witnessed in review); remaining flakers characterised before any `DRIVER_LOCK_LANE` entry; no serialization without a proven shared resource.

## Phase 1 — classifier + registry

Red contract tests in `test/ci-route.sh` first (tier 2 for mapped skill + dedicated tests + subsystem code; tier 3 for dedicated-test-alone, `test_python_layer.py`, unregistered tests; tier 1 for `TESTS-RESULTS/**` receipts; not-docs for receipt + executable mix; full for deleted dedicated suite), then implement D4 (TESTS-RESULTS docs pattern), D2 (skills-army-hq subsystem + `test/skills-army-hq.sh` wrapper + TESTS entry), D3 (claimed-test co-touch resolution).

**QA gate:** new cases green; `test/gh365-tier-fail-closed.sh` T1 sweep green; `test/gh35-test-tiers.sh` drift guard green both directions; ghost-suite negative still exits 2.

## Phase 2 — hook merge-base classification

Red hook tests in `test/gh544-pre-push-gate.sh` (fixture repos gain an origin remote + development branch; new-branch-with-base → narrow; no refs / unrelated history / empty range / push-by-URL → full with named reason; mixed push resolves every pair), then D1 in `githooks/pre-push` (per-pair base resolution shared by `classify_push` and the tier-2 paths-file loop; every failure path returns 1).

**QA gate:** step-3 cases green; `test/ci-route.sh:43` zero-path fail-closed pin and `:96-134` rename guard untouched and green.

## Phase 3 — contention fix, characterisation, docs, measurements

gh365 `unset RT_SHARD` (red re-run in this clone first: `RT_SHARD=1 bash test/gh365-validate-telemetry.sh` → rc=1/~345 B/A2; then green both envs, 16 pass; do not widen — `gh35-test-tiers.sh` passes untouched). Characterise the flake surface from the step-8 full-gate logs and post the table to the issue; lane entries only for proven shared resources. Docs per D5 (ROUTER.md, pre-push header, AGENTS.md). Measured timings + contention table into `TESTS-RESULTS/2026-09-07+GH-487/` (provenance.jsonl + SUMMARY.md, committed with the PR).

**QA gate:** gh365 red→green witnessed in this clone; contention table posted; receipts committed.

## Phase 4 — gate, PR, final QA

Full local gate (the PR self-escalates: `utils/ci-route.sh`/`validate.sh` are full_required surfaces), push through the gate, open PR against `development`, final relay QA per start-task, resolve findings.

**QA gate:** PR open with correct base/head/scope; hosted macOS run attests the head SHA; relay QA Approved.

## Lessons Learned (For Future Agents)

1. **`git ls-remote <remote-name>` resolves the FETCH url, not the pushurl.** A remote may carry a
   separate `pushurl`, so a freshness proof built on the remote's *name* can attest a server the push
   never touches — and then declare a stale base fresh. Resolve the destination explicitly with
   `git remote get-url --push` and probe that. Reproduced on a two-bare-repo fixture where the two
   URLs disagreed by one commit; pinned by *"a pushurl that disagrees with the fetch url fails closed
   to full"* in `test/gh544-pre-push-gate.sh`.
2. **A probe's exit status is authoritative; its output is not.** A `ls-remote` that advertised one
   ref and then lost the connection emits partial output that is byte-indistinguishable from a
   complete answer. Deciding on "did it print anything" instead of "did it succeed" silently narrows
   the gate on a failed probe. Every evidence-gathering step must fail closed on nonzero status even
   when it produced plausible output.
3. **Map a review comment to its commit before acting on it.** CodeRabbit anchors each finding to the
   `commit_id` it reviewed. On this PR three of seven findings described commits already superseded at
   head — including the headline Major, fixed 24 minutes before the review posted. Checking
   `gh pr view <n> --json commits` against each comment's `commit_id` separates live findings from
   stale ones and stops an agent from "fixing" code that already carries the fix.
4. **Bounded gates only narrow on positive evidence.** Missing refs, unrelated histories, an empty
   range, a push-by-URL, or an unresolvable base all return 1 and run the full suite. The narrow path
   is the exception that must be earned; anything unproven is not a reason to skip work, it is the
   reason to do all of it.
