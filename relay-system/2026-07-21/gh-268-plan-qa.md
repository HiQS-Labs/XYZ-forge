# RELAY · QA: GH-268 beta onboarding/build-quality remediation plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-21.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(gh-268-plan-qa): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/GH-268-BETA-ONBOARDING-BUILD-QUALITY-REMEDIATION.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-268-BETA-ONBOARDING-BUILD-QUALITY-REMEDIATION.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-21
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer (agy) — Round 1

**Verdict:** Changes requested

**Findings:**
- `[Blocker]` **Missing Definition of Done in the relay file:** The Setup block in this relay file has an empty `Definition of Done` (`file:34`). *Fix:* Fill in the acceptance criteria in the Setup block (e.g. "Plan passes SWE skill review and all 9 report items are addressed") so this loop has a clear termination condition.
- `[Should]` **SWE Frontmatter gap:** The plan's frontmatter is missing the mandatory `reversibility` field required by the SWE skill. *Fix:* Add `reversibility: Easy | Costly | One-way door — <one line of why>` to the frontmatter.
- `[Should]` **SWE Phase Goal formatting:** Phases lead with "Intent:" instead of the required `**Goal:** <one observable outcome>`. *Fix:* Change "Intent:" to "**Goal:**" across all phases.
- `[Should]` **SWE QA checklist missing:** The per-phase "Definition of done" blocks omit the mechanical SWE checks (Diagnosable, Blast, status table update). *Fix:* Rename to `Phase X — QA checklist` and append the standard SWE checkboxes to ensure phases are checked against the 4 pillars.
- `[Pass]` **Status table format:** The status table is correctly formatted with exactly two columns and one row (`file:36`).
- `[Pass]` **Checklist format:** Standard `- [ ]` syntax used throughout (e.g., `file:55`).
- `[Pass]` **Scope & Coverage:** The plan accounts for all 9 beta test findings across its 4 phases (2 blocking in Phase 1, 4 in Phase 2, 2 in Phase 3, 1 re-test in Phase 4). See Goal statement at `file:27`.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
