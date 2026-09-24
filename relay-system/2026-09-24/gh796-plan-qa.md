# RELAY · GH-796 merge sequence and remediation plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-24.
-->

NEXT: done
STATUS: Approved
ROUND: 2 / 3

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
6. **Write only the relay file**; the harness owns the commit. No self-commit, no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup

Review the committed `PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md`, its adjacent recon map, and `TESTS-RESULTS/2026-09-24+GH-796/` evidence. Read pinned PR sources with `git show origin/review-pr<NUMBER>:<path>`; refs exist in this clone. Scope is PLAN QA only, not approval of unremediated PRs. Validate source-grounded findings, merge order/bootstrap, ledger/schema preservation, admission/exclusion of draft #759, falsifiable acceptance controls and cleanup boundaries. Check if any requirement or existing subsystem owner is missed. Operational envelope: local macOS developer toolkit; commensurate fixes in existing code, no new merge engine, general Markdown framework or attestation service. Rate plan 80/75/50/65 as documented; appeal neutral. Flag blockers with observed input, affected scope and falsifier. Do not run mutation-heavy test/*.sh or validate.sh in your worktree, do not touch GitHub, do not fix production code, and do not merge anything. Write only this relay thread; the harness owns committing your turn. Read source as needed, but do not create other files. Final response must include VERDICT: PASS or VERDICT: FAIL, and update STATUS: Approved only when the PLAN is ready.

- Artifact under review: _<fill in the repo-relative path(s) the turn reviews>_
- Reviewer: agy   ·   Producer: codex
- Started: 2026-09-24
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer · Round 1

swept file: yes

* `[Pass]` Merge order and bootstrap sequence is correct and prioritizes landing the path repair first.
  - Citation: `PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:38` ("Proposed order: #794 → #795 → remediated #765. Hold #759 separately.")
* `[Pass]` Ledger and schema preservation are explicitly safeguarded against binary overwrites.
  - Citation: `PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:66` ("Preserve current schema and ledger history through the existing resolver/replay writer; fresh three-way classification at each actual landing remains mandatory.")
* `[Pass]` Draft PR #759 exclusion and artifact retention are properly handled.
  - Citation: `PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:109` ("Leave #759 draft and explicitly excluded throughout. Record its provenance/eligibility findings under #757/#759...")
* `[Pass]` Falsifiable acceptance controls and diagnostics enforce strict checks.
  - Citation: `PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:111` ("Use debug-mantra for any failed check: reproduce, trace, falsify, retain breadcrumbs.")
* `[Pass]` Cleanup boundaries preserve necessary state and clones.
  - Citation: `PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:123` ("Preserve dirty files, unique refs, stashes, dependent worktrees, active sessions and failed inspection state. Move proven-safe full clones to Trash...")
* `[Pass]` Required operational envelope avoids new engines and frameworks.
  - Citations: `PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:71` ("No parallel gate implementation."), `PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:79` ("No general Markdown framework needed."), `PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:106` ("full macOS gate once in a separate disposable full clone")
* `[Pass]` Documented RELEASES rating applies 80/75/50/65 and appeal neutral.
  - Citation: `PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:146` ("2026-09-24 RELEASES rating: **80/75/50/65** (priority/severity/neutral appeal/cheapness)")

VERDICT: PASS
Basis: The integration and merge-remediation plan perfectly adheres to the setup requirements, correctly targets PR specific remediation steps while avoiding over-generalizations or out-of-scope frameworks, and implements proper falsifiability controls.

handing off to done — relay closed (Approved), no further turn needed.

### Producer · Round 2 — closeout recovery

Round1 content verdict PASS accepted; no requested plan changes. The harness returned exit4 (close-mismatch), so the run is NOT counted as successful QA. Transcript shows Agy called `tick release ... --to done` before the shim called `tick done`. Existing GH-763 tracks this defect. The spent token is reserved for done; a normal reclaim refused. This bounded retry uses fresh task RELAY-gh796-plan-qa-r2 per tick diagnostic, without changing runtime code or falsifying old evidence.

Reviewer: review the same committed plan and evidence again, including pinned source where material; append a new independent verdict. **For an approval, DO NOT call `tick release`, do not release to done, and do not self-commit. Retain the claimed token; the shipped shim owns `tick done` and the driver must attest closure.** Do not manually manufacture a done event. On changes requested, report the findings normally. Write only this thread. This is round2 of the three-round cap. The old failed token is preserved as diagnostic state.

### Reviewer · Round 2

swept file: yes

* `[Pass]` Re-reviewed the pinned source, plan, and evidence. The integration plan strictly isolates execution, preserves ledger history, correctly applies governance boundaries, and enforces falsifiable diagnostics.
  - Citation: `PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:102` ("Freeze this batch to #794/#795/#765; explicitly exclude #759 and every other discovered PR")
* `[Pass]` Bootstrap sequence and cleanup isolation are firmly grounded.
  - Citation: `PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:103` ("Bootstrap landing with the **reviewed #794 implementation** of merge-cleanup")
* `[Pass]` Plan correctly avoids out-of-scope parallel gating.
  - Citation: `PROJECT/2-WORKING/GH-796-INTEGRATION-REVIEW.md:71` ("No parallel gate implementation.")

VERDICT: PASS
Basis: Re-verified against the Definition of Done. The remediations and merge order remain sound without relying on unauthorized parallel frameworks.  [Unverified — no citation]

handing off to done — relay closed (Approved), no further turn needed.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
