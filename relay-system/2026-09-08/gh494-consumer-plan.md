# RELAY · GH494 consumer-first HTML and Swift plan review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-07.
-->

NEXT: Producer
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
6. **Commit only the relay file** (`relay(gh494-consumer-first-html-and-swift-plan-review): <role> r<N>`); no push. **Stop** and report one line.
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
- Definition of Done: Full plan for HTML Flightdeck as consumer FIRST of existing Rebalance, Git Pulse sync and CLIO writer outputs; no new collectors unless an explicit demonstrated gap requires one. Fully tokenized colors/fonts/all design styling, light/dark production modes, preserve current HTML mockups, and future Swift conversion. User authorized plan only, not runtime implementation.
- Read canonical plan and PROJECT/2-WORKING/recon-flightdeck-consumer.md fully, docs/mockups/flight-dashboard/planning-evidence.json and latest provenance record. The source recon was performed by parent plus three read-only agents against Rebalance HEAD 0bffc4d and exact working-tree/deployment sources; unknowns are bounded. Actual Rebalance root for optional READ ONLY source verification is /Users/noelsaw/Documents/GH Repos/rebalanceOS; do not edit it or invoke any source refresh.
- Grade with SWE/recon principles: every component earns its existence, source authority stays with existing writers, no hidden collection/network/bootstrap in GET, correct provenance/coverage/unknowns, explicit pass/fail checks and rollback, phases connect data to UI, future Swift clearly distinguishes shell from native conversion.
- Questions: (1) Does the plan respect consumer-only reuse including CLIO, avoid false 150-second upstream freshness and refuse false counts/readiness? (2) Are the needed new consumer pieces versus source-owned extensions specific and sufficient to implement? (3) Is full styling tokenization, responsive breakpoints, light/dark and preserved reference designs achievable and bounded? (4) Do navigation, inactivity, errors, loop bounds, QA/6PM and future Swift requirements have actionable acceptance? (5) Any contradictions or important missing seam that would block implementation as written?
- Do not build code, run source jobs/tests, modify governance or execute Git. Edit only this relay file. Driver handles commit/handoff. Append one concise review block with swept file: yes, standalone VERDICT: PASS or VERDICT: FAIL, Basis: text, cited actionable findings. Set STATUS: Approved only for PASS; otherwise leave Open and NEXT: Producer. Proposed tests are promises, not executed proof. Avoid cosmetic or speculative scope expansion.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer — codex — round 1

swept file: yes
VERDICT: FAIL
Verdict: Changes requested
Basis: Read all 411 lines of the artifact, the full Recon Map, planning-evidence.json and latest provenance record. Consumer-first ownership is sound, but three decision contracts need explicit rules to make the requested acceptance falsifiable. This is plan review, not runtime proof; no artifact/source jobs, tests or Git commands were run. Read-only hashing matched the evidence receipt and all 20 source hashes. No additional pre-existing plan defects found beyond the findings below; this is not an exhaustive upstream source audit.

- [Should] **F1 — Define temporal coverage before assigning inactivity colors.** `.relay-artifacts/GH-494-FLIGHT-DASHBOARD.md:119,248–251,275–285` names availability separately from completeness, but only partial/missing coverage explicitly suppresses inactivity. A complete historical snapshot can therefore age into red while its producer is stale, and an hourly observation cannot prove no progress since that observation. Specify the source/lane observation watermark, freshness cutoff (including unknown schedule), null-progress behavior, and whether color is an explicitly as-of verdict or withheld until the required interval is covered. Apply the same rule when a retained snapshot ages without another GET. Add fixtures for complete-but-stale data, an observation watermark before the evaluated interval ends, and no known progress anchor; deliberately ignoring the watermark must fail, with the red receipt retained in the implementation PR.
- [Should] **F2 — Make QA queue classification deterministic.** `.relay-artifacts/GH-494-FLIGHT-DASHBOARD.md:125,254–257,259–263` requires four queue categories and exact-head evidence but never states their predicates or precedence. Passing observed checks alone does not establish that required checks/reviews are present; draft, missing requirements and conflicting review evidence need defined outcomes. Add a small decision table using only available cached fields: eligibility, head match, required-evidence completeness, freshness and category precedence. If required policy/evidence is not in the existing corpus, show unknown/needs verification rather than a ready candidate; no new fetcher is needed. Cover each category, empty checks, draft, missing requirements, changes-requested and wrong-head cases with planned failing controls.
- [Should] **F3 — Bound and version the complete pagination cycle.** `.relay-artifacts/GH-494-FLIGHT-DASHBOARD.md:118,141–145,280–285` caps each response and says to fetch all necessary pages, but defines neither a total page/byte/time cap nor how pages share a snapshot. Per-request timeout and single-flight do not stop an endless/repeated cursor; concurrent corpus updates can produce mixed pages and false exact totals. Specify stable cursor ordering and revision semantics (including server restart), a bounded aggregate cycle, and repeated-cursor/mixed-revision behavior. Either consume one consistent bounded snapshot or retain partial/unknown totals. Add fixtures for repeated cursor, changing revision between pages and aggregate-budget exhaustion; each must terminate and refuse an exact total.
- [Pass] **Reuse and honest source authority:** `.relay-artifacts/GH-494-FLIGHT-DASHBOARD.md:43–53,94–109,302–317` assigns existing writers, prohibits hidden GET collection/bootstrap, and scopes topology/CLIO extensions to their owners. Lines 275–278 explicitly reject a 150-second upstream freshness SLA. Preserve these constraints while resolving F1–F3.
- [Pass] **Design and future conversion are bounded:** `.relay-artifacts/GH-494-FLIGHT-DASHBOARD.md:168–211` defines one typed token source, generated breakpoint rules, light/dark/system and immutable references; lines 227–238 and 259–263 provide actionable navigation and wrap-up behavior; lines 358–384 distinguish the Swift shell from separately approved native views. Proposed QA remains a promise until implementation receipts exist.
- [Pass] **Recon limitations remain explicit:** `docs/mockups/flight-dashboard/provenance.jsonl:8` records “bounded_recon_complete” and names DB lag, topology and milestone/cross-device unknowns; `PROJECT/2-WORKING/recon-flightdeck-consumer.md:176–185` supplies bounded follow-ups. The referenced evidence SHA-256 matched on this review; that does not independently remeasure installed schedules or live coverage.

Handing off to designer (Producer) — resolve F1–F3 in the plan and log each disposition, then return for round 2 review. The harness owns the file-scoped commit.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
