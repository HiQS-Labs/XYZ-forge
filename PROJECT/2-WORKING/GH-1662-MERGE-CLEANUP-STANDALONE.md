---
title: "merge-cleanup: an explicit standalone mode, a git+gh-only merge sequence for large queues, and a prose runbook for an agent when the scripts cannot run"
status: Active
created: 2026-11-27
updated: 2026-11-27
owner: Noel Saw
gh_issue: 1662
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1662
doc_type: feature
reported_from: XYZ-forge
harness_commit: 52813e56f
non_goals:
  - modifying `utils/py/wave_reconcile.py` or any other overlay file (standalone mode does not run them; SKILL.md documents the development-only overlay requirement of the default mode)
  - touching `skills/4-occasional/ci-optimize/` (another PR owns it) or closing umbrella #1661
  - inferring standalone mode from any missing file (GH-1576 stands); a missing installer without the explicit declaration still refuses
  - a policy key in `.merge-cleanup.json` (see Decision D1)
  - a new test, test suite, gate entry or runner (GH-831); verification is the existing merge-cleanup suites plus a recorded manual check
  - changing any Forge-mode default (scan roots, gates, reconcile, record paths)
  - automatic ledger/changelog repair (B1) in a repository without the ledger
related:
  - 1661
  - 1576
  - 1226
  - 1452
  - 1470
  - 1066
  - 831
goal: "On a repository with no XYZ-forge overlay, `merge_cleanup.py --standalone` sequences a large PR queue, forecasts its landings and lands it using only git and gh; when no script can run, STANDALONE.md lets an agent do the same by hand; Forge mode is unchanged."
---

# GH-1662: merge-cleanup outside the harness overlay

## Status

| What was just completed | What's next |
|---|---|
| Recon at base `52813e56f` on a 17-PR foreign-repo fixture (measured below); plan drafted. | Codex plan QA, then implementation, verification, final QA, ready PR. Merge is the operator's. |

## Contract (binding: the "Contract decision" comment on #1661)

Priority order: (1) the merge sequence works with only `git` and `gh`; (2) landing works in an **explicit** standalone mode; (3) a prose runbook for an agent when the scripts cannot run. Forge mode is unchanged and its requirements are documented.

## Observed (measured at base `52813e56f`; fixture and stand-in `gh` under `TESTS-RESULTS/2026-11-27+GH-1662/fixture/`)

Fixture: a bare origin and a primary clone of a small repo ("acme/widgets", integration branch `main`) with **no Forge files**, 17 open PRs: a declared dependency (#106 depends on #109), a stacked PR (#107, base = #106's branch), file collisions on `src/core.py` (#102, #103, #105), a conflict hub (#105), a PR that conflicts with the base alone (#115), a draft (#108), failing checks (#110, with a dependent #116), a held PR (#114), a dependency cycle (#111 <-> #112, with a dependent #113), and a second PR editing `CHANGELOG.md` (#117, collides with #109). A fresh `HOME`, so no default scan root is reachable. The stand-in `gh` computes `files` and `mergeable` from real git and squash-merges into the bare origin; it cannot exercise GitHub's real checks, protection or rate limits.

| # | Probe | Observed at base |
|---|---|---|
| M1 | `--prs-only` (system Python 3.9.6) | rc 0. Needs no clone, no Forge file. All open PRs are in the table (none dropped). The cycle is named in "Ordering Notes". |
| M2 | dry run with `--prs` (15 PRs) | The Landing forecast **runs with no Forge files** (`git merge-tree`): hubs, clean set, fold, recommendation `group`. Then Phase 5 stops: rc 2, `landing clone gate wiring failed: githooks/install.sh is missing ... (GH-1576)` (T3). |
| M3 | the order, M1/M2 | **#107 (stacked on #106) is sequenced at 6, before its base #106 at 8** (because #106 waits for #109). `toposort_prs.py` never reads `baseRefName`. Landing in that order stops at #107: `targets 'feat/faq', not 'main'` (`merge_cleanup.py:2109-2111`), rc 2, mid-queue. A sequencing defect, not specific to standalone. |
| M4 | the forecast labels | `ledger_repair_paths()` defaults to `{releases.sql, releases.db, LEADERBOARD.*, CHANGELOG.md}`; in a repo without B1 a conflict on `CHANGELOG.md` would read "potentially B1-eligible" and "PRs needing a B1 repair: N", advice nothing can act on. |
| M5 | T4: `.tick/` | `selection-*.json` is written under `<primary>/.tick/merge-cleanup/` (`attempt_record.py:49-51`); `inspect_primary_landing` reads `git status --porcelain`, so the next run is NOT READY, and `commit_and_push_phase5_writes` would `git add -A` the pin file into the integration push. |
| M6 | scan roots | `default_scan_roots` = four fixed original-operator roots, not origin-filtered (`scan_clones.py:26-31`, `:71-83`). |

## Existing criteria (extracted, not invented)

- **Hard edges** (`toposort_prs.py:55-75`): `depends on|blocked by|after|requires|prerequisite[:] #N` or a PR URL, and `part of wave after #N`, to an **open** PR. A hard dependent is "NOT attempted" if its predecessor did not land (`merge_cleanup.py:2068-2079`).
- **Soft edges** (`:95-130`): two PRs touching a common file are ordered older `createdAt` first, unless that closes a cycle (then a warning). They order; they never block (GH-623).
- **Order**: Kahn, ready PRs by ascending number; a cycle is appended in numeric order with a warning, and its hard members are then each "NOT attempted".
- **Skips, reported**: draft (`:2093`), hold label/title token (`hold_label`, #444), required checks failing/pending/unreadable (`:2319-2343`, dry run reports only), mergeable not `MERGEABLE|CONFLICTING` (stop), `--prs` pins (GH-1226).
- **Forecast** (GH-1452/1470, `ledger_merge.landing_forecast`): each PR alone vs a frozen base, each pair, a cumulative fold stopping at the first conflict; hubs named by base conflict then greedy conflict degree; `direct in passes` when at least 3 conflict, the clean set folds clean, and the second pass is at most half; `group` on needs-review paths or an unclean clean-set fold; withheld when any step is unknown. Needs git >= 2.38.

## Decisions

- **D1. Declaration shape: a CLI flag `--standalone`, no policy key.** It is per run and visible on the command line, so a reviewer of a transcript or an agent's plan sees it; a committed `.merge-cleanup.json` key is persistent and could be committed into a Forge repo to turn its ledger gate off, and it changes the policy schema that older drivers refuse. Rejected: infer from absent files (GH-1576); policy key (above); a separate skill (second subsystem). Reversible: delete the flag.
- **D2. The declaration is guarded.** `--standalone` is refused (rc 2, naming the files) when the primary carries overlay markers (`releases.sql`, `releases.db`, `utils/py/releases_app.py`, `.xyz/utils/py/releases_app.py`, `utils/py/wave_reconcile.py`): skipping a ledger gate where a ledger exists would land PRs the ledger never saw. A partial overlay uses the default mode. It is also refused with `--reconcile-pr` and `--retire-published-pr`.
- **D3. What standalone skips, and only that:** the gate-wiring refusal when `githooks/install.sh` is absent (T3); the pre-merge ledger gate and semantic read (T5); post-merge `wave_reconcile`, `releases_app check`, `pdda.sh` and Jog (T5/T7); B1. A conflicting landing **hands off** (named paths, queue continues, exit 3): B1 is a Forge-ledger repair whose changelog union and ledger replay do not apply to a foreign repo. With an installer present, wiring runs as today.
- **D4. Pushes stay gated.** `gate_unwired_reason`, `push_resolved_head` and `commit_and_push_phase5_writes` are untouched, so any push from a clone or the primary without a proven gate hook is still refused; never `--no-verify`. Standalone makes no push on a clean queue.
- **D5. T4: `.tick/` is excluded in the primary's own `.git/info/exclude`** (`/.tick/`, only when `git check-ignore` says it is not already ignored, and only under `--standalone` when something will be written). Local, untracked, reversible by deleting one line; where `.tick/` is already ignored (Forge) nothing is written. Rejected: relocating records under `.git/` (changes the record contract the repair rungs and tests pin); editing the repo's tracked `.gitignore`; telling the operator to do it (the failure reads as an unrelated NOT READY).
- **D6. Scan roots:** under `--standalone` and no `--root`, only the primary's parent folder is scanned, origin-filtered (the existing GH-722 sibling filter), and the four fixed roots are not scanned. An explicit `--root` is the operator's choice, as in Forge mode. `--prefix` is documented.
- **D7. Prerequisites block, printed before Phase 0** (so before any clone): Python >= 3.9, git >= 2.38, gh >= 2.18 and runnable, an `origin` remote, `lsof`, and the gate-hook status (informational: standalone makes no push). Each unmet item is named; `--execute` refuses (rc 2) on an unmet hard one (Python, gh, origin).
- **D8. Forecast under `--standalone`:** `ledger_repair_paths` is empty, so every conflicting path is "needs review", the B1 line reads as a hand-off count, and one blind-spot line says so (fixes M4).
- **D9. Stacked bases are hard edges** in `toposort_prs.py` (fixes M3): a PR whose `baseRefName` is another open PR's `headRefName` waits for it, and is "NOT attempted" if it did not land. No warning line is added, so the output of every queue without an inverted stack is unchanged; the Base column already shows the stack. This is the one shared-code change that can alter a Forge-mode order, and only where the old order stopped the run.

## Smallest affected surface and the writers extended

- `merge_cleanup.py`: `--standalone`; three small helpers (`standalone_overlay_found`, `standalone_prerequisites`, `ensure_tick_ignored`); `prepare_landing_clone(..., standalone=False)`; in `_land_prs_loop` four `if standalone` branches (handoff before B1, ledger gate, post-merge reconcile, the clone call kwargs). Every Forge-mode call keeps its exact arguments (the suites stub `prepare_landing_clone` with a four-positional lambda and assert on `run_post_merge_reconcile`).
- `scan_clones.py`: `standalone_scan_roots` beside `default_scan_roots`.
- `ledger_merge.py`: `landing_forecast(..., standalone=False)`.
- `toposort_prs.py`: the stacked hard edge.
- `SKILL.md`: a compact "Standalone mode" section, prerequisites by mode, the stacked rule, link. New `STANDALONE.md`: the runbook.
- No change: attempt records, gates, batch records, `execute_pr_merge`, teardown.

## Ordered implementation, verification inline

1. Edit the four scripts as above. -> `python3 -m py_compile` under 3.9.6 and the 3.13 test venv; `git diff` shows the Forge-mode call sites unchanged.
2. Run the fixture (system 3.9.6, then venv 3.13): `--prs-only`; dry run with and without `--standalone`; a standalone `--execute` of a subset in dependency order; T4 twice; prerequisites with a version-faking `git`/`gh` shim. -> see Acceptance.
3. Write `STANDALONE.md` from the extracted criteria; SKILL.md edits (the capability table is untouched; the parity guard reads it).
4. Run the existing suites in a disposable full clone, test venv first on PATH: `gh436` (collects phase A/B/C), `gh534_phase_b/c` standalone, `gh645`, `gh674`. -> green.
5. Record the manual check and `provenance.jsonl`; final Codex QA; qualification from a disposable clone; push; ready PR.

## Acceptance and red controls (no new tests: GH-831)

| ID | Check | An unchanged or wrong candidate fails because | Expected |
|---|---|---|---|
| A1 | Base vs candidate, no flag, fixture without installer, dry run `--prs` | the guard must not be loosened | rc 2 with the GH-1576 refusal at both, output equal after path normalisation (**Forge regression**) |
| A2 | Candidate `--standalone`, same fixture | T3 still blocks | rc 0, per-PR dry run lines, forecast, `[DRY RUN] Would merge` for landable PRs |
| A3 | Mutant: the `standalone and` guard on the wiring skip removed (skip whenever the installer is missing) | the declaration would be inferred | A1's no-flag row turns rc 0 -> the row FAILS (control detects it) |
| A4 | Same fixture with `--with-installer`, no flag | Forge mode must still wire and then run the ledger gate | same refusal at the ledger gate at base and candidate (Forge mode unchanged) |
| A5 | Standalone `--execute` of a dependency-ordered subset, stand-in `gh` | gate, reconcile or ff steps still need the overlay | merged, primary equals origin, clean, no `.tick` in `git status`, no push attempted |
| A6 | T4: two consecutive standalone runs; mutant without `ensure_tick_ignored` | the second run reads NOT READY | candidate READY twice; mutant NOT READY on run 2 |
| A7 | Stacked order: base places #107 before #106; candidate after. Mutant (edge removed) + `--execute` | the loop stops at the child | candidate lands #106 then #107; mutant stops rc 2 `targets 'feat/faq'` |
| A8 | Prerequisites: `git` 2.30 and `gh` 2.4 shims; no origin | a dry run clones first and fails later | UNMET lines printed before the first `git clone` of the run |
| A9 | Scan roots: a clean other-origin clone under `$HOME/marathon-clones` | standalone widens teardown | Forge mode lists it; standalone does not |
| A10 | Overlay guard: fixture with `releases.sql` | the flag bypasses an existing ledger | `--standalone` refused rc 2 naming the file |
| A11 | Forecast labelling: a CHANGELOG.md conflict pair | M4 | Forge: "potentially B1-eligible"; standalone: "needs review", hand-off wording |
| A12 | Pushes stay gated: call `gate_unwired_reason` and `commit_and_push_phase5_writes` on the foreign primary with a dirty file | a push slips through | both refuse with the GH-1576 text |
| A13 | Existing suites (step 4) | regressions | green |
| A14 | Python: A2 under 3.9.6 and 3.13; `py_compile` both | a 3.10+ construct | identical results |

## Smoke (GH-1088)

Main path: A2/A5 (dry run then `--execute`). Adjacent path: the same command run a second time (A6), and `--scan-only`/`--prs-only`, which a resumed operator would run.

## Risks and rollback

- Standalone is a landing path on a foreign repo through a stand-in `gh`; real checks, protection and merge-queue behaviour are **not exercised**. Reversible: the flag is additive; reverting the PR restores today's behaviour.
- The stacked hard edge changes the order only where a child preceded its base. Existing suites decide whether any pinned order depends on the old behaviour.
- `.git/info/exclude` is the one write outside the working tree; one line, documented.

## Alternatives rejected (Preflight Bet Check)

Outcome sought: the sequence works anywhere, landing works when declared, an agent can do it by hand. Smallest bet: a flag plus four guarded branches, one runbook. Not built: a policy key, B1 for foreign repos, a second skill, any `wave_reconcile` change. Containment: the flag; the guards.

## Per-issue rating (RELEASES vocabulary, 1-100)

`40/40/60/35` (pri/sev/appeal/effort), the operator's proposal on the tracking issue (appeal 60 is the operator's value). Severity 40: nothing in Forge is blocked, but a foreign install stops after a real merge in the default mode (T7) and #107-style stacks stop mid-queue. Recurrence: unknown trend; one measured incident (#1661), no earlier same-class report. Effort 35: guarded branches in four scripts plus a runbook and a measured check.

## Lessons learned

NO_ENTRY at plan time.

## Recon ledger

- `prior_art_recon.py`: 0 open PRs, 0 merged, no fix candidates; #1661 is the umbrella.
- Base measurements M1-M6 above, retained under `TESTS-RESULTS/2026-11-27+GH-1662/`.
