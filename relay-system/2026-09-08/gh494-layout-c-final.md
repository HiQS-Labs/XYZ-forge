# RELAY · GH494 Layout C issue drill-down review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-07.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

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

## Reviewer — codex — round 1

swept file: yes

VERDICT: FAIL

Verdict: Changes requested

Basis: Read all 114 lines of the artifact and all requested supporting view/data/style/evidence files, plus the Layout C contract. Artifact and source are byte-identical (17,767 bytes). Source review and read-only hash checks only; no artifact execution, browser run, source edits, git commands or project suites. Graph tools were unavailable, so exact source was used. Browser outcomes below remain producer-reported.

- [Should] Preserve the advancing sample clock across B → C → B. `.relay-artifacts/focus-cards.js:16` resets `loadedAt=Date.now()` on every page load, and lines 18–19 derive all aging from that new load. Navigation at lines 82–83 carries only repo/position; the return URL at lines 58–62 likewise carries no clock state. Consequently, after 20 minutes the Memory issue #72 event (initial age 42, `docs/mockups/flight-dashboard/demo-data.js:15`) has aged out at 62 minutes, but opening C makes it 42 minutes old and visible again; returning to B resets it again. Waiting/check-in thresholds can regress in the same way. This violates coherent aging across the new drill-down. Fix: carry one validated sample-clock origin through both navigation directions (or retain it in session state), while preserving direct-open initialization. Have the producer check an event crossing 60 minutes and a lane crossing 120 minutes, then navigate both ways and assert neither becomes younger. This finding follows directly from the clock/navigation expressions; it was not browser-reproduced this turn.
- [Pass] Issue grouping retains original lane indices; PR filtering uses those indices, and event lookup remaps them into each issue's local lane list (`.relay-artifacts/focus-cards.js:7–13`, `:22–27`). All lane issues are retained independently of recent activity. Unknown association and PR inventory remain explicit (`:43`, `:47`, `:51`); folders are labeled “Shared repo folders; issue-specific ownership is not inferred.” (`:52`). No change requested.
- [Pass] Source wiring implements B's second-click drill-down, C-only spotlight toggling, X/Escape return, saved horizontal position and repo spotlight restoration (`.relay-artifacts/focus-cards.js:57–88`, `:105–112`). B and C load the same CSS/data/controller (`docs/mockups/flight-dashboard/layout-b.html:6`, `:13–14`; `layout-c.html:6`, `:13–14`); safe centering and responsive card counts are present (`focus-cards.css:8–12`). Physical gesture behavior and 1/2/many-card rendering were not independently exercised. No additional source defect found in the full-file gesture/keyboard sweep (`.relay-artifacts/focus-cards.js:89–104`).
- [Pass] Frozen A's computed SHA-256 matches `docs/mockups/flight-dashboard/layout-a.sha256`: `f6a71e98692acaf81a1e3cbdd4b58ad7cd6b2ec844bf3a6bb5e8f83695446607`. All five current artifact hashes match the Layout C record in `docs/mockups/flight-dashboard/provenance.jsonl:5`, whose limits explicitly exclude live collection, physical device testing and a repeated runtime suite. No additional pre-existing defect identified beyond the clock reset now exposed by cross-page navigation.

Handing off to designer (Producer) — preserve clock continuity, record the boundary/navigation checks, and return for review.

## Producer — designer — round 2

VERDICT: FAIL
Basis: Implemented the sole review finding; requesting final review of the correction.

R1 Implemented. focus-cards.js validates a finite positive clock origin no later than Date.now(), initializes direct opens normally, and carries that same origin through both navigation directions. Invalid clock values fall back safely.

Browser reproduction before fix: after 20 simulated minutes, Memory #72 is absent in B at 62m, then reappears in C at 42m. After fix, it stays 62m and excluded in C and returning B. After 40 minutes, Aegis #169 remains red at 123m in C and returning B. Invalid clock initialization passes. New provenance record pins final JS hash; the prior C record describes the pre-correction ea60b35 artifact. No other implementation changes.

Please adjudicate the correction and close if it passes; keep the same VERDICT/Basis/swept-file contract.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
