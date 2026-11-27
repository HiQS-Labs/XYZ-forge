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
| Plan written; defects verified against `origin/development` at `52813e56f` (Recon below). Plan-QA round 1 returned FAIL on two findings (issue provenance by subject; discriminating acceptance contract); both adopted in this revision. | Codex plan QA round 2, then the edit, the focused checks, final Codex QA, ready PR. |

## Recon (base `52813e56f`, documentation-only: instruction/consumer path)

Consumers of the file: the skill loader (frontmatter `description` is the trigger text), `ARCHITECTURE.md` (one-line table row, no count), two existing suites that grep the text, and the skill itself when read by an agent. Nothing parses the "12" count.

- `test/gh578-ci-optimize-skill.sh` greps `### 1.` to `### 12.`, the P1-P12 titles, `show-ref`, `20–25 runs each`, the Wave 1 / Wave 4 / scorecard section markers and `20–24 Points`.
- `test/gh609-sdlc-agent-gaps.sh` (`check_ci_optimize_contract`) greps the exact headings `13. Bounded Flake Stress Loops and Active Quarantine Sinks` and `14. Workload-Scoped Performance and Resource Budget Fences` and several single-line phrases inside P13/P14. So the P13/P14 headings and bodies must stay byte-identical. Both suites are existing and are used unchanged.
- Open PRs touching the file: none (`prior_art_recon`). #1133 (necessity review, text-only, paused) is a different scope on the same file.
- Link targets exist in the Forge tree: `skills/1-hourly/sanity-check/` and `skills/4-occasional/ci-suite-audit/`.
- **The nine cited numbers span two repos (plan-QA r1 finding, adopted).** `GH-<n>` numbering spans XYZ-forge and its private, archived predecessor `Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm` (`ROUTER.md`, `docs/ROADMAP-UPSTREAM-ARCHIVE.md`). Existence is not identity, so each number was matched by subject to the principle it supports (titles read from both repos on 2026-11-27; recorded in `TESTS-RESULTS/2026-11-27+GH-1663/provenance.jsonl`):
  - XYZ-forge matches: #35 (3-tier test suite selection), #365 (test-suite recalibration: tiering, parallel equivalence), #558 (gh32-releases-app flaky section).
  - Predecessor matches (the same numbers in XYZ-forge are unrelated: #42 Commandcode adapter, #376 marathon umbrella, #528 /unstuck, #544 Luna/Needle research, #549 work-state stream, #564 work backfill): #42 (concurrent relay/marathon single-writer hazard), #376 (relay-drive and marathon-drive take different locks), #528 (measure and recalibrate the test suite), #544 (local-gate-before-push), #549 (pre-push gate silently skipped without `githooks/`), #564 (a suite rewrote the real clone's git remote).
  - The operator brief proposed labeling all nine as XYZ-forge numbers; the evidence contradicts that for six of them, so the plan splits them by repo (deviation, reported in the PR).

## Verified defects (each re-read at the base; line numbers drift)

| # | Defect | Evidence at base |
|---|---|---|
| 1 | Principle count: description says "12-point", heading says "12 Foundational Principles", but there are 14 principle headings; waves and scorecard cover P1-P12 only | `### 1.` to `### 14.` present; waves list P1,P6 / P5,P7 / P2,P3 / P4,P8-P12; scorecard rows 1-12 |
| 2 | `../../1-hourly/sanity-check/SKILL.md` resolves only in the Forge tree. `../ci-suite-audit/SKILL.md` also resolves in a flat install when `ci-suite-audit` is installed beside it (measured), but dangles when it is absent. The flat fallback sentence exists once (sanity-check, in a later paragraph of the same section); none for ci-suite-audit | link lines in "Related skill" and "Related Skills"; checker columns `resolves_in_*` |
| 3 | Bare `#35, #42/#376, ...` with no repo; and because numbering spans two repos, six of the nine are not XYZ-forge issues at all | provenance sentence at the top; subject matching in Recon |
| 4a | Extra, proven contradiction: the roadmap diagram's Wave 4 node reads "P4 Flakes, P8 Seams, P10-P12 Invariants" and omits P9, while the Wave 4 list below it names P9 | diagram vs list |
| 4b | Extra, proven wording: "Adopt these principles in 4 structured waves" is false for 14 principles once P13/P14 are named, because the waves cover P1-P12 | follows from defect 1 |

I looked for other wrong counts, dead anchors and cross-section contradictions (scorecard rows vs principle numbers 1-12, wave membership vs the union P1-P12, score bands 0-24 vs 12 rows x 2, the new-tests callout's principle numbers 7, 8, 10 and Wave 2, the anti-pattern principle numbers 1, 4, 5, 8, internal anchors). None found beyond 4a and 4b. The "Repos that forbid new tests (XYZ-forge ... GH-831)" callout is already repo-labeled and stays untouched.

## Preflight Bet Check

- **Outcome sought:** a reader of the portable skill gets a count that matches the rubric they score, links that resolve in both layouts, and provenance numbers that name their repo.
- **Smallest viable bet:** text edits in one file (below). **Not built:** new scorecard rows, a fifth wave, rescaled bands, a link checker, any test.
- **Alternatives rejected:** (z) label all nine numbers XYZ-forge (the brief's suggestion): contradicted by subject evidence for six; (a) add P13/P14 rows and a wave: changes the rubric's meaning and the A/B/C bands (max 24 becomes 28), out of scope and a design change; (b) say "12 principles" and delete P13/P14: removes content other suites pin (gh609); (c) a prose-only count fix with no marking: leaves P13/P14 unscored with no explanation.
- **Rollback / containment:** `git revert` of one docs commit; no runtime consumer.

## Requirements and per-file change (one ordered list, verification inline)

1. Frontmatter `description`: replace "Provides a structured 12-point audit rubric," with "Provides 14 principles (a 12-point scored audit rubric plus two situational extensions)," keeping the rest.
2. Provenance sentence: `(#35, #42/#376, #365, #528, #544, #558, #549, #564)` becomes `(XYZ-forge issues in [HiQS-Labs/XYZ-forge](https://github.com/HiQS-Labs/XYZ-forge): #35, #365, #558; issues in its predecessor repo [Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm): #42/#376, #528, #544, #549, #564)`. Each repo is named once.
3. Heading `## The 12 Foundational Principles` becomes `## The 14 Foundational Principles`, with one intro line directly under it: Principles 1-12 are scored in the scorecard and sequenced in the four waves; Principles 13-14 are situational extensions, applied when the situation arises, intentionally outside the 12-row scored rubric and the waves. The existing "Repos that forbid new tests" callout stays as is.
4. Roadmap: "Adopt these principles in 4 structured waves" becomes "Adopt Principles 1-12 in 4 structured waves"; the diagram's Wave 4 node gains P9 ("P4 Flakes, P8 Seams, P9 Hosted CI, P10-P12 Invariants").
5. One line under the scorecard table: P13 and P14 have no row; the 0-24 scale and the A/B/C bands score P1-P12 only. Bands unchanged.
6. Related Skills bullet for `ci-suite-audit`: append "In a flat installed collection, resolve `ci-suite-audit` by name." (same sentence shape as the existing sanity-check one). The relative links stay.
   - Verify (after 1-6): `TESTS-RESULTS/2026-11-27+GH-1663/check_ci_optimize.py` (a retained manual check, not a suite or gate). Contract, each assertion a separate key in its JSON output, with nonempty-extraction guards (at least one principle heading, one scorecard row, a nonempty provenance paragraph, a Wave 4 node and list, and at least two relative links; an empty extraction fails rather than passes):
     1. `heading_count_matches_headings`: the number in `## The N Foundational Principles` equals the count of `### n.` headings (14).
     2. `description_names_principle_count_and_rubric_rows`: the frontmatter says "14 principles" and its "N-point" equals the scorecard row count (12).
     3. `extension_intro_present`: the first nonempty line under that heading names P1-12 as scored and waved and P13-14 as situational extensions to apply when the situation arises, outside the rubric and waves.
     4. `scorecard_note_present`: a line inside the scorecard section, after the table, says P13 and P14 have no row and that the bands score P1-P12 only; and the band lines (`20–24`, `14–19`, `<14`) are byte-identical to base.
     5. `roadmap_sentence_scoped`: the "Adopt ... waves" sentence says Principles 1-12.
     6. `wave4_node_matches_wave4_list`: the set of principles in the diagram's Wave 4 node equals the set in the Wave 4 list (P4, P8-P12).
     7. `provenance_attributed_by_repo`: the provenance paragraph names both repos once, and the numbers before/after the predecessor label equal the subject-matched sets {35,365,558} and {42,376,528,544,549,564}.
     8. `every_relative_link_has_flat_fallback`: for each relative link, a sentence "In a flat installed collection, resolve `<skill>` by name." exists; plus per-link columns for resolution in the Forge-tree layout, a flat layout with siblings, and a flat layout with the sibling absent (reported, not asserted, because resolution there is the point of the fallback).
     9. `relative_links_valid_in_forge_tree`: every relative link resolves in a Forge-tree layout copy.
   - Red controls, run by the same script (`--red-controls`) on the candidate: for each of edits 1-6 it reverts that edit alone in a temp copy and requires the corresponding assertion(s) above to flip to false while the others stay true, and requires the script's exit status 1. Expected recorded results: base file exit 1 with assertions 1, 2, 3, 4, 5, 6, 7, 8 false and 9 true; candidate exit 0 with all true; each of the six mutants exit 1 with exactly its own assertion(s) false. The decisive output and exit statuses go in `provenance.jsonl` with the base and candidate file hashes.
   - Verify: existing `bash test/gh578-ci-optimize-skill.sh` and `bash test/gh609-sdlc-agent-gaps.sh` stay green (P13/P14 headings untouched).
   - Verify: `utils/pdda/pdda.sh run` zero errors, and the final gate route from the classifier on the committed diff.

## Acceptance

- [ ] Both counts agree: 14 principle headings, text says 14; scorecard rows and bands unchanged and described as P1-P12.
- [ ] Every relative link has a flat-install fallback sentence; relative links unchanged.
- [ ] Each cited issue number attributed to the repo whose issue matches its subject (XYZ-forge: 35, 365, 558; predecessor: 42, 376, 528, 544, 549, 564); each repo named once.
- [ ] Manual check recorded with `provenance.jsonl`; existing suites and docs route green; no new test or registry entry; one skill file changed.
- [ ] Observed rejection: the checker exits 1 on the unchanged base (assertions 1-8 false) and 0 on the candidate, and each single-edit revert exits 1 with its own assertion false (the red controls above), so an unfixed or partially fixed candidate cannot be reported as delivered. The two existing suites do not check these edits and are regression coverage only.

## Risks

Low. The two pinning suites are the only text consumers and the P13/P14 text is untouched. An agent reading "situational extension" must not read it as "optional to ignore": the wording says apply when the situation arises.

## PRS rating (read-back of the ledger row is authoritative)

- pri 30: no consequence in Forge today; the defects mislead a reader of a portable skill. Departure from severity-led ordering: none.
- sev 15: wrong count and unresolvable links in prose; no runtime effect, no data at risk.
- appeal 45: operator-supplied.
- effort 85: one text file, existing checks. Recurrence: unknown trend; one report (#1661), independently confirmed by Codex. Dated 2026-11-27.
