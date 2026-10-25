# RELAY · GH-1208 final QA: jog land local reconcile evidence + receipts
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-24.
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
6. **Commit only the relay file** (`relay(gh-1208-final-qa-jog-land-local-reconcile-evidence-receipts): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1208-JOG-LAND-LOCAL-RECEIPT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1208-JOG-LAND-LOCAL-RECEIPT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Definition of Done: FINAL QA of the committed implementation at `e98f3162` (fix commit `f5a4e42f`; plan approved in
  `relay-system/2026-10-24/gh1208-plan-qa.md` r2, attested `94542fbb`). Approve when, against the live tree:
  (1) `utils/py/jog_run.py` `jog_land` carries exactly the approved change — hosted evidence first and unchanged, local
  evidence = `roadmap_items` row for GH-N in `Completed` whose `raw_text` contains `(PR #N)`, read on the existing read-only
  connection; refusal when neither names both remedies; `landing.json` records `hosted_reconcile: matching[0] | null` and
  `local_reconcile: {roadmap_gid, raw_text} | null`; nothing else in `utils/`, `src/`, `relay-automation/`, `bin/`, `test/`
  changed vs `80e67677` (`git diff --name-only 80e67677..HEAD -- utils src relay-automation bin test githooks`);
  (2) the receipts under `TESTS-RESULTS/2026-10-24+GH-1208/` substantiate `SUMMARY.md`: unmodified gh280 223/223 on the fixed
  code; variant GH1127 reverted → `hosted wave-reconcile is not green` refusal (red control); variant GH1127 fixed → suite
  225/225 rc=0 with `landing.json` `hosted_reconcile == null` and a `local_reconcile` object naming the GH-901 row
  (`landing-fixed-gh1127.json`), L6/L7 replay green; variant NEITHER fixed → the combined refusal, no landing. Re-grep the
  retained logs yourself; `reevaluation.txt` explains the driver's two anchoring FAILs honestly;
  (3) the variant edits (`variant-GH1127.sh`, `variant-NEITHER.sh` vs `test/gh280-jog-marathon-adapter.sh`) touch only the
  stub's wave-reconcile `run list` answer, a GH-901 `roadmap add` + `ROADMAP_SOURCE=releases` seed, the L5 step removal
  (NEITHER) and marker capture — no change to what the fix is measured against;
  (4) issue #1208's acceptance (land with local receipt and no hosted run; refuse with neither; idempotent replay) is met,
  with the stated Limit (legacy-ROADMAP repos without a ledger row keep hosted-only behaviour);
  (5) no new test, suite, registry entry, resolver or writer (GH-831); the capture doc's Status, rating 78/75/50/85 and
  `accepted-start` admission are consistent with the evidence.
  The tier-3 `ci-local.sh` full gate is running separately in a disposable clone on `f5a4e42f` (code identical to
  `e98f3162`); its log is attached to the PR, outside this review.
- Operational envelope: a ~20-line either/or evidence change in one function of a single-operator harness; grade against
  #1208, #1131, GH-1108/#1116 and GH-831. Do not request a new receipt format, hosted re-enablement, a second authority
  or enterprise threat models. Reviewer writes stay in this thread.
- Paths to read: `utils/py/jog_run.py` (`jog_land`), `TESTS-RESULTS/2026-10-24+GH-1208/**`,
  `PROJECT/2-WORKING/GH-1208-JOG-LAND-LOCAL-RECEIPT.md`, `relay-system/2026-10-24/gh1208-plan-qa.md`,
  `test/gh280-jog-marathon-adapter.sh:20-75,995-1045`, `utils/py/wave_reconcile.py:1516-1581`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
