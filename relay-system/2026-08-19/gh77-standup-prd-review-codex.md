# RELAY · GH-77 /standup PRD review (Codex sol-high)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-19.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh77-standup-prd-review-codex): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md` — the PRD for a new
  skill, `/standup`. Nothing is built yet; this review is of the **specification**, before any code.
- Reviewer: codex (model `sol`, reasoning effort `high`)   ·   Producer: claude-a
- Started: 2026-08-19
- Context the reviewer needs (read these, they are the design constraints):
  - `skills/radar/SKILL.md`, `skills/10days/SKILL.md`, `skills/releases/SKILL.md` — siblings in this
    repo that `/standup` explicitly defers to or routes into.
  - `~/.claude/skills/finish-line/SKILL.md` and `~/.claude/skills/rabbit-hole/SKILL.md` — the two
    skills whose disciplines this PRD borrows (Mandatory Bar; consolidate-once + interruption budget).
  - `AGENTS.md` → *Repo-specific rails* — the one-marathon-at-a-time rule and the RELEASES DB rails.
  - `RELEASES-DB-FAQS.md` → the drift Q — the incident that motivates the whole PRD.

## Definition of Done — what to grade against

Grade the PRD as a **buildable specification**, not as prose. It passes only if an unfamiliar builder
could implement it without asking the operator a question. Specifically:

1. **The frozen decisions are actually frozen and actually unambiguous.** Four were taken by the
   operator: session+local input scope, park-only write authority, both output halves every run,
   tactical cap of 7. If any is stated in a way that permits two readings, that is a `[Blocker]`.
2. **The interface catalogue is correct.** Every command, flag, rule name, and file path it cites
   must exist. Verify against the repo — `python3 utils/py/releases_app.py --help`, the ROADMAP entry
   format, `utils/pdda/pdda.sh`. **A wrong flag in a catalogue is worse than no catalogue**, because
   the whole point is that the next agent trusts it without checking. Cite `file:line` for anything
   you verify or falsify.
3. **The priority ladder is decidable.** Could two competent agents, handed the same session, produce
   materially different top-3 lists? If the tiers overlap or the tie-breaks are underspecified, say
   exactly where.
4. **The caps are enforceable, not aspirational.** "Hard cap 7" is a claim about behavior. Does the
   PRD say enough for a test to falsify it? Same for the ~5-line strategic section.
5. **The Definition of Done in the PRD is itself testable.** Each bullet should map to something a
   suite can assert. Name any that cannot.
6. **Overlap with the siblings is genuinely resolved.** The PRD claims a gap exists between
   `/finish-line`, `/rabbit-hole`, and `/radar`. Is that true, or does one of them already cover
   this with a different name? A real overlap the PRD papers over is a `[Blocker]`.
7. **Failure modes the PRD does not name.** It is a spec for a skill whose job is to prevent an LLM
   from producing a wall of text and chasing rabbit holes. Where could this skill itself commit
   either sin? Be adversarial here — this is the highest-value part of the review.

Out of scope for this review: the skill's name, the visual/markdown formatting of the eventual chat
output, and anything about GH-75 (the dashboard) beyond whether the PRD's reference to it is accurate.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

**Verdict: Changes requested**

- **[Blocker] The inputs are named, but the candidate-building procedure is absent.** The PRD lists
  conversation, tree, branch, PR, ROADMAP, RELEASES, and PARKED lenses
  (`PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md:127`), then jumps straight to ranking. It never
  defines what becomes an item, how the same work found in several lenses is deduplicated, how an
  open loop is distinguished from context, or how its closure interface is chosen. Fix: add a
  per-lens table with the bounded read, candidate predicate, stable item key, evidence field,
  staleness source, and closing-interface rule; then specify cross-lens deduplication before ranking.
- **[Blocker] The frozen ladder is not decidable across those sources.** “Staleness” and “smallest
  effort” are the tie-breaks (`PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md:109`), but a dirty
  file, conversation promise, PR, ledger row, and PARKED entry do not share a defined timestamp or
  effort scale; items may also match several tiers. Fix: say “highest applicable tier wins,” define
  a timestamp/fallback for each lens, define coarse deterministic effort bins plus a final stable
  tie-break (for example item key), and state what happens when age or effort is unknown.
- **[Blocker] The declared lenses cannot perform two checks used to justify the product.** The
  motivating audit includes closed issues with stale ROADMAP markers and newly filed issues absent
  from every index (`PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md:39` and `:40`), while the input
  scope permits open PRs but no bounded issue-state or issue-coverage read (`:129`). Fix: add a
  bounded current-state issue lens for issue numbers mentioned in the session and referenced by the
  current ledgers (not a history/similarity sweep), with loud degradation when that lens is
  unavailable; otherwise narrow the stated problem so the skill does not promise these detections.
- **[Blocker] The ROADMAP catalogue states a stricter, false parser grammar.** It says a recognized
  row requires a GH prefix, marker, bold status, body, doc link, and issue URL
  (`PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md:178` and `:181`), but the canonical contract
  requires only a flat bullet with a bold name under one of four headings (`ROADMAP.md:139` and
  `:145`); the parser extracts that bold prefix (`utils/py/_marathon_plan.py:485`). Fix: catalogue
  the actual minimum grammar separately from this repo's recommended GH-pointer shape, and preserve
  the four exact headings from `utils/py/_marathon_plan.py:31`.
- **[Blocker] “Exact command” is not exact, and the strategic reader is incomplete.** The output
  example and follow-up use bare `releases roadmap sync`
  (`PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md:85` and `:188`), while the canonical executable
  form is `python3 utils/py/releases_app.py roadmap sync` (`ROADMAP.md:171`). The catalogue also omits
  `list [--status ...]`, the whole-ledger reader needed to compare the release plan rather than only
  the next release (`skills/releases/SKILL.md:52` and `:54`), and abbreviates `update` as arbitrary
  `--<field>` although the accepted flags are finite (`utils/py/releases_app.py:2744`). Fix: provide
  copy-paste-complete invocations (or explicitly define one resolved `$R` prefix), add `list`, and
  enumerate the supported update flags.
- **[Blocker] The tactical item schema contradicts its own Definition of Done.** The frozen output
  contract requires only what/tier/closure (`PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md:80`),
  the ladder requires evidence only for tiers 1–3 (`:124`), but Definition of Done requires evidence
  on every item and changes “command, file, PR, or interface” into “exact closing command” (`:223`).
  Fix: define one canonical one-line item schema, require a cited evidence field for every tier, and
  consistently define the close field as an executable command or a named file/PR action when no
  command exists.
- **[Blocker] PARKED mutation makes idempotence undefined and can create a self-feeding loop.** The
  skill reads PARKED (`PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md:129`), writes every overflow
  there (`:141`), and promises consecutive runs return the same list (`:226`), but it defines no
  item identity, already-parked suppression, or no-op append rule. Fix: assign stable item IDs,
  exclude prior parked records from re-parking while retaining them for dedupe, append only newly
  parked IDs, and specify the identical second-run chat line and byte-no-op behavior.
- **[Blocker] The PARKED format is not actually an existing single format.** The PRD claims it
  borrows Finish Line's PARKED protocol (`PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md:64`) but
  specifies `PARKED/<date>-<event>.md` (`:142`); Finish Line specifies
  `YYYY-MM-DD-<reponame>-HHMM.md` with a `finish-line/parked/v2` run schema
  (`/Users/noelsaw/.claude/skills/finish-line/SKILL.md:181` and `:191`), while
  `PARKED/2026-08-19-session-close.md:1` is a different free-form event file. Fix: freeze one
  standup-owned schema and collision rule, or explicitly reuse Finish Line v2 byte-for-byte; define
  append behavior and the record fields needed for the stable-ID rule above.
- **[Blocker] The line limits cannot be tested as written.** “~5 lines” and “target under 15”
  (`PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md:91` and `:104`) have no falsifiable boundary,
  and headings, opening text, overflow, and degradation notices can push the total beyond either
  reading. Fix: replace both with integer maxima and define exactly what counts as a line and where
  mandatory degradation/overflow lines are charged; update Definition of Done to those exact
  integers.
- **[Should] Define the deterministic fixture runner before promising behavioral tests.** The no-write
  test says it will “run the skill's procedure” (`PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md:224`),
  but no invocation seam, fake conversation/GitHub/CLI inputs, or output parser exists. Fix: specify
  a fixture manifest and a deterministic helper or transcript evaluator that can assert ranking,
  caps, degradation, PARKED bytes, and second-run idempotence without live network/model variance.
- **[Pass] The sibling boundary is real, not papered over.** Finish Line is branch/checkpoint closure
  and freezes a done list (`/Users/noelsaw/.claude/skills/finish-line/SKILL.md:15` and `:72`);
  Rabbit Hole is reactive, one-task consolidation followed by an operator nod
  (`/Users/noelsaw/.claude/skills/rabbit-hole/SKILL.md:16` and `:21`); Radar owns the 21-day strategic
  sweep and is read-only analysis (`skills/radar/SKILL.md:3` and `:23`). A session-scoped, bounded,
  recommendation-only triage remains distinct once the blockers above define its mechanics.
- **[Pass] The one-marathon constraint is carried accurately.** The PRD refuses a second marathon and
  treats Immediate next-up as context (`PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md:200`), matching
  the repo rail that exactly one marathon is in flight and is named there (`AGENTS.md:81`).

Whole-file note: the entire PRD, including pre-existing text, was swept; no additional defects were
omitted as out of scope.

Handing off to Producer — go to the claude-a window and say “take your turn”.

### Producer — claude-a · round 2

Nine blockers, one should, all **Implemented** — none declined. The first blocker was the correct
diagnosis of the whole document: r1 named its inputs and jumped straight to ranking, so it never said
what *becomes* an item. That made the rest inevitable. Rewrote rather than patched; everything from
**The lenses** to **The test surface** is new.

**Dispositions**

- **[Blocker] The candidate-building procedure is absent** — **Implemented.** New *The lenses*
  section: an eight-row table giving each lens a bounded read, candidate predicate, stable item key,
  required evidence field, staleness source, and closing-interface rule, plus the standing rule that
  a lens which cannot produce all six for a candidate **does not emit it** and degrades loudly
  instead. Cross-lens dedup is now specified and explicitly runs *before* ranking: same issue/PR
  number, then same path; the survivor keeps the first key in lens order (stability), carries every
  contributing evidence field, and takes the highest tier any contributing lens justified.
- **[Blocker] The ladder is not decidable across those sources** — **Implemented.** "Highest
  applicable tier wins, evaluated top-down" is stated. Staleness has a per-lens source in the table;
  an unknown age sorts *after* every known age, never before. Effort is three deterministic bins — S
  (single command, no argument the agent must invent), M (single-file edit), L (anything else). Final
  stable tie-break is the item key, lexicographic, so ordering is total and repeat runs are
  byte-identical.
- **[Blocker] The declared lenses cannot perform two checks used to justify the product** —
  **Implemented**, taking your first option rather than narrowing the problem. Lens 5 is a bounded
  *issue-state* read: `gh issue view <n>` for only the numbers already mentioned in the session or
  cited by the current ledgers — a per-number state read, never a list or history sweep, which is
  what keeps it on the session side of the `/radar` line. Its degradation row is explicit. This is
  the single most consequential finding across both reviews: as written, r1 could not have detected
  two of the three drifts its own opening table cites.
- **[Blocker] The ROADMAP catalogue states a stricter, false parser grammar** — **Implemented**, and
  verified independently before accepting: `_parse_bullet` matches `^- \*\*(.+?)\*\*`
  (`utils/py/_marathon_plan.py:485`), and `ROADMAP.md:139-145` says the same. The catalogue now
  states the **grammar** (a flat bullet with a bold name, under one of the four exact headings from
  `utils/py/_marathon_plan.py:31`, silent-skip on anything else) and this repo's **recommended
  shape** as two separate things, with an explicit instruction never to present the second as the
  requirement. The Fable thread graded this ✅ — it had verified that r1's format string matches a
  real entry, which is true and not the claim under test.
- **[Blocker] "Exact command" is not exact, and the strategic reader is incomplete** —
  **Implemented, with one modification.** Rather than expanding the full path at every site, `$R` is
  defined once as `python3 utils/py/releases_app.py` with the standing rule that every *emitted*
  command is copy-paste executable and `$R` is expanded in output — you offered this as the
  alternative and it keeps the catalogue readable. Added `list [--status draft|active|shipped|cut]
  [--all-repos]` and labelled it the whole-ledger reader the strategic half needs. `update`'s flags
  are now enumerated finitely (verified against `$R update --help`) instead of an arbitrary
  `--<field>`.
- **[Blocker] The item schema contradicts its own Definition of Done** — **Implemented.** One
  canonical single-line schema — `<tier> · <what> — <evidence> — <close>` — with a field table:
  evidence required for every tier (`file:line` · `#n` · `rule=name` · quoted span), and `close`
  defined as an executable command **or** a named `file:`/`PR #n:` action when no single command
  exists. The schema is stated once and the DoD asserts against it rather than restating it.
- **[Blocker] PARKED mutation makes idempotence undefined** — **Implemented.** Stable item keys are
  now assigned by the lens table. Prior parked records are excluded from re-parking but retained for
  dedupe; only newly parked keys are appended; **if nothing is new, nothing is written** — no file,
  no touch. The second-run chat line is specified (`"N parked, M suppressed."`) and the byte-no-op is
  the thing the idempotence test asserts.
- **[Blocker] The PARKED format is not an existing single format** — **Implemented.** Froze a
  standup-owned schema, `PARKED/<YYYY-MM-DD>-standup-<HHMM>.md`, with the infix named as the
  collision rule and the deliberate divergence from finish-line v2. Record fields specified. Chose a
  new schema over reusing finish-line v2 byte-for-byte because v2's run-level frontmatter models a
  *close*, and this skill parks continuously within a session.
- **[Blocker] The line limits cannot be tested as written** — **Implemented.** Integer maxima with a
  defined unit and a per-segment table: 1 opening + 7 items + 1 overflow + 6 strategic = **17 total,
  hard**. "Rendered line" is defined; overflow and degradation lines are charged to a segment rather
  than being free. The DoD now cites those exact integers.
- **[Should] Define the deterministic fixture runner before promising behavioral tests** —
  **Implemented.** `skills/standup/collect.sh` is the named seam: the eight lens reads only, stable
  sorted JSON with no timestamps in the payload, `--fixture <dir>` for canned inputs. Every
  mechanical assertion runs against it, never against live model output. The test-surface table maps
  each property to its assertion, and Phase 2 now builds `collect.sh` and its fixtures *before* any
  prose about behavior.

**Handing off to the Reviewer (codex)** — round 2 is a rewrite, so re-read the whole artifact rather
than diffing. The highest-value checks: does the lens table actually yield a decidable item for all
eight lenses; is lens 5 genuinely bounded (session-mentioned and ledger-cited numbers only) or has it
drifted into a sweep; and can the suppression rule hide a tier-1 finding.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
