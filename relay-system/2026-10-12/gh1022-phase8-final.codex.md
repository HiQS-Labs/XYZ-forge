# RELAY · GH1022 Phase8 canonical preservation final QA
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
6. **Commit only the relay file** (`relay(gh1022-phase8-final): <role> r<N>`); no push. **Stop** and report one line.
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

Artifact scope: exact candidate16e4a046; whole utils/py/releases_app.py, both changed weekly/releases skill documents and main GH1022 plan. Inspect relevant existing owner fixture sources in full (gh32 owner/artifacts, gh360 scoped-chain/multiline, gh646 status-label, gh549 history). Read current implementation plus unchanged surrounding owner behavior, not only changed diff. Manual source-qualified evidence is committed under TESTS-RESULTS/2026-10-11+GH-1022/phase8-*.json with provenance. This is the bounded new canonical owner API prerequisite, not weekly coordination, proposal/freeze or shared firing/landing.

## Log

### Producer · Round 1

VERDICT: PARKED
Basis: Implemented approved Phase8 plan; new-scope final source QA pending.

Candidate16e4a046 factors existing check receipt arithmetic and existing rebuild staged constructor. Adds pure conservative local-parent row selection and opt-in check preview/apply; new-kind journal binds parent/selection/runtime/root/before-after state, stage exactness and same transaction receipt. Ordinary check owns exact new-mode recovery ahead of legacy cleanup. Existing check/rebuild/defaults, immutable triggers, backup and connector policy retained. Unknown/delete/conflict/owner drift holds; exact repeat no-op. No second store, merger outside owner, runner, gate, migration or event.

27 actual ephemeral manual controls are source-qualified atd7efd6d5: preview/apply/no-op3; backup/refusals/crash/recovery18; source/conflict/deletion/NULL-gh/override/start/history6. Fixtures write local Git/DB/dump/staging/journal/audit with connectors0, no external writes. Existing suites run only in separate disposable full clone. Do not claim every concurrency/drift boundary demonstrated merely because source guard exists; inspect proof and report limits. No new permanent test/case/parameter/registration approved or added.

No source edits, extra agents, executable suites/fixture programs, network/connectors/live actions, or Git commands/writes except this relay; harmless in-memory source probes permitted. Read owners and surrounding code completely in paged chunks (no truncated whole-file approval). Every behavior-change finding needs observed input/scope/falsifier. Preserve R6FAIL6/6/Medium1028, #1027unapproved, closed Phase6/7 and Phase8 planApprovedR1/3. This is genuinely new API finalQA cap3 under existing authority, not a reset or extra corrective allowance. Whole1022 and remainingW7–11 remainactive. Handing off to Reviewer(codex)—take Phase8 final Round1.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
