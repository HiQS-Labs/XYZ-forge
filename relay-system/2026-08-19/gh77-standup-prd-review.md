# RELAY · GH-77 /standup PRD review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-19.
-->

NEXT: — (closed)
STATUS: Escalated
ROUND: 4 / 4

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
6. **Commit only the relay file** (`relay(gh-77-standup-prd-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md` — the PRD for a new
  skill, `/standup`. Nothing is built yet; this review is of the **specification**, before any code.
- Reviewer: claude-fable   ·   Producer: claude-a
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

### Reviewer — claude-fable · round 1

swept file: yes

**Verdict:** Changes requested

**Findings**

- **[Blocker]** The strategic cap "~5 lines" is not a cap — it blocks because a frozen output contract that permits many readings fails DoD-1, and "never exceeds ~5 lines" (PRD:226) cannot be asserted by any test (rubric 4/5) — **Fix:** replace with an exact integer ceiling and define what counts as a line (e.g. "6 rendered lines max, counting the degradation statements") — `PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md:91` ("hard cap: ~5 lines") vs `:226`
- **[Blocker]** The DoD's test bullets have no testable surface — a SKILL.md is LLM instructions, yet the DoD demands "a test that snapshots the tree, runs the skill's procedure against a fixture, and asserts byte-identity" (PRD:224–227), an idempotence test (:228), and "every degradation row above has a test" (:229). Nothing deterministic is specified to run; the sibling that solves this (`/10days`) ships bundled deterministic scripts precisely so "the mechanical parts run byte-identical every time" (`skills/10days/SKILL.md:440-447`). An unfamiliar builder cannot write Phase 3 without asking the operator what these tests execute — **Fix:** specify a bundled deterministic collector script (git status, branch/ahead-behind, `gh pr list`, `releases check` output) as the pinned test surface, and restate the cap/idempotence bullets as fixture-transcript contract checks or Phase-4 dogfood assertions — `PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md:224-229`
- **[Should]** Idempotence contradicts append-only parking — "two consecutive runs with no work between produce the same list" (PRD:228) while every run with overflow writes a new dated park file ("one file per parking event", :141-143), so run 2 duplicates run 1's park file and the byte-identity test can never pass twice — **Fix:** state that a rerun with an unchanged list makes no park write (or re-uses the day's file), and exempt that file in the byte-identity test — `PROJECT/1-INBOX/GH-77-STANDUP-SESSION-TRIAGE.md:141-143,228`
- **[Should]** The PARKED protocol is ambiguous: PRD:64 says it "borrows … the PARKED protocol" from `/finish-line`, whose format is `YYYY-MM-DD-<reponame>-HHMM.md` with schema-v2 frontmatter and R-/P-ids (`~/.claude/skills/finish-line/SKILL.md:181-218`), but PRD:142 specifies `PARKED/<YYYY-MM-DD>-<event>.md` — and both formats already coexist (`PARKED/2026-08-16-xyz-forge-2143.md` vs `PARKED/2026-08-19-session-close.md`). No entry schema is given at all — **Fix:** name the `<event>` format as the deliberate divergence from finish-line, and specify the minimum entry fields (item, tier it missed, evidence, pickup pointer)
- **[Should]** The priority ladder is not fully decidable: (a) the staleness tie-break (PRD:108-109) is undefined for session-derived items that carry no timestamp; (b) an open PR one approval from merge matches tier 4 ("a loop one step from closed", :116) *and* tier 5 ("an open PR going stale", :120) with no explicit first-match rule; (c) the ladder requires evidence only for tiers 1–3 (:124-126) while the DoD requires "tier + evidence + the exact closing command" on **every** item (:223) — two agents produce different top-3s — **Fix:** state "first matching tier wins, evaluated top-down", define staleness measurement per source (PR `updatedAt`, doc `updated:`, session = age 0), and reconcile the evidence rule to one statement
- **[Should]** The skill can itself re-litigate every run (criterion 7): the strategic half is mandatory every run, the pivot-ID dedupe is explicitly deferred to v2 (PRD:243-244), and there is no decline/mute mechanism — so a pivot the operator heard yesterday and a tier-5 item they chose not to do re-appear on every invocation of a skill designed to be reached for "constantly" (:46). `/finish-line` names exactly this as its core failure mode ("Each re-ask that surfaces one more item teaches the user that the finish line is unreachable", `~/.claude/skills/finish-line/SKILL.md:250-253`) — **Fix:** pull the minimal v1 forward: don't re-raise a pivot or item already stated this session, and honor a parked/declined item as muted until state changes
- **[Should]** "ahead/behind trunk" (PRD:129) never names the trunk — this repo's declared integration branch is `development`, not `main` (`skills/releases/SKILL.md:81`: "Resolve the active integration branch from repo policy (`development` in this repo…)"), and `/finish-line` resolves `main`/`master` — two agents compute different ahead/behind facts — **Fix:** adopt the releases-skill resolution rule by reference
- **[Nit]** "Target under 15 lines" (PRD:104) is a soft instruction in a spec whose own thesis is "a soft instruction to be concise has never produced a concise agent; a fixed ceiling has" (:88-89), and degradation statements (:206-215) are never said to count against the budget — **Fix:** make 15 a cap and state the degradation lines count
- **[Nit]** "asking once" when `PARKED/` is missing (PRD:210) doesn't define the scope of "once" (per run? per session?) — **Fix:** say "once per session"
- **[Pass]** The claimed gap among siblings is genuine: `/finish-line` is one-branch, checkpoint-driven closing (`finish-line/SKILL.md:34-49`), `/rabbit-hole` fires on one task mid-drip (`rabbit-hole/SKILL.md:10`), `/radar` is a 21-day repo-wide window ("Default **21 days**", `skills/radar/SKILL.md:38`), `/10days` executes ("cut a branch and execute the marathon end-to-end", `skills/10days/SKILL.md:5-10`) — none answers "4 hours in, what did I leave open"
- **[Pass]** The motivating incident is accurately reported: the 0.7.1/stale-markers/#61–#65 drift table matches `RELEASES-DB-FAQS.md:352-367` row for row, and the #61–#65 disposition matches `PARKED/2026-08-19-session-close.md` (update note)
- **[Pass]** The dashboard gate claim ("a stale one turns the push red") holds end-to-end: `test/roadmap-dashboard.sh:53` fails on a stale committed dashboard, runs via `validate.sh:335`, which `githooks/pre-push:132` executes on push
- **[Pass]** Silent-skip parser claim verified: an unknown `###` heading sets `current=None` and its bullets are dropped without warning (`utils/py/_marathon_plan.py:518,521-523`), and the shadow-mirrors-file-not-planner claim matches `RELEASES-DB-FAQS.md:343-345`
- **[Pass]** Pre-existing defects: none found in the relay thread file (`relay-system/2026-08-19/gh77-standup-prd-review.md`) — header, rubric, and setup references all resolve; stated explicitly per ground rules

**Interface catalogue audit**

| PRD claim | Verified? | Evidence |
|---|---|---|
| `next` | ✅ | `releases next --help`: "the next unshipped release, by target date" |
| `show --version <v>` / `--full` untruncated | ✅ | `show --help`: "--full print long values verbatim (default elides them at 240 chars)" |
| `check` — generation trio, receipt chain, advisories | ✅ | top-level help: "DB<->dump<->generated consistency; … receipt-vs-change bypass detection; temp-ref staleness" |
| `ship --gid --evidence` required, `rule=ship-needs-evidence` | ✅ | `ship --help`: "REQUIRED — an empty value is refused with rule=ship-needs-evidence"; `utils/py/releases_app.py:1526` |
| `update --gid <GID> --<field> <value>` | ✅ | `update --help` lists --version/--status/--target-date/--description/… |
| `roadmap sync` one-way, no-change free no-op | ✅ | `roadmap --help`: "one-way; ROADMAP.md stays the source of truth"; `RELEASES-DB-FAQS.md:341-342` |
| `utils/releases-merge-resolve.sh` exists | ✅ | mode 755, 8.8K at repo root path |
| `rule=release-overdue` / `rule=release-target-passed` / `rule=temp-ref-stale` | ✅ | `utils/py/releases_app.py:2346,2352,2299` |
| ROADMAP entry format string | ✅ | `ROADMAP.md:102` (the GH-77 entry itself matches the schema exactly) |
| Planner SECTIONS = Queue / parked intake, In progress, Completed, Deferred · vision | ✅ | `utils/py/_marathon_plan.py:31` |
| Parser is a regex, failure mode silent skip | ✅ | `utils/py/_marathon_plan.py:518,521-523` |
| `bash utils/roadmap-dashboard.sh`; stale dashboard turns push red | ✅ | `test/roadmap-dashboard.sh:53` → `validate.sh:335` → `githooks/pre-push:132` |
| pdda checks `roadmap`, `roadmap-coverage`, `doc-ready` | ✅ | `utils/pdda/pdda.sh help` lists all three verbatim |
| Coverage rule + `roadmap_exempt: true` | ✅ | `utils/pdda/pdda.sh:340-352` |
| PDDA lifecycle 1-INBOX → 2-WORKING → 3-COMPLETED | ✅ | all three dirs exist under `PROJECT/` |
| One-marathon rail; named in Immediate next-up | ✅ | `AGENTS.md:73` §Repo-specific rails rule 1; `ROADMAP.md:50` "### Immediate next-up (ordered)" |
| `skills/*/install.sh` symlink pattern | ✅ | 19 `skills/*/install.sh` files present (10days, radar, releases, …) |
| `PARKED/<YYYY-MM-DD>-<event>.md` "existing dated-file format" | ⚠️ partially | convention documented in `PARKED/2026-08-19-session-close.md` header, but a second format (`2026-08-16-xyz-forge-2143.md`, finish-line's) coexists — see [Should] above |

**Handing off to the Producer (claude-a)** — disposition each finding, fix the two Blockers (exact strategic cap; a named deterministic test surface for the DoD), and resolve the parking/idempotence and ladder ambiguities in the PRD.

> Transport note (orchestrator, not the reviewer): the headless `claude-turn.sh` lane was unavailable — no `claude` CLI on this machine — so this turn ran as an in-process Fable subagent under read-only instruction rather than under the shim's worktree isolation + path allowlist. Verified after the fact: `git diff --stat 8104c73` was empty, so the reviewer wrote nothing.

### Reviewer — claude-fable · round 2

> **Restored 2026-08-19 by the orchestrator (claude-a), out of order.** This block was produced at
> the time but never appended — the Producer read it and went straight to producing, so the Log
> jumped Reviewer r1 → Producer r2. The gap was found by this reviewer's own round-3 pre-existing
> sweep. Ground rule 1 makes the thread the single source of truth; a missing reviewer block silently
> demotes it to the Producer's summary of what the reviewer said. Recorded here verbatim; the
> Producer's r2 dispositions below were written against this block.

swept file: yes

**Verdict:** Changes requested

**Round-1 findings — resolution check**

| # | Round-1 finding (short) | Status | Evidence |
|---|---|---|---|
| 1 | [B] "~5 lines" is not a cap | Resolved | Integer caps with a defined unit (PRD:174-175); "**17 rendered lines**, hard" (:184). New arithmetic defect filed below. |
| 2 | [B] DoD has no testable surface | Resolved | "Ship `skills/standup/collect.sh` … takes `--fixture <dir>`" (:302-304); per-property assertion table (:309-317); judgement carved out to Phase 4 (:318-319) |
| 3 | [S] Idempotence contradicts append-only parking | Resolved as stated | "append only item keys absent from **every** `PARKED/*.md`. **If nothing is new, write nothing**" (:221-222). The overflow regime re-breaks it via lens 2 — new Blocker below, distinct mechanism. |
| 4 | [S] PARKED protocol ambiguous | Resolved | Frozen schema with the infix named as collision rule and divergence (:210-213); record fields specified (:218) |
| 5 | [S] Ladder not decidable (3 sub-points) | Resolved | "First matching tier wins" (:127); per-lens staleness (:95-104) + unknown age sorts after known (:143-145); "Evidence is required for **every** tier" (:138); lexicographic key tie-break (:149-150) |
| 6 | [S] Re-litigates every run | Resolved as scoped | "Suppression — the anti-re-litigation rule (v1, not deferred)" (:195); three concrete rules (:199-203). The mechanism over-corrects — new Blocker below. |
| 7 | [S] Trunk never named | Resolved | "`development` here… Do not assume `main`" (:110-112); confirmed live at `skills/releases/SKILL.md:80-81` |
| 8 | [N] "Target under 15" soft | Resolved | "not a target — a cap" (:184); degradation lines "charged… never free" (:183) |
| 9 | [N] "asking once" scope | Resolved | "**once per session**, not once per run" (:289) |
| 10 | [⚠️] PARKED "existing format" partially true | Resolved | ":213"; both pre-existing files confirmed on disk |

**New findings**

- **[Blocker]** Segment caps do not reconcile with the total: 1 + 7 + 1 + 6 = **15**, but the total is
  17 (:179-184); Part 2 "includes its own heading" (:182) while Part 1's heading is charged to no
  segment, and even granting Part 1 an uncharged heading yields 16 — under no reading do the segments
  produce 17. A FROZEN section permitting two readings is a Blocker per DoD-1 — **Fix:** enumerate
  every permitted line exhaustively and make the total equal the sum of the segment caps; update the
  DoD bullet (:327-328) to the same integers — `:177-184`
- **[Blocker]** The suppression rule can hide a live tier-1 finding. (a) Within a session: a
  data-corruption item reported on run 1 and ignored is suppressed on run 2 (:199-200) because a
  persisting defect's evidence *is* unchanged — lens 6's evidence is "the emitted `rule=` line"
  (:102), identical every run until fixed. (b) Across sessions: a tier-1 item can park (:186), and a
  parked key with unchanged evidence is muted indefinitely (:201-202); the only exit is lens 8, whose
  predicate references a field the PARKED record schema does not contain (:104 vs :218), so nothing
  ever un-parks it — **Fix:** exempt tiers 1–3 from both suppression and parking, and redefine lens
  8's predicate over fields the record actually carries — `:199-204,186,104,218`
- **[Blocker]** Lens 2 turns the skill's own park write into a self-feeding loop. A fresh park file is
  untracked and `PARKED/` is not ignored, so lens 2's predicate (:98) emits it next run; in the
  overflow regime that caused the park the 7 slots are full, so it parks — one new file per run,
  unbounded, and the "write nothing" no-op (:221-222) never triggers because each park file is itself
  new — **Fix:** exclude `PARKED/` from lens 2, and add an overflow-then-rerun fixture — `:98,186,221-223`
- **[Should]** Lens 5's bound grows without limit (:101): today 30 unique issue references in
  `ROADMAP.md` plus non-shipped manifests, growing monotonically as `Completed` accumulates, against
  the frozen property "it finishes in seconds" (:52-53) — **Fix:** bound the ledger-cited set to
  active-marker entries plus non-shipped manifests plus session mentions
- **[Should]** Lens 6's item key is neither chosen nor unique: "`rule:<name>` or `rel:<gid>`" (:102)
  gives no rule for which applies, and two overdue releases collide on one `rule:` key — **Fix:** key
  release-scoped findings `rel:<gid>`, others `rule:<name>:<subject>`; move the stored-state clause to
  lens 5
- **[Should]** Lens 1's key derivation is underspecified (:97) — first 8 words of *which* text, and
  what normalization? Suppression, PARKED dedup, and the lexicographic tie-break all compare keys
  byte-wise — **Fix:** slug of the quoted evidence span, lowercased, non-alphanumerics collapsed
- **[Nit]** "never against model output" (:304-305) is contradicted by its own table (:314,:316,:334)
  — **Fix:** scope the sentence and name the transcript contract checks as a second lane
- **[Pass]** `update` flag enumeration is exact, matching `update --help` flag-for-flag — PRD:238
- **[Pass]** `list [--status …] [--all-repos]` verified against `list --help` — PRD:235
- **[Pass]** The ROADMAP grammar is now correct, and I verified the proposition that matters this
  time rather than the citation: `_parse_ledger` gates on `^- \*\*` (`utils/py/_marathon_plan.py:521`
  — a stronger citation than the PRD's `:485`, whose non-bold fallback is unreachable from the ledger
  path); unknown headings set `current=None` (`:518,521`); headings verbatim at `:31`
- **[Pass]** Lens 4's `gh pr list --json` fields are all valid — PRD:100
- **[Pass]** Revision header's "11 blockers between them" is accurate: 2 + 9 — PRD:17-18
- **[Pass]** Pre-existing sweep: unchanged sections re-read clean; drift table still matches
  `RELEASES-DB-FAQS.md`; sibling-gap claim from r1 still holds

**Handing off** — to the Producer (claude-a): three Blockers, all in the new material.

### Producer — claude-a · round 2

Rewrote rather than patched. Two blockers where both were "this cannot be tested as written", plus
Codex's independent finding that the r1 input scope could not detect two of the three drifts the PRD
opens with, meant the mechanics were never specified — not that they were specified wrongly.
Everything from **The lenses** to **The test surface** is new or rewritten.

**Dispositions**

- **[Blocker] "~5 lines" is not a cap** — **Implemented.** Both caps are now integers with a defined
  unit: Part 2 ≤ 6 rendered lines, total ≤ 17. "A rendered line" is defined (newline-delimited as
  emitted; soft-wrap does not count; headings count, blanks do not), and degradation statements are
  explicitly charged to the segment they qualify rather than being free. See *Output contract*.
- **[Blocker] The DoD has no testable surface** — **Implemented**, taking the `/10days` precedent you
  cited. The skill now ships `skills/standup/collect.sh`: the eight lens reads and nothing else,
  emitting stable sorted JSON, with `--fixture <dir>` for canned inputs. Every mechanical assertion
  runs against `collect.sh --fixture`, never against model output. The test-surface table maps each
  property to how it is asserted, and explicitly carves out judgement (was tier 4 the *right* call)
  as Phase-4 dogfood rather than pretending it is unit-testable.
- **[Should] Idempotence contradicts append-only parking** — **Implemented.** The append rule is now
  "append only item keys absent from every `PARKED/*.md`; **if nothing is new, write nothing** — no
  file, no touch." That is what makes the second run a byte no-op, and the idempotence assertion now
  tests exactly that rather than byte-identity over a file that always changes.
- **[Should] PARKED protocol ambiguous** — **Implemented.** Frozen one standup-owned schema:
  `PARKED/<YYYY-MM-DD>-standup-<HHMM>.md`, with the `-standup-` infix named as both the collision
  rule and the deliberate divergence from finish-line's `<reponame>-<HHMM>`. Record fields are
  specified (item-key, tier, what, evidence, close, first-seen) because the stable-ID rule needs
  them. Three formats coexisting without a rule was the real defect; this names ours.
- **[Should] The ladder is not decidable** — **Implemented**, all three sub-points. (a) Staleness now
  has a per-lens source in the lens table, and an item whose source is unavailable sorts *after*
  every known-age item — never before, so an unmeasured item cannot jump the queue. (b) "First
  matching tier wins, evaluated top-down" is stated explicitly, and an item is never listed twice.
  (c) Evidence is now required for **every** tier, reconciling the ladder with the DoD. Added a third
  tie-break — item key, lexicographic — so the ordering is total and two runs over identical state
  are byte-identical.
- **[Should] The skill can re-litigate itself every run** — **Implemented, pulled into v1.** You were
  right that this is not a v2 concern for a skill designed to be reached for constantly. Stable item
  keys made it mechanical: do not re-raise a reported key whose evidence is unchanged, do not
  re-raise a key already in `PARKED/`, do not re-raise a strategic claim already stated this session.
  Suppressed counts appear only in the overflow line. The finish-line quote you cited is now the
  section's stated rationale.
- **[Should] "ahead/behind trunk" never names the trunk** — **Implemented** by reference, as
  proposed: resolve the declared integration branch per `skills/releases/SKILL.md:81` (`development`
  here), with an explicit "do not assume `main`".
- **[Nit] "Target under 15" is soft in a spec whose thesis is that soft fails** — **Implemented.** It
  is now a hard cap of 17 (raised from 15 to absorb the overflow and degradation lines that are now
  charged rather than free), stated as "not a target — a cap".
- **[Nit] "asking once" undefined** — **Implemented.** "Once per session, not once per run."

**On the interface-catalogue audit.** 17 of 18 verified is the most useful thing either review
produced, and the one ⚠️ was correct. But the Codex thread independently graded the ROADMAP entry
format a **Blocker** where this review passed it, and Codex was right: `_parse_bullet` matches only
`^- \*\*(.+?)\*\*` (`utils/py/_marathon_plan.py:485`), so the parser requires a bold name under one
of four headings and nothing more — the full `GH-n · title … → links` shape is this repo's
convention, not the grammar. The ✅ here verified that r1's format string *matches a real entry*,
which is true and not the claim that mattered. The catalogue now states the minimum grammar and the
recommended shape as separate things. Flagging the mechanism, not the miss: a citation can be
accurate and still check the wrong proposition.

**Handing off to the Reviewer (claude-fable)** — round 2 is a substantial rewrite, so re-read the
whole artifact rather than diffing: verify the lens table produces a decidable item for each of the
eight lenses, that the caps are now falsifiable, and that the suppression rule cannot itself hide a
tier-1 finding.

### Producer — claude-a · round 3

Round 3. Both reviewers ran independently again; 13 further findings, nearly all against material r2
introduced. All implemented, none declined. Highlights of what changed structurally:

- **A tier classifier now exists.** r1 and r2 both listed tiers and never said how a candidate
  reaches one. There is now a first-match table keyed on lens output (corruption rule set; quoted
  traceback; operator label; `mergeStateStatus: CLEAN`; PR older than 7 days; …), a deterministic
  tier-6 fallback, and exactly one promotion path — a cited operator statement, which becomes the
  item's evidence so a fixture can represent it.
- **Tiers 1–3 are exempt from suppression AND from parking.** They render every run until closed.
- **Suppression compares a semantic fingerprint** — `sha256(key + tier + live-state)` — not the
  display string, so an escalation re-raises and a changed defect re-raises.
- **The second-run contract is frozen as one exact transcript**, replacing the contradictory pair
  ("same list" + "do not re-raise") that could not both hold.
- **Keys are entity-canonical** (`issue:`/`pr:`/`path:`/`rel:`/`rule:`/`branch:`, and a sha256 digest
  for conversation-only items), so they no longer depend on which lens fired or collide on an
  eight-word prefix.
- **One typed evidence grammar** covering all eight lenses, replacing four forms that rejected most
  of what the table emitted.
- **`triage.py` joins `collect.sh`** as a second named executable owning ranking, suppression,
  parking, and rendering, with `--dry-run`/`--apply`. `SKILL.md` keeps only the prose judgement.
  Every DoD bullet now names its assertion.
- **The line table is enumerated** and the total is the sum of its parts: 1+1+7+1+1+4 = 15.

**Dispositions — your round-2 findings**

- **[Blocker] Segment caps do not reconcile with the total** — **Implemented.** Every permitted line
  is now enumerated in a table with its own count, Part 1's heading is charged explicitly, and the
  total is stated as *the sum of the segment caps, not a separate number*: 1+1+7+1+1+4 = 15. Your
  observation that no reading produced 17 was exactly right; the DoD cites 15.
- **[Blocker] Suppression can hide a live tier-1 finding** — **Implemented, both halves.** (a)
  Within-session: tiers 1–3 are now exempt from suppression outright — they render every run until
  closed. (b) Across sessions: they are also exempt from *parking*, which closes the route you
  traced; if eight tier-1 items exist the cap truncates the list but never silences one. And lens 8's
  predicate is redefined over a field the record actually carries — the record's own `close` field
  being a no-op — instead of the "blocking condition" the schema never had. That was the detail that
  made the trap permanent, and it is the sharpest thing either reviewer found this round.
- **[Blocker] Lens 2 turns the skill's own park write into a self-feeding loop** — **Implemented.**
  Verified your premise before accepting it: `git check-ignore PARKED/` returns rc 1 (not ignored)
  and `git ls-files PARKED/` lists two tracked files, so a fresh park file is untracked and lens 2
  would have emitted it. Lens 2's read is now
  `git status --porcelain -- . ':(exclude)PARKED'`, and "a park file is never itself emitted as an
  item" is a DoD bullet with its own fixture. This is the best finding of the relay: it is a defect
  that only appears on the *second* run, in the overflow regime only, and neither the other reviewer
  nor I saw it.
- **[Should] Lens 5's bound grows without limit** — **Implemented.** The ledger-cited set is now
  restricted to entries under `Queue / parked intake` and `In progress` only, plus manifests of
  non-shipped releases, plus session mentions. `Completed` is excluded by name because it is the term
  that grows monotonically. Measured: 30 unique issue references across all of `ROADMAP.md`, of which
  the active-marker subset is a fraction — the bound is now tied to active state, not ledger size.
- **[Should] Lens 6's key is neither chosen nor unique** — **Implemented**, via a general fix: keys
  are now canonical **by entity**, not by lens. A release-scoped finding keys `rel:<gid>`; a rule
  finding keys `rule:<name>:<gid-or-subject>`, so two overdue releases cannot collide. The
  stored-state-vs-issue clause moved to lens 5, which is the lens that can actually see issue state,
  with lens 6's `show` output as its input.
- **[Should] Lens 1's slug is underspecified** — **Implemented**, and hardened past your proposal:
  `conv:<first 12 hex of sha256 of the normalized quoted evidence span>`, normalization stated
  (lowercase, collapse whitespace, strip punctuation). A digest rather than a slug because the other
  reviewer independently showed an 8-word prefix collides.
- **[Nit] "never against model output" contradicted by its own table** — **Implemented.** With
  `triage.py` owning ranking, suppression, parking and rendering, the mechanical lane asserts against
  `triage.py --dry-run`; the transcript checks are named as what they are. The overreaching sentence
  is gone.

**On your round-1 resolution table.** All ten confirmed resolved, and two of your "resolved as
stated" qualifications were the load-bearing calls — #3 and #6 both flagged that the *mechanism* I
adopted re-broke the property through a new route. That is the failure mode worth naming: a
disposition can be faithful to the finding and still be wrong, and only re-reading the whole artifact
catches it.

**Handing off to the Reviewer (claude-fable)** — third read of a document that has changed
substantially each round. Highest-value checks: does the tier classifier actually terminate on every
candidate the lens table can produce; can any tier-1 item still reach a suppressed or parked state by
some path; and does the enumerated line table hold for the empty, maximum, and fully-degraded shapes
simultaneously. If it is sound, approve it — a fourth round is the escalation cap, not a free one.

### Reviewer — claude-fable · round 3

> **Restored 2026-08-19 by the orchestrator (claude-a), out of order.** Second occurrence of the
> same defect the r2 restoration note above describes — one round after that note was written. The
> Log jumped Producer r3 → Producer r4. Recorded verbatim; the Producer's r4 dispositions were
> written against this block.

swept file: yes

**Verdict:** Changes requested

**Round-2 findings — resolution check**

| # | Round-2 finding (short) | Status | Evidence |
|---|---|---|---|
| B1 | Line caps don't reconcile (declared 17) | Resolved | Every line enumerated; "1+1+7+1+1+4 = 15, hard" (PRD:214); DoD "total ≤ 15" (:373) |
| B2 | Suppression can hide a live tier-1 | **Partial** | Named routes closed (:233-234); lens 8 predicate over the record's own `close` field (:97). The fix opens a **new route via cap truncation** — see Blocker below. Third instance of the r1-#3/#6 pattern. |
| B3 | Lens 2 self-feeds on its own park write | Resolved | `':(exclude)PARKED'` (:91); DoD bullet (:379) + fixture (:359). Verified by execution in a scratch repo. Side effect filed as a new [Should]. |
| S1 | Lens 5's bound grows without limit | Resolved | Bounded to session mentions + Queue/In progress + non-shipped manifests; "not `Completed`, which grows without limit" (:116-118) |
| S2 | Lens 6's key neither chosen nor unique | Resolved | Entity-canonical key table (:130-138); `rule:<name>:<gid-or-subject>` (:136) |
| S3 | Lens 1's slug underspecified | Resolved | `conv:<sha256 …, first 12 hex>` with normalization (:138) |
| N1 | "never against model output" self-contradicted | Resolved | Sentence gone (:336-351); residual seam gap filed as [Should] |

**New findings**

- **[Blocker]** Ranking is referenced everywhere and defined nowhere — `triage.py` "emits the ranked
  list" (:345), suppression runs "after ranking" (:246), the test table asserts "tie-break ordering"
  (:354), the DoD demands a total order (:375) — yet no within-tier ordering rule survives in rev 3.
  Grep confirms: no tie-break, no staleness ordering, no lexicographic key rule; **`S-bin` is used
  once (:156) and never defined**. The r3 rewrite dropped the r2-era ranking spec, which now exists
  only in the Producer's disposition text, not the artifact — **Fix:** restore the ranking section:
  tier ascending, staleness per the lens table (unknown sorts after known), S/M/L effort bins with S
  defined, then item key lexicographic — that also defines `S-bin` — `PRD:156,354,375`
- **[Blocker]** A tier-1 item ranked 8th is silenced with zero trace — the exact property B2
  protected, re-broken through the truncation route. "Items 8+ never appear; they park (subject to
  the tier exemption below) and are represented only by the notices line: *'N parked, M suppressed.'*"
  (:219-221): a tier-1 item beyond the cap is exempt from parking, exempt from suppression, and
  appears in **neither count**. PRD:234's own claim that the cap "never silences a corruption
  finding" is contradicted two sections up, and the frozen second-run transcript (:254-255) makes it
  invisible on every subsequent run — **Fix:** the cap is frozen, so extend the notices line and the
  frozen transcript to carry a truncated-critical count, and fixture 8 tier-1 items → 7 rendered +
  K=1 — `PRD:219-221,233-235,254-257`
- **[Should]** Two test-table rows assert against output `triage.py` does not emit — it emits "the
  ranked list, the notices line, and the park delta" (:344-346), but the caps row counts rendered
  lines against the enumerated table (:360) whose rows 1, 2, 5, 6 are SKILL.md prose, and the
  second-run row asserts a transcript including Part 2 (:357, :254-255) — **Fix:** have
  `triage.py --dry-run` emit the full six-row skeleton, or split the assertions into two lanes
- **[Should]** The degradation table charges only one of six rows to a segment — "gh unavailable" is
  charged (:329); truncation (:330), the six-field refusal (:333), the no-ledger statement (:332) and
  the empty-session statement (:334) name no segment. In a reachable state the verdict plus 3–4
  mandatory statements compete for Part 2's 1–4 lines with no combine-or-drop rule, so "loud, never
  silent" (:327) collides with the hard cap — **Fix:** charge every row and state a share-a-line or
  priority rule — `PRD:327-334`
- **[Should]** The lens-2 exclusion also hides **modified tracked** `PARKED/` files, forever —
  verified by execution: with `':(exclude)PARKED'`, ` M PARKED/tracked-park.md` disappears from
  porcelain output, and this repo has two tracked PARKED files. An operator's uncommitted edit to a
  parked file is permanently invisible. The exclusion only needs to cover **untracked** paths — a
  modified tracked path cannot loop, it closes with `git add` + commit — **Fix:** narrow the rule, or
  state the blind spot as an accepted trade-off — `PRD:91,101-102`
- **[Nit]** Row 3's "0–7" lower bound is unreachable — zero items emits `Nothing open.` (1 line), so
  it is 1–7; the other counts hold: empty = 5–8, maximum = 15 — `PRD:210,214`
- **[Nit]** The corruption set omits `dump-missing`, which the checker groups with the other three —
  `resolved = {"dump-divergence", "dump-missing", "generation-mismatch", "receipt-chain"}`
  (`utils/py/releases_app.py:2366-2367`) — a missing dump would classify tier 6 — `PRD:153`
- **[Pass]** The tier classifier terminates on every candidate — all six fields required (:88), tier 6
  is the deterministic fallback (:158), first-match stated (:149-150); live probe: this repo's PR #51
  returns `mergeStateStatus: "UNKNOWN"`, which falls past tier 4 into 5/6 rather than a dead end
- **[Pass]** Lens-2 pathspec works as claimed — ran it in a scratch repo: the untracked park file is
  present without the exclude, absent with it; `M src/tracked.txt` unaffected
- **[Pass]** Lens 3's no-upstream case is real and detectable — `fatal: no upstream configured`, exit
  128; trunk resolution citation verified verbatim at `skills/releases/SKILL.md:81`
- **[Pass]** New interface claims verified live — the four corruption rules exist; `releases.db`/
  `releases.sql` at root; `update`'s twelve flags match `update --help` exactly; `show --full` help
  verbatim; `list` prints `items=%d` (`:1728`); ROADMAP grammar `^- \*\*` (`_marathon_plan.py:521`)
  and four headings (`:31`); the `gh pr list` field set returns valid data
- **[Pass]** Pre-existing sweep: one transcript-integrity gap in the thread itself — the Reviewer r2
  block is absent from the Log, so ground rule 1's "single source of truth" depends on the Producer's
  summaries; an orchestrator issue, not the artifact's. No other defects found

**Handing off** — to the Producer (claude-a): two surgical fixes, not a rewrite — restore the
ranking/tie-break section (defining `S-bin`) and add the truncated-critical count to the notices line
+ frozen transcript + a DoD fixture; the two Shoulds are one-line charges/scopes. Round 4 should
close this.

### Producer — claude-a · round 4

Round 4 — the last before the escalation cap. **Edited surgically, not rewritten.** That is a direct
response to r3's most embarrassing finding: the r2 ranking spec was deleted by rewriting the section
around it. Rewriting a reviewed document is how accepted material gets lost, so every change below is
a targeted edit and the r2/r3 material that survived review was not touched.

**First — a defect of mine, not the artifact's.** Your pre-existing sweep caught that your own
round-2 Reviewer block was never appended: the Log jumped Reviewer r1 → Producer r2 → Producer r3.
Confirmed and **restored above**, verbatim, marked as an out-of-order restoration with the reason.
I read that review and went straight to producing. Ground rule 1 makes this file the single source of
truth, and a missing reviewer block silently demotes it to *the Producer's summary of what the
reviewer said* — which is exactly the failure mode the ground rule exists to prevent, committed by
the person enforcing it.

**Dispositions — your round-3 findings**

- **[Blocker] Ranking is referenced everywhere and defined nowhere** — **Implemented.** New
  *Ranking — the total order* section restoring the r2 spec as **one tuple** so a future rewrite
  cannot lose half of it: tier ascending → staleness oldest-first (with `unknown` sorting after every
  known age *within* its tier) → effort bin S/M/L → item key lexicographic. **S is now defined** —
  "a single command with no argument the agent must invent, every argument present in the item's own
  evidence" — and the tier-4 row's dangling `S-bin` reference resolves to it. Your diagnosis was
  exact: it survived only in my disposition prose, not in the artifact.
- **[Blocker] A tier-1 item ranked 8th is silenced with zero trace** — **Implemented**, and this is
  the third instance of the pattern you named in r2, now recorded in the revision header so it is not
  repeated a fourth time. The cap is frozen, so I took your fix: the notices line now carries
  *"N parked, M suppressed, **K critical beyond cap** — `triage.py --dry-run --all` lists every
  item"*, `K` is mandatory when non-zero, `--all` renders the uncapped list read-only, and the frozen
  second-run transcript includes `K`. The DoD bullet is restated as **"No tier-1–3 item is ever
  silent — rendered, or counted in `K`"**, with your 8-tier-1-items fixture.
- **[Should] Two test rows assert against output `triage.py` does not emit** — **Implemented** by
  taking your first option: `triage.py` now renders **all six rows** of the line table, not the
  mechanical middle. Part 2's verdict comes from a finite vocabulary (`no-contradiction` ·
  `ledger-behind` · `release-overdue` · `insufficient-evidence`) with one optional operator-facing
  clause, so the second-run transcript is byte-comparable rather than model-variable.
- **[Should] The degradation table charges only one of six rows** — **Implemented.** Every row now
  has an ID (`D1`–`D6`) and a named segment, `D3` moved to the notices line so it never competes, and
  there is an explicit **lossless aggregation rule**: ≤ 3 active IDs get a sentence each; more
  collapse to one line naming every ID and its subject. No ID is ever dropped. Your reachable
  collision state (no `gh`, no ROADMAP, no ledger, empty session) is now a required single fixture.
- **[Should] The lens-2 exclusion also hides modified tracked `PARKED/` files** — **Implemented**,
  and thank you for running it rather than reasoning about it. The rule is narrowed to *untracked*
  paths under `PARKED/` only; a modified tracked park file remains a candidate and closes with
  `git add` + commit, which cannot loop. The test table now carries **both** directions — the
  self-feed fixture and a control asserting a modified tracked park file **is** still emitted. My
  first fix over-corrected, which is the same shape as the two you flagged in r2.
- **[Nit] Row 3's `0–7` lower bound is unreachable** — **Implemented**, now `1–7`. Your empty-case
  count (5–8) and maximum (15) both hold against the corrected table.
- **[Nit] The corruption set omits `dump-missing`** — **Implemented**, and verified at
  `utils/py/releases_app.py:2366`: the checker groups exactly the four you named. An absent dump
  would have classified as housekeeping.

**Handing off to the Reviewer (claude-fable)** — round 4 of 4. If the two Blockers are closed and the
new material introduces nothing, approve and close the relay. If a real defect remains, say so and
let it escalate — `STATUS: Escalated` at the cap is an honest outcome and I will report it as one
rather than press for an approval.

### Reviewer — claude-fable · round 4

swept file: yes

**Verdict:** Changes requested — round 4 ends without Approved, so **`STATUS: Escalated`** is the
honest outcome.

**Round-3 findings — resolution check**

| # | Round-3 finding (short) | Status | Evidence |
|---|---|---|---|
| 1 | [B] Ranking referenced everywhere, defined nowhere | Resolved | *Ranking — the total order* (PRD:187-209): tier → staleness (unknown after known, :197-199) → S/M/L (S defined :201-203) → key lex (:205) |
| 2 | [B] Tier-1 ranked 8th silenced | Resolved on the truncation route — re-broken on a new route (Blocker below) | `K critical beyond cap` mandatory when non-zero, `--all` escape hatch (:296-300); `K` in the frozen transcript (:353-356); DoD (:499,:521) |
| 3 | [S] Test rows assert output `triage.py` doesn't emit | Resolved | `triage.py` renders "all six rows of the line table" (:470,:477-479); finite verdict vocabulary (:483-486) |
| 4 | [S] Degradation table charges one of six rows | Resolved (new fixture defect below) | `D1`–`D6` each charged (:437-443); `D3` on the notices line (:440,:449); aggregation rule (:445-449) |
| 5 | [S] Lens-2 exclusion hides modified tracked park files | Resolved | "except an **untracked** path under `PARKED/`" (:96); both directions tested (:502) |
| 6 | [N] Row 3's `0–7` lower bound unreachable | Resolved | "**1–7**" (:283) |
| 7 | [N] Corruption set omits `dump-missing` | Resolved | PRD:171; verified live at `utils/py/releases_app.py:2366-2367` |

**New findings**

- **[Blocker]** The tier-1 corruption path is unreachable through lens 6 — the **fourth** instance of
  the named pattern. Lens 6's predicate is "any `warn: rule=…`" (PRD:100), but the corruption rules
  emit via `fail()`, which prints `FAIL: rule=%s: %s` (`utils/py/releases_app.py:2166-2167`), not
  `warn:` (`:166`). `FAIL: rule=dump-divergence` therefore matches no predicate: no candidate, no
  `D5` (the lens ran fine), no `K`. Two further gates block it even with the predicate fixed — the
  evidence grammar requires `rule:<name>@<gid>` (:223) but corruption rules are DB-wide and carry no
  release gid (the key table already concedes `<gid-or-subject>`, :154 — an internal inconsistency),
  and the staleness source "release `target_date`" (:100) is undefined for them, so the six-field
  rule (:90) refuses emission. **The skill's founding incident class is silently invisible** —
  **Fix:** predicate = any `FAIL: rule=…` **or** `warn: rule=…`; evidence payload
  `<name>@<gid-or-db>` matching the key table; staleness `unknown` for DB-wide rules (ranking
  :197-199 already handles it); add a `FAIL`-line fixture — `PRD:90,100,154,171,223` ·
  `utils/py/releases_app.py:166,2166-2167`
- **[Blocker]** The `.git/standup-session-*.json` store violates the frozen write authority and is
  unimplementable as written. (a) FROZEN decision 2 is "**Write authority:** `PARKED/` only" (:80),
  unamended, while the DoD reads "No write outside `PARKED/` and `.git/standup-session-*.json`"
  (:519) and the no-write test carves the same exception (:497) — the DoD quietly rewrites an
  operator decision the FROZEN section never ratified, which is DoD-1's named Blocker class.
  (b) `XYZ_SESSION_ID` (:335) is defined nowhere; repo-wide grep returns zero matches outside the PRD
  and relay files. (c) The literal `.git/` path breaks in linked worktrees, where `.git` is a file,
  and this repo has active worktrees now — **Fix:** amend FROZEN decision 2 by operator ratification,
  or relocate to `PARKED/.standup-session-<id>.json`, which stays inside the frozen authority and is
  already invisible to lens 2 via the untracked exclusion (:96); resolve the dir via
  `git rev-parse --git-dir` if `.git` is kept; name the session-ID source — `PRD:80,334-338,497,519`
- **[Should]** The required all-six-simultaneous degradation fixture is unrealizable: `D1` is "`gh`
  unavailable" and `D2` is "`gh pr list` returns 51 rows" (:438-439) — mutually exclusive, yet :451
  and :503 demand one fixture exercising all six — **Fix:** require the maximal consistent set
  (`D2`–`D6` together, `D1` separately), or state that `D1` substitutes for `D2`
- **[Should]** The Reviewer r3 block is missing from the Log — the exact defect the r2 restoration
  note describes, recurring one round after that note was written: the Log jumps Producer r3 →
  Producer r4 — **Fix:** restore the r3 block verbatim, as was done for r2
- **[Nit]** Lens 7's staleness source, "`ROADMAP.md` mtime vs last sync" (:101), is a comparison, not
  an age — say which timestamp is the staleness value and where "last sync" is read from
- **[Nit]** The frozen transcript pins `M` to "the tier-4–6 items shown in run 1" (:354-355), implying
  parked-key suppressions (:344) do **not** count in `M` — state it, or a builder who counts both
  rules fails the byte-comparison
- **[Pass]** The restored ranking section is complete and consistent with everything referencing it:
  the tuple (:194-206) covers `triage.py`'s contract (:470), the DoD's totality bullet (:518), the
  test table's fixtures (:495), and tier 4's `S-bin` (:174) resolves to :203
- **[Pass]** The narrowed lens-2 exclusion survives the commit-between-runs trace: a committed,
  unmodified park file is absent from porcelain output entirely, so no candidate; a park file the
  skill's own `REVISED` append dirties is emitted once as designed, closes with `git add` + commit,
  and its unchanged `M` payload (:238) suppresses re-parking — no unbounded loop — `PRD:96,106-109,238`
- **[Pass]** The `REVISED` rule keeps the byte no-op: unchanged state means no new keys and no changed
  fingerprints, so neither branch writes (:377-378)
- **[Pass]** The arithmetic closes at all three shapes: max 15 (:287), empty 5 (:281-286), and the
  collapsed degradation line fits Part 2's 3 free body lines (:445-449)
- **[Pass]** Tier-5 advisory names are the emitted rule names — `warn("temp-ref-stale" …)` prints as
  `warn: rule=temp-ref-stale:` (`utils/py/releases_app.py:166`); the internal tally
  `warnings.append("stale-ref")` (`:2304`) is not the emitted name, so PRD:175,:397 are correct
- **[Pass]** ROADMAP grammar citations hold live — `SECTIONS` (`_marathon_plan.py:31`), `^- \*\*`
  (`:521`), unknown heading → `current=None` (`:518-519`)
- **[Pass]** Pre-existing sweep of the thread: beyond the missing r3 block (filed above), header,
  rubric, restored r2 block and all Producer dispositions resolve; no other defects

**Handing off** — round 4 ends without Approved: **`STATUS: Escalated`**. Escalation needs three
things: (1) fix the lens-6 tier-1 path — `FAIL: rule=` predicate, gid-free evidence form, unknown
staleness — it is the founding incident class and currently fully silent; (2) resolve the
session-state store against FROZEN decision 2 with operator ratification, or relocate under
`PARKED/`; (3) restore the Reviewer r3 block. Everything else in revision 4 is sound — both r3
Blocker dispositions were faithful, and the second was re-broken only by the pattern this relay has
now hit four times: a new route, not a bad fix.

### Orchestrator — relay closed ESCALATED · 2026-08-19

Round cap reached. **Both threads escalate**, independently: Codex returned *Blocked*, Fable returned
*Changes requested* and named `STATUS: Escalated` as the honest outcome. Neither reviewer approved,
and neither was asked to soften a finding to land one. No fifth cycle was opened — Codex's own
handoff said to resolve this with the operator instead, and that is what happens next.

**What the relay produced.** Four revisions of the artifact, eight review turns across two
independent models, 44 graded findings. All dispositioned; none declined.

| Round | Findings | Character |
|---|---|---|
| 1 | 11 blockers | r1 named its inputs and never said what *becomes* an item |
| 2 | 13 | almost all against material the r1→r2 rewrite introduced |
| 3 | 10 | including a **regression** — the r2 ranking spec deleted by rewriting around it |
| 4 | 10 | two structural, both unresolved at the cap |

**The convergence signal, stated plainly.** 11 → 13 → 10 → 10 is not a converging review. A
converging one goes 11 → 5 → 2. The rate held flat because the document was being pushed past what
prose can hold: a state machine — ranking tuples, fingerprints, evidence grammars, line arithmetic —
specified in Markdown, where every gap needs a human reader to find it. `triage.py` would have
failed on eight of these in a second.

**One pattern recurred four times**, and it is the most transferable thing in this thread: a
disposition faithful to the finding re-broke the same property through a new route.

1. r1 idempotence fix → re-broken by the lens-2 park self-feed.
2. r1 re-litigation fix → suppression could bury a tier-1 item.
3. r2 tier-1 exemption → re-broken by cap truncation (exempt from parking *and* suppression = counted
   in neither).
4. r3 `K` + `--all` fix → closed truncation, while lens 6's `warn:`-only predicate meant a corruption
   finding never became a candidate at all.

Each fix was correct about what it fixed. The property still failed.

**Two blockers stand at the cap, and both need the operator, not another round:**

1. **The founding incident class is invisible.** Lens 6 matches `warn: rule=…`; the corruption rules
   emit through `fail()` → `FAIL: rule=…` (`utils/py/releases_app.py:2166`, vs `:166`). A
   `dump-divergence` produces no candidate, no degradation, no `K`. Verified independently by the
   orchestrator before recording. Mechanically small to fix; it is here because it was found at the
   cap, not because it is hard.
2. **The session-state store contradicts a FROZEN operator decision.** Decision 2 is `PARKED/` only;
   the DoD grants `.git/standup-session-*.json`. A spec cannot amend its own frozen decision — that
   needs ratification or relocation under `PARKED/`. Secondary: `XYZ_SESSION_ID` is undefined
   repo-wide, and a literal `.git/` path breaks in linked worktrees, which this repo uses.

Plus two frozen-decision conflicts Codex raised that are likewise the operator's: lens 4's
`gh pr list` is *discovery*, which frozen decision 1 excludes; and `--all` is uncapped output in a
spec whose DoD says rendered output *never* exceeds 15 lines.

**Orchestrator defects, recorded because the thread is the source of truth.** Two reviewer blocks
were never appended — Fable r2, then Fable r3 one round *after* the r2 restoration note warned about
exactly that. Both restored above, verbatim, marked out of order. A missing reviewer block silently
demotes this file from the record to the Producer's summary of the record. Also: the r4 briefing
miscounted Fable's r3 Shoulds as four; there were three. Fable correctly refused to reconcile a
finding that did not exist rather than inventing one — the right call, and the miscount was the
orchestrator's.

**Recommendation to the operator: stop reviewing the PRD. Build `triage.py`.** Revision 4 is a sound
foundation — both reviewers confirmed the sibling boundary, the interface catalogue, the ranking
tuple, the arithmetic, and the lens-2 fix all hold. The remaining precision belongs in code where a
test falsifies it in a second, not in a document where a fifth reviewer finds it in six minutes.
Take the two blockers above as the first two commits.

STATUS: Escalated. No further turn.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
