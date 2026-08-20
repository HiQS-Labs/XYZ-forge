---
gh_issue: 77
source: https://github.com/HiQS-Suite/XYZ-forge/issues/77
title: "/standup — session-scoped triage: what did I leave open, what is rotting, is the plan still right?"
status: Proposed (1-INBOX — not yet active)
created: 2026-08-19
updated: 2026-08-19
doc_type: prd
effort: 3
complexity: 4
risk: 1
phases: 4
---

# GH-77: `/standup` — Session-Scoped Triage (PRD)

> **Revision 4 — 2026-08-19.** Two independent reviewers (Fable; Codex `gpt-5.6-sol` high), three
> rounds each. r1: 11 blockers. r2: 13. r3: 10. Threads:
> `relay-system/2026-08-19/gh77-standup-prd-review.md` and `…-codex.md`.
>
> **r4 was edited surgically, not rewritten** — r3's most embarrassing finding was a *regression*:
> the r2 ranking spec (staleness → effort bins → key) was deleted by rewriting the section around it,
> leaving `triage.py` told to "emit the ranked list" with no ordering rule in the document and
> `S-bin` referenced but undefined. Rewriting a reviewed document is how accepted material gets lost.
>
> The r3 round's two structural findings, both caught independently on both threads:
> **a tier-1 item ranked 8th was silent** — exempt from parking and from suppression, so it appeared
> in neither count, on every run, forever; and **suppression was unimplementable** — no lens defined
> its live-state payload and the park record stored no fingerprint. Both are closed below, the first
> by the `K` count and the `--all` escape hatch, the second by a per-lens payload table and two named
> state sources.
>
> Sections marked **FROZEN** carry operator decisions.
>
> ---
>
> **Review closed ESCALATED at the round cap; the build started instead.** Per-round finding counts
> were 11 → 13 → 10 → 10 — flat, where a converging review goes 11 → 5 → 2. The document was being
> pushed past what prose can hold, so `skills/standup/triage.py` now owns the mechanics and
> `test/gh77-standup-triage.sh` (29 assertions) pins them. **Where this document and the code
> disagree, the code and its tests win**; treat the sections below as design rationale.
>
> Two of the four escalation items are resolved **in code**, both without amending a frozen decision:
> the session store moved to `PARKED/.standup-session-<id>.json` (inside frozen decision 2, and safe
> in linked worktrees where `.git` is a file), and the uncapped `--all` became deterministic
> `--page N` paging (compatible with the frozen cap). Lens 6 now classifies corruption from **both**
> emission shapes, `FAIL: rule=` and `warn: rule=` — matching only `warn:` made the founding incident
> class produce no candidate at all.
>
> **Two still need the operator, and are not decided here:** (1) lens 4's `gh pr list` is *discovery*,
> which frozen decision 1 excludes — ratify a bounded open-PR inventory as the one exception, or
> restrict lens 4 to already-named PR numbers and accept weaker rot detection; (2) confirm the
> `PARKED/` session-store relocation is the wanted resolution rather than amending decision 2.

## Problem

Two failure modes make long agent sessions expensive:

**A. Wall of text.** The operator asks one question and gets four screens.

**B. Rabbit hole.** Four hours in, work sits open in five places and nobody can state what is
unfinished.

Together they produce a **confidence problem** that lands on `ROADMAP.md` and the RELEASES DB. Those
systems are worth what the operator believes about whether anything has quietly fallen out of them.
On 2026-08-19 that belief was measurably unearned:

| Drift found | How long true | Found by |
|---|---|---|
| Release 0.7.1 `active`, exit criterion met, merge landed, all 3 manifest items closed | ~1 day | a hand audit prompted by an offhand question |
| Four ledger entries marked active for issues GitHub had closed | 1–2 days | the same audit |
| Issues #61–#65 filed into neither the ledger nor `PARKED/` | ~1 day | the same audit |

Each discoverable in seconds; none discovered by anything. **The systems were correct and the
operator still could not trust them, because nothing ever looked.**

## Non-goals

- **Not an executor.** Recommends; the operator or `/10days` acts.
- **Not a retrospective.** Narration of the agent's own recent work is banned.
- **Not `/radar`.** No commit-history window, no clustering, no similarity sweep. `/radar` owns
  plan-versus-activity alignment over 21 days; this skill must never claim that verdict.
- **Not a writer** outside `PARKED/`.

## Where it sits among the existing skills

| Skill | Scope | Timing | Relation |
|---|---|---|---|
| `/finish-line` | one branch | closing | Borrows the Mandatory-Bar discipline; widens to the session. |
| `/rabbit-hole` | one task | reactive | Borrows consolidate-once; fires on the session, proactively. |
| `/radar` | repo, 21 days | strategic | Deferred to by name. |
| `/10days` | recent issues | executor | Downstream; may be recommended, never fired. |
| `/releases` | the release CLI | interface | Routed into, not duplicated. |

## Frozen decisions — FROZEN

1. **Input scope:** the session, the local repo, **and current-state GitHub metadata for entities the
   session or the ledgers already name.** No commit-history sweep, no list-wide issue enumeration, no
   similarity corpus. The explicit allowlist is the lens table; a read not in it is out of scope.
2. **Write authority:** `PARKED/` only.
3. **Output:** both halves, every run.
4. **Tactical cap:** 7 items.

Decision 1 is stated this way because r2 caught "session + local state" reading literally as
*offline*, while lenses 4–5 make network calls. Current-state metadata for already-named entities is
in scope; discovery is not.

## The lenses

Each lens supplies six fields. **A lens that cannot supply all six for a candidate does not emit it**
— it degrades loudly. `$R` = `python3 utils/py/releases_app.py`, expanded in all emitted output.

| # | Lens | Bounded read | Candidate predicate | Evidence (typed) | Staleness source | Closing interface |
|---|---|---|---|---|---|---|
| 1 | Conversation | this session's transcript | an action the agent said it would take, or a finding it raised, that was neither completed nor parked | `quote:<span>` | age 0 | the command named in the item |
| 2 | Working tree | `git status --porcelain` | any modified or untracked non-ignored path, **except an untracked path under `PARKED/`** | `path:<path>` | file mtime | `git add <path>` + commit, **or** `inspect: <path>` |
| 3 | Branch | `git rev-list --left-right --count @{upstream}...HEAD`; on exit 128 (`no upstream configured`) fall back to the trunk | ahead > 0 or behind > 0 | `counts:<ahead>/<behind>@<upstream-state>` where `upstream-state` ∈ `tracked` \| `no-upstream` | with upstream: committer date of the oldest unpushed commit, or for behind-only the newest upstream commit; **no-upstream: unknown** | `tracked`: `git push` / `git pull --rebase` · `no-upstream`: `inspect: branch <name> (push state unknown, no upstream)` |
| 4 | Open PRs | `gh pr list --limit 51 --json number,title,updatedAt,isDraft,mergeStateStatus` | any open PR | `pr:<n>+<mergeStateStatus>` | `updatedAt` | `gh pr merge <n>` / `gh pr review <n>` |
| 5 | Issue state | `gh issue view <n> --json number,state,title,updatedAt` over the **bounded set** below | a closed issue still carrying an active marker in the ledger; an open issue cited in no index; a manifest item whose stored state disagrees with the issue | `issue:<n>+<state>@<where>` | `updatedAt` | ledger edit → `$R roadmap sync`, or park |
| 6 | RELEASES ledger | `$R check`, `$R next`, then **`$R list --status draft` + `--status active` to enumerate**, then `$R show --version <v>` per enumerated release | any `warn: rule=…`; an `active` release past target | `rule:<name>@<gid>` | release `target_date` | `$R ship …` / `$R update …` |
| 7 | ROADMAP ledger | `$R roadmap sync --dry-run` | non-zero add/update/remove counts | `counts:+a~u-r` | `ROADMAP.md` mtime vs last sync | `$R roadmap sync` **then** `bash utils/roadmap-dashboard.sh` |
| 8 | PARKED | read `PARKED/*.md` | a parked record whose mandatory **`check` field** — a read-only probe, never the `close` command — reports the work is done | `park:<item-key>` | the record's `first seen` | the record's own `close` field |

**Five corrections rounds 2–3 forced, recorded so they are not undone:**

- **Lens 2 excludes only *untracked* paths under `PARKED/`.** The self-feed was the skill's own new
  file; a *modified tracked* park file cannot loop (it closes with `git add` + commit), and excluding
  the whole directory made an operator's uncommitted edit to a parked file permanently invisible.
  r3 caught the over-broad first fix.
- **Lens 3 measures against `@{upstream}` and never claims *unpushed* without one.** Divergence from
  the trunk does not establish push state. On `fatal: no upstream configured` (exit 128) the lens
  falls back to the trunk (resolved per `skills/releases/SKILL.md:81` — `development` here, never
  assume `main`), carries `upstream-state: no-upstream` in its typed evidence, takes **unknown**
  staleness, and its close becomes an `inspect:` action — never a bare `git push` at a remote nobody
  has resolved.
- **Lens 6 enumerates with `list` and inspects with `show`.** Both are required: `list` is the only
  reader that exposes every GID/status/version (`utils/py/releases_app.py:1715-1731`), while manifest
  item states come from `show` (`:1770-1793`). r3 caught "for each non-shipped release" as an
  enumeration the lens never performed.
- **Lens 6's advisories are tier 5, and the classifier says so.** `release-overdue`,
  `release-target-passed` and `temp-ref-stale` were labelled tier 5 in the catalogue while the
  classifier gave lens 6 no non-corruption row, silently sending them to the tier-6 fallback.
- **Lens 8 never executes the `close` command.** Deciding "the close is now a no-op" by *running* it
  contradicts both "Not an executor" and `PARKED/`-only write authority. Park records therefore carry
  a separate mandatory `check` field — a read-only probe drawn from an allowlist (`test -e <path>`,
  `git log --oneline -1 <ref>`, `$R check`, `gh issue view <n> --json state`, `$R roadmap sync
  --dry-run`) — and only that is run during collection.

### Lens 5's bounded set — FROZEN bound

Issue numbers from **exactly** three sources, unioned and de-duplicated:

1. numbers mentioned in this session;
2. numbers cited by `ROADMAP.md` ledger entries under **`Queue / parked intake` or `In progress`
   only** — not `Completed`, which grows without limit;
3. manifest items of **non-shipped** releases.

Measured today: 30 unique issue references in the whole of `ROADMAP.md`, and the active-marker subset
is a fraction of that. The bound must stay tied to *active* state, not to ledger size, or the skill
loses the property that makes it usable — it finishes in seconds.

### Item keys — canonical by entity, independent of lens order

r2 caught two key defects: an eight-word conversation slug collides, and "first lens in table order
wins" made a key change when an unrelated lens appeared. Keys are now derived from the **entity**, so
they never depend on which lens found it:

| Entity | Key |
|---|---|
| issue | `issue:<n>` |
| pull request | `pr:<n>` |
| file path | `path:<repo-relative path>` |
| release | `rel:<gid>` |
| ledger rule finding | `rule:<name>:<gid-or-subject>` |
| branch | `branch:<name>` |
| conversation-only | `conv:<sha256 of the normalized quoted evidence span, first 12 hex>` — normalize: lowercase, collapse whitespace, strip punctuation |

### Cross-lens deduplication — before ranking

Collapse on **identical key**. That is the whole rule now that keys are entity-canonical. The
survivor carries every contributing evidence field and takes the **highest** tier any contributing
lens justified.

## Tier classification — deterministic, then a cited override

r2's second blocker: r1 and r2 both listed tiers without saying how a candidate reaches one. Tier is
assigned by the **first matching row**:

| Tier | Assigned when | Never inferred from |
|---|---|---|
| 1 · corruption | lens 6 emits a rule in the corruption set — `dump-divergence`, **`dump-missing`**, `generation-mismatch`, `receipt-chain`, or a bypass detection; **or** lens 2 reports a modified path in the persisted-artifact set (`releases.db`, `releases.sql`) | prose describing risk |
| 2 · crash/hang | a session-quoted traceback, non-zero exit from a named suite, or a hang the session observed | speculation about reachability |
| 3 · customer/revenue | the operator labelled it so, in this session | the agent's own judgement — **never** |
| 4 · nearly done | lens 4 PR with `mergeStateStatus: CLEAN`; **or** lens 3 ahead > 0, `upstream-state: tracked`, clean tree; **or** a lens 1 item whose close is an **S**-bin command | "feels close" |
| 5 · rot risk | lens 4 PR `updatedAt` older than **7 days**; lens 3 behind > 0; lens 7 non-zero diff; lens 5 marker/index mismatch; lens 8 cleared park; **lens 6 emitting `release-overdue`, `release-target-passed`, or `temp-ref-stale`** | |
| 6 · housekeeping | **deterministic fallback** — any candidate with all six fields that matched no row above | |

The corruption set matches the checker's own grouping —
`resolved = {"dump-divergence", "dump-missing", "generation-mismatch", "receipt-chain"}`
(`utils/py/releases_app.py:2366`). r3 caught `dump-missing` missing here, which would have classified
an absent dump as housekeeping.

**Override:** an explicit operator statement in this session may raise a tier. The statement becomes
the item's evidence field (`quote:<span>`), so a fixture can represent it and a test can assert it.
No other promotion path exists.

## Ranking — the total order

**Restored in r4.** r2 specified this; the r3 rewrite of the surrounding section dropped it, leaving
`triage.py` "emits the ranked list", suppression "after ranking", and a DoD demanding a total order —
with no ordering rule anywhere in the document, and `S-bin` referenced but undefined. Both reviewers
caught it independently. It is stated here as one tuple so a rewrite cannot lose half of it.

Sort by this tuple, ascending on each component in turn:

1. **Tier**, 1 → 6.
2. **Staleness**, oldest first, measured from the lens's staleness source. **An item whose staleness
   source is unavailable (`unknown`) sorts after every item with a known age within its tier** — an
   unmeasured item must never jump the queue.
3. **Effort bin**, smaller first — finite and deterministic:
   - **S** — the closing interface is a single command with **no argument the agent must invent**
     (every argument is present in the item's own evidence). This is the definition `S-bin` refers to.
   - **M** — the closing interface names exactly one file to edit.
   - **L** — anything else, including every `inspect:` action.
4. **Item key**, lexicographic ascending. Total by construction, so identical state yields a
   byte-identical ordered list.

Fixtures required: a tie at each component, an `unknown`-staleness item against a known-age peer of
the same tier, and one item per effort bin.

## Evidence grammar — typed, and it covers every lens

One grammar, `<type>:<payload>`, with the serialized forms the lens table already uses:

| Type | Payload | Emitted by |
|---|---|---|
| `line` | `<path>:<lineno>` | any lens citing source |
| `path` | repo-relative path | 2 |
| `quote` | a span from the session or a doc | 1, tier-3 overrides |
| `counts` | `<ahead>/<behind>@<upstream-state>` (lens 3) or `+a~u-r` (lens 7) | 3, 7 |
| `pr` | `<n>+<mergeStateStatus>` | 4 |
| `issue` | `<n>+<state>@<where-cited>` | 5 |
| `rule` | `<name>@<gid>` | 6 |
| `park` | `<item-key>` | 8 |

**Every** tier requires a non-empty evidence field. r1 required it only for tiers 1–3 while the DoD
required it everywhere; this is the single statement.

### The canonical live-state payload — what suppression actually hashes

Suppression compares a fingerprint over live state, so each lens must name the payload it contributes.
r3 caught that the fingerprint was specified with no lens defining its input:

| Lens | Live-state payload |
|---|---|
| 1 | the normalized quoted span (identical to the key's input) |
| 2 | `<porcelain status code>` for the path (`M`, `??`, …) |
| 3 | `<ahead>/<behind>/<upstream-state>` |
| 4 | `<mergeStateStatus>/<isDraft>/<updatedAt>` |
| 5 | `<state>/<where-cited>` |
| 6 | the full `rule=` line as emitted by `check` |
| 7 | `+a~u-r` counts |
| 8 | the `check` field's exit status |

`fingerprint = sha256(item-key + "\0" + tier + "\0" + live-state-payload)`, first 16 hex.

## Item schema

Every tactical item is exactly one rendered line:

```
<tier> · <what> — <evidence> — <close>
```

`tier` 1–6 · `what` imperative, ≤ 12 words · `evidence` one typed form above, required ·
`close` an executable command, **or** `inspect: <path>` / `PR #<n>: <action>` when no single command
is safe.

**The line is rendered from a structured object, never parsed back out of prose.** `triage.py` holds
each item as `{tier, what, evidence_type, evidence_payload, close}` and renders it; tests assert
against the object, not a regex over the line. Any ` — ` inside `what`, `evidence_payload`, or
`close` is escaped as `—​—` on render, so the three top-level separators are unambiguous.
Fixtures must include a quoted span and a path that themselves contain ` — `. r3 caught that the
four-field parse was unachievable without this: session quotes and commands routinely contain the
delimiter.

**Closing interfaces are never destructive.** r2 caught `git restore` in lens 2: it cannot remove an
untracked path at all, and on a tracked path it discards work that may not be this session's. The
close for a dirty path is `git add` + commit or `inspect: <path>` — never restore, never discard,
never clean. This follows `AGENTS.md` on destructive actions.

## Output contract — FROZEN, and the arithmetic closes

**A rendered line** = one newline-delimited line as emitted. Soft-wrap does not count. Headings count.
Blank lines do not.

Every permitted line, enumerated:

| # | Line | Count |
|---|---|---|
| 1 | Opening line — branch + one-clause verdict | exactly 1 |
| 2 | Part 1 heading | exactly 1 |
| 3 | Item lines, or the single line `Nothing open.` when there are none | **1–7** |
| 4 | Notices line — parked count, suppressed count, **critical-beyond-cap count**, and the missing-`PARKED/` question all share this one line | 0–1 |
| 5 | Part 2 heading | exactly 1 |
| 6 | Part 2 body, **including every degradation statement** | 1–4 |
| | **Total** | **1+1+7+1+1+4 = 15, hard** |

15 is the sum of the segment caps, not a separate number. r2 caught r2's own `= 17` as arithmetic
that no reading produced — a cap that cannot be derived is a cap a builder cannot enforce. r3 caught
row 3's lower bound as unreachable (zero items still costs one line for `Nothing open.`).

Items 8+ never appear in the list. Tiers 4–6 park; **tiers 1–3 do not park and are not suppressed**,
so a truncated critical item is carried by an explicit count and an escape hatch:

> **Notices line format:** *"N parked, M suppressed, K critical beyond cap — `triage.py --dry-run
> --all` lists every item."*
>
> `K` is the number of tier-1–3 items the cap truncated. When `K > 0` the escape-hatch clause is
> mandatory. `--all` renders the complete ranked list with no cap, read-only, writing nothing.

r3 found this independently on both threads and it is the third instance of one pattern: the fix for
"suppression can hide a tier-1 item" re-opened the same hole through truncation — a tier-1 item
ranked 8th was exempt from parking *and* from suppression, so it appeared in neither count, and the
frozen second-run transcript made it invisible on every subsequent run. **A tier-1–3 item is never
silent: it is rendered, or it is counted in `K`.**

Part 2 answers, in plain English: **do `ROADMAP.md` and the RELEASES ledger still describe what this
repo is doing?** Its verdict is **bounded by construction** — the permitted positive form is *"no
contradiction found in the available snapshot"*, never *"the plan is sound"*. Plan-versus-activity
alignment needs a 21-day trunk window and belongs to `/radar`, which Part 2 names when that is what
would settle the question.

## Suppression — and the tier exemption that makes it safe

Suppression stops the skill re-litigating itself. r2 established that as written it could bury a live
tier-1 item, so:

> **Tiers 1–3 are exempt from suppression and from parking.** They render on every run until closed.
> If more than seven exist, the cap truncates the *list* and the surplus is counted as `K` on the
> notices line with the `--all` escape hatch — it is never silent.

For tiers 4–6, suppression compares a **semantic fingerprint** over the per-lens live-state payload
defined in the evidence grammar, not the display string:

```
fingerprint = sha256(item-key + "\0" + tier + "\0" + live-state-payload)[:16]
```

Including `tier` means an escalation (5 → 4) is a fingerprint change and re-raises. Including live
state means a defect that *changed* re-raises even under the same key.

**Where the two state sources live** — r3 caught the rule as unimplementable because neither existed:

- **Within-session** reported fingerprints: `triage.py --apply` writes them to
  `.git/standup-session-<XYZ_SESSION_ID>.json` — inside `.git`, so it is neither a working-tree
  candidate for lens 2 nor a repo write; it is passed to `--dry-run` runs via `--session-state`.
- **Across sessions**: every `PARKED/` record carries its `fingerprint:` field (see the record
  schema), so a parked key can be compared without re-deriving it.

Rules, applied **after ranking and before capping**:

- Do not re-raise, in this session, a tier-4–6 key whose fingerprint is unchanged.
- Do not re-raise a tier-4–6 key present in `PARKED/` whose fingerprint is unchanged.
- **Do re-raise a parked key whose fingerprint changed** — and, because the append rule rejects keys
  already present, append a *revision line* for it rather than a new record:
  `- [<item-key>] REVISED <fingerprint> — <what changed>`. r3 caught that without this a parked item
  whose state moved could never resurface.
- Do not restate a strategic claim already made this session.

Suppressed counts appear only in the notices line.

**Second-run contract, frozen exactly:** over unchanged state, run 2 emits the *same opening line,
the same ranked items for tiers 1–3, the same `K`, the same Part 2*, a notices line whose suppressed
count equals the tier-4–6 items shown in run 1, and **writes no park file**. That is one transcript,
testable, and it replaces r2's contradictory pair of "same list" plus "do not re-raise".

## PARKED — one frozen schema

**File:** `PARKED/<YYYY-MM-DD>-standup-<HHMM>.md`. Two runs in the same minute **append to the
existing file** rather than colliding; each append is preceded by a `## run <HHMMSS>` heading. The
`-standup-` infix separates this from `/finish-line`'s `<reponame>-<HHMM>` and from the free-form
event files.

**Record:**

```
- [<item-key>] tier <n> · <what> — evidence: <typed> — check: <read-only probe> — close: <…> — fingerprint: <16 hex> — first seen: <YYYY-MM-DD>
```

Two fields exist because r3 showed the record could not support the rules built on it: `fingerprint`
is what across-session suppression compares (without it the rule was unimplementable), and `check` is
the **read-only probe lens 8 runs** — never `close`, whose execution would violate "Not an executor".
`check` must come from the allowlist named in lens 8's correction note.

**Append rule:** append only keys absent from **every** `PARKED/*.md`; a present key whose fingerprint
changed gets a `REVISED` line instead. **If nothing is new and nothing revised, write nothing — no
file, no touch.** Combined with the lens-2 exclusion, that is what makes an unchanged second run a
byte-level no-op.

## Interface catalogue

`$R` = `python3 utils/py/releases_app.py`.

| Need | Command |
|---|---|
| Next release | `$R next` |
| One release, with manifest item states | `$R show --version <v>` (`--full` prints values elided at 240 chars) |
| Whole ledger | `$R list [--status draft\|active\|shipped\|cut] [--all-repos]` — prints an item **count**, not item states |
| Health | `$R check` |
| Ship | `$R ship --gid <GID> --evidence "<run cite>"` — required; `rule=ship-needs-evidence` |
| Amend | `$R update --gid <GID> …` — finite flags: `--version --codename --status --target-date --shipped-date --description --exit-criterion --milestone --gh-release-url --front-door --shakedown --license` |
| Mirror roadmap | `$R roadmap sync [--dry-run]` — one-way; a no-change sync is a free no-op |

Never hand-edit `releases.sql` or `releases.db`. Dump conflicts: `utils/releases-merge-resolve.sh`.
Contract: `RELEASES-DB-FAQS.md`. Tier-5 advisories: `rule=release-overdue`,
`rule=release-target-passed`, `rule=temp-ref-stale`.

### ROADMAP grammar, then convention

**The grammar the parser enforces** (`utils/py/_marathon_plan.py:521` — `re.match(r"^- \*\*", line)`):

```
- **<bold name>**[optional remainder]
```

The prefix alone. **No dash and no trailing content are required** — r2 caught r1's `— anything else`
as still overstating it. Recognised only under four `###` headings spelled exactly:
`Queue / parked intake`, `In progress`, `Completed`, `Deferred · vision`
(`utils/py/_marathon_plan.py:31`). Unknown heading → `current=None` → bullets **silently skipped**.

**This repo's convention**, not enforced by anything:

```
- **GH-<n> · <title>** <marker> **<status>** — <body>. → [<doc>](PROJECT/…md) · [#<n>](<url>)
```

Never present the convention as the grammar.

After any ledger edit: `$R roadmap sync`, then `bash utils/roadmap-dashboard.sh` — the committed
dashboard is gate-checked (`test/roadmap-dashboard.sh:53` → `validate.sh` → `githooks/pre-push`).

### PDDA · the marathon rail

Lifecycle `1-INBOX` → `2-WORKING` → `3-COMPLETED`; every `2-WORKING` doc needs a ROADMAP pointer or
`roadmap_exempt: true`. Checks: `utils/pdda/pdda.sh roadmap`, `roadmap-coverage`, `doc-ready`.
Exactly one long-horizon marathon in flight (`AGENTS.md` → Repo-specific rails) — never recommend a
second.

## Degradation — loud, never silent

Every row is charged to a named segment, and — because eight lenses can degrade at once against Part
2's four body lines — degradation is **aggregated, not enumerated**. r3 caught "loud, never silent"
colliding with the hard cap in a reachable state (no `gh`, no ROADMAP, no ledger, empty session).

| ID | Condition | Statement | Charged to |
|---|---|---|---|
| `D1` | `gh` unavailable | PR and issue-state lenses skipped | Part 2 body |
| `D2` | `gh pr list` returns 51 rows | PR list truncated at 50 | Part 2 body |
| `D3` | No `PARKED/` | Never create a top-level directory unannounced; ask **once per session** | notices line |
| `D4` | No `ROADMAP.md` / no ledger | the absent signal and what it costs the verdict | Part 2 body |
| `D5` | A lens cannot supply all six fields | the candidate is not emitted; name the lens | Part 2 body |
| `D6` | Empty session | the list is repo-derived, not session-derived | Part 2 body |

**Aggregation rule — lossless within the cap.** Part 2's body is 1–4 lines: line 1 is always the
verdict, leaving **3** for degradation. With ≤ 3 active IDs, each gets its own sentence. With more,
they collapse to one line naming **every** ID and its one-word subject —
*"Degraded: D1 gh, D4 ledger, D5 lens-6, D6 session."* No ID is ever dropped, so the statement stays
lossless while the cap holds. `D3` never competes: it is charged to the notices line.

A fixture must exercise **all six simultaneously**, not one per row.

## The test surface — two named executables, then the prose

r2's blocker: `collect.sh` performs reads only, so it could not own ranking, parking, suppression, or
rendering — yet those were the assertions. Two components, both deterministic:

**`skills/standup/collect.sh`**

```
collect.sh [--fixture <dir>] [--session <transcript.json>] > lenses.json
```

The eight lens reads, nothing else. Emits stable sorted JSON, no timestamps in the payload:
`{"lenses": {"1": {"status": "ok"|"degraded", "degraded_id": "D<n>"|null,
"candidates": [{"key", "evidence_type", "evidence_payload", "staleness", "live_state", "close"}]}}}`.
`--session` is how lens 1 receives the conversation — r3 caught that `collect.sh` had no way to see
it. `--fixture` substitutes canned inputs for every live read.

**`skills/standup/triage.py`** — the state machine **and the renderer of the whole transcript**.

```
triage.py --lenses lenses.json [--session-state <path>] [--parked-dir PARKED]
          (--dry-run | --apply) [--all] [--verdict-code <code>] [--verdict-prose <text>]
```

Consumes `collect.sh` JSON plus the two suppression state sources, and emits **all six rows of the
line table** — opening line, both headings, items, notices, and Part 2 — not just the mechanical
middle. r3's blocker was that the tests counted 15 lines against a component that emitted three of
them.

Part 2 is not free prose: its verdict comes from a **finite vocabulary** —
`no-contradiction` · `ledger-behind` · `release-overdue` · `insufficient-evidence` — each with a fixed
sentence. `--verdict-prose` supplies at most one operator-facing clause appended to it, and
`SKILL.md` chooses only that clause and the `what` phrasing. Everything else is deterministic, so the
frozen second-run transcript is byte-comparable.

Modes: `--dry-run` emits and writes nothing; `--apply` also writes the park delta and the session
state. `--all` renders the complete ranked list with no cap (the `K` escape hatch), read-only in both
modes. Exit `0` clean · `2` usage · `3` one or more lenses degraded.

| DoD bullet | Asserted by |
|---|---|
| dedup + tier assignment | `triage.py --dry-run` over fixtures; fixed input → fixed ordered list |
| **ranking is total** | one fixture per tie component: equal tier, equal staleness, equal effort bin; plus an `unknown`-staleness item against a known-age peer; plus one item per S/M/L bin |
| every tier-classification row | one fixture per row, including the tier-6 fallback and a cited override |
| no write outside `PARKED/` | snapshot the fixture tree, `triage.py --apply`, assert byte-identity everywhere except `PARKED/` and `.git/standup-session-*.json` |
| second-run byte no-op | `--apply` twice over unchanged state; assert no new park file **and** the frozen second-run transcript byte-for-byte |
| tiers 1–3 never silent | fixture with **8 tier-1 items**: assert 7 rendered, `K=1` on the notices line with the `--all` clause, none parked, none suppressed, and `--all` renders all 8 |
| parked key whose fingerprint changed | fixture: park an item, mutate its live state, rerun; assert a `REVISED` line and that it re-raises |
| lens-8 never executes `close` | fixture whose `close` is a sentinel that would leave a marker; assert the marker is absent and only `check` ran |
| **lens-2 self-feed is broken** | untracked park file present → not emitted; **and** a *modified tracked* park file → **is** emitted (the r3 over-broad-exclusion control) |
| caps | count rendered lines of `triage.py --dry-run` against the enumerated table; fixtures for max, empty, and **all six degradations at once** |
| item schema | every emitted line renders from the structured object and round-trips; fixtures include a quote and a path containing ` — ` |
| degradation aggregation | ≤ 3 active IDs → one sentence each; > 3 → the single collapsed line naming every ID |
| install | `skills/standup/install.sh --check` exits 0 after install |

Judgement — was tier 4 the *right* call for this item — is not unit-testable and is measured in
Phase 4. Everything above is.

## Definition of Done

- Loads from `skills/standup/`; `install.sh --check` exits 0.
- `collect.sh` and `triage.py` exist, run offline against fixtures, and honour the CLI contracts above.
- Every row of the test-surface table has a passing assertion.
- Rendered output never exceeds the enumerated line table; total ≤ 15.
- Every item renders from the structured object with non-empty typed evidence.
- Ranking is total: identical fixture state → byte-identical ordered list.
- No write outside `PARKED/` and `.git/standup-session-*.json`.
- Second run over unchanged state writes no park file and emits the frozen second-run transcript.
- **No tier-1–3 item is ever silent** — rendered, or counted in `K` with the `--all` escape hatch.
- A park file is never itself emitted as an item, and a modified tracked one still is.
- `close` is never executed during collection.

## Phases

1. **Lenses, tiers, evidence grammar, catalogue.** Verify every command and flag against the live
   CLI. Three revisions running, the catalogue has carried an error into review each time; the
   ROADMAP grammar alone was wrong twice.
2. **`collect.sh` + `triage.py` + fixtures.** The deterministic surface, before prose about behavior.
3. **The skill body + the full test table.**
4. **Dogfood.** Three real sessions; record whether the top item was what the operator did next. A
   miss is a tier-classification bug, not user error.

## Open questions (build-time)

- Should a strategic claim carry an ID persisted *across* sessions? Within-session is specified;
  across needs a store and can wait for evidence the same pivot recurs.
- Does `triage.py` warrant being Python rather than Bash? Assumed yes (JSON, sha256, sorting); the
  repo's Python-authoritative convention agrees.
