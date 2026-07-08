---
gh_issue: 164
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/164
title: "Idea -> queue -> plan docs & GH issue -> queue -> marathon: quick automated intake pipeline"
status: SHIPPED (3-COMPLETED) — Phase 1 items 1-2 built on branch claude/gh-161-harness-observability; item 5 (/idea skill) deferred
created: 2026-07-07
updated: 2026-07-07
owner: noel
doc_type: feature
complexity: 3
risk: 2
effort: 3
phases: 1
ratings_provisional: true
non_goals:
  - Not replacing HQ's existing park/queue/fire commands (GH-128/132) — this composes with them, not around them
  - Not auto-firing a marathon lane without a human review point somewhere in the loop
related:
  - ROADMAP.md
  - utils/hq/
  - utils/marathon-plan.sh
  - PROJECT/3-COMPLETED/GH-161-HARNESS-OBSERVABILITY.md
  - PROJECT/3-COMPLETED/GH-162-DEBUG-MANTRA-HARNESS-MODE.md
  - PROJECT/1-INBOX/GH-163-WP-SIBLING-AST-REVIEW.md
goal: >
  Design a faster, more automated on-ramp from a short idea prompt to a marathon-ready lane: draft
  the plan doc, file the GH issue, and add the ROADMAP queue entry, composing with HQ's existing
  park/queue/fire commands rather than duplicating them.
roadmap_exempt: false
---

## Key concepts

- Today's flow is mostly hand-authored: a `PROJECT/1-INBOX` doc → a matching GH issue → promotion
  to `2-WORKING` → only then eligible for `marathon-plan.sh`/preflight/`marathon-drive`.
- HQ (GH-128/132) already automates `park`/`queue`/`fire`; the idea → plan-doc → issue step itself
  is still fully manual.
- Goal: take a short idea prompt and auto-draft the plan doc + file the GH issue + add the ROADMAP
  queue entry, then queue it for a marathon.
- Decided (2026-07-07): the plan-doc skeleton (frontmatter + Key Concepts/Why/checklist scaffold)
  gets auto-drafted by a new `/idea` Claude Code skill acting as the **first responder / front-line
  intake layer** — an operator-friendly workflow that asks a short, fixed question set and infers the
  rest, then hands off to `hq park --create` for the actual mechanical write. It composes with HQ's
  existing commands rather than becoming a second, parallel path — see "Proposed Phase 1 shape" and
  the skill sketch below.

> **Note for plan writers:** apply the `/ponytail` lens here — the manual trace is a handful of
> mechanical steps (create issue, write doc, add a ROADMAP line, regenerate the dashboard); favor
> composing existing commands/scripts over new automation infrastructure, and question whether a
> new tool needs to exist at all versus a short script or an `hq` subcommand addition.

# GH-164 · Idea → queue → plan docs & GH issue → queue → marathon

## Status

| What was just completed | What's next |
|---|---|
| **Phase 1 items 1-2 SHIPPED (2026-07-07):** extended `hq_render_capture` (`utils/hq/hq-lib.sh`) to render the full PDDA skeleton — ratings, `non_goals`/`related`/`goal`, Key Concepts/Idea/Why/Phase 0 checklist/QA checklist — instead of the old thin Request/Notes template, with an optional `HQ_PARK_*` env-var synthesis passthrough; wired `ROADMAP-DASHBOARD.md` regeneration into `cmd_park`'s `--create` path. See "## Phase 1 build (shipped)" for the change set and verification. | Item 5 (the `/idea` Claude Code skill) is deferred — the passthrough env-var interface it will call into is now built and tested, but the skill itself (question flow, LLM synthesis, preview) is a separate, larger follow-up. Item 3 (bundling multiple fresh captures into one marathon-plan cluster) stays explicitly out of scope per Phase 0's own finding. |

## Idea

A "quick" and automated system for: initial idea -> queue -> build out plan docs & GH issue ->
queue -> marathon.

## Why

Today, going from a raw idea to a marathon-ready lane is mostly hand-authored: someone writes a
`PROJECT/1-INBOX` doc, files a matching GH issue, promotes the doc to `2-WORKING`, and only then
does it become eligible for `marathon-plan.sh`/preflight/`marathon-drive`. HQ already automates
parts of this (GH-128's `hq park`/`hq queue`/`hq fire`, GH-158's marathon-scan), but the idea ->
plan-doc -> issue step itself is still manual. A faster, more automated on-ramp — take a short idea
prompt, draft the plan doc + file the GH issue + add the ROADMAP queue entry, then queue it for a
marathon — could shorten the loop from "I have an idea" to "it's fireable" considerably.

## Phase 0 — Explore & scope

Purpose: this is a review/spike — use this session's own manual GH-161–164 intake as the concrete
trace to design against, rather than designing in the abstract.

### Checklist

- [x] Write down the exact manual steps this session took for GH-161–164: raw idea → `gh issue
      create` → `PROJECT/1-INBOX/GH-<n>-*.md` doc → ROADMAP queue line → ROADMAP-DASHBOARD
      regeneration. Note which of those are mechanical (could be scripted) vs. judgment calls
      (need a human).
- [x] Review HQ's existing `park`/`queue`/`fire` commands (`utils/hq/`) to find the seam where an
      automated draft step would plug in without duplicating what HQ already does.
- [x] Decide how much of the plan doc gets auto-drafted (skeleton with Key Concepts + Phase 0 only,
      like this doc) vs. left for human review before promotion/queueing.
- [x] Decide the human checkpoint: does the auto-drafted issue/doc get created directly, or staged
      for a one-line human approval before it's real?
- [x] Propose the concrete tool/command shape (a new `hq` subcommand, a standalone script, or a
      Claude Code skill) as this doc's next phase — do not implement in this phase. Apply the
      `/ponytail` lens: prefer extending an existing command over standing up a new tool surface.

### QA checklist — Phase 0

- [x] The design is grounded in this session's actual manual trace, not a hypothetical workflow.
- [x] The proposal states explicitly where a human checkpoint remains, not full auto-fire.
- [x] The proposal composes with HQ's park/queue/fire rather than introducing a second, competing path.

## Phase 0 findings

### 1. The exact manual trace (GH-161–164), reconstructed from real commits

The trace was NOT one pass — the operator explicitly split it into two rounds, visible in the
actual commit history:

| # | Step | Mechanical or judgment |
|---|---|---|
| 1 | Operator has 4 raw ideas; explicitly chooses "issues only, no plan docs yet" | **Judgment** — deferring doc-authoring was a deliberate call, not a default |
| 2 | `gh issue create` ×4 → issues #161–164 | **Mechanical** — one `gh issue create --title … --body …` per idea |
| 3 | Append a one-line ROADMAP queue pointer per issue, minimal "no plan doc yet" form | **Mechanical** — matches `hq_roadmap_line`/`hq_roadmap_insert` shape almost exactly |
| 4 | Regenerate `ROADMAP-DASHBOARD.md` | **Mechanical** — deterministic script, no judgment |
| 5 | Author the full skeleton plan doc per issue: frontmatter (ratings, `non_goals`, `related`, `goal`) + body (Key Concepts, `/ponytail` note, Idea, Why, Phase 0 checklist, QA checklist) | **Judgment** — requires understanding the idea, picking ratings, writing Why/Key Concepts, scoping checklist items |
| 6 | Rewrite the ROADMAP queue lines to point at the now-real docs | **Mechanical once the doc path is known** — a line replace |
| 7 | Author a brand-new Marathon Plan D doc bundling all 4 lanes (collision map, waves, execution contract) — **not** producible by `hq queue`, which requires a pre-existing plan | **Judgment** — grouping decision + collision-safety analysis + wave assignment |
| 8 | Add a ROADMAP queue pointer for the Marathon Plan D doc itself | **Mechanical** |
| 9 | Regenerate `ROADMAP-DASHBOARD.md` again | **Mechanical** |
| 10 | Iterative doc-content refinement — lock in specific design decisions | **Judgment** |
| 11 | Fire the explore-marathon lane per doc | **Judgment/execution** — a human/operator decision to launch, never automatic |

**Tally: 6 mechanical steps (2, 3, 4, 6, 8, 9), 5 judgment steps (1, 5, 7, 10, 11).** The mechanical
steps are exactly the ones `hq park` already partially automates; the judgment steps cluster around
*content* (what the idea means, what it's rated, how it's grouped/waved), not *mechanics* (where the
file goes, what the ROADMAP line looks like).

### 2. The HQ seam — where automation plugs in without duplicating park/queue/fire

- **`hq park` (`utils/hq/hq.sh`, Tier A/B `--create` path) already does steps 2+3 of the trace
  above**: `gh issue create` → dup-guard → render a capture doc via `hq_render_capture`
  (`utils/hq/hq-lib.sh`) → insert a ROADMAP line via `hq_roadmap_insert`, landing after the first
  `### … queue` heading — exactly `ROADMAP.md`'s `### Queue / parked intake` heading this repo
  already uses. This is the correct, already-existing seam — no new tool needed for steps 2/3.
- **Gap 1 — the rendered doc was much thinner than what step 5 actually produced.**
  `hq_render_capture` emitted only `gh_issue`/`source`/`title`/`status`/`created`/`doc_type`
  frontmatter plus a `## Request` + `## Notes` body — no ratings, no `non_goals`/`related`/`goal`,
  no Key Concepts, no Phase 0 checklist, no QA checklist. GH-161–164's real docs carry all of that.
- **Gap 2 — dashboard regeneration (steps 4 and 9) was not wired into `cmd_park` at all.** Nothing
  in `utils/hq/hq.sh` called `utils/roadmap-dashboard.sh` after the ROADMAP write; a human had to
  remember to run it separately, which the manual trace shows happening twice.
- **Gap 3 — bundling multiple fresh items into one marathon-plan cluster (step 7) has no home in
  HQ at all.** `hq queue` requires an **existing** `MARATHON-*.md` and only appends a single
  non-destructive lane block; it cannot create a **new** plan bundling several captures the way
  Marathon Plan D does. `utils/marathon-plan.sh` can auto-rank and wave-pack ledger items — but only
  ones with a filled-in preflight contract, a build-lane concept that explore-only docs-only lanes
  structurally don't have. This is a real, load-bearing gap, not an oversight to "just fix": explore-
  only marathon clustering is a genuinely different shape from build-lane sequencing.

### 3. Auto-draft vs. human review split

Auto-draftable (safe to generate mechanically, preview-first): the GitHub issue itself; the capture
doc's **skeleton** (frontmatter scaffold with best-guess ratings marked `ratings_provisional: true`,
`non_goals`/`related` stubs, Key Concepts/`## Idea` = the raw request verbatim/`## Why` TODO
prompt/generic Phase 0 + QA checklists); the one-line ROADMAP queue pointer; the ROADMAP-DASHBOARD
regeneration.

Left for human review, never auto-drafted: the real prose in Key Concepts/Why beyond the raw idea
text, and any ratings correction — a wrong provisional rating is self-limiting because
`marathon-plan.sh` already parks an unrated or under-rated doc as `"unrated"` (held out of active
waves) rather than misfiring, so a rough auto-guess is safe to ship as a *starting* value; whether
several fresh captures get bundled into one marathon-plan cluster vs. queued individually (Gap 3);
the actual Phase 0 exploration content — that is still a full explore-marathon lane.

### 4. The human checkpoint

`hq park` already has the right shape for this: it **PREVIEWS by default** and only writes with
`--create` — that preview-then-approve gate *is* the one-line human checkpoint, and Phase 1 keeps it
exactly as-is. Two checkpoints remain even after `--create`:
1. **Write checkpoint** — operator types `--create` after seeing the rendered issue/doc/ROADMAP-line
   preview, same as `hq park` today.
2. **Promotion/queue checkpoint** — the auto-drafted doc lands in `1-INBOX` with
   `status: Proposed (1-INBOX — not yet active)` and unchecked Phase 0 boxes; it is not
   marathon-fireable until a human runs `hq promote` (or equivalent) and/or decides how it's
   bundled into a marathon plan (Gap 3). No path in this proposal creates a directly-fireable lane.

## Proposed Phase 1 shape

**Favoring an `hq` subcommand extension over a new tool** (the `/ponytail` lens):

1. **Extend `hq_render_capture`** to render the fuller PDDA skeleton shape instead of the thin
   Request/Notes template: add ratings (marked `ratings_provisional: true`), `non_goals`/`related`
   stubs, and a body with Key Concepts/Idea/Why (TODO prompt)/a generic Phase 0 checklist/QA
   checklist. A template change inside the existing function, not a new command.
2. **Wire dashboard regeneration into `cmd_park`'s `--create` branch**, right after the
   `hq_roadmap_insert` call: if `$path/utils/roadmap-dashboard.sh` exists, run it in the target
   repo, mirroring the "only if present" pattern already used for the `pdda.sh frontmatter` check.
   Closes Gap 2.
3. **Do not build a new bundler for step 7 (Marathon Plan D-style clusters) in Phase 1.** Gap 3 is
   real but not automation-ready at current volume; revisit only if this pattern repeats often
   enough to earn the miles.
4. **Human checkpoint stays exactly `hq park`'s existing preview/`--create` gate**, plus the
   existing `1-INBOX` → `hq promote` → marathon-plan/queue lifecycle already in place.
5. **Composition, revised (2026-07-07):** the mechanical write stays entirely inside
   `utils/hq/hq.sh` + `utils/hq/hq-lib.sh` — same `park` verb, same preview/`--create` contract, same
   ROADMAP insertion point. `queue` and `fire` are untouched. **Decision: add a `/idea` Claude Code
   skill on top, as an operator-friendly front end** — the synthesis layer a static bash template
   structurally cannot provide, handing off to `hq park --create` for the actual write.

This was a proposal only at capture time — see "Phase 1 build (shipped)" below for what was actually
implemented, and what stays deferred.

## `/idea` skill sketch (design only — item 5, deferred; see Phase 1 build)

> **Update 2026-07-07 — the `/idea` front-end now lives in PDDA, not here.** The skill described
> below was built from this sketch in the [pdda](https://github.com/Hypercart-Dev-Tools/pdda) repo
> (`.claude/skills/idea/SKILL.md`), as a sibling to that repo's `/triage` intake skill. It was made
> **self-sufficient** (direct PDDA-compliant write: `PROJECT/1-INBOX/` capture + ROADMAP park +
> `pdda.sh frontmatter` validate) rather than depending on `hq park --create`, because PDDA's vendored
> `hq` does not carry the `HQ_PARK_*` synthesis interface. **No `/idea` skill was ever built in this
> repo** — only this sketch. What *did* ship here is the `hq park` `HQ_PARK_*` synthesis backend (see
> "## Phase 1 build" below), which is a general `hq` feature and stays. Treat the sketch below as
> historical design context; the maintained skill is in PDDA.

**Role:** front-line intake / first responder. Takes a raw idea from the operator, asks a short
fixed question set, synthesizes the judgment-heavy prose that `hq park`'s template structurally
can't produce (Why, Key Concepts, ratings, non_goals), then hands off to `hq park --create`.

**Deterministic question set (fixed, four questions, no branching follow-ups):**
1. Target project/repo (default: current repo; confirm only if ambiguous).
2. One-line idea (skip if already given at the trigger).
3. Rough shape: quick fix / feature / spike-explore-only / multi-phase build — maps to a starting
   ratings guess.
4. Known related docs/issues, if any (optional free text, or "none").

**Synthesis step (LLM inference, not scriptable in bash):** Why paragraph, Key Concepts bullets,
`non_goals` stubs, ratings (always `ratings_provisional: true`), `related` seeded from question 4.

**Preview-first, single checkpoint:** the skill renders the full synthesized doc, plus the `hq park`
command it is about to run, and asks for one operator confirmation — the same checkpoint
`hq park --create` already gates on.

**Mechanical handoff:** on confirm, the skill exports the `HQ_PARK_*` env vars (see "Phase 1 build"
below — this is the interface the sketch left as "a build-time detail, not decided here") and calls
`hq park <project> "<idea>" --create`.

## Phase 1 build (shipped 2026-07-07, branch `claude/gh-161-harness-observability`)

Built items 1-2 of the Proposed Phase 1 shape. Item 3 stays explicitly deferred per the proposal.
Item 5 (the `/idea` skill itself) is **not** built in this pass — what IS built is the exact
passthrough interface the skill will call into, so the skill becomes a thin front end with no
`hq`-side work left when it is eventually written.

### Change set

- **`utils/hq/hq-lib.sh` — `hq_render_capture`**: extended (backward-compatible; 8 new trailing
  params, all optional) to emit the full PDDA skeleton — `complexity`/`risk`/`effort`/`phases`
  (defaulting to a generic provisional starting point: 2/1/2/1) always `ratings_provisional: true`,
  `non_goals`/`related`/`goal`, `## Key concepts`, the `/ponytail` note, `## Status` table, `## Idea`
  (renamed from `## Request`), `## Why` (TODO stub when not synthesized), `## Phase 0 — Explore &
  scope` with `### Checklist`/`### QA checklist` — matching the shape GH-161–164's own docs use,
  instead of the old thin Request/Notes template.
- **`utils/hq/hq.sh` — `cmd_park`**: reads 8 new optional env vars once (`HQ_PARK_WHY`,
  `HQ_PARK_KEY_CONCEPTS`, `HQ_PARK_NON_GOALS`, `HQ_PARK_RELATED` — pipe (`|`)-delimited lists —
  and `HQ_PARK_COMPLEXITY`/`HQ_PARK_RISK`/`HQ_PARK_EFFORT`/`HQ_PARK_PHASES`) and threads them through
  to both `hq_render_capture` call sites (preview + `--create`). Chose env vars over new CLI flags —
  matches this repo's existing passthrough convention (`MARATHON_ROOT`, `CODEX_LOG`, `TICK_REPO_ROOT`,
  etc.) and keeps a bare `hq park <project> <request>` at exactly zero new required arguments, per
  the issue's own "cold operator, zero flags" requirement.
  Also wires `ROADMAP-DASHBOARD.md` regeneration into the `--create` path right after the
  `hq_roadmap_insert` call: runs `bash utils/roadmap-dashboard.sh` in the target repo **only if that
  script is present** (mirrors the existing `pdda.sh frontmatter` "only if present" pattern
  immediately below it) — never required, never fatal if it fails.
- **`utils/hq/hq.sh` usage() + `skills/hq/SKILL.md`**: documented the new env vars and the dashboard
  step.
- **`test/hq-park-synthesis.sh`** (new, 36 cases): a bare `--create` with zero synthesis env vars
  still renders a complete, valid skeleton (every new frontmatter key + body section present, TODO
  stubs where nothing was synthesized); the dashboard regenerates after `--create` when the script is
  present, and does neither fail nor falsely claim success when it is absent; a full synthesis
  passthrough (`HQ_PARK_*` set) lands the real ratings/Why/Key-Concepts/non_goals/related in the
  rendered doc, with pipe-delimited lists correctly split into real YAML list items / bullets. Added
  to `validate.sh`.

### Verification

- `test/hq-park-synthesis.sh`: 36/36 (new).
- `test/hq.sh` (23/23), `test/hq-park.sh` (23/23 — the pre-existing template's own assertions still
  hold against the new template), `test/hq-dispatch.sh` (18/18), `test/hq-promote.sh` (8/8),
  `test/hq-hardening.sh` (11/11), `test/hq-locator.sh` (8/8): all still green, no regressions.
- Full `./validate.sh`: same 4 pre-existing failures as GH-161/GH-162's builds (`archive-writers.sh`,
  `xyz-harness-hooks.sh`, `security-scan.sh`, `python:test_python_layer.py`), independently confirmed
  against a clean `origin/main` baseline earlier in this branch's work — none touch this change's
  files. One additional one-off flake (`worktree-isolation.sh`, unrelated subsystem) reproduced 31/31
  green standalone and did not recur on a second full-suite run.
