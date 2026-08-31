# DRY skill vs manual audit — blind comparison on LTVera-Pandas

**Target:** `BinoidCBD/LTVera-Pandas` @ `d25bdd8`, both auditors, same HEAD.
**Auditor A (`/dry` skill, Claude):** map committed `40fb97d` at 2026-08-30T10:01:31-07:00, 15 min.
**Auditor B (manual, GLM):** issue [#305](https://github.com/BinoidCBD/LTVera-Pandas/issues/305)
filed 2026-08-30T17:20:13Z, ~90 min.

Blind: A's map was committed before B's issue existed, and A did not read #305 until after.

---

## Result: manual won, clearly

| | `/dry` | Manual |
|---|---|---|
| Findings | 3 | 9 (5 with live divergence) |
| Files read in depth | ~5 | ~30 |
| Time | 15 min | 90 min |
| Existing-issue cross-check | skipped (to stay blind) | all ~100 titles reviewed |
| Languages swept | py + literals | py / sql / sh / html |

Time is a real confound — 6× the budget. But it does not explain the gap in *kind*, below.

## Overlap

**One finding in common.** `/dry` T2 ≈ manual F2: three rival BigQuery client owners.

Manual's version is strictly better and it is worth being precise about why. `/dry` found three
`client.py` modules and counted importers. Manual found the same three **and**: the private-helper
reach-ins (`sync_status.py:15`, `kpis.py:333` importing `_bigquery`/`_impersonated_credentials`), the
byte-billing ceiling hand-set at six different values across six files, the duplicated
`ops.publish_watermarks` freshness query, and the `AGENTS.md` rule the whole cluster violates
("keep BigQuery access behind one thin, swappable wrapper").

`/dry` listed "do the ~23 sites differ on credentials, location, or retry config?" as an **Unknown**.
Manual answered it: only `warehouse_publish` pins scopes and `lifetime=3600`. That answer is the
finding, and `/dry` left it on the table.

## Unique to `/dry` — one, and it is a different class

**The GH-38 guard reports OK while four executable files violate it.**
`scripts/check_no_wpdbtk_pointers.sh` exits 0, yet `PROJECT = "wp-db-toolkit"` sits at
`pipelines/reference_model/export_mki02_sqlite.py:22`, `run_bounce_refmodel_build.py:36`,
`run_mki02_build.py:44`, `deprecated/export_mki02_prior.py:15`, plus `SHOPIFY_PROJECT` at
`scripts/inspect_inventory_state.py:36`. Two holes: `pipelines/` is not in `TARGETS`, and the pattern
matches `DEFAULT_PROJECT`/`BQ_PROJECT` but not bare `PROJECT =`.

Manual saw #38 and recorded it as *closed and covered* (F5: "Distinct from closed #38/#59, which
covered the `wp-db-toolkit` project pointers"). It trusted the closed issue and the green guard.

This is the one place the mechanical sweep beat the reader, and the reason is structural: `/dry`
indexed the literal and then checked the guard against the index, rather than trusting the guard's
exit code. **Auditing the guard, not just the code, is a real technique and it is not in the skill.**

`/dry` T3 (the `wpdbtk` package duplicated across `buffer-server/` and `external/`, diverging at line
334) is also unique — but manual **deliberately excluded `external/`** as vendored and said so. That
exclusion is defensible; call T3 a scope difference, not a win.

## Unique to manual — seven findings, and one class `/dry` cannot see

F1, F3, F4, F5, F6, F7, F8, F9 are all absent from the `/dry` map. Most are simply coverage. But
**F1, F3 and F4 expose a design flaw, not a budget shortfall.**

- **F1** — "real sale" order status defined four times with three different value sets
  (`kpis.py:84`, `decisioning_warehouse.py:50`, `compute.py` inline ×5, `campaigns/config.py:66`).
- **F3** — vendor error-body truncation: 2,000-char canonical vs `nexmail/client.py:222` at 400.
- **F4** — retry/backoff written six times, none with the jitter `AGENTS.md` mandates.

All three are duplicated **knowledge with no shared resource literal**. There is no table name, host,
env var, or binary to index on — the duplication is a *concept* with divergent values.

The `/dry` skill's own one rule excludes them by construction:

> **A finding must name a shared *resource*, never a shared *shape*.**

That rule was written to suppress text-similarity noise, and it does. It also blinds the skill to the
highest-value finding in this repo. F1 is the best single finding in either report.

## What to change in `/dry`

1. **Add a `Policy` resource class.** Named constants, status/enum value sets, thresholds, timeouts,
   retry counts, size ceilings. Index the *name and the value set*, and flag where the same concept
   carries different values. This is what would have caught F1, F3, F4, and F2's six ceilings.
2. **Loosen the one rule to admit it.** A shared *policy constant* is a resource. The rule should
   forbid shared **syntax**, not shared semantics — the current wording overshoots.
3. **Add "audit the guards" to Step 2.** Where a repo ships a CI check for a duplication class, run
   it and test its coverage against the index rather than trusting its exit code. This was `/dry`'s
   only clean win and it happened by accident, not by instruction.
4. **Read the repo's own rules first.** Manual quoted `AGENTS.md` in F2 and F4 and used it to
   separate defect from house style. `/dry` never opened it. Cheap, and it is what makes a finding
   land as a violation rather than an opinion.
5. **Make the issue cross-check mandatory, not optional.** Skipped here for blindness; in real use
   it is what stops the skill re-filing tracked work.

## Honest verdict

On this test the skill did not earn its place. It found one third the findings in one sixth the time,
and its single unique win came from a technique the skill does not actually document.

What it did earn is a specific, actionable diagnosis of its own blind spot — semantic/policy
duplication — which a second run against the same repo can be measured against. That is worth more
than the finding count.

**Not yet tested:** whether `/dry` with the Policy class added closes the gap, and whether it holds up
at equal time budget. Both are cheap to run.
