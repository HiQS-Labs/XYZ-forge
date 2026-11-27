---
title: "GH-1663: ci-optimize SKILL.md principle count, tree-only links, bare issue numbers"
status: Active
created: 2026-11-27
updated: 2026-11-27
owner: operator (via /start-task)
gh_issue: 1663
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1663
doc_type: bugfix
complexity: 1
risk: 1
effort: 1
phases: 1
ratings_provisional: true
non_goals:
  - Redesign, reword for style, or change what any principle requires
  - Rescale the scorecard or its A/B/C bands
  - Add scorecard rows or waves for P13/P14
  - Touch skills/2-daily/merge-cleanup/ (parallel work) or close umbrella #1661
  - Add any test, suite, or gate registration (GH-831)
goal: >
  Make skills/4-occasional/ci-optimize/SKILL.md self-consistent and portable with the smallest
  text change: 14 principles with P13/P14 marked as situational extensions outside the 12-row
  scored rubric, flat-install fallbacks for both relative links, and a named repo for the bare
  issue numbers.
---

# GH-1663 - ci-optimize SKILL.md small defects

Tracks the `ci-optimize` slice of umbrella [#1661](https://github.com/HiQS-Labs/XYZ-forge/issues/1661) (Refs only; this PR does not close it).

## Status

| What was just completed | What's next |
|---|---|
| Plan written; defects verified against `origin/development` at `52813e56f` (Recon below). | Codex plan QA, then the edit, the focused checks, final Codex QA, ready PR. |

## Recon (base `52813e56f`, documentation-only: instruction/consumer path)

Consumers of the file: the skill loader (frontmatter `description` is the trigger text), `ARCHITECTURE.md` (one-line table row, no count), two existing suites that grep the text, and the skill itself when read by an agent. Nothing parses the "12" count.

- `test/gh578-ci-optimize-skill.sh` greps `### 1.` to `### 12.`, the P1-P12 titles, `show-ref`, `20–25 runs each`, the Wave 1 / Wave 4 / scorecard section markers and `20–24 Points`.
- `test/gh609-sdlc-agent-gaps.sh` (`check_ci_optimize_contract`) greps the exact headings `13. Bounded Flake Stress Loops and Active Quarantine Sinks` and `14. Workload-Scoped Performance and Resource Budget Fences` and several single-line phrases inside P13/P14. So the P13/P14 headings and bodies must stay byte-identical. Both suites are existing and are used unchanged.
- Open PRs touching the file: none (`prior_art_recon`). #1133 (necessity review, text-only, paused) is a different scope on the same file.
- Link targets exist in the Forge tree: `skills/1-hourly/sanity-check/` and `skills/4-occasional/ci-suite-audit/`.
- The nine cited issue numbers (`#35, #42, #376, #365, #528, #544, #558, #549, #564`) all exist in HiQS-Labs/XYZ-forge as issues (not PRs), so labeling them XYZ-forge numbers is true (they are not upstream-archive numbers).

## Verified defects (each re-read at the base; line numbers drift)

| # | Defect | Evidence at base |
|---|---|---|
| 1 | Principle count: description says "12-point", heading says "12 Foundational Principles", but there are 14 principle headings; waves and scorecard cover P1-P12 only | `### 1.` to `### 14.` present; waves list P1,P6 / P5,P7 / P2,P3 / P4,P8-P12; scorecard rows 1-12 |
| 2 | `../../1-hourly/sanity-check/SKILL.md` and `../ci-suite-audit/SKILL.md` resolve only in the Forge tree; the flat fallback sentence exists once (sanity-check, in a later paragraph), none for ci-suite-audit | link lines in "Related skill" and "Related Skills" |
| 3 | Bare `#35, #42/#376, ...` with no repo | provenance sentence at the top |
| 4a | Extra, proven contradiction: the roadmap diagram's Wave 4 node reads "P4 Flakes, P8 Seams, P10-P12 Invariants" and omits P9, while the Wave 4 list below it names P9 | diagram vs list |
| 4b | Extra, proven wording: "Adopt these principles in 4 structured waves" is false for 14 principles once P13/P14 are named, because the waves cover P1-P12 | follows from defect 1 |

I looked for other wrong counts, dead anchors and cross-section contradictions (scorecard rows vs principle numbers 1-12, wave membership vs the union P1-P12, score bands 0-24 vs 12 rows x 2, the new-tests callout's principle numbers 7, 8, 10 and Wave 2, the anti-pattern principle numbers 1, 4, 5, 8, internal anchors). None found beyond 4a and 4b. The "Repos that forbid new tests (XYZ-forge ... GH-831)" callout is already repo-labeled and stays untouched.

## Preflight Bet Check

- **Outcome sought:** a reader of the portable skill gets a count that matches the rubric they score, links that resolve in both layouts, and provenance numbers that name their repo.
- **Smallest viable bet:** text edits in one file (below). **Not built:** new scorecard rows, a fifth wave, rescaled bands, a link checker, any test.
- **Alternatives rejected:** (a) add P13/P14 rows and a wave: changes the rubric's meaning and the A/B/C bands (max 24 becomes 28), out of scope and a design change; (b) say "12 principles" and delete P13/P14: removes content other suites pin (gh609); (c) a prose-only count fix with no marking: leaves P13/P14 unscored with no explanation.
- **Rollback / containment:** `git revert` of one docs commit; no runtime consumer.

## Requirements and per-file change (one ordered list, verification inline)

1. Frontmatter `description`: replace "Provides a structured 12-point audit rubric," with "Provides 14 principles (a 12-point scored audit rubric plus two situational extensions)," keeping the rest.
2. Provenance sentence: `(#35, ... #564)` becomes `(XYZ-forge issue numbers, in [HiQS-Labs/XYZ-forge](https://github.com/HiQS-Labs/XYZ-forge): #35, ... #564)`.
3. Heading `## The 12 Foundational Principles` becomes `## The 14 Foundational Principles`, with one intro line directly under it: Principles 1-12 are scored in the scorecard and sequenced in the four waves; Principles 13-14 are situational extensions, applied when the situation arises, intentionally outside the 12-row scored rubric and the waves. The existing "Repos that forbid new tests" callout stays as is.
4. Roadmap: "Adopt these principles in 4 structured waves" becomes "Adopt Principles 1-12 in 4 structured waves"; the diagram's Wave 4 node gains P9 ("P4 Flakes, P8 Seams, P9 Hosted CI, P10-P12 Invariants").
5. One line under the scorecard table: P13 and P14 have no row; the 0-24 scale and the A/B/C bands score P1-P12 only. Bands unchanged.
6. Related Skills bullet for `ci-suite-audit`: append "In a flat installed collection, resolve `ci-suite-audit` by name." (same sentence shape as the existing sanity-check one). The relative links stay.
   - Verify (after 1-6): `TESTS-RESULTS/2026-11-27+GH-1663/check_ci_optimize.py` prints before (base) and after counts: principle headings 14 and 14, scorecard rows 12 and 12, "12-point"/"12 Foundational" literals, whether P9 is in the Wave 4 node, and resolves each relative link in a Forge-tree layout and in a flat layout copy (the links resolve in the tree; in the flat layout they do not, and each flat-layout link has a name-resolution fallback sentence within the same file). Results go in `provenance.jsonl`.
   - Verify: existing `bash test/gh578-ci-optimize-skill.sh` and `bash test/gh609-sdlc-agent-gaps.sh` stay green (P13/P14 headings untouched).
   - Verify: `utils/pdda/pdda.sh run` zero errors, and the final gate route from the classifier on the committed diff.

## Acceptance

- [ ] Both counts agree: 14 principle headings, text says 14; scorecard rows and bands unchanged and described as P1-P12.
- [ ] Every relative link has a flat-install fallback sentence; relative links unchanged.
- [ ] Issue numbers named as HiQS-Labs/XYZ-forge once.
- [ ] Manual check recorded with `provenance.jsonl`; existing suites and docs route green; no new test or registry entry; one skill file changed.
- [ ] Observed rejection: the checker run against the unchanged base file reports the inconsistencies (count text 12 vs 14 headings; P9 missing from the diagram; ci-suite-audit without fallback), so an unfixed candidate cannot be reported as delivered.

## Risks

Low. The two pinning suites are the only text consumers and the P13/P14 text is untouched. An agent reading "situational extension" must not read it as "optional to ignore": the wording says apply when the situation arises.

## PRS rating (read-back of the ledger row is authoritative)

- pri 30: no consequence in Forge today; the defects mislead a reader of a portable skill. Departure from severity-led ordering: none.
- sev 15: wrong count and unresolvable links in prose; no runtime effect, no data at risk.
- appeal 45: operator-supplied.
- effort 85: one text file, existing checks. Recurrence: unknown trend; one report (#1661), independently confirmed by Codex. Dated 2026-11-27.
