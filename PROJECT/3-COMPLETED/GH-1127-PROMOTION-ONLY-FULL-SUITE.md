---
gh_issue: 1127
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1127
title: "Full-suite qualification at development → main promotion only; ledgers reconcile locally after each development merge"
status: Complete
created: 2026-10-18
updated: 2026-10-18
owner: claude
goal: "Stop the routine hosted full-suite run on every development merge (#1131) while keeping one hosted full run, on the combined development tip, before every promotion"
doc_type: feature
effort: 2
complexity: 2
risk: 3
phases: 1
fix_probes:
  - "! grep -Eq '^  (pull_request|schedule):' .github/workflows/wave-reconcile.yml"
  - "grep -q 'MERGE_CLEANUP_USE_HOSTED' skills/2-daily/merge-cleanup/scripts/merge_cleanup.py"
---

# GH-1127 — promotion-only full suite; local ledger reconcile

Decision root: #1131 (operator, 2026-10-17). Issue #1127 is the brief. Also folds in the two Codex post-merge review findings filed on #1124 (comment by the Codex review, 2026-10-18): live docs still say hosted qualification is sequential, and `qualification_receipt_matches` ignores the receipt's new metadata.
Branch `feat/XYZ-forge-gh1127-promotion-only-full-suite-2026-10-18` off `development@4fd5dca8`.

## Status

| What was just completed | What's next |
|---|---|
| Plan QA Approved (Codex r3). Implemented; covering suites green (2 pinned assertions adapted, no new cases); manual controls pass; real zero-pending promotion run green (409/409, HEAD commit receipt, 1 rescue recorded) — `TESTS-RESULTS/2026-10-18+GH-1127/` | Final Codex QA → push (pre-push gate) → PR → merge on green CI |

## Observed today (4fd5dca8)

- `.github/workflows/wave-reconcile.yml:3-10` fires on `pull_request: closed` into development **and** `schedule '23 */6 * * *'`, plus `workflow_dispatch`. Every event runs `--catch-up --gate --qualify` (`:64-70`) on `macos-latest` (`:27`): one hosted macOS full run per development merge (49–70 min sequential; 22 min validator / 27 min job under #1134's parallel gate).
- The schedule's catch-up calls `unreconciled_prs` / `unreconciled_commits` (`utils/py/wave_reconcile.py:1288-1420`, reached only when `--qualify` is set, `:1443-1445`). So removing only the PR trigger would still qualify every locally reconciled PR every 6 h.
- `merge_cleanup.py:run_post_merge_reconcile` (`:708-772`) waits up to 90 min for that hosted run (`wait_for_hosted_reconcile`, `:503-601`). It falls back to the **existing** local writer `run_local_wave_reconcile` (`:604-618`, `wave_reconcile.py --pr N`) only when no hosted run appears after a 60 s grace, or the hosted run is red. Without `--qualify`, that local writer reconciles the ledger, docs and PDDA (`wave_reconcile.py:2271-2407`, `:1790-1923`) and never qualifies.
- `batch_record.py:finalize_sweep_inputs` (`:282-314`) tells every above-tier-1 batch to rerun `validate.sh --parallel 4` locally in a throwaway clone (`:312`, shown at `:184-186`).
- Promotion is a GitHub PR from development to main (e.g. merge of #1036). `ci.yml:152` runs `boundary-macos` (`validate.sh --sequential`, full) only **after** a push to main. `test/ci-workflow.sh:254-259` pins that this job never runs on `pull_request` (cost guard: macOS bills about 10× Linux).
- Codex review finding: `qualification_receipt_matches` discards `(summary, meta)` at `wave_reconcile.py:585`, so receipt `mode`, `width`, `first_attempt_failures` and `retries` are never checked against the retained telemetry.
- Codex review finding: these still describe the old cadence: `AGENTS.md:216-219,432-434`, `ROUTER.md:117-126,140-143`, `skills/2-daily/merge-cleanup/SKILL.md:298-303`, `ci.yml:156` comment, `validate.sh:706-711,1309` comments.

## Preflight bet

- **Outcome:** a development merge costs the local reconcile only (minutes, not a 27–70 min hosted queue). The full registry still runs hosted on macOS, once, on the combined development tip, before it is promoted.
- **Smallest bet:** turn the hosted lane from automatic to on-demand, and make the already-shipped local writer the default. Promotion qualification is the same `wave-reconcile.yml` dispatched once on development with one new flag, `--promotion`. Catch-up already gathers every receipt-less landing since cutover and qualifies them in **one** integrated-snapshot run at HEAD (`qualify_landings`, `:642-743`). `--promotion` closes the two gaps Codex found (F1): it forces the full registry instead of the tier selector, and when nothing is pending it qualifies HEAD itself as a commit landing. HEAD is always tested. No new workflow, job, scheduler, receipt schema or test file.
- **Rejected:** (a) adding `pull_request` → main to `boundary-macos`. That inverts a pinned cost guard (`ci-workflow.sh:254-259`), and the job still could not block without branch protection, which this agent cannot read or write (403 per #1127). (b) Deleting `wave-reconcile.yml`. `unreconciled_prs` dates its cutover from the file's add commit (`:1298-1302`), and five suites require the file. (c) Deleting `wait_for_hosted_reconcile`. `test/gh549-work-events.sh:628-654` and `test/gh674-merge-cleanup-hosted-lookup.sh` pin it, and it stays useful for an operator who dispatches the hosted lane deliberately.
- **Rollback:** restore the two triggers and flip the env default. Every receipt keeps its original meaning. Receipt-less landings from the interim are picked up by the next dispatched catch-up and qualified then, never retroactively marked passed.

## Changes (ordered, verification inline)

0. `utils/py/wave_reconcile.py`, F1: add `--promotion` (store_true). It requires `--catch-up --gate --qualify`, and the parser refuses it otherwise.
   - `qualify_landings(..., promotion=False)`: when `promotion` is set, (a) the gate is `QUALIFICATION_GATE` with reason `promotion (#1127): full registry`, and `select_qualification_gate` is not called; (b) if `pending` is empty, `pending = [fetch_commit_metadata(repo_root, tested)]`. That is the existing direct-commit landing shape (`:408-440`), so the receipt is an ordinary `artifact_kind: commit` entry for the tested tip, and `qualification_receipt_matches` already replays it.
   - The pending/gate decision lives in one small pure helper, `promotion_gate(pending, promotion, head_meta, select)`, so it is checkable without a suite run.
   - Call site `:2235`: `if args.qualify and (landing_items or args.promotion)`. The publish retry (`--only-receipted`) never calls `qualify_landings` (`:2240-2256`), so it still never runs the suite.
   - Ordinary `--qualify` without `--promotion` is unchanged: the tier selector and early return still apply, and historical receipts replay as before.
   Verify: manual `TESTS-RESULTS/2026-10-18+GH-1127/promotion-controls.log.txt`:
   - (p1) docs-only pending input (`AGENTS.md`, tier=1) with promotion → `validate.sh --parallel 4`; without promotion → Small. This is the red control: Codex's own probe input.
   - (p2) empty pending with promotion → one commit meta for the tested sha; without promotion → no run.
   - **(p4) actual route, F1 acceptance.** In a disposable full clone of the branch tip (identity bracketed), with every landing already receipted, run `python3 utils/py/wave_reconcile.py --catch-up --gate --qualify --promotion` unsandboxed, with no push. The current development tip has receipts for every landing, so this is naturally the zero-pending case. Retain the command, rc and decisive output, the one full-registry telemetry file (`mode=parallel`, `registered`=registry size, one top-level run), and the written `artifact_kind: commit` receipt for HEAD, replayed True through `qualification_receipt_matches`. Red control: re-run the same helper inputs with the old predicates (`if not pending: return` before the substitution, and `if args.qualify and landing_items`) and show that no run would be launched. This is one real full run of the *new* path (operator: "willing to re-test the new approach 2–3x"); it is not a baseline rerun.
   - (p3) `--promotion` without `--qualify`, and `--promotion` without `--catch-up` → parser error.
   - Then gh421, gh425, gh740.
1. `.github/workflows/wave-reconcile.yml`: delete the `pull_request` and `schedule` triggers and keep `workflow_dispatch`. Dispatch args become `--catch-up --gate --qualify --promotion`. The PR branch of the args step stays as dead code for rollback. Replace the header comment with the #1131 contract: dispatch on `development` before every promotion; the run qualifies all landings since the last receipt in one snapshot and publishes their receipts. Leave the dead PR branch of `if:` and the args step (`:24-26`, `:65-66`) in place. Re-enabling is then a two-line trigger restore.
   Verify: existing `test/ci-workflow.sh` (it parses this file's timeout at `:288-299`), `test/gh421-auto-wave-reconcile.sh`, `test/gh684-hosted-lane-report.sh`, `test/gh740-hosted-lane-publish.sh`.
2. `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:run_post_merge_reconcile`: local by default. Wait for the hosted run only when `MERGE_CLEANUP_USE_HOSTED=1`. Otherwise call `run_local_wave_reconcile` straight away, with no 60 s grace and no hosted lookup. Both call sites stay in the function, so the gh549 AST pin `{wait_for_hosted_reconcile, run_local_wave_reconcile} <= post_calls` still holds unchanged. The dry-run log line names the chosen path. The local writer's own single-writer guard (`check_hosted_reconciler_in_flight`, `wave_reconcile.py:2192-2195`, exit 8 while any hosted run is active) is kept. That means a landing during a promotion dispatch stops instead of racing it, which is the existing contract.
   Verify: existing `test/gh549-work-events.sh`, `test/gh674-merge-cleanup-hosted-lookup.sh` (calls `wait_for_hosted_reconcile` directly; unchanged), `test/gh436-merge-cleanup.sh` (mocks the function). Default merge-cleanup does no hosted polling or grace lookup. The local child `wave_reconcile.py --pr N` keeps its **one** safety query (`check_hosted_reconciler_in_flight`, `gh run list`, `:81-89`, `:2192-2195`) and still refuses with exit 8 while a promotion dispatch is active. `merge_cleanup.py:614-618` already prints that code and message (F3).
3. `skills/2-daily/merge-cleanup/scripts/batch_record.py:finalize_sweep_inputs`: when the classifier selects the full gate, `command` becomes `gh workflow run wave-reconcile.yml --ref <integration>  # full registry, hosted, once before promotion (#1131); no local full rerun`. The Small (tier 1) command is unchanged, because a local Small run is cheap. The `gate` and `gate_reason` fields are unchanged.
   The renderer (`batch_record.py:184-186`) labels it by kind:
   - Small: "Run it in a throwaway clone"
   - Full: "Full sweep deferred to the promotion dispatch (#1131); record `verdict: deferred` with that reason until the dispatch's receipt exists, or `clean` naming the hosted run"
   The CLI echo at `merge_cleanup.py:1733` shows the same command string. No machine parser of `command` was found in the bounded searches of merge-cleanup and its test wrapper (Codex F4).
   Verify: existing `test/gh436-merge-cleanup.sh` batch cases.
4. `utils/py/wave_reconcile.py:qualification_receipt_matches` (`:585`): keep the returned `meta`. For each of `mode`, `width` and `first_attempt_failures` **present** in the entry, require equality with the recomputed meta. If `retries` is present, require `len(first_attempt_failures)`. Absent keys keep historical semantics, so every pre-#1134 receipt still matches.
   Verify: `gh740` (replays a receipt), `gh425`, and the committed `TESTS-RESULTS/2026-10-17+GH-1114/reader-controls.py.txt`, re-run. Manual check `TESTS-RESULTS/2026-10-18+GH-1127/receipt-meta-controls.log.txt`: the committed 65f70cc5 receipt plus telemetry replays True; the same receipt with `mode: sequential`, `width: 1`, `retries: 1` or `first_attempt_failures: ["x"]` each replays False; the committed 61e27ed8 receipt, which lacks the keys, replays True.
5. Docs, text only: `AGENTS.md:216-219,432-434`, `ROUTER.md:117-126,140-143`, `skills/2-daily/merge-cleanup/SKILL.md:298-303` (and its Phase 5 summary line if it names the hosted wait as default), `ci.yml:154-158` comment, and `validate.sh:706-711,1309` comments. Each names its evidence boundary:
   - development merge = local reconcile + pre-push gate
   - promotion = dispatched hosted `wave-reconcile` full run on the development tip (parallel per #1134), then the post-push `boundary-macos` sequential witness on main (unchanged, operator's call under #1131 to flip)
   - `ci-local.sh` stays sequential
   Add the promotion procedure to `AGENTS.md`. Evidence is bound to the candidate that is actually merged (F2):
   1. **Quiet window from dispatch until the promotion PR is merged.** No PR merges or direct pushes to development during the window. The local writer's in-flight guard (exit 8) only refuses the *reconciliation* after a landing, never the merge itself (`merge_cleanup.py:713-716,749`), so the window is procedural and the operator holds it.
   2. `gh workflow run wave-reconcile.yml --ref development`, then take the run id from `gh run list --workflow wave-reconcile.yml --limit 1` and `gh run watch <id>` until it succeeds.
   3. `git fetch origin development`. Choose the receipt whose `run_url` ends in `/<id>` (`wave_reconcile.py:738-740`), not just the newest one. Then require all of:
      - `gate == "validate.sh --parallel 4"` and `result == "pass"`;
      - no `deferred` line in that run's log (`gh run view <id> --log`);
      - `git merge-base --is-ancestor <tested_commit> origin/development`;
      - every commit in `<tested_commit>..origin/development` is authored by `BOT_AUTHOR_EMAIL` (`wave_reconcile.py:1356`), and its changed paths pass the publisher's own allowlist `hosted_lane_publish.declared_paths` (`hosted_lane_publish.py:49-86`).
      Any failure means redispatch.
   4. Open the development → main PR. **Immediately before merging it**, fetch again and re-run step 3 against the PR's head SHA (`gh pr view <n> --json headRefOid`). If anything changed, redispatch.
   5. After the merge, `boundary-macos` witnesses main sequentially (unchanged).
   - Also update the merge-cleanup `SKILL.md` sweep text (`:22`, `:416-421`, `:435-437`). Full sweeps are deferred to the promotion dispatch; Small sweeps still run locally.
   - Also update the `hosted_lane_report.py:104-107` wording "next run" to "next dispatch" (F4/Nit).
   Verify: `utils/pdda/pdda.sh run` clean; `test/gh544-parallel-default.sh`, which pins the ci.yml literal, still green.

## Non-goals

- `ci.yml` jobs and triggers, including `boundary-macos` mode (`:203`) and the advisory Ubuntu canary on development pushes (`:248-250`). The canary is advisory, Linux-billed and not qualification. Removing it is an operator option, not part of this change.
- Branch-protection or ruleset wiring that makes the promotion run a *required* check. That needs an authorized reader and writer (#1127 records the 403). Recorded as a carry-over for the operator.
- `wave_reconcile.py` catch-up, cutover or lifecycle logic; `ci-local.sh`; `validate.sh` behavior; the pre-push hook; any new test file or case (GH-831; per-case operator approval).
- Removing `wait_for_hosted_reconcile` or the hosted lane scripts.

## Risks

- **Interim gap:** landings between merges and the next dispatch carry no qualification receipt. That is the decision, not a defect. The receipts appear at the promotion dispatch.
- **A large first dispatch:** qualifying many landings at once is one run (an integrated snapshot), not N runs. Its log names the count.
- **Promotion without a dispatch:** procedural, not enforced (see non-goals). `boundary-macos` still runs the full registry on main afterwards, so a regression is caught post-promotion at worst. That is the same exposure as today's post-push design.

## Acceptance

| # | Check | Red control |
|---|---|---|
| A0 | `--promotion` forces the full gate and qualifies HEAD when nothing is pending, end to end | p1 (docs-only → full; Small without the flag), p2 (empty → HEAD commit; none without the flag), p3 parser refusals, **p4 real zero-pending run in a disposable clone: full telemetry + replayable HEAD commit receipt**; old predicates launch nothing |
| A1 | wave-reconcile.yml has only `workflow_dispatch` as a trigger, with `--promotion` in its args; ci-workflow, gh421, gh684, gh740 green | fix_probe 1 fails on the base commit |
| A2 | Without the env var, merge-cleanup skips `wait_for_hosted_reconcile` (no hosted polling or grace lookup) and calls the local writer, which keeps its one in-flight safety query. With `MERGE_CLEANUP_USE_HOSTED=1` it takes the hosted path. gh549, gh674, gh436 green | manual: monkeypatched wait raising → not reached when the env is unset, reached when set; local-writer argv recorded |
| A3 | batch sweep command and label: tier 3 → dispatch line with the deferred label; tier 1 → unchanged local command | manual: `finalize_sweep_inputs` + render on a stub record for each tier |
| A4 | receipt-meta controls as in step 4 | each tampered field → False; legacy receipt → True |
| A5 | docs name the new boundaries; the AGENTS.md procedure binds evidence to the dispatch run id and the merged head; `pdda.sh run` clean; gh544 green | manual (fixture repo + the real `declared_paths`): passes on bot-authored allowlisted commits after tested_commit; fails on (i) a source commit after tested_commit, (ii) a bot commit touching a non-allowlisted path, (iii) a remote advance absent from the stale tracking ref until fetched, (iv) a receipt chosen by recency whose `run_url` is not the dispatch id |
| A6 | Pre-push gate for the changed paths (routes full: workflow + core skill code) | — |

## Carry-overs (operator)

- [ ] Optional: make the promotion dispatch a required check via branch protection or a ruleset (authorized reader needed).
- [ ] Optional, under #1131: `ci.yml:203` boundary to `--parallel 4`; retire the advisory Ubuntu canary on development pushes.
