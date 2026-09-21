---
gh_issue: 740
source: https://github.com/HiQS-Labs/XYZ-forge/issues/740
title: "GH-740 + GH-741: hosted reconcile lane — land receipts before the race, recompute transitions on rejection; report the failing step's real error"
status: In progress
created: 2026-09-21
updated: 2026-09-21
owner: Claude Code (start-task, one group: #740 + #741)
doc_type: bugfix
complexity: 3
risk: 2
effort: 3
phases: 1
rgt_note: "both issues are the same seam — the last two steps of .github/workflows/wave-reconcile.yml"
related:
  - GH-741-HOSTED-LANE-REPORT-ATTRIBUTION.md
  - "#591 umbrella (the post-merge reconciler actually lands) — this group closes two of its open classes"
  - "#674 — the operator-side half of the same race (merge-cleanup's local fallback); not changed here"
  - "#732 D.2 — the lane's success-rate measurement; exit condition 10 consecutive green runs"
non_goals:
  - GitHub merge queue / branch protection (#571 owns the research); the lane keeps `contents: write` on an unprotected branch
  - Splitting the workflow into two jobs (qualify / land) — same effect is reached inside the one step by pushing receipts first
  - The hosted qualification suite going red on the runner (8 of the 27 red runs since 09-17, `Full-suite qualification failed`) — a different class, tracked on #591/#293, untouched here
  - Any change to what the bot may commit (the declared-artifact allowlist moves verbatim; it is not widened)
  - Rebasing or force-pushing `releases.db` bytes
goal: >
  A merge landing during a hosted reconcile run costs at most one cheap recompute of the ledger
  transitions — never the ~70-minute qualification — and when a run is red, the one labelled
  attention issue names the step that failed and its real error, not a unit test's expected output.
---

# GH-740 + GH-741 — hosted reconcile lane: publish survives a concurrent landing; the lane report tells the truth

Issues: [#740](https://github.com/HiQS-Labs/XYZ-forge/issues/740) (push race),
[#741](https://github.com/HiQS-Labs/XYZ-forge/issues/741) (report attribution). Umbrella: #591.
Radar run 4 target `RADAR-class-hosted-reconcile-lane` (#293). Base: `origin/development @ b6bb8aab`.
Clone: `XYZ-forge-gh740-741-hosted-lane`, branch `fix/gh740-741-hosted-lane-push-and-report`.

## Status

| What was just completed | What's next |
|---|---|
| Recon on `b6bb8aab`: traced the publish step (`wave-reconcile.yml:68-103`), the receipt contract (`wave_reconcile.py:475-528` — a receipt counts only when **committed on HEAD**), the report scan (`hosted_lane_report.py:52-56`), and the tests that pin them (`test/gh421-auto-wave-reconcile.sh:525-640`, `test/gh684-hosted-lane-report.sh`). Classified all 27 red runs since 09-17 by failing step: 3 rejected pushes (09-18 ×2, 09-21), 13 GH-721 guard (fixed #725), 3 Lessons Learned (fixed GH-693), 8 hosted suite red (out of scope). Both issues parked and rated. Plan written. | Codex plan QA (relay-xyz). Then implement in order: (1) `hosted_lane_report.py` outcome-aware attribution + gh684 cases; (2) `hosted_lane_publish.py` two-phase publish + gh740 fixture suite + gh421 pin updates + workflow wiring; focused suites; final relay QA; full gate once in a disposable clone; PR. |

## Observed problem (both issues, one seam)

The lane is one ~70-minute job. Its last two steps are `Commit declared artifacts and push` (inline
Python: allowlist → `git add` → commit → **one plain `git push origin HEAD:development`**,
`wave-reconcile.yml:68-103`) and `Report hosted lane` (`hosted_lane_report.py`, `if: always()`).

- **#740.** When any merge lands on `development` during the run, the push is rejected
  (`! [rejected] HEAD -> development (fetch first)`), the job is red, and *everything* the run
  produced is discarded — including the qualification receipts under
  `TESTS-RESULTS/<date>+GH-591/wave-<tested>/`. The next run cannot reuse them:
  `committed_qualifications()` reads `git ls-tree HEAD` (`wave_reconcile.py:511-528`) and
  `qualification_receipt_matches()` (`:475-508`) requires the receipt on HEAD with `tested` an
  ancestor of HEAD. So the ~70-minute `validate.sh --sequential` runs again, and races again.
  `concurrency: group: wave-reconcile` (`:12-17`) serialises runs, not merges. Observed 3× in five
  days (runs 35372725722, 35375197135 on 09-18; 35623940059 on 09-21 — #733 landing during #731's run).
- **#741.** `summarize()` returns `errors[-1]` over every line of the tee'd reconcile log
  (`hosted_lane_report.py:52-56`). On a `--qualify` run that log contains the full test suite's
  output, and `test/gh421-auto-wave-reconcile.sh`'s unit tests deliberately drive
  `wave_reconcile.py:1210/:1229` through their expected `wave-reconcile: ERROR — …` lines. For run
  35623940059 the reconcile step was **green**; the push step failed; #735 reported
  `Malformed merged-PR recovery response: invalid merged_at timestamp`. The step that failed is not
  tee'd at all, so its cause is invisible to the report.

## Requirements

| Issue | Requirement | Acceptance (falsifiable) |
|---|---|---|
| #740 | A landing that races the run never costs the qualification again | Fixture: remote advances after the reconcile output exists and before the push; receipts commit lands (rebased), transitions land after one recompute; `git log origin/development` shows racer → receipts → transitions |
| #740 | A second race on the same run fails **loudly, once**, naming the racing head | Fixture: remote advances again during the retry → exit 1, stderr has `hosted-lane-publish: ERROR — …` naming `origin/development` and its SHA; receipts already on the remote |
| #740 | The bot's commit surface is unchanged | The allowlist cases pinned in gh421 (`undeclared` refusals for `utils/py/unexpected.py`, `TESTS-RESULTS/arbitrary/…`, `PROJECT/1-INBOX/scratch-note.md`, malformed `wave-<sha>`) pass against the moved function, byte-identical regexes |
| #740 | No force-push; `releases.db` never rebased | The publish code contains no `--force`/`-f` push and never runs `rebase` with the `exact` artifacts in the tree — the transitions retry is `reset --hard` + recompute, not rebase |
| #741 | A red run whose reconcile step is green never reports a reconcile-log error | Replay: gh421-style log (test-emitted `ERROR —` lines, last one `invalid merged_at timestamp`) + `--reconcile-outcome success` + `--publish-outcome failure` + publish log with `[rejected]` → body names the publish step and the rejection; does **not** contain `merged_at` |
| #741 | A red reconcile step still reports its real last error | Existing gh684 case (`Doc GH-505-X.md is missing …`) with `--reconcile-outcome failure` → unchanged body |
| #741 | Red control | The pre-fix `summarize()` on the replay log returns the `merged_at` line — the new attribution must differ from it on that input |
| both | Existing lane semantics | `job.status` still decides red/green; one labelled issue; self-close on green; skip lines unchanged |

## Smallest affected surface (existing subsystem + canonical writer, extended)

1. **`utils/py/hosted_lane_publish.py` (new file, same subsystem — it *is* the current inline step, moved).**
   The workflow's inline Python (`:71-103`) becomes a script so it can be unit-tested and retried;
   the allowlist (`exact`, `doc`, `plan`, `receipt` regexes), explicit `git add -A -- <paths>`, bot
   identity and commit message move **verbatim**. Added behaviour, in order:
   - `declared_paths()` → `(receipts, rest)` partition using the existing `receipt` regex.
   - **Phase A — receipts first.** If `receipts`: commit them alone (`chore: retain qualification
     receipts for <tested>`), then `push`; on rejection `fetch origin development` + `rebase
     origin/development` + `push`, up to 3 attempts. Receipt files are new files under a
     `wave-<tested>` folder unique to this run, so the rebase cannot conflict; a conflict is
     therefore an error, not something to resolve.
   - **Phase B — transitions.** Commit `rest` (`chore: reconcile merged development work`), `push`.
     On rejection: `fetch`, `reset --hard origin/development` (the receipts are upstream now, the
     tree is clean), re-run the reconcile command **once** — the same argv the reconcile step used,
     passed as `--reconcile-cmd` — then recompute `declared_paths()`, allowlist, commit, push. A
     second rejection exits 1 with `hosted-lane-publish: ERROR — push rejected after recompute;
     origin/development moved to <sha>`. Every failure path prints one `hosted-lane-publish: ERROR — …`
     line to stderr (the report's contract, below).
   - Why the recompute is cheap: on the fresh head the receipts are committed and `tested` is an
     ancestor, so `qualify_landings()` finds them and skips the suite for this run's landings. If the
     racing merge itself is unqualified, `--catch-up --qualify` qualifies it in the retry — real work
     its own queued run would otherwise do, bounded to one attempt.
   - Nothing to commit → `Nothing to commit`, exit 0 (unchanged).
2. **`.github/workflows/wave-reconcile.yml`** — publish step becomes `id: publish` /
   `run: python3 utils/py/hosted_lane_publish.py --reconcile-cmd "$RECONCILE_CMD" 2>&1 | tee
   "$RUNNER_TEMP/publish.log"` under `set -euo pipefail`; the reconcile step exports the argv it ran
   as `RECONCILE_CMD` via `$GITHUB_ENV` (one line each branch). Report step gains
   `--reconcile-outcome "${{ steps.reconcile.outcome }}" --publish-outcome "${{ steps.publish.outcome }}"
   --publish-log "$RUNNER_TEMP/publish.log"`. Triggers, permissions, concurrency, the two reconcile
   command lines pinned by gh421 — unchanged.
3. **`utils/py/hosted_lane_report.py`** — `summarize()` keeps its signature; new
   `terminal_error(reconcile_outcome, reconcile_lines, publish_outcome, publish_lines)`:
   reconcile outcome ≠ `success` → last `wave-reconcile: ERROR — ` line (today's behaviour);
   else publish outcome ≠ `success` → last `hosted-lane-publish: ERROR — ` line, falling back to the
   last non-empty publish-log line (a raw `git` rejection); else `None`. `body_for()` prints
   `Terminal error (step: reconcile|publish): …` or `none captured (no step reported an error; see the
   run)`. Outcomes default to `None` → current behaviour, so the workflow and the script can land in
   one PR without an ordering hazard. `job.status`, skips, issue discovery/close: untouched.
4. **Tests** (footprint scaled to ~150 lines of production change):
   - `test/gh684-hosted-lane-report.sh`: +2 cases — attribution by outcome (replay above) and the red
     control (old `summarize()` on that log returns the `merged_at` line; new attribution does not).
   - `test/gh421-auto-wave-reconcile.sh`: the three publish tests (`:551-640`) import
     `hosted_lane_publish` instead of exec'ing YAML; allowlist cases unchanged; the "rejected push
     raises" pin becomes "rejected push → Phase A rebase + Phase B recompute" with `check_output`
     patched as today; workflow markers updated (`id: publish`, `steps.reconcile.outcome`,
     `hosted_lane_publish.py`, `--publish-log`).
   - `test/gh740-hosted-lane-publish.sh` (new, registered in `validate.sh`'s `TESTS`): real git
     fixture — bare remote, clone, a stub reconcile command that writes a receipt folder + a
     `PROJECT/2-WORKING/GH-740-fixture.md` + `releases.sql` line and counts its invocations. Cases:
     no race (both phases push); race before Phase A (receipts rebased, transitions recomputed once,
     remote history = racer → receipts → transitions, stub invoked twice); race before Phase A **and**
     during Phase B (exit 1, `hosted-lane-publish: ERROR — ` names the remote SHA, receipts on the
     remote); undeclared artifact refused before any push; **red control** — a plain
     `git push origin HEAD:development` from the same raced clone is rejected, proving the fixture
     races.

## Dependencies, risks, rollback

- No PR dependency. #674 (operator side) stays open and unchanged.
- Risk: `git rebase` in CI needs the bot identity — set before Phase A (moved from today's step).
  Risk: `reset --hard` discards the transitions' working tree — intended; receipts are upstream first,
  and the recompute regenerates the rest from committed state. Risk: the recompute may take the full
  qualification time if the racer is unqualified — bounded to once, and the alternative (today) is
  the *whole* run again.
- Rollback: revert the PR; the inline step returns. Receipts already pushed by the new code remain
  valid under the unchanged receipt schema.

## Ratings (RELEASES `rated pri/sev/appeal/effort`, written 2026-09-21)

- **#740 `85/75/50/55`** — sev 75: no data loss, but every collision discards ~70 min of runner time
  and blocks the lane from converging; recurrence 3 collisions in 5 days plus the operator rule that
  serialises merges. pri 85: severity-led; it taxes every landing. appeal 50 neutral. effort 55: one
  script + fixture suite + pin updates.
- **#741 `70/55/50/80`** — sev 55: a misleading alert sends operators after the wrong bug (it nearly
  became a radar failure class); not blocking. pri 70: prerequisite for measuring D.2 honestly.
  appeal 50. effort 80: ~25 lines + 2 test cases.

## Ordered implementation (verification inline)

1. `hosted_lane_report.py`: `terminal_error()` + `body_for()` step label + two CLI flags; gh684 +2
   cases → `bash test/gh684-hosted-lane-report.sh` green, including the red control.
2. `hosted_lane_publish.py`: move the inline step; `declared_paths()`; Phase A/B; error lines.
3. `test/gh740-hosted-lane-publish.sh` + `validate.sh` registration → green, red control witnessed.
4. `wave-reconcile.yml` wiring (`RECONCILE_CMD`, `id: publish`, tee, report flags); gh421 pin
   updates → `bash test/gh421-auto-wave-reconcile.sh` green.
5. Focused: gh684, gh421, gh740, `ci-workflow.sh`. Full gate once, in a disposable clone, on the final
   approved commit; receipts retained under `TESTS-RESULTS/2026-09-21+GH-740/`.
6. Final Codex relay QA → PR against `development`. Hosted proof is post-merge: the first PR-closed
   run exercises Phase A on the real lane.

## Lessons Learned (For Future Agents)

- A qualification receipt is only worth anything once it is **committed on HEAD** — so the cheap,
  conflict-free artifact must be pushed before the expensive-to-recompute one, not with it.
- `if: always()` reporters that scan a log for the last error line are only right when the step
  that wrote the log is the step that failed; pass step outcomes, don't infer.
- Classify red runs by *failing step* before by error text: 13 of 27 "reconciler failures" were one
  fixed guard, and the 3 real races were invisible behind test output.
