# RELAY · GH1022 Phase9 preserved W7 caller final QA
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
6. **Commit only the relay file** (`relay(gh1022-phase9-final): <role> r<N>`); no push. **Stop** and report one line.
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

Artifact scope: whole current core, whole canonical owner, weekly skill/main plan and relevant unchanged owner/planner/caller fixture sources. Candidate5c09a12c plus source-qualified evidence/doc commit; source hashes are in phase9-qualified.json. This is bounded genuinely new W7 caller/orientation functionality, not a reset of R6 or closed Phase8. Do not approve only a diff.

## Log

### Producer · Round 1

VERDICT: PARKED
Basis: Implemented Approved Phase9 plan; independent finalQA pending within prior genuine-new-scope cap3.

Current core reuses existing runtime/preparation/census/private lock/receipt/writers. Canonical adapter swaps bounded delta orientation only, retains physical source/digest order/defaults. Cross-clone envelope retains original private fields/bytes and stops default/source writers; destination same preparation lock held through integration/prepare. Exact directory/bootstrap, parent/tree/blob/split-intent evidence gates resume; source worktree/HEAD retained. Canonical captures/intake accounted before native ancestry, then fresh broad prepare/no-op. Explicit published adoption/normalFF publication is opt-in with supplied normal-hook IO ceiling. No alias/schema/second ledger/orchestrator/gate/test framework or live action.

Current nine source-qualified flows passed (rollover/no-op; lost commit/clone/ancestry/split intent; competing destination writer; exact published adoption/localbare publication; six refusal batch; same-date advance). Earlier witnessed red failures and repairs retained. Existing disposable owner145/scoped27/planner-sourcePASS/rating16; full normal gate still pending. Current source hashes in phase9-qualified.json match source. Metadata/reporting is HELD; PR references are leads, reported done is not criterion evidence. Some nonempty PR, older cached-writer and exact normal-hook budget/interleavings remain explicitly unqualified—inspect limits rather than approving from empty input.

Read complete owners and surrounding code/plan/skills/covering existing fixture sources in paged chunks. Every behavior-change finding needs actual input/scope/falsifier; classify full-sweep limits honestly. No source edits, new agents, suites/executable fixtures, network/connectors/live actions or Git commands/writes except this relay; harmless in-memory source probes permitted. Preserve all R6FAIL6/6Medium1028,1027unapproved, closedPhase6/7/8 and Phase9planApprovedR1/3. No extra cap/tests granted by recent status messages. Full W8–11/1022 remains active. Handing off to Reviewer(codex)—take finalPhase9 Round1.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
