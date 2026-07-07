---
gh_issue: 158
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/158
title: "HQ marathon scan: automate cross-repo marathon aggregation + preflight"
status: Shipped 2026-07-06 (codex build + agy Approved; validate.sh 104/104 on re-run) — one known integration gap, see Acceptance criteria
created: 2026-07-06
updated: 2026-07-06
doc_type: feature
complexity: 3
risk: 2
effort: 3
phases: 1
ratings_provisional: false
non_goals:
  - Not firing marathon-drive.sh in any target repo — aggregation + preflight only, same
    boundary GH-88 drew for cross-repo launching (stays v1.1, not this)
  - Not a replacement for utils/hq/rollup.sh (GH-27) — that's a ROADMAP-wide Obsidian
    summary; this is marathon-specific and preflight-aware
  - Not writing any file to a target repo — read-only over every repo except the hub
related:
  - utils/hq/hq.sh
  - utils/hq/hq-lib.sh
  - utils/hq/rollup.sh
  - utils/swarm-preflight.sh
  - PROJECT/3-COMPLETED/GH-88-CROSS-REPO-MARATHON-MONITOR.md
  - PROJECT/2-WORKING/HQ-MARATHON-2026-07-06.md
roadmap_exempt: false
---

# GH-158 · HQ marathon scan — automate cross-repo marathon aggregation + preflight

## Problem

Two manual HQ passes (2026-07-06 and 2026-07-07) built a cross-repo "master marathon" view
by hand: query the Git Pulse Sync PDDA registry (`utils/hq/hq.sh registries`), find each
repo's `PROJECT/2-WORKING/*marathon*.md`, filter to Active/Held status, run
`swarm-preflight.sh --dry-run` on every lane, and aggregate into a single
`PROJECT/2-WORKING/HQ-MARATHON-<date>.md` doc. See
[HQ-MARATHON-2026-07-06.md](HQ-MARATHON-2026-07-06.md) for both passes' actual output.

Both passes found real, non-obvious drift a script would catch for free:

- sleuth-app's Wave 1 lanes were BLOCKED only because their capture docs sat in
  `PROJECT/1-INBOX/` instead of `PROJECT/2-WORKING/` — mechanical, one-line `git mv` fix,
  not a real blocker.
- sleuth-app's GH-355 and this repo's own `relay-to-issue-skill` were both "queued" lanes
  that had actually already shipped — `ROADMAP.md`'s ledger just wasn't updated, so
  `marathon-plan.sh` kept re-queueing already-done work as a ghost lane.
- rebalance-OS grew a second marathon file (`MARATHON-2026-07-06-B.md`, Held by design)
  between the two passes — nothing surfaced that automatically; it took a manual re-scan
  to notice a new file had appeared.

No automated tool does this today. `utils/hq/` only has `hq.sh` (resolve/status/park/
queue/promote/fire — all single-repo actions), `hq-lib.sh`, and `rollup.sh` (GH-27 ad-hoc —
a ROADMAP-only Obsidian summary; not marathon-aware, not preflight-aware). GH-88's
cross-repo marathon monitor is read-only *liveness* (LIVE/STALE/IDLE/GONE via lockfiles +
tick events), not an aggregator over marathon *content* or a preflight runner.

## Approach (proposed — refine before building)

A new read-only script, `utils/hq/marathon-scan.sh`:

1. Enumerate PDDA repos from the Git Pulse Sync registry (reuse `hq_known_repos` /
   `hq_repo_resolve` from `hq-lib.sh` — same primitive `rollup.sh` and `hq.sh` already use).
2. Per repo, find `PROJECT/2-WORKING/*[Mm]arathon*.md` / `*MARATHON*.md` docs and parse each
   doc's frontmatter `status:` (Active / Held / Completed).
3. For Active docs, extract each wave's lane list (gh-issue number, or project-doc path —
   both forms appear in real marathon plans today).
4. Run `swarm-preflight.sh --dry-run --format json` per lane, using **each repo's own**
   vendored preflight script (contracts and target-root context are repo-local, never the
   hub's copy) and classify the verdict:
   - `ready` (exit 0)
   - `blocked-not-promoted` (exit 6, doc lives in 1-INBOX not 2-WORKING — the common case)
   - `blocked-other` (exit 6, any other cause — surfaced verbatim, not auto-explained)
   - `stale-already-landed` (exit 4 — a real ghost, flag distinctly from a live blocker)
   - `ambiguous` (exit 7)
5. Write one aggregated `HQ-MARATHON-<date>.md` in the hub repo, grouping by repo. Held
   marathons are surfaced but **excluded from the "queued work" count** — never treated as
   fireable, matching the judgment call the 2026-07-07 manual pass made for
   rebalance-OS's `-B` file.

Non-goal, restated: this does **not** fire `marathon-drive.sh` in any target repo —
aggregation + preflight only, the same boundary GH-88 drew for "cross-repo launching."

## Zone / lane

New file `utils/hq/marathon-scan.sh` (+ test). Reads `utils/hq/hq-lib.sh` functions but
does not modify them. Independent leaf-util zone — no kernel/relay-drive touch, agy-safe.

## Acceptance criteria

- [x] Running the script with no args reproduces the same aggregation the two manual passes
  produced (use [HQ-MARATHON-2026-07-06.md](HQ-MARATHON-2026-07-06.md) as the fixture/oracle
  — same repos, same lane classifications). **Known gap:** the live run correctly aggregates
  rebalance-OS and xyz-3-agents-swarm, but silently drops sleuth-app — root-caused to a
  pre-existing `hq_repo_resolve()` bug (returns the same path twice as candidates, tripping
  its ambiguity check), not a defect in this script. Tracked separately, not blocking here.
- [x] Correctly classifies all five verdict states above, including Held-not-counted.
- [x] Writes no files to any *target* repo (read-only over sleuth-app/rebalance-OS/etc.);
  only writes the aggregated doc in the hub repo.
- [x] Test coverage (`test/hq-marathon-scan.sh` or similar) for the classification logic
  against fixture marathon docs + fixture preflight JSON output — all five states. 11/11 green.

## Swarm Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "main" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "path_absent", "path": "utils/hq/marathon-scan.sh" },
    { "type": "path_absent", "path": "test/hq-marathon-scan.sh" }
  ],
  "artifacts": [
    "utils/hq/marathon-scan.sh",
    "test/hq-marathon-scan.sh"
  ],
  "artifacts_new": [
    "utils/hq/marathon-scan.sh",
    "test/hq-marathon-scan.sh"
  ],
  "remediation": "Build utils/hq/marathon-scan.sh per the Approach section: enumerate PDDA repos via hq-lib.sh's hq_known_repos/hq_repo_resolve, find each repo's PROJECT/2-WORKING/*marathon*.md docs, parse frontmatter status, extract Active-wave lanes (gh-issue or project-doc form), run each repo's own swarm-preflight.sh --dry-run --format json per lane, classify into ready/blocked-not-promoted/blocked-other/stale-already-landed/ambiguous, and write one aggregated HQ-MARATHON-<date>.md grouped by repo with Held marathons surfaced but excluded from the queued-work count. Add test/hq-marathon-scan.sh covering all five classification states against fixtures.",
  "lanes": {
    "agy_safe": ["utils/hq/marathon-scan.sh", "test/hq-marathon-scan.sh"],
    "orchestrator_only": [],
    "note": "Independent leaf-util zone: read-only aggregator + preflight runner, no kernel/relay-drive touch. agy-safe, parallel-safe with any other wave lane."
  }
}
```

## Promotion note

Captured in `1-INBOX` per this repo's issue-first convention, then promoted to
`PROJECT/2-WORKING/` on 2026-07-06 — ready for a marathon lane.
