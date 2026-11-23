# RELAY · GH-1365 plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-11-07.
-->

NEXT: Producer
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
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Open`.
6. **Commit only the relay file** (`relay(gh-1365-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: PROJECT/2-WORKING/GH-1365-JOG-MARKDOWN-TAIL-EXEMPTION.md
- Reviewer: codex   ·   Producer: task-parent
- Started: 2026-11-07
- Definition of Done: The plan implements the explicit operator policy with honest version attribution and proportionate rigor.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Plain blank separators may be added or removed between sections; preserve every substantive line, indentation, and fenced/literal blank line. A historical FAIL→PASS edit or changed fenced example is forbidden.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Review scope

Read the plan, utils/py/jog_run.py (especially jog_land, _committed_jog_receipt, _publish_jog_receipt), existing gh280 landing checks, MACHINE-CONTRACTS.md, AGENTS.md and GUIDING-PRINCIPLES.md. This is plan QA, no implementation yet. Operational envelope: local operator-owned software factory, not enterprise hostile multi-tenant service. Operator explicitly selected removing exact approval ancestry from queue completion. Do not reinstate it through a supplemental attestation or renamed check. Publication checks stay intact.

1. Does the plan cover the operator's exact request and distinct reviewed/tested/landed versions without false attribution?
2. Are source claims accurate, existing writers retained and acceptance checks falsifiable? Flag concrete missed consumers, not hypothetical machinery.
3. Are rating rationale, scope, rollback and same-PR guidance updates sufficient and commensurate?

Write findings only in this relay; no tests or implementation. Return Approved if fit; keep findings concrete and scoped.

## Log

### Reviewer · Round 1

VERDICT: FAIL
Basis: The selected policy and bounded implementation are fit; add the concrete missed operator guidance consumer before implementation. No additional approval ancestry or supplemental attestation is requested.
swept file: yes

- [Pass] Whole plan swept, including pre-existing sections; no other plan defect found. The operator request is explicit (plan line 26), publication/retry checks remain intact (lines 30, 36), and original review/test attribution is separate from delivery (line 40). Source agrees: `utils/py/jog_run.py:1129` is the publication tail-proof caller, `:1344` is the landing caller, and `:1178` validates the gate against the original receipt head. Existing status ownership remains at `:1431`.
- [Should] Include `skills/2-daily/jog/SKILL.md:168-177` in same-PR guidance updates. It currently says a moved landing head may contain only receipt publication, ledger changes or proven upstream merges, that other blobs refuse, and that landing.json records tree IDs/exclusions. Those instructions would contradict both the new queue policy and removed tail_proof metadata. Cheapest fix: add this existing skill paragraph to implementation step 2, replacing only the landing description with merged/reconciled delivery plus explicit historical reviewed/tested/landed attribution; keep publication requirements distinct.
  Observed input: `skills/2-daily/jog/SKILL.md:170-176`: “A moved head may contain the exact validated receipt publication, ledger-only changes ... or mechanically proven upstream merges” and “Any remaining conflict or extra/missing blob refuses.” Plan steps 2-3 name MACHINE-CONTRACTS, GUIDING-PRINCIPLES and AGENTS, but omit this consumer.
  Affected scope: Operator/agent instructions for post-merge `jog land` and its landing.json description; no publication or retry admission change.
  Falsifier: If that paragraph described publication alone, or the plan already included its update, this finding would be unnecessary. Read-only command `sed -n '145,185p' skills/2-daily/jog/SKILL.md` exited 0 and printed the quoted landing instructions; `nl -ba PROJECT/2-WORKING/GH-1365-JOG-MARKDOWN-TAIL-EXEMPTION.md` exited 0 and showed the consumer absent from steps 2-3.
- [Unverified — needs clone run] Runtime outcomes, historical replay and red controls are implementation acceptance work, not established by this source-only plan review. No suite, fixture, Git operation or live queue mutation was run.
- [Nit] Plan line 36 calls the publisher `_publish_jog_receipt`; its actual name is `publish_jog_receipt` (`utils/py/jog_run.py:1077`). Correct the source pointer while revising.

Handing off to Producer (task-parent) — add the missed Jog guidance update, then return for plan QA.

### Producer · Round 1

Disposition: Implemented. Added skills/2-daily/jog/SKILL.md landing paragraph to step 2; source confirms this exact consumer must change. Corrected publish_jog_receipt symbol spelling. No scope expansion or extra mechanism. Please recheck revised plan and approve if fit.

### Reviewer · Round 2

VERDICT: PASS
Basis: The revised plan addresses the prior findings and fits the explicit operator policy with proportionate verification. Approval covers the plan, not implementation outcomes.
swept file: yes

- [Pass] Swept the whole revised plan, including pre-existing sections; no additional plan defect found. Step 2 now includes “skills/2-daily/jog/SKILL.md landing guidance” (plan:51), resolving the concrete missed consumer at skill lines 168-177. The corrected publisher name at plan:36 matches utils/py/jog_run.py:1077.
- [Pass] The boundary remains narrow: plan:30,36-40 preserves publication/retry admission and committed receipt identity while removing post-merge approval ancestry. Source separates the publication caller (utils/py/jog_run.py:1129) from landing (:1344), validates the historical gate (:1178), and uses the existing queue writer (:1431). Plan:40 explicitly separates original review fields, tested head, final PR head and merge SHA, with absent review fields left null.
- [Pass] Acceptance remains falsifiable and bounded: plan:42,53 requires nonledger and non-ancestor completion, original evidence/identity negatives, baseline refusal, exact attribution and replay idempotence in a disposable full clone. Existing landing checks at test/gh280-jog-marathon-adapter.sh:1000-1073 provide the scenario to update. Plan:28,46,52,58 records the tradeoff, rating rationale, guidance scope and rollback without adding a supplemental attestation.
- [Unverified — needs clone run] No runtime acceptance claim is established here. Source-reading commands (sed, rg and nl) exited 0; no suite, executable fixture, Git operation or queue mutation was run. Implementation and final gate evidence remain required by plan:53-54.

Relay closed (Approved), no further turn needed.


### Attestation · relay-drive — 2026-11-08T04:17:15Z
task: RELAY-gh1365-plan
reviewer: codex
status: Approved
reviewed-head: 140b8ac18f7cde6fe3d9d5ebb1f196818f88c103
added-range: 9786+1825
added-sha256: fc415f1a942d4165889ccfb884b5bc9f9cd85db559708ecfce6809a03a3a7258
<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
