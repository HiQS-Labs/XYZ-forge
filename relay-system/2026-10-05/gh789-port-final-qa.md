# RELAY · GH-789 port final QA (+#965)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-05.
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
6. **Commit only the relay file** (`relay(gh-789-port-final-qa-965): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`, plus the rest of this branch's diff against
  the development base `442ea913`: `ledger_merge.py`, `scan_clones.py`, `toposort_prs.py`, `skills/2-daily/merge-cleanup/SKILL.md`,
  the two fixture edits in `test/gh534_phase_b_tests.py` and `test/gh436-merge-cleanup.py`, the matrix and receipts in
  `TESTS-RESULTS/2026-10-05+GH-789/`, the plan `PROJECT/2-WORKING/GH-789-MERGE-CLEANUP-AUTONOMOUS-PIPELINE.md`, and the
  ledger rows (releases.sql). Approved plan QA: `relay-system/2026-10-05/gh789-port-plan-qa.md` (round 2).
  Issues: https://github.com/HiQS-Labs/XYZ-forge/issues/789, https://github.com/HiQS-Labs/XYZ-forge/issues/965.
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-10-05
- Definition of Done: the code does what the approved plan says (drafts at every boundary incl. the F2 push-boundary skip,
  f1/f2 exit codes, Draft column, CHANGELOG union, stale REBASE_HEAD), keeps every behaviour development gained since
  f1321d6d, adds no test suite / registry entry / capability row (GH-831; the two fixture edits only keep existing suites
  truthful), and the receipts substantiate each claim, including the red controls.

**Operational envelope.** Single-operator local merge tool, core skill. Grade against the approved plan. Do not ask for
new suites, capability rows, retries or a Markdown parser.

**Questions.**
1. Does the code match the approved plan item by item? Cite `file:line` for any gap, especially `push_resolved_head` /
   `DRAFT_REFUSAL` and its caller, the draft summary line, and `prepare_primary_landing`.
2. Did the conflict resolution drop or weaken any development behaviour (GH-851 head wait, GH-852 MERGED re-query,
   resume/attempt records, PUSH_GATE_TIMEOUT_S, hold labels, soft edges)? Concrete input if so.
3. Are the two test-file edits limited to keeping existing suites truthful (fixture `isDraft`; one extra mocked refresh)?
   Is anything else in `test/` new?
4. Do the receipts in `provenance.jsonl` and the logs support the candidate (26/26), R0–R4 and the gh436 run? Over-claims?
5. The SKILL.md wording change at the Phase 1 safe-roots sentence (GH-970 parked nit) — accurate?
6. Ratings 75/70/50/50 (GH-789) and 60/50/50/85 (GH-965) — still right on this evidence?

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
