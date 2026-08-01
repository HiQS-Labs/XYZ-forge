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
4. a table of contents (`## Table of contents`) listing each phase, if the plan is multi-phase — so a
   cold agent can see the full phase span and jump to the live one without scrolling the whole body
5. QA gates or acceptance criteria after each phase if the plan is multi-phase
6. for any discovery or spike phase, its findings written **back into this doc** before its QA gate can
   pass (see [Discovery & spike phases (Memory Injection)](#discovery--spike-phases-memory-injection))
7. repo-relative paths only; no hardcoded absolute local paths
8. before moving to `PROJECT/3-COMPLETED`, a `## Lessons Learned (For Future Agents)` section appended to capture quirks and gotchas

Recommended fields when relevant:

- `related`
- `context_tags` (e.g. `[auth, flaky-tests, build]`)
- `reviewed`
- `branch`
- `non_goals`
- `gh_issue`
- `effort`, `complexity`, `risk`, `phases` — triage ratings; **required for medium-large work** (see
  [Triage ratings for medium-large work](#triage-ratings-for-medium-large-work))

## Quad Concepts (opt-in)

An **opt-in** glance layer, **off by default**. The `## Status` table says *where* the work is; Quad
Concepts says *what* it is — a 5-second read of the core problems a plan tackles and how, so an operator
can see whether the real pain points are covered. (Distinct from `context_tags`: those are for search;
this is for glance.)

When enabled system-wide via the `.pdda-quad` lever (or the `PDDA_QUAD` env var — **orthogonal** to the
enforcement mode), tracked plan docs must carry a `## Quad Concepts` section of **1–4 bullets**,
conventionally right after `## Status`:

```md
## Quad Concepts
- <pain the doc addresses> → <how it addresses it>
```

- **Shape (deterministic):** 1–4 **top-level, non-empty** `-`/`*` bullets in the first `## Quad Concepts`
  section. `pain → fix` phrasing is the convention (nudged by the LLM readiness rubric), not a hard regex.
- **Scope:** `PROJECT/2-WORKING`, `PROJECT/1-INBOX/GH-*.md`, and `PROJECT/3-COMPLETED` (the last keeps a
  glanceable summary for cold-start recall). `PROJECT/4-MISC` is out.
- **Enable:** set `.pdda-quad` to `on` (or `PDDA_QUAD=1`). The enforcement mode still governs whether a
  missing/malformed section merely reports or blocks. **Opt a doc out** with `quad_exempt: true`.
- Enforced by `pdda.sh quad-concepts` (deterministic, structure-only) plus a warn-only readiness rubric.
- `pdda.sh glance` (read-only, always available) rolls up `title + Quad Concepts` across `2-WORKING` for
  a one-screen view of what the active portfolio is addressing.

## Triage ratings for medium-large work

So automation can pick *which* task to pursue without re-reading every plan, every newly recorded
**medium-large** task or project carries four triage fields in its frontmatter:

| Field | Range | Meaning |
|---|---|---|
| `effort` | integer `1`–`5` | how much work — `1` low, `5` highest |
| `complexity` | integer `1`–`5` | how intricate / how many moving parts — `1` low, `5` highest |
| `risk` | integer `1`–`5` | blast radius + uncertainty — `1` safe/contained, `5` one-way-door or unknown |
| `phases` | positive integer | total number of phases in the plan |

```yaml
effort: 2
complexity: 3
risk: 1
phases: 4
```

`risk` should track the repo's existing reversibility scale (`Easy / Costly / One-way door`,
`AGENTS.md` #3): `1`–`2` ≈ Easy, `3` ≈ Costly, `4`–`5` ≈ one-way door / high uncertainty. It is not a
parallel notion of danger — it is that scale expressed as a number.

**Scope.** Required for medium-large work (project plans, experiments, features, multi-phase efforts).
Genuinely small/trivial docs (a typo, a path repoint, a ≤2–3 line bug-fix — the same floor as the
issue-first SOP) do not need them. "Medium-large" is a judgment, so *presence* is enforced by the LLM
layer, not a regex (below).

### How to combine them — derive, don't store

There is deliberately **no stored composite "score" field.** A frozen aggregate would (a) drift from
the three numbers it came from, violating Principle #4 (*one canonical place per fact*), and (b) bake a
weighting choice into every doc that you then cannot re-tune without rewriting them. Compute the
selection signal **live, at selection time**, from the raw fields:

- **`risk` is a gate, not an addend.** A trivial-but-risky task (`effort 1`, `complexity 1`, `risk 5`)
  is easy to *do* but exactly what automation should not auto-pick — folding risk into a linear sum
  lets it slip through mid-ranked. Gate on it instead.
- **`effort` and `complexity` are correlated** (complex work is usually effortful), so summing them is
  a rough "size" proxy, not two independent signals — treat the sum as one ease axis, not two.

Reference selection rule (tune the thresholds per repo):

```text
eligible      = risk <= 2 AND not ratings_provisional   # safety gate; risk >= 4 => route to a human
ease          = effort + complexity       # 2..10, lower = easier
pick          = among eligible, lowest ease, then fewest phases as the tiebreak
```

`ratings_provisional: true` is an **eligibility gate, not just metadata.** Auto-drafted intake (e.g.
the `/idea` skill) ships best-guess ratings marked provisional; a rough `risk: 2` guess on a large
effort must **not** become auto-selectable on the strength of that guess. So a provisional doc is held
out of auto-selection until a human confirms the ratings and clears the flag — the same "route to a
human" posture as `risk >= 4`.

This keeps the raw ratings canonical and queryable while letting the "what's the easiest *safe* thing
to grab" logic live in one place that can evolve. (See the resolved `priority` note under
[Proposed extensions](#proposed-extensions-not-yet-locked).)

### How this is enforced

- **deterministic (values)** — `pdda.sh frontmatter` validates the fields **only when present**:
  `effort`/`complexity`/`risk` must be integers `1`–`5`, `phases` a positive integer. A present-but-bad
  value is unambiguous, so it `error`s. The script does **not** force presence — it cannot know whether
  a doc is "medium-large."
- **LLM (presence)** — `pdda-doc-ready.sh` flags a medium-large plan that is *missing* the triage
  ratings. Whether a doc is medium-large is a judgment, so it stays advisory/warn-capped like every
  other readiness finding.

## Why the two-column status header matters

The status table is the front door for both humans and automation.

- The left column is the last verified state change.
- The right column is the next action.
- If either is missing, an agent has to reconstruct state from the body, which is slow and error-prone.

PDDA therefore treats the exact header names as a contract, not a style preference. The header must be
exactly `What was just completed | What's next` — there is no alias/compatibility window. (One was
specced with a `2026-07-31` cutover, but a single-repo system controls its own docs: no doc here used
an old alias, so a dated, silently-changing branch guarded nothing and was removed 2026-06-22.)

## Discovery & spike phases (Memory Injection)

Discovery and spike phases exist to *learn* — reverse-engineer an existing system, probe an unknown,
prove or kill a risky approach before committing the plan to it. Their output is durable **memory**, and under
Principle #1 (*docs are the runtime state, not a record of it*) that knowledge is project state. If it
lives only in an agent's context or a throwaway scratch note, a cold agent resuming the plan cannot see
what was learned, why a path was chosen or abandoned, or what the spike actually proved — and the work
gets re-done.

Contract: **a phase tagged as discovery or spike must write its findings back into the originating plan
doc before its QA gate can pass.** This is active memory injection. Concretely, that phase's section (or a clearly linked sibling
section in the same doc) must capture:

- **what was investigated** — the system/area reverse-engineered or the question the spike asked
- **what was found (quirks, gotchas, mechanics)** — the concrete mechanics learned, with repo-relative pointers (`file:line`) where
  the finding lives in code, not a vague summary
- **what it changes** — how the finding confirms, redirects, or kills the plan's later phases; an
  unfinished "we'll know after the spike" left dangling is itself the gap

This satisfies Principle #4 (*one canonical place per fact*): the originating plan is that place. A
spike whose findings sit in chat is the exact drift PDDA exists to prevent. The QA gate for a
discovery/spike phase therefore includes "findings are written back to this doc" as an acceptance
criterion alongside the phase's normal checks.

Enforcement is **advisory (LLM layer, warn-capped)** — `pdda-doc-ready.sh` flags a discovery/spike
phase whose findings were not written back. "Did the agent actually capture what it learned" is a
judgment a regex cannot make honestly, so it stays with the LLM reviewer and, like every finding from
that layer, never blocks a build (see [LLM-assisted doc readiness review](#2-llm-assisted-doc-readiness-review)).
To tag a phase, name it plainly (e.g. `## Phase 2 — Discovery: …` / `## Phase 3 — Spike: …`) or set
`doc_type: research` / a phase-level marker the reviewer can see.

## Bug-fix doc stance

Bug-fix docs may use a lighter template than multi-phase project plans, but they still need:

- the minimum frontmatter
- the same `## Status` table while active
- a short bug description
- source of truth for intake, including a GitHub issue when relevant
- verification steps

GitHub issues are the default intake for substantive bug reports (issue-first SOP — see below). They are not a
substitute for the local active-work doc once execution starts in this repo.

## GitHub issue intake

GitHub issues are the **default front door** for substantive work — every project plan and every
non-trivial bug/fix opens an issue *first*, and that issue gets an in-repo pointer doc. The signal
stream lives in GitHub (machine-queryable state, labels, commit↔issue linkage); the execution
surface of record stays in `PROJECT/**`. This is the **issue-first SOP**; the bug-fix stance above
states the principle, and this section owns the *format*. To prevent duplicate intake and forgotten
work, every captured `GH-*.md` doc is also **parked immediately in `ROADMAP.md`** as a one-line queue
entry until it is promoted, deferred, or closed.

**Floor (what needs an issue).** The operational test is **lines of code touched**: any change
beyond a **2–3 line** fix opens a GitHub issue first, and its local plan doc is named after that
issue (see Filename below). Project plans, experiments, and features are always above this line.
**Exempt:** genuinely trivial edits — a ≤2–3 line code fix, a typo, a path repoint, a doc-only
one-liner, formatting — commit directly with a clear message and no issue. When in doubt, open the
issue — it is a cheap `gh issue create`. The SOP applies to *new* efforts going forward; in-flight
`1-INBOX`/`2-WORKING` docs are not backfilled.

Capture a tracked issue as a doc in `PROJECT/1-INBOX/` using this convention:

- **Filename:** `GH-<number>-VERY-SHORT-DESCRIPTION.md` — the local plan doc is always named after
  its GitHub issue (e.g. `GH-1234-SHOWME-COMMAND.md`, `GH-11-CROSS-REPO-TARGETING.md`). Keep the
  description to ~2–4 words; the issue number is the real key, the slug is just a human hint.
  SCREAMING-KEBAB to match the other inbox docs; no zero-padding — mirror the GitHub issue number.
  `<number>` resolves against `origin` (a single canonical repo), so the bare number is unambiguous.
- **Minimum frontmatter:** `gh_issue`, `source` (the full issue URL), `title`, `status`
  (`Proposed (1-INBOX — not yet active)`), `created`, and `doc_type` (`feedback` or `bugfix`).
  For medium-large captures, also include the triage ratings `effort`, `complexity`, `risk`, `phases`
  at capture time, so the queue can be triaged before promotion (see
  [Triage ratings for medium-large work](#triage-ratings-for-medium-large-work)).
- **Body:** transcribe the issue's actionable substance (the asks / acceptance criteria), not the whole
  thread. The live issue stays the discussion surface; this doc is the in-repo capture and back-reference.

Lifecycle:

- The `GH-` inbox doc is the **capture**, not the active-work doc. It carries no `## Status` table while
  it sits in `1-INBOX` (the inbox is the rough/untriaged bucket).
- Capture time also adds a **one-line `ROADMAP.md` queue pointer** linking that inbox doc. This is a
  temporary parking slot: it makes fresh intake visible to humans and automation before promotion,
  which is the duplicate-prevention guard.
- When execution starts, **promote** it to `PROJECT/2-WORKING/` — keep the `GH-` prefix for provenance —
  and it must then satisfy the full active-doc contract (frontmatter, exact status table, QA gates if
  phased), **carrying `gh_issue` forward**. The `ROADMAP.md` pointer is therefore required twice:
  first as a queued parking entry at capture, then as an active-work ledger entry after promotion.
  This is the concrete mechanism behind "GitHub issues are not a substitute for the local active-work
  doc once execution starts" (bug-fix stance above).
- If a captured issue is never actioned it ages out of `1-INBOX` like any other untriaged note; if it is
  closed without work, move the doc to `PROJECT/4-MISC` and remove its queue pointer from `ROADMAP.md`.

A foreign-repo issue (not `origin`) is the rare exception: the `source:` URL disambiguates it, since the
bare `GH-<number>` only guarantees uniqueness within the canonical repo.

## Automation layers

PDDA should have two classes of automation:

Implementation note:

- the automation ships as a single dispatcher, `utils/pdda/pdda.sh`, which sources shared helpers from
  `utils/pdda/pdda-lib.sh`
- every deterministic check is a subcommand: `pdda.sh frontmatter`, `pdda.sh status-table`,
  `pdda.sh hardcoded-paths`, `pdda.sh roadmap`, `pdda.sh roadmap-coverage`, `pdda.sh changelog`,
  `pdda.sh stale`, `pdda.sh issue-doc-sync`, `pdda.sh governance`
- the aggregate runner is `pdda.sh run` (it runs the deterministic checks in order, then the LLM
  review)
- each finding still carries a stable `check` id (e.g. `pdda-check-frontmatter`) in stdout and the
  activity log, independent of how the check is invoked
- **`run` reports what it found, not what it blocked on.** The mode gate forces every check's exit code
  to `0` outside `full`, so the closing line has three outcomes, not two: *all checks passed* (nothing
  found), *N error(s) found, not blocking in `<mode>` mode* (found, gate suppressed the failure), and
  *failures:* (found and blocked). Warnings never move the run out of the first state — a `warn` is the
  house-style advisory, and letting it read as failure would collapse the distinction. Inferring success
  from the gated exit code was BUG-001b: `run` printed *all checks passed* over real errors in `observe`
  and `light`, which are precisely the modes a new adopter starts in. The LLM readiness review is gated
  on the same signal, so an error-laden repo never spends an LLM call. **The rule:** a check that could
  not run — or could not block — must never be scored as a check that passed.

### 1. Deterministic hygiene checks

These catch issues where the answer should be the same every time.

#### A. `pdda.sh stale`

Purpose:
- inspect docs in `PROJECT/2-WORKING`
- detect stale docs based on file modification time
- **flag** them for a human to move (this check never moves files itself)

Minimum behavior:
- find docs in `PROJECT/2-WORKING` whose last edit is older than 4 days
- emit a `warn` finding per stale doc recommending the exact `git mv` to `PROJECT/4-MISC`
- honor a `pdda_hold: true` frontmatter override (skip the flag for held docs)
- log every flag to the activity log; **never** auto-move, so this check can never block a build

Why flag-only (design call, 2026-06-22):
- the auto-move was the repo's only destructive mechanic, and the activity log showed it never once
  fired a real move. The value is the flag; the move is risk with no proven payoff — a human runs one
  reversible `git mv`. mtime staleness is a deliberately loose signal, and flag-only makes a wrong
  guess cost nothing but an ignorable line. An opt-in move can be re-added later behind `pdda_hold` +
  `full` mode if it ever earns the miles.

#### B. `pdda.sh status-table`

Purpose:
- verify every doc in `PROJECT/2-WORKING` contains the exact two-column status table

Minimum behavior:
- fail if the `## Status` section is missing
- fail if the table headers are not exactly `What was just completed` and `What's next`
- fail if either first-row cell is blank

#### B2. `pdda.sh quad-concepts` (opt-in)

Purpose:
- when the `.pdda-quad` / `PDDA_QUAD` lever is on, verify each in-scope plan doc carries a
  `## Quad Concepts` section of 1–4 bullets (see [Quad Concepts (opt-in)](#quad-concepts-opt-in))

Minimum behavior:
- scope: `PROJECT/2-WORKING` + `PROJECT/1-INBOX/GH-*.md` + `PROJECT/3-COMPLETED`; skip `quad_exempt: true`
- parse the first `## Quad Concepts` section; count top-level, non-empty `-`/`*` bullets (skip fenced
  code, indented/nested and empty bullets; stop on the next h1/h2 or a blank line after a bullet)
- fail if the section is missing, has 0 bullets, or has more than 4
- **structure-only** — bullet *quality* (are they real `pain → fix` concepts?) is a warn-only job for
  the LLM readiness rubric, not this deterministic check
- runs standalone always; joins `pdda.sh run` only when the lever is enabled (orthogonal to the mode)

#### C. `pdda.sh frontmatter`

Purpose:
- ensure active docs expose the minimum machine-readable metadata

Minimum behavior:
- verify required keys exist
- flag empty required values
- flag invalid or missing dates
- when the triage ratings are present, validate their values — `effort`/`complexity`/`risk` must be
  integers `1`–`5`, `phases` a positive integer (presence itself is judged by the LLM layer; see
  [Triage ratings for medium-large work](#triage-ratings-for-medium-large-work))

#### D. `pdda.sh hardcoded-paths`

Purpose:
- catch absolute machine-specific paths before they fossilize into plans

Minimum behavior:
- scan working docs for obvious absolute paths such as `/Users/`, `/private/`, `/tmp/`, drive-letter paths, or `file://`
- report file + line for each hit

Expected exceptions:
- quoted terminal output
- explicitly marked transcript blocks

#### E. `pdda.sh roadmap`

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
  are not scanned — same convention as `pdda.sh hardcoded-paths`

The fuzzy judgment ("deep execution notes that belong elsewhere") stays with the LLM layer below; this
script only catches the unambiguous signals.

#### F. `pdda.sh changelog`

Purpose:
- nudge that `CHANGELOG.md` (the first-class end-of-iteration record) was updated this iteration

Minimum behavior:
- read `CHANGELOG.md` (override via `PDDA_CHANGELOG`); find the newest dated heading, accepting both
  `## YYYY-MM-DD` and `## [x.y.z] - YYYY-MM-DD`
- `warn` (never `error` — does not block, even in `full`) when that entry predates the latest git
  commit by more than `PDDA_CHANGELOG_STALE_DAYS` days (default `0`)
- `warn` if `CHANGELOG.md` is missing or has no dated entry; emit `info` (skip the compare) when there
  is no git history

Why warn-only:
- "did you update the changelog" is a reminder, not a correctness gate — blocking a build because a
  human hasn't written the prose yet is the wrong kind of friction (the calibration principle)

#### G. `pdda.sh roadmap-coverage`

Purpose:
- enforce the *coverage* direction of the `ROADMAP.md` contract: every active doc in `PROJECT/2-WORKING`
  must be reflected by a pointer in `ROADMAP.md`, so the ledger can never silently fall behind the
  working set. This is the inverse of `pdda.sh roadmap` (which keeps execution detail from leaking
  *into* the roadmap); together they guard the pointer/working-set relationship in both directions.

Minimum behavior:
- list the working docs (`PROJECT/2-WORKING/*.md`, `blank.md` excluded)
- `error` on any working doc whose repo-relative path (`PROJECT/2-WORKING/<name>.md`) does not appear in
  `ROADMAP.md` (override the roadmap location via `PDDA_ROADMAP`) — the action is "add a one-line ledger
  entry linking it"
- `error` if `ROADMAP.md` is missing entirely

Expected exceptions:
- a working doc that should not appear in the ledger opts out with `roadmap_exempt: true` in its
  frontmatter (mirrors the `pdda_hold` escape hatch in `pdda.sh stale`); the check then
  emits `info` (skip) for that doc

#### H. `pdda.sh issue-doc-sync`

Purpose:
- catch a tracked plan doc whose recorded state has drifted from its **GitHub issue**, in either
  direction — the gap a 2026-06-29 manual reconciliation pass had to cross-reference by hand

Scope: **both** `PROJECT/2-WORKING/` (active plans) and `PROJECT/3-COMPLETED/` (finished plans). The
completed bucket is not optional. Scanning `2-WORKING` alone means the check stops watching a doc at the
exact moment it completes — so the `git mv` that drift (a) recommends is what blinds it, and the issue is
orphaned forever (GH-27).

Minimum behavior:
- for each doc in either bucket, resolve its issue number from the `gh_issue` frontmatter key (preferred)
  or the `GH-<number>-` filename; silently skip docs that carry neither (they are not issue-tracked)
- resolve each issue's state from the best available source (see gh-degrade below), then flag:
  - **(a)** issue **CLOSED** but the doc is still in `2-WORKING` -> `warn`, recommending the exact
    `git mv` to `PROJECT/3-COMPLETED` (flag-only; a human runs the one reversible move)
  - **(b)** issue **OPEN** but the doc's `status:` lead word declares it done (`complete`, `done`,
    `shipped`, `fixed`, `closed`, `merged`, `resolved`, `landed`) -> `warn` to reconcile. Anchoring on the
    status **lead word** means a mid-status mention like `Active — Phase 0 complete` never false-flags.
  - **(b2)** issue **OPEN** but the doc's `status:` carries an explicit hand-off phrase anywhere
    (`ready to close`, `ready for 3-completed`, `awaiting close`) -> `warn`. Signal (b) alone is defeated
    by a self-contradictory status such as `Active — Phases 1-4 complete … Ready to close to 3-COMPLETED`:
    every human reads that as done; the lead word is `active`. The phrase list stays short and literal —
    a general "does this prose mean done?" parse is the false-positive machine the lead-word anchor exists
    to avoid.
  - **(c)** doc is in `3-COMPLETED` but the issue is **OPEN** -> `warn`, recommending `gh issue close <n>`.
    The lifecycle bucket is a deterministic signal; the status prose is not. `3-COMPLETED/` *is* the
    operator's assertion that the work is done, recorded in a path and verifiable with `test -f`.
    A doc in `3-COMPLETED` with a **CLOSED** issue is the fully reconciled end state: no finding.
- `warn` (never `error` — does not block, even in `full`, mirroring `pdda.sh changelog`); **flag-only**,
  never moves a file and never closes an issue
- gh-degrade: with `PDDA_ISSUE_SYNC_SOURCE=auto` (default) it uses live `gh` when that succeeds, else a
  cached state file (`PDDA_GH_STATE_CACHE`). `gh`/`cache` force one source. **A successful live lookup
  writes the cache** (best-effort, atomic), so the offline consumers — chiefly the `Stop` hook — have
  last-known state without a network call. When neither source yields a state, the affected doc emits a
  `warn` saying the sync was **NOT evaluated**: a check that could not run is not a check that passed.

Why warn-only + flag-only:
- every drift class here is mechanical, so the check carries zero false-judgment risk; a false flag is
  one ignorable warn line and a missed flag just leaves today's manual reconciliation — both cheap, so
  warn-only never-blocks is the right calibration (same stance as `pdda.sh stale` and `pdda.sh changelog`)
- closing an issue is a **human judgment** about whether the work is genuinely done, so no script does it.
  The `Stop` hook names the wrap (`/pdda-eod`) when this check reports reconciliation drift; the skill
  proposes, the operator confirms. Detect deterministically, act only with a yes.

#### I. `pdda.sh governance`

Purpose:
- evaluate the repo's own governance docs — `ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`,
  `README.md`, `CLAUDE.md`, `PROJECT/PDDA.md`, `utils/pdda/PDDA-INSTALL.md` — for the specific class of
  drift that Principle #4 (*one canonical place per fact*) exists to prevent: a doc pointing at a file
  that has moved or never existed, a doc that exists but no cold agent's read order will ever reach it,
  or a contract doc and the shipped code silently disagreeing about what commands or env vars exist

Minimum behavior (four checks, one shared `pdda-check-governance` id):
- **dead references** (`warn`) — every filename ending in `.md` **or `.sh`** named inside a governance
  doc must resolve to a real file, checked against the repo root or (for `./`/`../` links) the
  referencing file's own directory. A bare filename
  with no directory component (e.g. `blank.md`,
  which legitimately exists once per lifecycle folder) additionally falls back to a repo-wide basename
  search before being called dead — only a name absent *everywhere* is flagged. A `GH-<n>-*.md` name is
  never flagged; those are illustrative instances of the issue-doc naming convention, not fixed
  cross-references. `warn`, not `error`: prose extraction is inherently more heuristic than the
  mechanical checks above, so a false flag should cost one ignorable line, not a blocked build (same
  calibration as `pdda.sh stale`/`pdda.sh changelog`).
  - **Three extraction patterns** (union, then deduplicated): the target of a markdown link; a code span
    that contains nothing but the path; and **command-position paths** — a script token that opens a code
    span or a scanned fence line. The third exists because a router's most load-bearing references are
    the commands it tells an agent to run, and those carry arguments, so they close neither a link nor a
    backtick span right after the suffix. A vendored harness script invoked with a `--help` flag inside a
    code span, and a bare sync-tool invocation with its subcommand inside a scanned ` ```bash ` fence,
    both name a real file and matched nothing before GH-23 P3. Command position — line start, or
    immediately after a backtick — is where a shell command's *program* sits; a script name appearing
    later in a sentence is prose, and is not extracted. That is what keeps a documented invocation such
    as `pdda.sh run` from being read as two separate references. A leading `./` is stripped, because in
    command position it means "from the repo root I am standing in", not "relative to this doc".
  - **Suffix widening was not free.** `.sh` references are the ones that differ most between the canonical
    repo and a target, so the exemption manifest below had to grow with them — a fresh install went from
    0 to 46 self-inflicted warns before it did. A ref to a script that exists only on the operator's
    `PATH` (never in the repo) is a known, accepted false positive; it costs one advisory warn.
  - **GH-15 shipped-doc exemption manifest:** `utils/pdda/PDDA-INSTALL.md` and `PROJECT/PDDA.md` ship
    to every target install (`PDDA_GOV_SHIPPED_DOCS_DEFAULT`) but legitimately reference files
    `install.sh` deliberately does not copy there — the target's own repo-authored startup docs
    (`ROUTER.md`, `AGENTS.md`, `GUIDING-PRINCIPLES.md`, `README.md`, `CLAUDE.md`), canonical-only skill and
    companion-doc paths (`.claude/skills/pdda/SKILL.md`, `.claude/skills/governance-audit/SKILL.md`,
    `PROJECT/3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md`), and the pre-`utils/pdda/` legacy layout path
    (`utils/PDDA-INSTALL.md`, named only in migration-note prose). A fresh `install.sh . --mode observe`
    self-inflicted ~30 dead-reference/env-var warns from exactly this mismatch on its very first
    `pdda.sh run`, drowning a new adopter's own repo drift in PDDA-on-PDDA noise. The dead-reference scan
    skips a match against `PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS_DEFAULT`, scoped strictly to the docs in
    `PDDA_GOV_SHIPPED_DOCS_DEFAULT` — a repo-authored governance doc (e.g. this canonical repo's own `ROUTER.md`)
    referencing one of these is still a real dead-reference bug and is never exempted. The manifest was
    built from an actual dead-reference scan of a bare `install.sh` target, not retyped from an issue's
    illustrative list — re-run that scan if the shipped-doc set or its prose changes materially.
    **GH-17 (resolved separately from this manifest):** this file's own "CHANGELOG.md" section used to
    dead-reference two specific filenames (a retired recap note, a compliance-observations file) that
    turned out to be artifacts of the repo this contract doc was originally adapted from, never real
    files in this standalone PDDA repo. Naming them here was a copy-paste leftover, not a real PDDA
    requirement — genericized below rather than exempted, since a name that's dead *everywhere* is a
    real accuracy bug (Principle #4), not an install-boundary false positive like the manifest above.
  - **GH-23 P3 additions to the same manifest**, each read off a real scan of a bare
    `--with-startup-docs` target (46 warns before, 0 after), in three groups:
    canonical-only **tools** a target never receives (the installer itself; the sync engine, which
    `pdda-sync-manifest.conf` excludes because targets are leaf nodes; `templates/`; `test/`);
    **legacy flat-layout paths** (`utils/pdda.sh`, `utils/pdda-lib.sh`, …) that the install manifest names
    *precisely because they must not exist* — it documents the layout `install.sh` migrates away from,
    and their `.md` sibling was already exempt for this reason; and `config.sh`, which belongs to
    git-pulse, a separate program.
    **Known separate issue, not covered by this manifest:** this file's own CHANGELOG section
    dead-references the retired RECAP note-file and the REAL-AGENT-OBSERVATIONS compliance-findings
    file (see the "CHANGELOG.md" section below), neither of which exist anywhere in this repo, not
    even the canonical repo — a pre-existing doc-accuracy drift unrelated to the install-omission pattern above; left
    flagged rather than silently exempted pending a human decision on those files' fate.
- **orphan governance docs** (`warn`) — a present governance doc whose filename never appears anywhere
  in the index doc (`ROUTER.md` by default) — a doc a cold agent's startup sequence would never surface.
- **subcommand drift** (`error`) — every subcommand in `utils/pdda/pdda.sh`'s dispatcher `case` block
  must be named somewhere in the index doc. Parsing the `case` statement is mechanical (zero prose
  ambiguity), so this earns the same blocking severity as the structural checks — it is the concrete
  enforcement of AGENTS.md #5 ("keep the installer surface in lockstep").
- **env-var drift** (`warn`) — every `PDDA_*` token mentioned in a governance doc should actually be
  read or set somewhere in a shipped script (`utils/pdda/*.sh` or the repo-root `install.sh`). `warn`,
  not `error`: `utils/pdda/PDDA-INSTALL.md` ships to every target install but also documents
  `utils/pdda/pdda-sync.sh` — a canonical-only tool never copied to targets (it isn't in the "Canonical
  install set" above) — so a var like `PDDA_SYNC_BACKUPS` legitimately won't resolve in a target
  install's own scripts. That's expected, not drift, confirmed by installing this check into a second
  repo and seeing exactly that false positive fire — same calibration as dead-reference above.
  - **GH-15:** the same exemption mechanism above covers this class of mismatch too —
    `PDDA_GOV_SHIPPED_DOC_ENVVAR_EXEMPTIONS_DEFAULT` (`PDDA_REGISTRY`, `PDDA_GITPULSE_DIR`,
    `PDDA_SYNC_MAX_SHRINK`) lists canonical-only-tool env vars that `PDDA-INSTALL.md`/`PROJECT/PDDA.md`
    legitimately document but no target-installed script reads, scoped to the same `PDDA_GOV_SHIPPED_DOCS`
    set so a repo-authored doc's phantom env var still fires.

Expected exceptions:
- fenced `console`/`text`/`transcript` blocks and blockquote lines are not scanned (same carve-out as
  `pdda.sh hardcoded-paths`)
- override the doc set with `PDDA_GOVERNANCE_DOCS` (space-separated, repo-relative) and the index doc
  with `PDDA_GOVERNANCE_INDEX` (default `ROUTER.md`) for a repo with a different layout
- override the shipped-doc exemption manifest with `PDDA_GOV_SHIPPED_DOCS`,
  `PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS`, and `PDDA_GOV_SHIPPED_DOC_ENVVAR_EXEMPTIONS` (all
  space-separated) for a repo with a different shipped-doc layout

This check is deterministic-only; it catches the mechanical drift classes above. Semantic
contradictions in prose (two docs stating conflicting policy, a claim that quietly went stale) are a
judgment call for the LLM layer or a human — see the `/governance-audit` skill, which runs this check
first and then reads the same doc set for that fuzzier class of inconsistency.

#### J. `pdda.sh releases`

Purpose:
- validate `RELEASES.md`, the single forward-looking release-planning ledger — deliberately light.
  This replaced an earlier per-tag-doc lifecycle (`PROJECT/releases/RELEASE-<tag>.md` with a
  Draft/RC/Published status, linked marathons, linked issues, and a GitHub release-tag cache) that
  turned out to be too much data to keep current for an initial release. Fields and checks grow
  only as a real need shows up — see "RELEASES.md — release ledger" below.

Scope: every `Release:` block in `RELEASES.md`.

Minimum behavior:
- parse `RELEASES.md` into blocks (one per `Release:` line; see format below)
- **release-value check**: `error` if a block's `Release:` value is empty (a malformed-doc guard,
  not a readiness gate)
- **target-date check** (optional field): `warn` if `Target Date` is set but is not a valid
  `YYYY-MM-DD` calendar date
- **overdue check**: `warn` if `Target Date` has passed and `Status` doesn't read exactly `Shipped`
  (case-insensitive) — `Status: Shipped` is the sole "already shipped" signal; a populated `GH_URL`
  alone does not silence this (it means a Release object exists, not that it shipped)
- **QA-gate field check** (optional fields): `warn` if `Front-door reviewed`, `Shakedown reviewed`,
  or `License file` is set but its value isn't exactly `Yes` or `No` (case-insensitive); a blank
  value is fine (not yet answered)
- **iteration-band check** (optional field): `warn` if `Iterations` is set but isn't a well-formed
  `<lo>-<hi>` band — both sides plain dotted-numeric, `lo` no greater than `hi`. Strict on purpose:
  a band nobody can evaluate is worse than no band, because the duplicate check below silently
  stops covering that release
- **in-band duplicate check**: `warn` if a block's `Release:` version falls inside a *different*
  block's reserved `Iterations` band. This is the admission rule made mechanical — a version inside
  a band is already accounted for, so a block for it is by definition a duplicate. Only plain
  dotted-numeric versions are tested; a prerelease or date-shaped version is left to human judgment
  rather than guessed at
- **never blocks, even in `full` mode** — this check does not gate its exit code at all, regardless
  of findings. The one `error` above (empty `Release:` value) is a malformed-doc guard, surfaced
  loudly so it isn't missed, but deliberately cannot fail a build

gh-degrade: none. The check is purely file-driven (no GitHub calls), which is a deliberate
simplification over the old per-tag-doc check's issue/tag cross-checks against `gh`.

#### RELEASES.md — release ledger

**`RELEASES.md` is an optional planning aid.** It is not a required artifact, not a checklist, and
not something to keep topped up. An empty file, a stale file, or no file at all are all valid
states — `pdda.sh releases` skips a missing file entirely ("RELEASES.md not found — nothing to
check") and never blocks, even in `full` mode.

**Do not proactively offer to fill it in, populate it, bring it current, or add a release that has
already shipped. Do not treat a sparse file as an incomplete one.** Edit it only when an operator
explicitly asks for release *planning*.

That instruction is aimed at the reader who is likeliest to erode this file, which is increasingly
an LLM maintainer. The failure mode is not one bad decision; it is a long series of individually
reasonable offers to help — "want me to add the release you just shipped?" — that in aggregate turn
a planning aid into a second, hand-maintained history of what shipped. Two sources of truth for the
same fact is the defect, and it arrives one helpful suggestion at a time. `CHANGELOG.md` is the
history. This file is not.

What it *is*: a first-class root file, like `ROADMAP.md`/`CHANGELOG.md` — a single forward-looking
planning ledger for major releases, not a lifecycle bucket of per-tag docs. Marathon plans and other
forward planning cross-reference it for target release names/dates.

**The admission rule.** A block earns its place by being worth *planning toward* — a named arc with
a theme, usually carrying a target date and a milestone. If the only thing that can go in
`Description:` is a restatement of what changed, it belongs in `CHANGELOG.md` and nowhere else.
Everything below the threshold goes in an `Iterations:` band (see the field docs) rather than getting
its own block.

The test is the theme, not the paperwork: `Target Date:` and `Milestone:` are optional fields and
their absence never disqualifies a block. A release can be worth planning toward before anyone knows
when it lands.

Format — one flat `Label: value` block per release, blank line between blocks (blank lines are
just visual spacing; a new block starts at the next `Release:` line). Field order is not parsed and
every field except `Release:` is optional, so a real block is usually shorter than this:

```text
Release: 1.0.0
Iterations: 1.0.0-1.0.4
Status: Draft
Target Date: 2026-07-31
Codename: n/a
Milestone:
Description:
GH_URL:
Front-door reviewed:
Shakedown reviewed:
License file:
```

Fields:
- `Release:` (required) — the version being planned
- `Status:` (optional) — free-text, unvalidated by design (`Draft`, `Working`, `Shipped`, whatever
  an operator finds useful). **`Status: Shipped` is the sole "already shipped" signal** — both
  `pdda.sh releases`'s overdue nudge and `pdda.sh releases-current`'s "in progress" filter key off
  it exclusively. This is a rough signal, not a gated lifecycle — no fixed vocabulary is enforced.
- `Iterations:` (optional) — a **reserved band of version numbers**, written `<lo>-<hi>` (e.g.
  `0.2.0-0.2.4`). Versions inside a band ship freely and are recorded in `CHANGELOG.md` only; they
  **never get a block here**, and the band deliberately does not enumerate them. Absence of the
  field means no band is reserved.

  **The band's owner is the one exception.** A band is written on the block it belongs to, and that
  block's own `Release:` is the band's `<lo>` — so the owner sits inside its own band and keeps its
  block. Every *other* version in the range is covered by the band and gets none. `pdda.sh releases`
  identifies the owner by line, not by version text, so a second block that merely repeats the
  owner's version is still caught as the duplicate it is.

  This is what gives the admission rule an answer instead of an argument. "Where does 0.2.3 go?"
  resolved case-by-case is resolved by adding a row, every time; with a band it has a written
  answer, and `pdda.sh releases` can check it — a version inside an existing band is already
  accounted for, so a block for it is by definition a duplicate. That is testable in a way "is this
  release meaningful?" never will be.

  **When a band is exhausted** — `0.2.5` is needed and the band ends at `0.2.4` — **widen the band.
  Do not start enumerating, and do not add a block.** Promote to the next release only when the work
  genuinely became a new arc with its own theme, never merely because the numbers ran out; a version
  number driven by an accounting artifact is the convention rotting rather than holding.

  Rejected alternative, recorded so it isn't re-proposed: persisting `Iteration 1:` … `Iteration 5:`
  labels per release. That is 20–25 named rows across a five-release horizon, each an invitation to
  fill in what shipped — the same drift, arriving as structure instead of as appended blocks. One
  optional field beats five required ones.
- `Target Date:` (optional) — `YYYY-MM-DD`; `pdda.sh releases` warns once this passes and `Status`
  doesn't read `Shipped`
- `Codename:` (optional) — `n/a` is fine
- `Milestone:` (optional) — free-text, unvalidated, the **release → issue-set join key**. It holds a
  GitHub milestone *title*, so a release's scope can be queried rather than hand-maintained here:

  ```bash
  gh issue list --milestone "Quicksilver" --state open --json number,title,labels
  ```

  That query *is* release-driven work selection, with no second cache and no issue list copied into
  this file — which is why the field is worth having and why it stays a pointer. Unvalidated for the
  same reason as `Status:`: checking a title against GitHub would need a `gh` call, and this check is
  deliberately network-free. **Not warned on when absent** — a release with no milestone is a normal
  state, and a nudge here would recreate exactly the fill-it-in pressure this section exists to stop.
- `Description:` (optional) — one line for now; grows into something richer only if needed
- `GH_URL:` (optional) — populated once *a* GitHub Release object exists, including a draft (see
  `/release` skill). **This means "a Release object exists," not "shipped"** — a draft's `GH_URL`
  is real but the release isn't out. Flip `Status: Shipped` yourself (or let `/release` do it on an
  actual, non-draft publish) when it's really out; `GH_URL` alone no longer implies that.
- `Front-door reviewed:` / `Shakedown reviewed:` / `License file:` (optional) — pre-release QA-gate
  checkboxes: has the `/front-door` onboarding audit run, has the `/shakedown` script-path audit
  run, is a `LICENSE` file present. `Yes` or `No`; `pdda.sh releases` warns on any other non-blank
  value. A blank value just means not yet answered, not a failure.

Add new fields only when a real need shows up. This format intentionally started smaller than the
earlier per-tag-doc convention (status lifecycle, linked marathons, linked issues, a GitHub
release-tag cache) — that was more data than was practical to keep current for an initial release.
`Status:` is the first field added back in, deliberately kept unvalidated (baby steps, not a new
gated lifecycle) rather than reintroducing the old rigid `Draft → RC → Published` enum. The three
QA-gate fields are the second: a real pre-release checklist need (open-sourcing a release means a
front-door pass, a shakedown pass, and a `LICENSE` file all need to be true before shipping) that,
unlike `Status`, has an unambiguous right answer — so they're validated `Yes`/`No` rather than free-text.
`Iterations:` and `Milestone:` are the third pair, and both are additive: the parser ignores labels
it doesn't know, absence means "not reserved" / "no milestone", and neither produces a finding in a
ledger that has never used them. A repo can adopt them, or never hear of them, with no migration.

Two skills operate on this file: `/release-plan` **authors** entries (interviews the operator,
proposes a canonical version by cross-referencing `CHANGELOG.md`, previews, appends on confirmation)
and `/release` **publishes** an existing entry to GitHub once its `Status` is ready to ship. Both are
operator-triggered by design and neither should be offered unprompted — a skill that exists to keep a
file populated is the most efficient possible way to violate the optionality rule at the top of this
section.

#### `pdda.sh releases-current`

Read-only roll-up (not part of `PDDA_DETERMINISTIC_CHECKS` — emits no findings, never gates): lists
every `RELEASES.md` entry whose `Status` is empty or not exactly `Shipped`. A rough, non-authoritative
answer to "what's currently in progress" — for a human, or for another repo's tooling (e.g. the XYZ
sibling harness) to shell out to instead of re-implementing `RELEASES.md` parsing itself. Because
`Status` is free-text, this is a best-effort filter, not a guarantee — an entry with a typo'd or
unconventional `Status` value still shows up (safer default: never silently hide something that
lacks an explicit `Shipped` signal).

The four-tier shipping chain:

```
task/issue  (GH-*.md in 1-INBOX)
  → project (2-WORKING active doc)
    → marathon (marathon/MARATHON-*.yaml + PROJECT/2-WORKING/MARATHON-PLAN-*.md)
      → release (RELEASES.md entry + GitHub Release)
```

### 2. LLM-assisted doc readiness review

This catches the issues where structure exists but planning quality is weak.

#### `pdda-doc-ready.sh`

Purpose:
- review active project plans and flag docs that are not ready for reliable automation

It should check for:

- phased plans missing QA gates after a phase
- phase sections with actions but no observable acceptance criteria
- multi-phase plans missing a table of contents listing each phase
- discovery or spike phases whose findings were not written back into the plan doc
- medium-large plans missing the triage ratings (`effort`, `complexity`, `risk`, `phases`)
- status tables that are technically present but stale versus the body
- docs that bury the next action in prose instead of making it explicit
- plans that duplicate detail already meant to live in another canonical doc
- contradictory status, such as frontmatter saying `Completed` while the body says active

It should not:

- auto-rewrite the plan body without review
- invent technical claims not grounded in the doc
- silently override deterministic lints
- **block a build.** The LLM layer is advisory: its findings are capped at `warn` (any model `error`
  is clamped to `warn` in `pdda-doc-ready.sh`), so a non-deterministic oracle can never fail a build —
  the same doc must not pass at 2pm and fail at 3pm. Only deterministic checks earn blocking power.

### 3. Doc-health hooks (event-triggered delivery)

The deterministic checks above can also run automatically from Claude Code hooks, as a two-tier
doc-health system. The hooks are pure **delivery** — they run the SAME section-1 checks on a trigger;
they add no new analysis class. Both are **warn-only and fail-open: they always exit `0` and can never
block** an edit or a stop (a doc-hygiene reminder is never worth interrupting work — the calibration
principle, same as `pdda.sh changelog`).

- **Tier 1 — `pdda-edit-doc-hook.sh` (`PostToolUse` on `Edit|Write|MultiEdit`).** Reads the edited
  `tool_input.file_path`; exits `0` instantly unless it is `ROADMAP.md` or a `PROJECT/**/*.md` doc;
  otherwise runs the fast **local single-file** subset for just that file — `frontmatter`,
  `status-table`, `hardcoded-paths`, `roadmap-coverage` (and `roadmap` for `ROADMAP.md`), scoped via
  `PDDA_ONLY_FILE`. **No network, no `gh`, no LLM**, so it stays instant and cannot gate an edit.
- **Tier 2 — Stop full-scan (`pdda-stop-doc-health.sh`).** The companion that runs one consolidated,
  system-wide doc-health scan per turn (the deterministic suite plus `issue-doc-sync` against the
  cached gh-state file). See [Suggested Stop doc-health scan](#suggested-stop-doc-health-scan).

`PDDA_ONLY_FILE=<path>` is the seam that scopes any check to a single file (unset = full scan, the
default everywhere else). Wiring is repo-local in `.claude/settings.json`; installs receive the hook
scripts via the manifest and opt in by adding the hook entries.

#### Suggested Stop doc-health scan

Tier 2's `pdda-stop-doc-health.sh` runs **one** system-wide scan per turn and prints a **single
consolidated report**:

- it runs the deterministic suite with `PDDA_ISSUE_SYNC_SOURCE=cache`, so `issue-doc-sync` reads the
  cached gh-state file (written by `pdda.sh gh-refresh`) and the scan makes **no network call**;
- it runs in `observe` mode with the LLM layer disabled — purely deterministic, fast, offline;
- it aggregates the run into one report: a header with the error/warn totals, then the warn/error
  finding lines (an `all clear` line when there are none);
- it **always exits `0`** (proven by `test/pdda-doc-health-hooks.sh`), so it can never block a stop.

Wire it as a `Stop` hook in `.claude/settings.json` (no matcher). Because it reads the cache rather
than calling `gh`, keep `pdda.sh gh-refresh` on the hourly cadence so the Stop report stays current.

## Enforcement modes

PDDA runs in one of three modes. The mode is resolved in this order: **the `PDDA_MODE` env var wins if
set; otherwise the first non-comment line of a repo-root `.pdda-mode` file; otherwise the built-in
default `observe`.** (So an env var overrides a committed `.pdda-mode` — convenient for a one-off
`PDDA_MODE=observe` pass against a repo otherwise committed to `full`.) The point is an **adoption
ramp**: a freshly-installed PDDA should never break a build on day one, and a project should graduate
onto the rails deliberately.

| Mode | When | Findings reported | Exit on `error` |
|---|---|---|---|
| `observe` | just installed | yes | always `0` |
| `light` | transitioning | yes | `0` (warn, don't block) |
| `full` | fully on rails | yes | non-zero (blocks) |

- The default is `observe` so a brand-new install is non-blocking — it shows the team what PDDA
  *would* flag without failing anything.
- `light` is the transition phase: loud reports, but still never fails a build, while the backlog of
  doc debt is cleared.
- `full` is the strict end state: `error` findings block with a non-zero exit. A repo declares it by
  committing `.pdda-mode` with `full`.
- **No mode mutates the tree.** Stale docs are *flagged, never auto-moved* — the only destructive
  mechanic was removed (see the stale-doc check above). Mode controls one thing only: whether an
  `error` blocks. Every check ends with `exit "$(pdda_gated_exit "$EXIT_CODE")"`, which returns the
  real code only in `full`.

## ROADMAP.md contract

`ROADMAP.md` is a pointer file, not a plan body.

It should contain:

- queued / parked intake pointers for newly captured `GH-*.md` docs
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

Coverage rule:
- every active doc in `PROJECT/2-WORKING` must be reflected here by a pointer (a one-line ledger entry
  that links it), so the ledger never falls behind the working set. A working doc that legitimately
  should not appear opts out with `roadmap_exempt: true` in its frontmatter. This is the inverse of the
  "no detail leaks in" rule above: nothing active goes *missing from* the roadmap either.
- every captured GitHub issue doc in `PROJECT/1-INBOX/GH-*.md` must also be reflected here as a
  one-line **queued / parked** pointer until it is promoted, deferred out, or closed, so intake cannot
  quietly disappear and later be duplicated.

How this is enforced (so it cannot quietly rot in either direction):
- **deterministic (no leak in)** — `pdda.sh roadmap` errors on task checklists / `### Checklist` /
  `### QA checklist` headings and warns on size sprawl (runs hourly, free, no model needed)
- **deterministic (no gap missing)** — `pdda.sh roadmap-coverage` errors when either an
  active `PROJECT/2-WORKING` doc has no pointer here, or a captured `PROJECT/1-INBOX/GH-*.md` doc is
  not parked here as a queue entry (honors `roadmap_exempt: true`)
- **LLM** — `utils/pdda/pdda-doc-ready.sh` reviews `ROADMAP.md` against the full pointer contract for the
  fuzzier "this paragraph is really execution detail" cases (honors the carve-out)
- the file itself carries a top banner restating the contract, so a human editing it sees the rule

## CHANGELOG.md — end-of-iteration record (first-class)

`CHANGELOG.md` is a first-class PDDA artifact: the canonical, newest-first running log of what changed,
updated **at the end of each iteration**. It is the one narrative/provenance log this contract
prescribes — if an adopting repo kept its own ad hoc recap or run-observation notes before adopting
PDDA, `CHANGELOG.md` supersedes them; PDDA does not require or name any such file itself (Principle #4 —
one canonical place per fact). Durable Costly / one-way-door bets still earn a `decisions/` record.
updated **at the end of each iteration**. It supersedes the retired RECAP convention as the running
provenance/narrative log, and it also absorbs the run-specific compliance findings the retired
REAL-AGENT-OBSERVATIONS convention used to collect. Durable Costly / one-way-door bets still earn a
`decisions/` record.

It should contain:

- newest-first, dated sections headed either `## YYYY-MM-DD` or `## [x.y.z] - YYYY-MM-DD`
- one entry per substantive iteration: what changed, why, and the verification (test / suite result)
- the bet behind a consequential change when one applies (the call, the expected signal, reversibility)

It should not contain:

- per-file diffs or deep execution detail that belongs in the entry's `PROJECT/**` doc
- aspirational plans — those live in the project doc and the `ROADMAP.md` ledger

Maintained append-only:

- add a new dated entry per iteration; **never rewrite a past entry's numbers, claims, or
  recommendation** — *especially* not when it turned out wrong. Correct a past entry by appending a
  dated correction, not by editing history. This append-only guarantee is the whole point of having one
  canonical narrative log instead of scattered ad hoc notes.
  dated correction, not by editing history. This is the provenance guarantee the retired RECAP
  convention used to carry.

Recording a bet (when a change is consequential):

- when a decision is Costly, a one-way door, or rides on an assumption that could be wrong, the entry
  records the call, the bet/assumption, the expected signal with a by-when, the reversibility read, a
  revisit trigger, and a graduate / iterate / abandon recommendation. Below that threshold a plain
  entry suffices. Durable bets also earn a `decisions/` record. An adopting repo is free to keep its own
  separate run-specific compliance-observations doc if that's useful to it, but that's a local
  convention this contract neither requires nor names. (`AGENTS.md` principle #7 supplies the
  behavioral trigger — *record the bet*; this contract owns the *where and how*.)
  entry suffices. Durable bets also earn a `decisions/` record; run-specific compliance findings go in
  the iteration's own `CHANGELOG.md` entry. (`AGENTS.md` principle #7 supplies the behavioral trigger —
  *record the bet*; this contract owns the *where and how*, so governance is not fragmented across the
  two files.)

How this is enforced (a nudge, not a gate):
- **deterministic** — `pdda.sh changelog` **warns** (never `error`, so it never blocks —
  even in `full`) when the newest dated entry predates the latest git commit by more than
  `PDDA_CHANGELOG_STALE_DAYS` days (default `0`), i.e. an iteration shipped without a changelog entry
- whether an entry is actually *substantive* stays a human / LLM judgment, not a regex

## Activity log artifact

PDDA should write an append-only activity log to:

- `PROJECT/PDDA-ACTIVITY.jsonl`

Each script run should append:

- per-finding entries
- one summary entry for the script
- enough metadata to tell what moved, what failed, and when

## Suggested hourly schedule

Run the deterministic checks every hour in this order:

1. `pdda.sh frontmatter`
2. `pdda.sh status-table`
3. `pdda.sh hardcoded-paths`
4. `pdda.sh roadmap`
5. `pdda.sh roadmap-coverage`
6. `pdda.sh changelog`
7. `pdda.sh stale`
8. `pdda.sh issue-doc-sync`
9. `pdda.sh releases`
10. `pdda.sh governance`

Then run:

11. `pdda.sh doc-ready`

(`pdda.sh run` runs exactly this sequence and applies the active `PDDA_MODE` gate. Scheduling the
single aggregate command is the recommended hourly cron entry.)

The cached GitHub issue-state refresh is a separate, network-only step. Run `pdda.sh gh-refresh`
(the standalone `utils/pdda/pdda-gh-refresh.sh`) on the same hourly cron/launchd cadence, **before**
the suite, so `issue-doc-sync` and the Stop doc-health scan read fresh state. It is the only step that
needs `gh`/the network; it writes `PDDA_GH_STATE_CACHE` atomically and leaves the existing cache
untouched on any `gh` failure, so the suite itself stays offline-tolerant by reading the cache.

Reason for the order:

- deterministic failures should surface first
- the network-dependent `issue-doc-sync` runs last among the deterministic checks, so every local
  check still completes when `gh` is offline (it then degrades to the cache or an `info` skip)
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
- a multi-phase plan has a table of contents listing its phases
- any discovery or spike phase has its findings written back into the doc
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
- ~~a `priority` field if you want deterministic triage beyond folder placement~~ **superseded** by the
  `effort`/`complexity`/`risk`/`phases` [triage ratings](#triage-ratings-for-medium-large-work), which
  give richer triage than a single priority scalar — automation derives the selection signal from them
  rather than storing one frozen number
- a `pdda_hold: true` override for docs that should remain in `2-WORKING` despite inactivity
- a second generated PDDA summary artifact beyond the activity log

## Open questions

These need a decision before the automation should be considered stable:

1. Should `PROJECT/PDDA-ACTIVITY.jsonl` remain append-only forever, or rotate by month once the volume grows?
2. Should `ROADMAP.md` remain root-level canonical only, or do you also want a project-local roadmap index under `PROJECT/`?

Resolved:

- ~~Should the compatibility window end on `2026-07-31`, or be shorter/longer?~~ **Resolved
  2026-06-22:** removed entirely. No doc in the repo used an old alias, so a dated cutover guarded
  nothing — and a script whose behavior changes silently on a hardcoded date is the same fossilized
  assumption the hardcoded-path check exists to prevent. Headers are now exact-or-`error`, no window.
- ~~Should `gh_issue` stay optional metadata, or become required for bug-fix docs that originated from
  GitHub?~~ **Resolved 2026-06-21:** `gh_issue` stays optional in general, but is **required** on any
  doc that originated from a GitHub issue — which the `GH-<number>-…` filename guarantees. See
  [GitHub issue intake](#github-issue-intake).

## Recommended v1 stance

If the goal is "get project docs onto rails quickly," the safest v1 is:

- start in `observe` mode, then graduate `light` → `full` as the doc backlog is cleared
- enforce exact status-table headers (no alias window)
- require QA gates on phased plans
- forbid hardcoded absolute paths
- run deterministic checks hourly
- let the LLM reviewer flag readiness issues
- keep `ROADMAP.md` pointer-only (deterministic `pdda.sh roadmap` + the LLM rubric guard it)
- append all script activity to `PROJECT/PDDA-ACTIVITY.jsonl`
