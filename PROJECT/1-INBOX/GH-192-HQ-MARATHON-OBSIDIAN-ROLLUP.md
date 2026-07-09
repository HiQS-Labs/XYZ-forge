---
gh_issue: 192
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/192
title: "HQ: bridge marathon-scan.sh's preflight-ready output into the Obsidian daily rollup"
status: Proposed (1-INBOX — not yet active)
created: 2026-07-09
doc_type: feature
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
related:
  - utils/hq/marathon-scan.sh
  - utils/hq/rollup.sh
  - utils/hq/hq-lib.sh
  - PROJECT/3-COMPLETED/GH-158-HQ-MARATHON-SCAN.md
  - PROJECT/3-COMPLETED/GH-27-ROADMAP-DASHBOARD.md
roadmap_exempt: false
---

# GH-192 · HQ: bridge marathon-scan.sh's preflight-ready output into the Obsidian daily rollup

## Problem

`utils/hq/marathon-scan.sh` (GH-158) already polls every PDDA-known repo's
`PROJECT/2-WORKING/*marathon*.md` docs and preflights each active lane (ready /
blocked-not-promoted / blocked-other / stale-already-landed / ambiguous) — but it writes its
aggregate report to `PROJECT/2-WORKING/HQ-MARATHON-<date>.md` in the hub repo, not to Obsidian.

Separately, `utils/hq/rollup.sh` (GH-27) already writes to the operator's Obsidian vault
(`$HQ_OBSIDIAN_VAULT/HQ-Daily-Rollup.md`, default `~/Documents/Noel Saw/Dashboards/HQ-Daily-Rollup.md`)
— but it only scrapes generic `ROADMAP.md` "queue"/"parked"/"in progress"/"next-up" sections via
`agy` synthesis. It has no concept of preflight/ready-marathon classification, and it fully
overwrites `HQ-Daily-Rollup.md` on every run (`agy -p ... > "$OUT_FILE"`), so anything else that
also wrote there would get clobbered on the next rollup pass.

Net effect: there is no single script today that gives the operator a "which marathons are
actually ready to fire, across every known repo" view inside their daily Obsidian note. The two
features were deliberately kept separate — GH-158's own non-goals state "Not a replacement for
`utils/hq/rollup.sh` (GH-27) — that's a ROADMAP-wide Obsidian summary; this is marathon-specific
and preflight-aware."

Confirmed live on 2026-07-09 (this capture): ran `marathon-scan.sh --out <scratch>` directly.
On this device `hq_known_repos` currently resolves only `sleuth-app` (the rebalance-OS sqlite
registry and the `git-pulse-sync/pdda` registry dir are both unavailable here), which scanned 1
marathon doc, preflighted 5 active lanes, all `blocked-other`. Confirms the script runs and
classifies correctly; the registry thinness is a device-local fact, not a defect in this capture.

## Approach (proposed — refine before building)

- Either (a) `rollup.sh` also shells out to `marathon-scan.sh` and folds its aggregate table into
  a new section of the same synthesized `HQ-Daily-Rollup.md`, or (b) `marathon-scan.sh` gains a
  flag that writes/updates a distinct file in the same vault (e.g. `HQ-Marathon-Rollup.md`)
  alongside the existing daily rollup, without touching `rollup.sh`'s own overwrite behavior.
- Whichever approach, must not silently clobber the other script's output on a subsequent run —
  `rollup.sh`'s `agy -p ... > "$OUT_FILE"` is a full overwrite today.
- Known pre-existing gap to account for: GH-158's acceptance criteria record that a live
  `marathon-scan.sh` run once silently dropped sleuth-app due to a `hq_repo_resolve()` bug
  (returns the same path twice, tripping its ambiguity check) — tracked separately, but worth
  re-checking before wiring this into a daily-use path.
- Cross-repo completeness is bounded by which registries are populated on the device the script
  runs from (rebalance sqlite db, `git-pulse-sync/pdda` dir, `~/.config/xyz/registry.tsv`) — not
  something this issue needs to fix, just a caveat for whoever builds it.

## Non-goals

- Not re-litigating GH-158's marathon-scan classification logic itself.
- Not re-litigating GH-27's rollup synthesis prompt/format.
- Not fixing the pre-existing `hq_repo_resolve()` double-candidate bug (separate issue if it's
  still live).
