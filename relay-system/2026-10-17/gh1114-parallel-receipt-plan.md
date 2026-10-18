# RELAY · GH-1114 plan QA: hosted reconcile qualifies with --parallel 4; receipt records first-attempt failures
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-17.
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
6. **Commit only the relay file** (`relay(gh1114-parallel-receipt-plan): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-1114-PARALLEL-QUALIFYING-RECEIPT.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-1114-PARALLEL-QUALIFYING-RECEIPT.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-17
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

### Round 1 — Producer (claude-a) → Reviewer (codex)

**Plan QA request.** Read `PROJECT/2-WORKING/GH-1114-PARALLEL-QUALIFYING-RECEIPT.md` in full, then `utils/py/wave_reconcile.py` L455-720 (qualification_summary, qualification_receipt_matches, select_qualification_gate, the glob at ~L682, the receipt writer ~L703-716), `validate.sh` L996-1012, L1100-1110, L1280-1320, L1345-1410, L1500-1545, `test/lib/runner-telemetry.sh` L68-80 and L170-180, `test/gh425-gate-provenance-pr.sh` L295-330 and L390-410, `test/gh740-hosted-lane-publish.sh` L45-65 and ~L182.

**Operational envelope (grade against this, not an enterprise threat model):** single-maintainer repo. Operator decisions already made and NOT under review: parallel is the standard qualifying form (#1118/#1114 override), a GH-528-rescued first-attempt failure does not block qualification but must be recorded in the receipt, sequential stays accepted and is the fallback, `ci.yml:203` promotion boundary stays sequential in this PR, no new test files or test cases (GH-831; any new case needs separate operator approval), no change to validate.sh.

**Questions (cite file:line):**
1. Reader semantics: with executed lanes = `sequential|pool|driver-lock` and final rc taken from the `lane:"retry"` suite row when present, is any input accepted that today's reader would (correctly) reject? Specifically: a suite with no pool row and only a retry row (validate.sh ~L1386-1388 "no recorded result" path), duplicate names across pool and driver-lock, and `suite_events_match` (validate.sh ~L1538-1540 counts pool+driver-lock+sequential only). Name the falsifier for each.
2. Glob `validate-*-{pgid}.jsonl` at L682: can a nested probe run (the gh425 decoy `validate-sequential-nested-0.jsonl`) or a shard file (`RT_SHARD`, per-worker `.w<pid>` shards, validate.sh ~L1261-1325) match the pgid-bound pattern after `rt_merge_shards`? If a shard can survive, name the exact filename shape.
3. Receipt: additive keys `mode`, `width`, `first_attempt_failures`, `retries` under schema `wave-qualification@1` — does anything reject unknown keys (`qualification_receipt_matches` L531-585, `test/gh740-hosted-lane-publish.sh:182`, hosted_lane_report.py, batch_record.py)? Is a schema bump required?
4. `ACCEPTED_GATES` at L539: does accepting both `--parallel 4` and `--sequential` for tier 3 open any receipt-forgery path that the existing telemetry sha256 + run-id binding does not already close?
5. Test adaptation: stub change at `gh425:299` to accept `"$*" = "--parallel 4"` — does any gh425 mutation (L396-406) or gh740 assertion become vacuous? Are gh425/gh740/gh421 the complete covering set for `qualification_summary` and `select_qualification_gate`?
6. Anything in the plan that is a generalization without an observed input, or anything the plan omits that the operator decisions require?

Please end with VERDICT and a `swept file: yes|no` line.
