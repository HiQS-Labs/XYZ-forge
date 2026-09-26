---
gh_issue: 833
source: https://github.com/HiQS-Labs/XYZ-forge/issues/833
title: "docs: codify PRS — the Product Release System (the RELEASES ledger) — as the third part of the XYZ Forge / PDDA / PRS trinity"
status: Active — plan under review (2-WORKING)
created: 2026-09-26
updated: 2026-09-26
owner: operator (via /start-task)
doc_type: docs
branch: feat/gh833-prs-docs
non_goals:
  - Renaming code, files, tables, CLI verbs or the RELEASES-* docs.
  - Any new check or suite (AGENTS.md, No new tests).
  - Any file the tier router treats as non-docs; this landing must qualify through the hosted Small run.
  - Generated views (LEADERBOARD.md, PAGES/*), historical plans, CHANGELOG history and ledger row titles that already say "PRS".
related:
  - "#831 — the three-tier gate; Phase 3 is the first hosted Small run"
  - "#836 — step 6 is the same run"
goal: >
  An agent that meets "PRS" finds one canonical definition, and every canonical doc that discusses the
  ledger spells it out where it introduces the ledger. The merge is docs-only, so it is the first landing
  the hosted reconcile qualifies with the Small gate.
---

# GH-833 — define PRS, the Product Release System

## Status

| What was just completed | What's next |
|---|---|
| Intake (`7ee0ec0d`), recon and this plan. | Codex plan review. Then the edits, the witnesses and final QA. |

## Contents

- [Rating](#rating--2026-09-26-55205085-prisevappealeffort)
- [Recon](#recon)
- [Plan](#plan)
- [Verification](#verification)
- [Merge and the hosted Small run](#merge-and-the-hosted-small-run)
- [Risk and rollback](#risk-and-rollback)

## Rating — 2026-09-26: `55/20/50/85` (pri/sev/appeal/effort)

- **Severity 20.** No crash, data loss or blocked work. An agent that meets "PRS ratings" or "the PDDA, PRS and
  canary suites" (`ROUTER.md:119`) has to guess the term.
- **Priority 55.** Above what severity alone supports, because the operator scheduled it now, on 2026-09-26. It
  is the docs-only landing that the hosted Small run needs for #831 Phase 3 and #836 step 6.
- **Appeal 50.** Neutral; the operator gave no score.
- **Effort 85.** A docs-only change to eight docs and six skills. No code.
- **Recurrence:** PRS is used undefined in #443, #522, #645, #698 and #777, plus `LEADERBOARD.md` titles and
  three skills. These are uses of the term, not incidents; the incident trend is unknown.

## Recon

Base: `af4fef27` (origin/development, #838's merge).

**R1 — current use.** `git grep -w PRS` finds the term in exactly one canonical doc, `ROUTER.md:119` (the
Small tier's definition, from #831). "Product Release System" appears nowhere. Outside the canonical docs, PRS
appears undefined in three skills: `start-marathon` (line 239), `10days` (frontmatter line 6 and 13 more) and
`end-of-week` (line 32, inside its recite block). It also appears in `merge-cleanup/scripts/ledger_merge.py`,
which is code and out of scope.

**R2 — where each canonical doc introduces the ledger.** The spelled-out form goes where each doc describes
the RELEASES ledger, not necessarily at its first passing mention of "ledger":

| Doc | Placement | Why there |
|---|---|---|
| `HOW-TO-USE.md` | line 7, "The **releases DB is the commitment ledger**", and a new glossary entry (line 67) | line 7 names the DB before the glossary does; the glossary entry is the one canonical definition |
| `ROUTER.md` | a new trinity line after the intro (line 3) | the issue asks for it near the top; it must precede line 119 |
| `AGENTS.md` | line 173, "The RELEASES DB is two subsystems behind one CLI" | the paragraph that describes the ledger; line 157 is a passing mention |
| `PROJECT/PDDA.md` | line 948, the roadmap ledger contract ("in `releases.db` in releases-mode repos") | PDDA.md's only mention of the DB; its `RELEASES.md` sections (596, 658) describe the retired file |
| `SOP.md` | line 62, "Park the ledger row **in the RELEASES DB**" | first mention by name |
| `ARCHITECTURE.md` | line 406, "The GH-32 RELEASES ledger has its own authority split" | the prose description. Line 80 is a skills-catalog row, which `gh778`/`gh798` read, so it is left alone |
| `RELEASES-DB-FAQS.md` | a sentence under the title (line 1) | the ledger's own doc |
| `README.md` | line 145, the "**Release ledger**" row of the feature table | first mention by name; line 38's "internal ledger" is about version tags |

**R3 — skills.** The issue names `/releases`, `/start-task` (its rating policy) and `merge-cleanup`; the three
skills in R1 already use the bare term. Each gets the spelled-out form at its first use of PRS, or where it
introduces the ledger if it has no PRS:

| Skill | Placement |
|---|---|
| `skills/2-daily/releases/SKILL.md` | line 8, "Treat the release ledger" |
| `skills/1-hourly/start-task/SKILL.md` | the rating policy's first line, "using the existing XYZ RELEASES vocabulary and writer". The recite block and frontmatter are left alone |
| `skills/2-daily/merge-cleanup/SKILL.md` | line 8, "PDDA & RELEASES DB reconciliations" |
| `skills/2-daily/start-marathon/SKILL.md` | line 239, "the fuller PRS freshness gate" |
| `skills/3-weekly/10days/SKILL.md` | line 6 (frontmatter description), "evaluate PRS 4-axis ratings"; it is the first use |
| `skills/3-weekly/end-of-week/SKILL.md` | line 32, "RELEASES SQLite (PRS)", in its recite block; it is the only use |

**R4 — the tier router.** `utils/ci-route.sh` `is_docs_surface()` counts `*.md`, `PROJECT/*`, `TESTS-RESULTS/*`,
`relay-system/*` and `releases.db`/`releases.sql` as docs. Two exceptions matter:
- `relay-automation/*` and `skills/*/relay-xyz/*` force the full gate even for markdown, through `full_required`.
- The non-markdown files of the core skills (`relay`, `relay-xyz`, `relay-automation`, `merge-cleanup`,
  `express`, `jog`) are not docs.

Every file this plan touches is markdown or the ledger dump, and none is under those paths.
`merge-cleanup/SKILL.md` is markdown, so it stays docs by rule 1.

**R5 — how the reconcile picks the gate.** `wave_reconcile.py` `select_qualification_gate()` (line 589):
- It pipes the union of the pending landings' `git diff --name-only <merge>^ <merge>` through
  `utils/ci-route.sh push`.
- It runs Small only if the result is `tier=1`.
- The union covers every merged PR the run picks up, so #833 must be the only landing in its reconcile.

**R6 — suites that read these files.**
- `releases-skill.sh` reads `/releases`, `gh400-source-url.sh` reads `10days`, and `gh436-merge-cleanup.sh`
  reads merge-cleanup's SKILL.md. All three are in Small.
- `gh609-sdlc-agent-gaps.sh` reads start-task's SKILL.md. It is registered, but not in Small.
- `gh615` and `gh616` also read start-task, but are off the registry since #834.
- `gh778` and `gh798` read `ARCHITECTURE.md`'s skill table, which this plan does not touch.

## Plan

The canonical definition lives in one place: `HOW-TO-USE.md`'s glossary. Every other doc spells the term out
once and points there or to `RELEASES-DB-FAQS.md` (PDDA Principle #4).

1. **`HOW-TO-USE.md`.**
   - Retitle the glossary "the five terms you'll hit first". No link targets its anchor
     (`git grep four-terms` finds none).
   - Add the entry: **PRS**, the Product Release System, is the RELEASES ledger. It is `releases.db` with its
     git-mergeable dump `releases.sql`, written only through `utils/py/releases_app.py`. It holds the roadmap
     rows, their `rated pri/sev/appeal/effort` ranking, release manifests and ship evidence. PRS names the
     system; the files, tables, CLI verbs and `RELEASES-*` docs keep their names. The entry names the trinity,
     each part with its entry doc: XYZ Forge, the harness (`ROUTER.md`, `AGENTS.md`); PDDA, project-doc
     governance (`PROJECT/PDDA.md`); and PRS (`RELEASES-DB-FAQS.md`).
   - At line 7, "The **releases DB** — the Product Release System (PRS) — **is the commitment ledger**". The
     paragraph's "two core systems" framing (ledger vs. marathon engine) is a different axis and stays.
2. **`ROUTER.md`:** one line after the intro naming the trinity. PRS is spelled out, and the line links the
   glossary entry.
3. **The other six canonical docs:** the spelled-out form at the R2 placement, as a parenthetical or
   appositive, with no restated definition.
   - `PROJECT/PDDA.md`'s wording has to stand for other repos that adopt the PDDA contract: "in `releases.db` in
     releases-mode repos (the RELEASES ledger, which XYZ Forge calls the Product Release System, PRS)".
4. **The six skills:** the spelled-out form at the R3 placement.
5. **`CHANGELOG.md`:** one top entry.
6. **Witnesses:** see Verification.

The edits add words and remove none, so no existing assertion's anchor text changes.

## Verification

No new suite or registry entry (AGENTS.md, *No new tests*). Manual checks go to
`TESTS-RESULTS/2026-09-26+GH-833/` with `provenance.jsonl`.

- **V1, the definition-order check.** For each of the eight canonical docs and six skills, the first line
  matching `\bPRS\b` must also contain "Product Release System". Every file must have at least one match.
  Script: `prs-order-check.sh.txt`.
  - Red control, at base: the same check fails on all 14 files, 13 with no match and `ROUTER.md` on line 119.
  - A second red control: remove the new ROUTER line in a scratch copy, and ROUTER fails again.
- **V2, tier 1.** `git diff --no-renames --name-only origin/development...HEAD | bash utils/ci-route.sh push`
  prints `tier=1`, the input `select_qualification_gate()` uses.
  - Red control: the same pipe with `relay-automation/README.md` appended prints `tier=3`.
- **V3, the suites that read the edited skills:** `releases-skill.sh`, `gh400-source-url.sh`,
  `gh436-merge-cleanup.sh` and `gh609-sdlc-agent-gaps.sh`, run one at a time and all green.
- **V4:** `utils/pdda/pdda.sh run` reports 0 errors.
- **V5, the push gate:** a docs-only push takes the tier-1 docs gate, which is the qualifying local gate for
  this tier. The full registry is not run locally; the hosted Small run is this landing's qualification.

## Merge and the hosted Small run

- **Merge after #838's reconcile finishes** (run 36271811800), and when no other PR is merging, so #833 is the
  only landing in its reconcile (R5).
- **After merge,** the reconcile should log `validate.sh --sequential --subsystem small` and write a
  `tier: 2` receipt with the Small list.
- **Record** the run's ID, duration and suite count here and in `GH-831-THREE-TIER-GATE.md` and
  `GH-836-GATE-HOTSPOTS.md`, in a follow-up. That closes #831 Phase 3 and #836 step 6.
- **If the run takes the full gate instead,** that is a finding against #831's routing, reported with the log.
  It does not fail this issue.

## Risk and rollback

- **Risk:** a wording change breaks a skill-text assertion. V3 runs every registered suite that reads an
  edited skill; `gh615`/`gh616` are off the registry.
- **Risk:** the ledger dump conflicts with #838's reconcile commit. Rebase before push; resolve with
  `utils/releases-merge-resolve.sh` if needed.
- **Rollback:** revert the commit. There is no state to migrate. Deployed skills pick up the text on the
  operator's next skills-army-hq deploy.
