# RELAY · GH-48 Phase 3 — Klaviyo UI mapping review (redo, Codex, 500s)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-10.
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
6. **Commit only the relay file** (`relay(gh48-phase3-relay-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **`PROJECT/2-WORKING/v1.2/GH-48-KLAVIYO-ROLLOUT-TASK-BREAKDOWN.md`**
  (repo-relative to the **target repo**, `LTVera-Pandas` — this relay is driven with
  `--target-root` pointed there; the relay thread itself lives in this harness clone).
  Focus especially on the **"Phase 3 — Klaviyo UI mapping"** section: it maps abstract
  Human/Joint tasks in Steps 1-4 to concrete Klaviyo UI click-paths (list import via Lists &
  Segments, campaign exclusion via Send-to/exclude, conditional email blocks via the template
  editor's show/hide logic, recipient export via Recipient Activity / the API). Grounded via web
  search against Klaviyo's public Help Center (2026-07), not hands-on account access — desk
  research, not a verified runbook.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-10
- **Redo context:** this exact review already ran once as a one-shot `/consult` (Codex + agy in
  parallel). Codex was killed by the consult's 300s advisor cap mid-research — its own transcript
  shows it was about to check `developers.klaviyo.com/en/reference/get_campaign_recipients` when
  it died, no final verdict captured. agy answered and flagged a **[Blocker]**: the doc's original
  claim of a working `Get Campaign Recipients` API is wrong — that endpoint only ever existed
  under Klaviyo's legacy v1/v2 API, retired 2024-06-30 (`410 GONE` now). This was independently
  verified (WebFetch 404 + web search confirming the 2024-06-30 retirement) and **already fixed**
  in the doc (see its `4.4` row and revision log). This relay redo exists to give Codex the room
  (`RELAY_TURN_TIMEOUT_S=500`, up from 300s) to finish its own independent pass and confirm/refute
  the fix plus anything else it would have caught had it not been killed.
- Definition of Done: Grade the Phase 3 section (and the `4.4`/`4.2` rows specifically, since
  those changed post-consult) against: (1) accuracy/completeness of the Klaviyo UI mechanics
  claimed — list-import consent handling, campaign send-to/exclude behavior, show/hide logic
  case-sensitivity, the no-native-staggered-rollout claim, and the **corrected** recipient-export
  guidance (Events API filtered on `Received Email` + `campaign_id`, replacing the dead legacy
  endpoint); (2) whether the 4 flagged "gotchas" are genuinely non-obvious; (3) whether Phase 3
  correctly maps back to `PROJECT/2-WORKING/v1.2/V1.2-PREREGISTRATION.md` and
  `PROJECT/2-WORKING/v1.2/KLAVIYO-REAL-WORLD.md` §4. This is a **review-only** turn — Reviewer
  reports graded findings + a Verdict here, does not edit the artifact (`ALLOW_PATHS` is empty for
  this turn by design).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
