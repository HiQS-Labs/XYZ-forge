# RELAY · GH-1208 plan QA: jog land accepts local reconcile evidence
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
6. **Commit only the relay file** (`relay(gh-1208-plan-qa-jog-land-accepts-local-reconcile-evidence): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1208-JOG-LAND-LOCAL-RECEIPT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/1-INBOX/GH-1208-JOG-LAND-LOCAL-RECEIPT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-24
- Definition of Done: the plan in the artifact is approved when a reviewer confirms, against the live
  source paths, that (1) the defect claim is grounded: `utils/py/jog_run.py:1189-1201` requires a hosted
  `wave-reconcile.yml` run and `.github/workflows/wave-reconcile.yml` is `workflow_dispatch` only (#1131);
  (2) the call-site claim is grounded: merge-cleanup Phase 5 (`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:651-820`)
  invokes `run_jog_post_merge_land` BEFORE `commit_and_push_phase5_writes`, so a reconcile-commit check
  would refuse there and the reconciler's ledger write is the evidence that exists at that moment;
  (3) the local-evidence predicate (`roadmap_items` row for GH-N: `section == "Completed"` and `raw_text`
  contains `(PR #N)`) matches what `utils/py/wave_reconcile.py:1516-1581` writes, and is read through the
  existing read-only `connect()` already used in `jog_land` — no new file, schema, writer or reader;
  (4) hosted evidence stays accepted first and unchanged; "neither" still refuses with a message that names
  both remedies; `_landing_tail_proof` and all pre-merge checks are untouched;
  (5) the verification plan is falsifiable on the EXISTING gh280 fixture: the suite stays green unmodified,
  and a disposable copy whose stub `run list` returns `[]` turns L5 red on reverted code and green on fixed
  code, with a "neither" red control and an idempotent replay; no new suite or registry entry (GH-831);
  (6) the rating 78/75/50/85 is grounded in the stated consequence and recurrence; appeal neutral.
- Operational envelope: a ~15-line either/or evidence change in one function of a single-operator harness.
  Grade against #1208's acceptance, #1131, GH-1108/#1116's committed-receipt landing rules and GH-831; do
  not request a new receipt format, a second authority, hosted re-enablement, or enterprise threat models.
  Reviewer writes stay in this thread.
- Source paths to read: `utils/py/jog_run.py` (`jog_land`, `_landing_tail_proof`, `_committed_jog_receipt`),
  `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:640-830`, `utils/py/wave_reconcile.py:1500-1600`,
  `.github/workflows/wave-reconcile.yml`, `test/gh280-jog-marathon-adapter.sh:20-75` (gh stub) and `:995-1020` (L5).

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
