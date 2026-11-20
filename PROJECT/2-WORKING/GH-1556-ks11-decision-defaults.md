---
issue: 1556
title: "kickstart(KS-11): fail-closed decision defaults in launch authority template and SKILL.md"
status: active
roadmap_id: rmi-01M7VQW02KMDKEVC6SAXN6TQRN
parent_arc: 1541
milestone: KS-11
owner: antigravity
goal: "Codify and verify KS-11 fail-closed decision defaults (a: round cap, b: conflict hubs, c: KS-02 owner/applicable/non-superseded decisions) across build_queue.py and kickstart/SKILL.md with #1519 red/green replay."
created: 2026-11-20
updated: 2026-11-20
---

# GH-1556 (KS-11) — Fail-Closed Decision Defaults

## Status

| What was just completed | What's next |
|---|---|
| Created fresh clone, registered `rmi-01M7VQW02KMDKEVC6SAXN6TQRN`, completed grounded recon of `build_queue.py:43-73` (KS-03 authority template) and `skills/1-hourly/kickstart/SKILL.md`. | Complete Codex Plan QA, codify KS-11 fail-closed decision rules in `kickstart/SKILL.md` and align `build_queue.py`, run paired #1519 red/green replay + mypy + PDDA under `TESTS-RESULTS/2026-11-20+GH-1556/`, and pass Final QA. |

## Objective
Ensure kickstart's fail-closed decision defaults (issue #1541 KS-11) are completely specified, consistent between `skills/1-hourly/kickstart/scripts/build_queue.py` (KS-03 template) and `skills/1-hourly/kickstart/SKILL.md`, and verified with a discriminating #1519 round-cap red/green replay so no operator question is needed for round caps, conflict hubs, or owner decisions.

## Grounded Recon
- `skills/1-hourly/kickstart/scripts/build_queue.py:54-64` (landed via KS-03 #1546): already carries the launch-authority summary lines for KS-11(a), (b), and (c) in `AUTHORITY`.
- `skills/1-hourly/kickstart/SKILL.md`: does not yet have a dedicated operational specification for the child's fail-closed decision procedure on KS-11(a) round cap (exact surface check against `utils/ci-route.sh` `full_required`, exact reviewer-tagged Minor/nit deferral criteria, explicit PR/record disclosure wording never claiming `Approved` beyond what the reviewer stated), KS-11(b) conflict-hub separate batch recording, and KS-11(c) KS-02 owner/applicable/non-superseded verification.
- `utils/ci-route.sh`: defines `full_required` surfaces (gate, hook, containment, schema, kernel, Costly) that NEVER allow Minor/nit auto-accept/deferral under KS-11(a).
- `PROJECT/PDDA.md:462-465`: honor configured `CHANGELOG_WRITES` mode (no task-branch `CHANGELOG.md` edit under default `off`/`landing`).

## Plan
1. **`skills/1-hourly/kickstart/SKILL.md`:**
   - Add **Fail-Closed Decision Defaults (KS-11)** subsection specifying the exact deterministic child decision procedure with zero operator questions:
     - **(a) Relay Round Cap:** land ONLY with an independent reviewer's explicit approval covering the exact final head SHA. Minor/nit findings may be deferred ONLY when (i) the reviewer explicitly tagged them Minor/nit AND accepted the deferral, AND (ii) the changed files do NOT touch gate, hook, containment, schema, kernel, or Costly surfaces (`utils/ci-route.sh` `full_required`). Otherwise park the item and continue independent work. Any PR landed with reviewer-accepted Minor/nit deferrals MUST state so explicitly in the PR body and run record and NEVER claim unqualified `Approved` beyond what the reviewer stated.
     - **(b) Conflict Hubs:** PRs identified as conflict hubs by the merge-cleanup landing forecast route to a separate recorded batch rather than stalling clean PRs or asking the operator.
     - **(c) Operator Decisions (KS-02):** honor a hold release ONLY when authored by `--owner`, applicable to the current issue/head state, and not superseded by a later owner decision or run-record amendment.
2. **`skills/1-hourly/kickstart/scripts/build_queue.py`:**
   - Verify `AUTHORITY` lines 54–64 match `SKILL.md`'s KS-11(a)/(b)/(c) contract verbatim (surgical alignment if any wording gap exists) and verify `mypy`.
3. **Paired Red/Green Checks (`TESTS-RESULTS/2026-11-20+GH-1556/`, no new test suite GH-831):**
   - **Control 1 (#1519 round-cap shape replay):**
     - *Pre-change / Red:* show pre-KS-11 behavior where hitting the round cap on #1519 had no fail-closed child rule and forced an operator question.
     - *Changed / Green:* evaluate the KS-11(a) decision matrix across 4 concrete cases using real `utils/ci-route.sh` route classification: (i) docs-route PR with reviewer explicit approval + reviewer-accepted Minor/nit deferral -> deterministic LAND with explicit deferral disclosure; (ii) docs-route PR with unapproved/Major finding at round cap -> deterministic PARK (no operator question); (iii) `full_required` (hook/gate/schema) PR with Minor/nit deferral at round cap -> deterministic PARK (never auto-accept); (iv) approval on stale head SHA != current head -> deterministic PARK.
   - **Control 2 (KS-11b conflict hubs + KS-11c owner/superseded decision):** verify conflict-hub PR routes to separate recorded batch, and non-owner or superseded decision stays held.
   - Run `./utils/pdda/pdda.sh run` (0 errors), `utils/ci-route.sh`, and generate `provenance.jsonl`.

## Acceptance Criteria
- `skills/1-hourly/kickstart/SKILL.md` and `build_queue.py` consistently codify KS-11(a), (b), and (c) fail-closed decision defaults.
- Paired red/green check replaying the #1519 round-cap shape (against real `utils/ci-route.sh`), mypy, PDDA (0 errors), and `provenance.jsonl` retained under `TESTS-RESULTS/2026-11-20+GH-1556/`.
