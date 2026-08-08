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

**Compute the tally once, into a file, and prove it sums.** Write subjects with
`/usr/bin/git log --no-merges --since=<start> --until=<end> --pretty='%s' <trunk> > <tmpfile>`,
then assert `wc -l <tmpfile>` equals the sum of the bucket counts before reporting anything.
Two reasons, both observed: shell wrappers/hooks may rewrite or truncate `git` output (a `tail`
view of a piped tally returned counts that contradicted the `head` view of the same pipeline —
same keys, different numbers), and a partial read is indistinguishable from a real distribution.
An unproven tally is exactly the reads-as-authoritative-while-wrong failure this tool exists to
catch; do not let the radar commit it.

Then bucket by conventional-commit prefix, into **five** buckets:

| Bucket | Prefixes / rule |
|---|---|
| **Harness** | `relay*:` `marathon*:` `plan:` `capture:` `triage:` `wip:` — machine-generated turn/render commits, matched as **prefix families** (`relay-pkg:` is harness; exact-match lists leak — first calibration run caught exactly this). Report the count, then **exclude from the RGT denominator**: they are the machinery running, not work chosen. In a harness-driven repo they can outnumber everything else (validated here: 178 of 438 commits) and silently swamp the signal. |
| **Run** (KTLO) | `fix:` `chore:` `docs:` `refactor:` `test:` `ci:` `hotfix:` `cleanup:` — or the governing doc says `rgt: run` / `doc_type: bugfix` |
| **Grow** | `feat:` — or the governing doc says `rgt: grow` |
| **Transform** | **only** an explicit `rgt: transform` on the governing `PROJECT/**` doc. **Always report `rgt:` adoption alongside the figure** — at zero adopting docs, "Transform 0%" means *nobody has declared anything*, not *no transformative work happened*, and the number cannot become non-zero until the key is adopted. Print it as `0% (rgt: adoption: N docs)` so the distinction is never left to the reader. |
| **Unclassified** | everything else, including unprefixed. Reported, never silently bucketed — a large share is itself a finding (inconsistent conventional commits). |

An explicit `rgt:` key on the governing doc always beats prefix inference. Report the ratio over
the RGT denominator (Run+Grow+Transform+Unclassified), the trend vs. the prior window, and a
one-line verdict. No threshold blocks anything.

**Always print the Unclassified subjects verbatim, then give an adjusted read beside the
mechanical one.** Some repos use the *component* as the type (`stay-focused: add session-anchor
skill`), which conventional-commit inference cannot classify — and those commits are often plainly
Grow. Second calibration run: mechanical inference read 5% Grow where the adjusted read was 19%,
a ~4x undercount in the one direction that flatters nobody. Report both; label which is which.

## Step 2 — Lens 2: recurring-defect radar

Build clusters, then rank. Signals in order of precision:

**Signal precision is repo-dependent — measure it, don't assume it.** The order below is a
starting prior, not a ranking. Run every signal, report each one's **yield** (how many clusters it
produced), and rank targets by the evidence that actually materialized. Validated across two repos
whose sharpest signals were exact inverses: in `xyz-3-agents-swarm` signal 1 was decisive and
signal 2 flat; in `giant-brains-claude-skills` signal 1 yielded nothing and signal 2 carried the run.

1. **`related:` frontmatter** in `PROJECT/**/GH-*.md` — human-authored sibling links. **Two shapes
   exist and both must be parsed**: a block array of prose entries citing `#refs`, and a scalar
   pointing at a sibling *filename* (`related: GH-8-FOO.md`) with no issue number at all — resolve
   filename form to its issue via the target doc's `gh_issue:` key. **Report the extraction yield
   explicitly**: "N docs carry `related:`, M references extracted." *M=0 while N>0 is a parser
   failure, not an absent signal* — say so out loud. (Second calibration run hit exactly this: 2
   docs carried the key, the array-shaped extractor returned silence, and the skill nearly reported
   "no kinship signal" when the signal was there in a shape it could not read — the same
   reads-as-active-while-nothing-runs class this tool exists to find.)
   Citation count also **conflates two things**: defect kinship ("same seam", "same family",
   "opposite direction", "same class") and infrastructure context (a FROZEN-twin contract, a
   release issue, an SOP cited as background). Only kinship forms clusters — first calibration run:
   #308 drew 11 citations, all context, zero kinship.
2. **Shared seam** — `fix:` commits in the window grouped by touched file/function. **Group by
   issue, not by commit**: one commit fixing five shims is one data point per seam.
   **Then apply the recurrence discriminator, which is the whole point of this signal:**
   a hot seam counts as *recurring* only if its fixes span **≥2 distinct calendar days** AND
   **≥2 distinct originating PRs/branches/issues**. Otherwise it is **concentrated authoring** —
   one hardening pass on one component — and must be excluded from targets and labeled as such.
   (Second calibration run: 13 of 13 window `fix:` commits landed on one directory, which reads as
   an overwhelming top target until you check the dates — all 13 on a single day, all from PR #10.
   That is a skill being written, not a defect recurring.)
3. **Issue-text similarity** across `gh issue list --state all --json number,title,labels,body`.
4. **False closes, then reopens** — a capture doc recording a *doc-only / no-code-change*
   resolution for a code defect is the primary form of this signal and greps cheaply. Reopen
   events need per-issue `gh api` timeline calls — expensive; sample them only for cluster
   members already found by other signals. Treat doc-only closure as a strong recurrence
   predictor: first confirmed instance is #18, closed doc-only within 2 hours, same seam
   re-fired at day 34 (#314) and day 44 (#440).
   **This signal is structurally unavailable in a repo with zero closed issues** — check the closed
   count first and say so rather than reporting a clean sweep. Nothing has had time to recur.
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

Skip silently if `RELEASES.md` is absent, has no unshipped blocks, or **contains only the
installer's seed block** — a block whose `Description:` says EXAMPLE / "replace this", or that has
an empty `Target Date:` and `GH_URL:`, is a placeholder, not a plan. Reporting drift against a seed
is precisely the "do not treat a sparse file as an incomplete one" failure §GH-381 forbids.
(Second calibration run: the target repo's only block was the seed; correct output is silence.)

Otherwise, for each unshipped block: join its `Milestone:` to its issue set
(`gh issue list --milestone "<title>" --state open`), compare the planned theme against the
observed flow distribution and the top targets, and surface:

- Does the arc's `Description:` still describe where effort actually goes?
- Is a top radar target unclaimed by any planned band? Mark each reported target **claimed by
  <band>** or **UNCLAIMED** — a claimed target is context, an unclaimed one is the finding.
- Has the milestone's issue set drifted from its stated theme?
- The **orphan share**: what fraction of open issues belong to no milestone at all? A large
  unassigned majority means the bands describe less of the backlog than they appear to. Only
  meaningful once at least one real band exists — 100% orphan in a repo with no milestones is a
  young repo, not a planning failure.

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

Write `PROJECT/1-INBOX/RADAR-REPORT-YYYY-MM-DD.md` — **if that filename already exists, this is the
Nth run of the same day: append `-runN` (`RADAR-REPORT-2026-08-07-run2.md`) rather than overwriting.
A same-day rerun is a distinct immutable snapshot, and "never edit a prior report" outranks the
one-doc-per-date convention.** PDDA frontmatter
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
| `RELEASES.md`, or seed-only | Lens 3 | Everything else; PLAN reads "no release plan" — a valid state, not a gap |
| Closed issues (zero) | Lens 2 signal 4 entirely | Everything else; say "nothing has had time to recur" rather than implying a clean sweep |
| History < ~2 windows | The trend line, and most of Lens 2 | Lens 1 for the current window only; state that recurrence is structurally unobservable this young |

Always state which rows applied and what they cost the verdict.

## Boundaries

| Tool | Owns | Radar's difference |
|---|---|---|
| `weekly-shipped` | Outward recap of what shipped | Inward, diagnostic, judgmental |
| `marathon-triage` | Ranking marathon candidates | Radar asks what deserves to be a candidate; feeds it, never requires it |
| `/honest` | Whole-repo maturity read | Windowed (21 days) and mix-focused |
| `pdda.sh glance` / `releases-current` | Doc-state inventory | A verdict across git + issues + docs + releases, not an inventory |
| `/10days` | Sweeps issues then **executes** | Radar never executes anything |
