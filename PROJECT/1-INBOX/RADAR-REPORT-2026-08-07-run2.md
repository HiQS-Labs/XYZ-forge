---
title: RADAR report 2026-08-07 run 2 (reconciliation) — xyz-3-agents-swarm, window 2026-07-17..2026-08-07
status: Report (immutable snapshot — never edited after generation; a later run writes a new dated doc)
created: 2026-08-07
updated: 2026-08-07
owner: noel
doc_type: report
generated_by: skills/radar/SKILL.md (GH-442) — first run dispatched through the installed skill
window: 2026-07-17..2026-08-07
prior_window: 2026-06-26..2026-07-17
trunk: development @ f95eefc (read from a clean worktree cut from origin)
supersedes: none — RADAR-REPORT-2026-08-07.md (run 1) stays valid as its own snapshot
goal: >
  Evidence of record for the second radar run: the reconciliation pass against issue #444, plus a
  re-read of all three lenses after 63 commits of Litmus marathon landed. Completion state lives in
  #444, not here.
---

# RADAR — xyz-3-agents-swarm · run 2 (reconciliation) · 2026-07-17..2026-08-07

> Second run of the day, same window, +63 commits of delta. Read from a clean worktree at
> `f95eefc` so neither the main checkout's uncommitted work nor a concurrent session could
> contaminate it. First run executed through the **installed** skill rather than by hand.

## Reconciliation summary (the point of this run)

| | Run 1 | Run 2 | Delta |
|---|---|---|---|
| Commits in window | 438 | 501 | +63 (Litmus marathon, PR #443) |
| RGT denominator | 260 | 276 | +16 |
| Run / Grow / Transform / Uncl | 71 / 4 / 0 / 25 | **71 / 5 / 0 / 24** | ~1pt — **the mix did not move** |
| Targets | 2 actionable | 2 actionable | **0 retired, 0 added** |
| Orphan share | 67/98 (68%) | 67/99 (68%) | unchanged |
| Unshipped release bands | 2 | **3** (Plumbline added) | +1 |

**The headline is that 63 commits changed nothing the radar tracks.** A full marathon shipped four
Litmus lanes, and: the flow mix moved ~1 point, both targets carry forward untouched, and the
orphan share is identical. This is the aging signal working — not a null result.

## Lens 1 — Flow distribution

501 commits on `development` in the window; **225 harness-generated excluded** (relay 135,
marathon 73, plan 11, triage 2, capture 2, wip 1, relay-pkg 1). Denominator: 276.

| Bucket | Count | Share | Run 1 | Prior window |
|---|---|---|---|---|
| Run | 195 (fix 82, docs 76, chore 28, test 5, ci 2, hotfix 1, cleanup 1) | **71%** | 71% | 54% |
| Grow | 14 (feat) | **5%** | 4% | 15% |
| Transform | 0 | 0% | 0% | 0% |
| Unclassified | 67 | 24% | 25% | 31% |

Unclassified verbatim: UNPREFIXED 55, roadmap 2, release 2, license 2, file-xyz-bug 2, intake 1,
harden 1, adjudicate 1, revert 1. Adjusted read: `revert:` is maintenance and belongs in Run; the
rest are genuinely unclassifiable without reading each commit. Adjustment is <1pt — unlike the
second calibration repo, mechanical inference is accurate here.

**`rgt:` adoption remains 0 documents repo-wide.** Transform therefore reads 0% *structurally* —
this is "nobody has declared anything," not "no transformative work happened." The number cannot
become non-zero until the key is adopted, and that limitation should be read into every Transform
figure this tool has ever printed.

**Verdict:** unchanged from run 1 — a sustained KTLO pivot, now with 63 commits of confirming
evidence. Grow at 5% against a 15% prior baseline is the fact worth watching.

## Lens 2 — Recurring-defect targets

Signal yields this run: signal 1 — **184 docs carry `related:`, references extracted successfully**
(top: #1 ×21, #2 ×19, #3 ×18, #419 ×14, #308 ×13, #48 ×9); signal 2 — no new seam heat on any
target file; signal 4 — 22 docs mention doc-only resolutions.

**Kinship-vs-context filter did real work again.** The three most-cited issues (#1, #2, #3 at
21/19/18) are foundational context, not defect kinship — the same trap #308 set in run 1, now with
three larger instances. Applying the filter, #419 at 14 citations (up from 13) remains the top
kinship cluster.

### 1. RADAR-class-guards-cant-fail — CLAIMED (Litmus), runs: 2

#419 spine, 14 kinship citations (+1). Litmus shipped 4 lanes this window yet the milestone's open
count went **16 → 17**: the arc is producing new work as fast as it closes it. Reported for aging;
no checklist, still correctly claimed.

### 2. RADAR-ensure-gitignore — UNCLAIMED · runs: 2 · **no movement**

#18 (closed doc-only 2026-06-24) → #314 (day 34) → #440 (day 44). All still open;
**zero commits touched `relay-automation/xyz-vendor.sh` since run 1.** Span now 44 days and
counting. Score unchanged at ≈24, still the highest-scoring unclaimed target.

### 3. RADAR-class-foreign-repo-field-gaps — UNCLAIMED · runs: 2 · **no movement**

#312 (closed) · #438 · #439 open, none assigned to any milestone. No new field reports this window.

## Lens 3 — Release recalibration (advisory)

Three unshipped bands now — **Plumbline 0.4.0 was added since run 1** (target 2026-11-14,
"assisted reflection and a bounded self-improvement loop, measured before either is trusted",
GH-431), joining Litmus 0.2.0 and Nightwatch 0.3.0.

- **Litmus** (17 open, 2026-09-05): aligned; the 71% Run share is this arc executing.
- **Nightwatch** (15 open, 2026-10-10): **drift persists, now two runs deep.** Targets 2 and 3 are
  Nightwatch-shaped evidence — real-target-repo durability failures — and the band still claims none.
- **Plumbline** (2026-11-14): depends on Nightwatch; no radar target speaks to it.
- **Orphan share: 67 of 99 open issues (68%)** — unchanged across a 63-commit marathon.

**The recalibration finding sharpened by having two runs:** a *third* planning band was added while
the top two unclaimed targets went untouched and unassigned. Planning is extending forward faster
than the existing bands absorb the field reports already in hand.

## The ask

Same question as run 1, now with 44 days of non-movement behind it: assign #314/#438/#439/#440 to
Nightwatch, or fix the `ensure_gitignore` seam directly? A third run will report this target at
runs: 3 and the span will read 50+ days.

## Checklist as generated (live copy lives in #444)

Carried forward unchanged from run 1 — no item completed, none struck through.

### RADAR-ensure-gitignore — first-seen: 2026-08-07 · runs: 2
- [ ] Fix `ensure_gitignore()` (`relay-automation/xyz-vendor.sh`) to handle both directions
- [ ] Wire the #314 failure into preflight + `--dry-run` naming all three blocked paths (cf. #117)
- [ ] Add a regression test asserting both directions on a fresh vendor
- [ ] Re-vendor the 8 affected copies; acceptance: clean `git status` after a driven relay in each
- [ ] Close #314 and #440 with the commit SHA; annotate #18 with the recurrence chain

### RADAR-class-foreign-repo-field-gaps — first-seen: 2026-08-07 · runs: 2
- [ ] Decide the band: assign #314/#438/#439/#440 to Nightwatch or schedule as a pre-release fix
- [ ] Add a "foreign-repo shakedown" case to the harness test suite
