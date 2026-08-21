# Relay: GH-111 dialed-in plan — sharpen & QA
STATUS: Open
NEXT: aider (Reviewer)

## Task

Review `PROJECT/2-WORKING/GH-111-DIALED-IN.md` — the plan to retire release-manifest FREEZE and
replace it with a per-task/per-marathon DIALED-IN database state.

**Definition of Done for this review:** the plan's schema changes are sound against the real code
paths (`utils/py/releases_app.py` — schema at :490-520, dump writer :747-756, `load_dump()`
:2602-2612, rebuild migration chain :2649-2650), the state machine and its exclusivity constraint
are correct and safe for existing data, the prose-migration scope is right, and each of the five
"Open items for review" at the end of the doc gets an explicit verdict.

**Highest-value things to attack:**
1. The **partial unique index** on `manifest_items(issue_ref_id) WHERE state='dialed_in'` — does it
   actually give one-release-at-a-time without breaking legitimate history (cut on A, dial into B)?
2. **Migration-number collision** with GH-108's migration 003 (`PROJECT/2-WORKING/GH-108-RATING-SYSTEM.md`),
   which touches `roadmap_items` in the same week. Is the stated "whoever lands second renumbers"
   rule sufficient, or does it need a real mechanism?
3. The **`open` → `dialed_in` rename** of an existing CHECK-constrained state on populated rows —
   SQLite cannot ALTER a CHECK constraint in place. Is the migration actually implementable?
4. Whether folding #109 + #110 into this change is right, or whether it makes one change too big.

**Constraints on findings:**
- The four numbered decisions under "## The decision" are FROZEN operator calls — flag a
  contradiction WITH them, do not relitigate them.
- This is a REVIEW turn: report findings in this relay file only; do not edit the plan doc.
- Rank findings Blocking / Optional / Out-of-scope. Cite doc lines or repo files for each.

## Protocol

Append a `### Round N · Reviewer · aider` block with your findings, then set the `STATUS:` line at
the top of this file to `Approved` or `Changes requested`, and end your block with
`**Verdict:** Approved` or `**Verdict:** Changes requested`.

▶ TAKE YOUR TURN (aider)
