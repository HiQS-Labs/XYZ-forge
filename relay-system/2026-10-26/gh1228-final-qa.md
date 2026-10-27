---
Goal: Final QA — GH-1228 implementation (scope three vendored GH-831 lines to XYZ-forge)
Date: 2026-10-26
NEXT: codex
STATUS: Open
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
