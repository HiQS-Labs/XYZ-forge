---
Goal: QA the HiQS signal-bar rewrite and the counted-once rule in rebalanceOS
Date: 2026-09-04
NEXT: Reviewer
STATUS: Needs Revision
---

# Context

Adjudicate a documentation change in **a different repository** — `HiQS-Labs/rebalanceOS`, a
local-first "workday OS" that ingests Obsidian, GitHub, calendar, email and Slack into one local
SQLite store and serves it to agents over MCP. Branch `fix/alias-dedup-policy`, base `development`.

The full diff and the resulting section are seeded read-only at `.relay-artifacts/hqs-pillars.md`.
**Read it in full first.**

## What prompted this

A GitHub organisation rename put one repository into the `github_activity` table under two
spellings on the same `scan_date`. Every read path that aggregated those rows **summed** them, so a
day with 48 commits and 13 pull requests was reported as **86 and 26** in `top_active_repos`, the
`github_balance` MCP tool, Focus 5, the dashboard and the morning brief. No error was raised.

The test written to catch exactly this inserted the duplicate row with **every metric set to zero**,
so summing it changed nothing and the test always passed. It could never have failed.

Two things already landed on this branch and are **not** what you are reviewing: `SOP.md` §6 (the
policy), and `tests/test_alias_dedup_invariant.py` (a config-agnostic invariant test with synthetic
org names). They are shown in the artifact only as context.

## What you ARE reviewing

The rewrite of `GUIDING-PRINCIPLES.md`'s "signal bar":

- The four pillars are restated in the operator's canonical wording, and **RELEVANT is renamed
  RANKED**.
- A new subsection, *"Counted once — the fifth thing each pillar assumes"*, argues that
  de-duplication is **not** a fifth pillar but a precondition of the other four, and walks each one.
- It states an enforcement order: **detected, blocked, not counted**.
- Two stale "Relevant" references elsewhere in the doc are renamed, and a ninth review heuristic is
  added.

# Questions

Answer each directly. Cite `file:line` where you disagree. Be concrete.

1. **Is "counted once is a precondition, not a fifth pillar" actually right?** Or is it a rhetorical
   dodge that will let people skip it because it is not on the numbered list? Argue the other side
   before you agree.

2. **Are the four per-pillar arguments sound, one by one?** Specifically the FRESH claim: *"summing
   adds a stale partial snapshot to the current one. The stale copy does not decay — it
   accumulates."* Is that a correct description of what happens on a snapshot table, or is it
   stretched to make the pillar fit?

3. **Is renaming RELEVANT to RANKED a net win or a loss?** "Relevant" and "ranked" are not synonyms —
   relevance is about *whether* a signal belongs, ranking is about *order*. Does the rename lose a
   property the doc previously asserted? Check whether anything else in the repo depends on the old
   word (`PROJECT/4-MISC/GH-101-SIGNAL-QUALITY-CONTRACT.md` uses it).

4. **Is "detected, blocked, not counted" the right decomposition,** and is the doc right that all
   three are required? Could any be dropped without loss?

5. **Does this belong in `GUIDING-PRINCIPLES.md` at all,** given `SOP.md` §6 already holds the full
   policy? The repo's own worst recurring defect is duplicated docs that drift
   (`ROUTER.md` opens with a warning about it, and heuristic 5 says "no duplicated docs"). Is this
   section a second copy that will drift from §6, or is the split defensible — principles state
   *why*, SOP states *how*? If it will drift, say what should be cut.

6. **Is the prose too long?** The subsection is ~15 lines in a doc whose other principles are one
   line each. Should it compress, and if so what goes?

7. **Anything factually wrong, overclaimed, or missing?** In particular: is the doc right that
   `UNIQUE(...) ON CONFLICT REPLACE` "settles it without an opinion"?

Flag anything wrong, missing, mis-scoped, or over/under-engineered. If it is sound, say so plainly
and set `STATUS: Approved`. This is a **review-only** turn — do not edit any file other than this
relay file.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (deepseek)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Review (deepseek)

### 1. Precondition vs. fifth pillar — mixed verdict

**The argument is structurally correct but its presentation undermines it.** You are right that counted-once is cross-cutting in a way the four pillars are not: each pillar is a *positive property of a signal* (attestedness, ordering, freshness, structure), whereas counted-once is a *constraint on the aggregation pipeline*. They are different categories, and adding it as a fifth numbered pillar would make the list heterogeneous.

**The other side I must argue before agreeing:** The subsection heading itself is "the fifth thing each pillar assumes" — that's a fifth thing. The "Applying this" line (artifact line 110) now reads "Attested, Ranked, Fresh, Structured, **and counted once**" — placing it in the same enumeration as the four pillars. The review heuristic 9 (line 120) is a separate checklist item alongside the four-pillar heuristic 8. Everywhere a reader looks, this is treated as a fifth pillar *in practice* while the text says *in principle* it is not. This contradiction will cause readers to mentally categorize it as "the fifth pillar that the doc pretends is not a pillar" — the worst of both worlds, because it's longer than the other four but the author is on record disclaiming its status.

**Recommendation:** Either commit to it being a fifth pillar (restructure the list to five numbered items, accept the heterogeneity) or commit to it being a precondition and *remove* it from the Applying-this line and heuristic 9 — those are the places where it actually *is* treated as a fifth pillar. The subsection itself is fine as a precondition argument.

### 2. Per-pillar arguments — three solid, one stretched

**ATTESTED** (line 90): Sound. A number that disagrees with its receipts fails the most basic requirement of carrying evidence. The argument is tight and concrete.

**RANKED** (line 91): Sound. Inflating one row's count reorders the entire list. This is a crisp, falsifiable claim.

**FRESH** (line 92): **Stretched.** The argument is technically correct but retrofits the pillar. The fundamental defect is *double-counting*, not *staleness*. If both scans happened at the same instant on the same snapshot, the double-counting would still be a defect, but it would not be a FRESH problem. The FRESH argument works only because the two scans happened at different times, making one stale — but the staleness is an incidental property of this particular failure mode, not the essence of the defect. This is the weakest of the four arguments, and an informed reader will spot the retrofit.

**STRUCTURED** (line 93): Sound. Two spellings of the same entity are two shapes for one thing. This is the cleanest fit — duplicate rows are literally a structural problem.

**Recommendation:** Tighten the FRESH argument. The real argument is: "summing a stale row into a current one means the aggregate is neither fresh nor stale — it is a corrupted composite that no scan time can represent." That is stronger than "the stale copy does not decay" (which is true of any snapshot row, stale or not) and avoids the retrofit appearance.

### 3. RELEVANT → RANKED — net win, with one footnote

**Win.** The old heading "Relevant" said something different from its definition ("ranked, not dumped"). The rename makes the heading match the definition. This is a strict improvement in clarity.

**One loss to note:** "Relevant" carried a connotation of *selection for relevance* — not just ordering, but filtering out what does not belong. "Ranked" alone could be interpreted as "any ordering" (alphabetical, chronological, arbitrary). The new description "ordered by what your team actually owes" does imply relevance-based ordering, but the heading alone has lost the selection signal. This is minor and unlikely to cause confusion in context.

**Regarding GH-101-SIGNAL-QUALITY-CONTRACT.md:** I cannot check that file (it is in the rebalanceOS repo, not this one). The question itself flags it as a potential dependency. If that contract uses the term "Relevant" as a pillar name, the rename will break the cross-reference. The reviewer should verify and update that contract before this lands.

### 4. "Detected, blocked, not counted" — sound, but the ordering is debatable

**All three are required.** The decomposition is the strongest part of the section. Each step addresses a different failure mode:

| Step | Failure mode | What it catches |
|------|-------------|-----------------|
| Detected | Regression | A test that can go red |
| Blocked | Read-time aggregation | Prevents wrong numbers from being published |
| Not counted | Write-time persistence | Leaves no wrong rows for any consumer |

**Could any be dropped?**
- Drop "Detected" and you cannot tell when the schema has a gap or a new alias type emerges. It is the only proactive step.
- Drop "Blocked" and a consumer that reads before the store is cleaned up sees wrong numbers. The read path is the most-trafficked surface.
- Drop "Not counted" and the store remains wrong for every consumer that does not use the canonical read path (MCP tools, dashboards, exports). The doc's own argument for this is correct.

**Ordering question:** The doc says "in that order." But operationally, "Blocked" (read path) and "Not counted" (store) are concurrent or write-first, not sequential. Detection can run independently. The ordering is logical for a mental model, not chronological. If the doc intends the order of implementation priority, it should say so; if it means chronological order, it is wrong (the schema fix comes first).

### 5. Split between GUIDING-PRINCIPLES.md and SOP.md — defensible but fragile

**The split is defensible in principle:** GUIDING-PRINCIPLES states *why* a principle exists; SOP states *how* to apply it. The principles doc explains the reasoning (per-pillar, precondition argument), the SOP has the operational policy.

**In practice, it is fragile for the exact reason heuristic 5 exists.** Two docs now describe the same concept. The diff shows 54 lines of SOP and ~15 lines of GUIDING-PRINCIPLES — that is a lot of surface area to keep in sync. The concrete risk: if someone updates the SOP's enforcement order but forgets to update the GUIDING-PRINCIPLES version, or vice versa, the docs will disagree.

**What should be cut to reduce drift risk:** The enforcement order ("Detected, blocked, not counted") and the three numbered steps (lines 96-99) belong in the SOP, not the principles doc. The principles doc should state *that* counted-once is a precondition, *why* it is not a fifth pillar, and *that* there is an enforcement order in the SOP — but not describe the order itself. This would cut the drift surface by ~40%.

### 6. Prose length — yes, too long, but the right things are long

The subsection is ~15 lines vs. 1 line per pillar. **It should be compressed, but not by removing substance.** Three compression strategies:

1. **Move the live-failure story (lines 100-101) to a footnote or the SOP.** It is compelling but narrative, and narrative is what principles docs should not be. A one-sentence capstone ("This is written from a live failure — see SOP.md §6.") would lose only colour.
2. **Condense the per-pillar walkthrough to one line:** "A doubled count fails all four pillars — see the walkthrough in SOP.md §6." The current walkthrough is persuasive but duplicates what the SOP could say.
3. **Keep the enforcement order heading but drop the numbered steps** (as recommended above — move them to the SOP).

Target: ~8 lines, which is still verbose for this doc but not disproportionate.

### 7. Factual accuracy — one overclaim, one gap

**Overclaim:** `UNIQUE(...) ON CONFLICT REPLACE` "settles it without an opinion" (line 98, artifact line 154). This is not accurate. The mechanism encodes a definite opinion: "the last write wins." If the canonical name was written first and the alias was written second, the alias replaces the canonical row — that is the wrong outcome. The doc is correct that the schema enforces deduplication, but calling it "without an opinion" attributes a neutrality to the mechanism that is not warranted. The opinion is "last write wins," which is a choice, not an absence of choice.

**Gap:** The doc says "reads canonicalise before grouping" (line 98) but the enforcement mechanism described is a *write-time* UNIQUE constraint (schema). The read path's canonicalization is asserted but not described. If the read path does not actually canonicalize aliases before grouping, the UNIQUE constraint on the write path only prevents future duplicates — it does not fix existing ones or help a consumer that reads across multiple rows that happen to be unique. The doc should either describe the read-path canonicalization or acknowledge that it is the schema (write path) that does the blocking, not the read path.

**Missing:** The `ON CONFLICT REPLACE` hazard — renaming a row onto an existing key silently destroys the row already there — is mentioned in the SOP reference (line 101) but not in the principles section. A reader of the principles doc alone would miss this. The principles doc should either mention it or explicitly tell the reader to see the SOP for the hazard.

### Summary

| Question | Verdict |
|----------|---------|
| 1. Precondition vs. fifth pillar | Right in principle, undermined by presentation (Applying-this line, heuristic 9) |
| 2. Per-pillar arguments | Three sound; FRESH is stretched and needs tightening |
| 3. RELEVANT → RANKED | Net win; check GH-101 cross-reference |
| 4. Detected, blocked, not counted | Sound decomposition; ordering is logical not chronological |
| 5. Belongs in GUIDING-PRINCIPLES? | Defensible but fragile; move enforcement order to SOP |
| 6. Prose length | Too long; compress by moving narrative and enforcement steps to SOP |
| 7. Factual accuracy | One overclaim (UNIQUE "without an opinion"), one gap (read-path canonicalization undescribed), one missing hazard (ON CONFLICT REPLACE destruction) |

**Overall: needs revision before approval.** The structural argument is correct and the enforcement order is the strongest part. The three concrete issues to fix before landing: (1) resolve the "fifth pillar in practice but not in principle" contradiction, (2) tighten the FRESH argument, (3) correct the "without an opinion" overclaim and describe the read-path canonicalization. The GH-101 cross-reference should be checked by the author.
