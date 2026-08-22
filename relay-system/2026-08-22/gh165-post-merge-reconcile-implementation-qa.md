# RELAY · GH-165 Post-Merge Wave Reconciler — Implementation QA Review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded on 2026-08-22.
-->

NEXT: deepseek
STATUS: Open
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy, DeepSeek)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). **Review the whole implementation, not just the summary.**
     Declare it: every review block must contain a literal `swept file: yes` or `swept file: no` line.
     Any `[Pass]` or "verified"/"confirmed" finding MUST carry a quoted span or a `file:line` citation.
     Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh165-reconcile-impl-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first**. End your turn by naming who acts
   next and what they should do.

## Setup
- Artifact under review: **GH-165 Implementation** (`utils/py/wave_reconcile.py`, `test/wave-reconcile.sh`, `test/gh165-governance-canonical-paths-guard.sh`).
- Reviewer: deepseek   ·   Producer: antigravity
- Started: 2026-08-22

### Definition of Done for GH-165 Implementation
1. **Canonical Engine (`utils/py/wave_reconcile.py`):** Direct Python executable (no wrapper `.sh` shim per GH-551) acting as the sole post-merge lifecycle transition bridge.
2. **Merged PR Authority:** Moves active docs to `3-COMPLETED/` and derives badges strictly from merged PR metadata (`number`, `mergedAt`) on `development`. Asserts presence of `## Lessons Learned (For Future Agents)`. Routes unmerged/declined docs to `4-MISC/`.
3. **Hermetic Non-Mutating Dry-Run:** `--dry-run` performs zero network calls, cache writes, DB writes, or generated-file writes, proving byte-identical working tree state upon exit.
4. **Fail-Closed & Atomic Rollback:** Rejects dirty working trees (`git status --porcelain`) and rolls back all modifications via snapshot journal on any failure.
5. **Anti-Sprawl Static Guard:** `test/gh165-governance-canonical-paths-guard.sh` verifies in CI that no script outside `wave_reconcile.py` mutates docs, ROADMAP, or releases.
6. **Test Coverage:** All 9 assertions in `test/wave-reconcile.sh` and 4 assertions in `test/gh165-governance-canonical-paths-guard.sh` pass cleanly.

---

## Log

### Turn 1 — Producer (antigravity) — r1

**Artifacts ready for QA review:**
1. [`utils/py/wave_reconcile.py`](utils/py/wave_reconcile.py): Python reconciler with preflight porcelain checks, rollback journal, multiline ROADMAP entry preservation, and downstream view rebaking.
2. [`test/wave-reconcile.sh`](test/wave-reconcile.sh): 9-assertion fixture test suite.
3. [`test/gh165-governance-canonical-paths-guard.sh`](test/gh165-governance-canonical-paths-guard.sh): 4-assertion static guard.
4. [`PROJECT/1-INBOX/GH-165-POST-MERGE-WAVE-RECONCILER.md`](PROJECT/1-INBOX/GH-165-POST-MERGE-WAVE-RECONCILER.md): PDDA capture doc.

**Hand-off:** DeepSeek to review the implementation code against the Definition of Done and record structured findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`) and Verdict.

<!-- NEXT TURN APPENDS ABOVE THIS LINE -->
