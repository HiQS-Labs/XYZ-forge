# RELAY · GH-12 durability hardening — plan QA before implementation
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-08-04.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(gh12-durability-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `PROJECT/2-WORKING/GH-12-DURABILITY-HARDENING.md` — a **6-phase implementation
  plan**, reviewed **before any code is written**. The whole repo is readable in your worktree; the
  plan cites specific `file:line` locations and **you should open those files and check the claims**.
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-08-04
- Context: repo is AEGIS (Sleuth), a Slack reminder bot in daily production use for ~2.5 years across
  7 workspaces. Persistence is mutable JSON. Tracking issue: #12. This plan closes a durability hole
  that `HONEST.md:77/115/128` and `README.md:135-141` already admit publicly.

- Definition of Done — grade the plan against these, in priority order:
  1. **Are the Phase 0 findings factually correct?** Open the cited files. Specifically verify:
     (a) there really are zero `fsync`/`fdatasync` **call sites** in `src/`;
     (b) `reminders-module.js:2846-2864` `#SaveRemindersAsync` really does a bare full-file write;
     (c) `#DataLoaded` really is **never read by any writer** (the claimed silent-clobber cascade) —
         this is the load-bearing claim of the whole plan; if it's wrong, the plan is mis-scoped;
     (d) `completion-store.js:194-200` has the same shape;
     (e) `event-store.js` really is append-only AND `readAll` really tolerates a torn final line.
  2. **Is the tier ranking right?** The plan asserts the reminder queue is the biggest blast radius
     and the event ledger the smallest, correcting `HONEST.md:128`. Argue it or refute it.
  3. **Is the proposed fix correct and sufficient?** temp → `fsync` file → `rename` → `fsync` parent
     dir. Any correctness hole? Consider: rename atomicity guarantees, the `.tmp` on a different
     filesystem, crash *between* rename and dir-fsync, concurrent writers to the same path, and
     whether `#WriteChain` composition survives.
  4. **Is the quarantine guard right?** Plan distinguishes `ENOENT` (must still save — fresh install)
     from parse-failure (rename to `.corrupt-<ts>` before allowing a save). Any way this misfires,
     loses data, or bricks a workspace?
  5. **Is the phasing safe and correctly ordered?** Each phase independently shippable and reversible?
     Is Phase 1 really zero-blast-radius? Should anything be resequenced?
  6. **Are the QA gates real gates** — i.e. would they actually catch a regression, or are they
     box-ticking? Call out any gate that can't fail.
  7. **What's missing?** Anything the plan doesn't cover that it must before code is written.
     (Out of scope by explicit declaration: datastore migration, P3 event-sourcing cutover, load
     testing. Don't spend the turn re-litigating those non-goals.)

  Verdict `Approved` only if you'd be comfortable with someone implementing all 6 phases from this
  doc as-written. **Do not edit the artifact or any source file — append findings to this file only.**

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
