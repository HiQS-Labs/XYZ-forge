---
gh_issue: 684
source: https://github.com/HiQS-Labs/XYZ-forge/issues/684
title: "Hosted wave-reconcile lane: 0 successes since 2026-09-11; nothing alerts; one defect anywhere in the backlog fails every reconcile"
status: Active
created: 2026-09-18
updated: 2026-09-18
owner: operator (fresh-clone PR lane)
doc_type: bugfix
effort: 2
complexity: 3
risk: 2
phases: 1
branch: fix/gh684-hosted-reconcile-lane
shares_pr_with: [686]
non_goals: [drop or shorten --qualify (#591 decision), "#674", standup/radar lane health, the 35 docs missing Lessons Learned, GH-505's doc]
goal: >
  The hosted wave-reconcile lane tells a human when it is red or when it skipped something, and one
  defective backlog doc no longer prevents every other merged PR from reconciling; the qualification
  stays exactly as #591 designed it and its one flaky suite (gh53) becomes deterministic.
---

# GH-684 — hosted reconcile lane: alert on red, skip-and-report a defective backlog item

## Status

| What was just completed | What's next |
|---|---|
| Recon on base `ba1f58e8` (workflow, reconciler loop, catch-up, gh421 harness, gh53 fixture); #686 filed; both issues parked and rated; plan S1–S4 written. | Codex relay plan QA (relay-xyz) → adjudicate → implement S1–S4 on `fix/gh684-hosted-reconcile-lane` → disposable-clone verification → final relay QA → PR `Closes #684, Closes #686`. Post-merge: re-enable the workflow and record the first hosted green on #684. |

## Context & cross-references

- **Tracking issue:** [#684](https://github.com/HiQS-Labs/XYZ-forge/issues/684) (filed 2026-09-18 from measurement; the lane was disabled manually the same day).
- **Shares the PR with:** [#686](https://github.com/HiQS-Labs/XYZ-forge/issues/686) — `test/gh53-releases-merge-resolve.sh` coin-flip; the qualification's only red suite on the last hosted run. Its capture doc is `GH-686-GH53-FIXTURE-FLAKE.md`; its requirements map onto S3 below.
- **Umbrella:** [#591](https://github.com/HiQS-Labs/XYZ-forge/issues/591) — chose full-suite qualification in the hosted job on purpose ("failed proof cannot authorize closeout"). **This work keeps `--qualify` and `--gate` exactly as they are.**
- **Adjacent, not here:** [#674](https://github.com/HiQS-Labs/XYZ-forge/issues/674) (merge-cleanup looks the hosted run up by the wrong SHA); [#492](https://github.com/HiQS-Labs/XYZ-forge/issues/492) (non-PR closures); the 35 `2-WORKING` docs missing Lessons Learned (owners); surfacing lane health in `standup`/`radar`.

## Observed (2026-09-18 01:00–02:50 UTC)

- `gh run list --workflow wave-reconcile.yml --limit 100`: last success 2026-09-11T14:49Z (run 34612452966); since then 59 failures, 5 cancelled, 0 successes across 6 days.
- Three rotating terminal errors: `Closed GH-52 has reconciliation drift but no attributable merged development PR` (09-11/12); `Full-suite qualification failed; no receipt produced: validate.sh --sequential returned non-zero` (09-13→09-16 and 09-18 01:41Z: **392/393**, `gh53-releases-merge-resolve.sh` the one red suite); `Doc GH-505-RELAY-REVIEWER-INTEGRITY.md is missing mandatory '## Lessons Learned (For Future Agents)' section.` (09-17, exit 5, everything rolled back).
- Each run waited 1 h 18 m–2 h 23 m for a `macos-latest` runner, then ran 1 h–1 h 14 m before failing at the write step.
- `wave-reconcile.yml` has no failure step and `issues: read`; `merge_cleanup.py::wait_for_hosted_reconcile` logs "completed as failure; using local reconciliation" and proceeds — a red hosted run is treated as the normal path.

## Recon map (base `ba1f58e8`)

| Surface | What was traced | Finding |
|---|---|---|
| `.github/workflows/wave-reconcile.yml` (97 lines) | triggers, `concurrency` (`queue: max`), job `permissions: contents: write, issues: read`, steps: checkout → protection check → `npm ci` → pip → **Reconcile merged PR or catch up** (`--pr N --catch-up --gate --qualify` on PR-close; `--catch-up --gate --qualify` on schedule/dispatch) → **Commit declared artifacts and push** (refuses untracked files outside the declared set; one ff push). | No `if: failure()`/`always()` step; nothing captures the reconcile step's output; any log written *inside* the tree would be refused by the commit step. |
| `utils/py/wave_reconcile.py` main loop (`~1928–2070`) | `landing_items` = explicit `--pr/--commit/--manifest` + `catch_up_prs(...)` when `--catch-up`; dedup; `qualify_landings` once for the whole batch; then per landing → per closed issue: `ship_manifest_items` → `validate_and_update_doc` → `update_roadmap_entry`. | The **explicit** landings and the **catch-up-recovered** ones are indistinguishable once merged into `landing_items`. `validate_and_update_doc` calls `validate_lessons_learned` and `die(code=5)` — *after* `ship_manifest_items` has already written — so one defective backlog doc rolls back the whole batch, every run. |
| `wave_reconcile.py::catch_up_prs` (`1181–1248`) | Drift sources: dialed-in manifest members, non-terminal roadmap rows, every `2-WORKING/GH-*.md`; each closed issue → timeline → newest merged `development` closer. | Already has the precedent to extend (GH-584): "no attributable merged development PR → WARNING, leaving this legacy row unchanged and continuing". A skipped item is re-found next run by the same drift sources (doc still in `2-WORKING`, row not Completed), so a skip is durable-visible, not lost. |
| `wave_reconcile.py::validate_lessons_learned` (`926–949`) | Pure function on doc text → error string or None. | Callable *before* the first write; no new checker needed. |
| `test/gh421-auto-wave-reconcile.sh` (517 lines; registered) | Python `unittest` harness: offline manifest, patched `subprocess.run` (git/network forbidden), in-tree `releases_app.py` CLI, `WorkflowTests` pins the YAML (markers, `permissions`, triggers, `queue: max`, `--pr "$PR_NUMBER" --catch-up --gate --qualify`). | Right home for the S2 cases and the S1 workflow pins. Existing pins constrain the YAML edit: `'    permissions:\n      contents: write'` must stay a contiguous substring. |
| `test/gh53-releases-merge-resolve.sh` `union_dump` (`78–85`) + `utils/releases-merge-resolve.sh` (`75–96`) | Fixture unions two dumps keeping one `-- generation:` header and `awk '!seen[$0]++'` for the rest. | Each side's `settings` row `('generation','2',updated_at)` differs by `updated_at` when the two `releases add` calls straddle a second → both rows survive → resolver refuses `dump-duplicate-setting` (correctly). Reproduced by hand; `FAIL pass` at one commit. → #686. |
| `utils/ci-route.sh` | Path classes for the PR's diff. | `.github/workflows/*` and unmapped `utils/py/*` → `full_required` (the PR lane runs the full gate anyway); `validate.sh` append-only registration allowed. |

Untraced: the hosted runner's `gh` auth scope for issue writes (`github.token` with `issues: write` is the documented path); whether `pull_request: closed` runs can be re-keyed so #674's lookup works (out of scope, noted).

## Requirements → plan mapping

| Req | Source | Plan item |
|---|---|---|
| R1 A red hosted run is visible to humans without opening Actions; one place, not one issue per run | #684 §Proposed 1 | S1 |
| R2 A defective **backlog** item stops only itself; the run's own PR and the rest of the backlog still reconcile and land | #684 §Proposed 2 | S2 |
| R3 The current red suite in qualification is deterministic again, without weakening the qualification | #684 §Proposed 3/5 (as amended by #591) → #686 | S3 |
| R4 Skipped backlog items are reported, not silently dropped, and are retried on later runs until fixed | #684 §Why nobody saw it 2 | S1 + S2 |
| NG Dropping/shortening `--qualify`; #674; standup/radar health; fixing the 35 docs; GH-505's doc | #591 decision; separate issues | — |

## Plan (one phase, one PR: `Closes #684`, `Closes #686`)

- **S1 — alert on red or skips.** `wave-reconcile.yml`: give the reconcile step an `id`, `tee` its output to `"$RUNNER_TEMP/reconcile.log"` (outside the tree — the commit step refuses undeclared in-tree files), and add a final step `if: always()` that runs a new small stdlib tool `utils/py/hosted_lane_report.py --outcome <step outcome> --log <path> --run-url <url>`. Behaviour: parse the log for the last `wave-reconcile: ERROR — …` line and every `wave-reconcile: SKIPPED …` line; on `outcome != success` **or** any skip, ensure exactly one open issue labelled `hosted-reconcile-attention` (create if none, else comment) carrying the run URL and those lines; on a green run with no skips, comment and close the open one if any. Job `permissions: issues: write` (replaces `read`). No new workflow, no notifications beyond the issue.
- **S2 — skip-and-report a defective backlog item.** `wave_reconcile.py`: remember the explicit landings before `catch_up_prs` extends the list; in the per-issue loop, for a **catch-up-sourced** landing whose active doc fails `validate_lessons_learned`, log `WARNING — SKIPPED GH-N: <reason> (backlog item; fix the doc and the next run will retry)`, count it, and `continue` **before** `ship_manifest_items`. Explicit landings keep `die(code=5)` unchanged. End of run: `wave-reconcile: N backlog item(s) skipped — GH-…` summary line; exit 0 (the commit step lands the rest). Same shape as the GH-584 "leaving this legacy row unchanged and continuing" precedent, one step later in the pipeline.
- **S3 — #686.** `test/gh53-releases-merge-resolve.sh` `union_dump`: keep one `settings` row per key (`generation`: higher value, then later `updated_at`) alongside the one header; force the previously flaky shape deterministically (a `sleep 1.1` between the two sides' writes, or rewrite side B's `updated_at`) so the case is always exercised. `utils/releases-merge-resolve.sh` header comment: "one `-- generation:` header **and one `settings` row per key**". The resolver's refusal is untouched.
- **S4 — tests.** `test/gh421-auto-wave-reconcile.sh`: (a) catch-up with a second closed issue whose doc lacks Lessons Learned → that issue's manifest row **not** shipped, its doc still in `2-WORKING`, the other item reconciled, `SKIPPED GH-` in output, `main()` returns 0; (b) red control: the same defective doc on the **explicit** `--pr` landing → `SystemExit(5)`, nothing written (unchanged behaviour, now pinned); (c) `WorkflowTests`: pins `issues: write`, the `id:`, `RUNNER_TEMP`, the `if: always()` report step and its command. New `test/gh684-hosted-lane-report.sh` (registered after `gh421` in `validate.sh`): stub `gh` on `PATH` records calls; cases: red run with an ERROR line → `issue create` with label + run URL + line; red run with an existing open labelled issue → `issue comment`, no create; green run with skips → comment (not close); green run, no skips, open issue → `issue close`; green run, nothing open → no calls; empty/missing log on failure → still creates (names "no terminal error line captured"); red control: the stub asserts no `gh` call carries a body without the run URL. `bash test/gh53-releases-merge-resolve.sh` ten times in a row green in a disposable clone (the flake reproduced 3/6 before).

## Acceptance checks (falsifiable)

- [ ] `gh421` green in a disposable clone; removing the S2 skip branch turns case (a) red (case (b) stays green); reverting the YAML turns (c) red.
- [ ] `gh684-hosted-lane-report` green; the stub's call log matches per case; the red control fires.
- [ ] `gh53` 10/10 green in a disposable clone at the PR head; the same loop at the base shows ≥1 red (the flake, witnessed).
- [ ] `gh496`, `gh202`, `gh232`, `wave-reconcile.sh`, `gh358` unchanged and green (neighbouring reconciler suites).
- [ ] Full `validate.sh` in the disposable clone; the receipts land in `TESTS-RESULTS/<date>+GH-684/`.
- [ ] **Hosted proof (post-merge, on #684):** re-enable the workflow; the PR-close run for this PR completes green and lands its reconcile; the next scheduled catch-up **skips GH-505 with a WARNING and reconciles the rest**, and the `hosted-reconcile-attention` issue opens naming GH-505. That run is the first hosted success since 2026-09-11.

## Risks / rollback

- **Skipping is a policy change** for catch-up only: a defective backlog doc no longer blocks other issues. The item stays visible (roadmap row not Completed, doc in `2-WORKING`, `SKIPPED` line, alert issue) and is retried each run. Explicit landings are unchanged. Rollback: revert S2; the run reverts to fail-closed.
- **`issues: write`** widens the job's token by one scope; the tool only touches issues carrying its label. Rollback: revert the permission and the step.
- **S3 changes a test fixture and a comment**, not the resolver; if the fixture change is wrong the suite goes red deterministically instead of randomly.
- The hosted runner is `macos-latest`; nothing here changes the runtime or the qualification.

## RELEASES rating (2026-09-18)

`rated 80/75/50/60` — **pri 80**: blocks #591's acceptance and every merge's paperwork; growing backlog (≥9 closed issues stranded in `2-WORKING`). **sev 75**: work-blocking for governance, recoverable (manual local reconcile works), no data loss; recurrence is 59 incidents in 6 days of one class — assessed, not multiplied. **appeal 50**: neutral, no user preference given. **effort 60**: ~250 insertions across a YAML step, one new ~70-line tool, ~25 lines in the reconciler, fixture fix, tests; no schema or kernel change. Recurrence window: 2026-09-04→09-17 vs 08-21→09-03 — the hosted lane only exists since 09-10 (#421/#591), so the earlier window has no data (unknown trend, not zero).
