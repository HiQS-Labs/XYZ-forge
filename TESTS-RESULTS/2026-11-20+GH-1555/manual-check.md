# Manual Check — GH-1555 (KS-10: Kickstart Wiring for 3+ PR Merge-Cleanup Batches)

Date: 2026-11-20
Scope: `skills/1-hourly/kickstart/SKILL.md` (`route=docs`; docs-only change, no new dispatcher or test suite per GH-831).

## 1. Executable Disposable-Clone Probes (`outputs/disposable-cli-probes.txt`)
*Real runtime executions inside a disposable full clone with isolated `HOME` and a read-only fake `gh` shim (answers `pr list` with 3 fixture open PRs; refuses any mutating subcommand; zero remote or working-tree mutations):*
- **Probe 1A (executable `ledger_merge.landing_forecast` — clean-set fold did not run):** invoked `landing_forecast(disp, base_sha, [1501, 1502, 1503], heads)` on 3 real fixture commits (`1501` clean, `1502`/`1503` conflicting on `ks10_conflict.txt`) with the second `_fold` call returning `unknown`. Observed `recommendation: None` and verbatim reason `forecast incomplete, no recommendation: clean-set fold did not run at #1501 (simulated clean-set fold timeout)`.
- **Probe 1B (executable `ledger_merge.landing_forecast` — unknown member, no monkeypatch):** invoked `landing_forecast(..., unknown={1503: 'head fetch failed'})`. Observed `recommendation: None` and verbatim reason `forecast incomplete, no recommendation: #1503 (head fetch failed)`.
- **Probe 2 (executable `merge_cleanup.py --execute` on 3 pinned PRs without `--landing-plan`):** passed PR discovery and pin verification, reached GH-1066's `EXIT_LANDING_PLAN_REQUIRED` gate, printed `To proceed, re-run with: --landing-plan direct|group --landing-reason "<justification>"`, and exited non-zero (`rc=7`) with zero mutation calls.

## 2. Source Inspection (Distinct from Executable Probes Above)
- Inspected `merge_cleanup.py` lines 2775–2776 (`if len(listed_order) >= 3: forecast = build_landing_forecast(...)`) and lines 2204–2205 (`if dry_run: log("[DRY RUN] Would merge PR ...")`, confirming per-PR dry run does not advance the integration head).

## 3. Retained Instruction-Level Scenario Walkthrough (Pre-Change vs Revised `SKILL.md`)
*Explicitly labeled as instruction-level evidence quoting decisive rules from revised `skills/1-hourly/kickstart/SKILL.md` ("Batch Planning & 3+ PR Landing Defaults (KS-10, U5/U9)"), distinct from executable Probes 1–2 and Source Inspection above:*
- **Pre-Change Red Baseline (`origin/development:skills/1-hourly/kickstart/SKILL.md`):** contained no 3+ PR batch-forecast, `--landing-plan`, GH-1066 reopen, 2-PR sequential-fold distinction, or withheld-forecast HOLD wiring.
- **Scenario 1 — Withheld / Incomplete Forecast (`recommendation: None`):**
  - *Quoted rule:* "Withheld / incomplete forecast (`recommendation: None`): preserve the diagnostic verbatim and use the owner's bounded retry or hold path with **zero dispatch**; NEVER infer a clean set or dispatch blindly, even if valid `--landing-plan` arguments could be supplied."
  - *Observed disposition:* diagnostic preserved verbatim, **HOLD / zero dispatch**.
- **Scenario 2 — Complete `direct` or `direct in passes` Forecast:**
  - *Quoted rule:* "execute each approved pass with `--landing-plan direct --landing-reason \"<reason>\"`, refreshing `--prs` full-SHA pins and reopening affected sequence review after any base, head, or member change; honor configured `qualification.canary_command` and the existing post-batch sweep."
  - *Observed disposition:* dispatched via `--landing-plan direct --landing-reason ...` with exact full-SHA pins and post-batch sweep/`canary_command`.
- **Scenario 3a — `group` Forecast With 3+ PR Clean Subset + Conflict Hubs:**
  - *Quoted rule:* "3+ PR clean subset: execute ONLY after a fresh, complete 3+ PR dry-run forecast proves that subset folds clean and all hard dependencies are met; record remaining conflict hubs as a held separate batch (KS-11b)."
  - *Observed disposition:* fresh 3+ PR dry-run forecast required before subset dispatch; hubs recorded as held separate batch.
- **Scenario 3b — `group` Forecast With 2-PR Clean Subset Where Both PRs Pass Individually Against Base Yet Conflict Pairwise:**
  - *Quoted rule:* "NEVER pad with unrelated PRs to reach 3, and NEVER describe independent per-PR `--dry-run` output as proof of a combined fold ... 2-PR pair: choose one of three supported paths: (i) run disposable-full-clone sequential-fold preparation per `merge-cleanup/SKILL.md:308-313`, recording frozen heads, integration base, order, and actual clean combined-fold result; (ii) dispatch one approved singleton first, then refresh integration base, pins, and affected sequence review before considering the second; or (iii) explicitly HOLD the pair with an owner and recovery condition."
  - *Observed disposition:* independent per-PR dry-run output is NOT accepted as combined-fold proof; the pairwise conflict is caught by sequential-fold preparation or isolated by singleton-first dispatch + refresh (or explicitly HELD), with zero padding to 3.
- **Scenario 4 — Changed Membership, Head SHA, Integration Base, or Ordering:**
  - *Quoted rule:* "A newly ready PR or changed head SHA, integration base, or ordering NEVER silently joins an already-forecast batch: refresh pins and re-run the dry-run forecast (for 3+ PRs) or the appropriate small-subset check (for 1–2 PRs) ... explicitly reopen affected review whenever batch members, ordering, or the integration base change (`merge-cleanup/SKILL.md:299,314-320`)."
  - *Observed disposition:* silent join blocked; pins refreshed, forecast/check re-run, and affected GH-1066 sequence review reopened.
- **Scenario 5 — Post-Batch Sweep & `qualification.canary_command`:**
  - *Observed disposition:* configured `qualification.canary_command` and post-batch sweep honored without adding any new runner.

## 4. Route & PDDA
- `utils/ci-route.sh pull_request` (piped changed files): `route=docs`, `tier=1` (`outputs/ci-route.txt`)
- `./utils/pdda/pdda.sh run`: 0 errors (`outputs/pdda-run.log`)
