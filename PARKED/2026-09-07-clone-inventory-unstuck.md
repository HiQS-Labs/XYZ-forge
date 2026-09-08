# /unstuck classification — six stalled clones — 2026-09-07

## Method correction

The first inventory diffed each clone against **its own stale `origin/development`
ref**. All six were behind: refs ranged from `d0a4179f` to `66130821` while
primary was at `c4088fae`. Every diff in that table was measured against the
wrong baseline.

Re-fetched `origin/development` in each clone, re-diffed, then checked line
provenance — do the branch's *added files* already exist in current development?
— plus live GitHub issue state. Findings below rest on that, not on commit counts.

## Verdicts

| Clone | Issue | Diff vs fresh development | Provenance | Verdict |
|---|---|---|---|---|
| `xyzforge-gh478-runaway-guard` | GH-478 **open** | 21 files, +1553/-126 | 5/5 sampled new files absent from dev | **LAND — first** |
| `marathon-gh-424-status-marker-writer` | GH-424 **open** | 11 files, +763/-114 | 3/3 new files absent | **LAND** |
| `XYZ-forge-flight-dashboard` | GH-494 **open** | 22 files, +1278/-35 | 5/5 new files absent | **LAND** |
| `marathon-gh-462-planner-core` | GH-462 **open** | 87 files, +4638/-585 | 5/5 new files absent | **REVIVE** |
| `marathon-gh-299-gen4-ate` | GH-299 **open** | 22 files, +3341/-465 | 5/5 new files absent | **REVIVE** |
| `gh271-waveA` | GH-271 **closed** 2026-08-28 | 36 files, +2240/-11 | absent, but all archival | **RETIRE** |

No clone's work was superseded. Five carry genuinely unlanded content.

### GH-478 — land first

Smallest complete unit: ships `test/lib/runaway-guard.sh`, `test/gh478-runaway-guard.sh`,
a negative-control baseline, a relay plan-QA record, and a `PROJECT/2-WORKING`
doc. The issue it closes is a real safety failure — a gen4 adaptive-ate test hung
about three days at ~100% CPU. 1 dirty file to resolve. Branch is local-only.

### GH-424, GH-494 — land next

Both small, both open issues, both self-contained. GH-424 adds the missing
`roadmap_items.status_marker` CLI writer — without it a row can never leave 🆕,
which is live in releases-mode today. GH-494 is mockup-only (`docs/mockups/`),
so it is low-risk to land even unfinished. GH-494's clone was touched today —
confirm nobody is mid-edit before moving it.

### GH-462, GH-299 — revive, do not land as-is

Too large to land unreviewed. GH-462 is a marathon umbrella (87 files, adds its
own `MARATHON.yaml` plus six `PROJECT/2-WORKING` docs) and overlaps the governance
surface the active GH-490 marathon is rewriting — land GH-490 first or they
conflict. GH-299 has 10 dirty files and is the only one of the six with a live
remote branch (`feat/gh299-gen4-ate`), so its work is at least backed up.

### GH-271 — retire

Two independent reasons. Its `origin` is
`https://github.com/Hypercart-Dev-Tools/rebalance-OS.git`, not XYZ-forge — it was
never an XYZ-forge clone and my first inventory misfiled it. And its own issue is
closed, with the final commit reading *"cancel release 0.71.0; record Rule 0;
close the project."* All 36 changed files are archival: `PROJECT/3-COMPLETED/
GH-271-SUBTRACTION/` lanes and evidence, `relay-system/2026-08-15/`,
`marathon-system/A2`–`A6` transcripts. Nothing to land. Trash it, or copy the
`3-COMPLETED` tree into rebalance-OS if that record is wanted.

## Parked

- Whether the GH-271 archival record should be preserved in rebalance-OS before
  the folder is trashed. Not blocking.
- `~/Documents/GH Repos/XYZ-forge-merge-cleanup-docs` — 1 file, +3/-2. Fold into
  PR #493 or drop; too small to warrant its own decision.
