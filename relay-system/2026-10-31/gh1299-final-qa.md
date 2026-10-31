---
Goal: Final QA for GH-1299 (fold ceremony-audit into sanity-check)
Date: 2026-10-31
---

NEXT: codex
STATUS: In review

# Context

Review the committed change for https://github.com/HiQS-Labs/XYZ-forge/issues/1299: `git diff origin/development...HEAD`. Operator decision: fold the ceremony-audit skill (merged in PR #1289 for #1286) into sanity-check as Plan mode and add a mode-before-skill rule to skills/README.md. Evidence: TESTS-RESULTS/2026-10-31+GH-1299/ (fold-acceptance.md, raw/, inputs/, provenance.jsonl, gates.md).

Operational envelope: Markdown only, no scripts, no new tests (GH-831). Grade against the issue's scope and commensurate complexity. Do not ask for more acceptance rounds, scoring or tooling. Review only: edit nothing except this relay file. No network calls.

Known results to judge, not hide: the #1186 counter-example failed in both fold runs (both cut the optional red control); #1279 scored 4 of 6 with the tested wording, matching the standalone skill.

Questions:

1. Does skills/1-hourly/sanity-check/SKILL.md now carry the full ceremony-audit procedure (all Step 1–4 rules and qualifiers) without changing the existing ladder? Are the Plan mode triggers in the description? Cite file:line.
2. Is skills/1-hourly/ceremony-audit/ fully removed, with no live reference left (index row, links)? Is the ARCHITECTURE.md 1-hourly count (17, including `idea`) correct?
3. Is the skills/README.md rule clear and bounded, and does it sit with the existing add-a-skill contract?
4. Do the receipts and provenance support exactly what CHANGELOG.md claims, including the failed control? Is that an acceptable ship state, or does it block?
5. Is the 50/25/50/85 rating reasonable? Is skipping plan QA (operator-decided fold) acceptable?

Each `[Blocker]` or `[Should]` must carry `Observed input:`, `Affected scope:` and `Falsifier:` lines. Cite file:line.

Write your verdict below. Set STATUS to Approved if the change can ship as committed (minor notes allowed).

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

