# RELAY · GH494 Layout B final design review
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
6. **Commit only the relay file** (`relay(gh494-layout-b-final-design-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/layout-b.html** — the read-only path that
  `relay-drive.sh --artifact-file docs/mockups/flight-dashboard/layout-b.html` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: designer
- Started: 2026-09-07
- Definition of Done: Requested Layout B initial HTML design: three tall repo cards fully visible at 1920x1080 with two faded edge peeks, no persistent controls beyond cards and X, X opens saved Layout A, last-hour event/issue scope, agent context, checkout names/counts, quiet and unknown repos retained, swipes and keyboard/mouse usable. Exact Layout A preservation was committed/pushed separately.
- Read docs/mockups/flight-dashboard/{layout-b.html,demo-data.js,index.html,layout-b-verification.json,LAYOUTS.md,provenance.jsonl} and the Layout B section of PROJECT/2-WORKING/GH-494-FLIGHT-DASHBOARD.md. The frozen layout-a.html must match layout-a.sha256; only verify its hash, do not expand scope to re-review the unchanged A source.
- Questions: (1) Does B meet the user’s agreed three-card-only visual and X contract? (2) Do event-to-lane-to-issue joins and 0 <= age < 60 filtering avoid misleading activity? (3) Are scroll snap, drag, native touch/trackpad, parallel two-touch handler and pinch handoff coherent without intercepting vertical card scrolling? (4) Any defect from extracting shared fixtures into current index and B? (5) Is frozen A unchanged and evidence clear about simulated hardware testing?
- Browser checks already exercised direct one/two-contact input, pinch, wheel, mouse, keyboard, count/age boundaries and responsive layout. No physical trackpad claim. The native two-contact red control moved only 15px; fixed handler moved a full card. Review all changed source, but do not run suites, spawn reviewers or edit artifacts. No future Swift/collector work.
- Append concise cited findings plus standalone VERDICT: PASS or VERDICT: FAIL, Basis: ..., swept file: yes. Set STATUS Approved if approved. Harness commits, no git commands.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer · codex · Round 1

swept file: yes

- [Should] **R1 — preserve amber lane health independently of recent activity.** `.relay-artifacts/layout-b.html:33` uses `Math.min(...known.map(progressAge))` to choose amber, so the shipped Aegis fixture (Claude 83m, Codex 18m; `docs/mockups/flight-dashboard/demo-data.js:12`) renders green “Recent progress.” Its older lane also disappears because `waitingMarkup` only includes >=120m (`.relay-artifacts/layout-b.html:37`). The carried-forward contract uses the worst fresh known lane; current entry implements red > amber > unknown > green (`docs/mockups/flight-dashboard/index.html:54` and `:55`). Fix: determine health from all lanes, keeping latest progress as a separate timestamp, and retain the 60–119m lane's check-in context outside “Issues active this hour.” Check mixed 83m/18m and 59/60/119/120 boundaries; a recent event must not clear amber.
- [Should] **R2 — retain agent context when a lane has no last-hour event.** Agents/tasks appear only in event/issue rows or >=120m waiting rows (`.relay-artifacts/layout-b.html:35`, `:36`, `:37`, `:38`). Orion's existing Codex indexing lane (`docs/mockups/flight-dashboard/demo-data.js:16`) therefore has only an agent count and generic missing-data copy, with no agent name/task to reconnect with. A known lane aged 60–119m has the same omission. Fix: retain compact lane context inside the card, separate from last-hour issues; show the agent/task and quiet/unknown state, and label any historical/unconfirmed issue accordingly. Check Orion and a lone 60m lane without admitting either to active-hour issues.
- [Pass] Cards/X structure and intended geometry are present: three-card width calculation, edge-only mask, inner vertical overflow, responsive one-card fallback, and initial offset (`.relay-artifacts/layout-b.html:7`, `:10`, `:13`, `:56`); X explicitly targets `layout-a.html` (`:18`). Browser geometry remains producer-reported evidence (`docs/mockups/flight-dashboard/layout-b-verification.json:11`–`:14`), not a new visual run this turn.
- [Pass] Event attribution uses the explicit lane, excludes unknown/null progress, applies `0 <= age < 60`, and deduplicates issues from those filtered events (`.relay-artifacts/layout-b.html:31`–`:32`). Rebalance's old #196 is separated from recent #194 by the fixture and waiting path (`docs/mockups/flight-dashboard/demo-data.js:11`; `.relay-artifacts/layout-b.html:37`).
- [Pass] Keyboard/mouse paths and parallel-touch/pinch separation are present (`.relay-artifacts/layout-b.html:41`–`:55`). The recorded gesture checks explicitly limit their claims to synthetic Chromium inputs, with no physical trackpad/iOS test (`docs/mockups/flight-dashboard/layout-b-verification.json:29`–`:45`). No independent gesture execution performed here.
- [Pass] Read-only SHA-256 checks match frozen A's `f6a71e98…46607` in `layout-a.sha256:1`, B's `0f6fa88b…64b3f`, shared data and current entry hashes in `docs/mockups/flight-dashboard/layout-b-verification.json:3`–`:8`, and the verification receipt hash in `docs/mockups/flight-dashboard/provenance.jsonl:3`. The seeded artifact and canonical B are byte-identical by hash. Shared definitions load before their consumers (`docs/mockups/flight-dashboard/index.html:46`; `.relay-artifacts/layout-b.html:21`). No additional defects found in the fully read current entry or shared fixtures; frozen A source was not re-reviewed.

Verdict: Changes requested
VERDICT: FAIL
Basis: R1 and R2 leave the carried-forward lane warning/context contract incomplete. Whole-file static review of B, current entry and shared fixtures, plus supplied evidence and local hash checks. This isolated checkout has no listed graph index; direct source was used. No artifact/source execution, suites, source edits, or git commands.

Handing off to designer (Producer) — address R1/R2, refresh focused evidence, and take the next turn.

## Producer · designer · Round 2

VERDICT: FAIL
Basis: Both review findings reproduced before the fix and pass afterward; requesting fresh review.

R1 Implemented: health precedence uses all known lanes (red, amber, unknown, green), while latest progress remains a separate timestamp. All lanes without an in-hour event retain context; 60–119 minute lanes use an amber check-in note outside active-hour issues.
R2 Implemented: Orion retains Codex / Indexing experiment and an explicitly unconfirmed #28 association. A lone 60-minute lane retains agent/task and older issue context, never in active-hour issues. Younger lanes without event records use “No event recorded this hour” rather than mislabeling their age.

Browser controls: pre-fix Aegis amber=false, Orion agent=false; after both true. Boundary colors 59/60/119/120 are green/amber/amber/red. Lone quiet agent context and active-hour exclusion pass. Verification/provenance hashes refreshed; frozen A unchanged. No changes to gesture logic.

Please adjudicate R1/R2 and sweep the final changed files, keeping the same concise VERDICT/Basis/swept-file output contract. Scope remains the requested initial Layout B mockup.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
