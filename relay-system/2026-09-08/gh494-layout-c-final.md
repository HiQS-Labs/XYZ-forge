# RELAY · GH494 Layout C issue drill-down review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-07.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh494-layout-c-issue-drill-down-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/focus-cards.js** — the read-only path that
  `relay-drive.sh --artifact-file docs/mockups/flight-dashboard/focus-cards.js` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: designer
- Started: 2026-09-07
- Definition of Done: B first click spotlights, second click opens C for that repo. C shares tall-card styling and swipe logic, groups sample lanes by issue, shows correct activity/agent/next action/PRs, retains quiet and unknown context, and returns via X/Escape to B repo and scroll. Frozen A unchanged; light/dark themes deferred.
- Read fully docs/mockups/flight-dashboard/{focus-cards.js,focus-cards.css,layout-b.html,layout-c.html,demo-data.js,LAYOUTS.md,provenance.jsonl} and the Layout C section of PROJECT/2-WORKING/GH-494-FLIGHT-DASHBOARD.md. Current index and frozen A were not changed; verify A hash only.
- Questions: (1) Do issue grouping and retained sourceLane joins correctly attribute events and PRs without inventing issue-owned folders? (2) Are navigation, return state, spotlight, and drag/touch/keyboard semantics coherent? (3) Does extraction preserve B and is C usable with 1/2/many cards, unknown/invalid repo and aging data? (4) Are evidence limits honest and the implementation bounded to the HTML mockup?
- Review only; no source edits, git commands, suite execution or unrelated governance work. Driver owns commits and handoff. Use source citations; browser evidence is producer-reported. Append one review block with literal swept file: yes, a standalone VERDICT: PASS or VERDICT: FAIL, and Basis: text. Set STATUS: Approved only for PASS, otherwise leave Open and name actionable defects. Return NEXT: Producer.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
