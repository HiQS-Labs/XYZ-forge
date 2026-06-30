# RELAY · Review: PDDA consolidation (shipped) + GH-61 CI plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-30.
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
6. **Commit only the relay file** (`relay(pdda-consolidation-ci-plan-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Primary artifact under review: **.relay-artifacts/GH-61-CI-GITHUB-ACTIONS.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-61-CI-GITHUB-ACTIONS.md` seeds into the isolated worktree (read it there; do NOT edit it).
- **Also review (read these directly from the repo — you may read any path):** the *shipped* PDDA
  runtime consolidation that landed on `main` this session —
  `decisions/2026-06-30-pdda-runtime-consolidation.md`,
  `PROJECT/2-WORKING/PDDA-RUNTIME-CONSOLIDATION-MIGRATION.md`, the dispatcher `utils/pdda/pdda.sh`,
  the ratings consumer `utils/marathon-plan.sh`, and the integer-rating frontmatter now in
  `PROJECT/**` docs. Verify the migration's correctness/quality as merged.
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-06-30
- Definition of Done — grade against BOTH subjects:
  - **GH-61 CI plan:** the two-tier split is sound; Tier 1 checks (shellcheck/`bash -n`/JSON/`pdda.sh run`)
    are correct and reasonably complete; Tier 2's named risks (BSD-isms + live-agent tests to skip) are
    accurate and complete (call out any missed portability hazard or un-skippable test); the runner
    tradeoff (macos vs ubuntu) is fairly framed; ratings + sequencing notes are reasonable; nothing
    critical is missing for a build agent to execute it safely.
  - **PDDA consolidation (shipped):** the integer-ratings map (`low→2/med→3/high→4`) is defensible and
    preserves `marathon-plan.sh` ordering; dropping `pdda-check-ratings.sh` lost no critical enforcement;
    no live wiring still points at a deleted flat script; the decision record is honest about
    reversibility/revisit. Flag any real correctness or drift bug.
- **Note to Reviewer:** the consolidation already passes `./validate.sh` (exit 0), `pdda.sh run` full-mode
  (0 errors), `test/marathon-plan.sh` 31/31. Don't re-litigate green gates — hunt for what the gates
  *don't* catch (judgment calls, missed references, plan gaps).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
