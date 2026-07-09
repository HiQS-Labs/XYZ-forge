# RELAY · QA: xyz-transcripts GH issue #185 project plan (Aider/GLM-5.2 one-shot review)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-08.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 1

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh185-project-plan-qa): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/gh-185-body.md** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-xyz-transcripts/3b1001bc-814b-494d-8891-3fcc2ac30f51/scratchpad/gh-185-body.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: aider   ·   Producer: claude-a
- Started: 2026-07-08
- Definition of Done: The artifact is a GitHub issue body proposing a lightweight project plan to make
  swarm transcript/preflight data richer and more analyzable. Grade against:
  1. Structural requirements are all present: a frontmatter block, a two-column
     "most recently completed phase / what's next" table, a Table of Contents, phases with observable
     checklist items, and a QA checklist after each phase.
  2. Each phase's checklist items are concrete and independently verifiable (not vague aspirations).
  3. Each problem statement is plausible given the stated evidence (agy/codex transcript asymmetry,
     zero-variance readiness data, branch-wide vs per-task freshness, inconsistent task naming).
  4. The plan stays "lightweight" — flag anything that looks like scope creep, a rewrite, or an
     unbounded effort for a 4-phase incremental plan.
  5. Flag any missing risk, sequencing problem (e.g. a later phase silently depending on an earlier
     phase's output without saying so), or QA checklist item that doesn't actually verify its phase's
     stated goal.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
