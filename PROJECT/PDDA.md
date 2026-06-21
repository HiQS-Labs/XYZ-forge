# Project-Driven Doc Automation (PDDA)

PDDA is the document operating layer for this repo. Its job is to keep project plans, bug-fix docs,
research notes, and roadmap pointers clean enough that an agent can pick up work with minimal drift
and enough structure that routine hygiene can be automated instead of re-decided every session.

The core idea is simple:

- deterministic scripts enforce the parts that should never require judgment
- an LLM reviewer flags structural or planning-quality gaps that are hard to express as regex alone
- `ROADMAP.md` stays a pointer/index, while project detail lives in the individual project docs

## Goals

- Keep `PROJECT/2-WORKING` limited to docs that are truly active.
- Ensure every active doc answers two questions at a glance: what was just completed, and what is next.
- Make phased plans automation-ready by requiring explicit QA gates.
- Prevent plan rot: stale files, missing next steps, hardcoded paths, and hidden scope drift.
- Give agents one repeatable contract for project docs, bug-fix docs, and experimental plans.

## Non-goals

- PDDA does not replace the project docs themselves.
- PDDA does not decide product strategy.
- PDDA does not auto-rewrite nuanced plan content without review.
- PDDA does not turn `ROADMAP.md` into a second execution plan.

## Canonical document model

PDDA assumes four lifecycle buckets:

- `PROJECT/1-INBOX`: new ideas, rough proposals, untriaged notes
- `PROJECT/2-WORKING`: active docs that should be updated as work progresses
- `PROJECT/3-COMPLETED`: completed docs with an outcome
- `PROJECT/4-MISC`: reference, stale, superseded, or abandoned docs

Within that model:

- `ROADMAP.md` is the index of current, completed, attempted, and deferred work
- project detail lives in the individual `PROJECT/**` documents
- a working doc is the canonical source of truth for that effort until it is completed, deferred, or superseded
- `blank.md` placeholders are scaffolding and should be ignored by PDDA checks

## Required contract for active docs

Every doc in `PROJECT/2-WORKING` should have:

1. YAML frontmatter with at least `title`, `status`, `created`, `updated`, `owner`, and `goal`
2. a near-top status table with the exact columns:

```md
## Status

| What was just completed | What's next |
|---|---|
| ... | ... |
```

3. clear phase or work sections if the doc is a plan
4. QA gates or acceptance criteria after each phase if the plan is multi-phase
5. repo-relative paths only; no hardcoded absolute local paths

Recommended fields when relevant:

- `related`
- `reviewed`
- `branch`
- `non_goals`
- `gh_issue`

## Why the two-column status header matters

The status table is the front door for both humans and automation.

- The left column is the last verified state change.
- The right column is the next action.
- If either is missing, an agent has to reconstruct state from the body, which is slow and error-prone.

PDDA therefore treats the exact header names as a contract, not a style preference.

Compatibility window:

- older aliases are tolerated only through `2026-07-31`
- accepted aliases during that window are:
  - `What was last done | What's next`
  - `Most recently completed | What's next`
  - `Most recently completed phase | What's next`
- after `2026-07-31`, those aliases should be treated as errors

## Bug-fix doc stance

Bug-fix docs may use a lighter template than multi-phase project plans, but they still need:

- the minimum frontmatter
- the same `## Status` table while active
- a short bug description
- source of truth for intake, including a GitHub issue when relevant
- verification steps

GitHub issues are a valid source for bug reports and intake. They are not a substitute for the local active-work doc
once execution starts in this repo.

## Automation layers

PDDA should have two classes of automation:

Implementation note:

- the deterministic shell scripts currently live under `utils/`
- the aggregate runner is `utils/pdda-run.sh`

### 1. Deterministic hygiene scripts

These catch issues where the answer should be the same every time.

#### A. `pdda-stale-working-docs.sh`

Purpose:
- inspect docs in `PROJECT/2-WORKING`
- detect stale docs based on file modification time
- move or flag them according to policy

Minimum behavior:
- find docs in `PROJECT/2-WORKING` whose last edit is older than 4 days
- emit a clear report of which docs were stale
- move stale docs to `PROJECT/4-MISC` immediately
- log the action so the move was not silent

Recommended safety upgrade:
- support a dry-run mode
- support an allowlist or frontmatter override such as `pdda_hold: true`
- write a summary line per file: `moved`, `flagged`, or `skipped`

#### B. `pdda-check-status-table.sh`

Purpose:
- verify every doc in `PROJECT/2-WORKING` contains the exact two-column status table

Minimum behavior:
- fail if the `## Status` section is missing
- fail if the table headers are not exactly `What was just completed` and `What's next`
- fail if either first-row cell is blank

#### C. `pdda-check-frontmatter.sh`

Purpose:
- ensure active docs expose the minimum machine-readable metadata

Minimum behavior:
- verify required keys exist
- flag empty required values
- flag invalid or missing dates

#### D. `pdda-check-hardcoded-paths.sh`

Purpose:
- catch absolute machine-specific paths before they fossilize into plans

Minimum behavior:
- scan working docs for obvious absolute paths such as `/Users/`, `/private/`, `/tmp/`, drive-letter paths, or `file://`
- report file + line for each hit

Expected exceptions:
- quoted terminal output
- explicitly marked transcript blocks

#### E. `pdda-check-roadmap.sh`

Purpose:
- enforce the `ROADMAP.md` pointer/ledger contract deterministically (the cheap, hourly guard that
  does not need an LLM), so detail cannot silently leak back into the roadmap

Minimum behavior:
- scan `ROADMAP.md` (override via `PDDA_ROADMAP`)
- `error` on any GFM task-list item (`- [ ]` / `- [x]`) — a ledger carries no task checkboxes
- `error` on any `### Checklist` / `### QA checklist` heading — phase/QA detail belongs in the project doc
- `warn` when the file exceeds a line-count / heading-count budget (sprawl signal)

Expected exceptions:
- fenced `console` / `text` / `transcript` blocks and blockquote lines (the carve-out exception note)
  are not scanned — same convention as `pdda-check-hardcoded-paths.sh`

The fuzzy judgment ("deep execution notes that belong elsewhere") stays with the LLM layer below; this
script only catches the unambiguous signals.

### 2. LLM-assisted doc readiness review

This catches the issues where structure exists but planning quality is weak.

#### `pdda-doc-ready.sh`

Purpose:
- review active project plans and flag docs that are not ready for reliable automation

It should check for:

- phased plans missing QA gates after a phase
- phase sections with actions but no observable acceptance criteria
- status tables that are technically present but stale versus the body
- docs that bury the next action in prose instead of making it explicit
- plans that duplicate detail already meant to live in another canonical doc
- contradictory status, such as frontmatter saying `Completed` while the body says active

It should not:

- auto-rewrite the plan body without review
- invent technical claims not grounded in the doc
- silently override deterministic lints

## Enforcement modes

PDDA runs in one of three modes, set by `PDDA_MODE` (env) or the first non-comment line of a
repo-root `.pdda-mode` file; the built-in default is `observe`. The point is an **adoption ramp**: a
freshly-installed PDDA should never destroy files or break a build on day one, and a project should
graduate onto the rails deliberately.

| Mode | When | Findings reported | Stale-doc moves | Exit on `error` |
|---|---|---|---|---|
| `observe` | just installed | yes | no (forced dry-run) | always `0` |
| `light` | transitioning | yes | yes | `0` (warn, don't block) |
| `full` | fully on rails | yes | yes | non-zero (blocks) |

- The default is `observe` so a brand-new install is non-destructive and non-blocking — it shows the
  team what PDDA *would* flag without touching anything.
- `light` starts acting (moves stale docs, loud reports) but still never fails a build — the
  transition phase while the backlog of doc debt is cleared.
- `full` is the strict end state: `error` findings block with a non-zero exit. A repo declares it by
  committing `.pdda-mode` with `full`.
- Mechanics: `pdda-lib.sh` resolves the mode once; in `observe` it forces `PDDA_DRY_RUN=1`; every
  check ends with `exit "$(pdda_gated_exit "$EXIT_CODE")"`, which returns the real code only in `full`.

## ROADMAP.md contract

`ROADMAP.md` is a pointer file, not a plan body.

It should contain:

- projects in progress
- completed work
- attempted work
- deferred work
- links to the canonical project docs

It should usually not contain:

- detailed phase checklists
- step-by-step build instructions
- deep execution notes already owned by a project file

Strict exemption:
- a short exception note is allowed when omitting the note would hide an operationally critical fact

Maintainer rule:
- when a roadmap entry needs more than a one-line status + a link, that is the signal to put the
  detail in the entry's `PROJECT/**` doc and leave only the pointer here — do not grow the roadmap

How this is enforced (two layers, so it cannot quietly rot):
- **deterministic** — `utils/pdda-check-roadmap.sh` errors on task checklists / `### Checklist` /
  `### QA checklist` headings and warns on size sprawl (runs hourly, free, no model needed)
- **LLM** — `utils/pdda-doc-ready.sh` reviews `ROADMAP.md` against the full pointer contract for the
  fuzzier "this paragraph is really execution detail" cases (honors the carve-out)
- the file itself carries a top banner restating the contract, so a human editing it sees the rule

## Activity log artifact

PDDA should write an append-only activity log to:

- `PROJECT/PDDA-ACTIVITY.jsonl`

Each script run should append:

- per-finding entries
- one summary entry for the script
- enough metadata to tell what moved, what failed, and when

## Suggested hourly schedule

Run the deterministic checks every hour in this order:

1. `pdda-check-frontmatter.sh`
2. `pdda-check-status-table.sh`
3. `pdda-check-hardcoded-paths.sh`
4. `pdda-check-roadmap.sh`
5. `pdda-stale-working-docs.sh`

Then run:

6. `pdda-doc-ready.sh`

(`utils/pdda-run.sh` runs exactly this sequence and applies the active `PDDA_MODE` gate.)

Reason for the order:

- deterministic failures should surface first
- the LLM review should spend time only on docs that passed basic structural hygiene

## Suggested output contract

To make these scripts composable, each should emit:

- a short human-readable summary to stdout
- a machine-readable result format, ideally JSON lines
- non-zero exit when blocking issues are found

Suggested fields per finding:

- `severity`
- `check`
- `file`
- `line`
- `message`
- `action`
- `timestamp`

Severity proposal:

- `error`: automation-blocking
- `warn`: should be fixed soon but not blocking
- `info`: advisory only

## Readiness rubric for automation

A doc is "automation ready" when:

- it is in the correct lifecycle folder
- it has valid frontmatter
- it has the exact status table
- the next action is singular and explicit
- each phase has a visible QA gate
- links to canonical related docs are present where needed
- there are no hardcoded absolute paths
- `ROADMAP.md` is pointing at it rather than duplicating it

## Failure modes PDDA is trying to prevent

- active docs with no visible next step
- too many half-live docs in `PROJECT/2-WORKING`
- plans that look complete but have no verification gates
- stale working docs silently lingering forever
- roadmap sprawl where detail leaks into `ROADMAP.md`
- agent sessions restarting the same reasoning because the doc never captured "what changed"

## Proposed extensions not yet locked

These are likely useful for full automation, but they are still policy choices:

- a `doc_type` field such as `project`, `bugfix`, `research`, `feedback`, `roadmap`
- a `priority` field if you want deterministic triage beyond folder placement
- a `pdda_hold: true` override for docs that should remain in `2-WORKING` despite inactivity
- a second generated PDDA summary artifact beyond the activity log

## Open questions

These need a decision before the automation should be considered stable:

1. Should `gh_issue` stay optional metadata, or become required for bug-fix docs that originated from GitHub?
2. Should the compatibility window end on `2026-07-31`, or should it be shorter/longer?
3. Should `PROJECT/PDDA-ACTIVITY.jsonl` remain append-only forever, or rotate by month once the volume grows?
4. Should `ROADMAP.md` remain root-level canonical only, or do you also want a project-local roadmap index under `PROJECT/`?

## Recommended v1 stance

If the goal is "get project docs onto rails quickly," the safest v1 is:

- start in `observe` mode, then graduate `light` → `full` as the doc backlog is cleared
- enforce exact status-table headers
- tolerate known old aliases only through `2026-07-31`
- require QA gates on phased plans
- forbid hardcoded absolute paths
- run deterministic checks hourly
- let the LLM reviewer flag readiness issues
- keep `ROADMAP.md` pointer-only (deterministic `pdda-check-roadmap.sh` + the LLM rubric guard it)
- append all script activity to `PROJECT/PDDA-ACTIVITY.jsonl`
