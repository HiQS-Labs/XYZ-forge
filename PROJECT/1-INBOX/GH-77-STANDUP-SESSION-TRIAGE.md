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

> **Revision 3 — 2026-08-19.** Two independent reviewers (Fable; Codex `gpt-5.6-sol` high) have each
> reviewed twice. r1: 11 blockers. r2: 13 more, almost all against material the rewrite introduced.
> Threads: `relay-system/2026-08-19/gh77-standup-prd-review.md` and `…-codex.md`.
>
> The r2 round found three things worth naming up front, because they shaped this revision:
> the output contract's own arithmetic did not add up (1+7+1+6 was declared as 17); the suppression
> rule introduced in r2 could **hide a live tier-1 finding**; and lens 2 turned the skill's own park
> write into an **unbounded self-feeding loop** — a new park file is untracked, `PARKED/` is not
> gitignored (`git check-ignore PARKED/` → rc 1, and `git ls-files PARKED/` lists two tracked files),
> so the next run itemises it, and in the overflow regime that caused the park it parks again.
>
> Sections marked **FROZEN** carry operator decisions.

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
| 2 | Working tree | `git status --porcelain -- . ':(exclude)PARKED'` | any modified or untracked non-ignored path | `path:<path>` | file mtime | `git add <path>` + commit, **or** `inspect: <path>` |
| 3 | Branch | `git rev-list --left-right --count @{upstream}...HEAD` (falls back to the trunk with `no-upstream` noted) | ahead > 0 (**unpushed relative to upstream**) or behind > 0 | `counts:<ahead>/<behind>` | committer date of the oldest unpushed commit; for behind-only, the newest upstream commit date | `git push` / `git pull --rebase` |
| 4 | Open PRs | `gh pr list --limit 51 --json number,title,updatedAt,isDraft,mergeStateStatus` | any open PR | `pr:<n>+<mergeStateStatus>` | `updatedAt` | `gh pr merge <n>` / `gh pr review <n>` |
| 5 | Issue state | `gh issue view <n> --json number,state,title,updatedAt` over the **bounded set** below | a closed issue still carrying an active marker in the ledger; an open issue cited in no index; a manifest item whose stored state disagrees with the issue | `issue:<n>+<state>@<where>` | `updatedAt` | ledger edit → `$R roadmap sync`, or park |
| 6 | RELEASES ledger | `$R check`, `$R next`, `$R show --version <v>` for each non-shipped release | any `warn: rule=…`; an `active` release past target | `rule:<name>@<gid>` | release `target_date` | `$R ship …` / `$R update …` |
| 7 | ROADMAP ledger | `$R roadmap sync --dry-run` | non-zero add/update/remove counts | `counts:+a~u-r` | `ROADMAP.md` mtime vs last sync | `$R roadmap sync` **then** `bash utils/roadmap-dashboard.sh` |
| 8 | PARKED | read `PARKED/*.md` | a parked record whose **`close` field is now a no-op** — the named command reports nothing to do, or the named path no longer exists | `park:<item-key>` | the record's `first seen` | the record's own `close` field |

**Three corrections r2 forced, recorded so they are not undone:**

- **Lens 2 excludes `PARKED/`.** Without the exclusion the skill's own park write becomes a candidate
  next run and, under overflow, parks — one new file per run forever.
- **Lens 3 measures against `@{upstream}`, not the trunk.** Divergence from trunk does not establish
  *unpushed*. When no upstream is configured, fall back to the trunk (resolved per
  `skills/releases/SKILL.md:81` — `development` here, never assume `main`) and carry `no-upstream` in
  the evidence.
- **Lens 6 reads `show`, not `list`.** `list` prints only an item count
  (`utils/py/releases_app.py:1728`); manifest item states come from `show`. The stored-state-vs-issue
  comparison is **lens 5's**, using lens 6's `show` output as its input set.

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
| 1 · corruption | lens 6 emits a rule in the corruption set — `dump-divergence`, `generation-mismatch`, `receipt-chain`, or a bypass detection; **or** lens 2 reports a modified path in the persisted-artifact set (`releases.db`, `releases.sql`) | prose describing risk |
| 2 · crash/hang | a session-quoted traceback, non-zero exit from a named suite, or a hang the session observed | speculation about reachability |
| 3 · customer/revenue | the operator labelled it so, in this session | the agent's own judgement — **never** |
| 4 · nearly done | lens 4 PR with `mergeStateStatus: CLEAN`; **or** lens 3 ahead > 0 with a clean tree; **or** a lens 1 item whose close is an S-bin command | "feels close" |
| 5 · rot risk | lens 4 PR `updatedAt` older than **7 days**; lens 3 behind > 0; lens 7 non-zero diff; lens 5 marker/index mismatch; lens 8 cleared park | |
| 6 · housekeeping | **deterministic fallback** — any candidate with all six fields that matched no row above | |

**Override:** an explicit operator statement in this session may raise a tier. The statement becomes
the item's evidence field (`quote:<span>`), so a fixture can represent it and a test can assert it.
No other promotion path exists.

## Evidence grammar — typed, and it covers every lens

One grammar, `<type>:<payload>`, with the serialized forms the lens table already uses:

| Type | Payload | Emitted by |
|---|---|---|
| `line` | `<path>:<lineno>` | any lens citing source |
| `path` | repo-relative path | 2 |
| `quote` | a span from the session or a doc | 1, tier-3 overrides |
| `counts` | `<ahead>/<behind>` or `+a~u-r` | 3, 7 |
| `pr` | `<n>+<mergeStateStatus>` | 4 |
| `issue` | `<n>+<state>@<where-cited>` | 5 |
| `rule` | `<name>@<gid>` | 6 |
| `park` | `<item-key>` | 8 |

**Every** tier requires a non-empty evidence field. r1 required it only for tiers 1–3 while the DoD
required it everywhere; this is the single statement.

## Item schema

Every tactical item is exactly one rendered line:

```
<tier> · <what> — <evidence> — <close>
```

`tier` 1–6 · `what` imperative, ≤ 12 words · `evidence` one typed form above, required ·
`close` an executable command, **or** `inspect: <path>` / `PR #<n>: <action>` when no single command
is safe.

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
| 3 | Item lines, or the text `Nothing open.` when there are none | 0–7 |
| 4 | Notices line — parked/suppressed counts **and** the missing-`PARKED/` question share this one line | 0–1 |
| 5 | Part 2 heading | exactly 1 |
| 6 | Part 2 body, **including any degradation statement** | 1–4 |
| | **Total** | **1+1+7+1+1+4 = 15, hard** |

15 is the sum of the segment caps, not a separate number. r2 caught r2's own `= 17` as arithmetic
that no reading produced — a cap that cannot be derived is a cap a builder cannot enforce.

Items 8+ never appear; they park (subject to the tier exemption below) and are represented only by
the notices line: *"N parked, M suppressed."*

Part 2 answers, in plain English: **do `ROADMAP.md` and the RELEASES ledger still describe what this
repo is doing?** Its verdict is **bounded by construction** — the permitted positive form is *"no
contradiction found in the available snapshot"*, never *"the plan is sound"*. Plan-versus-activity
alignment needs a 21-day trunk window and belongs to `/radar`, which Part 2 names when that is what
would settle the question.

## Suppression — and the tier exemption that makes it safe

Suppression stops the skill re-litigating itself. r2 established that as written it could bury a live
tier-1 item, so:

> **Tiers 1–3 are exempt from suppression and from parking.** They render on every run until closed,
> however many runs that takes. If eight tier-1 items exist, the cap truncates the *list* — it never
> silences a corruption finding.

For tiers 4–6, suppression compares a **semantic fingerprint**, not the display string:

```
fingerprint = sha256(item-key + tier + live-state-payload)
```

Including `tier` means an escalation (5 → 4) is a fingerprint change and re-raises. Including live
state means a defect that *changed* re-raises even under the same key.

Rules, applied **after ranking and before capping**:

- Do not re-raise, in this session, a tier-4–6 key whose fingerprint is unchanged.
- Do not re-raise a tier-4–6 key present in `PARKED/` whose fingerprint is unchanged.
- Do not restate a strategic claim already made this session.

Suppressed counts appear only in the notices line.

**Second-run contract, frozen exactly:** over unchanged state, run 2 emits the *same opening line,
the same ranked items for tiers 1–3, the same Part 2*, a notices line whose suppressed count equals
the tier-4–6 items shown in run 1, and **writes no park file**. That is one transcript, testable, and
it replaces r2's contradictory pair of "same list" plus "do not re-raise".

## PARKED — one frozen schema

**File:** `PARKED/<YYYY-MM-DD>-standup-<HHMM>.md`. Two runs in the same minute **append to the
existing file** rather than colliding; each append is preceded by a `## run <HHMMSS>` heading. The
`-standup-` infix separates this from `/finish-line`'s `<reponame>-<HHMM>` and from the free-form
event files.

**Record:**

```
- [<item-key>] tier <n> · <what> — evidence: <typed> — close: <…> — first seen: <YYYY-MM-DD>
```

**Append rule:** append only keys absent from **every** `PARKED/*.md`. **If nothing is new, write
nothing — no file, no touch.** Combined with the lens-2 exclusion above, that is what makes an
unchanged second run a byte-level no-op.

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

| Missing | Behavior |
|---|---|
| `gh` unavailable | Skip lenses 4–5. State *"PR and issue-state lenses skipped — `gh` unavailable."* Charged to Part 2's body. |
| `gh pr list` returns 51 rows | The bound was hit. Emit the 50 and state *"PR list truncated at 50."* |
| No `PARKED/` | Never create a top-level directory unannounced. Emit to the cap; ask **once per session**, on the notices line. |
| No `ROADMAP.md` / no ledger | Run what remains; Part 2 names the absent signal and what it costs. |
| A lens cannot supply all six fields | Do not emit the candidate; name the lens and why. |
| Empty session | Local lenses only; say the list is repo-derived. |

## The test surface — two named executables, then the prose

r2's blocker: `collect.sh` performs reads only, so it could not own ranking, parking, suppression, or
rendering — yet those were the assertions. Two components, both deterministic:

**`skills/standup/collect.sh`** — the eight lens reads, nothing else. Stable sorted JSON, no
timestamps in the payload. `--fixture <dir>` reads canned inputs.

**`skills/standup/triage.py`** — the state machine. Consumes `collect.sh` JSON plus a session-state
fixture (previously reported fingerprints, `PARKED/` contents) and emits the ranked list, the notices
line, and the park delta. Modes: `--dry-run` (emit, write nothing) and `--apply` (write the park
file). Exit `0` clean, `2` usage, `3` a lens degraded.

The split: `triage.py` owns everything mechanical; `SKILL.md` owns only the final prose judgement —
Part 2's wording and the `what` phrasing.

| DoD bullet | Asserted by |
|---|---|
| dedup, tier assignment, tie-break ordering | `triage.py --dry-run` over fixtures; fixed input → fixed ordered list |
| every tier-classification row | one fixture per row, including the tier-6 fallback and a cited override |
| no write outside `PARKED/` | snapshot the fixture tree, `triage.py --apply`, assert byte-identity everywhere else |
| second-run byte no-op | `--apply` twice over unchanged state; assert no new park file **and** the frozen second-run transcript |
| tiers 1–3 exempt from suppression and parking | fixture with 8 tier-1 items, rerun; assert none suppressed, none parked |
| **lens-2 self-feed is broken** | fixture where a park file exists untracked; assert it is not emitted as an item |
| caps | count rendered lines of `triage.py --dry-run` against the enumerated table; fixtures for max, empty, and degraded shapes |
| item schema | every emitted line parses to four fields with non-empty evidence |
| every degradation row | one fixture each |
| install | `skills/standup/install.sh --check` exits 0 after install |

Judgement — was tier 4 the *right* call for this item — is not unit-testable and is measured in
Phase 4.

## Definition of Done

- Loads from `skills/standup/`; `install.sh --check` exits 0.
- `collect.sh` and `triage.py` exist and run offline against fixtures.
- Every row of the test-surface table has a passing assertion.
- Rendered output never exceeds the enumerated line table; total ≤ 15.
- Every emitted item parses against the item schema with non-empty typed evidence.
- Ranking is total: identical fixture state → byte-identical ordered list.
- No write outside `PARKED/`.
- Second run over unchanged state writes no park file and emits the frozen second-run transcript.
- No tier-1–3 item is ever suppressed or parked.
- A park file is never itself emitted as an item.

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
