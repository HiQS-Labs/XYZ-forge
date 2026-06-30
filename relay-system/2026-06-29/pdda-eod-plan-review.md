# RELAY · Review PDDA-EOD plan (GH-6)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-29.
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
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(pdda-eod-plan-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/GH-6-PDDA-EOD.md** — the read-only path that
  `relay-drive.sh --artifact-file /Users/noelsaw/Documents/GH Repos/pdda/PROJECT/2-WORKING/GH-6-PDDA-EOD.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-06-29
- Definition of Done: this is a **project plan** for a `/pdda-eod` end-of-day-wrap skill — grade the
  PLAN's quality, not code. It should be: (1) **complete** — covers the day-wrap scope (hygiene checks,
  ROADMAP/CHANGELOG, doc frontmatter + lifecycle moves, git clean/push, user-verified issue-close,
  dated summary) with no obvious gap; (2) **safe** — mutations are propose-then-confirm with a dry-run
  default, irreversible/outward actions (push, issue-close) individually confirmed, correct ordering
  (push before issue-close); (3) **well-sequenced** — phases independently shippable with a safe
  read-only Phase 1, each phase has concrete verifiable QA-gate checklist items; (4) **aligned with the
  repo's principles** — delegates deterministic work to `pdda.sh` rather than reinventing it (Principle
  #3), one canonical place per fact (#4), stays resumable (#2), non-destructive by default.
  Flag real gaps, safety holes, ordering bugs, vague/untestable QA items, or principle violations.
  Cosmetic wording is `[Nit]`. The plan text is the artifact — judge it as written.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
