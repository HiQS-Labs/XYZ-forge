# RELAY · PR1061 operator-authorized QA extension
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-15.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

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
6. **Commit only the relay file** (`relay(pr1061-authorized-extension): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: TESTS-RESULTS/2026-10-15+GH-1059-review-corrections/, original gh1059-final.codex.md and canonical GH1059 acceptance; existing runtime/policy unchanged from original final sweep.
- Reviewer: codex   ·   Producer: codex-producer
- Started: 2026-10-15
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->


### Producer · Extension Round 1 (cumulative final QA round 4)

Authorization: Noel explicitly answered “Authorize one evidence-only review” and then extended tonight's batch: “I authorize you and the agent to do more 2 rounds of QA per PR than base/default. Please get as many PRs merged tonight as possible. And then do the full clone folder clean up.” Main conversation 2026-10-14 19:55 PDT, Sentinel_4231123aedc48191a8cec54c1d6544e0, parent delegation. This is extension1/2 beyond original3/3, not a reset; original relay-system/2026-10-14/gh1059-final.codex.md stays Escalated3/3 byte-identical to880d1452. This thread has the single two-round extension budget, never multiplied across restarts. No new CI test/case approval. PR1062 remains excluded.

Evidence-only first extension: original Round3 found no material runtime defect after sweeping both Python owners and four policy files; it failed solely because newer manual47/cleanup180 atfb6b7f28 and manual48 at359f7766 had provenance.json rather than required JSONL. Those three truthful records were appended ate4a8af1e, original retained. Inspect correction root provenance.jsonl and all-native raw logs/identity/provenance.json. Retained normal full publication ate4a8af1e passed409/409,1223s, two initial suites (gh360-scoped-receipt-chain-rebuild.sh and jog-queue.sh) passed built-in sequential retry. It is local full evidence at its named revision, not hosted full or first-attempt perfection. Publication result/log/telemetry under publication/; original source-only full record was followed by explicit commit/pr/result alias at1c4bc868 for same actual run (no rerun). Existing receipt-reader result at1c/880 is retained there. Doc-only followups atbee96e20 (110s) and880d1452 (73s) published normally, not full409 reruns. No new fixture or tests requested.

Current-base integration: canonical B1 initially handed off CHANGELOG because independently inserted sections weren't prefix-additive. Exact section-by-section comparison proves common preamble/sections identical and all additions retained. Canonical B1 then resolved disjoint ledger by keeping higher-generation ours and replaying GH1052 through writer. current-base/ preserves refusal, resolution and exact business-content comparison: all incoming business content retained, GH1052 only gid/first_seen/updated_at reminted by canonical replay, only new issue1059; incoming LEADERBOARD bytes preserved. Six runtime/policy files are byte-identical to880, original finalQA file also unchanged; current-base/preservation.json includes SHA256 for file-only verification. Ledger check zero failures/nine existing warnings. No code/policy changed during current integration.

Read the relevant artifacts in full, verify missing-JSONL falsifier and evidence attribution/limits, current-base preservation and original-history integrity. No new runtime review is necessary solely for this metadata correction; report any concrete in-scope defect if seen. Do not call earlier full gate a current-head gate: new normal publication after this integration, exact-head hosted checks/reviews, premerge receipts and destination macOS qualification remain Producer obligations. No actual cleanup occurred.

Read-only peer: only this new relay file writable, no Git command, network, test/validate/pytest or executable fixture. Narrow file/JSON/hash probes with bytecode disabled allowed. Append at absolute EOF exact heading `### Reviewer (codex) · Round 1`, `VERDICT: PASS` or FAIL, nonempty Basis and `swept file: yes` or no. On PASS header Approved/NEXT —, tick done RELAY-PR1061-EXTENSION-20261015. On FAIL leave truthful findings and hand off; only one extension round remains. Never edit original relay or counters. Handing off to Reviewer.
