---
gh_issue: 833
source: https://github.com/HiQS-Labs/XYZ-forge/issues/833
title: "docs: codify PRS — the Product Release System (the RELEASES ledger) — as the third part of the XYZ Forge / PDDA / PRS trinity"
status: Active — merged; Small run recorded (2-WORKING)
created: 2026-09-26
updated: 2026-09-26
owner: operator (via /start-task)
doc_type: docs
branch: feat/gh833-prs-docs
non_goals:
  - Renaming code, files, tables, CLI verbs or the RELEASES-* docs.
  - No new automated suite or registry entry (AGENTS.md, No new tests). Manual checks under TESTS-RESULTS/ are allowed. (Wording corrected by GH-844.)
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
| Merged in PR #840 (`9fd2d885`). Its reconcile, [36276061201](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36276061201), is the first hosted Small run: tier 1, `validate.sh --sequential --subsystem small`, 76/76, 15.7 minutes, `tier: 2` receipt. CodeRabbit's post-merge findings are in umbrella #845. #844 (this evidence's check scope and recipe status) is fixed in the follow-up PR. | Close #833. Deployed skills pick up the text on the operator's next skills-army-hq deploy. |

## Contents

- [Rating](#rating--2026-09-26-55205085-prisevappealeffort)
- [Recon](#recon)
- [Plan](#plan)
- [Verification](#verification)
- [Results](#results)
- [Found in review, deferred](#found-in-review-deferred-not-in-this-pr)
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
- The union covers every merged PR the run picks up. Another docs-only landing in the same run would still
  be tier 1, so merging #833 alone is a scheduling choice for a clean attribution of the first Small run, not
  something the classifier needs.

**R6 — suites that read these files.**
- `releases-skill.sh` reads `/releases`' SKILL.md, and is in Small.
- `gh436-merge-cleanup.sh` reads the real merge-cleanup SKILL.md, and is in Small.
  - `test/gh436-merge-cleanup.py:863-865` imports `gh534_phase_c_tests` with `import *`, and that module loads
    `SKILL_MD` (`test/gh534_phase_c_tests.py:523`) for the capability-table parity guard and the drive-loop
    check (`:870`).
  - The SKILL.md paths in `gh436-merge-cleanup.py` itself are symlink fixtures (Codex r1 F2).
- `gh609-sdlc-agent-gaps.sh` reads start-task's SKILL.md (`:33`). It is registered, but not in Small.
- No registered suite reads the edited text of `10days`, `start-marathon` or `end-of-week`.
  - `gh400-source-url.sh` mentions `10days` only in a comment (`:5`); it tests `swarm_preflight.py` (Codex r1 F2).
  - Those three edits are checked by V1 and by reading the diff.
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
   appositive, with no restated definition. Its paragraph links the glossary heading or `RELEASES-DB-FAQS.md`,
   and `RELEASES-DB-FAQS.md` links the glossary. `HOW-TO-USE.md` line 7 links its own glossary heading.
   - `PROJECT/PDDA.md`'s wording has to stand for other repos that adopt the PDDA contract: "in `releases.db` in
     releases-mode repos (the RELEASES ledger, which XYZ Forge calls the Product Release System, PRS)".
   - `PROJECT/PDDA.md` is read in other repos, where a relative path differs. Its placement links the glossary
     by absolute URL, `https://github.com/HiQS-Labs/XYZ-forge/blob/development/HOW-TO-USE.md#glossary--the-five-terms-youll-hit-first`.
4. **The six skills:** the spelled-out form at the R3 placement, and the same absolute URL, since skills are
   deployed outside the repo and a relative link breaks there.
   - Absolute GitHub URLs are the existing practice for this; `relay-xyz`'s SKILL.md links
     `relay-automation/` that way.
   - Where the first use is in frontmatter (`10days` line 6) or a recite block (`end-of-week` line 32), the
     URL goes in the nearest prose after it: `10days`' first body paragraph, and one line after
     `end-of-week`'s recite block.
   - The URL resolves once this merges, because the heading exists only on this branch until then.
5. **`CHANGELOG.md`:** one top entry.
6. **Witnesses:** see Verification.

The edits add words and remove none, so no existing assertion's anchor text changes.

## Verification

No new suite or registry entry (AGENTS.md, *No new tests*). Manual checks go to
`TESTS-RESULTS/2026-09-26+GH-833/` with `provenance.jsonl`.

- **V1, the definition-order check.** For each of the eight canonical docs and six skills, the first line
  matching `\bPRS\b` must also contain "Product Release System". Every file must have at least one match.
  Script: `prs-order-check.sh.txt`.
  - Red control, at base (run 2026-09-26 against `af4fef27`): 0/14 pass. Ten files have no PRS. Four have a bare
    PRS first: `ROUTER.md:119`, `start-marathon:239`, `10days:6` and `end-of-week:32`.
  - A second red control: remove the new ROUTER line in a scratch copy, and ROUTER fails again.
- **V1b, the one definition and its links** (Codex r1 F1). Script: `prs-definition-check.py.txt`.
  - `HOW-TO-USE.md`'s glossary has exactly one `- **PRS**` entry. It spells out "Product Release System" and
    names XYZ Forge and PDDA. No other checked file has such an entry.
  - In each of the seven linked docs (`HOW-TO-USE.md`, `ROUTER.md`, `AGENTS.md`, `SOP.md`, `ARCHITECTURE.md`,
    `RELEASES-DB-FAQS.md`, `README.md`), the paragraph that spells out the term links either the glossary or
    `RELEASES-DB-FAQS.md`.
    - A glossary link's anchor must equal GitHub's slug of the real heading.
    - The linked file must exist.
  - `PROJECT/PDDA.md` and the six skills must each contain the absolute glossary URL, with the anchor equal to
    the slug of the real heading (Codex r2).
  - Red control, at base: 15 failures: no entry, no spelled-out paragraph in any of the seven linked docs, and no
    absolute pointer in any of the seven others.
  - Red controls after the edits, each in a scratch copy:
    - delete the glossary entry, and the check fails;
    - change ROUTER's anchor, and the check fails;
    - add a second `- **PRS**` entry to `RELEASES-DB-FAQS.md`, and the check fails;
    - change one skill's URL anchor, and the check fails.
- **V2, tier 1.** `git diff --no-renames --name-only origin/development...HEAD | bash utils/ci-route.sh push`
  prints `tier=1`, the input `select_qualification_gate()` uses.
  - Red control: the same pipe with `relay-automation/README.md` appended prints `tier=3`.
- **V3, the registered suites that read an edited skill** (R6): `releases-skill.sh`, `gh436-merge-cleanup.sh`
  and `gh609-sdlc-agent-gaps.sh`. They run one at a time, in a separate disposable full clone at the final
  commit, and must all be green.
- **V4:** `utils/pdda/pdda.sh run` reports 0 errors.
- **V5, the push gate:** the push takes the pre-push hook's tier-1 docs gate. That is a local push
  self-check, not qualification. The landing is qualified only by the hosted Small run after merge.

## Results

The edits are at `58256426`. The base red controls ran against `af4fef27`. Everything is recorded in
`TESTS-RESULTS/2026-09-26+GH-833/`, with one `provenance.jsonl` record per run.

| Witness | Result | Evidence |
|---|---|---|
| V1, definition order | 14/14 pass. At base: 0/14 | `witnesses.log`, `red-controls-base.log` |
| V1 red control | ROUTER's trinity line removed: ROUTER fails, rc 1 | `witnesses.log` |
| V1b, one definition and its links | pass. At base: 15 failures | `witnesses.log`, `red-controls-base.log` |
| V1b red controls | all four fail with rc 1: entry deleted; ROUTER anchor broken; entry restated in the FAQ; a skill URL anchor broken | `witnesses.log` |
| V2, tier | `route=docs tier=1 docs-only` on the committed diff; with `relay-automation/README.md` appended, `tier=3` | `v2-v4.log` |
| V3, reader suites | `releases-skill` 40/0, `gh609` 33/0, `gh436` 180 tests OK (243 s), in a disposable clone. HEAD and porcelain were unchanged across the run. The other `AGENTS.md:370` identity fields were not retained before it; they were checked after it (clean) | `v3-reader-suites.log`, `v3-identity-and-pdda-baseline.log` |
| V4, PDDA | no errors. Warnings compared in the disposable clone, base `af4fef27` vs `cd777ca7`: no new content warning. See the note below | `v2-v4.log`, `v3-identity-and-pdda-baseline.log` |
| V5, push self-check | the pre-push hook took the documentation gate: GREEN in 59 s at `24ad92cc` (rebased onto `f098ab43`) | `push-gate-24ad92cc.log` |

Notes against the plan:
- **V4 warnings (final QA r1 F1).** The base-vs-head diff shows two changes:
  - `ROUTER.md`'s three existing "dead reference RELEASES.md" warnings moved from lines 13/190/206 to 15/192/208,
    under the new trinity line.
  - Two "#833 state unavailable" warnings appear because the fresh clone has no cached `gh` state for the new
    row.

  The disposable clone reports 357/359 warnings; the task clone, with its cache, reports 32.
- **The witness recipe (final QA r1 F2).** The first run's recipe (`witness-script-r0.sh.txt`, output
  `witnesses-r0.log`) deleted a caller-supplied scratch path. The revised recipe (`witness-script.sh.txt`)
  copies into a new `mktemp -d` directory per control and deletes nothing. Its re-run (`witnesses.log`) gives the
  same results.
- **`PROJECT/PDDA.md`.** Plan step 3 proposed a parenthetical inside the releases-mode clause. The edit keeps
  the original sentence whole and adds a second one ("In releases-mode repos it is part of the RELEASES
  ledger, which XYZ Forge calls the Product Release System (PRS; definition)").
- **`/releases`.** The spelled-out form is a new first sentence at line 8, just before "Treat the release
  ledger", not inside it.
- **Wording.** No original word is removed, except "four" → "five" in the glossary heading.
  - `AGENTS.md:173` keeps its bold and its colon, and adds "it is the Product Release System, PRS" inside
    the parenthesis.
  - start-task keeps "the existing XYZ RELEASES vocabulary and writer", and adds a parenthesis.
  - No test, tool or workflow anchors on any rewritten phrase (`git grep` of each over `test`, `utils`,
    `validate.sh` and `.github`).
- **An observation, not changed.** `10days`' frontmatter description was already 1,546 characters, above the
  usual 1,024. The spelled-out form adds 25. No repo validator checks the length.

## Found in review, deferred (not in this PR)

Final QA r1 found three existing instruction problems in two skills this PR touches. This PR only adds names
and pointers (DoD (d)), so they are left for a follow-up issue, which is the operator's call. Each is confirmed:
- **`skills/2-daily/releases/SKILL.md:28-31`** calls `ROADMAP.md` the human file and says to finish with
  `releases roadmap sync`. In releases mode (this repo) the DB is the source of truth, and sync is a no-op.
- **`skills/3-weekly/10days/SKILL.md:208,233`** call `releases_app.py roadmap show <N>`. `roadmap` has no `show`
  subcommand; the CLI refuses it, listing sections, sync, reconcile-state, list, render, add, rate, repoint,
  update and move.
- **`skills/3-weekly/10days/SKILL.md:500-501`** falls back to `git worktree remove --force` when the worktree
  still reports uncommitted state. That can discard work.

## Merge and the hosted Small run

- **Merge after #838's reconcile finishes** (run 36271811800). Merge it when no other PR is landing, so the
  first Small run is attributable to one docs-only landing (R5; a scheduling choice).
- **After merge,** the reconcile should log `validate.sh --sequential --subsystem small` and write a
  `tier: 2` receipt with the Small list.
- **Record** the run's ID, duration and suite count here and in `GH-831-THREE-TIER-GATE.md` and
  `GH-836-GATE-HOTSPOTS.md`, in a follow-up. That closes #831 Phase 3 and #836 step 6.
- **If the run takes the full gate instead,** that is a finding against #831's routing, reported with the log.
  It does not fail this issue.

## Risk and rollback

- **Risk:** a wording change breaks a skill-text assertion. V3 runs every registered suite that reads an
  edited skill; `gh615`/`gh616` are off the registry. The three skills no suite reads are checked by V1 and by
  reading the diff.
- **Risk:** the ledger dump conflicts with #838's reconcile commit. Rebase before push; resolve with
  `utils/releases-merge-resolve.sh` if needed.
- **Rollback:** revert the commit. There is no state to migrate. Deployed skills pick up the text on the
  operator's next skills-army-hq deploy.

## Merge evidence

- PR #840 merged 2026-09-26 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
