---
title: "merge-cleanup: gate-toolchain fault must not burn a B1 repair slot or hide its cause"
status: "In progress (PR ready; awaiting merge)"
created: 2026-11-25
updated: 2026-11-25
owner: Noel Saw
gh_issue: 1606
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1606
doc_type: bugfix
reported_from: XYZ-forge
harness_commit: b479f74e0
non_goals:
  - changing pre-push gate policy or adding any bypass (`--no-verify`, `XYZ_SKIP_PREPUSH`)
  - changing the 2-repair-per-PR budget or `attempt_record` accounting semantics
  - making merge-cleanup choose or switch the interpreter (no silent venv injection)
  - improving how a genuine gate RED (failing suite) is surfaced after a push
related:
  - 732
  - 711
  - 789
goal: "A B1 repair is never started while the push gate cannot run: the PR is deferred with the named fault, no repair slot is spent, and the dry run warns first."
---

# GH-1606 — merge-cleanup: gate-toolchain fault must not burn a B1 repair slot

## Status

| What was just completed | What's next |
|---|---|
| Plan approved by Codex (round 3). Final Codex QA approved on round 2 after one real finding was fixed in `11ac019c7`. PR #1614 opened; CodeRabbit's PR review then found one more valid finding (a nonzero probe exit with no fault line must not defer), fixed in `06671b514` with a retained red/green control and a fresh end-to-end scenario. | Fresh Codex delta review of the fix, qualification gate and push, CI on the new head, then merge. The ungated phase B breakage is tracked in Issue #1615. |

## Observed problem (measured, not remembered)

Reported from the 2026-11-25 landing of PR #1599. B1 repaired the ledger conflict, then the repaired
head's push was refused by the pre-push gate with an `ENVIRONMENT FAULT`, and merge-cleanup printed
`push refused: utput above.` One of the PR's two repair slots was spent with no head pushed.

| Claim | Command / source | Observed |
|---|---|---|
| The fault is raised by the gate, in one place | `grep -n "ENVIRONMENT FAULT" validate.sh` | `validate.sh:1043`, before any suite runs, `exit 3` |
| A print-only probe of that exact check exists | `bash validate.sh --print-mode` (system `python3` 3.9.6) | rc=3 and the full fault line; no suites run; clone stayed clean |
| Same probe with the test venv first on PATH | `PATH="$HOME/.cache/xyz-forge-test-venv/bin:$PATH" bash validate.sh --print-mode` | rc=0 |
| The slot is reserved before any push precondition on the toolchain | `merge_cleanup.py:2148` `attempt_record.reserve(...)` | reserve precedes B1 (`:2188` `finish(... "resolved")`) and the push (`:2197`) |
| Hook wiring is already checked pre-reserve | `merge_cleanup.py:1094` in `prepare_landing_clone` | `gate_unwired_reason(clone, install=True)` — so wiring is **not** the gap; only the gate's toolchain is |
| The hidden cause | `merge_cleanup.py:1165` | `push refused: {r.stderr.strip()[-400:]}` — the hook's own text says "named in the output above", which the slice drops |
| The slot really was spent | attempt record for PR #1599 after one rerun | two `B1 / resolved` entries; the first never pushed a head |
| No gated suite enters the B1 reserve path | `test/gh436-merge-cleanup.py:43` stubs `gate_unwired_reason`, `:458` mocks `prepare_landing_clone`; `test/gh534_phase_b_tests.py` is not referenced by `validate.sh`/`ci-local.sh`/`test/*.sh` | no suite drives B1 reservation or a toolchain fault |
| Phase B is already red at the clean base (round-1 R1, measured) | `python3 test/gh534_phase_b_tests.py` in a disposable clone at `b479f74e0`, venv PATH | `Ran 39 tests … FAILED (failures=14, errors=1)`; cause `githooks/install.sh is missing … (GH-1576)` |
| Same-class run-start warnings exist | `merge_cleanup.py:1409` `preflight_warnings()`, called at `:2915` | warn-only; no gate-toolchain entry |

## Requirement (issue #1606)

1. A push-gate toolchain fault names its cause in merge-cleanup's own output.
2. It does not consume one of the 2 repair slots.
3. A recorded red control shows both sides: system `python3` → fault named and slot count unchanged; venv on PATH → proceeds.
4. No gate bypass; budget unchanged.

## Root cause vs proximate cause

- **Origin:** the repair slot (a bounded, durable budget) is reserved before the one external
  precondition its payoff depends on — that the pre-push gate can run at all — has been checked.
  The gate refused at its own first step, in 0 s, for a reason unrelated to the repair.
- **Class vs instance:** the Python-version fault is one instance. The class is every *blocking*
  toolchain fault `validate.sh` raises before any suite runs (wrong/old interpreter, missing
  `yaml`/`pytest`/`requests`/`mypy`; today `exit 3`, `validate.sh:1042-1045`). Checking that same
  probe before `reserve` removes that class. **Bounded on purpose (round-1 R2):** the PHP fault is
  *advisory* — `validate.sh:1028-1033` prints it and continues to `exit 0` — so the probe does not
  defer on it, and PHP semantics are untouched. The probe also **fails open** (spawn error or
  timeout → `""`), and `bash validate.sh` can read a non-executable file that the hook rejects
  (`githooks/pre-push:52-55`); those cases are unmeasured and still reach the hook, as today.
- **Fix site = origin** (before `reserve`), not the push site. The push-site message is a
  *symptom*: with the probe in place the detected blocking fault is named at the defer. It does not
  claim to remove every hidden cause (fail-open, advisory and unmeasured cases above remain).

## Plan (smallest bet)

Extends `merge_cleanup.py` only, reusing `validate.sh --print-mode` as the single source of truth
for the toolchain check (no copied module list).

1. **Helper `gate_toolchain_fault_reason(clone) -> str`** beside `gate_unwired_reason` (`~:1049`):
   - `""` when `<clone>/validate.sh` is absent (a consumer repo; its own qualification policy applies);
   - otherwise run `bash validate.sh --print-mode` in the clone with the inherited environment
     (the same PATH the push will use), bounded timeout;
   - rc 0 → `""`; nonzero → every `ENVIRONMENT FAULT` line, joined; a nonzero exit with **no** fault line → `""` (an unrelated failure, or a `validate.sh` that does not know `--print-mode`, is not a toolchain fault and the pre-push hook stays authoritative; CodeRabbit finding on PR #1614);
   - a probe that cannot answer (spawn error, timeout) returns `""` — the pre-push hook stays the
     enforcing authority; this is foresight, not a second gate.
2. **Pre-reserve defer (execute only)** in the B1 branch, immediately before `attempt_record.reserve`
   (`~:2148`), after the existing `--resume` skip: if the helper returns a reason, log it, set
   `failed[p_num] = "deferred: gate toolchain (…)"`, `continue`. Uses the run's existing *deferred*
   vocabulary (exit 3, queue continues, clean PRs still land, hard dependents blocked); no slot is
   reserved; no repair is attempted. A dry run reserves nothing, so it only warns (step 3).
3. **Run-start PRE-FLIGHT warning**: give `preflight_warnings` an optional `primary_repo` argument
   (default `None` → unchanged behaviour for existing callers) and add the helper's reason as one
   more warning, so the dry run says it before `--execute`. The text is labelled **advisory and
   specific to the primary checkout**: `validate.sh`'s linked-worktree guard (`validate.sh:58-94`)
   runs before `--print-mode`, so a primary-side answer does not prove a landing clone's readiness;
   the per-PR check in step 2 is the one that gates reservation. "Dry run writes nothing" means *no
   new writes from this change* — the existing dry run already publishes its selection pin before
   warnings (`merge_cleanup.py:2910-2916`).
4. **SKILL.md**: one sentence in Phase 5 and the PRE-FLIGHT list: a gate-toolchain fault defers the
   PR (exit 3) before a repair slot is spent; fix PATH and re-run.

No change to `attempt_record.py`, `push_resolved_head`, `gate_unwired_reason`, `validate.sh`, or the hook.

## Alternatives considered (ranked)

| # | Alternative | Verdict |
|---|---|---|
| 1 | **Probe before reserve, defer the PR (chosen)** | Fixes the origin; reuses `--print-mode`; spends no slot; fits existing "deferred" semantics |
| 2 | Refund/release the slot when the push is refused | Rejected: changes budget accounting semantics (a non-goal), adds a path where "resolved" ≠ pushed, and still hides the cause |
| 3 | Return exit 2 (stop) instead of defer | Rejected: halts later clean PRs that need no push; a toolchain fault is a deferrable, fixable condition |
| 4 | merge-cleanup injects the test venv onto PATH | Rejected: silently changes which interpreter produces gate evidence; the fault message already prescribes the PATH |
| 5 | Only widen the `[-400:]` slice | Rejected as the fix: treats the symptom, the slot is still spent; kept as a documented non-goal for genuine gate REDs |

## Preflight Bet Check

- **Outcome sought:** an unattended landing never wastes a bounded repair on a push that cannot be gated, and the operator learns why at the dry run.
- **Smallest viable bet:** one helper, one pre-reserve defer, one warning entry, one doc sentence. Not built: interpreter selection, accounting changes, gate-RED surfacing, new tests.
- **Rollback / containment:** revert the single change; the helper fails open (`""`), so a broken probe degrades to today's behaviour.

## Acceptance and red controls (no new tests — AGENTS.md *No new tests*, GH-831)

Evidence lands under `TESTS-RESULTS/2026-11-25+GH-1606/` with `provenance.jsonl`. All runs happen in
disposable full clones, never the primary.

### Measured prerequisite (round-1 R1, verified before revising)

- `test/gh534_phase_b_tests.py` is **already red at the clean base** `b479f74e0`: 39 tests, 14 failures,
  1 error. Cause measured: `landing clone gate wiring failed: githooks/install.sh is missing … (GH-1576)` —
  its `LedgerFixture` seed has no `githooks/`, and GH-1576 patched only `test/gh436-merge-cleanup.py`.
  The suite is not referenced by `validate.sh`, `ci-local.sh` or any `test/*.sh`, so the gate never saw it.
- The gated merge-cleanup suites are `gh436-merge-cleanup.sh`, `gh645-…`, `gh674-…`. `gh436` stubs the
  wiring check (`:43`) and mocks `prepare_landing_clone` (`:458`), so **no gated suite enters the B1
  reserve path**.
- Consequence: phase B is **not** a "stays green" witness, and the red control cannot be a PATH-only rerun of
  its existing fixture. The phase B breakage is a separate, pre-existing defect (out of scope here; recorded
  for triage, not fixed in this PR).

### Manual driver — `TESTS-RESULTS/2026-11-25+GH-1606/run_controls.py` (not a suite, not registered)

Same shape as the GH-1597 controls driver. It reuses `LedgerFixture` (bare origin, seeded ledger, primary
clone, `gh` stub) and derives its PR setup from the existing scenario
`TestPhase5EndToEnd.test_two_prs_second_conflicts_after_first_lands_and_b1_resolves_it`
(`test/gh534_phase_b_tests.py:421`) — a real B1 repair, a real push to the fixture's bare origin, and a
landing, which fails at base *only* because the seed lacks the installer (measured above). It adds two
**declared controlled seams** to the seed commit on `development`, before the PR branch is cut (the shim is
committed executable, `git update-index --chmod=+x`):

1. `githooks/install.sh` stub — `--check` and bare run exit 0. Stands in for real wiring; the real wiring
   refusal is witnessed by `TESTS-RESULTS/2026-11-21+GH-1576/`.
2. `validate.sh` shim — `--print-mode` exits 3 and prints a line beginning `ENVIRONMENT FAULT:` when
   `$GH1606_TOOLCHAIN=fault`, else exits 0 silently. Stands in for the toolchain only; the **real**
   `validate.sh --print-mode` behaviour is witnessed on the real task clone (AC-1).

**Push seam (round-2 R1 correction).** The fixture's `gh` stub reads the PR head from the origin branch
(`test/gh534_phase_b_tests.py:74-79`), and after the push `merge_cleanup.py:2213-2226` waits for that head to
equal B1's commit and returns exit 2 otherwise — so a return-only `(True, "pushed")` stub could never land.
Therefore: for the incident reproduction (S1) the driver uses a counting refusal stub returning
`(False, "push refused: utput above.")`; for every **healthy** run it uses a counting wrapper that **delegates
to the real `push_resolved_head`** against the fixture's local bare origin (the installer stub installs no
real hook, so this is a plain push, and `gate_unwired_reason` passes via the stub's `--check`). Before a
healthy run is accepted as landed the driver asserts the origin branch SHA is non-empty **and equals the
repaired commit recorded in the attempt record**, and that the fixture reports the PR `MERGED`. Every
scenario runs twice with identical inputs
— once against the BASE script directory (a clone at `b479f74e0`) and once against the CANDIDATE — selected
by an explicit script-directory argument. Per run the driver records: exit code, full stderr, whether
`routing to B1` and any `B1:` lines appear, the attempt count **loaded from the record file** (absent file is
reported as `absent`, never as `0`; it is accepted only where the scenario expects it), the origin PR branch
SHA before and after (`git ls-remote`), and the push-wrapper call count. The driver captures **stdout and
stderr**: `routing to B1` and `B1:` lines are written by `log` to stdout (`merge_cleanup.py:444-445`), whereas
`LedgerFixture.run_main` captures only stderr (`test/gh534_phase_b_tests.py:262-269`), so the driver runs
`merge_cleanup.main()` under its own `redirect_stdout` and `redirect_stderr`.

| ID | Scenario (identical inputs for BASE and CANDIDATE) | Unchanged / unfixed candidate is rejected because | Expected (candidate) |
|---|---|---|---|
| AC-1 | Real task clone, real `validate.sh`: helper under system `python3`, then under the venv PATH | On BASE the helper does not exist (`AttributeError`) — recorded as the base red; a helper that returns `""` under the fault fails the check | system → nonempty, contains `ENVIRONMENT FAULT`; venv → `""` |
| AC-2 (central) | S1/S2: conflicting disjoint-ledger PR, toolchain fault, push stub refusing | BASE (S1) must show: exit 2, `routing to B1`, attempts == 1, push stub called once, **fault text absent** from output — that is the incident. A candidate that still reserves fails S2 | S2: exit 3; stderr names `ENVIRONMENT FAULT` and `deferred: gate toolchain`; `routing to B1` present, no `B1:` lines; record `absent` or `attempts == []`; push stub 0 calls; origin branch SHA unchanged |
| AC-3 | S3 healthy toolchain; S4 fault run then `--resume --execute` with toolchain fixed; S5 no `validate.sh` in the clone (consumer shape); S7 `--resume` with the record at the 2-repair ceiling under fault | A candidate that changes the healthy path, spends/loses a slot across the resume, or probes before the resume skip fails one of these | S3: BASE == CANDIDATE (PR `MERGED`, attempts == 1, exactly one real push, origin SHA == the record's repaired commit); S4: second run lands the same way, total attempts == 1; S5: BASE == CANDIDATE; S7: `previously parked`, record unchanged (the 2-attempt ceiling record is created through the `attempt_record` writer, not hand-written JSON) |
| AC-4 | S6 dry run under fault, then healthy | A missing warning, a warning under a healthy toolchain, or any new write fails | fault: `PRE-FLIGHT:` line naming the fault, no attempt record, no new writes beyond the existing selection pin; healthy: no such line |
| AC-5 | Existing gated suites: `gh436-merge-cleanup.sh`, `gh645-…`, `gh674-…` run through the classified gate | Any regression | all green; phase B explicitly **not** used as a witness (red at base) |
| AC-6 | `SKILL.md` carries one sentence on the deferral and the PRE-FLIGHT entry, read from the consumer entry (Phase 5 / PRE-FLIGHT paragraph) | Missing or contradictory text | present and consistent with exit-3 / deferred vocabulary |

Non-vacuity rule for every row: a claimed named output must be **non-empty** and quoted; missing output is a
failure, never a pass, and "no attempts" is accepted only as an asserted `absent` or a loaded `attempts == []`.

Guarantees touched and how each is attacked: the 2-repair cap (S4, S7), `--resume` skip (S7), hard-dependent
blocking (the deferred PR enters the existing `failed` map; S2 asserts the end-of-run summary names it),
dry-run purity (S6), consumer repos without `validate.sh` (S5), healthy B1 behaviour (S3).

## Smoke (Step 7, GH-1088)

Main path: dry run of a real conflicted PR shape under system `python3` (warning appears) and under the venv
(no warning). Adjacent path: `--execute` under the fault (deferred, exit 3), then the same run again with the
PATH fixed — the deferred PR is repaired and lands using the same budget it would always have had
(attempts 0 → 1). Recorded under `TESTS-RESULTS/2026-11-25+GH-1606/`.

## Risks and accepted tradeoffs

- **Conservative deferral (round-1 R3, accepted).** The probe is unconditional, but the hook chooses its own
  route: a docs route skips `validate.sh` (`githooks/pre-push:390-395`) and an exact-commit receipt can skip
  it too (`:421-440`). A B1 repair whose push would have taken one of those routes can therefore be
  *falsely* deferred under an old interpreter. Consequence: exit 3 with a named fix, **no slot spent**, re-run
  after the PATH fix — strictly milder than today's spent slot. Not measured on a real docs-route push. The hook's
  classifier is deliberately **not copied** (DRY, and it would drift); same PATH is supported by
  `merge_cleanup.py:1155-1163`, but identical PATH does not establish identical route.
- **Probe cost:** a toolchain probe only; bounded by timeout; run once per conflicted PR on the execute path.
- **A PR that edits its own `validate.sh`:** the probe reads the PR's version, as the hook will — consistent.
- **Untraced:** callers of `preflight_warnings` outside `merge_cleanup.py` (none found by grep in `skills/`, `utils/`).

## Decisions after plan QA round 1

| Finding | Disposition |
|---|---|
| R1 [Blocker] red control not runnable as written | **Accepted.** AC-2 rewritten as the manual driver above; phase B withdrawn as a witness after measuring it red at base |
| R2 [Should] "whole class" overstated | **Accepted.** Class bounded to blocking toolchain faults; PHP stays advisory; fail-open and unmeasured cases stated |
| R3 [Should] probe is conservative | **Accepted.** Tradeoff recorded; hook classifier not copied |
| Round 2 R1 [Blocker] (open item) healthy push seam cannot land | **Accepted.** Verified: fixture head comes from the origin branch (`:74-79`) and `merge_cleanup.py:2213-2226` stops with exit 2 on a head mismatch. Healthy runs now delegate to the real `push_resolved_head`; S1 keeps the refusal stub; the published head must equal the recorded repaired commit; stdout is captured |
| Round 2 passes (R2, R3, Q3-4, Q5, Q7-8) | Kept unchanged. |
| Passes (Q1/3/4, Q2/4/6, Q6/7/8) | Kept. Taken: advisory/primary-specific warning label; "no *new* writes"; qualify "all hidden causes"; defer over stop; truncation stays out of scope; effort 25→70 correction stands |

## Open questions for the reviewers (round 3)

1. With the healthy path now delegating to the real `push_resolved_head` and asserting the published head equals the recorded repair, does the driver still have any path where an unchanged candidate is reported as delivered?
2. Is anything else in the S1–S7 set unrunnable on `LedgerFixture` plus the two declared seams?

## Per-issue rating (RELEASES vocabulary, `rated pri/sev/appeal/effort`, 1–100)

`55/55/50/70` — 2026-11-25. Severity: wastes 1 of 2 bounded repairs and can park a landable PR after a non-defect refusal; recoverable, no data loss. Priority follows severity and the fact that it fired in the live landing loop. Appeal 50 (neutral; no user preference). Effort is **cheapness** (high = easy): ~70 for one helper plus a defer. Recurrence: one incident in the window; trend unknown (no same-class issue found in the prior-art scan); no downgrade inferred. Correction: the filed issue's PRS line shows `effort 25`, which inverted the axis; this row supersedes it.

## Lessons learned

NO_ENTRY. The evidence is one incident and one fix; the generalizable claims (probe preconditions before spending a bounded budget; do not assume a gate prints a single fault line) rest on a single run each, which the admission rule treats as `confounded`, and adoption or a merge is not evidence. Revisit if the same shape recurs.

## Recon ledger

- `prior_art_recon.py --query "merge-cleanup push refused ENVIRONMENT FAULT repair slot"`: 0 open PRs, 0 merged, no `existing_fix_candidates`.
- Code traced at base `b479f74e0`: `reserve` `:2148`, `finish` `:2188`, push `:2197`, `push_resolved_head` `:1142`, tail slice `:1165`, hook wiring `:1094`, `preflight_warnings` `:1409`/`:2915`.
- Correction recorded: an early reading of the file predated PR #1599's own edits to it; all line numbers above are re-read at the clone base.
- Correction recorded: hook wiring is already pre-reserve, so the class is "gate toolchain", not "any push precondition".
- Plan QA round 1 (Codex, 2026-11-25): VERDICT FAIL → R1/R2/R3 accepted. Verified R1 empirically before accepting: a single existing phase B end-to-end test run in a disposable clone at base failed with the GH-1576 missing-installer refusal; the full phase B file then measured 39 tests, 14 failures, 1 error. Gated merge-cleanup suites located in `validate.sh` (`gh436`, `gh645`, `gh674`).
- Round-1 review paraphrase (written from the artifact only) matched the plan's intent; no comprehension mismatch to adjudicate.
- Plan QA round 2 (Codex, 2026-11-25): VERDICT FAIL on a single item (healthy push seam). Verified against `merge_cleanup.py:2213-2226` and the fixture's `view()` (`test/gh534_phase_b_tests.py:74-79`) before accepting; derived the driver from the existing disjoint-B1 landing scenario at `:421`. All other round-2 findings were `[Pass]`.
- Feasibility measured before round 3: in a disposable clone at base `b479f74e0`, applying only the wiring seam (`merge_cleanup.gate_unwired_reason = lambda clone, install=False: ""`, the same stub `test/gh436-merge-cleanup.py:43` uses) makes the existing scenario `TestPhase5EndToEnd.test_two_prs_second_conflicts_after_first_lands_and_b1_resolves_it` pass end to end: `attempt 1/2 reserved (script, rung B1, head 5629dff0c3)`, B1 repair `rc=0`, real push `pushed d55922402c to feat/b`, both PRs `MERGED`, `Ran 1 test … OK`. So the healthy path through the real `push_resolved_head` is runnable on `LedgerFixture`.

## Decisions after the PR review (CodeRabbit, PR #1614)

| Finding | Disposition |
|---|---|
| Inline, minor: a nonzero `validate.sh --print-mode` exit with no `ENVIRONMENT FAULT` line returns the output tail and defers the PR (plan line 84 said the same) | **Accepted and fixed** in `06671b514`: return `''`, the pre-push hook stays authoritative. Consistent with this plan's own rule that a probe which cannot answer is skipped. Codex's final QA had accepted the fallback; the two reviewers disagreed and the stricter rule was chosen on the plan's own principle. Retained controls: `AC-1-nofault-red/green` and `AC-3-S8-*` in `provenance.jsonl`. |
| Description check: PR body did not follow the template's checkbox sections | **Accepted**: PR body rewritten to the template. (The template's `check_machine_paths.py` does not exist in this repo; the real check is `pdda.sh hardcoded-paths`, which passes.) |
| Walkthrough and pre-merge checks | All four passed; no finding. |
