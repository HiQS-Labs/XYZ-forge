# Triangulate — plan + draft skill (for relay QA)

**Date:** 2026-08-28
**Author:** Claude (agent-b)
**Status:** FINAL rev 3 — round 1 (deepseek-v4-pro) + round 2 (qwen3.8-max) applied; shipped
**Deliverable:** a new skill `triangulate` installed at
`/Users/noelsaw/Documents/GH Repos/giant-brains-claude-skills/02-plan/triangulate/SKILL.md`

---

## 0. What was asked

1. Set up a fresh full clone of `XYZ-forge` from `origin/development`. **Done** —
   `/Users/noelsaw/marathon-clones/triangulate-relay` @ `fa85a955`.
2. Copy `debug-mantra` and `recon` into the giant-brains skills repo.
   **Already true** — both already live there (`04-build/debug-mantra`, `02-plan/recon`) and
   `~/.claude/skills/{debug-mantra,recon}` are symlinks into that repo. No copy is needed; the
   step is a verified no-op, not a skipped one.
3. Create a new `triangulate` skill that applies the best balance of **debug-mantra**,
   **ponytail-refined**, and **recon** to a problem or task — **only if the tension between them
   is not inherently contradictory**, and only if the result is grounded and practical.
4. Retire the current local `ponytail` skill (`~/.claude/skills/ponytail/`, a real directory
   holding only `SKILL.md`, distinct from the repo's `ponytail-refined`).

This document answers (3) — the gate first, then the design, then the draft skill.

---

## 1. The gate: is the tension inherently contradictory?

**Verdict: no.** The three lenses govern three different axes, so they compose. But there is
**one** genuine conflict, and the skill is worth building only because it resolves that conflict
explicitly. Without the arbitration rule in §2, `triangulate` would be a wrapper that says "apply
all three" — which fails ponytail's own rung 1 and should not be built.

| Lens | Axis it governs | Its question |
|---|---|---|
| **recon** | ground truth about the **system** | What is actually there? |
| **debug-mantra** | ground truth about the **claim** | Is what I believe actually true? |
| **ponytail** | size of the **response** | What is the smallest thing that works? |

recon and debug-mantra are *input* discipline — buy evidence before committing. ponytail is
*output* discipline — spend the minimum once committed. Independent axes compose without
contradiction, and in practice they reinforce each other:

- ponytail **without** recon is not laziness, it is guessing. A short diff with an unmeasured
  blast radius is cheap to write and expensive to own.
- recon **without** ponytail is ceremony. A four-lane fan-out on a contained rename is exactly the
  kind of ritual that gets ignored the day it actually matters.
- debug-mantra is what stops both from running on a false premise.

### The one real conflict, named

**How much evidence to buy.** recon defaults toward coverage ("fan out four lanes, wide and
shallow"). ponytail defaults toward stopping early ("The ladder is a reflex, not a research
project" — `skills/ponytail/SKILL.md:48`). Left unarbitrated, whichever skill fires first wins the
session and the other becomes decoration. That is the conflict `triangulate` exists to settle.

### Secondary tensions, and why they are not blocking

| Apparent clash | Resolution |
|---|---|
| debug-mantra: "reproduce before you theorise" vs ponytail: "ship the one-liner" | Different phases. Reproduce is input, one-liner is output. Ponytail never licenses a fix without an observation — debug-mantra's own "scale rigor to the bug" already caps the cost. |
| recon: "no plan step may name a blast radius nobody read" vs ponytail: "fewest files, shortest diff" | Not in conflict — recon constrains *what you must know*, ponytail constrains *what you must write*. A fully-read radius often makes the diff **shorter**, because you stop building defensively against imagined callers. |
| ponytail is "ACTIVE EVERY RESPONSE" (`skills/ponytail/SKILL.md:31`), so it would also shrink how recon and debug-mantra execute, not just their output | Real, and it is exactly what §2.2's evidence floor exists to bound. Ponytail may shrink the investigation, but never below the floor. Raised by round 1; resolved, not waved away. |
| All three want to be the thing that fires first | Settled by the order rule in §2.1 and its one exception. |

Each of the three already ships its own calibration escape hatch (recon's "Skip recon when" list,
debug-mantra's "scale rigor to the bug", ponytail's "When NOT to be lazy"). Triangulate does not
re-derive those — it decides which hatch is open for a given decision.

---

## 2. The design

### 2.1 Order — ground, falsify, shrink, with one gate in front

**recon → debug-mantra → ponytail. Ponytail runs last.**

You cannot know a one-liner is sufficient until you know what it has to cover. Ponytail applied
first produces a guess.

**The one exception — Step 0, the existence gate.** Ponytail's rung 1 ("Does this added machinery
need to exist at all?" — `skills/ponytail/SKILL.md:39-40`) can kill the task before any evidence is
worth buying. Ask it first, in one line.

**It may terminate triangulate only if the answer rests on a fact you already hold, or one command
away.** If answering it needs a trace, it is not rung 1 — it is recon, and the fixed order applies.
This guard is the whole point: "we don't need this" asserted without a number is the same guessing
the order rule exists to prevent, and ponytail itself forbids it ("Can't actually measure it? You
have no profiler. Don't assert 'fast enough' blind, name the assumption and the trigger to revisit" — `skills/ponytail/SKILL.md:72`).

*Round 1 raised the missing exception; the measurement guard is the modification.*

### 2.2 The arbitration rule (the actual content of the skill)

> **Ponytail governs the investigation too — but it may only cut evidence that a reversible,
> contained decision would waste. The evidence floor is set by reversibility and reach, never by
> how confident you feel.**

Classify **the decision**, not the task, on two axes:

- **Reversible** — you could delete it next week and nothing else moves.
  **Irreversible** — a migration, a published contract, a data shape, an API others call, or
  anything with a rollback cost.
  **A change another repo or another person has already consumed is not reversible.** Reverting
  your side does not un-break theirs. Reversibility is measured at the far end of the blast radius,
  not in your own working tree.
- **Contained** — one file, or callers you have already enumerated *and read*.
  **Crossing** — other modules, contracts, stored state, other repos, other people.

| | **Contained** | **Crossing** |
|---|---|---|
| **Reversible** | **none** — ponytail alone | **recon-lite + falsify** — read the seams, then disprove "that is all of them" |
| **Irreversible** | **falsify** — mantra step 3 on the load-bearing belief | **full** — recon fan-out + mantra ledger |

Read it as a severity count: zero hits → none, one hit → falsify, two hits → full.

The floor is a floor. You may buy more evidence; you may not buy less. "I'm confident" is not a
reason to drop a floor — confidence is the thing debug-mantra exists to attack.

*Round 1 finding, accepted-modified: its worked example (rename a utility imported by 20 modules
across 2 repos) showed `recon-lite` alone was too low for reversible+crossing. It proposed moving
the cell to `falsify`; the seam read is what tells you **what** to falsify, so both are named — and
the sharper fix is the reversibility definition above, which is what the example actually exposed.*

### 2.3 The anti-ceremony clause

Two guards, because round 1 showed one was too late:

1. **Before classifying:** if the change is smaller than the sentence describing it, do not
   classify. Fix it.
2. **After classifying:** if writing the Triangulation Card would take longer than making the
   change, the cell was reversible + contained. Say so in one line and go.

This is ponytail's rung 1 applied to triangulate itself.

### 2.4 The output — a Triangulation Card

One block, in chat when short, in a file when the recon output is long (recon's own rule: long
output belongs in the file).

```
SUBJECT: <the change, one line>
CELL:    <reversible|irreversible> x <contained|crossing>  ->  floor: <none|recon-lite+falsify|falsify|full>
GROUND:  <seams and file:line from recon — or "skipped: <reason>">
FALSIFY: <the belief that costs most if wrong; what disproved it, or what it survived>
SMALLEST:<the shape being shipped> — skipped: <X>, add when <Y>
UNKNOWNS:<what would change this answer, and the one command that settles it>
```

### 2.5 When NOT to fire

This is a **pre-step**, not a footnote — it runs before classification. Triangulate earns its place
only when **at least two** lenses would fire *and would pull in opposite directions on effort*.
Otherwise route to the single skill:

- A live bug in a system already understood → `/debug-mantra` alone.
- Greenfield with nothing to trace → `/ponytail` alone.
- Planning a change to an existing system with no over-build temptation → `/recon`, then `/swe`.
- A typo, comment, or formatting change → none of the three.
- A decision about whether an authority should exist at all → `/spike-360` first.

---

## 3. Draft SKILL.md (rev 2)

```markdown
---
name: triangulate
description: >-
  Apply three lenses to one problem in a fixed order — recon (what is actually
  there), debug-mantra (is what I believe actually true), ponytail (what is the
  smallest thing that works) — with an explicit rule for how much evidence to buy
  before shrinking. Use when a task tempts you toward opposite errors at once:
  over-building against a blast radius nobody measured, or shipping a confident
  one-liner into a system nobody read. Trigger on /triangulate, and on "what is the
  right amount of work here", "am I over-thinking this", "am I under-thinking this",
  "how deep should I go", "give me the balanced take", "is this a big change or a
  small one". Do NOT fire when only one lens applies: a live bug in a system you
  already understand is /debug-mantra, greenfield is /ponytail, and planning a
  change to a known system is /recon then /swe.
argument-hint: "[subject]"
---

# Triangulate

Three lenses, one problem. Ground it, falsify it, then shrink it.

## Step 0a — Should this fire at all?

Route to the single skill and stop, if the task is:

| Task | Route to |
|---|---|
| A live bug in a system you already understand | [debug-mantra](../../04-build/debug-mantra/SKILL.md) |
| Greenfield — nothing exists to trace | [ponytail](../../04-build/ponytail-refined/SKILL.md) |
| A change to a known system, no over-build temptation | [recon](../recon/SKILL.md), then [swe](../swe/SKILL.md) |
| "Should this authority exist at all?" | [spike-360](../spike-360/SKILL.md) |
| Pricing a one-way door you have already found | [blast-radius](../../01-decide/blast-radius/SKILL.md) |
| A typo, comment, or formatting change | none of the three — fix it |

Triangulate fires only when **at least two** lenses would fire **and pull in opposite directions on
effort**. If the change is smaller than the sentence describing it, do not classify — fix it.

## Step 0b — Does this need to exist at all?

Ponytail rung 1, in one line. If the answer is no, say so and stop.

**This may end the run only if the answer rests on a fact you already hold, or one command away.**
If answering it needs a trace, it is not rung 1 — it is recon. Proceed to Step 1.

Do not assert "we don't need this" without the number. Ponytail forbids it: *"Can't actually
measure it? You have no profiler. Don't assert 'fast enough' blind."*

## The three lenses

| Lens | Axis | Question |
|---|---|---|
| recon | the **system** | What is actually there? |
| debug-mantra | the **claim** | Is what I believe actually true? |
| ponytail | the **response** | What is the smallest thing that works? |

The only genuine conflict between them is **how much evidence to buy**. Steps 1–2 settle it.

Order after Step 0: **recon → debug-mantra → ponytail.** Ponytail runs last.

## Step 1 — Classify the decision, not the task

Two axes. One line each. Under a minute.

- **Reversible** — delete it next week and nothing else moves.
  **Irreversible** — migration, published contract, stored data shape, an API others call, or
  anything with a rollback cost.
  **A change another repo or another person has already consumed is not reversible** — reverting
  your side does not un-break theirs. Measure reversibility at the far end of the radius, not in
  your own working tree.
- **Contained** — one file, or callers you have already enumerated *and read*.
  **Crossing** — other modules, contracts, stored state, other repos, other people.

If you cannot classify an axis, it is **crossing** and **irreversible** until one lookup says
otherwise. Spend the lookup — asserting the cheap cell without checking is the easiest dishonest
exit in this skill.

## Step 2 — Read the floor

| | **Contained** | **Crossing** |
|---|---|---|
| **Reversible** | **none** — ponytail alone | **recon-lite + falsify** |
| **Irreversible** | **falsify** | **full** |

A severity count: zero hits → none, one hit → falsify, two hits → full.

- **none** — say `triangulate → ponytail only, <reason>` and go. No card, no ceremony.
- **recon-lite + falsify** — one recon pass for the seams (who calls this, what writes this state,
  what crosses a boundary; `file:line` or it is an Unknown), then disprove *"that is all of them."*
  The seam read is what tells you what to falsify.
- **falsify** — [debug-mantra](../../04-build/debug-mantra/SKILL.md) step 3 against the single
  belief that makes this irreversible. Run the **disproof** first.
- **full** — [recon](../recon/SKILL.md) fan-out, then the mantra ledger across every observation.
  Ponytail then applies to the **fix**, never to the reading.

**The floor is a floor.** Buy more evidence freely; never buy less. "I'm confident" is not a reason
to drop a floor — confidence is what debug-mantra exists to attack.

## Step 3 — Ground (recon)

Run [recon](../recon/SKILL.md) at the floor's width. Its rules carry unchanged: the graph is a
lead not a citation, every edge a decision depends on is confirmed by reading the file, and
anything unverified goes in Unknowns rather than being smoothed into the findings.

Recon's own skip list still applies inside triangulate. A floor of `recon-lite` on a subsystem you
traced ten minutes ago is satisfied by what you already hold — write it down, do not re-run it.

## Step 4 — Falsify (debug-mantra)

Take the belief the plan leans on hardest — the one whose failure costs the most, not the one you
are least sure of. Then apply [debug-mantra](../../04-build/debug-mantra/SKILL.md):

- What is the cleanest **disproof**? Run that first.
- Does the belief hold against **every** breadcrumb so far, or only the most recent?
- If the belief rests on a screenshot, a rendered view, or memory, it is hypothesis-zero. Look at
  the raw artifact before anything inherits its shape.

Recite the full mantra only if this is also an active debug session. Inside triangulate the
discipline is carried, not performed.

## Step 5 — Shrink (ponytail)

Now, and only now, run [ponytail](../../04-build/ponytail-refined/SKILL.md) on the *implementation*.
The ladder is unchanged: does this machinery need to exist, stdlib, native platform, existing
dependency, one line, minimum code.

Two guards that matter more here than in ponytail alone:

- Ponytail shrinks the **mechanism**, never the requirement, and never the evidence floor from
  Step 2. Trust boundaries, error handling that prevents data loss, security, accessibility, and
  operational controls stay.
- Every seam recon found is either **covered** by the shipped shape or **named** in the card as
  skipped-with-a-trigger. A silently dropped seam is not laziness; it is a bug you have not met yet.

## The card

```
SUBJECT: <the change, one line>
CELL:    <reversible|irreversible> x <contained|crossing>  ->  floor: <none|recon-lite+falsify|falsify|full>
GROUND:  <seams, file:line — or "skipped: <reason>">
FALSIFY: <the load-bearing belief; what disproved it, or what it survived>
SMALLEST:<the shape shipped> — skipped: <X>, add when <Y>
UNKNOWNS:<what would change this answer, and the one command that settles it>
```

Short card in chat. If recon's output is long, the map goes to `recon-<subject>.md` and the card
cites it — long output belongs in the file.

If writing the card would take longer than making the change, the cell was reversible + contained.
Say `triangulate → ponytail only` and go. This is ponytail rung 1 applied to triangulate itself.

## Neighbors

- [recon](../recon/SKILL.md) — the ground pass, Step 3.
- [debug-mantra](../../04-build/debug-mantra/SKILL.md) — the falsification pass, Step 4.
- [ponytail](../../04-build/ponytail-refined/SKILL.md) — rung 1 at Step 0b, the shrink pass at Step 5.
- [swe](../swe/SKILL.md) — grades the resulting plan; triangulate feeds its Pillar 0 and Blast.
```

---

## 4. Install plan (after adjudication)

1. `mkdir -p "<giant-brains>/02-plan/triangulate"` and write the final `SKILL.md`.
2. Symlink `~/.claude/skills/triangulate -> <giant-brains>/02-plan/triangulate`.
3. Remove the stale local `~/.claude/skills/ponytail/` directory (superseded by
   `ponytail-refined`), and — if a `/ponytail` trigger is still wanted — symlink
   `~/.claude/skills/ponytail -> <giant-brains>/04-build/ponytail-refined`.
   **Confirm with the operator before deleting.**
4. Update the giant-brains `README.md` / `REPO_MAP.md` index entry for the new skill.
5. No push without operator approval.

---

## 5. Round 1 disposition (deepseek-v4-pro via dsh → OpenRouter) — verdict: Changes requested

| # | Finding | Disposition |
|---|---|---|
| Q1 | Gate verdict sound; ponytail's "ACTIVE EVERY RESPONSE" is the residual tension | **Implemented** — added as a fourth row in §1's secondary-tension table, resolved by the §2.2 floor. |
| Q2 | Reversible×Crossing floor too low; worked example: rename a utility imported by 20 modules across 2 repos | **Modified** — accepted the finding, changed the fix. Cell is now `recon-lite + falsify` (the seam read is what tells you what to falsify), *and* "reversible" is redefined so cross-repo consumption disqualifies it. That definition is what the example actually exposed. |
| Q3 | Fixed order needs a YAGNI-first exception | **Modified** — added Step 0b, but gated: it may terminate the run only on a fact already held or one command away. Their own example ("50 req/min, DB read 2ms") is a measurement, not a reflex; ungated, rung 1 becomes the guessing the order rule prevents. |
| Q4 | Anti-ceremony reaches too late; "When NOT to fire" should be a pre-step | **Implemented** as proposed — it is now Step 0a, ahead of classification, plus the smaller-than-its-own-sentence guard. |
| Q5 | Placement `02-plan/`, cross-reference paths verified | **Confirmed** — no change. |
| Q6 | Draft violates ponytail: ~10 lines of prose and two aphorisms | **Mostly implemented** — cut "a guess wearing minimalism as a costume", cut "a skill that always fires is a skill nobody reads on the day it counts", cut the "Why the three do not fight" framing. **Declined** the full cut of the pre-table line: one sentence naming the conflict is load-bearing, since it is why the rest of the skill exists. |

Citations spot-checked against this clone: `skills/ponytail/SKILL.md:48`, `skills/swe/SKILL.md:80`,
`skills/xyz/SKILL.md:66-79` all resolve as quoted. The reviewer correctly marked its two
unverifiable claims `[Unverified]` rather than asserting them.

---

## 6. Round 2 disposition (qwen3.8-max via CommandCode) — verdict: Changes requested

| # | Finding | Disposition |
|---|---|---|
| Q1 | Step 0b guard ("a fact you already hold, or one command away") is gameable — "held" licenses memory, "one command away" licenses a command not yet run | **Implemented as proposed.** Replaced with the quote-verbatim form: (a) a statement in the request, or (b) the output of one read-only command run *this session*. "Quote" is the load-bearing word — a verbatim artifact cannot be rationalised. |
| Q2 | The severity count (0/1/2 hits) contradicts its own table: reversible x crossing is `recon-lite + falsify`, strictly more than "one hit -> falsify". Worked example: rename a utility imported by 12 modules in one repo | **Implemented.** Deleted the count line; the cell is now the only authority ("read the floor from the cell, not from a count"). A real self-inflicted inconsistency introduced in rev 2. |
| Q3 | Does the redefined "reversible" kill the `none` cell? | **[Pass]** — it does not. Only *consumed* changes are disqualified; unconsumed work (a new helper nothing imports, a test file, a change behind an unshipped flag) still lands in `none`. |
| Q4 | Step 0a has no precedence rule; "the prod export endpoint 500s, and we suspect the feature never should have shipped" matches two rows and routes wrong | **Implemented as proposed.** Added: "Two rows match: the existence question wins; then a live bug beats a planned change." |
| Q5 | Two aphorisms remain ("the discipline is carried, not performed"; "the easiest dishonest exit in this skill") | **Implemented** — both cut. |
| Q6 | No branch for when falsification *wins* — a task whose load-bearing belief dies in Step 4 falls through to Shrink with a dead premise | **Implemented as proposed.** Best finding of either round. Step 4 now re-classifies or stops rather than proceeding. |
| sweep | `skills/ponytail/SKILL.md:71` is wrong (the text is at :72), and Sec 5's "all resolve as quoted" was therefore false; the quote was also truncated | **Implemented.** Corrected to :72, quote extended, and this note stands as the correction to Sec 5. |
| sweep | Step 0a routes to `spike-360` and `blast-radius`, unverified from that clone | **Resolved, no change.** Both verified present in giant-brains: `02-plan/spike-360/SKILL.md`, `01-decide/blast-radius/SKILL.md`. The reviewer correctly marked it `[Unverified]` from where it stood. |
| sweep | Sec 2.5 lists five routes, Step 0a lists six — drift | **Implemented** — Sec 2.5 superseded by Step 0a; the skill is the authority. |
| sweep | No filled example card; both vendored models calibrate by example | **Implemented.** Added a worked card (the utility-rename case), which doubles as the Q6 illustration — its FALSIFY field shows a belief dying and the decision re-classifying. |

Round 2 also confirmed the gate argument in Sec 1 holds under a full read.

---

## 7. Outcome

Shipped to `<giant-brains>/02-plan/triangulate/SKILL.md`, symlinked at `~/.claude/skills/triangulate`.
Both rounds returned "Changes requested" and both were right; nothing required re-architecture.
The local `~/.claude/skills/ponytail/` directory is **not** deleted — it differs from
`ponytail-refined` (5966 vs 7616 bytes), so removing it loses content. A copy is preserved at
`<giant-brains>/PARKED/ponytail-local-superseded-20260828.md` pending the operator's call.
