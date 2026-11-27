---
title: "jog: approved-lane receipt publication books its own gate-attempt reservation"
status: Complete
created: 2026-11-27
updated: 2026-11-27
owner: Noel Saw
gh_issue: 1653
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1653
doc_type: bugfix
reported_from: XYZ-forge
harness_commit: 52813e56f
non_goals:
  - weakening, skipping or re-routing the pre-push gate or its attempt admission (no --no-verify, no XYZ_SKIP_PREPUSH)
  - a new scheduler, reservation store, attempt kind or test suite (AGENTS.md No new tests, GH-831)
  - reusing the Marathon lane's attested reservation for the receipt commit (it cannot cover it, see recon)
  - run_record.py checkpoint --push booking (named in #1653 Observed; separate owner, parked)
  - changing LANE_MAX_ATTEMPTS defaults or the archive-on-completion budget rule from #1399
related:
  - 1399
  - 1576
  - 1611
  - 1657
goal: "A Jog wake (and jog resume / gate-only retry) that publishes an approved receipt books a manual reservation through gate_receipt's existing lane writer, pushes under it, and finishes it; an unreserved task push is still refused and consumed attempts survive retry and restart."
---

# GH-1653 — Jog books the gate-attempt reservation for receipt publication

## Status

| What was just completed | What's next |
|---|---|
| Plan QA: 4 Codex rounds (cap; consult single-model PROCEED). Final QA: 4 Codex rounds (cap); rounds 1–3 fixed with before/after probes, round-4 lock window reproduced and filed as #1671; consult split (agy PROCEED, Codex HOLD on an out-of-band booking, declined). Merged `origin/development` incl. PR #1669. gh280 262/0, CLI smoke 12/12 through the installed hook (`TESTS-RESULTS/2026-11-27+GH-1653/`). | Exact-commit qualification from a disposable clone, ready PR, awaiting merge. |

## Observed problem (base `52813e56f`)

Day 3 (#1611 handback, comment 7224052933): two of two approved lanes ended
`jog: GH-<n> parked: approved receipt not published: git push origin HEAD:refs/heads/marathon/... failed:
gate-attempt: REFUSED — task qualification has no attempt reservation; use gate_receipt.py attempt-start`.
The workaround each time was `gate_receipt.py attempt-start --repo <exec> --accounting-root <coordinator>
--task GH-<n>-start-task --env`, `jog resume <n>`, `attempt-finish --outcome completed`.
Day 2 (#1610) needed the same. Recurrence: 3+ distinct lanes in the last 14 days (Day 2 977, Day 3 1626 and 792),
0 in the prior 14 days (the admission gate is from #1399, landed 2026-11-10; Jog receipt pushes are from #1576 era).

## Recon (traced)

| Claim | Source | Observed |
|---|---|---|
| Jog pushes the receipt bundle with no attempt context | `utils/py/jog_run.py` `publish_jog_receipt` (≈L1176–1250): commit then `_git(target, "push", "origin", "HEAD:refs/heads/<lane>")`, `env=None` | the push inherits Jog's environment; Jog never sets `XYZ_ATTEMPT_CONTEXT` |
| Three callers publish | `jog_run.py` wake (≈L721, `run_marathon_phase`), `jog_resume` (≈L818), gate-only retry (≈L1063) | all three have the coordinator `root`, the execution `target` and `gh_num` |
| The hook refuses any task push without context | `githooks/install.sh` stub `_attempt_guard` → `gate_receipt.py admit --ref --destination-ref`; `githooks/pre-push` L91–95 | `attempt_admission` raises `task qualification has no attempt reservation` when the env var is empty and the destination is a task branch |
| Marathon books and attests its own lane reservation | `marathon_drive.py` `lane_attempt_gate` → `rtl.lane_attempt_reserve(kind="lane")`; relay_drive binds it to the attestation; archived on completion | the lane push succeeds under it, in Marathon's process only |
| That lane reservation cannot cover the receipt commit | `attempt_admission` attestation branch → `relay_attest.candidate_ok` → `source_matches` | only transcript-only commits after the reviewed head pass; the receipt bundle adds `TESTS-RESULTS/...`, so it would be refused ("changes non-transcript content") |
| The manual lane writer already exists | `gate_receipt.py` `attempt-start` (→ `rtl.lane_attempt_reserve(kind="manual", cap=LANE_MAX_ATTEMPTS)`), `attempt-finish` (→ `attempt_admission` + `rtl.lane_attempt_finish`, archive on completed) | exactly the workaround's two calls; CLI-only today (logic inline in `main()`) |
| Manual admission conditions | `attempt_admission` `state == "active"` branch | target live HEAD == pushed sha; `start_sha` ancestor of sha; pushed ref == reserved branch |
| Consumed attempts persist on disk | `rtl.lane_attempt_reserve` appends a row under `<accounting-root>/.tick/attempts/<task>`; failed rows stay; completed rows archive to `.tick/attempt-history/` | a failed or crashed booking still counts toward the cap after a restart |
| `lane_attempt_reserve` mutates `os.environ` | `rtl.py` L113 | an in-process caller must restore the variable or later Jog work inherits a stale context |
| Existing coverage | `test/gh280-jog-marathon-adapter.sh` G4 (real Preflight → Marathon → receipt publication through a local remote) | the fixture execution clone has no pre-push hook, so the admission refusal is never exercised |

## Requirements (issue #1653 + ledger #1657)

1. An approved lane publishes its receipt in the same wake with no manual `attempt-start` (also on `jog resume` and gate-only retry).
2. An unreserved task push is still refused by the hook (negative control, unchanged gate).
3. Consumed attempts survive retry and restart; an exhausted budget refuses publication (no rename, no reset).
4. Reuse `gate_receipt.py` / `rtl` accounting from #1399; no new scheduler, suite or bypass.

## Preflight bet check

- Outcome sought: unattended wakes deliver approved lanes end-to-end; the hidden per-lane manual step disappears.
- Smallest viable bet: Jog calls the existing manual booking/finish around its one push. Not built: a new attempt kind, Marathon handing its context to Jog, hook changes, run_record booking.
- Alternative rejected: reuse Marathon's attested lane context — refused by `candidate_ok` for the receipt commit; widening the transcript allowlist would weaken the gate.
- Rollback: revert the commit; the documented manual workaround still works.

## Plan

1. **`utils/py/gate_receipt.py`** — move the existing `attempt-start` / `attempt-finish` bodies out of `main()` into
   `manual_attempt_start(repo_root, task, accounting_root=None)` (returns `(count, context-or-None)`) and
   `manual_attempt_finish(repo_root, context, outcome)`; `main()` calls them unchanged in behaviour and output.
2. **`utils/py/jog_run.py`** — `publish_jog_receipt(..., accounting_root=None)`: when `push`, book
   `manual_attempt_start(target, f"GH-{issue}-jog-publish", accounting_root or target)` on the lane branch before the
   evidence commit; exhausted → `ContractError("gate-attempt budget exhausted after N consumed rounds ...")`;
   push with `env={**os.environ, XYZ_ATTEMPT_CONTEXT: json.dumps(context)}`; on success `manual_attempt_finish(..., "completed")`;
   on a failed push `manual_attempt_finish(..., "failed")` (best effort, the row stays consumed either way) and re-raise.
   A finish error *after* a successful push does not fail publication (R2-S3): the helper returns normally, prints
   `jog: GH-<n> receipt pushed; attempt accounting pending: <err>`, and the wake/resume/retry callers record the
   publication as succeeded (no `receipt-publication-failed`, no "not published" message). Save/restore the caller's
   exact `XYZ_ATTEMPT_CONTEXT` in a `finally` covering reserve, push and finish. Accounting `ValueError`s map to
   `ContractError` (the existing Jog park/`jog: <msg>` surfaces). The three callers pass `accounting_root=root`.
   The key `GH-<n>-jog-publish` is the canonical publication identity; retries and restarts draw on the same budget,
   nothing renames it, and it is not a recovery switch for any other key.
   **Settle a pending archive first (R3-B2):** at the start of every publication *and* in `_jog_resume_locked`
   when `committed_receipt` is already saved, if the live last row of `GH-<n>-jog-publish` is a `manual`
   `completed` row (its archive failed after the completed write), Jog archives it with the existing
   `rtl.archive_lane_attempts(path)` (same bytes renamed into `attempt-history`, no booking, no push). If instead the
   live last row is a `manual` **`active`** row of this key (finish failed before the completed write), the same settle
   step applies the exact-bundle/exact-ref proof below (committed bundle at HEAD, live ref == HEAD) and, when it
   holds, finishes that same row `completed` through `manual_attempt_finish` and archives it — no booking, no push
   (R4-B1). Without the proof (remote still at the prior SHA) the active row stays consumed.
   **Already-published recovery (R1-B1 / R2-B2 / R3-B1), no second booking:** the shortcut applies only when the bundle
   was already committed before this call (all four evidence files at HEAD byte-identical, nothing to commit,
   HEAD != the approved `head_sha`). Jog then reads the exact live ref with `git ls-remote origin refs/heads/<lane>`
   (no `--exit-code`): nonzero exit = transport failure → `ContractError`; empty output = ref absent; otherwise the
   SHA (absence-as-empty is the checkpoint caller's convention, `run_record.py:602–609`). Absent or different ⇒ normal
   booking path (a first publish books once and creates the ref). If it equals the local HEAD (the bundle commit), the receipt is already published:
   Jog books nothing and pushes nothing; if the live row of `GH-<n>-jog-publish` is a `manual` row that is `active`, or
   `completed` with `candidate` == HEAD (archival pending), Jog finishes that same row as `completed` with the
   existing `manual_attempt_finish` (admission re-checks identity, origin, branch and candidate), which archives it.
   If the remote ref differs, the normal booking path runs and the cap applies (e.g. failed + active at cap 2 with
   the remote still at the prior SHA refuses, rows and remote unchanged).
   **Lock ownership (R1-S5 / R2-B1):** split `jog_resume` into a lock-acquiring CLI entry
   (`JogSupervisorLock(root)`, as retry-gate/retry-build do; a held lock refuses with the existing exit 4) and
   `_jog_resume_locked(root, gh_num, args)` holding today's body. Supervised recovery (`_jog_supervise_recover`,
   which already holds the coordinator lock, `jog_run.py:2977–3009`) calls `_jog_resume_locked`. State is loaded and
   saved inside the lock. Supervision's line `recovered ... without a new builder or attempt` becomes
   `without a new builder turn`. Docstring: resume "spends no build turn; publication books one gate attempt".
3. **`test/gh280-jog-marathon-adapter.sh`** (existing suite, focused cases only) — an execution-clone fixture
   pre-push hook that, per pushed ref, unsets the fixture's command-scoped transport rewrite
   (`GIT_CONFIG_PARAMETERS`/`GIT_CONFIG_COUNT`, R1-S4: probe showed the hook otherwise sees the local bare URL and
   hashes a different origin) and runs the real `gate_receipt.py admit --repo . --sha --ref --destination-ref`
   (the installed stub's admission step). A receipt-only fail sentinel fires *after* admission and only when the
   pushed commit's subject starts `jog: publish` (R1-S3), so Marathon's earlier lane push is unaffected.
   - G4 (wake): row parked awaiting-landing; the bare remote's lane ref holds the `jog: publish` commit and the bundle
     `receipt.json`; the coordinator `$FR/.tick/attempt-history/GH-901-jog-publish-*/attempts` holds one completed row.
   - G4-neg: a new commit on a new task branch pushed from the same clone with `XYZ_ATTEMPT_CONTEXT` and
     `MERGE_CLEANUP_RECORD` unset is refused with `task qualification has no attempt reservation`; remote has no such ref.
   - G4-retry (fresh fixture; starting lane ref recorded): sentinel on → run parks `receipt not published`, 1 failed
     row, remote lane ref unchanged; `jog resume` (new process) → 2 failed rows; sentinel off → `jog resume` refused
     `budget exhausted after 2`, still 2 rows, remote unchanged. Optional fixture-only: `LANE_MAX_ATTEMPTS=3 jog resume`
     publishes and the archive holds 3 rows.
   - G4-archive (R1-B1/R2-B2): continuing G4-retry's state (1 failed row live): (a) push the bundle commit to the
     bare remote out of band and append a `completed` row with `candidate` = HEAD to the live file (crash before
     archival) — `jog resume` exits 0, books nothing, the archive holds exactly those 2 rows (same ids), state has
     `committed_receipt`; (b) seed failed + `active` at cap with the remote still at the prior SHA — `jog resume`
     refuses `budget exhausted`, both live rows and the remote ref unchanged; (c) after a successful publication,
     move the archived file back to the live path as a `completed` row (archive failed after the completed write, with
     `committed_receipt` saved) — `jog resume` archives that same row id with no booking and the bare ref unchanged.
     (d) as (c) but the live row is the `active` row (finish failed before the completed write; bundle already on
     the bare remote), with and without `committed_receipt`: `jog resume` completes and archives the same row id at
     cap, no booking, no push, bare ref unchanged.
   - K2 additionally asserts the bare remote lacks the K2 lane ref before the retry (first publish creates it).
   - Lock (R1-S5/R2-S4): the Round 1 two-resume clone probe, run against the implementation in a disposable clone
     (patching the binding the publication helper calls), expects B exit 4 and exactly one additional row; recorded
     under `TESTS-RESULTS/`. Supervised recovery publishing with the lock held is exercised by the existing gh280
     supervision section if it covers an approved pending publication; otherwise by the smoke.
   - K2 (R1-B2, gate-only caller): the same hook on K2's execution clone; after the approved retry, the bare remote
     holds the retry's `jog: publish` commit and `$FR/.tick/attempt-history/GH-901-jog-publish-*` holds a completed
     row (omitting `accounting_root=root` would put it under `$FT` and fail). K2's no-builder/no-new-token checks stay.
   - P2: reword to "Marathon keeps executor attempts and Tick tokens; Jog writes only publication rows through gate_receipt".
   Red control: the fixture overlay run against runtime base `52813e56f` (`utils/py` from base) fails G4/K2 with the
   admission refusal and an unchanged remote ref. Day 3 (`3f2ffa353`, #1653) is field evidence; this is the replay.
4. Smoke (GH-1088): in a disposable full clone with the *real installed* hook (`githooks/install.sh`), main path = a
   Jog publication of an approved fixture receipt through the installed stub; adjacent path = `jog resume` after a
   failed publication. Receipt under `TESTS-RESULTS/2026-11-27+GH-1653/`. Live OL-13 credit stays with the Day 4 run.

## Verification

- Focused: `bash test/gh280-jog-marathon-adapter.sh` red on base, green on the fix.
- Final: classified gate route on the approved commit from a disposable clone (start-task Step 7/9).

## Risks / rollback

- Each publication now consumes one manual attempt from `LANE_MAX_ATTEMPTS` (default 2) under `GH-<n>-jog-publish`; a completed publication archives, so a later lane for the same issue starts a fresh budget (the #1399 rule).
- A crash between booking and finishing leaves an active row that still counts (honest accounting).
- Rollback: revert; the manual workaround remains valid.

## PRS rating (2026-11-27)

`rated 80/65/50/65` — sev 65: every unattended approved lane parks until a person books an attempt (work-blocking manual step, no data loss, recoverable by `jog resume`); pri 80: Day 4 prerequisite in #1657, recurring every lane (3 lanes / 14 days vs 0 before); appeal 50 neutral; effort 65: two-file change plus a focused case in an existing suite.
