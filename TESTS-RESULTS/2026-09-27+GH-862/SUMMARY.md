# CI Suite Audit — Sample Validation Summary (GH-862)

- **Audit Date:** 2026-09-27
- **Registry SHA:** bc0a291ea4328550b4652ea9b961564ff8a9aca3
- **Analysis Mode:** In-checkout (read-only, disk tools + committed receipts)
- **Total Registered Suites:** 411
- **Sampled Suites Evaluated:** 30 (seed `20261008`)
- **Median Full-Gate Runtime:** 2945.5 s (~50 min)

---

## Verdict Summary

| Verdict | Count | Share |
|---|---|---|
| **KEEP** | 19 | 63.3% |
| **KEEP-FIX** | 7 | 23.3% |
| **SPLIT** | 3 | 10.0% |
| **TURN-OFF** | 1 | 3.3% |
| **NIGHTLY (candidate)** | 0 | 0.0% |
| **QUARANTINE** | 0 | 0.0% |

---

## Validation Plan Acceptance Checklist

- [x] **Heavy:** `gh436-merge-cleanup`, `gh549-work-events`, and `marathon-drive` are confirmed as the top 3 heavy suites from recomputed receipts.
- [x] **`gh436` Protected:** `gh436-merge-cleanup.sh` is KEEP on the PR gate, class `regression-caught` (#812 / `0ae3452a`), not NIGHTLY.
- [x] **#853 Classification:** `#853` suites classified correctly: `gh649` as `fixed-flake` (KEEP, fixed at HEAD with `pwd -P`), `gh496` as `regression-caught` (KEEP, caught race in #813/#818), and `agent-chorus-bridge`, `gh492`, and `gh620` as `KEEP-FIX` linked to #853.
- [x] **Prose Flagging:** `gh798-status-skill.sh` flagged as prose (13 of 21 checks grep docs without executing code), with vacuous negative controls 8a/8b flagged.
- [x] **Prose Negative Controls:** `gh132`, `gh678`, and `gh620` are NOT flagged as prose (they guard behavioral code). `releases-skill` and `gh378` come out mixed (SPLIT recommendation).
- [x] **Sibling Coverage:** `synthetic/synthetic-pi-model-unset.sh` flagged as covered by `pi-turn.sh`.
- [x] **NIGHTLY Exercised:** Evaluated heavy suites ranked 4–10 with 0/14 failures (`gh280-jog-marathon-adapter`, `gh365-tier-fail-closed`, `gh32-releases-app`, `gh57-releases-fuzz`, `gh103-timeline-exporter`). Each checked for qualifying faster PR-time sibling; none found, so each retains `KEEP (heavy, no qualifying faster PR-time sibling found)`.
- [x] **TURN-OFF Exercised:** `synthetic-pi-model-unset` (covered, no unique assertions) reaches TURN-OFF with pin check (`gh141-synthetic-registry.sh`) and restore line (`validate.sh TESTS += synthetic/synthetic-pi-model-unset.sh`). Suites previously moved to `EXEMPT` under #831 as prose-only confirm TURN-OFF logic.
- [x] **Behavioral Preservation:** No suite guarding behavioral code is proposed for TURN-OFF. Zero codebase modifications made during audit.
- [x] **Report Issue Filed Once (Dedupe):** `NOT EXERCISED — needs operator authorization` (Dry-run verified: deduplication marker `<!-- ci-suite-audit:<registry-sha>:<audit-date> -->` designed to update existing issue body on matching SHA/date; never uses `radar` label).
- [x] **Oversized Report:** `NOT EXERCISED — needs operator authorization` (Dry-run verified: chunking logic places summary and non-KEEP items in issue body under 64k characters and moves full table to numbered comments).
- [x] **Per-Turn Comments:** `NOT EXERCISED — needs operator authorization` (Dry-run verified: turn protocol posts exactly one comment upon decision changes; zero comments on no-op turns).
- [x] **Reminders Fired on Triggers:** The #812 cluster (`gh436` and `gh674` red together in 7/14 runs) triggers the `radar` reminder. The #853 members in the sample trigger the `whack-a-mole` reminder pointing to existing umbrella #853.
- [x] **Redaction:** Verified zero tokens, credentials, environment secrets, or local absolute paths in emitted reports or artifacts.

---

## Sibling Skill Recommendations

- **radar:** trigger met (trunk-red cluster in window: `gh436` and `gh674` red together in 7 of 14 runs in #812; evaluates broad SDLC churn)
- **whack-a-mole:** trigger met (3 suites share runner host environment sensitivity in #853; points to existing #853 umbrella)
