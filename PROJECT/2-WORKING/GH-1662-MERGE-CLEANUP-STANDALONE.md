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
| Plan approved by Codex on round 3 (round 1 FAIL six Should; round 2 FAIL one Should; both answered). Implemented; manual check A1-A15 recorded under `TESTS-RESULTS/2026-11-27+GH-1662/`; existing suites run in a disposable clone. | Final Codex QA, qualification gate and push from a disposable clone, ready PR. Merge is the operator's. |

## Contract (binding: the "Contract decision" comment on #1661)

Priority order: (1) the merge sequence works with only `git` and `gh`; (2) landing works in an **explicit** standalone mode; (3) a prose runbook for an agent when the scripts cannot run. Forge mode is unchanged and its requirements are documented.

## Observed (measured at base `52813e56f`; fixture and stand-in `gh` under `TESTS-RESULTS/2026-11-27+GH-1662/fixture/`)

Fixture: a bare origin and a primary clone of a small repo ("acme/widgets", integration branch `main`) with **no Forge files**, 17 open PRs: a declared dependency (#106 depends on #109), a stacked PR (#107, base = #106's branch), file collisions on `src/core.py` (#102, #103, #105), a conflict hub (#105), a PR that conflicts with the base alone (#115), a draft (#108), failing checks (#110, with a dependent #116), a held PR (#114), a dependency cycle (#111 <-> #112, with a dependent #113), and a second PR editing `CHANGELOG.md` (#117, collides with #109). A fresh `HOME`, so no default scan root is reachable. The stand-in `gh` computes `files` and `mergeable` from real git and squash-merges into the bare origin; it cannot exercise GitHub's real checks, protection or rate limits.

| # | Probe | Observed at base |
|---|---|---|
| M1 | `--prs-only`, all 17 open PRs (system Python 3.9.6) | rc 0, makes no clone, needs no Forge file. All 17 are in the table (none dropped). The cycle is named in "Ordering Notes". Receipt: `base/base-prs-only.out`. |
| M2 | dry run with `--prs`, 16 of the 17 (the draft #108 cannot be pinned) | The Landing forecast **runs with no Forge files** (`git merge-tree`): hubs, clean set, fold, recommendation `group`. Then Phase 5 stops at the first PR: rc 2, `landing clone gate wiring failed: githooks/install.sh is missing ... (GH-1576)` (T3). Receipt: `base/base-dry.out`. |
| M3 | the order | **#107 (stacked on #106) is sequenced at 6, before its base #106 at 9 in the 17-PR table (M1) and at 8 in the 16-PR dry run (M2)** (because #106 waits for #109). `toposort_prs.py` never reads `baseRefName`. Landing in that order stops at #107: `targets 'feat/faq', not 'main'` (`merge_cleanup.py:2109-2111`), rc 2, mid-queue. A sequencing defect, not specific to standalone. **A second, related stop (plan QA F1):** in a **dry run** nothing is retargeted, so even a correctly ordered stacked child reads `targets 'feat/faq', not 'main'` and stops the preview (that stop at `:2109-2111` precedes the dry-run `continue` at `:2379-2381`; `_protect_stacked_dependents` runs only at `:2412`). |
| M4 | the forecast labels | `ledger_repair_paths()` defaults to `{releases.sql, releases.db, LEADERBOARD.*, CHANGELOG.md}`; in a repo without B1 a conflict on `CHANGELOG.md` would read "potentially B1-eligible" and "PRs needing a B1 repair: N", advice nothing can act on. |
| M5 | T4: `.tick/` | `selection-*.json` is written under `<primary>/.tick/merge-cleanup/` (`attempt_record.py:49-51`); `inspect_primary_landing` reads `git status --porcelain`, so the next run is NOT READY, and `commit_and_push_phase5_writes` would `git add -A` the pin file into the integration push. |
| M6 | scan roots | `default_scan_roots` = four fixed original-operator roots, not origin-filtered, plus the primary's parent folder when it is safe, origin-filtered (`scan_clones.py:26-31`, `:71-83`). |

## Existing criteria (extracted, not invented)

- **Hard edges** (`toposort_prs.py:55-75`): `depends on|blocked by|after|requires|prerequisite[:] #N` or a PR URL, and `part of wave after #N`, to an **open** PR. A hard dependent is "NOT attempted" if its predecessor did not land (`merge_cleanup.py:2068-2079`).
- **Soft edges** (`:95-130`): two PRs touching a common file are ordered older `createdAt` first, unless that closes a cycle (then a warning). They order; they never block (GH-623).
- **Order**: Kahn, ready PRs by ascending number; a cycle is appended in numeric order with a warning, and its hard members are then each "NOT attempted".
- **Skips, reported**: draft (`:2093`), hold label/title token (`hold_label`, #444), required checks failing/pending/unreadable (`:2319-2343`, dry run reports only), mergeable not `MERGEABLE|CONFLICTING` (stop), `--prs` pins (GH-1226).
- **Forecast** (GH-1452/1470, `ledger_merge.landing_forecast`): each PR alone vs a frozen base, each pair, a cumulative fold stopping at the first conflict; hubs named by base conflict then greedy conflict degree; `direct in passes` when at least 3 conflict, the clean set folds clean, and the second pass is at most half; `group` on needs-review paths or an unclean clean-set fold; withheld when any step is unknown. Needs git >= 2.38.

## Decisions

- **D1. Declaration shape: a CLI flag `--standalone`, no policy key.** It is per run and visible on the command line, so a reviewer of a transcript or an agent's plan sees it; a committed `.merge-cleanup.json` key is persistent, could be committed into a Forge repo to turn its ledger gate off, and changes the policy schema that older drivers refuse (`merge_cleanup.py:480-486`). Rejected: infer from absent files (GH-1576); a policy key; a separate skill (a second subsystem). Reversible: delete the flag.
- **D2. The declaration is guarded, in the contradicting direction only.** `--standalone` is refused (rc 2, naming the files) when the primary carries one of these overlay markers: `releases.sql`, `releases.db`, `utils/py/releases_app.py`, `.xyz/utils/py/releases_app.py`, `utils/py/wave_reconcile.py`, `utils/pdda/pdda.sh`. A ledger the run would skip is a ledger the landing would bypass; a partial overlay uses the default mode. The list is the set of files the skipped steps need, not a claim that every file of that name belongs to Forge. It is also refused with `--reconcile-pr` and `--retire-published-pr`.
- **D3. What standalone skips, and only that:** the gate-wiring refusal **when `githooks/install.sh` is absent** (T3; with an installer present, wiring runs as today); the pre-merge ledger gate and its semantic read (T5); post-merge `wave_reconcile`, `releases_app check`, `pdda.sh` (including the deferred batch-finalization `pdda.sh` pass) and Jog (T5/T7); B1. A conflicting landing **hands off** (named paths, queue continues, exit 3): B1's ledger replay and changelog union do not apply to a foreign repo.
- **D4. Pushes stay gated.** `gate_unwired_reason`, `push_resolved_head` and `commit_and_push_phase5_writes` are untouched, so a push from a clone or the primary without a proven gate hook is still refused; never `--no-verify`. Standalone makes no push on a clean queue: the hand-off replaces B1, so `push_resolved_head` is unreachable from it; the batch and record writers write local files and use `gh issue`, not `git push`. After merging `origin/development` (which landed GH-1656's local-merge rung, `land_via_local_merge`) there is one more push a standalone run can reach: a GitHub-`CONFLICTING` PR with a clean local merge under policy `merge`. It runs the same `gate_unwired_reason(clone)` check before `git push`, so without an installed hook it refuses (row A17); the dry run says so.
- **D5. T4: `/.tick/` is excluded through Git's own exclude file.** Under `--standalone`, when the run will write records (a dry run with `--prs`, or `--execute`): (a) `git check-ignore -q .tick/merge-cleanup/`: 0 = already ignored, nothing is written (bytes unchanged); 1 = not ignored; anything else = refuse (rc 2). (b) Refuse (rc 2) if `git ls-files .tick/merge-cleanup` lists tracked records (an ignore rule cannot hide them from `git add -A`). (c) Resolve the file with `git rev-parse --git-path info/exclude` (relative output resolved against the primary; for a linked-worktree primary that is the shared common dir, one line for all its worktrees), append `/.tick/` preserving existing bytes and adding a leading newline only if the file does not end in one. (d) Re-run `check-ignore`; still not ignored = refuse. Two concurrent appenders can add the same line twice; harmless, no new lock. Rejected: relocating records under `.git/` (changes the record contract the repair rungs and tests pin); editing the repo's tracked `.gitignore`; telling the operator to do it (the failure reads as an unrelated NOT READY).
- **D6. Scan roots:** under `--standalone` and no `--root`, only the primary's parent folder is scanned, always through the existing origin filter (the GH-722 sibling filter, even when that folder is also a default root), and only if `sibling_root()` allows it (its `NEVER_DELETE` guard is kept); the four fixed roots are not scanned. An explicit `--root` is the operator's choice and is not origin-filtered, exactly as in Forge mode, so a clean clone of another repo under a root the operator names (and under a fixed safe root) stays removable as today; nothing becomes removable that Forge mode would not remove. `--prefix` is a name substring, not an origin constraint (documented).
- **D7. Prerequisites are reported before any clone, in both modes.** One block printed after the run-mode log and **before the early landing-plan checkpoint** (which can create a batch) and before Phase 0, so before the forecast clone and every landing clone. *Standalone:* Python >= 3.9, git launchable (an old git, below 2.38, is distinguished from one that cannot run), gh launchable and >= 2.18, an `origin` remote, `lsof` and the gate-hook status (informational: standalone makes no push). `--execute` refuses (rc 2) on an unlaunchable git or gh, a Python below 3.9, or no origin; an old git or gh version only withholds the forecast or warns, as today. *Default mode, only when a modes-that-clone run (`--prs` or `--execute`) finds one missing:* a stderr `PRE-FLIGHT` line per missing requirement (no `githooks/install.sh` in the primary: landing clones refuse unless `--standalone` is declared; no ledger/`releases_app.py`: the pre-merge ledger gate refuses; an integration branch other than `development`: post-merge `wave_reconcile` is development-only). Report-only, existing later guards untouched, silent for a repo that has the overlay.
- **D8. Forecast under `--standalone`:** `ledger_repair_paths` is empty, so every conflicting path is "needs review", the B1 line reads as a hand-off count, and one blind-spot line says so (fixes M4). The forecast dict carries `standalone: true`.
- **D9. Stacked bases are hard edges** in `toposort_prs.py` (fixes M3): a PR whose `baseRefName` is another open PR's `headRefName` waits for it and is "NOT attempted" if it did not land. This is a **new shared ordering edge**, accepted as the existing intent of `_protect_stacked_dependents` (parent first, retarget the child). Effects on a stacked pair, in every mode: the order changes only if the child preceded its parent; an overlapping pair gets a hard edge instead of a soft collision edge, so its "File collision" note disappears and `_hard_deps`/`_soft_deps` change (`toposort_prs.py:112-145`); a listed child whose parent is unlisted is deferred in Phase 4 (exit 3, named) instead of refused at `:3069-3079`; the log order of `not in --prs` lines for an unlisted stacked pair follows the new order. The parent must be a same-repository PR: a cross-repository (fork) PR's head branch is not a branch of this repository, so `isCrossRepository` PRs are never parents (final QA round 1 F1: two fork PRs from `main` would otherwise depend on each other); `gh pr list` now also requests `isCrossRepository`, and data without the field is read as same-repository. Queues with no PR whose base is another open same-repository PR's head are unchanged **by construction** (the edge set is empty). No warning line is added. `_protect_stacked_dependents` applies the same rule (final QA round 2 F2: it matched by short branch name and would have retargeted an unrelated upstream child when a same-named fork PR landed): a cross-repository PR retargets nothing; the live read carries no identity, so it is taken from the discovery list; no change when the field is absent.
- **D10. A stacked child previews in a dry run.** In `_land_prs_loop`, when `info.baseRefName != branch` and this is a dry run and that base is the head of a PR already previewed earlier in this loop (so it would have landed and retargeted the child), the loop logs `[DRY RUN] PR #N targets #M's branch; it would be retargeted to <branch> after #M lands` and continues the preview; **execute keeps the live-base stop** (by then the parent has landed and `_protect_stacked_dependents` has retargeted the child, so a mismatch means something is wrong), and a child whose parent was skipped never reaches the check (D9 blocks it). No `gh pr edit` or merge is issued in the preview. Shared by both modes (a dry run of a correctly ordered stack now previews instead of stopping).

## Smallest affected surface and the writers extended

- `merge_cleanup.py`: `--standalone`; helpers `standalone_overlay_found`, `standalone_prerequisites`, `default_mode_preflight`, `ensure_tick_ignored`; `prepare_landing_clone(..., standalone=False)`; in `_land_prs_loop` the `if standalone` branches (hand-off before B1, ledger gate, post-merge reconcile, clone kwargs) and the D10 preview. Every Forge-mode call keeps its exact arguments (the suites stub `prepare_landing_clone` with a four-positional lambda and assert on `run_post_merge_reconcile`).
- `scan_clones.py`: `standalone_scan_roots` beside `default_scan_roots`.
- `ledger_merge.py`: `landing_forecast(..., standalone=False)`.
- `toposort_prs.py`: the stacked hard edge.
- `SKILL.md`: a compact "Standalone mode" section, prerequisites by mode, the stacked rule, link. New `STANDALONE.md`: the runbook.
- No change: attempt records, gates, batch records, `execute_pr_merge`, teardown.

## Ordered implementation, verification inline

1. Edit the four scripts as above. -> `python3 -m py_compile` under 3.9.6 and the 3.13 test venv; `git diff` shows the Forge-mode call sites unchanged.
2. Run the fixture (system 3.9.6, then venv 3.13) per the acceptance rows. -> receipts under `TESTS-RESULTS/2026-11-27+GH-1662/`.
3. Write `STANDALONE.md` from the extracted criteria; SKILL.md edits (the capability table is untouched; the parity guard reads it).
4. Run the existing suites in a disposable full clone, test venv first on PATH: `gh436` (collects phase A/B/C), `gh534_phase_b/c` standalone, `gh645`, `gh674`. -> green.
5. Record the manual check and `provenance.jsonl`; final Codex QA; qualification from a disposable clone; push; ready PR.

## Acceptance and red controls (no new tests: GH-831)

Exact subsets (fixture, integration branch `main`, fresh HOME, stand-in `gh`; each mutant keeps every other candidate fix and all unrelated preconditions green, so its rejection is the named one):

- **CLEAN** = `--prs 101,109,106,107` (a declared dependency and a stack, all mergeable, none conflicting; 4 PRs, so a landing decision is needed).
- **MIXED** = `--prs 101,102,103,104,105,106,107,109,110,111,112,113,114,115,116,117` (all but the draft).

| ID | Check | An unchanged or wrong candidate fails because | Expected |
|---|---|---|---|
| A1 | **Forge regression.** Base vs candidate, **no flag**, fixture without installer built `--no-stack` (#107 targets `main`, so no PR is stacked), dry run, `--prs` MIXED. (First attempt, with the stack present and #106/#107 merely unlisted: stdout differed in the order of the `not in --prs; not sequenced` log lines of the unlisted stacked pair, which D9 reorders; recorded, hence the `--no-stack` fixture.) | the guard must not be loosened and Forge output must not move | rc 2 at both; stdout identical after path normalisation; stderr differs only by the D7 default-mode `PRE-FLIGHT` lines |
| A2 | Candidate `--standalone`, CLEAN dry run (python 3.9.6, then 3.13) | T3, the stacked stop (D10) or another overlay step still blocks | rc 0; per-PR dry-run lines for all four incl. the stacked child; `[DRY RUN] Would merge` x4; no `pr edit`/`pr merge` in the stand-in log |
| A2b | Candidate `--standalone`, MIXED dry run | drafts, holds, failing, cyclic, conflicting PRs must be reported, not dropped | rc 3; named: the hold row for #114, `NOT attempted` for #111, #112 (the cycle) and #113, the `HANDOFF` of #115 with its paths, the `N PR(s) did not land` summary. #110's failing checks appear as the table's `FAIL` and `[DRY RUN] ... required checks failing` line, and #116 (depends on #110) is **previewed**, not blocked: a dry run only reports checks (`merge_cleanup.py:2334-2335`, shared behaviour unchanged). The failure-dependent block of #116 is asserted in a separate **execute** observation (CLEAN plus #110 and #116, `--standalone --execute`): #110 `required checks failing ... not merged`, #116 `NOT attempted — depends on #110` |
| A3 | Mutant: the `standalone and` condition removed from the wiring skip; **no flag**, fixture without installer | the declaration would be inferred | the GH-1576 diagnostic `landing clone gate wiring failed: githooks/install.sh is missing` is **absent** from the mutant's output (present at base and candidate); a later ledger-gate failure may keep the rc at 2, so the diagnostic is the assertion |
| A4 | Same fixture **with** `--with-installer`, no flag, base vs candidate, CLEAN | Forge mode must still wire, then run the ledger gate | same `pre-merge ledger gate RED` rc 2 at both |
| A5 | Candidate `--standalone --execute` on CLEAN with `--landing-plan direct --landing-reason ...`, then `--record-sweep` | gate, reconcile or fast-forward steps still need the overlay | #109, #106, #107 land in that order; each reads MERGED; primary equals origin and is clean after each; no `.tick` in `git status`; no push; rc 4 (batch QA pending) then 0 after the verdict |
| A6 | T4: two consecutive standalone dry runs with `--prs`; mutant without `ensure_tick_ignored`; plus a linked-worktree primary, an already-ignored `.tick/` (bytes unchanged) and a tracked `.tick/merge-cleanup` record (refused) | the second run reads NOT READY | candidate READY twice; mutant NOT READY on run 2; each side case behaves as D5 says |
| A7 | Stacked order. Base places #107 before #106 (M3). Candidate after. Mutant: only the `toposort_prs.py` edge removed, `--standalone --execute` on CLEAN | the loop stops at the child | candidate orders #106 first and lands both; the mutant stops rc 2 with `targets 'feat/faq', not 'main'`; and a pure sorter probe on both stacked orders, including the overlapping-pair case F2 named, recording the changed warnings and dependency fields |
| A8 | Prerequisites, with a **working** origin: a `git` shim that reports 2.30.0 for `--version` only and a `gh` shim reporting 2.4.0, echoing a marker to stderr on every `git clone`. Separately a primary with no `origin` | the dry run clones first and reports later | `UNMET` lines appear before the first clone marker in the merged stream; the no-origin case reports `UNMET origin` and `--execute` refuses rc 2 |
| A9 | Scan roots: a clean other-origin clone under `$HOME/marathon-clones` of the fresh HOME, no `--root` | standalone widens teardown | Forge mode lists it; standalone does not; with explicit `--root` both list it |
| A10 | Overlay guard: fixture with a committed `releases.sql` | the flag bypasses an existing ledger | `--standalone` refused rc 2 naming the file |
| A11 | Forecast labelling: `--prs 101,109,117` (#117 collides with #109 on `CHANGELOG.md`) | M4 | Forge: `direct`, "potentially B1-eligible" `CHANGELOG.md`; standalone: `group`, "needs review", hand-off wording and the blind-spot line |
| A12 | Pushes stay gated, with an identity set and a working origin so `commit`/`fetch` cannot mask the hook refusal: call `gate_unwired_reason` and `commit_and_push_phase5_writes` on a throwaway copy of the foreign primary holding a dirty file | a push slips through | both return the GH-1576 text and origin's tip is unchanged |
| A13 | Existing suites (step 4) | regressions | green |
| A14 | Python: A2 and `py_compile` under 3.9.6 and 3.13 | a 3.10+ construct | identical results |
| A16 | **Fork heads are not parents (final QA R1 F1, R2 F2).** Sorter and `effective_sequence` probe on two fork `main`->`main` PRs and on a genuine same-repository stack; `_protect_stacked_dependents` probe (fork parent: zero `pr edit` calls, also in the production shape where the live read lacks the field and the discovery list has it; same-repository parent: exactly one); fixture `--with-forks` dry run of `--prs 118`; mutants with each guard removed | a short branch name would invent a dependency between independent fork PRs | candidate: no edge, a selected fork PR kept and previewed, genuine stack still ordered and its child deferred when the parent is unlisted; mutant: the fork PR is deferred behind the other fork PR |
| A15 | **Runbook honesty.** Execute the runbook's own commands (`gh pr list`, the `merge-tree` alone/pair/fold) on the fixture, and an order derived only from the runbook text by an independent snippet | the prose and the script disagree | same order as the script's table and same conflict pairs as the forecast; differences recorded as runbook defects |

## Rebase onto the moved base

After final QA approval, `origin/development` moved 87 commits (`6142128d9`), including GH-1656's local-merge rung (`land_via_local_merge`, GitHub-`CONFLICTING` PRs landed through a leased push under policy `merge`), a batch-record change and a phase B test addition, and conflicted with this branch in `merge_cleanup.py` (the dry-run `Would merge` block) and the ledger. Resolution: the dry-run block takes GH-1656's text and keeps this change's `landing_heads` line plus one standalone-only message (the rung pushes from the clone, so without a proven hook the dry run says `--execute` would stop); the ledger takes the base's `releases.sql`/`releases.db` and this task's row is re-applied through the writer (`roadmap pickup`, `--accepted-start`), `releases check` clean. Docs now name the rung as the one extra push a standalone run can reach (D4, SKILL.md, STANDALONE.md) and row A17 proves it is refused without a hook. The regression rows (A1, A4, A6) compare against `origin/development` at `6142128d9`; the `BASE-*` measurements stay at `52813e56f`, where the defects were measured. All rows and suites were rerun on the merged tree.

## Verification results (see `provenance.jsonl` for the revision of each row)

Manual check, `TESTS-RESULTS/2026-11-27+GH-1662/` (`provenance.jsonl`, `runs/`, `run_controls.py`, `runbook_walk.py`, `fixture/`). All rows pass; red controls are real (each mutant fails on the named assertion, the same row passes unmutated).

| Rows | Result |
|---|---|
| BASE-M1/M2/M5 | base: sequencing works with no Forge file; T3 refusal; T4 `.tick/` left untracked; stacked child before its base |
| A1, A4 | Forge regression: same refusal / same ledger-gate RED at base and candidate; stdout identical on a no-stack queue; stderr differs only by the two default-mode `PRE-FLIGHT` lines |
| A2, A14, A2b, A2b-prs-only, A2b-exec | standalone dry run rc 0 (3.9.6 and 3.13 identical); mixed queue rc 3 with every skipped, held, handed-off, cyclic and blocked PR named; `--prs-only` lists all 17, no clone; execute blocks the dependent of a failing-checks PR |
| A3, A2-mut, A6, A7 (mutants) | "never inferred" mutant loses the GH-1576 diagnostic; no-preview mutant stops the stacked child; no-`.tick`-ignore mutant reads NOT READY on run 2; no-sorter-edge mutant stops `--execute` at the child |
| A5 | standalone `--execute` lands 101, 109, 106, 107 in order; primary equals origin and clean; origin has only fixture-author and stand-in commits (no tool push); sweep verdict recorded |
| A8-A12 | prerequisites before the first clone; scan roots; overlay guard; forecast labels; pushes stay gated |
| A16 | fork heads are not stacked parents (final QA R1 F1, R2 F2): no edge between two fork `main` PRs, a selected fork PR kept and previewed, a genuine stack still ordered and deferred; a landed fork PR issues zero `pr edit` retargets (also in the production shape) while a same-repository parent still issues exactly one; the mutants without each guard reproduce the defects |
| A13 | existing suites green at `217845ee1`: phase B 39, phase C 111, gh645 8, gh674 6, gh436 227 (disposable full clone, test venv first on PATH, identity unchanged) |
| A15 | the runbook's commands and rules reproduce the script's order, 20 conflict pairs, alone-conflict and fold stop |

**Not verified:** real GitHub (checks, protection, merge queue, rate limits, real squash effect on a stacked child); Python below 3.9 at runtime; A15 shares an author with the script and the runbook (finds drift, not independent review). One recorded correction: A1's first attempt (stack present, #106/#107 unlisted) differed in the order of two `not in --prs` log lines because D9 reorders the unlisted stacked pair; A1 now uses a `--no-stack` fixture, and that order change is the accepted D9 semantics.

## Smoke (GH-1088)

Main path: A2/A5 (dry run then `--execute`). Adjacent path: the same command run a second time (A6), and `--scan-only`/`--prs-only`, which a resumed operator would run.

## Risks and rollback

- Standalone is a landing path on a foreign repo through a stand-in `gh`; real checks, protection and merge-queue behaviour are **not exercised**. Reversible: the flag is additive; reverting the PR restores today's behaviour.
- The stacked hard edge (D9) and the dry-run preview (D10) are shared with Forge mode and change behaviour only for queues containing a stacked pair (accepted shared semantics, D9). Plan QA R1 checked that `TestTopologicalSort` and the retarget tests pin neither the old order nor the dry-run stop; the existing suites run in step 4 confirm it.
- `.git/info/exclude` is the one write outside the working tree; one line, documented.

## Alternatives rejected (Preflight Bet Check)

Outcome sought: the sequence works anywhere, landing works when declared, an agent can do it by hand. Smallest bet: a flag plus four guarded branches, one runbook. Not built: a policy key, B1 for foreign repos, a second skill, any `wave_reconcile` change. Containment: the flag; the guards.

## Per-issue rating (RELEASES vocabulary, 1-100)

`40/40/60/35` (pri/sev/appeal/effort), the operator's proposal on the tracking issue (appeal 60 is the operator's value). Severity 40: nothing in Forge is blocked, but a foreign install in the default mode is predicted by source order to stop after a merge (T7: observed with a stand-in `gh`, not exercised against real GitHub) and #107-style stacks stop mid-queue. Recurrence: unknown trend; one measured incident (#1661), no earlier same-class report. Effort 35: guarded branches in four scripts plus a runbook and a measured check.

## Lessons learned

NO_ENTRY. Edit verdicts: the `--standalone` flag, the stacked hard edge and the dry-run preview each changed several things at once with only fixture runs behind them (`confounded`); no lesson rests on a `helped` row.

## Recon ledger

- `prior_art_recon.py`: 0 open PRs, 0 merged, no fix candidates; #1661 is the umbrella.
- Base measurements M1-M6 above, retained under `TESTS-RESULTS/2026-11-27+GH-1662/`.
