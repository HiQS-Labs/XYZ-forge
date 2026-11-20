---
gh_issue: 1556
title: "kickstart(KS-11): fail-closed decision defaults in launch authority template and SKILL.md"
status: Complete
roadmap_id: rmi-01M7WQ3CNCG4FBDBZ90J5BMZC9
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
| Addressed Plan QA R2 blocker (F2): grounded the #1519 replay in the exact sourced PR #1532 artifacts (URL, comment #7029123199, verbatim round-cap text, heads `eea4c81a0`/`2a3601a90`, `validate.sh`), added nonempty input/excerpt checks, separated policy-quote/predicate/observed-action recording from expectations, labeled pre-KS-03 `0edbab45d6` as historical absence, and added a scratch-copy sensitivity ablation on the `githooks/pre-push` hook case. | Complete Plan QA R3 approval, implement KS-11 in `skills/1-hourly/kickstart/SKILL.md` and align `build_queue.py`, run disposable-clone probes + pinned #1519 manual replay + mypy + PDDA under `TESTS-RESULTS/2026-11-20+GH-1556/`, and pass Final QA. |

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
3. **Paired Red/Green Replay, Sensitivity Ablation & Real Classifier Probes (`TESTS-RESULTS/2026-11-20+GH-1556/`, no new policy engine or test suite):**
   - **Sourced #1519 Input Record (`outputs/gh1519-pr1532-input.json`):** retain verbatim from live `gh pr view 1532` (issue #1519's PR `https://github.com/HiQS-Labs/XYZ-forge/pull/1532`, head `2a3601a9009966f7bacd39eebe77f6f9bfbfba47`, full-gate head `eea4c81a0`, operator comment `https://github.com/HiQS-Labs/XYZ-forge/pull/1532#issuecomment-7029123199`, PR body excerpt `"Codex final QA reached its 3-round cap with one open provenance nit"`, changed files list including `validate.sh`). Verify via script that the retained input JSON and historical baseline excerpts are nonempty (byte count > 0, exit 0) and explicitly label any reconstructed fields used in synthetic control cases (e.g., synthetic non-owner/superseded/inapplicable KS-11c controls).
   - **Pinned Historical Baseline (`outputs/historical-baseline-0edbab45d6.txt`, explicitly labeled *historical absence*, NOT a witnessed behavioral failure):** extract via `git show 0edbab45d6:...` (verifying `0edbab45d6` ancestry and nonempty byte count) the exact pre-KS-03 `build_queue.py` `AUTHORITY` and `kickstart/SKILL.md` excerpts showing no KS-11 round-cap/protected-surface/conflict-hub/owner-supersession rules existed.
   - **Real `utils/ci-route.sh` Path Probes (`outputs/ci-route-probes.txt`, exit status + verbatim stdout recorded):**
     - Positive docs-only path (`skills/1-hourly/kickstart/SKILL.md`) -> `route=docs`, `full_required=false`.
     - Real hook counterexample (`githooks/pre-push`) -> `route=fast`, `full_required=false`.
     - Gate surface from #1519/PR #1532 (`validate.sh`) -> `full_required=true`.
   - **Candidate Sensitivity Ablation (proving the new independent protected-surface clause is load-bearing, not decorative):**
     - Hold every predicate constant on the `githooks/pre-push` hook case (`ci-route.sh` `full_required=false`, explicit current-head reviewer approval, reviewer-tagged & accepted Minor/nit deferral, reversible).
     - Walk (a) a scratch copy with the independent protected-surface/reversibility clause removed/replaced by `full_required`-only -> observed disposition fails to block deferral on `githooks/pre-push` (unsafe permission / missing prohibition), vs (b) the actual candidate `SKILL.md` + `build_queue.py` text -> observed disposition deterministically **PARKS** citing the quoted independent hook-surface prohibition.
   - **Bounded Manual Policy Walkthrough (`manual-check.md`, applying identical recorded inputs to baseline & candidate; recording policy quotation + file:line, evaluated predicate table, observed resulting action + disclosure separately from expectation, plus candidate revision SHA):**
     - KS-11(a): (1) docs-only PR with explicit current-head approval + reviewer-tagged/accepted Minor/nit deferral -> observed LAND with explicit deferral disclosure (never unqualified `Approved`); (2) sourced #1519/PR #1532 input (3-round cap, unapproved final head, `validate.sh` gate surface) -> observed PARK (no operator question); (3) `githooks/pre-push` hook counterexample (`full_required=false`, paired with the scratch-copy ablation above) -> observed PARK; (4) `full_required=true` or Costly/unknown reversibility -> observed PARK; (5) stale reviewer approval (`reviewed_sha != current_head`) -> observed PARK.
     - KS-11(b): forecast-identified conflict hub -> observed separate recorded batch.
     - KS-11(c) (synthetic fields explicitly labeled reconstructed): (1) valid current `--owner` decision applicable & not superseded -> observed RELEASE (positive control); (2) same `--owner` decision inapplicable to current issue/head -> observed HOLD; (3) non-owner comment -> observed HOLD; (4) superseded owner decision -> observed HOLD.
   - Run `./utils/pdda/pdda.sh run` (0 errors), `utils/ci-route.sh`, `mypy`, and generate non-empty `provenance.jsonl`.

## Acceptance Criteria
- `skills/1-hourly/kickstart/SKILL.md` and `build_queue.py` consistently codify KS-11(a)/(b)/(c), explicitly inspecting changed surfaces & reversibility independent of `full_required=false`.
- Pinned historical baseline, real `ci-route.sh` probes (including `githooks/pre-push` counterexample), full KS-11(a)/(b)/(c) manual replay, mypy, PDDA (0 errors), and `provenance.jsonl` retained under `TESTS-RESULTS/2026-11-20+GH-1556/`.
