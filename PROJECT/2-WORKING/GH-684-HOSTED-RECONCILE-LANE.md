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
| Recon on base `ba1f58e8`; #686 filed; both issues parked and rated; plan S1–S4 written; **Codex plan QA round 1 (`relay-system/2026-09-18/gh684-plan-qa.md`): 1 Blocker + 3 Should + nits, all dispositioned into this revision.** | Codex round 2 → Approved → implement S1–S4 on `fix/gh684-hosted-reconcile-lane` → disposable-clone verification → final relay QA → PR `Closes #684, Closes #686`. Post-merge: re-enable the workflow and record the first hosted green on #684. |

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
| `wave_reconcile.py::catch_up_prs` (`1181–1235`) | Drift sources: dialed-in manifest members, non-terminal roadmap rows, every `2-WORKING/GH-*.md`; each closed issue → timeline → newest merged `development` closer. | Already has the precedent to extend (GH-584): "no attributable merged development PR → WARNING, leaving this legacy row unchanged and continuing". A skipped item is re-found next run by the same drift sources (doc still in `2-WORKING`, row not Completed), so a skip is durable-visible, not lost. |
| `wave_reconcile.py::validate_lessons_learned` (`926–949`) | Pure function on doc text → error string or None. | Callable *before* that issue's lifecycle writes; no new checker needed. |
| `wave_reconcile.py::qualify_landings` (`~500–600`) + `check_provenance_receipts` (`604+`) | `--qualify` runs once for the **whole batch** before the issue loop and writes validation telemetry + per-landing provenance receipts (`578–600`); `--gate` only reads. | Receipts are evidence that the *snapshot* was tested, not that a doc completed (`451–484`). A skipped landing legitimately keeps its receipt; "skip" therefore means **no issue lifecycle writes** (manifest ship, doc move, roadmap update), not "no writes at all". |
| `wave_reconcile.py` planner ownership: `reconciled_issues.update(linked_issues)` (`1999`) → `run_subprocesses(..., reconciled_issues)` (`2113–2117`) → `handle_marathon_plan_result` (`1445–1457`) | Any marathon-plan `already-closed`/held finding whose issue is in `reconciled_issues` is **fatal** (`die(6)`); unrelated findings only warn. `_marathon_plan.py:866–870` emits exactly that finding for a CLOSED issue still `In progress`. | **A skipped issue must be removed from the ownership set**, or its own retained drift kills the run one step later (Codex probe: `{421,505}` → `ReconcileError 6`; `{421}` → accepted). |
| `test/gh421-auto-wave-reconcile.sh` (517 lines; registered) | Python `unittest` harness: offline manifest, patched `subprocess.run` (git/network forbidden), in-tree `releases_app.py` CLI, `WorkflowTests` pins the YAML (markers, `permissions`, triggers, `queue: max`, `--pr "$PR_NUMBER" --catch-up --gate --qualify`). | Right home for the S2 cases and the S1 workflow pins. Existing pins constrain the YAML edit: `'    permissions:\n      contents: write'` must stay a contiguous substring. **`WorkflowTests.publish` (`476–478`) extracts the publication Python from `shell: python3 {0}\n        run: |\n` to end-of-file and compiles it — any step appended after the publication step makes that text invalid Python (probe: `IndentationError`), so S4 must bound the extraction to the step's own `run:` block first.** |
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

- **S1 — alert on red or skips.** `wave-reconcile.yml`: the reconcile step gets `id: reconcile` and runs `python3 utils/py/wave_reconcile.py … 2>&1 | tee "$RUNNER_TEMP/reconcile.log"` under `set -euo pipefail` (stderr carries the `ERROR —` line; the log lives outside the tree because the commit step refuses undeclared in-tree files). A final step `Report hosted lane` with `if: always()` runs a new small stdlib tool `python3 utils/py/hosted_lane_report.py --status "${{ job.status }}" --log "$RUNNER_TEMP/reconcile.log" --run-url "$RUN_URL"`. **`job.status`, not the reconcile step's outcome**: it reflects every preceding step, so a successful reconcile followed by a rejected fast-forward push (the documented concurrent-merge case, `yml:94–97`) reports as red. Behaviour: parse the log for the last `wave-reconcile: ERROR — …` line and every line matching the **one skip literal** `wave-reconcile: SKIPPED GH-<n> — <reason>` (S2 emits it through `log("SKIPPED GH-… — …")`; the marker string is a module constant `SKIP_MARKER = "SKIPPED "` in `wave_reconcile.py` that the report tool imports, so producer and consumer cannot drift). On `status != success` **or** any skip line: ensure exactly one open issue labelled `hosted-reconcile-attention` (create if none, else comment) carrying the run URL, the status, the ERROR line (or "no terminal error line captured") and the skip lines. On `status == success` with no skips: if an open labelled issue exists, comment "green at <run URL>" and close it; otherwise no mutating call. Label provisioning: `gh label create hosted-reconcile-attention --force …` (idempotent) before the first create. Job `permissions: issues: write` (replaces `read`; `GH_TOKEN` is already `github.token`). No new workflow, no notification service.
- **S2 — skip-and-report a defective backlog item.** `wave_reconcile.py`: remember the explicit landings (`set(landing_items)`) before `catch_up_prs` extends the list. In the per-issue loop, **inside the merged/closing-doc branch (`elif doc_path:` … `if is_merged:`, i.e. after the open-issue/umbrella preservation branch at `2025`, so an OPEN umbrella's merge-evidence behaviour is untouched)** and **before `ship_manifest_items`**: if the landing is catch-up-sourced and `validate_lessons_learned(content)` returns an error → `log(f"SKIPPED GH-{n} — {reason} (backlog item; fix the doc and the next run retries)")`, `reconciled_issues.discard(n)`, add to `skipped_issues`, `continue`. No issue lifecycle write happens for that issue; the batch's qualification receipts (written earlier for the whole batch) are retained by design. Explicit landings keep `die(code=5)` unchanged. Ownership handed to `run_subprocesses`/`handle_marathon_plan_result` is `reconciled_issues` with the skipped issues removed, so the planner's `already-closed` finding for a skipped issue is *unrelated* (warn) while a finding for an actually reconciled issue stays fatal. End of run: `log(f"{len(skipped)} backlog item(s) skipped — …")`; exit 0 (the commit step lands the rest). A skipped item is re-found next run by `catch_up_prs`'s drift sources (doc still in `2-WORKING`, row not Completed) — receipts are an additional source there, not a filter (`1187–1200`).
- **S3 — #686.** `test/gh53-releases-merge-resolve.sh` `union_dump`: keep one `settings` row per key (`generation`: higher value, then later `updated_at`) alongside the one header; force the previously flaky shape deterministically with `sleep 1.1` between the two sides' writes and **assert the two `generation` rows' timestamps differ before unioning** (so the control cannot silently degrade back to luck); keep the single `-- generation:` header equal to the kept row's value (the resolver rejects a header below either parent, `98–119`). `utils/releases-merge-resolve.sh` header comment: "one `-- generation:` header **and one `settings` row per key**". The resolver's refusal is untouched.
- **S4 — tests.** `test/gh421-auto-wave-reconcile.sh`: **(0)** bound `WorkflowTests.publish`'s extraction to the publication step's own `run:` block (stop at the next `      - name:`), keeping every current allowlist/rejected-push assertion, and add a pin that the base and the appended-step workflow both yield compilable publication Python; **(a)** catch-up mixed batch: a second closed issue (`#422`, doc in `2-WORKING` without Lessons Learned, roadmap row, manifest dial-in, merged PR 43 closing it, receipt `{"pr":43}`) recovered only by `--catch-up` → GH-421 shipped/moved, GH-422's manifest row still `dialed_in`, its doc still in `2-WORKING`, exactly one `wave-reconcile: SKIPPED GH-422 — ` line, `main()` exits 0; **repeat-then-repair**: a second `apply('--catch-up')` skips it again (retry source intact, including with its receipt present), then adding the section and applying a third time ships it; **(b)** red control: the same defective doc on the **explicit** `--pr 43` landing → `SystemExit(5)`, snapshot unchanged (existing behaviour, now pinned); **(c)** planner ownership: the marathon-plan stub returns a real-shaped exit-4 finding `{"check":"marathon-plan/already-closed","file":"PROJECT/2-WORKING/GH-422-fixture.md","message":"issue #422 is CLOSED but the ledger lists it under \"In progress\""}` during the mixed batch → run still exits 0 with the unrelated-drift WARNING; **red control**: the same finding naming GH-421 (actually reconciled) → `SystemExit(6)` and full rollback; **(d)** `WorkflowTests`: pins `issues: write`, `id: reconcile`, `2>&1 | tee "$RUNNER_TEMP/reconcile.log"`, `if: always()`, `--status "${{ job.status }}"`, and the report command. New `test/gh684-hosted-lane-report.sh` (registered after `gh421` in `validate.sh`): a stub `gh` on `PATH` records every call and asserts each mutating body contains the run URL; cases: red + ERROR line, no open issue → `label create` + `issue create`; red + open issue → `issue comment`, no create; success + one skip line (generated by importing `wave_reconcile.SKIP_MARKER`, not retyped) → comment, never close; success + no skips + open issue → `issue close`; success + nothing open → **no mutating calls** (discovery `issue list` is allowed); failure with an empty/missing log → still creates ("no terminal error line captured"); **red control witnessed**: a mutant that omits the run URL trips the stub's assertion. `gh53`: 10/10 green in a disposable clone at the PR head, ≥1 red in the same loop at the base; **causal red control**: undo only the settings dedupe while keeping the forced distinct timestamps → deterministically red.

## Acceptance checks (falsifiable)

New-behaviour proofs (each with its witnessed red control):
- [ ] `gh421` (a)(c)(d) green at the PR head; removing the S2 skip branch turns (a) red; removing the `reconciled_issues.discard` turns (c) red while (a) stays green; reverting the YAML turns (d) red. (b) is a preservation pin and stays green on base.
- [ ] `gh684-hosted-lane-report` green; the omitted-run-URL mutant is witnessed red; the skip line the suite feeds is produced from `SKIP_MARKER`, not retyped.
- [ ] `gh53` 10/10 green at the PR head; ≥1 red witnessed in the same loop at the base; the dedupe-only revert (timestamps still forced apart) is witnessed red.

Preservation checks (expected green on base too — regression evidence, not proof):
- [ ] `gh496`, `gh202`, `gh232`, `wave-reconcile.sh`, `gh358`, `gh421`'s pre-existing cases unchanged and green.
- [ ] Full `validate.sh` in the disposable clone; receipts (green and red outputs with provenance) in `TESTS-RESULTS/<date>+GH-684/`.

Hosted proof (post-merge, recorded on #684, in this order):
- [ ] The workflow stays disabled until this PR merges. After merge: `gh workflow enable wave-reconcile.yml`, then one `workflow_dispatch` run as the recovery proof — it runs `--catch-up` with the new code, must complete green, land its reconcile (this PR's docs promoted), **report GH-505 as `SKIPPED`** (its doc is still defective) and open the `hosted-reconcile-attention` issue naming it. That dispatch is the first hosted success since 2026-09-11. The next PR-close event then proves the PR path; the next scheduled run proves the retry (GH-505 skipped again until its doc is fixed).

## Risks / rollback

- **Skipping is a policy change** for catch-up only: a defective backlog doc no longer blocks other issues. The item stays visible (roadmap row not Completed, doc in `2-WORKING`, `SKIPPED` line, alert issue) and is retried each run. Explicit landings are unchanged. Rollback: revert S2; the run reverts to fail-closed.
- **`issues: write`** widens the job's token by one scope; the tool only touches issues carrying its label. Rollback: revert the permission and the step.
- **S3 changes a test fixture and a comment**, not the resolver; if the fixture change is wrong the suite goes red deterministically instead of randomly.
- The hosted runner is `macos-latest`; nothing here changes the runtime or the qualification.

## RELEASES rating (2026-09-18)

`rated 80/75/50/60` — **pri 80**: blocks #591's acceptance and every merge's paperwork; growing backlog (≥9 closed issues stranded in `2-WORKING`). **sev 75**: work-blocking for governance, recoverable (manual local reconcile works), no data loss; recurrence is 59 incidents in 6 days of one class — assessed, not multiplied. **appeal 50**: neutral, no user preference given. **effort 60**: ~250 insertions across a YAML step, one new ~70-line tool, ~25 lines in the reconciler, fixture fix, tests; no schema or kernel change. Recurrence window: 2026-09-04→09-17 vs 08-21→09-03 — the hosted lane only exists since 09-10 (#421/#591), so the earlier window has no data (unknown trend, not zero).
