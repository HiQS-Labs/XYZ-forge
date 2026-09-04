---
Goal: Sharpen the GH-421 plan after a Codex pass — second reviewer, different lens
Date: 2026-09-04
NEXT: Reviewer
STATUS: Open
---

# Context

`PROJECT/1-INBOX/GH-421-AUTO-WAVE-RECONCILE.md` has already been through one review round with
Codex. **All seven of its findings were verified against the code and adopted**, and the plan was
rewritten — including one that reversed the plan's central claim (that Phase 1 could be built from
verbs that already exist; it cannot, because `status_marker` has no CLI writer).

This is a **review turn** — report, do not edit. Cite `file:line` where you disagree.

Your job is **not** to repeat that pass. The easy findings are gone. Your job is to find what a
careful first reviewer *and* a careful author both still missed, and to push back on anything the
first round got wrong or over-corrected.

Read in full:

- `PROJECT/1-INBOX/GH-421-AUTO-WAVE-RECONCILE.md` — the revised plan
- `relay-system/2026-09-04/gh421-auto-reconcile-plan-qa.md` — the Codex round, so you do not repeat it
- `utils/py/wave_reconcile.py` — the tool being automated
- `utils/py/releases_app.py` — the ledger CLI (esp. `roadmap update` / `repoint` / `manifest ship`)
- `AGENTS.md` §13, `GUIDING-PRINCIPLES.md`, `SOP.md` — the house rules the plan claims to follow

Repo context to assume: releases-mode repo, `releases.db` (via `releases.sql`) is planning truth,
`ROADMAP.md` is frozen legacy, every ledger write goes through `releases_app.py` — never direct SQL.

# Questions

Answer each explicitly. "Agree with Codex" is not an answer — say what Codex and the author both
missed, or where they are wrong.

1. **The new scope — a lifecycle write verb.** Phase 1 now requires either extending
   `roadmap update` with a marker argument or adding a purpose-built verb. **Which, and why?**
   Consider: `status_marker` currently only ever arrived by parsing a markdown line
   (`releases_app.py:3475-3534`). Is deriving the marker from `raw_text` reintroducing the
   markdown-as-schema coupling this whole arc exists to remove? Argue for an explicit
   `--status-marker` enum instead if that is the better call. Name the exact CLI shape you would
   ship.

2. **Is Phase 1 now too big to be one phase?** It grew a CLI verb, a manifest lookup, and a
   rollback-boundary change. Should the ledger-CLI work split into its own issue that #421 depends
   on — the way #423 was split out of #418 in this same arc? Give a yes/no and the split line.

3. **Atomicity across two CLI processes.** The plan says "snapshot before the first new mutation, or
   wrap the lifecycle in one transaction." But `manifest ship` and the roadmap write are **separate
   `releases_app.py` invocations**, each with its own connection and its own `perform_write` receipt.
   A single transaction across both is not available without a new batch verb. Is the journal
   snapshot genuinely sufficient? What does the receipt chain look like after a rollback that
   discards a committed `manifest-ship` receipt — does `releases check` still pass, or does the
   chain break? This is the question I most expect to have gotten wrong.

4. **Does the catch-up scan need a persisted "reconciled" marker?** The plan proposes reconciling
   "any merged-but-unreconciled PR" as a backstop past `queue: max`'s 100. How does a run *know* a
   PR was already reconciled, given the reconciler is idempotent but not free? Is there existing
   state for this, or is the plan quietly requiring a new one? If new, that contradicts its own
   non-goal.

5. **Is `--gate`'s disposition right?** The plan resolves it as "do not use in Phase 2, fix
   separately," on the grounds that `check_provenance_receipts` (`wave_reconcile.py:281-298`) never
   compares `pr_num`. Is deferring correct, or does shipping automation without any provenance gate
   create a worse hole than a weak gate? Should the broken check be filed as its own issue rather
   than left as a paragraph in this plan?

6. **What breaks the first time this runs for real?** Not design critique — operational. Walk the
   first automated reconcile end to end on this repo as it exists today and name where it stops.
   Include anything about the current `development` state, the 24 pending grandfather entries, or
   the 8 standing `releases check` warnings that would surprise an unattended run.

7. **Anything Codex got wrong or over-corrected?** It was adopted in full. Push back if any of it
   was mistaken, or if adopting it made the plan worse.

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete and cite
`file:line`.

Write your verdict below. Set `STATUS: Approved` only if the plan is implementable as written.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (agy)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->
