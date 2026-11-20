# Manual Check — GH-1555 (KS-10: Kickstart Wiring for 3+ PR Merge-Cleanup Batches)

Date: 2026-11-20
Scope: `skills/1-hourly/kickstart/SKILL.md` (`route=docs`; docs-only change, no new dispatcher or test suite per GH-831).

## 1. Executable Disposable-Clone CLI / Contract Probes (`outputs/disposable-cli-probes.txt`)
*Labeled distinctly as measurements of the existing `merge-cleanup` / `ledger_merge` CLI contracts in a disposable full clone (zero local/remote mutations):*
- **Probe 1 (`ledger_merge.py` withheld forecast branch):** confirmed `recommendation = None` when clean-set fold did not run.
- **Probe 2 (`merge_cleanup.py --execute --prs 1501,1502,1503` without `--landing-plan`):** exited non-zero (`rc=2`) refusing execution without `--landing-plan` / `--landing-reason` (GH-1066 gate).
- **Probe 3 (`merge_cleanup.py` threshold & dry-run semantics):** verified `if len(listed_order) >= 3: forecast = build_landing_forecast(...)` (`L2775-2776`) and per-PR `--dry-run` `Would merge ...; continue` (`L2204-2206`, proving a 2-PR dry run does not advance the integration head).

## 2. Retained Instruction-Level Scenario Walkthrough (Pre-Change vs Revised `SKILL.md`)
*Explicitly labeled as instruction-level evidence quoting decisive rules from revised `skills/1-hourly/kickstart/SKILL.md` ("Batch Planning & 3+ PR Landing Defaults (KS-10, U5/U9)"), distinct from the executable CLI probes above:*
- **Pre-Change Red Baseline (`origin/development:skills/1-hourly/kickstart/SKILL.md`):** contained no 3+ PR batch-forecast, `--landing-plan`, GH-1066 reopen, 2-PR sequential-fold distinction, or withheld-forecast HOLD wiring (leaving 3+ PR batches to ad-hoc operator questions or blind dispatch).
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

## 3. Route & PDDA
- `utils/ci-route.sh pull_request` (piped changed files): `route=docs`, `tier=1` (`outputs/ci-route.txt`)
- `./utils/pdda/pdda.sh run`: 0 errors (`outputs/pdda-run.log`)
