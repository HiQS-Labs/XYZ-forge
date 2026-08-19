# RELAY · GH-77 /standup PRD review
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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
