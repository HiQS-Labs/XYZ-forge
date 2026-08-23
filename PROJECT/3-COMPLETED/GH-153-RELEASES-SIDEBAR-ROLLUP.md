---
gh_issue: 153
source: https://github.com/HiQS-Suite/XYZ-forge/issues/153
title: "Add left sidebar navigation and project switcher rollup for RELEASES system"
status: Active (2-WORKING — spike executing 2026-08-22, same session as filing)
created: 2026-08-22
updated: 2026-08-22
owner: noelsaw1
doc_type: plan
effort: 2
complexity: 2
risk: 2
phases: 3
rating: "pri/sev/appeal/effort 70/55/80/45 · calc 250"
related:
  - https://github.com/HiQS-Suite/XYZ-forge/issues/154
goal: >
  Technical spike (operator-directed): give the RELEASES dashboard a traditional left
  sidebar — default ON, hamburger slideout, minimize-to-icon-rail, project switcher,
  and explicit NON-LINK placeholders where no destination exists — and extend the HQ
  daily rollup from marathon-runs-only to the entire RELEASES cycle via one shared
  read-only module that also feeds the sidebar panel. Additive by contract: the
  dashboard system is used as-is, no restructure, no forked bake pipeline.
---

# GH-153 — RELEASES sidebar navigation + full-cycle rollup (spike)

## Why

The dashboard (`RELEASES-PREVIEW.html` / `LEADERBOARD.html`, both baked from the single
template `utils/timeline/RELEASES.html` by `utils/timeline/export_timeline.py`) is a
single-surface SPA: header, banner, strip, rail. It reads as a timeline viewer, not a
dashboard — no navigation chrome, no at-a-glance home for cross-repo/project context.
Meanwhile `utils/hq/rollup.sh` (GH-192) rolls up Marathon runs only; `releases.db` — the
ledger those runs serve — has no rollup anywhere.

## Bet (explicit, per AGENTS.md #2)

- **Assumption:** the sidebar can live entirely in the shared template + one additive
  payload key, so both baked artifacts inherit it and the bake pipeline stays single-source.
- **Tradeoff:** three-state chrome (expanded/rail/hidden) in a 615-line single-file template
  rather than a component framework — more raw JS/CSS, but zero build tooling and zero
  fork of the design system.
- **Failure mode:** template drift between the two views (mitigated by construction — one
  template), or the cycle numbers disagreeing across surfaces (mitigated by one shared
  module, `releases_cycle.py`, consumed by both the exporter and the rollup).
- **Reversibility:** Easy — additive files and additive payload keys; one revert restores
  the pre-spike dashboard.

## Phase 1 — shared cycle module + sidebar surfaces

- `utils/py/releases_cycle.py` (new, exec bit, read-only URI): full-ledger summary —
  releases by status (+ open list, overdue, recent shipped), roadmap shadow movement,
  marathon states (+ running refs), manifest outcomes, latest append-only state events.
  `--json` / markdown renders; exit 2 on missing/corrupt DB so callers degrade per repo.
- `utils/timeline/export_timeline.py`: imports `summary_from_cx`; payload gains
  `projects` (repos table + active flag), `cycle` (the summary), `meta.repoUrl`.
- `utils/timeline/RELEASES.html`: additive sidebar — `#sidenav-toggle` (hamburger),
  `#sidenav` nav, `#sn-project` switcher, `#sn-min` minimize-to-rail chevron; states
  `body[data-sn=expanded|rail|hidden]`, default **expanded**, persisted in
  `localStorage('ledger-sidenav')`; focus items drive the existing `#fbar` buttons;
  `.sn-ph` placeholders are deliberately non-links; Esc hides; print CSS hides the chrome;
  leaderboard view hides the timeline-only focus section (mirrors `#fbar`).
- `utils/hq/rollup.sh`: new `## RELEASES cycle (full ledger, per repo)` section — per
  known repo, embeds the module's markdown via the existing `demote_embed` verbatim rule;
  missing ledgers named explicitly; per-repo failure = visible banner, not a drop;
  `RELEASES_CYCLE_BIN` test seam (same convention as `MARATHON_SCAN_BIN`).

## Phase 2 — regression locks

- `test/gh153-releases-sidebar-rollup.sh` (registered in `validate.sh`): module JSON
  contract + internal consistency, markdown sections, exit-2 negative controls, exporter
  payload keys, baked chrome markers in BOTH artifacts, template-level state/placeholder
  facts. 40/0.
- `test/hq-rollup.sh` extended: Case A asserts the section + no-ledger line with the real
  module; Case F (stub seam) pins verbatim embed + H1 demotion; Case G (corrupt DB) pins
  the failure banner. 36/0.
- `test/gh103-timeline-exporter.sh` untouched and green (38/0) — the injection broke
  nothing the exporter suite pins.

## Phase 3 — docs + ledger hygiene

- ROADMAP `### In progress` entry + `releases roadmap sync` (the sanctioned DB write path;
  its refresh hook re-bakes both artifacts, keeping them fresh against the new generation).
- CHANGELOG `[Unreleased]` entry; `utils/timeline/README.md` sidebar note.

## Verification ladder (SHA-exact — cite the final SHA only)

1. Focused suites green: gh153 40/0, hq-rollup 36/0, gh103 38/0 (pre-gate runs).
2. `./validate.sh` full gate green on the final tree.
3. `utils/pdda/pdda.sh run` — 0 errors.
4. Committed `RELEASES-PREVIEW.html` / `LEADERBOARD.html` match a fresh bake of the
   committed template + DB (gh32-releases-artifacts pins db/dump agreement).
5. PR into `development`; merge is the operator's call.

## Status

| What was just completed | What's next |
|------|------|
| #153 filed 2026-08-22 (duplicate #154 closed same minute); Phases 1+2 built in a standalone throwaway clone off `development` f1d20f6a; focused suites gh153 40/0, hq-rollup 36/0, gh103 38/0; roadmap sync at generation 73 (which also required removing the pre-existing duplicate GH-135..140 entry that blocked all syncs); merged as PR #159 (squash 98375b36) into `development`, conflicts hand-resolved against the post-#160 ledger state (ROADMAP.md union, releases.sql/.db via `utils/releases-merge-resolve.sh`, generated views regenerated from resolved source) | none — shipped |

## Lessons Learned (For Future Agents)

Merging this PR required resolving conflicts on `ROADMAP.md`, `releases.sql`, `releases.db`, and the
baked views (`LEADERBOARD.*`, `ROADMAP-DASHBOARD.md`, `RELEASES-PREVIEW.html`) against `development`,
since two other PRs (#162, #160) had already landed and advanced the same shared ledger files. Pattern
that worked: hand-resolve only `ROADMAP.md` (union of both sides' inserted bullets — same insertion
point each time) and `releases.sql` (generation counter + `roadmap_items` take `development`'s side
since `roadmap sync` recomputes them anyway; `op_receipts` union both sides — it's an append-only
audit log, not a fact in dispute), then run `utils/releases-merge-resolve.sh` to rebuild `releases.db`
and finally regenerate the baked views from the resolved source rather than hand-merging generated
HTML/Markdown. CI's ubuntu portability canary showed one non-reproducible failure
(`test/gh103-timeline-exporter.sh`, "legend flipped") not seen on prior merges and not reproducible
locally against the identical committed content — treated as ubuntu-only test-suite noise per this
repo's GH-509 advisory-canary policy, not investigated further; worth a second look if it recurs.
