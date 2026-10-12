# RELAY · GH1022 Phase9 bounded W7 caller plan
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-12.
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
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
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
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh1022-phase9-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: codex   ·   Producer: Author
- Started: 2026-10-12
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

Artifact under review: whole PROJECT/2-WORKING/GH-1022-WEEKLY-INTAKE.md, especially Phase9 bounded caller plan atc1158396. Read complete expanded Recon Map and relevant current core preparation/runtime/census/CLI, canonical selector/journal/check/root guards, source private-state and native Git integration/publication contracts. This is a genuine new W7 caller/orientation plan; owner sourcee64 Phase8 is closed ApprovedR2/3 and publishedd22. Do not relabel/reopen R6 or spend outside current cap3.

## Log

### Producer · Round 1

VERDICT: PARKED
Basis: Source-grounded bounded W7 integration plan pending independent planQA, not implementation or full1022 approval.

Read whole plan and source before assessing. Actual e64 direction grounding (phase9-direction-grounding.json) witnesses old planning RMI override240 and fresh canonical release description preserved by existing selector in incoming-delta orientation. Propose one explicit delta-parent policy adapter inside existing owner, preserve default/current schema/GIDs/history/root receipt order; no extra merger, schema, identity alias or broader ledger redesign.

Extend existing core/private preparation protocol for exact old owned/published branch adoption, preserved cross-clone rollover, incoming-path accounting and canonical captures, fresh broad intake/work/PR accounting, no-op and explicit normalFF publication policy. Original predecessor commits/work and private source evidence survive; unknown identity/owner/capture/source conflicts hold. A native ours merge must first prove complete preservation, never bypass conflict. Actual this-task validation isolated/localbare only; onlyimplementationbranchmaypush. Normal hook IO budget must be explicit (oldprepare60s vsmeasuredgate326s). No new store/runner/gate/tests/scheduler/consent or cost framework.

Audit plan honesty and preservation/partial-state/read-only distinctions; do not ask to implement unrelated W8–11/auth/budget infrastructure under this plan. Concrete behavior findings need observed input/scope/falsifier. Whole-source review accurately states bounds; read relevant sources in paged chunks without truncated claims. No source/artifact edits, new agents, executable suites/fixtures, network/connectors/live actions or Git commands/writes except this relay; harmless in-memory source probes permitted. No new CI tests/cases/parameters/registrations or cap allowance. EarlierclosedR6FAIL6/6Medium1028, Phase6/7, Phase8 and1027unapproved remain immutable. Handing off to Reviewer(codex)—take bounded Phase9 plan Round1.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
