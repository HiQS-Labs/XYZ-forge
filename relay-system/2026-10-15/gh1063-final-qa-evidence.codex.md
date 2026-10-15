# RELAY · Final merge-batch QA evidence accuracy
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
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
6. **Commit only the relay file** (`relay(gh1063-final-qa-evidence): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: TESTS-RESULTS/2026-10-15+GH-1063-final-regression-QA/ (all retained report, receipts, input/output and investigation files).
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-15
- Definition of Done: Report accurately distinguishes full/recovery PASS, original native FAIL and two instrumented PASS observations; uncertainty and source/identity limits are retained; no runtime, CI-test/case or gate changes, and no fresh native formal approval implied.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->


### Producer · Round 1

This is an evidence-only batch QA report after all four eligible implementation PRs merged1054→1065→1058→1061. Exact tested final implementation5c46c49b. Review only report accuracy/provenance/limitations; it is not another PR1061 runtime QA/adjudication or cap reset. Native original3/3FAIL and two operator-authorized extension rounds remain exhausted/in history. Source/runtime/CI files are unchanged; only TESTS-RESULTS artifacts and this report-review thread are introduced. No new assertion/case, suite, registry or gate is registered.

Actual dedicated local pass in a fresh full clone: unchanged recovery34 PASS64.06s; original unchanged native48 input FAIL14.6s at the exact query-disposition assertion, actual result discarded by that old helper; full local validator PASS409/409 in1314.53s, identity unchanged. Overall runner exits1 because the original manualFAIL remains. Do NOT turn this into an overall clean QA verdict. Two bounded separate diagnostic runs wrap only inspect() with full-result logging, same48 predicates, each48/48PASS. Their before/after config identities were not recorded; the report expressly excludes that claim. Original failure remains unattributed/unchecked inGH1063; no harmless-flake or runtime-fix claim. Existing early preservation returns are only a hypothesis for the initial exact-reason mismatch. Logging input fixes the concrete observability gap, without changing its predicates. No further broad rerun loop.

Full validator's sole pooled failure was gh648-l4-285-revalidate.sh, PermissionError in the real short-lived process-group fixture observation/cleanup. Existing built-in sequential retry PASS; raw initial and retry outputs plus actual telemetry attempts retained. Framework classification contended is not a proven OS-level cause. Git blob proof shows the fixture/codex-turn/agy-turn/proc_group files byte-identical to pre-batch69666c47. Raw output byte counts/digest prefixes match actual telemetry. Full409 is local parallel evidence, not hosted sequential or stable-main qualification. Hosted native wave38677715889 remains active; no hostPASS or actual preexisting checkout retirement is claimed. All native/Git/Trash removals were own synthetic fixtures, metadata/API stubbed; recovery agents stubbed, no live Marathon/Jog.

Read full README, result/provenance, actual failure trace, both instrumented inputs/results/inspection logs, full telemetry/initial+retry evidence and unchanged-source proof. Check original vs instrumented predicates and attribution rigor. Acceptance is truthful, reviewable QA reporting with unresolved finding retained, not certification of every runtime path or demand to manufacture a root cause. A report documenting an unresolved finding can pass accuracy review without declaring runtime QA clean. Normal publication/exact-head checks and destination qualification remain Producer obligations. The subsequent publication uses normal docs gates since these are evidence-only paths; no full runtime rerun for receipt-only edits.

Read-only peer, only this thread writable. No Git command, network, test/validate/pytest, executable fixture or repository import. Narrow file/JSON/hash comparisons with bytecode disabled allowed. Append at absolute EOF exact `### Reviewer (codex) · Round 1`, VERDICT PASS/FAIL, Basis and swept file yes/no. PASS header Approved/NEXT —, tick done RELAY-GH1063-QA-EVIDENCE-20261015. Findings cite concrete artifact/line; no speculative test additions (per-case approval moratorium). Handing off to Reviewer.
