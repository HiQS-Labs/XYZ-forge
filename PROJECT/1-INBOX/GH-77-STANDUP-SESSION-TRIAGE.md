---
gh_issue: 77
source: https://github.com/HiQS-Suite/XYZ-forge/issues/77
title: "/standup — session-scoped triage: what did I leave open, what is rotting, is the plan still right?"
status: Proposed (1-INBOX — not yet active)
created: 2026-08-19
doc_type: prd
effort: 3
complexity: 3
risk: 1
phases: 4
---

# GH-77: `/standup` — Session-Scoped Triage (PRD)

> Scope decisions were taken by the operator on 2026-08-19 and are **frozen** for v1: session +
> local state (no history sweep), park-only write authority, both output halves every run, tactical
> list hard-capped at 7. Sections marked **FROZEN** below are not open for re-litigation during the
> build; a builder who thinks one is wrong raises it as a finding, not as a change.

## Problem

Two failure modes make long agent sessions expensive:

**A. Wall of text.** The operator asks one question and gets four screens. The answer is in there.
Finding it costs more than the answer was worth.

**B. Rabbit hole.** Four hours in, the original focus has been diverted six times. Work sits open in
five places and neither the human nor the agent can state what is actually unfinished.

Individually these are annoyances. Together they produce a **confidence problem**, and it lands on
the two systems this repo just built. `ROADMAP.md` and the RELEASES DB are worth exactly as much as
the operator's belief that nothing has quietly fallen out of them. On 2026-08-19 that belief was
measurably unearned:

| Drift found | How long it had been true | How it was found |
|---|---|---|
| Release 0.7.1 `active` with its exit criterion met, merge landed, all three manifest items closed | ~1 day | a hand audit, prompted by an offhand question |
| Four ledger entries carrying `🆕`/`🚧` for issues GitHub had closed | 1–2 days | the same audit |
| Issues #61–#65 filed into neither the ledger nor `PARKED/` | ~1 day | the same audit |

Every one was discoverable in seconds. None was discovered by anything. **The systems were correct
and the operator still could not trust them, because nothing ever looked.**

`/standup` is the thing that looks. It is not part of the governance machinery — it is the
instrument you reach for constantly, which is why every design decision below trades completeness
for the property that makes it get used: it finishes in seconds and fits on one screen.

## Non-goals

- **Not an executor.** It recommends; the operator (or `/10days`) acts. No branch cuts, no marathons.
- **Not a retrospective.** Forward-looking only, same rule as `/finish-line`. It reports what
  REMAINS, never what happened. Narration of the agent's own recent work is the single most common
  wall-of-text source and is banned outright.
- **Not `/radar`.** No 21-day commit analysis, no flow distribution, no defect clustering. When the
  session's evidence cannot support a strategic call, `/standup` says so and names `/radar` — it
  never guesses to fill the section.
- **Not a writer.** See *Write authority*.

## Where it sits among the existing skills

| Skill | Scope | Timing | This skill's relation |
|---|---|---|---|
| `/finish-line` | one branch | closing | Borrows the Mandatory-Bar discipline and the PARKED protocol; widens scope from one branch to the whole session. |
| `/rabbit-hole` | one task | reactive, mid-task | Borrows the consolidate-once, spend-the-budget rule; fires on the *session*, not one task, and proactively. |
| `/radar` | whole repo, 21 days | strategic, occasional | Explicitly deferred to. `/standup` carries a 5-line strategic read and hands off when that is not enough. |
| `/10days` | recent issues | unattended executor | Downstream. `/standup` may recommend it; it never fires it. |
| `/releases` | the release CLI | interface | `/standup` routes into it. It does not duplicate its rails. |

The gap all five leave: **"I have been working for four hours — what did I leave open, what is about
to rot, and is the plan still right?"**

## Output contract — FROZEN

Both halves print on **every** run, in this order. Plain chat prose. Never a fenced code block,
never written to a file, never a machine report.

### Part 1 — Do this now (hard cap: 7 items)

A ranked list. Each item is **one line** and must carry three things:

1. **What** — the action, imperative, in the user's vocabulary.
2. **Why it ranked** — the priority tier it matched (see ladder), compressed to a few words.
3. **How to close it** — the exact command, file, PR, or interface. Never "reconcile the roadmap";
   always `` `releases roadmap sync` ``.

Items 8+ do not appear. They go to `PARKED/` and are represented in chat by exactly one line:
*"N further items parked."* Never itemized. The cap is the feature — a soft instruction to be
concise has never produced a concise agent; a fixed ceiling has.

### Part 2 — Strategic read (hard cap: ~5 lines)

Answers, in plain English with no tool jargon: **do `ROADMAP.md` and the RELEASES ledger still
describe what this repo is actually doing?** Name a pivot only when the session's own evidence
supports it. If it does not, the correct output is one line saying the plan looks sound and, when
warranted, that `/radar` would settle it.

The strategic half is capped, not optional. An operator who never sees a pivot signal stops
believing the plan is being checked at all — which is the confidence problem this skill exists to
fix.

### Total budget

Target **under 15 lines** including both parts and the opening line. If the honest triage does not
fit, the overflow parks — it does not expand the output.

## Priority ladder — FROZEN

Fixed order, highest first. Ties break by **staleness** (older = higher), then by **smallest effort
to close**.

1. **Data corruption or loss.** Anything that has written, or can write, wrong bytes to a persisted
   artifact. *This repo's own history is the argument: a fixture escape rebuilt the production
   ledger during the authoring of a test meant to protect it.*
2. **Crash or hang on a reachable path.**
3. **Customer-facing or revenue-affecting incident.**
4. **Nearly-finished work** — a loop one step from closed. Ranks above rot risk deliberately: the
   context is still loaded and it evaporates when the session ends. Highest regret-per-minute in
   the list.
5. **Rot risk** — an open PR going stale, a branch behind trunk, an unsynced ledger, a filed issue
   that landed in no index.
6. **Housekeeping** — doc lifecycle moves, PDDA steps owed, test findings not yet written down.

Tiers 1–3 require **evidence** (`file:line`, a PR number, an issue number, or an observed failure).
Burden of proof is on inclusion: unsure → it drops a tier, or parks.

## Input scope — FROZEN

**Reads:** the conversation; the working tree and `git status`; current branch, ahead/behind trunk;
open PRs; `ROADMAP.md`; the RELEASES ledger via the CLI; `PARKED/`.

**Does not read:** long-window commit history, issue-text similarity corpora, runtime logs. Those
are `/radar`'s lenses and running them here would reintroduce the exact wall of text this skill
exists to prevent.

Every read is cheap and bounded. The design target is **seconds, not minutes** — a skill that takes
two minutes is a skill the operator stops reaching for, and an unreached instrument detects nothing.

## Write authority — FROZEN

`/standup` writes **exactly one thing**: dropped and overflowed items into `PARKED/`, in the
existing dated-file format (`PARKED/<YYYY-MM-DD>-<event>.md`, append-only, one file per parking
event). It never edits `ROADMAP.md`, never touches `releases.db`/`releases.sql`, never files an
issue, never commits, never pushes.

This is what makes it safe to run reflexively, which is the whole point.

**But park-only is not the same as interface-ignorant.** A recommendation the next agent has to
research is a recommendation that costs more than it saves. The skill therefore ships an
**interface catalogue** as a first-class section and cites from it in every item it emits.

## The interface catalogue — what the skill must know cold

This is the section that makes `/standup` a suite member rather than a parallel opinion.

### RELEASES DB (GH-32)

Single CLI, `python3 utils/py/releases_app.py`:

| Need | Command |
|---|---|
| What ships next | `next` |
| One release in detail | `show --version <v>` (`--full` for untruncated prose) |
| Ledger health | `check` — generation trio, receipt chain, advisories |
| Ship it | `ship --gid <GID> --evidence "<run cite>"` — **evidence is required**, `rule=ship-needs-evidence` |
| Change a field | `update --gid <GID> --<field> <value>` |
| Mirror the roadmap | `roadmap sync` — one-way, a no-change sync is a **free no-op** |

Hard rules to carry: **never hand-edit `releases.sql` or `releases.db`**; merge conflicts on the
dump have a one-command resolver (`utils/releases-merge-resolve.sh`); the full contract lives in
`RELEASES-DB-FAQS.md`.

Advisories `check` emits that map directly onto ladder tier 5: `rule=release-overdue`,
`rule=release-target-passed`, `rule=temp-ref-stale`.

### ROADMAP schema (GH-69 shadow)

Entry format — the parser is a regex and its failure mode is **silent skip**, so shape matters:

```
- **GH-<n> · <title>** <marker> **<status phrase>** — <body>. → [<doc>](PROJECT/…md) · [#<n>](<issue url>)
```

Sections the marathon planner actually reads: `Queue / parked intake`, `In progress`, `Completed`,
`Deferred · vision`. A heading outside that list is mirrored by the shadow but invisible to the
planner — `/standup` must say so when it recommends adding an entry under one.

After **any** ledger edit, two follow-ups are owed and the skill must name both:
`releases roadmap sync`, then `bash utils/roadmap-dashboard.sh` (the committed
`ROADMAP-DASHBOARD.md` is gate-checked; a stale one turns the push red).

### PDDA

Lifecycle `PROJECT/1-INBOX` → `2-WORKING` → `3-COMPLETED`. Coverage rule: **every `2-WORKING` doc
must be reflected by a ROADMAP pointer**, or opt out with `roadmap_exempt: true`. Checks:
`utils/pdda/pdda.sh roadmap`, `roadmap-coverage`, `doc-ready`.

### The marathon rail

Exactly **one** long-horizon marathon is in flight at a time (AGENTS.md → Repo-specific rails).
`/standup` must never recommend starting a second, and when the current one is named in ROADMAP's
Immediate next-up it treats that item as context, not as a candidate to re-decide.

## Degradation — loud, never silent

| Missing | Behavior |
|---|---|
| `gh` unavailable or unauthenticated | Skip the PR lens. State: *"PR rot not checked — `gh` unavailable."* Never imply a clean sweep. |
| No `PARKED/` directory | Do not create a top-level folder unannounced. Emit the full list up to the cap and say where overflow *would* go, asking once. |
| No `ROADMAP.md` or no ledger | Run the lenses available; the strategic half states which signal was absent and what that costs the verdict. |
| Empty session (invoked cold) | Legitimate. Fall back to local state alone and say the tactical list is repo-derived, not session-derived. |

A skill that degrades quietly reports a clean sweep it never performed. That is the same
"guards that cannot report red" defect class this repo has been fixing all month, and it is not
allowed to reappear here.

## Definition of done

- Loads from `skills/standup/`, symlinked per repo convention (`skills/*/install.sh` pattern).
- Tactical list **never** exceeds 7 items in chat; overflow count stated; overflowed items present
  in `PARKED/`.
- Strategic section never exceeds ~5 lines.
- Every tactical item carries tier + evidence + the exact closing command.
- **No write outside `PARKED/`.** Pinned by a test that snapshots the tree, runs the skill's
  procedure against a fixture, and asserts byte-identity for everything but the park file.
- Idempotent: two consecutive runs with no work between produce the same list.
- Every degradation row above has a test.

## Phases

1. **Catalogue + ladder.** Write the interface catalogue and the priority ladder; verify every
   command in it against the live CLI (a catalogue with one wrong flag is worse than none).
2. **The skill body.** Protocol, output contract, caps, PARKED protocol.
3. **Tests.** Cap enforcement, no-write-outside-PARKED, idempotence, each degradation row.
4. **Dogfood.** Run it at the end of three real sessions; record whether the tactical list's top
   item was the thing the operator actually did next. That is the only metric that matters, and a
   miss is a ladder bug, not a user error.

## Open questions (for the build, not blockers)

- Should the tactical list distinguish *this session's* findings from pre-existing repo state? Cheap
  to add as a marker; risks a second axis competing with the priority ladder.
- Does the strategic half need a stable ID per pivot claim (radar's target-ID pattern) so the same
  pivot is not re-raised every run? Probably yes by v2; not needed for v1.
