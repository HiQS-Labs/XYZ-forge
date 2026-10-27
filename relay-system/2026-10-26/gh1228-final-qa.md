---
Goal: Final QA — GH-1228 implementation (scope three vendored GH-831 lines to XYZ-forge)
Date: 2026-10-26
NEXT: codex
STATUS: Approved
---

# Context

Review the committed implementation (`git diff 1f5b0508..HEAD`, commits `2837159d` and `fc7808f1`) against the approved plan in `PROJECT/2-WORKING/GH-1228-GH831-VENDORED-SCOPE.md` (plan QA: `relay-system/2026-10-26/gh1228-plan-qa.md`, approved round 4).

Requirement: a vendored `.xyz/` must not tell a host repo it may not add tests. XYZ-forge's own GH-831 rule stays in force.

Operational envelope: three lines of skill text, docs route. No new tests, suites, gates or machinery (GH-831). A new test file or registry entry in the diff is a finding.

Read: `skills/2-daily/express/SKILL.md` (lines 28 and 172-175), `skills/4-occasional/ci-suite-audit/SKILL.md:342`, `CHANGELOG.md` (the new GH-1228 entry), and `TESTS-RESULTS/2026-10-26+GH-1228/` (smoke.md, recon-grep.log, vendor-smoke.log, pdda.log, provenance.jsonl).

Questions:

1. Does the diff implement exactly plan steps 1–4, with nothing extra? Does the release-ledger change (`releases.db`/`.sql`) contain only the GH-1228 park, rate and accepted-start?
2. Does each rewritten line keep XYZ-forge's GH-831 rule intact and defer elsewhere to the host repo's policy? Is the express discipline still coherent (express still requires an existing covering suite)?
3. Do the evidence logs support the claims: route docs/tier 1, red control (3 → 0), vendor smoke on fresh and re-vendor paths, and no PDDA finding on touched files?
4. Is the CHANGELOG entry accurate?

Cite file:line. Use `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`.

**Required output format:** append one block under `## Log` containing a line `VERDICT: PASS` or `VERDICT: FAIL` (exactly), a one-line `Basis:` line, then your findings. Set STATUS to Approved on PASS.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Log

### Codex final QA (2026-10-26)

VERDICT: PASS

Basis: The three scoped skill-text edits, committed manual evidence, and GH-1228 ledger state implement the approved four-step docs-route plan without a host-wide test prohibition or an extra verification subsystem.

- [Pass] `skills/2-daily/express/SKILL.md:28,173-174` preserves Express's
  existing-covering-suite requirement while limiting GH-831 to XYZ-forge and
  sending an uncovered fix to the host's own test policy; `skills/4-occasional/ci-suite-audit/SKILL.md:342`
  likewise scopes the no-new-tests condition and explicitly defers elsewhere.
  This is coherent with the Express discipline at `skills/2-daily/express/SKILL.md:28`
  and `:171-174`; no test, suite, gate, or runner is introduced.

  Read-only probe (exit 0): `rg -n -i -e 'no new tests|no new suite|test freeze'
  skills/2-daily/express/SKILL.md skills/4-occasional/ci-suite-audit/SKILL.md`
  returned the scoped `express:174` and `ci-suite-audit:342` policy statements;
  the remaining hits describe existing skill-local behavior rather than a
  GH-831 rule imposed on a vendored host.

- [Pass] The evidence is internally consistent and commensurate for this
  documentation-only change: `TESTS-RESULTS/2026-10-26+GH-1228/smoke.md:3-8`
  records `route=docs tier=1`, the base-to-head three-hit-to-zero red control,
  and fresh plus re-vendor read-back. The underlying receipts corroborate it:
  `recon-grep.log:1-14` records the three former lines, head grep exit 1, and
  docs tier 1; `vendor-smoke.log:3-10` records no unscoped vendored pattern
  and counts 2/1 scoped lines after re-vendor; `pdda.log:188-189` records no
  errors and exit 0. The 41 warnings are pre-existing, unrelated paths as
  shown by `pdda.log:164-182`, not findings on a touched file.

- [Pass] `CHANGELOG.md:3-12` accurately states the three rewritten skill
  locations, the retained Express existing-suite constraint, the deliberately
  unchanged harness-local README, docs-route verification, and no-new-tests
  outcome.

- [Pass] The ledger has exactly the expected GH-1228 lifecycle state:
  `releases.sql:901` contains the one in-progress/rated roadmap row and
  `releases.sql:4115-4117` records only `parked`, `rated`, and `in_flight`
  (`accepted_start`) events. Read-only SQLite probe (exit 0):
  `sqlite3 -header -column releases.db "SELECT event, payload FROM work_events WHERE gh_number = '1228' ORDER BY at;"`
  returned precisely those three events, with rating `60/45/50/92` and
  `accepted_start: true`.

### Attestation · relay-drive — 2026-10-27T03:35:05Z
task: RELAY-gh1228-final-qa
reviewer: codex
status: Approved
reviewed-head: c94a14e9eda41b84f2b9d16b7b1f72ef962fb465
added-range: 1989+2523
added-sha256: 9fff4577f551e78a4cf6998b4094cc995b800a6824ca999dc8d6efc88d905556
