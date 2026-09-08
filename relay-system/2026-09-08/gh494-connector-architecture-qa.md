# RELAY · GH494 source-neutral incoming connector architecture QA
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
6. **Commit only the relay file** (`relay(gh494-connector-architecture-qa): <role> r<N>`); no push. **Stop** and report one line.
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
- Definition of Done: Flightdeck core and Swift client do not require Rebalance,
  CLIO, Git Pulse or Daily/Shutdown. A small incoming connector protocol supports
  the five planned first-party adapters, each independently removable, while all
  truth/policy remains centralized and GET remains passive. The design must honor
  Ponytail: static registry and one read function, with no marketplace, discovery,
  event bus, DI container, hot reload or duplicated collectors.
- Read the entire artifact and answer with file:line citations:
  1. Can Flightdeck start, render honest capability states and preserve other data
     when zero or any one connector is disabled or broken?
  2. Is the connector batch contract sufficient for current and plausible alternate
     sources without embedding Rebalance/CLIO-specific assumptions in aggregation?
  3. Are parsing/attribution, cross-source truth, browser state and Swift ownership
     separated cleanly, with exactly one authority for each?
  4. Are the five first-party connectors fully included in build and QA, and are any
     source-specific migrations or implicit producer requirements left behind?
  5. Is the plugin mechanism the smallest maintainable implementation, or is any
     part either under-specified or over-engineered?
  6. Does the revised plan contradict another section, its prior review claims, or
     its no-collector/passive-GET boundary?
- Output one concise block with `swept file: yes`, graded findings, concrete fixes,
  `Basis:`, and standalone `VERDICT: PASS` or `VERDICT: FAIL`. Set STATUS Approved
  only for PASS. Review the plan only; do not edit the artifact or build code.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Turn 1: agy (Reviewer)

swept file: yes

Basis: The complete `GH-494-FLIGHT-DASHBOARD.md` artifact was read and evaluated against the Definition of Done and the six QA criteria. The design firmly honors Ponytail constraints, separates concerns precisely, and introduces no contradictory states or unstated producer requirements. Pre-existing content was fully reviewed and no defects were found.

* `[Pass]` Q1 (Start/render with missing connectors): Verified via `GH-494-FLIGHT-DASHBOARD.md:L45-47` ("Missing, disabled or failed connectors yield explicit unavailable/partial capabilities") and `GH-494-FLIGHT-DASHBOARD.md:L228`. (No fix needed).
* `[Pass]` Q2 (Neutral connector contract): Verified via `GH-494-FLIGHT-DASHBOARD.md:L125-130` (immutable metadata, `ConnectorBatch`) and `GH-494-FLIGHT-DASHBOARD.md:L108` (aggregation handles normalization, no source-specific parsing). (No fix needed).
* `[Pass]` Q3 (Separation of concerns): Verified via module table at `GH-494-FLIGHT-DASHBOARD.md:L105-111`, policy centralized at `GH-494-FLIGHT-DASHBOARD.md:L149-151`, and Swift ownership at `GH-494-FLIGHT-DASHBOARD.md:L152-153`. (No fix needed).
* `[Pass]` Q4 (First-party connectors QA/Build): Verified via table at `GH-494-FLIGHT-DASHBOARD.md:L134-140` (all 5 omit independently) and delivery steps at `GH-494-FLIGHT-DASHBOARD.md:L229`. Gap dispositions rely on existing paths `GH-494-FLIGHT-DASHBOARD.md:L443-450`. (No fix needed).
* `[Pass]` Q5 (Maintainable plugin mechanism): Verified via `GH-494-FLIGHT-DASHBOARD.md:L142-147` ("No directory scanning, entry-point discovery... or connector-to-connector calls") and `GH-494-FLIGHT-DASHBOARD.md:L116-118`. (No fix needed).
* `[Pass]` Q6 (No contradictions/passive GET): Verified via `GH-494-FLIGHT-DASHBOARD.md:L230` ("Prove passive reads... spy collectors... assert zero calls during repeated GETs") and `GH-494-FLIGHT-DASHBOARD.md:L538` ("No new collector is currently justified"). (No fix needed).

VERDICT: PASS

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
