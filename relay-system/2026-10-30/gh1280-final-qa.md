# RELAY · GH-1280 final QA: campaign dispositions and report
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-30.
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
6. **Commit only the relay file** (`relay(gh1280-final-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `TESTS-RESULTS/2026-10-30+GH-1280/SUMMARY.md` (sha256
  `61910ac997aa13d86919d0f4594dfb51f44362c66a3cf4c372aae9f79db8cf33`) and the evidence it cites, all committed at
  `6e60dd4a` on `chore/XYZ-forge-gh1280-outer-loop-ate-campaign-2026-10-30`. `provenance.jsonl` (sha256
  `6a5dc903bf941d15da050126f5655ce4640e8d3e4d82943d4e6798f164bfdde9`) hashes every evidence file. A read-only copy of
  SUMMARY.md is also seeded at `.relay-artifacts/SUMMARY.md`. Do NOT edit any of it.
- Key evidence: `runs/long/supervisor-report.json`, `runs/long/campaign-report.json`, `runs/long/telemetry.jsonl.gz`
  (complete telemetry, 10,000 events), `ev/11-phase3.json` (R1–R4), `ev/12-phase3b.json`, `ev/14-d1-unsandboxed.txt`,
  `ev/06-candidate-status-creates-state.txt`, `ev/timeline.txt`, `contracts/contract-long*.json`, `tools/phase3*.py`,
  `tools/supervisor.py`. Source under `utils/py/` (harness.py `status()` ~line 1267, gen4_campaign.py).
- Prior reviews: `relay-system/2026-10-30/gh1280-plan-qa.md`, `relay-system/2026-10-30/gh1280-long-contract-qa.md`
  (round 2 PASS: "final campaign evidence and dispositions still require their separate review" — this is it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-30
- Operational envelope: one supervised local experiment on the operator's Mac Studio; disposable clones; no
  production-code change; no new tests (GH-831); nothing filed automatically. Grade against issue #1280's acceptance
  criteria (plan `PROJECT/2-WORKING/GH-1280-OUTER-LOOP-ATE-CAMPAIGN.md` § Acceptance criteria and Phase 3 step 11/13)
  and commensurate complexity.
- Definition of Done — answer each, citing file/section:
  1. Does every signal (D1–D6) have an accountable disposition with replay and clean/failing controls, and the row
     fields Phase 3 step 11 requires? Is any disposition wrong (e.g. D2 "expected behaviour", D4 "not flaky", D5
     "environment limit")?
  2. Do the long-run numbers in SUMMARY.md match the reports and telemetry (counts per class per target, 0 candidates,
     stop reason, deadlines, no survivors, canaries unchanged)?
  3. Are the deviations (corpus deleted by the replay reset; D4 replay setup fault) honestly stated, and does either
     invalidate a result?
  4. Is the acceptance criterion "stopped at the no-new-signal limit or earlier" met given D6, and is the stop/go
     recommendation supported?
  Approve only if the report and dispositions may ship as the campaign's record.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
