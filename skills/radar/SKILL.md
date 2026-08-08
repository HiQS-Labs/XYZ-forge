---
name: radar
description: >-
  Per-repo strategic compass over the last 2-3 weeks of activity. Reports the Run/Grow/Transform
  flow distribution (are we treading water or moving the needle), clusters recurring defects into
  high-value fix targets ranked by what one durable fix would retire, and flags where RELEASES.md
  planning has drifted from what the repo is actually doing. Analysis is read-only; findings persist
  to two sinks (an immutable dated report doc + one live radar-labeled issue checklist) so they
  survive across sittings. Use when the operator asks "what have we actually been doing", "are we
  just fixing bugs", "what keeps breaking", "what should we fix once to stop the bleeding", "is the
  plan still right", "strategic review", "impact review", "run the radar", or "/radar". Not for
  end-user shipped recaps (weekly-shipped), not for ranking marathon candidates (marathon-triage),
  not for maturity assessment (/honest), and it never executes fixes (/10days does that).
---

# radar

A per-repo compass: three lenses over one window, then a persisted, reconcilable report.
Every claim cites a commit, file, or issue. Tracking issue: GH-442.

## Guardrails

- **Analysis reads; only the report writes.** The two report sinks (Step 5) are the *only* writes.
  Never edit an existing doc, never edit ROADMAP.md, never commit, never push.
- **Never edit RELEASES.md.** Absent, sparse, or stale are all valid states (its §GH-381 forbids
  topping it up). Report drift; stop there.
- **Transform is declared, never inferred.** No commit prefix promotes work to Transform — only an
  explicit `rgt: transform` frontmatter key on the governing `PROJECT/**` doc. Auto-promoting
  `perf:`/`refactor:` would inflate the one number this exercise exists to keep honest.
- **Cite or drop.** An uncited target is a guess.
- **No targets → write nothing.** Report the flow distribution in-session and stop. A clean run
  that manufactures paperwork trains the operator to ignore the artifacts.
- **Degrade loudly.** Missing `gh`, no `PROJECT/**`, no conventional commits → run the lenses you
  can and state plainly which signal was unavailable and what that costs the verdict (table below).

## Step 0 — Frame the window

Default **21 days**; honor an operator override. Resolve to explicit dates and state them.
Read the repo's trunk (`main`, or `development` where that is the declared WIP branch), not the
current feature branch. Compute the prior window of equal length for the trend comparison.

## Step 1 — Lens 1: flow distribution

Tally `git log --no-merges --since=<start> --until=<end> --pretty='%s'` on the trunk by
conventional-commit prefix, into **five** buckets:

| Bucket | Prefixes / rule |
|---|---|
| **Harness** | `relay:` `marathon:` `plan:` `capture:` `triage:` `wip:` — machine-generated turn/render commits. Report the count, then **exclude from the RGT denominator**: they are the machinery running, not work chosen. In a harness-driven repo they can outnumber everything else (validated here: 165 of 438 commits in the first hand-run) and silently swamp the signal. |
| **Run** (KTLO) | `fix:` `chore:` `docs:` `refactor:` `test:` `ci:` `hotfix:` `cleanup:` — or the governing doc says `rgt: run` / `doc_type: bugfix` |
| **Grow** | `feat:` — or the governing doc says `rgt: grow` |
| **Transform** | **only** an explicit `rgt: transform` on the governing `PROJECT/**` doc |
| **Unclassified** | everything else, including unprefixed. Reported, never silently bucketed — a large share is itself a finding (inconsistent conventional commits). |

An explicit `rgt:` key on the governing doc always beats prefix inference. Report the ratio over
the RGT denominator (Run+Grow+Transform+Unclassified), the trend vs. the prior window, and a
one-line verdict. No threshold blocks anything.

## Step 2 — Lens 2: recurring-defect radar

Build clusters, then rank. Signals in order of precision:

1. **`related:` frontmatter arrays** in `PROJECT/**/GH-*.md` — human-authored sibling links, the
   highest-precision signal and already sitting in the tree unread. Extract every issue reference
   from every `related:` block and tally: the most-cited issues are cluster centers.
2. **Shared seam** — `fix:` commits in the window grouped by touched file/function
   (`git log --since=<start> --name-only --pretty='%h %s'`, filter to `fix:`).
3. **Issue-text similarity** across `gh issue list --state all --json number,title,labels,body`.
4. **Reopens and false closes** — reopened issues, or a capture doc recording a *doc-only /
   no-code-change* resolution for a code defect. Treat doc-only closure as a strong recurrence
   predictor until the repo's own history says otherwise.
5. **Cross-repo re-reports** — the `reported_from:` frontmatter key. The same harness bug reported
   from three vendored repos is one target, not three.

**Clusters come in two shapes; support both.** *Seam-shaped*: N issues circling one file or
function (e.g. three issues on one `ensure_gitignore()`). *Class-shaped*: N issues sharing a defect
class across different files (e.g. "guards that cannot report red" — the shape this repo's Litmus
release was hand-derived from). A radar that only sees seams misses the class clusters, which the
first hand-run showed are where the largest verdicts live.

Rank crudely; refine only if it misranks in practice:

```
target score ≈ (distinct issues in cluster)
             × (blast radius: repos / lanes the seam or class touches)
             ÷ (fix cost: the cluster's median effort rating)
             × 1.5 if any member was closed without a code change
```

For each target report: the cluster (issue numbers + docs), the shared seam or class, the span in
days, why it recurs, and what a single durable fix would retire.

## Step 3 — Lens 3: release recalibration

Skip silently if `RELEASES.md` is absent or has no unshipped blocks. Otherwise, for each unshipped
block: join its `Milestone:` to its issue set (`gh issue list --milestone "<title>" --state open`),
compare the planned theme against the observed flow distribution and the top targets, and surface:

- Does the arc's `Description:` still describe where effort actually goes?
- Is a top radar target unclaimed by any planned band?
- Has the milestone's issue set drifted from its stated theme?

Advisory only. Say "the plan says X, the repo is doing Y" and stop.

## Step 4 — Report in-session

    RADAR — <repo> · <start>..<end>

    FLOW      Run <n>% · Grow <n>% · Transform <n>% · Unclassified <n>%
              (+ <n> harness commits excluded)
              <trend vs prior window> · <one-line verdict>

    TARGETS   1. RADAR-<slug> — <n> issues over <n> days · <what one fix retires>
              2. ...

    PLAN      <drift between RELEASES.md and observed reality, or "aligned", or "no RELEASES.md">

    ASK       <the one decision this puts in front of the operator>

## Step 5 — Persist the report (two sinks, one confirmation)

Skip entirely when there are no targets.

### Target IDs — stable across runs

A target is identified by what it centers on, never by its prose:

- **Seam-shaped, one function:** `RADAR-<function-name-slug>` (function name preferred over file
  path — it survives file moves).
- **Seam-shaped, one file:** `RADAR-<basename-sans-extension>`.
- **Class-shaped:** `RADAR-class-<short-class-slug>`, chosen once at first sighting.

Slug rule: lowercase, non-alphanumerics → hyphens. **Never re-slug a live target.** If its seam is
renamed, keep the original ID and add a `formerly <old name>` note under the target's heading in
the issue body — an alias that fails visibly beats a silent identity split that resets the aging
clock exactly when it matters.

### Sink A — evidence, immutable

Write `PROJECT/1-INBOX/RADAR-REPORT-YYYY-MM-DD.md`: PDDA frontmatter
(`title status created updated owner goal` + `doc_type: report`), the full three-lens analysis
with citations, and the checklist as it stands at generation time (a historical record, not a
second live copy). Never edit a prior report; a new run writes a new dated doc. No ROADMAP pointer
— 1-INBOX carries no coverage requirement. If the repo has no `PROJECT/` tree, offer repo root as
a fallback location and say so in the report header.

### Sink B — completion state, live

The checklist only, plus a link to the newest report doc. Search first:

    gh issue list --label radar --state open

- **none** → `gh issue create --label radar --title "radar: <repo> — recurring targets"`
  (create the `radar` label first if the repo lacks it)
- **exactly one** → update in place: carry unchecked items forward by ID, append new targets,
  strike through targets whose seam went quiet citing the fixing commit, update each target's
  `first-seen: <date> · runs: <n>` line, then comment with the run delta and the new report link.
  Never open a second radar issue.
- **more than one** → stop and ask the operator which is canonical.

Checklist items are grouped under their target heading and each names a file, a function, and an
acceptance condition, so a different agent in a later session can execute one cold:

```md
## RADAR-ensure-gitignore — 3 issues over 47 days · first-seen: 2026-08-07 · runs: 1

- [ ] Fix `ensure_gitignore()` to handle both directions (add-ignore and un-ignore) — `relay-automation/xyz-vendor.sh`
- [ ] Add a regression test asserting both directions on a fresh vendor
- [ ] Close #18 / #314 / #440 with the commit SHA — none of them doc-only this time
```

### Confirmation

Preview both artifacts, write on **one** confirmation covering both sinks. Never ask twice.
Then offer — do not assume — to hand the targets to `marathon-triage`.

## Degradation table

| Missing | Lost | Still runs |
|---|---|---|
| `gh` / auth | Lens 2 signals 3-5, Lens 3 joins, Sink B | Lenses 1-2 (signals 1-2), Sink A; state that the checklist has no live home this run |
| `PROJECT/**` | Lens 2 signal 1, `rgt:` overrides, Sink A's normal location | Lenses 1-3 from git + `gh`; offer repo-root fallback for Sink A |
| Conventional commits | Lens 1 inference | Report the Unclassified share as the finding it is |
| `RELEASES.md` | Lens 3 | Everything else; PLAN line reads "no RELEASES.md" — a valid state, not a gap |

Always state which rows applied and what they cost the verdict.

## Boundaries

| Tool | Owns | Radar's difference |
|---|---|---|
| `weekly-shipped` | Outward recap of what shipped | Inward, diagnostic, judgmental |
| `marathon-triage` | Ranking marathon candidates | Radar asks what deserves to be a candidate; feeds it, never requires it |
| `/honest` | Whole-repo maturity read | Windowed (21 days) and mix-focused |
| `pdda.sh glance` / `releases-current` | Doc-state inventory | A verdict across git + issues + docs + releases, not an inventory |
| `/10days` | Sweeps issues then **executes** | Radar never executes anything |
