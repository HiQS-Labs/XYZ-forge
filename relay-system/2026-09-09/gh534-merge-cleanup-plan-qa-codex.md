---
Goal: Plan QA — GH-534 merge-cleanup failure modes (Phases A, B1, C) before implementation
Date: 2026-09-09
Producer: claude-a
Reviewer: codex
NEXT: codex
STATUS: Open
Round-cap: 3
---

# Context

Adjudicate the plan in `PROJECT/1-INBOX/GH-534-MERGE-CLEANUP-FAILURE-MODES.md` **before** any
implementation. The operator has chosen Phase **B1** (implement the ledger-conflict half) and added
Phase **C** (a decision ladder for conflicts B1 cannot resolve). Base SHA for all claims: `6e304820`.

This is a plan review, not a build turn. Do not edit anything except this file.

Read in full:

- `PROJECT/1-INBOX/GH-534-MERGE-CLEANUP-FAILURE-MODES.md` — the plan under review
- `skills/merge-cleanup/SKILL.md` — what the skill promises
- `skills/merge-cleanup/scripts/merge_cleanup.py`, `scan_clones.py`, `toposort_prs.py` — what it does
- `WORKTREE-SAFETY.md` lines 700–810 — the `SAFE_ROOTS` governance the scripts mirror
- `utils/releases-merge-resolve.sh` — the resolver Phase B1 proposes to drive
- `skills/workhorse/SKILL.md` — the existing decision-ladder shape Phase C copies
- `test/gh1-adoption-guard.sh` — the existing "docs promise X, code must have X" guard shape

Also read the issue thread if reachable: https://github.com/HiQS-Labs/XYZ-forge/issues/534
(two comments: the `WORKTREE-SAFETY.md:783` root-cause addendum and the commit lineage).

# Questions

Answer every one. Cite `file:line` for each claim you confirm or dispute.

1. **Are the six failure modes (A–F) real at `6e304820`?** For each: confirmed / disputed, with the
   line. In particular verify D by grep: is `inspect_tick_claims()` called anywhere? And verify A
   by reading `DEFAULT_SAFE_ROOTS` and `is_safe_deletable_path()`.

2. **Phase A.2 — unpushed → unlanded via `git cherry origin/development <branch>`.** Is this
   sufficient and safe? Specifically: (a) a squash-merge whose conflict resolution *changed* the
   patch — does `cherry` then report `+` (unlanded) for a commit that did land? Is that an
   acceptable false-preserve, or does the check need the PR's merge commit as a second reference?
   (b) Can a genuinely unlanded commit collide on patch-id and read as landed (false-eligible)?
   If either risk is real, state the exact check you would require instead.

3. **Phase A.3 — the regenerable-dirt list** (`harnesses.db`, `harnesses.sql`, `MARATHON-PLAN-*.md`,
   `.playwright-mcp/`, `*.db.bak`). Is any entry a file that could carry real work? Should
   `harnesses.db` be there given it is a committed ledger, not scratch? Propose removals/additions.

4. **Phase A.1 — changing `SAFE_ROOTS` in `WORKTREE-SAFETY.md` first.** Is the governance doc the
   right layer, or should the skill read roots from one config both sides consume? What else in
   the repo reads or is bound by `WORKTREE-SAFETY.md`'s `SAFE_ROOTS` list — is the blast radius
   traced correctly (the plan claims no other script consumer)?

5. **Phase B1 — the automated ledger-conflict flow.** Read `utils/releases-merge-resolve.sh`. Does
   the proposed sequence (disposable clone → `git merge origin/development` → resolver → CLI
   re-apply of branch-only rows → regen → gate → push) match what the resolver actually does and
   expects as input state? Is "ledger-only conflict" reliably detectable as *conflict file set ⊆
   {releases.db, releases.sql, ROADMAP-DASHBOARD.md, LEADERBOARD.md, harnesses.db, harnesses.sql}*?
   What happens on the generation-rewind guard the resolver has (it refused once during #519)?

6. **Phase C — the decision ladder.** The plan says the *script* can only emit a structured
   handoff and enforce a retry cap, while skill invocation is the calling agent's act named in
   SKILL.md. Is that division honest and implementable? Is rung 2 (bounded `/recon` per conflicting
   code file) bounded enough to be safe under an automated run, or should it be caller-only?
   Is the retry cap ("same rung twice") the right stall guard?

7. **Acceptance checks.** Do they detect the actual failures? Is the A.2 red control (a fixture
   whose only "ahead" commit is a squash-merged twin must be eligible; the same fixture with one
   real unlanded commit must be `PRESERVE_UNPUSHED` naming it) sufficient, and does it fail if
   A.2 is reverted? Name any missing check — especially for E (Phase 5 feedback loop) and for the
   new doc/code parity guard.

8. **Collision with in-flight work.** #444 and #523 are open on the same skill and PR #526
   (for #523/#524) touches `merge_cleanup.py` and/or `SKILL.md`. Does this plan collide with
   #526's file set? If you can read PR #526, say which hunks overlap; if not, say so and state
   what the plan must do to avoid a second conflicting PR on the same file.

9. **Rating `75/70/50/40`.** Grounded? The recurrence claim is 3 distinct same-class incidents in
   the last 14 days (#444 09-05, #523 09-09, #534 09-09) vs 0 in the prior 14 (skill landed 09-04).
   Is sev 70 right given D is a latent safety gap with no observed loss? Appeal is neutral 50.

10. **Doc/code parity guard.** The lineage shows two commits widened the doc/code gap (one added
    a guard never called, one added a job never implemented). What is the smallest deterministic
    check that fails when SKILL.md and the scripts drift again — which strings/structures should
    it assert, in the shape of `gh1-adoption-guard.sh`?

Flag anything wrong, missing, mis-scoped, or over/under-engineered. Mark each finding
**Blocking** or **Non-blocking**. Be concrete; cite `file:line` where you disagree.

Write your verdict below. Set `STATUS: Approved` only if no Blocking finding remains; otherwise
leave `STATUS: Open` and set `NEXT: claude-a`.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

# Log
