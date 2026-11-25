---
title: "merge-cleanup: gate-toolchain fault must not burn a B1 repair slot or hide its cause"
status: "In progress (plan QA pending)"
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
| Fresh task clone, issue #1606 registered, recon done, plan drafted. | Codex plan QA via relay-xyz; then implement the reviewed scope. |

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
| Existing coverage pins neighbours, not this | `test/gh534_phase_b_tests.py` mocks `push_resolved_head`; `test/gh436-merge-cleanup.py:43` stubs `gate_unwired_reason` | no suite drives a toolchain fault |
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
- **Class vs instance:** the Python-version fault is one instance. Any gate-runnability fault
  (missing modules, broken `php`, wrong interpreter) reaches the same spend-then-refuse ordering.
  Checking the gate's own toolchain probe before `reserve` removes the whole class.
- **Fix site = origin** (before `reserve`), not the push site. The push-site message is a
  *symptom*: with the probe in place the fault is named at the defer, so the truncation can no longer hide it.

## Plan (smallest bet)

Extends `merge_cleanup.py` only, reusing `validate.sh --print-mode` as the single source of truth
for the toolchain check (no copied module list).

1. **Helper `gate_toolchain_fault_reason(clone) -> str`** beside `gate_unwired_reason` (`~:1049`):
   - `""` when `<clone>/validate.sh` is absent (a consumer repo; its own qualification policy applies);
   - otherwise run `bash validate.sh --print-mode` in the clone with the inherited environment
     (the same PATH the push will use), bounded timeout;
   - rc 0 → `""`; nonzero → the first `ENVIRONMENT FAULT` line, else the output tail with the rc;
   - a probe that cannot answer (spawn error, timeout) returns `""` — the pre-push hook stays the
     enforcing authority; this is foresight, not a second gate.
2. **Pre-reserve defer (execute only)** in the B1 branch, immediately before `attempt_record.reserve`
   (`~:2148`), after the existing `--resume` skip: if the helper returns a reason, log it, set
   `failed[p_num] = "deferred: gate toolchain (…)"`, `continue`. Uses the run's existing *deferred*
   vocabulary (exit 3, queue continues, clean PRs still land, hard dependents blocked); no slot is
   reserved; no repair is attempted. A dry run reserves nothing, so it only warns (step 3).
3. **Run-start PRE-FLIGHT warning**: give `preflight_warnings` an optional `primary_repo` argument
   (default `None` → unchanged behaviour for existing callers) and add the helper's reason as one
   more warning, so the dry run says it before `--execute`.
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

Evidence lands under `TESTS-RESULTS/2026-11-25+GH-1606/` with `provenance.jsonl`; checks run in a
disposable full clone, never the primary.

| ID | Check | Fails when | Red control |
|---|---|---|---|
| AC-1 | `gate_toolchain_fault_reason(clone)` with system `python3` returns the `ENVIRONMENT FAULT` line; with the venv on PATH returns `""` | helper returns `""` under the fault (decorative), or a fault under the venv | run the helper on the unfixed-equivalent (stub returning `""`) → AC-1 fails |
| AC-2 | Existing B1 end-to-end fixture driven under a PATH forcing the fault: PR is `deferred`, run exits 3, attempt record holds **0** attempts | on the **base commit** the same scenario reserves a slot and stops with exit 2 | witness the base-commit run first (red), then the candidate (green) |
| AC-3 | Same fixture with a healthy PATH: B1 resolves and lands exactly as before | the candidate changes the healthy path | existing suites below |
| AC-4 | A clone with no `validate.sh` (consumer shape, and the existing fixtures) is unaffected | helper refuses where it should be silent | AC-3 + existing suites |
| AC-5 | Dry run prints a `PRE-FLIGHT:` line naming the fault under system `python3`, none under the venv | no warning, or a warning under a healthy PATH | AC-1 mirror at the dry-run surface |
| AC-6 | Existing suites stay green: `test/gh534_phase_b_tests.py`, `test/gh436-merge-cleanup.py`, and the rest of the merge-cleanup suites | any regression | n/a — existing guarantees |

Guarantees touched and how I will try to violate them: the 2-repair cap (probe runs before `reserve`,
so no accounting write moves), `--resume` skip (probe sits after it), hard-dependent blocking (a
deferred PR enters `failed`, the existing mechanism), dry-run purity (no writes, warn only), and
consumer repos without `validate.sh` (fail open).

## Smoke (Step 7, GH-1088)

Main path: dry run of a real conflicted PR shape under system `python3` (warning appears) and
under the venv (no warning). Adjacent path: `--execute` then the same re-run with the PATH fixed —
the deferred PR is repaired and lands in the **same budget** it would have had (slots 0 → 1).

## Risks

- `validate.sh --print-mode` cost: measured to be a toolchain probe only; bounded by timeout and run once per conflicted PR.
- A fault in the PR's own `validate.sh` (branch edits it): the probe then defers a PR whose gate would also have refused — consistent, not a regression.
- Untraced: other callers of `preflight_warnings` outside `merge_cleanup.py` (none found by grep in `skills/` and `utils/`).

## Open questions for the reviewers

1. Is defer (exit 3) the right outcome versus stop (exit 2)? Strongest counterargument: a deterministic environment fault affects every repair, so stopping early is simpler.
2. Should the push-site `[-400:]` truncation also be addressed here, or kept out as a separate issue for genuine gate REDs?
3. Is adding the run-start PRE-FLIGHT warning (step 3) scope creep given step 2 alone satisfies the acceptance?

## Per-issue rating (RELEASES vocabulary, `rated pri/sev/appeal/effort`, 1–100)

`55/55/50/70` — 2026-11-25. Severity: wastes 1 of 2 bounded repairs and can park a landable PR after a non-defect refusal; recoverable, no data loss. Priority follows severity and the fact that it fired in the live landing loop. Appeal 50 (neutral; no user preference). Effort is **cheapness** (high = easy): ~70 for one helper plus a defer. Recurrence: one incident in the window; trend unknown (no same-class issue found in the prior-art scan); no downgrade inferred. Correction: the filed issue's PRS line shows `effort 25`, which inverted the axis; this row supersedes it.

## Lessons learned

NO_ENTRY at plan time; decide at handoff.

## Recon ledger

- `prior_art_recon.py --query "merge-cleanup push refused ENVIRONMENT FAULT repair slot"`: 0 open PRs, 0 merged, no `existing_fix_candidates`.
- Code traced at base `b479f74e0`: `reserve` `:2148`, `finish` `:2188`, push `:2197`, `push_resolved_head` `:1142`, tail slice `:1165`, hook wiring `:1094`, `preflight_warnings` `:1409`/`:2915`.
- Correction recorded: an early reading of the file predated PR #1599's own edits to it; all line numbers above are re-read at the clone base.
- Correction recorded: hook wiring is already pre-reserve, so the class is "gate toolchain", not "any push precondition".
