---
Goal: QA the HiQS signal-bar rewrite and the counted-once rule in rebalanceOS
Date: 2026-09-04
NEXT: Reviewer
STATUS: Changes Requested
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

# Review Findings (agy)

1. **Is "counted once is a precondition, not a fifth pillar" actually right?**
Yes, it is factually correct. **Argument against:** keeping it off the main list might cause it to be skipped. However, the doc mitigates this by explicitly appending it to the "Applying this" checklist (L110) and adding it as heuristic 9 (L120). It genuinely is a precondition—duplication breaks the core assumptions of the other pillars rather than being an independent quality metric.

2. **Are the four per-pillar arguments sound, one by one?**
- **ATTESTED**: Sound (L90). Receipts (source data) don't match the inflated aggregate.
- **RANKED**: Sound (L91). An inflated count artificially reorders the list.
- **FRESH**: Sound (L92). *"The stale copy does not decay — it accumulates."* accurately describes a snapshot table failure: an older row from a previous org name persists and sums alongside the new row.
- **STRUCTURED**: Stretched (L93). *"Two spellings of one entity are two shapes for one thing"* is a reach. "Structured" is defined as "Clean to read, ready to feed your agents" (L81) — this refers to data format/schema (e.g., no screenshot parsing). Having two rows for the same entity is a normalization failure, not a structural format failure.

3. **Is renaming RELEVANT to RANKED a net win or a loss?**
It is a **net loss**. "Relevant" acts as a filter (does this belong at all?), whereas "Ranked" only implies sorting (what order does it go in?). The doc claims "Volume is not value," which requires filtering. Furthermore, changing the name breaks existing references (e.g., `PROJECT/4-MISC/GH-101-SIGNAL-QUALITY-CONTRACT.md`), creating drift across the repo.

4. **Is "detected, blocked, not counted" the right decomposition?**
No, it conflates read-time and write-time concerns. "Blocked" (L98) claims "Reads canonicalise before grouping" (read-time) but justifies it with "UNIQUE(...) ON CONFLICT REPLACE" (a write-time schema constraint). If the schema replaces the row on write, the read path has no duplicates to canonicalise.

5. **Does this belong in `GUIDING-PRINCIPLES.md` at all?**
Only the "why" (how duplication breaks the four pillars) belongs here. The "how" (the 1-2-3 list of Detected/Blocked/Not Counted and the live failure anecdote in L95-L101) belongs in `SOP.md` §6. Keeping execution details here violates heuristic 5 ("No duplicated docs") because it creates a second copy that will drift from the SOP.

6. **Is the prose too long?**
Yes. The core principles are one-liners, making this 15-line subsection disproportionately long. It should be compressed by cutting the 1-2-3 execution steps and the anecdote, leaving only the explanation of the precondition and a pointer to `SOP.md` §6.

7. **Anything factually wrong, overclaimed, or missing?**
Yes. The claim that `UNIQUE(...) ON CONFLICT REPLACE` "settles it without an opinion" (L98) is factually wrong in the context of the GitHub org rename mentioned in L101. If the unique constraint includes the org/repo name, a rename changes the key, meaning `ON CONFLICT REPLACE` will *not* trigger (it will insert a duplicate, which is exactly what happened). The constraint only "settles it" if it relies on an immutable ID, which the doc fails to specify.

STATUS: Changes Requested

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (agy)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
