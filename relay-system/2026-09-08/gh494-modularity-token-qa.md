# RELAY · GH494 modularity and tokenization plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-08.
-->

NEXT: designer
STATUS: Approved
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
6. **Commit only the relay file** (`relay(gh494-modularity-token-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-494-FLIGHT-DASHBOARD.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-494-FLIGHT-DASHBOARD.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: agy   ·   Producer: designer
- Started: 2026-09-08
- Definition of Done: The full Flightdeck plan remains implementable and consumer-first while its
  module and token boundaries balance future change with Ponytail/YAGNI. The plan must centralize all
  changeable visual decisions, support light/dark and future Swift parity, preserve readable CSS,
  avoid one-use abstractions and frameworks, assign data truth to Rebalance, and provide testable
  ownership rules. Current HTML mockups remain unchanged; this review covers the plan only.
- Read the complete artifact, not only the new modularity/token paragraphs. Adjudicate these specific
  questions with `file:line` citations:
  1. Are the three public seams (snapshot, app state, semantic tokens) sufficient to change the data
     source, views, themes and future Swift client without coupling unrelated responsibilities?
  2. Do the four implementation responsibilities prevent duplicated fetching, state and truth while
     avoiding interfaces/factories/components that have only one implementation?
  3. Does “fully tokenized” cover every visual decision the operator reasonably expects to change,
     while correctly leaving layout mechanics, content and transient runtime state outside tokens?
  4. Is one JSON-to-CSS/Swift generation path the smallest maintainable cross-platform solution, or
     does any proposed generator/schema/documentation create avoidable machinery?
  5. Are the architecture/token checks strong enough to fail on real drift without becoming a brittle
     dependency-policy framework? Identify any simpler concrete check.
  6. Does any other part of the plan contradict these boundaries or quietly create a second source of
     truth, state store, collector, policy engine or token system?
- Output one concise review block with `swept file: yes`, graded findings, concrete fixes, `Basis:`,
  and standalone `VERDICT: PASS` or `VERDICT: FAIL`. Set STATUS Approved only for PASS. Proposed tests
  are plans, not executed evidence. Do not edit the artifact or build code.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

**agy (Reviewer) — Round 1**
swept file: yes
I swept the entire artifact and found no pre-existing defects violating the modularity or token rules.

* `[Pass]` Three public seams are sufficient and explicitly prevent coupling: "The JSON snapshot is the only Rebalance-to-client contract. App state is the only cross-view runtime contract. Semantic tokens are the only styling contract." (GH-494-FLIGHT-DASHBOARD.md:L111-113).
* `[Pass]` The four responsibilities prevent over-engineering: "A one-use card class, interface/factory, dependency-injection container, event bus, plugin API and generic design-system package are out of scope." (GH-494-FLIGHT-DASHBOARD.md:L109-111).
* `[Pass]` "Fully tokenized" correctly isolates visuals from layout mechanics: "Keep layout mechanics such as grid/flex keywords, percentages, content-driven sizes, stacking structure and accessibility state in CSS" (GH-494-FLIGHT-DASHBOARD.md:L236-237).
* `[Pass]` The token generator is the minimal cross-platform solution: "The token pipeline is deliberately one-way and narrow... Avoid a general token schema language" (GH-494-FLIGHT-DASHBOARD.md:L243-247).
* `[Pass]` Architecture checks are concrete and avoid brittle frameworks: "Add one intentional hardcoded card color/font size and observe the token audit fail." (GH-494-FLIGHT-DASHBOARD.md:L267) and "A deliberate forbidden import must fail the smallest architecture check." (GH-494-FLIGHT-DASHBOARD.md:L269).
* `[Pass]` No hidden state stores or duplicate collectors: "No two active polling owners in shell mode: the web client owns polling" (GH-494-FLIGHT-DASHBOARD.md:L477-478).

Basis: The plan successfully applies minimal YAGNI principles to modularity and tokenization.
VERDICT: PASS

relay closed (Approved), no further turn needed

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
