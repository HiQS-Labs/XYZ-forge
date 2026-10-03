---
gh_issue: 836
source: https://github.com/HiQS-Labs/XYZ-forge/issues/836
title: "CI refactor: trim the measured gate hotspots (gh549 race leg and board-dispatch backfills, gh436 parity double-run, gh649 /tmp bug); take the tier decisions on hosted Small numbers"
status: Active — merged (#838); step 6 done; D1 decided (gh436 to Large), implemented and gated, PR ready; awaiting merge; D3 awaits the operator (2-WORKING)
created: 2026-09-26
updated: 2026-09-26
owner: operator (via /start-task)
doc_type: fix
branch: fix/gh836-gate-hotspots
non_goals:
  - New suites, registry entries or gate machinery (AGENTS.md, No new tests).
  - (#838's scope) Moving gh549 or gh436 out of Small. That was D1, the operator's decision on hosted numbers, decided 2026-09-26 and done in its own PR (see "D1 — gh436 to Large").
  - Rewriting gh549 to run in one process, or gh436 on template fixtures (deferred in #836).
  - (#838's scope) Any change to utils/py/releases_app.py, the merge-cleanup scripts, ci-route or the runner (D2's hook default is the one operator-directed exception). D1's PR changes ci-route by operator decision.
related:
  - "#835 — the gate-timing snapshot and its three profiling reviews (closed as completed)"
  - "#831 — the three-tier gate; its Phase 3 hosted Small evidence is recorded (run 36276061201)"
goal: >
  gh549 and gh436, which make up two-thirds of the hosted Small run, get cheaper where the time was measured.
  Every trimmed leg keeps its assertion and red control, and gh649 stops failing falsely under /tmp.
---

# GH-836 — trim the measured gate hotspots

## Status

| What was just completed | What's next |
|---|---|
| D1: plan Approved in round 2 (`86b778d2`) and final QA Approved in round 1 (`12d72667`). Rebased onto `fe2fa18b`; `git range-diff` shows the 9 reviewed patches identical. The full gate is GREEN, 414/414 in 1,049 s, at `4e1ac5e7`. PR opened. The O2 consult transcripts that informed D1 are preserved in `relay-system/2026-09-26/gh831-o2-small-*`. | Operator merge. This PR touches `utils/ci-route.sh`, so its reconcile runs the full registry. The next docs-only landing should show a 72-suite Small run of about 12 min. D3 stays open. |

## Contents

- [Rating](#rating--2026-09-26-70455070-prisevappealeffort)
- [Recon](#recon)
- [Plan](#plan)
- [Verification and evidence](#verification-and-evidence)
- [Decisions for the operator](#decisions-for-the-operator-not-in-this-pr)
- [Risk and rollback](#risk-and-rollback)

## Rating — 2026-09-26: `70/45/50/70` (pri/sev/appeal/effort)

- **Severity 45.** No crash or data loss. The cost is time: `gh549` and `gh436` are about 12 of the hosted Small
  run's ~18 minutes, and every docs, ledger and skill landing pays it.
  - One real defect: `gh649` goes red on any clone under the `/tmp` symlink, a false failure in the gate
    (GLM's red log, `TESTS-RESULTS/2026-09-26+GH-835/full-gate-b2c307b4-tmp-red.log`).
- **Priority 70.** Gate cost is the operator's current focus. The 14-day window (2026-09-12 to 09-26) shows the
  same class repeatedly:
  - #802, #828's 79-minute reconcile failure, #831 and #835;
  - the operator asked for this work directly.

  The window before it (08-29 to 09-11) was not searched, so the trend is **unknown**, not rising.
- **Appeal 50.** Neutral; the operator gave no score.
- **Effort 70.** Cheap: edits to three existing suites, with no routing or runner change. The cost is witnessing
  red controls and taking same-device before/after timings.

## Recon

Base `4bd8851a` (`development`). Baseline evidence is in `TESTS-RESULTS/2026-09-26+GH-836/baseline-*`. It is a
disposable clone at `9c5d294e`, run with the gate's `PATH`, one suite at a time, with identity unchanged
before and after.

**R1 — `gh549` leg 21e's red control is 124.8 s** (`baseline-gh549-top-gaps.txt`, line 1068).

- The red control copies `utils/py/` and mutates `releases_app.py` so the suppression read happens outside the
  write transaction. The mutation inserts `import time as _t; _t.sleep(0.4)` between the read and the write
  (`test/gh549-work-events.sh:1043-1062`).
- Two backfills then race over the full fixture (`:1064-1068`). The fixture is a copy of the real ledger, with
  about 274 roadmap rows.
- The sleep runs on **every** row, so each racer crawls through 274 × 0.4 s ≈ 110 s in lockstep.
- The leg needs only one duplicate (`NBF3 > NROWS`, `:1070`). A race window on the first few rows is enough.
- The positive race itself (`:1038-1041`, two unmutated backfills) costs about 10 s and is not the problem.
- The two racers are launched with a plain `for i in 1 2; do … & done; wait` (`:1068`). Nothing synchronises
  them, and they walk the same ordered rows (`utils/py/releases_app.py:5175`). The per-row sleep is what
  currently absorbs their startup skew (Codex plan r1, S1).

**R2 — two `work backfill` calls with the board connector on cost 68.8 s + 38.0 s** (lines 1127 and 1178,
section 21f).

- `rr` (`:1094`) runs its verb with the github_board connector enabled against the mock board.
- `work backfill` projects every ledger row (`releases work backfill` has no issue filter). Each emit
  dispatches to the connector post-commit (`_dispatch_work_connectors`, `utils/py/releases_app.py:1613`), one
  mock-board subprocess per event.
- Leg 21f's assertions read only `work_events` rows for issues 9920 and 9903 (`:1129-1147`), and its red (iii)
  reads 9920's review_ready count (`:1179-1183`). None of them reads board state.
- `_scan_review_ready` runs before dispatch and derives its suppression from event history, not the cursor
  (`utils/py/releases_app.py:5264-5324`, `:5628-5641`). So advancing the cursor skips only the old board
  replay (Codex plan r1).
- Red (i)'s backfill at `:1159` costs 2.9 s and stays as it is.
- Connector dispatch is covered by legs 12–20. The same `work reconcile` alone, with the cursor at the tail,
  ran in 1 s on a scratch fixture.
- `XYZ_WORK_CONNECTORS=0` skips dispatch (`:1620`) and the review_ready scan (`:5269`). So it may be set only on
  the **backfill** calls, never on the reconcile calls the leg asserts on.
- Afterwards the github_board cursor must advance to the new tail. Otherwise the next `rr … work reconcile`
  replays the whole backlog, and the cost only moves.

**R3 — `gh436`'s parity test is 49.0 s of 292 s** (`baseline-gh436-durations.out`).

- `TestParityGuard.test_skill_md_matches_code_and_tests` calls `parity_failures(..., run_tests=True)`
  (`test/gh534_phase_c_tests.py:928`), which re-runs each script row's named test (`:587-590`).
- A probe loaded `gh436`'s collection (180 tests). All 17 distinct named tests are in it: `gh436` imports
  phases A, B and C with `import *` (`test/gh436-merge-cleanup.py:863-865`), and phase C defines no `__all__`.
  Every named test is therefore collected in the full invocation, and a failing one fails the suite.
  Execution is subject to each test's existing prerequisites: `TestA4OpenHandles` skips without `lsof`
  (`test/gh534_phase_a_tests.py:427-431`), exactly as its nested run does today. The baseline reports no skips.
- No other caller passes `run_tests=True`. The five mutation controls (`:935-966`) call `_fails()`, which
  leaves it off.
- GH-534's spec says the guard "asserts every named test exists and runs"
  (`PROJECT/3-COMPLETED/GH-534-MERGE-CLEANUP-FAILURE-MODES.md:443`). After this change, "runs" is met by the
  suite's own collection. "Exists" stays checked by the guard, against the module globals that collection
  draws from.

**R4 — `gh649`'s `/tmp` false red.** `test/gh649-pdda-migration.sh:4` sets `ROOT` with a logical `pwd`, while
`skills/4-occasional/vendor-stack/find-pdda.sh:22,26` resolves with `cd -P`. On macOS `/tmp` is a symlink, so under it the
equality at `:15` fails. It is witnessed red in GLM's `full-gate-b2c307b4-tmp-red.log`.

**R5 — agy's `relay-self-sufficiency` claim is true** (for D2, not this PR). The pre-push hook runs `validate.sh`
without `RELAY_SELF_SUFFICIENCY_SKIP`, while `ci-local.sh:404` and all three `ci.yml` jobs set it. So each local
full gate makes a real agent call when agy or codex is on `PATH` (`test/relay-self-sufficiency.sh:7-11`).

## Plan

Every step is an edit to an existing suite. Nothing is added to `test/` or the registry. Each red control is
witnessed on the edited suite and recorded under `TESTS-RESULTS/2026-09-26+GH-836/`.

1. **`gh549` 21e red control: a rendezvous, then a short race window.** This changes only the mutated copy's
   inserted text (`:1057-1062`) and its launch line (`:1068`).
   - On its first emit, each racer creates a marker file in a directory named by `GH549_RACE_DIR`, which only
     this leg sets. It then waits, bounded at 10 s, until its peer's marker exists.
   - Both racers then sleep 0.4 s on their first 3 emits, not on every emit. The rendezvous lines them up on the
     same first row, so the window no longer depends on startup skew (Codex plan r1, S1).
   - If the peer never arrives, the wait times out and the racer carries on. The leg's existing duplicate
     assertion (`bad "21e red did not reproduce"`) still judges the outcome. A peer arriving just after the
     timeout can still overlap (Codex plan r2 nit).
   - The unmutated race, its `NROWS` fixture and both assertions are unchanged.

   → expect: green. **Red-control witness, in the disposable clone:**
   - the edited leg reproduces duplication (`NBF3 > NROWS`) with deliberately staggered launches: 0 s, 1.5 s and
     3 s, in both orders, which is beyond the old 1.2 s sleep budget;
   - no racer crashes: each exits 0, or 4 (`EXIT_LOCK_REFUSED`, `utils/py/releases_app.py:91`). The first
     after-run showed that once the racers leave the shared rows, one may lose the writer lock by design. At base,
     the per-row sleep kept them in lockstep and both exited 0, with 550 duplicates against 278 after the
     change. So "both exit 0" was the wrong requirement;
   - the positive `NBF2 = NROWS` holds in the same runs.

   **Fallback, if any offset fails:** keep the existing per-row sleep, and record 21e as untrimmed.
2. **`gh549` 21f: backfill without board dispatch.**
   - Set `XYZ_WORK_CONNECTORS=0` on the `work backfill` calls in 21f and 21f red (iii) (`:1127`, `:1132`,
     `:1141`, `:1178`), and only those.
   - After each, advance the github_board cursor to the current tail. This extends the existing
     `seed_cursor_tail` helper (`:162`) with an optional id, defaulting to `$PRISTINE_TAIL`, so there is no
     second helper.
   - The reconcile calls keep the connector and the PR scan.

   → expect: green, with all 21f assertions unchanged. **Red controls:** 21f red (iii) and red (ii) still
   reproduce. **A witness that the cursor step is load-bearing:** without it, the next reconcile's wall time
   comes back (recorded, not asserted).
3. **`gh436` parity guard: one execution per named test.**
   - `test_skill_md_matches_code_and_tests` stops passing `run_tests=True`.
   - The now-unused `run_tests` parameter and branch are removed from `parity_failures`.
   - A comment records that the suite's own collection runs each named test, and why that holds (`import *`,
     no `__all__`).
   - SKILL.md's description of the guard (`skills/2-daily/merge-cleanup/SKILL.md:213`) already makes no "runs"
     claim, and stays as it is.

   → expect: green. **Red controls:**
   - (a) a SKILL.md row deleted in a scratch copy fails the parity test;
   - (b) a named test forced to fail in a scratch copy still fails the `gh436` suite, now through collection.
4. **`gh649`: `pwd -P` at line 4.**
   → expect: green from a physical path. **Red control:** run it from a clone reached through the `/tmp` symlink,
   not through the physical directory it points to: red before the fix, green after it.
5. **Measure after.** Same device, same procedure as the baseline: `gh549` traced, `gh436` plain and
   `--durations`. The before/after table goes in this doc.
6. **Hosted Small numbers (#836 step 2, #831 Phase 3).** When the first hosted Small run exists, record its run
   ID and duration here and in the GH-831 plan. This may land in a later docs PR if the run comes after this PR
   merges.
   **Found 2026-09-26:** the reconcile's catch-up recovers merged **PRs** only. The scheduled run on the
   direct docs commit `4bd8851a` (run 36255771642) logged `Receipt recovery found 0 pending PR(s)` and
   `Nothing to reconcile`. So a direct push to `development` is never hosted-qualified. This predates the
   tiers, and it is reported to the operator separately. The first hosted Small run therefore needs a docs-only
   PR, such as #833. This PR touches `test/`, so its own reconcile runs the full registry.

7. **D2, decided by the operator on 2026-09-26 and folded in after plan approval: option C.**
   - This follows a `/consult`. Codex recommended C; agy's backend stalled four times, so there was no
     second model. Transcripts: `relay-system/2026-09-26/gh836-d2-*`.
   - `githooks/pre-push` defaults `RELAY_SELF_SUFFICIENCY_SKIP` to 1 on its full-gate `validate.sh` call.
     `=0` opts back in, and calling `validate.sh` directly is unchanged.
   - `test/relay-self-sufficiency.sh`'s header and skip message say what it checks: the fixed fixture, not
     `new-relay.sh`'s template. They also say that four wrappers skip it by default, and that a direct `validate.sh`
     run is unchanged.
   - `relay-automation/README.md` names when a recorded live run is owed:
     - shim or turn-prompt changes, or fixture changes;
     - a `SKIPPED` result does not count;
     - template changes need review evidence of the generated instructions.
   - `relay-pkg.tar.gz` is rebuilt, because the README ships inside it.

   → expect: `gh544-pre-push-gate` and `relay-pkg-freshness` green. **Witness:** the final full gate through
   the real hook logs the suite as skipped by default.
   **Not done here:** rebuilding the fixture from `new-relay.sh`'s output. That would change what the suite
   tests, and needs live runs to prove; agy's backend was down today. It is a follow-up, if the operator
   wants it.

**Expected:** `gh549` from about 346 s to about 130 s and `gh436` from about 292 s to about 243 s, locally.
Hosted Small drops by roughly the same share, from ~18 minutes to ~12–13.

## Results — 2026-09-26

Same device, same procedure, one suite at a time, in disposable clones. The identity check before and after
each run was clean. The evidence is in `TESTS-RESULTS/2026-09-26+GH-836/`: `baseline-*` at `9c5d294e`, and
`after-*` and `witnesses.log` at `4c5ee0bf`.

| Suite | Before | After | Where it went |
|---|---|---|---|
| `gh549-work-events.sh` | 346 s, 124 passed | **147 s**, 125 passed | 21e red control 124.8 s → about 12 s; the 21f backfills 68.8 + 38.0 s → about 10 s each |
| `gh436-merge-cleanup.sh` | 292 s, 180 passed | **239 s**, 180 passed | The parity test (49.0 s) is out of the slowest list |
| `gh649-pdda-migration.sh` | red under a `/tmp` clone | green | `pwd -P` |

The +1 pass in `gh549` is the racers' crash check. Together the two suites fall from 638 s to 386 s locally,
about 4.2 minutes.

**Witnesses** (`witnesses.log`, with the script as `witness-script.sh.txt`):

- **W1, the 21e race under staggered launches** (0, 1.5 and 3 s, both orders): 6/6 pass.
  - Duplicates 277–279 against 275 rows. The positive race is exact at 275 = 275. No racer crashed.
  - In every run one racer exited 4. That is the designed writer-lock refusal (`EXIT_LOCK_REFUSED`,
    `utils/py/releases_app.py:91`), once the racers leave the shared rows. At base, the per-row sleep kept them
    in lockstep, both exited 0 and every row was duplicated (550).
  - The first after-run caught this: the "both exit 0" check I had added failed. The check now fails only on a
    crash, meaning any exit code other than 0 or 4.
- **W2, is the cursor advance load-bearing?** Legs 1–21f take 92 s with the advance and 104 s without it. So the
  backlog replay it avoids is about 12 s, not the ~100 s of the per-event dispatch that step 2 removes. The
  saving comes from turning dispatch off; the advance keeps the reconcile from paying a smaller replay.
  Recorded, not asserted.
- **W3a, a SKILL.md capability row deleted:** the parity test fails with `row missing: teardown-trash-only`
  (rc 1).
- **W3b, a SKILL.md-named test forced to fail:** the registered `gh436` wrapper exits 1 and names
  `TestE6Gate.test_gate_red_prevents_the_merge`. The parity test alone still passes, because it checks
  existence only; execution is the suite's.
  - The first W3b attempt pointed at the wrong module, did not inject, and proves nothing. The log keeps it,
    labelled as such.
- **W4, `gh649` through the logical `/tmp` path:** `4bd8851a`'s version fails with `FAIL - resolver`; the fixed
  version passes.
- **D2:** `gh544-pre-push-gate` 103/103 and `relay-pkg-freshness` 3/3. **Witnessed through the real hook** in the
  final full gate at `290f75e0`: `relay-self-sufficiency.sh` took 0.0 s and printed 207 bytes, the skip message
  (164 s before on this machine).
- **Full gate, run once on the final approved commit:** GREEN, 414/414 in 867 s, from a disposable clone through
  the push hook (`push-gate-290f75e0.log`, telemetry alongside). The Phase 2 gates took 938–944 s.

## Verification and evidence

- Each edited suite is run focused while iterating. The full gate runs **once** on the final approved commit,
  in a disposable clone through the push hook. Test edits route tier 3.
- The PR records same-device before/after numbers. Red-control logs carry exit codes, in `provenance.jsonl`.

## Decisions for the operator (not in this PR)

- **D1:** move `gh436` alone to Large if hosted Small is still over ~12 minutes after this lands.
  - **Hosted numbers (2026-09-26, run [36276061201](https://github.com/HiQS-Labs/XYZ-forge/actions/runs/36276061201)):** Small is 15.7 min (942 s over 75 entries).
    - `gh436` is 221 s (23 %) and `gh549` 159 s (17 %).
    - Without `gh436` it would be about 721 s (12.0 min).
    - `gh436` stays a tier-1 reader: it loads merge-cleanup's `SKILL.md` and `WORKTREE-SAFETY.md`. Moving it
      alone would mean a docs-only change to those files is checked only by the next full run (any tier-2 or
      tier-3 landing's reconcile) or at promotion (O8).
  - **Decided 2026-09-26: move it, with the compensating route below** ("if relatively safe"). See "D1 —
    `gh436` to Large".
- **D2: decided, option C, and folded into this PR as step 7.**
- **D3:** move `gh645` and `gh674` to Large, for tidiness only.

## D1 — `gh436` to Large (operator decision 2026-09-26)

**Why now.** Hosted Small was 15.7 min, over D1's ~12-minute line. `gh436` is its largest suite at 221 s (23 %).
Removing it gives about 721 s (12.0 min).

**Recon at `1eef93a3`.**
- **What `gh436` reads.** Its only tier-1 (docs) inputs are `WORKTREE-SAFETY.md` (`test/gh534_phase_a_tests.py:125`)
  and merge-cleanup's `SKILL.md` (`test/gh534_phase_c_tests.py:523`, the parity guard and drive-loop check).
  Its other real-repo inputs (corrected after Codex plan r1 S1) all route as non-docs, so a landing that changes
  them already takes the full hosted reconcile (tier 2 or 3 → `wave_reconcile.py:589-614`):
  - merge-cleanup code, tier 3 (`utils/ci-route.sh:67`, `test/ci-route.sh:165`);
  - `utils/py/releases_app.py` and `utils/releases-merge-resolve.sh`, which phase B copies into fixtures
    (`test/gh534_phase_b_tests.py:32-33,163-165`): tier 2;
  - `.gitattributes`, copied by the same fixture: tier 3;
  - `bin/tick`, invoked by phase A (`test/gh534_phase_a_tests.py:36,304`): tier 3, `route=full`.
  The fixture ledger and README data are generated inside the fixtures (`gh534_phase_b_tests.py:161-170`).
- **How the two files route today.** Both are docs, tier 1 (`is_docs_surface` rule 1, `*.md`).
- **The gap without a compensating route.** A docs-only landing that edits either file would qualify through
  Small without `gh436`. Only the next full run, or promotion, would check it.
- **How often that happens.** Seven commits touched the two files in the 30 days to 2026-09-26. Only one was
  docs-only (#840, wording); the other six also changed code and took the full gate anyway.
- **Precedence.** `full_required` takes precedence over docs-only in the tier resolution
  (`utils/ci-route.sh:467-471`). Its block comment already names "worktree safety" among the surfaces that
  require the full suite (`:319-321`).

**Change (existing subsystem, existing writer: `utils/ci-route.sh`).**
1. Remove `gh436-merge-cleanup.sh` from `SUBSYSTEM_TESTS_small` (`:38`). It stays registered in `validate.sh`,
   so every full run (Medium and Large reconciles, the full push gate, promotion) still runs it.
2. Add `WORKTREE-SAFETY.md` and `skills/*/merge-cleanup/SKILL.md` to the `full_required` case, with a GH-836 D1
   comment. A landing that touches either now takes the full registry at push and at the reconcile, so
   `gh436` still checks every change to its inputs.
3. `test/ci-route.sh`: only the existing Small pin changes, 73 → 72, with `gh436` absent. That keeps the suite
   truthful about the list it pins (AGENTS.md: "edit an existing suite only to keep it truthful"). The two new
   routings are witnessed as recorded manual probes, not new cases (Codex plan r1 S2).
4. Docs:
   - `ROUTER.md:128-130`, which says skill markdown keeps docs routing except `relay-xyz` and
     `relay-automation`, adds merge-cleanup's `SKILL.md` and `WORKTREE-SAFETY.md` as full-gate files (GH-836 D1);
   - the `CHANGELOG`;
   - this plan's Results.

**Non-goals.** Changing any other suite's tier (D3, `gh645`/`gh674`, stays open); changing `gh436` itself;
changing D2's hook default.

**Verification (no new tests).**
- **V1, the pin, red then green:** run the edited `test/ci-route.sh` against the unedited `utils/ci-route.sh`
  (a scratch copy). The Small-pin assertion must fail (73 listed). Against the edited router the whole suite
  must pass.
- **V2, routing, as recorded manual probes** (`TESTS-RESULTS/2026-09-26+GH-836/d1-routing-probes.log`, with
  provenance):
  - each probe records the command, exit status and non-empty `route=`/`tier=`/`tier_reason=` output;
  - at base: `WORKTREE-SAFETY.md` and merge-cleanup's `SKILL.md` give `route=docs tier=1` (red);
  - after: both, alone and each paired with `README.md`, give `route=full tier=3`, and `README.md` alone stays
    `tier=1`;
  - `subsystems small` lists 72 suites, without `gh436`.
- **V3:** `gh306-registry-bidirectional.sh` and `gh35-test-tiers.sh` pass. They pin the registry and tier
  contracts.
- **V4, the qualifying gate:** the push hook's full gate, once, on the final commit, in a disposable clone. This
  PR touches `utils/ci-route.sh` and a test, so its own reconcile runs the full registry.
- **After merge,** the next docs-only landing's hosted Small run should list 72 suites and take about 12 min.

**Risk.**
- **The cost:** a docs-only landing that edits either file now pays a full gate: about 15 min locally and 57–60
  min hosted. By the 30-day count, that is about one landing a month.
- **More CI:** `route=full` also selects CI's Ubuntu full-registry canary for such a PR (`.github/workflows/ci.yml:480-489`).
  It is advisory, and it is extra runner time, not a new blocker.

**Rollback.** Revert. Old receipts stay valid, because a receipt replays its own recorded list
(`wave_reconcile.py:556`).

**Results (2026-09-26).** Evidence is in `TESTS-RESULTS/2026-09-26+GH-836/`, with `provenance.jsonl`.

| Witness | Result | Evidence |
|---|---|---|
| V1, pin red → green | Edited `test/ci-route.sh` vs the unedited router: rc 1, exactly one FAIL (the Small pin, 73 listed). Vs the edited router: rc 0, 81 pass / 0 fail | `d1-v1-pin-red-green.log` |
| V2, routing probes | Before: all six probes `route=docs tier=1`, and Small is 73 with `gh436`. After: both files, alone and with `README.md`, give `route=full tier=3`; the two controls stay `tier=1`; Small is 72 without `gh436` | `d1-routing-probes.log`, `d1-probes.sh.txt` |
| V3, registry and tiers | `gh306-registry-bidirectional` 10/0, `gh35-test-tiers` 72/0 | `d1-v3-registry-tier-suites.log` |
| V4, the full gate | Through the push hook from a disposable clone at `4e1ac5e7`, rebased onto `fe2fa18b`: **GREEN, 414/414 in 1,049 s**. Re-run ladder 0 suites, runner envelope clean, identity unchanged | `d1-push-gate-4e1ac5e7.log` |

## Risk and rollback

- **Risk: a trimmed leg stops catching what it caught.** Each step witnesses its red control on the edited
  suite, and step 1's race control was run under six staggered launches (W1).
- **Rollback:** revert the PR. It touches test files, the pre-push hook's environment default, the relay README
  and its rebuilt package, docs, the ledger row and evidence. There is no production state to migrate.

## Merge evidence

- PR #838 merged 2026-09-26 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #840 merged 2026-09-26 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #847 merged 2026-09-26 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #848 merged 2026-09-27 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #910 merged 2026-10-01 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #925 merged 2026-10-02 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
