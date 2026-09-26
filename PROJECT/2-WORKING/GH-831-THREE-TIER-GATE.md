---
gh_issue: 831
source: https://github.com/HiQS-Labs/XYZ-forge/issues/831
title: "GH-831: no new tests, and three gate tiers (Small/Medium/Large) chosen by ci-route for push, per-merge reconcile and promotion; non-core suites off"
status: Active — Phase 1 merged (#832); Phase 2 built and under Codex final QA (2-WORKING)
created: 2026-09-25
updated: 2026-09-25
owner: operator (via /start-task)
doc_type: feature
branch: feat/gh831-phase2-tiers (Phase 1: feat/gh831-three-tier-gate, merged as f832ef5a)
non_goals:
  - Deleting test files; "off" keeps them on disk.
  - New gate machinery of any kind (lanes, runners, telemetry, guard suites).
  - Moving tests to another repository (#816).
related:
  - "#802 — CI retrospective; the operator decision is recorded there (comment 5841529958)"
  - "#819, #815, #816, #817 — superseded by this issue"
  - "#830 / #829 — the flaky non-core suite that failed #828's 79-minute reconcile"
  - "PR #811 — test admission gateway; conflicts with this decision (see O6)"
goal: >
  The gate runs what a change needs: Small (PDDA + PRS + canaries) for docs, ledger and skill files,
  Medium (the touched area's suites) for mapped non-core code, Large (the registry: Small + core + area
  suites) for the core harness. utils/ci-route.sh picks the tier for the push hook and for the hosted
  reconcile after each merge. Promotion always runs Large. Suites outside those sets are off, and agents stop
  adding tests.
---

# GH-831 — no new tests; three gate tiers; non-core suites off

## Status

| What was just completed | What's next |
|---|---|
| Phase 1 merged as `f832ef5a` (#832). Phase 2 steps 1–6 built on `feat/gh831-phase2-tiers` (`9ecf2071`, `626b8f5d`): the Small list and D4 routing, the 8 suites off, the reconcile qualifying by tier, and the docs. The first real Small run is green, 76/76 in 1,233 s locally, and the step-4 reconcile check passes 19/19 against its telemetry, with red controls. See "Phase 2 — what the build found". | Codex final QA of Phase 2, then the full gate once in a disposable clone through the push hook, then the PR. Phase 3 after merge. |

## Table of contents

- [Decision and rating](#decision-and-rating)
- [Recon](#recon)
- [Design](#design)
- [Decisions for the operator](#decisions-for-the-operator)
- [Phase 1 — Freeze and rules (docs-only PR)](#phase-1--freeze-and-rules-docs-only-pr)
- [Phase 2 — Tiers (gate code PR)](#phase-2--tiers-gate-code-pr)
- [Phase 3 — First hosted evidence](#phase-3--first-hosted-evidence)
- [Verification, rollback, blast radius](#verification-rollback-blast-radius)

## Decision and rating

The operator's decision (2026-09-25) is recorded on [#802](https://github.com/HiQS-Labs/XYZ-forge/issues/802#issuecomment-5841529958)
and restated as the requirements of [#831](https://github.com/HiQS-Labs/XYZ-forge/issues/831). This doc does
not restate them. Retained copies for offline review:
`TESTS-RESULTS/2026-09-25+GH-831/requirements-issue-831.md` and
`TESTS-RESULTS/2026-09-25+GH-831/decision-802-comment-5841529958.md`.

Operator answers taken on 2026-09-25, in the `/start-task` session that wrote this plan:

- Medium = mapped non-core code.
- "Off" = unregistered, files kept.
- Enforcement = rules and skill text only.
- Sequencing = issue + plan after #821.
- After the Codex plan review escalated for them, the operator accepted O1, O2, O3, O4, O7 and O8 as proposed:
  - O1: fast push checks;
  - O2: gh549 and gh436 stay in Small;
  - O3, O4 and O7: Medium handling, all three;
  - O8: promotion always runs Large.

  O5 and O6 were not asked. O5 follows the no-new-tests rule, and O6 is a recommendation outside this
  issue.

**Rating `rated 85/70/75/40` (2026-09-25).**

- **Severity 70.** This is a queue delay, not a work-blocking defect. Every merge waits for a 61–76-minute
  hosted run before the next can land, and a red in any suite withholds the merge's closeout until a re-run.
  Nothing is lost and no work is blocked indefinitely, so it sits below the policy's 80–100 band for crashes,
  corruption and work-blocking defects.
- **Priority 85.** The operator asked for this now, and it gates every other merge.
- **Appeal 75.** An interpretation of the operator's stated preference ("we have to start to enforce adding no
  more tests", "radical refactoring"), not a score they gave.
- **Effort 40.** It touches `validate.sh`, `utils/ci-route.sh`, `utils/py/wave_reconcile.py`,
  `utils/py/express.py`, three existing suites that pin today's behaviour, the root rules, and about 20
  skills. The push hook is unchanged. That is one to two days.

**Recurrence (14-day windows).**

- `ci`-labelled issues opened: 67 (09-12..09-26) against 53 (08-29..09-11).
- `ci:local-gates`: 24 against 17.
- Hosted wave-reconcile runs failed on every run until the lane stabilised on 2026-09-21. Since then 14 of 48
  runs failed (29%). Causes are not classified here; one known case is #829 (flake #830).

## Recon

Base `37038841` (development after #821's reconcile). Evidence and its method are in
`TESTS-RESULTS/2026-09-25+GH-831/`: `suite_map.py`, which reproduces both tables below,
`suite-map.tsv`, `merge-projection.tsv`, `registry-37038841.txt` and `provenance.jsonl`.

**R1 — How tiers work today.**

- **`utils/ci-route.sh` classifies a path list.**
  - Docs surfaces (`*.md`, `*.txt`, `PROJECT/`, `docs/`, `relay-system/`, `decisions/`, `TESTS-RESULTS/`) give
    tier 1.
  - Paths claimed by `subsystem_of()` (hq, releases, telemetry, ate, swe-diagram, pdda, agent-chorus,
    standup, skills-army-hq) give tier 2 with that subsystem's `SUBSYSTEM_TESTS_*`.
  - These always give tier 3: `src/`, `bin/tick`, `relay-automation/`, `.github/workflows/`, unmapped
    `utils/py/*`, and any other unmapped path (`utils/ci-route.sh:296-455`).
  - A `test/` edit gives tier 3, with one exception (GH-487, `utils/ci-route.sh:335-347, 418-424`): a suite
    that a subsystem claims stays in tier 2 when the same push also touches that subsystem's code.
    Example: `utils/py/releases_app.py` + `test/gh549-work-events.sh` gives tier 2, releases. This plan keeps
    both rules.
  - Skill code under `skills/` is unmapped unless a subsystem claims it, so a radar or status script edit goes
    to tier 3. `releases.db`/`releases.sql` go to the releases subsystem, which runs 24 suites.
- **`validate.sh` applies the tier.**
  - Tier 1 runs only `utils/pdda/pdda.sh run` plus the warn-only local checks (`validate.sh:1069-1093`).
  - Tier 2 runs `T2_TESTS` from the classifier, plus the PDDA gate when docs changed and static syntax checks
    on changed files (`validate.sh:1122-1176`).
  - Tier 3 runs the whole `TESTS` array (`validate.sh:88-696`, 419 entries) plus the python lane,
    clone-identity and gamma probes.
- **`githooks/pre-push` dispatches on the classifier's output.**
  - route=docs runs the docs gate (84 s).
  - tier 2 runs `validate.sh --paths-file`.
  - Anything else runs full `validate.sh` (930 s at 4-wide on 2026-09-25) (`githooks/pre-push:252-300`).
- **The hosted reconcile always runs the full suite.** `utils/py/wave_reconcile.py:548-616` `qualify_landings`
  runs `bash validate.sh --sequential` whatever the landing changed, and any non-zero exit means no receipt
  and a rollback. It knows each landing's merge commit (`meta.mergeCommit.oid`), so the landing diff is
  available. It strips `XYZ_VALIDATE_*` from the environment (`:574`), so the GH-379 skip list cannot reach it.
- **`ci-local.sh` and `ci.yml` parse `TESTS` out of `validate.sh`** (`ci-local.sh:250-251`), so changing the
  registry changes every full-run path consistently. The promotion boundary runs `validate.sh --sequential`
  on a push to `main` (`.github/workflows/ci.yml`).

**R2 — Suite map (419 registered; hosted sequential minutes from run `a0345e9c`).** Every suite's final
disposition is the `disposition` column of `suite-map.tsv`, produced by `suite_map.py`.

| Disposition | Suites | Minutes | What it is |
|---|---:|---:|---|
| Small | 73 | 17.9 | PDDA (`SUBSYSTEM_TESTS_pdda` + `gh784-marathon-qa-gate`), PRS (`SUBSYSTEM_TESTS_releases`, merge-cleanup/reconcile suites, 11 ledger suites) and 15 canaries. `gh549-work-events.sh` (6.4) and `gh436-merge-cleanup.sh` (3.9) dominate it. |
| Core | 300 | 38.1 | the suite runs core harness code |
| Medium | 38 | 4.7 | owned by an area: hq 13, ate 11, skills-army-hq 5, telemetry 4, agent-chorus 3, standup 1, swe-diagram 1 |
| Off | 8 | 0.1 | executes nothing but reads skill text, or runs only its own skill's `install.sh` |

The rules settled most suites. For the 63 they could not settle, the calls are recorded in `suite_map.py`'s
`OVERRIDES`:

- **Small (12):**
  - PRS: `gh75-dashboard.sh`, `gh107-timeline-json-seam.sh`, `gh349-releases-roadmap-vendored.sh`,
    `gh351-manifest-unship.sh`, `gh360-scoped-receipt-chain-rebuild.sh`, `gh424-roadmap-status-marker.sh`,
    `gh491-roadmap-section-validation.sh`, `gh492-roadmap-state-sweep.sh`, `gh527-issue-url-repair.sh`,
    `gh605-work-state.sh`, `gh605-board-policy.sh`.
  - PDDA: `gh784-marathon-qa-gate.sh`.
- **Medium (7), joining an existing area list:**
  - ate: `gh142-ate-exit-contract.sh`, `synthetic/gh102-telemetry-schema.sh`.
  - agent-chorus: `agent-chorus-bridge.sh`, `gh233-agent-chorus-concurrency.sh`.
  - skills-army-hq: `gh589-xyz-mini-sync.sh`, `gh589-consult-no-tick.sh`, `gh589-skill-viewer.sh`.
- **Off (8).**
  - These execute nothing, only reading skill text: `gh578-ci-optimize-skill.sh`,
    `gh615-start-task-reinforce.sh`, `gh616-start-task-commensurate-envelope.sh`,
    `gh617-relay-xyz-commensurate-review.sh`, `gh779-radar-ci-health.sh`, `gh781-wam-radar-seed.sh`.
  - These read skill text and run only that skill's own `install.sh`: `gh778-review-code-skill.sh`,
    `gh798-status-skill.sh`.
- **Core:** every other unsettled suite. Codex round 1 (F1) moved three suites here from an earlier off list,
  because each runs harness code:
  - `debug-mantra.sh` runs the marathon driver's dry-run (`test/debug-mantra.sh:24-36`).
  - `gh777-start-task-prior-art.sh` runs `utils/py/prior_art_recon.py` against the roadmap
    (`test/gh777-start-task-prior-art.sh:8-31`).
  - `gh132-review-xyz-skill.sh` runs `utils/py/review_xyz.py` (`test/gh132-review-xyz-skill.sh:29-31`).
  - The rule is now: **a suite that executes harness, PDDA or PRS code is never off.** `gh527` has two suites;
    only `gh527-issue-url-repair.sh` is Small, and `gh527-destructive-git-guard.sh` is core.

**R2 finding: turning suites off saves almost no time.** This repo's suites overwhelmingly exercise its own
harness. "Off" is 8 suites and about 6 seconds of runtime; its value is less flake and skill-text churn, not
speed. The name-based estimate in #802 and #831 (~180 off) was wrong. The time lever is routing.

**R3 — Merge projection.** The 146 squash merges on `development` since 2026-08-26 were routed by D4 and
priced by D5: tier 1 runs the hosted Small run, and tier 2 or 3 runs the hosted full run. See
`merge-projection.tsv`.

| Variant | Tier 1 (Small run) | Tier 2 | Tier 3 |
|---|---:|---:|---:|
| As merged: real paths, test edits included | 47 (32%) | 1 | 98 |
| No test edits: `test/` paths removed | 62 (42%) | 4 | 80 |

Neither variant is exact:
- **As merged understates Small.** Many of those test edits were new suites, which D7 stops.
- **No test edits overstates Small.** It also strips repairs to existing suites, which still happen.

The realistic Small share is 32–42%. At about 18 minutes for the hosted Small run and about 61 for the full
run (the registry minus off), the average hosted qualification per merge falls from about 61 minutes to about
44–47.

**R4 — Instructions that make agents add tests.** An inventory was taken from the root docs, skills and brief
generators. Items marked (A) ask for a new test outright; (B) require a failing-first check that in practice
produces a new test file.

- **Blocker in code.** `utils/py/express.py:536-546, 569, 1260` refuses a hotfix without `--suite` naming a
  file registered in `validate.sh`. It checks only that the file exists and that its name is registered, so an
  existing covering suite passes. `/express`'s skill text is what demands a new dedicated suite.
- **(A):**
  - `skills/2-daily/express/SKILL.md:5-6, 22, 33, 60-75, 127-128`
  - `skills/2-daily/review-code/SKILL.md:164-165, 225, 296`
  - `skills/2-daily/review-xyz/SKILL.md:29, 103`
  - `skills/2-daily/ci-debug/SKILL.md:115`
  - `skills/2-daily/workhorse/SKILL.md:112`
  - `skills/1-hourly/ponytail/SKILL.md:116-121`
  - `skills/2-daily/file-xyz-bug/SKILL.md:202`
  - `skills/3-weekly/whack-a-mole/SKILL.md:179-180`
  - `skills/3-weekly/radar/SKILL.md:508`
  - `skills/4-occasional/ci-optimize/SKILL.md:59-60, 69-70, 119`
  - `skills/1-hourly/swe/SKILL.md:159`
  - `SOP.md:135, 234`
  - `ARCHITECTURE.md:73`
  - `relay-automation/README.md:38-40`
- **(B):**
  - `GUIDING-PRINCIPLES.md:85` (principle 13: every new or changed gate ships a witnessed red control)
  - `skills/1-hourly/start-task/SKILL.md:136-138`
  - `skills/1-hourly/debug-mantra/SKILL.md:80, 83`
  - `skills/2-daily/workhorse/SKILL.md:91`
  - `review-code/SKILL.md:24-25, 173-181`
  - `ci-optimize/SKILL.md:54-56`
  - `swe/SKILL.md:67`
- **Brief generators** (`relay-turn-lib.sh`, `swarm_preflight.py`, the `marathon_drive.py` relay template)
  contain none.
- **Deployment.** Installed skills are copies under the Deployed Skills collection. They pick up edits only
  through `skills-army-hq`, which is a separate operator action.

**R5 — Existing suites and code that pin today's behaviour.** Read-only recon on base `37038841`. These
facts shaped D1–D4.

- **Registry guards.**
  - `test/gh306-registry-bidirectional.sh:87-94` requires every top-level `test/*.sh` to be in `TESTS` or in
    its 5-entry `EXEMPT` list (`:46-52`). That list is limited by its own rule to "only when it CANNOT run in
    the gate" (`:41`), so an unregistered-but-kept suite fails it today. It does not scan `test/<subdir>/`.
  - `test/gh35-test-tiers.sh:144-153` requires every `SUBSYSTEM_TESTS_*` suite (70) to be in `TESTS`.
  - `test/gh365-driver-lane-registry.sh:49-55` requires the 16 driver-lock-lane suites to be in `TESTS`.
  - `test/gh141-synthetic-registry.sh:34-49` requires the synthetic entries and their 4 wrappers (gh124,
    gh129, gh130, gh131) to be in `TESTS`.
  - `test/ci-workflow.sh:179-183` requires `ci-workflow.sh` to be registered.
  - `test/gh379-canary-uses-validate.sh:275-287` requires the canary's `--skip` names (acorn-extract,
    registry-lock-concurrency, pdda-repo-contract) to stay registered.
  - The release-manifest suites (`litmus-`, `nightwatch-`, `ballast-`, `meter-release.sh`) require their
    manifest gates to stay registered when the gate's issue is closed. None of them is on the off list.
- **Tier pins.**
  - `test/gh35-test-tiers.sh:214-224, 356-401` pins tier 1 as "runs no suite" and "exits 0 in a fixture with
    no suites".
  - `test/gh365-runner-envelope.sh:205-229` pins tier 1 as needing no suites.
  - `test/gh544-pre-push-gate.sh:123-139` pins "the docs route does not run `validate.sh`".
  - The tier-2 fixtures in `gh35` §6 and `gh365-validate-telemetry` contain only `test/hq.sh`. This is safe
    only because `ci-route.sh`'s `add_tier2_test` skips suites missing on disk.
  - `test/gh251-validate-pytest-skip.sh:22, 58` runs the real repo's tier 2 twice. Adding Small to every tier-2
    run would undo #821's saving.
  - `test/ci-route.sh:144-232` pins the tier table and exact subsystem counts (hq 13, releases 24, pdda 15,
    skills-army-hq 2).
- **Qualification.**
  - `utils/py/wave_reconcile.py:461-490` `qualification_summary` accepts only tier 3, sequential, with
    `run_set == registered` and `total == registered + 3`. A tier-1 run emits no telemetry at all
    (`validate.sh:1069-1085` exits first).
  - `qualification_receipt_matches` (`:493-526`) requires schema `wave-qualification@1` and the exact gate
    string `validate.sh --sequential`.
  - `test/gh425-gate-provenance-pr.sh:282-420` pins both, and its stub `validate.sh` exits 7 unless the first
    argument is `--sequential`.
  - `test/gh740-hosted-lane-publish.sh` holds a tier-3 fixture receipt.
  - The 22 committed receipts are each checked against their own telemetry, so shrinking `TESTS` does not
    invalidate them.
- **Other consumers.**
  - `ci-local.sh:274` and `test/gh528-parallel-contention-retry.sh:55-66` parse one `TESTS=( … )` block.
    Entries are removed, not commented out; `gh365-validate-telemetry` D1 catches a commented entry.
  - `utils/py/express.py:540-546` accepts any `--suite` whose name appears in `validate.sh`.
  - Marathon closeout needs a tier-3 gate receipt (`relay-automation/marathon-closeout.sh:148-160`),
    unchanged.

**What R5 changed in the plan.** An earlier draft made tier 1 run Small and added Small to every tier-2 run.
R5 shows that would rewrite the tier-1 and tier-2 contracts pinned by six suites, and it would re-inflate
gh251. The design below leaves `validate.sh`'s tier mechanics and the push hook alone. It applies the new
tiers where the operator's complaint is, the hosted run after each merge, using a data list and the existing
`--subsystem` selector.

## Design

**D1 — What runs where.**

| Boundary | Small: docs, ledger, skill files | Medium: mapped non-core code | Large: core harness |
|---|---|---|---|
| `githooks/pre-push` (a fast pre-check, unchanged) | docs gate (~1.5 min) | the area's tier-2 suites | the full registry |
| Hosted reconcile after each merge (qualifies the landing) | `validate.sh --sequential --subsystem small`: **one** run | `validate.sh --sequential`: the full registry (O7) | `validate.sh --sequential` |
| Promotion (`ci.yml` boundary on `main`) | — | — | `validate.sh --sequential` (unchanged; the classifier is not consulted, O8) |

- **Where the classifier decides.** `utils/ci-route.sh` picks the tier at the push hook and at the hosted
  reconcile. Promotion always runs Large.
- **Why the hosted reconcile runs Medium in full.** It qualifies Medium merges with the full run rather than
  Small plus the area's suites, so every landing is qualified by exactly one run. This avoids a two-run
  receipt, which the matcher's any-match lookup cannot bind to one landing (Codex r1 F2). Medium was 1–4 of
  146 merges.

**D2 — Small is data.**

- `SUBSYSTEM_TESTS_small` in `utils/ci-route.sh` lists the 73 Small suites (R2, `disposition == SMALL`). It is
  the one definition of Small.
- `small` is also added to the `SUBSYSTEMS` enumeration (`utils/ci-route.sh:24`). The listing and validation
  loop (`:52-67`) reads only enumerated names (Codex r2 pass note).
- `validate.sh --subsystem small` already runs any listed subsystem through the tier-2 path
  (`validate.sh:934-940`).
- The only `validate.sh` edit adds `small` to the `--subsystem` case that sets `T2_PYTEST` (`:939`), and
  sets `T2_PDDA=1` for it, so the Small run also runs the PDDA docs gate.
- `subsystem_of()` claims no paths for `small`.

**D3 — Registry.**

- `TESTS` keeps every Small, core and Medium suite. The Medium suites stay registered, so `gh35` §4 holds;
  see O3.
- The 8 off suites (R2) are removed from `TESTS`, not commented out; their files stay in `test/`.
- `gh306`'s existing `EXEMPT` list (`test/gh306-registry-bidirectional.sh:46-52`) gains them, and its rule
  comment (`:41`) gains a second allowed reason: "turned off by operator decision (GH-831)". That list is the
  one record of off.
- R2's 7 Medium reclassifications join their areas' `SUBSYSTEM_TESTS_*` lists.
- None of the 8 is named by `gh141`, `gh379`'s canary skips, the four release-manifest gate lists, or
  `ci-workflow.sh` (Codex r1, Q5 pass).

**D4 — Classifier (`utils/ci-route.sh`).** These join the docs surfaces, so they route to tier 1 and
route=docs. Precedence is explicit (Codex r2, F8), and D4 adds each item to the docs-surface patterns:

- skill files: `skills/**`, except under `relay-xyz`, `relay`, `relay-automation`, `merge-cleanup`,
  `express` and `jog`, and except paths `subsystem_of()` claims;
- ledger and data files: `releases.db`, `releases.sql`, `harnesses.db`, `harnesses.sql`;
- generated views: `LEADERBOARD.html`, `RELEASES-PREVIEW.html`.

How precedence works:

- **The named ledger, data and view files are an explicit exception.** They are added to the docs-surface
  patterns, which `ci-route.sh` checks before `subsystem_of()` in the tier-2 membership case. So they are docs
  even though `subsystem_of()` also claims `releases.db`/`.sql` for releases (`utils/ci-route.sh:36`).
- **For skill paths, core exclusions and subsystem claims take precedence over the new skill-files exception.**
  Text files (`*.md`, `*.txt`) keep their existing docs routing, checked first, and the existing full-gate
  surfaces (`relay-xyz`, `relay-automation`) still win over it (Codex Phase 2 r1, F1).
- **Everything else keeps its existing mapping.** Releases implementation (`utils/py/releases_app.py` etc.)
  stays tier 2, and its dedicated-test co-touch behaviour (GH-487) is unchanged. The push hook, CI's route and `--auto` follow
automatically. Unchanged:
- everything that fails closed today (core surfaces, unmapped code, empty diffs);
- the `test/` edit rules, including the GH-487 exception (R1).

**D5 — The hosted reconcile qualifies by tier (`utils/py/wave_reconcile.py`).** It keeps one run and one
receipt entry per landing, exactly as today.

1. **Selection.** `qualify_landings` unions the pending landings' diffs (`mergeCommit^..mergeCommit`) and
   classifies them in the qualification clone at the tested SHA with `bash utils/ci-route.sh push`.
   - Tier 1 runs `validate.sh --sequential --subsystem small`.
   - Anything else runs `validate.sh --sequential`, exactly as today.
   - A classifier that cannot run, or unreadable output, means the full run.
2. **Tier-2 completeness rule** in `qualification_summary`, used only when the run's `tier` is 2. The tier-3
   rules are untouched. All of these must hold:
   - Identity is unchanged from today: one `run.start` and one `run.summary`, `commit == tested`, `mode ==
     sequential`, one run ID, and `runner == validate` on every row.
   - `tier == 2`.
   - The shell suite events are the events with `lane == sequential`. Their names are unique, and equal the
     expected Small list exactly, with no more and no fewer. Every `rc` is 0.
   - The `lane == non-suite` suite events include `tier2:pdda` (`validate.sh:1142`) and
     `python:test_python_layer.py` (`:1454-1461`), each with rc 0.
   - The identity check is the existing `event == stage`, `name == envelope-assert` event (`:1480`), with rc 0.
     It is not a suite event. No telemetry is added (Codex r2, F7).
   - The Python layer actually ran: `total == len(expected) + 3`. The 3 are the always-counted identity check
     (`validate.sh:1514`), the Python layer and `tier2:pdda` (`:1515-1519`). `validate.sh` excludes a skipped
     Python layer from `total`, so the zero-rc skip event at `:1454` cannot satisfy this.
   - `passed == total`, `failed == 0`, `suite_events_match == "yes"`, and `envelope_rc == "0"`, a string as
     written by `test/lib/runner-telemetry.sh:174-175`.
3. **Durable replay** (Codex r1, F2).
   - The receipt entry records `tier: 2`, the gate string `validate.sh --sequential --subsystem small`, and
     the expected list.
   - `qualification_receipt_matches` checks the recorded list against the `SUBSYSTEM_TESTS_small` line of
     `utils/ci-route.sh` **at the tested commit** (`git show <tested>:utils/ci-route.sh`), not at HEAD. It then
     applies rule 2 to the committed telemetry.
   - A later change to the Small list therefore never invalidates, or wrongly validates, an old receipt.
   - Receipts without `tier`, and the `validate.sh --sequential` gate string, match exactly as today.
4. **Atomicity** is unchanged. A failed or incomplete run produces no receipt, and the landing is rolled
   back. `--only-receipted` recovery and the any-match suppression at `:553-555, 2054-2061` stay correct,
   because a landing still has exactly one qualifying entry.
5. **Logging.** The log line names the tier and the gate string.

**D6 — Promotion is unchanged (O8).** The boundary job still runs `validate.sh --sequential`, now the
registry minus the 8 off suites. #831's Decision 2 has the classifier choose at promotion too. This plan
deliberately does not, and records that as O8 for the operator. GH-509 becomes two rules:

- a landing is qualified on hosted macOS by the run D5 selects;
- promotion needs a hosted macOS full-registry run for the exact commit.

**D7 — No new tests, enforced as rules.**

- `AGENTS.md` rule: no new `test/` suites and no new registry entries. Verification uses an existing suite or a
  manual check recorded in `TESTS-RESULTS/`. Existing suites may be edited only to keep them truthful when the
  behaviour they pin changes.
- `GUIDING-PRINCIPLES.md` principle 13: a red control is witnessed on an existing suite or recorded as a
  manual check, never by adding a suite.
- Every R4 (A)/(B) line is rewritten to match.
- The Codex QA briefs in `/start-task` step 8 and `relay-xyz` flag a new test file as a finding.
- `/express`: the skill text says to name the existing suite that covers the fix. `utils/py/express.py` keeps
  `--suite` required and changes only its capture-doc wording, "regression suite registered as the landing
  gate".

## Decisions for the operator

**Confirmed by the operator on 2026-09-25: O1, O2, O3, O4, O7 and O8.** O5 and O6 remain proposals; O5 follows
the no-new-tests rule. Each entry keeps its reasoning.

- **O1 — Pushes keep today's cheap checks for Small and Medium. Default: yes.** The hosted run after the merge
  runs the tier. Running Small at every docs push would cost about 6.5 minutes locally instead of 84 seconds,
  because `gh549` alone takes 6.4.
- **O2 — `gh549-work-events.sh` and `gh436-merge-cleanup.sh` stay in Small. Default: yes, by definition (PRS).**
  They are 10.3 of Small's 17.9 hosted minutes. Moving them to the releases area would make the Small run
  about 7.6 minutes.
- **O3 — Medium suites stay registered, so they also run in Large. Default: yes.** Large is then the registry
  minus off, about 61 minutes. Unregistering them would save about 4.7 minutes on core merges, but it would
  rewrite `gh35` §4's pin, and a Medium area's suites would never run at promotion.
- **O4 — Unmapped non-core code goes to Large, not Medium. Default: yes, fail closed.** An unmapped script has
  no area suites to run.
- **O5 — `/express` keeps a required `--suite` that must name an existing suite. Default: yes.**
- **O6 — PR #811 (a test admission gateway, +21k lines) contradicts "no new gate machinery".** This issue does
  not act on it. Recommend closing it as superseded by #831.
- **O7 — The hosted reconcile qualifies Medium merges with the full run, not Small plus the area. Default: yes.**
  This keeps one run per landing (D5), at the cost of about 43 extra minutes on 1–4 merges a month.
- **O8 — Promotion always runs Large; the classifier is not consulted. Default: yes.** This is a deviation
  from #831's Decision 2, which has the classifier choose at promotion.
  - A promotion covers every merge since the last one: 1,803 commits on 2026-09-25. That range always touches
    core, so the classifier would pick Large anyway.
  - Classifying `main..development` inside `ci.yml` would add machinery to reach the same answer.
  - The promotion run is also the GH-509 witness, the last full check before a release.
  - If the operator wants the literal requirement, the smallest form is a `ci-route.sh` classification of the
    promotion range in the boundary job, with Large for anything but tier 1.

**Expected effect** (hosted sequential; R2, R3): 32–42% of merges qualify through the Small run in about 18
minutes instead of 61. The rest stay at about 61. The average falls from about 61 minutes to about 44–47, or
to about 39–43 with O2's alternative. The per-merge wait for docs, ledger and skill merges is where the change
is felt.

## Phase 1 — Freeze and rules (docs-only PR)

This lands first and alone, so agents see the freeze before the gate change is reviewed.

1. Add the `AGENTS.md` rule and the principle 13 change (D7), and make the R4 (A)/(B) rewrites across the
   root docs and skills. `express.py` waits for Phase 2. So do the (A) lines on full-gate paths:
   `relay-automation/README.md:38-40`, `relay-automation/CONTRACT.example.md:59`,
   `skills/1-hourly/relay-automation/SKILL.md:63`, the `relay-xyz` QA-brief line, and
   `.github/pull_request_template.md:9`.
   - Shared skills say "where the repo forbids new tests (XYZ-forge, GH-831)", because they are deployed
     machine-wide and other repos keep their own policy.
   - `/express`, which exists only here, states the rule unconditionally.
   → expect: `grep` for the R4 phrases in the edited files finds none. The result is recorded in
   `TESTS-RESULTS/2026-09-25+GH-831/`.
2. Cut GH-732's parked ledger row as superseded by #802/#831 with the `releases_app.py roadmap` verbs.
   → expect: `releases check` clean, and the row out of the parked queue.
3. Put a pointer line at the top of #805 and #732 ("superseded, see #802/#831").
4. Push through the hook and open the PR. It runs the tier-2 releases lane, not the docs gate, because the
   branch carries ledger rows; D4's ledger-as-docs routing is Phase 2. Recorded: tier 2 GREEN in 478 s.

**Phase 1 QA gate:** Codex final review of the diff, the docs gate green, `pdda.sh run` 0 errors.

## Phase 2 — Tiers (gate code PR)

The operator confirmed O1–O4, O7 and O8 on 2026-09-25.

1. `utils/ci-route.sh`: add `SUBSYSTEM_TESTS_small` (D2), the Medium list additions (D3), and the D4 docs
   surfaces.
   → expect: `test/ci-route.sh` updated to the new tier table and counts. Recorded red controls:
   - removing a Small member fails it;
   - dropping a D4 exclusion (`merge-cleanup` skill code routed to tier 1) fails it.

   Recorded routing check (Codex r2, F8):
   - `releases.db` alone gives `route=docs`, `tier=1`;
   - `utils/py/releases_app.py` gives tier 2, releases;
   - `releases.db` + `relay-automation/relay-drive.sh` gives tier 3.
2. `validate.sh`: add `small` to the `--subsystem` case for `T2_PYTEST`/`T2_PDDA`, and remove the 8 off entries
   from `TESTS`.
   → expect:
   - `./validate.sh --list` has no off suite;
   - `./validate.sh --sequential --subsystem small`, run in a disposable clone, runs exactly the 73 Small
     suites plus `tier2:pdda`, the Python layer and the identity check.
3. `test/gh306-registry-bidirectional.sh`: the 8 off suites join `EXEMPT` with their reason.
   → expect: green. Recorded red control: an unlisted, unregistered file still fails.
4. `utils/py/wave_reconcile.py`: selection with fail-closed, the tier-2 rule, receipt fields and durable
   replay, and the log line (D5).
   → expect: `test/gh425-gate-provenance-pr.sh` still green, with its tier-3 cases unchanged. Recorded manual
   checks against real Small telemetry from step 2:
   - the complete run qualifies;
   - removing `tier2:pdda` is rejected;
   - deleting or failing the `envelope-assert` stage is rejected;
   - removing the Python event, or substituting the skipped-Python shape, is rejected;
   - a duplicated shell event is rejected;
   - a missing Small suite is rejected;
   - a receipt still matches after a later, unrelated change to `SUBSYSTEM_TESTS_small`;
   - a classifier failure selects the full run.
5. `utils/py/express.py` wording and `/express` skill text (D7).
   → expect: the existing express suite green.
6. Docs:
   - the `ROUTER.md` command rails and tier text (`:65-122`);
   - the `AGENTS.md` GH-509/GH-544 rails (`:168-191`, `:388-397`);
   - the `validate.sh` header (`:15-18`, `:1066-1068`);
   - the `ci.yml` boundary comment.

   → expect: `pdda.sh run` 0 errors.
7. Run the full gate once on the final commit, in a disposable full clone, through the push hook. It routes
   full because `validate.sh` changed.

**Phase 2 QA gate:** Codex final review, the full gate green, and the recorded checks from steps 1–4.

### Phase 2 — what the build found

Evidence is in `TESTS-RESULTS/2026-09-25+GH-831/` (`phase2-*`, `small-run-9ecf2071*`, `provenance.jsonl`).

- **Step 1.**
  - `releases.db` alone gives `route=docs` and `tier=1`, and `utils/py/releases_app.py` gives tier 2 for
    releases. `releases.db` with `relay-automation/relay-drive.sh` gives tier 3.
  - One helper, `is_docs_surface()`, replaces the two copies of the docs-pattern list.
  - Of the tracked non-markdown `skills/` files, exactly 43 move from tier 3 to tier 1
    (`phase2-d4-skill-files-to-tier1.txt`), and no other skill path changes tier.
  - Red controls: dropping a Small member, or the `merge-cleanup` exclusion, turns `test/ci-route.sh` red.
  - **A consequence to know.** A ledger dump no longer counts as releases code for GH-487's co-touch rule. So
    an edit to a releases test that travels with only `releases.sql` now gives tier 3, not tier 2. That is the
    fail-closed direction.
  - `LEADERBOARD.html` and `RELEASES-PREVIEW.html` are not tracked today; the pattern covers them if they are
    ever committed.
- **Step 2.**
  - `./validate.sh --list` has 411 entries and none of the 8.
  - `--sequential --subsystem small` ran in a disposable clone at `9ecf2071`: 73 suites plus `tier2:pdda`, the
    Python layer and the identity check. Result: 76/76, `run_set` 73, 1,233 s, identity unchanged.
- **Step 3.** `gh306` is green with the 8 in `EXEMPT`. An unregistered probe file turns it red.
  - `test/gh35-test-tiers.sh`'s drift fixture now creates subdirectories, because a Medium addition lives at
    `synthetic/gh102-telemetry-schema.sh`. It was red on exactly that before the fix.
- **Step 4.** `phase2_reconcile_check.py` replays the real Small telemetry and passes 19/19. It checks:
  - every rejection the plan lists;
  - that a receipt survives a later change to the Small list;
  - that a receipt with the wrong list, tier or gate does not match;
  - selection: docs and ledger landings pick Small; a batch with a core landing, a missing classifier or an
    unreadable diff picks the full run.

  Two red controls each disable one rule in a scratch copy of the module, and the check turns red. The
  existing `gh425`, `gh740` and `gh421` suites stay green unchanged. `gh425`'s fixture has no classifier and a
  root-commit landing, so it takes the fail-closed full path.
- **Step 5.** `gh267` passes 113/113.
- **Step 6.** `pdda.sh run` reports 0 errors. The `validate.sh` banners at `:1066-1068` ("NEVER promotion
  evidence") stay as they are, because they are still true: the Small run qualifies a landing, not a promotion.
  - The D7 `relay-xyz` review-brief rule is item 7 of its review scope. The five lines Phase 1 deferred are
    rewritten.

## Phase 3 — First hosted evidence

After the Phase 2 merge, its own reconcile runs the full registry, because it touches core. The next
docs-only merge must qualify through the Small run in about 18 minutes, and still produce its receipt and
closeout.
→ expect: both runs' logs name their tier, and their run IDs and durations are recorded here.
If either fails, use the rollback below.

**Phase 3 QA gate:** those two hosted runs, cited by run ID.

## Verification, rollback, blast radius

- **No new tests.**
  - Existing suites are edited only where they pin behaviour this changes: `test/ci-route.sh`, `gh306` and,
    if needed, `gh425`.
  - Red controls are witnessed on those existing suites or recorded as manual checks in
    `TESTS-RESULTS/2026-09-25+GH-831/`.
  - Phase 3 proves the rest on hosted runs.
- **Reversibility: Costly.** This changes what qualifies a merge. A wrong Small list or tier map could let a
  regression land qualified by the Small run.
- **Rollback** (Codex r1, F4).
  - **Trigger:** any one of:
    - a defect found on `development` that the full run would have caught, in a landing the Small run
      qualified;
    - a Small run that proves incomplete;
    - a Phase 3 failure.
  - **Action:** a small forward-fix PR that reverts **only D5's selection**, so `qualify_landings` always
    runs the full registry again. It keeps D5's receipt reader, so every published Small receipt still
    matches.
  - **Check:** the next landing's receipt carries the gate string `validate.sh --sequential`.
  - **A full revert of Phase 2 is not the rollback.** It restores the old matcher (`wave_reconcile.py:473,
    501`), which rejects tier-2 receipts. It is allowed only after every Small-qualified landing has been
    re-qualified with a full run.
  - **Phase 1** is text, and reverts cleanly.
- **Blast radius.**
  - The hosted qualification of every merge and the push route for skill and ledger files.
  - `ci-local.sh`, `ci.yml` and the promotion run lose the 8 off suites from `TESTS`.
  - Vendored `.xyz/` copies get the new lists on their next sync.
  - Installed skills change only when the operator re-deploys through `skills-army-hq`.
