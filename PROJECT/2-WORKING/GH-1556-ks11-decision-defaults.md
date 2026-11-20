---
issue: 1556
title: "kickstart(KS-11): fail-closed decision defaults in launch authority template and SKILL.md"
status: active
roadmap_id: rmi-01M7W49MQWX5WDGFH04176P39V
parent_arc: 1541
milestone: KS-11
owner: antigravity
goal: "Codify and verify KS-11 fail-closed decision defaults (a: round cap with independent protected-surface inspection, b: conflict hubs, c: KS-02 owner/applicable/non-superseded decisions) across build_queue.py and kickstart/SKILL.md with pinned #1519 red/green replay."
created: 2026-11-20
updated: 2026-11-20
---

# GH-1556 (KS-11) — Fail-Closed Decision Defaults

## Status

| What was just completed | What's next |
|---|---|
| Addressed Plan QA R1 blockers (F1: protected-surface inspection independent of `ci-route.sh full_required` using real `githooks/pre-push` counterexample; F2: pinned pre-KS-03 historical baseline for #1519 replay + full positive/negative KS-11a/b/c manual walkthrough with exact inputs/outputs/provenance). | Complete Plan QA R2 approval, implement KS-11 in `skills/1-hourly/kickstart/SKILL.md` and align `build_queue.py`, run disposable-clone probes + pinned #1519 manual replay + mypy + PDDA under `TESTS-RESULTS/2026-11-20+GH-1556/`, and pass Final QA. |

## Objective
Codify KS-11 fail-closed decision defaults cleanly in `skills/1-hourly/kickstart/SKILL.md` and align `skills/1-hourly/kickstart/scripts/build_queue.py`'s `AUTHORITY` text (fixing the `full_required` over-reliance), verified by a reproducible, truthfully labeled paired red/green replay grounded in pinned historical #1519 baseline artifacts and real `utils/ci-route.sh` probes. No new policy engine, classifier change, or test suite.

## Grounded Recon
- `skills/1-hourly/kickstart/scripts/build_queue.py:54-64` (landed via KS-03 #1546): currently summarizes KS-11(a)/(b)/(c) and references `(utils/ci-route.sh full_required)` next to gate/hook/containment/schema/kernel/Costly surfaces.
- **Critical classifier limitation verified directly:** `printf "%s\n" githooks/pre-push | bash utils/ci-route.sh pull_request` returns `full_required=false`, `route=fast`, `tier_reason=unmapped path: githooks/pre-push`, and `Costly` is a change-level reversibility assessment rather than a path-classifier output. Therefore `full_required=true` is a *sufficient* trigger to deny Minor/nit deferral, but `full_required=false` NEVER proves absence of a protected surface.
- Historical pre-KS-03 baseline commit (`0edbab45d6`, parent of #1546 merge `d87a4e1bfc`) shows pre-KS-03 `build_queue.py` and `kickstart/SKILL.md` had zero KS-11 round-cap / conflict-hub / owner-applicability decision rules (forcing operator questions like #1519).
- `PROJECT/PDDA.md:462-465`: honor configured `CHANGELOG_WRITES` mode (no task-branch `CHANGELOG.md` edit under default `off`/`landing`).

## Plan
1. **`skills/1-hourly/kickstart/SKILL.md`:**
   - Add **Fail-Closed Decision Defaults (KS-11)** subsection specifying the exact deterministic child decision procedure:
     - **(a) Relay Round Cap:** land ONLY with an independent reviewer's explicit approval covering the exact final head SHA. Minor/nit findings may be deferred ONLY when ALL hold: (i) the reviewer explicitly tagged every deferred item Minor/nit AND accepted the deferral on the current head, AND (ii) direct inspection of the actual changed files AND reversibility assessment confirms NO gate, hook (e.g., `githooks/*`), containment, schema, kernel, or Costly/irreversible surface is touched, AND `utils/ci-route.sh` does NOT report `full_required=true`. Treat `full_required=false` conservatively: it NEVER grants permission to defer on a named protected surface or when surface/reversibility classification is unknown (unknown -> PARK). Any PR landed with reviewer-accepted Minor/nit deferrals MUST state so explicitly in the PR body and run record and NEVER claim unqualified `Approved` beyond what the reviewer stated.
     - **(b) Conflict Hubs:** PRs identified as conflict hubs by the merge-cleanup landing forecast route to a separate recorded batch rather than stalling clean PRs or asking the operator.
     - **(c) Operator Decisions (KS-02):** honor a hold release ONLY when authored by `--owner`, applicable to the current issue/head state, and not superseded by a later owner decision or run-record amendment; otherwise stay held.
2. **`skills/1-hourly/kickstart/scripts/build_queue.py`:**
   - Tighten `AUTHORITY` line 58 so it states explicitly that protected surfaces (gate, hook, containment, schema, kernel, or Costly) are checked by inspecting actual changed files and reversibility as well as `utils/ci-route.sh` `full_required` (`full_required=false` never waives a named protected surface; unknown parks).
   - Verify `mypy --allow-untyped-defs --allow-incomplete-defs skills/1-hourly/kickstart/scripts/build_queue.py`.
3. **Paired Red/Green Replay & Real Classifier Probes (`TESTS-RESULTS/2026-11-20+GH-1556/`, no new policy engine or test suite):**
   - **Pinned Historical Baseline (Red):** retain the exact pre-KS-03 commit SHA (`0edbab45d6`) excerpt of `build_queue.py` `AUTHORITY` and `kickstart/SKILL.md` showing no round-cap / protected-surface / conflict-hub / decision-supersession defaults existed, plus the #1519 round-cap input shape (which required an operator question).
   - **Real `utils/ci-route.sh` Path Probes (read-only command outputs retained verbatim):**
     - Positive docs-only path (`skills/1-hourly/kickstart/SKILL.md`) -> `route=docs`, `full_required=false`.
     - Real hook counterexample (`githooks/pre-push`) -> `route=fast`, `full_required=false` (proving why direct surface inspection is mandatory!).
     - `full_required=true` path (e.g., `.github/workflows/ci.yml` or `utils/ci-route.sh`) -> `full_required=true`.
   - **Bounded Manual Policy Walkthrough (truthfully labeled as manual policy replay walking each predicate of the revised `SKILL.md` + `build_queue.py` text):**
     - KS-11(a) cases: (1) docs-only PR with explicit approval on current head + reviewer-tagged/accepted Minor/nit deferral -> LAND with explicit deferral disclosure (never claiming unqualified `Approved`); (2) #1519 shape: unapproved / Major finding at round cap -> PARK (no operator question); (3) `githooks/pre-push` hook counterexample (`full_required=false` yet named hook surface) -> PARK (protected surface blocks deferral); (4) `full_required=true` or Costly/unknown reversibility -> PARK; (5) reviewer approval on stale head SHA != current head -> PARK.
     - KS-11(b) case: forecast-identified conflict hub -> separate recorded batch.
     - KS-11(c) cases: (1) valid current `--owner` decision applicable & not superseded -> RELEASE (positive control); (2) same `--owner` decision that is inapplicable to current issue/head -> HOLD; (3) non-owner comment -> HOLD; (4) superseded owner decision -> HOLD.
   - Run `./utils/pdda/pdda.sh run` (0 errors), `utils/ci-route.sh`, `mypy`, and generate non-empty `provenance.jsonl`.

## Acceptance Criteria
- `skills/1-hourly/kickstart/SKILL.md` and `build_queue.py` consistently codify KS-11(a)/(b)/(c), explicitly inspecting changed surfaces & reversibility independent of `full_required=false`.
- Pinned historical baseline, real `ci-route.sh` probes (including `githooks/pre-push` counterexample), full KS-11(a)/(b)/(c) manual replay, mypy, PDDA (0 errors), and `provenance.jsonl` retained under `TESTS-RESULTS/2026-11-20+GH-1556/`.
