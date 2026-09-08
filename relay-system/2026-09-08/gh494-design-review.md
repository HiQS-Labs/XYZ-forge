# RELAY · GH494 HTML design brief review
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
6. **Commit only the relay file** (`relay(gh494-html-design-brief-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-494-FLIGHT-DASHBOARD.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-494-FLIGHT-DASHBOARD.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: designer
- Started: 2026-09-07
- Definition of Done: The brief covers hourly recall, checkout/issue/PR context, deterministic freshness and attention states, countdown and browser checks, and minimal reversible scope. Approval authorizes constructing the HTML mockup only. Operator visual approval and the Swift plan remain later checkpoints.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer — codex — Round 1

**Verdict: Changes requested.** The mockup scope is sound; clarify the approval boundary and make the attention-state checks reproducible before accepting the brief.

swept file: yes

Read the entire 90-line artifact, including frontmatter, grounding and rating rationale. This is a design-brief review against its Scope, Agreed design and Review questions, provisionally, because Setup still contains a Definition of Done placeholder. Findings below cover the existing text as well as the proposed work; no other pre-existing defects identified in this bounded document review.

- [Should] **R1 — Define the relay's approval checkpoint.** Setup says `Definition of Done: The brief covers hourly recall, checkout/issue/PR context, deterministic freshness and attention states, countdown and browser checks, and minimal reversible scope. Approval authorizes constructing the HTML mockup only. Operator visual approval and the Swift plan remain later checkpoints.`, while `.relay-artifacts/GH-494-FLIGHT-DASHBOARD.md:24` and `:73` reserve rendered HTML and operator approval for later. Fix: replace the placeholder with concrete brief-review criteria, explicitly stating that relay approval authorizes mockup construction only and does not constitute visual approval or permission to begin the Swift plan. The brief's existing review questions can supply these criteria; no implementation work is needed to resolve this finding.
- [Should] **R2 — Separate observation freshness from progress age and define mixed-lane display.** `.relay-artifacts/GH-494-FLIGHT-DASHBOARD.md:50` requires an overdue lane to remain visible, but `:53`–`:56` provide only progress-age colors and the undefined rule “Unknown/stale data is gray.” With a fresh five-minute lane, a fresh 130-minute lane and an unobserved lane in one repo, card status and attention filtering remain ambiguous. Fix: name separate mock observation/progress timestamps (or explicit fixture freshness state), state when data is stale, and specify that unknown progress never becomes green. Define the repo summary/filter rule so a gray lane cannot erase a known overdue lane, and retain the last-known progress age with an uncertainty label when its observation is stale. This is a fixture/display contract, not a request for telemetry infrastructure.
- [Should] **R3 — Give the visual review concrete pass/fail cases.** `.relay-artifacts/GH-494-FLIGHT-DASHBOARD.md:70`–`:72` say to “exercise” states without expected results, and `:47` leaves the seven-card fit viewport unspecified. Fix: add a small acceptance table with desktop/narrow viewport sizes and expected visibility; progress ages 59/60/119/120 minutes; the mixed-lane case from R2; missing/stale observations; 17:59/18:00/18:01 on one fixed local date; and copy denial producing selectable handoff text. Require named, nonempty fixtures for checkout totals and a deliberately mismatched total that the check catches. State where the producer will retain the visual/check results for operator review. These are planned checks, not evidence that the HTML already passes.
- [Pass] **Minimal scope and reversibility are explicit.** `.relay-artifacts/GH-494-FLIGHT-DASHBOARD.md:28`–`:31` limits the work to local mock UI state and excludes services, publication, messaging and merge execution; `:65`–`:69` specifies one self-contained file without packages or telemetry fetches. Retain these boundaries.
- [Pass] **The brief distinguishes activity from progress and preserves human approval.** `.relay-artifacts/GH-494-FLIGHT-DASHBOARD.md:53`–`:56` defines meaningful progress and prevents check-in/snooze from resetting it; `:58`–`:60` keeps wrap-up due after 6 PM; `:73`–`:74` holds Swift planning until operator approval. Retain these requirements while adding the expected outcomes above.

Evidence/limits: direct, complete numbered-source read of the supplied artifact and whole relay; no artifact execution, rendering, source changes, git commands or project gates. Graph project enumeration had no index for this worktree or its flight-dashboard parent clone, so this non-code review uses direct document evidence; no implementation coverage or telemetry-source audit is claimed. Grounding and incident/rating history remain author-reported, not independently established here. Only the relay header and this appended block were edited; the harness owns validation and commit.

**Handoff:** handing off to designer (Producer) — address R1–R3, log a disposition for each and return the revised brief for Reviewer round 2. Go to the Producer window and say 'take your turn'.

### Producer — designer — Round 2

VERDICT: FAIL
Basis: First review produced usable findings but exited 8 because its structured VERDICT/Basis lines were missing; no approval claimed.

R1 Implemented: Setup and brief now distinguish construction approval from user visual approval.
R2 Implemented: explicit observation freshness, >6 minute stale cutoff, summary precedence, mixed-lane and filter rules.
R3 Implemented: viewport, state boundary, countdown, copy-denial and nonempty/negative-count cases with expected outcomes.

Reviewer: review the revised brief, answer its Review questions and resolve R1–R3. Keep the response concise. Your appended block MUST contain standalone `VERDICT: PASS` (approval) or `VERDICT: FAIL`, plus `Basis: ...` and `swept file: yes`. Set STATUS Approved only if approved. Do not run suites or edit artifacts. The harness commits your relay change.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
