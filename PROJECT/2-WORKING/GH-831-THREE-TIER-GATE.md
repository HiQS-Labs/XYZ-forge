---
gh_issue: 831
source: https://github.com/HiQS-Labs/XYZ-forge/issues/831
title: "GH-831: no new tests, and three gate tiers (Small/Medium/Large) chosen by ci-route for push, per-merge reconcile and promotion; non-core suites off"
status: Active — plan under Codex review (2-WORKING)
created: 2026-09-25
updated: 2026-09-25
owner: operator (via /start-task)
doc_type: feature
branch: feat/gh831-three-tier-gate
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
  Medium (Small + the touched area's suites) for mapped non-core code, Large (Small + core suites) for the
  core harness. utils/ci-route.sh picks the tier for the push hook, the hosted reconcile after each merge,
  and promotion. Suites outside those sets are off, and agents stop adding tests.
---

# GH-831 — no new tests; three gate tiers; non-core suites off

## Status

| What was just completed | What's next |
|---|---|
| Recon done on base `37038841`: every registered suite mapped, a month of merges projected onto the tiers, gate mechanics traced, and every instruction that asks for new tests inventoried. Plan written. | Codex plan review (relay), then Phase 1. |

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
not restate them. Operator answers taken on 2026-09-25:

- Medium = mapped non-core code.
- "Off" = unregistered, files kept.
- Enforcement = rules and skill text only.
- Sequencing = issue + plan after #821.

**Rating `rated 85/70/75/40` (2026-09-25).**

- **Severity 70.** Every merge waits for a 61–76-minute hosted run, and a red in any suite withholds the
  merge's closeout. That is work-blocking but recoverable; nothing is lost, so it sits below the crash and
  corruption band.
- **Priority 85.** The operator asked for this now, and it gates every other merge.
- **Appeal 75.** An interpretation of the operator's stated preference ("we have to start to enforce adding no
  more tests", "radical refactoring"), not a score they gave.
- **Effort 40.** It touches `validate.sh`, `utils/ci-route.sh`, `githooks/pre-push`, `utils/py/wave_reconcile.py`,
  `utils/py/express.py`, several existing suites that pin today's behaviour, the root rules, and about 20
  skills. That is one to two days.

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
    `utils/py/*`, any other unmapped path, and any `test/` edit (`utils/ci-route.sh:296-455`).
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

**R2 — Suite map (419 registered; hosted sequential minutes from run `a0345e9c`).**

| Class | Suites | Minutes | Notes |
|---|---:|---:|---|
| Small: PDDA | 15 | 3.4 | `SUBSYSTEM_TESTS_pdda` |
| Small: PRS | 31 | 12.7 | `SUBSYSTEM_TESTS_releases` + merge-cleanup/reconcile suites; `gh549-work-events.sh` 6.4 and `gh436-merge-cleanup.sh` 3.9 |
| Small: canaries | 15 | 1.2 | #816's blast-radius list + #802's static guards |
| Core | 264 | 33.2 | the suite's code references core harness paths |
| Medium (subsystem-owned) | 31 | 4.2 | hq 13, ate 9, telemetry 4, skills-army-hq 2, agent-chorus, standup, swe-diagram |
| Needs a call | 54 | 5.7 | reference signals and subject disagree; proposed dispositions below |
| Off (clear) | 9 | 0.5 | skill-text or skill-feature only |

Proposed dispositions for the 63 "needs a call" and "off" suites. `suite-map.tsv` is the per-suite source,
and a `disposition` column is added in Phase 2.

- **Core (~30):** consult, tick, relay containment, driver lock, vendoring, turn-timeout, pre-push and
  gate suites: `consult.sh`, `gh308-consult-guards`, `gh610-claude-subscription`, `gh554-tick-unknown-flags`,
  `gh410-*`, `gh417-*`, `gh218-*`, `gh124-*`, `gh129-*`, `gh130-*`, `gh131-*`, `gh648-l3/l4`, `synthetic/gh101-*`,
  `synthetic/synthetic-claude-target-root`, `gh293-*`, `gh353-*`, `gh396-*`, `gh460-*`, `gh514-*`, `gh528-*`,
  `gh591-*`, `gh681-*`, `gh123-*`, `gh369-*`, `gh609-*`, `registry-lock-concurrency`, `fixtures/canary-token-reuse`,
  `jog-queue`, `sentinel-overlay`.
- **Small (12):**
  - PRS: `gh75`, `gh107`, `gh349`, `gh351`, `gh360`, `gh424`, `gh491`, `gh492-roadmap-state-sweep`, `gh527`,
    `gh605-*`.
  - PDDA: `gh784-marathon-qa-gate`, which tests `pdda.sh marathon-qa`.

  Together these add under a minute.
- **Medium, joining an existing subsystem list:**
  - ate: `gh142-ate-exit-contract`, `synthetic/gh102-telemetry-schema`.
  - agent-chorus: `agent-chorus-bridge`, `gh233-agent-chorus-concurrency`.
  - skills-army-hq: `gh589-xyz-mini-sync`, `gh589-consult-no-tick`, `gh589-skill-viewer`. These are the
    spin-off publishers, alongside #830's gh620.
- **Off (~12):** tests of skill text and skill features: `gh578-ci-optimize-skill`,
  `gh778-review-code-skill`, `gh798-status-skill`, `gh779-radar-ci-health`, `gh781-wam-radar-seed`,
  `gh777-start-task-prior-art`, `gh615-*`, `gh616-*`, `gh617-*`, `debug-mantra.sh`, `gh132-review-xyz-skill`.

**R2 finding: turning suites off saves almost no time.** This repo's suites overwhelmingly exercise its own
harness. Once the calls above are made, "off" is about a dozen suites and seconds of runtime. Its value is less
flake surface and no skill-text churn, not speed. The name-based estimate in #802 and #831 (~180 off) was
wrong. The time lever is routing.

**R3 — Merge projection.** The 146 squash merges on `development` since 2026-08-26 were classified with
their `test/` and evidence edits removed, as in a world with no new tests:

| Projected tier | Merges | Share |
|---|---:|---:|
| Small | 68 (48 docs/ledger/views, 17 skill code, 3 PDDA/releases code) | 47% |
| Medium | 1 | 1% |
| Large | 77 | 53% |

Small runs about 17 minutes hosted sequentially against 61 for the full suite today. Large is about 54 minutes:
Small plus core, without the Medium-owned and off suites. The per-merge saving concentrates on the 47%.

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
| Hosted reconcile after each merge (qualifies the landing) | `validate.sh --sequential --subsystem small` | `--subsystem small`, then `--paths-file` (the area's suites) | `validate.sh --sequential` |
| Promotion (`ci.yml` boundary on `main`) | — | — | `validate.sh --sequential` (unchanged) |

`utils/ci-route.sh` picks the tier at every boundary.

- **Push hook.** It keeps its current cheap form for Small and Medium (O1). It already runs the full registry
  for Large.
- **Hosted reconcile.** It runs each tier's full definition. That run is what qualifies a merge.

**D2 — Small is data.** `SUBSYSTEM_TESTS_small` in `utils/ci-route.sh` lists the 61 Small suites (PDDA, PRS,
canaries), plus R2's 12 reclassified Small suites. It is the one definition of Small.

- `validate.sh --subsystem small` already runs any listed subsystem through the tier-2 path.
- The only `validate.sh` edit is adding `small` to the `--subsystem` case that sets `T2_PYTEST`, and having it
  also run the PDDA docs gate (`T2_PDDA=1`).
- `subsystem_of()` claims no paths for `small`, so path classification is unchanged.

**D3 — Registry.**

- `TESTS` keeps every Small, core and Medium suite. The Medium suites stay registered, so `gh35` §4 holds;
  see O3.
- The ~12 off suites are removed from `TESTS`, and their files stay in `test/`.
- The off suites join `gh306`'s existing `EXEMPT` list, and that list's rule comment gains a second reason:
  "turned off by operator decision (GH-831)". That list is the one place off is recorded. There is no
  second list.
- R2's Medium reclassifications join their areas' `SUBSYSTEM_TESTS_*` lists: `gh589-*` to skills-army-hq,
  `gh142`/`gh102` to ate, and `agent-chorus-bridge`/`gh233` to agent-chorus.

**D4 — Classifier (`utils/ci-route.sh`).** Unmapped, non-core skill files and ledger or data files join the
docs surfaces, so they route to tier 1 and route=docs:

- skill files: `skills/**` except `relay-xyz`, `relay`, `relay-automation`, `merge-cleanup`, `express`, `jog`,
  and paths a subsystem claims;
- ledger and data files: `releases.db`, `releases.sql`, `harnesses.db`, `harnesses.sql`;
- generated views: `LEADERBOARD.html`, `RELEASES-PREVIEW.html`.

The push hook, CI's route and `--auto` all follow automatically.

- A ledger-only push drops from the 24-suite releases lane to the docs gate. The hosted Small run, which
  includes those suites, qualifies the merge.
- Everything that fails closed today still fails closed to tier 3: core surfaces, unmapped code, test edits,
  and empty diffs.

**D5 — The hosted reconcile qualifies by tier (`utils/py/wave_reconcile.py`).**

1. `qualify_landings` unions the pending landings' diffs (`mergeCommit^..mergeCommit`) and classifies them in
   the qualification clone with `bash utils/ci-route.sh push`.
   - Tier 1 runs `--sequential --subsystem small`.
   - Tier 2 runs that, then `--sequential --paths-file <diff>`.
   - Tier 3 runs `--sequential`, as today.
   - A classifier that cannot run means tier 3.
2. `qualification_summary` keeps its tier-3 rules unchanged. It accepts a tier-2 run only when every one of
   these holds:
   - `mode` is sequential and `tier` is 2.
   - The suite event names equal the expected list exactly: `ci-route.sh subsystems small` for the Small run,
     and the classifier's `tier2_tests` for the area run.
   - Every `rc` is 0, `failed` is 0, and `passed` equals `total`.
   - `envelope_rc` is 0 and `suite_events_match` is yes.
   - The Python-layer event is present whenever the lane selected it.
3. Each run's receipt entry records `tier` and its exact gate string. `qualification_receipt_matches` accepts
   `validate.sh --sequential` as before, and also the two new gate strings with their tier-2 rules. Old
   receipts match unchanged.
4. The log line names the tier and its gate strings.

**D6 — Promotion is unchanged.** The boundary job still runs `validate.sh --sequential`, now the registry
minus the off suites. GH-509 becomes two rules:

- a landing is qualified by its classified tier on hosted macOS;
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

Each has a default, so the work can proceed. Say otherwise to change it.

- **O1 — Pushes keep today's cheap checks for Small and Medium. Default: yes.** The hosted run after the merge
  runs the full tier. Running Small at every docs push would cost about 6.5 minutes locally instead of 84
  seconds, because `gh549` alone takes 6.4 minutes.
- **O2 — `gh549-work-events.sh` and `gh436-merge-cleanup.sh` stay in Small. Default: yes, by definition (PRS).**
  They are 10.3 of Small's 17.2 hosted minutes. Moving them to the releases area would make Small about
  7 minutes for 47% of merges.
- **O3 — Medium suites stay registered, so they also run in Large. Default: yes.** Large is then the registry
  minus off, about 60 minutes, close to today's 61. Unregistering them would save about 4 minutes on core
  merges, but it would rewrite `gh35` §4's pin, and a Medium area's suites would then never run at promotion.
- **O4 — Unmapped non-core code goes to Large, not Medium. Default: yes, fail closed.** An unmapped script has
  no area suites to run.
- **O5 — `/express` keeps a required `--suite` that must name an existing suite. Default: yes.**
- **O6 — PR #811 (a test admission gateway, +21k lines) contradicts "no new gate machinery".** This issue does
  not act on it. Recommend closing it as superseded by #831.

**Expected effect** (hosted sequential, from R2 and R3): the 47% of merges that are docs, ledger or skill-only
qualify in about 17 minutes instead of 61. They would take about 7 minutes under O2's alternative. The 53% of
merges that touch core stay at about 60. The average per merge falls from about 61 minutes to about 40.

## Phase 1 — Freeze and rules (docs-only PR)

This lands first and alone, so agents see the freeze before the gate change is reviewed.

1. Add the `AGENTS.md` rule and the principle 13 change (D7), and make the R4 (A)/(B) rewrites across the
   root docs and skills. `express.py` waits for Phase 2.
   → expect: `grep` for the R4 phrases in the edited files finds none. The result is recorded in
   `TESTS-RESULTS/2026-09-25+GH-831/`.
2. Cut GH-732's parked ledger row as superseded by #802/#831 with the `releases_app.py roadmap` verbs.
   → expect: `releases check` clean, and the row out of the parked queue.
3. Put a pointer line at the top of #805 and #732 ("superseded, see #802/#831").
4. Push through the hook (docs gate) and open the PR.

**Phase 1 QA gate:** Codex final review of the diff, the docs gate green, `pdda.sh run` 0 errors.

## Phase 2 — Tiers (gate code PR)

1. `utils/ci-route.sh`: add `SUBSYSTEM_TESTS_small` (D2), the Medium list additions (D3), and the docs-surface
   additions (D4).
   → expect: `test/ci-route.sh` updated to the new tier table and counts. Recorded red control: removing a
   Small member or reverting a D4 path makes it fail.
2. `validate.sh`: add `small` to the `--subsystem` case for `T2_PYTEST`/`T2_PDDA`, and remove the off entries
   from `TESTS`.
   → expect: `./validate.sh --list` has no off suite, and `./validate.sh --sequential --subsystem small` runs
   exactly the Small list.
3. `test/gh306-registry-bidirectional.sh`: the off suites join `EXEMPT` with their reason.
   → expect: green. Recorded red control: an unlisted, unregistered file still fails.
4. `utils/py/wave_reconcile.py`: tier selection, fail-closed, the tier-2 summary rules, receipt fields and
   matcher, and the log line (D5).
   → expect: `test/gh425-gate-provenance-pr.sh` still green with its tier-3 cases unchanged.
   Recorded manual checks:
   - a docs-only landing qualifies through the Small run;
   - a Small run missing one suite does not qualify;
   - a classifier failure falls back to tier 3.
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

**Phase 2 QA gate:** Codex final review, the full gate green, and the recorded red controls.

## Phase 3 — First hosted evidence

After the Phase 2 merge, its own reconcile runs tier 3, because it touches core. The next docs-only merge must
qualify through the Small run in about 17 minutes, and still produce its receipt and closeout.
→ expect: both runs' logs name their tier, and their run IDs and durations are recorded here.

**Phase 3 QA gate:** those two hosted runs, cited by run ID.

## Verification, rollback, blast radius

- **No new tests.**
  - Existing suites are edited only where they pin behaviour this changes: `ci-route.sh`, `gh306` and,
    if needed, `gh425`.
  - Red controls are witnessed on those existing suites or recorded as manual checks in
    `TESTS-RESULTS/2026-09-25+GH-831/`.
  - The rest of the behaviour is proven by the Phase 3 hosted runs.
- **Reversibility: Costly.** This changes what qualifies a merge. A wrong Small list or tier map could let a
  regression land qualified by Small.
  - **Phase 2:** rollback is reverting its PR, which returns every merge to the full run. Receipts written
    under it stay valid, because the matcher keeps accepting them.
  - **Phase 1:** text only, and it reverts cleanly.
- **Blast radius.**
  - The hosted qualification of every merge and the push route for skill and ledger files.
  - `ci-local.sh`, `ci.yml` and the promotion run lose the off suites from `TESTS`.
  - Vendored `.xyz/` copies get the new lists on their next sync.
  - Installed skills change only when the operator re-deploys through `skills-army-hq`.
