---
gh_issue: 1466
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1466
title: "xyz-vendor: --ledger-only mode that vendors only the ledger, reconcile and PDDA scripts (no skills/relay/marathon)"
status: In Progress
created: 2026-11-14
updated: 2026-11-14
owner: operator
goal: "`xyz-vendor.sh <host> --ledger-only` installs a persistent tier=ledger .xyz/ holding only the ledger CLI, reconcile, merge-resolve and PDDA closure, and it survives `xyz-sync update`."
complexity: 2
risk: 2
effort: 2
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Intake, recon at `e0586fc30`, plan drafted. | Codex plan QA via relay-xyz. |

## Problem

`relay-automation/xyz-vendor.sh` has two tiers. Both mirror `relay-automation bin src utils test skills` (about 20 MB and 1,760 files) into `<host>/.xyz/`. A host that only uses the ledger still gets every skill, relay shim, marathon runtime, tick core and test suite. The companion research on a consumer, [BinoidCBD/LTVera-Pandas#1101](https://github.com/BinoidCBD/LTVera-Pandas/issues/1101), found that product work there needs no `.xyz/`. Only governance does: ledger writes, post-merge reconcile and `releases.sql` merge resolution.

## Recon (base `origin/development@e0586fc30`)

**Tier logic** lives in `relay-automation/xyz-vendor.sh`:

| Lines | What it does |
|---|---|
| `:37-58` | Flag parsing |
| `:66-72` | Tier 2 auto-enables, and stays on, when `releases.db` exists |
| `:196` | `tick_version()` reads the **harness** `src/events.js`, not the vendored copy |
| `:202-234` | 5-field registry writer |
| `:236` | `XYZ_RUNTIME_PATHS` (GH-312 preservation) |
| `:396-414` | `register_vendor` |
| `:432-433` | `VENDOR_DIRS`, `RELEASES_OVERLAY` deny-list (GH-197) |
| `:435-505` | `materialize_vendor`, including the runnability check (`bin/tick`, `relay-turn-lib.sh`) and `VERSION tier=1|2` (`:478`) |

**Re-vendor:** `relay-automation/xyz-sync.sh:296` runs `"$VENDOR_SCRIPT" <repo>` with **no flags**, so any host with `releases.db` comes back as Tier 2.

**Drift check:** `xyz-sync.sh:405-460` (`check_rows`) compares the recorded `tick_version` and `source_commit` with the harness's current values. It then greps `relay-automation/relay-drive.sh` for a safety-guard marker (`:83-95`) and prints `SAFETY GUARD MISSING` when the file is absent. Because `tick_version` is harness-derived, a ledger install records the same value as any other install, so there is **no false tick_version drift and no registry schema change needed**. Only the guard probe misfires.

**HQ:** `utils/hq/hq-lib.sh:69` `hq_xyz_lookup` is the single reader that turns registry rows into `XYZ_PATH`. Five `hq.sh` call sites (`:123`, `:248`, `:531`, `:605`, `:647`) derive `has_xyz` → Tier A from it. Filtering there fixes all five.

**PDDA:** `utils/pdda/pdda-lib.sh:6` defaults `PDDA_REPO_ROOT` to two levels above the lib dir. That is `<host>/.xyz` when the copy is vendored. `utils/py/wave_reconcile.py:2098` picks the host's `utils/pdda-local-checks.sh`, otherwise a repo-relative `utils/pdda/pdda.sh`, without `harness_tool()`. `pdda.sh` also calls `$HERE/../py/{pdda_gov_scan,pdda_comment_refs,wave_reconcile}.py`, `$HERE/check_marathon_qa.py` and sibling `pdda-*.sh` files, all inside `utils/pdda/` or `utils/py/`.

**Import and subprocess closure** (traced with grep over top-level and lazy imports plus `$HERE`/`harness_tool` targets):
- `releases_app` → `harness_paths` (`:4718`). Lazy: `work_connectors` (`:1636`, `:5505`, `:5904`, `:5936`) and `jog_run` (`:5201-5238`).
- `work_connectors/` → `releases_app`, `device_config`, `board_sync`. `board_sync` → `device_config`, `harness_paths`, `releases_app`, `work_connectors`.
- `wave_reconcile` → `harness_paths`, `gate_env`, `proc_group`, `releases_app`. Its subprocesses are `marathon-plan.sh` (fatal, `:2059`), `timeline/export_timeline.py` and `leaderboard.sh`.
- `marathon-plan.sh` → `py/marathon_plan.py` → `_marathon_plan` → `router_audit`, `releases_app`, **`swarm_preflight`** (top-level; it imports only `harness_paths`), plus `marathon-plan-zones.default.json`. `swarm-preflight.sh` runs only under `--deep`, so it is excluded.
- `releases-merge-resolve.sh` → `py/releases_app.py`, `timeline/export_timeline.py`, `leaderboard.sh`. `export_timeline.py` → `releases_cycle`.
- `harness_paths`, `gate_env`, `proc_group`, `device_config`, `releases_cycle` and `swarm_preflight` import only the standard library, apart from `harness_paths`.
- `jog_run` is not part of the ledger.

**`harness_tool()`** (`harness_paths.py:92-130`) prefers the host copy and falls back to `harness_home()` (the vendored `.xyz/`). That is the existing seam for vendored tool lookup.

**Existing coverage:** `test/gh197-vendor-tier-split.sh`, `gh105-vendor-releases-addon.sh`, `gh312-vendor-preserves-state.sh`, `gh358-wave-reconcile-vendored-paths.sh`, plus the xyz-sync, hq and pdda suites in `validate.sh`.

## Plan

**Bet check.**
- *Outcome:* hosts that only need governance get a small, persistent ledger install with no agent tooling.
- *Smallest bet:* one new tier in the existing vendor script, plus one-line or few-line fixes where existing readers mistake it for a broken full install.
- *Rejected alternatives:*
  - Skip missing tools inside reconcile: this changes Tier 1/2 failure behaviour and doesn't cover merge-resolve (consult on #1466).
  - A pip package or moving the ledger out of the repo: bigger, and tracked in #1224.
  - Running the writer from an external checkout: unproven for reconcile and loses `VERSION` pinning.
- *Rollback:* re-run with `--with-releases`. The flag is additive, and Tier 1/2 code paths are untouched.

**Non-goals.**
- No change to Tier 1/2 contents or to `wave_reconcile.py` failure semantics.
- No registry schema change.
- No pip packaging (#1224) and no change to write timing (#1458).
- No new test suite or `validate.sh` entry (AGENTS.md *No new tests*, GH-831). The issue's "closure test" is delivered as the vendor's runnability import check plus manual checks under `TESTS-RESULTS/`.
- No removal of `.xyz/` from any host. LTVera adoption is LTVera-Pandas#1101.

**Ordered implementation**, each step verified inline:

1. **`xyz-vendor.sh` flag and tier selection.**
   - Add `--ledger-only` (`TIER=ledger`). Combining it with `--with-releases` exits 2.
   - When neither flag is given, read the existing `$VENDOR_DIR/VERSION`. `tier=ledger` keeps ledger mode, and this check runs **before** the `releases.db` auto-promotion at `:66-72`.
   - Explicit `--with-releases` upgrades a ledger install; explicit `--ledger-only` downgrades a Tier 1/2 install.
   - *Verify:* manual checks M1 and M5–M6.
2. **`LEDGER_MANIFEST` and materialisation.**
   - One space-separated list next to `RELEASES_OVERLAY`:
     - **`utils/py`:** `releases_app.py`, `releases_cycle.py`, `wave_reconcile.py`, `harness_paths.py`, `gate_env.py`, `proc_group.py`, `device_config.py`, `board_sync.py`, `work_connectors`, `marathon_plan.py`, `_marathon_plan.py`, `router_audit.py`, `swarm_preflight.py`, `pdda_gov_scan.py`, `pdda_comment_refs.py`.
     - **Other `utils/`:** `releases-merge-resolve.sh`, `release-lanes.sh`, `marathon-plan.sh`, `marathon-plan-zones.default.json`, `leaderboard.sh`, `timeline`, `pdda`, `pdda-local-checks.sh`.
   - In ledger mode, `materialize_vendor` copies exactly these entries with the same `cp -Rp` it already uses, instead of the `VENDOR_DIRS` mirror. **A missing manifest entry is a hard `die`**: that is the GH-77 drop failure made loud. `RELEASES-DB-FAQS.md`, the `package.json` boundary, `VERSION` (`tier=ledger`), `.DS_Store` stripping and GH-312 runtime-path preservation are all reused unchanged.
   - *Verify:* M1 (file inventory) and M2 (red control: delete an entry in a scratch harness copy → vendor dies naming it).
3. **Mode-aware runnability check.**
   - Under `tier=ledger`, replace the `bin/tick` / `relay-turn-lib.sh` checks with an import smoke on the staged copy: `python3 -I -c 'import sys; sys.path.insert(0, "<stage>/utils/py"); import releases_app, wave_reconcile, work_connectors, board_sync, marathon_plan'`. If it fails, `die` before the swap.
   - This is the closure guard. It runs at every vendor, reuses the existing sanity-check slot, and adds no suite.
   - *Verify:* M3, a red control with `device_config.py` dropped from the manifest in a scratch harness → vendor dies.
4. **`xyz-sync check`.** In `check_rows`, skip the safety-guard probe when `<install>/VERSION` contains `tier=ledger`. The guard protects relay targets, and a ledger install has no relay. *Verify:* M7.
5. **HQ.** In `hq_xyz_lookup`'s read loop, skip a row whose `$install/VERSION` contains `tier=ledger`. All five `hq.sh` Tier A sites follow, and the repo reads as Tier B. *Verify:* M8 (`hq status` / `hq fire` on a ledger host).
6. **PDDA host root.**
   - `pdda-lib.sh:6`: when the lib dir sits at `*/.xyz/utils/pdda`, default `PDDA_REPO_ROOT` to three levels up, the host, instead of two. An explicit `PDDA_REPO_ROOT` still wins. This also corrects the identical latent bug for Tier 1/2 vendored `pdda.sh`, which today scans `.xyz/`; nothing in-repo invokes that path.
   - `wave_reconcile.py:2098`: keep host-first and change the fallback from the literal `utils/pdda/pdda.sh` to `harness_tool(repo_root, "utils/pdda/pdda.sh")`.
   - *Verify:* M4. A broken host capture doc makes vendored `pdda.sh` report an ERROR; before the fix it scans `.xyz/` and reports none.
7. **Jog refusal.** One helper `_import_jog_run()` in `releases_app.py` that catches `ModuleNotFoundError`, prints `jog: unavailable in this install (jog_run.py absent; .xyz tier=ledger?)` and exits 2. It is used by `cmd_jog_run`, `_jog_verb_dispatch` and `cmd_jog_land`. *Verify:* M9.
8. **Docs.** Add the `--ledger-only` usage line and a third tier row to the xyz-vendor.sh header, a short "Ledger-only tier" note in `RELEASES-DB-FAQS.md`, and a CHANGELOG entry.

**Verification.**
- **Focused, during the build:** `bash test/gh197-vendor-tier-split.sh`, `gh105`, `gh312`, `gh358`, and the existing xyz-sync / hq / pdda suites touched by the change.
- **Final:** the classifier route (`utils/ci-route.sh`), expected to be full. Run `bash ci-local.sh` once on the final commit, in a disposable `-gate` clone.
- **Manual checks**, recorded under `TESTS-RESULTS/2026-11-14+GH-1466/` with `provenance.jsonl`. Each runs in a throwaway host repo (`git init` plus a seeded ledger copied from this repo's `releases.sql`), with the harness checkout made unreachable by copying `.xyz/` into a scratch host and calling it by absolute path. `harness_home()` anchors on the file location, so no fallback is possible.

| Check | Expectation |
|---|---|
| **M1** | `--ledger-only`: no `bin/ src/ skills/ test/ relay-automation/`; `VERSION` has `tier=ledger`; file count recorded |
| **M2** | Red control: missing manifest entry → `die` naming it |
| **M3** | Red control: `device_config.py` removed → the import smoke dies |
| **M4** | Vendored `pdda.sh` flags a broken host doc. Red control: same run on the base commit → no finding |
| **M5** | `xyz-sync update <host>` with `releases.db` present keeps `tier=ledger`. Red control: base commit → `tier=2` |
| **M6** | `--ledger-only --with-releases` → exit 2; `--with-releases` on a ledger host → `tier=2` |
| **M7** | `xyz-sync check` on the ledger row: no `SAFETY GUARD MISSING` |
| **M8** | `hq` reports the ledger host as not Tier A; `fire` refuses |
| **M9** | `releases_app.py jog run --dry-run` → exit 2 with the message, no traceback |
| **M10** (smoke, main path) | In the ledger host, `releases_app.py check` exits 0; `roadmap add` then `rate` writes with no `ModuleNotFoundError` on stderr; a non-dry-run `wave_reconcile.py --pr <N> --skip-branch-check` on an offline fixture runs the planner, timeline and PDDA gate |
| **M11** (smoke, adjacent path) | Re-run the vendor on the same host (no flags) and run `releases-merge-resolve.sh` on a conflicted `releases.sql` |

**Acceptance map → issue #1466 checklist.**

| Issue item | Covered by |
|---|---|
| Inventory | M1 |
| Ledger CLI, reconcile, PDDA work offline | M10, M4 |
| Vendored PDDA scans the host | M4 |
| Merge-resolve | M11 |
| Closure test → runnability import smoke | M3 |
| Sticky across `xyz-sync update` | M5 |
| `xyz-sync check` / hq | M7, M8 |
| Flag conflict and upgrade | M6 |
| Jog refusal | M9 |
| Tier 1/2 unchanged | gh197/105/312/358 green |

**Risks.**
- **Future drift:** a lazy import added to a manifest module later can still escape the import smoke. This is a known limit, accepted under GH-831 and noted in the header comment.
- **Python version:** the planner needs Python ≥3.10 (`_marathon_plan.py:121`). The vendor doesn't change that; it is documented in the FAQ note.

## Rating (2026-11-14)

`rated 55/30/50/40`. pri 55: operator-requested now, blocks nothing. sev 30: no crash or data loss; today's cost is about 20 MB of unneeded tooling per host plus drift exposure. appeal 50: neutral. effort 40: about 7 touch points, each small, plus manual verification. Recurrence doesn't apply (feature). The related older vendoring-drift issues are #1011, #715 and #1013.
