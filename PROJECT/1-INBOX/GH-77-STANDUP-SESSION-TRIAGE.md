---
gh_issue: 77
source: https://github.com/HiQS-Suite/XYZ-forge/issues/77
title: "/standup — session-scoped triage: what did I leave open, what is rotting, is the plan still right?"
status: Proposed (1-INBOX — not yet active)
created: 2026-08-19
updated: 2026-08-19
doc_type: prd
effort: 3
complexity: 3
risk: 1
phases: 4
---

# GH-77: `/standup` — Session-Scoped Triage (PRD)

> **Revision 2 — 2026-08-19.** Two independent relay reviews (Fable; Codex `gpt-5.6-sol` at high
> reasoning) returned *Changes requested* with 11 blockers between them. Threads:
> `relay-system/2026-08-19/gh77-standup-prd-review.md` and `…-codex.md`.
> Revision 1 named its inputs and then jumped straight to ranking — it never said what *becomes* an
> item. Everything from **The lenses** to **The test surface** below is new or rewritten; the two
> reviews' most consequential catch was that r1's declared input scope **could not have detected two
> of the three drifts that motivate the skill**, because it read no issue state at all.
>
> Sections marked **FROZEN** carry operator decisions and are not open for re-litigation during the
> build; a builder who thinks one is wrong raises a finding, not a change.

## Problem

Two failure modes make long agent sessions expensive:

**A. Wall of text.** The operator asks one question and gets four screens. The answer is in there;
finding it costs more than the answer was worth.

**B. Rabbit hole.** Four hours in, the original focus has been diverted six times. Work sits open in
five places and neither the human nor the agent can state what is unfinished.

Together they produce a **confidence problem**, and it lands on the two systems this repo just built.
`ROADMAP.md` and the RELEASES DB are worth exactly what the operator believes about whether anything
has quietly fallen out of them. On 2026-08-19 that belief was measurably unearned:

| Drift found | How long it had been true | Found by |
|---|---|---|
| Release 0.7.1 `active` with exit criterion met, merge landed, all 3 manifest items closed | ~1 day | a hand audit prompted by an offhand question |
| Four ledger entries carrying `🆕`/`🚧` for issues GitHub had closed | 1–2 days | the same audit |
| Issues #61–#65 filed into neither the ledger nor `PARKED/` | ~1 day | the same audit |

Each was discoverable in seconds. None was discovered by anything. **The systems were correct and
the operator still could not trust them, because nothing ever looked.**

`/standup` is the thing that looks. It is not governance machinery — it is the instrument reached for
constantly, so every decision below trades completeness for the property that gets it used: it
finishes in seconds and fits on one screen.

## Non-goals

- **Not an executor.** It recommends; the operator (or `/10days`) acts.
- **Not a retrospective.** Forward-looking only. Narration of the agent's own recent work is the most
  common wall-of-text source and is banned outright.
- **Not `/radar`.** No commit-history window, no defect clustering, no issue-text similarity. When
  session evidence cannot support a strategic call, it says so and names `/radar`.
- **Not a writer** outside `PARKED/`.

## Where it sits among the existing skills

| Skill | Scope | Timing | Relation |
|---|---|---|---|
| `/finish-line` | one branch | closing | Borrows the Mandatory-Bar discipline; widens scope from one branch to the session. |
| `/rabbit-hole` | one task | reactive, mid-task | Borrows consolidate-once + spend-the-budget; fires on the session, proactively. |
| `/radar` | repo, 21 days | strategic, occasional | Explicitly deferred to. |
| `/10days` | recent issues | unattended executor | Downstream. May be recommended, never fired. |
| `/releases` | the release CLI | interface | Routed into, not duplicated. |

The gap all five leave: **"I have been working for four hours — what did I leave open, what is about
to rot, and is the plan still right?"**

## Frozen decisions — FROZEN

1. **Input scope:** session + local state. No commit-history sweep.
2. **Write authority:** `PARKED/` only.
3. **Output:** both halves, every run.
4. **Tactical cap:** 7 items.

Everything below specifies *how* these are met; none of it may weaken them.

## The lenses — what is read, and what becomes an item

Each lens has a bounded read, a predicate that turns a read into a candidate, a stable key, a
required evidence field, a staleness source, and a closing interface. **A lens that cannot produce
all six for a candidate does not emit it** — it degrades loudly instead (see *Degradation*).

Throughout, `$R` is the single resolved prefix `python3 utils/py/releases_app.py`. Every emitted
command must be copy-paste executable; `$R` is defined once in the skill body and expanded in output.

| # | Lens | Bounded read | Candidate predicate | Item key | Evidence | Staleness source | Closing interface |
|---|---|---|---|---|---|---|---|
| 1 | Conversation | this session's transcript | an action the agent said it would take, or a finding it raised, that was neither completed nor parked | `conv:<slug of first 8 words>` | quoted span from the session | age 0 | named in the item |
| 2 | Working tree | `git status --porcelain` | any modified or untracked non-ignored path | `tree:<path>` | the path | file mtime | `git add`/commit, or `git restore` |
| 3 | Branch | `git rev-list --left-right --count <trunk>...HEAD` | ahead > 0 (unpushed) or behind > 0 | `branch:<name>` | the two counts | commit date of the oldest unpushed commit | `git push` / `git pull --rebase` |
| 4 | Open PRs | `gh pr list --limit 50 --json number,title,updatedAt,isDraft,mergeStateStatus` | any open PR on this repo | `pr:<number>` | number + `mergeStateStatus` | `updatedAt` | `gh pr merge <n>` / `gh pr review <n>` |
| 5 | **Issue state** | `gh issue view <n> --json number,state,title` for **only** the issue numbers mentioned in this session or cited by the current `ROADMAP.md` ledger and RELEASES manifests | a closed issue still carrying an active marker in the ledger, **or** an open issue cited nowhere | `issue:<number>` | number + state + where it is (or is not) cited | issue `updatedAt` | ledger edit → `$R roadmap sync`, or park |
| 6 | RELEASES ledger | `$R check`, `$R next`, `$R list` | any `warn: rule=…` line; an `active` release past target; a manifest item whose stored state is older than its issue's | `rule:<name>` or `rel:<gid>` | the emitted `rule=` line | release `target_date` | `$R ship …` / `$R update …` |
| 7 | ROADMAP ledger | `$R roadmap sync --dry-run` | non-zero add/update/remove counts | `roadmap:sync` | the dry-run counts line | `ROADMAP.md` mtime vs last sync | `$R roadmap sync` **then** `bash utils/roadmap-dashboard.sh` |
| 8 | PARKED | read `PARKED/*.md` | a parked item whose stated blocking condition has visibly cleared | `park:<item-key>` | the park record's key | park file date | the record's own pointer |

**Lens 5 is deliberately bounded.** It is a per-number *state* read, never a list or history sweep —
that boundary is what keeps it on the session side of the `/radar` line while still catching the two
drifts r1 could not see.

**Trunk resolution:** take the repo's declared integration branch, `development` here, per
`skills/releases/SKILL.md:81` ("Resolve the active integration branch from repo policy"). Do not
assume `main`.

### Cross-lens deduplication — runs before ranking

Two lenses routinely surface the same work. Collapse before ranking, in this order:

1. **Same issue or PR number** → one item.
2. **Same file path** → one item.
3. Otherwise distinct.

The surviving item keeps **the first key assigned in lens order** (stability across runs) and carries
**every** contributing evidence field. Its tier is the **highest** any contributing lens justified.

## Priority ladder — FROZEN order, deterministic resolution

**First matching tier wins, evaluated top-down.** An item that matches several tiers takes the
highest; it is never listed twice.

1. **Data corruption or loss** — has written, or can write, wrong bytes to a persisted artifact.
2. **Crash or hang on a reachable path.**
3. **Customer-facing or revenue-affecting incident.**
4. **Nearly-finished work** — one step from closed. Above rot risk on purpose: the context is loaded
   now and evaporates at session end.
5. **Rot risk** — stale PR, branch behind trunk, unsynced ledger, an issue filed into no index.
6. **Housekeeping** — doc lifecycle moves, PDDA steps owed, findings not yet written down.

**Evidence is required for every tier**, not only 1–3. An item without a citable evidence field is
not emitted; it parks.

**Tie-breaks, applied in order:**

1. **Staleness**, older first — measured from the lens's staleness source in the table above. When a
   lens's source is unavailable, the item's age is **unknown** and it sorts *after* every item with a
   known age (never before — an unmeasured item must not jump the queue).
2. **Effort bin**, smaller first — three deterministic bins: **S** = the closing interface is a
   single command with no argument the agent must invent; **M** = a single-file edit; **L** =
   anything else.
3. **Item key**, lexicographic ascending. This final tie-break exists so the ordering is total and
   two runs over identical state produce byte-identical output.

## Item schema — one canonical form

Every tactical item is exactly one rendered line:

```
<tier> · <what> — <evidence> — <close>
```

| Field | Rule |
|---|---|
| `tier` | integer 1–6 |
| `what` | imperative, ≤ 12 words, in the operator's vocabulary |
| `evidence` | one of: `file:line` · `#<number>` · `rule=<name>` · a quoted span. **Required.** |
| `close` | an executable command, **or** `file: <path>` / `PR #<n>: <action>` when no single command exists |

This schema is the *only* statement of what an item carries. The Definition of Done asserts against
it and adds nothing.

## Output contract — FROZEN, integer caps

Plain chat prose. Never a fenced block, never written to a file, never a machine report.

**A rendered line** = one newline-delimited line as emitted to chat. Terminal soft-wrapping does not
count. A bullet is one line. Headings count. Blank lines do not.

| Segment | Cap | Notes |
|---|---|---|
| Opening line | 1 | branch + one-clause verdict |
| Part 1 — Do this now | **7 items** | ranked; each exactly one line per the item schema |
| Overflow line | 1 | printed only when something parked or was suppressed |
| Part 2 — Strategic read | **6 lines** | includes its own heading and any degradation statement it carries |
| Degradation statements | charged to the segment they qualify | never free |
| **Total** | **17 rendered lines**, hard | not a target — a cap |

Items 8+ never appear. They park, and are represented by one line: *"N parked, M suppressed."* Never
itemized.

Part 2 answers, in plain English with no tool jargon: **do `ROADMAP.md` and the RELEASES ledger still
describe what this repo is doing?** Name a pivot only when session evidence supports it; otherwise
one line saying the plan looks sound, and name `/radar` when that is what would settle it. Part 2 is
capped, not optional — an operator who never sees the plan checked stops believing it is being
checked.

## Suppression — the anti-re-litigation rule (v1, not deferred)

Stable item keys make this mechanical, so it ships in v1:

- **Do not re-raise, within the same session, an item key already reported** unless its evidence
  field has changed.
- **Do not re-raise an item key present in any `PARKED/*.md`** whose evidence field is unchanged.
- **Do not re-raise a strategic claim already stated this session.**

Suppressed counts appear in the overflow line and nowhere else. This is `/finish-line`'s named core
failure mode ("Each re-ask that surfaces one more item teaches the user that the finish line is
unreachable") and a skill reached for *constantly* meets it constantly.

## PARKED — one frozen, standup-owned schema

**File:** `PARKED/<YYYY-MM-DD>-standup-<HHMM>.md`. The `-standup-` infix is both the collision rule
and the deliberate divergence from `/finish-line`'s `<YYYY-MM-DD>-<reponame>-<HHMM>.md` and from the
existing free-form event files (`PARKED/2026-08-19-session-close.md`). Three formats coexisting
without a rule was a real defect in r1; this names ours and stops there.

**Record**, one per line:

```
- [<item-key>] tier <n> · <what> — evidence: <…> — close: <…> — first seen: <YYYY-MM-DD>
```

**Append rule:** append only item keys absent from **every** `PARKED/*.md`. **If nothing is new,
write nothing** — no file, no touch. That rule is what makes a second run over unchanged state a
byte-level no-op, which is what the idempotence assertion actually tests.

## Interface catalogue

Cited in every item the skill emits. `$R` = `python3 utils/py/releases_app.py`.

### RELEASES DB (GH-32)

| Need | Command |
|---|---|
| What ships next | `$R next` |
| One release | `$R show --version <v>` (`--full` prints values the default elides at 240 chars) |
| **Whole ledger** | `$R list [--status draft\|active\|shipped\|cut] [--all-repos]` — the reader the strategic half needs |
| Ledger health | `$R check` |
| Ship | `$R ship --gid <GID> --evidence "<run cite>"` — evidence **required**, `rule=ship-needs-evidence` |
| Amend | `$R update --gid <GID> …` — the accepted flags are finite: `--version --codename --status --target-date --shipped-date --description --exit-criterion --milestone --gh-release-url --front-door --shakedown --license` |
| Mirror the roadmap | `$R roadmap sync [--dry-run]` — one-way; a no-change sync is a **free no-op** |

Never hand-edit `releases.sql` or `releases.db`. Dump conflicts have a one-command resolver,
`utils/releases-merge-resolve.sh`. Full contract: `RELEASES-DB-FAQS.md`.

Advisories that map to ladder tier 5: `rule=release-overdue`, `rule=release-target-passed`,
`rule=temp-ref-stale`.

### ROADMAP schema — the grammar, then the convention

**What the parser actually requires** (`utils/py/_marathon_plan.py:485`, `ROADMAP.md:139-145`):

```
- **<bold name>** — anything else
```

A flat bullet whose name is bold, under one of four `###` headings spelled exactly:
`Queue / parked intake`, `In progress`, `Completed`, `Deferred · vision`
(`utils/py/_marathon_plan.py:31`). That is the whole grammar. Failure mode is a **silent skip** — an
unrecognised heading sets the section to `None` and its bullets vanish without warning.

**This repo's recommended shape**, which is a convention and *not* enforced by the parser:

```
- **GH-<n> · <title>** <marker> **<status>** — <body>. → [<doc>](PROJECT/…md) · [#<n>](<url>)
```

Never present the second as the requirement. r1 did, and both reviewers caught it.

After any ledger edit, two follow-ups are owed and both must be named: `$R roadmap sync`, then
`bash utils/roadmap-dashboard.sh` — the committed `ROADMAP-DASHBOARD.md` is gate-checked
(`test/roadmap-dashboard.sh:53` → `validate.sh` → `githooks/pre-push`), so a stale one turns the push
red.

### PDDA

Lifecycle `PROJECT/1-INBOX` → `2-WORKING` → `3-COMPLETED`. Coverage rule: every `2-WORKING` doc needs
a ROADMAP pointer or `roadmap_exempt: true`. Checks: `utils/pdda/pdda.sh roadmap`,
`roadmap-coverage`, `doc-ready`.

### The marathon rail

Exactly one long-horizon marathon in flight (`AGENTS.md` → Repo-specific rails). Never recommend a
second; treat the one named in ROADMAP's Immediate next-up as context, not a candidate.

## Degradation — loud, never silent

| Missing | Behavior |
|---|---|
| `gh` unavailable / unauthenticated | Skip lenses 4 and 5. State: *"PR and issue-state lenses skipped — `gh` unavailable."* Charged to Part 2's cap. Never imply a clean sweep. |
| No `PARKED/` | Do not create a top-level directory unannounced. Emit up to the cap, say where overflow would go, and ask — **once per session**, not once per run. |
| No `ROADMAP.md` or no ledger | Run the available lenses; Part 2 names the absent signal and what it costs the verdict. |
| A lens cannot produce all six required fields | Do not emit the candidate. State which lens degraded and why. |
| Empty session (invoked cold) | Legitimate. Local lenses only; say the list is repo-derived, not session-derived. |

A skill that degrades quietly reports a sweep it never performed — the same
guards-that-cannot-report-red class this repo has spent the month fixing.

## The test surface — deterministic, and named before the tests are promised

A `SKILL.md` is model instructions and cannot be asserted directly. `/10days` solved the same problem
by bundling deterministic scripts so the mechanical parts run byte-identically; do that here.

**Ship `skills/standup/collect.sh`** — the eight lens reads and nothing else. It emits a stable JSON
document (keys sorted, no timestamps in the payload) and takes `--fixture <dir>` to read canned
inputs instead of live ones. **All mechanical assertions run against `collect.sh --fixture`, never
against model output.**

That splits the testable surface cleanly:

| Property | Asserted how |
|---|---|
| Cross-lens dedup, tier assignment, tie-break ordering | `collect.sh --fixture` + a ranking helper; fixed input → fixed ordered list |
| No write outside `PARKED/` | snapshot the fixture tree, run the procedure, assert byte-identity for every path except `PARKED/` |
| Second-run byte no-op | run twice over unchanged fixture state; assert **no** new park file and an identical ranked list |
| Caps | count rendered lines in the emitted transcript against the integers in the output contract |
| Every degradation row | one fixture per row (no `gh` on PATH, no `PARKED/`, no ledger, a lens missing a field, empty session) |
| Item schema | every emitted line parses against the four-field form; evidence field non-empty |

Judgement — whether tier 4 was the *right* call for a given item — is not unit-testable and is
measured in Phase 4 instead.

## Definition of Done

Each bullet maps to an assertion above.

- Loads from `skills/standup/`, symlinked per the repo's `skills/*/install.sh` pattern.
- `collect.sh` exists, runs offline against `--fixture`, and emits stable sorted JSON.
- Tactical list never exceeds **7** items; Part 2 never exceeds **6** rendered lines; total never
  exceeds **17**. Counted mechanically against the emitted transcript.
- Every emitted item parses against the item schema with a non-empty evidence field.
- Ranking is total and deterministic: identical fixture state → byte-identical ordered list.
- No write outside `PARKED/`, pinned by the snapshot test.
- Second run over unchanged state writes no park file and emits the same list.
- Every degradation row has a fixture and a test.
- Suppression holds: a reported key with unchanged evidence does not reappear in the same session.

## Phases

1. **Catalogue + lenses + ladder.** Write the lens table, the ladder resolution, and the interface
   catalogue; verify **every** command and flag against the live CLI. r1 shipped a catalogue with a
   false ROADMAP grammar, a non-executable command form, and a missing `list` — a wrong catalogue is
   worse than none, because its whole premise is being trusted unchecked.
2. **`collect.sh` + fixtures.** The deterministic surface, before any prose about behavior.
3. **The skill body + tests.** Protocol, output contract, suppression, PARKED protocol; then every
   assertion in the test-surface table.
4. **Dogfood.** Run at the end of three real sessions and record whether the top item was what the
   operator did next. That is the only metric that matters, and a miss is a ladder bug, not user
   error.

## Open questions (build-time, not blockers)

- Should items distinguish *this session's* findings from pre-existing repo state? Cheap as a marker;
  risks a second axis competing with the ladder.
- Does a strategic claim need a stable ID persisted **across** sessions, not just within one? Within
  a session is specified above; across sessions needs a store and can wait for evidence that the same
  pivot actually recurs.
