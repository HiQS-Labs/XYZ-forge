# RELAY · GH-1195 final QA: planner root anchor fix + evidence
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
6. **Commit only the relay file** (`relay(gh-1195-final-qa-planner-root-anchor-fix-evidence): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1195-PLANNER-ROOT-LEAK.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1195-PLANNER-ROOT-LEAK.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Definition of Done: FINAL QA of the committed implementation at `ac12b1b2` (fix commit `5623dfd7`,
  plan approved in `relay-system/2026-10-24/gh1195-plan-qa.md` r2). Approve when, against the live tree:
  (1) `utils/py/marathon_plan.py` carries exactly the one approved change (`repo_root(anchor_file=__file__)`)
  and nothing else in `utils/`, `src/`, `relay-automation/` or `bin/` changed vs `80e67677`;
  (2) the receipts under `TESTS-RESULTS/2026-10-24+GH-1195/` substantiate the claims in `SUMMARY.md`:
  check A rc=4→rc=3 with B byte-identical, resolver probe, smoke sentinel absent/present/present, and the
  `smoke-reevaluation.txt` explanation of the driver's two assertion-string FAILs is honest (the artifacts
  `smoke-*.jsonl` and `provenance.jsonl` are the evidence; re-grep them yourself);
  (3) the six suites named in `focused-suites-5623dfd7.log` ran and passed, and the stated suite boundary is accurate;
  (4) issue #1195's acceptance bullets are met or explicitly deferred with reason (the vendored root is witnessed
  by a simulated anchor, not an installed vendored CLI; say whether that is acceptable for this one-line change);
  (5) no new test, suite, registry entry, resolver or writer (GH-831); the capture doc's Status, rating 72/70/50/92
  and `accepted-start` admission are consistent with the evidence.
  The tier-3 `ci-local.sh` full gate is running separately in a disposable clone on `5623dfd7` (code identical to
  `ac12b1b2`); its log is attached to the PR, not part of this review.
- Operational envelope: a one-line default-root fix in a single-operator harness; grade against #1195's
  acceptance, GH-831 and GH-1001, not against enterprise threat models. Do not request new tests or changes to
  `harness_home()` precedence. Reviewer writes stay in this thread.
- Paths to read: `utils/py/marathon_plan.py`, `utils/py/harness_paths.py`, `TESTS-RESULTS/2026-10-24+GH-1195/**`,
  `PROJECT/2-WORKING/GH-1195-PLANNER-ROOT-LEAK.md`, `relay-system/2026-10-24/gh1195-plan-qa.md`.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
