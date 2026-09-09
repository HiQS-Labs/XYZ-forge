---
title: Recon Map — roadmap_items.status_marker write path and the wave_reconcile rollback journal
status: Reference (1-INBOX — recon artifact, not a plan)
created: 2026-09-04
owner: noelsaw1
gh_issue: 424
source: https://github.com/HiQS-Labs/XYZ-forge/issues/424
doc_type: research
roadmap_exempt: true
goal: >
  The traced current state behind GH-424, produced before the implementation plan so no plan step
  names a blast radius nobody read. Four parallel read-only lanes plus four hands-on reproductions.
---

# Recon Map — `roadmap_items.status_marker`

Commit: `4503b08d` · Mode: grep+read (no knowledge-graph index for this repo) · Lanes: A, B, C, D all ran

## Subject and change class

**Subject:** the `status_marker` column of `roadmap_items`, its (absent) mutation path in
`utils/py/releases_app.py`, and `utils/py/wave_reconcile.py`'s rollback journal.

**Change class: state/authority.** A column that today has no mutator gains one, and a rollback
journal gains an artifact. Both are contract changes to the ledger's write surface.

## Corrections this recon forced on GH-424's issue body

Recorded first because the issue text is wrong in three places and the plan must not inherit it.

| GH-424 claims | Actually |
|---|---|
| "`roadmap sync` was the only thing that ever set the marker" | **Three writers.** `cmd_roadmap_add:3169` hardcodes `🆕` on every intake; `cmd_roadmap_sync:3522` sets it from parsed markdown; `load_dump:4533` restores whatever the dump holds. The true gap is narrower: **no writer can MUTATE an existing row's marker in releases-mode.** |
| "the enum is `🆕/🚧/✅`, already present in the data" | Three different vocabularies. Parser `_ROADMAP_STATUS_MARKERS` (`releases_app.py:2814`) declares **12**; the two viewers map **4** (`✅ 🚧 ⏸ ‖`) and **exclude `🆕`**; live data holds 3 + NULL. |
| implied: the journal gap breaks committed state | `RELEASES.generated.md` is **gitignored** (`.gitignore:73`). Never in a fresh clone, never in CI. Operator-machine only. |

## Reproductions (debug-mantra step 1 — observed, not inferred)

Run in this clone, restored to HEAD afterwards. Full ledger: `scratchpad/gh424-breadcrumbs.md`.

**R1 — the gap is real, and it is silent.**
`roadmap update --issue-num 425 --raw-text '…✅ marker probe'` → prints `updated GH-425`, exit 0.
Column still `🆕`. It is not a refusal; it is a successful write that ignores the marker.

**R2 — the two representations already diverge, and `check` does not care.**
After R1: `marker=🆕` while that row's own `raw_text` says `✅`. `releases check` → `clean`.
Neither reviewer surfaced this. **It is the design constraint the plan turns on**: an independent
`--status-marker` reproduces the same hazard from the opposite direction.

**R3 — the generated view is gitignored.** `git check-ignore -v` → `.gitignore:73`. Absent here.

**R4 — the rollback mismatch, witnessed.**
`releases gen` (gen 403) → snapshot db+sql (exactly the journal's set) → a ledger write (DB → 404,
**and the gen file auto-follows to 404**) → restore db+sql only →
`FAIL: rule=generation-mismatch: RELEASES.generated.md carries generation 404 but the DB is at 403`.

## The seams — where a change here escapes these two files

| Seam | Location | Crosses | Breaks if |
|---|---|---|---|
| **Live GitHub Projects board** | `board_sync.py:184` — `WHERE status_marker = '🚧'` | process → GitHub API | a real `🚧` writer exists. Today the query is inert because nothing can write `🚧`; after this change, flipping a row starts **creating cards on the live board**. |
| Push gate | `githooks/pre-push:83` → `dashboard-staleness-guard.sh`, pinned by `test/gh243-…` | commit → push | a commit changes `releases.sql`/`.db` without regenerating `ROADMAP-DASHBOARD.md`. Every marker write rewrites the dump. |
| Viewer marker maps | `export_timeline.py:39`, `releases_cycle.py:35` | ledger → HTML/JSON | a marker outside their 4-key maps is written. **`⏸️` (U+23F8 U+FE0F, what the parser declares) never matches `⏸` (U+23F8, what both maps key on).** Latent today; the new flag makes it reachable. |
| Site build | `site_build.py:95-100` | ledger → static site | a `roadmap list --json` row lacks `status_marker` — it **hard-fails**, does not degrade. |
| Receipt chain | `perform_write` `releases_app.py:1205-1288` | write → `releases check` | a marker write bypasses `perform_write`. `check` rule `receipt-chain` catches a receipt-less mutation *after the fact*, never prevents it. |
| Vendor tiers | `xyz-vendor.sh:343-344` | harness → consumer repos | `wave_reconcile.py` ships to **Tier 1** (all of `utils/`); `releases_app.py` is **Tier 2 overlay only**. The journal fix must not assume `releases_app.py` or `RELEASES.generated.md` exist. |
| Test registry | `test/gh306-registry-bidirectional.sh` | new suite → gate | a new `test/*.sh` is not registered in `validate.sh`'s `TESTS`. |

## Call paths in

```
CLI          releases roadmap update            -> releases_app.py:4984 (parser) -> :5097 (dispatch) -> cmd_roadmap_update:3295
intake       hq park                            -> utils/hq/hq.sh:343  -> roadmap add   -> hardcodes 🆕 at :3169
             express                            -> utils/py/express.py:484 -> roadmap add
promotion    jog                                -> utils/py/jog_run.py:1258 -> roadmap repoint
post-merge   wave_reconcile.py                  -> :726 roadmap sync (NO-OP here) -> :727 releases check
```

No cron, no launchd, no CI invocation of any roadmap verb.

## State

**Write sites (all in `releases_app.py`, all via `perform_write`):** `:3169` add (hardcoded `🆕`),
`:3522` sync (no-op in releases-mode), `:4533` `load_dump` (rebuild). `cmd_roadmap_rate:3245`,
`repoint:3286`, `update:3366` never name the column. **There is a single write path — the CLI — and
`perform_write` appends the `op_receipts` row itself "so no writer can forget it" (`:1262-1267`).**

**Read sites:** `board_sync.py:184` (filter, live board), `releases_cycle.py:79` (aggregate),
`export_timeline.py:110` → `:146-153` (branch — **`section` outranks the column**) → `:581` (render),
`site_build.py:95`/`:266` (required key, then render), `releases_app.py:3552`/`:3574` (list),
`:4734-4748` (dashboard HTML), `:1076` (dump round-trip).

**Negative results, verified rc=1:** `utils/roadmap-dashboard.sh`, `utils/leaderboard.sh`,
`utils/py/_marathon_plan.py`, and `utils/py/wave_reconcile.py` contain **zero** references to
`status_marker` or `roadmap_items`. The dashboard renders the emoji out of **`raw_text`**, not the
column — so R2's divergence would display `✅` on the dashboard while the column reads `🆕`.
No skill script reads the column at all.

**Schema:** `status_marker TEXT` (`releases_app.py:602`) — nullable, **no CHECK, no default, no
index**. Installed by migration 2; no migration ever altered it. **A CLI flag writing an existing
column needs no migration and no version bump** — precedent for refusing instead: rule
`schema-behind` at `:3332`.

**Live distribution:** `🆕` 54 · `✅` 47 · `🚧` 11 · NULL 5. All 54 `🆕` rows already render as
`unmarked` in both viewers.

## Contracts

| Contract | Where | Breaking if |
|---|---|---|
| Not a frozen twin | `test/gh308-frozen-twin-guard.sh:14-31` — 12 Bash entries, neither `.py` file | — **no `Frozen-twin-exception:` trailer needed** |
| New Bash under `test/` is exempt | `AGENTS.md:260`, guard `:78-86` | — **no `New-bash-exception:` trailer needed** |
| Receipt op name | `test/gh257-roadmap-ledger-fixes.sh:122` asserts `roadmap-update` verbatim | a new op string is introduced |
| `no-update` refusal | `releases_app.py:3321-3323` "pass at least one of --raw-text or --section" | the condition is not extended → `--status-marker` alone is rejected |
| SOP promotion procedure | `SOP.md:80-83` — `--raw-text` must be a bullet starting `- **<title>**` | the new flag regresses it |
| Ledger writes go through the CLI | `AGENTS.md:155-164` "Never hand-edit `releases.sql` or `releases.db`" | a direct `conn.execute` is used |
| No governance constraint on the vocabulary | `git grep` over the six governance docs → **zero** hits for marker/emoji | — the enum is a code decision, not a documented one |
| Zero skill consumers | no `SKILL.md` mentions `roadmap update` | — an optional flag breaks no skill |

## Sequencing into the post-merge reconciler

`wave_reconcile.py` **has no `sqlite3` import** — it never touches the DB directly, only through
subprocesses. A new ledger write must therefore be a `releases_app.py` subprocess call, which is
also what `AGENTS.md:155-164` requires.

`main()` order, with the insertion point:

```
:928-931   validate_and_update_doc      2-WORKING -> 3-COMPLETED / 4-MISC
:932-942   update_roadmap_entry         ROADMAP.md badge + Completed move
   <<-- THE NEW DB WRITE GOES HERE
:985       fix_mangled_roadmap_entries
:988       run_subprocesses   1. roadmap sync (no-op here)
                              2. releases check          <- validates the new write
                              3. export_timeline --preview
                              4. roadmap-dashboard.sh    <- satisfies the GH-243 push guard
                              5. marathon-plan.sh
:996       run_validation_gate          PDDA; exit 7
```

**Before `run_subprocesses` is the only correct slot**, and for two independent reasons: `releases
check` (step 2) must validate the post-write state, and `roadmap-dashboard.sh` (step 4) must run
*after* the dump changes or `githooks/pre-push` refuses the reconcile commit.

**The OPEN-issue guard is duplicated and must be honored at BOTH sites:** `:920-925` (active-doc
branch) and `:946`/`:958-959` (no-doc branch). A merged PR behind a still-OPEN issue is not a
completion.

## Build, failure and rollback today

`RollbackJournal` (`wave_reconcile.py:75-119`) — **not** `Journal`. `snapshot()` silently no-ops for
a path that does not exist (`:83-89`); `deleted_files` is initialized and never used (dead field).
Ten snapshot sites; the artifact set at `:686-696` is a hardcoded 4-tuple.

`express.py:71-77` already defines `RELEASES_PROJECTIONS` + `DRIVER_GENERATED` — **the same five
files, with `RELEASES.generated.md` first.** `wave_reconcile`'s tuple is that list with the first
entry dropped. The omission is a copy that drifted, and the fix is one shared definition.

**Why the gap is invisible:** `verify_rollback_completeness()` (`:146-168`) diffs
`git status --porcelain` against a baseline. **A gitignored file can never appear in porcelain**, so
an unrestored `RELEASES.generated.md` passes the completeness check silently and only surfaces later
as `releases check` rule `generation-mismatch`.

**Byte-unchanged assertions a careless write would trip:** `test/gh32-releases-artifacts.sh:113`
and `:143`, `test/gh32-releases-app.sh:253`, `test/gh69-roadmap-shadow.sh:82`,
`test/gh168-wave-reconcile-scope.sh:136,151`, `test/wave-reconcile.sh:200`,
`test/roadmap-dashboard.sh:9`.

**Every wave_reconcile suite uses a fixture repo with a mocked `releases_app.py`**
(`test/wave-reconcile.sh:145-185`, `gh168:79`, `gh202:226-295`, `gh232:76`, `gh358:47`). A new
subprocess verb means **every one of those mocks must learn it**, or the fixtures break.

## Unknowns

| Unknown | Why it matters | What would settle it |
|---|---|---|
| Whether importing `express.py` has module-level side effects | it holds the canonical 5-file constant the fix should share | read `utils/py/express.py` top-to-bottom past the imports; module-level imports are stdlib-only and `releases_app` is a *function*, so the risk is low but unread |
| Whether any Tier-1 consumer repo exists whose `.xyz/` lacks `releases_app.py` | the journal fix must not assume the gen file is producible there | `grep -h '^tier=' <consumer>/.xyz/VERSION` across known consumers |
| `recover_from_journal`'s treatment of a torn `RELEASES.generated.md` | a crash mid-write is the adjacent failure mode | read `releases_app.py:1414-1500` |
| Whether a `check` rule for marker/`raw_text` divergence would go red on existing data | decides whether R2's hazard can be gated or only warned | `SELECT` rows whose `raw_text` marker != `status_marker` |
| `githooks/dashboard-staleness-guard.sh` internals | whether the new write trips or evades it | read the guard, not only its test |

Five unknowns on a subsystem this size is an honest result, not a manufactured one — the two that
would change the plan are the `express.py` import and the divergence-rule blast radius.

## Current-state radius, one line

The ledger CLI and its 28 `perform_write` call sites; the committed `releases.db`/`releases.sql`
pair and the four regenerated views; `RELEASES.generated.md` on operator machines only; the static
site build; the **live GitHub Projects board** via `board_sync`'s `🚧` query; the push gate; 30
registered test suites, five of which mock `releases_app.py` inside a fixture repo; and every
consumer repo carrying a vendored `.xyz/`, split across two tiers.
