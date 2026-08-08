---
title: RADAR report 2026-08-07 — xyz-3-agents-swarm, window 2026-07-17..2026-08-07
status: Report (immutable snapshot — never edited after generation; a later run writes a new dated doc)
created: 2026-08-07
updated: 2026-08-07
owner: noel
doc_type: report
generated_by: skills/radar/SKILL.md (GH-442, first calibration run)
window: 2026-07-17..2026-08-07
prior_window: 2026-06-26..2026-07-17
trunk: origin/development
goal: >
  Evidence of record for the 2026-08-07 radar run: flow distribution with trend, recurring-defect
  targets with citations, and RELEASES.md recalibration. Completion state lives in the
  radar-labeled GitHub issue, not here — this doc is never ticked, only superseded.
---

# RADAR — xyz-3-agents-swarm · 2026-07-17..2026-08-07

> Evidence sink (Sink A). The live checklist is in the `radar`-labeled issue. The checklist below
> is the state **at generation time** — a historical record, not a second live copy.

## Lens 1 — Flow distribution

438 commits on `origin/development` in the window; **178 harness-generated excluded** from the RGT
denominator (relay 122, marathon 43, plan 8, capture 2, triage 2, wip 1). Denominator: 260.

| Bucket | Count | Share | Prior window (818 commits, 269 harness, denom 549) |
|---|---|---|---|
| Run | 184 (fix 79, docs 70, chore 27, test 4, ci 2, hotfix 1, cleanup 1) | **71%** | 297 — 54% |
| Grow | 11 (feat) | **4%** | 82 — 15% |
| Transform | 0 (`rgt:` declared nowhere in tree — key adoption is 0) | 0% | 0 — 0% |
| Unclassified | 65 (53 unprefixed + harden/license/release/roadmap/file-xyz-bug/relay-pkg/intake/adjudicate) | 25% | 170 — 31% |

**Trend:** Run 54%→71%, Grow 15%→4% — feature output collapsed ~4x while maintenance grew by a
third. **Verdict:** a deliberate KTLO pivot (the Litmus arc executing), not drift — but nothing new
is growing while it runs, and no work anywhere in the tree is declared Transform.

Caveats: `docs:` → Run is a conservative choice that overstates Run in a docs-driven repo (70 of
184). The 25% Unclassified share is itself a finding — prefix discipline is inconsistent.

## Lens 2 — Recurring-defect targets

Signal base: 66 docs in `PROJECT/**` carry `related:` blocks; 22 docs mention doc-only /
no-code-change resolutions; 11 docs carry `reported_from:` (4 distinct external repos this window).
Per-commit seam heat was flat (max 1 fix-commit per file — GH-432 touched 5 shims in one commit)
and contributed nothing beyond the `related:` graph; recorded as a calibration fact.

### 1. RADAR-class-guards-cant-fail — CLAIMED (Litmus 0.2.0), context not recommendation

The largest cluster: **13 kinship citations** centering #419 ("a documented guard that reads as
active while nothing runs it"), spine #418 #425 #426 #416 #375 #344 #368, family #315 #319 #348.
Already operator-derived into the Litmus release (CHANGELOG 2026-08-05: *"derived from where the
failures actually cluster, not from a backlog sweep"*), milestone holds 16 open issues, target
2026-09-05. Reported for aging only; no checklist.

Note of record: #308 drew 11 citations and is **not** a cluster — every citation is FROZEN-twin
contract context, zero are defect kinship. (This distinction is now codified in the skill.)

### 2. RADAR-ensure-gitignore — UNCLAIMED · top actionable target

One function, `ensure_gitignore()` in `relay-automation/xyz-vendor.sh`, failing in both directions:

| Issue | Date | State | Fact |
|---|---|---|---|
| [#18](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/18) | 2026-06-24 | closed | **created and closed doc-only within 2 hours**; the code gap it named shipped nothing |
| [#314](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/314) | 2026-07-28 | open | day 34 — never un-ignores `phases/`/`relay-system/`, HALTs a marathon mid-chain; reported from **two** repos (LTVera-Pandas, then aegis-sleuth-slack-bot at a cost of an operator afternoon); `--dry-run` cannot see it |
| [#440](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/440) | 2026-08-07 | open | day 44 — adds `.xyz/` but not `/.tick/`, untracked runtime state in every consuming repo |

Span 44 days · blast radius 8 vendored `.xyz/` copies · median effort ~1-2 · doc-only-close boost
applies → **score ≈ 24**, the highest of any unclaimed target. One durable fix (both directions +
regression test + re-vendor sweep) retires all three and the class of future re-reports.
This is also the first confirmed instance of the doc-only-close recurrence predictor.

### 3. RADAR-class-foreign-repo-field-gaps — UNCLAIMED

Vendored-harness runs in foreign repos keep hitting seams the home repo never exercises:
[#312](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/312) (xyz-sync
destroys live `.tick/`/`relay-system/` state, closed),
[#438](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/438) (a
git-index lane cannot complete and false-passes, 2/2),
[#439](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/439) (same-repo
linked worktree splits build and thread across two branches) — sibling of target 2, which shares
the pattern. **5 fresh field reports in 10 days from 4 distinct repos** (`reported_from:` LTVera-Pandas,
aegis-sleuth-slack-bot, giant-brains-claude-skills, + rebalance-OS/pdda/hyper-pandas historically),
all filed via /file-xyz-bug, none claimed by any band.

## Lens 3 — Release recalibration (advisory)

- **Litmus 0.2.0** (16 open, 2026-09-05): **aligned** — the 71% Run share *is* Litmus executing.
- **Nightwatch 0.3.0** ("unattended durability against a real target repo", 15 open, 2026-10-10):
  **drift** — targets 2-3 are precisely Nightwatch-shaped evidence, arriving early from real target
  repos, and the band claims none of them.
- **Orphan share: 67 of 98 open issues (68%) belong to no milestone** — the two bands describe less
  of the backlog than they appear to.

## The ask

Pull targets 2-3 into Nightwatch's band (they are its theme arriving early), or fix the
`ensure_gitignore` seam now, ahead of the calendar? One decision; the checklist is in the issue.

## Checklist as generated (live copy lives in the radar issue)

### RADAR-ensure-gitignore — first-seen: 2026-08-07 · runs: 1
- [ ] Fix `ensure_gitignore()` (`relay-automation/xyz-vendor.sh`) to handle both directions —
      append missing ignores (`/.tick/`, #440) AND un-ignore required tracked paths
      (`phases/`, `relay-system/`, #314) — as one seam, not two append paths
- [ ] Wire the #314 failure into preflight + `--dry-run` naming all three blocked paths (cf. #117);
      explicitly not `git add -f`
- [ ] Add a regression test asserting both directions on a fresh vendor into a repo with a
      pre-existing conflicting ignore rule
- [ ] Re-vendor the 8 affected copies; acceptance: clean `git status` after a driven relay in each
- [ ] Close #314 and #440 with the commit SHA; annotate #18 with the recurrence chain — none of
      them doc-only this time

### RADAR-class-foreign-repo-field-gaps — first-seen: 2026-08-07 · runs: 1
- [ ] Decide the band: assign #314/#438/#439/#440 to Nightwatch or schedule as a pre-release seam
      fix (operator decision — the radar only surfaces it)
- [ ] Add a "foreign-repo shakedown" case to the harness test suite: vendor into a scratch repo
      with hostile `.gitignore` + linked worktree, run one driven relay, assert clean status and
      single-branch landing (covers the #312/#438/#439 shapes)
