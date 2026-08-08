---
title: /radar — per-repo strategic compass (flow distribution + recurring-defect radar + release recalibration)
status: Active — Phase 0 (validate the signals before building)
created: 2026-08-07
updated: 2026-08-07
owner: noel
gh_issue: 442
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/442
doc_type: plan
complexity: 3
risk: 2
effort: 3
phases: 3
ratings_provisional: true
supersedes: PROJECT/1-INBOX/RGT.md (research capture; folded in verbatim as Appendix A)
non_goals:
  - Cross-repo / fleet-wide roll-up. Deliberately deferred — the operator wants the review and its
    recommendations to stay granular and per-repo at this stage. No rebalance-OS integration, no
    Focus 5 tile, no shared DB. A later umbrella layer must not be designed for here.
  - Any automated enforcement. /radar never blocks a commit, never gates a marathon, never fails CI.
    It is an advisory read an operator asks for. Persisting a report is not enforcement — nothing
    downstream is required to consume it.
  - Mutating anything other than its own two report sinks. No edits to existing docs, ROADMAP.md,
    RELEASES.md, or issue state beyond the single radar-labeled worklist issue it owns.
  - Editing RELEASES.md. Lens 3 proposes recalibration in the session; the operator edits the ledger.
    RELEASES.md's own GH-381 section explicitly forbids assistants topping it up (see Lens 3).
  - Replacing weekly-shipped, marathon-triage, /honest, or pdda.sh glance. Boundaries are drawn below.
  - A PDDA subcommand in v1. The deterministic slice graduates into PDDA only after the taxonomy has
    been exercised by hand and stops needing judgment (see "Where this graduates to").
related:
  - "skills/weekly-shipped/SKILL.md — adjacent and outward-facing (what shipped, for end users).
     /radar is inward-facing and diagnostic. Reuse its git sourcing conventions, not its framing."
  - "skills/marathon-triage/SKILL.md — consumes a ranked candidate list. /radar's Lens 2 output is a
     natural upstream input, but /radar must not depend on marathon existing (it runs in any repo)."
  - "utils/pdda/pdda.sh glance / releases-current — existing read-only roll-ups; the shape /radar's
     eventual deterministic slice should mimic (opt-in lever, warn-only, never mutates)."
  - "PROJECT/1-INBOX/GH-440-VENDOR-TICK-GITIGNORE.md — the worked example for Lens 2: its `related:`
     block names #18/#314/#312 all clustered on one function, and records that #18 was closed
     'doc-only, no code change'. That is the recurrence signal, already hand-authored."
  - "RELEASES.md §'This file is OPTIONAL (GH-381)' — the hard constraint on Lens 3."
goal: >
  Give an operator a single per-repo command that answers "are we treading water or moving the
  needle, what keeps breaking, and does the plan still match reality" — by reading the last 2-3
  weeks of repo activity through three lenses (Run/Grow/Transform flow distribution, recurring-defect
  clustering, and RELEASES.md recalibration), then persisting a fixed-schema report to two sinks
  (a dated PROJECT/1-INBOX capture doc for the evidence, a GitHub issue for the live checklist) so
  the findings survive across sittings instead of dying with the session.
---

# GH-442 — RADAR, a per-repo strategic compass

## Status

| What was just completed | What's next |
| --- | --- |
| **Phase 1 complete and its QA gate passed.** Two calibration runs on structurally opposite repos, whose sharpest signals turned out to be exact inverses; nine fixes total folded back into `skills/radar/SKILL.md`. Run 1 (this repo) wrote both sinks — [RADAR-REPORT-2026-08-07.md](../1-INBOX/RADAR-REPORT-2026-08-07.md) + issue [#444](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/444). Run 2 (`giant-brains-claude-skills`) correctly found no qualifying targets and **wrote nothing**, proving the guardrail that most needed proving. | Phase 2 — reconciliation. Needs a *second* run against issue #444 to exercise carry-forward: unchanged seams keep their IDs, ticked boxes survive, fixed targets get struck through with the commit cited. Also still open: the systematic doc-only-close sweep (open question 5 has one confirmed instance, not a proof). |

## Why now

Activity in this repo is high and legible — CHANGELOG.md is 634 KB, ROADMAP.md is 238 KB, and
`PROJECT/1-INBOX/` holds 25+ capture docs. None of that answers the question an operator actually
asks on a Monday: *is this motion or progress?* A repo can run marathons daily and still be
100% KTLO. The existing tooling reports **volume and status**; nothing reports **mix**.

There is a second, sharper gap. Defects here recur in clusters, and the clusters are already
hand-documented but never aggregated. [GH-440](../1-INBOX/GH-440-VENDOR-TICK-GITIGNORE.md)
records three sibling issues (#18, #314, #312) circling one function, `ensure_gitignore()` — and
notes that #18 was *"resolved doc-only, no code change."* That is a repeat offender announcing
itself one capture doc at a time, with nobody standing far enough back to see it. A cluster like
that is a high-value target: fixing the seam once retires several future issues.

Third, `RELEASES.md` names forward arcs (theme, target date, milestone) that were chosen at some
earlier moment. Nothing ever re-asks whether the arc still matches where effort is actually going.

## What the radar reads — three lenses

Default window: **21 days** (the "last 2-3 weeks" framing), operator-overridable.

### Lens 1 — Flow distribution (Run / Grow / Transform)

Classify each unit of work in the window into one of three buckets and report the ratio, with the
evidence for each classification visible.

| Bucket | Means | Primary signals in this repo |
|---|---|---|
| **Run** (KTLO) | Treading water: bug fixes, maintenance, debt paydown, vendoring, hygiene | `fix:`, `chore:`, `docs:`, `refactor:` commits; `doc_type: bugfix` capture docs; issues labeled bug |
| **Grow** | Directional: incremental features, scaling, individual requests | `feat:` commits; `doc_type: plan` docs scoped to one capability |
| **Transform** | Game-changer: a new capability class, a new seam, a strategic bet | explicit `rgt: transform` on the doc — **never** inferred |

**Classification rule.** Infer Run/Grow from conventional-commit prefix when nothing better exists;
take an explicit `rgt:` frontmatter key on the governing `PROJECT/**` doc as authoritative when
present. **Transform is never inferred** — it must be declared. This deliberately contradicts the
source research (Appendix A, §5), which maps `perf:`/`refactor:` to Transform. In this repo most
refactors are maintenance; auto-promoting them would inflate the one number the whole exercise
exists to keep honest. A radar that flatters is worse than no radar.

Unclassifiable work is reported as **Unclassified**, never silently bucketed. A large Unclassified
share is itself a finding (the repo isn't using conventional commits consistently).

Output: the ratio, the trend against the prior window of equal length, and a one-line verdict.
No threshold blocks anything; the operator reads the mix and decides.

### Lens 2 — Recurring-defect radar (the high-value-target finder)

The part with the most leverage. Cluster the window's defect signals into **repeat offenders**, then
rank by how much a single fix would retire.

Signals to mine, in rough order of reliability:

1. **`related:` frontmatter arrays** in `PROJECT/**/GH-*.md` — human-authored sibling links, the
   highest-precision signal available and already sitting in the tree unread.
2. **Shared code seam** — `fix:` commits in the window grouped by touched path/function. N distinct
   fix commits landing on one file is a heat signature regardless of what the issues say.
3. **Issue-text similarity** — `gh issue list --state all` title/body clustering, for reports that
   never got a capture doc.
4. **Reopens and false closes** — a reopened issue, or one whose capture doc records a *doc-only*
   or *no code change* resolution for a code defect. GH-440's note about #18 is exactly this.
   **Hypothesis worth testing in Phase 1: doc-only resolution of a code defect is the strongest
   single predictor of recurrence in this repo.** If it holds, it is the cheapest check to build.
5. **Cross-repo re-reports** — the `reported_from:` frontmatter key (GH-440 carries
   `reported_from: giant-brains-claude-skills`). The same harness bug reported from three vendored
   repos is one target, not three.

Ranking, kept deliberately crude for v1 — refine only if it misranks in practice:

```
target score ≈ (distinct issues in cluster)
             × (blast radius: how many repos / lanes the seam touches)
             ÷ (fix cost: the cluster's median effort rating)
             × 1.5 if any member was closed without a code change
```

Output per target: the cluster (issue numbers + docs), the shared seam (file/function), the span in
days, why it recurs, and what a single durable fix would retire. Every claim cites a file, commit,
or issue — an uncited target is a guess, and this repo already has an epistemic-hygiene rule about
that (GH-178 uncited-findings work).

### Lens 3 — Release recalibration (read-only, advisory)

Read the non-`Shipped` blocks in `RELEASES.md`, join each to its issue set via
`gh issue list --milestone "<title>"`, and compare the **planned** theme against the **observed**
flow distribution and the top radar targets. Surface three questions:

- Does the next arc's `Description:`/`Codename:` still describe where effort actually went?
- Is a top radar target unclaimed by any planned band? (A repeat offender nobody has scheduled.)
- Has the milestone's issue set drifted from its stated theme?

**Hard constraint.** `RELEASES.md` §"This file is OPTIONAL (GH-381)" says, in the file itself:
*"Do not offer to fill this in, populate it, bring it up to date... Do not treat a sparse file as an
incomplete one."* Lens 3 must therefore: skip silently when the file is absent or has no unshipped
blocks; never propose adding a block for a version inside an existing band; and never edit the file.
It may only say *"the plan says X, the repo is doing Y"* and stop. A missing or stale RELEASES.md is
a valid state, not a finding.

## Scope decisions already settled

| Decision | Choice | Why |
|---|---|---|
| Scope | **Per-repo only** | Operator wants granular review + recommendations per repo first; an umbrella roll-up is a later, separate question. No rebalance-OS integration in this doc's scope. |
| Form factor | **A Claude Skill, run manually** | Judgment-heavy classification and clustering; there is no regex for "is this a game changer." Start where judgment is cheap. |
| Side effects | **Analysis is read-only; the report persists to two sinks** | Findings must outlive the sitting. Writes exactly two artifacts, both on one confirmation (see below). Still never edits RELEASES.md, ROADMAP.md, or any existing doc. |
| Enforcement | **None** | Advisory. Follows PDDA's own adoption ramp: earn trust in observe mode before anything gates. |
| Window | **21 days, overridable** | Matches the "last 2-3 weeks" framing this started from. |

## Report persistence — two sinks, one owner per fact

A verdict that exists only in a terminal is gone the moment the session ends, and a radar run
routinely surfaces more than one sitting can absorb. So every run with findings persists a
**fixed-schema report** to two places. The word *deterministic* here means the **structure** is
fixed and the **target identities are stable across runs** — the classification itself is judgment
and always will be. A report whose sections and IDs shift between runs cannot be reconciled, and
reconciliation is the entire point of persisting it.

### The drift hazard, and the rule that avoids it

Writing the same facts to a doc and an issue creates two sources of truth that disagree the first
time someone ticks a box in one of them. `RELEASES.md` §GH-381 names this exactly: *"Two sources of
truth for the same fact is the defect."* The fix is that the two sinks hold **different facts**:

| Sink | Owns | Mutability |
|---|---|---|
| `PROJECT/1-INBOX/RADAR-REPORT-YYYY-MM-DD.md` | The **evidence**: window, flow distribution, full cluster analysis, citations, Lens 3 drift note. The analysis of record. | **Immutable after generation.** Dated snapshot, never edited by a later run. A new run writes a new dated doc. |
| GitHub issue `radar: <repo> — recurring targets` | The **completion state**: the live checklist and nothing else, plus a link to the newest report doc. | **Mutable.** This is where boxes get ticked, across as many sittings as it takes. |

Completion state lives in exactly one place; evidence lives in exactly one place. Neither can go
stale against the other, because neither restates the other. The doc includes the checklist as it
stood at generation time — that is a historical record of what was proposed, not a second live copy.

### Stable target IDs

A target is identified by its **seam**, not its prose: `RADAR-<seam-slug>`, slugged from the file or
function the cluster centers on — e.g. `RADAR-ensure-gitignore`. Same seam next run, same ID.

This is what makes run N+1 useful rather than noisy. With stable IDs the skill can carry unchecked
items forward, mark a target retired when its seam stops producing defects, and say "this has been
open across 3 runs" — the single most damning fact a radar can report. With prose-derived IDs, every
run looks like a fresh set of problems and nothing accumulates.

### Issue reconciliation, not issue accumulation

Before filing, search for an open issue with the `radar` label in this repo.

- **None open** → file a new one.
- **One open** → **update it in place**: carry unchecked items forward, append newly found targets,
  and strike through targets whose seam went quiet, citing the commit that fixed it. Do not open a
  second issue. Comment on the issue with a short run-delta and the new report doc link.
- **More than one open** → stop and ask. Two live radar issues is a state a human should resolve.

### Checklist format

Every actionable item is a GFM checklist item, grouped under its target, each carrying its citation:

```md
## RADAR-ensure-gitignore — 3 issues over 47 days · blast radius: 8 vendored repos

- [ ] Reproduce the shared failure once, covering all three reports (#18, #314, #440)
- [ ] Fix `ensure_gitignore()` to handle both directions (add-ignore and un-ignore) — `relay-automation/xyz-vendor.sh`
- [ ] Add a regression test asserting both directions on a fresh vendor
- [ ] Re-vendor the 8 affected copies and confirm clean `git status`
- [ ] Close #18 / #314 / #440 with the commit SHA — none of them doc-only this time
```

Items are written so a *different* agent in a *later* session can execute one without re-deriving
the analysis: name the file, the function, and the acceptance condition.

### When not to write anything

**No targets found → no doc, no issue.** Report the flow distribution in-session and stop. A clean
radar run that manufactures paperwork trains the operator to ignore the artifacts it produces.

### Confirmation

Preview both artifacts, write on **one** confirmation — the pattern `/idea` already uses in this
repo. One prompt covers both sinks; the skill does not ask twice.

## Where this lives, and where it graduates to

**Now:** `skills/radar/SKILL.md` in this repo, installed to user level via the same `install.sh`
pattern the other skills here use, so it runs in any repo without vendoring.

**Later, conditionally:** the *deterministic slice only* — commit-prefix tallying, `related:`-graph
clustering, milestone joins — graduates into PDDA as an opt-in check (`pdda.sh flow-distribution`,
lever `.pdda-rgt`, warn-only), mirroring how Quad Concepts is gated by `.pdda-quad`. That migration
is **out of scope here** and gated on one thing: the taxonomy running by hand for several cycles
without the operator having to argue with its buckets. Judgment-shaped work does not belong in a
shell check, and PDDA's stated non-goal — *"PDDA does not decide product strategy"* — means PDDA may
report a distribution but must never assert the ratio is wrong.

## Boundary vs. existing tools

Each of these already exists; /radar must not duplicate them.

| Tool | Owns | /radar's difference |
|---|---|---|
| `skills/weekly-shipped` | Outward-facing recap of what shipped, in end-user language | Inward, diagnostic, judgmental. Reuse its git sourcing; discard its framing. |
| `skills/marathon-triage` | Ranking candidates for a marathon, preflight, wave grouping | Radar asks *what deserves to be a candidate at all*. Its Lens 2 output feeds triage; it must not require marathon to exist. |
| `/honest` | Maturity/ground-truth read of the whole repo | Radar is windowed (21 days) and mix-focused, not a maturity assessment. |
| `pdda.sh glance` / `releases-current` | Read-only roll-ups of doc state | Radar reads across git + issues + docs + releases and produces a *verdict*, not an inventory. |
| `/10days` | Sweeps recent issues and then **executes** a marathon | Radar never executes anything. |

## Open questions for the deeper pass

1. Is `rgt:` a new frontmatter key, or is it derivable from the existing `doc_type` + labels? A new
   required key has adoption cost across 25+ existing docs; a derived one may be too coarse.
2. ~~Should Lens 2 cluster on *issues* or on *seams*?~~ **Settled by Phase 0 (2026-08-07):** both
   shapes are real in this repo — `ensure_gitignore` is seam-shaped, #419 is class-shaped and is
   the *bigger* cluster. The skill supports both (`RADAR-<seam-slug>` / `RADAR-class-<slug>`).
3. Backfill: does the first run need a historical baseline to make "trend vs. prior window"
   meaningful, or is the first run allowed to report no trend?
4. What does /radar do in a repo with no `PROJECT/**`, no conventional commits, and no `gh`? Degrade
   to Lens 1-from-commits only, or refuse and say why? (Prefer degrade + state the degradation.)
5. Does the doc-only-close recurrence predictor (Lens 2 signal 4) actually hold here? **First
   confirmed instance (2026-08-07):** #18 was created and closed doc-only within 2 hours on
   2026-06-24; the same `ensure_gitignore` seam re-fired as #314 (day 34) and #440 (day 44).
   One instance is evidence, not proof — the systematic closed-issue sweep remains open.
6. Is the seam slug stable enough to be an ID? A renamed function or a file moved between refactors
   breaks it, silently splitting one aging target into two young ones. **Provisionally settled in
   the skill (2026-08-07):** slug on function name over file path (survives moves); never re-slug a
   live target — on rename, keep the original ID and add a visible `formerly <old name>` alias
   under the target's issue heading. Cheapest thing that fails visibly. Confirm it holds through
   Phase 2's two-run QA gate before calling it closed.
7. Retention of `RADAR-REPORT-*.md` in 1-INBOX. Weekly runs accumulate ~50 docs a year. Sweep older
   ones to `4-MISC`, keep the last N, or leave them — git already holds the history and PDDA's
   `stale` check flags but never moves. Do not solve this before it hurts.
8. Should the report doc be committed, or left untracked for the operator to stage? Committing on
   the operator's behalf is a write this doc has so far avoided.

## Phase sketch

### Phase 0 — Validate the signals before building the skill

Cheap, read-only, no code. Confirms the radar has something real to read.

- [x] File the tracking GitHub issue ([#442](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/442))
      and promote this doc to `PROJECT/2-WORKING/GH-442-RADAR.md` (issue-first SOP) — 2026-08-07.
- [x] Hand-run Lens 2 signals 1 and 4 over the current tree — 2026-08-07, results below.
- [ ] Test open question 5 against closed issues — does doc-only closure predict recurrence?
      (Not yet run; needs closed-issue archaeology, deliberately not rushed for the gate.)
- [x] Sanity-check Lens 1 against the last 21 days of commits — 2026-08-07, results below.

**QA gate:** at least one Lens 2 cluster the operator confirms is genuinely high-value, and a Lens 1
ratio they recognize. If neither lands, stop — the concept is unproven and the skill is premature.

#### Phase 0 results (2026-08-07, window 2026-07-17..2026-08-07, trunk `origin/development`)

**Lens 2 — gate PASSED, by a stronger route than expected.** 66 docs in `PROJECT/**` carry
`related:` blocks. Tallying every issue reference inside them, the top cluster centers are
**#419 (13 citations)** and #308 (11), with #348/#351 next — *not* the `ensure_gitignore` cluster
this doc used as its worked example (still present, just smaller). The decisive fact: the operator
already hand-derived the **Litmus release** from the #419 cluster — CHANGELOG 2026-08-05 records
*"the two arcs were derived from where the failures actually cluster, not from a backlog sweep."*
The radar's core method has therefore already been executed manually once, by the operator, and
produced a release arc they committed to. That is operator confirmation of high value in the
strongest available form. Bonus finding: #419 is a **class-shaped** cluster (a defect class across
many files: guards that cannot report red), settling open question 2 — clusters come in two shapes,
seam-shaped and class-shaped, and the skill must support both. It does.

**Lens 1 — gate PASSED, with one design correction.** 438 commits in the window. The two largest
"prefixes" are `relay` (122) and `marathon` (43) — **harness-generated turn/render commits, not
chosen work** — which a naive prefix tally would let swamp the signal. Correction adopted into the
skill: a fifth **Harness** bucket, counted and reported but excluded from the RGT denominator.
Among classifiable human work: fix 79 + docs 70 + chore 27 ≈ **94% Run** vs feat 11 ≈ 6% Grow,
0 Transform declared, 53 unprefixed. The ratio is recognizable — the period was dominated by
gate-repair (Litmus) — which is exactly what the gate required.

### Phase 1 — Ship `skills/radar/SKILL.md` with first-run persistence

- [x] Author the skill; `install.sh` matching the sibling skills' pattern — 2026-08-07,
      [`skills/radar/SKILL.md`](../../skills/radar/SKILL.md). Diverges from the sketch below in two
      Phase-0-driven ways: a fifth Harness bucket in Lens 1, and class-shaped cluster IDs
      (`RADAR-class-<slug>`) alongside seam-shaped ones. The sketch is retained unedited as the
      historical design record.
- [ ] Implement the seam-slug ID scheme and prove two runs over the same tree agree on IDs.
- [ ] Implement Sink A (dated `RADAR-REPORT-*.md` with PDDA frontmatter) and Sink B (create path:
      new `radar`-labeled issue), both behind one preview + one confirmation.
- [x] Run it on this repo — 2026-08-07, full three-lens pass. Four calibration fixes folded back
      into the skill: prefix-family matching for the Harness bucket, the kinship-vs-context rule
      for `related:` citations (#308 drew 11 citations, all FROZEN-twin context, zero kinship —
      a naive count would have ranked infrastructure as the #2 defect cluster), group-by-issue for
      seam heat (per-commit heat went flat while the `related:` graph stayed sharp), and the
      orphan-share line in Lens 3. Bonus: first confirmed instance of the doc-only-close predictor
      (#18, closed doc-only in 2 hours, seam re-fired at day 34 and day 44).
- [x] Run it on `giant-brains-claude-skills` to prove graceful degradation — 2026-08-07.
      **The no-targets guardrail fired correctly and nothing was written**, which is the outcome
      that most needed proving. Five more calibration fixes earned (see "Second calibration run"
      below), one of which was a genuine parser defect: signal 1 read 2 docs carrying `related:`
      and extracted 0 references *in silence*, because that repo uses the scalar-filename shape
      (`related: GH-8-FOO.md`) rather than the block-array-of-`#refs` shape. The radar exhibited
      the exact defect class it was built to detect — a signal that reads as active while nothing
      runs. Yield reporting is now mandatory on that signal.
- [ ] Document the boundary vs. weekly-shipped inside the skill so a session doesn't pick the wrong one.

**QA gate:** two clean runs on structurally different repos; the no-targets path writes nothing at
all; zero writes outside the two sinks; every finding carries a citation; every checklist item names
a file and an acceptance condition an unrelated agent could act on cold.
**Gate status 2026-08-07: PASSED.** Two runs, structurally opposite (see below); the no-targets
path fired on run 2 and wrote nothing; run 1's two sinks were the only writes across both.

#### Second calibration run — `giant-brains-claude-skills`, 2026-08-07

Same window, trunk `origin/main`, 21 commits (vs 438). The repo turned out **less degraded than
planned for** — it has PDDA, `PROJECT/**`, and `RELEASES.md` — so the interesting failures were
not missing inputs but *inputs in unexpected shapes*. The two runs' sharpest signals were exact
inverses, which is the finding that most changes the design:

| | xyz-3-agents-swarm | giant-brains-claude-skills |
|---|---|---|
| Signal 1 (`related:`) | decisive — 13-citation cluster | **0 extracted** from 2 docs (scalar-filename shape) |
| Signal 2 (seam heat) | flat, contributed nothing | 13/13 fix commits on one seam — but **one day, one PR** |
| Signal 4 (doc-only) | first confirmed instance | structurally unavailable — **0 closed issues repo-wide** |
| Lens 3 | Nightwatch drift, orphan 68% | seed-only `RELEASES.md` → correct output is silence |
| Verdict | 3 targets, both sinks written | **no targets — nothing written** |

Five fixes folded into the skill: (1) signal 1 parses both `related:` shapes and must report
extraction yield, since `M=0 while N>0` is a parser failure masquerading as an absent signal;
(2) a **recurrence discriminator** on signal 2 — a hot seam counts only if its fixes span ≥2
calendar days AND ≥2 originating PRs, else it is concentrated authoring (13 fixes on one component
in one PR is a skill being written, not a defect recurring); (3) signal precision is repo-dependent,
so measure per-signal yield instead of assuming the ranking; (4) Lens 3 skips installer-seed blocks;
(5) print Unclassified subjects verbatim with an adjusted read beside the mechanical one — component-
as-type prefixes (`stay-focused: add ... skill`) made mechanical inference report 5% Grow where the
honest read was 19%, a 4x undercount.

### Phase 2 — Reconciliation across runs + triage handoff

The update-in-place path can only be tested once a prior run exists, so it lands here.

- [ ] Implement the issue update path: carry unchecked items forward by ID, append new targets,
      strike through quiet seams with the fixing commit cited, comment the run delta.
- [ ] Report "open across N runs" per target — the aging signal that makes the radar bite.
- [ ] Emit Lens 2 targets in a shape `marathon-triage` can ingest directly.
- [ ] Decide the PDDA graduation question with real usage data behind it.

**QA gate:** run twice with a commit in between — unchanged seams keep their IDs, manually ticked
boxes survive the second run untouched, a target fixed between runs is struck through with its
commit cited, and exactly one `radar` issue exists at the end.

## First sketch — `skills/radar/SKILL.md`

Draft only. Deliberately thin on prose so the deeper pass can shape the judgment sections; the
structure, guardrails, and lens order are what matter here.

````markdown
---
name: radar
description: >-
  Per-repo strategic compass over the last 2-3 weeks of activity. Reports the Run/Grow/Transform
  flow distribution (are we treading water or moving the needle), finds recurring defects that
  cluster on one seam and ranks them as high-value fix targets, and flags where RELEASES.md plans
  have drifted from what the repo is actually doing. Read-only and advisory. Use when the operator
  asks "what have we actually been doing", "are we just fixing bugs", "what keeps breaking",
  "what should we fix once to stop the bleeding", "is the plan still right", "strategic review",
  "impact review", or "/radar". Not for end-user shipped recaps (that's weekly-shipped) and not
  for executing anything (that's marathon-triage / 10days).
---

# radar

A per-repo compass. Three lenses over one window. Every claim cites a commit, file, or issue.

## Guardrails

- **Analysis reads; only the report writes.** The two report sinks (Step 5) are the *only* writes.
  Never edit an existing doc, never edit ROADMAP.md, never commit, never push.
- **Never edit RELEASES.md.** Absent, sparse, or stale are all valid states. Report drift; stop there.
- **Transform is declared, never inferred.** No commit prefix promotes work to Transform.
- **Cite or drop.** An uncited target is a guess.
- **Degrade loudly.** Missing `gh`, no `PROJECT/**`, no conventional commits → run the lenses you
  can and state plainly which signal was unavailable and what that costs the verdict.

## Step 0 — Frame the window

Default 21 days; honor an operator override. Resolve to explicit dates and state them. Read `main`
(or the repo's trunk), not the current feature branch. Also compute the prior window of equal length
for trend.

## Step 1 — Lens 1: flow distribution

Tally the window's work into Run / Grow / Transform / Unclassified.

- Authoritative: an `rgt:` key on the governing `PROJECT/**` doc.
- Inferred: `fix:` `chore:` `docs:` `refactor:` → Run. `feat:` → Grow. Nothing infers Transform.
- Report the ratio, the trend vs. the prior window, and a one-line verdict.
- A large Unclassified share is a finding, not a rounding error.

## Step 2 — Lens 2: recurring-defect radar

Build clusters, then rank. Signals by precision:

1. `related:` frontmatter arrays in `PROJECT/**/GH-*.md` (highest precision — already human-authored)
2. shared seam — `fix:` commits grouped by touched file/function
3. issue-text similarity across `gh issue list --state all`
4. reopens, and closures recorded as doc-only / no-code-change for a code defect
5. the same defect re-reported from multiple repos (`reported_from:`)

Rank by cluster size × blast radius ÷ fix cost, boosted when a member was closed without a code change.

For each target report: the cluster, the shared seam, the span in days, why it recurs, and what one
durable fix would retire.

## Step 3 — Lens 3: release recalibration

Skip silently if RELEASES.md is absent or has no unshipped blocks. Otherwise, for each unshipped
block: join its milestone to its issue set, compare planned theme against observed flow distribution
and the top targets, and surface drift. Advisory only.

## Step 4 — Report in-session

    RADAR — <repo> · <start>..<end>

    FLOW      Run <n>% · Grow <n>% · Transform <n>% · Unclassified <n>%
              <trend vs prior window> · <one-line verdict>

    TARGETS   1. RADAR-<seam-slug> — <n> issues over <n> days · <what one fix retires>
              2. ...

    PLAN      <drift between RELEASES.md and observed reality, or "aligned">

    ASK       <the one decision this puts in front of the operator>

## Step 5 — Persist the report (two sinks, one confirmation)

Skip this step entirely when there are no targets — report the flow distribution and stop.

Assign each target a stable ID: `RADAR-<seam-slug>`, slugged from the file or function it centers
on. Same seam next run must produce the same ID.

**Sink A — evidence, immutable:** write `PROJECT/1-INBOX/RADAR-REPORT-YYYY-MM-DD.md` with PDDA
frontmatter (`title status created updated owner goal`, plus `doc_type: report`), the full three-lens
analysis with citations, and the checklist as it stands at generation time. Never edit a prior
report; a new run writes a new dated doc. Do not add a ROADMAP pointer — 1-INBOX carries no coverage
requirement, and one pointer per run would churn the ledger.

**Sink B — completion state, live:** the checklist only, plus a link to the newest report doc.

    gh issue list --label radar --state open

- none → `gh issue create --label radar --title "radar: <repo> — recurring targets"`
- exactly one → update it in place: carry unchecked items forward by ID, append new targets, strike
  through targets whose seam went quiet (cite the fixing commit), then comment with the run delta
  and the new report link. Never open a second radar issue.
- more than one → stop and ask the operator which is canonical.

Preview both artifacts and write on **one** confirmation. Then offer — do not assume — to hand the
targets to `marathon-triage`.
````

## Appendix A — original `RGT.md` capture (verbatim)

Retained so this doc is a lossless replacement for the research note it supersedes. Note that §5's
`perf:`/`refactor:` → Transform mapping is **deliberately rejected** above.

> While there is no single slang term that encapsulates this exact workflow, the process you are describing sits at the intersection of **Value Stream Management (VSM)** and **Engineering Portfolio Management**.
>
> In modern engineering leadership, this "compass" is built using a combination of specific frameworks and metrics designed to measure the *quality* of output, not just the volume. If you are looking to implement or name this process within your organization, the industry uses the following terminology and frameworks.
>
> ### 1. The Categorization Framework: Run / Grow / Transform (RGT)
> This is the closest conceptual match to your tiers. Originally popularized by Gartner and widely used in enterprise engineering, this framework tags work into three buckets to measure an "Innovation Ratio" [[10], [11]].
> *   **Run (Treading Water):** Often called **KTLO (Keep The Lights On)**. This includes routine bug fixes, technical debt, and maintenance. If your ratio here is too high, you are treading water.
> *   **Grow (Directional Improvements):** Incremental features, scaling efforts, and individual feature requests.
> *   **Transform (Game Changers):** Strategic, "move the needle" innovations that fundamentally change the product or open new markets [[13]].
>
> By reviewing the last 2-3 weeks of repo activity through an RGT lens, a leader can instantly see if the team is stuck in maintenance mode or actually advancing the product.
>
> ### 2. The Metric: Flow Distribution
> In DevOps and Value Stream Management (VSM), analyzing repo activity to categorize the types of work being delivered is called measuring **Flow Distribution** [[56]]. This tracks the proportion of work items—specifically features vs. bug fixes vs. risk/debt—flowing through your system [[52]].
> *   **The Compass Function:** VSM helps identify a common anti-pattern where a team is highly active (e.g., deploying 100 times a day) but is *only* deploying bug fixes rather than delivering actual product value [[55]].
>
> ### 3. The Ritual: Outcome-Based Sprint Review (or Impact Review)
> The "last 2-3 weeks" aligns perfectly with an Agile Sprint. However, a traditional "Sprint Review" often devolves into a "show-and-tell" of output (features built).
> *   **Impact Review:** What you are describing is an **Outcome-Based Review**. Instead of asking "What code did we push?", the team looks at the repo activity and categorizes the *Business Value Delivered* [[45]]. They ask, "Did this PR fix a leak, or did it move the needle on retention?"
>
> ### 4. The Mapping Tool: The Innovation Ambition Matrix
> To separate standard "features" from "true game changers," engineering leaders often map their recent commits and features onto the **Innovation Ambition Matrix** [[13]]:
> *   **Core:** Optimizing what you already have (incremental).
> *   **Adjacent:** Expanding existing features to new use-cases (directional).
> *   **Transformational:** The "game changers" that redefine the user experience [[13]].
>
> ### 5. How to Enforce This in the Repo
> To automate this "compass" so you don't have to manually read every commit, teams use **Conventional Commits** (e.g., `fix:`, `feat:`, `perf:`, `chore:`).
> *   **`fix:`** and **`chore:`** usually map to "Treading Water" (Maintenance/KTLO).
> *   **`feat:`** maps to "Individual Features" (Grow).
> *   **`perf:`** or **`refactor:`** often map to "Move the Needle" improvements (Transform/Strategic).
>
> ### Summary: What to call it?
> If you want to introduce this process to your team, you should call it a **Strategic Alignment Check** or an **Impact Review**.
> *   **The Goal:** To monitor your **Run-Grow-Transform ratio**.
> *   **The Metric:** **Flow Distribution**.
> *   **The "Compass":** Ensuring that for every hour spent on "Run" (treading water), you are spending equal or greater time on "Transform" (moving the needle).
